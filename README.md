# MiND-Reliability

Age effects on neural reliability, confusability, and distinctiveness across
auditory, motor, and visual cortex, in Waves 1–2 of the MiND study.

Everything is reported under two motion-exclusion rules, and the tag is carried
in the filenames:

| Tag | Rule | Role |
| --- | --- | --- |
| `fd04_pct10` | FD 0.4 mm, run dropped at ≥ 10% scrubbed TRs | primary |
| `fd05_pct20` | FD 0.5 mm, run dropped at ≥ 20% scrubbed TRs | liberal / supplementary |

## Running the pipeline

Open `MiND-Reliability.Rproj`, or run from anywhere. Each script anchors on its
own file location and derives every path from the project root, so the working
directory does not matter and nothing needs editing after a clone. (`here()` on
its own is not enough for this: it searches upward from the *working
directory*, so a script launched by path from outside the project would anchor
outside the project. It is still what the interactive document uses, where the
working directory is inside the project by construction.)

```sh
Rscript script/01_prepare_data.R
Rscript script/02_fit_models.R
Rscript script/03_sensitivity.R
Rscript script/04_magnitude_comparison.R
Rscript script/05_figures.R
Rscript script/06_assemble_manuscript.R
```

Requires R with `here`, `shiny`, `tidyverse`, `lme4`, `lmerTest`, `patchwork`,
`flextable`, `emmeans`, `ggh4x`, and `parallel` (included with R). Each script
checks and stops with the list of anything missing.

## Scripts, in execution order

| Script | What it does |
| --- | --- |
| `script/01_prepare_data.R` | Reads `data/raw/`, applies both motion rules, builds the Waves 1–2 analytic data, and writes it to `data/derived/`. |
| `script/02_fit_models.R` | Fits the mixed-effects models, the age × modality interaction models, and the contextual effect; writes 13 tables to `output/tables/` and caches Figure 2–3 plotting data in `data/derived/figure_data_by_rule.rds`. |
| `script/03_sensitivity.R` | Refits the main models under MAD × 3 outlier exclusion; writes `output/tables/outlier_sensitivity.csv`. |
| `script/04_magnitude_comparison.R` | Compares the absolute component age slopes with 5,000 paired participant bootstrap draws per rule; validates against stage 02 and writes `output/tables/magnitude_comparison.csv`. |
| `script/05_figures.R` | Builds manuscript Figures 2–4 and within-person Figure S3 under both rules from saved plotting data and tables, checks the layouts, and writes 16 files to `output/figures/`. |
| `script/06_assemble_manuscript.R` | Copies from `output/` into a wiped-and-rebuilt `manuscript/` tree under manuscript-facing names. Reads no data and computes nothing. |
| `script/motion_corrected_analysis_interactive.Rmd` | Shiny viewer for exploring any FD/percentage cutoff interactively. Sources the same code in `R/` and writes nothing. Serve it with `rmarkdown::run()`. |

`01` must run first, followed by `02`, then `04`, then `05`. Stage `04`
validates against the stage `02` tables; stage `05` reads stage `02` plotting
data/model intervals and the stage `04` bootstrap table. Stage `03` can run
independently after `01`; `06` runs last. The shared implementation lives in `R/` (`setup.R`, `data.R`,
`models.R`, `sensitivity.R`, `magnitude.R`, `figures.R`) and is sourced by the
scripts and by the interactive document alike, so the viewer and the committed
outputs cannot drift apart.

## Component age-effect magnitudes

Stage `04` estimates `delta = |b_reliability| - |b_confusability|` on the
original correlation scale, pooled and by modality, for both age terms and both
motion rules. Positive values indicate a larger absolute reliability slope.
No outcomes are standardized. Both components must use exactly the same rows;
unequal complete-case samples cause an error before resampling.

The 95% percentile intervals and two-sided bootstrap sign-tail p values use
5,000 paired resamples of participants, carrying every retained session and
modality together and assigning new IDs to repeated participant copies. Singular,
non-converged, or rank-deficient resample fits are omitted for the affected scope;
`n_boot_ok` reports usable draws and failure rates above 1% produce a warning.
The p value is `2 * min(mean(delta_star <= 0), mean(delta_star >= 0))`, capped
at one for ties at zero. A value of zero means no sampled contrast crossed zero,
not an exactly zero population probability.

The seed is `MAGNITUDE_BOOT_SEED` in `R/setup.R`. Each draw has its own
L'Ecuyer-CMRG stream so changing core count does not change the resamples.
`parallel::mclapply` uses up to 8 detected physical cores by default (one if
core detection is unavailable); Windows runs serially. Override the draw and
worker counts for a smoke test:

```sh
MIND_BOOT_B=50 MIND_BOOT_CORES=2 Rscript script/04_magnitude_comparison.R
```

Run again with the default 5,000 draws before assembling manuscript results.
Stage `04` prints the seed, draw count, elapsed time, valid draws per row, and
checks the expected primary pooled and motor between-person point estimates.
The interactive viewer recomputes only point estimates for the selected cutoff;
its bootstrap intervals are read from this saved CSV for the manuscript rules.

**Validation correction to the supplied analysis brief:** the observed outcome
identity `Distinctiveness = Reliability - Confusability` does not imply exact
additivity of coefficients from three separately fitted mixed models. Each fit
estimates its own covariance parameters; fixed-effect estimation depends on those
parameters (see the [lme4 model formulation, Section 3](https://lme4.github.io/lme4/articles/lmer.pdf)).
The existing exports already violate that proposed identity (the largest absolute
age-slope discrepancy is about 0.000816). Stage `04` instead asserts agreement of
each component slope with its corresponding stage `02` export to `1e-8`, checks
the outcome-level identity and same-sign magnitude identity, and prints the
difference between `signed_diff` and the separately fitted distinctiveness slope.
It does not alter the existing model specifications to force coefficient additivity.

The bootstrap regression checks can be run after stage `01`:

```sh
Rscript tests/check_magnitude.R
```

They cover mismatched rows even within the same participant, intact resampled
clusters, distinct IDs for repeated copies, serial/parallel agreement, restoration
of RNG and contrast settings, original-data point estimates, and failed draws.

## Magnitude-contrast figure

`script/05_figures.R` exports the between-person analysis as
`figure4_{fd04_pct10,fd05_pct20}.{pdf,png}`. The within-person analysis uses the
identical two-panel layout in `figure_s3_{fd04_pct10,fd05_pct20}.{pdf,png}`.
Both use the shared theme, outcome colours, and PDF/PNG export helper, with a
compact 180 × 85 mm canvas. Components are on the left and sign-aligned
contrasts on the right, sharing an x scale within each figure. Pooled,
Auditory, Visual, and Motor appear top to bottom, with a light divider below
Pooled and a zero line. Light-grey connectors join the two contrast points in
each scope; vertical offsets and four distinct shapes preserve their visibility.

Component points and delta come from `magnitude_comparison.csv`. Component
95% CIs come from `model_estimates.csv` (pooled Satterthwaite t intervals) and
the rule-specific `simple_slopes.csv` files. Delta uses the saved bootstrap
percentile CI. Solid intervals are model-based; dashed intervals are bootstrap
percentile intervals, as stated in the figure caption. Stage `05` fits no models
and never reruns the bootstrap. It stops with an instruction to run stage `04`
when the bootstrap CSV is missing; Figure 2–3 predictions are cached by stage `02`.

The green series reverses the fitted distinctiveness-model estimate and its CI:
`b` becomes `-b`, and `[lo, hi]` becomes `[-hi, -lo]`. Its legend reads
"Signed difference (sign reversed)"; the smaller caption identifies the
negated model estimate explicitly.
The exact component difference and the separately fitted distinctiveness slope
remain slightly different, so this is a model approximation to
`-(b_reliability - b_confusability)`, not a relabeling of the tabled coefficient.
For two negative component slopes the reversed component difference equals
delta; for positive slopes or opposite signs, that equality is not guaranteed.
Consequently, "Excess age effect on reliability" describes the intended
comparison for these predominantly negative slopes, not a universal magnitude
interpretation of a signed contrast.

In the manuscript, the primary between-person figure is Figure 4, the primary
and liberal within-person figures are S3 and S4, and the liberal between-person
figure is S5. Existing figure numbers are unchanged.

Run `Rscript tests/check_figure4.R` after stages `02` and `04` to verify CI
reversal, unchanged bootstrap intervals, connectors, shapes, interval styles,
shared scales, scope ordering, the missing-input error, and all 16 exports
with model fitting explicitly disabled.

## Layout

```
data/raw/          read-only inputs; nothing in this repository produces them
data/derived/      stage handoffs written by 01 and 02 (not tracked)
R/                 shared implementation
script/            01–06 plus the interactive viewer
output/tables/     15 CSVs
output/figures/    16 files: Figures 2–4 and within-person Figure S3 as PDF and PNG, under both motion rules
manuscript/        rebuilt by 06 (not tracked)
```

### Input data

`script/01_prepare_data.R` reads exactly four files from `data/raw/`, and
stops with the list of any that are absent:

| File | Supplies |
| --- | --- |
| `df_mind_all.csv` | Outcome measures, FD 0.5 mm scrubbing pipeline |
| `df_mind_all_mc04.csv` | Outcome measures, FD 0.4 mm scrubbing pipeline |
| `motion_exclusion_by_run_5mm.csv` | Run-level motion, keyed to the FD 0.5 mm outcomes |
| `motion_exclusion_by_run_4mm.csv` | Run-level motion, keyed to the FD 0.4 mm outcomes |

The outcome files and the motion files are both required: the motion files are
what apply the `fd04_pct10` and `fd05_pct20` rules, so the outcome files alone
cannot reproduce anything.

The study master sheets (`CombinedMasterGLX_new_part1/2.csv`) are **not** part
of this repository. No script reads them and they are not needed to reproduce
any result here; ask the study team if you need them.

## Manuscript manifest

Written by `script/06_assemble_manuscript.R`. The `MANIFEST` data frame at the
top of that script is the single edit point: moving a table between main and
supplement, or renumbering one, is a change there and nowhere else.

| Manuscript file | Source in `output/` | Notes |
| --- | --- | --- |
| `manuscript/main/figure_2.png` | `figures/figure2_fd04_pct10.png` | Between-person age effects, primary motion rule. |
| `manuscript/main/figure_3.png` | `figures/figure3_fd04_pct10.png` | Within-person age effects, primary motion rule. |
| `manuscript/main/figure_4.png` | `figures/figure4_fd04_pct10.png` | Between-person component slopes and sign-aligned magnitude comparison, primary rule. |
| `manuscript/main/table_3.csv` | `tables/model_estimates.csv` | PARTIAL: the primary-rule rows. The liberal-rule rows are Table S5. |
| `manuscript/main/table_4.csv` | `tables/fd04_pct10_interaction_tests.csv` | Joint age × modality *F* tests, primary rule. |
| `manuscript/main/table_5.csv` | `tables/fd04_pct10_simple_slopes.csv` | Simple slopes by modality, primary rule. |
| `manuscript/supplement/figure_s1.png` | `figures/figure2_fd05_pct20.png` | Figure 2 under the liberal rule. |
| `manuscript/supplement/figure_s2.png` | `figures/figure3_fd05_pct20.png` | Figure 3 under the liberal rule. |
| `manuscript/supplement/figure_s3.png` | `figures/figure_s3_fd04_pct10.png` | Within-person component slopes and sign-aligned magnitude comparison, primary rule. |
| `manuscript/supplement/figure_s4.png` | `figures/figure_s3_fd05_pct20.png` | Within-person component slopes and sign-aligned magnitude comparison, liberal rule. |
| `manuscript/supplement/figure_s5.png` | `figures/figure4_fd05_pct20.png` | Figure 4 under the liberal rule. |
| `manuscript/supplement/table_s1.csv` | `tables/fd04_pct10_demographics.csv` | Demographics by analytic sample, primary rule. |
| `manuscript/supplement/table_s2.csv` | `tables/fd04_pct10_descriptives.csv` | Descriptive statistics by modality, primary rule. |
| `manuscript/supplement/table_s3.csv` | `tables/motion_accounting.csv` | Runs assessed and excluded, both rules. |
| `manuscript/supplement/table_s4.csv` | `tables/outlier_sensitivity.csv` | ALL of it: MAD × 3 sensitivity, both rules, all three variants. |
| `manuscript/supplement/table_s5.csv` | `tables/model_estimates.csv` | PARTIAL: the liberal-rule rows. The primary-rule rows are Table 3. |
| `manuscript/supplement/table_s6.csv` | `tables/fd05_pct20_interaction_tests.csv` | Joint age × modality *F* tests, liberal rule. |
| `manuscript/supplement/table_s7.csv` | `tables/fd05_pct20_simple_slopes.csv` | Simple slopes by modality, liberal rule. |
| `manuscript/supplement/table_s8.csv` | `tables/contextual_effects.csv` | ALL of it: `b_between − b_within` with its Satterthwaite test, both rules. |
| `manuscript/supplement/table_s9.csv` | `tables/magnitude_comparison.csv` | ALL of it: magnitude comparison of the age effects on reliability and confusability, both motion rules. |

Four tables in `output/tables/` are deliberately not in the manifest:
`fd04_pct10_slope_contrasts.csv`, `fd05_pct20_slope_contrasts.csv`,
`fd05_pct20_demographics.csv`, and `fd05_pct20_descriptives.csv`. Script `06`
prints them on every run so a table cannot go missing unnoticed.
