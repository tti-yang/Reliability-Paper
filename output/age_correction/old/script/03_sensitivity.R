# 03 - MAD x 3 outlier sensitivity under both motion rules.
#
#   reads   data/derived/analysis_data_by_rule.rds
#   writes  output/tables/outlier_sensitivity.csv
#
# Independent of 02: it refits the same specification on the full sample and on
# the two outlier-exclusion variants, and compares them.

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
source(file.path(PROJECT_ROOT, "R", "sensitivity.R"))

analysis_data_by_rule <- read_derived("analysis_data_by_rule")
message("Read ", file.path(DERIVED_DATA_DIR, DERIVED_FILES[["analysis_data_by_rule"]]))

outlier_sensitivity_by_rule <- setNames(
  lapply(MOTION_RULES, function(rule) {
    outlier_sensitivity_table(analysis_data_by_rule[[rule$key]], rule$label)
  }),
  rule_keys()
)

for (rule in MOTION_RULES) {
  counts <- mad_outlier_counts(analysis_data_by_rule[[rule$key]])
  any_row <- counts %>% filter(Outcome == "Any outcome")
  detail(sprintf(
    "  %-28s %3d observations flagged on any outcome (%.1f%%), %d participants",
    rule$prefix,
    any_row$`Observations flagged`,
    any_row$`Observations flagged (%)`,
    any_row$`Participants affected`
  ))
}

sensitivity_table <- bind_rows(outlier_sensitivity_by_rule)

dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)
readr::write_csv(sensitivity_table, file.path(TABLE_DIR, "outlier_sensitivity.csv"))
message(sprintf(
  "Wrote %s (%d x %d)",
  file.path(TABLE_DIR, "outlier_sensitivity.csv"),
  nrow(sensitivity_table), ncol(sensitivity_table)
))
