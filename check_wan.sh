#!/bin/bash
#
# Uses ICMP ping to check if WAN/LAN is losing packages or slow response
#
# by Felipe Ferreira 01/2019
# 
# IMPORTANT: this script name must be "check_wan.sh or check_lan.sh" 
# It should only send e-mail if an error happens more then X time in a short period of time (so we are sure there is a problem)
# 
# COPYRIGHT: This code is released as open source software under the GPL v3 license.
# Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.
#
# TIPS: a good way to run this script on the background is to use the command: nohup ./check_wan.sh 50 &
#
# TODO:  improve the sendemail to check the down log file timestamp and send only every X minutes 
#        integrate with centreon clapi to set hosts in downtime (avoid too many e-mails for a network problem)


SNAME=$(echo "$0" |awk -F"_" '{ print $NF}' | sed 's/\.sh//g')
D=$(date +%D | sed 's/\//_/g')
DH=$(date +%H_%M)

############################
#####    EDIT HERE     #####
PINGS="5"
SLEEP="10"
ERRORCOUNTCRIT=2   # only after two 'consecutive' errors it should send out email
ADDRESS_WAN=google.it
ADDRESS_LAN=172.31.0.123
EMAILTO="felipe.ferreira@bobo.com.br"
##############################
CRIT=$1
if [ "$SNAME" == "wan" ]; then
 address=$ADDRESS_WAN
 if [ -z $CRIT ]; then
  CRIT=44
 fi
elif [ "$SNAME" == "lan" ]; then
 address=$ADDRESS_LAN
 if [ -z $CRIT ]; then
  CRIT=14 # threashold for alert in ms
 fi
else
 echo "ERROR - please check this script name $0 it should be:  check_wan.sh or check_lan.sh"
 exit 2
fi

FDIR="/tmp/check_${SNAME}/$D"
F="$FDIR/check_${SNAME}.log"
FDOWN="$FDIR/_down_$DH.log"

#####################
EMAILSENT=0
COUNT=0
ERRORCOUNT=0
internet=1 # default to internet is up

if [ ! -d $FDIR ]; then
 mkdir -p $FDIR
fi
if [ ! -f "$F" ]; then
 touch $F
fi


#################################################################
sendme() {
 SUBJ=$1
 MAILB=$2
 TM="/$FDIR/mailtest"
 echo "From: network_check@bbb.local" > "$TM"
 echo "To: $EMAILTO" >> "$TM"
 echo "$SUBJ" >> $TM
 echo "" >> $TM
 echo $MAILB >> $TM
 if [ $EMAILSENT -eq 0 ]; then
  cat $TM | /usr/sbin/sendmail -t
  EMAILSENT=1
  ERRORCOUNT=0
  echo "### EMAIL SENT"
 fi
}
################################################################

echo -e "\nPinging $address slow network threashold is $CRIT ms (saving logs at $FDIR)"

# INFINITE LOOP 
while true;
do
# DH=$(date +%H_%M)
 DH=$(date +%H)
 FDOWN="$FDIR/_down_$DH.log"
 echo -n "$COUNT - $(date +"%a, %b %d, %r") -- "
 ping -c $PINGS ${address} > $F
 if [[ $? -ne 0 ]]; then
  if [[ ${internet} -eq 1 ]]; then # edge trigger -- was up now down
   echo -n "Internet DOWN"
   cp -fv $F $FDOWN
   sendme "Subject: WAN Network Problem - INTERNET DOWN" "$(tail -n 5 $FDOWN)"
  else
   echo -n "... still down (log at $FDOWN)"
  fi
  internet=0
 else
  if [[ ${internet} -eq 0 ]]; then # was down and came up
   echo -n $("Internet back up")
  fi

  internet=1
  E2=$(tail -n 1 "$F")
  #check if any packages loss
  P=$(tail -n 2 "$F" |grep -c "0% packet loss")
  if [ "$P" -ne "1" ]; then
   cp -fv $F $FDOWN
   E1=$(tail -n 2 "$F"|head -n1 )
   echo "ERROR - We lost some packages! $E1 $E2"
   sendme "Subject: $SNAME Network Problem -  losing packages" "LAN network is losing packages checked from $HOSTNAME to $address and lost packages at $(date +"%a, %b %d, %r") $(cat $FDOWN)"
  fi
  #check average ping speed (ms)
  MS=$(echo "$E2"|awk -F"/" '{ print $6 }')
  MS=$(echo $MS/1 |bc)
  echo "Average Response Time of Last ${PINGS} pings is $MS ms"
 
  if [ $MS -gt $CRIT ]; then
   ERRORCOUNT=$(( $ERRORCOUNT + 1 ))
   ERRMSG="$(date +"%a, %b %d, %r") -- ERROR (${ERRORCOUNT}/${ERRORCOUNTCRIT}) -  The $SNAME network is too slow, average ${PINGS} from $address pings was ${MS} ms slower then $CRIT threashold"
   if [ $ERRORCOUNT -ge $ERRORCOUNTCRIT ]; then
    echo $ERRMSG | tee -a $FDOWN
    sendme "Subject: $SNAME Network Problem  slow response (${MS}/${CRIT})" "$ERRMSG"
   else
    echo $ERRMSG | tee -a $FDOWN
   fi
  elif [ $ERRORCOUNT -gt 1 ]; then
   EMAILSENT=0
   ERRORCOUNT=0
   OKMSG="$(date +"%a, %b %d, %r") -- RECOVERED (${ERRORCOUNT}/${ERRORCOUNTCRIT}) -  The $SNAME network is back to normal, average ${PINGS} from $address pings was ${MS} of $CRIT threashold"
   sendme "Subject: $SNAME Network Recovery (${MS}/${CRIT})" "$OKMSG"
  fi
 fi
 #RESET EMIL SENT EVERY 50 to avoid spamming we alert only every 50 checks (to be improved)
 if [ $COUNT -eq 50 ]; then
    echo -e "\n$COUNT is 50, reseting email send and error count"
    EMAILSENT=0
    ERRORCOUNT=0
    COUNT=0
 fi

 sleep $SLEEP ;
 COUNT=$(echo "$COUNT + 1"|bc)
done
