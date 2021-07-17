#!/bin/bash
########################################################################
# Name:        hm_runsql.sh
#
# Description: Script to run SQL script with logon from file.
#
# Parameters:  p1
#                SQL script
#
#              p2...pn
#                Passed to SQL script
#
# Returns:     0 if script succeded; 1 if script failed
#
# Notes:     o Basic environment settings are stored in setenv.sh file.
#            o Database TNSName identifier (e.g. enid195.pfizer.com) is
#              found in database.name file.
#            o Database identifier is used to look up an environment
#              section in odbc.ini file.
#            o SQL Script name is relative to home directory.
#            o SQL parameters must be quoted if they have spaces.
#              Normally quotes are stripped by the shell, so if you
#              need to pass "My Param" you should use '"My Param"' or
#              "\"My Param\""
#
# Usage:       hm_runsql.sh myfile.sql
#
# Author:      Tad Harrison
# Date:        2014-06-09
########################################################################
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILENAME=$(basename "$0")
TODAY=$(date +"%Y%m%d")
LOGFILENAME="${LOGFILENAME%.*}.$TODAY"
ROOT_DIR=$MYDIR
SQL_DIR="$ROOT_DIR/sql"
LOG_DIR="$ROOT_DIR/logs"
SCRIPT_DIR=$ROOT_DIR
LOGFILE="$LOG_DIR/$LOGFILENAME.log"

# Make sure log is world RW
umask 0000

# Bring in environment configuration
source "$SCRIPT_DIR/setenv.sh"

# Bring in common functions, for logging and ODBC config
source "$SCRIPT_DIR/common.sh"

exec 3>>$LOGFILE

# Verify number of args
[[ $# -lt 1 ]] && { log_error "Usage: $0 config-script sql-script" ; exit 1; }

# Verify argument values
SQL="$1"
SQL_SCRIPT="$SQL_DIR/$SQL"

[[ -z $SQL ]] && { log_error "SQL script was not provided" ; exit 1; }
[[ ! -f $SQL_SCRIPT ]] && { log_error "SQL script $SQL_SCRIPT not found." ; exit 1; }

# Consume argument
shift

# Get configured database from database.name file
# This file is used by R and by scripts to determine which environment
# to use. The file contains one line, an Oracle TNSNames name.

sid=$(head -n 1 "$SCRIPT_DIR/database.name")

# Load named section of odbc.ini file into environment
readconf "$sid"

log_info "Running $SQL_SCRIPT as $HM_ALGO_DB_USER on $HM_ALGO_DB_SERVER in $ENVIRONMENT."

[ $# -gt 0 ] && log_info "Arguments: $@"

# Make sure a nonzero error in pipe is propagated through pipe
set -o pipefail

###################################################################
# SQL: Begin
##################################################################

# Go to SQL directory in case script has includes
pushd $SQL_DIR > /dev/null

# Run SQL*Plus
#
#  -silent
#     Silent mode, without prolog/postlog output
#
#  /nolog
#     Don't prompt for login
#
#  <<SQL_EOT
#     A here-doc with payload for SQL*Plus. This contains the basic
#     configuration, connection, and the call to the provided SQL
#     script with any additional args.
#
#  "2>&1 | tee > (cat >>$LOGFILE)" 
#     This combines STDOUT and STDERR and then sends a copy of this
#     combined stream to STDOUT and the log file. By doing this, log
#     output is captured, but STDOUT is visible to user and UC4 can
#     capture the output.
#
sqlplus -silent /nolog 2>&1 <<SQL_EOT 2>&1 | tee >(cat >>$LOGFILE)
set verify off
set feedback off
connect $HM_ALGO_DB_USER@$HM_ALGO_DB_SERVER/$HM_ALGO_DB_PASSWD
@$SQL_SCRIPT $@
SQL_EOT

# Grab error code before anything else
ERRORCODE=$?

# Go back to where we came from
popd >/dev/null

###################################################################
# SQL: End
###################################################################

#Check the return code from SQL Plus
if [ $ERRORCODE != 0 ]
then
  log_error "SQL execution failed with error code $ERRORCODE"
else
  log_info "SQL execution ran successfully. "
fi
exit $ERRORCODE
