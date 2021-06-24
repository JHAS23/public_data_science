# --------------
# Title: quality_control.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Oct 26 2016
# --------------
# Description: This script runs quality control checks on the raw input data
# that is loaded from various views in the Oracle database. If any potential
# problems are found with the data, the script raises an error and/or outputs a
# warning message to the program log, depending on the severity of the problem.
# --------------
# Author:
# Date:
# Modification:
# --------------

write_log_sub_header("quality_control.R", "Quality Control Module", log_con)

# Run QC checks on raw input data
NON.CRITICAL.ERRORS <- qc_checks_input_data()

# Run QC checks on the modeling dataset for each module. If any critical errors
# are found, then the appropriate "PASS" flag will be set to false, so that the
# model is not run until the errors can be corrected.
if (RUN.PD.MODULE) { # PROTOCOL DEVIATIONS
  PASS.PD <- run_qc_checks(Model.data.PD, "PD")
}

if (RUN.SA.MODULE) { # SAFETY
  PASS.SA <- run_qc_checks(Model.data.SA, "SA")
}

if (RUN.TL.MODULE) { # TIMELINESS
  PASS.TL <- run_qc_checks(Model.data.TL, "TL")
}

if (RUN.TO.MODULE) { # TURNOVER
  PASS.TO <- run_qc_checks(Model.data.TO, "TO")
}

if (RUN.SH.MODULE) { # OVERALL SITE HEALTH
  PASS.SH <- run_qc_checks(Model.data.SH, "SH")
}


