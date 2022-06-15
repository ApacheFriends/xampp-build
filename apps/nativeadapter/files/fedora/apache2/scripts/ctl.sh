#!/bin/sh

ERROR=0
HTTPD_STATUS=""

is_apache_running() {
    systemctl -q status httpd.service > /dev/null
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        HTTPD_STATUS="apache already running"
	return 1
    else
        HTTPD_STATUS="apache not running"
	return 0
    fi
}

start_apache() {
    is_apache_running
    RUNNING=$?

    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: httpd already running"
    else
        systemctl -q  start httpd.service > /dev/null
	RESULT=$?
        if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: httpd started"
        else
            echo "$0 $ARG: httpd could not be started"
            ERROR=3
        fi
    fi
}

stop_apache() {
    NO_EXIT_ON_ERROR=$1
    is_apache_running
    RUNNING=$?

    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $HTTPD_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
    systemctl stop httpd.service > /dev/null
    RESULT=$?
        if [ $RESULT -eq 0 ]; then
            echo "$0 $ARG: httpd stopped"
        else
            echo "$0 $ARG: httpd could not be stopped"
            ERROR=4
        fi
}


if [ "x$1" = "xstart" ]; then
	start_apache
    sleep 5

elif [ "x$1" = "xstop" ]; then
    stop_apache
	sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_apache_running
    echo "$HTTPD_STATUS"
fi

exit $ERROR

