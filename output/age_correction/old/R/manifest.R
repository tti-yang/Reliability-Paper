# The manuscript manifest: the ONE place a table or figure number is written.
#
# MANIFEST maps a file in output/ to the place it appears in the manuscript.
# The number lives in `destination` and nowhere else in this repository.
# Moving a table between main and supplement, or renumbering one, is a change
# to `destination` here and to nothing else: script/06_assemble_manuscript.R
# copies the files and rewrites the README's manifest table from this object,
# and every other number the reader sees -- the README, the interactive
# document's prose and headings -- is looked up with manuscript_label().
#
# This lives in R/ rather than in script/06 precisely so the interactive
# document can source it. A number that has to be typed twice is a number that
# will eventually disagree with itself.
#
# `rule_filter` selects rows from a source covering both motion rules; NA
# copies the file whole. It is the only column that changes what is written --
# source, destination, and notes are the description.
#
# `notes` may reference another manifest row with a {{source}} token, or
# {{source|rule_filter}} when a source appears more than once. The token is
# replaced with that row's label, so a note can say "Figure 2 under the liberal
# rule" without anyone typing the 2.

MANIFEST <- tribble(
  ~source,                              ~destination,                    ~rule_filter,                  ~notes,

  # --- main -------------------------------------------------------------
  "figures/figure2_fd04_pct10.png",     "main/figure_2.png",             NA,                            "Between- and within-person age effects on all three outcomes, primary motion rule (FD 0.4 mm / 10%).",
  "figures/figure3_fd04_pct10.png",     "main/figure_3.png",             NA,                            "Pooled magnitude contrast of the reliability and confusability age effects, both age terms, primary rule.",
  "tables/model_estimates.csv",         "main/table_3.csv",              "FD 0.4 mm / 10% (primary)",   "PARTIAL: the primary-rule rows of model_estimates.csv. The liberal-rule rows of the same file are {{tables/model_estimates.csv|FD 0.5 mm / 20% (liberal)}}.",
  "tables/fd04_pct10_interaction_tests.csv", "main/table_4.csv",         NA,                            "Joint age x modality F tests, primary rule.",
  "tables/fd04_pct10_simple_slopes.csv", "main/table_5.csv",             NA,                            "Simple slopes by modality, primary rule.",

  # --- supplement -------------------------------------------------------
  "figures/figure2_fd05_pct20.png",     "supplement/figure_s1.png",      NA,                            "{{figures/figure2_fd04_pct10.png}} under the liberal motion rule (FD 0.5 mm / 20%).",
  "figures/figure3_fd05_pct20.png",     "supplement/figure_s2.png",      NA,                            "{{figures/figure3_fd04_pct10.png}} under the liberal motion rule.",
  "tables/fd04_pct10_demographics.csv", "supplement/table_s1.csv",       NA,                            "Demographics by analytic sample, primary rule.",
  "tables/fd05_pct20_descriptives.csv", "supplement/table_s2.csv",       NA,                            "Descriptive statistics by modality, liberal rule (FD 0.5 mm / 20%).",
  "tables/motion_accounting.csv",       "supplement/table_s3.csv",       NA,                            "Runs assessed and excluded by age group and modality, both rules.",
  "tables/outlier_sensitivity.csv",     "supplement/table_s4.csv",       NA,                            "ALL of outlier_sensitivity.csv: MAD x 3 sensitivity, both rules, all three exclusion variants.",
  "tables/model_estimates.csv",         "supplement/table_s5.csv",       "FD 0.5 mm / 20% (liberal)",   "PARTIAL: the liberal-rule rows of model_estimates.csv. The primary-rule rows are {{tables/model_estimates.csv|FD 0.4 mm / 10% (primary)}}.",
  "tables/fd05_pct20_interaction_tests.csv", "supplement/table_s6.csv",  NA,                            "Joint age x modality F tests, liberal rule.",
  "tables/fd05_pct20_simple_slopes.csv", "supplement/table_s7.csv",      NA,                            "Simple slopes by modality, liberal rule.",
  "tables/contextual_effects.csv",      "supplement/table_s8.csv",       NA,                            "ALL of contextual_effects.csv: b_between - b_within with its Satterthwaite test, both rules.",
  "tables/magnitude_comparison.csv",    "supplement/table_s9.csv",       NA,                            "ALL of magnitude_comparison.csv: magnitude comparison of the age effects on reliability and confusability, both motion rules."
)

# ---------------------------------------------------------------------------
# Reading a number back out of a destination.
#
# "main/figure_2.png" -> Figure 2; "supplement/table_s9.csv" -> Table S9. The
# section and the s-prefix must agree, so a supplement row cannot be numbered
# as a main one by a slip of the keyboard.
# ---------------------------------------------------------------------------
MANIFEST_DESTINATION_PATTERN <-
  "^(main|supplement)/(figure|table)_(s?)([0-9]+)\\.[A-Za-z0-9]+$"

manuscript_destination_parts <- function(destination) {
  matched <- regmatches(
    destination, regexec(MANIFEST_DESTINATION_PATTERN, destination)
  )
  malformed <- destination[lengths(matched) == 0L]
  if (length(malformed) > 0) {
    stop(
      "Manifest destinations must look like main/figure_2.png or ",
      "supplement/table_s9.csv. Malformed: ",
      paste(malformed, collapse = ", ")
    )
  }
  field <- function(i) vapply(matched, `[[`, character(1), i)

  parts <- tibble(
    destination = destination,
    section = field(2L),
    kind = field(3L),
    supplement = field(4L) == "s",
    number = as.integer(field(5L))
  )
  mismatched <- parts$destination[(parts$section == "supplement") != parts$supplement]
  if (length(mismatched) > 0) {
    stop(
      "A supplement destination needs an s-prefixed number and a main one ",
      "must not have it. Mismatched: ", paste(mismatched, collapse = ", ")
    )
  }
  parts
}

manuscript_label_from_destination <- function(destination) {
  parts <- manuscript_destination_parts(destination)
  paste0(
    if_else(parts$kind == "figure", "Figure ", "Table "),
    if_else(parts$supplement, "S", ""),
    parts$number
  )
}

# The lookup every other file uses. `source` is the path under output/;
# rule_filter disambiguates a source that appears in the manifest twice.
manuscript_label <- function(source, rule_filter = NA_character_) {
  stopifnot(length(source) == 1L, length(rule_filter) == 1L)
  rows <- MANIFEST[MANIFEST$source == source, ]
  if (!is.na(rule_filter)) {
    rows <- rows[!is.na(rows$rule_filter) & rows$rule_filter == rule_filter, ]
  }
  if (nrow(rows) == 0L) {
    stop("No manifest entry for '", source, "'",
         if (!is.na(rule_filter)) paste0(" with rule_filter '", rule_filter, "'"),
         ".")
  }
  if (nrow(rows) > 1L) {
    stop(
      "'", source, "' appears ", nrow(rows), " times in the manifest; pass ",
      "rule_filter to choose one of: ",
      paste(rows$rule_filter, collapse = " | ")
    )
  }
  manuscript_label_from_destination(rows$destination)
}

# ---------------------------------------------------------------------------
# {{source}} / {{source|rule_filter}} references inside notes.
# ---------------------------------------------------------------------------
MANIFEST_TOKEN_PATTERN <- "\\{\\{[^{}]+\\}\\}"

expand_manifest_tokens <- function(text) {
  vapply(text, function(one) {
    if (is.na(one)) return(NA_character_)
    repeat {
      position <- regexpr(MANIFEST_TOKEN_PATTERN, one)
      if (position == -1L) break
      inner <- sub("^\\{\\{(.*)\\}\\}$", "\\1", regmatches(one, position))
      pieces <- trimws(strsplit(inner, "|", fixed = TRUE)[[1]])
      regmatches(one, position) <- manuscript_label(
        pieces[[1]],
        if (length(pieces) > 1L) pieces[[2]] else NA_character_
      )
    }
    one
  }, character(1), USE.NAMES = FALSE)
}

# ---------------------------------------------------------------------------
# The manifest as a table, and as the markdown block the README carries.
# ---------------------------------------------------------------------------
manifest_table <- function() {
  MANIFEST %>%
    mutate(
      label = manuscript_label_from_destination(destination),
      notes = expand_manifest_tokens(notes)
    ) %>%
    bind_cols(manuscript_destination_parts(.$destination) %>%
                select(section, kind, supplement, number)) %>%
    select(label, section, kind, supplement, number, destination, source,
           rule_filter, notes)
}

manifest_markdown <- function() {
  entries <- manifest_table()
  c(
    "| Number | Manuscript file | Source in `output/` | Notes |",
    "| --- | --- | --- | --- |",
    sprintf(
      "| %s | `manuscript/%s` | `%s` | %s |",
      entries$label, entries$destination, entries$source, entries$notes
    )
  )
}

# The current assignment, with any gap in a run of numbers called out. Gaps are
# legitimate -- a manuscript can hold tables this pipeline does not produce --
# so this reports them rather than failing on them.
manuscript_numbering <- function() {
  manifest_table() %>%
    arrange(kind, supplement, number) %>%
    group_by(kind, supplement) %>%
    summarise(
      assigned = paste(label, collapse = ", "),
      gaps = {
        expected <- seq_len(max(number))
        missing <- setdiff(expected, number)
        if (length(missing) == 0) "none" else paste(missing, collapse = ", ")
      },
      .groups = "drop"
    )
}

# ---------------------------------------------------------------------------
# Checked at source time: a manifest that cannot be trusted is worse than none.
# ---------------------------------------------------------------------------
validate_manifest <- function() {
  duplicated_destinations <- MANIFEST$destination[duplicated(MANIFEST$destination)]
  if (length(duplicated_destinations) > 0) {
    stop(
      "Two manifest rows claim the same manuscript number: ",
      paste(unique(duplicated_destinations), collapse = ", ")
    )
  }
  # Parses the destinations and enforces the section/s-prefix agreement.
  invisible(manuscript_destination_parts(MANIFEST$destination))

  known_rules <- vapply(MOTION_RULES, `[[`, character(1), "label")
  unknown <- setdiff(na.omit(MANIFEST$rule_filter), known_rules)
  if (length(unknown) > 0) {
    stop(
      "rule_filter values must match a MOTION_RULES label. Unknown: ",
      paste(unknown, collapse = ", ")
    )
  }
  # Resolves every {{...}} note reference, so a broken cross-reference is
  # caught here rather than printed into the README.
  invisible(expand_manifest_tokens(MANIFEST$notes))
  invisible(TRUE)
}

validate_manifest()
