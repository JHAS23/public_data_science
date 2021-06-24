# --------------
# Title: utilities_model_dataset_creation.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Nov 22 2016
# --------------
# Description: This script contains functions used to help create the input 
# datasets used by the models in the five different modules.
# --------------
# Author:
# Date:
# Modification:
# --------------

### Create initial shell of allvars: for now, one row per site + oversight
### report; eventually, one row per site for scoring, with date=current date
create_modeling_data_shell <- function(module) {
  if (module %in% c("SH", "SA", "TO")) {
    # For overall Site Health, Safety, and Turnover modules, create one row
    # per site. The date will either be the current date or the "run as of"
    # date, if provided; it will be the LSLV date for sites that have had their
    # LSLV date already.
    Data <- INPUT$Sites[c("HM_SITE_ID", "SITE_LSLV_DATE_DERIVED")]
    Data$DATE <- pmin(RUN.DATE, Data$SITE_LSLV_DATE_DERIVED, na.rm=TRUE)
    Data$SITE_LSLV_DATE_DERIVED <- NULL
  }
  else if (module == "PD") {
    # For PD module, create one row per PD visit. Exclude the most recent
    # monitoring visit for each site, if that visit started within the most
    # recent year AND the site has not had its LSLV date (since that visit could
    # still be ongoing).
    # The date for each visit will be the start date of that visit.

    Data <- merge(INPUT$Sites[c("HM_SITE_ID", "SITE_LSLV_DATE_DERIVED")],
                  INPUT$PD.monitoring[c("HM_SITE_ID", "VISIT_START_DATE")],
                  by="HM_SITE_ID")
    names(Data)[names(Data) == "VISIT_START_DATE"] <- "DATE"
    # If doing a run-as-of date, exclude visits that started after the run date
    Data <- Data[Data$DATE <= RUN.DATE,]

    cat(nrow(Data), "PD monitoring windows found in dataset\n", file=log_con)

    # Drop duplicate visits on the same date
    Data <- unique(Data)

    # Sort ascending by date within site, then drop the most recent visit at
    # each site if it started less than one year ago AND the site has not had
    # an LSLV date
    Data <- Data[order(Data$HM_SITE_ID, Data$DATE),]
    Data <- Data[Data$HM_SITE_ID == c(Data[2:nrow(Data),"HM_SITE_ID"], 0)
                 | Data$DATE <= RUN.DATE - 365
                 | (!is.na(Data$SITE_LSLV_DATE_DERIVED)
                    & Data$SITE_LSLV_DATE_DERIVED <= RUN.DATE),]
    Data$SITE_LSLV_DATE_DERIVED <- NULL

    # Lastly, filter to only include a maximum of 4 PD visits for each site-
    # this is the max number that are displayed in the main database output
    # table (most recent visit plus three previous visits), and helps to
    # greatly increase module running time by reducing the size of the dataset
    if (nrow(Data) > MAX.PD.VISITS) {
      ix <- 1:(nrow(Data)-MAX.PD.VISITS)
      ix.drop <- which(Data[ix,"HM_SITE_ID"]
                       == Data[ix+MAX.PD.VISITS,"HM_SITE_ID"])
      if (length(ix.drop) > 0) {
        Data <- Data[-ix.drop,]
      }
    }

    cat(nrow(Data), "PD monitoring windows remain for modeling after filtering",
        "out duplicate visits on the same date, excluding still-unfinished",
        "visits, and limiting to the", MAX.PD.VISITS, "most recent visits at",
        "a site\n", file=log_con)
  }
  else if (module == "TL") {
    
    # For Timeliness module, create one row per site; the date for each site
    # will the day after the last day of the most recent month for which
    # patient visit information is available for that site (where the date is
    # prior to RUN.DATE).

    # Convert RUN.DATE into a month, in YYYYMM integer format (e.g. 201501 if
    # the RUN.DATE is in Jan. 2015)
    run.date.month <- as.integer(format(RUN.DATE, "%Y%m"))
    
    before.run.date <- INPUT$Patient.visits$MONTH_ID < run.date.month
    # For each site that has had any patient visits prior to RUN.DATE, find the
    # last month (again, prior to RUN.DATE) when visits occurred
    Data <- aggregate(INPUT$Patient.visits[before.run.date,]["MONTH_ID"],
                      by=INPUT$Patient.visits[before.run.date,]["HM_SITE_ID"],
                      FUN=max)
    # Get the first day of the next month
    #years <- Data$MONTH_ID %/% 100 # "floor division"; e.g. 201605 becomes 2016
    #months <- Data$MONTH_ID %% 100 # remainder modulo 100; e.g. 201605 becomes 5
    #Data$DATE <- as.Date(sprintf("%d-%d-01",
    #                             ifelse(months == 12, years + 1, years),
    #                             ifelse(months == 12, 1, months + 1)))
    #Data$MONTH_ID <- NULL
    # For the TL Module the DATE is the last month from the run date
    # Take off 45 days from Today's date
    r <- Sys.Date()
    Data$DATE <- as.Date(r,"%Y-%m-%d")-45
    
    
  }

  cat("Dataset for", module, "module has", nrow(Data), "observations\n",
      file=log_con)

  # For all modules, filter out sites where:
  #  FSFV date is missing or has not yet happened
  #  OR LSLV date has happened and was far in the past
  Data <- merge(Data,
                INPUT$Sites[c("HM_SITE_ID", "SITE_FSFV_DATE_DERIVED",
                              "SITE_LSLV_DATE_DERIVED")])
  Data <- Data[!is.na(Data$SITE_FSFV_DATE_DERIVED)
               & Data$SITE_FSFV_DATE_DERIVED <= RUN.DATE
               & (is.na(Data$SITE_LSLV_DATE_DERIVED)
                  | Data$SITE_LSLV_DATE_DERIVED > RUN.DATE - LSLV.LAG.DAYS),]
  Data$SITE_FSFV_DATE_DERIVED <- NULL
  Data$SITE_LSLV_DATE_DERIVED <- NULL


## New RUN.DATE for New TL Model : It has to be 1 month before the run date
 
  cat(nrow(Data), "observations remain after excluding sites that haven't",
      "yet had their FSFV date, or had their LSLV date more than",
      LSLV.LAG.DAYS, "days ago\n", file=log_con)

  if (nrow(Data) == 0) {
    stop(paste("No valid sites were found that can be scored by the", module,
               "module"))
  }

  return(Data)
}

# This function creates all the variables needed for scoring and creating the
# necessary output for each of the five modules.
#
# The "module" argument is used for efficiency purposes, to avoid creating
# certain computationally expensive variables when they are not needed by the
# particular module.
create_all_variables <- function(Data, module) {
  cat(paste("\n* Creating variables for", module, "MODULE *\n"), file=log_con)
  
  Data <- create_prev_report_start_date(Data)
  Data <- create_site_and_study_vars(Data)
  
  if (module == "PD") {
    cat("Creating protocol deviation variables\n", file=log_con)
    Data <- create_pd_vars(Data)
  }

  cat("Creating patient variables\n", file=log_con)
  Data <- create_patient_vars(Data, module)

  if (module %in% c("SH", "PD", "SA")) {
    cat("Creating patient visit variables\n", file=log_con)
    Data <- create_patient_visit_vars(Data, module)
  }

  if (module %in% c("SH", "SA", "TO")) {
    cat("Creating staff variables\n", file=log_con)
    Staff.turnover <- create_staff_turnover_dataset(Data, module)
    Data <- create_staff_vars(Data, Staff.turnover, module)
  }

  if (module %in% c("PD", "SA", "TO")) {
    cat("Creating safety variables\n", file=log_con)
    Data <- create_safety_vars(Data, module)
  }

  cat("Creating miscellaneous variables\n", file=log_con)
  Data <- create_misc_vars(Data)
  
  # Create Variables for TL - #visits, #pages, #subjects
  if(module %in% "TL"){
    cat("Creating TL specific variables\n", file=log_con)
    Data <- create_tl_variables(Data)
  }
  
  cat(paste("Created variables for", module, "MODULE successfully\n\n"),
      file=log_con)

  # For the Turnover module, we need the modeling dataset but also need to store
  # the intermediate staff turnover dataset, for output to Spotfire
  if (module == "TO") {
    return(list(Model.data=Data, Staff.turnover=Staff.turnover))
  }
  else {
    return(Data)
  }
}


