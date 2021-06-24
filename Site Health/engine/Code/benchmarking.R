# --------------
# Title: benchmarking.R
# --------------
# Author: Bambo Sosina (bsosina@deloitte.com),
#         Kevin Coltin (kcoltin@deloitte.com)
# Date: Oct 27 2016
# --------------
# Description: Benchmarks the accuracy of the overall Site Health model against
# the accuracy of the model when it was originally constructed, in order to
# measure the model's robustness over time.
# --------------
# Author:
# Date:
# Modification:
# --------------

write_log_sub_header("benchmarking_module.R", "Benchmarking Module", log_con)

# This is the main function for running benchmarking of the Site Health module.
#
# Input:
#  -Results from previous runs of the Overall Site Health module which occurred
#    after the more recent of BENCHMARK.START.DATE and [RUN.DATE minus
#    BENCHMARK.LOOKBACK.DAYS], and before RUN.DATE. These are retrieved from
#    the timestamped module output files saved in the "Module_output"
#    directory.
#  -Results of actual issue reports, from the INPUT$Issues dataframe
#  -Predictive model object from original model fitting process, saved in
#    Model_files/sh_fitted_model.rds
#
# The output is a string displaying the accuracy of the original model and the
# recent model predictions, measured along multiple metrics.
run_benchmarking <- function() {
  # Get a list of all outputs from previous overall SH module runs
  sh.out.files <- list.files(MONTHLY.RUN.OUTDIR, "Module_Output_SH_.*",
                             recursive=TRUE, full.names=TRUE)
  cat(length(sh.out.files), "output files found from previous Monthly Runs of",
      "Overall Site Health module\n", file=log_con)
  # Get the timestamps of each of these previous model runs
  # ("sub" uses a regular expression to extract dates and times from filenames)
  timestamps <- as.POSIXct(
        sub("^.*\\/Module_Output_SH_(....)\\.(..?)\\.(..?)_(..?)h(..?)m\\.csv$",
            "\\1-\\2-\\3 \\4:\\5", sh.out.files))
  # Exclude any files from runs that took place before the starting point when
  # the model was originally fit, or that took place before the "lookback
  # period" (e.g. we might only want to include results from the previous 6
  # months in order to give an indication of how accurate the model has been
  # recently).
  MIN.DATE <- max(BENCHMARK.START.DATE, RUN.DATE - BENCHMARK.LOOKBACK.DAYS)
  if (RUN.DATE <= BENCHMARK.START.DATE) {
    cat(paste0("WARNING: Unable to run benchmarking because the run date (",
               format(RUN.DATE), ") is prior to the benchmarking start date (", 
               BENCHMARK.START.DATE, ") defined in parameters.R\n"),
        file=log_con)
    return("")
  }
  sh.out.files <- sh.out.files[as.Date(timestamps) >= MIN.DATE
                               & as.Date(timestamps) <= RUN.DATE]
  cat(length(sh.out.files), "of these previous Monthly Runs of the",
      "Overall Site Health module were run during the valid time period for",
      "benchmarking, between", format(MIN.DATE), "and", format(RUN.DATE), "\n",
      file=log_con)
  if (length(sh.out.files) == 0) {
    cat("WARNING: Unable to run benchmarking because no SH Module output",
        "files were found in", MONTHLY.RUN.OUTDIR, "from on or after",
        format(MIN.DATE), "and before", format(RUN.DATE), "\n", file=log_con)
    return("")
  }

  # Read in the site IDs, dates, and predicted issue counts from these files,
  # and concatenate them
  Predictions <- data.frame(HM_SITE_ID=integer(),
                            ISSUE_COUNT_EXPECTED=numeric(),
                            ABSOLUTE_SITE_HEALTH_SCORE=numeric(),
                            TIMESTAMP=as.character(),
                            stringsAsFactors=FALSE)
  KEEP <- c("HM_SITE_ID", "ISSUE_COUNT_EXPECTED", "ABSOLUTE_SITE_HEALTH_SCORE")
  for (i in 1:length(sh.out.files)) {
    Data.in <- read.csv(sh.out.files[i])[KEEP]
    Data.in$TIMESTAMP <- timestamps[i]
    Predictions <- rbind(Predictions, Data.in)
  }

  # Next, look at the counts of issues found in all Oversight Reports that have
  # happened since the starting point when the model was originally fit
  Issues <- INPUT$Issues
  Issues <- Issues[Issues$REPORT_START_DATE >= MIN.DATE
                   & Issues$REPORT_START_DATE <= RUN.DATE,]
  # Drop issues not corresponding to a site that's been scored
  Issues <- Issues[Issues$HM_SITE_ID %in% Predictions$HM_SITE_ID,]
  # If no relevant reports are found, exit with an error - need to exit early
  # here to avoid errors when trying to aggregate a zero-row Issues dataframe
  if (nrow(Issues) == 0) {
    cat("WARNING: Unable to run benchmarking because no oversight reports were",
        "found from within the benchmarking time range from", format(MIN.DATE),
        "to", format(RUN.DATE), "for which a predicted site health score",
        "exists\n", file=log_con)
    return("")
  }
  
  # Aggregate total issues by report
  Reports <-aggregate(data.frame(ISSUE_COUNT=Issues$RISK_CATEGORY_COUNT.capped),
                      by=Issues[c("HM_SITE_ID", "REPORT_START_DATE")],
                      FUN=sum)

  # For each oversight report, pull in the most recent model predictions for
  # the given site that were made prior to the date of the oversight report
  f <- function(site.id, report.date) { # Helper func. to get most recent preds
    ix <- Predictions$HM_SITE_ID == site.id &
            as.Date(Predictions$TIMESTAMP) < report.date
    if (any(ix)) {
      return(min(Predictions[ix,"TIMESTAMP"]))
    } else {
      return(as.POSIXct(NA))
    }
  }
  Reports$PREDICTION_TIMESTAMP <- mapply(f, Reports$HM_SITE_ID,
                                         Reports$REPORT_START_DATE)
  Reports$PREDICTION_TIMESTAMP <- as.POSIXct(Reports$PREDICTION_TIMESTAMP,
                                             origin=R.DATE.ORIGIN)
  Reports <- merge(Reports, Predictions,
                   by.x=c("HM_SITE_ID", "PREDICTION_TIMESTAMP"),
                   by.y=c("HM_SITE_ID", "TIMESTAMP"))
  cat(nrow(Reports), "Oversight Reports were found within the benchmarking",
      "timeframe where a Site Health Metric had been estimated for the site:",
      "these reports can be used for benchmarking the module's predictive",
      "accuracy.\n", file=log_con)
  # If no relevant reports are found, exit with an error
  if (nrow(Reports) == 0) {
    cat("WARNING: Unable to run benchmarking because no oversight reports were",
        "found from within the benchmarking time range from", format(MIN.DATE),
        "to", format(RUN.DATE), "for which a usable predicted site health",
        "metric exists. (Note: in order to be used for benchmarking, the",
        "prediction must come from a Site Health module run which occurred",
        "prior to the report start date)\n", file=log_con)
    return("")
  }


  # Load the original predictive model for issue counts, for comparison
  sh.model <- readRDS(file.path(MODEL.DIR, "sh_fitted_model.rds"))
  # Calculate accuracy based on various metrics from the original model build
  accuracy.orig <- benchmark_stats(as.numeric(sh.model$y),
                                   sh.model$fitted.values,
                                   as.numeric(sh.model$y),
                                   sh.model$fitted.values)
  # Using the actual and predicted results from each oversight report, calculate
  # the accuracy based on various metrics
  accuracy.current <- benchmark_stats(Reports$ISSUE_COUNT,
                                      Reports$ISSUE_COUNT_EXPECTED,
                                      as.numeric(sh.model$y),
                                      sh.model$fitted.values,
                                      Reports$ABSOLUTE_SITE_HEALTH_SCORE)

  return(paste0("----BENCHMARKING RESULTS ", TIMESTAMP, "----\n\n",
                "Accuracy based on predicted vs. actual issue counts from ",
                "oversight reports held between ", MIN.DATE, " and ", RUN.DATE,
                ":\n\n", accuracy.current, "\n\n",
                "Accuracy from when the current version of the Site Health ",
                "model was built:\n\n", accuracy.orig))
}


# Function for calculating statistics of modela accuracy. Calculates the
# following measures:
#
# RMSE (root mean squared error)
# Percent of variance explained by the model
# Correlation between the observed and predicted response values
# Correlation of observed and predicted percentiles
# Standard seven-number summary of the calculated Site Health metric (min, max,
#   mean, median, etc.)
#
# Args:
#  y.actual: Actual observed issue counts
#  y.fitted: Predicted issue counts
#  y.actual.orig, y.fitted.orig: Observed and predicted issue counts from the
#    original model build; these are needed for fixing constant decile
#    boundaries
#  sh.metric: Overall Site Health metric, on zero to ten scale
#
# Returns: A string displaying the results of these metrics
benchmark_stats <- function(y.actual, y.fitted, y.actual.orig, y.fitted.orig,
                            sh.metric=NULL) {
  #### Number of observations
  nobs <- length(y.fitted)

  #### The root mean squared error
  rmse <- sqrt(mean((y.actual - y.fitted)^2))

  #### The percentage of variance explained
  var.explained <- 100*(1 - mean((y.actual - y.fitted)^2)/
                          mean((y.actual - mean(y.actual))^2))

  #### The correlation of observed and predicted
  correlation <- cor(y.actual, y.fitted, use="pairwise.complete.obs")

  #### Calculate correlation based on ranks
  rank.correlation <- cor(rank(y.actual), rank(y.fitted),
                          use="pairwise.complete.obs")


  #### Format results from all metrics into text for output
  if (nobs < MIN.BENCHMARK.OBS) {
    small.n.warning <- paste("WARNING: Fewer than", MIN.BENCHMARK.OBS,
                             "observations found; please use caution when",
                             "evaluating accuracy based on small sample",
                             "size\n\n")
  } else {
    small.n.warning <- ""
  }
  results <- sprintf(paste0("Number of observations (completed oversight ",
                            "reports) benchmarked against:\n",
                            "\t%d\n",
                            small.n.warning,
                            "Root Mean Squared Error (lower is better):\n",
                            "\t%0.2f\n\n",
                            "Percent variance explained (higher is better):\n",
                            "\t%0.1f\n\n",
                            "Correlation of actual and predicted issue counts ",
                            "(higher is better):\n",
                            "\t%0.1f\n\n",
                            "Correlation of percentiled actual and predicted ",
                            "issue counts (higher is better):\n",
                            "\t%0.1f\n\n"),
                     nobs, rmse, var.explained, 100. * correlation,
                     100. * rank.correlation)
  if (!is.null(sh.metric)) {
    results <- paste0(results, "Distribution of Overall Site Health Metric:\n",
                      paste(capture.output(summary(sh.metric)), collapse="\n"),
                      "\n\n")
  }

  return(results)
}



PASS.BENCHMARKING <- TRUE # Set global success flag

benchmark.results.text <- try(run_benchmarking(), silent=TRUE)
# If benchmarking fails due to an R error, then we set the flag to indicate
# failure, update with a more informative error message to be
# send to the benchmarking output file, and re-raise the error to be handled by
# main.R
if (is_error(benchmark.results.text)) {
  err <- benchmark.results.text
  benchmark.resuts.text <- paste("Unable to run benchmarking due to errors.",
                                 "For details see log file",
                                 summary(log_con)$description)
  PASS.BENCHMARKING <- FALSE
  stop(err) # re-raise error
} else if (nchar(benchmark.results.text) == 0) {
  # If benchmarking fails due to insufficient data (which will cause it to
  # return an empty zero-length string) - then we set the flag to indicate
  # failure, and update with a more informative error message to be sent to the
  # benchmarking output file
  benchmark.resuts.text <- paste("Unable to run benchmarking due to",
                                 "insufficient historical data. For details",
                                 "see log file", summary(log_con)$description)
  PASS.BENCHMARKING <- FALSE
}



