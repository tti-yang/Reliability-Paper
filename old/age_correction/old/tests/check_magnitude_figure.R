# Run after stages 02 and 04: Rscript tests/check_magnitude_figure.R
PROJECT_ROOT <- local({
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  dirname(dirname(normalizePath(sub("^--file=", "", file_arg))))
})
source(file.path(PROJECT_ROOT, "R", "setup.R"))
source(file.path(PROJECT_ROOT, "R", "models.R"))
source(file.path(PROJECT_ROOT, "R", "figures.R"))

read_table <- function(name) {
  readr::read_csv(file.path(TABLE_DIR, name), num_threads = 1,
                  show_col_types = FALSE)
}
magnitude <- read_table("magnitude_comparison.csv")

expect_error <- function(expression, pattern = NULL) {
  error <- tryCatch({ force(expression); NULL }, error = identity)
  stopifnot(inherits(error, "error"))
  if (!is.null(pattern)) stopifnot(grepl(pattern, conditionMessage(error)))
}

# The figure plots the pooled rows only, but the TABLE must keep everything:
# the supplement still reports the modality-specific rows, the component
# slopes, and the signed difference. Narrowing the figure must not narrow the
# export.
stopifnot(
  setequal(magnitude$scope, c("Pooled", "Auditory", "Visual", "Motor")),
  all(c("b_reliability", "b_confusability", "signed_diff", "delta",
        "delta_ci_lo", "delta_ci_hi", "boot_p", "n_boot_ok") %in%
        names(magnitude)),
  nrow(magnitude) == length(MOTION_RULES) * 4L * length(AGE_TERMS)
)

for (rule in MOTION_RULES) {
  data <- magnitude_plot_data(magnitude, rule$label)
  original <- magnitude %>%
    filter(motion_rule == rule$label, scope == "Pooled")

  # Two rows, both age terms, between-person above within-person.
  stopifnot(
    nrow(data) == 2L,
    setequal(data$age_term, AGE_TERMS),
    data$y[data$age_term == "between_cAge"] >
      data$y[data$age_term == "within_cAge"]
  )

  # The saved bootstrap estimates are displayed, not recomputed or rounded.
  ordered <- original[match(data$age_term, original$age_term), ]
  stopifnot(
    identical(data$delta, ordered$delta),
    identical(data$conf_low, ordered$delta_ci_lo),
    identical(data$conf_high, ordered$delta_ci_hi)
  )

  # delta is the contrast of the two MAGNITUDES, whatever the component signs.
  stopifnot(all(abs(
    data$delta - (abs(ordered$b_reliability) - abs(ordered$b_confusability))
  ) < 1e-8))

  figure <- build_magnitude_figure(data)
  built <- ggplot_build(figure)

  # One series, two points, no legend, and a reference line at zero.
  points <- built$data[[3]]
  stopifnot(
    nrow(points) == 2L,
    length(unique(points$colour)) == 1L,
    identical(unique(points$colour), unname(SERIES_COLOURS[[POOLED_SERIES]])),
    identical(unique(points$shape), 22),
    built$data[[1]]$xintercept == 0,
    length(built$plot$scales$get_scales("colour")) == 0L,
    identical(figure$theme$legend.position, "none")
  )

  # Both rows sit on one x scale: that is the point of the shared axis.
  stopifnot(length(built$layout$panel_params) == 1L)
  x_range <- built$layout$panel_params[[1]]$x.range
  stopifnot(
    all(data$conf_low >= x_range[[1]]), all(data$conf_high <= x_range[[2]]),
    0 >= x_range[[1]], 0 <= x_range[[2]]
  )

  # The y axis names the two age terms, between-person first.
  stopifnot(identical(
    built$layout$panel_params[[1]]$y$get_labels(),
    unname(MAGNITUDE_AGE_LABELS[c("between_cAge", "within_cAge")])
  ))

  # The caption is written beside the figure, not drawn on it.
  stopifnot(is.null(figure$labels$caption))

  caption <- magnitude_caption(data, "Figure 9", rule$label)
  stopifnot(
    # Draw count and usable draws both reported, neither hardcoded.
    grepl(format(MAGNITUDE_BOOT_DRAWS, big.mark = ","), caption, fixed = TRUE),
    grepl(format(min(data$n_boot_ok), big.mark = ","), caption, fixed = TRUE),
    grepl("sign-free", caption, fixed = TRUE),
    # The figure number comes from the caller, i.e. from MANIFEST.
    grepl("^Figure 9\\.", caption),
    grepl(rule$label, caption, fixed = TRUE),
    # The asymmetric-interval explanation is present.
    grepl("biased upward", caption, fixed = TRUE),
    grepl("conservative", caption, fixed = TRUE),
    # Nothing from the retired version survives.
    !grepl("excess", caption, ignore.case = TRUE),
    !grepl("sign reversed", caption, ignore.case = TRUE)
  )

  # A delta that no longer matches its own components is a stale export.
  stale <- magnitude
  row <- which(stale$motion_rule == rule$label & stale$scope == "Pooled")[1]
  stale$b_reliability[row] <- stale$b_reliability[row] + .01
  expect_error(magnitude_plot_data(stale, rule$label))

  # Missing pooled rows must fail rather than silently draw fewer points.
  short <- magnitude %>%
    filter(!(motion_rule == rule$label & scope == "Pooled" &
               age_term == "within_cAge"))
  expect_error(magnitude_plot_data(short, rule$label))
}

# delta is sign-free, so a NEGATIVE reliability slope is perfectly admissible
# and must not be rejected: the retired figure's sign reasoning is gone.
flipped <- magnitude %>%
  mutate(b_reliability = -b_reliability, b_confusability = -b_confusability)
stopifnot(nrow(magnitude_plot_data(flipped, MOTION_RULES[[1]]$label)) == 2L)

# Exercise the script in a fresh project with ONLY saved plotting data/tables.
# No analysis/raw data or models are supplied, and any lmer call is fatal.
scratch <- tempfile("mind-figures-")
for (directory in c("R", "script", "data/derived", "output/tables")) {
  dir.create(file.path(scratch, directory), recursive = TRUE)
}
stopifnot(all(file.copy(list.files(project_path("R"), full.names = TRUE),
                       file.path(scratch, "R"))),
          file.copy(project_path(PROJECT_FILE), scratch),
          file.copy(project_path("script", "05_figures.R"),
                    file.path(scratch, "script")))
wrapper <- file.path(scratch, "script", "check_no_fits.R")
writeLines(c(
  "lmer <- function(...) stop('Figure stage attempted to fit a model')",
  "magnitude_contrast <- function(...) stop('Figure stage attempted a bootstrap')",
  paste0("source(", deparse(file.path(scratch, "script", "05_figures.R")), ")")
), wrapper)
log <- file.path(scratch, "check.log")
status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(wrapper),
                   stdout = log, stderr = log)
stopifnot(status != 0L,
          any(grepl("Run script/04_magnitude_comparison.R first", readLines(log))))
tables <- c(
  "magnitude_comparison.csv", "model_estimates.csv",
  paste0(rep(vapply(MOTION_RULES, `[[`, character(1), "prefix"), each = 2),
         c("_simple_slopes.csv", "_interaction_tests.csv"))
)
stopifnot(all(file.copy(file.path(TABLE_DIR, tables),
                       file.path(scratch, "output", "tables"))),
          file.copy(project_path("data", "derived", "figure_data_by_rule.rds"),
                    file.path(scratch, "data", "derived")))
status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(wrapper),
                   stdout = log, stderr = log)
if (status != 0L) stop(paste(readLines(log), collapse = "\n"))
exports <- list.files(file.path(scratch, "output", "figures"),
                      pattern = "[.](pdf|png)$")
captions <- list.files(file.path(scratch, "output", "figures"),
                       pattern = "_caption[.]txt$")
stopifnot(
  length(exports) == 8L,
  # The retired within-person magnitude figure is no longer written.
  !any(grepl("^figure_s3_", exports)),
  # One caption file per figure, beside the exports.
  length(captions) == 4L,
  setequal(captions, paste0(sub("[.](pdf|png)$", "", unique(exports)),
                            "_caption.txt"))
)
message("Magnitude-figure checks passed: pooled-only content, saved intervals ",
        "displayed unchanged, shared x scale, no legend, sign-free contrast, ",
        "the caption written beside the figure, the full table preserved, and ",
        "all 8 exports plus 4 captions without fits.")
