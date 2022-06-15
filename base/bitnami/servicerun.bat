@echo off
rem START or STOP Services
rem ----------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop

if exist "@@XAMPP_INSTALLDIR@@\hypersonic\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\server\hsql-sample-database\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\ingres\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\ingres\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\mysql\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mysql\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\mariadb\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mariadb\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\postgresql\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\postgresql\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\logstash\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\logstash\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\openoffice\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\openoffice\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\apache2\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache2\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\resin\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\resin\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\activemq\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\activemq\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\jetty\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\jetty\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\subversion\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\subversion\scripts\servicerun.bat" START)
rem RUBY_APPLICATION_START
if exist "@@XAMPP_INSTALLDIR@@\lucene\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\lucene\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\mongodb\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mongodb\scripts\servicerun.bat" START)
if exist "@@XAMPP_INSTALLDIR@@\third_application\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\third_application\scripts\servicerun.bat" START)
goto end

:stop
echo "Stopping services ..."
if exist "@@XAMPP_INSTALLDIR@@\third_application\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\third_application\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\lucene\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\lucene\scripts\servicerun.bat" STOP)
rem RUBY_APPLICATION_STOP
if exist "@@XAMPP_INSTALLDIR@@\subversion\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\subversion\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\jetty\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\jetty\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\hypersonic\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\server\hsql-sample-database\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\resin\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\resin\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\activemq\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\activemq\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\openoffice\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\openoffice\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\apache2\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache2\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\servicerun.bat" (start "" /MIN /WAIT "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\logstash\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\logstash\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\ingres\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\ingres\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\mysql\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mysql\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\mariadb\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mariadb\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\mongodb\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mongodb\scripts\servicerun.bat" STOP)
if exist "@@XAMPP_INSTALLDIR@@\postgresql\scripts\servicerun.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\postgresql\scripts\servicerun.bat" STOP)

:end
