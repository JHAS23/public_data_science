# --------------
# Title: utilities.R
# --------------
# Author: Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Oct 30 2016
# --------------
# Description: This script contains all custom utility functions used to perform
# operations in other modules as part of the site health programs.
# --------------
# Author:
# Date:
# Modification:
# --------------

# Load other utilities files
source("Code/Utilities/utilities_database.R")
source("Code/Utilities/utilities_input.R")
source("Code/Utilities/utilities_model_dataset_creation.R")
source("Code/Utilities/utilities_modeling_sh.R")
source("Code/Utilities/utilities_output.R")
source("Code/Utilities/utilities_quality_control.R")
source("Code/Utilities/utilities_site_and_study_vars.R")
source("Code/Utilities/utilities_var_creation.R")


# First, creates a new ".txt" file named "Log" with the current system date and 
# time as the suffix. Then opens a connection to the log file, so descriptive 
# messages about how the site health programs are running may be appended to the 
# log.
#
# Args:
#   log.file.path: a string containing the location of the log file
#   log.file.name: a string containintg the name of the ".txt" log file
#
# Returns:
#   An open file connection to a ".txt" log file to which text can be appended
open_log <- function(log.file.path, log.file.name){
  # Create log file
  write.table("", file.path(LOGDIR, log.file.name), col.names = FALSE, 
              row.names = FALSE, quote = FALSE)
  # return connection to log file
  return(file(file.path(log.file.path, log.file.name), open="a"))
}


# Prints a header box to the log file and prints the current system
# date and time to the log below that.
#
# Args:
#   log_con: An open file connection to a ".txt" log file to which text can be 
#            appended
#
# Returns:
#   N/A - function simply writes to the log file
write_log_header <- function(log_con){
  header <- paste("\n###############################################################################\n",
                  "#                                                                             #\n",
                  "#                           	    LOG FILE                                  #\n",
                  "#                   	  Site Health Application Run                         #\n",
                  "#                                                                             #\n",
                  "###############################################################################\n",
                  sep="")
  date.line <- paste("##------------------------", format(CURR.SYS.TIME, "%a %b %d %H:%M:%S %Y"), "-------------------------##\n")
  pound.line <- "###############################################################################\n\n"
  cat(paste(header, date.line, pound.line, sep=""), file=log_con)
}

# Prints a subheader to the log file to break the log up into sections.
#
# Args:
#   module.name: Text specifying the name of te R script that will be run
#   header.text: Text to be written as the header
#   log_con: An open file connection to a ".txt" log file to which text can be 
#            appended
#
# Returns:
#   N/A - function simply writes to the log file
write_log_sub_header <- function(module.name, header.text, log_con){
  title.line <- paste("##---------------------", header.text, "---------------------##")
  pound.line <- "###############################################################################\n"
  
  # calculate difference in width between title line and pound line
  width.diff <- nchar(pound.line) - nchar(title.line)
  if (width.diff > 0){
    width.pad <- paste0(rep("#", round(width.diff/2)), collapse = "")
    title.line <- paste0(width.pad, title.line, width.pad, collapse = "")
  }
  
  # Write messages to log
  cat(paste0(pound.line, title.line, "\n", pound.line, sep=""), file=log_con)
  cat("Loading", module.name, "script...\n", file=log_con)
}

# Checks if a given variable contains a "try-error", or has inherited one from
# attempting a block of code encased in a try() statememt. If the code ran
# successfully, the given variable will not have inherited a "try-error", 
# otherwise if there were any issues running the code, the variable will have
# inherited a "try-error". Returns TRUE if an error has occured, FALSE otherwise.
#
# Args:
#   loaded: A variable assigned to the outcome of a try() statement. If the code
#           attempted in the try() statement produces an error, this variable will
#           inherit a "try-error".
#
# Returns:
#   A boolean value (TRUE or FALSE). Returns TRUE if "loaded" variable contains
#   a "try-error", returns FALSE otherwise.
is_error <- function(loaded){
  inherits(loaded, "try-error")
}


# Checks if a given variable contains a "try-error" using the previously defined
# function is_error(). If no error, prints a successfully run message to the log
# file, whose connection is provided via the "log_con" parameter. If an error is
# present, prints a message to the log file indicating there was an error while 
# running this file (file name provided via "filename" parameter) and then
# prints the specific error message provided by R to the log.
#
# Args:
#   loaded: A variable assigned to the outcome of a try() statement. If the code
#           attempted in the try() statement produces an error, this variable will
#           inherit a "try-error"
#   filename: A string containintg the name of the R script (.R) file being run
#   log_con: An open file connection to a ".txt" log file
#
# Returns:
#   A boolean value (TRUE or FALSE). Returns TRUE if "loaded" variable does not
#   inherit a try-error, returns FALSE otherwise.
log_error_check <- function(loaded, filename, log_con){
  if (!is_error(loaded)){ # MODULE PASSED (ran through without errors)
    MODULE.PASS.IND <- TRUE
    cat(paste(filename, " successfully run\n\n", sep=""), file=log_con)
  } 
  else { # Module FAILED (errors occured while running)
    MODULE.PASS.IND <- FALSE 
    cat("\n****************** ERROR *******************\n", file=log_con)
    cat(paste("ERROR running", filename, "script\n"), file=log_con)
    cat(paste(loaded[1], sep=""), file=log_con)
    cat("********************************************\n\n", file=log_con)
  }
  
  # Return a TRUE/FALSE value
  # invisible() function used so T/F value is not printed to console if output 
  # is not assigned to a variable (as it is for PD, SA, TL, TO, SH modules)
  return(invisible(MODULE.PASS.IND)) 
}


# Checks if a given module name, indicated by the parameter "module.name" is 
# listed in the command line arguments provided at runtime. If if finds that the
# module name is provided, then returns TRUE, othewise FALSE.
#
# Args:
#   args: A character vector containing the arguments passed to R from the
#         command line at the time the R script is being called
#   module.name: A string containing the name of the module to check for
#
# Returns:
#   A boolean value (TRUE or FALSE). Returns TRUE if "module.name" is listed in
#   the command line arguments ("args"), FALSE otherwise.
check_module_run <- function(args, module.name){
  # check if the module name is listed in the arguments provided at runtime
    # if yes, length = 1 (> 0), return true
    # if not, length = 0, return false
  return(length(args[args %in% module.name]) > 0)
}


# Checks if a date is listed in the command line arguments provided at runtime. 
# If the date is listed in proper form "YYYY-MM", then returns a date object
# specifying that date. If no date is listed in the arguments, returns the 
# current system date.
#
# Args:
#   args: A character vector containing the arguments passed to R from the
#         command line at the time the R script is being called
#
# Returns:
#   Returns an object of class "Date"
parse_date <- function(args){
  # check if a date ("YYYY-MM") is listed in the arguments provided at runtime
  myDate <- args[args %like% "^....-..$"]
  
  # if a date IS listed, length of myDate > 0, return listed date as date object
  if (length(myDate) > 0){
    return(as.Date(paste(myDate, "-01", sep=""))) 
  } else {
    # if date not provided, length of myDate = 0, return system date
    return(as.Date(format(CURR.SYS.TIME,"%Y-%m-%d"))) 
  }
}



# Checks which modules were listed in the command line arguments provided at runtime. 
# Also checks if the run is a "monthly run", and if benchmarking should be performed.
# If "monthly run" then the overall SH module, all sub-modules, and benchamrking
# are automatically set to TRUE. If not a "monthly run", then searches the 
# command arguments for each module name - if found then returns TRUE, othewise FALSE.
# If "CSV" is listed in arguments, indicates the input files will be read from
# ".csv" files instead of the database (option used mainly for testing).
#
# Args:
#   args: A character vector containing the arguments passed to R from the
#         command line at the time the R script is being called
#
# Returns:
#   A named list with boolean values (TRUE or FALSE). List values are TRUE if 
#   that module was listed in the command line arguments ("args"), FALSE otherwise.
parse_arguments <- function(args){
  # Set input arguments to upper case
  args <- toupper(args) 
  
  # Check if "CSV" argument is given
  CSV.INPUT <- check_module_run(args, "CSV")
  
  # Check if it is a "monthly run" and if "SH" module was specified to run
  MONTHLY.RUN <- check_module_run(args, "MONTHLY_RUN")
  RUN.SH.MODULE <- check_module_run(args, "SH") # (Overall) Site Health
  
  # If monthly run, set benchmarking to true and date to current system date
  # Otherwise, it is an ad hoc run and we must check if benchmarking should be 
  # run and check for a run date specified (set date to current system date if 
  # none specified)
  if (MONTHLY.RUN){
    BENCHMARKING <- TRUE # Benchmarking
    RUN.DATE <- CURR.SYS.TIME # Run as of
  } else { 
    # Not a monthly run
    BENCHMARKING <- check_module_run(args, "BENCHMARK") # Benchmarking
    RUN.DATE <- parse_date(args) # Run as of
  }
  
  # Set boolean values to inidcate which modules to run
  # If monthly run or SH module set to run, all modules should be set to run
  # Otherwise, check each of the sub-modules to see if they should be run
  if (MONTHLY.RUN | RUN.SH.MODULE) { # Monthly run
    RUN.PD.MODULE <- TRUE # Protocol Deviations
    RUN.SA.MODULE <- TRUE # Safety
    RUN.TL.MODULE <- TRUE # Timeliness
    RUN.TO.MODULE <- TRUE # Turnover
    RUN.SH.MODULE <- TRUE # Overall Site Health
  } else { 
    # Not a monthly run or overall site health run
    RUN.PD.MODULE <- check_module_run(args, "PD") # Protocol Deviations
    RUN.SA.MODULE <- check_module_run(args, "SA") # Safety
    RUN.TL.MODULE <- check_module_run(args, "TL") # Timeliness
    RUN.TO.MODULE <- check_module_run(args, "TO") # Turnover
  }
  
  # Return a named list containing: boolean values (TRUE/FALSE) inidicating if 
  # it is a monthly run, TRUE/FALSE if benchamrking should be performed, 
  # TRUE/FALSE for each module to run, and the run date
  RUN.LIST <- list(MONTHLY_RUN=MONTHLY.RUN, RUN_DATE=RUN.DATE, 
                   PD_MODULE=RUN.PD.MODULE, SA_MODULE=RUN.SA.MODULE, 
                   TL_MODULE=RUN.TL.MODULE, TO_MODULE=RUN.TO.MODULE, 
                   OVERALL_SH_MODULE=RUN.SH.MODULE, 
                   BENCHMARKING=BENCHMARKING, CSV_INPUT=CSV.INPUT)
  
  return(RUN.LIST)
}


# Prints an overview of the Site Health applciation run to the log, showing the
# date of the run, whether or not it is a regular monthly run, whether or not
# benchmarking should be performed, and finally which of the individual modules
# should be run.
#
# Args:
#   module_runs: A boolean vector of TRUE/FALSE values, one per each module,
#                indicating which modules should be run
#   module_names: A character vector containing the full names of each Site Health
#                 module
#   log_con: An open file connection to a ".txt" log file to which text can be appended
#
# Returns:
#   N/A - function simply writes to the log file
log_overview <- function(run.list, log.con){
  module_runs <- run.list[3:8]
  module_names <- names(run.list[3:8])
  input_type <- ifelse(run.list["CSV_INPUT"]==1, ".csv files", "database tables")
  
  cat("****************************\n", file=log_con)
  cat("APPLICATION RUN OVERVIEW:\n", file=log_con)
  cat("****************************\n", file=log_con)
  cat(paste("Run as of date:", RUN.DATE, "\n"), file=log_con)
  cat(paste("Monthly run:", run.list['MONTHLY_RUN']==1,"\n"), file=log_con)
  cat(paste("Input type:", input_type,"\n\n"), file=log_con)
  
  cat("- Modules selected to run -\n", file=log_con)
  for (i in 1:length(module_names)){
    cat(paste(module_names[i], ": ", module_runs[i]==1, "\n", sep=""), file=log_con)
  }
  cat("****************************\n\n", file=log_con)
}


# Checks if the run date provided is valid by checking that the run date is a
# date that occurs after the minimum run date. Uses global variables RUN.DATE, 
# which is obtained by parsing the command line arguments, and MIN.RUN.DATE, 
# which is set in the Parameters. Use to stop code flow with an error in main.R
# if the run date is outside the valid range.
#
# Args:
#   <None>
#
# Returns:
#   A boolean value (TRUE or FALSE). Returns TRUE if RUN.DATE < MIN.RUN.DATE 
#   (invalid date), FALSE otherwise.
is_invalid_date <- function(){
  return(RUN.DATE < MIN.RUN.DATE)
}


# Computes the date "n" months prior to or post the given date.
#
# Args:
#   date: an object of class "Date" in the format "%Y-%m-%d"
#      n: The number of months to shift the given date. Must be an integer. 
#         Negative integers will shift the month backwards, positive integers
#         shift the date forwards by the specified number of months.
#
# Returns:
#   A date, shifted the approopriate number of months forward or backward
#   from the given date.
add_months <- function(date, n){
  y <- seq(date, by = paste (n, "months"), length = 2)
  return(y[2])
}


# Vectorized version of the add_months function.
# Computes the dates "n" months prior to or post the given vector of dates.
#
# Args:
#   dates: a vector of dates of class "Date" in the format "%Y-%m-%d"
#      n: The number of months to shift the given dates. Must be an integer. 
#         Negative integers will shift the date backwards, positive integers
#         shift the date forwards by the specified number of months.
#
# Returns:
#   A vector of dates, shifted the approopriate number of months forward or 
#   backward from the given dates in the input vector.
add_months_vector <- function(dates, n){
  as.Date(sapply(dates, add_months, n), origin="1970-01-01")
}


# Counts the number of NA values in each column of a data frame.
#
# Args:
#   dat: a data frame object
#
# Returns:
#   A Nx2 matrix of NA counts. The first column contains the names of each 
#   column in the data frame, with one row per column. The second column 
#   contains the number of NA values in that column in the data frame.
na_count <- function(dat){
  mat <- t(t(sapply(dat, function(x) sum(is.na(x)))))
  colnames(mat)  <- "NA Count"
  return(mat)
}


# Similar to the Excel function IFNA(). Given a value, vector, or list "x",
# returns "x" with all NA values replaced with the value given by "val.if.NA"
#
# Args:
#   x: Vector or list (may be of any length, including 0 or 1)
#   val.if.NA: Value to substitute for any NA values found in "x"
#
# Returns: copy of "x" with all NA values replaced by "val.if.NA"
#
# Examples:
#   answers <- c("Y", "N", "N", NA, "Y"); ifna(answers, "No response")
ifna <- function(x, val.if.NA) {
  if (length(val.if.NA) != 1) stop("Argument 'val.if.NA' must have length 1")
  if (length(x) == 0) return (x)

  ix <- is.na(x)
  if (is.factor(x) && !val.if.NA %in% levels(x)) {
    levels(x) <- c(levels(x), val.if.NA)
    warning(paste0("Adding new level '", val.if.NA, "' to factor"))
  }
  x[ix] <- val.if.NA
  return (x)
}
