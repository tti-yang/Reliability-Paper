# Manuscript figures 2 and 3.
#
# Both figures are one 3 x 4 grid built by the same function, so they cannot
# drift apart. Measure is the row throughout and the modality average is the
# leftmost column of the same grid rather than a separate stacked panel.
#
# Extracted verbatim from the manuscript-figure-helpers chunk of the original
# interactive document; only this header is new.

# ---------------------------------------------------------------------------
# Shared aesthetic mapping for every manuscript figure.
#
# Colour encodes the measure and nothing else. Shape encodes the modality
# column and nothing else. Both scales are defined once here and reused by
# every panel of every figure; no figure defines its own palette.
# ---------------------------------------------------------------------------
# The row order and the column order of both figures. The average column is the
# leftmost column of the same grid, not a separate panel stacked above it. It
# keeps the short level name "Average" in the data - the checks and the filters
# key on it - and is labelled "All modalities" on the figure, which describes
# the aggregate rather than suggesting a location.
MEASURES <- OUTCOMES
AVERAGE_COLUMN <- "Average"
MODALITY_COLUMNS <- c(AVERAGE_COLUMN, "Auditory", "Visual", "Motor")

MEASURE_COLOURS <- c(
  Reliability = "#0072B2",      # Okabe-Ito blue
  Confusability = "#D55E00",    # Okabe-Ito vermillion
  Distinctiveness = "#009E73"   # Okabe-Ito green
)

# Outlined-fill shapes: the fill and the outline are drawn as two layers so the
# pale fill (alpha 0.15) and the darker outline (alpha 0.6) can share one
# colour scale with the ribbons and model lines. The average column gets the
# neutral diamond, so it reads as a summary rather than as a fourth modality,
# and it is named in the legend rather than left unexplained.
MODALITY_SHAPES <- c(
  Average = 23,    # diamond
  Auditory = 21,   # circle
  Visual = 24,     # triangle
  Motor = 22       # square
)

# Every panel is named by its own strips, so neither figure carries a legend at
# all. The shape mapping is kept - it is what keeps the three modality columns
# visually distinct - but its guide is dropped: a shape legend would list the
# average alongside the modalities and imply it is a fourth one.
scale_measure_colour <- scale_colour_manual(
  values = MEASURE_COLOURS,
  guide = "none"
)
scale_measure_fill <- scale_fill_manual(
  values = MEASURE_COLOURS,
  guide = "none"
)
scale_modality_shape <- scale_shape_manual(
  values = MODALITY_SHAPES,
  breaks = MODALITY_COLUMNS,
  guide = "none"
)

MEASURE_STRIP_LABELS <- c(
  Reliability = "Neural reliability",
  Confusability = "Neural confusability",
  Distinctiveness = "Neural distinctiveness"
)
MODALITY_STRIP_LABELS <- c(
  Average = "All modalities",
  Auditory = "Auditory",
  Visual = "Visual",
  Motor = "Motor"
)
manuscript_labeller <- labeller(
  measure = MEASURE_STRIP_LABELS,
  modality = MODALITY_STRIP_LABELS
)

# Raw two-wave segments are drawn in neutral grey: they are the data layer, and
# leaving them uncoloured keeps colour reserved for the outcome and keeps the
# model line visible on top of them.
SEGMENT_COLOUR <- "grey55"
SEGMENT_ALPHA <- 0.25
SEGMENT_WIDTH <- 0.3

POINT_SIZE <- 1.2
POINT_STROKE <- 0.35
POINT_FILL_ALPHA <- 0.15
POINT_OUTLINE_ALPHA <- 0.6

RIBBON_ALPHA <- 0.25
LINE_WIDTH <- 0.8
GAP_LINE_WIDTH <- 0.6

# Ages and follow-up intervals are recorded in whole years, so points would
# otherwise stack into vertical stripes. Jitter is horizontal only - the
# outcome is never displaced - and is seeded so every figure and every rebuild
# places the same point in the same place.
JITTER_SEED <- 1
FIGURE2_JITTER_WIDTH <- 0.5
FIGURE3_JITTER_WIDTH <- 0.15

AGE_AXIS_LABEL <- "Age (years)"
WITHIN_TIME_LABEL <- "Years from first wave"
WITHIN_TIME_BREAKS <- c(0, 2, 4, 6)

FIGURE_WIDTH_MM <- 180
FIGURE_HEIGHT_MM <- 150       # one 3 x 4 grid, no stacked panels
FIGURE_DPI <- 300
GRID_POINTS <- 100

# The average column is set apart from the block of three modality columns by
# roughly one extra panel gap of whitespace. ggplot2 accepts one width per gap
# between panel columns, so this is the gap after column 1 followed by the gaps
# inside the modality block; widen or narrow the break by editing one number.
AVERAGE_COLUMN_GAP <- 16      # points (~5.6 mm at the saved figure width)
MODALITY_COLUMN_GAP <- 4      # points

# A thin rule is drawn in that gap, so the break survives greyscale print
# without tinting any panel: all four panels keep the same white background.
AVERAGE_DIVIDER_COLOUR <- "grey70"
AVERAGE_DIVIDER_WIDTH <- 0.5

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

# The average column's strip label is emphasised by weight alone: same
# typeface, same size, bold. Per-strip text needs ggh4x's themed strips, since
# theme(strip.text.x = ...) styles every column strip at once.
manuscript_strips <- function() {
  ggh4x::strip_themed(
    text_x = ggh4x::elem_list_text(
      face = c("bold", rep("plain", length(MODALITY_COLUMNS) - 1))
    )
  )
}

# The divider is a gtable edit, because no ggplot layer can draw in the gap
# between two panel columns - that space belongs to the layout, not to any
# panel. The rule is inserted into the existing spacing column, so no width
# changes and the panels keep the sizes ggplot2 gave them.
#
# Positions are looked up from the panel grobs rather than hard-coded: the gap
# is the widest layout column between panel column 1 and panel column 2, and
# the rule spans the panel rows only, so it stops short of the column strips
# above and the x axis below.
add_average_divider <- function(figure) {
  table <- ggplotGrob(figure)
  panels <- table$layout[grep("^panel", table$layout$name), ]

  panel_columns <- sort(unique(panels$l))
  panel_rows <- sort(unique(panels$t))
  stopifnot(length(panel_columns) == length(MODALITY_COLUMNS))

  gap_candidates <- seq(panel_columns[[1]] + 1, panel_columns[[2]] - 1)
  gap_widths <- vapply(
    gap_candidates,
    function(i) as.numeric(convertWidth(table$widths[i], "pt")),
    numeric(1)
  )
  gap_column <- gap_candidates[[which.max(gap_widths)]]
  # The gap must be the widened one, not a zero-width layout artefact.
  stopifnot(max(gap_widths) > MODALITY_COLUMN_GAP)

  widths_before <- table$widths
  table <- gtable::gtable_add_grob(
    table,
    linesGrob(
      x = unit(c(0.5, 0.5), "npc"),
      y = unit(c(0, 1), "npc"),
      gp = gpar(col = AVERAGE_DIVIDER_COLOUR, lwd = AVERAGE_DIVIDER_WIDTH)
    ),
    t = min(panel_rows),
    b = max(panel_rows),
    l = gap_column,
    r = gap_column,
    name = "average-divider"
  )
  # Inserting into an existing column cannot resize anything; assert it anyway,
  # because a shifted panel width would break the across-column comparison.
  stopifnot(identical(as.character(widths_before), as.character(table$widths)))

  table
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
# Layer builders. Order is fixed everywhere: raw segments, then points, then
# the CI ribbon, then the model line on top of the data cloud.
# ---------------------------------------------------------------------------
segment_layer <- function(segments) {
  if (is.null(segments)) return(NULL)

  geom_line(
    data = segments,
    aes(x, value, group = participant),
    colour = SEGMENT_COLOUR, alpha = SEGMENT_ALPHA, linewidth = SEGMENT_WIDTH
  )
}

point_layers <- function(points, position) {
  list(
    geom_point(
      data = points,
      aes(x, value, fill = measure, shape = modality),
      colour = NA, alpha = POINT_FILL_ALPHA, size = POINT_SIZE,
      stroke = POINT_STROKE, position = position, show.legend = FALSE
    ),
    geom_point(
      data = points,
      aes(x, value, colour = measure, shape = modality),
      fill = NA, alpha = POINT_OUTLINE_ALPHA, size = POINT_SIZE,
      stroke = POINT_STROKE, position = position
    )
  )
}

model_layers <- function(lines) {
  list(
    geom_ribbon(
      data = lines,
      aes(x, ymin = conf_low, ymax = conf_high, fill = measure,
          group = line_group),
      alpha = RIBBON_ALPHA, colour = NA
    ),
    geom_line(
      data = lines %>% filter(gap_span),
      aes(x, predicted, colour = measure, group = line_group),
      linewidth = GAP_LINE_WIDTH, linetype = "dashed"
    ),
    geom_line(
      data = lines %>% filter(!is.na(solid_segment)),
      aes(x, predicted, colour = measure, group = solid_group),
      linewidth = LINE_WIDTH
    )
  )
}

# ---------------------------------------------------------------------------
# The figure builder. Both manuscript figures are this one 3 x 4 grid: measure
# is the row throughout, and the modality average is the leftmost column of the
# same grid rather than a separate panel stacked above it.
#
# scales = "free_y" is load-bearing. It frees the y scale by ROW and shares it
# within the row, so all four columns of a row sit on one scale, drawn once at
# the left; switch = "y" puts the measure strip where that y title would be.
# scales = "free" would give each of the twelve panels its own y axis and
# destroy the across-column comparison the row exists to support.
# ---------------------------------------------------------------------------
build_measure_modality_figure <- function(points, lines, x_label,
                                          segments = NULL,
                                          position = position_identity(),
                                          x_scale = NULL) {
  figure <- ggplot() +
    segment_layer(segments) +
    point_layers(points, position) +
    model_layers(lines) +
    # facet_grid2 is facet_grid plus per-strip theming; the faceting itself is
    # unchanged, including the load-bearing scales = "free_y".
    ggh4x::facet_grid2(
      measure ~ modality,
      scales = "free_y", switch = "y", labeller = manuscript_labeller,
      strip = manuscript_strips()
    ) +
    scale_measure_colour +
    scale_measure_fill +
    scale_modality_shape +
    guides(shape = "none") +
    labs(x = x_label, y = NULL) +
    manuscript_theme() +
    theme(
      panel.spacing.x = unit(
        c(
          AVERAGE_COLUMN_GAP,
          rep(MODALITY_COLUMN_GAP, length(MODALITY_COLUMNS) - 2)
        ),
        "pt"
      )
    )

  if (!is.null(x_scale)) figure <- figure + x_scale
  figure
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

figure2_modality_lines <- function(data, interaction_models) {
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
      interaction_models[[measure_name]],
      prediction_grid,
      contrasts_option = INTERACTION_CONTRASTS
    ) %>%
      mutate(measure = measure_name, modality = as.character(Modality))
  })
}

figure2_plot_data <- function(data, models, interaction_models) {
  list(
    points = bind_rows(
      figure2_average_points(data),
      figure2_modality_points(data)
    ) %>%
      as_plot_frame(),
    lines = bind_rows(
      figure2_average_lines(data, models),
      figure2_modality_lines(data, interaction_models)
    ) %>%
      as_line_frame()
  )
}

# Takes the frame built above rather than building it, so the figure and the
# checks run on exactly the same rows.
build_figure2 <- function(figure_data) {
  build_measure_modality_figure(
    figure_data$points,
    figure_data$lines,
    AGE_AXIS_LABEL,
    position = position_jitter(
      width = FIGURE2_JITTER_WIDTH, height = 0, seed = JITTER_SEED
    )
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

figure3_modality_lines <- function(data, interaction_models, sessions) {
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
      interaction_models[[measure_name]],
      prediction_grid,
      contrasts_option = INTERACTION_CONTRASTS
    ) %>%
      mutate(measure = measure_name)
  })
}

figure3_plot_data <- function(data, models, interaction_models) {
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
      figure3_modality_lines(data, interaction_models, modality_sessions)
    ) %>%
      as_line_frame()
  )
}

build_figure3 <- function(figure_data) {
  # Points and grey connecting segments are the same rows, so they cannot come
  # apart: the segment joins exactly the two markers it belongs to.
  build_measure_modality_figure(
    figure_data$points,
    figure_data$lines,
    WITHIN_TIME_LABEL,
    segments = figure_data$points,
    x_scale = scale_x_continuous(breaks = WITHIN_TIME_BREAKS)
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
    figure = "Figure 3",
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
    figure = "Figure 2",
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
# must be 3 x 4 with no empty panel, and the four panels of a row must share
# one y scale (which is what scales = "free_y" buys and scales = "free" would
# throw away).
# ---------------------------------------------------------------------------
verify_manuscript_figure <- function(figure, points) {
  panel_counts <- points %>%
    count(measure, modality, .drop = FALSE)

  stopifnot(
    nrow(panel_counts) == length(MEASURES) * length(MODALITY_COLUMNS),
    all(panel_counts$n > 0)
  )

  built <- ggplot_build(figure)
  layout <- built$layout$layout
  stopifnot(nrow(layout) == length(MEASURES) * length(MODALITY_COLUMNS))

  y_limits <- map_dfr(seq_len(nrow(layout)), function(i) {
    range <- built$layout$panel_params[[i]]$y.range
    tibble(
      row = layout$ROW[[i]],
      measure = as.character(layout$measure[[i]]),
      modality = as.character(layout$modality[[i]]),
      y_min = range[[1]],
      y_max = range[[2]]
    )
  })

  row_spread <- y_limits %>%
    group_by(row) %>%
    summarise(
      spread = max(abs(y_min - first(y_min))) + max(abs(y_max - first(y_max))),
      .groups = "drop"
    )
  stopifnot(all(row_spread$spread < 1e-9))

  list(panels = panel_counts, y_limits = y_limits)
}

save_manuscript_figure <- function(figure, directory, name,
                                   height_mm = FIGURE_HEIGHT_MM) {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)

  ggsave(
    file.path(directory, paste0(name, ".pdf")),
    figure,
    width = FIGURE_WIDTH_MM, height = height_mm, units = "mm"
  )
  ggsave(
    file.path(directory, paste0(name, ".png")),
    figure,
    width = FIGURE_WIDTH_MM, height = height_mm, units = "mm", dpi = FIGURE_DPI
  )

  file.path(directory, paste0(name, c(".pdf", ".png")))
}
