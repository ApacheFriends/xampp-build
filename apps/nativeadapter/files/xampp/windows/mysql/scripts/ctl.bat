@echo off
rem START or STOP Services
rem ----------------------------------
rem Check if argument is STOP or START

if not ""%1"" == ""START"" goto stop


"@@XAMPP_INSTALLDIR@@\mysql\bin\mysqld" --defaults-file="@@XAMPP_INSTALLDIR@@\mysql\bin\my.ini" --standalone
if errorlevel 1 goto error
goto finish

:stop
cmd.exe /C start "" /MIN call "@@XAMPP_INSTALLDIR@@\killprocess.bat" "mysqld.exe"

if not exist "@@XAMPP_INSTALLDIR@@\mysql\data\%computername%.pid" goto finish
echo Delete %computername%.pid ...
del "@@XAMPP_INSTALLDIR@@\mysql\data\%computername%.pid"
goto finish


:error
echo MySQL could not be started

:finish
exit
