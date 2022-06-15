@echo off
rem -- Check if argument is INSTALL or REMOVE

if not ""%1"" == ""INSTALL"" goto remove

"@@PHP_DIRECTORY@@\scripts\winserv.exe" install "@@PHP_CGI_UNIQUE_SERVICE_NAME@@" -start auto "@@PHP_DIRECTORY@@\php-cgi.exe" -b 127.0.0.1:@@PHP_CGI_PORT@@ -c "@@PHP_DIRECTORY@@\php.ini"
net start @@PHP_CGI_UNIQUE_SERVICE_NAME@@ > NUL

goto end

:remove
rem -- STOP SERVICE BEFORE REMOVING

net stop @@PHP_CGI_UNIQUE_SERVICE_NAME@@ > NUL

"@@PHP_DIRECTORY@@\scripts\winserv.exe" uninstall "@@PHP_CGI_UNIQUE_SERVICE_NAME@@"

:end
exit
