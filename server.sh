#!/bin/sh
##########################
#
# Server startscript
#
# ver 2.2
#
#########################

WHITE='\033[0;37m'
GREEN='\033[0;32m'
LRED='\033[1;31m'

PARAM2=$2

# config file for wait to stop server
if [ -e "srv_cfg_stopsec.dat" ]; then
    STOPSEC=`cat srv_cfg_stopsec.dat | awk ' {print $1 }' | grep '^[0-9]'`
    if [ -z $STOPSEC ] || [ $STOPSEC -lt 5 ]; then
	printf "${GREEN}"
	printf "Warning: Your waiting seconds are too small at least should be 5.\n"
	printf "5">srv_cfg_stopsec.dat
	printf "${LRED}"
	printf "Stop seconds seted to default 15 sec in \"srv_cfg_stopsec.dat\"\n"
	STOPSEC=15
	printf "${WHITE}"
    fi
###############################
else
    printf "${LRED}"
    printf "Error: \"srv_cfg_stopsec.dat\" missing.\Creating.\n\n"
    printf "15">srv_cfg_stopsec.dat
    printf "${WHITE}"
    STOPSEC=15
fi

# config file for start stop java server
if [ -e "srv_cfg_servername.dat" ]; then
    #SZERVER=`cat srv_cfg_servername.dat | awk ' {print $1 }' | grep '^[A-Z,a-z,0-9]'`
    SZERVER=`cat srv_cfg_servername.dat`
else
    printf "${GREEN}"
    printf "Error: \"srv_cfg_servername.dat\" missing.\nExiting.\n\n"
    printf "${WHITE}"
    exit 1
fi

start(){
# start script
rm $SZERVER.pid.old 2>/dev/null
printf "${GREEN}"
printf "Starting $SZERVER server in background ...\n"
java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar $SZERVER.jar --noconsole >$SZERVER.log & echo $! > $SZERVER.pid
printf "PID: "
cat $SZERVER.pid
printf "${WHITE}"
}

debug(){
java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar $SZERVER.jar
}

stop() {
#stop sctipt
sec=0

if [ -e $SZERVER.pid ]; then
    pid=`cat $SZERVER.pid`
else
    printf "Error: Pid file missing can't stop server or not running.\nExitig.\n"
    exit 1
fi

if [ -e /proc/$pid ]; then
    CMDLINE=`cat /proc/$pid/cmdline`
    SERVERNAME=$SZERVER.jar
    if [ -z "${CMDLINE##*"java"*}" ] && [ -z "${CMDLINE##*$SERVERNAME*}" ]; then
	printf "${GREEN}$SZERVER Server running, Stopping it.\n"
	sleep 1;
	kill -15 $pid;
	printf "Wait up to $STOPSEC second(s) for stop server...\n"
	while ps -p $pid > /dev/null; do
	    sleep 1;
	    sec=$((sec + 1));
	    if [ $sec -eq $STOPSEC ]; then
		printf "Stopping Timeout. Terminate stopping script. Check for dead thread(s)."
		printf "$SZERVER server PID: "
		cat $SZERVER.pid
		exit 1
	    fi
	done;
	printf "Last 15 line from log:\n"
	printf "${WHITE}\n"
	tail -n 15 $SZERVER.log
	sleep 2
	printf "${GREEN}\n"
	rm $SZERVER.pid.old 2>/dev/null
	cp $SZERVER.pid $SZERVER.pid.old >/dev/null
	rm $SZERVER.pid 2>/dev/null
	printf "${WHITE}"
    fi
fi
}

log(){
if [ -e "$SZERVER.log" ]; then
    printf "${GREEN}"
    printf "Listing actual log file:\n"
    case "$PARAM2" in
	f)
	    printf "Mode: follow, exit with ctrl\+c\n"
	    printf "${WHITE}"
	    tail -n40 -f $SZERVER.log 
	    exit 1
	;;
	t)
	    printf "Mode: tail\n"
	    printf "${WHITE}"
	    tail -n40 $SZERVER.log
	    exit 1
	;;
    *)
    # cat log file
    printf "Mode: tail\n"
    cat "$SZERVER.log"
    printf "${WHITE}"
    printf "\n"
    ;;
    esac

else
    printf "${GREEN}"
    printf "Error: \"$SZERVER.log\" missing.\nExiting.\n\n"
    printf "${WHITE}"
    exit 1
fi
}



 case "$1" in
    start)
	start
	;;
    stop)
	stop
	;;
    restart)
	stop
	start
	;;
    debug)
	debug
	;;
    log)

	log $2
	;;
    *)
    printf "${GREEN}Usage: $0 {start|stop|restart|debug|log [f|t]}\n"
    printf "${WHITE}"
    exit 1
    ;;
    
 esac
exit 0