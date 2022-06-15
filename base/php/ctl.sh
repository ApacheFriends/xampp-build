#!/bin/sh

PHPFPM_PREFIX="@@XAMPP_PHPFPM_ROOTDIR@@"
PHPFPM_PIDFILE="$PHPFPM_PREFIX/var/run/php5-fpm.pid"
PHPFPM_SERVER="$PHPFPM_PREFIX/sbin/php-fpm"
PHPFPM_CONFIG_FILE="$PHPFPM_PREFIX/etc/php-fpm.conf"
PHP_INI="$PHPFPM_PREFIX/etc/php.ini"
PHPFPM_OPTIONS="--pid $PHPFPM_PIDFILE --fpm-config $PHPFPM_CONFIG_FILE --prefix $PHPFPM_PREFIX -c $PHP_INI"
PHPFPM_START_CMD="$PHPFPM_SERVER $PHPFPM_OPTIONS"
PHPFPM_CHECK_CONFIG_CMD="$PHPFPM_SERVER $PHPFPM_OPTIONS -t"
PHPFPM_STATUS=""
PHPFPM_PID=""
ERROR=0

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f "$PIDFILE" ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_phpfpm_pid() {
    get_pid $PHPFPM_PIDFILE
    if [ ! "$PID" ]; then
        return
    fi
    if [ "$PID" -gt 0 ]; then
        PHPFPM_PID=$PID
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

is_phpfpm_running() {
    get_phpfpm_pid
    is_service_running $PHPFPM_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        PHPFPM_STATUS="php-fpm not running"
    else
        PHPFPM_STATUS="php-fpm already running"
    fi
    return $RUNNING
}

start_phpfpm() {
    is_phpfpm_running
    RUNNING=$?

    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: php-fpm (pid $PHPFPM_PID) already running"
    else
        if $PHPFPM_CHECK_CONFIG_CMD ; then
            if $PHPFPM_START_CMD 2> /dev/null ; then
                echo "$0 $ARG: php-fpm started"
            else
                echo "$0 $ARG: php-fpm could not be started"
                ERROR=3
            fi
        else
            echo "$0 $ARG: php-fpm configuration is incorrect"
            ERROR=3
        fi
    fi
}

stop_phpfpm() {
    NO_EXIT_ON_ERROR=$1
    is_phpfpm_running
    RUNNING=$?

    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $PHPFPM_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
    kill $PHPFPM_PID
    sleep 5
    is_phpfpm_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: php-fpm stopped"
    else
        echo "$0 $ARG: php-fpm could not be stopped"
        ERROR=4
    fi
}


cleanpid() {
    rm -f $PHPFPM_PIDFILE
}

if [ "x$1" = "xstart" ]; then
	start_phpfpm
    sleep 5

elif [ "x$1" = "xstop" ]; then
    stop_phpfpm
	sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_phpfpm_running
    echo "$PHPFPM_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR

