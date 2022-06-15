@echo off
rem START or STOP MySQL
rem --------------------------------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop

net start "@@XAMPP_MYSQL_SERVICE_NAME@@"
goto end

:stop
net stop "@@XAMPP_MYSQL_SERVICE_NAME@@"

:end
exit
