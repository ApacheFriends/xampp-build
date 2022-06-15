#!/bin/sh

ERROR=0
OPTIONS="-r @@XAMPP_SUBVERSION_REPOSITORY@@ --listen-port=@@XAMPP_SUBVERSION_PORT@@"
export OPTIONS

is_subversion_running() {
    if [ -d /etc/systemd ]; then
        systemctl -q status svnserve.service > /dev/null
    else
        /etc/init.d/svnserve status > /dev/null
    fi
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        SVNSERVE_STATUS="subversion already running"
	return 1
    else
        SVNSERVE_STATUS="subversion not running"
	return 0
    fi
}

start_subversion() {
    is_subversion_running
    RUNNING=$?

    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: subversion already running"
    else
        if [ -d /etc/systemd ]; then
            systemctl -q start svnserve.service > /dev/null
        else
            /etc/init.d/svnserve start > /dev/null
        fi
	    RESULT=$?
        if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: subversion started"
        else
            echo "$0 $ARG: subversion could not be started"
            ERROR=3
        fi
    fi
}

stop_subversion() {
    NO_EXIT_ON_ERROR=$1
    is_subversion_running
    RUNNING=$?

    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $SVNSERVE_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
    if [ -d /etc/systemd ]; then
        systemctl -q stop svnserve.service > /dev/null
    else
        /etc/init.d/svnserve stop > /dev/null
    fi
    RESULT=$?
        if [ $RESULT -eq 0 ]; then
            echo "$0 $ARG: subversion stopped"
        else
            echo "$0 $ARG: subversion could not be stopped"
            ERROR=4
        fi
}


if [ "x$1" = "xstart" ]; then
	start_subversion
    sleep 5

elif [ "x$1" = "xstop" ]; then
    stop_subversion
	sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_subversion_running
    echo "$SVNSERVE_STATUS"
fi

exit $ERROR

