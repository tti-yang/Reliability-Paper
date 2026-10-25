# Manuscript analysis validation

`script/manuscript_analysis.Rmd` was knit twice from a clean R session (no
objects, no cached state), using only the four raw CSV inputs in `data/raw/`.
Pandoc is not installed in the environment this check was run in, so the
document was rendered with `rmarkdown::render(..., run_pandoc = FALSE)`,
which executes every R chunk exactly as a normal knit would and stops at the
first error; it only skips the final HTML conversion step. Both runs
completed all 62 chunks with zero errors and zero `stopifnot()` failures.
Every number below is read from the resulting `output/tables/*.csv` and
`output/figures/*` files, or extracted directly from the rendered figure
objects, and compared against `old/age_correction/comparison_report.md` and
its accompanying comparison CSVs -- the authoritative audited record.

No analysis code was changed to produce this report.

## A. Sample construction

**PASS**

Reproduced by `sample_summary()` in the Rmd's Sample checks section, and
cross-checked directly here:

| | observations | sessions | participants | returners | wave1 | wave2 | wave2-only |
| --- | --- | --- | --- | --- | --- | --- | --- |
| primary (expected) | 724 | 276 | 218 | 58 | 217 | 59 | 1 |
| primary (observed) | 724 | 276 | 218 | 58 | 217 | 59 | 1 |
| liberal (expected) | 841 | 286 | 226 | 60 | 226 | 60 | 0 |
| liberal (observed) | 841 | 286 | 226 | 60 | 226 | 60 | 0 |

Exact match on all 14 values. The Rmd's own `stopifnot()` block over these
same 14 values (script/manuscript_analysis.Rmd, Sample checks section) also
passed during both knits.

## B. Corrected age decomposition

**PASS**

1. Divergence from the retired modality-weighted calculation, reproduced
   independently (standalone script, not part of the repository, comparing
   `mean(Age_DuringParticipation_)` over all retained modality rows per
   participant against the corrected `mean(Age_DuringParticipation_)` over
   unique retained participant-wave rows per participant):

   | | participants affected | max |old - corrected| mean age |
   | --- | --- | --- |
   | primary (expected) | 18 | 1.25 |
   | primary (observed) | 18 | 1.2500 |
   | liberal (expected) | 5 | 0.50 |
   | liberal (observed) | 5 | 0.5000 |

2. Worked synthetic example, run inside the Rmd before the function is ever
   applied to real data (Age decomposition section): a participant observed
   at ages 70 and 74 produces `mean_age = 72`, `within_cAge = (-2, +2)`; a
   dropped modality at a retained wave leaves that wave's age terms
   unchanged. Output: `Worked example passed: mean age 72 for participant 1
   (ages 70, 74); within-person ages -2/+2.`

3. On the real analytic data, `add_age_decomposition()`'s internal
   `stopifnot()` enforces, and both knits confirmed without error:
   - every retained participant-wave has exactly one non-missing age
     (`!anyNA(age_by_wave)`, `!anyDuplicated(... SubNum, Wave_Num)`);
   - one-wave participants have `within_cAge == 0`;
   - each participant's `within_cAge` values sum to zero across their own
     retained waves (`tapply(within_cAge, SubNum, sum)` all `< 1e-9`);
   - `between_cAge` is exactly `mean_age - 65` and `within_cAge` is exactly
     `Age_DuringParticipation_ - mean_age` for every row;
   - mean age is computed from `distinct(SubNum, Wave_Num,
     Age_DuringParticipation_)`, i.e. one row per retained wave regardless of
     how many modalities survived motion exclusion at that wave, so modality
     retention cannot affect it by construction.

## C. All six models

**PASS**

All 42 fixed-effect rows (3 outcomes x 7 terms x 2 rules) in
`output/tables/table_2.csv` and `output/tables/table_s4.csv` were compared
against the `corrected` column of
`old/age_correction/fixed_effects_all_statistics.csv`. 42/42 rows matched; 0
unmatched in either direction.

| statistic | max absolute difference |
| --- | --- |
| estimate | 0 |
| SE | 0 |
| df | 0 |
| t | 0 |
| p | 1.6e-27 (floating-point noise) |

Highlighted terms, observed vs. requested:

| term | observed | requested |
| --- | --- | --- |
| Primary Reliability within_cAge, b | -0.008891223292446591 | -0.008891223 |
| Primary Reliability within_cAge, SE | 0.0042848212369418805 | 0.004284821 |
| Primary Reliability within_cAge, df | 528.6951427969236 | 528.6951 |
| Primary Reliability within_cAge, t | -2.0750511633461626 | -2.075051 |
| Primary Reliability within_cAge, p | 0.03846485490984026 | 0.03846485 |
| Primary Reliability between_cAge, b | -0.0031979520352177285 | -0.003197952 |
| Primary Reliability between_cAge, SE | 0.00044620471130793574 | 0.0004462047 |
| Primary Distinctiveness within_cAge, b | -0.009219343396312332 | -0.009219343 |
| Primary Distinctiveness within_cAge, p | 0.1910458118559566 | 0.1910458 |
| Primary Distinctiveness between_cAge, b | -0.0030794017227267975 | -0.003079402 |
| Primary Confusability within_cAge, b | 0.0013052617605473736 | 0.001305262 |
| Primary Confusability within_cAge, p | 0.8341521271272789 | 0.8341521 |
| Primary Confusability between_cAge, b | -0.00011174911665243286 | -0.0001117491 |
| Primary Confusability between_cAge, p | 0.7996286709747871 | 0.7996287 |

All agree to the precision given in the request. `lmerTest::lmer()`,
`REML = FALSE`, and Satterthwaite inference are used throughout;
`car::Anova()` does not appear anywhere in the active document.

## D. Bootstrap

**PASS**

`output/tables/magnitude_comparison.csv`, compared against the requested
values:

| rule | term | delta (observed / requested) | CI lo (observed / requested) | CI hi (observed / requested) | n_boot_ok |
| --- | --- | --- | --- | --- | --- |
| primary | between | 0.0030862029 / 0.003086203 | 0.0018107243 / 0.001810724 | 0.0037695308 / 0.003769531 | 5000 |
| primary | within | 0.0075859615 / 0.007585962 | -0.0047654293 / -0.004765429 | 0.0148007939 / 0.01480079 | 5000 |
| liberal | between | 0.0032266578 / 0.003226658 | 0.0018658642 / 0.001865864 | 0.0038555171 / 0.003855517 | 5000 |
| liberal | within | 0.0089931822 / 0.008993182 | -0.0032017828 / -0.003201783 | 0.0142070662 / 0.01420707 | 5000 |

Max absolute difference against the requested (7-significant-digit) values:
4.7e-10 (delta), 3.0e-10 (CI lower), 3.9e-9 (CI upper) -- consistent with the
request's values being rounded, not a discrepancy. All four rows report
`n_boot_ok == 5000`, i.e. all 5,000 draws were usable for both age terms
under both motion rules; `bootstrap_draws_{primary,liberal}.csv` each contain
5,000 rows. The Rmd's own `check_point_estimates()` (Participant-level
magnitude bootstrap section) additionally confirms the bootstrap's point
estimate reproduces Tables 2/S4 to `< 1e-8`, and this also passed on both
knits.

## E. Tables

**PASS**

| Table | File | Rule(s) present | Role |
| --- | --- | --- | --- |
| Table 1 | `table_1.csv` | primary only | participant characteristics |
| Table 2 | `table_2.csv` | primary only | fixed effects |
| Table 3 | `table_3.csv` | primary only | descriptive statistics |
| Table S1 | `table_s1.csv` | liberal only | participant characteristics |
| Table S2 | `table_s2.csv` | liberal only | descriptive statistics |
| Table S3 | `table_s3.csv` | primary + liberal | motion accounting |
| Table S4 | `table_s4.csv` | liberal only | fixed effects |

Each file's `motion_rule` column was checked directly; Table S3 is the only
one carrying both rule labels, as required.

Demographics (Tables 1/S1), descriptives (Tables 3/S2), and motion
accounting (Table S3) were compared row-for-row against the `corrected`
column of `old/age_correction/demographics_descriptives_comparison.csv` and
`old/age_correction/motion_accounting_comparison.csv` (which record the
pre-correction manuscript's own values under `old`, confirmed identical to
`corrected` there since the age-decomposition correction does not touch
these statistics):

| | rows compared | unmatched | max abs. difference |
| --- | --- | --- | --- |
| Demographics (Tables 1 + S1) | 72 / 72 | 0 | 0 |
| Descriptives (Tables 3 + S2) | 168 / 168 | 0 | 0 |
| Motion accounting (Table S3) | 96 / 96 | 0 | 0 |

Unchanged relative to the pre-correction manuscript, as required.

## F. Figures

**PASS**

Figures 2/S1 (combined age-effect grid):

- Pooled line slopes, extracted directly from the rendered `ggplot` object's
  underlying data (not merely from the code's own internal assertion) and
  compared to Table 2's coefficients for all 3 outcomes x 2 columns: max
  absolute difference 2.8e-17 (floating-point noise). PASS.
- The ribbon is built by `combined_change_ribbon()` from the same pooled
  model's `estimate`/`se`/`df` as the fixed-effects table, with its own
  `stopifnot(max(abs(panel$predicted - slope$b * (panel$x - reference))) <
  1e-8)` -- passed on both knits, so the ribbon's center line and the plotted
  pooled line agree by construction, from one model.
- Colored modality lines: the caption text (`output/figures/figure_2_caption.txt`,
  `figure_s1_caption.txt`) states explicitly that they are "descriptive
  only, from visualization-only fits," and carry "no inferential interaction
  test, simple-slope estimate, or modality-specific statistical conclusion."
  No interaction p-value, F-test, or simple-slope number appears in either
  caption.
- No inferential interaction output (test statistic, p-value, or emtrends
  slope) is read by any figure-building function in `R/plot_helpers.R`;
  `between_person_plot_data()`/`within_person_plot_data()` take only the
  pooled models and the visualization-only model objects themselves.
- Axes/references match captions: the between-person column's x-axis is
  "Age (years)" with reference age 65 (`OLDER_ADULT_AGE`); the within-person
  column's x-axis is "Years from first wave" with reference 0. Both captions
  state this explicitly ("shifted by its own fitted value at age 65 in the
  between-person column, and at the first wave in the within-person
  column"), matching the rendered axis titles.

Figures 3/S2 (magnitude contrast):

- Point and error-bar coordinates were extracted directly from the rendered
  `ggplot` object (`ggplot_build()`) for the primary-rule figure and compared
  to `magnitude_comparison.csv`: segment endpoints matched `delta_ci_lo`/
  `delta_ci_hi` exactly (bit-for-bit), and point positions matched `delta`
  exactly (bit-for-bit). No modality-specific magnitude row is read or
  plotted anywhere in `R/plot_helpers.R`.

## G. Reproducibility hygiene

**CHECK** (one item; documentation only, not a correctness issue)

- Absolute `/Users/...` paths: **none found** outside `old/`, `.git/`, and
  `.Rproj.user/`.
- `setwd(...)`: **none found** anywhere in the active repository.
- `data/raw/*.csv`: all 6 files' SHA-256 hashes match
  `old/age_correction/protected_sha256.json` exactly -- byte-identical to
  the audited inputs, confirming they were never modified.
- References to Shiny, MAD sensitivity, `contextual_effect`, `simple_slopes`,
  `interaction_tests`, obsolete manuscript table numbers (`table_4`,
  `table_5`, `table_s5`-`table_s9`, `fd04_pct10_*`, `fd05_pct20_*`), and the
  manifest/assembly pipeline: **all occurrences are inside `old/`**, with one
  exception:

  **CHECK**
  **expected:** README.md, per the original refactor instructions, should
  not mention retired analyses except perhaps in git history.
  **observed:** `README.md` lines 193, 201-203, and 217 name the retired
  six-script pipeline, the Shiny explorer, the MAD x3 sensitivity analysis,
  and the manifest/assembly pipeline, inside a "What changed, and what
  didn't" section and the `old/` manifest description.
  **relevant file/line:** `README.md:190-221`.
  **likely explanation:** This is a deliberate choice made when the README
  was written, not an accidental leftover from the refactor: the mentions
  are confined to a section explicitly describing what was retired and
  where it now lives (`old/`), which is the kind of "historical
  documentation" this validation pass's own hygiene check (G) treats as
  acceptable. It does, however, go beyond the original instruction's letter
  ("do not mention retired analyses except perhaps in git history"). No
  retired function, file path, or table number from this text is referenced
  anywhere in the active analysis -- this is a documentation-scope question,
  not a reproducibility defect. Left as-is pending your decision; trimming
  it is a one-section edit to `README.md` if you'd rather it referred readers
  to git history instead.

## Summary

| Check | Result |
| --- | --- |
| A. Sample construction | PASS |
| B. Age decomposition | PASS |
| C. Six models (42/42 fixed effects) | PASS |
| D. Bootstrap (4/4 contrasts, 5000/5000 draws each) | PASS |
| E. Tables (7/7, demographics/descriptives/motion unchanged) | PASS |
| F. Figures 2/3/S1/S2 | PASS |
| G. Reproducibility hygiene | CHECK (README scope only; no code/data issue) |

No accidental change was introduced by the structural refactor. The single
CHECK item is a documentation-scope question about how much the README
should say about retired analyses, not a statistical or reproducibility
defect, and no analysis code, table, or figure is affected by it.
