@echo off
rem -- Check if argument is INSTALL or REMOVE

if not ""%1"" == ""INSTALL"" goto remove

"@@XAMPP_POSTGRESQL_ROOTDIR@@\bin\pg_ctl.exe" register -N "@@XAMPP_POSTGRESQL_SERVICE_NAME@@" -D "@@XAMPP_POSTGRESQL_DATADIR@@"

net start "@@XAMPP_POSTGRESQL_SERVICE_NAME@@" >NUL
goto end

:remove
rem -- STOP SERVICE BEFORE REMOVING

net stop "@@XAMPP_POSTGRESQL_SERVICE_NAME@@" >NUL
"@@XAMPP_POSTGRESQL_ROOTDIR@@\bin\pg_ctl.exe" unregister -N "@@XAMPP_POSTGRESQL_SERVICE_NAME@@"


:end
exit
