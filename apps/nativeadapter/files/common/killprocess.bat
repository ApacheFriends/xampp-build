@echo off 
SetLocal EnableDelayedExpansion
set "PID_LIST="

for /f "tokens=2" %%V in ('tasklist.exe ^| findstr /i "%1" 2^>NUL') do @set "PID_LIST=!PID_LIST! /PID %%V"

if defined PID_LIST (
  taskkill.exe /F %PID_LIST%
) else (
  echo Process %1 not running
)

SetLocal DisableDelayedExpansion
exit
