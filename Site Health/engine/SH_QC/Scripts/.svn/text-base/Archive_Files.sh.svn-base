#!/bin/sh

########################################################################
# Name:        Archive_Files.sh
#
# Description: Script to archive previous month files  
# Notes:     o archives previous months file to arhive directory.
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################


curr_moth=`ls -alt $curr_dir/PROCESS/con_profile_report* | head -1 | sed 's/:[0-9][0-9]/,/' |  tr -d ' \t\n\r\f' | cut -d',' -f2 | cut -d'/' -f7`
prev_month=`ls -alt $curr_dir/PROCESS/con_profile_report* | tail -1 | sed 's/:[0-9][0-9]/,/' |  tr -d ' \t\n\r\f' | cut -d',' -f2 | cut -d'/' -f7`


timestmp=`date +"%m-%d-%Y"`





# MOVE PROFFILE REPORT FOR PREVIOUS MONTH AND THRESHOLD REPORT FOR CURRENT MONTH FROM PROCESS FOLDER TO ARCHIVE FOLDER

cd $proc_folder


ls | grep -v $curr_moth | while read line
do

mv -f $proc_folder/$line $arc_folder/

if [ $? -ne 0 ]; then 

echo "FILE MOVE FROM $proc_folder/$line TO $arc_folder/ FAILED " >> $LOG_FILE

exit 1

fi


done









