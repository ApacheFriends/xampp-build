#!/bin/sh

SVN_PIDFILE=@@XAMPP_SUBVERSION_ROOTDIR@@/tmp/svnserve.pid

SVN_START="@@XAMPP_SUBVERSION_ROOTDIR@@/bin/svnserve -d --listen-port=@@XAMPP_SUBVERSION_PORT@@ --pid-file=$SVN_PIDFILE"

SVN_STATUS=""
SVN_PID=""
PID=""
ERROR=0

SVN_ASROOT=0
if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
    SVN_ASROOT=1
fi

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f $PIDFILE ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_subversion_pid() {
    get_pid $SVN_PIDFILE
    if [ ! $PID ]; then
        return
    fi
    if [ $PID -gt 0 ]; then
        SVN_PID=$PID
    fi
}

is_service_running() {
    PID=$1
    if [ "x$PID" != "x" ] && kill -0 $PID 2>/dev/null ; then
        RUNNING=1
    else
        RUNNING=0
    fi
    return $RUNNING
}

is_subversion_running() {
    get_subversion_pid
    is_service_running $SVN_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        SVN_STATUS="subversion not running"
    else
        SVN_STATUS="subversion already running"
    fi
    return $RUNNING
}

start_subversion() {
    is_subversion_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: subversion  (pid $SVN_PID) already running"
	exit
    fi
    if [ $SVN_ASROOT -eq 1 ]; then
	su subversion -c "$SVN_START &"
    else
	$SVN_START &
    fi
    sleep 8
    is_subversion_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        ERROR=1
    fi

    if [ $ERROR -eq 0 ]; then
	echo "$0 $ARG: subversion started at port @@XAMPP_SUBVERSION_PORT@@"
	sleep 2
    else
	echo "$0 $ARG: subversion could not be started"
	ERROR=3
    fi
}

stop_subversion() {
    NO_EXIT_ON_ERROR=$1
    is_subversion_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $SVN_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
	
    kill $SVN_PID
    rm $SVN_PIDFILE
    sleep 3

    is_subversion_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: subversion stopped"
        else
            echo "$0 $ARG: subversion could not be stopped"
            ERROR=4
    fi
}

cleanpid() {
    rm -f $SVN_PIDFILE
}

if [ "x$1" = "xstart" ]; then
    start_subversion
elif [ "x$1" = "xstop" ]; then
    stop_subversion
elif [ "x$1" = "xstatus" ]; then
    is_subversion_running
    echo "$SVN_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR
