# 02 - Fit the mixed-effects models and write the manuscript tables.
#
#   reads   data/derived/analysis_data_by_rule.rds, run_flags_by_rule.rds,
#           subject_age_groups.rds
#   writes  output/tables/fd04_pct10_{demographics,descriptives,
#             interaction_tests,simple_slopes,slope_contrasts}.csv
#           output/tables/fd05_pct20_{... the same five ...}.csv
#           output/tables/motion_accounting.csv
#           output/tables/model_estimates.csv
#           output/tables/contextual_effects.csv
#
# demographics and descriptives are rule-specific and are therefore prefixed
# with the motion rule; the rest carry a motion_rule column and cover both
# rules in one file.

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

analysis_data_by_rule <- read_derived("analysis_data_by_rule")
run_flags_by_rule <- read_derived("run_flags_by_rule")
subject_age_groups <- read_derived("subject_age_groups")

interaction_results_by_rule <- lapply(
  analysis_data_by_rule,
  compute_interaction_results
)

contextual_effects_by_rule <- setNames(
  lapply(MOTION_RULES, function(rule) {
    contextual_effects_table(analysis_data_by_rule[[rule$key]], rule$label)
  }),
  rule_keys()
)

export_tables <- list()
for (rule in MOTION_RULES) {
  rule_data <- analysis_data_by_rule[[rule$key]]
  rule_interaction <- interaction_results_by_rule[[rule$key]]

  export_tables[[paste0(rule$prefix, "_demographics.csv")]] <-
    demographics_export(rule_data, rule$label)
  export_tables[[paste0(rule$prefix, "_descriptives.csv")]] <-
    descriptives_export(rule_data, rule$label)
  export_tables[[paste0(rule$prefix, "_interaction_tests.csv")]] <-
    rule_interaction$tests %>% mutate(motion_rule = rule$label, .before = 1)
  export_tables[[paste0(rule$prefix, "_simple_slopes.csv")]] <-
    rule_interaction$slopes %>% mutate(motion_rule = rule$label, .before = 1)
  export_tables[[paste0(rule$prefix, "_slope_contrasts.csv")]] <-
    rule_interaction$contrasts %>% mutate(motion_rule = rule$label, .before = 1)
}
export_tables[["motion_accounting.csv"]] <-
  motion_accounting_export(run_flags_by_rule, subject_age_groups)
export_tables[["model_estimates.csv"]] <-
  model_estimates_export(analysis_data_by_rule)
export_tables[["contextual_effects.csv"]] <-
  bind_rows(contextual_effects_by_rule)

dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)
for (filename in names(export_tables)) {
  readr::write_csv(export_tables[[filename]], file.path(TABLE_DIR, filename))
  message(sprintf(
    "  %-40s %3d x %2d",
    filename, nrow(export_tables[[filename]]), ncol(export_tables[[filename]])
  ))
}
message("Wrote ", length(export_tables), " tables to ", TABLE_DIR)
