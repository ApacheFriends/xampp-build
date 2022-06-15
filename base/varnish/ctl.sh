#! /bin/sh

VARNISH_SERVER_ID=@@XAMPP_VARNISH_ID@@
VARNISH_PIDFILE="@@XAMPP_VARNISH_ROOTDIR@@/var/$VARNISH_SERVER_ID/varnishd.pid"
VARNISH_SERVER=@@XAMPP_VARNISH_ROOTDIR@@/bin/varnishd
VARNISH_CONFIG_FILE=@@XAMPP_VARNISH_CONFIGFILE@@
VARNISH_SECRET_FILE="@@XAMPP_VARNISH_ROOTDIR@@/etc/$VARNISH_SERVER_ID/secret"
VARNISH_PORT=@@XAMPP_VARNISH_PORT@@
VARNISH_WORKING_DIR="@@XAMPP_VARNISH_ROOTDIR@@/var/$VARNISH_SERVER_ID"
VARNISH_STORAGE_FILE="@@XAMPP_VARNISH_ROOTDIR@@/var/$VARNISH_SERVER_ID/varnish_storage.bin"
VARNISH_STORAGE_SIZE=1G
VARNISH_STORAGE="file,${VARNISH_STORAGE_FILE},${VARNISH_STORAGE_SIZE}"
VARNISH_LISTEN_ADDRESS=
VARNISH_OPTIONS="-a ${VARNISH_LISTEN_ADDRESS}:${VARNISH_PORT} -f ${VARNISH_CONFIG_FILE} -s ${VARNISH_STORAGE} -P $VARNISH_PIDFILE -n $VARNISH_WORKING_DIR -p vmod_dir=@@XAMPP_VARNISH_ROOTDIR@@/lib/varnish/vmods"

if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
    VARNISH_OPTIONS="-j unix,user=varnish $VARNISH_OPTIONS"
fi

VARNISH_START_CMD="$VARNISH_SERVER $VARNISH_OPTIONS"

VARNISH_STATUS=""
VARNISH_PID=""
ERROR=0

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f "$PIDFILE" ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_varnish_pid() {
    get_pid $VARNISH_PIDFILE
    if [ ! "$PID" ]; then
        return
    fi
    if [ "$PID" -gt 0 ]; then
        VARNISH_PID=$PID
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

is_varnish_running() {
    get_varnish_pid
    is_service_running $VARNISH_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        VARNISH_STATUS="varnish not running"
    else
        VARNISH_STATUS="varnish already running"
    fi
    return $RUNNING
}

start_varnish() {
    is_varnish_running
    RUNNING=$?

    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: varnish (pid $VARNISH_PID) already running"
    else
        if $VARNISH_START_CMD ; then
            echo "$0 $ARG: varnish started at port $VARNISH_PORT"
        else
            echo "$0 $ARG: varnish could not be started"
            ERROR=3
        fi
    fi
}

stop_varnish() {
    NO_EXIT_ON_ERROR=$1
    is_varnish_running
    RUNNING=$?

    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $VARNISH_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
    kill $VARNISH_PID
    sleep 5
    is_varnish_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: varnish stopped"
    else
        echo "$0 $ARG: varnish could not be stopped"
        ERROR=4
    fi
}


cleanpid() {
    rm -f $VARNISH_PIDFILE
}

if [ "x$1" = "xstart" ]; then
	start_varnish
    sleep 5

elif [ "x$1" = "xstop" ]; then
    stop_varnish
	sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_varnish_running
    echo "$VARNISH_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR

