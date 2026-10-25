# Clean-room reproducibility check

**CLEAN-ROOM REPRODUCTION: PASS**

Run date: 2026-10-25. All scientific outputs reproduced. Of 22 regenerated artifacts, 18 are byte-identical and four PDFs differ only in creation/modification timestamps. Environment differences are documented below; no numerical or visual discrepancy was found.

## 1. PASS — Isolated environment and preservation

The starting branch was `final-repo-cleanup`, with uncommitted structural cleanup: 143 deleted tracked files, five modified tracked files, and four untracked additions; no staged changes. The complete starting status and 36-file inventory were recorded in the temporary `baseline.json` before execution. The validated reference is commit `25118f0b5bcad8c08bc1b40865b1870c3bbb39db`.

`reproducibility/frozen-files.sha256` existed. All four prepared inputs and 22 frozen outputs matched its validated-state hashes before running. The manifest's own SHA-256 was `8a048122c0393c60fd81c5749c9db4e32953522514968d193cff1d9d292d904f`. Its three source entries describe the pre-cleanup source bytes; the documented comment/prose cleanup is already reflected in the current sources. Current source hashes were separately recorded and preserved.

The isolated copy contained exactly the 36 intended cleaned files. It excluded Git history, ignored IDE/session files, `old/`, deleted internal audit documents, removed subject-level motion files, the historical HTML, and archived RDS objects. Separate frozen references were retained outside that copy. All 22 copied outputs were then removed, leaving both output directories empty before execution.

A fresh `Rscript --vanilla` session ran the analysis. The audit harness, logs, and validators lived outside the isolated repository. The harness observed file access and inspected newly generated live objects; it did not modify analysis source, formulas, seeds, or outputs.

## 2. PASS — Dependency versions

R 4.5.2 (2025-10-31), platform `aarch64-apple-darwin20`, macOS Tahoe 26.6.2 (Darwin 25.6.0, arm64). R, macOS, platform, BLAS/LAPACK, and timezone `America/Detroit` agree with `reproducibility/session-info.txt`.

| Package | Current version | Historical comparison |
| --- | --- | --- |
| here | 1.0.2 | Matches |
| tidyverse | 2.0.0 | Matches |
| lme4 | 1.1.38 | Matches |
| lmerTest | 3.2.0 | Matches |
| ggh4x | 0.3.1 | Matches |
| gtable | 0.3.6 | Matches |
| scales | 1.4.0 | Matches |
| rmarkdown | 2.30 | Matches |
| knitr | 1.51 | Matches |

The historical spellings `lme4_1.1-38` and `lmerTest_3.2-0` denote the same versions as the normalized package-version strings above. All 74 packages appearing in both session records match. Historical `rstudioapi` was not loaded in the command-line run. No packages were installed, upgraded, or downgraded. Pandoc 3.6.3 was used; setup differences are recorded in section 14.

## 3. PASS — Full render completion

Executed from the isolated project root, in document order:

```r
rmarkdown::render("script/manuscript_analysis.Rmd")
```

- Start: 2026-10-25 21:26:45 UTC (17:26:45 America/Detroit).
- End: 2026-10-25 21:36:00 UTC (17:36:00 America/Detroit).
- Elapsed render runtime: 554.6819 seconds (9 minutes 14.68 seconds), including access tracing.
- Result: all 68 knitr progress steps and final Pandoc HTML conversion completed; process exit status 0.
- The newly rendered HTML remains only in the isolated copy. No chunks were manually rerun or reordered, and no frozen artifacts were copied into the output directories after deletion.

## 4. PASS — All 22 outputs freshly regenerated

Every listed output was absent before the run and had a new modification timestamp within the recorded render interval. These independently verified all 22 artifacts, including captions, while leaving the executable 18-entry expected-output check unchanged as requested. Times below are UTC on 2026-10-25.

| Artifact | Frozen-versus-fresh classification | Fresh modification time |
| --- | --- | --- |
| `output/figures/figure_2.pdf` | NUMERICALLY IDENTICAL | 21:35:57.403116 |
| `output/figures/figure_2.png` | EXACT | 21:35:57.565379 |
| `output/figures/figure_2_caption.txt` | EXACT | 21:35:57.568132 |
| `output/figures/figure_3.pdf` | NUMERICALLY IDENTICAL | 21:35:57.904513 |
| `output/figures/figure_3.png` | EXACT | 21:35:58.006493 |
| `output/figures/figure_3_caption.txt` | EXACT | 21:35:58.010004 |
| `output/figures/figure_s1.pdf` | NUMERICALLY IDENTICAL | 21:35:59.090010 |
| `output/figures/figure_s1.png` | EXACT | 21:35:59.238554 |
| `output/figures/figure_s1_caption.txt` | EXACT | 21:35:59.242732 |
| `output/figures/figure_s2.pdf` | NUMERICALLY IDENTICAL | 21:35:59.543156 |
| `output/figures/figure_s2.png` | EXACT | 21:35:59.637017 |
| `output/figures/figure_s2_caption.txt` | EXACT | 21:35:59.641862 |
| `output/tables/bootstrap_draws_liberal.csv` | EXACT | 21:35:55.958385 |
| `output/tables/bootstrap_draws_primary.csv` | EXACT | 21:35:55.954092 |
| `output/tables/magnitude_comparison.csv` | EXACT | 21:35:55.941260 |
| `output/tables/table_1.csv` | EXACT | 21:26:48.018578 |
| `output/tables/table_2.csv` | EXACT | 21:26:48.316331 |
| `output/tables/table_3.csv` | EXACT | 21:26:48.047268 |
| `output/tables/table_s1.csv` | EXACT | 21:26:48.087242 |
| `output/tables/table_s2.csv` | EXACT | 21:26:48.111804 |
| `output/tables/table_s3.csv` | EXACT | 21:26:48.145848 |
| `output/tables/table_s4.csv` | EXACT | 21:26:48.453246 |

## 5. PASS — Sample construction

Counts were independently computed from the live analytic data, using unique participant-wave pairs for sessions. Every expected count agreed.

| Measure | Primary | Liberal |
| --- | ---: | ---: |
| Participants | 218 | 226 |
| Sessions | 276 | 286 |
| Modality-level observations | 724 | 841 |
| Participants contributing both retained waves | 58 | 60 |
| Wave-1 sessions | 217 | 226 |
| Wave-2 sessions | 59 | 60 |
| Wave-2-only analytic participants | 1 | 0 |

## 6. PASS — Corrected age decomposition

For both rules, independently recomputing person means from unique retained participant-wave observations gave maximum error **0**. Modality retention therefore did not weight those means. One-wave participants had exactly zero `within_cAge`; within-person age averaged exactly zero over each participant's retained waves. The identities `within_cAge = age - mean_age` and `between_cAge = mean_age - 65` also had maximum error **0**.

## 7. PASS — All six mixed models

Tables 2 and S4 are byte-identical to the frozen files, covering all 21 coefficient rows per table and every estimate, SE, df, t, p, label, and sample-count field at exported full precision. This comparison included all coefficients, not only the following age terms.

| Rule | Outcome | Between-person estimate | Within-person estimate |
| --- | --- | ---: | ---: |
| Primary | Distinctiveness | -0.0030794017227267975 | -0.009219343396312332 |
| Primary | Reliability | -0.0031979520352177285 | -0.008891223292446591 |
| Primary | Confusability | -1.1174911665243286e-4 | 0.0013052617605473736 |
| Liberal | Distinctiveness | -0.003289144712645617 | -0.009146257224415562 |
| Liberal | Reliability | -0.0032349035410298944 | -0.009147392352992084 |
| Liberal | Confusability | 8.245771125395509e-6 | 1.5421019527865366e-4 |

All six live model objects used `REML = FALSE` and the specified formula:

```r
outcome ~ within_cAge + between_cAge + Sex_M1 + Education +
  aud_mot + aud_vis + (1 | SubNum)
```

All six had optimizer convergence code 0, no lme4 convergence messages, and `isSingular = FALSE`.

## 8. PASS — Descriptive/sample tables

Tables 1, 3, S1, S2, and S3 are byte-identical to their frozen references. Headers, row ordering, categorical fields, and all numerical values agree.

## 9. PASS — Participant bootstrap

Both rules used **5,000 draws**, seed **20260910**, and **one worker**. `MIND_BOOT_CORES` was unset. Each age term had 5,000 finite usable draws under each rule. Both raw draw CSVs are byte-identical to the frozen files, including draw ordering; `magnitude_comparison.csv` is also byte-identical.

Inspection confirmed whole-participant resampling, independent cluster IDs for duplicated sampled participants, reliability/confusability model refits inside each draw, and type-7 percentile 95% intervals. The existing L'Ecuyer-CMRG stream assignment is unchanged.

| Rule | Age term | Delta | 95% lower | 95% upper |
| --- | --- | ---: | ---: | ---: |
| Primary | between_cAge | 0.003086202918565296 | 0.001810724303405431 | 0.003769530796882757 |
| Primary | within_cAge | 0.007585961531899218 | -0.004765429261855273 | 0.01480079386699081 |
| Liberal | between_cAge | 0.003226657769904499 | 0.001865864217701847 | 0.00385551714188212 |
| Liberal | within_cAge | 0.00899318215771343 | -0.003201782807913349 | 0.01420706615989455 |

An independent calculation from the fresh CSV draws reproduced the percentile endpoints and model-derived point estimates with maximum arithmetic error 1.73e-18. This is floating-point arithmetic in the independent checker; the fresh and frozen CSVs themselves have **zero differing bytes or values**.

## 10. PASS — Figures

Figures 2 and S1 each have six panels and 24 outcome/age-term/series groups. Pooled line slopes match the corresponding Table 2/S4 age coefficients; maximum reconstructed slope error was 2.95e-17. All series were centered at age 65 for between-person panels and zero for within-person panels; maximum reconstructed centering error was 5.55e-17.

Pooled ribbons exactly matched `b * (x - reference) +/- qt(.975, df) * se * abs(x - reference)` from the intended pooled models, with zero width at the reference and maximum coordinate error **0**. Colored modality lines remain descriptive visualization-only interaction fits; they do not replace pooled inferential estimates or export interaction tests.

Figures 3 and S2 each contain two points. Their point and error-bar endpoint coordinates exactly matched the appropriate magnitude-summary estimates and percentile limits (maximum error **0**). All four PNGs are byte-identical; the PDFs' non-date contents are also byte-identical. Thus the coordinate checks are supported by identical rendered figure content.

## 11. PASS — Captions

All four caption `.txt` files are byte-identical, including wording and line endings.

## 12. PASS — Hidden-dependency search within observed scope

Runtime traces recorded exactly four `read_csv` calls, reading only:

- `data/raw/df_mind_all.csv`
- `data/raw/df_mind_all_mc04.csv`
- `data/raw/motion_exclusion_by_run_4mm.csv`
- `data/raw/motion_exclusion_by_run_5mm.csv`

The two `source` calls read only `R/bootstrap.R` and `R/plot_helpers.R`. Active-code inspection and the captured access trace found no analysis dependency on `old/`, removed motion/audit files, the removed HTML, absolute user-home paths, or an undocumented cached scientific object.

The 20,415 traced `readRDS` calls resolved to 182 distinct **installed R package metadata files**, all under the R library. No scientific RDS cache was read. Installed R libraries, Pandoc, system libraries/fonts, and temporary rendering resources necessarily exist outside the cleaned repository; they are runtime dependencies, not extra research inputs. The generated HTML also declares its normal external MathJax URL.

Evidence combines a successful run without historical files, static inspection, logs, and traces of `read_csv`, `source`, and `readRDS`. This was not an operating-system-wide filesystem/network trace, so it does not claim every internal library access was instrumented.

## 13. PASS — Frozen-versus-fresh comparison and final preservation

Classification totals: **18 EXACT**, **4 NUMERICALLY IDENTICAL**, **0 ROUNDING-EQUIVALENT**, **0 DIFFERENT**. CSV comparisons checked full content and full exported precision; no tolerance was needed to accept any artifact. For PDFs, replacing only `/CreationDate` and `/ModDate` metadata with common placeholders made the complete files byte-identical.

All 36 original cleaned files still matched their before-run SHA-256 hashes after rendering and verification. The original Git status was unchanged before adding this report. Original inputs, frozen outputs, statistical sources, and `reproducibility/frozen-files.sha256` were preserved. During the reproduction task, the only addition to the cleanup working tree was this report, now stored at `reproducibility/REPRODUCIBILITY_CHECK.md`. No commit, merge, push, tag push, or history rewrite was performed during that task.

## 14. CHECK — Warnings, metadata, and environment differences

**Environment setup**

```text
Expected: Reproduce in a documented environment, identifying differences from the historical session.
Observed: R, OS, platform, BLAS/LAPACK, timezone, and all shared package versions match. Locale is C.UTF-8 instead of en_US.UTF-8. The command-line session did not load rstudioapi. MIND_BOOT_CORES was unset; physical-core detection returned NA and the existing fallback selected one worker. Pandoc initially was not discoverable, but the already installed RStudio-bundled Pandoc 3.6.3 worked after setting RSTUDIO_PANDOC in this process.
Difference: Locale, session context, and Pandoc discovery differ. Historical Pandoc version and actual worker count are not recorded, so equality for those cannot be asserted.
Likely explanation: A fresh sandboxed command-line R session has different locale/environment settings and cannot obtain the physical-core count. No package installation or version change was needed.
Does this affect manuscript results? NO — all CSVs, bootstrap draws, captions, and PNGs reproduced byte-for-byte.
```

Pandoc setup used only this process-local setting before the requested render:

```r
Sys.setenv(RSTUDIO_PANDOC =
  "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64")
rmarkdown::find_pandoc(cache = FALSE)
```

**PDF metadata**

```text
Expected: Identical scientific figure content; regenerated graphics need not have identical timestamps.
Observed: Four PDFs have different creation/modification timestamps; all remaining bytes match.
Difference: Metadata only. All four PNGs are byte-identical.
Likely explanation: PDF devices record the time of regeneration.
Does this affect manuscript results? NO
```

**Warnings and singular bootstrap draws**

```text
Expected: Complete both bootstraps with 5,000 usable draws per age term, retaining singular draws under the validated policy.
Observed: 740/5,000 primary and 1,646/5,000 liberal draws were flagged singular and retained; every draw remained usable. No errors or unsuppressed warnings were captured in the render log, outer condition handler, or rendered output. All six manuscript models had no convergence messages and were nonsingular.
Difference: No deviation from the documented singular-fit policy or frozen results.
Likely explanation: Some bootstrap samples place a random-intercept variance at its zero boundary. Existing code suppresses per-draw warning/message text and records singular flags; consequently individual suppressed messages are not available for review.
Does this affect manuscript results? NO — the retained draw files and confidence intervals exactly reproduce the frozen references.
```

Temporary reproduction harnesses, logs, isolated copies, and other local evidence are not distributed with this repository. This report preserves the validation results without participant-level values or local user identifiers. Reproduction success does not resolve the separate, unresolved public-sharing status of participant-level historical data and does not establish data-sharing authorization.

**CLEAN-ROOM REPRODUCTION: PASS**

Differences were limited to PDF timestamp metadata and documented execution-environment details. Scientific values and visible figures reproduced unchanged.
