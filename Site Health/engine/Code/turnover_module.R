# --------------
# Title: turnover_module.R
# --------------
# Author: Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Oct 27 2016
# --------------
# Description: This file contains code used to run the turnover module to 
# predict the amount of monitor and sub-investigator turnover in the past 1 year
# from the run date.
# --------------
# Author:
# Date:
# Modification:
# --------------

library(quantregForest)

write_log_sub_header("turnover_module.R", "Turnover Module", log_con)

run_turnover_model <- function(Model.data, Staff.turnover.data){
  
  # load model object
  to.model <- readRDS(file.path(MODEL.DIR, "to_fitted_model.rds"))
  
  # The response for the model
  #response.name <- 'PCT_MONITORS_AND_SUBI_LEFT_1YR'
  
#################################################################################################
##### New Addition 4.0 ##############################################################################
#################################################################################################
#Predictors in the new turnover module
  c <- rownames(to.model$importance)
  c <- union(c,c("PCT_MONITORS_AND_SUBI_LEFT_1YR","HM_SITE_ID"))
#Using some information from the safety module
  t <- Model.data.SA[,c("HM_SITE_ID","AES_IN_STUDY","MONITOR_TO_PATIENT_RATIO")]
#extracting the dataset relevant for the new predictors
  Model.data$MONITOR_SUBI_1YR <- Model.data$STAFF_COUNT_MONITORS_1YR + Model.data$STAFF_COUNT_SUBI_1YR
#Selecting sites that have MONITOR_SUBI_1YR >0
  ts <- Model.data[Model.data$MONITOR_SUBI_1YR >0,]
#Selecting sites that have had a patient visit in the past 12 months
  ts <- Model.data[Model.data$PAT_COUNT_PAST_1YR >0,]

  ts$PATIENT_MONITOR_SUBI_RATIO_1yr <- ts$PAT_COUNT_PAST_1YR/ts$MONITOR_SUBI_1YR
  ts <- merge(ts,t)
  ts <- ts[ts$SITE_STATUS %in% "ONGOING",c]
#Ensuring no missing values are present
  ts <- ts[complete.cases(ts),]

#################################################################################################
##### System Test for STUDY_THERAPEUTIC_AREA3 ##############################################################################
#################################################################################################
#x = table(as.vector(ts$STUDY_THERAPEUTIC_AREA3)); x = data.frame(x);
#write.table(x,file="STUDY_THERAPEUTIC_AREA3",sep='\t',quote=F,row.names=F);
#################################################################################################

  
  to.pred <- c("DAYS_SINCE_SITE_FSFV",
              "STAFF_COUNT",
              "PCT_NEW_STAFF_PREV_6MON",
              "STUDY_THERAPEUTIC_AREA3",
              "TOT_PATIENT_MONTHS_IN_STUDY_ALL_SITES",
              "DAYS_SINCE_STUDY_FSFV",
              "AES_IN_STUDY",
              "REGION",
              "PCT_ACTIVE_SUBJECTS")
  x_test <- ts[,to.pred]
  y_test <- ts$PCT_MONITORS_AND_SUBI_LEFT_1YR
# Make Predictions
  pred <- predict(to.model, newdata = x_test, what=0.01 * (1:100))

#Find Percentile of the observed value
  k <- c()
  for(i in 1:nrow(pred))
  {
    x <- as.vector(pred[i,])
    if(y_test[i] ==0)
    {
     k[i] <- min(which(abs(x-y_test[i])==min(abs(x-y_test[i]))));
    } else {  k[i] <- max(which(abs(x-y_test[i])==min(abs(x-y_test[i])))); }
  }
  q <- data.frame(HM_SITE_ID = ts$HM_SITE_ID,
                 RT_PERCENTILE = k,
                 #PATIENT_MONITOR_SUBI_RATIO_1yr = ts$PATIENT_MONITOR_SUBI_RATIO_1yr,
                 AES_IN_STUDY = ts$AES_IN_STUDY
                 #MONITOR_TO_PATIENT_RATIO = ts$MONITOR_TO_PATIENT_RATIO
                 )
  q$RT_PERCENTILE <- 0.01 *q$RT_PERCENTILE
  Model.data <- merge(Model.data,q)
  
  # Make predictions and get percentiles by setting Beta distribution parameters
  # mean = (alpha/(alpha + beta)) and phi = (alpha + beta) for the Beta distribution
  #phi.pred <- exp(to.model$family$getTheta())
  
  # Use model to score sites
  #mu.pred <- get_model_predictions(Model.data, to.model, "Turnover", log_con)

  # Set shape parameters for the distribution
  # Shape1 = alpha, and shape2 = beta, from the Beta distribution
  #shape1.pred <- mu.pred * phi.pred
  #shape2.pred <- (1 - mu.pred) * phi.pred
  
  # Set up data frame to with just HM_SITE_ID and the ACTUAL turnover values
  #preds <- as.data.frame(cbind(HM_SITE_ID = Model.data$HM_SITE_ID,
  #                             Model.data[, response.name]))
  #colnames(preds)[2] <- response.name
  
  # Calculate the turnover percentiles (a.k.a p-values)
  #preds$RT_PERCENTILE <- pbeta(q = preds[, response.name], 
  #                             shape1 = shape1.pred, 
  #                             shape2 = shape2.pred)
 
#IOP
#preds$Predicted=mu.pred;

 
  # Create null column for expected issue count 
  # Note: relic of original turnover model that predicted issue count
  Model.data$OS_ISSUE_COUNT_EXPECTED <- NA
  
  # Merge model data with predictions to add turnover percentile
  #to.out <- merge(Model.data, preds, by = "HM_SITE_ID")
  to.out <- Model.data
  
  # Create null column for Spotfire table
  to.out$HM_WRK_RT_OUT_ID <- NA
  
  # Select variables for output to spotfire 
  cols.needed <- c("HM_WRK_RT_OUT_ID", "HM_STUDY_ID", "HM_SITE_ID", "DATE", 
                   "PERIOD_START_1YR", "PAT_COUNT_PAST_1YR",
                   "STAFF_COUNT_SUBI_1YR", "NUM_SUBI_LEFT_1YR", "PCT_SUBI_LEFT_1YR", 
                   "STAFF_COUNT_MONITORS_1YR", "NUM_MONITORS_LEFT_1YR", "PCT_MONITORS_LEFT_1YR",
                   "OS_ISSUE_COUNT_EXPECTED", "RT_PERCENTILE")


#IOP
#write.table(to.out,file="/hpc/grid/predinfo/mathus07/site_health/analysis/Model.data.TO",sep='\t',quote=F,row.names=F);

  
  to.out <- to.out[, cols.needed]
  
  # Rename columns to match spotfire table
  to.out <- rename(to.out, c("DATE" = "RT_END_DATE",
                             "PAT_COUNT_PAST_1YR" = "RT_PATIENT_COUNT",
                             "STAFF_COUNT_SUBI_1YR" = "SI_COUNT_1YR",
                             "NUM_SUBI_LEFT_1YR" = "SI_TURNOVER_1YR",
                             "PCT_SUBI_LEFT_1YR" = "SI_TURNOVER_PERCENT",
                             "STAFF_COUNT_MONITORS_1YR" = "MONITOR_COUNT_1YR",
                             "NUM_MONITORS_LEFT_1YR" = "MONITOR_TURNOVER_1YR",
                             "PCT_MONITORS_LEFT_1YR" = "MONITOR_TURNOVER_PERCENT"))
  
  # If monthly run, create historical staff turnover dataset for Spotfire dashboard
  if (MONTHLY.RUN){
    to.out.hist <- get_hist_staff_data(Staff.turnover.data, to.out)
  } else {
    to.out.hist <- NULL
  }
  
  # Return named list to output both datatables
  return(list(WRK_RT_OUT=to.out, WRK_RT_OUT_HIST=to.out.hist))
}

to.output <- run_turnover_model(Model.data.TO, Staff.turnover.data)
to.out <- to.output$WRK_RT_OUT
to.out.hist <- to.output$WRK_RT_OUT_HIST
####################################################################################################
######################### New modification 4.0 ##################################################
# REMOVE STUDY_THERAPEUTIC_AREA3
Model.data.TO <- Model.data.TO[,!names(Model.data.TO)%in% "STUDY_THERAPEUTIC_AREA3"]
######## End of modification ###########################

