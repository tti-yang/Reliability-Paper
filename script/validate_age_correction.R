# Targeted OLD vs CORRECTED validation; never writes manuscript/ or raw inputs.
# Run after stages 01, 02, 04, 05. OLD is the preserved pre-correction snapshot.
PROJECT_ROOT <- local({
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  dirname(dirname(normalizePath(sub("^--file=", "", arg))))
})
for (file in c("setup.R", "data.R", "models.R", "figures.R")) {
  source(file.path(PROJECT_ROOT, "R", file))
}
AUDIT <- project_path("output", "age_correction")
OLD <- file.path(AUDIT, "old")
read_csv1 <- function(path) readr::read_csv(path, num_threads=1, show_col_types=FALSE)
write_audit <- function(x, name) readr::write_csv(x, file.path(AUDIT, paste0(name, ".csv")))
paired <- function(old, corrected, keys, fields) {
  stopifnot(!anyDuplicated(old[keys]), !anyDuplicated(corrected[keys]),
            nrow(anti_join(old, corrected, by=keys)) == 0,
            nrow(anti_join(corrected, old, by=keys)) == 0)
  a <- old %>% select(all_of(c(keys, fields))) %>% rename_with(~paste0("old_", .x), all_of(fields))
  b <- corrected %>% select(all_of(c(keys, fields))) %>% rename_with(~paste0("corrected_", .x), all_of(fields))
  left_join(a, b, by=keys)
}
long_comparison <- function(old, corrected, keys) {
  fields <- names(old)[vapply(old, is.numeric, logical(1)) & !names(old) %in% keys]
  a <- old %>% select(all_of(c(keys, fields))) %>% pivot_longer(all_of(fields), names_to="statistic", values_to="old")
  b <- corrected %>% select(all_of(c(keys, fields))) %>% pivot_longer(all_of(fields), names_to="statistic", values_to="corrected")
  result <- full_join(a,b,by=c(keys,"statistic")) %>% mutate(difference=corrected-old, changed=abs(difference)>1e-12)
  stopifnot(nrow(result)==nrow(a), !anyNA(result))
  result
}

# Both versions start from the same raw files; only the age decomposition differs.
invisible(list2env(load_source_data(), globalenv()))
old_env <- new.env(parent=globalenv())
sys.source(file.path(OLD, "R", "data.R"), envir=old_env)
old_data <- setNames(lapply(MOTION_RULES, function(r) old_env$build_analysis_data(r$fd_cutoff,r$pct_cutoff)),rule_keys())
corrected_data <- setNames(lapply(MOTION_RULES, function(r) build_analysis_data(r$fd_cutoff,r$pct_cutoff)),rule_keys())
old_cached <- readRDS(file.path(OLD,"data/derived/analysis_data_by_rule.rds"))
corrected_cached <- read_derived("analysis_data_by_rule")
stopifnot(isTRUE(all.equal(old_data,old_cached)),isTRUE(all.equal(corrected_data,corrected_cached)))
for (key in rule_keys()) {
 a <- old_data[[key]]; b <- corrected_data[[key]]
 unchanged <- setdiff(names(a),c("mean_age","within_cAge","between_cAge"))
 stopifnot(identical(a[unchanged],b[unchanged]))
 validate_age_decomposition(b)
}

count_sample <- function(d) {
 session_rows <- d %>% distinct(SubNum,Wave_Num)
 waves <- session_rows %>% count(SubNum)
 tibble(observations=nrow(d),sessions=nrow(session_rows),participants=n_distinct(d$SubNum),
        returners=sum(waves$n==2),wave1_sessions=sum(session_rows$Wave_Num==1),
        wave2_sessions=sum(session_rows$Wave_Num==2),
        wave2_only_participants=sum(session_rows$Wave_Num==2 & session_rows$SubNum %in% waves$SubNum[waves$n==1]))
}
samples <- map_dfr(MOTION_RULES,function(r) {
 long_comparison(count_sample(old_data[[r$key]]) %>% mutate(rule=r$key),
                 count_sample(corrected_data[[r$key]]) %>% mutate(rule=r$key),"rule")
})
write_audit(samples,"sample_comparison")
ages <- map_dfr(MOTION_RULES,function(r) {
 a <- old_data[[r$key]] %>% distinct(SubNum,Wave_Num,Age_DuringParticipation_,mean_age,within_cAge,between_cAge)
 b <- corrected_data[[r$key]] %>% distinct(SubNum,Wave_Num,Age_DuringParticipation_,mean_age,within_cAge,between_cAge)
 paired(a,b,c("SubNum","Wave_Num","Age_DuringParticipation_"),c("mean_age","within_cAge","between_cAge")) %>% mutate(rule=r$key,.before=1)
})
write_audit(ages,"session_age_comparison")

# OLD fixed-effect estimates are independently refit from raw inputs.
old_models <- lapply(old_data,fit_outcome_models)
corrected_models <- lapply(corrected_data,fit_outcome_models)
old_est <- model_estimates_export(old_data,old_models)
new_est <- model_estimates_export(corrected_data,corrected_models)
old_export <- read_csv1(file.path(OLD,"output/tables/model_estimates.csv"))
new_export <- read_csv1(file.path(TABLE_DIR,"model_estimates.csv"))
stopifnot(isTRUE(all.equal(old_est,old_export,tolerance=1e-8,check.attributes=FALSE)),
          isTRUE(all.equal(new_est,new_export,tolerance=1e-8,check.attributes=FALSE)))
fixed <- paired(old_export,new_export,c("motion_rule","outcome","term"),
                c("estimate","se","df","t","p","n_observations","n_participants")) %>%
 mutate(numerical_change=abs(corrected_estimate-old_estimate)>1e-12,
        significance_changed=(old_p<.05)!=(corrected_p<.05),
        sign_changed=sign(old_estimate)!=sign(corrected_estimate))
write_audit(fixed,"fixed_effects_comparison")
write_audit(long_comparison(old_export,new_export,c("motion_rule","outcome","term")),"fixed_effects_all_statistics")

# Wave-1-anchored groups deliberately exclude the Wave-2-only older adult.
# That participant remains in pooled models; do not add to Table 1 groups.
summary_changes <- map_dfr(MOTION_RULES,function(r) {
 map_dfr(c("demographics","descriptives"),function(kind) {
  filename <- paste0(r$prefix,"_",kind,".csv")
  a <- read_csv1(file.path(OLD,"output/tables",filename))
  b <- read_csv1(file.path(TABLE_DIR,filename))
  builder <- get(paste0(kind,"_export"))
  stopifnot(isTRUE(all.equal(a,builder(old_data[[r$key]],r$label),check.attributes=FALSE)),
            isTRUE(all.equal(b,builder(corrected_data[[r$key]],r$label),check.attributes=FALSE)))
  keys <- c("motion_rule","sample",if(kind=="descriptives") "modality")
  long_comparison(a,b,keys) %>% mutate(table=kind,.before=1)
 })
})
write_audit(summary_changes,"demographics_descriptives_comparison")
stopifnot(!any(summary_changes$changed))
wave2_only <- corrected_data$primary %>% group_by(SubNum) %>% filter(all(Wave_Num==2)) %>% ungroup()
stopifnot(n_distinct(wave2_only$SubNum)==1,nrow(wave2_only)==1,all(wave2_only$Modality=="Aud"),
          all(wave2_only$Age_DuringParticipation_>=65))
for (sample in sample_definitions(corrected_data$primary)) {
 stopifnot(!any(wave2_only$SubNum %in% sample$SubNum))
}
write_audit(wave2_only,"wave2_only_analytic_participant")
motion_old <- read_csv1(file.path(OLD,"output/tables/motion_accounting.csv"))
motion_new <- read_csv1(file.path(TABLE_DIR,"motion_accounting.csv"))
motion_cmp <- long_comparison(motion_old,motion_new,c("motion_rule","age_group","modality"))
stopifnot(!any(motion_cmp$changed))
write_audit(motion_cmp,"motion_accounting_comparison")

# Compare saved OLD 5,000-draw intervals with the corrected full rerun.
old_mag <- read_csv1(file.path(OLD,"output/tables/magnitude_comparison.csv")) %>% filter(scope=="Pooled")
new_mag <- read_csv1(file.path(TABLE_DIR,"magnitude_comparison.csv"))
mag <- paired(old_mag,new_mag,c("motion_rule","scope","age_term"),
              c("b_reliability","b_confusability","signed_diff","delta","delta_ci_lo","delta_ci_hi","boot_p","n_boot_ok")) %>%
 mutate(old_excludes_zero=old_delta_ci_lo>0 | old_delta_ci_hi<0,
        corrected_excludes_zero=corrected_delta_ci_lo>0 | corrected_delta_ci_hi<0,
        conclusion_changed=old_excludes_zero!=corrected_excludes_zero)
write_audit(mag,"magnitude_comparison")
boot <- readRDS(file.path(DERIVED_DATA_DIR,"magnitude_bootstrap_by_rule.rds"))
boot_counts <- map_dfr(seq_along(MOTION_RULES),function(i) {
 metadata <- attr(boot[[i]],"bootstrap")
 stopifnot(metadata$B==5000L,metadata$seed==MAGNITUDE_BOOT_SEED,
           metadata$pooled_only,nrow(metadata$draws)==5000,ncol(metadata$draws)==2)
 for(j in 1:2) {
  valid <- metadata$draws[is.finite(metadata$draws[,j]),j]
  stopifnot(isTRUE(all.equal(as.numeric(quantile(valid,c(.025,.975))),
                           c(boot[[i]]$delta_ci_lo[j],boot[[i]]$delta_ci_hi[j]))))
 }
 write_audit(as_tibble(metadata$draws,.name_repair=~metadata$contrasts$age_term) %>% mutate(draw=row_number(),.before=1),paste0("bootstrap_draws_",MOTION_RULES[[i]]$key))
 tibble(rule=MOTION_RULES[[i]]$key,requested=metadata$B,
        usable_between=boot[[i]]$n_boot_ok[1],usable_within=boot[[i]]$n_boot_ok[2],
        singular_draws_retained=sum(metadata$singular_draws),seed=metadata$seed)
})
write_audit(boot_counts,"bootstrap_diagnostics")

# Every plotted line coordinate and pooled ribbon bound, not merely endpoints.
old_fig <- readRDS(file.path(OLD,"data/derived/figure_data_by_rule.rds"))
new_fig <- read_derived("figure_data_by_rule")
all_lines <- list(); all_ribbons <- list(); all_slopes <- list(); all_magnitude_points <- list()
for(r in MOTION_RULES) {
 raw_lines <- list(old=combined_plot_data(old_fig[[r$key]]$figure2,old_fig[[r$key]]$figure3),
                   corrected=combined_plot_data(new_fig[[r$key]]$figure2,new_fig[[r$key]]$figure3))
 # Verify old cached predictions against models rebuilt from the raw inputs.
 old_viz <- fit_visualization_models(old_data[[r$key]])
 old_rebuilt <- combined_plot_data(figure2_plot_data(old_data[[r$key]],old_models[[r$key]],old_viz),
                                  figure3_plot_data(old_data[[r$key]],old_models[[r$key]],old_viz))
 stopifnot(max(abs(old_rebuilt$predicted-raw_lines$old$predicted))<1e-8)
 centered <- lapply(raw_lines,centre_combined_lines)
 line_frames <- lapply(centered,function(x) x %>% group_by(measure,column,series) %>%
   mutate(grid_index=row_number()) %>% ungroup() %>%
   select(measure,column,series,grid_index,x,predicted,gap_span,solid_segment))
 all_lines[[r$key]] <- paired(line_frames$old,line_frames$corrected,
   c("measure","column","series","grid_index"),c("x","predicted","gap_span","solid_segment")) %>% mutate(rule=r$key,.before=1)
 slope_frame <- function(x) x %>% group_by(measure,column,series) %>% summarise(
   slope=(predicted[which.max(x)]-predicted[which.min(x)])/(max(x)-min(x)),
   x_min=min(x),x_max=max(x),y_start=predicted[which.min(x)],y_end=predicted[which.max(x)],.groups="drop")
 all_slopes[[r$key]] <- paired(slope_frame(centered$old),slope_frame(centered$corrected),
   c("measure","column","series"),c("slope","x_min","x_max","y_start","y_end")) %>%
   mutate(rule=r$key,role=if_else(series==POOLED_SERIES,"Pooled manuscript model","Descriptive visualization only"),.before=1)
 ribbons <- list(old=combined_change_ribbon(centered$old,combined_pooled_slopes(old_export,r$label)),
                 corrected=combined_change_ribbon(centered$corrected,combined_pooled_slopes(new_export,r$label)))
 ribbons <- lapply(ribbons,function(x) x %>% group_by(measure,column) %>% mutate(grid_index=row_number()) %>% ungroup())
 all_ribbons[[r$key]] <- paired(ribbons$old,ribbons$corrected,c("measure","column","grid_index"),
   c("x","predicted","conf_low","conf_high")) %>% mutate(rule=r$key,.before=1)
 all_magnitude_points[[r$key]] <- paired(magnitude_plot_data(old_mag,r$label),magnitude_plot_data(new_mag,r$label),
   c("age_term"),c("y","delta","conf_low","conf_high","n_boot_ok")) %>% mutate(rule=r$key,.before=1)
}
write_audit(bind_rows(all_lines),"figure_2_s1_all_line_coordinates")
write_audit(bind_rows(all_ribbons),"figure_2_s1_all_ribbon_coordinates")
write_audit(bind_rows(all_slopes),"figure_2_s1_slopes_endpoints")
write_audit(bind_rows(all_magnitude_points),"figure_3_s2_all_coordinates")

# A readable report includes every fixed effect and links full-precision values.
fmt <- function(x) ifelse(is.na(x),"",formatC(x,digits=7,format="g"))
md_table <- function(d) {
 d <- as.data.frame(d)
 for(n in names(d)) if(is.numeric(d[[n]])) d[[n]] <- fmt(d[[n]])
 c(paste0("| ",paste(names(d),collapse=" | ")," |"),
   paste0("| ",paste(rep("---",ncol(d)),collapse=" | ")," |"),
   apply(d,1,function(row) paste0("| ",paste(row,collapse=" | ")," |")),"")
}
report <- c("**Age decomposition correction: OLD vs CORRECTED**", "",
 "OLD denotes the archived pre-correction results. Both analytic datasets and all six OLD and CORRECTED pooled models were reconstructed from the repository raw CSVs; their estimates match the archived/current exports. OLD intervals are the archived 5,000-draw intervals; CORRECTED intervals were rerun with 5,000 participant resamples per rule, seed 20260910, on the corrected raw-input datasets. Singular fits remain eligible; nonconverged/rank-deficient/error fits are rejected as before.","",
 "The only analytic-data change is equal weighting of unique retained participant-wave ages. Inclusion, outcomes, covariates, modality coding, and Wave-1-anchored sample definitions are unchanged. No manuscript file was edited. Retired output files remain in place pending the later cleanup and are not corrected manuscript results.","",
 "The OLD report at output/magnitude_comparison_report.md is stale and is not the baseline for this comparison; the archived CSV is authoritative.","",
 "**Sample sizes (OLD and CORRECTED)**", "",md_table(samples %>% select(rule,statistic,old,corrected)),
 "**Age decomposition changes**", "")
report <- c(report,md_table(ages %>% group_by(rule) %>% summarise(
 affected_participants=n_distinct(SubNum[abs(corrected_mean_age-old_mean_age)>1e-10]),
 max_mean_age_change=max(abs(corrected_mean_age-old_mean_age)),.groups="drop")),
 "[Every participant-session age quantity, OLD and CORRECTED](session_age_comparison.csv).", "",
 "**All fixed effects**", "",
 "Estimates are ML; SE, df, t and p use lmerTest Satterthwaite inference. Each term has an OLD and a CORRECTED row. Values are displayed to seven significant digits; [full-precision paired coefficients](fixed_effects_comparison.csv) and [all statistics and changes](fixed_effects_all_statistics.csv) are available.", "")
for(r in MOTION_RULES) for(out in c("Distinctiveness","Reliability","Confusability")) {
 rows <- fixed %>% filter(motion_rule==r$label,outcome==out)
 shown <- map_dfr(seq_len(nrow(rows)),function(i) {
  x <- rows[i,]
  tibble(term=x$term,version=c("OLD","CORRECTED"),estimate=c(x$old_estimate,x$corrected_estimate),
         SE=c(x$old_se,x$corrected_se),df=c(x$old_df,x$corrected_df),t=c(x$old_t,x$corrected_t),p=c(x$old_p,x$corrected_p))
 })
 report <- c(report,paste0("**",r$label," — ",out,"**"),"",md_table(shown))
}
report <- c(report,"**Magnitude contrasts and Figures 3/S2**","",
 md_table(mag %>% select(motion_rule,age_term,old_delta,corrected_delta,old_delta_ci_lo,old_delta_ci_hi,corrected_delta_ci_lo,corrected_delta_ci_hi,conclusion_changed)),
 "[Full magnitude comparison, including component coefficients, p values, and usable draws](magnitude_comparison.csv). [Every Figure 3/S2 point and CI coordinate](figure_3_s2_all_coordinates.csv).","",
 md_table(boot_counts),
 "**Participant characteristics, descriptives, and motion accounting**", "",
 "All demographic and descriptive numbers are unchanged. [Every demographic/descriptive statistic, OLD and CORRECTED](demographics_descriptives_comparison.csv). [Every motion-accounting statistic, OLD and CORRECTED](motion_accounting_comparison.csv).",
 paste0("The primary-rule Wave-2-only older adult (SubNum ",wave2_only$SubNum[[1]],") retains one auditory observation in all three models. This participant is deliberately absent from the Wave-1-anchored demographic/descriptive groups. The corresponding manuscript note is preserved because manuscript files are untouched."),"",
 "**Every Figure 2/S1 value**", "",
 "The heavy pooled lines and their Satterthwaite change intervals use the same models as the fixed-effect tables. Colored lines in both columns use visualization-only interaction fits; no inferential interaction tests or simple-slope tables are generated or consulted.","",
 "[Every plotted line coordinate, OLD and CORRECTED](figure_2_s1_all_line_coordinates.csv). [Every pooled ribbon bound, OLD and CORRECTED](figure_2_s1_all_ribbon_coordinates.csv). Grid indices pair corresponding ordered points; both x coordinates are retained because within-person display ranges can change. Colored lines have no inferential ribbon. [All line slopes, ranges and endpoints](figure_2_s1_slopes_endpoints.csv).", "",
 md_table(bind_rows(all_slopes) %>% select(rule,measure,column,series,old_slope,corrected_slope)),
 "**Manuscript statements requiring numerical updates**", "",
 paste0("- ",sum(fixed$numerical_change)," of 42 fixed-effect estimates change numerically. Update all six model summaries/tables, including SE, df, t and p, using the comparison files."),
 paste0("- Fixed-effect p < .05 classifications change for ",sum(fixed$significance_changed)," of 42 terms; coefficient signs change for ",sum(fixed$sign_changed)," terms."),
 paste0("- Bootstrap CI zero-inclusion conclusions change for ",sum(mag$conclusion_changed)," of four magnitude contrasts; all four point estimates and intervals require numerical updates."),
 "- Replace all model-implied age-effect coordinates, pooled intervals, and descriptive colored slopes with the corrected Figure 2/S1 values.",
 "- Remove interaction-significance claims from Figure 2/S1 captions. Descriptive status applies to colored lines in both columns regardless of any significance test.",
 "- Figure 3/S2 captions now state percentile intervals need not be symmetric; the unsupported assertion that these intervals are conservative was removed.",
 "- Sample-size, Wave-1-anchored demographics/descriptives, and assessed-run motion statements do not change.","",
 "These flags identify statements supported by the available analysis outputs; no manuscript prose was edited or assumed to have been updated.","",
 "**Missing-motion records**", "",
 "Both rules have the same 84 unmatched modality rows: 30 participant-wave sessions from 29 participants. Wave 1: auditory 22, motor 19, visual 19 (60 rows); Wave 2: 8 per modality (24 rows). All 84 rows lack all three prepared outcomes under both rules.","",
 "For 83 rows there is no motion record for that subject/modality in any session. The remaining row is mindo107 / SubNum 107 / Wave 1 / auditory: its only corresponding motion row is drug/001, not the required placebo/001. Normalizing case, whitespace, and run-number zero padding does not produce any missing placebo match. This supports unavailable prepared measurements rather than a detected join-format error; the upstream acquisition/preprocessing reason cannot be established from these CSVs alone.","",
 "The older noninteractive Motion Corrected Analaysis.Rmd uses the same placebo/run-001 join and filter(!exclude), which drops unmatched NA flags. All three outcomes are already absent for these rows, so admitting them would not add complete model observations; doing so before age decomposition could nonetheless alter session means and reported counts. The exclusion policy is unchanged.","",
 "[Every unmatched row, outcome availability and alternative motion records](missing_motion_rows.csv). [All affected participants, waves and modalities](missing_motion_sessions.csv).","",
 "**Validation**", "",
 "Equal-wave weighting, single-wave zero, identical within-session quantities, unchanged row membership/covariates, both raw-input reconstructions, all fixed-effect exports, unchanged anchored summaries/motion tables, OLD cached figure predictions, corrected bootstrap percentile calculations, and plotted pooled slope/interval consistency were checked. The figure regression test exercises export without simple-slope or interaction-test CSVs.","",
 "The snapshot in old/ preserves prior code, derived data, tables and figures. protected_sha256.json records the raw/manuscript hashes. session_info.txt records the R environment. Obsolete analyses were not rerun and broad repository restructuring was not performed.")
writeLines(report,file.path(AUDIT,"comparison_report.md"))
writeLines(capture.output(sessionInfo()),file.path(AUDIT,"session_info.txt"))
message("Comparison validated and written to ",file.path(AUDIT,"comparison_report.md"))
