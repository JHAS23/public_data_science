# --------------
# Title: quality_control.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Nov 20, 2016
# --------------
# Description: Contains functions used by quality_control module.
# --------------
# Author:
# Date:
# Modification:
# --------------

# This function runs QC checks on raw input data - these checks are done after
# the data is read in, but before any transformations / synthetic variable
# creation is done.
#
# The only item that this function checks for is to check whether any of the
# raw data tables have not received any new data within a specified period,
# for example within the past 45 days. All other QC checks on the raw data are
# performed outside of R.
#
# Returns: Boolean, TRUE if any problems are found, or FALSE if no problems are
# found. If any problems are found it also sends a descriptive message to the
# log file.
qc_checks_input_data <- function() {
  cat("Running quality control on raw input data...\n", file=log_con)
  errors.found <- FALSE
 
  # List containing a column to check for updated dates, in each dataset
  DATE.COLS <- list(Sites="SITE_FSFV_DATE_DERIVED",
                    Subjects=c("SUBJ_ENROLLED_STUDY_DT_DERIVED",
                               "SUBJ_COMPLETED_STUDY_DT",
                               "SUBJ_DISCONTINUED_DT"),
                    Patient.visits="MONTH_ID",
                    Staff="STATUS_DATE",
                    AEs="AE_COLLECTION_DATE_DERIVED",
                    SAEs="INIT_RECV_DATE",
                    PDs="DATE_DEVIATION_NOTED",
                    PD.monitoring="VISIT_START_DATE",
                    Oversight.reports="REPORT_START_DATE")
  # Notes: No need to check the Studies dataset (every site has an associated
  # study). No need to check the Issues dataset because it is tied to Oversight
  # Reports and does not contain date information.

  # Loop over each dataset in DATE.COLS above, skipping those that have not
  # been loaded (e.g. if the PD module is not being run, there is no need to
  # load the PDs dataset into INPUT)
  for (dataset in intersect(names(DATE.COLS), names(INPUT))) {
    for (date.var in DATE.COLS[[dataset]]) {
      dates <- INPUT[[dataset]][[date.var]]
      if (!inherits(dates, "Date")) { # for MONTH_ID variable
        dates <- as.Date(sprintf("%d-%d-01", dates %/% 100, dates %% 100))
      }
      # Find the most recent date, prior to the current date or run-as-of date,
      # when data was updated
      dates.before.run.date <- dates[!is.na(dates) & dates <= RUN.DATE]
      if (length(dates.before.run.date) > 0) {
        most.recent.date <- max(dates.before.run.date)
        if (most.recent.date < RUN.DATE - NO.NEW.DATA.WARNING.DAYS) {
          cat(paste0("NON-CRITICAL ERROR: ", dataset, " dataset does not ",
                     "appear to have received any new data within the past ",
                     NO.NEW.DATA.WARNING.DAYS, " days prior to the run date ",
                     "of ", format(RUN.DATE), ". The most recent value of ",
                     date.var, " prior to that date is ",
                     format(most.recent.date), "\n"),
              file=log_con)
          errors.found <- TRUE
        }
      }
    }
  }

  cat("Completed quality control checks on raw input data.\n\n", file=log_con)
  return(errors.found)
}


run_qc_checks <- function(Data, module) {
  cat("Running quality control for", module, "module...\n", file=log_con)
  pass <- TRUE

  # Load CSV file with information on what to check for when QCing certain
  # variables
  filename <- file.path(MISC.DATA.DIR, "QC_variable_checks.csv")
  QC.checks <- try(read.csv(filename, as.is=TRUE,
                            na.strings=c("", "#N/A", "NA")),
                   silent=TRUE)
  if (inherits(QC.checks, "try-error")) {
    stop(paste("ERROR reading QC checks file, check that file exists:",
               filename))
  }
  if (length(unique(QC.checks$VAR)) < nrow(QC.checks)) {
    stop(paste0("ERROR: duplicate variable names found in QC checks file (",
                filename, ")"))
  }

  for (col in names(QC.checks)) {
    if (is.character(QC.checks[[col]])) {
      QC.checks[col] <- trim(toupper(QC.checks[[col]]))
    }
  }
  rownames(QC.checks) <- QC.checks$VAR

  for (col in intersect(names(Data), QC.checks$VAR)) {
    x <- Data[[col]]

    # Check that this variable is the correct datatype
    pass <- pass && check_datatype(col, x, QC.checks[col,"DATATYPE"])

    # Check min and max values
    pass <- pass && check_min_val(col, x, Data, QC.checks[col,"MIN"])
    pass <- pass && check_max_val(col, x, Data, QC.checks[col,"MAX"])

    # Check for N/As
    if (!QC.checks[col,"CAN_BE_MISSING"] && any(is.na(x))) {
      cat(paste0("WARNING: N/A values were found in variable ", col,
                 ", which should not contain missing values\n"), file=log_con)
    }
    if (mean(is.na(x)) > NA.WARNING.PCT) {
      cat(paste0("WARNING: ", round(100. * mean(is.na(x))), "% of the values ",
                 "of ", col, " are N/A\n"), file=log_con)
    }
  }

  if (pass) {
    cat(module, "module passed quality control checks without errors\n\n",
        file=log_con)
  }
  else {
    cat(module, "module failed quality control checks\n\n", file=log_con)
  }
  return(pass)
}



check_datatype <- function(varname, x, datatype) {
  if (datatype == "NUMERIC") {
    pass <- is.numeric(x)
  }
  else if (datatype == "INTEGER") {
    pass <- is.numeric(x) && all(is.na(x) | x %% 1 == 0)
  }
  else if (datatype == "FACTOR") {
    pass <- is.factor(x)
  }
  else if (datatype == "DATE") {
    pass <- inherits(x, "Date")
  }
  else {
    cat(paste0("WARNING: Unrecognized datatype '", datatype, "' in ",
        "QC_variable_checks.csv file\n"), file=log_con)
    pass <- TRUE
  }

  if (!pass) {
    cat("ERROR:", varname, "is not a valid", tolower(datatype), "variable\n",
        file=log_con)
  }

  return(pass)
}

check_min_val <- function(varname, x, Data, min.val) {
  num.min <- suppressWarnings(as.numeric(min.val))
  if (is.na(min.val)) {
    pass <- TRUE
  }
  else if (!is.na(num.min)) {
    pass <- all(x >= num.min, na.rm=TRUE)
  }
  else if (min.val %in% names(Data)) {
    pass <- all(x >= Data[[min.val]], na.rm=TRUE)
  }
  else {
    cat(paste0("Note: variable ", min.val, ", in the 'MIN' column of ",
               "QC_variable_checks.csv, was not found in the modeling ",
               "dataset - skipping this QC check\n"), file=log_con)
    pass <- TRUE
  }

  if (!pass) {
    cat("ERROR: variable", varname, "is below the minimum allowable value of",
        min.val, "\n", file=log_con)
  }

  return(pass)
}


check_max_val <- function(varname, x, Data, max.val) {
  num.max <- suppressWarnings(as.numeric(max.val))
  if (is.na(max.val)) {
    pass <- TRUE
  }
  else if (!is.na(num.max)) {
    pass <- all(x <= num.max, na.rm=TRUE)
  }
  else if (max.val %in% names(Data)) {
    pass <- all(x <= Data[[max.val]], na.rm=TRUE)
  }
  else {
    cat(paste0("WARNING: variable ", max.val, ", in the 'MAX' column of ",
              "QC_variable_checks.csv, was not found in the modeling ",
              "dataset - skipping this QC check\n"), file=log_con)
    pass <- TRUE
  }

  if (!pass) {
    cat("ERROR: variable", varname, "is above the maximum allowable value of",
        max.val, "\n", file=log_con)
  }

  return(pass)
}


