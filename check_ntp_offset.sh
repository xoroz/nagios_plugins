# Check NTPD offset
#
# Felipe Ferreira
# 04/07/2016
# Simple NTPD offset local check
# Version 2.0 fix check if ntpd service is running
# Version 3.0 added support for chronyd get correctly tail, find out first how many timed servers are configured
# Version 4.0 fix bug when chronyc sourcestats outputs is not in milesconds
    #ns (indicating nanoseconds), us (indicating microseconds), ms (indicating milliseconds), or s (indicating seconds).

limit=$1   # Set your limit in milliseconds here otherwise it will be 4 seconds
count=0
countd=0
total=0

if [[ $(id chrony 2> /dev/null |grep -c uid ) > 0 ]] && [[ $(ps -u chrony -f |grep -c chronyd) -eq 1  ]]; then
# ANOTHER WAY TO GET AVERAGE
# offsets=$(chronyc sourcestats |awk '{ print $(NF -1) }' |sed 's/ms//g' |tail -n 5 | awk -v N=1 '{ sum += $N } END { if (NR > 0) print sum / NR }' | tr -d '-' |tr -d '+')

 countd=$(chronyc sourcestats |wc -l)
 countd=$(echo $countd - 3|bc)
 offsets=$( chronyc sourcestats |awk '{ print $(NF -1) }' |tail -n $countd |sed 's/ms//g' | tr -d '-' |tr -d '+')
 offsets=$( chronyc sourcestats |awk '{ print $(NF -1) }' |tail -n $countd | tr -d '-' |tr -d '+')
  if  [[ $(echo $offsets |grep -o '[0-9:]s' |grep -c s ) = 1 ]]; then
#   echo " found s (seconds unit), should multiply by 1000"
   offsets=$(echo $offsets|sed 's/s//g')
   SECONDS=1
  elif  [[ $(echo $offsets |grep -c 'ms ' ) = 1 ]]; then
#   echo " found ms (mileseconds unit)"
   offsets=$(echo $offsets|sed 's/ms//g')
 elif [[ $(echo $offsets |grep -c us) = 1 ]]; then
#  echo " found us (time unit) lower then 1ms so OK"
   offsets=0
 elif [[ $(echo $offsets |grep -c ns) = 1 ]]; then
#  echo " found ns (nano seconds unit) lower then 1ms so OK"
   offsets=0
 fi
 MSG="chronyd"
else
 if [[ $(ps -u ntp -f |grep -c ntpd) -eq 0  ]]; then
  echo "UNKONWN - Could not find NTPD or Chronyd services"
  exit 1
 else
  countd=$(ntpq -nc peers |wc -l)
  countd=$(echo $countd - 2|bc)
  offsets=$(ntpq -nc peers | tail -n $countd | cut -c 62-66 | tr -d '-')
  MSG="NTPD"
 fi
fi

if [ -z "$offsets" ]; then
 echo "UNKONWN - Could not find offset"
 exit 1
fi

if [ -z $limit ]; then
 limit=4000
fi

# LOOP THRU ALL OFFSETS AND CHECK IF ANY IS HIGHER THEN IT SHOULD
for offset in ${offsets}; do
 if [ $SECONDS -eq 1 ] && [[ $(echo $offset |grep -oc '[0-9:]m' ) != 1 ]] ; then
  offset=$(echo "scale=3;${offset} * 1000" | bc)
 elif [[ $(echo $offset |grep -oc '[0-9:]m' ) = 1 ]] ; then
  offset=$(echo $offset |grep -o '[0-9:]*')
 fi
 if [ $(echo " $offset > $limit" | bc) -eq 1 ]; then
  echo "CRITICAL - $MSG offset of $offset ms is NOT fine|ntpoffset=$offset"
  exit 2
 fi
#get average offset
 total=$(echo $total+$offset | bc )
 ((count++))
done

offset=$(echo "scale=0; $total / $count" | bc)
MSG="$MSG offset of average $offset ms is fine|ntpoffset=$offset"
echo "OK - $MSG"
exit 0
