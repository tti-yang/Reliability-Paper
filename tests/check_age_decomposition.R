# Rscript tests/check_age_decomposition.R
PROJECT_ROOT <- local({
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  dirname(dirname(normalizePath(sub("^--file=", "", arg))))
})
source(file.path(PROJECT_ROOT, "R", "setup.R"))
source(file.path(PROJECT_ROOT, "R", "data.R"))
# Three modalities at Wave 1, one at Wave 2; second participant is single-wave.
x <- tibble(SubNum = c(1, 1, 1, 1, 2, 2),
            Wave_Num = c(1, 1, 1, 2, 2, 2),
            Age_DuringParticipation_ = c(65, 65, 65, 69, 72, 72),
            Modality = c("Aud", "Mot", "Vis", "Aud", "Aud", "Vis"))
a <- add_age_decomposition(x)
stopifnot(identical(a$SubNum, x$SubNum), nrow(a) == nrow(x),
          all(a$person_mean_age[a$SubNum == 1] == 67),
          identical(a$within_cAge, c(-2, -2, -2, 2, 0, 0)),
          identical(a$between_cAge, c(2, 2, 2, 2, 7, 7)),
          identical(a$aud_mot, c(-1, 1, 0, -1, -1, 0)),
          identical(a$aud_vis, c(-1, 0, 1, -1, -1, 1)))
# Removing extra modalities leaves the session age decomposition unchanged.
b <- add_age_decomposition(x[c(1, 4, 5), ])
stopifnot(identical(b$person_mean_age, a$person_mean_age[c(1, 4, 5)]),
          identical(b$within_cAge, a$within_cAge[c(1, 4, 5)]))
expect_error <- function(expr) stopifnot(inherits(tryCatch({force(expr); NULL}, error=identity), "error"))
bad <- x; bad$Age_DuringParticipation_[2] <- 66
expect_error(add_age_decomposition(bad))
bad <- a; bad$within_cAge[2] <- -1
expect_error(validate_age_decomposition(bad))
bad <- a; bad$person_mean_age[bad$SubNum == 1] <- 66
expect_error(validate_age_decomposition(bad))
raw <- build_all_from_source()$analysis_data_by_rule
invisible(lapply(raw, validate_age_decomposition))
message("Age checks passed: equal wave weights, single-wave zero, consistent session values, preserved rows/contrasts, invalid-age rejection, both raw-input rules.")
