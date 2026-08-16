# Packages, project paths, and the constants every stage shares.
#
# Sourced first by all five scripts and by the interactive document, so the
# search path is identical everywhere. The library() order is load-bearing:
# shiny and tidyverse mask each other in places, and the numbers in output/
# were produced under this order.

required_packages <- c(
  "here", "shiny", "tidyverse", "lme4", "lmerTest", "patchwork",
  "flextable", "emmeans", "ggh4x"
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

# ---------------------------------------------------------------------------
# Paths.
#
# here() resolves against MiND-Reliability.Rproj at the repository root, so
# every path below is correct no matter which directory R was started in and
# nothing has to be edited after a clone.
# ---------------------------------------------------------------------------
RAW_DATA_DIR <- here("data", "raw")
DERIVED_DATA_DIR <- here("data", "derived")
TABLE_DIR <- here("output", "tables")
FIGURE_DIR <- here("output", "figures")
MANUSCRIPT_DIR <- here("manuscript")

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
