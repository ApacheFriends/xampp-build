@echo off
rem START or STOP Tomcat
rem ------------------------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop

set "JAVA_HOME=@@XAMPP_JAVA_ROOTDIR@@"
set "CATALINA_HOME=@@XAMPP_TOMCAT_ROOTDIR@@"

net start "@@XAMPP_TOMCAT_SERVICE_NAME@@"

goto end

:stop
net stop "@@XAMPP_TOMCAT_SERVICE_NAME@@"

:end
exit
