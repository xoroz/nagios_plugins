
#!/bin/bash
#
# Felipe Ferreira
# 04/07/2016

# fix 06/07/2016 - grep and su showing on ps

i=0
TMP="/tmp/.check_many.tmp"
#GET ARGUMENTS AND SPLIT USER:SERVICE INTO AN ARRAY
for word in "$@"
do
  OIFS=$IFS
  IFS=':'
   for args in $word
    do
     AUS[$i]="$args"
     i=$(expr $i + 1)
    done
done

#GO THRU ARRAY
#echo " go thru array"
i=0
E=${#AUS[@]}
if [ ! $((E%2)) -eq 0 ]; then
 echo "UNKOWN - wrong number of arguments"
 exit 3
fi
#GET LIST OF ALL RUNNING PROCS ONLY ONCE
ps -ef > $TMP
while [ $i -lt $E ]
do
 SERVICE=${AUS[$i]}
 i=$(expr $i + 1)
 USER=${AUS[$i]}
 i=$(expr $i + 1)

# echo "USER: $USER"
# echo "SERVICE: $SERVICE"

 RESULT=$(egrep "^${USER}" $TMP | grep -v bash |grep -v grep | grep -c  "$SERVICE")
 #echo $RESULT
 if [ ${RESULT} -eq 0 ]; then
    echo "CRITICAL - Proc $SERVICE with user $USER is not running"
    exit 2
 else
    MSG=" ${RESULT} ${SERVICE} $MSG"
    TRESULT=$(expr $TRESULT + $RESULT)
 fi
done
