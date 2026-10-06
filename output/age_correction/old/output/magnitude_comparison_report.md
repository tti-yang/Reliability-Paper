# Component age-effect magnitude comparison

Full pipeline rebuilt from raw inputs on 2026-09-10. Each script was launched from outside the repository to verify path anchoring.

5,000 paired participant resamples per motion rule; seed `20260910`; eight workers. Outcomes retain their shared correlation scale. Positive delta indicates the larger absolute reliability slope.

New-stage elapsed time: **446.48 seconds**, including R startup and validation. Full pipeline: **462.52 seconds**.

## Results

`Between` denotes `between_cAge`; `Within` denotes `within_cAge`. CI endpoints are the 2.5th and 97.5th percentiles of usable draws. Values below are rounded; the CSV preserves full precision.

### FD 0.4 mm / 10% (primary)

| Scope | Age term | b reliability | b confusability | Signed difference | Delta | 95% percentile CI | Bootstrap p | Usable draws |
| --- | --- | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| Pooled | Between | -0.003181 | -0.000107 | -0.003074 | 0.003074 | [0.001768, 0.003736] | 0.00000 | 4271/5000 |
| Pooled | Within | -0.009776 | 0.000017 | -0.009793 | 0.009759 | [-0.003167, 0.015613] | 0.19293 | 4271/5000 |
| Auditory | Between | -0.004118 | -0.002746 | -0.001372 | 0.001372 | [0.000270, 0.002510] | 0.01280 | 4532/5000 |
| Auditory | Within | -0.003338 | -0.003076 | -0.000262 | 0.000262 | [-0.008541, 0.007672] | 0.95322 | 4532/5000 |
| Visual | Between | -0.003347 | 0.000478 | -0.003825 | 0.002869 | [0.000988, 0.003981] | 0.00177 | 4532/5000 |
| Visual | Within | -0.009911 | -0.005919 | -0.003992 | 0.003992 | [-0.013569, 0.017101] | 0.75110 | 4532/5000 |
| Motor | Between | -0.001927 | 0.002295 | -0.004222 | -0.000368 | [-0.001241, 0.000539] | 0.42454 | 4532/5000 |
| Motor | Within | -0.016662 | 0.013705 | -0.030366 | 0.002957 | [-0.008379, 0.013509] | 0.57237 | 4532/5000 |

### FD 0.5 mm / 20% (liberal)

| Scope | Age term | b reliability | b confusability | Signed difference | Delta | 95% percentile CI | Bootstrap p | Usable draws |
| --- | --- | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| Pooled | Between | -0.003232 | 0.000008 | -0.003240 | 0.003223 | [0.001791, 0.003803] | 0.00000 | 3353/5000 |
| Pooled | Within | -0.009342 | 0.000157 | -0.009499 | 0.009184 | [-0.002913, 0.014465] | 0.16880 | 3353/5000 |
| Auditory | Between | -0.004379 | -0.002799 | -0.001581 | 0.001581 | [0.000500, 0.002678] | 0.00552 | 3989/5000 |
| Auditory | Within | 0.000629 | -0.001874 | 0.002503 | -0.001245 | [-0.009991, 0.010514] | 0.98822 | 3989/5000 |
| Visual | Between | -0.003574 | 0.000668 | -0.004242 | 0.002906 | [0.001075, 0.004121] | 0.00201 | 3989/5000 |
| Visual | Within | -0.014957 | -0.007571 | -0.007386 | 0.007386 | [-0.007828, 0.020218] | 0.36099 | 3989/5000 |
| Motor | Between | -0.001750 | 0.002182 | -0.003931 | -0.000432 | [-0.001235, 0.000426] | 0.30233 | 3989/5000 |
| Motor | Within | -0.013693 | 0.010215 | -0.023908 | 0.003478 | [-0.005103, 0.011591] | 0.42617 | 3989/5000 |

## Fit failures and interpretation

Singular and non-converged bootstrap fits were excluded as specified in the analysis brief. Failure rates exceed 1% and must be considered when interpreting the resulting intervals: inference uses the subset of resamples with accepted fits. The 50-draw diagnostic traced all rejected smoke-test draws to singular confusability models.

| Motion rule | Model scope | Usable draws | Rejected (%) |
| --- | --- | ---: | ---: |
| FD 0.4 mm / 10% (primary) | Pooled | 4271/5000 | 14.58 |
| FD 0.4 mm / 10% (primary) | Interaction (all modalities) | 4532/5000 | 9.36 |
| FD 0.5 mm / 20% (liberal) | Pooled | 3353/5000 | 32.94 |
| FD 0.5 mm / 20% (liberal) | Interaction (all modalities) | 3989/5000 | 20.22 |

The two-sided p value is `2 * min(mean(delta_star <= 0), mean(delta_star >= 0))`, capped at one for ties at zero. A reported zero means no usable draw crossed zero; it is not an exactly zero population probability.

## Validation and corrections to the brief

- Component samples agree exactly: primary 724 observations; liberal 841 observations. Participant counts and actual fitted rows agree for both components.
- Every pooled and modality-specific component slope matches the corresponding stage 02 export within `1e-8`. Original observations satisfy `Distinctiveness = Reliability - Confusability` within `1e-8`. Same-sign magnitude identities also pass.
- The proposed identity in the brief between the signed component difference and the separately fitted distinctiveness coefficient does not hold: outcome-specific mixed models estimate different variance parameters. The existing exports already differed by up to approximately 0.000816. The implementation checks component-to-component agreement and prints the distinctiveness discrepancies rather than changing the models to force equality. This reasoning follows the [lme4 model formulation, Section 3](https://lme4.github.io/lme4/articles/lmer.pdf).
- Since stage 04 validates against stage 02 CSVs, stage 02 must precede stage 04. Stages 02, 03, and 05 can otherwise run independently after stage 01.
- `tests/check_magnitude.R` passed: unequal observation samples, complete cluster copies and unique IDs, original-data point estimates, serial/parallel reproducibility, RNG/contrast restoration, and failed-draw handling.
- All R files and R Markdown chunks parse. Shiny server checks confirmed reactive point estimates and fixed cached intervals. Full HTML rendering was not tested because Pandoc is unavailable.
- The full six-stage pipeline passed, including existing contextual-effect and figure assertions. The new result is copied to supplementary Table S9; contextual effects remain S8. No existing manuscript table number changed.

## Stage runtimes

| Stage | Seconds (including R startup) |
| --- | ---: |
| 01_prepare_data | 2.12 |
| 02_fit_models | 3.57 |
| 03_sensitivity | 2.49 |
| 04_magnitude_comparison | 446.48 |
| 05_figures | 6.03 |
| 06_assemble_manuscript | 1.83 |
