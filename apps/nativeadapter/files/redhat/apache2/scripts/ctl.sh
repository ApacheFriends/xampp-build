#!/bin/sh

ERROR=0
HTTPD_STATUS=""

test_apache_config() {
     if [ -d /etc/systemd ]; then
         apachectl -t > /dev/null
     else
         /etc/init.d/httpd configtest > /dev/null
     fi
     RESULT=$?
     if [ $RESULT -eq 0 ]; then
        ERROR=0
     else
        ERROR=8
        echo "apache config test fails, aborting"
        exit $ERROR
    fi
}

is_apache_running() {
    if [ -d /etc/systemd ]; then
        systemctl -q status httpd.service > /dev/null
    else
         /etc/init.d/httpd status > /dev/null
    fi
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
    test_apache_config
    is_apache_running
    RUNNING=$?

    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: httpd already running"
    else
        if [ -d /etc/systemd ]; then
            systemctl -q start httpd.service > /dev/null
        else
            /etc/init.d/httpd start > /dev/null
        fi        
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
    test_apache_config
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
    if [ -d /etc/systemd ]; then
        systemctl -q stop httpd.service > /dev/null
    else
        /etc/init.d/httpd stop > /dev/null
    fi
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

