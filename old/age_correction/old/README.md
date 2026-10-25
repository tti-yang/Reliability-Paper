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

```sh
Rscript script/01_prepare_data.R
Rscript script/02_fit_models.R
Rscript script/03_sensitivity.R
Rscript script/04_magnitude_comparison.R
Rscript script/05_figures.R
Rscript script/06_assemble_manuscript.R
```

Open `MiND-Reliability.Rproj`, or run from anywhere: each script anchors on its
own file location, so the working directory does not matter and nothing needs
editing after a clone. (`here()` alone is not enough, because it searches
upward from the *working* directory; a script launched by path from outside the
project would anchor outside it. The interactive document still uses `here()`,
where the working directory is inside the project by construction.)

Requires R with `here`, `shiny`, `tidyverse`, `lme4`, `lmerTest`, `patchwork`,
`flextable`, `emmeans`, `ggh4x`, and `parallel` (included with R). Each script
stops with the list of anything missing.

Each stage prints what it read and what it wrote, and nothing else. Assertions
and warnings are never suppressed, so a quiet run is a run where nothing went
wrong. Three environment variables change behaviour:

| Variable | Default | Effect |
| --- | --- | --- |
| `MIND_VERBOSE` | `0` | `1` adds the per-row diagnostics, intermediate counts, and sanity checks to any stage. |
| `MIND_BOOT_B` | `5000` | Bootstrap draws in stage `04`. |
| `MIND_BOOT_CORES` | up to 8 physical cores | Bootstrap workers in stage `04`; Windows always runs serially. |

```sh
MIND_VERBOSE=1 Rscript script/02_fit_models.R
MIND_BOOT_B=50 MIND_BOOT_CORES=2 Rscript script/04_magnitude_comparison.R  # smoke test
```

Run stage `04` again at the default 5,000 draws before assembling results.

## Scripts, in execution order

| Script | What it does |
| --- | --- |
| `script/01_prepare_data.R` | Reads `data/raw/`, applies both motion rules, builds the Waves 1–2 analytic data, and writes it to `data/derived/`. |
| `script/02_fit_models.R` | Fits the mixed-effects models, the age × modality interaction models, and the contextual effect; writes 13 tables to `output/tables/` and caches the between- and within-person plotting data in `data/derived/`. |
| `script/03_sensitivity.R` | Refits the main models under MAD × 3 outlier exclusion; writes `output/tables/outlier_sensitivity.csv`. |
| `script/04_magnitude_comparison.R` | Compares the absolute component age slopes with 5,000 paired participant bootstrap draws per rule; validates against stage `02` and writes `output/tables/magnitude_comparison.csv`. |
| `script/05_figures.R` | Builds the combined age-effect figure and the magnitude-contrast figure under both rules from saved plotting data and tables, checks the layout, and writes 8 figure files plus a caption file each to `output/figures/`. |
| `script/06_assemble_manuscript.R` | Copies from `output/` into a wiped-and-rebuilt `manuscript/` tree under manuscript-facing names, and rewrites this README's manifest table. Reads no data and fits nothing. |
| `script/motion_corrected_analysis_interactive.Rmd` | Shiny viewer for exploring any FD/percentage cutoff interactively. Sources the same code in `R/` and writes nothing. Serve it with `rmarkdown::run()`. |

`01` runs first, then `02`, then `04`, then `05`. Stage `04` validates against
the stage `02` tables; stage `05` reads the stage `02` plotting data and model
intervals plus the stage `04` bootstrap table, and fits nothing itself. Stage
`03` can run any time after `01`; `06` runs last.

The shared implementation lives in `R/` — `setup.R`, `data.R`, `models.R`,
`sensitivity.R`, `magnitude.R`, `figures.R`, `manifest.R` — and is sourced by
the scripts and by the interactive document alike, so the viewer and the
committed outputs cannot drift apart.

## Component age-effect magnitudes

Stage `04` estimates `delta = |b_reliability| - |b_confusability|` on the
original correlation scale, pooled and by modality, for both age terms and both
motion rules. Positive values indicate a larger absolute reliability slope. No
outcomes are standardized, and both components must use exactly the same rows —
unequal complete-case samples stop the run before any resampling.

The 95% percentile intervals and two-sided sign-tail p values use 5,000 paired
resamples of participants, carrying every retained session and modality
together and assigning new IDs to repeated participant copies.

A **singular** resample fit is retained, not discarded. Singularity here is a
participant variance estimated at the zero boundary — a legitimate maximum
likelihood estimate that leaves the fixed-effect age slopes intact. The
confusability model sits near that boundary in the observed data (participant
SD 0.045 against a residual SD of 0.221 under the primary rule; 0.029 against
0.223 under the liberal one), so resamples reach it often: 14.6% and 32.9% of
draws respectively. Discarding those draws was not a neutral filter — they
contain systematically fewer returners (*p* < 1e-04) and a systematically
different contrast — so they are kept and counted instead. Stage `04` reports
the singular proportion per rule on completion.

Only a genuinely unusable fit is rejected: non-convergence, rank deficiency, or
an error. `n_boot_ok` reports usable draws, and a failure rate above 1% raises
a warning — which, under this policy, is informative rather than permanently
tripped. The p value is `2 * min(mean(delta_star <= 0), mean(delta_star >= 0))`,
capped at one. A p value of zero means no sampled contrast crossed zero, not an
exactly zero population probability.

The seed is `MAGNITUDE_BOOT_SEED` in `R/setup.R`, and each draw has its own
L'Ecuyer-CMRG stream, so changing the core count does not change the resamples.

**On additivity.** The outcome identity `Distinctiveness = Reliability -
Confusability` does *not* imply additivity of coefficients from three separately
fitted mixed models: each fit estimates its own covariance parameters, and
fixed-effect estimation depends on them (see the
[lme4 model formulation, Section 3](https://lme4.github.io/lme4/articles/lmer.pdf)).
The exports already depart from that identity, by up to about 0.000816 on the
age slopes. Stage `04` therefore asserts that each component slope matches its
stage `02` export to `1e-8`, checks the outcome-level and same-sign magnitude
identities, and reports the gap between `signed_diff` and the separately fitted
distinctiveness slope rather than forcing the models to agree.

`delta` is sign-free. It says which component's age effect is the larger in
magnitude and makes no claim about the direction of either, so a positive value
means the age effect is larger for reliability whichever way the two components
point. The figure therefore carries no "excess", "gain" or "loss" language.

## Figures

`script/05_figures.R` builds two figures per motion rule. The combined
age-effect figure (`figure2_<rule>`) is one 3 x 2 grid: outcome by row
(distinctiveness, reliability, confusability) and age term by column
(between-person against age, within-person against years from the first wave).
Panels are tagged A–F in reading order. Colour encodes modality throughout,
from one palette in `R/figures.R`: the pooled series takes a near-black neutral
and a heavier weight so it reads as primary, and the three modalities take
Okabe-Ito hues. The pooled line is drawn first and the modality lines over it,
so a modality line lying on the pooled estimate stays visible. No raw
observations are drawn. In the between-person column a dashed line marks
extrapolation across the unsampled 30–60 age range, and means nothing else
anywhere in the figure.

Both columns carry all four series, but **the within-person modality lines are
subordinated** — thinner, at alpha 0.5, and without ribbons — because the
within-person age × modality interaction is not significant for any outcome
under either motion rule (all *p* > .19), so those slopes are descriptive
rather than inferential. The caption reports the three *F* tests, read from
`{rule}_interaction_tests.csv`; `within_interaction_summary()` asserts they are
all non-significant, so the caption cannot state a claim the data no longer
supports.

Every modality line drawn, in both columns, is verified against the emtrends
simple slopes in `{rule}_simple_slopes.csv` by `verify_modality_slopes()` — the
lines come from the cached interaction-model predictions, the slopes from
emmeans, and the two must agree to 1e-8.

By default the lines are **centred**: each series is shifted by its own fitted
value at the column's reference — age 65 on the left, matching the model
centring, and the first wave on the right — so every line passes through zero
there and each panel shows model-implied change rather than a level. The row
labels stay neutral ("Neural distinctiveness", not "Change in …"); that the
panels plot change is stated in the caption file. The ribbon
is then the 95% CI of that change, `b * (x - x_ref) ± t * SE(b) * |x - x_ref|`,
using the pooled slope, its standard error and its Satterthwaite *df* from the
same model the tables report — a straight-edged bowtie pinched shut at the
reference, where the plotted change is zero by construction.
`combined_change_ribbon()` asserts the width there is exactly zero, and that
the centred line agrees with the tabled coefficient. Set `MIND_CENTRED=0`, or
pass `centred = FALSE`, for the raw outcome scale and the fitted-value
interval.

Captions are **not drawn on the figures**. Each export is accompanied by
`<name>_caption.txt` in the same directory, carrying the full caption with its
figure number looked up from MANIFEST. They are written per motion rule,
because each rule becomes a different manuscript figure and the magnitude
caption reports that rule's usable bootstrap draws.

The magnitude-contrast figure (`figure3_<rule>`) is a single short panel at
one journal column: the pooled contrast `delta = |b_reliability| -
|b_confusability|` for the between- and within-person age terms, two points
with their 95% bootstrap percentile intervals read straight from
`magnitude_comparison.csv`. Both rows share one x scale, because both are
per-year slopes in the same units and the shared axis is what shows the
within-person estimate to be far the less precise of the two. The point is the
same filled black square as the pooled series of the combined figure.

Only the pooled rows are plotted. The modality-specific rows, the component
slopes and the signed difference stay in `magnitude_comparison.csv` and in the
supplementary table; `tests/check_magnitude_figure.R` asserts that narrowing
the figure has not narrowed the export.

## Checks

```sh
Rscript tests/check_magnitude.R          # after stage 01
Rscript tests/check_magnitude_figure.R   # after stages 02 and 04
```

`check_magnitude.R` covers mismatched rows within a participant, intact
resampled clusters, distinct IDs for repeated copies, serial/parallel
agreement, restoration of RNG and contrast settings, point estimates, and
failed draws. `check_magnitude_figure.R` covers pooled-only content, the saved
bootstrap intervals being displayed unchanged, the shared x scale, row order,
the absence of a legend, the sign-free contrast, the preservation of the full
export table, the missing-input error, and all 8 exports with model fitting
disabled. Neither writes into the repository.

## Layout

```
data/raw/          read-only inputs; nothing here produces them
data/derived/      stage handoffs written by 01 and 02 (not tracked)
R/                 shared implementation, including the manifest
script/            01–06 plus the interactive viewer
tests/             regression checks for stages 04 and 05
output/tables/     15 CSVs
output/figures/    8 figures (PDF and PNG, both rules) plus one caption .txt each
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

The `MANIFEST` data frame in `R/manifest.R` is the single edit point, and the
only place in this repository where a manuscript table or figure number is
written down. Moving a table between main and supplement, or renumbering one,
is a change to its `destination` there and nowhere else. Every other number a
reader sees — the table below, the headings and prose in the interactive
document — is looked up from it with `manuscript_label()`.

The table below is generated: `script/06_assemble_manuscript.R` rewrites
everything between the markers on every run. Do not edit it by hand; edit
`R/manifest.R` and re-run stage `06`.

<!-- MANIFEST:BEGIN - generated by script/06_assemble_manuscript.R; edit R/manifest.R instead -->

| Number | Manuscript file | Source in `output/` | Notes |
| --- | --- | --- | --- |
| Figure 2 | `manuscript/main/figure_2.png` | `figures/figure2_fd04_pct10.png` | Between- and within-person age effects on all three outcomes, primary motion rule (FD 0.4 mm / 10%). |
| Figure 3 | `manuscript/main/figure_3.png` | `figures/figure3_fd04_pct10.png` | Pooled magnitude contrast of the reliability and confusability age effects, both age terms, primary rule. |
| Table 3 | `manuscript/main/table_3.csv` | `tables/model_estimates.csv` | PARTIAL: the primary-rule rows of model_estimates.csv. The liberal-rule rows of the same file are Table S5. |
| Table 4 | `manuscript/main/table_4.csv` | `tables/fd04_pct10_interaction_tests.csv` | Joint age x modality F tests, primary rule. |
| Table 5 | `manuscript/main/table_5.csv` | `tables/fd04_pct10_simple_slopes.csv` | Simple slopes by modality, primary rule. |
| Figure S1 | `manuscript/supplement/figure_s1.png` | `figures/figure2_fd05_pct20.png` | Figure 2 under the liberal motion rule (FD 0.5 mm / 20%). |
| Figure S2 | `manuscript/supplement/figure_s2.png` | `figures/figure3_fd05_pct20.png` | Figure 3 under the liberal motion rule. |
| Table S1 | `manuscript/supplement/table_s1.csv` | `tables/fd04_pct10_demographics.csv` | Demographics by analytic sample, primary rule. |
| Table S2 | `manuscript/supplement/table_s2.csv` | `tables/fd05_pct20_descriptives.csv` | Descriptive statistics by modality, liberal rule (FD 0.5 mm / 20%). |
| Table S3 | `manuscript/supplement/table_s3.csv` | `tables/motion_accounting.csv` | Runs assessed and excluded by age group and modality, both rules. |
| Table S4 | `manuscript/supplement/table_s4.csv` | `tables/outlier_sensitivity.csv` | ALL of outlier_sensitivity.csv: MAD x 3 sensitivity, both rules, all three exclusion variants. |
| Table S5 | `manuscript/supplement/table_s5.csv` | `tables/model_estimates.csv` | PARTIAL: the liberal-rule rows of model_estimates.csv. The primary-rule rows are Table 3. |
| Table S6 | `manuscript/supplement/table_s6.csv` | `tables/fd05_pct20_interaction_tests.csv` | Joint age x modality F tests, liberal rule. |
| Table S7 | `manuscript/supplement/table_s7.csv` | `tables/fd05_pct20_simple_slopes.csv` | Simple slopes by modality, liberal rule. |
| Table S8 | `manuscript/supplement/table_s8.csv` | `tables/contextual_effects.csv` | ALL of contextual_effects.csv: b_between - b_within with its Satterthwaite test, both rules. |
| Table S9 | `manuscript/supplement/table_s9.csv` | `tables/magnitude_comparison.csv` | ALL of magnitude_comparison.csv: magnitude comparison of the age effects on reliability and confusability, both motion rules. |

<!-- MANIFEST:END -->

Four tables in `output/tables/` are in no manifest entry and are copied
nowhere: `fd04_pct10_slope_contrasts.csv`, `fd05_pct20_slope_contrasts.csv`,
`fd05_pct20_demographics.csv`, and `fd04_pct10_descriptives.csv`. Run stage
`06` with `MIND_VERBOSE=1` to have it list them.
