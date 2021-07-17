#!/bin/sh

########################################################################
# Name:        Gen_threshold_Rep.sh
#
# Description: Script to generate threshold report for comparing current month.
#               profile report with previous month profile report against
#              threshold rule file     
# Notes:     o This is used to create a threshold report with naming 
#              convention Threshold_Report_mm-dd-yyyy.csv in process directory.
#            
#
# Author:      Rajesh Mechery
# Date:        2016-10-26
# Version : 0.1
########################################################################


##############################################################################
# set  variables
#########################################################################

curr_dir=/app/r/engine/SH_QC

curr_moth=`ls -alt $curr_dir/PROCESS/con_profile_report* | head -1 | sed 's/:[0-9][0-9]/,/' |  tr -d ' \t\n\r\f' | cut -d',' -f2`
prev_month=`ls -alt $curr_dir/PROCESS/con_profile_report* | tail -1 | sed 's/:[0-9][0-9]/,/' |  tr -d ' \t\n\r\f' | cut -d',' -f2`
rule_file=$curr_dir/Scripts/Threshold_Rules.csv
proc_folder=$curr_dir/PROCESS
curr_mon_file=`echo $curr_moth |  tr -d ' \t\n\r\f'`
prev_mon_file=`echo $prev_month |  tr -d ' \t\n\r\f'`
first_run=`ls $proc_folder/con_profile_report* | wc -l`
timestmp=`date +%d-%m-%Y`

LOG_FILE=/app/r/engine/SH_QC/Log/QC_MASTER_Log_$timestmp.txt

#source /app/r/engine/SH_QC/Scripts/config.sh

rm -f  $proc_folder/Threshold_Report_$timestmp.csv


touch $proc_folder/Threshold_Report_temp.csv
touch $proc_folder/Threshold_Report_$timestmp.csv


echo "  Threshold Report SCRIPT STARTED AT : $timestmp " >> $LOG_FILE
 
echo "RULE_ID|RULE_NAME|MEASURE_TYPE|MODEL|VIEW_NAME|ATTRIBUTE_NAME|DATA_TYPE|PROFILE_TYPE|CURRENT_MONTH_VAL|PREVIOUS_MONTH_VAL|MIN_VAL|MAX_VAL|CRITICAL|RESULT"  >> $proc_folder/Threshold_Report_$timestmp.csv





echo "curr month file:"$curr_mon_file
echo "pre month file :"$prev_mon_file

# read rules in threshold rule file and execute threshold rules one by one


sed 1d $rule_file | grep -v "COUNT OF:"  | while read line
do

RULE_NAME=`echo $line | cut -d '|' -f2 | tr -d ' \t\n\r\f'` 
MEASURE_TYPE=`echo $line | cut -d '|' -f3 | tr -d ' \t\n\r\f'`
MODEL=`echo $line | cut -d '|' -f4 | tr -d ' \t\n\r\f'`
view_name=`echo $line | cut -d '|' -f5 | tr -d ' \t\n\r\f'`
col_name=`echo $line | cut -d '|' -f6 | tr -d ' \t\n\r\f'`
DATA_TYPE=`echo $line | cut -d '|' -f7 | tr -d ' \t\n\r\f'`
prof_type=`echo $line | cut -d '|' -f8 `
MIN_VAL=`echo $line | cut -d '|' -f9 | tr -d ' \t\n\r\f'`
MAX_VAL=`echo $line | cut -d '|' -f10 | tr -d ' \t\n\r\f'`
CRITICAL=`echo $line | cut -d '|' -f11 | tr -d ' \t\n\r\f'`



curr_view_rec_count=`cat $curr_mon_file  | grep -w $view_name | grep -w "NA" | grep -w "RECORD COUNT" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq `
prev_view_rec_count=`cat $prev_mon_file  | grep -w $view_name | grep -w "NA" | grep -w "RECORD COUNT" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq`
prev_mon_val=`cat $prev_mon_file  | grep -w $view_name | grep -w $col_name | grep -w "$prof_type" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq `
prev_mon_found=$?
curr_mon_val=`cat $curr_mon_file  | grep -w $view_name | grep -w $col_name | grep -w "$prof_type" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq `
curr_mon_found=$?


if [ "$CRITICAL" == "N" ]; then
CRITIC_TYPE=OPTIONAL
else
CRITIC_TYPE=CRITICAL
fi

per_mul=100

# Run if only current month profile report is present 


if [   $curr_mon_found -ne 0  ]; then

echo " current month profile report not found " >> $LOG_FILE
echo " Threshold Report SCRIPT FAILED AT : $timestmp " >> $LOG_FILE
exit 1

fi


if [   $curr_mon_found -eq 0  ]; then




# Check rule for rule type absolute check and measure type value




if [  "$MEASURE_TYPE" == "VALUE" -a  "$DATA_TYPE" != "DATE"  -a   "$RULE_NAME" == "ABSOLUTE_CHECK" ]; then

    
  if [  $MIN_VAL  -eq $MAX_VAL ]; then

    if [ $curr_mon_val -gt $MIN_VAL  ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
      
              
        else
         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
      
  fi

   else
   
   
  if [ $curr_mon_val -ge $MIN_VAL  -a $curr_mon_val -le $MAX_VAL ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
      
              
        else
         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
      
  fi

 fi
 


fi

# Check rule for rule type absolute check and measure type value and for column of data type date


if [  "$MEASURE_TYPE" == "VALUE" -a  "$DATA_TYPE" == "DATE" -a  "$RULE_NAME" == "ABSOLUTE_CHECK" -a "$prof_type" != "RANGE OF COLUMN" -a "$prof_type" != "NULL COUNT" ]; then

    
    
     min_date=`expr substr "$MIN_VAL" 7 4`/`expr substr "$MIN_VAL" 1 2`/`expr substr "$MIN_VAL" 4 2`
     max_date=`expr substr "$MAX_VAL" 7 4`/`expr substr "$MAX_VAL" 1 2`/`expr substr "$MAX_VAL" 4 2`
     
 
     echo $min_date $max_date 

     col_val_date=`date -d "$curr_mon_val" "+%Y%m%d"`
     MAX_VAL_date=`date -d "$max_date" "+%Y%m%d"`
     MIN_VAL_date=`date -d "$min_date" "+%Y%m%d"`

     echo $col_val_date $MAX_VAL_date $MIN_VAL_date
   
   
  if (( $col_val_date >= $MIN_VAL_date )) && (( $col_val_date <= $MAX_VAL_date )); then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
      
              
  else
         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
      
  fi
 


fi


# Check rule for profile type range of column



if [  "$prof_type" == "RANGE OF COLUMN" ]; then

    

   
   
  if [ $curr_mon_val -ge $MIN_VAL  -a $curr_mon_val -le $MAX_VAL ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
      
              
  else
         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
      
  fi
 

fi

# Check rule for rule type delta check and measure type percent 


if [  "$MEASURE_TYPE" == "PERCENT" -a  "$RULE_NAME" == "DELTA_CHECK" -a "$prev_mon_found" == "0" ]; then


     curr_mon_val_tmp=` echo $curr_mon_val. | cut -d '.' -f1 ` 
     prev_mon_val_tmp=` echo $prev_mon_val. | cut -d '.' -f1 `
  

     if [ $curr_mon_val_tmp -ge $prev_mon_val_tmp ]; then
          
           if [ $prev_mon_val_tmp -eq 0 ]; then
              if [ $curr_mon_val_tmp -eq 0 ]; then 
                  mul=0 
              else 
                  mul=100 
              fi
           else
             sub=`expr $curr_mon_val_tmp - $prev_mon_val_tmp`
             div=`expr $sub / $prev_mon_val_tmp`
             mul=`expr $div \* $per_mul`
            fi 
        echo $mul
      else
 
           
          if [ $prev_mon_val_tmp -eq 0 ]; then
              if [ $curr_mon_val_tmp -eq 0 ]; then 
                  mul=0 
              else 
                  mul=100 
              fi
           else
             sub=`expr $prev_mon_val_tmp - $curr_mon_val_tmp`
             div=`expr $sub / $prev_mon_val_tmp`
             mul=`expr $div \* $per_mul`
            fi
         echo $mul
      fi 

     if [ $mul -ge $MIN_VAL  -a $mul -le $MAX_VAL ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
   
              
      else

         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
       
        
       fi

  


fi

# Check rule for rule type delta check and measure type value 


if [  "$MEASURE_TYPE" == "VALUE" -a  "$RULE_NAME" == "DELTA_CHECK" -a "$prev_mon_found" == "0" ]; then

  

     if [ $curr_mon_val -ge $prev_mon_val ]; then
          sub=`expr $curr_mon_val - $prev_mon_val`
        
      else
 
           sub=`expr $prev_mon_val - $curr_mon_val`
         
      fi 

     if [ $sub -ge $MIN_VAL  -a $sub -le $MAX_VAL ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
   
              
      else

         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
       
        
       fi

  


fi








echo "----------------------------------------------------"
echo "view name: " $view_name
echo "col name: " $col_name
echo "prof type: " $prof_type
echo "rule name: " $RULE_NAME
echo "measure type:" $MEASURE_TYPE
echo "model : " $MODEL
echo "data type : " $DATA_TYPE
echo " min val : " $MIN_VAL
echo "max val: " $MAX_VAL
echo "criticial val:" $CRITICAL
echo "criticality type : " $CRITIC_TYPE

echo " current rec count : " $curr_view_rec_count
echo " prevoius rec count : " $prev_view_rec_count
echo " prev mon value : " $prev_mon_val
echo " curre mon value : "  $curr_mon_val
echo " REsult : " $RESULT

echo "----------------------------------------------------"


echo "${RULE_NAME}|${MEASURE_TYPE}|${MODEL}|${view_name}|${col_name}|${DATA_TYPE}|${prof_type}|${curr_mon_val}|${prev_mon_val}|${MIN_VAL}|${MAX_VAL}|${CRITICAL}|${RESULT}"  >> $proc_folder/Threshold_Report_temp.csv


echo $line

fi

done

# Generate report for categorical variables


sed 1d $rule_file | grep  "COUNT OF:"  | while read line
do

RULE_NAME=`echo $line | cut -d '|' -f2 | tr -d ' \t\n\r\f'` 
MEASURE_TYPE=`echo $line | cut -d '|' -f3 | tr -d ' \t\n\r\f'`
MODEL=`echo $line | cut -d '|' -f4 | tr -d ' \t\n\r\f'`
view_name=`echo $line | cut -d '|' -f5 | tr -d ' \t\n\r\f'`
col_name=`echo $line | cut -d '|' -f6 | tr -d ' \t\n\r\f'`
DATA_TYPE=`echo $line | cut -d '|' -f7 | tr -d ' \t\n\r\f'`
prof_type=`echo $line | cut -d '|' -f8 `
MIN_VAL=`echo $line | cut -d '|' -f9 | tr -d ' \t\n\r\f'`
MAX_VAL=`echo $line | cut -d '|' -f10 | tr -d ' \t\n\r\f'`
CRITICAL=`echo $line | cut -d '|' -f11 | tr -d ' \t\n\r\f'`



curr_view_rec_count=`cat $curr_mon_file  | grep -w $view_name | grep -w "NA" | grep -w "RECORD COUNT" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq `
prev_view_rec_count=`cat $prev_mon_file  | grep -w $view_name | grep -w "NA" | grep -w "RECORD COUNT" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq`
prev_mon_val=`cat $prev_mon_file  | grep -w $view_name | grep -w $col_name | grep -w "$prof_type" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq `
prev_mon_found=$?
curr_mon_val=`cat $curr_mon_file  | grep -w $view_name | grep -w $col_name | grep -w "$prof_type" | cut -d '|' -f6 | tr -d ' \t\n\r\f' | uniq `
curr_mon_found=$?


if [ "$CRITICAL" == "N" ]; then
CRITIC_TYPE=OPTIONAL
else
CRITIC_TYPE=CRITICAL
fi

per_mul=100




# Check rule for rule type absolute check and measure type value


if [   $curr_mon_found -ne 0  ]; then

RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"



else

if [  "$MEASURE_TYPE" == "VALUE" -a  "$DATA_TYPE" != "DATE"  -a   "$RULE_NAME" == "ABSOLUTE_CHECK" ]; then

    
  if [  $MIN_VAL  -eq $MAX_VAL ]; then

    if [ $curr_mon_val -gt $MIN_VAL  ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
      
              
        else
         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
      
  fi

   else
   
   
  if [ $curr_mon_val -ge $MIN_VAL  -a $curr_mon_val -le $MAX_VAL ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
      
              
        else
         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
      
  fi

 fi
 


fi


fi






# Check rule for rule type delta check and measure type percent 


if [   $curr_mon_found -ne 0  ]; then

RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"

else


if [  "$MEASURE_TYPE" == "PERCENT" -a  "$RULE_NAME" == "DELTA_CHECK" -a "$prev_mon_found" == "0" ]; then


     
  
  

     if [ $curr_mon_val -ge $prev_mon_val ]; then
          
           if [ $prev_mon_val -eq 0 ]; then
              if [ $curr_mon_val -eq 0 ]; then
                   mul=0 
                   else 
                   mul=100 
               fi
           else
             sub=`expr $prev_mon_val - $curr_mon_val`
             div=`expr $sub / $prev_mon_val`
             mul=`expr $div \* $per_mul`
            fi 
        echo $mul
      else
 
           
          if [ $prev_mon_val -eq 0 ]; then
              if [ $curr_mon_val -eq 0 ]; then
                   mul=0 
                   else 
                   mul=100 
               fi
           else
             sub=`expr $prev_mon_val - $curr_mon_val`
             div=`expr $sub / $prev_mon_val`
             mul=`expr $div \* $per_mul`
            fi
         echo $mul
      fi 

     if [ $mul -ge $MIN_VAL  -a $mul -le $MAX_VAL ]; then 
     
          
        RESULT="${MODEL}_${CRITIC_TYPE}_PASS"
   
              
      else

         RESULT="${MODEL}_${CRITIC_TYPE}_FAIL"
          
       
        
       fi

  


fi

fi











echo "----------------------------------------------------"
echo "view name: " $view_name
echo "col name: " $col_name
echo "prof type: " $prof_type
echo "rule name: " $RULE_NAME
echo "measure type:" $MEASURE_TYPE
echo "model : " $MODEL
echo "data type : " $DATA_TYPE
echo " min val : " $MIN_VAL
echo "max val: " $MAX_VAL
echo "criticial val:" $CRITICAL
echo "criticality type : " $CRITIC_TYPE

echo " current rec count : " $curr_view_rec_count
echo " prevoius rec count : " $prev_view_rec_count
echo " prev mon value : " $prev_mon_val
echo " curre mon value : "  $curr_mon_val
echo " REsult : " $RESULT

echo "----------------------------------------------------"


echo "${RULE_NAME}|${MEASURE_TYPE}|${MODEL}|${view_name}|${col_name}|${DATA_TYPE}|${prof_type}|${curr_mon_val}|${prev_mon_val}|${MIN_VAL}|${MAX_VAL}|${CRITICAL}|${RESULT}"  >> $proc_folder/Threshold_Report_temp.csv


echo $line



done


# consolidate results from temp file into the actual threshold file


cat $proc_folder/Threshold_Report_temp.csv | awk '{ print FNR "|" $0 }' >> $proc_folder/Threshold_Report_$timestmp.csv


# delete temp file 


rm -f $proc_folder/Threshold_Report_temp.csv


echo "  Threshold Report SCRIPT ended at : $timestmp " >> $LOG_FILE












