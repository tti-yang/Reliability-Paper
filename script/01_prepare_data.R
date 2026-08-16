# 01 - Read data/raw/, apply the motion-exclusion rules, and write the analytic
# data that every later stage uses.
#
#   reads   data/raw/df_mind_all.csv, df_mind_all_mc04.csv,
#           motion_exclusion_by_run_5mm.csv, motion_exclusion_by_run_4mm.csv
#   writes  data/derived/analysis_data_by_rule.rds
#           data/derived/run_flags_by_rule.rds
#           data/derived/subject_age_groups.rds

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

message("Reading raw data from ", RAW_DATA_DIR)
source_data <- load_source_data()
invisible(list2env(source_data, globalenv()))

# The analytic data for each manuscript rule is built once here and reused by
# every later stage: the exports, the sensitivity analysis, and the figures.
analysis_data_by_rule <- setNames(
  lapply(MOTION_RULES, function(rule) {
    build_analysis_data(rule$fd_cutoff, rule$pct_cutoff)
  }),
  rule_keys()
)

run_flags_by_rule <- setNames(
  lapply(MOTION_RULES, function(rule) {
    build_run_flags(rule$fd_cutoff, rule$pct_cutoff)
  }),
  rule_keys()
)

written <- save_derived(list(
  analysis_data_by_rule = analysis_data_by_rule,
  run_flags_by_rule = run_flags_by_rule,
  subject_age_groups = source_data$subject_age_groups
))

for (rule in MOTION_RULES) {
  data <- analysis_data_by_rule[[rule$key]]
  message(sprintf(
    "  %-28s %4d observations, %3d participants",
    rule$prefix, nrow(data), n_distinct(data$SubNum)
  ))
}
message("Wrote:\n  ", paste(written, collapse = "\n  "))
