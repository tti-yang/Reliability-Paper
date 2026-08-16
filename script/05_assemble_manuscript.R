# 05 - Assemble the manuscript tree from output/.
#
#   reads   output/tables/, output/figures/
#   writes  manuscript/main/, manuscript/supplement/
#
# This script reads nothing from data/ and computes nothing. It copies files
# out of output/ under manuscript-facing names, so output/ can keep names that
# describe what produced a file while the manuscript gets names that describe
# where the file appears.
#
# manuscript/ is wiped and rebuilt on every run and is not tracked by git: it
# is derived, and a tracked second copy could disagree with output/.
#
# MANIFEST is the single edit point. Moving a table between main and
# supplement, or renumbering one, is a change to `destination` here and to
# nothing else.

source(here::here("R", "setup.R"))

# rule_filter selects rows from a source that covers both motion rules; NA
# copies the file whole. It is the only column that changes what is written --
# source, destination, and notes are the description.
MANIFEST <- tribble(
  ~source,                              ~destination,                    ~rule_filter,                  ~notes,

  # --- main -------------------------------------------------------------
  "figures/figure2_fd04_pct10.png",     "main/figure_2.png",             NA,                            "Between-person age effects, primary motion rule (FD 0.4 mm / 10%).",
  "figures/figure3_fd04_pct10.png",     "main/figure_3.png",             NA,                            "Within-person age effects, primary motion rule.",
  "tables/model_estimates.csv",         "main/table_3.csv",              "FD 0.4 mm / 10% (primary)",   "PARTIAL: the primary-rule rows of model_estimates.csv. The liberal-rule rows of the same file are Table S5.",
  "tables/fd04_pct10_interaction_tests.csv", "main/table_4.csv",         NA,                            "Joint age x modality F tests, primary rule.",
  "tables/fd04_pct10_simple_slopes.csv", "main/table_5.csv",             NA,                            "Simple slopes by modality, primary rule.",

  # --- supplement -------------------------------------------------------
  "figures/figure2_fd05_pct20.png",     "supplement/figure_s1.png",      NA,                            "Figure 2 under the liberal motion rule (FD 0.5 mm / 20%).",
  "figures/figure3_fd05_pct20.png",     "supplement/figure_s2.png",      NA,                            "Figure 3 under the liberal motion rule.",
  "tables/fd04_pct10_demographics.csv", "supplement/table_s1.csv",       NA,                            "Demographics by analytic sample, primary rule.",
  "tables/fd04_pct10_descriptives.csv", "supplement/table_s2.csv",       NA,                            "Descriptive statistics by modality, primary rule.",
  "tables/motion_accounting.csv",       "supplement/table_s3.csv",       NA,                            "Runs assessed and excluded by age group and modality, both rules.",
  "tables/outlier_sensitivity.csv",     "supplement/table_s4.csv",       NA,                            "ALL of outlier_sensitivity.csv: MAD x 3 sensitivity, both rules, all three exclusion variants.",
  "tables/model_estimates.csv",         "supplement/table_s5.csv",       "FD 0.5 mm / 20% (liberal)",   "PARTIAL: the liberal-rule rows of model_estimates.csv. The primary-rule rows are Table 3.",
  "tables/fd05_pct20_interaction_tests.csv", "supplement/table_s6.csv",  NA,                            "Joint age x modality F tests, liberal rule.",
  "tables/fd05_pct20_simple_slopes.csv", "supplement/table_s7.csv",      NA,                            "Simple slopes by modality, liberal rule.",
  "tables/contextual_effects.csv",      "supplement/table_s8.csv",       NA,                            "ALL of contextual_effects.csv: b_between - b_within with its Satterthwaite test, both rules."
)

source_path <- function(relative) file.path(here("output"), relative)
destination_path <- function(relative) file.path(MANUSCRIPT_DIR, relative)

missing_sources <- MANIFEST$source[!file.exists(source_path(MANIFEST$source))]
if (length(missing_sources) > 0) {
  stop(
    "Missing sources in output/: ", paste(unique(missing_sources), collapse = ", "),
    "\nRun script/02_fit_models.R, 03_sensitivity.R and 04_figures.R first."
  )
}

# Wipe and rebuild, so a destination that has been renamed or dropped from the
# manifest cannot survive as a stale file in manuscript/.
unlink(MANUSCRIPT_DIR, recursive = TRUE)
for (subdirectory in unique(dirname(MANIFEST$destination))) {
  dir.create(destination_path(subdirectory), showWarnings = FALSE, recursive = TRUE)
}

copy_entry <- function(source, destination, rule_filter) {
  from <- source_path(source)
  to <- destination_path(destination)

  if (is.na(rule_filter)) {
    stopifnot(file.copy(from, to, overwrite = TRUE))
    return(NA_integer_)
  }

  table <- readr::read_csv(from, show_col_types = FALSE, progress = FALSE)
  if (!"motion_rule" %in% names(table)) {
    stop(source, " has no motion_rule column, so it cannot be split by rule.")
  }
  rows <- table %>% filter(motion_rule == rule_filter)
  if (nrow(rows) == 0) {
    stop("No rows in ", source, " with motion_rule == '", rule_filter, "'.")
  }
  readr::write_csv(rows, to)
  nrow(rows)
}

MANIFEST$rows_written <- unlist(Map(
  copy_entry, MANIFEST$source, MANIFEST$destination, MANIFEST$rule_filter
))

# Anything in output/ the manifest does not reference. Reported rather than
# silently dropped, so a new table in output/tables/ cannot go unnoticed.
all_tables <- list.files(here("output", "tables"), pattern = "[.]csv$")
unreferenced <- setdiff(all_tables, basename(MANIFEST$source[grepl("^tables/", MANIFEST$source)]))

# ---------------------------------------------------------------------------
# The manifest, as a markdown table for the README.
# ---------------------------------------------------------------------------
markdown_row <- function(...) cat("|", paste(c(...), collapse = " | "), "|\n")

cat("\n### Manuscript manifest\n\n")
markdown_row("Manuscript file", "Source in `output/`", "Notes")
markdown_row("---", "---", "---")
for (i in seq_len(nrow(MANIFEST))) {
  markdown_row(
    paste0("`manuscript/", MANIFEST$destination[[i]], "`"),
    paste0("`", MANIFEST$source[[i]], "`"),
    MANIFEST$notes[[i]]
  )
}

cat("\nWrote", nrow(MANIFEST), "files to", MANUSCRIPT_DIR, "\n")
if (length(unreferenced) > 0) {
  cat(
    "\nNOT referenced by the manifest (in output/tables/ but not copied):\n  ",
    paste(unreferenced, collapse = "\n  "), "\n"
  )
}
