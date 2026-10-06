# Reading the raw files and building the analytic data.
#
# Everything here is a plain function of (fd_cutoff, pct_cutoff) so the
# interactive document and the batch scripts share one implementation.
#
# load_source_data() returns the four objects the build_* functions look up in
# the global environment; callers put them there with list2env(). The lookup by
# name is how the original document worked and is kept so the analysis
# functions below are unchanged.

# The prepared outcome files hold the 2,000-vertex motion-corrected measures:
# df_mind_all.csv is the FD 0.5 mm scrubbing pipeline and df_mind_all_mc04.csv
# the FD 0.4 mm pipeline. Each is keyed to the matching run-level motion file.
OUTCOME_FILES <- c(
  "0.5" = "df_mind_all.csv",
  "0.4" = "df_mind_all_mc04.csv"
)
MOTION_FILES <- c(
  "0.5" = "motion_exclusion_by_run_5mm.csv",
  "0.4" = "motion_exclusion_by_run_4mm.csv"
)

# num_threads = 1 is deliberate: the multi-threaded readr parser segfaults on
# these files.
read_data_file <- function(filename) {
  readr::read_csv(
    file.path(RAW_DATA_DIR, filename),
    num_threads = 1,
    show_col_types = FALSE
  )
}

prepare_outcome_data <- function(data) {
  data %>%
    filter(!is.na(SubNum)) %>%
    pivot_longer(
      cols = matches("^(Aud|Mot|Vis)(Distinctiveness|Reliability|Confusability)$"),
      names_to = c("Modality", ".value"),
      names_pattern = "(Aud|Mot|Vis)(.*)"
    ) %>%
    mutate(Modality = factor(Modality, levels = c("Aud", "Mot", "Vis"))) %>%
    # Wave 3 is dropped here, i.e. before the motion-exclusion accounting, so
    # the run counts reported in the manuscript are Waves 1-2 only.
    filter(Wave_Num %in% ANALYSIS_WAVES)
}

load_source_data <- function() {
  missing <- c(OUTCOME_FILES, MOTION_FILES)
  missing <- missing[!file.exists(file.path(RAW_DATA_DIR, missing))]
  if (length(missing) > 0) {
    stop(
      "Missing raw data files in ", RAW_DATA_DIR, ": ",
      paste(missing, collapse = ", ")
    )
  }

  outcome_data <- lapply(OUTCOME_FILES, function(filename) {
    prepare_outcome_data(read_data_file(filename))
  })

  motion_exclusions <- lapply(MOTION_FILES, read_data_file)

  healthy_subject_ids <- bind_rows(outcome_data) %>%
    filter(Subgroup == 1) %>%
    distinct(Subject) %>%
    pull(Subject)

  subject_age_groups <- bind_rows(outcome_data) %>%
    filter(Subgroup == 1) %>%
    distinct(Subject, Age_DuringParticipation_) %>%
    transmute(
      Subject,
      Age_Group = factor(
        if_else(
          Age_DuringParticipation_ < OLDER_ADULT_AGE,
          "Young adults",
          "Older adults"
        ),
        levels = c("Young adults", "Older adults")
      )
    ) %>%
    distinct(Subject, Age_Group)

  list(
    outcome_data = outcome_data,
    motion_exclusions = motion_exclusions,
    healthy_subject_ids = healthy_subject_ids,
    subject_age_groups = subject_age_groups
  )
}

build_run_flags <- function(fd_cutoff, pct_cutoff) {
  motion_exclusions[[fd_cutoff]] %>%
    filter(
      subject %in% healthy_subject_ids,
      session == "placebo",
      run == "001",
      experiment %in% c("auditory", "visual", "motor")
    ) %>%
    transmute(
      Subject = subject,
      Modality = recode(
        experiment,
        auditory = "Aud",
        motor = "Mot",
        visual = "Vis"
      ),
      pct_excluded,
      exclude = pct_excluded >= pct_cutoff
    )
}

build_joined_data <- function(fd_cutoff, pct_cutoff) {
  outcome_data[[fd_cutoff]] %>%
    left_join(
      build_run_flags(fd_cutoff, pct_cutoff),
      by = c("Subject", "Modality")
    )
}

build_motion_filtered_data <- function(fd_cutoff, pct_cutoff) {
  build_joined_data(fd_cutoff, pct_cutoff) %>%
    # Intended behaviour, confirmed against the reported sample sizes: a
    # session x modality with NO run-level motion record is DROPPED, not
    # retained. `!exclude` already drops NA, but the NA test is written out so
    # the intent is explicit and is not mistaken for the earlier
    # `is.na(exclude) | !exclude` behaviour, which kept unassessed rows.
    filter(!is.na(exclude), !exclude)
}

count_missing_motion_records <- function(fd_cutoff, pct_cutoff) {
  build_joined_data(fd_cutoff, pct_cutoff) %>%
    filter(Subgroup == 1, is.na(exclude)) %>%
    nrow()
}

add_age_decomposition <- function(data) {
  data %>%
    group_by(SubNum) %>%
    mutate(
      n_waves = n_distinct(Wave_Num),
      mean_age = if_else(
        n_waves > 1,
        mean(Age_DuringParticipation_, na.rm = TRUE),
        Age_DuringParticipation_
      ),
      within_cAge = if_else(
        n_waves > 1,
        Age_DuringParticipation_ - mean_age,
        0
      ),
      between_cAge = mean_age - OLDER_ADULT_AGE,
      aud_mot = case_when(
        Modality == "Aud" ~ -1,
        Modality == "Mot" ~ 1,
        TRUE ~ 0
      ),
      aud_vis = case_when(
        Modality == "Aud" ~ -1,
        Modality == "Vis" ~ 1,
        TRUE ~ 0
      )
    ) %>%
    ungroup()
}

build_analysis_data <- function(fd_cutoff, pct_cutoff) {
  build_motion_filtered_data(fd_cutoff, pct_cutoff) %>%
    filter(Subgroup == 1, Wave_Num %in% ANALYSIS_WAVES) %>%
    add_age_decomposition()
}

# ---------------------------------------------------------------------------
# The handoff between stages. 01 writes analytic data; 02 writes the prepared
# Figure 2-3 data so 05 can render figures without fitting models.
# ---------------------------------------------------------------------------
DERIVED_FILES <- c(
  analysis_data_by_rule = "analysis_data_by_rule.rds",
  run_flags_by_rule = "run_flags_by_rule.rds",
  subject_age_groups = "subject_age_groups.rds",
  figure_data_by_rule = "figure_data_by_rule.rds"
)

save_derived <- function(objects) {
  dir.create(DERIVED_DATA_DIR, showWarnings = FALSE, recursive = TRUE)
  for (name in names(objects)) {
    saveRDS(objects[[name]], file.path(DERIVED_DATA_DIR, DERIVED_FILES[[name]]))
  }
  file.path(DERIVED_DATA_DIR, DERIVED_FILES[names(objects)])
}

read_derived <- function(name) {
  path <- file.path(DERIVED_DATA_DIR, DERIVED_FILES[[name]])
  if (!file.exists(path)) {
    producer <- if (name == "figure_data_by_rule") {
      "script/02_fit_models.R"
    } else "script/01_prepare_data.R"
    stop("Missing ", path, ". Run ", producer, " first.")
  }
  readRDS(path)
}

# Builds the analytic data straight from data/raw/, for the interactive
# document, which is not part of the numbered pipeline and should not depend on
# 01 having been run.
build_all_from_source <- function() {
  list2env(load_source_data(), globalenv())

  list(
    analysis_data_by_rule = setNames(
      lapply(MOTION_RULES, function(rule) {
        build_analysis_data(rule$fd_cutoff, rule$pct_cutoff)
      }),
      rule_keys()
    ),
    run_flags_by_rule = setNames(
      lapply(MOTION_RULES, function(rule) {
        build_run_flags(rule$fd_cutoff, rule$pct_cutoff)
      }),
      rule_keys()
    )
  )
}
