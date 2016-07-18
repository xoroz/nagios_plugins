#!/bin/bash
#
# Felipe Ferreira
# 04/07/2016

# fix 06/07/2016 - grep and su showing on ps

SERVICE="$1"
USER="$2"
if [ -z $USER ]; then
        echo "UNKONW - Please set SERVICE and USER arguments"
        exit 3
fi
RESULT=$(ps -U $USER -f 2>&1 | grep -v bash |grep -v grep |grep -v su| grep -c  "$SERVICE")
#echo $RESULT
if [ ${RESULT} -eq 0 ]; then
    echo "CRITICAL - Proc $SERVICE with user $USER is not running"
    exit 2
else
    echo "OK - Proc $SERVICE with user $USER is running"
    exit 0
fi
