# --------------
# Title: library.R
# --------------
# Author: Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Oct 24 2016
# --------------
# Description: This script loads all required R packages (libraries) needed to 
# run the Pfizer site health algorithms.
# --------------
# Author:
# Date:
# Modification:
# --------------

# Note:	The code will be running with R version 3.0.2. 
# We cannot use any packages that are not compiled against this version.

cat("Running library.R script...\n", file=log_con)
cat("Loading required R libraries...\n", file=log_con)

load_libraries <- function(){
  require(data.table)
  require(plyr)
  require(reshape2)
  require(pscl)
  require(circular)

  # If RODBC cannot be loaded due to missing configuration information, output
  # a helpful message
  success <- require(RODBC)
  if (!success) { # success is TRUE if RODBC loaded correctly
    cat("WARNING: Unable to load R package 'RODBC'. You may need to run",
        "the following command in the Unix command prompt in order to load",
        "certain environment variables, then try re-running main.R:\n",
        "\tsource /app/hmuser/.bash_profile\n", file=log_con)
  }
}

suppressMessages(suppressWarnings(load_libraries()))


