@echo off
rem START or STOP Apache Service
rem --------------------------------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop

net start @@XAMPP_APACHE_SERVICE_NAME@@
goto end

:stop

"@@XAMPP_APACHE_ROOTDIR@@\bin\httpd.exe" -n "@@XAMPP_APACHE_SERVICE_NAME@@" -k stop

:end
exit
