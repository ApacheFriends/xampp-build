#!/bin/sh

HOSTNAME=`hostname`
MYSQL_PIDFILE=/opt/lampp/var/mysql/$HOSTNAME.pid

MYSQL_STATUS=""
MYSQL_PID=""
PID=""
ERROR=0

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f "$PIDFILE" ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_mysql_pid() {
    get_pid $MYSQL_PIDFILE
    if [ ! "$PID" ]; then
        return
    fi
    if [ "$PID" -gt 0 ]; then
        MYSQL_PID=$PID
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

is_mysql_running() {
    get_mysql_pid
    is_service_running $MYSQL_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        MYSQL_STATUS="mysql not running"
    else
        MYSQL_STATUS="mysql already running"
    fi
    return $RUNNING
}

start_mysql() {
    is_mysql_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: mysql  (pid $MYSQL_PID) already running"
	exit
    fi
    /opt/lampp/lampp startmysql > /dev/null &

    COUNTER=40
    while [ $RUNNING -eq 0 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 3
        is_mysql_running
        RUNNING=$?
    done
    if [ $RUNNING -eq 0 ]; then
        ERROR=1
    fi

    if [ $ERROR -eq 0 ]; then
	echo "$0 $ARG: mysql  started at port 3306"
	sleep 2
    else
	echo "$0 $ARG: mysql  could not be started"
	ERROR=3
    fi
}

stop_mysql() {
    NO_EXIT_ON_ERROR=$1
    is_mysql_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $MYSQL_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
	
    kill $MYSQL_PID

    COUNTER=40
    while [ $RUNNING -eq 1 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 3
        is_mysql_running
        RUNNING=$?
    done

    is_mysql_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: mysql stopped"
        else
            echo "$0 $ARG: mysql could not be stopped"
            ERROR=4
    fi
}

cleanpid() {
    rm -f $MYSQL_PIDFILE
}

if [ "x$1" = "xstart" ]; then
    start_mysql
elif [ "x$1" = "xstop" ]; then
    stop_mysql
elif [ "x$1" = "xstatus" ]; then
    is_mysql_running
    echo "$MYSQL_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR
