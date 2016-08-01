#!/bin/bash
#
# Felipe Ferreira 08/2016
# check if one or many directories exists

#GET ARGUMENTS AND SPLIT 
for args in "$@"
do
   for dirs in $args
    do
     DIRA[$i]="$dirs"
     i=$(expr $i + 1)
    done
done

#GO THRU ARRAY
#echo " go thru array"
i=0
E=${#DIRA[@]}
if [ $E -eq 0 ]; then
 echo "UNKOWN - wrong number of arguments"
 exit 3
fi
while [ $i -lt $E ]
do
 DIR=${DIRA[$i]}
# echo "Checking if $DIR exists"
 if [ -d $DIR ]; then
  T=$(ls -l $DIR |wc -l)
  if [ $T -lt 2 ]; then
   echo "CRITICAL - could not list $DIR files"
   exit 3
  fi
 else
  echo "CRITICAL - $DIR not found"
  exit 3
 fi
 i=$(expr $i + 1)
done

echo "OK - All $i directories exists"
exit 0
