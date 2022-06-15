@echo off
rem -- Check if argument is INSTALL or REMOVE

if not ""%1"" == ""INSTALL"" goto remove

"@@XAMPP_SUBVERSION_ROOTDIR@@\scripts\winserv.exe" install @@XAMPP_SUBVERSION_SERVICE_NAME@@ -displayname "@@XAMPP_SUBVERSION_SERVICE_NAME@@" -start auto "@@XAMPP_SUBVERSION_ROOTDIR@@\bin\svnserve.exe" -d --listen-port=@@XAMPP_SUBVERSION_PORT@@

net start @@XAMPP_SUBVERSION_SERVICE_NAME@@ >NUL
goto end

:remove
rem -- STOP SERVICES BEFORE REMOVING

net stop @@XAMPP_SUBVERSION_SERVICE_NAME@@ >NUL
"@@XAMPP_SUBVERSION_ROOTDIR@@\scripts\winserv.exe" uninstall @@XAMPP_SUBVERSION_SERVICE_NAME@@

:end
exit
