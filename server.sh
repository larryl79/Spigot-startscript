#!/bin/sh
##########################
#
# Java Server startscript
#
# ver 3.1
#
#########################

# Color Codes
WHITE='\033[0;37m'
GREEN='\033[0;32m'
LRED='\033[1;31m'
YELLOW='\033[1;33m'

# Some helper string. Don't edit them!
PARAM2=$2
VERSION=3.1

############################################################################ Checking Config files ###############################

# config file for tail files
if [ -e "srv_cfg_loglines.dat" ]; then
    LOGLINES=`cat srv_cfg_loglines.dat | awk ' {print $1 }' | grep '^[0-9]'`
    if [ -z $LOGLINES ] || [ $LOGLINES -lt 5 ]; then
	printf "${YELLOW}Warning:${GREEN} Your tail log lines are too small at least should be 5.\n"
	printf "40">srv_cfg_loglines.dat
	printf "${GREEN}"
	printf "Tail log lines set to default ${LRED}40${GREEN} in \"${LRED}srv_cfg_loglines.dat${GREEN}\"\n"
	LOGLINES=40
	printf "${WHITE}"
    fi
else
    printf "${YELLOW}Warning:${GREEN} \"${LRED}srv_cfg_loglines.dat${GREEN}\" missing.\Creating.\n\n"
    printf "40">srv_cfg_loglines.dat
    printf "${WHITE}"
    LOGLINES=15
fi

# config file for wait to stop server
if [ -e "srv_cfg_stopsec.dat" ]; then
    STOPSEC=`cat srv_cfg_stopsec.dat | awk ' {print $1 }' | grep '^[0-9]'`
    if [ -z $STOPSEC ] || [ $STOPSEC -lt 5 ]; then
	printf "${YELLOW}Warning:${GREEN} Your stop waiting seconds are too small at least should be 5.\n"
	printf "5">srv_cfg_stopsec.dat
	printf "${LRED}"
	printf "Stop seconds set to default 15 sec in \"srv_cfg_stopsec.dat\"\n"
	STOPSEC=15
	printf "${WHITE}"
    fi
else
    printf "${YELLOW}Warning:${GREEN} \"${LRED}srv_cfg_stopsec.dat${GREEN}\" missing.\Creating.\n\n"
    printf "15">srv_cfg_stopsec.dat
    printf "${WHITE}"
    STOPSEC=15
fi

# config file for java command line (may you can run in docker or another jail)
if [ -e "srv_cfg_servercmd.dat" ]; then
    #SZERVER=`cat srv_cfg_servercmd.dat | awk ' {print $1 }' | grep '^[A-Z,a-z,0-9]'`
    CMD=`cat srv_cfg_servercmd.dat`
else
    printf "${GREEN}"
    printf "${YELLOW}Warning:${GREEN} \"${LRED}srv_cfg_serverparam.dat${GREEN}\" missing.\nCreating with default value: \"${GREEN}java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar${GREEN}\".\n"
    printf "java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar" srv_cfg_servercmd.dat
    printf "${WHITE}\n"
    CMD='java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar'
fi

# config file for start stop java server
if [ -e "srv_cfg_servername.dat" ]; then
    #SZERVER=`cat srv_cfg_servername.dat | awk ' {print $1 }' | grep '^[A-Z,a-z,0-9]'`
    SZERVER=`cat srv_cfg_servername.dat`
else
    printf "${GREEN}"
    printf "${LRED}Error:${GREEN} \"${LRED}srv_cfg_servername.dat${GREEN}\" missing.\nExiting.\n\n"
    printf "Create and insert your server program filenname without extension in config file before start using this program.\n"
    printf "Exiting.\n\n"
    printf "${WHITE}\n"
    exit 1
fi

# config file for server progam parameter(s)
if [ -e "srv_cfg_serverparam.dat" ]; then
    #SZERVER=`cat srv_cfg_serverparam.dat | awk ' {print $1 }' | grep '^[A-Z,a-z,0-9]'`
    SRVPARAM=`cat srv_cfg_serverparam.dat`
else
    printf "${GREEN}"
    printf "${YELLOW}Warning:${GREEN} \"${LRED}srv_cfg_serverparam.dat${GREEN}\" missing.\nCreating.\n"
    touch srv_cfg_serverparam.dat
    printf "${WHITE}\n"
    SRVPARAM=''
fi


############################################################################ Functions ###########################################

start(){
    # start script
    if ! chkrun; then
        rm $SZERVER.pid.old 2>/dev/null
	printf "${GREEN}"
	printf "Starting $SZERVER server in background ...\n"
	SRVCMD="$CMD $SZERVER.jar $SRVPARAM >$SZERVER.log &" 
	eval "$SRVCMD"
	echo $! > $SZERVER.pid
#    	java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar $SZERVER.jar $SRVPARAM >$SZERVER.log & echo $! > $SZERVER.pid
	printf "PID: "
	cat $SZERVER.pid
    else
	printf "${GREEN}$SZERVER server is running already with PID: "
	cat $SZERVER.pid
	printf ".\nNot starting it again."
    fi
	printf "${WHITE}\n"
}

debug(){
    if ! chkrun; then
	SRVCMD="$CMD $SZERVER.jar"
	eval "$SRVCMD"
    else
	printf "${GREEN}$SZERVER server is running already with PID: "
	cat $SZERVER.pid
	printf "Not starting it again."
    fi
	printf "${WHITE}\n"
}

stop() {
#stop sctipt
sec=0

if [ -e $SZERVER.pid ]; then
    pid=`cat $SZERVER.pid`
else
    printf "${LRED}Error:${GREEN} Pid file missing can't stop server or not running.\nExitig.\n"
    exit 1
fi

if [ -e /proc/$pid ]; then
    CMDLINE=`cat /proc/$pid/cmdline`
    SERVERNAME=$SZERVER.jar
    if [ -z "${CMDLINE##*"java"*}" ] && [ -z "${CMDLINE##*$SERVERNAME*}" ]; then
	printf "${GREEN}$SZERVER Server is running, Stopping it.\n"
	sleep 1;
	kill -15 $pid;
	printf "Wait up to $STOPSEC second(s) for stop server...\n"
	while ps -p $pid > /dev/null; do
	    sleep 1;
	    sec=$((sec + 1));
	    if [ $sec -eq $STOPSEC ]; then
		printf "Timeout. Terminate stopping script. Check for dead thread(s)."
		printf "$SZERVER server PID: "
		cat $SZERVER.pid
		printf "${WHITE}\n"
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

######################################################################### Log file Functions ###########################################
log(){
if [ -e "$SZERVER.log" ]; then
    printf "${GREEN}"
    printf "Listing actual log file:\n"
    printf "Mode: "
    case "$PARAM2" in
	f)
	    printf "follow - list last $LOGLINES lines of log and follow changes. Exit with ctrl\+c\n"
	    printf "${WHITE}"
	    tail -n$LOGLINES -f $SZERVER.log
	    exit 1
	;;
	t)
	    printf "tail - list last $LOGLINES lines of log.\n"
	    printf "${WHITE}"
	    tail -n$LOGLINES $SZERVER.log
	    exit 1
	;;
    *)
    # no param cat log file
    printf "fullog - print whole log file"
    cat "$SZERVER.log"

    printf "\n"
    ;;
    esac
else
    printf "${GREEN}"
    printf "${LRED}Error:${GREEN} \"${LRED}$SZERVER.log${GREEN}\" missing.\nExiting.\n\n"
    printf "${WHITE}"
    exit 1
fi
printf "${WHITE}"
}

############################################################################ Help Screen ###########################################
help(){
    printf "\n"
    printf "${GREEN}"
    printf "Java Server program manager\n"
    printf "\n"
    printf "Help screen\n"
    printf "\n"
    syntax
    printf "\n"
    printf "Params:\n"
    printf "\n"
    printf "${LRED}start${GREEN}	Start server in background\n"
    printf "${LRED}stop${GREEN}	Stop background running server\n"
    printf "${LRED}restart${GREEN}	Restart bacground running server\n"
    printf "${LRED}debug${GREEN}	Start server in foreground. May stop server with crtl+c\n"
    printf "${LRED}status${GREEN}	Checking server (running) status. \n"
    printf "${LRED}log${GREEN}	Show full log of server\n"
    printf "${LRED}log t${GREEN}	Tail of log file ( last $LOGLINES lines )\n"
    printf "${LRED}log f${GREEN}	Tail of log file and follow changes. Start with last $LOGLINES lines. Stop with ctrl+c key.\n"
    printf "${LRED}chkconfig${GREEN}	Check your configuration\n"
    printf "${LRED}ver${GREEN}	Check script version, and latest release on Github\n"
    printf "${LRED}help${GREEN}	This screen\n"
    printf "\n"
    printf "\n"
    printf "${WHITE}Config files:${GREEN}\n"
    printf "\n"
    printf "These files editable by you."
    printf "\n"
    printf "${LRED}srv_cfg_servercmd.dat${GREEN}		Your command for run your server.\n"
    printf "				CMDline will looks like this when you issue start:${YELLOW} srv_cfg_servercmd.dat srv_cfg_servername.dat ...${GREEN}\n"
    printf "				check ${LRED}chkconfig${GREEN} param for exact cmdline!\n"
    printf "				Default value is: ${LRED}java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar${GREEN}\n"
    printf "${LRED}srv_cfg_servername.dat${GREEN}		Your server program (file)name without extension.\n"
    printf "				(e.g. MyServer) itt will start MyServer.jar and create MyServer.pid and MyServer.log\n"
    printf "				No default value program will exit with error if file is missing.\n"
    printf "${LRED}srv_cfg_serverparam.dat${GREEN}		Insert your parameters into this config file e.g. --noconsole \n"
    printf "				${YELLOW}Warning!!!${GREEN} No parameters passing trough from this file for debug start!\n"
    printf "				CMDline will looks like this when you issue start:${YELLOW} ...... srv_cfg_servername.dat srv_cfg_serverparam.dat${GREEN}\n"
    printf "				check ${LRED}chkconfig${GREEN} param for exact cmdline!\n"
    printf "${LRED}srv_cfg_stopsec.dat${GREEN}		Wait seconds for stop server before this script exit with warn you about dead process.\n"
    printf "				Only numbers in config file. (e.g 10) minimum is 5 second, default 15 second.\n"
    printf "${LRED}srv_cfg_loglines.dat${GREEN}		How many last lines show from log file.\n"
    printf "				Only numbers in config file. (e.g 40) minimum value is 5, default value is 40.\n"
    printf "${WHITE}\n"
}

syntax(){
    printf "${WHITE}Syntax: ${GREEN}$0 ${WHITE}{ ${LRED}start${WHITE} | ${LRED}stop${WHITE} | ${LRED}restart${WHITE} | ${LRED}debug${WHITE} | ${LRED}log${WHITE} | ${LRED}log${WHITE} [${LRED}f${WHITE}|${LRED}t${WHITE}] | ${LRED}chkconfig${WHITE} | ${LRED}help${WHITE} | ${LRED}ver${WHITE} }\n"
}

version(){
    printf "Version: ${GREEN}$VERSION${WHITE}\n"
    printf "Wait a sec, checking for latest release on Github.\n"
    RELEASE=`curl --silent "https://api.github.com/repos/larryl79/Spigot-startscript/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
    echo "Git release: ${GREEN}$RELEASE${WHITE}"
    if [ $RELEASE \> $VERSION ]; then
	printf "${YELLOW}Warning: ${GREEN}You are not on a latest release, ${YELLOW}please update${GREEN} for new feauters and bugfixes from github.\n"
	printf "\n"
    else
	printf "${GREEN}You are on a latest release.\n"
    fi
    printf "${WHITE}"
}

chkconfig(){
    printf "${GREEN}Check configuration.\n"
    printf "\n"
    printf "srv_cfg_servername	=	$SZERVER\n"
    printf "srv_cfg_serverparam	=	$SRVPARAM\n"
    printf "srv_cfg_cmd		=	$CMD\n"
    printf "srv_cfg_loglines	=	$LOGLINES\n"
    printf "srv_cfg_stopsec		=	$STOPSEC\n"
    printf "\n"
    printf "${GREEN}Your START command line by config:${WHITE}\n"
    printf "$CMD $SZERVER.jar $SRVPARAM\n"
    printf "${GREEN}Your DEBUG command line by config:${WHITE}\n"
    printf "$CMD $SZERVER.jar\n"
    printf "\n"
}

chkrun(){

if [ -e $SZERVER.pid ]; then
    pid=`cat $SZERVER.pid`

    if [ -e /proc/$pid ]; then
	CMDLINE=`cat /proc/$pid/cmdline`
	SERVERNAME=$SZERVER.jar
	if [ -z "${CMDLINE##*"java"*}" ] && [ -z "${CMDLINE##*$SERVERNAME*}" ]; then
	    return 0
	else
	    return 1
	fi
    fi

else
    #printf "${LRED}Error:${GREEN} Pid file missing can't stop server or not running.\nExitig.\n"
    return 1
fi

}

status(){
    if chkrun; then
	printf "${GREEN}$SZERVER Server is running with PID: "
	cat $SZERVER.pid
    else
	printf "${GREEN}Server not runnning.\n"
    fi
printf "${WHITE}"
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
    status)
	status
	;;
    debug)
	debug
	;;
    log)
	log
	;;
    help)
	help
	;;
    ver)
	version
	;;
    chkconfig)
	chkconfig
	;;

    *)
    printf "Server program manager\n"
    printf "\n"
    syntax
    printf "\n"
    exit 1
    ;;
    
 esac
exit 0
