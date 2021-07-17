# --------------
# Title: pd_module.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Oct 27 2016
# --------------
# Description: This file contains code for running the PD module.
# --------------
# Author:
# Date:
# Modification:
# --------------

write_log_sub_header("pd_module.R", "Protocol Deviations Module", log_con)

# Applies the model for protocol deviations.
#
# Args:
#   Model.data: Dataframe with one row for each PD monitoring visit to be
#     evaluated, and containing all variables necessary to apply the PD model
#
# Returns: A list containing two dataframes of PD module results, formatted for
#  output to the relevant Oracle database tables which feed into Spotfire.
run_pd_model <- function(Model.data) {
  # Start to create the PD output dataset
  PD.out <- Model.data[c("HM_SITE_ID", "HM_STUDY_ID", "PFIZER_PROTOCOL_ID")]
  PD.out$HM_WRK_PD_OUT_ID <- NA # Add empty key column for sqlSave function
  PD.out$PERIOD_START_CURRENT <- Model.data$DATE
  PD.out$PERIOD_END_CURRENT <- Model.data$PD_VISIT_END_DATE
  PD.out$PATIENT_COUNT <- Model.data$PATIENT_COUNT_IN_PD_VISIT
  PD.out$PATIENT_COUNT_SCALE <- Model.data$PATIENT_COUNT_IN_PD_VISIT_SCALED
  PD.out$PD_COUNT_ACTUAL_CURRENT <- Model.data$NUM_PDS_IN_VISIT

  PD.out$CURRENT_PERIOD_LENGTH <- as.integer(PD.out$PERIOD_END_CURRENT
                                             - PD.out$PERIOD_START_CURRENT) + 1

  # Load fitted PD model object
  model <- readRDS(file.path(MODEL.DIR, "pd_fitted_model.rds"))
  
  # Use model to score sites
  cat("Scoring sites for PD module...\n", file=log_con)
  predicted <- try(predict(model, Model.data), silent=TRUE)
  if (inherits(predicted, "try-error")) {
    stop("ERROR when scoring PD model:", as.character(predicted))
  }
  cat(paste("PD model successfully scored",
            length(unique(Model.data$HM_SITE_ID[!is.na(predicted)])),
            "out of", length(unique(Model.data$HM_SITE_ID)), "sites\n"),
      file=log_con)
  if (any(is.na(predicted))) {
    cat("WARNING: When scoring PD model, unable to produce predictions for",
        "all relevant sites\n", file=log_con)
  }
  PD.out$PD_COUNT_EXPECTED_CURRENT <- predicted
  PD.out$DELTA_CURRENT <- PD.out$PD_COUNT_ACTUAL_CURRENT -
                            PD.out$PD_COUNT_EXPECTED_CURRENT

  # Create percentile scores: these are based on the percentiles of the
  # residuals (actual minus expected PDs) from when the PD model was originally
  # fit. Higher values indicate abnormally high PD counts; very low values may
  # signal potential underreporting.
  # Calculate the percentile, on a scale from 0 to 1, by calculating the
  # percentage of residuals from the model which are less than each delta
  PD.out$PD_PERCENTILE_CURRENT <- vapply(PD.out$DELTA_CURRENT,
                                         function(delta) {
                                           mean(model$residuals < delta)
                                         },
                                         numeric(1))


 
  # Next, create the PD_OUT_HIST dataset, which will include output from
  # every PD visit, not just the most recent at each site
  PD.hist <- PD.out[c("HM_STUDY_ID", "HM_SITE_ID",
                      "PATIENT_COUNT", "PATIENT_COUNT_SCALE")]
  PD.hist$HM_WRK_PD_OUT_HIST_ID <- NA # Add empty key for sqlSave function
  PD.hist$PERIOD_START <- PD.out$PERIOD_START_CURRENT
  PD.hist$PERIOD_END <- PD.out$PERIOD_END_CURRENT
  PD.hist$PERIOD_LENGTH <- PD.out$CURRENT_PERIOD_LENGTH
  PD.hist$PD_COUNT_ACTUAL <- PD.out$PD_COUNT_ACTUAL_CURRENT
  PD.hist$PD_COUNT_EXPECTED <- PD.out$PD_COUNT_EXPECTED_CURRENT
  PD.hist$PD_PERCENTILE <- PD.out$PD_PERCENTILE_CURRENT

  # Then, drop rows from the main PD OUT output dataset, keeping only the most
  # recent completed PD visit at each site
  PD.out <- PD.out[order(PD.out$HM_SITE_ID, PD.out$PERIOD_START_CURRENT),]
  PD.out <- PD.out[c(PD.out[1:(nrow(PD.out)-1),"HM_SITE_ID"]
                     != PD.out[2:nrow(PD.out),"HM_SITE_ID"], TRUE),]

  # Merge PD.hist with the original PD.out in order to populate the columns for
  # lagged actual and expected PD counts
  Lagged <- merge(PD.hist, PD.out[c("HM_SITE_ID", "PERIOD_START_CURRENT")])
  Lagged <- Lagged[Lagged$PERIOD_START < Lagged$PERIOD_START_CURRENT,]
  # Add a column "Lag" such that the most recent previous PD window is Lag=1,
  # the window before that is Lag=2, and so on
  # First, need to group each site together for the following line to work
  Lagged <- Lagged[order(Lagged$HM_SITE_ID),]
  # Then create Lag column
  Lagged$Lag <- unlist(with(Lagged, tapply(PERIOD_START, HM_SITE_ID, rank)))
  Lagged <- Lagged[Lagged$Lag <= 3,] # Keep first three lags only

  # Handle the case where there are no lagged visits found (this would likely
  # only occur when testing with a subsample of the data)
  if (nrow(Lagged) == 0) {
    PD.actual <- data.frame(HM_SITE_ID=integer(),
                            PD_COUNT_ACTUAL_T1=integer(),
                            PD_COUNT_ACTUAL_T2=integer(),
                            PD_COUNT_ACTUAL_T3=integer())
    PD.exp <- data.frame(HM_SITE_ID=integer(),
                         PD_COUNT_EXPECTED_T1=numeric(),
                         PD_COUNT_EXPECTED_T2=numeric(),
                         PD_COUNT_EXPECTED_T3=numeric())
  } else {
    # Convert each lagged value into columns for actual and expected PD counts,
    # for Lag 1, Lag 2, and Lag 3
    PD.actual <- dcast(Lagged, HM_SITE_ID ~ Lag, value.var="PD_COUNT_ACTUAL")
    names(PD.actual) <- c("HM_SITE_ID",
                          paste0("PD_COUNT_ACTUAL_T", 1:(ncol(PD.actual)-1)))
    PD.exp <- dcast(Lagged, HM_SITE_ID ~ Lag, value.var="PD_COUNT_EXPECTED")
    names(PD.exp) <- c("HM_SITE_ID",
                       paste0("PD_COUNT_EXPECTED_T", 1:(ncol(PD.exp)-1)))
    # If there are fewer than 3 lags (which might happen when testing on a small
    # subsample of the data), add columns of N/As
    for (lag in 1:3) {
      if (!paste0("PD_COUNT_ACTUAL_T", lag) %in% names(PD.actual)) {
        PD.actual[paste0("PD_COUNT_ACTUAL_T", lag)] <- as.integer(NA)
      }
      if (!paste0("PD_COUNT_EXPECTED_T", lag) %in% names(PD.exp)) {
        PD.exp[paste0("PD_COUNT_EXPECTED_T", lag)] <- as.integer(NA)
      }
    }
  }
  # Merge into main output dataframe
  PD.out <- merge(PD.out,
                  merge(PD.actual, PD.exp, by="HM_SITE_ID", all=TRUE),
                  by="HM_SITE_ID", all.x=TRUE)

  return(list(WRK_PD_OUT=PD.out[c("HM_WRK_PD_OUT_ID", "HM_SITE_ID",
                                  "HM_STUDY_ID", "PFIZER_PROTOCOL_ID",
                                  "PERIOD_START_CURRENT", "PERIOD_END_CURRENT",
                                  "PATIENT_COUNT", "PATIENT_COUNT_SCALE",
                                  "CURRENT_PERIOD_LENGTH",
                                  "PD_COUNT_ACTUAL_CURRENT",
                                  "PD_COUNT_ACTUAL_T1", "PD_COUNT_ACTUAL_T2",
                                  "PD_COUNT_ACTUAL_T3",
                                  "PD_COUNT_EXPECTED_CURRENT",
                                  "PD_COUNT_EXPECTED_T1",
                                  "PD_COUNT_EXPECTED_T2",
                                  "PD_COUNT_EXPECTED_T3", "DELTA_CURRENT",
                                  "PD_PERCENTILE_CURRENT")],
              WRK_PD_OUT_HIST=PD.hist[c("HM_WRK_PD_OUT_HIST_ID", "HM_STUDY_ID",
                                        "HM_SITE_ID", "PERIOD_START",
                                        "PERIOD_END", "PATIENT_COUNT",
                                        "PATIENT_COUNT_SCALE", "PERIOD_LENGTH",
                                        "PD_COUNT_ACTUAL", "PD_COUNT_EXPECTED",
                                        "PD_PERCENTILE")]))
  
}

out <- run_pd_model(Model.data.PD)
pd.out <- out$WRK_PD_OUT
pd.out.hist <- out$WRK_PD_OUT_HIST
####################################################################################################
######################### New modification 4.0 ##################################################
# REMOVE STUDY_THERAPEUTIC_AREA3
Model.data.PD = Model.data.PD[,!names(Model.data.PD)%in% "STUDY_THERAPEUTIC_AREA3"]
######## End of modification ###########################


