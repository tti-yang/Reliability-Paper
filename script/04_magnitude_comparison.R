# 04 - Compare the magnitudes of reliability and confusability age slopes.
#
#   reads   data/derived/analysis_data_by_rule.rds
#           output/tables/model_estimates.csv, {rule}_simple_slopes.csv
#   writes  output/tables/magnitude_comparison.csv

# Anchor on this file's own location, so the script runs from any working
# directory. here() searches upward from the working directory instead, which
# is the wrong root when the script is launched by path from elsewhere.
PROJECT_ROOT <- local({
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(file_arg) == 1) {
    dirname(dirname(normalizePath(sub("^--file=", "", file_arg))))
  } else {
    here::here()
  }
})
source(file.path(PROJECT_ROOT, "R", "setup.R"))
source(file.path(PROJECT_ROOT, "R", "data.R"))
source(file.path(PROJECT_ROOT, "R", "models.R"))
source(file.path(PROJECT_ROOT, "R", "magnitude.R"))

B <- suppressWarnings(as.numeric(Sys.getenv("MIND_BOOT_B", "5000")))
if (length(B) != 1L || !is.finite(B) || B < 1 || B != floor(B) ||
    B > .Machine$integer.max) {
  stop("MIND_BOOT_B must be a positive integer.")
}
cores <- magnitude_boot_cores()
started <- proc.time()[["elapsed"]]
message("Magnitude comparison: B = ", B, ", seed = ", MAGNITUDE_BOOT_SEED,
        ", cores = ", cores)
analysis_data_by_rule <- read_derived("analysis_data_by_rule")

read_reference <- function(filename) {
  path <- file.path(TABLE_DIR, filename)
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run script/02_fit_models.R first.")
  }
  readr::read_csv(path, num_threads = 1, show_col_types = FALSE)
}
pooled_reference <- read_reference("model_estimates.csv")

validate_magnitude_signs <- function(table) {
  # Opposite signs motivated this analysis: this identity does not apply then.
  same_sign <- sign(table$b_reliability) == sign(table$b_confusability)
  stopifnot(all(abs(table$delta[same_sign] -
    sign(table$b_reliability[same_sign]) * table$signed_diff[same_sign]) < 1e-8))
}

# Validate BOTH rules before spending time on any bootstrap draws.
for (rule in MOTION_RULES) {
  data <- validate_component_sample(analysis_data_by_rule[[rule$key]])
  stopifnot(all(is.finite(data$Distinctiveness)),
            all(abs(data$Reliability - data$Confusability -
                      data$Distinctiveness) < 1e-8))
  point <- component_magnitude_estimates(data)
  reference <- bind_rows(
    pooled_reference %>%
      filter(motion_rule == rule$label, term %in% AGE_TERMS) %>%
      transmute(scope = "Pooled", age_term = term, outcome, slope = estimate),
    read_reference(paste0(rule$prefix, "_simple_slopes.csv")) %>%
      filter(motion_rule == rule$label, age_term %in% AGE_TERMS) %>%
      transmute(scope = modality, age_term, outcome, slope)
  )
  stopifnot(nrow(reference) == 24L,
            !anyDuplicated(reference[c("scope", "age_term", "outcome")]))
  reference <- reference %>%
    pivot_wider(names_from = outcome, values_from = slope)
  comparison <- left_join(point, reference, by = c("scope", "age_term"))
  # Same model, same component: these equalities hold for separate mixed fits.
  stopifnot(nrow(comparison) == 8L,
            all(is.finite(as.matrix(comparison[-c(1, 2)]))),
            all(abs(comparison$b_reliability - comparison$Reliability) < 1e-8),
            all(abs(comparison$b_confusability - comparison$Confusability) < 1e-8))
  validate_magnitude_signs(point)

  # Outcome additivity does NOT force coefficient additivity when each model
  # estimates its own variance components. Report this discrepancy explicitly;
  # forcing equality would change the manuscript's component specifications.
  message("\n", rule$label, ": identical samples (", nrow(data), " rows, ",
          n_distinct(data$SubNum), " participants); component export checks passed.")
  print(comparison %>% transmute(
    scope, age_term, signed_diff, distinctiveness_slope = Distinctiveness,
    difference = signed_diff - Distinctiveness
  ), n = Inf)
}

results <- bind_rows(lapply(MOTION_RULES, function(rule) {
  message("\nBootstrapping ", rule$label)
  magnitude_contrast(analysis_data_by_rule[[rule$key]], B = B,
                     seed = MAGNITUDE_BOOT_SEED,
                     rule_label_text = rule$label, cores = cores)
}))
validate_magnitude_signs(results)
if (any(results$n_boot_ok == 0L)) {
  stop("No usable bootstrap draws for one or more rows; no table was written.")
}

for (rule in MOTION_RULES) {
  for (scope_name in c("Pooled", "Motor")) {
    row <- results %>% filter(motion_rule == rule$label, scope == scope_name,
                              age_term == "between_cAge")
    includes_zero <- row$delta_ci_lo <= 0 && row$delta_ci_hi >= 0
    message(sprintf("%s, %s between-person: delta = %.7f; CI %s zero.",
                    rule$label, scope_name, row$delta,
                    if (includes_zero) "includes" else "excludes"))
    if (rule$key == "primary") {
      expected <- if (scope_name == "Pooled") .0031 else -.0004
      if (abs(row$delta - expected) > .001) {
        message("  CHECK: point estimate is more than 0.001 from the brief's ",
                "approximate expectation (", expected, ").")
      }
    }
  }
}

dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)
readr::write_csv(results, file.path(TABLE_DIR, "magnitude_comparison.csv"))
message(sprintf("\nCompleted B = %d, seed = %d in %.1f seconds.",
                B, MAGNITUDE_BOOT_SEED, proc.time()[["elapsed"]] - started))
print(results %>% select(motion_rule, scope, age_term, n_boot_ok), n = Inf)
message("Wrote ", file.path(TABLE_DIR, "magnitude_comparison.csv"))
