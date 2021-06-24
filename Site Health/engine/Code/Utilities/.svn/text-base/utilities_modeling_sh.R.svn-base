# --------------
# Title: utilities_data_processing_1.R
# --------------
# Author: Bambo Sosina (bsosina@deloitte.com),
#         Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Nov 23 2016
# --------------
# Description: This script contains custom utility functions used to perform
# overall issue count modeling and create the overall site health metric
# as part of the site health programs.
# --------------
# Author:
# Date:
# Modification:
# --------------

#####################################################################################################
#                                                                                                   #
#                                     The Modeling functions                                        #
#                   Functions for building models based on the Training dataset                     #
#                                                                                                   #
##################################################################################################### 

#####################################################################################################
#                                                                                                   #
#                       The function for generating the issue count output                          #
#                                                                                                   #
#####################################################################################################
get_sh_output <- function(Model.data, Train.data, sh.model, fmla){
  
  # Trim the dataset if necessary 
  # (find new levels not present in training dataset and drop with warning)
  Model.data.Complete <- data.frame(model.frame(fmla, Model.data))
  Model.data.Trimmed <- trim_fun(old.data=Train.data, 
                                   new.data=Model.data.Complete, log_con)$trim.data
  
  # The predictions from the training dataset
  SH.train.pred <- sh.model$fitted.values
  
  # Use model to score sites
  cat("Scoring sites with predicted issue count model...\n", file=log_con)
  predicted <- try(predict(sh.model, newdata=Model.data.Trimmed, type='response'), 
                   silent=TRUE)
  if (inherits(predicted, "try-error")) {
    stop(paste0("ERROR when scoring issue count model:\n", 
                as.character(predicted), "\n"))
    
  } else {
    cat(paste("Issue count model successfully scored", sum(!is.na(predicted)), 
              "out of", nrow(Model.data.Trimmed), "sites\n"), file=log_con)
  }
  
  SH.New.pred <- predicted
  
  # The empirical cummalative distribution function for the training predictions
  SH.f <- ecdf(SH.train.pred)
  
  # The percentiles for the new issue counts based on the estimated distribution 
  # for the training predictions
  SH.New.pctl <- SH.f(SH.New.pred)
  
  # The output
  SiteHealth.output <- data.frame(HM_SITE_ID=Model.data.Trimmed$HM_SITE_ID,
                                  DATE=Model.data.Trimmed$DATE, 
                                  ISSUE_COUNT_EXPECTED=SH.New.pred,
                                  SH.New.pctl=SH.New.pctl)
  
  return(SiteHealth.output)
}


run_overall_sh_model <- function(SH.output, PD.output, SA.output, TL.output, TO.output) {
  
  # Supply the module outputs to be used in the OSH metric calculation
  Module.Outputs <- list(SH.output = SH.output, PD.output = PD.output,
                         SA.output = SA.output, TO.output = TO.output,
                         TL.output = TL.output)
  
  # Generate SH metric
  # Use sub-module weights from global parameter list MODULE.WEIGHTS
  OSH.metric.data <- get_sh_metric(Module.Outputs, MODULE.WEIGHTS)
  
  return(OSH.metric.data)
}


#####################################################################################################
#                                                                                                   #
#                           The function for generating the SH metric                               #
#                                                                                                   #
#####################################################################################################

get_sh_metric <- function(module.outputs, module.weights){
  
  SH.output <- module.outputs$SH.output
  PD.output <- module.outputs$PD.output
  SA.output <- module.outputs$SA.output
  TO.output <- module.outputs$TO.output
  TL.output <- module.outputs$TL.output
  
  weight.pd <- module.weights$weight.pd
  weight.sa <- module.weights$weight.sa
  weight.tl <- module.weights$weight.tl
  weight.to <- module.weights$weight.to
  
  # The HM_SITE_IDs for which scores will be generated
  common.ids <- sort(unique(SH.output$HM_SITE_ID))
  
  # Merge individual model outputs with SH (issue count) output to ensure that
  # all sites that will be scored (those in SH.output) have a row in each of the
  # individual modules.
  PD.output.merge <- merge(PD.output, SH.output, by = "HM_SITE_ID", all.y = TRUE)
  SA.output.merge <- merge(SA.output, SH.output, by = "HM_SITE_ID", all.y = TRUE)
  TL.output.merge <- merge(TL.output, SH.output, by = "HM_SITE_ID", all.y = TRUE)
  TO.output.merge <- merge(TO.output, SH.output, by = "HM_SITE_ID", all.y = TRUE)
  
  #######################################################################
  # Calculating an initial metric from the SH output
  #######################################################################
  # Reversing so that lower values are bad
  max.weight <- 1; max.metric <- 10
  SH.uniform <- (1 - SH.output$SH.New.pctl)
  
  # SH.Uniform is uniform and ranges from 0 to max.metric. We however want a 
  # normal-like shape for site monitoring efficiency. To do this, we use the 
  # Von Mises (VM) distribution, which is also known as the circular normal 
  # distribution. This distribution nis particularly desirable since it is 
  # already bounded (from -pi to pi) just like our Uniform metric is, and it 
  # has the normal-shape we want, with the shape controlled by a single 
  # parameter kappa.
  
  # First we convert the uniform value to a VM-quantile and then shift and 
  # rescale by pi and max.metric/2pi respectively in order to get values ranging 
  # from 0 to max.metric. Note that the conversion to VM-quantiles is based on 
  # the Probability Integral Transform (PIT) theory which says any 
  # distribution's quantiles can be obtained from Uniform quantiles.
  
  # The measure of concentration 
  # (analogous to inverse variance in normal distributions)
  kap <- 2
  
  # The conversion to VM-quantiles centered at 0
  QQ <- as.numeric(qvonmises(SH.uniform, mu=circular(0), kappa=kap))
  
  # Shifting and rescaling to the interval (0, max.metric)
  SH.initial <- (max.metric/(2*pi)) * (pi + QQ)
  
  # Save as dataframe
  SH.scaled <- data.frame(HM_SITE_ID = SH.output$HM_SITE_ID, 
                          total.SH.scaled = SH.initial)
  
  
  #######################################################################
  # Impute Missing Values for Sub-modules
  #
  # If PD, SA, TL, or TO data for a site is not available, impute with a 
  # percentile of 0.5. This imputation essentially has no effect since only 
  # sites with percentiles above 95% affect the final metric.
  #######################################################################
  
  #######################################################################
  # PD Module
  # For the PD module, more work is needed
  # Note that higher values are bad here. No need to flip the percentiles to 
  # stay consistent with SA percentiles, but we will multiply by -1 when 
  # combining with the others just like for SA
  #######################################################################
  # The cummulative probabilities based on each observed score (percentiles)
  PD.output$prob <- PD.output$PD_PERCENTILE_CURRENT
  
  # PD deviations are bad if too high or too low, i.e., if p*(1 - p) is too low. 
  # Since p(1-p) ranges from 0 to 1/4, we rescale and flag sites if 1 - 4p(1-p) 
  # is too high to remain consistent with the SA module.
  PD.output$pval <- 1 - 4*PD.output$prob*(1 - PD.output$prob)
  
  # set up dataframe
  PD.scaled <- data.frame(HM_SITE_ID = PD.output.merge$HM_SITE_ID)
  
  # substitute 0.5 for NA percentiles
  PD.scaled$total.PD.scaled <- sapply(PD.output.merge$PD_PERCENTILE_CURRENT, 
                                      sub_mid_percentile)
  
  # Filter to only sites that have issue count score
  PD.scaled <- PD.scaled[PD.scaled$HM_SITE_ID %in% common.ids, ]
  
  
  #######################################################################
  # Safety module
  # Note that higher values are bad here. No need to flip the percentiles, but 
  # will multiply by -1 when combining with the others
  #######################################################################
  # Set up dataframe
  SA.scaled <- data.frame(HM_SITE_ID = SA.output.merge$HM_SITE_ID)
  
  # Substitute 0.5 for NA percentiles
  # Use 1-Safety Percentile to capture potential underreporting of AEs / SAEs
  SA.scaled$total.SA.scaled <- sapply(1-SA.output.merge$SAFETY_PERCENTILE, 
                                      sub_mid_percentile)
  
  # Filter to only sites that will be scored
  SA.scaled <- SA.scaled[SA.scaled$HM_SITE_ID %in% common.ids, ]
  
  
  #######################################################################
  # Timeliness module
  # Note that lower values are bad here. We will need to flip the percentiles, 
  # to stay consistent with SA percentiles, and also multiply by -1 when 
  # combining with the others
  #######################################################################
  # set up dataframe
  TL.scaled <- data.frame(HM_SITE_ID = TL.output.merge$HM_SITE_ID)
  
  # substitute 0.5 for NA percentiles
  TL.scaled$total.TL.scaled <- sapply(TL.output.merge$TIMELINESS_PERCENTILE, 
                                      sub_mid_percentile)
  
  # Filter to only sites that have issue count score
  TL.scaled <- TL.scaled[TL.scaled$HM_SITE_ID %in% common.ids, ]
  
  
  #######################################################################
  # Turnover module
  # Note that higher values are bad here. No need to flip the percentiles to 
  # stay consistent with SA percentiles, but we will multiply by -1 when 
  # combining with the others just like for SA
  #######################################################################
  # set up dataframe
  TO.scaled <- data.frame(HM_SITE_ID = TO.output.merge$HM_SITE_ID)
  
  # substitute 0.5 for NA percentiles
  TO.scaled$total.TO.scaled <- sapply(TO.output.merge$RT_PERCENTILE, 
                                      sub_mid_percentile)
  
  # Filter to only sites that have issue count score
  TO.scaled <- TO.scaled[TO.scaled$HM_SITE_ID %in% common.ids, ]
  
  
  #######################################################################
  # Creating the final SH metric
  #######################################################################
  
  # Merge outputs from overall SH and the individual sub-modules
  all.modules.scaled.list <- list(SH.scaled, PD.scaled, SA.scaled, TO.scaled, TL.scaled)
  merge_fun <- function(x, y){merge(x, y, by='HM_SITE_ID')}
  
  all.modules.scaled <- Reduce(merge_fun, all.modules.scaled.list)
  
  # Now penalize the original SH metric by the module percentiles. The 
  # multiplicative constant of 20 = (1/0.05) is included to ensure a range of 0 
  # to 1 for each module penalty, prior to weighting. The exception here is the 
  # PD module. This is because the two-tailed conversion of the percentiles into 
  # pscores leads to a censoring value of 0.0975 instead of 0.05.
  
  PD.penalty <- weight.pd * pmax(0.025*0.975 - all.modules.scaled$total.PD.scaled, 0)/(0.025*0.975)
  SA.penalty <- weight.sa * pmax(all.modules.scaled$total.SA.scaled - 0.95, 0)/(0.05)
  TL.penalty <- weight.tl * pmax(0.05 - all.modules.scaled$total.TL.scaled, 0)/(0.05)
  TO.penalty <- weight.to * pmax(all.modules.scaled$total.TO.scaled - 0.95, 0)/(0.05)
  
  all.modules.scaled$SH.score.raw <- all.modules.scaled$total.SH.scaled - 
    (PD.penalty + SA.penalty + TO.penalty + TL.penalty)
  
  # Cap metric below at 0
  all.modules.scaled$ABSOLUTE_SITE_HEALTH_SCORE <- pmax(all.modules.scaled$SH.score.raw, 0)
  
  # Bring in variables from PD and TO modules for use in creaeting
  # SITE_HEALTH_INDICATOR_B
  pd.tmp <- pd.out[,c("HM_SITE_ID", "DELTA_CURRENT", "PD_COUNT_ACTUAL_T1", "PD_COUNT_EXPECTED_T1")]
  pd.tmp$PD_DELTA_LAG1 <- pd.tmp$PD_COUNT_ACTUAL_T1 - pd.tmp$PD_COUNT_EXPECTED_T1
  to.tmp <- to.out[,c("HM_SITE_ID", "MONITOR_TURNOVER_PERCENT", "SI_TURNOVER_PERCENT")]
  all.modules.scaled <- merge(all.modules.scaled, pd.tmp,
                              by="HM_SITE_ID", all.x=TRUE)
  all.modules.scaled <- merge(all.modules.scaled, to.tmp,
                              by="HM_SITE_ID", all.x=TRUE)
  
  # Create variables for Spotfire
  all.modules.scaled$HM_WRK_GL_OUT_OVERVIEW_ID <- NA
  all.modules.scaled$SITE_HEALTH_INDICATOR <- ifelse(all.modules.scaled$ABSOLUTE_SITE_HEALTH_SCORE>=5, 1, 0)
  all.modules.scaled$SITE_HEALTH_INDICATOR_B <- ifelse(
                        (is.na(all.modules.scaled$DELTA_CURRENT)
                         | (all.modules.scaled$DELTA_CURRENT
                              >= SITE.HEALTH.IND.THRESHOLDS$MIN.PD.DELTA
                            & all.modules.scaled$DELTA_CURRENT
                               <= SITE.HEALTH.IND.THRESHOLDS$MAX.PD.DELTA))
                      & (is.na(all.modules.scaled$MONITOR_TURNOVER_PERCENT)
                         | all.modules.scaled$MONITOR_TURNOVER_PERCENT
                             <= SITE.HEALTH.IND.THRESHOLDS$MAX.MONITOR.TURNOVER)
                      & (is.na(all.modules.scaled$SI_TURNOVER_PERCENT)
                         | all.modules.scaled$SI_TURNOVER_PERCENT
                             <= SITE.HEALTH.IND.THRESHOLDS$MAX.SUBI.TURNOVER),
                      1, 0)
  
  all.modules.scaled <- merge(all.modules.scaled, 
                              Model.data.SH[,c('HM_SITE_ID','HM_STUDY_ID')])
  
  all.modules.scaled <- merge(all.modules.scaled, 
                              SH.output[, c('HM_SITE_ID', 'ISSUE_COUNT_EXPECTED')])
  
  # Output final metric
  return(all.modules.scaled[c('HM_WRK_GL_OUT_OVERVIEW_ID', 
                              'HM_SITE_ID',
                              'HM_STUDY_ID',
                              'ABSOLUTE_SITE_HEALTH_SCORE', 
                              'SITE_HEALTH_INDICATOR', 
                              'SITE_HEALTH_INDICATOR_B',
                              'ISSUE_COUNT_EXPECTED')])
}


# Function to substitute NA values with 0.5
# Used for sub-module percentiles as part of generating overal SH metric
sub_mid_percentile <- function(x){
  ifelse(is.na(x), 0.5, x) 
}

############################################################################################
# Function for trimming out observations with new levels in testing/validation datasets.
# Name: 
#       trim_fun
# Description:  
#       This function finds and drops observations with previously unseen factor levels, with a warning message.
#       If left in, the new levels will cause the predictions to stop with errors
# Input: 
#       old.data                (data frame)      : The training dataset, preprocessed to remove missing values
#       new.data                (data frame)      : The testing/validation dataset, preprocessed to remove 
#                                                   missing values. This is what we want to trim
# Output:
#                               (list)            : a list containing the trimmed dataset, as well as row 
#                                                   indices of trimmed observations
####
trim_fun <- function(old.data, new.data, log_con){
  # Identify the factors
  factor.columns <- sapply(new.data, class)=='factor'
  factor.columns.old <- as.numeric(sapply(names(new.data)[factor.columns], function(x){
    which(names(old.data)== x)
  }))
  
  # Identify new levels
  new.levels <- lapply(1:sum(factor.columns), function(ii){
    # Count table of the factor in both the old and new datasets
    tab.old <- table(old.data[, factor.columns.old[ii]])
    tab.new <- table(new.data[, which(factor.columns)[ii]])
    
    # Names of those levels with counts greater than zero (the present levels)
    non.zero.old <- names(tab.old)[tab.old > 0]
    non.zero.new <- names(tab.new)[tab.new > 0]
    
    # Which non-zero-count levels in tab.new are not in non-zero-count tab.old levels
    res <- non.zero.new[!non.zero.new %in% non.zero.old]
    return(res)
  })
  
  # Identify the observations (those corresponding to new levels) to be dropped from the new data
  idx.drop <- lapply(1:sum(factor.columns), function(ii){
    which(as.character(new.data[, which(factor.columns)[ii]]) %in% new.levels[[ii]])
  })
  
  # The unique list of row indices to be dropped
  all.drop <- unique(unlist(idx.drop))
  
  # Which factors are affected by the new levels?
  non.zero.idx <- which(sapply(idx.drop, length) > 0)
  
  # Warning message if any obswervation is to be dropped
  if(length(all.drop)>0){
    cat('WARNING: New factor levels for', paste(names(new.data)[factor.columns][non.zero.idx], 
                                       collapse=' and '), 
        'have been identified in the new dataset.\n', length(all.drop), 
        'observations will be dropped and not scored, corresponding to these new levels:\n', 
        paste(unlist(new.levels), collapse=' and '), 'not found in the previous dataset.\n', 
        'Proceeding with analysis...\n\n', file=log_con)
    
    trim.res <- new.data[-all.drop, ]
  }else{
    trim.res <- new.data
  }
  
  # Return trimmed dataset along with row indices for identifying dropped observations
  return(list(trim.data=trim.res, idx=all.drop))
}


# Function to make predictions using the model data and model object and write
# descriptive messages to the log during the process
# 
# Arguments:
#  Model.data: data frame of modeling dataset
#  model.obj: saved fitted model object
#  model.name: text string indicating the model name
#  log_con: An open file connection to a ".txt" log file to which text can be 
#            appended
#
# Returns: model predictions for rows in Model.data
get_model_predictions <- function(Model.data, model.obj, model.name, log_con){
  # Wite message to log
  cat("Scoring sites with predicted", model.name, "model...\n", file=log_con)
  
  # Make predictions
  predicted <- try(predict(model.obj, newdata=Model.data, type='response'), 
                   silent=TRUE)
  
  # Stop if error occurs while making predictions
  if (inherits(predicted, "try-error")) {
    stop(paste("ERROR when scoring",  model.name, "model:\n", 
                as.character(predicted), "\n"))
  } else {
    # Write success message if no errors
    cat(model.name, "model successfully scored", sum(!is.na(predicted)), 
              "out of", nrow(Model.data), "sites\n", file=log_con)
    
    # Return predictions
    return(predicted)
  }
}
