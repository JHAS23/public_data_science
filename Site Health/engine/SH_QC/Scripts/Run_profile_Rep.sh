#!/bin/bash

########################################################################
# Name:        SH_QC_MASTER.sh
#
# Description: Master Script to call all modules related to Site Health Qc    
# Notes:     o This is used call all modules related to Site Health QC and 
#              send out failure mails if any of the script call fails.
#              this script takes input parameter , 1 for calling the QC scripts
#              for pre processing and 2 for the actual call
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################


source $curr_dir/Scripts/config.sh

#curr_dir=/app/r/engine/SH_QC
#PROFILE_DIR=$curr_dir/PROCESS
scipt_dir=$curr_dir/Scripts
timestmp=`date +%d-%m-%Y`

Log_File=$curr_dir/Log/QC_Log_${timestmp}.txt










rm -f $Log_File

touch $Log_File



curr_mon_profile_rep=con_profile_report_${timestmp}.csv

curr_mon_profile_rep_tmp=con_profile_report_${timestmp}_tmp.csv

touch $PROFILE_DIR/$curr_mon_profile_rep_tmp

cd $scipt_dir




echo "PROFILE_ID|VIEW_NAME|COLUMN_NAME|DATA_TYPE|PROFILE_TYPE|VALUE|INS_DATE" > $PROFILE_DIR/$curr_mon_profile_rep



# call profile generation script for each view  in view_list.txt file present in scripts directory and send out 
# failure mail if the call fails

while read line
do

sh $scipt_dir/Gen_Profile_Rep.sh $line $curr_mon_profile_rep_tmp  >>  $Log_File

echo $line

done < $scipt_dir/view_list.txt

awk '{ print FNR "|" $0 }' $PROFILE_DIR/$curr_mon_profile_rep_tmp >> $PROFILE_DIR/$curr_mon_profile_rep

rm -f $PROFILE_DIR/$curr_mon_profile_rep_tmp