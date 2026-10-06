# The manuscript figures.
#
# Two figures are built here:
#
#   the combined age-effect figure -- one 3 x 2 grid, outcome by row and age
#   term by column, with a pooled and three modality-specific fitted lines in
#   every panel; and
#
#   the magnitude-contrast figure, in a between-person and a within-person
#   variant sharing one layout.
#
# Colour means MODALITY in both, from one palette defined once below, so a
# series keeps its colour across the whole figure set.

# The data keeps the short level name "Average" for the pooled series -- the
# checks and the filters key on it -- and it is relabelled POOLED_SERIES on the
# figure, which describes the aggregate rather than suggesting a location.
MEASURES <- OUTCOMES
AVERAGE_COLUMN <- "Average"
MODALITY_COLUMNS <- c(AVERAGE_COLUMN, "Auditory", "Visual", "Motor")

# Rows of the combined figure, top to bottom. This is the Results order and is
# deliberately NOT the order of OUTCOMES; do not sort it.
COMBINED_MEASURE_LEVELS <- c("Distinctiveness", "Reliability", "Confusability")

# Columns of the combined figure, left to right.
COMBINED_COLUMNS <- c("Between-person", "Within-person")

# ---------------------------------------------------------------------------
# The one palette. Colour encodes modality and nothing else, in the combined
# figure and in the magnitude figure alike.
#
# The pooled series takes a dark neutral rather than a hue, so it reads as the
# primary estimate and not as a fourth modality; the three modalities are
# Okabe-Ito hues, which stay distinguishable under the common forms of colour
# blindness and in greyscale.
# ---------------------------------------------------------------------------
POOLED_SERIES <- "All modalities"
SERIES_LEVELS <- c(POOLED_SERIES, "Auditory", "Visual", "Motor")
SERIES_COLOURS <- c(
  "All modalities" = "#1A1A1A",  # near-black
  Auditory         = "#0072B2",  # Okabe-Ito blue
  Visual           = "#D55E00",  # Okabe-Ito vermillion
  Motor            = "#009E73"   # Okabe-Ito bluish green
)

MEASURE_STRIP_LABELS <- c(
  Reliability = "Neural reliability",
  Confusability = "Neural confusability",
  Distinctiveness = "Neural distinctiveness"
)

# The reference each column is centred on. Age 65 matches the model centring
# (OLDER_ADULT_AGE, the origin of between_cAge); year 0 is each participant's
# own first retained wave.
COMBINED_REFERENCES <- c(
  "Between-person" = OLDER_ADULT_AGE,
  "Within-person" = 0
)
CENTRED_ZERO_LINE_COLOUR <- "grey85"
CENTRED_ZERO_LINE_WIDTH <- 0.3

# The pooled line is drawn markedly thicker than the three modality lines, so
# the primary estimate is legible where all four overlap.
COMBINED_POOLED_WIDTH <- 1.15
COMBINED_MODALITY_WIDTH <- 0.5
COMBINED_GAP_WIDTH_SCALE <- 0.8   # dashed spans, slightly lighter than solid
# The pooled line is thick, and ggplot scales a dash pattern with linewidth, so
# "dashed" there reads as a row of long bars. It gets a tighter pattern of its
# own; the thinner modality lines keep the default.
COMBINED_POOLED_DASH <- "22"

# Colored modality slopes are descriptive only in both columns.
# Within-person lines are subordinated -- thinner and semi-transparent,
# and without ribbons. The between-person column is unaffected.
COMBINED_WITHIN_MODALITY_WIDTH <- 0.35
COMBINED_WITHIN_MODALITY_ALPHA <- 0.5

# Only the pooled line carries a ribbon: four overlapping ribbons per panel is
# unreadable.
COMBINED_RIBBON_ALPHA <- 0.18

POINT_STROKE <- 0.35

# Ages and follow-up intervals are recorded in whole years, so points would
# otherwise stack into vertical stripes. Jitter is horizontal only - the
# outcome is never displaced - and is seeded so every figure and every rebuild
# places the same point in the same place.
JITTER_SEED <- 1
FIGURE3_JITTER_WIDTH <- 0.15

AGE_AXIS_LABEL <- "Age (years)"
WITHIN_TIME_LABEL <- "Years from first wave"
WITHIN_TIME_BREAKS <- c(0, 2, 4, 6)

FIGURE_WIDTH_MM <- 180
FIGURE_HEIGHT_MM <- 150
FIGURE_DPI <- 300
GRID_POINTS <- 100

# Portrait, and wide enough that six panels stay legible at a two-column
# journal width (180 mm); each panel is then about 62 x 52 mm.
COMBINED_WIDTH_MM <- 140
COMBINED_HEIGHT_MM <- 185



manuscript_theme <- function(base_size = 9) {
  theme_classic(base_size = base_size) +
    theme(
      panel.grid = element_blank(),
      axis.text = element_text(colour = "black"),
      axis.title = element_text(colour = "black"),
      axis.line = element_line(colour = "black", linewidth = 0.3),
      axis.ticks = element_line(colour = "black", linewidth = 0.3),
      # Plain strip text at the axis-title size: the strips are labels, not
      # headings.
      strip.background = element_blank(),
      strip.placement = "outside",
      strip.text = element_text(face = "plain", size = rel(1), colour = "black"),
      legend.position = "none",
      legend.key.height = unit(9, "pt"),
      legend.margin = margin(t = 1, b = 0),
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      plot.tag = element_text(face = "bold", size = 11),
      plot.margin = margin(3, 5, 3, 3)
    )
}

# predict.merMod gives no standard errors, so the fixed-effect prediction and
# its Wald CI are computed from the design matrix and the fixed-effect vcov.
# `contrasts_option` must match the contrasts the model was fitted under.
fixed_effect_predictions <- function(model, newdata, contrasts_option = NULL) {
  if (!is.null(contrasts_option)) {
    previous_contrasts <- options(contrasts = contrasts_option)
    on.exit(options(previous_contrasts), add = TRUE)
  }

  design <- model.matrix(
    delete.response(terms(model, fixed.only = TRUE)),
    data = newdata
  )
  design <- design[, names(fixef(model)), drop = FALSE]

  fitted_values <- as.vector(design %*% fixef(model))
  standard_errors <- sqrt(
    rowSums((design %*% as.matrix(vcov(model))) * design)
  )
  critical_value <- qnorm(0.975)

  newdata %>%
    mutate(
      predicted = fitted_values,
      se = standard_errors,
      conf_low = fitted_values - critical_value * standard_errors,
      conf_high = fitted_values + critical_value * standard_errors
    )
}

complete_outcome_data <- function(data, outcome) {
  data %>% drop_na(all_of(c(outcome, MODEL_TERMS, "SubNum")))
}

# Both figures are drawn from one long frame with the same six columns, so the
# row order, the column order, and the column names are set in exactly one
# place and the two figures cannot drift apart.
as_plot_frame <- function(frame) {
  frame %>%
    transmute(
      participant,
      session,
      x,
      measure = factor(measure, levels = MEASURES),
      modality = factor(modality, levels = MODALITY_COLUMNS),
      value
    )
}

# Model lines carry the same measure/modality keys plus the grouping the
# solid/dashed split needs. line_group keeps each panel's ribbon and dashed
# span in one piece; solid_group splits the solid line at the unsampled gap.
as_line_frame <- function(frame) {
  frame %>%
    mutate(
      measure = factor(measure, levels = MEASURES),
      modality = factor(modality, levels = MODALITY_COLUMNS),
      line_group = paste(measure, modality),
      solid_group = paste(measure, modality, solid_segment)
    )
}

typical_covariates <- function(data) {
  list(
    Sex_M1 = median(data$Sex_M1, na.rm = TRUE),
    Education = median(data$Education, na.rm = TRUE)
  )
}

# No one was scanned between the young and older cohorts, so the age axis has
# an unsampled interval. The model line is drawn solid where there are data and
# dashed across the gap; the ribbon stays continuous. Ranges come from the data
# of that panel. `gap_span` includes both boundary points so the dashed span
# meets the solid spans exactly.
mark_age_gap <- function(grid_x, observed_ages) {
  young_ages <- observed_ages[observed_ages < OLDER_ADULT_AGE]
  older_ages <- observed_ages[observed_ages >= OLDER_ADULT_AGE]

  if (length(young_ages) == 0 || length(older_ages) == 0) {
    return(tibble(
      x = grid_x,
      solid_segment = "all",
      gap_span = FALSE
    ))
  }

  young_max <- max(young_ages, na.rm = TRUE)
  older_min <- min(older_ages, na.rm = TRUE)

  tibble(
    x = grid_x,
    solid_segment = case_when(
      grid_x <= young_max ~ "young",
      grid_x >= older_min ~ "older",
      TRUE ~ NA_character_
    ),
    gap_span = grid_x >= young_max & grid_x <= older_min
  )
}

# Figure 3 has no unsampled interval, so every point of the line is solid.
mark_no_gap <- function(grid_x) {
  tibble(x = grid_x, solid_segment = "all", gap_span = FALSE)
}

# One jitter offset per participant, applied to every observation that
# participant contributes, so both endpoints of a segment move together and the
# segment still meets its own points.
jitter_participant_x <- function(data, width, seed = JITTER_SEED) {
  participant_ids <- sort(unique(data$participant))
  offsets <- with_seeded_rng(seed, runif(length(participant_ids), -width, width))
  names(offsets) <- as.character(participant_ids)

  data %>%
    mutate(x = x + unname(offsets[as.character(participant)]))
}

# set.seed() inside a helper would leak into the caller's RNG state; this
# restores whatever stream was in use.
with_seeded_rng <- function(seed, expression) {
  if (exists(".Random.seed", envir = globalenv())) {
    previous_seed <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", previous_seed, envir = globalenv()), add = TRUE)
  }
  set.seed(seed)
  expression
}

# ---------------------------------------------------------------------------
# Figure 2: between-person age effects.
#
# The Average column is the former panel A, unchanged: the same participant
# means across modalities and waves, and the same pooled main-effect model line
# with its 95% CI ribbon. The three modality columns are the former panel B,
# unchanged: session x modality observations with the slopes implied by the
# interaction model.
# ---------------------------------------------------------------------------
figure2_average_points <- function(data) {
  map_dfr(MEASURES, function(measure_name) {
    complete_outcome_data(data, measure_name) %>%
      group_by(SubNum) %>%
      summarise(
        x = mean(Age_DuringParticipation_, na.rm = TRUE),
        value = mean(.data[[measure_name]], na.rm = TRUE),
        .groups = "drop"
      ) %>%
      transmute(
        participant = SubNum,
        # These points pool over waves as well as modalities, so they belong to
        # a participant rather than to any one session.
        session = NA_real_,
        x,
        measure = measure_name,
        modality = "Average",
        value
      )
  })
}

figure2_average_lines <- function(data, models) {
  map_dfr(MEASURES, function(measure_name) {
    column_data <- complete_outcome_data(data, measure_name)
    covariates <- typical_covariates(column_data)

    age_grid <- seq(
      min(column_data$Age_DuringParticipation_, na.rm = TRUE),
      max(column_data$Age_DuringParticipation_, na.rm = TRUE),
      length.out = GRID_POINTS
    )
    prediction_grid <- mark_age_gap(
      age_grid, column_data$Age_DuringParticipation_
    ) %>%
      mutate(
        between_cAge = x - OLDER_ADULT_AGE,
        within_cAge = 0,
        Sex_M1 = covariates$Sex_M1,
        Education = covariates$Education,
        # Effect-coded contrasts at zero: the average of the three modalities.
        aud_mot = 0,
        aud_vis = 0
      )

    fixed_effect_predictions(models[[measure_name]], prediction_grid) %>%
      mutate(measure = measure_name, modality = "Average")
  })
}

figure2_modality_points <- function(data) {
  map_dfr(MEASURES, function(measure_name) {
    prepare_interaction_data(complete_outcome_data(data, measure_name)) %>%
      transmute(
        participant = SubNum,
        session = Wave_Num,
        x = Age_DuringParticipation_,
        measure = measure_name,
        modality = as.character(Modality),
        value = .data[[measure_name]]
      )
  })
}

figure2_modality_lines <- function(data, visualization_models) {
  map_dfr(MEASURES, function(measure_name) {
    column_data <- prepare_interaction_data(
      complete_outcome_data(data, measure_name)
    )
    covariates <- typical_covariates(column_data)

    prediction_grid <- column_data %>%
      group_by(Modality) %>%
      group_modify(~ mark_age_gap(
        seq(
          min(.x$Age_DuringParticipation_, na.rm = TRUE),
          max(.x$Age_DuringParticipation_, na.rm = TRUE),
          length.out = GRID_POINTS
        ),
        .x$Age_DuringParticipation_
      )) %>%
      ungroup() %>%
      mutate(
        between_cAge = x - OLDER_ADULT_AGE,
        within_cAge = 0,
        Sex_M1 = covariates$Sex_M1,
        Education = covariates$Education
      )

    # Modality stays a factor with the interaction model's own levels until the
    # design matrix has been built; only then does it become a plotting column.
    fixed_effect_predictions(
      visualization_models[[measure_name]],
      prediction_grid,
      contrasts_option = INTERACTION_CONTRASTS
    ) %>%
      mutate(measure = measure_name, modality = as.character(Modality))
  })
}

figure2_plot_data <- function(data, models, visualization_models) {
  list(
    points = bind_rows(
      figure2_average_points(data),
      figure2_modality_points(data)
    ) %>%
      as_plot_frame(),
    lines = bind_rows(
      figure2_average_lines(data, models),
      figure2_modality_lines(data, visualization_models)
    ) %>%
      as_line_frame()
  )
}

# ---------------------------------------------------------------------------
# Figure 3: within-person age effects, on time since each participant's own
# first retained wave so every trajectory starts at zero.
#
# within_cAge is centred on each participant's mean age, so it maps onto the
# plotted axis with a constant offset. The line is clipped to the follow-up
# actually observed in that panel; being a straight line, its slope and CI are
# unaffected by where it is truncated.
# ---------------------------------------------------------------------------
within_prediction_grid <- function(data) {
  offset <- mean(data$x - data$within_cAge, na.rm = TRUE)
  within_range <- range(data$within_cAge, na.rm = TRUE) + offset
  time_range <- c(
    max(0, within_range[1]),
    min(max(data$x, na.rm = TRUE), within_range[2])
  )

  grid_x <- seq(time_range[1], time_range[2], length.out = GRID_POINTS)
  mark_no_gap(grid_x) %>%
    mutate(within_cAge = x - offset)
}

# The session frames keep `within_cAge` alongside the six plotting columns
# because the prediction grids are built from it; as_plot_frame() drops it
# again before anything is drawn.
figure3_average_sessions <- function(data) {
  map_dfr(MEASURES, function(measure_name) {
    complete_outcome_data(data, measure_name) %>%
      group_by(SubNum, Wave_Num) %>%
      summarise(
        age = mean(Age_DuringParticipation_, na.rm = TRUE),
        within_cAge = mean(within_cAge, na.rm = TRUE),
        value = mean(.data[[measure_name]], na.rm = TRUE),
        .groups = "drop"
      ) %>%
      group_by(SubNum) %>%
      filter(n() >= 2) %>%
      mutate(x = age - min(age, na.rm = TRUE)) %>%
      ungroup() %>%
      transmute(
        participant = SubNum,
        session = Wave_Num,
        x,
        within_cAge,
        measure = measure_name,
        modality = "Average",
        value
      )
  })
}

figure3_average_lines <- function(data, models, sessions) {
  map_dfr(MEASURES, function(measure_name) {
    covariates <- typical_covariates(complete_outcome_data(data, measure_name))

    prediction_grid <- sessions %>%
      filter(measure == measure_name) %>%
      within_prediction_grid() %>%
      mutate(
        between_cAge = 0,
        Sex_M1 = covariates$Sex_M1,
        Education = covariates$Education,
        aud_mot = 0,
        aud_vis = 0
      )

    fixed_effect_predictions(models[[measure_name]], prediction_grid) %>%
      mutate(measure = measure_name, modality = "Average")
  })
}

figure3_modality_sessions <- function(data) {
  map_dfr(MEASURES, function(measure_name) {
    prepare_interaction_data(complete_outcome_data(data, measure_name)) %>%
      group_by(SubNum, Modality) %>%
      filter(n_distinct(Wave_Num) >= 2) %>%
      mutate(
        x = Age_DuringParticipation_ -
          min(Age_DuringParticipation_, na.rm = TRUE)
      ) %>%
      ungroup() %>%
      transmute(
        participant = SubNum,
        session = Wave_Num,
        x,
        within_cAge,
        measure = measure_name,
        modality = as.character(Modality),
        value = .data[[measure_name]]
      )
  })
}

figure3_modality_lines <- function(data, visualization_models, sessions) {
  map_dfr(MEASURES, function(measure_name) {
    covariates <- typical_covariates(complete_outcome_data(data, measure_name))

    prediction_grid <- sessions %>%
      filter(measure == measure_name) %>%
      group_by(modality) %>%
      group_modify(~ within_prediction_grid(.x)) %>%
      ungroup() %>%
      mutate(
        between_cAge = 0,
        Sex_M1 = covariates$Sex_M1,
        Education = covariates$Education,
        Modality = factor(modality, levels = INTERACTION_MODALITY_LEVELS)
      )

    fixed_effect_predictions(
      visualization_models[[measure_name]],
      prediction_grid,
      contrasts_option = INTERACTION_CONTRASTS
    ) %>%
      mutate(measure = measure_name)
  })
}

figure3_plot_data <- function(data, models, visualization_models) {
  # The prediction grids are built from the unjittered sessions; the display
  # frame is jittered once - not per layer - so each participant's segment and
  # its endpoint markers all move by the same offset.
  average_sessions <- figure3_average_sessions(data)
  modality_sessions <- figure3_modality_sessions(data)

  list(
    points = bind_rows(average_sessions, modality_sessions) %>%
      as_plot_frame() %>%
      jitter_participant_x(FIGURE3_JITTER_WIDTH),
    lines = bind_rows(
      figure3_average_lines(data, models, average_sessions),
      figure3_modality_lines(data, visualization_models, modality_sessions)
    ) %>%
      as_line_frame()
  )
}

# ---------------------------------------------------------------------------
# The combined age-effect figure.
#
# One 3 x 2 grid: outcome by row (distinctiveness, reliability, confusability --
# the Results order), age term by column. Every panel carries the pooled fitted
# line and the three modality-specific fitted lines, from the same models that
# fed the earlier pair of figures; nothing is refitted here.
#
# scales = "free" is load-bearing, and means exactly what is wanted: in
# facet_grid the y scale is freed by ROW and shared across the columns of that
# row, and the x scale is freed by COLUMN and shared down the rows of that
# column. Age in years and years-from-first-wave therefore never share an axis,
# while the two columns of a row stay directly comparable.
# ---------------------------------------------------------------------------
combined_series <- function(modality) {
  factor(
    if_else(modality == AVERAGE_COLUMN, POOLED_SERIES, modality),
    levels = SERIES_LEVELS
  )
}

# Reshapes the two cached per-column frames into one frame of fitted lines.
# Pure reshaping: no model is fitted and no estimate recomputed, so stage 02's
# cache is unchanged. Raw observations are deliberately not carried through --
# they are pooled-sample points, and three of the four lines in a panel are not
# pooled, so they correspond to nothing that is drawn.
combined_plot_data <- function(figure2_data, figure3_data) {
  as_combined <- function(frame, column) {
    frame %>%
      mutate(
        column = factor(column, levels = COMBINED_COLUMNS),
        measure = factor(
          as.character(measure), levels = COMBINED_MEASURE_LEVELS
        ),
        series = combined_series(as.character(modality))
      )
  }

  lines <- bind_rows(
    as_combined(figure2_data$lines, COMBINED_COLUMNS[[1]]),
    as_combined(figure3_data$lines, COMBINED_COLUMNS[[2]])
  ) %>%
    mutate(
      line_group = paste(measure, series, column),
      solid_group = paste(measure, series, column, solid_segment)
    )

  stopifnot(
    setequal(levels(lines$measure), COMBINED_MEASURE_LEVELS),
    # All four series are present in BOTH columns. The within-person modality
    # lines are subordinated when drawn, not dropped here.
    setequal(
      as.character(lines$series[lines$column == COMBINED_COLUMNS[[1]]]),
      SERIES_LEVELS
    ),
    setequal(
      as.character(lines$series[lines$column == COMBINED_COLUMNS[[2]]]),
      SERIES_LEVELS
    ),
    # Dashes mark the unsampled age range and nothing else, so they may only
    # ever appear in the between-person column.
    !any(lines$gap_span[lines$column == COMBINED_COLUMNS[[2]]])
  )
  lines
}

# ---------------------------------------------------------------------------
# The pooled slope, its standard error and its Satterthwaite df, keyed the way
# the combined figure needs them. Takes model_estimates.csv, or anything with
# its columns.
# ---------------------------------------------------------------------------
combined_pooled_slopes <- function(pooled_models, rule_label_text) {
  slopes <- pooled_models %>%
    filter(motion_rule == rule_label_text, term %in% AGE_TERMS) %>%
    transmute(
      measure = factor(outcome, levels = COMBINED_MEASURE_LEVELS),
      column = factor(
        if_else(term == "between_cAge", COMBINED_COLUMNS[[1]], COMBINED_COLUMNS[[2]]),
        levels = COMBINED_COLUMNS
      ),
      b = estimate, se, df
    )
  stopifnot(
    nrow(slopes) == length(COMBINED_MEASURE_LEVELS) * length(COMBINED_COLUMNS),
    !anyDuplicated(slopes[c("measure", "column")]),
    !anyNA(slopes), all(slopes$se > 0), all(slopes$df > 0)
  )
  slopes
}

# ---------------------------------------------------------------------------
# The ribbon: the CI of the CHANGE, not of the fitted value.
#
# At the reference the plotted change is zero by construction, so its interval
# must have zero width there. For a model linear in the age term the change is
# b * (x - x_ref) and its standard error is SE(b) * |x - x_ref|, giving
#
#     b * (x - x_ref)  +/-  t(0.975, df) * SE(b) * |x - x_ref|
#
# -- a straight-edged bowtie pinched shut at the reference. df is the
# Satterthwaite df of the same coefficient the tables report, so the ribbon and
# the tabled interval are the same statement.
#
# Shifting the fitted-value interval instead, as this figure did before, leaves
# a ribbon of non-zero width around a quantity that is exactly zero.
# ---------------------------------------------------------------------------
combined_change_ribbon <- function(centred_lines, pooled_slopes) {
  ribbon <- centred_lines %>%
    filter(series == POOLED_SERIES) %>%
    group_by(measure, column) %>%
    group_modify(function(panel, key) {
      reference <- COMBINED_REFERENCES[[as.character(key$column)]]
      slope <- pooled_slopes %>%
        filter(measure == key$measure, column == key$column)
      stopifnot(nrow(slope) == 1L)

      # Two routes to one number: the centred pooled line comes from the cached
      # design-matrix predictions, b comes from the exported coefficient. They
      # must agree, or the ribbon would belong to a different line.
      stopifnot(
        max(abs(panel$predicted - slope$b * (panel$x - reference))) < 1e-8
      )

      # The reference is not generally on the prediction grid; adding it puts a
      # point exactly at the pinch.
      grid <- sort(unique(c(panel$x, reference)))
      change <- slope$b * (grid - reference)
      half_width <- qt(.975, slope$df) * slope$se * abs(grid - reference)
      tibble(
        x = grid,
        predicted = change,
        conf_low = change - half_width,
        conf_high = change + half_width
      )
    }) %>%
    ungroup()

  # The width at the reference is zero, exactly.
  at_reference <- ribbon %>%
    group_by(measure, column) %>%
    summarise(
      width = {
        reference <- COMBINED_REFERENCES[[as.character(column[[1]])]]
        (conf_high - conf_low)[which(x == reference)]
      },
      .groups = "drop"
    )
  stopifnot(
    nrow(at_reference) == length(COMBINED_MEASURE_LEVELS) * length(COMBINED_COLUMNS),
    all(at_reference$width == 0),
    # ... and nowhere else, so the bowtie really is pinched at one point.
    all(ribbon$conf_high >= ribbon$conf_low)
  )
  ribbon
}

# Every modality line drawn must be the emtrends simple slope the tables
# report. The lines come from the cached interaction-model predictions and the
# slopes from {rule}_simple_slopes.csv, which emtrends produced; for a model
# linear in the age term the two are the same number by construction, and this
# says so out loud rather than trusting it. Covers both columns: the
# within-person lines are obtained exactly as the between-person ones are.
verify_modality_slopes <- function(lines, modality_slopes, rule_label_text) {
  drawn <- lines %>%
    filter(series != POOLED_SERIES) %>%
    group_by(measure, column, series) %>%
    summarise(
      slope = {
        first <- which.min(x)
        last <- which.max(x)
        (predicted[[last]] - predicted[[first]]) / (x[[last]] - x[[first]])
      },
      .groups = "drop"
    )
  expected <- modality_slopes %>%
    filter(motion_rule == rule_label_text) %>%
    transmute(
      measure = factor(outcome, levels = COMBINED_MEASURE_LEVELS),
      column = factor(
        if_else(age_term == "between_cAge",
                COMBINED_COLUMNS[[1]], COMBINED_COLUMNS[[2]]),
        levels = COMBINED_COLUMNS
      ),
      series = factor(modality, levels = SERIES_LEVELS),
      emtrends_slope = slope
    )
  comparison <- inner_join(drawn, expected,
                           by = c("measure", "column", "series"))
  stopifnot(
    nrow(drawn) == length(COMBINED_MEASURE_LEVELS) * length(COMBINED_COLUMNS) *
      (length(SERIES_LEVELS) - 1L),
    nrow(comparison) == nrow(drawn),
    max(abs(comparison$slope - comparison$emtrends_slope)) < 1e-8
  )
  comparison
}

# The within-person age x modality F tests, formatted for the caption. The
# assertion is the point: the caption says these interactions were not
# significant, so if that ever stops being true the run fails rather than
# printing a false claim.
within_interaction_summary <- function(interaction_tests, rule_label_text) {
  tests <- interaction_tests %>%
    filter(motion_rule == rule_label_text, age_term == "within_cAge") %>%
    mutate(measure = factor(outcome, levels = COMBINED_MEASURE_LEVELS)) %>%
    arrange(measure)
  stopifnot(
    nrow(tests) == length(COMBINED_MEASURE_LEVELS),
    setequal(as.character(tests$measure), COMBINED_MEASURE_LEVELS),
    all(tests$p >= .05)
  )
  paste(
    sprintf(
      "%s F(%d, %.1f) = %.2f, p = %s",
      tolower(as.character(tests$measure)), as.integer(tests$df1),
      tests$df2, tests$F, format_p(tests$p)
    ),
    collapse = "; "
  )
}

# The caption is written beside the figure rather than drawn on it, so it can
# say everything a reader needs without competing with six panels for space.
# The row strips are deliberately neutral, so this is the only place that says
# the panels plot change rather than level.
CAPTION_WIDTH <- 78   # characters, for a plain-text caption file

combined_caption <- function(figure_label, rule_label_text, interaction_tests = NULL,
                             width = CAPTION_WIDTH) {
  paste(
    strwrap(
      paste0(
        figure_label, ". Model-implied age effects on neural distinctiveness, ",
        "reliability and confusability under ", rule_label_text,
        ". Each panel plots change from a reference rather than a level: every ",
        "series is shifted by its own fitted value at age ", OLDER_ADULT_AGE,
        " in the between-person column, and at the first wave in the ",
        "within-person column, so all series pass through zero there. Colour ",
        "encodes modality; the pooled series is the heavier near-black line. ",
        "Ribbon: 95% CI of the model-implied change from the reference, zero ",
        "width at the reference by construction. Dashed segments span the ",
        "unsampled age range between the young and older samples. ",
        "Colored modality-specific lines in both columns are descriptive only, ",
        "from visualization-only fits allowing different slopes by modality. ",
        "They carry no inferential interaction tests or modality-specific ",
        "statistical conclusions. The heavy near-black pooled line and its ",
        "interval use the manuscript's pooled mixed model."
      ),
      width = width
    ),
    collapse = "\n"
  )
}

# Writes <name>_caption.txt beside the figure exports.
write_figure_caption <- function(text, directory, name) {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(directory, paste0(name, "_caption.txt"))
  writeLines(text, path)
  path
}

# Panel tags A-F, in reading order across the grid.
combined_panel_tags <- function() {
  expand_grid(
    measure = factor(COMBINED_MEASURE_LEVELS, levels = COMBINED_MEASURE_LEVELS),
    column = factor(COMBINED_COLUMNS, levels = COMBINED_COLUMNS)
  ) %>%
    mutate(label = LETTERS[seq_len(n())])
}

# ---------------------------------------------------------------------------
# Centring.
#
# Each series is shifted by its OWN fitted value at the column's reference, so
# every line passes through zero there and the panel shows model-implied change
# from that reference rather than a level. The four series in a panel start
# from different levels, so each needs its own shift.
#
# The ribbon is shifted by the same constant. It therefore remains the interval
# around the pooled FITTED VALUE, not the interval around the change, and does
# not close to zero width at the reference -- a proper interval for the change
# would need the covariance between the two fitted values, which the cached
# predictions do not carry.
# ---------------------------------------------------------------------------

# Every fitted line here is linear in x, so the value at the reference is exact
# by linear interpolation between the endpoints, and is still correct when the
# reference falls just outside the drawn range. The assertion keeps that
# honest: a curved term in the specification would trip it rather than silently
# centring on the wrong value.
reference_value <- function(x, predicted, reference) {
  first <- which.min(x)
  last <- which.max(x)
  stopifnot(x[[last]] > x[[first]])
  slope <- (predicted[[last]] - predicted[[first]]) / (x[[last]] - x[[first]])
  straight <- predicted[[first]] + (x - x[[first]]) * slope
  stopifnot(max(abs(predicted - straight)) < 1e-8)
  predicted[[first]] + (reference - x[[first]]) * slope
}

centre_combined_lines <- function(lines) {
  centred <- lines %>%
    group_by(measure, column, series) %>%
    mutate(
      offset = reference_value(
        x, predicted, COMBINED_REFERENCES[[as.character(column[[1]])]]
      ),
      predicted = predicted - offset,
      conf_low = conf_low - offset,
      conf_high = conf_high - offset
    ) %>%
    ungroup()

  # Every series must now pass through zero at its reference.
  at_reference <- centred %>%
    group_by(measure, column, series) %>%
    summarise(
      value = reference_value(
        x, predicted, COMBINED_REFERENCES[[as.character(column[[1]])]]
      ),
      .groups = "drop"
    )
  stopifnot(max(abs(at_reference$value)) < 1e-8)
  centred %>% select(-offset)
}

# Solid where there are data, dashed across the unsampled age range. By
# construction only the between-person column has such a range.
combined_line_layers <- function(lines, width, dash = "dashed", alpha = 1) {
  dashed <- lines %>% filter(gap_span)
  solid <- lines %>% filter(!is.na(solid_segment))
  # A zero-row layer is dropped rather than added: ggh4x's per-facet scales
  # fail on a layer whose data carries no PANEL column, and the within-person
  # column legitimately has no dashed span at all.
  layers <- list()
  if (nrow(dashed) > 0) {
    layers <- c(layers, list(geom_line(
      data = dashed,
      aes(x, predicted, colour = series, group = line_group),
      linewidth = width * COMBINED_GAP_WIDTH_SCALE, linetype = dash,
      alpha = alpha
    )))
  }
  if (nrow(solid) > 0) {
    layers <- c(layers, list(geom_line(
      data = solid,
      aes(x, predicted, colour = series, group = solid_group),
      linewidth = width, alpha = alpha
    )))
  }
  layers
}

# centred = FALSE draws the fitted values on the raw outcome scale, which is
# what the figure did before, so the two versions can be compared side by side.
# The change-CI ribbon belongs to the centred version only: on the raw scale
# there is no reference for a change to be measured from, so that version keeps
# the fitted-value interval.
build_combined_figure <- function(lines, pooled_slopes, centred = TRUE) {
  stopifnot(is.logical(centred), length(centred) == 1L, !is.na(centred))
  if (centred) lines <- centre_combined_lines(lines)
  pooled <- lines %>% filter(series == POOLED_SERIES)
  modalities <- lines %>% filter(series != POOLED_SERIES)
  ribbon <- if (centred) combined_change_ribbon(lines, pooled_slopes) else pooled

  ggplot() +
    # The zero line is the reference the series were centred on, so it belongs
    # only to the centred version.
    (if (centred) {
      geom_hline(
        yintercept = 0, colour = CENTRED_ZERO_LINE_COLOUR,
        linewidth = CENTRED_ZERO_LINE_WIDTH
      )
    }) +
    geom_ribbon(
      data = ribbon,
      aes(x, ymin = conf_low, ymax = conf_high,
          group = interaction(measure, column)),
      fill = SERIES_COLOURS[[POOLED_SERIES]], alpha = COMBINED_RIBBON_ALPHA,
      colour = NA
    ) +
    # Pooled first, modality lines on top: where a modality line sits on the
    # pooled estimate it stays visible rather than being hidden beneath the
    # heavier line. In the within-person column those lines are thinner and
    # semi-transparent, so the pooled estimate still dominates.
    combined_line_layers(pooled, COMBINED_POOLED_WIDTH,
                         dash = COMBINED_POOLED_DASH) +
    combined_line_layers(
      modalities %>% filter(column == COMBINED_COLUMNS[[1]]),
      COMBINED_MODALITY_WIDTH
    ) +
    combined_line_layers(
      modalities %>% filter(column == COMBINED_COLUMNS[[2]]),
      COMBINED_WITHIN_MODALITY_WIDTH, alpha = COMBINED_WITHIN_MODALITY_ALPHA
    ) +
    geom_text(
      data = combined_panel_tags(), aes(x = -Inf, y = Inf, label = label),
      inherit.aes = FALSE, hjust = -0.55, vjust = 1.35,
      fontface = "bold", size = 3.2, colour = "black"
    ) +
    ggh4x::facet_grid2(
      measure ~ column,
      scales = "free", switch = "y",
      # Neutral row labels in both modes. That the centred panels plot change
      # rather than level is stated in the caption file, not in the strip.
      labeller = labeller(measure = MEASURE_STRIP_LABELS)
    ) +
    ggh4x::facetted_pos_scales(
      x = list(
        column == COMBINED_COLUMNS[[2]] ~
          scale_x_continuous(breaks = WITHIN_TIME_BREAKS)
      )
    ) +
    scale_colour_manual(
      values = SERIES_COLOURS, breaks = SERIES_LEVELS, limits = SERIES_LEVELS,
      name = NULL
    ) +
    # Headroom at the top of every panel, so a tag never lands on a line.
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.14))) +
    guides(colour = guide_legend(nrow = 1, override.aes = list(
      linewidth = c(
        COMBINED_POOLED_WIDTH,
        rep(COMBINED_MODALITY_WIDTH, length(SERIES_LEVELS) - 1)
      )
    ))) +
    # One shared x title is set here and then replaced, per column, by
    # add_column_axis_titles(); ggplot cannot render two of them on its own.
    labs(x = AGE_AXIS_LABEL, y = NULL) +
    manuscript_theme() +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 8),
      legend.key.width = unit(16, "pt"),
      legend.box.spacing = unit(3, "pt"),
      panel.spacing.x = unit(10, "pt"),
      panel.spacing.y = unit(6, "pt")
    )
}

# ggplot draws one x title for the whole grid, but the two columns are in
# different units. The title row is therefore repopulated with one centred
# title per panel column. A layout edit, like the retired average-column
# divider: it writes into existing cells and must not resize anything.
add_column_axis_titles <- function(figure,
                                   titles = c(AGE_AXIS_LABEL, WITHIN_TIME_LABEL)) {
  table <- ggplotGrob(figure)
  panels <- table$layout[grep("^panel", table$layout$name), ]
  panel_columns <- sort(unique(panels$l))
  stopifnot(length(panel_columns) == length(titles))

  index <- which(table$layout$name == "xlab-b")
  stopifnot(length(index) == 1L)
  title_row <- table$layout$t[[index]]
  style <- table$grobs[[index]]$children[[1]]$gp

  widths_before <- table$widths
  # Blank the shared title, keeping the row height it already reserved.
  table$grobs[[index]] <- nullGrob()
  for (i in seq_along(titles)) {
    table <- gtable::gtable_add_grob(
      table,
      textGrob(titles[[i]], gp = style),
      t = title_row, b = title_row,
      l = panel_columns[[i]], r = panel_columns[[i]],
      name = paste0("xlab-column-", i)
    )
  }
  stopifnot(identical(as.character(widths_before), as.character(table$widths)))
  table
}

# ---------------------------------------------------------------------------
# The magnitude-contrast figure.
#
# One panel, one series: the POOLED magnitude contrast
#
#     delta = |b_reliability| - |b_confusability|
#
# for the two age terms, with its 95% bootstrap percentile interval read from
# magnitude_comparison.csv. Nothing is fitted or resampled here.
#
# delta is sign-free. It says which component's age effect is larger in
# MAGNITUDE, and carries no claim about the direction of either component, so
# nothing in this figure may be labelled as an excess, a gain, or a loss.
#
# The modality-specific rows, the component slopes, and the signed difference
# stay in magnitude_comparison.csv and in the supplementary table. They are
# simply not plotted: this is a change to what is shown, not to what is
# computed.
# ---------------------------------------------------------------------------
MAGNITUDE_AGE_LABELS <- c(
  between_cAge = "Between-person age",
  within_cAge = "Within-person age"
)
# Between-person on top. The rows sit half a unit apart rather than a whole
# one: with only two of them, unit spacing left the middle of the panel empty.
MAGNITUDE_AGE_POSITIONS <- c(between_cAge = 1.5, within_cAge = 1)

# Small enough that the between-person interval, whose upper half is short,
# stays visible on both sides of its point.
MAGNITUDE_POINT_SIZE <- 1.5
MAGNITUDE_WIDTH_MM <- 90        # a single journal column
# Two rows, the axis, and the direction annotation, and nothing else: the
# caption lives in its own file, so the panel needs no room for one.
MAGNITUDE_HEIGHT_MM <- 36

# The direction annotation sits below both plotted rows -- so it cannot collide
# with an interval however wide it runs -- and hard against the axis line, with
# each arrow directly beneath its own label so the two read as one unit rather
# than as two separate bands.
MAGNITUDE_DIRECTION_TEXT_Y <- 0.72
MAGNITUDE_DIRECTION_ARROW_Y <- 0.50
MAGNITUDE_DIRECTION_FLOOR <- 0.40   # panel bottom, just under the arrows
MAGNITUDE_DIRECTION_PAD <- 0.02     # gap from zero, as a fraction of the span
MAGNITUDE_DIRECTION_ARROW <- 0.13   # arrow length, likewise

# Plotmath rather than a plain string: at this size the ASCII pipe of
# "|b_reliability|" renders close enough to a lowercase L to be misread.
MAGNITUDE_X_LABEL <- expression(
  "Magnitude difference," ~ paste("|", beta[R], "|") -
    paste("|", beta[C], "|") ~ "(per year)"
)
# Two lines each: anchored on zero, a one-line "larger for confusability" is
# wider than the space between zero and the left edge of the panel, because
# zero sits well left of centre once the within-person interval is in view.
MAGNITUDE_DIRECTION_LEFT <- "larger for\nconfusability"
MAGNITUDE_DIRECTION_RIGHT <- "larger for\nreliability"

magnitude_plot_data <- function(magnitude, rule_label_text) {
  rows <- magnitude %>%
    filter(motion_rule == rule_label_text, scope == "Pooled") %>%
    transmute(
      age_term,
      label = unname(MAGNITUDE_AGE_LABELS[age_term]),
      y = unname(MAGNITUDE_AGE_POSITIONS[age_term]),
      delta,
      conf_low = delta_ci_lo,
      conf_high = delta_ci_hi,
      n_boot_ok,
      # Kept as the one identity that still applies to a sign-free quantity:
      # the plotted value must be the contrast of the two magnitudes.
      delta_check = abs(b_reliability) - abs(b_confusability)
    )

  stopifnot(
    nrow(rows) == length(AGE_TERMS),
    setequal(rows$age_term, AGE_TERMS),
    !anyNA(rows$delta), !anyNA(rows$conf_low), !anyNA(rows$conf_high),
    all(is.finite(c(rows$delta, rows$conf_low, rows$conf_high))),
    all(abs(rows$delta - rows$delta_check) < 1e-8),
    all(rows$conf_low <= rows$delta), all(rows$delta <= rows$conf_high),
    # A percentile interval cannot come from more draws than were requested.
    all(rows$n_boot_ok > 0), all(rows$n_boot_ok <= MAGNITUDE_BOOT_DRAWS)
  )
  rows %>% select(-delta_check)
}

magnitude_caption <- function(figure_data, figure_label, rule_label_text,
                              width = CAPTION_WIDTH) {
  paste(
    strwrap(
      paste0(
        figure_label, ". Pooled magnitude contrast of the age effects on ",
        "reliability and confusability under ", rule_label_text,
        ". Points are delta = |b_R| - |b_C|, where b_R is the age slope for ",
        "reliability and b_C the corresponding slope for confusability, both ",
        "per year on the original correlation scale. delta is sign-free: a ",
        "positive value means the age effect is larger in magnitude for ",
        "reliability, whichever direction either component points in. ",
        "Intervals are 95% bootstrap percentile intervals from a cluster ",
        "bootstrap over participants (B = ",
        format(MAGNITUDE_BOOT_DRAWS, big.mark = ","), " draws",
        # Only worth saying when some draw was unusable.
        if (min(figure_data$n_boot_ok) < MAGNITUDE_BOOT_DRAWS) {
          paste0(" requested, ", format(min(figure_data$n_boot_ok), big.mark = ","),
                 " usable here")
        },
        "). Percentile intervals need not be symmetric about the point estimate."
      ),
      width = width
    ),
    collapse = "\n"
  )
}

build_magnitude_figure <- function(figure_data) {
  stopifnot(nrow(figure_data) == length(AGE_TERMS))
  # The direction labels are placed relative to zero in data units, so their
  # offsets are read off the span the panel actually covers.
  span <- diff(range(c(0, figure_data$conf_low, figure_data$conf_high)))
  pad <- MAGNITUDE_DIRECTION_PAD * span
  arrow_length <- MAGNITUDE_DIRECTION_ARROW * span
  # One shared x scale across both rows. They are per-year slopes in the same
  # units, so a shared axis is the honest display: it shows the within-person
  # estimate for what it is, far less precise than the between-person one.
  ggplot(figure_data, aes(delta, y)) +
    geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.3) +
    geom_segment(
      aes(x = conf_low, xend = conf_high, yend = y),
      linewidth = 0.5, colour = SERIES_COLOURS[[POOLED_SERIES]]
    ) +
    # The same filled black square as the pooled series of the combined figure.
    geom_point(
      shape = 22, size = MAGNITUDE_POINT_SIZE, stroke = 0.4,
      colour = SERIES_COLOURS[[POOLED_SERIES]],
      fill = SERIES_COLOURS[[POOLED_SERIES]]
    ) +
    annotate(
      "text", x = -pad, y = MAGNITUDE_DIRECTION_TEXT_Y,
      label = MAGNITUDE_DIRECTION_LEFT, hjust = 1, vjust = 0.5, size = 2.0,
      lineheight = 0.95, colour = "grey35"
    ) +
    annotate(
      "text", x = pad, y = MAGNITUDE_DIRECTION_TEXT_Y,
      label = MAGNITUDE_DIRECTION_RIGHT, hjust = 0, vjust = 0.5, size = 2.0,
      lineheight = 0.95, colour = "grey35"
    ) +
    annotate(
      "segment", x = -pad, xend = -pad - arrow_length,
      y = MAGNITUDE_DIRECTION_ARROW_Y, yend = MAGNITUDE_DIRECTION_ARROW_Y,
      colour = "grey35", linewidth = 0.3,
      arrow = arrow(length = unit(1.1, "mm"), type = "closed")
    ) +
    annotate(
      "segment", x = pad, xend = pad + arrow_length,
      y = MAGNITUDE_DIRECTION_ARROW_Y, yend = MAGNITUDE_DIRECTION_ARROW_Y,
      colour = "grey35", linewidth = 0.3,
      arrow = arrow(length = unit(1.1, "mm"), type = "closed")
    ) +
    scale_y_continuous(
      breaks = unname(MAGNITUDE_AGE_POSITIONS),
      labels = unname(MAGNITUDE_AGE_LABELS[names(MAGNITUDE_AGE_POSITIONS)]),
      limits = c(MAGNITUDE_DIRECTION_FLOOR, 1.78),
      expand = expansion(mult = 0)
    ) +
    scale_x_continuous(
      expand = expansion(mult = c(.16, .06)), labels = scales::label_number()
    ) +
    labs(x = MAGNITUDE_X_LABEL, y = NULL) +
    manuscript_theme() +
    theme(
      legend.position = "none",
      axis.title.x = element_text(size = 8.5),
      # Leave room for the terminal tick label after corrected intervals
      # change the automatically selected x-axis breaks (notably Figure S2).
      plot.margin = margin(4, 14, 3, 3)
    )
}

# ---------------------------------------------------------------------------
# Checks on the Average column.
#
# The Average column is a summary of the modality columns, so it is recomputed
# from the session x modality observations and compared rather than trusted.
# Motion exclusion is modality-dependent, so a session can survive with fewer
# than three modalities; those sessions are averages over an incomplete set and
# are counted here.
# ---------------------------------------------------------------------------
modality_observations <- function(data) {
  map_dfr(MEASURES, function(measure_name) {
    prepare_interaction_data(complete_outcome_data(data, measure_name)) %>%
      transmute(
        participant = SubNum,
        session = Wave_Num,
        modality = as.character(Modality),
        measure = measure_name,
        value = .data[[measure_name]]
      )
  })
}

session_modality_means <- function(observations) {
  observations %>%
    group_by(measure, participant, session) %>%
    summarise(
      session_value = mean(value),
      n_modalities = n_distinct(modality),
      .groups = "drop"
    )
}

average_column_values <- function(points) {
  points %>%
    filter(modality == "Average") %>%
    mutate(measure = as.character(measure)) %>%
    select(measure, participant, session, plotted = value)
}

# Figure 3's Average points are session-level, so they are exactly the
# per-session mean across the modalities retained for that session.
figure3_average_check <- function(data, points) {
  sessions <- session_modality_means(modality_observations(data))
  plotted <- average_column_values(points)

  comparison <- plotted %>%
    inner_join(sessions, by = c("measure", "participant", "session"))
  stopifnot(nrow(comparison) == nrow(plotted))

  plotted_sessions <- sessions %>%
    semi_join(plotted, by = c("measure", "participant", "session"))

  list(
    figure = "Within-person figure",
    average_definition = "per-session mean across retained modalities",
    rows_compared = nrow(comparison),
    max_difference = max(abs(comparison$plotted - comparison$session_value)),
    session_cells = nrow(plotted_sessions),
    incomplete_cells = sum(plotted_sessions$n_modalities < 3),
    incomplete_sessions = plotted_sessions %>%
      filter(n_modalities < 3) %>%
      distinct(participant, session) %>%
      nrow()
  )
}

# Figure 2's Average points pool over waves as well, so the comparison is made
# at the participant level; the extra term reports how far that participant
# mean sits from the unweighted mean of its own session means, which differ
# only when a participant's sessions retained different numbers of modalities.
figure2_average_check <- function(data, points) {
  observations <- modality_observations(data)
  sessions <- session_modality_means(observations)
  plotted <- average_column_values(points)

  participant_means <- observations %>%
    group_by(measure, participant) %>%
    summarise(observation_mean = mean(value), .groups = "drop")
  session_based_means <- sessions %>%
    group_by(measure, participant) %>%
    summarise(session_mean = mean(session_value), .groups = "drop")

  comparison <- plotted %>%
    inner_join(participant_means, by = c("measure", "participant")) %>%
    inner_join(session_based_means, by = c("measure", "participant"))
  stopifnot(nrow(comparison) == nrow(plotted))

  list(
    figure = "Between-person figure",
    average_definition = "participant mean across retained sessions x modalities",
    rows_compared = nrow(comparison),
    max_difference = max(abs(comparison$plotted - comparison$observation_mean)),
    max_session_based_difference =
      max(abs(comparison$plotted - comparison$session_mean)),
    session_cells = nrow(sessions),
    incomplete_cells = sum(sessions$n_modalities < 3),
    incomplete_sessions = sessions %>%
      filter(n_modalities < 3) %>%
      distinct(participant, session) %>%
      nrow()
  )
}

print_average_check <- function(check) {
  cat(check$figure, "- Average column\n")
  cat("  definition:", check$average_definition, "\n")
  cat(sprintf(
    "  %d Average points recomputed from the modality columns; max |difference| = %.3g\n",
    check$rows_compared, check$max_difference
  ))
  if (!is.null(check$max_session_based_difference)) {
    cat(sprintf(
      "  max |plotted - unweighted mean of that participant's session means| = %.3g\n",
      check$max_session_based_difference
    ))
  }
  cat(sprintf(
    "  session x measure cells: %d; averaged over fewer than 3 modalities: %d (%.1f%%)\n",
    check$session_cells, check$incomplete_cells,
    100 * check$incomplete_cells / check$session_cells
  ))
  cat(sprintf(
    "  distinct sessions averaged over fewer than 3 modalities: %d\n",
    check$incomplete_sessions
  ))
}

# ---------------------------------------------------------------------------
# Checks on the grid itself, run before anything is written to disk: the grid
# must be 3 x 2 with no empty panel, the two panels of a row must share one y
# scale, and the three panels of a column must share one x scale. That sharing
# is the whole point of scales = "free" here, and is what makes the two columns
# of a row comparable.
# ---------------------------------------------------------------------------
verify_combined_figure <- function(figure, lines) {
  panel_counts <- lines %>% count(measure, column, .drop = FALSE)
  stopifnot(
    nrow(panel_counts) ==
      length(COMBINED_MEASURE_LEVELS) * length(COMBINED_COLUMNS),
    all(panel_counts$n > 0)
  )

  built <- ggplot_build(figure)
  layout <- built$layout$layout
  stopifnot(nrow(layout) == nrow(panel_counts))

  ranges <- map_dfr(seq_len(nrow(layout)), function(i) {
    params <- built$layout$panel_params[[i]]
    tibble(
      row = layout$ROW[[i]], col = layout$COL[[i]],
      measure = as.character(layout$measure[[i]]),
      column = as.character(layout$column[[i]]),
      x_min = params$x.range[[1]], x_max = params$x.range[[2]],
      y_min = params$y.range[[1]], y_max = params$y.range[[2]]
    )
  })

  spread <- function(group, low, high) {
    ranges %>%
      group_by(.data[[group]]) %>%
      summarise(
        spread = max(abs(.data[[low]] - first(.data[[low]]))) +
          max(abs(.data[[high]] - first(.data[[high]]))),
        .groups = "drop"
      )
  }
  # y identical across the columns of a row; x identical down the rows of a
  # column. Both must hold to the last bit.
  stopifnot(
    all(spread("row", "y_min", "y_max")$spread < 1e-9),
    all(spread("col", "x_min", "x_max")$spread < 1e-9)
  )
  # The columns are in different units, so their x ranges must NOT coincide.
  stopifnot(nrow(distinct(ranges, col, x_min, x_max)) == length(COMBINED_COLUMNS))

  list(panels = panel_counts, ranges = ranges)
}

save_manuscript_figure <- function(figure, directory, name,
                                   height_mm = FIGURE_HEIGHT_MM,
                                   width_mm = FIGURE_WIDTH_MM) {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)

  ggsave(
    file.path(directory, paste0(name, ".pdf")),
    figure,
    width = width_mm, height = height_mm, units = "mm"
  )
  ggsave(
    file.path(directory, paste0(name, ".png")),
    figure,
    width = width_mm, height = height_mm, units = "mm", dpi = FIGURE_DPI
  )

  file.path(directory, paste0(name, c(".pdf", ".png")))
}

# ---------------------------------------------------------------------------
# The interactive ROI age-effect panels.
#
# Display only: the viewer draws these, and no numbered script writes them.
# They are NOT the manuscript figures and are not built from the same
# estimates. Each panel fits its own stratified per-modality model, whereas the
# manuscript's modality-specific slopes come from the interaction model via
# modality_trends()/emtrends -- see R/models.R. The two routes answer the same
# question with different estimators and need not agree.
# ---------------------------------------------------------------------------
get_roi_age_plot_info <- function(data, modality, outcome) {
  plot_data <- data %>%
    filter(Modality == modality) %>%
    select(
      Subject, SubNum, Wave_Num, Age_DuringParticipation_, n_waves,
      mean_age, within_cAge, between_cAge, Sex_M1, Education,
      Modality, all_of(outcome)
    ) %>%
    rename(value = all_of(outcome)) %>%
    drop_na(
      value, Age_DuringParticipation_, within_cAge, between_cAge,
      Sex_M1, Education, SubNum
    )

  roi_model <- lmer(
    reformulate(
      c(
        "within_cAge", "between_cAge", "Sex_M1", "Education",
        "(1 | SubNum)"
      ),
      response = "value"
    ),
    data = plot_data,
    REML = FALSE
  )

  coefficients <- summary(roi_model)$coefficients
  outcome_sd <- sd(plot_data$value, na.rm = TRUE)
  within_b <- coefficients["within_cAge", "Estimate"]
  between_b <- coefficients["between_cAge", "Estimate"]
  within_beta <- within_b * sd(plot_data$within_cAge, na.rm = TRUE) / outcome_sd
  between_beta <- between_b * sd(plot_data$between_cAge, na.rm = TRUE) / outcome_sd
  stats_label <- sprintf(
    paste0(
      "Long.: B=%.3f, β=%.3f, p=%s\n",
      "Cross-sec.: B=%.3f, β=%.3f, p=%s"
    ),
    within_b,
    within_beta,
    format_p(coefficients["within_cAge", "Pr(>|t|)"]),
    between_b,
    between_beta,
    format_p(coefficients["between_cAge", "Pr(>|t|)"])
  )

  longitudinal_data <- plot_data %>% filter(n_waves > 1)
  covariates <- typical_covariates(plot_data)

  between_age <- seq(
    min(plot_data$Age_DuringParticipation_, na.rm = TRUE),
    max(plot_data$Age_DuringParticipation_, na.rm = TRUE),
    length.out = GRID_POINTS
  )
  between_line <- tibble(
    age = between_age,
    within_cAge = 0,
    between_cAge = between_age - OLDER_ADULT_AGE,
    Sex_M1 = covariates$Sex_M1,
    Education = covariates$Education,
    SubNum = plot_data$SubNum[1]
  ) %>%
    mutate(predicted = predict(
      roi_model, newdata = ., re.form = NA, allow.new.levels = TRUE
    ))

  if (nrow(longitudinal_data) > 0 &&
      diff(range(longitudinal_data$within_cAge, na.rm = TRUE)) > 0) {
    within_values <- seq(
      min(longitudinal_data$within_cAge, na.rm = TRUE),
      max(longitudinal_data$within_cAge, na.rm = TRUE),
      length.out = GRID_POINTS
    )
    within_age <- mean(longitudinal_data$mean_age, na.rm = TRUE) +
      within_values
    within_line <- tibble(
      age = within_age,
      within_cAge = within_values,
      between_cAge = 0,
      Sex_M1 = covariates$Sex_M1,
      Education = covariates$Education,
      SubNum = plot_data$SubNum[1]
    ) %>%
      mutate(predicted = predict(
        roi_model, newdata = ., re.form = NA, allow.new.levels = TRUE
      ))
  } else {
    within_line <- tibble(age = numeric(), predicted = numeric())
  }

  list(
    data = plot_data,
    longitudinal_data = longitudinal_data,
    between_line = between_line,
    within_line = within_line,
    stats_label = stats_label
  )
}

# Its own theme and blue/red scale, deliberately: this is the exploratory ROI
# display, not a manuscript panel, so it does not use manuscript_theme() or the
# SERIES_COLOURS palette the manuscript figures share.
make_roi_age_panel <- function(data, modality, outcome, label) {
  plot_info <- get_roi_age_plot_info(data, modality, outcome)
  roi_labels <- c(Aud = "Auditory", Mot = "Motor", Vis = "Visual")

  point_data <- plot_info$data

  figure <- ggplot(point_data, aes(Age_DuringParticipation_, value)) +
    geom_line(
      data = plot_info$longitudinal_data %>% arrange(SubNum, Wave_Num),
      aes(group = SubNum),
      colour = "#CC0000", linewidth = 0.35, alpha = 0.45
    ) +
    geom_point(size = 1.25, alpha = 0.5) +
    geom_line(
      data = plot_info$between_line,
      aes(age, predicted, colour = "Cross-sectional"),
      linewidth = 1.4,
      inherit.aes = FALSE
    ) +
    geom_line(
      data = plot_info$within_line,
      aes(age, predicted, colour = "Longitudinal"),
      linewidth = 1.4,
      inherit.aes = FALSE
    ) +
    scale_colour_manual(
      values = c("Cross-sectional" = "#3366CC", "Longitudinal" = "#CC0000"),
      name = NULL
    ) +
    labs(
      title = unname(roi_labels[[modality]]),
      subtitle = plot_info$stats_label,
      x = "Age",
      y = paste("Neural", tolower(outcome)),
      caption = label
    ) +
    theme_classic(base_size = 10) +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 6.8, hjust = 0.5, lineheight = 1.1),
      plot.caption = element_text(size = 8.5, hjust = 0.5),
      axis.title = element_text(size = 9.5),
      axis.text = element_text(size = 8.5),
      legend.text = element_text(size = 8.5)
    )

  list(
    figure = figure,
    roi_label = unname(roi_labels[[modality]]),
    stats_label = plot_info$stats_label
  )
}
