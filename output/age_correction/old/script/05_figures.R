# 05 - The manuscript figures, under both motion rules.
#
#   reads   data/derived/figure_data_by_rule.rds
#           output/tables/magnitude_comparison.csv, model_estimates.csv,
#           {rule}_simple_slopes.csv, {rule}_interaction_tests.csv
#   writes  output/figures/figure2_{rule}.{pdf,png}   combined age effects
#           output/figures/figure3_{rule}.{pdf,png}   pooled magnitude contrast
#           output/figures/figure{2,3}_{rule}_caption.txt
#
# Captions are written beside the figures rather than drawn on them. The figure
# number in a caption comes from MANIFEST, like every other number.
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
source(file.path(PROJECT_ROOT, "R", "manifest.R"))

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
message("Read ", DERIVED_FILES[["figure_data_by_rule"]],
        " and the stage-02/04 estimate tables")

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

  combined_lines <- combined_plot_data(figure2_data, figure3_data)
  combined_plot <- build_combined_figure(
    combined_lines, combined_pooled_slopes(pooled_estimates, rule$label),
    centred = COMBINED_CENTRED
  )

  magnitude_data <- magnitude_plot_data(magnitude_estimates, rule$label)

  # The check runs on the ggplot, before it is turned into a gtable: it needs
  # ggplot_build(), which a gtable no longer supports. Nothing is written until
  # it passes; it stop()s on failure.
  combined_layout <- verify_combined_figure(combined_plot, combined_lines)
  # Every modality line drawn, in both columns, is the emtrends simple slope
  # the tables report.
  verify_modality_slopes(
    combined_lines, read_figure_table(paste0(rule$prefix, "_simple_slopes.csv")),
    rule$label
  )

  # The combined figure is saved as a gtable, because its two columns need one
  # x title each; the magnitude figures are patchworks.
  combined_name <- paste0("figure2_", rule$prefix)
  magnitude_name <- paste0("figure3_", rule$prefix)

  list(
    combined = add_column_axis_titles(combined_plot),
    magnitude = build_magnitude_figure(magnitude_data),
    combined_name = combined_name,
    magnitude_name = magnitude_name,
    combined_caption = combined_caption(
      manuscript_label(paste0("figures/", combined_name, ".png")), rule$label,
      read_figure_table(paste0(rule$prefix, "_interaction_tests.csv"))
    ),
    magnitude_caption = magnitude_caption(
      magnitude_data,
      manuscript_label(paste0("figures/", magnitude_name, ".png")), rule$label
    ),
    combined_layout = combined_layout,
    figure2_average = rule_data$figure2_average,
    figure3_average = rule_data$figure3_average
  )
})
names(manuscript_figures) <- rule_keys()

saved_figure_files <- character()
for (rule in MOTION_RULES) {
  figures <- manuscript_figures[[rule$key]]

  detail("\n", rule$label)
  if (MIND_VERBOSE) {
    print_average_check(figures$figure2_average)
    print_average_check(figures$figure3_average)
  }

  saved_figure_files <- c(
    saved_figure_files,
    save_manuscript_figure(
      figures$combined, FIGURE_DIR, figures$combined_name,
      height_mm = COMBINED_HEIGHT_MM, width_mm = COMBINED_WIDTH_MM
    ),
    write_figure_caption(
      figures$combined_caption, FIGURE_DIR, figures$combined_name
    ),
    save_manuscript_figure(
      figures$magnitude, FIGURE_DIR, figures$magnitude_name,
      height_mm = MAGNITUDE_HEIGHT_MM, width_mm = MAGNITUDE_WIDTH_MM
    ),
    write_figure_caption(
      figures$magnitude_caption, FIGURE_DIR, figures$magnitude_name
    )
  )
}

message("\nWrote:\n  ", paste(saved_figure_files, collapse = "\n  "))
