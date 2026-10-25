# Prepared manuscript-analysis inputs

The four CSVs in `raw/` are prepared analysis inputs, not scanner-level/raw
neuroimaging data. The active workflow starts with these files. Upstream MRI
preprocessing, computation of the supplied outcome measures, and preparation
of these CSVs are outside this repository's implemented scope.

This description records what the active code establishes. It does not
establish consent, a data license, or authorization for public sharing.
Consult the study's data-access documentation for authorization and provenance
of participant-level data. The repository does not supply that documentation.

## Files read by the analysis

| File | Use |
| --- | --- |
| `raw/df_mind_all_mc04.csv` | Outcome and covariate data for the primary rule, from the FD 0.4 mm scrubbing pipeline |
| `raw/df_mind_all.csv` | Outcome and covariate data for the liberal rule, from the FD 0.5 mm scrubbing pipeline |
| `raw/motion_exclusion_by_run_4mm.csv` | Run-level motion summary matched to the primary outcome file |
| `raw/motion_exclusion_by_run_5mm.csv` | Run-level motion summary matched to the liberal outcome file |

The `4mm` and `5mm` filenames are retained historical names. The active
analysis pairs them with FD thresholds of **0.4 and 0.5 mm**, respectively;
they do not indicate 4 or 5 mm thresholds. No upstream naming rationale is
documented here. The analysis reads these inputs without rewriting them.

## Outcome-file fields

| Field | Meaning and use established by the active analysis |
| --- | --- |
| `Subject` | Study observation/session identifier used to join outcomes to motion records; it distinguishes records across waves. It is not the longitudinal model's grouping variable. |
| `SubNum` | Participant study identifier linking retained waves; used for model random intercepts, participant summaries, and cluster resampling. No identity crosswalk is provided. |
| `Wave_Num` | Study wave. The analysis retains values 1 and 2 and drops other waves before later accounting. |
| `Subgroup` | Cohort code. Value 1 identifies the healthy cohort used by this manuscript. Other codes are not interpreted by the active analysis. |
| `Age_DuringParticipation_` | Age in years at the observation's wave; used for sample descriptions and person-mean age decomposition. |
| `Sex_M1` | The demographic summaries count 1 as men and 2 as women. Models use the supplied numeric variable as a covariate without recoding it. |
| `Education` | Supplied education covariate, summarized and used numerically in the models. Its measurement unit is not explicitly established by the active code. |
| `AudReliability`, `MotReliability`, `VisReliability` | Prepared reliability measures for auditory, motor, and visual cortex, respectively. |
| `AudConfusability`, `MotConfusability`, `VisConfusability` | Corresponding prepared confusability measures. |
| `AudDistinctiveness`, `MotDistinctiveness`, `VisDistinctiveness` | Corresponding distinctiveness measures; the active workflow checks that Distinctiveness = Reliability - Confusability. |

The outcomes retain their supplied scale; the magnitude comparison uses age
slopes on the original correlation scale. The Rmd reshapes the nine outcome
columns into participant-wave-modality observations. `Subject` and `SubNum`
have study-ID roles; their appearance alone does not establish deidentification
or public-sharing authorization.

## Run-level motion fields

| Field | Meaning and use |
| --- | --- |
| `subject` | Identifier matched to the outcome files' `Subject`. |
| `session` | Session category; the active analysis selects `placebo`. |
| `experiment` | Experiment category; the active analysis selects `auditory`, `motor`, and `visual`. |
| `run` | Run label; the active analysis selects `001`. |
| `pct_excluded` | Percentage of volumes excluded by the supplied motion processing. Runs are excluded at >= 10% under the primary rule or >= 20% under the liberal rule. |
| `age_group` | Supplied grouping field. Table S3 instead derives age group from the outcome-file age variable and the analysis's age cutoff. |
| `n_frames`, `n_excluded`, `n_excluded_tpef_file` | Supplied numeric motion-summary counts. The active analysis does not use these fields; the precise upstream meaning of `n_excluded_tpef_file` is not documented here. It contains counts, not file paths. |

The files contain records beyond the manuscript's retained subset. The active
workflow filters those records in memory; structural cleanup leaves the full
four input files unchanged.

## Missing data and analysis construction

- Outcome rows without `SubNum` are excluded before reshaping and wave filtering.
- Healthy-cohort IDs from the two outcome files determine the assessed motion
  records. Outcome rows without a matching usable motion flag are excluded;
  a missing flag is not treated as a passed motion screen.
- Participant mean age is computed over unique retained participant-wave
  observations. The code asserts nonmissing, consistent ages for these rows.
  Between-person age is mean age minus 65; within-person age is wave age minus
  that participant's mean age. A single-wave participant has zero within-person age.
- Pooled models use complete cases across all three outcomes, the model
  covariates, and `SubNum`. The workflow does not impute missing measurements.
- Demographic summaries deduplicate participants within each sample and omit
  missing values in their summaries. Descriptive tables summarize available
  outcomes by modality; their `n` counts nonmissing Reliability observations.
- Demographic/descriptive samples are Wave-1-anchored. A participant retained
  only at Wave 2 can contribute to the models without entering those samples.

The executable definitions in `script/manuscript_analysis.Rmd` remain the
reference for exact inclusion, coding, and missing-value behavior.
