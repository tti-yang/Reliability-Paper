# 03 - MAD x 3 outlier sensitivity under both motion rules.
#
#   reads   data/derived/analysis_data_by_rule.rds
#   writes  output/tables/outlier_sensitivity.csv
#
# Independent of 02: it refits the same specification on the full sample and on
# the two outlier-exclusion variants, and compares them.

source(here::here("R", "setup.R"))
source(here("R", "data.R"))
source(here("R", "models.R"))
source(here("R", "sensitivity.R"))

analysis_data_by_rule <- read_derived("analysis_data_by_rule")

outlier_sensitivity_by_rule <- setNames(
  lapply(MOTION_RULES, function(rule) {
    outlier_sensitivity_table(analysis_data_by_rule[[rule$key]], rule$label)
  }),
  rule_keys()
)

for (rule in MOTION_RULES) {
  counts <- mad_outlier_counts(analysis_data_by_rule[[rule$key]])
  any_row <- counts %>% filter(Outcome == "Any outcome")
  message(sprintf(
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
