@echo off
cd /D %~dp0
echo Mysql shutdowm ...

mysql\bin\mysqladmin -u root shutdown

if not exist mysql\data\%computername%.pid GOTO exit
echo Delete %computername%.pid ...
del mysql\data\%computername%.pid

:exit
