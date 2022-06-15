# please run the script on Windows machine in freshly unpacked mysql binaries
# it will start a database and initialize its contents appropriately

# check that the script is run on Windows and inside mysql folder
if {$::tcl_platform(platform) != "windows" || ![file exists bin/mysqld.exe]} {
    puts "Use the script from inside \"mysql\" directory on Windows"
    exit 1
}

proc startMysql {} {
    exec bin/mysqld --skip-grant-tables --port=31337 --innodb-fast-shutdown=0 --bind-address=127.0.0.1 >NUL 2>NUL <NUL &
    for {set try 1} {$try <= 10} {incr try} {
        if {[testMysql]} {
            break
        }  elseif  {$try < 5} {
            after ${try}00
        }  else  {
            error "Unable to start Mysql"
        }
    }
}

proc testMysql {} {
    # validate addition over SQL to ensure any type of error message is not assumed as valid result
    if {[catch {
        if {![regexp {2139062143} [exec bin/mysql -P31337 -B -uroot << "SELECT 2139029504 + 32639;"]]} {error "Result not found"}
    }]} {
        return 0
    }  else  {
        return 1
    }
}

proc runMysqlUpgrade {} {
    exec bin/mysql_upgrade -P31337 -uroot
}

proc testMysqlDatabase {} {
    # run mysqlcheck and parse result for each line
    foreach line [split [exec bin/mysqlcheck -P31337 -uroot -A -m 2>@1] \r\n] {
        if {($line != "") && (![regexp {OK|Table is already up to date} $line])} {
            error "Error parsing line $line"
        }
    }
}

proc stopMysql {} {
    if {[testMysql]} {
        exec bin/mysqladmin -P31337 -uroot shutdown >NUL 2>NUL <NUL
        after 5000
    }
}

proc runSqlFile {sql} {
    exec bin/mysql -P31337 -B -uroot <$sql >@stdout 2>@stderr
}

if {[catch {
    # initialize database using the *.sql script for creating databases
    puts "Initializing database..."
    startMysql
    runSqlFile [info script].sql
    # make sure database is up to date
    runMysqlUpgrade
    # verify database and stop it
    testMysqlDatabase
    stopMysql
    
    # clean up not required files
    foreach g [glob -type f -directory data *.err *.pid *.log auto.cnf] {
        file delete -force $g
    }
    
    # make a backup of data structure before validation
    puts "Copying data structure..."
    catch {file delete -force data_output}
    file copy -force data data_output
    
    # validate data structure
    puts "Validating data structure..."
    startMysql
    testMysqlDatabase
    stopMysql
    
    puts "Reverting to correct data structure..."
    file delete -force data
    file copy -force data_output data

    # test that force-killing mysqld.exe does not break the database
    puts "Validating data structure after hard crash..."
    startMysql
    testMysqlDatabase
    exec taskkill /f /im:mysqld.exe >NUL 2>NUL &
    after 5000
    startMysql
    testMysqlDatabase
    stopMysql
    
    puts "Reverting to correct data structure..."
    file delete -force data
    file copy -force data_output data
}]} {
    puts "Error:\n$::errorInfo\n\nStopping database..."
    stopMysql
    puts "\n\nFAILED!"
}  else  {
    puts "\n\nSUCCESS!"
}
