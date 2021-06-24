#!/bin/bash
########################################################################
# Name:        SH_Run_ETL_Rules.sh
#
# Description: Script to run ETL rules before Site Health QC .
#
# Notes:     o Script to run ETL rules before Site Health QC .
#              log file name is sourced from config.sh  
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################




dat=`date`

touch $spool_file





# The following rules are applied 

# Rule 1: In table wrk_tl_in_crf_data_entry_compl, if the visit count is less than the compliant count, make them both the greater of the two

# Rule 2: In table wrk_tl_in_crf_data_entry_compl, if either Visit Count or Compliant Count is null, then assign it to zero

# Rule 3 : Update YN_Excluded =Y in wrk_gl_in_clinical_study where development_phase LIKE ‘%N/A%’

# Rule 4 : Exclude subjects in wrk_gl_in_subject that have no enrollment dates

# Rule 5 : Exclude PSQRVs before 2012-01-01 

echo " STARTED APPLYING ETL RULES AT : $dat " > $LOG_FILE

# check if spool file exists

if [ -f $spool_file ]; then 

echo "SPOOL FILE CHECK PASSED" >> $LOG_FILE

else 

echo "SPOOL FILE CHECK FAILED" >> $LOG_FILE

echo "Dear Recipient:"  > $bdy_fail
printf "\n" >> $bdy_fail
echo "ETL Rules Applied on Work Area tables FAILED, Please find attached QC Master log file." >> $bdy_fail
cat  $bdy_fail | mailx -s "ETL Rules Applied on Work Area tables FAILED on $dat" -a $LOG_FILE ${mail_recp}
exit 1
 
fi


if [ ! -z "$ORACLE_HOME" ]; then

echo "ORACLE HOME SET " >> $LOG_FILE

else 

echo "ORACLE HOME NOT SET " >> $LOG_FILE

echo "Dear Recipient:"  > $bdy_fail
printf "\n" >> $bdy_fail
echo "ETL Rules Applied on Work Area tables FAILED, Please find attached QC Master log file." >> $bdy_fail
cat  $bdy_fail | mailx -s "ETL Rules Applied on Work Area tables FAILED on $dat" -a $LOG_FILE ${mail_recp}
exit 1
 
fi




$ORACLE_HOME/bin/sqlplus -s $DB_CRED <<EOF
whenever sqlerror exit sql.sqlcode;
whenever oserror exit failure;
spool $spool_file;
update HM_DM_WRK_OWNER.wrk_tl_in_crf_data_entry_compl set VISIT_COUNT=COMPLIANT_COUNT  where VISIT_COUNT < COMPLIANT_COUNT;
COMMIT;
update HM_DM_WRK_OWNER.wrk_tl_in_crf_data_entry_compl set VISIT_COUNT=0  where VISIT_COUNT is null;
COMMIT;
update HM_DM_WRK_OWNER.wrk_tl_in_crf_data_entry_compl set COMPLIANT_COUNT=0  where COMPLIANT_COUNT is null;
commit;
update HM_DM_WRK_OWNER.wrk_gl_in_clinical_study set YN_EXCLUDED='Y', excluded_reason=hm_dm_wrk_owner.append(EXCLUDED_REASON, 'Dev phase N/A') where ltrim(rtrim(DEVELOPMENT_PHASE)) LIKE 'N/A%';
commit;
delete From HM_DM_WRK_OWNER.wrk_gl_in_subject Where SUBJ_ENROLLED_STUDY_DT_DERIVED is null AND SUBJ_DISCONTINUED_DT is null AND SUBJ_COMPLETED_STUDY_DT is null;
commit;
update HM_DM_WRK_OWNER.WRK_GL_IN_OVERSIGHT_REPORTS set YN_EXCLUDED='Y', excluded_reason=hm_dm_wrk_owner.append(EXCLUDED_REASON, 'Report start before 2012') Where REPORT_START_DATE < DATE '2012-01-01';
commit;
UPDATE HM_DM_WRK_OWNER.WRK_GL_IN_CLINICAL_STUDY SET YN_VISUALIZE = 'N' WHERE YN_EXCLUDED = 'Y';
commit;
exit;
EOF

# check sql succeeded or failed


dat=`date`

if [ $? -eq 0 ]; then
echo "  ETL RULES  PASSED  AT : $dat " >> $LOG_FILE
else
cat $spool_file >> $LOG_FILE
echo " ETL RULES  FAILED    AT : $dat " >> $LOG_FILE

#send  failure mail

echo "Dear Recipient:"  > $bdy_fail

printf "\n" >> $bdy_fail

echo "ETL Rules Applied on Work Area tables FAILED, Please find attached QC Master log file." >> $bdy_fail


cat  $bdy_fail | mailx -s "ETL Rules Applied on Work Area tables FAILED on $dat" -a $LOG_FILE ${mail_recp}


exit 1 

fi


