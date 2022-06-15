@echo off
rem -- Check if argument is INSTALL or REMOVE

if not ""%1"" == ""INSTALL"" goto remove

if exist "@@XAMPP_INSTALLDIR@@\mysql\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mysql\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\mariadb\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mariadb\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\postgresql\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\postgresql\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\logstash\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\logstash\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\kibana\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\kibana\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\apache2\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache2\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\resin\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\resin\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\activemq\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\activemq\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\openoffice\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\openoffice\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\subversion\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\subversion\scripts\serviceinstall.bat" INSTALL)
rem RUBY_APPLICATION_INSTALL
if exist "@@XAMPP_INSTALLDIR@@\mongodb\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mongodb\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\lucene\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\lucene\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\third_application\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\third_application\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\nginx\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\nginx\scripts\serviceinstall.bat" INSTALL)
if exist "@@XAMPP_INSTALLDIR@@\php\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\php\scripts\serviceinstall.bat" INSTALL)
goto end

:remove

if exist "@@XAMPP_INSTALLDIR@@\third_application\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\third_application\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\lucene\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\lucene\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\mongodb\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mongodb\scripts\serviceinstall.bat")
rem RUBY_APPLICATION_REMOVE
if exist "@@XAMPP_INSTALLDIR@@\subversion\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\subversion\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\openoffice\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\openoffice\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\resin\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\resin\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\activemq\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\activemq\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache-tomcat\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\apache2\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\apache2\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\kibana\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\kibana\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\logstash\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\logstash\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\elasticsearch\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\postgresql\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\postgresql\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\mysql\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mysql\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\mariadb\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\mariadb\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\php\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\php\scripts\serviceinstall.bat")
if exist "@@XAMPP_INSTALLDIR@@\nginx\scripts\serviceinstall.bat" (start "" /MIN "@@XAMPP_INSTALLDIR@@\nginx\scripts\serviceinstall.bat")
:end
