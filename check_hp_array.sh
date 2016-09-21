
#! /bin/sh
######################################################################
# Name: check_hparray
# By: Copyright (C) 2007 Magnus Glantz
# Credits to: andreiw
# Edited by FELIPE FERREIRA (fix Upgrade situation)
######################################################################
# Licence: GPL 2.0
 A Nagios plugin that checks HP Proliant hardware raid via the HPACUCLI tool.
#
# HPACUCLI needs administrator rights.
# add this line to /etc/sudoers
#
# nagios      ALL=NOPASSWD: /usr/sbin/hpacucli
######################################################################

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`
HPACUCLI=/usr/sbin/hpacucli

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

print_usage() {
        echo ""
        echo "Usage: $PROGNAME -s <slot-number>"
        echo "Usage: $PROGNAME [-h | --help]"
        echo "Usage: $PROGNAME [-V | --version]"
        echo ""
        echo " NOTE:"
        echo ""
        echo " HPACUCLI needs administrator rights."
        echo " add this line to /etc/sudoers"
        echo " nagios      ALL=NOPASSWD: /usr/sbin/hpacucli"
        echo ""
}

print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        print_usage
        echo ""
        echo "This plugin checks hardware status for HP Proliant servers using HPACUCLI utility."
        echo ""
        support
        exit 0
}

if [ $# -lt 1 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

check_raid()
{
        raid_ok=`echo $check|grep -i ok|wc -l`
        raid_warning=`echo $check|grep -i rebuild|wc -l`
        raid_critical_1=`echo $check|grep -i failed|wc -l`
        raid_critical_2=`echo $check|grep -i recovery|wc -l`
        raid_upgrade=$(echo $check|grep -i upgrade|wc -l)
    #    echo "RAID_OK $raid_ok RAID_CRITICAL_1 $raid_critical_1 RAID_CRITICAL_2 $raid_critical_2"
        err_check=`expr $raid_ok + $raid_warning + $raid_critical_1 + $raid_critical_2`

#### IF ELSE
        if [ $raid_critical_1 -ge "1" ]; then
                exit_status=$STATE_CRITICAL
        elif [ $raid_warning -ge "1" ] || [ $raid_upgrade -ge "1" ]; then
                exit_status=$STATE_WARNING
        else
                exit_status=0
        fi


        if [ $exit_status -eq "0" ]; then
                msg_ok=`echo $check|grep -i ok`
                echo "RAID OK - $msg_ok"
                exit $exit_status
        elif [ $exit_status -eq "1" ]; then
                msg_warning=`echo $check|egrep -i 'rebuild|upgrade'`
                echo "RAID WARNING - ($msg_warning)"
                exit $exit_status
        elif [ $exit_status -eq "2" ]; then
                msg_critical1=`echo $check|grep -i failed`
                msg_critical2=`echo $check|grep -i recovery`
                echo "RAID CRITICAL - ($msg_critical1 $msg_critical2)"
                exit $exit_status
        fi
}


case "$1" in
        --help)
                print_help
                exit 0
                ;;
        -h)
                print_help
                exit 0
                ;;
        --version)
                print_revision $PROGNAME $REVISION
                exit 0
                ;;
        -V)
                print_revision $PROGNAME $REVISION
                exit 0
                ;;
        -s)
                check=`sudo -u root $HPACUCLI controller slot=$2 ld all show`
                check_raid
                ;;
        *)
                print_usage
                ;;
esac
