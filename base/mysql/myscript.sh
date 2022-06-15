#!/bin/sh

cd $1
if ! [ -e tmp ] ;then
  mkdir tmp
fi
chmod 777 tmp

scripts/mysql_install_db --port=@@XAMPP_MYSQL_PORT@@ --socket=@@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock --old-passwords --datadir=@@XAMPP_MYSQL_DATADIR@@ --pid-file=@@XAMPP_MYSQL_DATADIR@@/mysqld.pid > /dev/null

if [ `uname -s` = "SunOS" ]; then
    U=`id|sed -e s/uid=//g -e s/\(.*//g`
else
    U=`id -u`
fi

if [ $U = 0 ]; then
   chown -R root .
   chgrp -R root .

   # External data directory - T3532
   cd @@XAMPP_MYSQL_DATADIR@@
   chown -R mysql .
   chgrp -R root .
   cd $1
fi



@@XAMPP_INSTALLDIR@@/ctlscript.sh start @@XAMPP_MYSQL_DATABASE_TYPE@@ > /dev/null
sleep 10
bin/mysql -S @@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock -u root -e "DELETE FROM mysql.user WHERE User='';"
bin/mysql -S @@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock -u root -e "UPDATE mysql.user SET Password=PASSWORD('$2') WHERE User='root';"
bin/mysql -S @@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock -u root -e "FLUSH PRIVILEGES;"
