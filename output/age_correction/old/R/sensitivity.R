# MAD x 3 outlier sensitivity.
#
# Outliers are flagged per outcome separately within each modality, because the
# auditory, motor, and visual distributions differ enough that pooling them
# inflates the MAD and flags almost nothing. R's mad() already applies the
# 1.4826 consistency constant.

add_mad_outlier_flags <- function(data) {
  data %>%
    group_by(Modality) %>%
    mutate(
      across(
        all_of(OUTCOMES),
        ~ !is.na(.x) &
          abs(.x - median(.x, na.rm = TRUE)) >
            MAD_THRESHOLD * mad(.x, na.rm = TRUE),
        .names = "outlier_{.col}"
      )
    ) %>%
    ungroup() %>%
    mutate(
      outlier_any = if_any(starts_with("outlier_"))
    )
}

mad_outlier_counts <- function(data) {
  flagged <- add_mad_outlier_flags(data)

  by_outcome <- map_dfr(OUTCOMES, function(outcome) {
    indicator <- flagged[[paste0("outlier_", outcome)]]
    tibble(
      Outcome = outcome,
      `Observations flagged` = sum(indicator),
      `Observations flagged (%)` = 100 * mean(indicator),
      `Participants affected` = n_distinct(flagged$SubNum[indicator])
    )
  })

  bind_rows(
    by_outcome,
    tibble(
      Outcome = "Any outcome",
      `Observations flagged` = sum(flagged$outlier_any),
      `Observations flagged (%)` = 100 * mean(flagged$outlier_any),
      `Participants affected` =
        n_distinct(flagged$SubNum[flagged$outlier_any])
    )
  )
}

build_outlier_variants <- function(data) {
  flagged <- add_mad_outlier_flags(data)
  affected_participants <- flagged %>%
    filter(outlier_any) %>%
    distinct(SubNum) %>%
    pull(SubNum)

  list(
    `Full sample` = flagged,
    `Drop flagged observations` = flagged %>% filter(!outlier_any),
    `Drop flagged participants` = flagged %>%
      filter(!SubNum %in% affected_participants)
  )
}

# Rows removed by each exclusion variant, by wave. Counted from the same
# variants the models are refit on, so the numbers match the comparison table.
outlier_drops_by_wave <- function(data) {
  variants <- build_outlier_variants(data)
  count_by_wave <- function(rows) {
    rows %>%
      count(Wave_Num, name = "n") %>%
      tidyr::complete(Wave_Num = sort(unique(data$Wave_Num)),
                      fill = list(n = 0L))
  }

  full <- count_by_wave(variants$`Full sample`)
  by_wave <- tibble(
    Wave = paste("Wave", full$Wave_Num),
    `Analytic observations` = full$n,
    `Dropped: flagged observations` =
      full$n - count_by_wave(variants$`Drop flagged observations`)$n,
    `Dropped: flagged participants` =
      full$n - count_by_wave(variants$`Drop flagged participants`)$n
  )

  bind_rows(
    by_wave,
    by_wave %>%
      summarise(across(-Wave, sum)) %>%
      mutate(Wave = "Total", .before = 1)
  )
}

outlier_sensitivity_table <- function(data, rule_label_text = NA_character_) {
  variants <- build_outlier_variants(data)

  # Rows per wave entering one model, with the same complete-case filter
  # fit_model() applies (model@frame does not carry Wave_Num).
  wave_counts <- function(rows, outcome) {
    waves <- rows %>%
      drop_na(all_of(c(outcome, MODEL_TERMS, "SubNum"))) %>%
      pull(Wave_Num)
    vapply(ANALYSIS_WAVES, function(w) sum(waves == w), integer(1))
  }

  map_dfr(OUTCOMES, function(outcome) {
    full_by_wave <- wave_counts(variants$`Full sample`, outcome)

    map_dfr(names(variants), function(variant) {
      model <- fit_model(variants[[variant]], outcome)
      model_frame <- model@frame
      coefficients <- summary(model)$coefficients
      by_wave <- wave_counts(variants[[variant]], outcome)
      stopifnot(sum(by_wave) == nrow(model_frame))

      tibble(
        `Motion rule` = rule_label_text,
        Outcome = outcome,
        `Exclusion variant` = variant,
        `N observations` = nrow(model_frame),
        `N participants` = n_distinct(model_frame$SubNum),
        # Per wave: observations in the model, and observations removed
        # relative to the full sample for the same outcome.
        !!!setNames(
          as.list(by_wave),
          paste("N observations Wave", ANALYSIS_WAVES)
        ),
        !!!setNames(
          as.list(full_by_wave - by_wave),
          paste("N dropped Wave", ANALYSIS_WAVES)
        ),
        age_between_b = coefficients["between_cAge", "Estimate"],
        age_between_SE = coefficients["between_cAge", "Std. Error"],
        age_between_df = coefficients["between_cAge", "df"],
        age_between_p = coefficients["between_cAge", "Pr(>|t|)"],
        age_within_b = coefficients["within_cAge", "Estimate"],
        age_within_SE = coefficients["within_cAge", "Std. Error"],
        age_within_df = coefficients["within_cAge", "df"],
        age_within_p = coefficients["within_cAge", "Pr(>|t|)"]
      )
    })
  })
}

format_outlier_sensitivity <- function(table) {
  table %>%
    mutate(
      across(
        c(age_between_b, age_between_SE, age_within_b, age_within_SE),
        ~ sprintf("%.5f", .x)
      ),
      across(c(age_between_df, age_within_df), ~ sprintf("%.1f", .x)),
      across(c(age_between_p, age_within_p), format_p)
    ) %>%
    select(-any_of("Motion rule")) %>%
    rename(
      `age_between b` = age_between_b,
      `age_between SE` = age_between_SE,
      `age_between df` = age_between_df,
      `age_between p` = age_between_p,
      `age_within b` = age_within_b,
      `age_within SE` = age_within_SE,
      `age_within df` = age_within_df,
      `age_within p` = age_within_p
    )
}
