#!/bin/bash
#
# Felipe Ferreira 08/2016
# check if a directory was updated X days

#EDIT HERE: more then one day alerts
D=1



#GET ARGUMENTS AND SPLIT USER:SERVICE INTO AN ARRAY
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
T=0

E=${#DIRA[@]}
if [ $E -eq 0 ]; then
 echo "UNKOWN - wrong number of arguments"
 exit 3
fi

datediff() {
#echo "d1: $1 d2 $2"
  T=$(echo $(( (d1 - d2) / 86400 )))
#echo T $T
}

d1=$(date -d "now" +%s)


while [ $i -lt $E ]
do
 T=0
 DIR=${DIRA[$i]}
# echo "Checking if $DIR exists"
 if [ -d $DIR ]; then
  d2=$(find $DIR -exec stat \{} --printf="%y\n" \; |awk -F"." '{ print $1}')
  d2=$(date -d "$d2" +%s)
  datediff $d1 $d2
#COMPARE DATE DIFF (AGE) OLDER THEN XD
  if [ $T -gt $D ]; then
   echo "CRITICAL - backup $DIR older then $D days!"
   exit 3
  fi
 else
  echo "CRITICAL - $DIR not found"
  exit 3
 fi
 i=$(expr $i + 1)
done

echo "OK - All $i directories are updated"
exit 0
