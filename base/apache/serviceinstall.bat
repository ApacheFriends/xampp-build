@echo off
rem -- Check if argument is INSTALL or REMOVE

if not ""%1"" == ""INSTALL"" goto remove

"@@XAMPP_APACHE_ROOTDIR@@\bin\httpd.exe" -k install -n "@@XAMPP_APACHE_SERVICE_NAME@@" -f "@@XAMPP_APACHE_ROOTDIR@@\conf\httpd.conf"

net start @@XAMPP_APACHE_SERVICE_NAME@@ >NUL
goto end

:remove
rem -- STOP SERVICE BEFORE REMOVING

net stop @@XAMPP_APACHE_SERVICE_NAME@@ >NUL
"@@XAMPP_APACHE_ROOTDIR@@\bin\httpd.exe" -k uninstall -n "@@XAMPP_APACHE_SERVICE_NAME@@"

:end
exit
