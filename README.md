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
Rscript script/04_figures.R
Rscript script/05_assemble_manuscript.R
```

Requires R with `here`, `shiny`, `tidyverse`, `lme4`, `lmerTest`, `patchwork`,
`flextable`, `emmeans`, and `ggh4x`. Each script checks and stops with the list
of anything missing.

## Scripts, in execution order

| Script | What it does |
| --- | --- |
| `script/01_prepare_data.R` | Reads `data/raw/`, applies both motion rules, builds the Waves 1–2 analytic data, and writes it to `data/derived/`. |
| `script/02_fit_models.R` | Fits the mixed-effects models, the age × modality interaction models, and the contextual effect; writes 13 tables to `output/tables/`. |
| `script/03_sensitivity.R` | Refits the main models under MAD × 3 outlier exclusion; writes `output/tables/outlier_sensitivity.csv`. |
| `script/04_figures.R` | Builds manuscript Figures 2 and 3 under both rules, runs the average-column and grid checks, and writes 8 files to `output/figures/`. |
| `script/05_assemble_manuscript.R` | Copies from `output/` into a wiped-and-rebuilt `manuscript/` tree under manuscript-facing names. Reads no data and computes nothing. |
| `script/motion_corrected_analysis_interactive.Rmd` | Shiny viewer for exploring any FD/percentage cutoff interactively. Sources the same code in `R/` and writes nothing. Serve it with `rmarkdown::run()`. |

`01` must run before `02`–`04`; `02`–`04` are independent of each other; `05`
runs last. The shared implementation lives in `R/` (`setup.R`, `data.R`,
`models.R`, `sensitivity.R`, `figures.R`) and is sourced by the scripts and by
the interactive document alike, so the viewer and the committed outputs cannot
drift apart.

## Layout

```
data/raw/          read-only inputs; nothing in this repository produces them
                   (combined_master_glx_part1.csv is not distributed here --
                    ask the study team; no script in this repository reads it)
data/derived/      stage handoff written by 01 (not tracked)
R/                 shared implementation
script/            01–05 plus the interactive viewer
output/tables/     14 CSVs
output/figures/    Figures 2 and 3 as PDF and PNG, under both motion rules
manuscript/        rebuilt by 05 (not tracked)
```

## Manuscript manifest

Written by `script/05_assemble_manuscript.R`. The `MANIFEST` data frame at the
top of that script is the single edit point: moving a table between main and
supplement, or renumbering one, is a change there and nowhere else.

| Manuscript file | Source in `output/` | Notes |
| --- | --- | --- |
| `manuscript/main/figure_2.png` | `figures/figure2_fd04_pct10.png` | Between-person age effects, primary motion rule. |
| `manuscript/main/figure_3.png` | `figures/figure3_fd04_pct10.png` | Within-person age effects, primary motion rule. |
| `manuscript/main/table_3.csv` | `tables/model_estimates.csv` | PARTIAL: the primary-rule rows. The liberal-rule rows are Table S5. |
| `manuscript/main/table_4.csv` | `tables/fd04_pct10_interaction_tests.csv` | Joint age × modality *F* tests, primary rule. |
| `manuscript/main/table_5.csv` | `tables/fd04_pct10_simple_slopes.csv` | Simple slopes by modality, primary rule. |
| `manuscript/supplement/figure_s1.png` | `figures/figure2_fd05_pct20.png` | Figure 2 under the liberal rule. |
| `manuscript/supplement/figure_s2.png` | `figures/figure3_fd05_pct20.png` | Figure 3 under the liberal rule. |
| `manuscript/supplement/table_s1.csv` | `tables/fd04_pct10_demographics.csv` | Demographics by analytic sample, primary rule. |
| `manuscript/supplement/table_s2.csv` | `tables/fd04_pct10_descriptives.csv` | Descriptive statistics by modality, primary rule. |
| `manuscript/supplement/table_s3.csv` | `tables/motion_accounting.csv` | Runs assessed and excluded, both rules. |
| `manuscript/supplement/table_s4.csv` | `tables/outlier_sensitivity.csv` | ALL of it: MAD × 3 sensitivity, both rules, all three variants. |
| `manuscript/supplement/table_s5.csv` | `tables/model_estimates.csv` | PARTIAL: the liberal-rule rows. The primary-rule rows are Table 3. |
| `manuscript/supplement/table_s6.csv` | `tables/fd05_pct20_interaction_tests.csv` | Joint age × modality *F* tests, liberal rule. |
| `manuscript/supplement/table_s7.csv` | `tables/fd05_pct20_simple_slopes.csv` | Simple slopes by modality, liberal rule. |
| `manuscript/supplement/table_s8.csv` | `tables/contextual_effects.csv` | ALL of it: `b_between − b_within` with its Satterthwaite test, both rules. |

Four tables in `output/tables/` are deliberately not in the manifest:
`fd04_pct10_slope_contrasts.csv`, `fd05_pct20_slope_contrasts.csv`,
`fd05_pct20_demographics.csv`, and `fd05_pct20_descriptives.csv`. Script `05`
prints them on every run so a table cannot go missing unnoticed.
