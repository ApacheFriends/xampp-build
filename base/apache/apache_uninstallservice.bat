@echo off

if "%OS%" == "Windows_NT" goto WinNT

:Win9X
echo Don't be stupid! Win9x don't know Services
echo Please use apache_stop.bat instead
goto exit

:WinNT
echo Are you sure you wan't this?
echo now stopping Apache2.4 when it runs
net stop Apache2.4
echo Time to say good bye to Apache2.4 :(
bin\httpd -k uninstall

:exit
pause
