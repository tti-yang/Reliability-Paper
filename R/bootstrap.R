# Participant-cluster bootstrap for the pooled reliability/confusability
# magnitude contrast, delta = |b_reliability| - |b_confusability|.
#
# This helper supports script/manuscript_analysis.Rmd: the resampling loop
# refits two mixed models 5,000 times per motion rule. Keeping it here prevents
# that mechanical
# repetition from burying the substantive, once-per-rule analysis in the Rmd.
# The model formulas it refits are exactly the ones fit visibly in the Rmd;
# nothing about the manuscript specification lives only in this file.

#' Resample whole participants with replacement and relabel each sampled copy
#' with a fresh cluster id, so a participant drawn twice contributes two
#' independent random-intercept levels rather than one duplicated level.
#' All rows belonging to a sampled participant (every retained wave and
#' modality) travel together.
resample_participant_clusters <- function(data, clusters) {
  draws <- sample.int(length(clusters), length(clusters), replace = TRUE)
  selected <- clusters[draws]
  sampled <- data[unlist(selected, use.names = FALSE), , drop = FALSE]
  sampled$SubNum <- rep(seq_along(selected), lengths(selected))
  sampled
}

#' Fit the pooled Reliability and Confusability models on one (possibly
#' resampled) dataset, using the exact manuscript formula.
#'
#' A SINGULAR fit is retained, not rejected: a participant variance estimated
#' at the zero boundary is still a legitimate maximum-likelihood estimate, and
#' the confusability model sits close to that boundary even in the observed
#' data, so resamples reach it often. Discarding singular draws is not a
#' neutral filter -- it is correlated with sample composition -- so they are
#' kept and counted instead (`attr(., "singular")`). Only a genuinely unusable
#' fit is rejected: non-convergence, rank deficiency, or an outright error.
fit_magnitude_components <- function(data, require_convergence = FALSE) {
  outcomes <- c("Reliability", "Confusability")
  singular <- logical(length(outcomes))
  models <- setNames(lapply(seq_along(outcomes), function(i) {
    outcome <- outcomes[[i]]
    model_data <- data %>%
      tidyr::drop_na(dplyr::all_of(c(outcome, MODEL_TERMS, "SubNum")))
    model <- lmerTest::lmer(
      reformulate(c(MODEL_TERMS, "(1 | SubNum)"), response = outcome),
      data = model_data, REML = FALSE
    )
    if (require_convergence) {
      messages <- model@optinfo$conv$lme4$messages
      boundary <- grepl("singular", messages, ignore.case = TRUE)
      singular[[i]] <<- lme4::isSingular(model)
      if (any(model@optinfo$conv$opt != 0L) ||
          length(messages[!boundary]) > 0L ||
          length(attr(lme4::getME(model, "X"), "col.dropped")) > 0L) {
        stop("Non-converged or rank-deficient bootstrap fit.")
      }
    }
    model
  }), outcomes)
  attr(models, "singular") <- any(singular)
  models
}

#' Choose a conservative worker count; Windows always runs serially.
magnitude_boot_cores <- function() {
  detected <- parallel::detectCores(logical = FALSE)
  if (is.na(detected)) detected <- 1L
  requested <- Sys.getenv("MIND_BOOT_CORES", as.character(min(8L, detected)))
  cores <- suppressWarnings(as.numeric(requested))
  if (length(cores) != 1L || !is.finite(cores) || cores < 1 ||
      cores != floor(cores)) {
    stop("MIND_BOOT_CORES must be a positive integer.")
  }
  if (.Platform$OS.type == "windows") 1L else as.integer(cores)
}

#' Paired participant-cluster bootstrap of delta = |b_R| - |b_C| for both age
#' terms (between_cAge, within_cAge), on one motion rule's analysis data.
#'
#' Returns a list with point estimates (`point`, one row per age term), the
#' 95% percentile CIs and bootstrap diagnostics (`summary`), and the raw
#' per-draw deltas (`draws`, a B x 2 matrix with a column per age term) so
#' they can be saved and inspected without rerunning the resampling.
magnitude_bootstrap <- function(data, age_terms, B = 5000L, seed = 20260910L,
                                cores = magnitude_boot_cores()) {
  stopifnot(length(B) == 1L, is.finite(B), B >= 1, B == floor(B),
            length(seed) == 1L, is.finite(seed), seed == floor(seed))

  point_models <- fit_magnitude_components(data)
  point_slopes <- sapply(age_terms, function(term) {
    c(reliability = unname(lme4::fixef(point_models$Reliability)[term]),
      confusability = unname(lme4::fixef(point_models$Confusability)[term]))
  })
  point <- tibble::tibble(
    age_term = age_terms,
    b_reliability = point_slopes["reliability", ],
    b_confusability = point_slopes["confusability", ],
    delta = abs(point_slopes["reliability", ]) - abs(point_slopes["confusability", ])
  )

  clusters <- split(seq_len(nrow(data)), as.character(data$SubNum))

  # Each draw gets its own L'Ecuyer-CMRG stream, so changing the core count
  # never changes which resamples are drawn, and the caller's RNG state is
  # restored on exit.
  previous_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) previous_seed <- get(".Random.seed", envir = globalenv())
  on.exit({
    do.call(RNGkind, as.list(previous_kind))
    if (had_seed) {
      assign(".Random.seed", previous_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  streams <- vector("list", B)
  streams[[1]] <- get(".Random.seed", envir = globalenv())
  if (B > 1L) {
    for (i in 2:B) streams[[i]] <- parallel::nextRNGStream(streams[[i - 1L]])
  }

  draw_once <- function(i) {
    assign(".Random.seed", streams[[i]], envir = globalenv())
    sampled <- resample_participant_clusters(data, clusters)
    result <- tryCatch({
      models <- suppressMessages(suppressWarnings(
        fit_magnitude_components(sampled, require_convergence = TRUE)
      ))
      slopes <- sapply(age_terms, function(term) {
        c(lme4::fixef(models$Reliability)[term],
          lme4::fixef(models$Confusability)[term])
      })
      list(
        delta = abs(slopes[1, ]) - abs(slopes[2, ]),
        singular = isTRUE(attr(models, "singular"))
      )
    }, error = function(e) {
      list(delta = setNames(rep(NA_real_, length(age_terms)), age_terms),
           singular = FALSE)
    })
    result
  }

  workers <- if (.Platform$OS.type == "windows") 1L else min(cores, B)
  draws <- if (workers == 1L) {
    lapply(seq_len(B), draw_once)
  } else {
    parallel::mclapply(seq_len(B), draw_once, mc.cores = workers, mc.set.seed = FALSE)
  }

  singular_draws <- vapply(draws, `[[`, logical(1), "singular")
  delta_matrix <- do.call(rbind, lapply(draws, `[[`, "delta"))
  colnames(delta_matrix) <- age_terms

  inference <- lapply(age_terms, function(term) {
    valid <- delta_matrix[is.finite(delta_matrix[, term]), term]
    interval <- if (length(valid)) {
      stats::quantile(valid, c(.025, .975), names = FALSE, type = 7)
    } else c(NA_real_, NA_real_)
    tibble::tibble(
      age_term = term,
      delta_ci_lo = interval[1], delta_ci_hi = interval[2],
      n_boot_ok = length(valid)
    )
  })
  inference <- dplyr::bind_rows(inference)

  summary_table <- dplyr::left_join(point, inference, by = "age_term")

  list(
    point = point,
    summary = summary_table,
    draws = delta_matrix,
    singular_draws = singular_draws,
    B = B, seed = seed, cores = workers
  )
}
