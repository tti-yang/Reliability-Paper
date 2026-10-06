# 06 - Assemble the manuscript tree from output/.
#
#   reads   output/tables/, output/figures/, R/manifest.R
#   writes  manuscript/main/, manuscript/supplement/
#           README.md (the block between the MANIFEST markers, only)
#
# This script reads nothing from data/ and computes nothing. It copies files
# out of output/ under manuscript-facing names, so output/ can keep names that
# describe what produced a file while the manuscript gets names that describe
# where the file appears.
#
# manuscript/ is wiped and rebuilt on every run and is not tracked by git: it
# is derived, and a tracked second copy could disagree with output/.
#
# MANIFEST is the single edit point, and it lives in R/manifest.R so the
# interactive document can read the same numbers. Moving a table between main
# and supplement, or renumbering one, is a change to `destination` there and to
# nothing else: this stage rewrites the README's manifest table from it, so the
# README cannot drift out of step.

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
source(file.path(PROJECT_ROOT, "R", "manifest.R"))

source_path <- function(relative) project_path("output", relative)
destination_path <- function(relative) file.path(MANUSCRIPT_DIR, relative)

message("Read ", nrow(MANIFEST), " files from ", project_path("output"))
missing_sources <- MANIFEST$source[!file.exists(source_path(MANIFEST$source))]
if (length(missing_sources) > 0) {
  stop(
    "Missing sources in output/: ", paste(unique(missing_sources), collapse = ", "),
    "\nRun script/02_fit_models.R, 03_sensitivity.R, 04_magnitude_comparison.R and 05_figures.R first."
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
all_tables <- list.files(TABLE_DIR, pattern = "[.]csv$")
unreferenced <- setdiff(all_tables, basename(MANIFEST$source[grepl("^tables/", MANIFEST$source)]))

# ---------------------------------------------------------------------------
# The README's manifest table, rewritten in place from MANIFEST.
#
# Only the lines BETWEEN the markers are touched; everything else in README.md
# is left exactly as it was. The markers must already exist -- this stage will
# not guess where the table belongs.
# ---------------------------------------------------------------------------
README_PATH <- project_path("README.md")
MANIFEST_BEGIN <- "<!-- MANIFEST:BEGIN"
MANIFEST_END <- "<!-- MANIFEST:END -->"

update_readme_manifest <- function() {
  lines <- readLines(README_PATH, warn = FALSE)
  begin <- grep(MANIFEST_BEGIN, lines, fixed = TRUE)
  end <- grep(MANIFEST_END, lines, fixed = TRUE)
  if (length(begin) != 1 || length(end) != 1 || end <= begin) {
    stop(
      "README.md needs exactly one '", MANIFEST_BEGIN, " ... -->' line ",
      "followed by exactly one '", MANIFEST_END, "' line. Found ",
      length(begin), " and ", length(end), "."
    )
  }
  updated <- c(
    lines[seq_len(begin)],
    "",
    manifest_markdown(),
    "",
    lines[end:length(lines)]
  )
  if (identical(updated, lines)) {
    return(FALSE)
  }
  writeLines(updated, README_PATH)
  TRUE
}

readme_changed <- update_readme_manifest()

detail_cat("\nManuscript numbering (from MANIFEST, the only place it is written):\n")
numbering <- manuscript_numbering()
for (i in seq_len(nrow(numbering))) {
  detail_cat(sprintf(
    "  %-9s %s\n    %s\n",
    paste0(if (numbering$supplement[[i]]) "supp. " else "main ",
           numbering$kind[[i]], "s"),
    if (numbering$gaps[[i]] == "none") {
      "no gaps"
    } else {
      paste0("not produced here: ", numbering$gaps[[i]])
    },
    numbering$assigned[[i]]
  ))
}

cat("\nWrote", nrow(MANIFEST), "files to", MANUSCRIPT_DIR, "\n")
cat(if (readme_changed) {
  "Rewrote the manifest table in README.md.\n"
} else {
  "README.md manifest table was already up to date.\n"
})
if (length(unreferenced) > 0) {
  detail_cat(
    "\nNOT referenced by the manifest (in output/tables/ but not copied):\n  ",
    paste(unreferenced, collapse = "\n  "), "\n"
  )
}
