# --------------
# Title: data_processing.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Oct 26 2016
# --------------
# Description: This script creates the input datasets with all variables used by
# the models in the five different modules. It uses the input raw data which has
# been loaded by the input module, and creates one modeling input dataset for
# each of the modules which is being run.
# --------------
# Author:
# Date:
# Modification:
# --------------

write_log_sub_header("data_processing.R", "Data Processing Module", log_con)

# For each module we are running, we need to first create the modeling data
# shell (which consists of two columns, HM_SITE_ID and DATE, indicating the
# sites to be scored for the particular module and the relevant date or dates
# (e.g. for the PD module, this will be the dates of PD monitoring visits at the
# site).
# Second, we then call create_all_variables to create the various variables that
# are needed for the module.

if (RUN.PD.MODULE) { # PROTOCOL DEVIATIONS
  Model.data.PD <- create_modeling_data_shell("PD")
  Model.data.PD <- create_all_variables(Model.data.PD, "PD")
}

if (RUN.SA.MODULE) { # SAFETY
  Model.data.SA <- create_modeling_data_shell("SA")
  Model.data.SA <- create_all_variables(Model.data.SA, "SA")
}

if (RUN.TL.MODULE) { # TIMELINESS
  Model.data.TL <- create_modeling_data_shell("TL")
  Model.data.TL <- create_all_variables(Model.data.TL, "TL")
  tl <- sa_pd_vars(Model.data.TL,Model.data.PD,Model.data.SA)
  Model.data.TL <- tl$Model.data.TL.org
  Model.data.TL.tfm <- tl$Model.data.TL.tfm
}

if (RUN.TO.MODULE) { # TURNOVER
  Model.data.TO <- create_modeling_data_shell("TO")
  # For the Turnover module, we need the modeling dataset but also need to store
  # the intermediate staff turnover dataset, for output to Spotfire
  out <- create_all_variables(Model.data.TO, "TO")
  Model.data.TO <- out$Model.data
  Staff.turnover.data <- out$Staff.turnover
}

if (RUN.SH.MODULE) { # OVERALL SITE HEALTH
  Model.data.SH <- create_modeling_data_shell("SH")
  Model.data.SH <- create_all_variables(Model.data.SH, "SH")
}

#write.csv(Staff.turnover.data, "/app/r/engine/TEST.csv")
