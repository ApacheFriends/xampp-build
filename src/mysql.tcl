
::itcl::class mysql {
    inherit baseBitnamiProgram
    public variable stripBinaries 1
    protected variable osxVersion {}
    protected variable urlFolder {}
    constructor {environment} {
        chain $environment
    } {
        set name mysql
        set fullname MySQL
        set vtrackerName MySQL8
        set licenseRelativePath LICENSE
        set dependencies {mysql {mysql.xml mysql-service.xml mysql-properties.xml mysql-functions.xml mysql-upgrade.xml mysql-libs.xml} java {mysql-connector-java.xml} javaFiles {mysql-connector-java.xml}}
        set moduleDependencies {mysql {mysql-properties.xml mysql-functions.xml}}
        set scriptFiles {{ctl.sh myscript.sh myscript_upgrade.sh} {linux osx solaris-intel solaris-sparc rpm deb} {myscript.bat servicerun.bat serviceinstall.bat} windows}
        set readmePlaceholder MYSQL
        set version [versions::get "MySQL" 80]
        # For supporting 10.6 versions
        set osxVersion $version
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
        set upgradable 1
        set mainComponentXMLName mysql
    }
    public method setEnvironment {} {
       set ::env(LD_LIBRARY_PATH) [prefix]/lib:$::env(LD_LIBRARY_PATH)
       set ::env(PATH) [prefix]/bin:$::env(PATH)
       set ::opts(mysql.prefix) [prefix]
       set ::opts(mysql.src) [srcdir]
       set ::env(CFLAGS) "-I[prefix]/include ${::env(CFLAGS)}"
       set ::env(CPPFLAGS) "-I[prefix]/include ${::env(CPPFLAGS)}"
       set ::env(LDFLAGS) "-L[prefix]/include ${::env(LDFLAGS)}"
    }
    public method build {} {
    }
    public method install {} {
        file delete -force [prefix]
        file copy -force [srcdir] [prefix]
    file delete -force [prefix]/.buildcomplete
    }
    public method preparefordist {} {
       chain
       if {$stripBinaries} {
      catch {eval exec strip [glob [prefix]/bin/*]} kk
      puts $kk
       }
    }
    public method prepareXmlFiles {} {
        foreach xmlFile [list [file join [$be cget -output] mysql.xml] [file join [$be cget -output] mysql-functions.xml]] {
            xampptcl::util::substituteParametersInFile $xmlFile [list "@@XAMPP_MYSQL_FLAVOUR@@" "$name"]
        }
    }
    public method download {} {
        set downloadType wget
        set folderAtThirdparty [$be cget -tarballs]/$name
        if {$fullname == "MySQL"} {
            foreach version [list [getVtrackerField MySQL57 version infrastructure] [getVtrackerField MySQL8 version infrastructure]] {

                regexp -- {^(.*\..*)\..*$} $version - urlFolder
                set downloadUrl https://dev.mysql.com/get/Downloads/MySQL-$urlFolder
                if {[string match *8.0* $version]} {
                    set tarballNameListForDownload [list  \
                                                        mysql-$version-winx64.zip \
                                                        mysql-$version-linux-glibc2.12-x86_64.tar.xz \
                                                        mysql-$version.tar.gz]
                } elseif {[string match *5.7* $version]} {
                    set tarballNameListForDownload [list  \
                                                        mysql-$version-winx64.zip \
                                                        mysql-$version-linux-glibc2.12-x86_64.tar.gz \
                                                        mysql-$version.tar.gz]
                } else {
                    set tarballNameListForDownload [list  \
                                                        mysql-$version-winx64.zip \
                                                        mysql-$version-linux-glibc2.12-x86_64.tar.gz \
                                                        mysql-$version.tar.gz]
                }

                chain
            }
        } else {
            foreach version [getVtrackerField MariaDB version infrastructure] {
                set downloadUrl https://downloads.mariadb.org/f/mariadb-$version
                set tarballNameListForDownload [list source/mariadb-$version.tar.gz \
                                                    winx64-packages/mariadb-$version-winx64.zip \
                                                    bintar-linux-x86_64/mariadb-$version-linux-x86_64.tar.gz \
                                                    bintar-linux-glibc_214-x86_64/mariadb-$version-linux-glibc_214-x86_64.tar.gz]
                chain
            }
        }
    }
    public method copyScripts {} {
        chain
        # We only use the new initialisation script when using MySQL 5.7.x family
        # since MariaDB doesn't support the --initialize-insecure yet
        if {[string match "windows*" [$be targetPlatform]]} {
            if {[::xampptcl::util::compareVersions $version 5.7.6] >= 0 && $name == "mysql"} {
                file copy -force [file join [$be cget -projectDir] base mysql myscript57.bat] [file join [prefix] scripts myscript.bat]
            }
        } else {
            if {[::xampptcl::util::compareVersions $version 5.7.6] >= 0 && $name == "mysql"} {
                file copy -force [file join [$be cget -projectDir] base mysql myscript57.sh] [file join [prefix] scripts myscript.sh]
            }
            set fileList {ctl.sh myscript.sh}
            foreach f $fileList {
                xampptcl::util::substituteParametersInFile [file join [prefix] scripts $f] \
                    [list {--old-passwords} {} {--default-table-type=InnoDB} {}]
            }
        }
    }
}

::itcl::class mysqlUnix {
    inherit mysql
    constructor {environment} {
        chain $environment
    } {}
    public method preparefordist {} {
        chain
	xampptcl::util::substituteParametersInFile [file join [prefix] bin mysqld_safe] \
	    [list {if test -w / -o "$USER" = "root"} {if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]} ]

       #Delete MySQL extras
        message info "Deleting MySQL extras"
        set old_pwd [pwd]
        cd [$be cget -output]/mysql
        if { [catch { foreach file "sql-bench [glob -nocomplain lib/*.a] test man mysql-test" { \
                                                                                                            puts $file
                                                                                                        file delete -force [$be cget -output]/mysql/$file }}]
        } {}
        foreach f {*bin/*test* *bin/*embedded* *bin/*debug*} {
            ::xampptcl::util::deleteFilesAccordingToPattern [prefix] $f
        }
        cd $old_pwd
        # TODO: What's this return?
        return
        foreach {d f} {
         bin mysqlaccess
         bin mysqld_safe
         bin mysqld_multi
         bin safe_mysqld
         bin mysql_fix_privilege_tables
         support-files mysql.server
         support-files mysql-log-rotate
         support-files mysql.spec
         mysql-test mysql-test-run
        } {
         xampptcl::util::substituteParametersInFile \
            [file join [prefix] $d $f] \
            [list [prefix] @@XAMPP_MYSQL_ROOTDIR@@]
       }
    }
    public method srcdir {} {
        return [getTarballName]
    }
    public method getTarballName {} {
	    switch [$be targetPlatform] {
            "linux-x64" {
                return mysql-$version-linux2.6-x86_64
            } "osx-x64" {
                return mysql-$osxVersion-osx10.6-x86_64
            }
	    }
    }
    public method getSourcesTarballName {} {
        return $name-$version
    }
}


::itcl::class mysqlUnixWrapper {
   inherit mysqlUnix
   public variable setupServer 1
   constructor {environment} {
    chain $environment
   } {}

   public method preparefordist {} {
            if {!$setupServer} {
                return
            }
            chain
        # MySQL 4 does not recognize MYSQL_HOME
        # so we need to pass path to my.cnf
        # Problem is, not all of them support
        # --defaults-file, so we need to find them
        # and replace them with a wrapper
        # For safe_mysqld, wrapper_s is a temporary solution -- solved by adding mysqld=mysqld.bin to my.ini
            cd [prefix]/bin
	   xampptcl::file::write wrapper {#!/bin/sh
LD_LIBRARY_PATH=@@XAMPP_MYSQL_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/../common/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
case "$@" in
  *--no-defaults*)
    exec $0.bin "$@"
    ;;
  *--defaults-extra-file*)
    exec $0.bin "$@"
    ;;
esac
exec $0.bin --defaults-file=@@XAMPP_MYSQL_ROOTDIR@@/my.cnf "$@"
}
        if {[string match osx* [$be cget -target]]} {
            xampptcl::util::substituteParametersInFile wrapper [list {LD_LIBRARY_PATH} {DYLD_FALLBACK_LIBRARY_PATH}]
        }
        file attributes wrapper -permissions 0755

        #T20827 - Create libtinfo library. It's needed for the MySQL client
        if {[file exists [prefix]/lib/libncurses.so.5] && ![file exists [prefix]/lib/libtinfo.so]} {
            exec ln -snf [prefix]/lib/libncurses.so.5 [prefix]/lib/libtinfo.so.5
            exec ln -snf [prefix]/lib/libtinfo.so.5 [prefix]/lib/libtinfo.so
        }

        set wrapperFiles {}
        if {[string match osx* [$be cget -target]]} {
            set wrapperFiles [list mysqld mysql mysqlslap mysqlshow mysqlimport mysqldump mysqlcheck mysqladmin my_print_defaults myisamchk myisampack]
        }
        foreach f [glob *] {
            # 'replace' binary hangs waiting on stdin
            if {$f == "replace"} {continue}
            # 'tokuft_logprint' also hangs waiting on stdin
            if {$f == "tokuft_logprint"} {continue}

            if {[isBinaryFile $f]} {
                set kk {}
                if {[catch {exec ./$f --help --verbose} kk]} {
                    # It does not accept command line options
                }
                if { [string match *defaults-file* $kk] || "$f" == "mysqld" } {
                    lappend wrapperFiles $f
                }
            }
       }
       foreach f $wrapperFiles {
           if {![file exists $f.bin]} {
               file rename $f $f.bin
               exec ln -s wrapper $f
           }
       }
       if {[string match osx* [$be cget -target]]} {
           #Refs T3954 New MySQL versions require compilation
           set dirs [list bin include include/mysql]
           if { [file exists support-files] } {
               lappend dirs support-files
           }
           foreach g $dirs {
               cd [file join [prefix] $g]
               foreach f [glob -nocomplain -type f *] {
                   if {![isBinaryFile $f]} {
                       xampptcl::util::substituteParametersInFile $f \
                           [list [prefix] @@XAMPP_MYSQL_ROOTDIR@@]
                   }
               }
           }
       }
       if { ![file exists [prefix]/bin/mysql.bin] } {
           message error "mysql wrapper creation failed."
           exit 1
       }
       #T20827 - Remove libtinfo after building MySQL
       if { [file exists [prefix]/lib/libtinfo.so] } {
           file delete -force [file join [prefix] lib libtinfo.so]
           file delete -force [file join [prefix] lib libtinfo.so.5]
       }
       exec touch [file join [prefix] my.cnf]
       xampptcl::file::append [file join [prefix] my.cnf] {
[mysqladmin]
user=root

[mysqld]
basedir=@@XAMPP_MYSQL_ROOTDIR@@
datadir=@@XAMPP_MYSQL_ROOTDIR@@/data
port=@@XAMPP_MYSQL_PORT@@
socket=@@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock
tmpdir=@@XAMPP_MYSQL_ROOTDIR@@/tmp
max_allowed_packet=32M
bind-address=127.0.0.1
skip-name-resolve=1
expire_logs_days=7
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

[client]
port=@@XAMPP_MYSQL_PORT@@
socket=@@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock

[manager]
port=@@XAMPP_MYSQL_PORT@@
socket=@@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock
pid-file=@@XAMPP_MYSQL_ROOTDIR@@/tmp/manager.pid
default-mysqld-path=@@XAMPP_MYSQL_ROOTDIR@@/bin/mysqld.bin

}
                xampptcl::util::substituteParametersInFile \
            [file join [prefix] bin mysql_config] \
            [list {socket='/tmp/mysql.sock'} {socket='@@XAMPP_MYSQL_ROOTDIR@@/tmp/mysql.sock'} \
                  {port='3306'} {port='@@XAMPP_MYSQL_PORT@@'}]
    }

}


::itcl::class mysqlXLinux {
    inherit mysqlUnixWrapper
    constructor {environment} {
       chain $environment
    } {
        set licenseRelativePath LICENSE
    }
    #Needs be replaced by a regexp
    public method versionNumber {} {
        return $version
    }
    public method preparefordist {} {
	chain
	    xampptcl::util::substituteParametersInFile [file join [prefix] bin mysqld_safe] \
		[list {mysqld_ld_preload=
mysqld_ld_library_path=} {mysqld_ld_preload=
mysqld_ld_library_path=@@XAMPP_MYSQL_ROOTDIR@@/lib}]
    }
}

::itcl::class mysql56Linux {
     inherit mysqlXLinux
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 56]
        set osxVersion $version
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
        if {[$be cget -target] == "linux"} {
            set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-linux-glibc2.12-i686.tar.gz
        } else {
            set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-linux-glibc2.12-x86_64.tar.gz
        }
    }
    public method getTarballName {} {
        switch [$be cget -target] {
            "linux" {
                return mysql-$version-linux-glibc2.12-i686
            } "linux-x64" {
                return mysql-$version-linux-glibc2.12-x86_64
            }
        }
    }
}

::itcl::class mysql57Linux {
     inherit mysql56Linux
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 57]
        set osxVersion $version
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
        if {[$be cget -target] == "linux"} {
            set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-linux-glibc2.12-i686.tar.gz
        } else {
            set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-linux-glibc2.12-x86_64.tar.gz
        }
    }
}

::itcl::class mysql80Linux {
    inherit mysql57Linux
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 80]
        set licenseRelativePath LICENSE
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
        if {[$be cget -target] == "linux"} {
            set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-linux-glibc2.12-i686.tar.gz
        } else {
            set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-linux-glibc2.12-x86_64.tar.gz
        }
    }
    public method preparefordist {} {
        chain
        foreach f [glob -nocomplain -type f [prefix]/lib/private/lib*] {
            file copy -force $f [file join [prefix] lib]
        }
        xampptcl::util::substituteParametersInFileRegex [file join [prefix] my.cnf] [list {expire_logs_days\s*=\s*[^\n]*} {binlog_expire_logs_seconds=604800} ]
    }

}

::itcl::class mariadb {
    inherit mysqlXLinux
    constructor {environment} {
        chain $environment
    } {
        set name mariadb
        set fullname MariaDB
        set vtrackerName MariaDB
        set licenseRelativePath COPYING
        set uniqueIdentifier mariadb
        set version 5.5.50
        set readmePlaceholder MARIADB
        # For supporting 10.6 versions
        set osxVersion $version
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
        set mainComponentXMLName mysql
        $be configure -setvars "[$be cget -setvars] mysql_database_type=MariaDB"
    }
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base mysql]
    }
    public method applicationOutputDir {} {
        return [file join [$be cget -output] mysql]
    }
    public method srcdir {} {
        return [$be cget -src]/[getTarballName]
    }
    public method prefix {} {
        return [$be cget -output]/mysql
    }
    public method getTarballName {} {
        switch [$be cget -target] {
            "linux-x64" {
                return $name-$version-linux-x86_64
            } "solaris-intel-x64" {
                return $name-$version-solaris10-x86_64
            }
        }
    }
    public method install {} {
        file delete -force [prefix]
        file copy -force [srcdir] [prefix]
        file delete -force [prefix]/.buildcomplete
        createMysqlLayout
    }
    protected method createMysqlLayout {} {
        file rename [prefix]/include/mysql [prefix]/mysql_include
        set l [glob -nocomplain [prefix]/include/*]
        if {$l == ""} {
            file delete [prefix]/include
            file rename [prefix]/mysql_include [prefix]/include
        } else {
            error message "Check directory structure, it seems it has changed"
            exit 1
        }
    }
    public method copyScripts {} {
        chain
        xampptcl::util::substituteParametersInFile [file join [$be cget -output] mysql scripts myscript.sh] [list {scripts/mysql_install_db} {scripts/mysql_install_db --defaults-file=@@XAMPP_MYSQL_ROOTDIR@@/my.cnf}] 1
        xampptcl::util::substituteParametersInFile [file join [$be cget -output] mysql scripts ctl.sh] [list {mysqld=mysqld.bin} {mysqld=mysqld}] 1
    }
}

::itcl::class mariadb5Unix {
    inherit mariadb
    constructor {environment} {
        chain $environment
    } {
        set version 5.5.50
        set osxVersion $version
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
    }
}

::itcl::class mariadb10Unix {
    inherit mariadb5Unix
    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "MariaDB" 10]
        set osxVersion $version
        regexp -- {^(.*\..*)\..*$} $version - urlFolder
    }

    public method setEnvironment {} {
        set ::env(IS_MARIADB_BUILT) 1
        set ::env(LDFLAGS) "-L[prefix]/lib $::env(LDFLAGS)"
        chain
    }

    public method preparefordist {} {
        chain
        cd [prefix]/bin

        # Avoid wrappers to pass more than one --defaults-file option
        file delete wrapper
        xampptcl::file::write wrapper { #!/bin/sh
LD_LIBRARY_PATH=/opt/codedx/mysql/lib:/opt/codedx/mysql/../common/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
case "$@" in
  *--no-defaults*)
    exec $0.bin "$@"
    ;;
  *--defaults-extra-file*)
    exec $0.bin "$@"
    ;;
  *--defaults-file*)
    exec $0.bin "$@"
    ;;
esac
exec $0.bin --defaults-file=@@XAMPP_MYSQL_ROOTDIR@@/my.cnf "$@"}
        file attributes wrapper -permissions 0755;

        # Wrapper for mysqld
        file delete mysqld

        xampptcl::file::write mysqld {#!/bin/sh
LD_LIBRARY_PATH=@@XAMPP_MYSQL_ROOTDIR@@/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
exec $0.bin "$@"
            }
        file attributes mysqld -permissions 0755

        # T16869 - MariaDB 10.1.21 adds mysqld_safe_helper and it needs reference to common libs
        if {![file exists mysqld_safe_helper.bin]} {
            file rename mysqld_safe_helper mysqld_safe_helper.bin
            xampptcl::file::write mysqld_safe_helper {#!/bin/sh
LD_LIBRARY_PATH=@@XAMPP_MYSQL_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/../common/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
exec $0.bin "$@"}
            file attributes mysqld_safe_helper -permissions 0755
        }
        if {[file exists [prefix]/lib/galera-4] && ![file exists [prefix]/lib/galera]} {
           file rename [prefix]/lib/galera-4 [prefix]/lib/galera
        }
    }
}

::itcl::class mysqlWindows {
    inherit mysql
    constructor {environment} {
        chain $environment
    } {
        #Disabling strips for windows. strip (v2.13) corrupts exe files in RedHat9
        set stripBinaries 0
        lappend additionalFileList msvcr100.dll msvcp100.dll msvcr100-x64.dll msvcp100-x64.dll msvcr120.dll msvcp120.dll msvcr120-x64.dll msvcp120-x64.dll
    }
    public method preparefordist {} {
        chain
	# Add to Ruby, mysql2 gems requires it
	if {[file exists [$be cget -output]/ruby] && [file exists [prefix]/lib/libmysql.dll]} {
	    file copy -force [prefix]/lib/libmysql.dll [$be cget -output]/ruby/bin
	}
        foreach dir {Embedded examples Docs mysql-test sql-bench} {
            file delete -force [prefix]/$dir
    }
       catch {eval file delete -force [glob [prefix]/bin/*.pdb]} kk
       puts $kk
       catch {eval file delete -force [glob [prefix]/bin/*.map]} kk
       puts $kk
    exec touch [file join [prefix] my.ini]
    xampptcl::file::append [file join [prefix] my.ini] {

[mysqldump]
quick
max_allowed_packet = 32M

[isamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

[mysqladmin]
user=root
port=@@XAMPP_MYSQL_PORT@@

# The MySQL server
[mysqld]
# Example MySQL config file for medium systems.
#
# This is for a system with little memory (32M - 64M) where MySQL plays
# an important part, or systems up to 128M where MySQL is used together with
# other programs (such as a web server)

# Replication Master Server (default)
# binary logging is required for replication
#log-bin=mysql-bin

# required unique id between 1 and 2^32 - 1
# defaults to 1 if master-host is not set
# but will not function as a master if omitted
server-id   = 1

# Point the following paths to different dedicated disks
#tmpdir     = /tmp/
#log-update     = /path-to-dedicated-directory/hostname

# Uncomment the following if you are using BDB tables
#bdb_cache_size = 4M
#bdb_max_lock = 10000

# Uncomment the following if you are using InnoDB tables
#innodb_data_home_dir = /usr/local/var/
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = /usr/local/var/
#innodb_log_arch_dir = /usr/local/var/
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
#innodb_buffer_pool_size = 16M
#innodb_additional_mem_pool_size = 2M
# Set .._log_file_size to 25 % of buffer pool size
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

# set basedir to your installation path
basedir=@@XAMPP_MYSQL_ROOTDIR@@
# set datadir to the location of your data directory
datadir=@@XAMPP_MYSQL_ROOTDIR@@\data
port=@@XAMPP_MYSQL_PORT@@
skip-locking
key_buffer_size = 16M
max_allowed_packet = 32M
table_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
bind-address = 127.0.0.1
expire_logs_days=7
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# The following options will be passed to all MySQL clients
[mysql]
port=@@XAMPP_MYSQL_PORT@@
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates
}

	    xampptcl::util::substituteParametersInFile [file join [prefix] my.ini] \
		[list {skip-locking} {#skip-locking}]
    }
    public method install {} {
        chain
        if {[string match {5.6.*} $version]} {
            if {[string match windows-x64 [$be cget -target]]} {
                    file copy -force [findFile msvcr100-x64.dll] [prefix]/bin/msvcr100.dll
                    file copy -force [findFile msvcp100-x64.dll] [prefix]/bin/msvcp100.dll
            } else {
                    file copy -force [findFile msvcr100.dll] [prefix]/bin/msvcr100.dll
                    file copy -force [findFile msvcp100.dll] [prefix]/bin/msvcp100.dll
            }
        } elseif {[string match {5.7.*} $version]} {
            if {[string match windows-x64 [$be cget -target]]} {
                    file copy -force [findFile msvcr120-x64.dll] [prefix]/bin/msvcr120.dll
                    file copy -force [findFile msvcp120-x64.dll] [prefix]/bin/msvcp120.dll
            } else {
                    file copy -force [findFile msvcr120.dll] [prefix]/bin/msvcr120.dll
                    file copy -force [findFile msvcp120.dll] [prefix]/bin/msvcp120.dll
            }
        }
    }
}

::itcl::class mysqlXWindows {
    inherit mysqlWindows
    constructor {environment} {
        chain $environment
    } {
        # Currently 5.1.X version is not supported for Windows due to
        # PHP 5.2.8 has been compiled using MySQL 5.0.X version.
        # More info at: http://bugs.php.net/bug.php?id=46842&edit=1
        # http://forums.devnetwork.net/viewtopic.php?f=2&p=506230
        set licenseRelativePath LICENSE
        set tarballName mysql-${version}-winx64
    }
    public method getTarballName {} {
        return mysql-$version-winx64
    }
    public method srcdir {} {
	    return [file join [$be cget -src] mysql-${version}-winx64]
    }
}

::itcl::class mysql56Windows {
    inherit mysqlXWindows
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 56]
        set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-winx64.zip
    }
    public method getTarballName {} {
        return mysql-${version}-winx64
    }

    public method preparefordist {} {
        chain
        file delete -force [file join [prefix] my.ini]
        exec touch [file join [prefix] my.ini]
        xampptcl::file::append [file join [prefix] my.ini] {
[client]
default-character-set=UTF8

[mysqladmin]
user=root
port=@@XAMPP_MYSQL_PORT@@

# The MySQL server
[mysqld]
# set basedir to your installation path
basedir=@@XAMPP_MYSQL_ROOTDIR@@
# set datadir to the location of your data directory
datadir=@@XAMPP_MYSQL_ROOTDIR@@\data
port=@@XAMPP_MYSQL_PORT@@
max_allowed_packet=32M
bind-address=127.0.0.1
expire_logs_days=7
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# The default storage engine that will be used when create new tables when
default-storage-engine=INNODB

[mysqldump]
quick
max_allowed_packet = 32M

[mysql]
port=@@XAMPP_MYSQL_PORT@@
no-auto-rehash

}
    }
}

::itcl::class mysql57Windows {
     inherit mysql56Windows
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 57]
        set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-winx64.zip
    }
}

::itcl::class mysql80Windows {
    inherit mysql57Windows
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 80]
        set licenseRelativePath LICENSE
        set downloadUrl http://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}-winx64.zip
        lappend additionalFileList vcruntime140_1.dll
    }
     public method preparefordist {} {
        chain
        xampptcl::util::substituteParametersInFileRegex [file join [prefix] my.ini] [list {expire_logs_days\s*=\s*[^\n]*} {binlog_expire_logs_seconds=604800} ]
     }
     public method install {} {
         chain
         file copy -force [findFile vcruntime140_1.dll] [file join [$be cget -output] mysql/bin/vcruntime140_1.dll]
     }
}

::itcl::class mariadb10Windows {
    inherit mysqlXWindows
    constructor {environment} {
        chain $environment
    } {
        set name mariadb
        set uniqueIdentifier mariadb
        set readmePlaceholder MARIADB
        set licenseRelativePath COPYING
        set version [versions::get "MariaDB" 10]
        $be configure -setvars "[$be cget -setvars] mysql_database_type=MariaDB"
        lappend additionalFileList vcruntime140_1.dll
    }
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base mysql]
    }
    public method applicationOutputDir {} {
        return [file join [$be cget -output] mysql]
    }
    public method prefix {} {
       return [$be cget -output]/mysql
    }
    public method getTarballName {} {
        return mariadb-$version-winx64
    }
    public method srcdir {} {
        return [$be cget -src]/[getTarballName]
    }
    public method install {} {
        chain
        file copy -force [findFile vcruntime140_1.dll] [file join [prefix] bin/vcruntime140_1.dll]
    }
}

::itcl::class mysql56Macosx64 {
     inherit mysqlUnixWrapper
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 56]
    }
    public method getTarballName {} {
        return $name-$version
    }
    public method srcdir {} {
	return [file join [$be cget -src] $name-$version]
    }
    public method install {} {
        if {[$be cget -target] == "osx-x64" && [info exists ::env(DYLD_LIBRARY_PATH)]} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        cd [srcdir]
        eval logexec [make] install
        if {[$be cget -target] == "osx-x64" && [info exists oldDYLD]} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
    public method build {} {
        if {[$be cget -target] == "osx-x64" && [info exists ::env(DYLD_LIBRARY_PATH)]} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        cd [srcdir]
        showEnvironmentVars
        eval logexec BUILD/autorun.sh
        eval logexec ./configure --prefix=[prefix]
        eval logexec cmake . -DWITH_SSL=[file join [$be cget -output] common]
        eval logexec [make]
        if {[$be cget -target] == "osx-x64" && [info exists oldDYLD]} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
}

::itcl::class mysql57Macosx64 {
     inherit mysqlUnixWrapper
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 57]
        set downloadUrl https://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}.tar.gz
        $be configure -setvars "[$be cget -setvars] mysql_min_osx_version=[getRequiredMacOSVersion]"
    }
    public method getTarballName {} {
        if {[::xampptcl::util::compareVersions $version 5.7.24] >= 0} {
            return $name-$version-macos10.14-x86_64
        } elseif {[::xampptcl::util::compareVersions $version 5.7.21] >= 0} {
            return $name-$version-macos10.13-x86_64
        } elseif {[::xampptcl::util::compareVersions $version 5.7.17] >= 0} {
            return $name-$version-macos10.12-x86_64
        } elseif {[::xampptcl::util::compareVersions $version 5.7.12] >= 0 && [::xampptcl::util::compareVersions $version 5.7.17] < 0} {
            return $name-$version-osx10.11-x86_64
        } else {
            return $name-$version-osx10.9-x86_64
        }
    }
    public method getRequiredMacOSVersion {} {
        regexp ".*-(?:macos|osx)(\[0-9.\]+)-.*" [getTarballName] {\1} requiredVersion
        if {![info exists requiredVersion] || ![string match {[0-9]*[.][0-9]*} $requiredVersion]} {
            message fatalerror "Could not extract required macOS version from tarball name!"
        }
        if {$requiredVersion == 10.14} {
            # From the official website: "Packages for Mojave (10.14) are compatible with High Sierra (10.13)"
            set requiredVersion 10.13
        }
        return $requiredVersion
    }
}

::itcl::class mysql80Macosx64 {
    inherit mysqlUnixWrapper
    constructor {environment} {
       chain $environment
    } {
        set version [versions::get "MySQL" 80]
        set licenseRelativePath LICENSE
        set downloadUrl https://dev.mysql.com/get/Downloads/MySQL-${urlFolder}/mysql-${version}.tar.gz
    }
    public method getTarballName {} {
        return $name-$version-macos11-x86_64
    }
     public method preparefordist {} {
        chain
        xampptcl::util::substituteParametersInFileRegex [file join [prefix] my.cnf] [list {expire_logs_days\s*=\s*[^\n]*} {binlog_expire_logs_seconds=604800} ]
    }
}


::itcl::class mariadb10Macosx {
    inherit mariadb10Unix
    constructor {environment} {
        chain $environment
    } {
        set name mariadb
        set version [versions::get "MariaDB" 10]
        set supportsParallelBuild 0
        set patchList {TokuDB-MacOS.patch mariadb-clock_realtime.patch}
    }
    public method setEnvironment {} {
        set ::opts(mysql.prefix) [prefix]
        set ::opts(mysql.srcdir) [srcdir]
    }
    public method getTarballName {} {
        return $name-$version
    }
    public method install {} {
        if {[info exists ::env(DYLD_LIBRARY_PATH)]} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        cd [srcdir]
        eval logexec [make] install
        foreach f [glob -nocomplain -type f [prefix]/include/mysql/*] {
            file attributes $f -permissions 0644
        }

        if {[info exists oldDYLD]} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }

    }
    public method build {} {
        cd [srcdir]
        if {[file exists [srcdir]/mysys/my_default.c.orig]} {
            file copy -force [srcdir]/mysys/my_default.c.orig [srcdir]/mysys/my_default.c
            file copy -force [srcdir]/mysys/my_sync.c.orig [srcdir]/mysys/my_sync.c
        } else {
            file copy -force [srcdir]/mysys/my_default.c [srcdir]/mysys/my_default.c.orig
            file copy -force [srcdir]/mysys/my_sync.c [srcdir]/mysys/my_sync.c.orig
        }

        # Starting from MariaDB 10.4.14, upstream is using ld arguments not present in our ld version (-z)
        xampptcl::util::substituteParametersInFile [file join [srcdir] CMakeLists.txt] [list {MY_CHECK_AND_SET_LINKER_FLAG("-Wl,-z,relro,-z,now")} {# MY_CHECK_AND_SET_LINKER_FLAG("-Wl,-z,relro,-z,now")}] 1

        xampptcl::util::substituteParametersInFile [srcdir]/mysys/my_sync.c [list DBUG_PRINT //DBUG_PRINT DBUG_ENTER //DBUG_ENTER]
        xampptcl::util::substituteParametersInFile [srcdir]/cmake/ssl.cmake [list {REGEX "^#define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9].*"} {REGEX "^.*define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9].*"}]

        # MariaDB provides its own implementation of strnlen but it is not used when compiling the "auth_gssapi" plugin. We force it here.
        # See fixed on https://github.com/MariaDB/server/commit/36bf482
        xampptcl::util::substituteParametersInFile [file join [srcdir] "plugin" "auth_gssapi" "client_plugin.cc"] [list  "#include \"common.h\"" "#include \"common.h\"\n#include \"m_string.h\""]

        xampptcl::file::prependTextToFile [file join [srcdir] "plugin" "auth_gssapi" "CMakeLists.txt"] \
            {SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -lstrings -L../../strings" )
SET ( HAVE_KRB5_FREE_UNPARSED_NAME 1 )
}
        xampptcl::util::substituteParametersInFile [file join [srcdir] "storage" "tokudb" "CMakeLists.txt"] [list  "-fuse-linker-plugin" ""]
        file attributes [file join [srcdir] "storage" "tokudb" "PerconaFT" "third_party" "xz-4.999.9beta" "build-aux" "install-sh"] -permissions 0755

        set ldflags $::env(LDFLAGS)
        set ::env(LDFLAGS) "$ldflags -lssl -lcrypto -ldl -lstdc++ -L[prefix]/include/openssl -L[prefix]/share/openssl"

        if {[info exists ::env(DYLD_LIBRARY_PATH)]} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }

        # Patch RocksDB CMakeLists.txt file
        # ROCKSDB_SUPPORT_THREAD_LOCAL: our OS X version does not support thread local features, but the CMAKE logic enables it by default for OS X platforms.
        # __MACH__: this macro doesn't only define OS X features but GNU/Hurd as well. Both platforms are based on the MACH microkernel. OS X compilation fails if set.
        xampptcl::util::substituteParametersInFile [file join [srcdir] "storage" "rocksdb" "CMakeLists.txt"] [list {ADD_DEFINITIONS(-DROCKSDB_SUPPORT_THREAD_LOCAL)} \
        {MESSAGE(STATUS "Bitnami -- Unsetting ROCKSDB_SUPPORT_THREAD_LOCAL and __MACH__ flags to properly build MariaDB on OS X platforms")
  ADD_DEFINITIONS(-UROCKSDB_SUPPORT_THREAD_LOCAL)
  ADD_DEFINITIONS(-U__MACH__)}] 1

        # Show environment
        showEnvironmentVars

        # Start building
        eval logexec cmake . -DCMAKE_INSTALL_PREFIX=[prefix] -DINSTALL_PLUGINDIR=lib/mysql/plugin -DENABLED_LOCAL_INFILE=ON -DMYSQL_UNIX_ADDR=[prefix]/var/mysql/mysql.sock -DINSTALL_SBINDIR=bin -DSYSCONFDIR=[prefix]/etc  -DDEFAULT_SYSCONFDIR=[prefix]/etc -DMYSQL_DATADIR=[prefix]/var/mysql -DINSTALL_INFODIR=[prefix]/info -DWITH_SSL=system -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1  -DOPENSSL_INCLUDE_DIR=$::opts(openssl.prefix)/include -DOPENSSL_ROOT_DIR=$::opts(openssl.prefix) -DINSTALL_SCRIPTDIR=[prefix]/bin -DINSTALL_SUPPORTFILESDIR=[prefix]/share/mysql -DPLUGIN_TOKUDB=NO

        # MariaDB is intended to be compiled using the OS-X system "libtool" library which includes the "-static" option.
        # The GNU "libtool" we add as a build dependency, since PHP requires, it does not have that option.
        # This is a patch to compile MariaDB with the OS-X system "libtool" library.
        xampptcl::util::substituteParametersInFile  [srcdir]/cmake/libutils.cmake [list {libtool -static} "/usr/bin/libtool -static"]


        # Fix error (T35889): "'mutable' and 'const' cannot be mixed"
        if {[string match osx* [$be cget -target]]} {
          xampptcl::util::substituteParametersInFile /Library/Developer/CommandLineTools/usr/include/c++/v1/iterator [list "mutable _Iter" "/* mutable */ _Iter"]
        }
        eval logexec [make]
        if {[string match osx* [$be cget -target]]} {
          xampptcl::util::substituteParametersInFile /Library/Developer/CommandLineTools/usr/include/c++/v1/iterator [list "/* mutable */ _Iter" "mutable _Iter"]
        }
        set ::env(LDFLAGS) $ldflags

        if {[info exists oldDYLD]} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
    public method preparefordist {} {
        chain

        cd [prefix]/bin

        # T16869 - We need to add common libs to the libraries to load in wrappers
        file delete wrapper
        xampptcl::file::write wrapper { #!/bin/sh
DYLD_FALLBACK_LIBRARY_PATH=@@XAMPP_MYSQL_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/../common/lib:$DYLD_FALLBACK_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH
case "$@" in
    *--no-defaults*)
        exec $0.bin "$@"
        ;;
    *--defaults-file*)
        exec $0.bin "$@"
        ;;
esac
exec $0.bin --defaults-file=@@XAMPP_MYSQL_ROOTDIR@@/my.cnf "$@"}
        file attributes wrapper -permissions 0755;

        # Workaround for a possible unwanted interaction between our wrapper and mysqld_safe.
        # Recent versions of OS X (From El Capitan onwards?) seem to mess with environment
        # variables passed down to commands called from scripts.
        # T16869 - MariaDB 10.1.21 adds mysqld_safe_helper
        foreach f [list mysqld resolveip my_print_defaults mysqld_safe_helper] {
            if {$f == "resolveip"} {
                file rename $f $f.bin
            } else {
                # Our parent class should have turned mysqld into a wrapper by now.
                file delete $f
            }

            xampptcl::file::write $f {#!/bin/sh
DYLD_FALLBACK_LIBRARY_PATH=@@XAMPP_MYSQL_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/../common/lib:$DYLD_FALLBACK_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH
exec $0.bin "$@"
}
            file attributes $f -permissions 0755
        }

        # T7904 - Fix for upgrading process in OS X
        foreach f [list mysql mysql_upgrade mysqlcheck] {
            if {![file exists $f.bin]} {
                file delete $f
                xampptcl::file::write $f { #!/bin/sh
DYLD_FALLBACK_LIBRARY_PATH=@@XAMPP_MYSQL_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/../common/lib:$DYLD_FALLBACK_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH
case "$@" in
    *--no-defaults*)
        exec $0.bin "$@"
        ;;
    *--defaults-file*)
        exec $0.bin "$@"
        ;;
esac
exec $0.bin --defaults-file=@@XAMPP_MYSQL_ROOTDIR@@/my.cnf "$@"}
               file attributes $f -permissions 0755;
           }
        }

        # Our installers expect mysql_install_db in the script folder
        file mkdir [prefix]/scripts
        file rename [prefix]/bin/mysql_install_db [prefix]/scripts
    }
}
