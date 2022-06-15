@echo off
rem -- Check if argument is INSTALL or REMOVE

if not ""%1"" == ""INSTALL"" goto remove

"@@XAMPP_MYSQL_ROOTDIR@@\bin\mysqld.exe" --install "@@XAMPP_MYSQL_SERVICE_NAME@@" --defaults-file="@@XAMPP_MYSQL_ROOTDIR@@\my.ini"

net start "@@XAMPP_MYSQL_SERVICE_NAME@@" >NUL
goto end

:remove
rem -- STOP SERVICES BEFORE REMOVING

net stop "@@XAMPP_MYSQL_SERVICE_NAME@@" >NUL
"@@XAMPP_MYSQL_ROOTDIR@@\bin\mysqld.exe" --remove "@@XAMPP_MYSQL_SERVICE_NAME@@"

:end
exit
