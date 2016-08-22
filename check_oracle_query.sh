#! /bin/bash
# check_sql_query
# nagios plugin to execute a specific sql query
# author: Sergei Haramundanis 08-Aug-2006
# edited: Felipe Ferreira 22-Aug-2016
  # Time in ms, simpler SQL_QUERY file

# usage: check_sql_query access_file query_file
#
# Description:
# This plugin will execute a sql query and report the elapsed time it took for the values to return
# This plugin requires oracle sqlplus (see definition of ORACLE_HOME, PATH and LD_LIBRARY_PATH further on in this script, you may need to change them)

# CREATE A CONF_DIR AND CONFIGURE THE VARIABLE TO PUT THE access_file and query_file
# contents of access_file must contain database connection information in the following format:
# USERNAME username
# PASSWORD password
# CONNECTION_STRING connection_string
# Exemple:
# CONNECTION_STRING <servername>:<port>/<service_db_instance>

# contents of query_file must contain sql query information in the following format:
# SQL_QUERY="specific_sql_query"
# EXAMPLE
# SQL_QUERY=select * from DUAL;
#
# these are to be used by sqlplus to login to the database and execute the appropriate sql query
# Output:
# During any run of the plugin, it will execute the sql query
# if the query was successful it will return on OK state with the message:
# OK - successful sql query execution | elapsedTime=##secs
# if the query was not successful it will return a CRITICAL state with the message:
# CRITICAL - sql query execution failed db_result | elapsedTime=##secs
# query execution failure is determined if any ORA- error is received or if the query returned 0 rows
#

if [ "${1}" = "" -o "${1}" = "--help" ]; then
    echo "check_sql_query 2.0"
    echo ""
    echo "nagios plugin to execute a specific sql query"
    echo ""
    echo "This nagios plugin comes with ABSOLUTELY NO WARRANTY."
    echo "You may redistribute copies of this plugin under the terms of the GNU General Public License"
    echo "as long as the original author, edit history and description information remain in place."
    echo ""
    echo "usage: check_sql_query access_file query_file"
    echo "usage: check_sql_query --help"
    echo "usage: check_sql_query --version"
    exit ${STATE_OK}
fi

if [ ${1} == "--version" ]; then
    echo "check_sql_query 1.0"
    echo "This nagios plugin comes with ABSOLUTELY NO WARRANTY."
    echo "You may redistribute copies of this plugin under the terms of the GNU General Public License"
    echo "as long as the original author, edit history and description information remain in place."
    exit ${STATE_OK}
fi

if [ $# -lt 1 ]; then
    echo "CRITICAL - insufficient arguments"
    exit ${STATE_CRITICAL}
fi

#################EDIT HERE###########################

CONF_DIR="/usr/lib/nagios/plugins/confs_ora/"

ORACLE_VERSION="10.2.0.4"
if [ -d "/usr/lib/oracle/$ORACLE_VERSION/client64/" ]; then
 export ORACLE_HOME="/usr/lib/oracle/$ORACLE_VERSION/client64"
 export TNS_ADMIN="/usr/lib/oracle/$ORACLE_VERSION/client64/network/admin"
 export PATH=$PATH:"$ORACLE_HOME/bin"
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$ORACLE_HOME/lib"
else
 echo "Path /usr/lib/oracle/$ORACLE_VERSION/client64/ not found"
fi


################# DONE EDIT ######################

ACCESS_FILE=${CONF_DIR}${1}
if [ -z $2 ]; then
 QUERY_FILE="${CONF_DIR}basic.sql"
else
 QUERY_FILE=${CONF_DIR}${2}
fi

#(optional) WARNING AND CRITICAL TIME TO EXECUTE QUERY IN MILESECONDS
if [ -z $3 ]; then
 WARN=600
else
 WARN=$3
fi
if [ -z $3 ]; then
 CRIT=900
else
 CRIT=$4
fi


#echo "ACCESS_FILE=\"${ACCESS_FILE}\""
#echo "QUERY_FILE=\"${QUERY_FILE}\""

SCRIPTPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
. ${SCRIPTPATH}/utils.sh # sets correct STATE_* return values


if [ ! -f ${ACCESS_FILE} ]; then
    echo "CRITICAL - unable to locate access_file ${ACCESS_FILE} from `pwd`"
    exit ${STATE_CRITICAL}
fi

if [ ! -r ${ACCESS_FILE} ]; then
    echo "CRITICAL - unable to read access_file ${ACCESS_FILE}"
    exit ${STATE_CRITICAL}
fi

if [ `grep "USERNAME " ${ACCESS_FILE} | wc -l` -eq 0 ]; then
    echo "CRITICAL - unable to locate USERNAME in ${ACCESS_FILE}"
    exit ${STATE_CRITICAL}
fi

if [ `grep "PASSWORD " ${ACCESS_FILE} | wc -l` -eq 0 ]; then
    echo "CRITICAL - unable to locate PASSWORD in ${ACCESS_FILE}"
    exit ${STATE_CRITICAL}
fi

if [ `grep "CONNECTION_STRING " ${ACCESS_FILE} | wc -l` -eq 0 ]; then
    echo "CRITICAL - unable to locate CONNECTION_STRING ${ACCESS_FILE}"
    exit ${STATE_CRITICAL}
fi

if [ ! -f ${QUERY_FILE} ]; then
    echo "CRITICAL - unable to locate query_file ${QUERY_FILE} from `pwd`"
    exit ${STATE_CRITICAL}
fi

if [ ! -r ${QUERY_FILE} ]; then
    echo "CRITICAL - unable to read query_file ${QUERY_FILE}"
    exit ${STATE_CRITICAL}
fi

if [ `grep "SQL_QUERY=" ${QUERY_FILE} | wc -l` -eq 0 ]; then
    echo "CRITICAL - unable to locate SQL_QUERY in ${QUERY_FILE}"
    exit ${STATE_CRITICAL}
fi

USERNAME=$(grep "^USERNAME" ${ACCESS_FILE}|awk '{print $2}')
PASSWORD=$(grep "^PASSWORD" ${ACCESS_FILE}|awk '{print $2}')
CONNECTION_STRING=$(grep "^CONNECTION_STRING" ${ACCESS_FILE}|awk '{print $2}')
SQL_QUERY=$(grep "^SQL_QUERY=" ${QUERY_FILE}|awk -F"=" '{print $NF}')

##ORIGINAL CODE###
#{ while read record; do
#    echo "record=\"${record}\""
#    WORD_COUNT=`echo $record | grep "^SQL_QUERY" | wc -w | sed s/\ //g`
#    if [ ${WORD_COUNT} -ne 0 ]; then
#        SQL_QUERY=`echo $record | sed s/SQL_QUERY\ //g`
##        echo "SQL_QUERY=\"${SQL_QUERY}\""
#        SQL_QUERY=\"${record}\"
#    fi
#done } < ${QUERY_FILE}

#echo "SQL_QUERY=${SQL_QUERY}"

START_TIME=$(date +%s%3N)
# execute query
DB_RESULT=""
DB_RESULT=`sqlplus -s <<EOT
$USERNAME/$PASSWORD@$CONNECTION_STRING
set pagesize 9999
set lines 4096
set head off
set echo off
set feedback off
${SQL_QUERY}
exit
EOT
`
RETRESULT=$?
END_TIME=$(date +%s%3N)
ERRCNT=`echo ${DB_RESULT} | grep ORA- | wc -l`
if [ ${ERRCNT} -ne 0  -o  ${RETRESULT} -ne 0 ] ; then
    let ELAPSED_TIME=${END_TIME}-${START_TIME}
    if [ ${ERRCNT} -gt 0 ]; then
        ORA_ERROR=`echo ${DB_RESULT} | grep "ORA-"`
        echo "CRITICAL - sql query execution failed RETRESULT=\"${RETRESULT}\" ORA_ERROR=\"${ORA_ERROR}\" | elapsedTime=${ELAPSED_TIME}secs"
    else
        echo "CRITICAL - sql query execution failed RETRESULT=\"${RETRESULT}\" DB_RESULT=\"${DB_RESULT}\" | elapsedTime=${ELAPSED_TIME}secs"
    fi
    exit ${STATE_CRITICAL}
fi

#echo "DB_RESULT=\"${DB_RESULT}\""

# show resultset
let col_count=0
let rec_count=0
RECORD=""

for col_value in ${DB_RESULT}; do
#    echo "col_value=\"${col_value}\""
    let col_count=$col_count+1
    RECORD=`echo ${RECORD} ${col_value}`
    if [ $col_count -eq 3 ]; then
        let rec_count=rec_count+1
        #echo "RECORD=\"${RECORD}\""

        # extract return value and datetime
        set -A COLARRAY `echo ${RECORD}`
        REC_COL0=${COLARRAY[0]}
        REC_COL1=${COLARRAY[1]}
        REC_COL2=${COLARRAY[2]}
        #echo "[${rec_count}] REC_COL0=\"${REC_COL0}\""
        #echo "[${rec_count}] REC_COL1=\"${REC_COL1}\""
        #echo "[${rec_count}] REC_COL2=\"${REC_COL2}\""

        # initialize values for next record
        let col_count=0
        RECORD=""
    fi
done

ELAPSED_TIME=$(($END_TIME-$START_TIME))
if [ $ELAPSED_TIME -gt $CRIT ]; then
 echo "CRITICAL - sql query execution took $ELAPSED_TIME ms (longer then $CRIT ms ) | elapsedTime=${ELAPSED_TIME}ms"
 exit ${STATE_CRITICAL}
elif [ $ELAPSED_TIME -gt $WARN ]; then
 echo "WARNING - sql query execution took $ELAPSED_TIME ms (longer then $WARN ms ) | elapsedTime=${ELAPSED_TIME}ms"
 exit ${STATE_WARNING}
else
 echo "OK - successful sql query execution | elapsedTime=${ELAPSED_TIME}ms"
 exit ${STATE_OK}
fi
