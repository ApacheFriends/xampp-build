@echo off
echo ################################# START XAMPP TEST SECTION #################################
echo:
echo:
echo [XAMPP]: FIRST TEST - Searching for an installed Microsoft Visual C++ 2008 runtime package in the registry ...

set runtime8_a=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{FF66E9F6-83E7-3A3E-AF14-8DE9A809A6A4}
set runtime8_b=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{350AA351-21FA-3270-8B7A-835434E766AD}
set runtime8_c=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{2B547B43-DB50-3139-9EBE-37D419E0F5FA}
set runtime8_d=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{9A25302D-30C0-39D9-BD6F-21E6EC160475}
set runtime8_e=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8220EEFE-38CD-377E-8595-13398D740ACE}
set runtime8_f=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{5827ECE1-AEB0-328E-B813-6FC68622C1F9}
set runtime8_g=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1F1C2DFC-2D24-3E06-BCB8-725134ADF989}
set runtime8_h=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1F1C2DFC-2D24-3E06-BCB8-725134ADF989}
set runtime8_i=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{4B6C7001-C7D6-3710-913E-5BC23FCE91E6}
set runtime8_j=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{977AD349-C2A8-39DD-9273-285C08987C7B}

reg query "%runtime8_a%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)
reg query "%runtime8_b%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)
reg query "%runtime8_c%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_d%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_e%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_f%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_g%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_e%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_h%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_i%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

reg query "%runtime8_j%" /v DisplayVersion
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

  echo:
  echo [WARNING]: Microsoft C++ 2008 runtime libraries not found !!!
  echo [WARNING]: Possibly PHP cannot execute without these runtime libraries
  echo [WARNING]: Please install the MS VC++ 2008 Redistributable Package from the Mircrosoft page
  echo [WARNING]: http://www.microsoft.com/en-us/download/details.aspx?id=5582
  goto runtime_end


:runtime_success
echo [SUCCESS]: Microsoft Visual C++ 2008 Redistributable Package found! Good!

:runtime_end
echo:
echo:
echo [XAMPP]: SECOND TEST - Execute php.exe with php\php.exe -n -d output_buffering=0 --version ...
echo:
php\php.exe -n -d output_buffering=0 --version
if %ERRORLEVEL% GTR 0 (
  echo:
  echo [ERROR]: Test php.exe failed !!!
  echo [ERROR]: Perhaps the Microsoft C++ 2008 runtime package is not installed.
  echo [ERROR]: Please install the MS VC++ 2008 Redistributable Package from the Mircrosoft page
  echo:
  echo ################################# END XAMPP TEST SECTION ##################################
  echo:
  pause
  exit 1
)

echo [SUCCESS]: Test for the php.exe successfully passed. Good!
echo:
echo ################################# END XAMPP TEST SECTION ##################################
echo:

pause 