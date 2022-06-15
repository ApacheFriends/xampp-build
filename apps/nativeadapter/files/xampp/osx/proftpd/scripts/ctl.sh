#!/bin/sh

ERROR=0
FTP_STATUS=""
FTP_PIDFILE=/Applications/XAMPP/xamppfiles/var/proftpd.pid
FTPD=/Applications/XAMPP/xamppfiles/sbin/proftpd

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f "$PIDFILE" ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_ftp_pid() {
    get_pid $FTP_PIDFILE
    if [ ! "$PID" ]; then
        return
    fi
    if [ "$PID" -gt 0 ]; then
        FTP_PID=$PID
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

is_ftp_running() {
    get_ftp_pid
    is_service_running $FTP_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        FTP_STATUS="proftpd not running"
    else
        FTP_STATUS="proftpd already running"
    fi
    return $RUNNING
}

test_ftp_config() {
    if $FTPD -t; then
        ERROR=0
    else
        ERROR=8
        echo "proftpd config test fails, aborting"
        exit $ERROR
    fi
}

start_ftp() {
    test_ftp_config
    is_ftp_running
    RUNNING=$?

    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: proftpd (pid $FTP_PID) already running"
    else
        /Applications/XAMPP/xamppfiles/xampp startftp > /dev/null
	RESULT=$?
        if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: proftpd started"
        else
            echo "$0 $ARG: proftpd could not be started"
            ERROR=3
        fi
    fi
}


stop_ftp() {
    NO_EXIT_ON_ERROR=$1
    test_ftp_config
    is_ftp_running
    RUNNING=$?

    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $FTP_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi
    /Applications/XAMPP/xamppfiles/xampp stopftp > /dev/null
    RESULT=$?
        if [ $RESULT -eq 0 ]; then
            echo "$0 $ARG: proftpd stopped"
        else
            echo "$0 $ARG: proftpd could not be stopped"
            ERROR=4
        fi
}

cleanpid() {
    rm -f $FTP_PIDFILE
}

if [ "x$1" = "xstart" ]; then
	start_ftp
    sleep 5

elif [ "x$1" = "xstop" ]; then
    stop_ftp
	sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_ftp_running
    echo "$FTP_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR

