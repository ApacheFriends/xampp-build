@echo off
rem START or STOP Services
rem ----------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop

if exist @@XAMPP_INSTALLDIR@@\hypersonic\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\server\hsql-sample-database\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\ingres\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\ingres\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\mysql\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\mysql\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\postgresql\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\postgresql\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\apache\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\apache\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\openoffice\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\openoffice\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\resin\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\resin\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\jetty\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\jetty\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\subversion\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\subversion\scripts\ctl.bat START)
rem RUBY_APPLICATION_START
if exist @@XAMPP_INSTALLDIR@@\lucene\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\lucene\scripts\ctl.bat START)
if exist @@XAMPP_INSTALLDIR@@\third_application\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\third_application\scripts\ctl.bat START)
goto end

:stop
echo "Stopping services ..."
if exist @@XAMPP_INSTALLDIR@@\third_application\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\third_application\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\lucene\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\lucene\scripts\ctl.bat STOP)
rem RUBY_APPLICATION_STOP
if exist @@XAMPP_INSTALLDIR@@\subversion\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\subversion\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\jetty\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\jetty\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\hypersonic\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\server\hsql-sample-database\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\resin\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\resin\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\ctl.bat (start /MIN /B /WAIT @@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\openoffice\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\openoffice\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\apache\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\apache\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\ingres\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\ingres\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\mysql\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\mysql\scripts\ctl.bat STOP)
if exist @@XAMPP_INSTALLDIR@@\postgresql\scripts\ctl.bat (start /MIN /B @@XAMPP_INSTALLDIR@@\postgresql\scripts\ctl.bat STOP)

:end

