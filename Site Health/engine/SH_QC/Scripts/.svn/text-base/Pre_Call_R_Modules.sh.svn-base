#!/bin/bash


########################################################################
# Name:        Pre_Call_R_Modules.sh
#
# Description: Script to call R modules     
# Notes:     o This is used to call R Modules based on the status of work area
#               QC .
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################







dat=`date +%d-%m-%Y_%H:%M:%S`




#source /app/hmuser/.bash_profile


# take count of critical errors in threshold report file for each module


SAE_critical_fail=`grep SA_CRITICAL_FAIL $file_path | wc -l`
RT_critical_fail=`grep TO_CRITICAL_FAIL $file_path | wc -l`
PD_critical_fail=`grep PD_CRITICAL_FAIL $file_path | wc -l`
TL_critical_fail=`grep TL_CRITICAL_FAIL $file_path | wc -l`
OH_critical_fail=`grep OH_CRITICAL_FAIL $file_path | wc -l`

file_path=$curr_dir/PROCESS/Threshold_Report_[0-9]*.csv

#source /app/hmuser/.bash_profile

cd $R_Engine


# if there are critical errors in all modules exit script with exitc code 3


if [ $SAE_critical_fail -gt 0  -a $PD_critical_fail -gt 0 -a $RT_critical_fail -gt 0  -a $OH_critical_fail -gt 0  -a $TL_critical_fail -gt 0  ]; then



echo "DATA ISSUES IN WORK AREA TABLES RELATED TO ALL MODELS UC4 EXECUTION STOPPED"  >> $LOG_FILE


exit 3


# if there no critical errors in work area views for all modules call R Main and execute all modules


elif [ $SAE_critical_fail -eq 0  -a $PD_critical_fail -eq 0 -a $RT_critical_fail -eq 0  -a $OH_critical_fail -eq 0  -a $TL_critical_fail -eq 0  ]; then

  echo " Call R Main module"  >> $LOG_FILE


  /app/r/R-3.0.2/bin/Rscript main.R SH TL TO PD SA BENCHMARK


else


# cal individual modules if there are no critical data errors realated to SA,TL,PD,T moduleS in work area views
# ELSE PART WILL BE EXECUTED IF THERE ARE CRITICAL ERRORS RELATED TO SOME MODULES BUT OTHER MODULES HAVE NO CRITICAL ERRORS AND THEY CAN BE EXECUTED


     if [ $SAE_critical_fail -eq 0  ]; then

         echo "call SAE MODULE"  >> $LOG_FILE


         /app/r/R-3.0.2/bin/Rscript main.R SA
      fi

 
      if [ $PD_critical_fail -eq 0   ]; then

         echo "call PD MODULE"  >> $LOG_FILE

         /app/r/R-3.0.2/bin/Rscript main.R PD

      fi



      if [ $RT_critical_fail -eq 0   ]; then

         echo "call RT MODULE"  >> $LOG_FILE

         /app/r/R-3.0.2/bin/Rscript main.R TO

      fi


      
     
      if [ $TL_critical_fail -eq 0   ]; then

         echo "call TL MODULE"  >> $LOG_FILE

         /app/r/R-3.0.2/bin/Rscript main.R TL

      fi

     if [ $OH_critical_fail -eq 0   ]; then

         echo "call SH MODULE"  >> $LOG_FILE

         /app/r/R-3.0.2/bin/Rscript main.R SH

      fi


        
          


fi





















