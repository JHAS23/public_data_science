#!/bin/bash
########################################################################
# Name:        config.sh
#
# Description: Script to create config.sh script to set environment 
#              variables.
#
# Notes:     o This is used to create a simple environment script that
#              tools such as UC4 can call prior to using the pmcmd
#              command to launch workflows.
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
########################################################################


##############################################################################
# set oracle related variables 
#########################################################################

  export ORACLE_BASE=/app/oracle 
 
 ORACLE_HOME=$ORACLE_BASE/product/11.2.0.2_64 
 export ORACLE_HOME
 ORACLE_SID=ORCL 
 export ORACLE_SID
 PATH=$ORACLE_HOME/bin:$PATH 
 export PATH
 LD_LIBRARY_PATH=$ORACLE_HOME/lib 
 export LD_LIBRARY_PATH
export mail_recp="DL-CTO-SiteHealthSupport@pfizer.com DL-BUS-SiteHealth@pfizer.com"
export mail_recp_bus="DL-CTO-SiteHealthSupport@pfizer.com DL-BUS-SiteHealth@pfizer.com"
dat=`date +%d-%m-%Y`


export LOG_FILE=/app/r/engine/SH_QC/Log/QC_MASTER_Log_$dat.txt



#source  profile for running R scripts

source /app/hmuser/.bash_profile



# Bring in environment configuration
source /app/r/engine/setenv.sh

# Bring in common functions, for logging and ODBC config
source /app/r/engine/common.sh


export DB_CRED="$HM_ALGO_DB_USER/$HM_ALGO_DB_PASSWD@$HM_ALGO_DB_SERVER";


export spool_file=/app/r/engine/SH_QC/Log/spool.txt

export curr_dir=/app/r/engine/SH_QC

export bdy_fail=$curr_dir/Temp/fail.txt

export bdy_succ=$curr_dir/Temp/succ.txt

export PROFILE_DIR=/app/r/engine/SH_QC/PROCESS





####################################VARIABLES FOR PROFILE REPORT SCRIPT#################


export PROFILE_DIR_TMP=/app/r/engine/SH_QC/Temp




#######################################################################################


#######################variables for arcive script#################################




export proc_folder=$curr_dir/PROCESS
export arc_folder=$curr_dir/ARCHIVE


#######################################################################################


######################################## variables for qc status mail script ########################



############################################################################################################


############################################ variables for threshold report script #########################################




#export curr_moth_genth=`ls -alt $curr_dir/PROCESS/con_profile_report* | head -1 | sed 's/:[0-9][0-9]/,/' |  tr -d ' \t\n\r\f' | cut -d',' -f2`
#export prev_month_genth=`ls -alt $curr_dir/PROCESS/con_profile_report* | tail -1 | sed 's/:[0-9][0-9]/,/' |  tr -d ' \t\n\r\f' | cut -d',' -f2`
#export rule_file=$curr_dir/Scripts/Threshold_Rules.csv
#export curr_mon_file=`echo $curr_moth_genth |  tr -d ' \t\n\r\f'`
#export prev_mon_file=`echo $prev_month_genth |  tr -d ' \t\n\r\f'`
#export first_run=`ls $proc_folder/con_profile_report* | wc -l`



##############################################################################################################################



############################ variables for R status check #########################################################################3333



export R_dir=/app/r/engine/Log/Module_success_indicators



export arc_folder=/app/r/engine/SH_QC/ARCHIVE






##########################################################################################################################################


###################################### VARIABLES FOR CALL r script #############################################################

export R_Dir=/app/r/R-3.0.2/bin
export R_Engine=/app/r/engine


########################################################################################################################




################################################# variable for master Script ####################################################

export log_temp=/app/r/engine/SH_QC/Log/log.txt

export scipt_dir=$curr_dir/Scripts

################################################################################################################################













 

