# MiND Reliability

This repository reproduces every analysis, table, and figure reported in the
manuscript on age effects on neural reliability, confusability, and
distinctiveness across auditory, motor, and visual cortex, in Waves 1-2 of the
MiND study.

**Everything lives in one document: [`script/manuscript_analysis.Rmd`](script/manuscript_analysis.Rmd).**
Open it, run it top to bottom, and it reproduces every number, table, and
figure in the manuscript from the four raw input files. There is no separate
pipeline of numbered scripts to run in order and no hidden analysis step
outside that document.

## Research question

Does neural reliability, confusability, and distinctiveness in sensory and
motor cortex change with age, and does that change differ between a
between-person (cross-sectional) comparison and a within-person
(longitudinal) comparison across two study waves?

## Running it

Open `MiND-Reliability.Rproj` in RStudio, open
`script/manuscript_analysis.Rmd`, and knit it (or run it chunk by chunk). The
document anchors on the project root with `here::here()`, so it does not
matter where the project folder lives on disk, and nothing needs editing
after a clone.

```r
rmarkdown::render("script/manuscript_analysis.Rmd")
```

Requires R with `here`, `tidyverse`, `lme4`, `lmerTest`, `ggh4x`, `gtable`,
and `scales`; the document stops with the list of anything missing. A full
run (including the 5,000-draw bootstrap under both motion rules) takes about
2-3 minutes on a multi-core machine.

## The two motion-exclusion rules

Every result is reported under two rules, applied to run-level framewise
displacement (FD):

| Rule | FD cutoff | Run excluded at | Role |
| --- | --- | --- | --- |
| primary | 0.4 mm | >= 10% scrubbed volumes | primary manuscript analysis |
| liberal | 0.5 mm | >= 20% scrubbed volumes | supplementary robustness check |

A subject x modality row with no matching motion record at all (not merely a
record that fails the threshold) is excluded, not retained -- this handling
has been audited and is preserved exactly. 84 modality rows (30
participant-wave sessions, 29 participants) have no motion record under
either rule; all three outcomes are already missing for every one of them, so
including them would add no complete model observations. They are not
recovered.

## The four raw inputs

Read from `data/raw/` and nowhere else:

| File | Supplies |
| --- | --- |
| `df_mind_all_mc04.csv` | Outcome measures, FD 0.4 mm scrubbing pipeline (primary rule) |
| `df_mind_all.csv` | Outcome measures, FD 0.5 mm scrubbing pipeline (liberal rule) |
| `motion_exclusion_by_run_4mm.csv` | Run-level motion, keyed to the FD 0.4 mm outcomes |
| `motion_exclusion_by_run_5mm.csv` | Run-level motion, keyed to the FD 0.5 mm outcomes |

No other file in `data/raw/` is read. The study master sheets
(`CombinedMasterGLX_*`) are not part of this repository and are not needed to
reproduce any result here. Raw files are never modified by anything in this
repository.

## Person-mean age decomposition

Age is decomposed into a between-person and a within-person component, with
one critical property: **mean age is computed over unique retained
participant-wave observations, not modality-level rows**, so the number of
modalities a wave happened to retain cannot influence that participant's mean
age.

```
age_by_wave  <- distinct(SubNum, Wave_Num, Age_DuringParticipation_)
mean_age     <- mean(Age_DuringParticipation_)        # per participant
between_cAge <- mean_age - 65
within_cAge  <- Age_DuringParticipation_ - mean_age   # per wave
```

A one-wave participant has `within_cAge == 0` by construction. A participant
observed at ages 70 and 74 has `mean_age = 72` and within-person ages -2 and
+2. The Rmd checks this against a worked synthetic example before applying it
to real data, and asserts the resulting invariants (zero within-person sum
per participant, zero within-person age for single-wave participants) on the
real analytic data.

## Modality coding

Two numeric contrasts code the three modalities:

| | `aud_mot` | `aud_vis` |
| --- | --- | --- |
| Auditory | -1 | -1 |
| Motor | 1 | 0 |
| Visual | 0 | 1 |

## The six pooled mixed models

For each outcome (Distinctiveness, Reliability, Confusability), under each
motion rule:

```
outcome ~ within_cAge + between_cAge + Sex_M1 + Education + aud_mot + aud_vis + (1 | SubNum)
```

fit with `lmerTest::lmer()`, `REML = FALSE`, Satterthwaite degrees of freedom
and p-values. `car::Anova()` is not used anywhere for manuscript inference.
These six models are the only source of the manuscript's inferential
claims about age effects; the visualization-only interaction models used to
draw the colored, descriptive modality lines in Figures 2/S1 are fit
separately, labelled VISUALIZATION ONLY in the Rmd, and contribute no
inferential test, simple slope, or conclusion.

## The magnitude bootstrap

For both motion rules, `delta = |beta_Reliability| - |beta_Confusability|` is
computed for the between-person and within-person age terms separately, using
a participant-level cluster bootstrap: 5,000 draws, seed `20260910`. Every
retained wave and modality belonging to a sampled participant travels
together, and a participant drawn more than once is assigned a fresh cluster
ID per copy. The Reliability and Confusability models are refit, with the
exact formula above, inside every draw; the 95% CI is the percentile interval
of the resulting `delta` draws. A singular fit (a participant variance
estimated at the zero boundary) remains eligible and is retained, not
discarded -- see the header of `R/bootstrap.R` for why discarding it would
not be a neutral filter. Only a modality-level, pooled contrast is computed;
no modality-specific magnitude bootstrap is run.

The resampling loop is the one piece of mechanical, repeated code kept
outside the Rmd (`R/bootstrap.R`); the formula it refits is the one fit
visibly in the document, and the Rmd asserts that the bootstrap's point
estimate reproduces the corresponding fixed-effects table exactly.

Raw bootstrap draws are saved to `output/tables/bootstrap_draws_{primary,liberal}.csv`
so the full resampling distribution can be inspected without rerunning 5,000
iterations.

## Outputs, and what they correspond to in the manuscript

| Output | Manuscript item |
| --- | --- |
| `output/tables/table_1.csv` | Table 1 -- primary participant characteristics |
| `output/tables/table_2.csv` | Table 2 -- primary fixed effects (all 3 outcomes) |
| `output/tables/table_3.csv` | Table 3 -- primary descriptive statistics |
| `output/tables/table_s1.csv` | Table S1 -- liberal participant characteristics |
| `output/tables/table_s2.csv` | Table S2 -- liberal descriptive statistics |
| `output/tables/table_s3.csv` | Table S3 -- motion accounting, both rules |
| `output/tables/table_s4.csv` | Table S4 -- liberal fixed effects (all 3 outcomes) |
| `output/tables/magnitude_comparison.csv` | Pooled magnitude bootstrap summary, both rules (source for Figures 3/S2) |
| `output/tables/bootstrap_draws_primary.csv`, `bootstrap_draws_liberal.csv` | Raw 5,000-draw bootstrap deltas, for inspection |
| `output/figures/figure_2.{png,pdf}` | Figure 2 -- combined age effects, primary rule |
| `output/figures/figure_3.{png,pdf}` | Figure 3 -- pooled magnitude contrast, primary rule |
| `output/figures/figure_s1.{png,pdf}` | Figure S1 -- combined age effects, liberal rule |
| `output/figures/figure_s2.{png,pdf}` | Figure S2 -- pooled magnitude contrast, liberal rule |
| `output/figures/*_caption.txt` | The full caption text for each figure |

Figures 2/S1 are a 3 x 2 grid (outcome x age term). The heavy near-black line
in every panel is the pooled model reported in Tables 2/S4; the three colored
modality lines are descriptive only. Figures 3/S2 plot only the pooled
reliability-vs-confusability magnitude contrast and its bootstrap interval;
no modality-specific contrast is plotted.

## Layout

```
data/raw/          read-only inputs; nothing here produces them, nothing writes to it
R/
  bootstrap.R      participant-cluster bootstrap for the magnitude contrast
  plot_helpers.R   ggplot construction for Figures 2/3/S1/S2
script/
  manuscript_analysis.Rmd   the entire analysis, start to finish
output/
  tables/          8 CSVs + 2 raw bootstrap-draw files (see table above)
  figures/         8 figure files (PNG + PDF, both rules) + 4 caption .txt files
old/               archived pre-refactor pipeline, outputs, and the audit
                   trail for the age-decomposition correction (see below)
```

## What changed, and what didn't

The corrected person-mean age decomposition documented in
`old/age_correction/comparison_report.md` is authoritative and was not
altered by this refactor: inclusion, motion rules, outcomes, covariates,
modality coding, and model formulas are exactly as before. What changed is
structural, not statistical: the former six-script pipeline
(`script/01_prepare_data.R` through `06_assemble_manuscript.R`), the Shiny
explorer, and the per-table/per-figure helper modules in `R/` have been
replaced by the single Rmd above plus two small, purely mechanical helper
files.

Several analyses that are no longer part of the manuscript were retired from
the active workflow in the same pass: the age x modality interaction
*inference* (joint F-tests, simple slopes, pairwise slope contrasts, and the
contextual between-vs-within coefficient test), the MAD x 3 outlier
sensitivity analysis, the modality-specific magnitude bootstrap, the Shiny
threshold explorer, and the manuscript assembly/manifest pipeline. None of
these are referenced by the current manuscript tables or figures. Everything
retired is preserved under `old/` -- nothing was deleted irreversibly.

The primary-rule analytic sample includes one Wave-2-only older adult
(SubNum 118, one retained auditory observation); this participant is
deliberately absent from the Wave-1-anchored demographic/descriptive tables
(Tables 1/3/S1/S2) by design, not by omission.

## `old/`

A complete, unmodified archive, preserved rather than deleted:

- `old/script/`, `old/R/`, `old/tests/` -- the previous six-script pipeline,
  its shared `R/` implementation, the Shiny interactive document, and their
  regression tests.
- `old/output/` -- the previous pipeline's table and figure exports, under
  their old filenames.
- `old/manuscript/` -- the previous manuscript-facing copies, under the old
  table/figure numbering (superseded by the table above).
- `old/age_correction/` -- the full audit trail for the age-decomposition
  correction, including `comparison_report.md` (OLD vs CORRECTED, the
  authoritative record of what changed and why), the archived pre-correction
  code snapshot, and every comparison CSV the correction was validated
  against.

Nothing here is part of the active analysis. It exists so every number in the
manuscript can be traced back through its history, not just its current
value.
