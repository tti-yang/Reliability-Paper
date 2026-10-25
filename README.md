# MiND Reliability

This repository reproduces every analysis, table, and figure reported in the
manuscript on age effects on neural reliability, confusability, and
distinctiveness across auditory, motor, and visual cortex, in Waves 1-2 of the
MiND study.

The analysis entry point is [`script/manuscript_analysis.Rmd`](script/manuscript_analysis.Rmd),
with bootstrap and plotting helpers in `R/`. It reads four prepared
manuscript-analysis inputs. Upstream MRI preprocessing and preparation of
these inputs are outside this repository's implemented scope.

## Frozen reference state

The manuscript analyses are corrected, validated, and submitted. The
committed files in `output/tables/` and `output/figures/` are frozen reference
artifacts. Structural cleanup preserves their bytes and the four input files.
The complete pre-cleanup reference is commit
`25118f0b5bcad8c08bc1b40865b1870c3bbb39db`.

[`reproducibility/frozen-files.sha256`](reproducibility/frozen-files.sha256)
records that commit's three active sources, four inputs, and all 22 outputs.
The source hashes refer to the original files: approved documentation/comment
edits during cleanup change their byte hashes while preserving executable R
expressions. Input and output hashes continue to match the working files.

**Running the Rmd writes directly into `output/` and can overwrite the
committed reference artifacts.** Reproduce in a separate clone or checkout,
then compare its fresh outputs with the reference commit. Choosing a different
HTML output directory does not redirect the CSV and figure writes.

## Reproducibility validation

The cleaned repository was reproduced from the four documented prepared
inputs in a fresh R session. All manuscript tables, bootstrap draws,
captions, and PNG figures reproduced byte-identically; regenerated PDFs
differed only in timestamp metadata. Full validation details are in
[`reproducibility/REPRODUCIBILITY_CHECK.md`](reproducibility/REPRODUCIBILITY_CHECK.md).

## Research question

Does neural reliability, confusability, and distinctiveness in sensory and
motor cortex change with age, and does that change differ between a
between-person (cross-sectional) comparison and a within-person
(longitudinal) comparison across two study waves?

## Running it

Use a fresh R session with the working directory at the project root. In
RStudio, open `MiND-Reliability.Rproj`, then open and knit
`script/manuscript_analysis.Rmd`. Paths are resolved from the project root
with `here::here()`.

Install R and the analysis packages `here`, `tidyverse`, `lme4`, `lmerTest`,
`ggh4x`, `gtable`, and `scales`, plus `rmarkdown` and `knitr`. Pandoc must be
available to `rmarkdown` for final HTML conversion. The document's setup
checks the analysis packages; it does not check all rendering prerequisites.

From the project root in the separate reproduction checkout:

```r
rmarkdown::render("script/manuscript_analysis.Rmd")
```

The local HTML is generated at `script/manuscript_analysis.html` and is
ignored by Git. It can include machine-specific output paths, so inspect it
before sharing it. The existing validation-session versions, including
R 4.5.2, are preserved in
[`reproducibility/session-info.txt`](reproducibility/session-info.txt).
This is a historical extraction from the saved rendering, not a newly
captured environment or a guarantee for arbitrary package versions.

The documented full run (5,000 bootstrap draws under both rules) took about
2-3 minutes on a multi-core machine; runtime depends on hardware and platform.
`MIND_BOOT_CORES` overrides the worker count with a positive integer. The
default is up to eight physical cores; Windows always executes the bootstrap
serially. Each draw has its own random-number stream, so worker count does
not change the resamples.

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

## The four prepared inputs

Read from `data/raw/` and nowhere else. Despite the directory name, these
are prepared analysis inputs, not scanner-level/raw neuroimaging data:

| File | Supplies |
| --- | --- |
| `df_mind_all_mc04.csv` | Outcome measures, FD 0.4 mm scrubbing pipeline (primary rule) |
| `df_mind_all.csv` | Outcome measures, FD 0.5 mm scrubbing pipeline (liberal rule) |
| `motion_exclusion_by_run_4mm.csv` | Run-level motion, keyed to the FD 0.4 mm outcomes |
| `motion_exclusion_by_run_5mm.csv` | Run-level motion, keyed to the FD 0.5 mm outcomes |

No other data file is read. The active workflow never modifies these inputs.
See [`data/README.md`](data/README.md) for their field definitions and scope.
The repository audit does not establish public-sharing authorization for
these participant-level files; consult the study's data-access documentation.

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
not be a neutral filter. Only a contrast pooled across modalities is computed;
no modality-specific magnitude bootstrap is run.

The resampling loop is kept outside the Rmd (`R/bootstrap.R`); the formula
it refits is the one fit
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

## Sample interpretation

The primary-rule analytic sample includes one Wave-2-only older adult with
one retained auditory observation. This participant remains in the models
but is deliberately absent from the Wave-1-anchored demographic/descriptive
tables (Tables 1/3/S1/S2).

## Layout

```text
R/                 bootstrap and plotting helpers
script/            manuscript_analysis.Rmd, the analysis entry point
data/README.md     prepared-input field definitions and provenance limitations
data/raw/          four prepared inputs; read-only to the analysis
output/tables/     8 summary CSVs + 2 bootstrap-draw CSVs; frozen references
output/figures/    8 figure files + 4 captions; frozen references
reproducibility/   reproduction report, historical session record, SHA-256 manifest
```

Historical implementations and validation records remain in Git history.
A historical participant-level master sheet also remains reachable there;
its public-sharing status remains a separate unresolved issue. Neither the
cleanup nor the reproducibility check establishes data-sharing authorization.
