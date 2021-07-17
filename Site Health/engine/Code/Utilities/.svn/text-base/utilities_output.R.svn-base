# --------------
# Title: utilities_output.R
# --------------
# Author: Cristina DeFilippis (cdefilippis@deloitte.com)
# Date: Nov 22 2016
# --------------
# Description: Contains functions for saving and outputting data from R to 
# .csv files and to the database
# --------------
# Author:
# Date:
# Modification:
# --------------

# Pastes together text elements to create a file name that starts with the 
# prefix supplied as an argument, followed by an underscore, then the current
# system date, another underscore, and then the current system time 
# (in military time).
# E.g. "MyFile_2016.11.01_14h33m.csv"
#
# Args:
#   prefix: A character string indicating the name of the file
#   file.type: A character string indicating the type of file the name is for
#
# Returns:
#   A character string
create_file_name <- function(prefix, file.type){
  file_name <- paste(prefix, "_", TIMESTAMP, file.type, sep="")
  return(file_name)
}


# Writes an R object (data frame) to a ".csv" file.
#
# Note: the folder location of where the file is saved depends on the values of
# the global variables "PROCESSED.DATA.DIR" or "OUTDIR" which will specify 
# that the sub-folder is either "Monthly_Runs' if it is a monthly run or the
# sub-folder "Ad_Hoc_Runs" if it is an ad hoc run. A line is written to the log
# each time a file is saved indicating the file name and location.
#
# If the object is processed data set used for modeling in one of the modules, 
# the ".csv" file is saved to a folder named by the date the program was run,
# within the folders specified by global variable "PROCESSED.DATA.DIR".
# For example, if today's date is Novemeber 22, 2016 and
# global variable "PROCESSED.DATA.DIR" = "Processed_data/Ad_Hoc_Runs", 
# then a resulting .csv file may be saved: 
# "../Data/Processed_data/Ad_Hoc_Runs/2016.11.22/Model_Data_PD_2016.11.22_14h42m.csv"
#
# If the object is output from one of the modules, the ".csv" file is saved to 
# a folder named by the date the program was run, within the folder specified 
# by global variable "OUTDIR". For example, if today's date is 
# Novemeber 22, 2016 and global varable OUTDIR = "Module_output/Monthly_Runs", 
# then a resulting .csv file may be saved: 
# "../Module_output/Monthly_Runs/2016.11.22/Module_Output_PD_2016.11.22_15h14m.csv"
#
# Args:
#   output: The object to be written, preferably a matrix or data frame. 
#           If not, it is attempted to coerce x to a data frame.
#   output.type: A character string indicating the type of object that is to 
#                be written to a .csv file, possible values are:
#                "Model Data" or "Module Output"
#   module.name: A character string indicating the module the object relates to
#   log_con: An open file connection to a ".txt" log file
#
# Returns:
#   N/A
save_output_to_csv <- function(output, output.type, module.name, log_con=log_con){
  # save processed data set used for modeling to a csv file
  if (output.type == "Model Data"){
    prefix <- paste("Model_Data_", module.name, sep="")
    file.name <- create_file_name(prefix, ".csv")
    write.csv(output, file.path(PROCESSED.DATA.DIR, file.name),
              row.names = FALSE)
    cat(paste("File '", file.name, "' saved to folder '", PROCESSED.DATA.DIR, "'\n", sep=""), 
        file=log_con)
  }
  # save module output to a csv file
  else if (output.type == "Module Output"){
    prefix <- paste("Module_Output_", module.name, sep="")
    file.name <- create_file_name(prefix, ".csv")
    write.csv(output, file.path(OUTDIR, file.name), row.names = FALSE)
    cat(paste("File '", file.name, "' saved to folder '", OUTDIR, "'\n", sep=""), 
        file=log_con)
  }
  else {
    # write error to log file
    cat("ERROR: unknown output type - R doesn't know where to save .csv file",
        file=log_con)
  }
}




# Create a sub-folder named with today's date in the folder name specified by
# the "folder.dir" parameter, if one does not exist already
# Write a message to the log indicating what folder was created and where
create_date_subfolder <- function(folder.dir, log_con=log_con, linspace="\n"){
  # Check if a folder with the given date exists in the parent folder
  # If not, create one with the name provided by folder.date
  if (!file.exists(file.path(folder.dir))){
    dir.create(file.path(folder.dir))
    # write message to log
    cat("New folder created:", folder.dir, linspace, file=log_con)
  }
  else { # Folder already created
    # Write message to log
    cat("Folder", folder.dir, "already exists (not created) in directory", 
        linspace, file=log_con)
  }
}


# Create indicator file with given module name based on value of pass
# Arguments:
#   module.name: A text string indicating the module name to be used
#   module.pass: A boolean value (true/false) indicating if the module ran
#                successfully without errors (true if so)
#   nc.errors: A boolean value (true/false) indicating the presense of
#              non-critical errors. Defaults to FALSE if not specified.
#
# Returns: writes a file named [module.name].ind to the file path specified
#          by MODULE.IND.PATH
#
write_ind_file <- function(module.name, module.pass, nc.errors=FALSE){
  if (module.pass & !nc.errors) {
    # If module ran successfully and there were no non-critical errors
    result <- "SUCCESS"
  } else if (module.pass & nc.errors){
    # If module ran successfully and there was 1 or more non-critical errors
    result <- "NON-CRITICAL ERROR"
  } else {
    # If module did not run successfully
    result <- "ERROR"
  }
  
  # Create .txt file with result
  write.table(result, 
              file.path(MODULE.IND.DIR, paste(module.name, ".ind", sep="")), 
              col.names = FALSE, row.names = FALSE, quote = FALSE)
}


# Create indicator files with given module name based on values of pass 
# variables. Global variable NON.CRITICAL.ERRORS set to TRUE if there are any 
# non-critical errors. Set indicator file for SH to say "NON-CRITICAL ERROR" if 
# NON.CRITICAL.ERRORS = TRUE, else set the indicator file for SH as per usual.
# Only create indicator files for module that were set to run - use 
# RUN.[XX].MODULE values to determine if a module was set to run. 
write_indicator_files <- function(){
  if (RUN.PD.MODULE){
    write_ind_file("PD", PASS.PD)
  }
  
  if (RUN.SA.MODULE){
    write_ind_file("SA", PASS.SA)
  }
  
  if (RUN.TL.MODULE){
    write_ind_file("TL", PASS.TL)
  }
  
  if (RUN.TO.MODULE){
    write_ind_file("TO", PASS.TO)
  }
  
  if (RUN.SH.MODULE){
    write_ind_file("SH", PASS.SH, nc.errors = NON.CRITICAL.ERRORS)
  }
}


# Function to save benchmarking results to a .txt file in the folder location
# specified by global variable OUTDIR. A line is written to the log when the 
# file is saved indicating the file name and location.
save_benchmarking_results <- function(log_con){
  file.name <- create_file_name("Benchmarking_Results", ".txt")
  write.table(benchmark.results.text, file.path(OUTDIR, file.name),
              col.names = FALSE, row.names = FALSE, quote = FALSE)
  
  # This line converts files to Windows line endings so they can be viewed on
  # both Windows and Unix.
  try(suppressWarnings(system(paste("unix2dos", file.path(OUTDIR, file.name)),
                              ignore.stdout=TRUE, ignore.stderr=TRUE)), silent=TRUE)
  
  # Write message to the log
  cat(paste("File '", file.name, "' saved to folder '", OUTDIR, "'\n", sep=""), 
      file=log_con)
}
