#!/bin/sh

MYSQL_STATUS=""
ERROR=0
MYSQL_SERVICE=@@XAMPP_MYSQL_TYPE@@

is_mysql_running() {
    if [ "$MYSQL_SERVICE" == "MariaDB" ]; then
        systemctl -q status mariadb.service > /dev/null
    else
        /etc/init.d/mysqld status > /dev/null
    fi
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
	else
        if [ "$MYSQL_SERVICE" == "MariaDB"  ]; then
            systemctl -q start mariadb.service > /dev/null
        else
            /etc/init.d/mysqld start > /dev/null
        fi
        RESULT=$?
        if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: mysqld started"
        else
            echo "$0 $ARG: mysqld could not be started"
	        ERROR=3
        fi
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
    if [ "$MYSQL_SERVICE" == "MariaDB"  ]; then
        systemctl -q stop mariadb.service > /dev/null
    else
        /etc/init.d/mysqld stop > /dev/null
    fi
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        echo "$0 $ARG: mysqld stopped"
    else
        echo "$0 $ARG: mysqld could not be stopped"
        ERROR=4
    fi
}

if [ "$MYSQL_SERVICE" == "MariaDB"  ]; then
    if [ ! -f /etc/systemd/system/multi-user.target.wants/mariadb.service ]; then
        echo "mysql not installed"
    elif [ "x$1" = "xstart" ]; then
        start_mysql
    elif [ "x$1" = "xstop" ]; then
        stop_mysql
    elif [ "x$1" = "xstatus" ]; then
        is_mysql_running
        echo "$MYSQL_STATUS"
    fi
else
    if [ ! -f /etc/init.d/mysqld ]; then
        echo "mysql not installed"
    elif [ "x$1" = "xstart" ]; then
        start_mysql
    elif [ "x$1" = "xstop" ]; then
        stop_mysql
    elif [ "x$1" = "xstatus" ]; then
        is_mysql_running
        echo "$MYSQL_STATUS"
    fi
fi

exit $ERROR
