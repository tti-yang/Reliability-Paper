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

outlier_sensitivity_table <- function(data, rule_label_text = NA_character_) {
  variants <- build_outlier_variants(data)

  map_dfr(OUTCOMES, function(outcome) {
    map_dfr(names(variants), function(variant) {
      model <- fit_model(variants[[variant]], outcome)
      model_frame <- model@frame
      coefficients <- summary(model)$coefficients

      tibble(
        `Motion rule` = rule_label_text,
        Outcome = outcome,
        `Exclusion variant` = variant,
        `N observations` = nrow(model_frame),
        `N participants` = n_distinct(model_frame$SubNum),
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
