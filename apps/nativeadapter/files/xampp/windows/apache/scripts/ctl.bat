@echo off

if not ""%1"" == ""START"" goto stop

cmd.exe /C start /B /MIN "" "@@XAMPP_INSTALLDIR@@\apache\bin\httpd.exe"

if errorlevel 255 goto finish
if errorlevel 1 goto error
goto finish

:stop
cmd.exe /C start "" /MIN call "@@XAMPP_INSTALLDIR@@\killprocess.bat" "httpd.exe"

if not exist "@@XAMPP_INSTALLDIR@@\apache\logs\httpd.pid" GOTO finish
del "@@XAMPP_INSTALLDIR@@\apache\logs\httpd.pid"
goto finish

:error
echo Error starting Apache

:finish
exit
