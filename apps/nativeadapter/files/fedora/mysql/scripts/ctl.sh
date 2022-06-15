#!/bin/sh

MYSQL_STATUS=""
ERROR=0

is_mysql_running() {
    systemctl -q status mysqld.service > /dev/null
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        MYSQL_STATUS="mysql already running"
	return 1
    else
        MYSQL_STATUS="mysql not running"
	return 0
    fi
}

start_mysql() {
    is_mysql_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: mysql already running"
	exit
    fi
    systemctl -q  start mysqld.service > /dev/null
    RESULT=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: mysqld started"
    else
        echo "$0 $ARG: mysqld could not be started"
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

    systemctl stop mysqld.service > /dev/null
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        echo "$0 $ARG: mysqld stopped"
    else
        echo "$0 $ARG: mysqld could not be stopped"
        ERROR=4
    fi
}

if [ "x$1" = "xstart" ]; then
    start_mysql
elif [ "x$1" = "xstop" ]; then
    stop_mysql
elif [ "x$1" = "xstatus" ]; then
    is_mysql_running
    echo "$MYSQL_STATUS"
fi

exit $ERROR
