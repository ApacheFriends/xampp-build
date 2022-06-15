@echo off
"@@XAMPP_MYSQL_ROOTDIR@@\bin\mysql.exe" --defaults-file="@@XAMPP_MYSQL_ROOTDIR@@\my.ini" -u root -e "DELETE FROM mysql.user WHERE User=''; CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY '%1'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;ALTER USER 'root'@'localhost' IDENTIFIED BY '%1';"
