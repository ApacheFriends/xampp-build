@echo off
SetLocal EnableDelayedExpansion
cd /D %~dp0
::::::::::::::::::::::::::::::::::::
::  Set JAVA_HOME or JRE_HOME     ::
::::::::::::::::::::::::::::::::::::
title %~0

IF EXIST tomcat\logs\catalina.pid (
    del /F/Q tomcat\logs\catalina.pid
)

set TASKCMD=TASKLIST /V
set FINDCMD=FIND /I

FOR /F "tokens=2 delims= " %%A IN ('%TASKCMD% ^| %FINDCMD% "%~0"') DO SET MyPID=%%A

echo.
echo [XAMPP]: Searching for JDK or JRE HOME with reg query ...
set JDKKeyName64=HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Development Kit
set JDKKeyName64Short=HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\JDK
set AdoptOpenJDKKeyName64=HKEY_LOCAL_MACHINE\SOFTWARE\AdoptOpenJDK\JDK
set JREKeyName64=HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Runtime Environment
set JREKeyName64Short=HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\JRE
set AdoptOpenJDKKeyName64JRE=HKEY_LOCAL_MACHINE\SOFTWARE\AdoptOpenJDK\JRE

reg query "%JDKKeyName64%" /s
if %ERRORLEVEL% EQU 1 (
    echo . [XAMPP]: Could not find 32 bit or 64 bit JDK
    echo . [XAMPP]: Looking for 32 bit JDK on 64 bit machine
    goto FINDJDK64SHORT
)
set KeyName=%JDKKeyName64%
goto JDKRUN

:FINDJDK64SHORT
reg query "%JDKKeyName64Short%" /s
if %ERRORLEVEL% EQU  1 (
    echo . [XAMPP]: Could not find 32 bit JDK
    echo . [XAMPP]: Looking for 32 bit or 64 bit on 64 bit machine with short name
    goto FINDADOPTOPENJDK64
)
set KeyName=%JDKKeyName64Short%
goto JDKRUN

:FINDADOPTOPENJDK64
reg query "%AdoptOpenJDKKeyName64%" /s
if %ERRORLEVEL% EQU  1 (
    echo . [XAMPP]: Could not find 32 bit or 64 bit AdoptOpenJDK
    echo . [XAMPP]: Looking for 32 bit or 64 bit JRE
    goto FINDJRE64
)
set KeyName=%AdoptOpenJDKKeyName64%
goto JDKRUN

:FINDJRE64
reg query "%JREKeyName64%" /s
if %ERRORLEVEL% EQU 1 (
    echo . [XAMPP]: Could not find 32 bit or 64 bit JRE with long name
    echo . [XAMPP]: Looking for 32 bit or 64 bit JRE on 64 bit machine with short name
    goto FINDJRE64SHORT
)
set KeyName=%JREKeyName64%
goto JRERUN

:FINDJRE64SHORT
reg query "%JREKeyName64Short%" /s
if %ERRORLEVEL% EQU 1 (
    echo . [XAMPP]: Could not find 32 bit or 64 bit JRE with short name
    echo . [XAMPP]: Looking for 32 bit or 64 bit AdoptOpenJDK JRE on 64 bit machine
    goto FINDADOPTOPENJDK64JRE
)
set KeyName=%JREKeyName64Short%
goto JRERUN

:FINDADOPTOPENJDK64JRE
reg query "%AdoptOpenJDKKeyName64JRE%" /s
if %ERRORLEVEL% EQU  1 (
    echo . [XAMPP]: Could not find 32 bit or 64 bit AdoptOpenJDK JRE
    echo . [XAMPP]: Looking for 32 JRE on 64 bit machine
    goto ENDERROR
)
set KeyName=%AdoptOpenJDKKeyName64JRE%
goto JRERUN

:JDKRUN
echo.
echo [XAMPP]: Using JDK
set "CURRENT_DIR=%cd%"
set "CATALINA_HOME=%CURRENT_DIR%\tomcat"

if NOT DEFINED JAVA_HOME (
    set Cmd=reg query "!KeyName!" /s
    for /f "tokens=2*" %%i in ('!Cmd! ^| find "JavaHome"') do set JAVA_HOME=%%j
)

echo.
echo [XAMPP]: Seems fine!
echo [XAMPP]: Set JAVA_HOME : %JAVA_HOME%
echo [XAMPP]: Set CATALINA_HOME : %CATALINA_HOME%
echo.

if %ERRORLEVEL% == 0 (
    echo %MyPID% > tomcat\logs\catalina.pid
)

"%CATALINA_HOME%\bin\catalina.bat" run
goto END

:JRERUN
echo.
echo [XAMPP]: Using JRE
set "CURRENT_DIR=%cd%"
set "CATALINA_HOME=%CURRENT_DIR%\tomcat"

if NOT DEFINED JRE_HOME (
    set Cmd=reg query "!KeyName!" /s
    for /f "tokens=2*" %%i in ('!Cmd! ^| find "JavaHome"') do set JRE_HOME=%%j
)

echo.
echo [XAMPP]: Seems fine!
echo [XAMPP]: Set JRE_HOME : %JRE_HOME%
echo [XAMPP]: Set CATALINA_HOME : %CATALINA_HOME%
echo.

if %ERRORLEVEL% == 0 (
    echo %MyPID% > tomcat\logs\catalina.pid
)

"%CATALINA_HOME%\bin\catalina.bat" run
goto END

:ENDERROR
exit 1

:END
echo done.
SetLocal DisableDelayedExpansion
pause


