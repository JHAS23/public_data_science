# --------------
# Title: main.R
# --------------
# Author: Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Nov 29 2016
# --------------
# Description: This is the main script to run the Pfizer site health algorithms.
# It sources all other relevant scripts to run the programs.
# --------------
# Author:
# Date:
# Modification:
# --------------

################################################################################
#                 Set up Log File, Load Utilities and Libraries                #
################################################################################
# Assign folder directory for storage of log files
LOGDIR <- "Log"

# Load utility functions
source("Code/Utilities/utilities_general.R")

# Record the start date/time the application run, in military time
CURR.SYS.TIME <- Sys.time()
TIMESTAMP <- format(CURR.SYS.TIME, "%Y.%m.%d_%Hh%Mm")

# Constant needed for date manipulation in R- date zero in R is 1/1/1970
R.DATE.ORIGIN <- as.Date("1970-01-01")

# Create log file, open log connection, write messages to log
log.file.name <- create_file_name("Log", ".txt") 
log_con <- open_log(LOGDIR, log.file.name)
write_log_header(log_con)

cat("utilities.R successfully run\n\n", file=log_con)

# Load libraries
loaded <- try(source("Code/library.R"), silent = TRUE)
log_error_check(loaded, "library.R", log_con)


################################################################################
#                          Get Command Line Arguments                          #
################################################################################
# Scan arguments that have been supplied when the current R session was invoked
args <- commandArgs()
#args <- c("MONTHLY_RUN", "TO", "TL", "SH", "SA", "PD", "CSV")
#args <- c("2019-10", "TO", "TL", "SH", "SA", "PD", "CSV")

# Parse command line arguments to determine the run date, whether it is a 
# monthly run or ad hoc run, which modules to run, whether or not to perform
# benchmarking, and whether the input files come from the databse or .csv files
run.list <- parse_arguments(args = args)

RUN.DATE <- as.Date(run.list$RUN_DATE, origin = R.DATE.ORIGIN) # RUN AS OF
MONTHLY.RUN <- run.list$MONTHLY_RUN # MONTHLY RUN
RUN.PD.MODULE <- run.list$PD_MODULE # PROTOCOL DEVIATIONS
RUN.SA.MODULE <- run.list$SA_MODULE # SAFETY
RUN.TL.MODULE <- run.list$TL_MODULE # TIMELINESS
RUN.TO.MODULE <- run.list$TO_MODULE # TURNOVER
RUN.SH.MODULE <- run.list$OVERALL_SH_MODULE # OVERALL SITE HEALTH
RUN.BENCHMARKING <- run.list$BENCHMARKING # BENCHMARKING
CSV.INPUT <- run.list$CSV_INPUT # INPUT DATA FROM CSV FILES

# Print overview of application run to the log based on the arguments supplied 
log_overview(run.list, log_con)


################################################################################
#                       Load Parameters and Check Run Date                     #
################################################################################

# Load parameters
loaded <- try(source("Code/parameters.R"), silent=TRUE)
log_error_check(loaded, "parameters.R", log_con)

# Check that run date is valid, if not stop code flow and output error message
if(is_invalid_date()){
  cat("*** ERROR: Invalid run date. Run date", format(RUN.DATE), 
      "is before the minimum run date", format(MIN.RUN.DATE), file=log_con)
  stopifnot(RUN.DATE > MIN.RUN.DATE)
}

# Create timestamped output folders in directories to save .csv files 
create_date_subfolder(PROCESSED.DATA.DIR, log_con, "\n")
create_date_subfolder(OUTDIR, log_con, "\n\n")


################################################################################
#                Input Data, Process Data, and Run QC Checks                   #
################################################################################
# Load data, using functions from inputs.R
loaded <- try(source("Code/input.R"), silent=TRUE)
log_error_check(loaded, "input.R", log_con)

# Perform data processing / synthetic variable creation
loaded <- try(source("Code/data_processing.R"), silent=TRUE)
log_error_check(loaded, "data_processing.R", log_con)

# Run quality control checks on data
loaded <- try(source("Code/quality_control.R"), silent=TRUE)
log_error_check(loaded, "quality_control.R", log_con)


################################################################################
#                    Load Modeling Modules and Run Models                      #
################################################################################

## Protocol Deviations (PD) ####################################################
if (RUN.PD.MODULE && PASS.PD){ # PD module is set to run and data passed QC checks
  loaded <- try(source("Code/pd_module.R"), silent=TRUE)
  PASS.PD <- log_error_check(loaded, "pd_module.R", log_con)
} else {
  cat("* PD module NOT RUN because either it was not set to run or because it failed quality control checks.\n\n", file=log_con)
}

## Safety (SA) #################################################################
if (RUN.SA.MODULE && PASS.SA){ # SA module is set to run and data passed QC checks
  loaded <- try(source("Code/safety_module.R"), silent=TRUE)
  PASS.SA <- log_error_check(loaded, "safety_module.R", log_con)
} else {
  cat("* Safety module NOT RUN because either it was not set to run or because it failed quality control checks.\n\n", file=log_con)
}

## Timeliness (TL) #############################################################
if (RUN.TL.MODULE && PASS.TL){ # TL module is set to run and data passed QC checks
  loaded <- try(source("Code/timeliness_module.R"), silent=TRUE)
  PASS.TL <- log_error_check(loaded, "timeliness_module.R", log_con)
} else {
  cat("* Timeliness module NOT RUN because either it was not set to run or because it failed quality control checks.\n\n", file=log_con)
}

## Turnover (TO) ###############################################################
if (RUN.TO.MODULE && PASS.TO){ # TO module is set to run and data passed QC checks
  loaded <- try(source("Code/turnover_module.R"), silent=TRUE)
  PASS.TO <- log_error_check(loaded, "turnover_module.R", log_con)
} else {
  cat("* Turnover module NOT RUN because either it was not set to run or because it failed quality control checks.\n\n", file=log_con)
}

## Overall Site Health (SH) ####################################################
# If SH module is set to run and data passed QC checks
if (RUN.SH.MODULE && PASS.PD && PASS.SA && PASS.TL && PASS.TO && PASS.SH){
  loaded <- try(source("Code/overall_site_health_module.R"), silent=TRUE)
  PASS.SH <- log_error_check(loaded, "overall_site_health_module.R", log_con)
} else {
  PASS.SH <- FALSE
  cat("* Overall Site Health module NOT RUN because either it was not set to run, because it or one or more of the sub-modules failed quality control checks, 
      or because one of the sub-modules failed to run.\n\n", file=log_con)
}


################################################################################
#                           Run Benchmarking Analysis                          #
################################################################################
if (RUN.BENCHMARKING && PASS.SH){
   loaded <- try(source("Code/benchmarking.R"), silent=TRUE)
   PASS.BENCHMARKING <- log_error_check(loaded, "benchmarking.R", log_con)
   
   # Update global variable/flag 'NON.CRITICAL.ERRORS' to TRUE if non-critical  
   # errors occur while running benchmarking. If value is already TRUE because 
   # non-critical errors occured during QC, no need to update the value
   NON.CRITICAL.ERRORS <- (NON.CRITICAL.ERRORS | !PASS.BENCHMARKING)
} else {
  RUN.BENCHMARKING <- FALSE
  cat("* Benchmarking analysis NOT RUN because either it was not set to run or because overall site health module failed.\n\n", file=log_con)
}


################################################################################
#                                 Output Results                               #
################################################################################
loaded <- try(source("Code/output.R"), silent=TRUE)
log_error_check(loaded, "output.R", log_con)


################################################################################
#                                    All Done!                                 #
################################################################################
cat("Site health monitoring application run complete!\n", file=log_con)

# Close connection to log
close(log_con)

################################################################################
# This line converts files to Windows line endings so they can be viewed on
# both Windows and Unix.
try(suppressWarnings(system(paste("unix2dos", file.path(LOGDIR, log.file.name)),
                            ignore.stdout=TRUE, ignore.stderr=TRUE)), silent=TRUE)
