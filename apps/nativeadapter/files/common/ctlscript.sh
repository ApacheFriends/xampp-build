#!/bin/sh

# Disabling SELinux if enabled
if [ -f "/usr/sbin/getenforce" ] && [ `id -u` = 0 ] ; then
    selinux_status=`/usr/sbin/getenforce`
    /usr/sbin/setenforce 0 2> /dev/null
fi

INSTALLDIR=@@XAMPP_INSTALLDIR@@

if [ -r "$INSTALLDIR/scripts/setenv.sh" ]; then
. "$INSTALLDIR/scripts/setenv.sh"
fi

ERROR=0
MYSQL_SCRIPT=$INSTALLDIR/mysql/scripts/ctl.sh
INGRES_SCRIPT=$INSTALLDIR/ingres/scripts/ctl.sh
PROFTP_SCRIPT=$INSTALLDIR/proftpd/scripts/ctl.sh
APACHE_SCRIPT=$INSTALLDIR/apache2/scripts/ctl.sh
HYPERSONIC_SCRIPT=$INSTALLDIR/hypersonic/scripts/ctl.sh
TOMCAT_SCRIPT=$INSTALLDIR/apache-tomcat/scripts/ctl.sh
RESIN_SCRIPT=$INSTALLDIR/resin/scripts/ctl.sh
SUBVERSION_SCRIPT=$INSTALLDIR/subversion/scripts/ctl.sh
OPENOFFICE_SCRIPT=$INSTALLDIR/openoffice/scripts/ctl.sh
#RUBY_APPLICATION_SCRIPT
LUCENE_SCRIPT=$INSTALLDIR/lucene/scripts/ctl.sh
ZOPE_SCRIPT=$INSTALLDIR/zope_application/scripts/ctl.sh
THIRD_SCRIPT=$INSTALLDIR/third_application/scripts/ctl.sh
POSTGRESQL_SCRIPT=$INSTALLDIR/postgresql/scripts/ctl.sh
NAGIOS_SCRIPT=$INSTALLDIR/nagios/scripts/ctl.sh
JETTY_SCRIPT=$INSTALLDIR/jetty/scripts/ctl.sh
MEMCACHED_SCRIPT=$INSTALLDIR/memcached/scripts/ctl.sh
RABBITMQ_SCRIPT=$INSTALLDIR/rabbitmq-server/scripts/ctl.sh

help() {
	echo "usage: $0 help"
	echo "       $0 (start|stop|restart|status)"
	if test -x $MYSQL_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) mysql"
	fi
        if test -x $POSTGRESQL_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) postgresql"
	fi
	if test -x $INGRES_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) ingres"
	fi
	if test -x $MEMCACHED_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) memcached"
	fi
        if test -x $PROFTP_SCRIPT; then
             echo "       $0 (start|stop|restart|status) proftpd"
        fi
	if test -x $APACHE_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) apache"
	fi
	if test -x $HYPERSONIC_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) hypersonic"
	fi
	if test -x $TOMCAT_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) tomcat"
	fi
	if test -x $RESIN_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) resin"
	fi
	if test -x $SUBVERSION_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) subversion"
	fi
	if test -x $OPENOFFICE_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) openoffice"
	fi
        #RUBY_APPLICATION_HELP
	if test -x $LUCENE_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) lucene"
	fi
	if test -x $RABBITMQ_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) rabbitmq"
	fi
	if test -x $ZOPE_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) zope_application"
	fi
	if test -x $THIRD_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) third_application"
	fi
	if test -x $NAGIOS_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) nagios"
	fi
	if test -x $JETTY_SCRIPT; then
	    echo "       $0 (start|stop|restart|status) jetty"
	fi
	cat <<EOF

help       - this screen
start      - start the service(s)
stop       - stop  the service(s)
restart    - restart or start the service(s)
status     - show the status of the service(s)

EOF
}


# Disable Monit
if [ -f "$INSTALLDIR/config/monit/bitnami.conf" ] && [ `id -u` = 0 ] && [ `which monit 2> /dev/null` ] && ( [ "x$1" = "xstop" ] || [ "x$1" = "xrestart" ] ); then
    if [ "x$2" = "x" ]; then
        env -i monit unmonitor all
    elif [ -f "$INSTALLDIR/config/monit/conf.d/$2.conf" ]; then
        env -i monit unmonitor $2
    fi
fi


if [ "x$1" = "xhelp" ] || [ "x$1" = "x" ]; then
    help
elif [ "x$1" = "xstart" ]; then

    if [ "x$2" = "xmysql" ]; then
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT start
            MYSQL_ERROR=$?
        fi
    elif [ "x$2" = "xpostgresql" ]; then
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT start
            POSTGRESQL_ERROR=$?
        fi
    elif [ "x$2" = "xingres" ]; then
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT start
            INGRES_ERROR=$?
        fi
    elif [ "x$2" = "xopenoffice" ]; then
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT start
            OPENOFFICE_ERROR=$?
        fi
    elif [ "x$2" = "xhypersonic" ]; then
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT start
            HYPERSONIC_ERROR=$?
        fi
    elif [ "x$2" = "xmemcached" ]; then
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT start
            MEMCACHED_ERROR=$?
        fi
    elif [ "x$2" = "xtomcat" ]; then
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT start
            TOMCAT_ERROR=$?
        fi
    elif [ "x$2" = "xresin" ]; then
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT start
            RESIN_ERROR=$?
        fi
    #RUBY_APPLICATION_START
    elif [ "x$2" = "xrabbitmq" ]; then
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT start
            RABBITMQ_ERROR=$?
        fi
    elif [ "x$2" = "xzope_application" ]; then
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT start
            ZOPE_ERROR=$?
        fi
    elif [ "x$2" = "xlucene" ]; then
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT start
            LUCENE_ERROR=$?
        fi
    elif [ "x$2" = "xproftpd" ]; then
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT start
            PROFTP_ERROR=$?
        fi
    elif [ "x$2" = "xapache" ]; then
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT start
            APACHE_ERROR=$?
        fi
    elif [ "x$2" = "xsubversion" ]; then
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT start
            SUBVERSION_ERROR=$?
        fi
    elif [ "x$2" = "xthird_application" ]; then
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT start
            THIRD_ERROR=$?
        fi
    elif [ "x$2" = "xnagios" ]; then
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT start
            NAGIOS_ERROR=$?
        fi
    elif [ "x$2" = "xjetty" ]; then
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT start
            JETTY_ERROR=$?
        fi
    else
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT start
            MYSQL_ERROR=$?
            sleep 5
        fi
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT start
            POSTGRESQL_ERROR=$?
            sleep 5
        fi
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT start
            INGRES_ERROR=$?
            sleep 5
        fi

        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT start
            OPENOFFICE_ERROR=$?
        fi

        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT start
            HYPERSONIC_ERROR=$?
        fi

        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT start
            MEMCACHED_ERROR=$?
        fi

        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT start
            TOMCAT_ERROR=$?
        fi

        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT start
            RESIN_ERROR=$?
        fi
        #RUBY_APPLICATION_GENERIC_START

        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT start
            RABBITMQ_ERROR=$?
        fi

        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT start
            ZOPE_ERROR=$?
        fi

        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT start
            LUCENE_ERROR=$?
        fi
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT start
            PROFTP_ERROR=$?
        fi
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT start
            APACHE_ERROR=$?
        fi

        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT start
            SUBVERSION_ERROR=$?
        fi
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT start
            THIRD_ERROR=$?
        fi
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT start
            NAGIOS_ERROR=$?
        fi
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT start
            JETTY_ERROR=$?
        fi

    fi


elif [ "x$1" = "xstop" ]; then

    if [ "x$2" = "xmysql" ]; then
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT stop
            MYSQL_ERROR=$?
            sleep 2
        fi
    elif [ "x$2" = "xpostgresql" ]; then
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT stop
            POSTGRESQL_ERROR=$?
            sleep 5
        fi
    elif [ "x$2" = "xingres" ]; then
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT stop
            INGRES_ERROR=$?
            sleep 5
        fi
    elif [ "x$2" = "xopenoffice" ]; then
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT stop
            OPENOFFICE_ERROR=$?
        fi
    elif [ "x$2" = "xhypersonic" ]; then
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT stop
            HYPERSONIC_ERROR=$?
        fi
    elif [ "x$2" = "xmemcached" ]; then
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT stop
            MEMCACHED_ERROR=$?
        fi
    elif [ "x$2" = "xtomcat" ]; then
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT stop
            TOMCAT_ERROR=$?
        fi
    elif [ "x$2" = "xresin" ]; then
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT stop
            RESIN_ERROR=$?
        fi
    #RUBY_APPLICATION_STOP
    elif [ "x$2" = "xrabbitmq" ]; then
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT stop
            RABBITMQ_ERROR=$?
        fi
    elif [ "x$2" = "xzope_application" ]; then
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT stop
            ZOPE_ERROR=$?
        fi
    elif [ "x$2" = "xlucene" ]; then
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT stop
            LUCENE_ERROR=$?
        fi
    elif [ "x$2" = "xproftpd" ]; then
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT stop
            PROFTP_ERROR=$?
        fi
    elif [ "x$2" = "xapache" ]; then
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT stop
            APACHE_ERROR=$?
        fi
    elif [ "x$2" = "xsubversion" ]; then
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT stop
            SUBVERSION_ERROR=$?
        fi
    elif [ "x$2" = "xthird_application" ]; then
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT stop
            THIRD_ERROR=$?
        fi
    elif [ "x$2" = "xnagios" ]; then
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT stop
            NAGIOS_ERROR=$?
        fi
    elif [ "x$2" = "xjetty" ]; then
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT stop
            JETTY_ERROR=$?
        fi
    else
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT stop
            HYPERSONIC_ERROR=$?
        fi
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT stop
            JETTY_ERROR=$?
        fi
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT stop
            NAGIOS_ERROR=$?
        fi
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT stop
            THIRD_ERROR=$?
        fi
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT stop
            SUBVERSION_ERROR=$?
        fi
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT stop
            PROFTP_ERROR=$?
        fi
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT stop
            APACHE_ERROR=$?
        fi
        #RUBY_APPLICATION_GENERIC_STOP

        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT stop
            ZOPE_ERROR=$?
        fi
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT stop
            RABBITMQ_ERROR=$?
        fi
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT stop
            LUCENE_ERROR=$?
        fi
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT stop
            TOMCAT_ERROR=$?
            sleep 3
        fi
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT stop
            RESIN_ERROR=$?
            sleep 3
        fi
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT stop
            MEMCACHED_ERROR=$?
        fi
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT stop
            OPENOFFICE_ERROR=$?
        fi
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT stop
            MYSQL_ERROR=$?
        fi
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT stop
            INGRES_ERROR=$?
        fi
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT stop
            POSTGRESQL_ERROR=$?
        fi

    fi

elif [ "x$1" = "xrestart" ]; then

    if [ "x$2" = "xmysql" ]; then
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT stop
            sleep 2
            $MYSQL_SCRIPT start
            MYSQL_ERROR=$?
        fi
    elif [ "x$2" = "xpostgresql" ]; then
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT stop
            sleep 5
            $POSTGRESQL_SCRIPT start
            POSTGRESQL_ERROR=$?
        fi
   elif [ "x$2" = "xingres" ]; then
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT stop
            sleep 5
            $INGRES_SCRIPT start
            INGRES_ERROR=$?
        fi
    elif [ "x$2" = "xopenoffice" ]; then
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT stop
            sleep 2
            $OPENOFFICE_SCRIPT start
            OPENOFFICE_ERROR=$?
        fi
    elif [ "x$2" = "xhypersonic" ]; then
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT stop
            sleep 2
            $HYPERSONIC_SCRIPT start
            HYPERSONIC_ERROR=$?
        fi
    elif [ "x$2" = "xmemcached" ]; then
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT stop
            $MEMCACHED_SCRIPT start
            MEMCACHED_ERROR=$?
        fi
    elif [ "x$2" = "xtomcat" ]; then
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT stop
            sleep 5
            $TOMCAT_SCRIPT start
            TOMCAT_ERROR=$?
        fi
    elif [ "x$2" = "xresin" ]; then
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT stop
            sleep 5
            $RESIN_SCRIPT start
            RESIN_ERROR=$?
        fi
    #RUBY_APPLICATION_RESTART

    elif [ "x$2" = "xrabbitmq" ]; then
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT stop
            sleep 2
            $RABBITMQ_SCRIPT start
            RABBITMQ_ERROR=$?
        fi
    elif [ "x$2" = "xzope_application" ]; then
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT stop
            sleep 2
            $ZOPE_SCRIPT start
            ZOPE_ERROR=$?
        fi
    elif [ "x$2" = "xlucene" ]; then
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT stop
            sleep 2
            $LUCENE_SCRIPT start
            LUCENE_ERROR=$?
        fi
    elif [ "x$2" = "xproftpd" ]; then
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT stop
            sleep 2
            $PROFTP_SCRIPT start
            PROFTP_ERROR=$?
        fi

    elif [ "x$2" = "xapache" ]; then
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT stop
            sleep 2
            $APACHE_SCRIPT start
            APACHE_ERROR=$?
        fi
    elif [ "x$2" = "xsubversion" ]; then
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT stop
            sleep 2
            $SUBVERSION_SCRIPT start
            SUBVERSION_ERROR=$?
        fi
    elif [ "x$2" = "xthird_application" ]; then
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT stop
            sleep 2
            $THIRD_SCRIPT start
            THIRD_ERROR=$?
        fi
    elif [ "x$2" = "xnagios" ]; then
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT stop
            sleep 2
            $NAGIOS_SCRIPT start
            NAGIOS_ERROR=$?
        fi
    elif [ "x$2" = "xjetty" ]; then
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT stop
            sleep 2
            $JETTY_SCRIPT start
            JETTY_ERROR=$?
        fi
    else
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT stop
            HYPERSONIC_ERROR=$?
        fi
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT stop
            JETTY_ERROR=$?
        fi
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT stop
            NAGIOS_ERROR=$?
        fi
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT stop
            THIRD_ERROR=$?
        fi
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT stop
            SUBVERSION_ERROR=$?
        fi
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT stop
            PROFTP_ERROR=$?
        fi
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT stop
            APACHE_ERROR=$?
        fi
        #RUBY_APPLICATION_GENERIC_STOP
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT stop
            ZOPE_ERROR=$?
        fi
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT stop
            LUCENE_ERROR=$?
        fi
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT stop
            TOMCAT_ERROR=$?
        fi
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT stop
            RESIN_ERROR=$?
        fi
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT stop
            $MEMCACHED_SCRIPT start
            MEMCACHED_ERROR=$?
        fi
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT stop
            OPENOFFICE_ERROR=$?
        fi
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT stop
            sleep 2
            $MYSQL_SCRIPT start;
            MYSQL_ERROR=$?
            sleep 2
        fi
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT stop
            sleep 2
            $POSTGRESQL_SCRIPT start;
            POSTGRESQL_ERROR=$?
            sleep 2
        fi
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT stop
            sleep 7
            $INGRES_SCRIPT start;
            INGRES_ERROR=$?
            sleep 2
        fi
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT start
            OPENOFFICE_ERROR=$?
        fi
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT start
            TOMCAT_ERROR=$?
        fi
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT start
            RESIN_ERROR=$?
        fi
        #RUBY_APPLICATION_GENERIC_START
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT start
            RABBITMQ_ERROR=$?
        fi
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT start
            ZOPE_ERROR=$?
        fi
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT start
            PROFTP_ERROR=$?
        fi
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT start
            APACHE_ERROR=$?
        fi
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT start
            SUBVERSION_ERROR=$?
        fi
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT start
            THIRD_ERROR=$?
        fi
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT start
            NAGIOS_ERROR=$?
        fi
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT start
            JETTY_ERROR=$?
        fi
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT start
            HYPERSONIC_ERROR=$?
        fi
    fi

elif [ "x$1" = "xstatus" ]; then

    if [ "x$2" = "xmysql" ]; then
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT status
            sleep 2
        fi
    elif [ "x$2" = "xopenoffice" ]; then
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT status
        fi
    elif [ "x$2" = "xingres" ]; then
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT status
        fi
    elif [ "x$2" = "xpostgresql" ]; then
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT status
            sleep 2
        fi
    elif [ "x$2" = "xhypersonic" ]; then
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT status
        fi
    elif [ "x$2" = "xmemcached" ]; then
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT status
        fi
    elif [ "x$2" = "xtomcat" ]; then
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT status
        fi
    elif [ "x$2" = "xresin" ]; then
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT status
        fi
    #RUBY_APPLICATION_STATUS
    elif [ "x$2" = "xrabbitmq" ]; then
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT status
        fi
    elif [ "x$2" = "xzope_application" ]; then
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT status
        fi
    elif [ "x$2" = "xlucene" ]; then
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT status
        fi
    elif [ "x$2" = "xproftpd" ]; then
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT status
        fi
    elif [ "x$2" = "xapache" ]; then
        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT status
        fi
    elif [ "x$2" = "xsubversion" ]; then
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT status
        fi
    elif [ "x$2" = "xthird_application" ]; then
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT status
        fi
    elif [ "x$2" = "xnagios" ]; then
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT status
        fi
    elif [ "x$2" = "xjetty" ]; then
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT status
        fi
    else
        if test -x $HYPERSONIC_SCRIPT; then
            $HYPERSONIC_SCRIPT status
        fi
        if test -x $JETTY_SCRIPT; then
            $JETTY_SCRIPT status
        fi
        if test -x $NAGIOS_SCRIPT; then
            $NAGIOS_SCRIPT status
        fi
        if test -x $THIRD_SCRIPT; then
            $THIRD_SCRIPT status
        fi
        if test -x $SUBVERSION_SCRIPT; then
            $SUBVERSION_SCRIPT status
        fi
        if test -x $PROFTP_SCRIPT; then
            $PROFTP_SCRIPT status
        fi

        if test -x $APACHE_SCRIPT; then
            $APACHE_SCRIPT status
        fi
        #RUBY_APPLICATION_GENERIC_STATUS
        if test -x $RABBITMQ_SCRIPT; then
            $RABBITMQ_SCRIPT status
        fi
        if test -x $ZOPE_SCRIPT; then
            $ZOPE_SCRIPT status
        fi
        if test -x $LUCENE_SCRIPT; then
            $LUCENE_SCRIPT status
        fi
        if test -x $INGRES_SCRIPT; then
            $INGRES_SCRIPT status
        fi
        if test -x $TOMCAT_SCRIPT; then
            $TOMCAT_SCRIPT status
            sleep 3
        fi
        if test -x $RESIN_SCRIPT; then
            $RESIN_SCRIPT status
            sleep 3
        fi
        if test -x $OPENOFFICE_SCRIPT; then
            $OPENOFFICE_SCRIPT status
        fi
        if test -x $MYSQL_SCRIPT; then
            $MYSQL_SCRIPT status
        fi
        if test -x $POSTGRESQL_SCRIPT; then
            $POSTGRESQL_SCRIPT status
            sleep 3
        fi
        if test -x $MEMCACHED_SCRIPT; then
            $MEMCACHED_SCRIPT status
        fi

    fi
elif [ "x$1" = "xcleanpid" ]; then
    if test -x $HYPERSONIC_SCRIPT; then
        $HYPERSONIC_SCRIPT cleanpid
    fi
    if test -x $NAGIOS_SCRIPT; then
        $NAGIOS_SCRIPT cleanpid
    fi
    if test -x $SUBVERSION_SCRIPT; then
        $SUBVERSION_SCRIPT cleanpid
    fi
    if test -x $PROFTP_SCRIPT; then
        $PROFTP_SCRIPT cleanpid
    fi
    if test -x $APACHE_SCRIPT; then
        $APACHE_SCRIPT cleanpid
    fi
    if test -x $LUCENE_SCRIPT; then
        $LUCENE_SCRIPT cleanpid
    fi
    if test -x $TOMCAT_SCRIPT; then
        $TOMCAT_SCRIPT cleanpid
    fi
    if test -x $MYSQL_SCRIPT; then
        $MYSQL_SCRIPT cleanpid
    fi
    if test -x $POSTGRESQL_SCRIPT; then
        $POSTGRESQL_SCRIPT cleanpid
    fi
    if test -x $MEMCACHED_SCRIPT; then
        $MEMCACHED_SCRIPT cleanpid
    fi
else
    help
    exit 1
fi


# Enable Monit
if [ -f "$INSTALLDIR/config/monit/bitnami.conf" ] && [ `id -u` = 0 ] && [ `which monit 2> /dev/null` ] && ( [ "x$1" = "xstart" ] || [ "x$1" = "xrestart" ] ); then
    if [ "x$2" = "x" ]; then
        env -i monit monitor all
    elif [ -f "$INSTALLDIR/config/monit/conf.d/$2.conf" ]; then
        env -i monit monitor $2
    fi
fi


# Checking for errors
for e in $APACHE_ERROR $PROFTP_ERROR $MYSQL_ERROR $SUBVERSION_ERROR $TOMCAT_ERROR $RESIN_ERROR $MEMCACHED_ERROR $INGRES_ERROR $OPENOFFICE_ERROR $LUCENE_ERROR $ZOPE_ERROR $POSTGRESQL_ERROR $THIRD_ERROR $NAGIOS_ERROR $RABBITMQ_ERROR $JETTY_ERROR $HYPERSONIC_ERROR; do
    if [ $e -gt 0 ]; then
        ERROR=$e
    fi
done
# Restoring SELinux
if [ -f "/usr/sbin/getenforce" ] && [ `id -u` = 0 ] ; then
    /usr/sbin/setenforce $selinux_status 2> /dev/null
fi

exit $ERROR
