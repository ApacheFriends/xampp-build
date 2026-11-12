@echo off
SetLocal EnableDelayedExpansion
cd /D %~dp0
::::::::::::::::::::::::::::::::::::
:: Tomcat Starter for XAMPP Control Panel
::::::::::::::::::::::::::::::::::::
title %~0

:: Clean up old PID file
IF EXIST tomcat\logs\catalina.pid (
    del /F/Q tomcat\logs\catalina.pid
)

:: Get current PID so the XAMPP Control Panel turns green
set TASKCMD=TASKLIST /V
set FINDCMD=FIND /I
FOR /F "tokens=2 delims= " %%A IN ('%TASKCMD% ^| %FINDCMD% "%~0"') DO SET MyPID=%%A

:: Check if system-level JAVA_HOME is set and valid
if "%JAVA_HOME%" == "" goto noJavaHome
if not exist "%JAVA_HOME%\bin\java.exe" goto badJavaHome

:: Set paths relative to XAMPP root folder
set "CURRENT_DIR=%cd%"
set "CATALINA_HOME=%CURRENT_DIR%\tomcat"

echo.
echo [XAMPP]: Seems fine!
echo [XAMPP]: Set JAVA_HOME : %JAVA_HOME%
echo [XAMPP]: Set CATALINA_HOME : %CATALINA_HOME%
echo.

:: Write the PID so XAMPP Control Panel can track it
echo %MyPID% > tomcat\logs\catalina.pid

:: Launch Tomcat
"%CATALINA_HOME%\bin\catalina.bat" run
goto END

:noJavaHome
echo ERROR: The JAVA_HOME environment variable is not defined.
echo Please set it to point to your OpenJDK installation root.
exit /b 1

:badJavaHome
echo ERROR: JAVA_HOME is set incorrectly.
echo Cannot find java.exe at: "%JAVA_HOME%\bin\java.exe"
exit /b 1

:END
echo done.
SetLocal DisableDelayedExpansion
pause

