# Packages, project paths, and the constants every stage shares.
#
# Sourced first by all six scripts and by the interactive document, so the
# search path is identical everywhere. The library() order is load-bearing:
# shiny and tidyverse mask each other in places, and the numbers in output/
# were produced under this order.

required_packages <- c(
  "here", "shiny", "tidyverse", "lme4", "lmerTest", "patchwork",
  "flextable", "emmeans", "ggh4x", "parallel"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Install these packages before running the pipeline: ",
    paste(missing_packages, collapse = ", ")
  )
}

suppressPackageStartupMessages({
  library(here)
  library(shiny)
  library(tidyverse)
  library(lme4)
  library(lmerTest)
  library(patchwork)
  library(flextable)
  library(emmeans)
  library(ggh4x)
  # The manuscript figures finish with a gtable edit (the divider beside the
  # average column), which needs grid's grob constructors and unit arithmetic.
  library(grid)
})

# ---------------------------------------------------------------------------
# Console verbosity.
#
# By default each numbered script prints what it read, what it wrote, and
# nothing else. MIND_VERBOSE=1 adds the per-row diagnostics, intermediate
# counts, and sanity checks that are useful when something looks wrong and are
# noise the rest of the time.
#
#   MIND_VERBOSE=1 Rscript script/02_fit_models.R
#
# Assertions are deliberately NOT routed through this: stop() and warning()
# fire either way, so a quiet run is a run where nothing went wrong.
# ---------------------------------------------------------------------------
MIND_VERBOSE <- local({
  requested <- tolower(trimws(Sys.getenv("MIND_VERBOSE", "0")))
  if (!requested %in% c("0", "1")) {
    stop(
      "MIND_VERBOSE must be 0 or 1; got '", Sys.getenv("MIND_VERBOSE"), "'."
    )
  }
  requested == "1"
})

# Diagnostic output. Silent unless MIND_VERBOSE=1.
detail <- function(...) if (MIND_VERBOSE) message(...)

# The same, for diagnostics produced by print() or cat() rather than message().
detail_print <- function(x, ...) if (MIND_VERBOSE) print(x, ...)
detail_cat <- function(...) if (MIND_VERBOSE) cat(...)

# ---------------------------------------------------------------------------
# Whether the combined figure plots model-implied CHANGE from a reference
# (the default) or fitted values on the raw outcome scale.
#
#   MIND_CENTRED=0 Rscript script/05_figures.R
#
# build_combined_figure(lines, centred = FALSE) is the same switch for a single
# call, which is the one to reach for when comparing the two versions without
# overwriting output/figures/.
# ---------------------------------------------------------------------------
COMBINED_CENTRED <- local({
  requested <- tolower(trimws(Sys.getenv("MIND_CENTRED", "1")))
  if (!requested %in% c("0", "1")) {
    stop("MIND_CENTRED must be 0 or 1; got '", Sys.getenv("MIND_CENTRED"), "'.")
  }
  requested == "1"
})

# ---------------------------------------------------------------------------
# Paths.
#
# Every path below is derived from PROJECT_ROOT, so nothing has to be edited
# after a clone and there are no absolute paths anywhere in the repository.
#
# PROJECT_ROOT is set by the calling script from its own file location, before
# this file is sourced -- see the four-line header of any of script/01-06.
# here() cannot do that job on its own: it searches upward from the *working
# directory*, so `Rscript /path/to/repo/script/01_prepare_data.R` launched from
# somewhere else anchors on that somewhere else and silently resolves every
# path to the wrong place. here::i_am() has the same limitation; it at least
# errors instead of guessing.
#
# When PROJECT_ROOT is not already set -- the interactive document, or a
# console session -- here() is the right answer, because the working directory
# is then inside the project by construction. The check below turns a wrong
# root into an immediate error either way.
# ---------------------------------------------------------------------------
PROJECT_FILE <- "MiND-Reliability.Rproj"

if (!exists("PROJECT_ROOT")) {
  PROJECT_ROOT <- here()
}
PROJECT_ROOT <- normalizePath(PROJECT_ROOT, mustWork = TRUE)

if (!file.exists(file.path(PROJECT_ROOT, PROJECT_FILE))) {
  stop(
    "Project root resolved to '", PROJECT_ROOT, "', which does not contain ",
    PROJECT_FILE, ". Run the scripts with Rscript, or open the project first."
  )
}

RAW_DATA_DIR <- file.path(PROJECT_ROOT, "data", "raw")
DERIVED_DATA_DIR <- file.path(PROJECT_ROOT, "data", "derived")
TABLE_DIR <- file.path(PROJECT_ROOT, "output", "tables")
FIGURE_DIR <- file.path(PROJECT_ROOT, "output", "figures")
MANUSCRIPT_DIR <- file.path(PROJECT_ROOT, "manuscript")

project_path <- function(...) file.path(PROJECT_ROOT, ...)

# ---------------------------------------------------------------------------
# Analysis constants.
# ---------------------------------------------------------------------------
# Waves 1 and 2 only. The exploratory three-wave MIND-C analysis has been
# removed from the manuscript and its supplement, so Wave 3 never enters the
# pipeline.
ANALYSIS_WAVES <- c(1, 2)
OUTCOMES <- c("Reliability", "Confusability", "Distinctiveness")
MODEL_TERMS <- c(
  "within_cAge", "between_cAge", "Sex_M1", "Education",
  "aud_mot", "aud_vis"
)
OLDER_ADULT_AGE <- 65
MAD_THRESHOLD <- 3
MAGNITUDE_BOOT_SEED <- 20260910L
# Nominal bootstrap draws. Stage 04 takes this as the default for MIND_BOOT_B,
# and the magnitude figure's caption reports it, so the number is written once.
MAGNITUDE_BOOT_DRAWS <- 5000L

# The two rules the manuscript reports. `prefix` is used for rule-specific
# export filenames.
MOTION_RULES <- list(
  list(
    key = "primary",
    fd_cutoff = "0.4",
    pct_cutoff = 10,
    label = "FD 0.4 mm / 10% (primary)",
    prefix = "fd04_pct10"
  ),
  list(
    key = "liberal",
    fd_cutoff = "0.5",
    pct_cutoff = 20,
    label = "FD 0.5 mm / 20% (liberal)",
    prefix = "fd05_pct20"
  )
)

rule_keys <- function() {
  vapply(MOTION_RULES, `[[`, character(1), "key")
}

format_p <- function(p) {
  if_else(
    is.na(p),
    NA_character_,
    if_else(p < .001, "< .001", sprintf("%.3f", p))
  )
}

rule_text <- function(fd_cutoff, pct_cutoff) {
  paste0(
    "FD ≥ ", fd_cutoff, " mm; run excluded at ≥ ",
    pct_cutoff, "% excluded TRs"
  )
}
