@echo off
echo ################################# START XAMPP TEST SECTION #################################
echo:
echo:
echo [XAMPP]: FIRST TEST - Searching for an installed Microsoft Visual C++ 2017 runtime package in the registry ...

set runtime17_a=HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64

reg query "%runtime15_a%" /v Version
if %ERRORLEVEL% EQU 0 (
    goto runtime_success
)

  echo:
  echo [WARNING]: Microsoft C++ 2017 runtime libraries not found !!!
  echo [WARNING]: Possibly PHP cannot execute without these runtime libraries
  echo [WARNING]: Please install the MS VC++ 2017 Redistributable Package from the Mircrosoft page
  echo [WARNING]: https://www.microsoft.com/en-us/download/details.aspx?id=48145
  goto runtime_end


:runtime_success
echo [SUCCESS]: Microsoft Visual C++ 2017 Redistributable Package found! Good!

:runtime_end
echo:
echo:
echo [XAMPP]: SECOND TEST - Execute php.exe with php\php.exe -n -d output_buffering=0 --version ...
echo:
php\php.exe -n -d output_buffering=0 --version
if %ERRORLEVEL% GTR 0 (
  echo:
  echo [ERROR]: Test php.exe failed !!!
  echo [ERROR]: Perhaps the Microsoft C++ 2017 runtime package is not installed.
  echo [ERROR]: Please install the MS VC++ 2017 Redistributable Package from the Mircrosoft page
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
