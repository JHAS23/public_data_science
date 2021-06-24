# --------------
# Title: parameters.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Oct 26 2016
# --------------
# Description: This script contains all parameters used in other modules as 
# part of the site health programs.
# --------------
# Author:
# Date:
# Modification:
# --------------

cat("Running parameters.R script...\n", file=log_con)

# Directory for saving processed modeling input datasets
if (MONTHLY.RUN) {
  PROCESSED.DATA.DIR <- file.path("Data/Processed_data/Monthly_Runs", TIMESTAMP)
} else {
  PROCESSED.DATA.DIR <- file.path("Data/Processed_data/Ad_Hoc_Runs", TIMESTAMP)
}

# Top-level directory for saving model results for monthly runs
MONTHLY.RUN.OUTDIR <- "Module_output/Monthly_Runs"
# Specific directory for saving model results for this run of the modules
if (MONTHLY.RUN) {
  OUTDIR <- file.path(MONTHLY.RUN.OUTDIR, TIMESTAMP)
} else {
  OUTDIR <- file.path("Module_output/Ad_Hoc_Runs", TIMESTAMP)
}


# Directory for storing flags indicating whether models ran successfully
MODULE.IND.DIR <- "Log/Module_success_indicators"
# Directory where the fitted model files are saved
MODEL.DIR <- "Model_files"
# Directory for miscellaneous data files
MISC.DATA.DIR <- "Data/Misc"
# Directory holding CSV files which contain raw data pulled from views in the
# Oracle database. When the CSV option is given, the app reads raw data in from
# these files instead of from the database
DATABASE.DATA.DIR <- "Data/Database_data"


# These two parameters define the earliest date from which model predictions
# will be tested in the benchmarking module. For example, suppose that the
# model for total issue count was originally built on 1/1/2016- then it makes
# sense for that date to be the benchmarking start date, so that we are only
# evaluating how well the model does while predicting issue counts from future
# reports that were not known at the time the model was built. Additionally,
# the BENCHMARK.LOOKBACK.DAYS parameter restricts the duration of the lookback
# period, to give a better indication of how well the model has performed
# recently. E.g. if lookback days = 180, then benchmarking will only evaluate
# predictions made within the past 180 days.
BENCHMARK.START.DATE <- as.Date("2016-10-01")
BENCHMARK.LOOKBACK.DAYS <- 180
# If fewer than this number of observations (completed oversight reports) are
# available for benchmarking, the benchmarking module will output a warning
# cautioning the user not to overinterpret accuracy results from a relatively
# small number of observations.
MIN.BENCHMARK.OBS <- 100

# Minimum month and year for which it is permissible to do "run as of" - i.e.,
# the earliest date for which the user can provide an optional run date which
# will run the application using only data from *before* this month.
# This is set as Jan. 2014 because the last old-version (PSQRV) oversight
# reports were held in December 2013, and the algorithms (especially the overall
# Site Health module) were built based on new-version data and are not designed
# to work as well with PSQRV reports.
MIN.RUN.DATE <- as.Date("2014-01-01")

# Number of days to keep including a site in the modeling, after its last
# subject last visit (LSLV) date has passed. For example, if this variable is
# set to 365, then we will continue to include sites up to one year after their
# LSLV date.
LSLV.LAG.DAYS <- 365 * 3

# In the PD module, include data for the past 4 PD visits - this is in keeping
# with the database output which shows the most recent PD visit plus 3 previous
# ones.
MAX.PD.VISITS <- 4

# If a variable is found to have N/As in more than a certain percentage of rows,
# a warning will be triggered in the QC module. For example, set NA.WARNING.PCT
# equal to 0.5 in order to trigger warnings when more than 50% of values of a
# variable are missing.
NA.WARNING.PCT <- 0.5

# If no new data has been added to a raw dataset within a certain number of
# days, then a warning will be triggered in the QC module. For example, if
# NO.NEW.DATA.WARNING.DAYS is 45, then a warning will be printed whenever
# a dataset does not contain any new data from within the past 45 days.
NO.NEW.DATA.WARNING.DAYS <- 45

# Weights indicating how the four sub-modules factor into the overall
# zero-to-ten Site Health metric - higher values for a module indicate that that
# module has a greater impact on the overall metric. The rational for these
# weights is in the model specification documentation for the overall SH module.
MODULE.WEIGHTS <- list(weight.pd = 0.28, weight.sa = 0.35,
                       weight.tl = 0.17, weight.to = 0.20)

# The following thresholds are used to define the "SITE_HEALTH_INDICATOR_B"
# field in the database. A site is deemed to be unhealthy by this indicator if
# it violates any of the following thresholds, defined below.
#
# The threshold values were copied from the previous version of the Site Health
# algorithm (as of 2016) in order to avoid changing the interpretation of this
# indicator. The one change made is that the threshold for high actual minus
# expected SAEs was dropped, because the intent of the SAE model is to identify
# possible underreporting of SAEs, as opposed to *higher* than expected numbers
# of SAEs. Therefore, it does not seem to make sense for higher then normal SAE
# counts to cause this flag to identify sites as unhealthy.
SITE.HEALTH.IND.THRESHOLDS <- list(
              # Unhealthy if actual minus expected PDs (in either the current or
              # most recent previous window) exceeds the MAX threshold
              # (indicating unusually high PDs) or is below the MIN threshold
              # (indicating possible underreporting)
              MAX.PD.DELTA = 7.0,
              MIN.PD.DELTA = -2.5,
              # Unhealthy if the percentage of monitors or sub-investiagors who
              # left within the past year exceeds these thresholds
              MAX.MONITOR.TURNOVER = 0.80,
              MAX.SUBI.TURNOVER = 0.67)


# Valid values of "Development phase" in the raw studies dataset. This is used
# in order to warn the user if any new values are added.
DEVELOPMENT.PHASES <- c("PHASE I", "PHASE II", "PHASE III", "PHASE IV",
                        "N/A (NOT APPLICABLE)")

# Name of Oracle database
DATABASE.NAME <- "HM_DM_WRK_OWNER"
# Names of servers where the Oracle databases are hosted- this should be a list
# mapping the name of each application server to the corresponding database
# server
DATABASE.SERVER.NAMES <- list(amrndhl985="enid195.pfizer.com", # Dev
                              amrndhl986="enit185.pfizer.com", # Test
                              amrndhl987="enis188.pfizer.com", # Stage
                              amrndhl988="sthlth_p.pfizer.com") # Prod




