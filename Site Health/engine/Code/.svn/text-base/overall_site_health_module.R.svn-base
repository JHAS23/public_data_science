# --------------
# Title: overall_site_health_module.R
# --------------
# Authors: Bambo Sosina (bsosina@deloitte.com), 
#          Cristina DeFilippis (Cdefilippis@deloitte.com)
# Date: Nov 22 2016
# --------------
# Description: This file contains code for running the Safety module.
# --------------
# Author:
# Date:
# Modification:
# --------------

write_log_sub_header("overall_site_health_module.R", "Site Health Module", log_con)

run_overall_sh_module <- function(Model.data) {
  # Start to create the Site Health output dataset
  SH.out.overall <- Model.data[c("HM_SITE_ID", "HM_STUDY_ID")]
  SH.out.overall$HM_WRK_GL_OUT_OVERVIEW_ID <- NA # Add empty key column for sqlSave function
  
  # Update model dataset to exclude rows that can't be modeled, for example
  # because they contain new factor levels not present in the training dataset
  covars <- readRDS(file.path(MODEL.DIR, "sh_module_covariates.rds"))
  Train.data <- readRDS(file.path(MODEL.DIR, "sh_module_train_dataset.rds"))
  
  # Load fitted SH model object
  sh.model <- readRDS(file.path(MODEL.DIR, "sh_fitted_model.rds"))
  
  # Use model to score sites
  sh.out <- get_sh_output(Model.data, Train.data, sh.model, covars)
  
  # Subset output table rows to only rows we can obtain prediction percentiles for
  SH.out.overall <- SH.out.overall[SH.out.overall$HM_SITE_ID %in% sh.out$HM_SITE_ID,]
  
  out.metrics <- run_overall_sh_model(SH.output=sh.out, PD.output=pd.out, 
                                      SA.output=sa.out, TL.output=tl.out, 
                                      TO.output=to.out)
  
  return(out.metrics)
}

sh.out <- run_overall_sh_module(Model.data.SH)


