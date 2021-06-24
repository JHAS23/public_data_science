#!/bin/bash

########################################################################
# Name:        SH_QC_MASTER.sh
#
# Description: Master Script to call all modules related to Site Health Qc    
# Notes:     o This is used call all modules related to Site Health QC and 
#              send out failure mails if any of the script call fails.
#              this script takes input parameter , 1 for calling the QC scripts
#              for pre processing and 2 for the actual call
#              Log file name is source from config.sh
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################


timestmp=`date +%d-%m-%Y`
 





curr_mon_profile_rep=con_profile_report_${timestmp}.csv

curr_mon_profile_rep_tmp=con_profile_report_${timestmp}_tmp.csv

touch $PROFILE_DIR/$curr_mon_profile_rep_tmp

cd $scipt_dir

echo " QC MASTER SCRIPT STARTED  AT : $timestmp " >> $LOG_FILE

if [ $# -lt 1 ];
  then
    echo "No arguments supplied to QC MASTER SCRIPT " >> $LOG_FILE
   exit 1
fi


echo "PROFILE_ID|VIEW_NAME|COLUMN_NAME|DATA_TYPE|PROFILE_TYPE|VALUE|INS_DATE" > $PROFILE_DIR/$curr_mon_profile_rep

echo "Started Generating Profile Report at : $timestmp  " >> $LOG_FILE

# call profile generation script for each view  in view_list.txt file present in scripts directory 

while read line
do

sh $scipt_dir/Gen_Profile_Rep.sh $line  $curr_mon_profile_rep_tmp  >&  $log_temp




# exit on error and send mail to users

if [ $? -gt 0 ]; then 

cat $log_temp >> $LOG_FILE

echo "Dear Recipient:" > $bdy_fail
printf "\n" >>  $bdy_fail
echo "SITE HEALTH QC FAILED at profile Report script, Please find attached QC Log FILE" > $bdy_fail



cat  $bdy_fail | mailx -s "SITE HEALTH QC FAILED on $timestmp" -a $LOG_FILE ${mail_recp}

rm -f $PROFILE_DIR/$curr_mon_profile_rep $PROFILE_DIR/$curr_mon_profile_rep_tmp

exit 1


fi

done < $scipt_dir/view_list.txt


echo " Profile Report script ended at : $timestmp  " >> $LOG_FILE

# format report file

awk '{ print FNR "|" $0 }' $PROFILE_DIR/$curr_mon_profile_rep_tmp >> $PROFILE_DIR/$curr_mon_profile_rep

rm -f $PROFILE_DIR/$curr_mon_profile_rep_tmp

# call threshold report script

sh $scipt_dir/Gen_threshold_Rep.sh   >&  $log_temp




# exit on error and send mail to users

if [ $? -gt 0 ]; then 

cat $log_temp >> $LOG_FILE


echo "Dear Recipient:"  > $bdy_fail
printf "\n" >>  $bdy_fail
echo "SITE HEALTH QC FAILED at threshold Report script, Please find attached QC Log FILE" >> $bdy_fail

rm -f    $PROFILE_DIR/Threshold_Report_*


cat  $bdy_fail | mailx -s "SITE HEALTH QC FAILED on $timestmp" -a $LOG_FILE ${mail_recp}

 

exit 1


fi




# call qc status mail script 

sh $scipt_dir/Send_QC_Status_Mail.sh  >&  $log_temp

# exit on error and send mail to users


if [ $? -gt 0 ]; then 

cat $log_temp >> $LOG_FILE

echo "Dear Recepient:"  > $bdy_fail
printf "\n" >> $bdy_fail
echo "SITE HEALTH QC FAILED, Please find attached QC Log FILE" > $bdy_fail


cat  $bdy_fail | mailx -s "SITE HEALTH QC FAILED on $timestmp" -a $LOG_FILE ${mail_recp}





exit 1


fi









echo " QC MASTER SCRIPT ENDED  AT : $timestmp " >> $LOG_FILE



echo " QC MASTER FOR R CALL STARTED AT : $timestmp " >> $LOG_FILE


# call r module script

if [ $1 -eq 1 ]; then 

echo " Pre_Call_R_Modules.sh STARTED AT : $timestmp " >> $LOG_FILE

sh $scipt_dir/Pre_Call_R_Modules.sh  >&  $log_temp

# exit on error and send mail to users

if [ $? -gt 0 ]; then 

 

cat $log_temp >> $LOG_FILE


echo " QC MASTER FOR R CALL FAILED AT Pre_Call_R_Modules.sh SCRIPT" >> $LOG_FILE

echo "Dear Recipient" > $bdy_fail
printf "\n"  >> $bdy_fail
echo "SITE HEALTH QC FAILED at R call,Please find attached QC Log FILE" >> $bdy_fail

cat  $bdy_fail | mailx -s "SITE HEALTH QC FAILED AT Pre_Call_R_Modules.sh SCRIPT" -a $LOG_FILE ${mail_recp}

sh $scipt_dir/Archive_Files.sh

exit 1

else 

echo " Pre_Call_R_Modules.sh ended AT : $timestmp " >> $LOG_FILE



fi





else

echo " Call_R_Modules.sh STARTED AT : $timestmp " >> $LOG_FILE

sh $scipt_dir/Call_R_Modules.sh  >&  $log_temp


# exit on error and send mail to users

if [ $? -gt 0 ]; then 



cat $log_temp >> $LOG_FILE

echo " QC MASTER FOR R CALL FAILED AT Call_R_Modules.sh SCRIPT" >> $LOG_FILE




echo "Dear Recipient:"  > $bdy_fail

printf "\n" >> $bdy_fail

echo "SITE HEALTH QC FAILED at R call , Please find attached QC Log FILE" >> $bdy_fail



cat  $bdy_fail | mailx -s "SITE HEALTH QC FAILED FAILED AT Call_R_Modules.sh SCRIPT $timestmp" -a $LOG_FILE ${mail_recp}

sh $scipt_dir/Archive_Files.sh

exit 1

else

echo " Call_R_Modules.sh ended AT : $timestmp " >> $LOG_FILE


fi


fi







# call  r status check

sh $scipt_dir/R_Status_Check.sh  >&  $log_temp

# exit on error and send mail to users

if [ $? -gt 0 ]; then 

cat $log_temp >> $LOG_FILE

echo " QC MASTER FOR R CALL FAILED AT R_Status_Check.sh SCRIPT" >> $LOG_FILE

echo "Dear Recipient:" 'SITE HEALTH QC FAILED at R status check script,' ' Please find attached QC Log FILE' > $bdy_fail

printf "\n" >> $bdy_fail

echo "SITE HEALTH QC FAILED at R status check script" >> $bdy_fail


cat  $bdy_fail | mailx -s "SITE HEALTH QC R CALL FAILED at R status check $timestmp" -a $LOG_FILE ${mail_recp}

sh $scipt_dir/Archive_Files.sh

exit 1


fi


# call archive script 


echo " Archive_Files.sh Script STARTED AT : $timestmp " >> $LOG_FILE

sh $scipt_dir/Archive_Files.sh  >&  $log_temp

# exit on error and send mail to users

if [ $? -gt 0 ]; then 

cat $log_temp >> $LOG_FILE

echo " QC MASTER FOR R CALL FAILED AT Archive_Files.sh SCRIPT" >> $LOG_FILE

echo  "Dear Recipient:" 'SITE HEALTH QC FAILED at Archival script,' ' Please find attached QC Log FILE' > $bdy_fail

printf "\n" >> $bdy_fail

echo  "SITE HEALTH QC FAILED at Archival script, Please find attached QC Log FILE" >> $bdy_fail



cat  $bdy_fail | mailx -s "SITE HEALTH QC R CALL FAILED at archival step on $timestmp" -a $LOG_FILE ${mail_recp}

exit 1


fi


echo " Archive_Files.sh Script Ended AT : $timestmp " >> $LOG_FILE







echo " QC MASTER FOR R CALL ENDED : $timestmp" >> $LOG_FILE

















