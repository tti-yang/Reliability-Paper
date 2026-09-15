# Run after stages 02 and 04: Rscript tests/check_figure4.R
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
pooled <- read_table("model_estimates.csv")
for (rule in MOTION_RULES) {
  modality <- read_table(paste0(rule$prefix, "_simple_slopes.csv"))
  data <- figure4_plot_data(magnitude, pooled, modality, rule$label)
  main <- build_figure4(data)
  supplement <- build_figure_s3(data)
  delta <- data %>% filter(measure == "Delta")
  original <- magnitude %>% filter(motion_rule == rule$label)
  stopifnot(identical(delta$estimate, original$delta),
            identical(delta$conf_low, original$delta_ci_lo),
            identical(delta$conf_high, original$delta_ci_hi))

  # Negating a confidence interval swaps the endpoints, not just their signs.
  expected <- bind_rows(
    pooled %>% filter(motion_rule == rule$label, outcome == "Distinctiveness",
                      term %in% AGE_TERMS) %>%
      transmute(scope = "Pooled", age_term = term,
                lo = -(estimate + qt(.975, df) * se),
                hi = -(estimate - qt(.975, df) * se), estimate = -estimate),
    modality %>% filter(outcome == "Distinctiveness") %>%
      transmute(scope = modality, age_term, estimate = -slope,
                lo = -upper.CL, hi = -lower.CL)
  )
  comparison <- data %>% filter(measure == "Distinctiveness") %>%
    left_join(expected, by = c("scope", "age_term"), suffix = c("", "_expected"))
  stopifnot(all(abs(comparison$estimate - comparison$estimate_expected) < 1e-12),
            all(abs(comparison$conf_low - comparison$lo) < 1e-12),
            all(abs(comparison$conf_high - comparison$hi) < 1e-12))

  for (age in AGE_TERMS) {
    plot <- if (age == "between_cAge") main else supplement
    stopifnot(inherits(plot, "patchwork"), length(plot) == 2L,
              identical(plot[[1]]$labels$x, paste(
                if (age == "between_cAge") "Between-person" else "Within-person",
                "age slope (per year)"
              )),
              all(diff(unname(FIGURE4_SCOPE_POSITIONS)) == -1))
    for (i in seq_len(2)) {
      stopifnot(all(plot[[i]]$data$age_term == age))
      panel <- ggplot_build(plot[[i]])
      points <- panel$data[[5]]
      x_axis <- panel$layout$panel_params[[1]]$x
      ticks <- x_axis$get_breaks()
      finite <- is.finite(ticks)
      stopifnot(all(abs(as.numeric(x_axis$get_labels()[finite]) - ticks[finite]) < 1e-8),
                nrow(points) == 8L,
                identical(panel$layout$panel_params[[1]]$y$get_labels(), FIGURE4_SCOPES),
                all(points$x >= x_axis$continuous_range[1]),
                all(points$x <= x_axis$continuous_range[2]))
    }
    stopifnot(identical(
      ggplot_build(plot[[1]])$layout$panel_params[[1]]$x.range,
      ggplot_build(plot[[2]])$layout$panel_params[[1]]$x.range
    ))
    right <- ggplot_build(plot[[2]])
    connectors <- right$data[[3]]
    endpoints <- plot[[2]]$data %>%
      select(scope, measure, estimate, y) %>%
      pivot_wider(names_from = measure, values_from = c(estimate, y))
    stopifnot(nrow(connectors) == 4L,
              all(abs(connectors$x - endpoints$estimate_Distinctiveness) < 1e-12),
              all(abs(connectors$xend - endpoints$estimate_Delta) < 1e-12),
              all(abs(connectors$y - endpoints$y_Distinctiveness) < 1e-12),
              all(abs(connectors$yend - endpoints$y_Delta) < 1e-12),
              setequal(right$data[[4]]$linetype, c("solid", "22")),
              setequal(right$data[[5]]$shape, c(23, 15)),
              setequal(ggplot_build(plot[[1]])$data[[5]]$shape, c(16, 17)))
  }
  stopifnot(!identical(
    ggplot_build(main[[1]])$layout$panel_params[[1]]$x.range,
    ggplot_build(supplement[[1]])$layout$panel_params[[1]]$x.range
  ))

  # A stale component estimate cannot silently borrow a different model's CI.
  bad <- magnitude
  bad$b_reliability[1] <- bad$b_reliability[1] + .01
  if (rule$key == "primary") {
    error <- tryCatch({
      figure4_plot_data(bad, pooled, modality, rule$label)
      NULL
    }, error = identity)
    stopifnot(inherits(error, "error"))
  }
}

# Exercise the script in a fresh project with ONLY saved plotting data/tables.
# No analysis/raw data or models are supplied, and any lmer call is fatal.
scratch <- tempfile("mind-figure4-")
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
tables <- c("magnitude_comparison.csv", "model_estimates.csv",
            "fd04_pct10_simple_slopes.csv", "fd05_pct20_simple_slopes.csv")
stopifnot(all(file.copy(file.path(TABLE_DIR, tables),
                       file.path(scratch, "output", "tables"))),
          file.copy(project_path("data", "derived", "figure_data_by_rule.rds"),
                    file.path(scratch, "data", "derived")))
status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(wrapper),
                   stdout = log, stderr = log)
if (status != 0L) stop(paste(readLines(log), collapse = "\n"))
stopifnot(length(list.files(file.path(scratch, "output", "figures"),
                            pattern = "[.](pdf|png)$")) == 16L)
message("Figure 4 checks passed: saved intervals, panel ordering/scales, stale ",
        "estimates, missing-bootstrap error, and all 16 exports without fits.")
