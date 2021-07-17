# --------------
# Title: input.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Oct 26 2016
# --------------
# Description: This script loads raw data from views in the Oracle database or
# from CSV files into R dataframes.
# --------------
# Author:
# Date:
# Modification:
# --------------

cat("Running input.R script...\n", file=log_con)

# Global list of data frames that holds the input data files for all modules
INPUT <- load_input_data()


