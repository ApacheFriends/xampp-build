#!/bin/sh

CATALINA_HOME=@@XAMPP_TOMCAT_ROOTDIR@@
TOMCAT_BINDIR=@@XAMPP_TOMCAT_ROOTDIR@@/bin
JRE_HOME=@@XAMPP_JAVA_ROOTDIR@@
CATALINA_PID=@@XAMPP_TOMCAT_ROOTDIR@@/temp/catalina.pid
export CATALINA_PID
TOMCAT_STATUS=""
ERROR=0
CDBG=0
PID=""
ALLOW_TOMCAT_ASROOT=1
TOMCAT_ASTOMCATUSER=0
JSVC_ENABLED=0

if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ] && [ $ALLOW_TOMCAT_ASROOT -eq 0 ]; then
    TOMCAT_ASTOMCATUSER=1
fi

cleanpid() {
    rm -f $CATALINA_PID
}

prepare_stack_debugger() {
    cd $CATALINA_HOME/scripts
    wget -O /tmp/format_env_gce.sh -qnc https://storage.googleapis.com/cloud-debugger/compute-java/format_env_gce.sh
    if [ $( file /tmp/format_env_gce.sh | grep "shell script" | wc -l ) -ne 0 ]; then
        cp /tmp/format_env_gce.sh .
    fi
    chmod +x ./format_env_gce.sh
    CDBG_ARGS="$( ./format_env_gce.sh --app_class_path=$TOMCAT_BINDIR/bootstrap.jar --app_class_path=$TOMCAT_BINDIR/tomcat-juli.jar)"
    if [ $? -ne -0 ]; then
        echo "$0 $ARG: Could not configure Google Stackdrive Debugger. Run sudo $CATALINA_HOME/scripts/format_env_gce.sh --verbose for more information."
    elif [ $( echo "$CDBG_ARGS" | grep "cdbg_java_agent" | wc -l ) -eq 0  ]; then
        echo "$0 $ARG: Could not configure Google Stackdrive Debugger. Run sudo $CATALINA_HOME/scripts/format_env_gce.sh --verbose for more information."
    else
        JAVA_OPTS="$JAVA_OPTS $CDBG_ARGS"
        export JAVA_OPTS
    fi
    cd -
}

start_tomcat() {
    is_tomcat_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: tomcat (pid $PID) already running"
    else
        if [ $CDBG -eq 1 ]; then
            prepare_stack_debugger
        fi
        cleanpid
	export JAVA_HOME=$JRE_HOME
	previousdir=`pwd`
	cd $CATALINA_HOME/logs
	if [ $TOMCAT_ASTOMCATUSER -eq 1 ] && [ $JSVC_ENABLED -eq 1 ]; then
	    $TOMCAT_BINDIR/daemon.sh start
        elif [ $TOMCAT_ASTOMCATUSER -eq 1 ] && [ $JSVC_ENABLED -eq 0 ]; then
	    su tomcat -s /bin/sh -c "$TOMCAT_BINDIR/startup.sh"
        else
	    $TOMCAT_BINDIR/startup.sh
	fi
        sleep 5
        is_tomcat_running
        RUNNING=$?
	if [ $RUNNING -eq 1 ];  then
            echo "$0 $ARG: tomcat started"
	else
            echo "$0 $ARG: tomcat could not be started"
            ERROR=1
	fi
	cd $previousdir
    fi
}

daemon_tomcat() {
    export JAVA_HOME=$JRE_HOME
    if [ $TOMCAT_ASTOMCATUSER -eq 1 ] && [ $JSVC_ENABLED -eq 1 ]; then
      $TOMCAT_BINDIR/daemon.sh start
    elif [ $TOMCAT_ASTOMCATUSER -eq 1 ] && [ $JSVC_ENABLED -eq 0 ]; then
	    su tomcat -s /bin/sh -c "$TOMCAT_BINDIR/catalina.sh run"
    else
      $TOMCAT_BINDIR/catalina.sh run
    fi
}

stop_tomcat() {
    is_tomcat_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $TOMCAT_STATUS"
        exit
    fi
    if [ $TOMCAT_ASTOMCATUSER -eq 1 ] && [ $JSVC_ENABLED -eq 1 ]; then
	    $TOMCAT_BINDIR/daemon.sh stop
    elif [ $TOMCAT_ASTOMCATUSER -eq 1 ] && [ $JSVC_ENABLED -eq 0 ]; then
	    su tomcat -s /bin/sh -c "$TOMCAT_BINDIR/shutdown.sh"
    else
	    $TOMCAT_BINDIR/shutdown.sh
    fi
    sleep 2
    is_tomcat_running
    RUNNING=$?
    COUNTER=30
    while [ $RUNNING -ne 0 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 2
        is_tomcat_running
        RUNNING=$?
    done
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: tomcat stopped"
        sleep 3
    else
        echo "$0 $ARG: tomcat could not be stopped"
        ERROR=2
    fi
}

get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile
    if [ -f $PIDFILE ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_tomcat_pid() {
    get_pid $CATALINA_PID
    if [ ! $PID ]; then
        return
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

is_tomcat_running() {
    get_tomcat_pid
    is_service_running $PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        TOMCAT_STATUS="tomcat not running"
    else
        TOMCAT_STATUS="tomcat already running"
    fi
    return $RUNNING
}

if [ "x$1" = "xstart" ]; then
    start_tomcat
    sleep 2
elif [ "x$1" = "xdaemon" ]; then
    daemon_tomcat
elif [ "x$1" = "xstop" ]; then
    stop_tomcat
    sleep 2
elif [ "x$1" = "xstatus" ]; then
    is_tomcat_running
    echo $TOMCAT_STATUS
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR
