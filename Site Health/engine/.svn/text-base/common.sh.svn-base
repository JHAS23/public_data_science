#!/bin/bash
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=3 # default to show warnings
silent_lvl=0
err_lvl=1
wrn_lvl=2
inf_lvl=3
dbg_lvl=4



log_notify() { log $silent_lvl "[NOTE] $@"; } # Always prints
log_error() { log $err_lvl "[ERROR] $@"; }
log_warn() { log $wrn_lvl "[WARNING] $@"; }
log_info() { log $inf_lvl "[INFO] $@"; } # "info" is already a command
log_debug() { log $dbg_lvl "[DEBUG] $@"; }

log() {
    if [ $verbosity -ge $1 ]; then
	shift
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "`date` $@" | fold -w132 -s | sed '2~1s/^/  /' | tee >(cat >&3)
        # echo -e "`date` $@" >&3
    fi
}
function readconf() {
 
    match=0
    shopt -s nocasematch
    while read line; do
        # skip comments
        [[ $line =~ ^\ {0,}# ]] && continue
 
        # skip empty lines
        [[ -z "$line" ]] && continue
 
        # still no match? lets check again
        if [ $match == 0 ]; then
            # do we have a section tag ?
            if [[ $line =~ ^\[.*?\] ]]; then
                #strip []
                line=${line:1:$((${#line}-2))}
                # strip whitespace
                section=${line// /}
                # do we have a match ?
                if [[ "$section" == "$1" ]]; then
                    match=1
                    continue
                fi
 
                continue
            fi
 
        # found next section after config was read - exit loop
        elif [[ $line =~ ^\[.*?\] && $match == 1 ]]; then
            break
 
        # got a config line eval it
        else
            var=${line%%=*}
            var=${var// /}
            value=${line##*=}
            value=${value## }
            eval "$var='$value'"
        fi
 
    done < "$ODBC_INI"
    shopt -u nocasematch

    export HM_ALGO_DB_USER=$UserID
    export HM_ALGO_DB_PASSWD=$Password
    export HM_ALGO_DB_SERVER=$ServerName
    export ENVIRONMENT=${DBMAP[${ServerName,,}]:-Custom}
}
