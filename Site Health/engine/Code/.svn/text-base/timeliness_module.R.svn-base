# --------------
# Title: timeliness_module.R
# --------------
# Author: Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Oct 27 2016
# --------------
# Description: This file contains code used to run the timeliness module to 
# predict ....
# --------------
# Author:
# Date:
# Modification:
# --------------

write_log_sub_header("timeliness_module.R", "Timeliness Module", log_con)

run_timeliness_model <- function(tl_org, Model.data){
  
  # Load model object
  tl.model <- readRDS(file.path(MODEL.DIR, "tl_fitted_model.rds"))
  
  # The response for the model
  response.name <- 'DET_MEDIAN_DAYS'
  
  # Use model to score sites
  Model.data$pred <- get_model_predictions(Model.data, tl.model, "Timeliness", log_con)
  Model.data$TIMELINESS_PERCENTILE <- ppois(Model.data$DET_MEDIAN_DAYS,lambda=Model.data$pred)
  # Some arbitraty rules for Not-Falgging and Flagging sites
  ## If median <5 and predicted <2 then don't flag. If median>25, the FLAG.
  Model.data$TIMELINESS_PERCENTILE <- ifelse(Model.data$pred <2 & Model.data$DET_MEDIAN_DAYS <5,0.55,Model.data$TIMELINESS_PERCENTILE)
  Model.data$TIMELINESS_PERCENTILE <- ifelse(Model.data$DET_MEDIAN_DAYS >30,1.0,Model.data$TIMELINESS_PERCENTILE)
  
  
  # Merge model data with predictions to add timeliness percentile
  Model.data <- merge(tl_org,Model.data[,c("HM_SITE_ID","TIMELINESS_PERCENTILE")])
  tl.out <- Model.data[,c("HM_SITE_ID","HM_STUDY_ID","TIMELINESS_PERCENTILE")]
  
  # Create null column for Spotfire table
  tl.out$HM_WRK_TL_OUT_ID <- NA
  tl.out$PERIOD_1_DATE <- NA
  tl.out$PERIOD_1_PATIENT_VISIT_COUNT <- NA
  tl.out$PERIOD_1_DATA_ENTRY_TIMELINESS <- NA
  tl.out$PERIOD_2_DATE <- NA
  tl.out$PERIOD_2_PATIENT_VISIT_COUNT <- NA
  tl.out$PERIOD_2_DATA_ENTRY_TIMELINESS <- NA
  tl.out$COMPLIANCE_3_MONTHS <- NA
  tl.out$PATIENT_VISIT_COUNT_3_MONTHS <- NA
  tl.out$OS_ISSUE_COUNT_EXPECTED <- NA
  tl.out$MEDIAN_DAYS <- Model.data$DET_MEDIAN_DAYS
  tl.out$NUM_VISITS <- Model.data$NUM_VISITS
  tl.out$NUM_ACTIVE_SUBJECTS <- Model.data$NUM_ACTIVE_PAT
 
  # Date is the 1st of the last month data was available
  r <- Sys.Date()
  e <- as.character(as.Date(r,"%Y-%m-%d")-45)
  e <- paste0(substr(e,1,8),"01")
  tl.out$DET_DATE <- as.Date(e,"%Y-%m-%d")
  Model.data$DET_DATE <- as.Date(e,"%Y-%m-%d")
  
  # Select variables for output to spotfire 
  cols.needed <- c("HM_WRK_TL_OUT_ID", "HM_SITE_ID", "HM_STUDY_ID", "PERIOD_1_DATE", "PERIOD_1_PATIENT_VISIT_COUNT", "PERIOD_1_DATA_ENTRY_TIMELINESS", "PERIOD_2_DATE", "PERIOD_2_PATIENT_VISIT_COUNT", "PERIOD_2_DATA_ENTRY_TIMELINESS", "TIMELINESS_PERCENTILE", "COMPLIANCE_3_MONTHS", "PATIENT_VISIT_COUNT_3_MONTHS", "OS_ISSUE_COUNT_EXPECTED",  "MEDIAN_DAYS", "NUM_VISITS", "NUM_ACTIVE_SUBJECTS","DET_DATE")
  tl.out <- tl.out[, cols.needed]
  
  return(list(tl.out=tl.out, Model.data.TL=Model.data))

}

tl <- run_timeliness_model(Model.data.TL,Model.data.TL.tfm)
tl.out <- tl$tl.out
Model.data.TL <- tl$Model.data.TL

