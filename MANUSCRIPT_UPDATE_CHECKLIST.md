# Manuscript update checklist

Quantitative values only, drawn exclusively from the validated repository
outputs in `output/tables/` and `output/figures/` (see `MANUSCRIPT_CHECK.md`
for how those outputs were validated). No manuscript file was read, opened,
or inferred from to produce this checklist. No prose wording is suggested;
compare each value below against the corresponding number in your manuscript
text/tables/figures by hand.

Values are rounded to a reporting-style precision (b/SE to ~4 significant
figures, df to 2 decimals, t to 2 decimals, p to 3 decimals or `< .001`).
Full machine precision is always available in the cited source CSV if you
need to check a borderline rounding.

---

## Main text

### Analytic sample size (primary rule)

**Manuscript location/category:** Main text, Participants/Sample description
**Final value(s):**
- Participants: **218**
- Sessions (participant-waves retained): **276** (217 Wave 1 + 59 Wave 2)
- Modality-level observations: **724**
- Modality counts: Auditory **265**, Motor **226**, Visual **233**
- Participants with both waves retained (returners): **58**
- Follow-up interval (Wave 2 age − Wave 1 age, returners only): **M = 4.00, SD = 0.84, range 3–7 years**
- Wave-2-only participants: **1** (SubNum 118; retained in the models, excluded from Wave-1-anchored Tables 1/3)
**Source file in repository:** `output/tables/table_1.csv`, `output/tables/table_3.csv`, `MANUSCRIPT_CHECK.md` §A (participants/sessions/observations/returners); modality counts and follow-up interval computed directly from `analysis_primary` per the pipeline in `script/manuscript_analysis.Rmd` (not pre-exported to a table)
**Notes:** Unchanged from the pre-correction manuscript — only the age decomposition changed, not sample membership.

### Primary motion-exclusion counts and percentages

**Manuscript location/category:** Main text, Motion exclusion description
**Final value(s):** All participants, all modalities: **855 runs assessed, 131 excluded (15.32%)**, mean 4.72% volumes scrubbed. By modality: Auditory 283 assessed/18 excluded (6.36%); Motor 286/60 (20.98%); Visual 286/53 (18.53%).
**Source file in repository:** `output/tables/table_s3.csv` (rows with `motion_rule = FD 0.4 mm / 10% (primary)`)
**Notes:** Unchanged from the pre-correction manuscript.

### Table 1 values (primary participant characteristics)

**Manuscript location/category:** Main text, Table 1
**Final value(s):**

| Sample | n | Age M (SD) | Age range | Education M (SD) | Men | Women |
| --- | --- | --- | --- | --- | --- | --- |
| Young adults, Wave 1 | 59 | 22.71 (2.95) | 18–29 | 15.34 (1.57) | 30 | 29 |
| Older adults, Wave 1 | 158 | 70.51 (5.02) | 65–87 | 16.82 (2.18) | 61 | 97 |
| Older adults, Wave 2 (returners) | 58 | 74.17 (5.37) | 68–94 | 16.66 (2.21) | 24 | 34 |
| Older adults, Wave 1 (Wave 2 returners) | 58 | 70.17 (5.05) | 65–87 | 16.66 (2.21) | 24 | 34 |

**Source file in repository:** `output/tables/table_1.csv`
**Notes:** Unchanged from the pre-correction manuscript.

### Table 2 values (primary fixed effects, all 3 outcomes)

**Manuscript location/category:** Main text, Table 2
**Final value(s):**

| Outcome | Term | b | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| Distinctiveness | (Intercept) | 0.5659 | 0.1157 | 203.05 | 4.89 | < .001 |
| Distinctiveness | within_cAge | -0.009219 | 0.007042 | 543.88 | -1.31 | 0.191 |
| Distinctiveness | between_cAge | -0.003079 | 0.0006198 | 232.13 | -4.97 | < .001 |
| Distinctiveness | Sex_M1 | 0.01131 | 0.02587 | 215.50 | 0.44 | 0.663 |
| Distinctiveness | Education | 0.009137 | 0.006357 | 206.05 | 1.44 | 0.152 |
| Distinctiveness | aud_mot | 0.5202 | 0.01342 | 550.17 | 38.75 | < .001 |
| Distinctiveness | aud_vis | -0.06060 | 0.01331 | 548.84 | -4.55 | < .001 |
| Reliability | (Intercept) | 0.5843 | 0.08404 | 208.57 | 6.95 | < .001 |
| Reliability | within_cAge | -0.008891 | 0.004285 | 528.70 | -2.08 | 0.038 |
| Reliability | between_cAge | -0.003198 | 0.0004462 | 223.23 | -7.17 | < .001 |
| Reliability | Sex_M1 | -0.01234 | 0.01871 | 215.61 | -0.66 | 0.510 |
| Reliability | Education | 0.002734 | 0.004611 | 211.40 | 0.59 | 0.554 |
| Reliability | aud_mot | 0.07929 | 0.008178 | 536.88 | 9.70 | < .001 |
| Reliability | aud_vis | -0.03764 | 0.008106 | 536.03 | -4.64 | < .001 |
| Confusability | (Intercept) | 0.0002987 | 0.07998 | 187.79 | 0.00 | 0.997 |
| Confusability | within_cAge | 0.001305 | 0.006231 | 577.19 | 0.21 | 0.834 |
| Confusability | between_cAge | -0.0001117 | 0.0004398 | 257.21 | -0.25 | 0.800 |
| Confusability | Sex_M1 | -0.02254 | 0.01808 | 211.80 | -1.25 | 0.214 |
| Confusability | Education | -0.005336 | 0.004402 | 190.77 | -1.21 | 0.227 |
| Confusability | aud_mot | -0.4396 | 0.01187 | 576.53 | -37.04 | < .001 |
| Confusability | aud_vis | 0.02346 | 0.01177 | 574.56 | 1.99 | 0.047 |

n = 724 observations, 218 participants for all 21 rows.
**Source file in repository:** `output/tables/table_2.csv`
**Notes:** Every value here is the corrected result; all 21 rows change numerically from the pre-correction manuscript's Table 2 (see "What changed" below). No sign change, no p-value crosses .05.

### Table 3 values (primary descriptive statistics)

**Manuscript location/category:** Main text, Table 3
**Final value(s):**

| Sample | Modality | n | Reliability M (SD) | Confusability M (SD) | Distinctiveness M (SD) |
| --- | --- | --- | --- | --- | --- |
| Young adults, Wave 1 | Auditory | 58 | 0.741 (0.151) | 0.406 (0.242) | 0.336 (0.185) |
| Young adults, Wave 1 | Motor | 53 | 0.778 (0.201) | -0.644 (0.232) | 1.422 (0.413) |
| Young adults, Wave 1 | Visual | 56 | 0.719 (0.148) | -0.113 (0.246) | 0.832 (0.287) |
| Older adults, Wave 1 | Auditory | 149 | 0.538 (0.209) | 0.267 (0.241) | 0.271 (0.149) |
| Older adults, Wave 1 | Motor | 130 | 0.699 (0.170) | -0.543 (0.192) | 1.241 (0.336) |
| Older adults, Wave 1 | Visual | 132 | 0.561 (0.186) | -0.085 (0.224) | 0.647 (0.287) |
| Older adults, Wave 2 (returners) | Auditory | 57 | 0.540 (0.182) | 0.253 (0.194) | 0.287 (0.132) |
| Older adults, Wave 2 (returners) | Motor | 43 | 0.669 (0.191) | -0.519 (0.238) | 1.188 (0.410) |
| Older adults, Wave 2 (returners) | Visual | 45 | 0.534 (0.190) | -0.122 (0.200) | 0.656 (0.276) |
| Older adults, Wave 1 (Wave 2 returners) | Auditory | 56 | 0.545 (0.226) | 0.262 (0.257) | 0.283 (0.169) |
| Older adults, Wave 1 (Wave 2 returners) | Motor | 53 | 0.718 (0.172) | -0.561 (0.177) | 1.279 (0.324) |
| Older adults, Wave 1 (Wave 2 returners) | Visual | 52 | 0.559 (0.199) | -0.101 (0.230) | 0.660 (0.300) |

**Source file in repository:** `output/tables/table_3.csv`
**Notes:** Unchanged from the pre-correction manuscript.

### Results — Distinctiveness age effects

**Manuscript location/category:** Main text, Results, Distinctiveness
**Final value(s):**
- Between-person: **b = -0.003079, SE = 0.0006198, df = 232.13, t = -4.97, p < .001**
- Within-person: **b = -0.009219, SE = 0.007042, df = 543.88, t = -1.31, p = 0.191**
**Source file in repository:** `output/tables/table_2.csv` (outcome = Distinctiveness, term = between_cAge / within_cAge)
**Notes:** Both values changed numerically from the pre-correction manuscript; neither crosses the .05 threshold in either version, and neither changed sign.

### Results — Reliability age effects

**Manuscript location/category:** Main text, Results, Reliability
**Final value(s):**
- Between-person: **b = -0.003198, SE = 0.0004462, df = 223.23, t = -7.17, p < .001**
- Within-person: **b = -0.008891, SE = 0.004285, df = 528.70, t = -2.08, p = 0.038**
**Source file in repository:** `output/tables/table_2.csv` (outcome = Reliability, term = between_cAge / within_cAge)
**Notes:** Both values changed numerically. The within-person effect remains significant at p < .05 in both the old and corrected analysis (old p = .024, corrected p = .038) — the conclusion is unchanged, but the reported p-value must be updated.

### Results — Confusability age effects

**Manuscript location/category:** Main text, Results, Confusability
**Final value(s):**
- Between-person: **b = -0.0001117, SE = 0.0004398, df = 257.21, t = -0.25, p = 0.800**
- Within-person: **b = 0.001305, SE = 0.006231, df = 577.19, t = 0.21, p = 0.834**
**Source file in repository:** `output/tables/table_2.csv` (outcome = Confusability, term = between_cAge / within_cAge)
**Notes:** Both values changed numerically; both remain non-significant in both versions.

### Results — Reliability-vs-confusability magnitude comparison (primary)

**Manuscript location/category:** Main text, Results, magnitude contrast
**Final value(s):**
- Between-person age: **delta = 0.003086, 95% CI [0.001811, 0.003770]**
- Within-person age: **delta = 0.007586, 95% CI [-0.004765, 0.01480]**
(delta = |b_Reliability| - |b_Confusability|; positive = larger in magnitude for reliability)
**Source file in repository:** `output/tables/magnitude_comparison.csv` (motion_rule = primary); raw draws in `output/tables/bootstrap_draws_primary.csv`
**Notes:** Both point estimates and both intervals changed numerically from the pre-correction manuscript; the between-person interval excludes zero in both versions, the within-person interval includes zero in both versions — zero-inclusion conclusion unchanged for both.

---

## Supplement

### Liberal-rule sample size

**Manuscript location/category:** Supplement, Participants/Sample description (liberal rule)
**Final value(s):**
- Participants: **226**
- Sessions: **286** (226 Wave 1 + 60 Wave 2)
- Modality-level observations: **841**
- Modality counts: Auditory **282**, Motor **280**, Visual **279**
- Returners: **60**
- Follow-up interval (returners only): **M = 4.02, SD = 0.87, range 3–7 years**
- Wave-2-only participants: **0**
**Source file in repository:** `output/tables/table_s1.csv`, `output/tables/table_s2.csv`, `MANUSCRIPT_CHECK.md` §A; modality counts/follow-up interval computed directly from `analysis_liberal`
**Notes:** Unchanged from the pre-correction manuscript.

### Table S1 values (liberal participant characteristics)

**Manuscript location/category:** Supplement, Table S1
**Final value(s):**

| Sample | n | Age M (SD) | Age range | Education M (SD) | Men | Women |
| --- | --- | --- | --- | --- | --- | --- |
| Young adults, Wave 1 | 60 | 22.77 (2.95) | 18–29 | 15.35 (1.56) | 31 | 29 |
| Older adults, Wave 1 | 166 | 70.52 (4.99) | 65–87 | 16.80 (2.17) | 62 | 104 |
| Older adults, Wave 2 (returners) | 60 | 74.35 (5.43) | 68–94 | 16.70 (2.19) | 24 | 36 |
| Older adults, Wave 1 (Wave 2 returners) | 60 | 70.33 (5.16) | 65–87 | 16.70 (2.19) | 24 | 36 |

**Source file in repository:** `output/tables/table_s1.csv`
**Notes:** Unchanged from the pre-correction manuscript.

### Table S2 values (liberal descriptive statistics)

**Manuscript location/category:** Supplement, Table S2
**Final value(s):**

| Sample | Modality | n | Reliability M (SD) | Confusability M (SD) | Distinctiveness M (SD) |
| --- | --- | --- | --- | --- | --- |
| Young adults, Wave 1 | Auditory | 60 | 0.734 (0.154) | 0.396 (0.244) | 0.337 (0.183) |
| Young adults, Wave 1 | Motor | 60 | 0.740 (0.227) | -0.610 (0.249) | 1.350 (0.460) |
| Young adults, Wave 1 | Visual | 59 | 0.695 (0.180) | -0.116 (0.239) | 0.812 (0.299) |
| Older adults, Wave 1 | Auditory | 162 | 0.516 (0.217) | 0.254 (0.237) | 0.262 (0.151) |
| Older adults, Wave 1 | Motor | 162 | 0.671 (0.182) | -0.519 (0.201) | 1.190 (0.360) |
| Older adults, Wave 1 | Visual | 162 | 0.539 (0.190) | -0.083 (0.218) | 0.621 (0.280) |
| Older adults, Wave 2 (returners) | Auditory | 60 | 0.529 (0.192) | 0.239 (0.196) | 0.290 (0.143) |
| Older adults, Wave 2 (returners) | Motor | 58 | 0.644 (0.201) | -0.499 (0.239) | 1.143 (0.421) |
| Older adults, Wave 2 (returners) | Visual | 58 | 0.476 (0.214) | -0.119 (0.188) | 0.596 (0.298) |
| Older adults, Wave 1 (Wave 2 returners) | Auditory | 59 | 0.530 (0.232) | 0.252 (0.255) | 0.278 (0.171) |
| Older adults, Wave 1 (Wave 2 returners) | Motor | 59 | 0.691 (0.185) | -0.540 (0.185) | 1.230 (0.349) |
| Older adults, Wave 1 (Wave 2 returners) | Visual | 59 | 0.537 (0.213) | -0.090 (0.235) | 0.627 (0.309) |

**Source file in repository:** `output/tables/table_s2.csv`
**Notes:** Unchanged from the pre-correction manuscript.

### Table S3 motion accounting (both rules)

**Manuscript location/category:** Supplement, Table S3
**Final value(s):**

| Rule | Age group | Modality | Runs assessed | Runs excluded | % excluded | Mean % scrubbed |
| --- | --- | --- | --- | --- | --- | --- |
| primary | Older adults | Auditory | 223 | 16 | 7.17% | 2.79% |
| primary | Older adults | Motor | 226 | 53 | 23.45% | 7.06% |
| primary | Older adults | Visual | 226 | 49 | 21.68% | 6.12% |
| primary | Young adults | Auditory | 60 | 2 | 3.33% | 1.44% |
| primary | Young adults | Motor | 60 | 7 | 11.67% | 3.11% |
| primary | Young adults | Visual | 60 | 4 | 6.67% | 2.72% |
| primary | Older adults | All modalities | 675 | 118 | 17.48% | 5.33% |
| primary | Young adults | All modalities | 180 | 13 | 7.22% | 2.43% |
| primary | All participants | Auditory | 283 | 18 | 6.36% | 2.50% |
| primary | All participants | Motor | 286 | 60 | 20.98% | 6.24% |
| primary | All participants | Visual | 286 | 53 | 18.53% | 5.41% |
| primary | All participants | All modalities | 855 | 131 | 15.32% | 4.72% |
| liberal | Older adults | Auditory | 223 | 1 | 0.45% | 1.68% |
| liberal | Older adults | Motor | 226 | 6 | 2.65% | 4.45% |
| liberal | Older adults | Visual | 226 | 6 | 2.65% | 3.91% |
| liberal | Young adults | Auditory | 60 | 0 | 0.00% | 0.97% |
| liberal | Young adults | Motor | 60 | 0 | 0.00% | 2.16% |
| liberal | Young adults | Visual | 60 | 1 | 1.67% | 1.81% |
| liberal | Older adults | All modalities | 675 | 13 | 1.93% | 3.35% |
| liberal | Young adults | All modalities | 180 | 1 | 0.56% | 1.65% |
| liberal | All participants | Auditory | 283 | 1 | 0.35% | 1.53% |
| liberal | All participants | Motor | 286 | 6 | 2.10% | 3.97% |
| liberal | All participants | Visual | 286 | 7 | 2.45% | 3.47% |
| liberal | All participants | All modalities | 855 | 14 | 1.64% | 2.99% |

**Source file in repository:** `output/tables/table_s3.csv`
**Notes:** Unchanged from the pre-correction manuscript.

### Table S4 fixed effects (liberal rule, all 3 outcomes)

**Manuscript location/category:** Supplement, Table S4
**Final value(s):**

| Outcome | Term | b | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| Distinctiveness | (Intercept) | 0.4988 | 0.1176 | 218.19 | 4.24 | < .001 |
| Distinctiveness | within_cAge | -0.009146 | 0.006817 | 631.19 | -1.34 | 0.180 |
| Distinctiveness | between_cAge | -0.003289 | 0.0006399 | 253.19 | -5.14 | < .001 |
| Distinctiveness | Sex_M1 | 0.02024 | 0.02633 | 227.85 | 0.77 | 0.443 |
| Distinctiveness | Education | 0.01046 | 0.006414 | 221.11 | 1.63 | 0.104 |
| Distinctiveness | aud_mot | 0.4963 | 0.01284 | 633.53 | 38.66 | < .001 |
| Distinctiveness | aud_vis | -0.06279 | 0.01285 | 634.72 | -4.88 | < .001 |
| Reliability | (Intercept) | 0.5404 | 0.08979 | 223.96 | 6.02 | < .001 |
| Reliability | within_cAge | -0.009147 | 0.003979 | 623.91 | -2.30 | 0.022 |
| Reliability | between_cAge | -0.003235 | 0.0004815 | 241.24 | -6.72 | < .001 |
| Reliability | Sex_M1 | -0.01561 | 0.02001 | 229.72 | -0.78 | 0.436 |
| Reliability | Education | 0.004371 | 0.004889 | 225.78 | 0.89 | 0.372 |
| Reliability | aud_mot | 0.07781 | 0.007497 | 625.86 | 10.38 | < .001 |
| Reliability | aud_vis | -0.04252 | 0.007509 | 626.65 | -5.66 | < .001 |
| Confusability | (Intercept) | 0.02660 | 0.07190 | 210.70 | 0.37 | 0.712 |
| Confusability | within_cAge | 0.0001542 | 0.005776 | 664.58 | 0.03 | 0.979 |
| Confusability | between_cAge | 8.246e-06 | 0.0004063 | 302.81 | 0.02 | 0.984 |
| Confusability | Sex_M1 | -0.03416 | 0.01625 | 227.94 | -2.10 | 0.037 |
| Confusability | Education | -0.005400 | 0.003931 | 215.27 | -1.37 | 0.171 |
| Confusability | aud_mot | -0.4178 | 0.01087 | 666.56 | -38.43 | < .001 |
| Confusability | aud_vis | 0.01984 | 0.01088 | 668.12 | 1.82 | 0.069 |

n = 841 observations, 226 participants for all 21 rows.
**Source file in repository:** `output/tables/table_s4.csv`
**Notes:** Every value here is the corrected result; all 21 rows change numerically (see "What changed" below). No sign change. One term (Confusability, Sex_M1: p = 0.037) is below .05 in the corrected liberal-rule results — check whether this term's p-value was already reported as significant in your current manuscript text, since the number itself has moved slightly (old vs. corrected both < .05 here; this is not a newly-crossed threshold, see below).

### Liberal-rule magnitude comparison

**Manuscript location/category:** Supplement, magnitude contrast (liberal rule)
**Final value(s):**
- Between-person age: **delta = 0.003227, 95% CI [0.001866, 0.003856]**
- Within-person age: **delta = 0.008993, 95% CI [-0.003202, 0.01421]**
**Source file in repository:** `output/tables/magnitude_comparison.csv` (motion_rule = liberal); raw draws in `output/tables/bootstrap_draws_liberal.csv`
**Notes:** Both point estimates and both intervals changed numerically; zero-inclusion conclusion unchanged for both (between excludes zero, within includes zero, in both old and corrected analyses).

---

## Figures

### Figure 2 (primary): pooled slopes and caption-stated values

**Manuscript location/category:** Main text, Figure 2
**Final value(s):**
- Pooled (heavy, near-black) line slopes = the between_cAge/within_cAge rows of Table 2, identical values:
  - Distinctiveness: between -0.003079, within -0.009219
  - Reliability: between -0.003198, within -0.008891
  - Confusability: between -0.0001117, within 0.001305
- Values explicitly stated in the caption text: reference age **65** (between-person column) and reference **first wave / time 0** (within-person column).
**Source file in repository:** `output/figures/figure_2_caption.txt`; slopes verified bit-for-bit identical to `output/tables/table_2.csv` (see `MANUSCRIPT_CHECK.md` §F)
**Notes:** Colored modality lines are explicitly descriptive only (caption: "descriptive only, from visualization-only fits... carry no inferential interaction test, simple-slope estimate, or modality-specific statistical conclusion"). No interaction p-value, F-test, or simple-slope number is stated anywhere in the caption or figure.

### Figure 3 (primary): point estimates and 95% bootstrap CIs

**Manuscript location/category:** Main text, Figure 3
**Final value(s):**
- Between-person age: **delta = 0.003086, 95% CI [0.001811, 0.003770]**
- Within-person age: **delta = 0.007586, 95% CI [-0.004765, 0.01480]**
- Caption explicitly states: **B = 5,000 draws**; "percentile intervals need not be symmetric about the point estimate."
**Source file in repository:** `output/figures/figure_3_caption.txt`; `output/tables/magnitude_comparison.csv`; point/segment coordinates verified bit-for-bit identical to the table (see `MANUSCRIPT_CHECK.md` §F)
**Notes:** These are 95% participant-level percentile bootstrap CIs. Do not describe them as "conservative" — the caption makes no such claim and the repository's prior over-claim on this point was already removed.

### Figure S1 (liberal): corresponding values

**Manuscript location/category:** Supplement, Figure S1
**Final value(s):**
- Pooled line slopes = the between_cAge/within_cAge rows of Table S4:
  - Distinctiveness: between -0.003289, within -0.009146
  - Reliability: between -0.003235, within -0.009147
  - Confusability: between 0.000008246, within 0.0001542
- Reference age **65** (between-person); reference **first wave / time 0** (within-person) — same as Figure 2.
**Source file in repository:** `output/figures/figure_s1_caption.txt`; slopes bit-for-bit identical to `output/tables/table_s4.csv`
**Notes:** Same descriptive-only status for colored modality lines as Figure 2.

### Figure S2 (liberal): corresponding values

**Manuscript location/category:** Supplement, Figure S2
**Final value(s):**
- Between-person age: **delta = 0.003227, 95% CI [0.001866, 0.003856]**
- Within-person age: **delta = 0.008993, 95% CI [-0.003202, 0.01421]**
- Caption explicitly states: **B = 5,000 draws**.
**Source file in repository:** `output/figures/figure_s2_caption.txt`; `output/tables/magnitude_comparison.csv`
**Notes:** Same CI-interpretation note as Figure 3 (percentile intervals, not "conservative").

---

## What changed from the previous manuscript numbers

**Unchanged** (verified exactly against the pre-correction manuscript values — see `MANUSCRIPT_CHECK.md` §E):
- Demographics (Tables 1, S1)
- Descriptive statistics (Tables 3, S2)
- Sample sizes (participants, sessions, observations, returners, both rules)
- Motion accounting (Table S3, both rules)

**Changed — every fixed-effect numerical value** (Tables 2 and S4, all 42 rows across both rules):
- All 21 primary-rule and all 21 liberal-rule coefficients, standard errors, t-values, and p-values move numerically from the pre-correction manuscript, because the person-mean age decomposition changed (equal weighting of unique retained participant-wave ages, instead of weighting by how many modalities a wave happened to retain). This affects `within_cAge` and `between_cAge` directly and `Sex_M1`/`Education`/`aud_mot`/`aud_vis`/the intercept indirectly (same model, re-estimated).
- **No coefficient changes sign**, in either outcome or either rule.
- **No fixed-effect p-value crosses the .05 threshold** between the old and corrected analysis — every term that was significant (p < .05) in the old results remains significant in the corrected results, and every term that was non-significant remains non-significant. (The Confusability × Sex_M1 term under the liberal rule, flagged above, is below .05 in *both* the old and corrected analysis — it does not represent a new threshold crossing.)

**Changed — all four magnitude-comparison values** (Table 3's in-text figure values / `magnitude_comparison.csv`, both rules, both age terms):
- All four `delta` point estimates and all four 95% CIs move numerically.
- **Zero-inclusion conclusions are unchanged** for all four: the between-person contrast excludes zero in both rules (old and corrected); the within-person contrast includes zero in both rules (old and corrected).

**Changed — Figures 2/3/S1/S2**: every pooled line, ribbon, and magnitude-contrast point/interval reflects the corrected coefficients and bootstrap above. The colored modality lines in Figures 2/S1 remain explicitly descriptive/visualization-only and were not part of what changed (they were never inferential).

**Not changed in this pass:** Nothing about the inclusion criteria, motion-exclusion rule definitions, modality coding, model specification, or which observations enter the analytic sample. Only the person-mean age values feeding `within_cAge`/`between_cAge` were corrected.
