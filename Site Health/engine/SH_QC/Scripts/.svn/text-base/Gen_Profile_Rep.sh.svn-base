#!/bin/bash
########################################################################
# Name:        Gen_Profile_Rep.sh
#
# Description: Script to generate profile report for current month on  
#              top of work area views.
#
# Notes:     o This is used to create profile report csv file in process directory.
#              This script takes view name as the first parameter and 
#              profile report file name as second parameter
#              Log File is sourced from config.sh
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################








timestmp=`date +%d-%m-%Y`

rm -f $PROFILE_DIR_TMP/PROFILE_REP*.csv

# create zero byte files which are used for temporary processing

touch  $PROFILE_DIR_TMP/PROFILE_REP_date.csv $PROFILE_DIR_TMP/PROFILE_REP_num.csv $PROFILE_DIR_TMP/PROFILE_REP_char.csv $PROFILE_DIR_TMP/PROFILE_REP_id.csv $PROFILE_DIR_TMP/PROFILE_REP_tot_count.csv $PROFILE_DIR_TMP/PROFILE_REP_char_dis.csv


# check for oracle home 


if [  -z "$ORACLE_HOME" ]; then

echo "ORACLE HOME NOT SET " >> $LOG_FILE

exit 1
 
fi

# if the two required parameters are not passed to the script exit 




if [ $# -lt 2 ];
  then
    echo "No arguments supplied" >> $LOG_FILE
   exit 1
fi

# take out table name from the first argument as the argument is in the format schema_name.table_name

tab_name=`echo $1 | cut -d'.' -f2`

# Connect to database and pull metadata for the view provided


view_col_array_site=($($ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
spool $PROFILE_DIR_TMP/temp.csv
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF;
SELECT TABLE_NAME||','||COLUMN_NAME||','||DATA_TYPE  FROM all_TAB_COLUMNS WHERE table_name = '$tab_name' and owner='HM_DM_WRK_OWNER';
COMMIT;
exit
EOF
))

# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi



view_col_array_site_len=${#view_col_array_site[@]}

# for each column in the view generate profile


for (( i=0; i<${view_col_array_site_len}; i++ ));do

data_type=`echo ${view_col_array_site[$i]} | cut -d',' -f3`
col_name=`echo ${view_col_array_site[$i]} | cut -d',' -f2`

# generate profile for Date columns

if [ "$data_type" == "DATE" ]; then
$ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
SET COLSEP "|"
SET FEEDBACK OFF
SET LINESIZE 3000
SET ECHO OFF
SET HEADING OFF
spool $PROFILE_DIR_TMP/temp1.csv
with temp_table as 
(select count(*) count from  $1  where $col_name is null)
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'MAX OF COLUMN'||'|'||max($col_name)||'|'||SYSDATE from $1
union
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'MIN OF COLUMN'||'|'||MIN($col_name)||'|'||SYSDATE from $1
union
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'RANGE OF COLUMN'||'|'||to_char(max($col_name)-min($col_name))||'|'||SYSDATE from $1
UNION
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'NULL COUNT'||'|'||count||'|'||SYSDATE from temp_table;
COMMIT;
SPOOL OFF
exit
EOF

# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp1.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi

cat $PROFILE_DIR_TMP/temp1.csv >> $PROFILE_DIR_TMP/PROFILE_REP_date.csv

fi

# generate profile for numeric  columns which are not id 

echo $col_name | grep ID
str_cmp3=$?

#echo $col_name | grep NUMBER
#str_cmp6=$?


if [ $str_cmp3 -eq 1  ]; then

if [ "$data_type" == "NUMBER" -o  "$data_type" == "INTEGER" ]; then
$ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
SET COLSEP "|"
SET FEEDBACK OFF
SET LINESIZE 3000
SET ECHO OFF
SET HEADING OFF
spool $PROFILE_DIR_TMP/temp2.csv
with temp_table as 
(select count(*) atr_count from  $1  where $col_name is null)
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'MAX OF COLUMN'||'|'||max($col_name)||'|'||SYSDATE from $1
union
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'MIN OF COLUMN'||'|'||MIN($col_name)||'|'||SYSDATE from $1
union
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'AVERAGE OF COLUMN'||'|'||avg(TO_NUMBER($col_name))||'|'||SYSDATE from $1
UNION
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'MEDIAN OF COLUMN'||'|'||median(TO_NUMBER($col_name))||'|'||SYSDATE from $1
union
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'NULL COUNT'||'|'||atr_count||'|'||SYSDATE from temp_table;
COMMIT;
SPOOL OFF
exit
EOF

# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp2.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi

cat $PROFILE_DIR_TMP/temp2.csv >> $PROFILE_DIR_TMP/PROFILE_REP_num.csv

fi

fi


# generate profile for varchar  columns which are not id columns

echo $col_name | grep NUMBER
str_cmp1=$?


echo $col_name | grep ID
str_cmp2=$?

if [ $str_cmp1 -eq 1 -a $str_cmp2 -eq 1 ]; then

if [ "$data_type" == "CHAR" -o "$data_type" == "VARCHAR2" -o "$data_type" == "VARCHAR"  ]; then

$ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
SET COLSEP "|"
SET FEEDBACK OFF
SET LINESIZE 3000
SET ECHO OFF
SET HEADING OFF
spool $PROFILE_DIR_TMP/temp3.csv
with temp_table as 
(select count(*) atr_count from  $1  where $col_name is null)
select '$1','$col_name','$data_type','NULL COUNT',atr_count,SYSDATE from temp_table;
COMMIT;
SPOOL OFF
exit
EOF


# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp3.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi

cat $PROFILE_DIR_TMP/temp3.csv >> $PROFILE_DIR_TMP/PROFILE_REP_char.csv

fi

fi

# generate profile for category columns


if [ "$col_name" == "STUDY_THERAPEUTIC_AREA" -o "$col_name" == "COUNTRY_NAME" -o "$col_name" == "DEVELOPMENT_PHASE" -o "$col_name" == "STUDY_STATUS_CURRENT"  ]; then


if [ $str_cmp1 -eq 1 -a $str_cmp2 -eq 1 ]; then

if [ "$data_type" == "CHAR" -o "$data_type" == "VARCHAR2" -o "$data_type" == "VARCHAR"  ]; then

$ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
SET COLSEP "|"
SET FEEDBACK OFF
SET LINESIZE 3000
SET ECHO OFF
SET HEADING OFF
spool $PROFILE_DIR_TMP/temp8.csv
with temp_table as 
(select distinct $col_name atr_name, count(*) over (partition by $col_name) atr_count from $1)
select '$1'||'|'||'$col_name'||'|'||'$data_type'||'|'||'COUNT OF: '||nvl(atr_name,'NULL')||'|'||atr_count||'|'||SYSDATE from temp_table where atr_name is not null;
COMMIT;
SPOOL OFF
exit
EOF


# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp8.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi


cat $PROFILE_DIR_TMP/temp8.csv >> $PROFILE_DIR_TMP/PROFILE_REP_char_dis.csv

fi

fi

fi



# generate profile for ID columns


echo $col_name | grep ID
str_cmp4=$?

if [ $str_cmp4 -eq 0 -a "$data_type" == "NUMBER" ]; then



$ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
SET COLSEP "|"
SET FEEDBACK OFF
SET LINESIZE 3000
SET ECHO OFF
SET HEADING OFF
spool $PROFILE_DIR_TMP/temp4.csv
with temp_table as 
(select count(*) atr_count from  $1  where $col_name is null),
temp_table2 as 
(select count(distinct $col_name) dist_count from  $1)
select '$1','$col_name','$data_type','UNIQUE KEY COUNT',dist_count,SYSDATE from temp_table2
union
select '$1','$col_name','$data_type','NULL COUNT',atr_count,SYSDATE from temp_table;
COMMIT;
SPOOL OFF
exit
EOF

# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp4.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi

cat $PROFILE_DIR_TMP/temp4.csv >> $PROFILE_DIR_TMP/PROFILE_REP_id.csv

fi











done

# generate profile for count of records in the view

$ORACLE_HOME/bin/sqlplus -s $DB_CRED << EOF
SET COLSEP "|"
SET FEEDBACK OFF
SET LINESIZE 3000
SET ECHO OFF
SET HEADING OFF
spool $PROFILE_DIR_TMP/temp5.csv
with temp_table as 
(select count(*) rec_count from  $1 )
select '$1','NA','NA','RECORD COUNT',rec_count,SYSDATE from temp_table;
COMMIT;
SPOOL OFF
exit
EOF


# if sql fails log error and exit

if [   $? -ne 0  ]; then
cat $PROFILE_DIR_TMP/temp5.csv >> $LOG_FILE
echo " Profile Report Sql failed  " >> $LOG_FILE
exit 1
fi

cat $PROFILE_DIR_TMP/temp5.csv >> $PROFILE_DIR_TMP/PROFILE_REP_tot_count.csv

rm -f $PROFILE_DIR_TMP/temp*.csv

# consolidate profiles created for each data type into a temp file


touch $PROFILE_DIR_TMP/PROFILE_REP_temp.csv


cat $PROFILE_DIR_TMP/PROFILE_REP_date.csv  >> $PROFILE_DIR_TMP/PROFILE_REP_temp.csv

cat $PROFILE_DIR_TMP/PROFILE_REP_num.csv >> $PROFILE_DIR_TMP/PROFILE_REP_temp.csv

cat $PROFILE_DIR_TMP/PROFILE_REP_char.csv >> $PROFILE_DIR_TMP/PROFILE_REP_temp.csv

cat $PROFILE_DIR_TMP/PROFILE_REP_char_dis.csv >> $PROFILE_DIR_TMP/PROFILE_REP_temp.csv

cat $PROFILE_DIR_TMP/PROFILE_REP_id.csv >> $PROFILE_DIR_TMP/PROFILE_REP_temp.csv

cat $PROFILE_DIR_TMP/PROFILE_REP_tot_count.csv >> $PROFILE_DIR_TMP/PROFILE_REP_temp.csv


# format the columns and transfer the profile report to csv file which is passed as second parameter to the script


sed '/^$/d' $PROFILE_DIR_TMP/PROFILE_REP_temp.csv  | sed 's/HM_DM_WRK_OWNER.//'  >> $PROFILE_DIR/$2







