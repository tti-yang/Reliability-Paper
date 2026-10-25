# Magnitude of the component age effects, on their shared correlation scale.
# All helpers return objects; only the numbered script writes results to disk.

COMPONENT_OUTCOMES <- c("Reliability", "Confusability")
MAGNITUDE_SCOPES <- c("Pooled", INTERACTION_MODALITY_LEVELS)

#' Check that both component specifications use exactly the same source rows.
#' Stop on unequal missingness rather than silently changing the main sample.
validate_component_sample <- function(data) {
  prepared <- prepare_interaction_data(data)
  row_sets <- lapply(COMPONENT_OUTCOMES, function(outcome) {
    list(
      pooled = which(complete.cases(data[c(outcome, MODEL_TERMS, "SubNum")])),
      interaction = which(complete.cases(prepared[c(
        outcome, AGE_TERMS, "Sex_M1", "Education", "SubNum", "Modality"
      )]))
    )
  })
  rows <- row_sets[[1]]$pooled
  for (sets in row_sets) {
    for (candidate in sets) {
      if (!identical(rows, candidate) ||
          !identical(sort(as.character(data$SubNum[rows])),
                     sort(as.character(data$SubNum[candidate])))) {
        stop("Component models must use identical rows and SubNum multisets.")
      }
    }
  }
  if (!length(rows) || n_distinct(data$SubNum[rows]) < 2L) {
    stop("At least two participants with complete component data are required.")
  }
  if (!setequal(as.character(prepared$Modality[rows]),
                INTERACTION_MODALITY_LEVELS)) {
    stop("All three modalities are required for the magnitude comparison.")
  }
  data[rows, , drop = FALSE]
}

#' Fit the existing component specifications and verify actual model frames.
#'
#' A SINGULAR fit is retained, not rejected. A singular fit here is a
#' participant variance estimated at the zero boundary, which is a legitimate
#' maximum-likelihood estimate; the fixed-effect age slopes this analysis reads
#' off are unaffected by it. The confusability model sits near that boundary in
#' the observed data (participant SD 0.045 against a residual SD of 0.221 under
#' the primary rule, 0.029 against 0.223 under the liberal one), so resamples
#' reach it often -- and more often when the resample happens to contain fewer
#' returners, which made rejecting them a filter correlated with both the
#' sample composition and the contrast itself.
#'
#' Rejection is therefore reserved for fits that are genuinely unusable:
#' non-convergence, rank deficiency, or an outright error. Singularity is
#' recorded on the returned list so the boundary behaviour stays visible.
fit_component_pair <- function(data, interaction = FALSE, bootstrap = FALSE) {
  fitter <- if (interaction) fit_interaction_model else fit_model
  singular <- logical(length(COMPONENT_OUTCOMES))
  models <- setNames(lapply(seq_along(COMPONENT_OUTCOMES), function(index) {
    model <- fitter(data, COMPONENT_OUTCOMES[[index]])
    if (bootstrap) {
      messages <- model@optinfo$conv$lme4$messages
      # lme4 reports the boundary as a convergence message; it is not one.
      boundary <- grepl("singular", messages, ignore.case = TRUE)
      singular[[index]] <<- lme4::isSingular(model)
      if (any(model@optinfo$conv$opt != 0L) ||
          length(messages[!boundary]) > 0L ||
          length(attr(lme4::getME(model, "X"), "col.dropped")) > 0L) {
        stop("Non-converged or rank-deficient bootstrap fit.")
      }
    }
    model
  }), COMPONENT_OUTCOMES)
  frames <- lapply(models, model.frame)
  stopifnot(
    nrow(frames[[1]]) == nrow(data),
    nrow(frames[[1]]) == nrow(frames[[2]]),
    identical(rownames(frames[[1]]), rownames(frames[[2]])),
    identical(as.character(frames[[1]]$SubNum),
              as.character(frames[[2]]$SubNum))
  )
  attr(models, "singular") <- any(singular)
  models
}

#' Extract pooled age slopes, named Outcome.age_term, from existing fits.
pooled_component_slopes <- function(models) {
  unlist(lapply(models, function(model) {
    slopes <- lme4::fixef(model)[AGE_TERMS]
    if (any(!is.finite(slopes))) stop("Non-estimable pooled component slope.")
    slopes
  }))
}

#' Fit both pooled component models using the manuscript specification.
component_age_slopes <- function(data) {
  pooled_component_slopes(fit_component_pair(validate_component_sample(data)))
}

#' Extract simple slopes using the manuscript's emtrends/Satterthwaite helper.
modality_component_slopes <- function(models) {
  map_dfr(COMPONENT_OUTCOMES, function(outcome) {
    map_dfr(AGE_TERMS, function(age_term) {
      result <- as_tibble(summary(modality_trends(models[[outcome]], age_term)))
      slopes <- result[[paste0(age_term, ".trend")]]
      if (any(!is.finite(slopes))) stop("Non-estimable modality component slope.")
      tibble(
        modality = as.character(result$Modality), age_term = age_term,
        outcome = outcome, slope = slopes
      )
    })
  })
}

#' Fit the component interaction models and return modality-specific slopes.
component_age_slopes_by_modality <- function(data) {
  modality_component_slopes(fit_component_pair(
    validate_component_sample(data), interaction = TRUE
  ))
}

#' Combine pooled and modality slopes into the eight original-data contrasts.
component_contrast_table <- function(pooled, modality) {
  pooled_table <- expand_grid(outcome = COMPONENT_OUTCOMES, age_term = AGE_TERMS) %>%
    mutate(
      modality = "Pooled",
      slope = unname(pooled[paste(outcome, age_term, sep = ".")])
    )
  bind_rows(pooled_table, modality) %>%
    pivot_wider(names_from = outcome, values_from = slope) %>%
    transmute(
      scope = modality, age_term,
      b_reliability = Reliability, b_confusability = Confusability,
      signed_diff = Reliability - Confusability,
      delta = abs(Reliability) - abs(Confusability)
    ) %>%
    arrange(match(scope, MAGNITUDE_SCOPES), match(age_term, AGE_TERMS))
}

#' Cheap point estimates for the selected interactive motion rule.
component_magnitude_estimates <- function(data, pooled_only = FALSE) {
  component_contrast_table(
    component_age_slopes(data),
    if (pooled_only) NULL else component_age_slopes_by_modality(data)
  )
}

#' Resample whole participants and assign a fresh ID to each sampled copy.
#' Retain the prepared age decomposition: all retained sessions travel together.
resample_component_clusters <- function(data, clusters) {
  draws <- sample.int(length(clusters), length(clusters), replace = TRUE)
  selected <- clusters[draws]
  sampled <- data[unlist(selected, use.names = FALSE), , drop = FALSE]
  sampled$SubNum <- rep(seq_along(selected), lengths(selected))
  sampled
}

#' Choose a conservative worker count; Windows always runs serially.
magnitude_boot_cores <- function() {
  detected <- parallel::detectCores(logical = FALSE)
  if (is.na(detected)) detected <- 1L
  requested <- Sys.getenv("MIND_BOOT_CORES", as.character(min(8L, detected)))
  cores <- suppressWarnings(as.numeric(requested))
  if (length(cores) != 1L || !is.finite(cores) || cores < 1 ||
      cores != floor(cores) || cores > .Machine$integer.max) {
    stop("MIND_BOOT_CORES must be a positive integer.")
  }
  if (.Platform$OS.type == "windows") 1L else as.integer(cores)
}

#' Paired participant bootstrap of |b_R| - |b_C| for both age terms.
#' Original-data fits supply the point estimates; percentile intervals and
#' two-sided sign-tail probabilities use only finite bootstrap contrasts.
#' Each draw has its own L'Ecuyer stream, independent of worker scheduling.
magnitude_contrast <- function(data, B = MAGNITUDE_BOOT_DRAWS,
                               seed = MAGNITUDE_BOOT_SEED,
                               rule_label_text = NA_character_,
                               cores = magnitude_boot_cores(),
                               pooled_only = FALSE, keep_draws = FALSE) {
  stopifnot(length(B) == 1L, is.finite(B), B >= 1, B == floor(B),
            B <= .Machine$integer.max,
            length(seed) == 1L, is.finite(seed), seed == floor(seed),
            abs(seed) <= .Machine$integer.max,
            length(cores) == 1L, is.finite(cores), cores >= 1,
            cores == floor(cores))
  data <- validate_component_sample(data)
  # Primary fits remain visible: suppression is limited to resample fits below.
  point <- component_magnitude_estimates(data, pooled_only = pooled_only)
  clusters <- split(seq_len(nrow(data)), as.character(data$SubNum))

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

  missing_pooled <- setNames(
    rep(NA_real_, 4L),
    as.vector(t(outer(COMPONENT_OUTCOMES, AGE_TERMS, paste, sep = ".")))
  )
  missing_modality <- expand_grid(
    modality = INTERACTION_MODALITY_LEVELS, age_term = AGE_TERMS,
    outcome = COMPONENT_OUTCOMES
  ) %>%
    mutate(slope = NA_real_)

  draw <- function(i) {
    assign(".Random.seed", streams[[i]], envir = globalenv())
    sampled <- resample_component_clusters(data, clusters)
    # A failed pooled pair need not discard a successful interaction pair.
    safe <- function(expression, fallback) {
      tryCatch(suppressMessages(suppressWarnings(expression)),
               error = function(e) fallback)
    }
    singular <- FALSE
    slopes_from <- function(interaction, extract, fallback) {
      models <- safe(
        fit_component_pair(sampled, interaction = interaction, bootstrap = TRUE),
        NULL
      )
      if (is.null(models)) return(fallback)
      singular <<- singular || isTRUE(attr(models, "singular"))
      safe(extract(models), fallback)
    }
    pooled <- slopes_from(FALSE, pooled_component_slopes, missing_pooled)
    modality <- if (pooled_only) NULL else
      slopes_from(TRUE, modality_component_slopes, missing_modality)
    list(
      delta = component_contrast_table(pooled, modality)$delta,
      singular = singular
    )
  }
  workers <- if (.Platform$OS.type == "windows") 1L else min(cores, B)
  draws <- if (workers == 1L) {
    lapply(seq_len(B), draw)
  } else {
    parallel::mclapply(seq_len(B), draw, mc.cores = workers, mc.set.seed = FALSE)
  }
  if (any(!vapply(draws, function(x) {
    is.list(x) && is.numeric(x$delta) && length(x$delta) == nrow(point) &&
      is.logical(x$singular) && length(x$singular) == 1L
  }, logical(1)))) {
    stop("A bootstrap worker failed outside the protected model fits.")
  }
  # Retained, not discarded -- but recorded, so a run that sits on the boundary
  # cannot do so silently.
  singular_draws <- vapply(draws, `[[`, logical(1), "singular")
  draws <- do.call(rbind, lapply(draws, `[[`, "delta"))
  inference <- map_dfr(seq_len(nrow(point)), function(j) {
    valid <- draws[is.finite(draws[, j]), j]
    interval <- if (length(valid)) {
      quantile(valid, c(.025, .975), names = FALSE, type = 7)
    } else c(NA_real_, NA_real_)
    tibble(
      delta_ci_lo = interval[1], delta_ci_hi = interval[2],
      # Cap at one for the degenerate case with probability mass at zero.
      boot_p = if (length(valid)) {
        min(1, 2 * min(mean(valid <= 0), mean(valid >= 0)))
      } else NA_real_,
      n_boot_ok = length(valid)
    )
  })
  result <- bind_cols(point, inference) %>%
    mutate(motion_rule = rule_label_text, .before = 1)

  # Reported here rather than returned: the result is written straight to CSV,
  # and an extra column would change the supplementary table while an extra
  # attribute rides along through subsetting and breaks equality checks on it.
  message(sprintf(
    "%s%d of %d draws had a singular component fit (%.1f%%), all retained.",
    if (is.na(rule_label_text)) "" else paste0(rule_label_text, ": "),
    sum(singular_draws), B, 100 * sum(singular_draws) / B
  ))
  failed <- result %>% filter(n_boot_ok < .99 * B)
  if (nrow(failed)) {
    warning("More than 1% of bootstrap fits failed for ", rule_label_text, ": ",
            paste(paste(failed$scope, failed$age_term,
                        paste0(failed$n_boot_ok, "/", B)), collapse = "; "))
  }
  if (keep_draws) {
    attr(result, "bootstrap") <- list(
      draws = draws, contrasts = point[c("scope", "age_term")],
      singular_draws = singular_draws, B = B, seed = seed, cores = workers,
      pooled_only = pooled_only
    )
  }
  result
}
