@echo off
"@@XAMPP_MYSQL_ROOTDIR@@\bin\mysql.exe" --defaults-file="@@XAMPP_MYSQL_ROOTDIR@@\my.ini" -u root -e "DELETE FROM mysql.user WHERE User='';"
"@@XAMPP_MYSQL_ROOTDIR@@\bin\mysql.exe" --defaults-file="@@XAMPP_MYSQL_ROOTDIR@@\my.ini" -u root -e "UPDATE mysql.user SET Password=password('%1') WHERE User='root';"
"@@XAMPP_MYSQL_ROOTDIR@@\bin\mysql.exe" --defaults-file="@@XAMPP_MYSQL_ROOTDIR@@\my.ini" -u root -e "FLUSH PRIVILEGES;"
