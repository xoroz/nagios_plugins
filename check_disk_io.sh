#!/bin/bash
#
# Felipe Ferreira 07/2016
#
# Local Disk await
# await =  The average time (in milliseconds) for I/O requests issued to the device to be served. This includes the time spent by the requests in  queue  and the time spent servicing them.

# IMPORTANT: Requires iostat

#Example
#./check_io_disk.sh sdc 20.0 28.0
# OK -  Disk sdc await time is 8.0 ms | await=8.0


DISK=$1
WARN=$2
CRIT=$3

R=$(iostat -d $DISK -xmt  2 4 |  awk '{ sum += $10; n++ } END { if (n > 0) print sum / n; }' |cut -c 1-3)

if [ -z $R ]; then
        echo "UNKOWN - Error to get iostat info for disk $DISK"
        exit 3
fi

MSG=" Disk $DISK await time is $R ms | await=$R"

if (( $(bc <<< "$R > $CRIT") )); then
        echo "CRITICAL - $MSG "
        exit 2
elif (( $(bc <<< "$R > $WARN") )); then
        echo "WARNING - $MSG"
        exit 1
fi
echo "OK - $MSG"
exit 0
