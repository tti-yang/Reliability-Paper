# Run with Rscript tests/check_magnitude.R after stage 01.
PROJECT_ROOT <- local({
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  dirname(dirname(normalizePath(sub("^--file=", "", file_arg))))
})
source(file.path(PROJECT_ROOT, "R", "setup.R"))
source(file.path(PROJECT_ROOT, "R", "data.R"))
source(file.path(PROJECT_ROOT, "R", "models.R"))
source(file.path(PROJECT_ROOT, "R", "magnitude.R"))

data <- read_derived("analysis_data_by_rule")$primary
expect_error <- function(expression, pattern) {
  error <- tryCatch({ force(expression); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}

# Equal row counts and equal participant multisets alone cannot detect unequal
# observations: put missing outcomes on different rows of the SAME participant.
rows <- which(data$SubNum == data$SubNum[[1]])[1:2]
bad <- data
bad$Reliability[rows[1]] <- NA_real_
bad$Confusability[rows[2]] <- NA_real_
expect_error(validate_component_sample(bad), "identical rows")

# Repeated participant copies keep every original session and modality but
# have distinct model grouping IDs. Check source-row membership directly.
data$source_row <- seq_len(nrow(data))
clusters <- split(seq_len(nrow(data)), as.character(data$SubNum))
set.seed(14)
sampled <- resample_component_clusters(data, clusters)
groups <- split(sampled$source_row, sampled$SubNum)
stopifnot(length(groups) == length(clusters),
          anyDuplicated(vapply(groups, function(x) data$SubNum[x[1]], numeric(1))) > 0)
for (group in groups) {
  stopifnot(identical(group, clusters[[as.character(data$SubNum[group[1]])]]))
}

# The caller's RNG state and contrast settings survive both execution modes.
set.seed(33)
previous_seed <- .Random.seed
previous_kind <- RNGkind()
previous_contrasts <- getOption("contrasts")
serial <- suppressWarnings(magnitude_contrast(data, B = 12, cores = 1))
stopifnot(identical(previous_seed, .Random.seed),
          identical(previous_kind, RNGkind()),
          identical(previous_contrasts, getOption("contrasts")))
parallel_result <- suppressWarnings(magnitude_contrast(data, B = 12, cores = 2))
stopifnot(identical(serial, parallel_result),
          identical(previous_seed, .Random.seed),
          identical(previous_kind, RNGkind()),
          identical(previous_contrasts, getOption("contrasts")))
point <- component_magnitude_estimates(data)
stopifnot(identical(serial[names(point)], point),
          nrow(serial) == 8L,
          all(serial$delta_ci_lo <= serial$delta_ci_hi),
          all(serial$boot_p >= 0 & serial$boot_p <= 1))

# Failed bootstrap fits must not abort or turn into successful zero contrasts.
original_fitter <- fit_component_pair
fit_component_pair <- function(data, interaction = FALSE, bootstrap = FALSE) {
  if (bootstrap) stop("Injected resample fit failure")
  original_fitter(data, interaction, bootstrap)
}
warnings <- character()
failed <- withCallingHandlers(magnitude_contrast(data, B = 2, cores = 1),
  warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
fit_component_pair <- original_fitter
stopifnot(all(failed$n_boot_ok == 0L), all(is.na(failed$boot_p)),
          all(is.na(failed$delta_ci_lo)), all(is.na(failed$delta_ci_hi)),
          identical(failed[names(point)], point),
          any(grepl("More than 1%", warnings)))
message("Magnitude checks passed: sample identity, cluster copies, original-data ",
        "estimates, core-independent RNG, state restoration, and failed draws.")
