#!/bin/bash


D_PID=$$
D_PATH=$(readlink -f $0)
D_ROOT=$(dirname $D_PATH)
D_NAME=$(basename $D_PATH)
D_KILLFILE="$D_ROOT/.$D_NAME.kill"
D_ERRFILE="$D_ROOT/.$D_NAME.err"
D_LOGFILE="$D_ROOT/.$D_NAME.log"
D_BLOCKFILE="$D_ROOT/.$D_NAME.block"
D_PIDFILE="$D_ROOT/.$D_NAME.pid"


function getpid() {
	if [ -f $D_PIDFILE ]; then
		return $D_PIDFILE
	else
		return 0
	fi
}

function daemonize() {
	echo $D_PID > $D_PIDFILE
	#closing & redirecting input/ouput
	exec 0<&-
	exec 2>>$D_ERRFILE
	exec 1>>$D_LOGFILE
	echo $(date)" Daemonizing" >> $D_ERRFILE
}

function daemon_function() {
  while [ true ]; do
  	checkforkill
  	#insert daemon function here
  	echo "dsdsds"
    sleep 10
  done
}

function checkforkill() {
	if [ -f $D_KILLFILE ]; then
		echo $(date)" Terminating gracefully" >> $D_ERRFILE
		rm $D_PIDFILE
		rm $D_KILLFILE
		kill $D_PID
		exit 0
	fi
}




case $1 in
	restart)
		$0 stop
		$0 start
		;;
	start)
		$0 run &
		echo "Daemon Started"
		#closing input/output
		exec 2>&-
		exec 1>&-
		exec 0<&-
		exit 0
		;;
	run)
		daemonize
		daemon_function
		;;
	stop)
		echo -n "Terminating daemon... "
		$0 status 1>/dev/null 2>/dev/null
		if [ $? -ne 0 ]; then
			echo "daemon is not running"
			exit 0
		fi
		touch $D_KILLFILE
		$0 status 1>/dev/null 2>/dev/null
		exitcode=$?
		counter=0
		if [ "$countermax" = "" ]; then countermax=30; fi
		while [ $exitcode -eq 0 ]; do
			sleep 1
			let counter=$counter+1
			if [ $counter -lt $countermax ]; then
				$0 status 1>/dev/null 2>/dev/null
				exitcode=$?
			else
				exitcode=1
			fi
		done
		$0 status 1>/dev/null 2>/dev/null
		if [ $? -eq 0 ]; then
			PID=$(cat $D_PIDFILE)
			kill $PID
			rm $D_PIDFILE
			rm $D_KILLFILE
			echo $(date)" Terminating forcefully" >> $D_ERRFILE
			exit 0;
		else
			echo "Process exited gracefully"
		fi
		;;
	status)
		if [ ! -f $D_PIDFILE ]; then
			echo "$D_NAME is not running"
			exit 1
		fi
		pgrep -l -f "$D_NAME run" | grep -q -E "^$(cat $D_PIDFILE) "
		if [ $? -eq 0 ]; then
			echo "$D_NAME is running: PID = "$(getpid)
			exit 0
		else
			echo "$D_NAME is not running"
			exit 1
		fi
		;;
esac