# 04 - Manuscript figures 2 and 3 under both motion rules.
#
#   reads   data/derived/analysis_data_by_rule.rds
#   writes  output/figures/figure2_fd04_pct10.{pdf,png}
#           output/figures/figure3_fd04_pct10.{pdf,png}
#           output/figures/figure2_fd05_pct20.{pdf,png}
#           output/figures/figure3_fd05_pct20.{pdf,png}
#
# The motion rule is in the filename rather than in a supplement/ subdirectory,
# so the two rules cannot be confused for each other. The models are refit here
# rather than carried over from 02: lmer is deterministic on identical rows, so
# this is the same fit, and it keeps the stages independent.

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

analysis_data_by_rule <- read_derived("analysis_data_by_rule")

manuscript_figures <- lapply(MOTION_RULES, function(rule) {
  rule_data <- analysis_data_by_rule[[rule$key]]
  rule_models <- fit_outcome_models(rule_data)
  rule_interaction_models <- fit_interaction_models(rule_data)

  figure2_data <- figure2_plot_data(
    rule_data, rule_models, rule_interaction_models
  )
  figure3_data <- figure3_plot_data(
    rule_data, rule_models, rule_interaction_models
  )

  figure2_plot <- build_figure2(figure2_data)
  figure3_plot <- build_figure3(figure3_data)

  # The checks run on the ggplot, before it is turned into a gtable: the layout
  # checks need ggplot_build(), which a gtable no longer supports. Nothing is
  # written until they pass; they stop() on failure.
  figure2_layout <- verify_manuscript_figure(figure2_plot, figure2_data$points)
  figure3_layout <- verify_manuscript_figure(figure3_plot, figure3_data$points)

  # The saved figures are the gtables, divider included.
  list(
    figure2 = add_average_divider(figure2_plot),
    figure3 = add_average_divider(figure3_plot),
    figure2_layout = figure2_layout,
    figure3_layout = figure3_layout,
    figure2_average = figure2_average_check(rule_data, figure2_data$points),
    figure3_average = figure3_average_check(rule_data, figure3_data$points)
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
    )
  )
}

message("\nWrote:\n  ", paste(saved_figure_files, collapse = "\n  "))
