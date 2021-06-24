#!/bin/bash
export HM_ALGO_DB_USER=HM_DM_ALGO_USER
export HM_ALGO_DB_PASSWD=Pfizer#123

SERVER=$( uname -a | sed "s/.*\(amrndhl98.\).*/\\1/" ) # Get server name
if [[ "$SERVER" == "amrndhl985" ]]; then # Dev
  export HM_ALGO_DB_SERVER=ENID195.PFIZER.COM
elif [[ "$SERVER" == "amrndhl986" ]]; then # Test
  export HM_ALGO_DB_SERVER=ENIT185.PFIZER.COM
elif [[ "$SERVER" == "amrndhl987" ]]; then # Stage
  export HM_ALGO_DB_SERVER=ENIS188.PFIZER.COM
elif [[ "$SERVER" == "amrndhl988" ]]; then # Prod
  export HM_ALGO_DB_SERVER=STHLTH_P.PFIZER.COM
fi

export PMSuccessEmailUser=DL-HM_PROD_ETL_WATCH@pfizer.com
export PMFailureEmailUser=DL-HM_PROD_ETL_ERRORS@pfizer.com
export ODBC_INI=/app/r/ODBC/etc/odbc.ini

# A map to convert machine identifiers to environment names
# Each entry should have a lower-case key
declare -A DBMAP
DBMAP["enid195.pfizer.com"]=Development
DBMAP["enit185.pfizer.com"]=Test
DBMAP["enis188.pfizer.com"]=Stage
DBMAP["sthlth_p.pfizer.com"]=Prod
export DBMAP
