**Age decomposition correction: OLD vs CORRECTED**

OLD denotes the archived pre-correction results. Both analytic datasets and all six OLD and CORRECTED pooled models were reconstructed from the repository raw CSVs; their estimates match the archived/current exports. OLD intervals are the archived 5,000-draw intervals; CORRECTED intervals were rerun with 5,000 participant resamples per rule, seed 20260910, on the corrected raw-input datasets. Singular fits remain eligible; nonconverged/rank-deficient/error fits are rejected as before.

The only analytic-data change is equal weighting of unique retained participant-wave ages. Inclusion, outcomes, covariates, modality coding, and Wave-1-anchored sample definitions are unchanged. No manuscript file was edited. Retired output files remain in place pending the later cleanup and are not corrected manuscript results.

The OLD report at output/magnitude_comparison_report.md is stale and is not the baseline for this comparison; the archived CSV is authoritative.

**Sample sizes (OLD and CORRECTED)**

| rule | statistic | old | corrected |
| --- | --- | --- | --- |
| primary | observations |      724 |      724 |
| primary | sessions |      276 |      276 |
| primary | participants |      218 |      218 |
| primary | returners |       58 |       58 |
| primary | wave1_sessions |      217 |      217 |
| primary | wave2_sessions |       59 |       59 |
| primary | wave2_only_participants |        1 |        1 |
| liberal | observations |      841 |      841 |
| liberal | sessions |      286 |      286 |
| liberal | participants |      226 |      226 |
| liberal | returners |       60 |       60 |
| liberal | wave1_sessions |      226 |      226 |
| liberal | wave2_sessions |       60 |       60 |
| liberal | wave2_only_participants |        0 |        0 |

**Age decomposition changes**

| rule | affected_participants | max_mean_age_change |
| --- | --- | --- |
| liberal |        5 |      0.5 |
| primary |       18 |     1.25 |

[Every participant-session age quantity, OLD and CORRECTED](session_age_comparison.csv).

**All fixed effects**

Estimates are ML; SE, df, t and p use lmerTest Satterthwaite inference. Each term has an OLD and a CORRECTED row. Values are displayed to seven significant digits; [full-precision paired coefficients](fixed_effects_comparison.csv) and [all statistics and changes](fixed_effects_all_statistics.csv) are available.

**FD 0.4 mm / 10% (primary) — Distinctiveness**

| term | version | estimate | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| (Intercept) | OLD | 0.5670913 | 0.1157237 | 203.0529 | 4.900392 | 1.952288e-06 |
| (Intercept) | CORRECTED | 0.5659291 | 0.1157262 | 203.0538 | 4.890242 | 2.044495e-06 |
| within_cAge | OLD | -0.009747659 | 0.007090738 | 528.8127 | -1.374703 | 0.1698057 |
| within_cAge | CORRECTED | -0.009219343 | 0.007042386 | 543.8817 | -1.309122 | 0.1910458 |
| between_cAge | OLD | -0.003067443 | 0.0006204228 | 232.1295 | -4.944117 | 1.466494e-06 |
| between_cAge | CORRECTED | -0.003079402 | 0.0006198264 | 232.1347 | -4.968168 | 1.311286e-06 |
| Sex_M1 | OLD | 0.01118999 | 0.02586857 | 215.5243 | 0.432571 | 0.665759 |
| Sex_M1 | CORRECTED | 0.01130759 | 0.02587471 | 215.5004 | 0.4370133 | 0.6625393 |
| Education | OLD | 0.009097 | 0.006356577 | 206.0842 | 1.431116 | 0.1539116 |
| Education | CORRECTED | 0.009137489 | 0.006357395 | 206.0514 | 1.437301 | 0.1521494 |
| aud_mot | OLD | 0.5201702 | 0.01342493 | 550.0036 | 38.74658 | 2.457371e-159 |
| aud_mot | CORRECTED | 0.5202387 | 0.01342391 |  550.168 | 38.75462 | 2.154116e-159 |
| aud_vis | OLD | -0.06063023 | 0.013308 | 548.8569 | -4.555925 | 6.432144e-06 |
| aud_vis | CORRECTED | -0.06059596 | 0.01330804 | 548.8387 | -4.553334 | 6.509009e-06 |

**FD 0.4 mm / 10% (primary) — Reliability**

| term | version | estimate | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| (Intercept) | OLD | 0.5857192 | 0.08394535 | 208.5991 | 6.977388 | 3.920037e-11 |
| (Intercept) | CORRECTED | 0.5842954 | 0.08403519 | 208.5747 | 6.952984 | 4.513047e-11 |
| within_cAge | OLD | -0.009776072 | 0.004304842 | 518.5188 | -2.270948 | 0.02355934 |
| within_cAge | CORRECTED | -0.008891223 | 0.004284821 | 528.6951 | -2.075051 | 0.03846485 |
| between_cAge | OLD | -0.003181252 | 0.0004461812 | 223.3256 | -7.129955 | 1.37774e-11 |
| between_cAge | CORRECTED | -0.003197952 | 0.0004462047 |  223.228 | -7.167006 | 1.107259e-11 |
| Sex_M1 | OLD | -0.01246868 | 0.01868926 | 215.6703 | -0.6671573 | 0.5053848 |
| Sex_M1 | CORRECTED | -0.01234478 | 0.01871311 | 215.6083 | -0.6596862 | 0.5101593 |
| Education | OLD | 0.00267932 | 0.004605175 | 211.4454 | 0.5818063 | 0.5613169 |
| Education | CORRECTED | 0.002734176 | 0.004610618 | 211.3981 | 0.5930172 | 0.5538035 |
| aud_mot | OLD | 0.07922164 | 0.008178206 | 536.8792 | 9.686922 | 1.468237e-20 |
| aud_mot | CORRECTED | 0.07929408 | 0.008178035 | 536.8839 | 9.695981 | 1.361428e-20 |
| aud_vis | OLD | -0.03767522 | 0.008105665 | 536.1468 | -4.648011 | 4.224002e-06 |
| aud_vis | CORRECTED | -0.03764426 | 0.00810592 | 536.0299 | -4.644045 | 4.302937e-06 |

**FD 0.4 mm / 10% (primary) — Confusability**

| term | version | estimate | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| (Intercept) | OLD | 0.0004871858 | 0.08002297 | 187.8435 | 0.006088074 | 0.9951489 |
| (Intercept) | CORRECTED | 0.0002987281 | 0.07998413 | 187.7869 | 0.003734842 | 0.997024 |
| within_cAge | OLD | 1.68413e-05 | 0.006303548 | 552.5956 | 0.002671718 | 0.9978692 |
| within_cAge | CORRECTED | 0.001305262 | 0.006231139 | 577.1882 | 0.209474 | 0.8341521 |
| between_cAge | OLD | -0.000107403 | 0.0004404069 | 257.0909 | -0.2438722 | 0.8075243 |
| between_cAge | CORRECTED | -0.0001117491 | 0.0004398005 |  257.209 | -0.2540905 | 0.7996287 |
| Sex_M1 | OLD | -0.02253297 | 0.01808547 | 211.8913 | -1.245915 | 0.2141713 |
| Sex_M1 | CORRECTED | -0.02254219 | 0.01808073 |  211.802 | -1.246752 | 0.2138653 |
| Education | OLD | -0.005351034 | 0.004404195 | 190.8873 | -1.214986 | 0.2258723 |
| Education | CORRECTED | -0.005336291 | 0.004402418 | 190.7725 | -1.212127 | 0.2269627 |
| aud_mot | OLD | -0.4396588 | 0.01186978 | 576.2359 | -37.04018 | 1.488019e-154 |
| aud_mot | CORRECTED | -0.439599 | 0.01186823 | 576.5307 | -37.03997 | 1.382487e-154 |
| aud_vis | OLD | 0.02344213 | 0.01177043 | 574.5523 | 1.991611 | 0.04688668 |
| aud_vis | CORRECTED | 0.02345755 | 0.01177051 | 574.5583 | 1.992909 | 0.04674394 |

**FD 0.5 mm / 20% (liberal) — Distinctiveness**

| term | version | estimate | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| (Intercept) | OLD | 0.4990417 | 0.1176185 |  218.166 | 4.242884 | 3.262372e-05 |
| (Intercept) | CORRECTED | 0.4987657 | 0.1176427 |  218.188 | 4.239665 | 3.305752e-05 |
| within_cAge | OLD | -0.009498418 | 0.006820726 | 629.6553 | -1.392582 | 0.1642379 |
| within_cAge | CORRECTED | -0.009146257 | 0.006816946 | 631.1859 | -1.341694 | 0.1801776 |
| between_cAge | OLD | -0.003285532 | 0.0006398014 | 253.2058 | -5.135238 | 5.624528e-07 |
| between_cAge | CORRECTED | -0.003289145 | 0.0006398808 |  253.192 | -5.140246 | 5.490676e-07 |
| Sex_M1 | OLD | 0.02029139 | 0.02632743 | 227.8273 | 0.7707319 | 0.4416644 |
| Sex_M1 | CORRECTED | 0.02023766 | 0.0263342 | 227.8535 | 0.7684934 | 0.4429899 |
| Education | OLD | 0.01044317 | 0.006413133 | 221.0949 | 1.628403 | 0.1048635 |
| Education | CORRECTED | 0.01046373 | 0.006414237 | 221.1129 | 1.631329 | 0.1042444 |
| aud_mot | OLD | 0.4963287 | 0.01283756 |   633.52 | 38.66224 | 7.515943e-169 |
| aud_mot | CORRECTED | 0.4963313 | 0.01283748 | 633.5263 | 38.66267 | 7.466765e-169 |
| aud_vis | OLD | -0.06279399 | 0.01285467 | 634.7066 | -4.884916 | 1.311425e-06 |
| aud_vis | CORRECTED | -0.06278774 | 0.01285458 | 634.7153 | -4.884463 | 1.314327e-06 |

**FD 0.5 mm / 20% (liberal) — Reliability**

| term | version | estimate | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| (Intercept) | OLD | 0.5406959 | 0.08976258 | 223.9381 | 6.023622 | 6.931936e-09 |
| (Intercept) | CORRECTED | 0.5404372 | 0.08979181 | 223.9589 | 6.018781 | 7.111868e-09 |
| within_cAge | OLD | -0.009341655 | 0.00398039 | 623.0934 | -2.34692 | 0.01924149 |
| within_cAge | CORRECTED | -0.009147392 | 0.003979157 | 623.9118 | -2.298827 | 0.0218444 |
| between_cAge | OLD | -0.003231601 | 0.0004814057 | 241.2422 | -6.712843 | 1.35366e-10 |
| between_cAge | CORRECTED | -0.003234904 | 0.0004815278 | 241.2409 | -6.717999 | 1.313944e-10 |
| Sex_M1 | OLD | -0.01555758 | 0.02000199 | 229.6982 | -0.777802 | 0.4374862 |
| Sex_M1 | CORRECTED | -0.01560787 | 0.02000947 | 229.7203 | -0.7800243 | 0.4361795 |
| Education | OLD | 0.004351931 | 0.004887335 | 225.7632 | 0.8904508 | 0.3741718 |
| Education | CORRECTED | 0.004371161 | 0.00488877 | 225.7808 | 0.8941228 | 0.3722083 |
| aud_mot | OLD | 0.07780482 | 0.00749702 | 625.8528 |  10.3781 | 2.168349e-23 |
| aud_mot | CORRECTED | 0.07780599 | 0.007496977 | 625.8632 | 10.37832 | 2.16405e-23 |
| aud_vis | OLD | -0.04251925 | 0.007508614 | 626.6416 | -5.66273 | 2.270608e-08 |
| aud_vis | CORRECTED | -0.04251557 | 0.007508568 | 626.6532 | -5.662274 | 2.276342e-08 |

**FD 0.5 mm / 20% (liberal) — Confusability**

| term | version | estimate | SE | df | t | p |
| --- | --- | --- | --- | --- | --- | --- |
| (Intercept) | OLD | 0.0265999 | 0.0719003 | 210.7019 | 0.3699553 | 0.7117874 |
| (Intercept) | CORRECTED | 0.02660275 | 0.07189851 | 210.7016 | 0.3700042 | 0.711751 |
| within_cAge | OLD | 0.0001572982 | 0.005782874 | 661.3743 | 0.02720069 | 0.9783079 |
| within_cAge | CORRECTED | 0.0001542102 | 0.005776205 | 664.5766 | 0.02669749 | 0.978709 |
| between_cAge | OLD | 8.216232e-06 | 0.000406387 | 302.8479 | 0.02021775 | 0.983883 |
| between_cAge | CORRECTED | 8.245771e-06 | 0.0004063456 | 302.8133 | 0.02029251 | 0.9838234 |
| Sex_M1 | OLD | -0.03415953 | 0.01625302 | 227.9252 | -2.101734 | 0.03667466 |
| Sex_M1 | CORRECTED | -0.03415775 | 0.01625366 |  227.937 | -2.101542 | 0.03669165 |
| Education | OLD | -0.0053998 | 0.003931614 | 215.2769 | -1.373431 | 0.171047 |
| Education | CORRECTED | -0.005400134 | 0.003931381 |  215.274 | -1.373597 | 0.1709954 |
| aud_mot | OLD | -0.4177777 | 0.01087105 | 666.5547 | -38.43032 | 3.211624e-171 |
| aud_mot | CORRECTED | -0.4177778 | 0.01087104 |  666.556 | -38.43035 | 3.209579e-171 |
| aud_vis | OLD | 0.01984143 | 0.01088147 | 668.1096 | 1.823414 | 0.06868739 |
| aud_vis | CORRECTED | 0.01984122 | 0.01088144 | 668.1161 | 1.823399 | 0.06868963 |

**Magnitude contrasts and Figures 3/S2**

| motion_rule | age_term | old_delta | corrected_delta | old_delta_ci_lo | old_delta_ci_hi | corrected_delta_ci_lo | corrected_delta_ci_hi | conclusion_changed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FD 0.4 mm / 10% (primary) | between_cAge | 0.003073849 | 0.003086203 | 0.001795295 | 0.003750068 | 0.001810724 | 0.003769531 | FALSE |
| FD 0.4 mm / 10% (primary) | within_cAge | 0.009759231 | 0.007585962 | -0.0032476 | 0.01561428 | -0.004765429 | 0.01480079 | FALSE |
| FD 0.5 mm / 20% (liberal) | between_cAge | 0.003223385 | 0.003226658 | 0.001861172 | 0.003852673 | 0.001865864 | 0.003855517 | FALSE |
| FD 0.5 mm / 20% (liberal) | within_cAge | 0.009184356 | 0.008993182 | -0.003039832 | 0.01432869 | -0.003201783 | 0.01420707 | FALSE |

[Full magnitude comparison, including component coefficients, p values, and usable draws](magnitude_comparison.csv). [Every Figure 3/S2 point and CI coordinate](figure_3_s2_all_coordinates.csv).

| rule | requested | usable_between | usable_within | singular_draws_retained | seed |
| --- | --- | --- | --- | --- | --- |
| primary |     5000 |     5000 |     5000 |      740 | 2.026091e+07 |
| liberal |     5000 |     5000 |     5000 |     1646 | 2.026091e+07 |

**Participant characteristics, descriptives, and motion accounting**

All demographic and descriptive numbers are unchanged. [Every demographic/descriptive statistic, OLD and CORRECTED](demographics_descriptives_comparison.csv). [Every motion-accounting statistic, OLD and CORRECTED](motion_accounting_comparison.csv).
The primary-rule Wave-2-only older adult (SubNum 118) retains one auditory observation in all three models. This participant is deliberately absent from the Wave-1-anchored demographic/descriptive groups. The corresponding manuscript note is preserved because manuscript files are untouched.

**Every Figure 2/S1 value**

The heavy pooled lines and their Satterthwaite change intervals use the same models as the fixed-effect tables. Colored lines in both columns use visualization-only interaction fits; no inferential interaction tests or simple-slope tables are generated or consulted.

[Every plotted line coordinate, OLD and CORRECTED](figure_2_s1_all_line_coordinates.csv). [Every pooled ribbon bound, OLD and CORRECTED](figure_2_s1_all_ribbon_coordinates.csv). Grid indices pair corresponding ordered points; both x coordinates are retained because within-person display ranges can change. Colored lines have no inferential ribbon. [All line slopes, ranges and endpoints](figure_2_s1_slopes_endpoints.csv).

| rule | measure | column | series | old_slope | corrected_slope |
| --- | --- | --- | --- | --- | --- |
| primary | Distinctiveness | Between-person | All modalities | -0.003067443 | -0.003079402 |
| primary | Distinctiveness | Between-person | Auditory | -0.001417188 | -0.00142036 |
| primary | Distinctiveness | Between-person | Visual | -0.003823769 | -0.00382725 |
| primary | Distinctiveness | Between-person | Motor | -0.004212075 | -0.004237554 |
| primary | Distinctiveness | Within-person | All modalities | -0.009747659 | -0.009219343 |
| primary | Distinctiveness | Within-person | Auditory | -0.0008751057 | -0.0007207182 |
| primary | Distinctiveness | Within-person | Visual | -0.003856889 | -0.004869529 |
| primary | Distinctiveness | Within-person | Motor | -0.02955049 | -0.02582162 |
| primary | Reliability | Between-person | All modalities | -0.003181252 | -0.003197952 |
| primary | Reliability | Between-person | Auditory | -0.00411849 | -0.004126934 |
| primary | Reliability | Between-person | Visual | -0.003347196 | -0.003363404 |
| primary | Reliability | Between-person | Motor | -0.001927327 | -0.00194712 |
| primary | Reliability | Within-person | All modalities | -0.009776072 | -0.008891223 |
| primary | Reliability | Within-person | Auditory | -0.003337969 | -0.002414139 |
| primary | Reliability | Within-person | Visual | -0.009911011 | -0.009098679 |
| primary | Reliability | Within-person | Motor | -0.01666179 | -0.0153701 |
| primary | Confusability | Between-person | All modalities | -0.000107403 | -0.0001117491 |
| primary | Confusability | Between-person | Auditory | -0.002746024 | -0.002754821 |
| primary | Confusability | Between-person | Visual | 0.0004779002 | 0.0004658758 |
| primary | Confusability | Between-person | Motor | 0.002295152 | 0.002303924 |
| primary | Confusability | Within-person | All modalities | 1.68413e-05 | 0.001305262 |
| primary | Confusability | Within-person | Auditory | -0.003075725 | -0.001332024 |
| primary | Confusability | Within-person | Visual | -0.005919482 | -0.003379818 |
| primary | Confusability | Within-person | Motor | 0.01370464 | 0.01187947 |
| liberal | Distinctiveness | Between-person | All modalities | -0.003285532 | -0.003289145 |
| liberal | Distinctiveness | Between-person | Auditory | -0.001637519 | -0.001639511 |
| liberal | Distinctiveness | Between-person | Visual | -0.004273427 | -0.004275645 |
| liberal | Distinctiveness | Between-person | Motor | -0.003968987 | -0.003975423 |
| liberal | Distinctiveness | Within-person | All modalities | -0.009498418 | -0.009146257 |
| liberal | Distinctiveness | Within-person | Auditory | 0.002312512 | 0.002473145 |
| liberal | Distinctiveness | Within-person | Visual | -0.007291035 | -0.007308087 |
| liberal | Distinctiveness | Within-person | Motor | -0.02380729 | -0.02287667 |
| liberal | Reliability | Between-person | All modalities | -0.003231601 | -0.003234904 |
| liberal | Reliability | Between-person | Auditory | -0.004379221 | -0.004380925 |
| liberal | Reliability | Between-person | Visual | -0.003574144 | -0.003578106 |
| liberal | Reliability | Between-person | Motor | -0.001749752 | -0.001753475 |
| liberal | Reliability | Within-person | All modalities | -0.009341655 | -0.009147392 |
| liberal | Reliability | Within-person | Auditory | 0.0006289736 | 0.0006915638 |
| liberal | Reliability | Within-person | Visual | -0.01495696 | -0.01466296 |
| liberal | Reliability | Within-person | Motor | -0.01369306 | -0.01349102 |
| liberal | Confusability | Between-person | All modalities | 8.216232e-06 | 8.245771e-06 |
| liberal | Confusability | Between-person | Auditory | -0.002798714 | -0.00279898 |
| liberal | Confusability | Between-person | Visual | 0.0006680669 | 0.0006661664 |
| liberal | Confusability | Between-person | Motor | 0.002181655 | 0.00218428 |
| liberal | Confusability | Within-person | All modalities | 0.0001572982 | 0.0001542102 |
| liberal | Confusability | Within-person | Auditory | -0.001873929 | -0.001798006 |
| liberal | Confusability | Within-person | Visual | -0.007571073 | -0.007134805 |
| liberal | Confusability | Within-person | Motor | 0.01021524 | 0.009614832 |

**Manuscript statements requiring numerical updates**

- 42 of 42 fixed-effect estimates change numerically. Update all six model summaries/tables, including SE, df, t and p, using the comparison files.
- Fixed-effect p < .05 classifications change for 0 of 42 terms; coefficient signs change for 0 terms.
- Bootstrap CI zero-inclusion conclusions change for 0 of four magnitude contrasts; all four point estimates and intervals require numerical updates.
- Replace all model-implied age-effect coordinates, pooled intervals, and descriptive colored slopes with the corrected Figure 2/S1 values.
- Remove interaction-significance claims from Figure 2/S1 captions. Descriptive status applies to colored lines in both columns regardless of any significance test.
- Figure 3/S2 captions now state percentile intervals need not be symmetric; the unsupported assertion that these intervals are conservative was removed.
- Sample-size, Wave-1-anchored demographics/descriptives, and assessed-run motion statements do not change.

These flags identify statements supported by the available analysis outputs; no manuscript prose was edited or assumed to have been updated.

**Missing-motion records**

Both rules have the same 84 unmatched modality rows: 30 participant-wave sessions from 29 participants. Wave 1: auditory 22, motor 19, visual 19 (60 rows); Wave 2: 8 per modality (24 rows). All 84 rows lack all three prepared outcomes under both rules.

For 83 rows there is no motion record for that subject/modality in any session. The remaining row is mindo107 / SubNum 107 / Wave 1 / auditory: its only corresponding motion row is drug/001, not the required placebo/001. Normalizing case, whitespace, and run-number zero padding does not produce any missing placebo match. This supports unavailable prepared measurements rather than a detected join-format error; the upstream acquisition/preprocessing reason cannot be established from these CSVs alone.

The older noninteractive Motion Corrected Analaysis.Rmd uses the same placebo/run-001 join and filter(!exclude), which drops unmatched NA flags. All three outcomes are already absent for these rows, so admitting them would not add complete model observations; doing so before age decomposition could nonetheless alter session means and reported counts. The exclusion policy is unchanged.

[Every unmatched row, outcome availability and alternative motion records](missing_motion_rows.csv). [All affected participants, waves and modalities](missing_motion_sessions.csv).

**Validation**

Equal-wave weighting, single-wave zero, identical within-session quantities, unchanged row membership/covariates, both raw-input reconstructions, all fixed-effect exports, unchanged anchored summaries/motion tables, OLD cached figure predictions, corrected bootstrap percentile calculations, and plotted pooled slope/interval consistency were checked. The figure regression test exercises export without simple-slope or interaction-test CSVs.

The snapshot in old/ preserves prior code, derived data, tables and figures. protected_sha256.json records the raw/manuscript hashes. session_info.txt records the R environment. Obsolete analyses were not rerun and broad repository restructuring was not performed.
