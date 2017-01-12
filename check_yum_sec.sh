#!/bin/bash
#
#Felipe Ferreira Jan 2017
#
# First lets chceck if yum --security exists and works

#MAKE SURE yum-security is installed
if [[ $(yum -h |grep -c "Include security") = 0 ]]; then
 echo "UNOKWN - Require yum-security but it's not installed.  Aborting."
 exit 3
fi


#CHECK FOR ARGS
if [[ $2 ]]; then
 WARN=$1
 CRIT=$2
else
 echo "UNKONW - Please pass arguments, number of security patches missing it should warn or crit $0 <warning> <critical> "
 exit 3
fi

if [[ $(yum -C --security check-update|grep -c "No packages needed") != 0 ]]; then
 echo "OK - Zero patches needed|sec=0"
 exit 0
else
 A=$(yum -C --security check-update |grep " needed for security")
 C=$(echo $A|awk '{ print $1 }')
fi

if [ "$C" -gt "$CRIT" ]; then
 echo "CRITICAL - $A | sec=$C"
 exit 2
elif  [ "$C" -gt "$WARN" ]; then
 echo "WANING - $A | sec=$C"
 exit 1
fi

echo "OK - $A | sec=$C"
exit 0
