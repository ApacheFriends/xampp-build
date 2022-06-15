#!/bin/sh

HOSTNAME=`hostname`
POSTGRESQL_PIDFILE=@@XAMPP_POSTGRESQL_DATADIR@@/postmaster.pid

POSTGRESQL_START="@@XAMPP_POSTGRESQL_ROOTDIR@@/bin/pg_ctl start -w -D @@XAMPP_POSTGRESQL_DATADIR@@"
POSTGRESQL_STOP="@@XAMPP_POSTGRESQL_ROOTDIR@@/bin/pg_ctl stop -D @@XAMPP_POSTGRESQL_DATADIR@@"

PGPORT=@@XAMPP_POSTGRESQL_PORT@@
POSTGRESQL_STATUS=""
POSTGRESQL_PID=""
PID=""
ERROR=0

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f "$PIDFILE" ] ; then
        PID=`head -1 $PIDFILE`
    fi
}

get_postgresql_pid() {
    get_pid $POSTGRESQL_PIDFILE
    if [ ! "$PID" ]; then
        return
    fi
    if [ "$PID" -gt 0 ]; then
        POSTGRESQL_PID=$PID
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

is_postgresql_running() {
    get_postgresql_pid
    is_service_running $POSTGRESQL_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        POSTGRESQL_STATUS="postgresql not running"
    else
        POSTGRESQL_STATUS="postgresql already running"
    fi
    return $RUNNING
}

start_postgresql() {
    is_postgresql_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: postgresql  (pid $POSTGRESQL_PID) already running"
	exit
    fi
    if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
	su postgres -c "$POSTGRESQL_START"
    else
	$POSTGRESQL_START 
    fi
    sleep 3
    is_postgresql_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        ERROR=1
    fi
    if [ $ERROR -eq 0 ]; then
	echo "$0 $ARG: postgresql  started at port @@XAMPP_POSTGRESQL_PORT@@"
	sleep 2
    else
	echo "$0 $ARG: postgresql  could not be started"
	ERROR=3
    fi
}

stop_postgresql() {
    NO_EXIT_ON_ERROR=$1
    is_postgresql_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $POSTGRESQL_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
    if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
        su postgres -c "$POSTGRESQL_STOP"
    else
        $POSTGRESQL_STOP
    fi
    sleep 5

    is_postgresql_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: postgresql stopped"
        else
            echo "$0 $ARG: postgresql could not be stopped. Trying to perform a \"fast\" shutdown."
            if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
                su postgres -c "$POSTGRESQL_STOP -m fast"
            else
                $POSTGRESQL_STOP -m fast
            fi
            sleep 5

            is_postgresql_running
            RUNNING=$?
            if [ $RUNNING -eq 0 ]; then
                    echo "$0 $ARG: postgresql stopped"
                else
                    echo "$0 $ARG: postgresql could not be stopped."
                    ERROR=4
            fi
    fi
}

cleanpid() {
    rm -f $POSTGRESQL_PIDFILE
}

if [ "x$1" = "xstart" ]; then
    start_postgresql
elif [ "x$1" = "xstop" ]; then
    stop_postgresql
elif [ "x$1" = "xstatus" ]; then
    is_postgresql_running
    echo "$POSTGRESQL_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR
