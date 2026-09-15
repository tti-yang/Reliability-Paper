# 05 - Manuscript figures 2-4 and within-person Figure S3 under both rules.
#
#   reads   data/derived/figure_data_by_rule.rds
#           output/tables/magnitude_comparison.csv, model_estimates.csv,
#           {rule}_simple_slopes.csv
#   writes  output/figures/figure2_fd04_pct10.{pdf,png}
#           output/figures/figure3_fd04_pct10.{pdf,png}
#           output/figures/figure2_fd05_pct20.{pdf,png}
#           output/figures/figure3_fd05_pct20.{pdf,png}
#           output/figures/figure4_fd04_pct10.{pdf,png}
#           output/figures/figure4_fd05_pct20.{pdf,png}
#           output/figures/figure_s3_fd04_pct10.{pdf,png}
#           output/figures/figure_s3_fd05_pct20.{pdf,png}
#
# The motion rule is in the filename rather than in a supplement/ subdirectory,
# so the two rules cannot be confused for each other. All model predictions
# and intervals were computed in 02/04; this stage never fits models or runs
# the bootstrap.

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
source(file.path(PROJECT_ROOT, "R", "figures.R"))

# Check the bootstrap handoff before doing any figure work.
magnitude_path <- file.path(TABLE_DIR, "magnitude_comparison.csv")
if (!file.exists(magnitude_path)) {
  stop("Missing ", magnitude_path,
       ". Run script/04_magnitude_comparison.R first.")
}
magnitude_estimates <- readr::read_csv(
  magnitude_path, num_threads = 1, show_col_types = FALSE
)
figure_data_by_rule <- read_derived("figure_data_by_rule")

read_figure_table <- function(filename) {
  path <- file.path(TABLE_DIR, filename)
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run script/02_fit_models.R first.")
  }
  readr::read_csv(path, num_threads = 1, show_col_types = FALSE)
}
pooled_estimates <- read_figure_table("model_estimates.csv")

manuscript_figures <- lapply(MOTION_RULES, function(rule) {
  rule_data <- figure_data_by_rule[[rule$key]]
  figure2_data <- rule_data$figure2
  figure3_data <- rule_data$figure3

  figure2_plot <- build_figure2(figure2_data)
  figure3_plot <- build_figure3(figure3_data)
  figure4_data <- figure4_plot_data(
    magnitude_estimates, pooled_estimates,
    read_figure_table(paste0(rule$prefix, "_simple_slopes.csv")), rule$label
  )
  figure4_plot <- build_figure4(figure4_data)
  figure_s3_plot <- build_figure_s3(figure4_data)

  # The checks run on the ggplot, before it is turned into a gtable: the layout
  # checks need ggplot_build(), which a gtable no longer supports. Nothing is
  # written until they pass; they stop() on failure.
  figure2_layout <- verify_manuscript_figure(figure2_plot, figure2_data$points)
  figure3_layout <- verify_manuscript_figure(figure3_plot, figure3_data$points)

  # Figures 2-3 are saved as gtables with dividers; Figure 4 is a patchwork.
  list(
    figure2 = add_average_divider(figure2_plot),
    figure3 = add_average_divider(figure3_plot),
    figure4 = figure4_plot,
    figure_s3 = figure_s3_plot,
    figure2_layout = figure2_layout,
    figure3_layout = figure3_layout,
    figure2_average = rule_data$figure2_average,
    figure3_average = rule_data$figure3_average
  )
})
names(manuscript_figures) <- rule_keys()

saved_figure_files <- character()
for (rule in MOTION_RULES) {
  figures <- manuscript_figures[[rule$key]]

  message("\n", rule$label)
  print_average_check(figures$figure2_average)
  print_average_check(figures$figure3_average)

  saved_figure_files <- c(
    saved_figure_files,
    save_manuscript_figure(
      figures$figure2, FIGURE_DIR, paste0("figure2_", rule$prefix)
    ),
    save_manuscript_figure(
      figures$figure3, FIGURE_DIR, paste0("figure3_", rule$prefix)
    ),
    save_manuscript_figure(
      figures$figure4, FIGURE_DIR, paste0("figure4_", rule$prefix),
      height_mm = FIGURE4_HEIGHT_MM
    ),
    save_manuscript_figure(
      figures$figure_s3, FIGURE_DIR, paste0("figure_s3_", rule$prefix),
      height_mm = FIGURE4_HEIGHT_MM
    )
  )
}

message("\nWrote:\n  ", paste(saved_figure_files, collapse = "\n  "))
