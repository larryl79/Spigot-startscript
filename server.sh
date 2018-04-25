#!/bin/sh
###
#
# Server startscript
#
# ver 2.0
#
###

WHITE='\033[0;37m'
GREEN='\033[0;32m'
stopsec=15

if [ -e "servername.dat" ]; then
    #SZERVER=`cat servername.dat | awk ' {print $1 }' | grep '^[A-Z,a-z,0-9]'`
    SZERVER=`cat servername.dat`
else
    printf "${GREEN}"
    printf "Error: "servername.dat" missing.\nExitig.\n\n"
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
	printf "Wait up to $stopsec second(s) for stop server...\n"
	while ps -p $pid > /dev/null; do
	    sleep 1;
	    sec=$((sec + 1));
	    if [ $sec -eq $stopsec ]; then
		printf "Stopping Timeout. Terminate stopping script. Check for dead thread(s)."
		printf "PID: "
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
    *)
    echo "${GREEN}Usage: $0 {start|stop|restart|debug}${WHITE}"
    exit 1
    ;;
    
 esac
exit 0