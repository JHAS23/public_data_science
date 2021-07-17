#!/bin/bash


########################################################################
# Name:        Send_QC_Status_Mail.sh
#
# Description: Script to send QC status      
# Notes:     o This is used to send status files based on the threshhold file.
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################




file_path=$curr_dir/PROCESS/Threshold_Report_[0-9]*.csv


#file_path=$curr_dir/PROCESS/Threshold_Report_[0-9]*.csv



dat=`date +%d-%m-%Y`




# take critical fail count for each module in threshold report


SAE_critical_fail=`grep SA_CRITICAL_FAIL $file_path | wc -l`
RT_critical_fail=`grep TO_CRITICAL_FAIL $file_path | wc -l`
PD_critical_fail=`grep PD_CRITICAL_FAIL $file_path | wc -l`
TL_critical_fail=`grep TL_CRITICAL_FAIL $file_path | wc -l`
OH_critical_fail=`grep OH_CRITICAL_FAIL $file_path | wc -l`



count_critical_error=`expr $SAE_critical_fail + $RT_critical_fail + $PD_critical_fail  + $TL_critical_fail + $OH_critical_fail`

# take optional & critical fail count for each module in threshold report

cnt_optional_fail=`grep OPTIONAL_FAIL $file_path | wc -l`
cnt_CRITICAL_fail=`grep CRITICAL_FAIL $file_path | wc -l`






# if critical errors are found in work area views realted to all R module then send out mail saying QC failed and stop execution 


if [ $SAE_critical_fail -gt 0  -a $PD_critical_fail -gt 0 -a $RT_critical_fail -gt 0  -a  $OH_critical_fail -gt 0  -a $TL_critical_fail -gt 0 ]; then


echo "DATA ISSUES IN WORK AREA TABLES RELATED TO ALL MODELS UC4 EXECUTION STOPPED" >> $LOG_FILE

 echo "Dear Recipient:" > $bdy_fail
 printf "\n" >> $bdy_fail
 echo "QC on work area views failed, please find attached threshold report and QC master Log." >> $bdy_fail
 printf "\n" >> $bdy_fail
 echo " Optional fail count (errors on columns that are not critical to the algorithms):  " $cnt_optional_fail >> $bdy_fail
 echo  " Critical fail count (errors on columns that are critical to the algorithms):" $cnt_CRITICAL_fail >> $bdy_fail 
 


cat  $bdy_fail | mailx -s "Site Health work area views QC failed on $dat" -a $file_path -a $LOG_FILE ${mail_recp}




exit 3

fi

# if few of the modules have critical or optional errors then send out a mail saying QC completed with errors

if [ $cnt_optional_fail -gt 0 -o $cnt_CRITICAL_fail -gt 0 ]; then


  

         echo  " Dear Recipient:" > $bdy_succ
         printf "\n" >> $bdy_succ
         echo " QC on work area views completed with errors, please find attached threshold report and QC master Log." >> $bdy_succ
         printf "\n" >> $bdy_succ
         
         echo  " Optional fail count (errors on columns that are not critical to the algorithms):  " $cnt_optional_fail >> $bdy_succ
         echo  " Critical fail count (errors on columns that are critical to the algorithms):" $cnt_CRITICAL_fail >> $bdy_succ

         cat  $bdy_succ | mailx -s "Site Health work area QC completed with errors on $dat" -a $file_path -a $LOG_FILE ${mail_recp}

fi

# if none of the modules have critical or optional errors then send out a mail saying QC completed with no errors


if [ $cnt_optional_fail -eq 0 -a $cnt_CRITICAL_fail -eq 0 ]; then

         echo "Dear Recipient:"  > $bdy_succ
         printf "\n" >> $bdy_succ

         echo "QC on work area views completed successfully, please find attached threshold report and QC master Log." >> $bdy_succ


         cat  $bdy_succ | mailx -s "Site Health work area QC completed successfully on $dat" -a $file_path -a $LOG_FILE  ${mail_recp} 


fi





















