@echo off
SetLocal EnableDelayedExpansion
cd /D %~dp0
::::::::::::::::::::::::::::::::::::
:: Tomcat Stopper for XAMPP Control Panel
::::::::::::::::::::::::::::::::::::
title %~0

:: Check if system-level JAVA_HOME is set and valid
if "%JAVA_HOME%" == "" goto noJavaHome
if not exist "%JAVA_HOME%\bin\java.exe" goto badJavaHome

:: Set paths relative to XAMPP root folder
set "CURRENT_DIR=%cd%"
set "CATALINA_HOME=%CURRENT_DIR%\tomcat"

echo.
echo [XAMPP]: Seems fine!
echo [XAMPP]: Using JAVA_HOME : %JAVA_HOME%
echo [XAMPP]: Using CATALINA_HOME : %CATALINA_HOME%
echo.

:: Clean up the PID file if the command state is fine
if %ERRORLEVEL% == 0 (
    del /F/Q tomcat\logs\catalina.pid
)

:: Execute Tomcat shutdown sequence
"%CATALINA_HOME%\bin\catalina.bat" stop
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
