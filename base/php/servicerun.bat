@echo off
rem START or STOP PHP CGI Service
rem --------------------------------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop

net start @@PHP_CGI_UNIQUE_SERVICE_NAME@@

goto end
:stop

net stop @@PHP_CGI_UNIQUE_SERVICE_NAME@@

:end
exit
