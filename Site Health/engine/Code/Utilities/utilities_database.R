# --------------
# Title: utilities_database.R
# --------------
# Author: Kevin Coltin (kcoltin@deloitte.com)
# Date: Nov 21 2016
# --------------
# Description: Contains functions for reading and writing to the Oracle database
# --------------
# Author:
# Date:
# Modification:
# --------------

# Connects to the Oracle database
#
# Returns: A database connection object
connect_to_database <- function() {
  # Get the name of the Linux app server, e.g. amrndhl985 for the Dev server
  app.server <- try(system("uname -n", intern=TRUE, ignore.stderr=TRUE),
                    silent=TRUE)
  if (inherits(app.server, "try-error")) {
    stop(paste("ERROR when executing Unix command 'uname -n':",
               as.character(app.server)))
  }
  app.server <- sub("\\.pfizer\\.com$", "", tolower(app.server)) # remove domain
  # Get the name of the corresponding Oracle server
  server.name <- DATABASE.SERVER.NAMES[[app.server]]
  if (is.null(server.name)) {
    stop(paste0("ERROR: the parameter list DATABASE.SERVER.NAMES does not ",
               "contain an entry for the app server '", app.server, "'"))
  }

  # Connect to database
  db.channel <- try(odbcConnect(server.name), silent=TRUE)
  if (!inherits(db.channel, "RODBC")) {
    stop(paste("Unable to connect to database:", as.character(db.channel)))
  }
  return (db.channel)
}


# Uploads a dataframe as a database table, deleting all rows currently in the
# table
#
# Args:
#   Data: Data frame to upload
#   table.name: Name of the database table to which the dataframe is to be
#     uploaded. This should be the name of the table only, for example
#     V_W_MY_TABLE rather than HM_DM_WRK_OWNER.V_W_MY_TABLE
upload_as_db_table <- function(Data, table.name, log_con) {
  channel <- connect_to_database()
  table.name <- paste0(DATABASE.NAME, ".", table.name)

  # First try clearing data from existing db tables
  result <- try(sqlQuery(channel, paste("delete from", table.name)),
                silent=TRUE)
  
  # If error in clearing data, write message to the log
  if (inherits(result, "try-error")) { # Error clearing data from db tables
    cat("ERROR clearing existing data from database table", table.name, ":", 
        as.character(result), "\n", file = log_con)
  } else { # If successfully cleared data
    
    # Write message to log that data cleared from existing db table
    cat("Existing data successfully cleared from database table", table.name, 
        "\n", file = log_con)
    
    # Try uploading new data to db table
    result <- try(sqlSave(channel, Data, table.name, append=TRUE, rownames=FALSE),
                  silent=TRUE)
    
    # If error in uploading data, write message to the log
    if (inherits(result, "try-error")) { # Error uploading data to db tables
      cat("ERROR uploading dataframe to database table", table.name, ":", 
          as.character(result), "\n", file = log_con)
    } else { # If successfully uploaded data
      
      # Write message to log that data uploaded to db table
      cat("New data successfully uploaded to database table", table.name, 
          "\n", file = log_con)
    }
  }
  # close db connection
  try(close(channel), silent = TRUE)
}





