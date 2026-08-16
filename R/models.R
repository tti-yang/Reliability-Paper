# Mixed-effects models, the modality interaction, the contextual effect, and
# the table builders behind output/tables/.

# ---------------------------------------------------------------------------
# Main models.
# ---------------------------------------------------------------------------
fit_model <- function(data, outcome) {
  model_data <- data %>%
    drop_na(all_of(c(outcome, MODEL_TERMS, "SubNum")))

  if (nrow(model_data) == 0) {
    stop("No complete observations are available for ", outcome)
  }

  lmer(
    reformulate(
      c(MODEL_TERMS, "(1 | SubNum)"),
      response = outcome
    ),
    data = model_data,
    REML = FALSE
  )
}

fit_outcome_models <- function(data) {
  setNames(
    lapply(OUTCOMES, function(outcome) fit_model(data, outcome)),
    OUTCOMES
  )
}

# ---------------------------------------------------------------------------
# Modality-specific age effects.
# ---------------------------------------------------------------------------
INTERACTION_MODALITY_LEVELS <- c("Auditory", "Visual", "Motor")
INTERACTION_CONTRASTS <- c("contr.sum", "contr.poly")
AGE_TERMS <- c("between_cAge", "within_cAge")

prepare_interaction_data <- function(data) {
  data %>%
    mutate(
      Modality = factor(
        recode(
          as.character(Modality),
          Aud = "Auditory",
          Vis = "Visual",
          Mot = "Motor"
        ),
        levels = INTERACTION_MODALITY_LEVELS
      )
    )
}

fit_interaction_model <- function(data, outcome) {
  # contr.sum is required for a valid Type III test of a factor that appears in
  # an interaction; the previous setting is restored on exit so the main models
  # and their manual numeric contrasts are untouched.
  previous_contrasts <- options(contrasts = INTERACTION_CONTRASTS)
  on.exit(options(previous_contrasts), add = TRUE)

  model_data <- prepare_interaction_data(data) %>%
    drop_na(all_of(c(
      outcome, "between_cAge", "within_cAge", "Sex_M1", "Education", "SubNum"
    )))

  lmer(
    reformulate(
      c(
        "(between_cAge + within_cAge) * Modality",
        "Sex_M1", "Education", "(1 | SubNum)"
      ),
      response = outcome
    ),
    data = model_data,
    REML = FALSE
  )
}

fit_interaction_models <- function(data) {
  setNames(
    lapply(OUTCOMES, function(outcome) fit_interaction_model(data, outcome)),
    OUTCOMES
  )
}

interaction_tests_table <- function(interaction_models) {
  map_dfr(OUTCOMES, function(outcome) {
    # lmerTest's anova() is Type III with Satterthwaite denominator df.
    anova_table <- anova(interaction_models[[outcome]])

    map_dfr(AGE_TERMS, function(age_term) {
      row <- paste0(age_term, ":Modality")
      tibble(
        outcome = outcome,
        age_term = age_term,
        F = anova_table[row, "F value"],
        df1 = anova_table[row, "NumDF"],
        df2 = anova_table[row, "DenDF"],
        p = anova_table[row, "Pr(>F)"]
      )
    })
  })
}

modality_trends <- function(model, age_term) {
  # lmer.df is always passed explicitly so emmeans never falls back to
  # Kenward-Roger for these models.
  emmeans::emtrends(
    model,
    ~ Modality,
    var = age_term,
    lmer.df = "satterthwaite",
    infer = c(TRUE, TRUE)
  )
}

simple_slopes_table <- function(interaction_models, tests) {
  gate <- tests %>%
    transmute(outcome, age_term, interaction_significant = p < .05)

  map_dfr(OUTCOMES, function(outcome) {
    map_dfr(AGE_TERMS, function(age_term) {
      summary(modality_trends(interaction_models[[outcome]], age_term)) %>%
        as_tibble() %>%
        transmute(
          outcome = outcome,
          age_term = age_term,
          modality = as.character(Modality),
          slope = .data[[paste0(age_term, ".trend")]],
          SE,
          df,
          lower.CL,
          upper.CL,
          t = t.ratio,
          p = p.value
        )
    })
  }) %>%
    left_join(gate, by = c("outcome", "age_term"))
}

slope_contrasts_table <- function(interaction_models) {
  map_dfr(OUTCOMES, function(outcome) {
    map_dfr(AGE_TERMS, function(age_term) {
      trends <- modality_trends(interaction_models[[outcome]], age_term)
      summary(pairs(trends, adjust = "holm")) %>%
        as_tibble() %>%
        transmute(
          outcome = outcome,
          age_term = age_term,
          contrast = as.character(contrast),
          estimate,
          SE,
          df,
          t = t.ratio,
          p_holm = p.value
        )
    })
  })
}

compute_interaction_results <- function(data) {
  interaction_models <- fit_interaction_models(data)
  tests <- interaction_tests_table(interaction_models)

  list(
    models = interaction_models,
    tests = tests,
    slopes = simple_slopes_table(interaction_models, tests),
    contrasts = slope_contrasts_table(interaction_models)
  )
}

# ---------------------------------------------------------------------------
# Contextual effect: does the between-person age slope differ from the
# within-person one?
#
# Estimates, SEs, t and p agree to floating-point noise. Satterthwaite df are
# the exception: they come from numerical derivatives of the profiled
# likelihood, so the two parameterisations agree only to ~1e-5 and get their
# own tolerance.
# ---------------------------------------------------------------------------
CONTEXTUAL_TOLERANCE <- 1e-8
CONTEXTUAL_DF_TOLERANCE <- 1e-3

# Same rows, same estimator, same random effect as fit_model(); only the two
# age columns are re-expressed.
fit_contextual_model <- function(data, outcome) {
  model_data <- data %>%
    drop_na(all_of(c(outcome, MODEL_TERMS, "SubNum"))) %>%
    mutate(age_session_c = within_cAge + between_cAge)

  lmer(
    reformulate(
      c("age_session_c", setdiff(MODEL_TERMS, "within_cAge"), "(1 | SubNum)"),
      response = outcome
    ),
    data = model_data,
    REML = FALSE
  )
}

contextual_contrast <- function(model) {
  L <- setNames(rep(0, length(fixef(model))), names(fixef(model)))
  L[["within_cAge"]] <- -1
  L[["between_cAge"]] <- 1
  lmerTest::contest1D(model, L, ddf = "Satterthwaite")
}

contextual_effects_table <- function(data, rule_label_text) {
  map_dfr(OUTCOMES, function(outcome) {
    model <- fit_model(data, outcome)
    reparameterised <- fit_contextual_model(data, outcome)

    original <- summary(model)$coefficients
    repar <- summary(reparameterised)$coefficients
    contrast <- contextual_contrast(model)

    # A reparameterisation, not a different model: the slope on session age is
    # the original within-person slope and the fit is identical.
    stopifnot(
      abs(repar["age_session_c", "Estimate"] -
        original["within_cAge", "Estimate"]) < CONTEXTUAL_TOLERANCE,
      abs(as.numeric(logLik(reparameterised)) - as.numeric(logLik(model))) <
        CONTEXTUAL_TOLERANCE
    )

    result <- tibble(
      motion_rule = rule_label_text,
      outcome = outcome,
      estimate = repar["between_cAge", "Estimate"],
      se = repar["between_cAge", "Std. Error"],
      df = repar["between_cAge", "df"],
      t = repar["between_cAge", "t value"],
      p = repar["between_cAge", "Pr(>|t|)"]
    )

    # ... and the contrast on the original model must land in the same place.
    stopifnot(
      abs(result$estimate - contrast[["Estimate"]]) < CONTEXTUAL_TOLERANCE,
      abs(result$se - contrast[["Std. Error"]]) < CONTEXTUAL_TOLERANCE,
      abs(result$t - contrast[["t value"]]) < CONTEXTUAL_TOLERANCE,
      abs(result$p - contrast[["Pr(>|t|)"]]) < CONTEXTUAL_TOLERANCE,
      abs(result$df - contrast[["df"]]) < CONTEXTUAL_DF_TOLERANCE
    )

    result
  })
}

# ---------------------------------------------------------------------------
# Table builders for output/tables/.
# ---------------------------------------------------------------------------
sample_definitions <- function(data) {
  returner_ids <- data %>%
    distinct(SubNum, Wave_Num) %>%
    count(SubNum, name = "n_retained_waves") %>%
    filter(n_retained_waves >= 2) %>%
    pull(SubNum)

  young_wave1 <- data %>%
    filter(Wave_Num == 1, Age_DuringParticipation_ < OLDER_ADULT_AGE)
  older_wave1 <- data %>%
    filter(Wave_Num == 1, Age_DuringParticipation_ >= OLDER_ADULT_AGE)

  list(
    `Young adults, Wave 1` = young_wave1,
    `Older adults, Wave 1` = older_wave1,
    `Older adults, Wave 2 (returners)` = data %>%
      filter(
        Wave_Num == 2,
        Age_DuringParticipation_ >= OLDER_ADULT_AGE,
        SubNum %in% returner_ids
      ),
    `Older adults, Wave 1 (Wave 2 returners)` = older_wave1 %>%
      filter(SubNum %in% returner_ids)
  )
}

demographics_export <- function(data, rule_label_text) {
  samples <- sample_definitions(data)

  map_dfr(names(samples), function(sample_name) {
    participants <- samples[[sample_name]] %>%
      distinct(SubNum, .keep_all = TRUE)

    tibble(
      motion_rule = rule_label_text,
      sample = sample_name,
      n = nrow(participants),
      age_m = mean(participants$Age_DuringParticipation_, na.rm = TRUE),
      age_sd = sd(participants$Age_DuringParticipation_, na.rm = TRUE),
      age_min = min(participants$Age_DuringParticipation_, na.rm = TRUE),
      age_max = max(participants$Age_DuringParticipation_, na.rm = TRUE),
      education_m = mean(participants$Education, na.rm = TRUE),
      education_sd = sd(participants$Education, na.rm = TRUE),
      n_men = sum(participants$Sex_M1 == 1, na.rm = TRUE),
      n_women = sum(participants$Sex_M1 == 2, na.rm = TRUE)
    )
  })
}

descriptives_export <- function(data, rule_label_text) {
  samples <- sample_definitions(data)

  map_dfr(names(samples), function(sample_name) {
    samples[[sample_name]] %>%
      mutate(
        modality = recode(
          as.character(Modality),
          Aud = "Auditory",
          Mot = "Motor",
          Vis = "Visual"
        )
      ) %>%
      group_by(modality) %>%
      summarise(
        n = sum(!is.na(Reliability)),
        reliability_m = mean(Reliability, na.rm = TRUE),
        reliability_sd = sd(Reliability, na.rm = TRUE),
        confusability_m = mean(Confusability, na.rm = TRUE),
        confusability_sd = sd(Confusability, na.rm = TRUE),
        distinctiveness_m = mean(Distinctiveness, na.rm = TRUE),
        distinctiveness_sd = sd(Distinctiveness, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        motion_rule = rule_label_text,
        sample = sample_name,
        .before = 1
      )
  })
}

# The run flags and the age groups are passed in rather than looked up, because
# 02 reads them from data/derived/ and never loads data/raw/.
motion_accounting_export <- function(run_flags_by_rule, subject_age_groups) {
  map_dfr(MOTION_RULES, function(rule) {
    flags <- run_flags_by_rule[[rule$key]] %>%
      left_join(subject_age_groups, by = "Subject") %>%
      mutate(
        age_group = as.character(Age_Group),
        modality = recode(
          as.character(Modality),
          Aud = "Auditory",
          Mot = "Motor",
          Vis = "Visual"
        )
      )

    summarise_flags <- function(grouped) {
      grouped %>%
        summarise(
          runs_assessed = n(),
          runs_excluded = sum(exclude, na.rm = TRUE),
          pct_runs_excluded = 100 * mean(exclude, na.rm = TRUE),
          mean_pct_volumes_scrubbed = mean(pct_excluded, na.rm = TRUE),
          .groups = "drop"
        )
    }

    bind_rows(
      summarise_flags(flags %>% group_by(age_group, modality)),
      summarise_flags(flags %>% group_by(age_group)) %>%
        mutate(modality = "All modalities"),
      summarise_flags(flags %>% group_by(modality)) %>%
        mutate(age_group = "All participants"),
      summarise_flags(flags %>% group_by()) %>%
        mutate(age_group = "All participants", modality = "All modalities")
    ) %>%
      mutate(motion_rule = rule$label, .before = 1) %>%
      select(
        motion_rule, age_group, modality, runs_assessed, runs_excluded,
        pct_runs_excluded, mean_pct_volumes_scrubbed
      )
  })
}

model_estimates_export <- function(analysis_data_by_rule) {
  map_dfr(MOTION_RULES, function(rule) {
    data <- analysis_data_by_rule[[rule$key]]
    outcome_models <- fit_outcome_models(data)

    map_dfr(OUTCOMES, function(outcome) {
      model <- outcome_models[[outcome]]
      summary(model)$coefficients %>%
        as.data.frame() %>%
        rownames_to_column("term") %>%
        as_tibble() %>%
        transmute(
          motion_rule = rule$label,
          outcome = outcome,
          term,
          estimate = Estimate,
          se = `Std. Error`,
          df,
          t = `t value`,
          p = `Pr(>|t|)`,
          n_observations = nrow(model@frame),
          n_participants = n_distinct(model@frame$SubNum)
        )
    })
  })
}

# ---------------------------------------------------------------------------
# Display formatting, used by the interactive document only.
# ---------------------------------------------------------------------------
format_interaction_tests <- function(tests) {
  tests %>%
    transmute(
      Outcome = outcome,
      `Age term` = age_term,
      F = sprintf("%.2f", F),
      df1,
      df2 = sprintf("%.1f", df2),
      p = format_p(p),
      `Interaction significant` = if_else(p < .05, "Yes", "No")
    )
}

format_simple_slopes <- function(slopes) {
  slopes %>%
    transmute(
      Outcome = outcome,
      `Age term` = age_term,
      Modality = modality,
      Slope = sprintf("%.5f", slope),
      SE = sprintf("%.5f", SE),
      df = sprintf("%.1f", df),
      `95% CI` = sprintf("[%.5f, %.5f]", lower.CL, upper.CL),
      t = sprintf("%.2f", t),
      p = format_p(p),
      `Interaction significant` = if_else(interaction_significant, "Yes", "No")
    )
}

format_slope_contrasts <- function(contrasts) {
  contrasts %>%
    transmute(
      Outcome = outcome,
      `Age term` = age_term,
      Contrast = contrast,
      Estimate = sprintf("%.5f", estimate),
      SE = sprintf("%.5f", SE),
      df = sprintf("%.1f", df),
      t = sprintf("%.2f", t),
      `p (Holm)` = format_p(p_holm)
    )
}

format_contextual_effects <- function(table) {
  table %>%
    transmute(
      Outcome = outcome,
      `Contextual effect` = sprintf("%.5f", estimate),
      SE = sprintf("%.5f", se),
      df = sprintf("%.1f", df),
      t = sprintf("%.2f", t),
      p = format_p(p),
      `Slopes differ` = if_else(p < .05, "Yes", "No")
    )
}
