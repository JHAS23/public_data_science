#!/bin/bash
########################################################################
# Name:        hm_sendmail.sh
#
# Description: Script to send notification email.
#
# Parameters:  p1
#                workflow name
#              p2
#                status (SUCCESS | ERROR)
#              p3
#                message
#
# Returns:     0 if script succeded; 1 if script failed
#
# Notes:     o Basic environment settings are stored in setenv.sh file.
#            o Database TNSName identifier (e.g. enid195.pfizer.com) is
#              found in database.name file.
#            o This identifier is converted to an environment name
#              using an array from setenv.sh.
#
# Usage:       hm_sendmail.sh wf_ALGO_Main SUCCESS
#
# Author:      Tad Harrison
# Date:        2014-06-09
########################################################################
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILENAME=$(basename "$0")
TODAY=$(date +"%Y%m%d")
LOGFILENAME="${LOGFILENAME%.*}.$TODAY"
ROOT_DIR=$MYDIR
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
[[ $# -lt 2 ]] && { log_error "Usage: $0 workflow {SUCCESS|ERROR} [message]" ; exit 1; }

WORKFLOW=$1
WORKFLOW_STATUS=$2
WORKFLOW_MESSAGE=$3

# Verify argument values
[[ -z $WORKFLOW ]] && { log_error "Workflow was not provided" ; exit 1; }
[[ $WORKFLOW_STATUS == 'SUCCESS' || $WORKFLOW_STATUS == 'ERROR' ]] || { log_error "Workflow status must be SUCCESS or ERROR" ; exit 1; }

case $WORKFLOW_STATUS in
SUCCESS)
  RECIPIENTS=$PMSuccessEmailUser
  MESSAGE="ran successfully"
  ;; 
*)
  RECIPIENTS=$PMFailureEmailUser
  MESSAGE="failed with errors"
  ;;
esac

# Get configured database from database.name file
# This file is used by R and by scripts to determine which environment
# to use. The file contains one line, an Oracle TNSNames name.
sid=$(head -n 1 "$SCRIPT_DIR/database.name")

# Load named section of odbc.ini file into environment
# This will give us a value for $ENVIRONMENT
readconf "$sid"

mailx -s "[$WORKFLOW_STATUS] ${ENVIRONMENT} Site Health Algorithms $MESSAGE" -r '"Site Health R Server" <hmuser>' $RECIPIENTS <<EOT
The $WORKFLOW workflow of Site Health $MESSAGE.
$WORKFLOW_MESSAGE
Server: $(hostname)
Environment: $ENVIRONMENT
Workflow: $WORKFLOW

==============================================================
Note: This is a system-generated message.

If you do not wish to receive these messages, please contact the distribution list owner. Right-click on the distribution list in Outlook and select "Outlook Properties" in order to see the owner.
EOT
