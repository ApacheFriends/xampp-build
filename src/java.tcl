::itcl::class tomcat {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name tomcat
        set vtrackerName tomcat85
        set fullname Tomcat
        set dependencies {tomcat {tomcat.xml tomcat-properties.xml tomcat-java.xml tomcat-service.xml tomcat-functions.xml tomcat-manager.xml tomcat-noroot.xml tomcat-upgrade.xml tomcatcomponents-upgrade.xml tomcat-imagemagick.xml}}
        set moduleDependencies {tomcat {tomcat-properties.xml tomcat-functions.xml}}
        set scriptFiles {ctl.sh {linux osx solaris-intel solaris-sparc} {servicerun.bat serviceinstall.bat} windows}
        set readmePlaceholder TOMCAT
        set licenseRelativePath LICENSE
        set requiredMemory 1024
        set downloadType wget
    }
    public method setEnvironment {} {
        set ::opts(tomcat.prefix) [prefix]
        set ::opts(tomcat.lib) [prefix]/common/lib
        chain
        set ::opts(tomcat.lib) [prefix]/lib
    }
    public method srcdir {} {
        return [file join [$be cget -src] apache-tomcat-$version]
    }
    public method prefix {} {
        return [file join [$be cget -output] apache-tomcat]
    }
    public method build {} {
    }
    public method install {} {
        file delete -force [prefix]
        file copy -force [srcdir] [prefix]
        file delete -force [prefix]/.buildcomplete
        if {![string match windows* [$be cget -target]]} {
            file copy -force [findTarball jsvc-linux-x64] [file join [prefix] bin jsvc]
            if { $version == "6.0.29" } {
                file copy -force [findTarball commons-daemon.jar] [file join [prefix] bin commons-daemon.jar]
            }
            if {![file exists [file join [prefix] bin daemon.sh]]} {
                file copy -force [findTarball java/daemon.sh] [file join [prefix] bin]
            }
            foreach f {jsvc daemon.sh} {
                file attributes [prefix]/bin/$f -permissions 0755
            }
        }
    }
    public method preparefordist {} {
        chain
        file mkdir -force [file join [prefix] scripts ]
        file copy -force /tmp/tarballs/tomcat/format_env_gce20160519.sh [file join [prefix] scripts ]/format_env_gce.sh
        if { [file exists [file join [prefix] bin service.bat]] } {
            xampptcl::util::substituteParametersInFile \
                [file join [prefix] bin/service.bat] \
                [list {"%EXECUTABLE%" //US//%SERVICE_NAME% --JvmOptions "-Dcatalina.base=%CATALINA_BASE%;-Dcatalina.home=%CATALINA_HOME%;-Djava.endorsed.dirs=%CATALINA_HOME%\common\endorsed" --StartMode jvm --StopMode jvm} {"%EXECUTABLE%" //US//%SERVICE_NAME% --Startup auto --JvmOptions "-Dcatalina.base=%CATALINA_BASE%;-Dcatalina.home=%CATALINA_HOME%;-Djava.endorsed.dirs=%CATALINA_HOME%\common\endorsed" --StartMode jvm --StopMode jvm} \
            {set PR_DISPLAYNAME=Apache Tomcat %2} {set PR_DISPLAYNAME=%2}]
        }
        cleanupExampleFiles

        if [file exists [prefix]/bin/service.bat] {
            if {[string match {8.0.*} $version]} {
                xampptcl::util::substituteParametersInFile [prefix]/bin/service.bat \
                    [list {%CATALINA_BASE%\conf\logging.properties;%JvmArgs%"} {%CATALINA_BASE%\conf\logging.properties;%JvmArgs%" %JAVA_OPTS%}] 1
            } else {
                xampptcl::util::substituteParametersInFile [prefix]/bin/service.bat \
                    [list {;%JvmArgs%"} {" %JAVA_OPTS%}] 1
                xampptcl::util::substituteParametersInFile [prefix]/bin/service.bat \
                    [list \
                         {--Startup "%SERVICE_STARTUP_MODE%" ^"} {} \
                         {--JvmMs "%JvmMs%" ^} {} \
                         {--JvmMx "%JvmMx%"} {} ]
            }
        }
        xampptcl::util::substituteParametersInFile \
            [file join [prefix] conf server.xml] \
            [list \
                 {port="8080"} {port="@@XAMPP_TOMCAT_PORT@@" URIEncoding="UTF-8"} \
                 {port="8009"} {port="@@XAMPP_TOMCAT_AJP_PORT@@"} \
                 {port="8005"} {port="@@XAMPP_TOMCAT_SHUTDOWN_PORT@@"} \
                 {redirectPort="8443"} {redirectPort="@@XAMPP_TOMCAT_SSL_PORT@@"} \
                 {<Listener className="org.apache.catalina.core.AprLifecycleListener" />} {<!-- <Listener className="org.apache.catalina.core.AprLifecycleListener" /> -->} \
                ]
    }
    protected method cleanupExampleFiles {} {
        foreach dir {webapps/tomcat-docs webapps/servlets-examples webapps/jsp-examples} {
            file delete -force [prefix]/$dir
        }
    }
    public method getProgramFiles {} {
        if [isWindows] {
            return [list serviceinstall.bat servicerun.bat]
        } else {
            return [list ctl.sh]
        }
    }
    public method copyProjectFiles {stack} {
        file mkdir [file join [$be cget -output] apache-tomcat scripts]
        foreach f [getProgramFiles] {
            file copy -force [file join [$be cget -projectDir] base tomcat $f] [file join [$be cget -output] apache-tomcat scripts]
        }
        chain $stack
    }
    public method copyScripts {} {
        chain
        if {![isWindows]} {
            file attributes  [prefix]/scripts/ctl.sh -permissions 0755
            xampptcl::util::substituteParametersInFile \
                [prefix]/scripts/ctl.sh \
                [list {shutdown.sh} {shutdown.sh 10 -force} \
                  {rm $CATALINA_PID} {if [ -f $CATALINA_PID ] ; then
           rm $CATALINA_PID
         fi}]
        }
        if { [string match osx* [$be cget -target]] } {
            xampptcl::util::substituteParametersInFile [prefix]/bin/daemon.sh \
                [list {-wait 10} {-wait 10 -jvm server}]
        }
    }
    public method buildBnconfig {} {
        chain
        file mkdir [prefix]
        file copy -force [glob [$be cget -output]/$name/bnconfig*] [prefix]
    }
    public method getTarballName {} {
       if [isWindows64] {
            return apache-tomcat-$version-windows-x64
       } else {
            return apache-tomcat-$version
        }
    }
    public method getDefaultApplicationUser {} {
        return manager
    }
    public method getDefaultApplicationPassword {} {
        return bitnami
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        set urlFolder [lindex [split $version .] 0]
        set downloadUrlBase https://downloads.apache.org/tomcat/tomcat-$urlFolder/v$version/bin/
        set downloadUrl [list $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip $downloadUrlBase/apache-tomcat-$version.tar.gz]
        foreach du $downloadUrl {
            set downloadUrl $du
            chain
            set downloadTarballName ""
        }
    }
}

::itcl::class tomcat85 {
   inherit tomcat
   constructor {environment} {
       chain $environment
   } {
       set vtrackerName tomcat85
       set version [versions::get "Tomcat" 85]
       set urlFolder [lindex [split $version .] 0]
       set downloadUrlBase https://downloads.apache.org/tomcat/tomcat-$urlFolder/v$version/bin/
       if { [$be cget -target] == "windows-x64" } {
           set downloadUrl $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip
       } else {
           set downloadUrl $downloadUrlBase/apache-tomcat-$version.tar.gz
       }
       set patchList {apache-tomcat.12691.patch}
   }
    public method download {} {
        set version  [getVersionFromVtracker]
        set urlFolder [lindex [split $version .] 0]
        set downloadUrlBase http://apache.uvigo.es/tomcat/tomcat-$urlFolder/v$version/bin
        set downloadUrl [list $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip $downloadUrlBase/apache-tomcat-$version.tar.gz]
        chain
    }
}

::itcl::class tomcat9 {
   inherit tomcat
   constructor {environment} {
       chain $environment
   } {
       set vtrackerName tomcat9
       set version [versions::get "Tomcat" 9]
       regexp -- {^(.)*\..*\..*$} $version -- urlFolder
       set downloadType wget
       set downloadUrlBase http://apache.uvigo.es/tomcat/tomcat-$urlFolder/v$version/bin
       if { [$be cget -target] == "windows-x64" } {
           set downloadUrl $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip
       } else {
           set downloadUrl $downloadUrlBase/apache-tomcat-$version.tar.gz
       }
       set patchList {apache-tomcat.12691.patch}
   }
    public method download {} {
        set version  [getVersionFromVtracker]
        regexp -- {^(.)*\..*\..*$} $version -- urlFolder
        set downloadUrlBase http://apache.uvigo.es/tomcat/tomcat-$urlFolder/v$version/bin
        set downloadUrl [list $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip $downloadUrlBase/apache-tomcat-$version.tar.gz]
        chain
    }
}

::itcl::class tomcat10 {
   inherit tomcat
   constructor {environment} {
       chain $environment
   } {
       set vtrackerName tomcat10
       set version [versions::get "Tomcat" 10]
       set urlFolder [lindex [split $version .] 0]
       set downloadType wget
       set downloadUrlBase http://apache.uvigo.es/tomcat/tomcat-$urlFolder/v$version/bin
       if { [$be cget -target] == "windows-x64" } {
           set downloadUrl $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip
       } else {
           set downloadUrl $downloadUrlBase/apache-tomcat-$version.tar.gz
       }
       set patchList {apache-tomcat.12691.patch}
   }
    public method download {} {
        set version  [getVersionFromVtracker]
        set urlFolder [lindex [split $version .] 0]
        set downloadUrlBase http://apache.uvigo.es/tomcat/tomcat-$urlFolder/v$version/bin
        set downloadUrl [list $downloadUrlBase/apache-tomcat-${version}-windows-x64.zip $downloadUrlBase/apache-tomcat-$version.tar.gz]
        chain
    }
}

::itcl::class mysql-connector-java {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set name mysql-connector-java
        set version [versions::get "MySQL-Connector-Java" stable]
        set licenseRelativePath LICENSE
        set isReportableAsMainComponent 0
        set ::opts(mysql-connector-java.version) $version
        set downloadType wget
        set downloadUrl https://dev.mysql.com/get/Downloads/Connector-J/$name-$version.zip
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        set downloadType wget
        if {$name == "mysql-connector-java"} {
            set downloadUrl https://dev.mysql.com/get/Downloads/Connector-J/$name-$version.zip
        } else {
            set downloadUrl http://downloads.mariadb.com/Connectors/java/connector-java-$version/mariadb-java-client-$version.jar
        }
        chain
    }
    public method setEnvironment {} {
        set ::opts(mcj.prefix) [prefix]
        chain
    }

    public method build {} {

    }

    public method install {} {
        if {[info exists ::opts(mysql-connector-java.customDir)]} {
            file copy -force [srcdir]/mysql-connector-java-$version.jar $::opts(mysql-connector-java.customDir)
        }	elseif {[info exists ::opts(tomcat.lib)]} {
            file copy -force [srcdir]/mysql-connector-java-$version.jar $::opts(tomcat.lib)
        } else {
            message error "No tomcat found. You can override the destination using ::opts(mysql-connector-java-customDir)"
            exit 1
        }
    }

    public method preparefordist {} {
    }
}

::itcl::class mariadb-connector-java {
    inherit mysql-connector-java
    constructor {environment} {
	 chain $environment
    } {
        set name mariadb-connector-java
        set version [versions::get "MariaDB-Connector-Java" stable]
        set downloadUrl http://downloads.mariadb.com/Connectors/java/connector-java-$version/mariadb-java-client-$version.jar
        set licenseRelativePath {}
        set tarballName mariadb-java-client-$version.jar
        set ::opts(mariadb-connector-java.version) $version
    }

    public method needsToBeBuilt {} {
        return 0
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile $tarballName] $::opts(tomcat.lib)
	}
}

::itcl::class resin {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name [getProgramName]
        set version 4.0.41
        set dependencies {resin {resin.xml resin-functions.xml resin-properties.xml resin-validations.xml resin-service.xml}}
        set scriptFiles {ctl.sh {linux osx solaris-intel solaris-sparc} {servicerun.bat serviceinstall.bat} windows}
        set readmePlaceholder RESIN
        set licenseRelativePath LICENSE

        set folderAtThirdparty [$be cget -tarballs]/java
        set downloadType wget
        set downloadUrl http://caucho.com/download/$name-$version.tar.gz
    }
    protected method getProgramName {} {
        return resin
    }
    public method setEnvironment {} {
        set ::opts(${name}.prefix) [prefix]
        set ::opts(${name}.lib) [prefix]/lib
    }
    public method configureOptions {} {
        return [list --with-resin-init-d=[prefix]/bin/resinctl --with-openssl=$::opts(openssl.prefix) --enable-ssl "SSL_LIBS=-L$::opts(openssl.prefix)/lib -lssl -lcrypto"]
    }
    public method preparefordist {} {
        if { [file exists [file join [prefix] conf resin.xml]] } {
            set resin_conf_file [file join [prefix] conf resin.xml]
        } else {
            set resin_conf_file [file join [prefix] conf resin.conf]
        }
        xampptcl::util::substituteParametersInFile $resin_conf_file \
            [list {port="8080"} {port="@@XAMPP_RESIN_PORT@@"} {<watchdog-port>6600</watchdog-port>} {<watchdog-port>@@XAMPP_RESIN_SHUTDOWN_PORT@@</watchdog-port>} \
                  {6800} {@@XAMPP_RESIN_CLUSTER_PORT@@}]
    }
    public method copyScripts {} {
        chain
        if { [file exists [file join [prefix] bin resin.sh]] } {
            set resin_control_script resin.sh
        } elseif { [file exists [file join [prefix] bin httpd.sh]]} {
            set resin_control_script httpd.sh
        } else {
           message error "Cannot find resin control script."
           exit 1
        }
        if { ![string match windows* [$be cget -target]] } {
          xampptcl::util::substituteParametersInFile [prefix]/scripts/ctl.sh \
            [list {@@XAMPP_RESIN_CONTROL_SCRIPT@@} "$resin_control_script" ]
          xampptcl::util::substituteParametersInFile [prefix]/bin/$resin_control_script \
            [list {#! /bin/sh} {#! /bin/sh
. @@XAMPP_INSTALLDIR@@/scripts/setenv.sh} ]
        }
    }
    public method removeDocs {} {}
}

::itcl::class resinpro {
    inherit resin
    constructor {environment} {
        chain $environment
    } {}
    protected method getProgramName {} {
        return resin-pro
    }
    public method configureOptions {} {
        return [linsert [chain] end --with-openssl=$::opts(openssl.prefix) --enable-ssl "SSL_LIBS=-L$::opts(openssl.prefix)/lib -lssl -lcrypto"]
    }
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base resin]
    }
}

::itcl::class resinNotCompiled {
    inherit resin
    constructor {environment} {
       chain $environment
    } {}

    public method build {} {}
    public method install {} {
        file delete -force [prefix]
        file copy -force [srcdir] [prefix]
        file delete -force [prefix]/.buildcomplete
    }
}

::itcl::class postgres-connector-java {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set name postgres-connector-java
        set version [versions::get "Postgres-Connector-Java" stable]
        set tarballName postgresql-${version}.jar
        set readmePlaceholder POSTGRESQLJDBC
        set licenseRelativePath {}
        set isReportableAsMainComponent 0
        set downloadType wget
        set downloadUrl https://jdbc.postgresql.org/download/postgresql-$version.jar
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        set downloadType wget
        set downloadUrl https://jdbc.postgresql.org/download/postgresql-$version.jar
        chain
    }
    public method needsToBeBuilt {} {
        return 0
    }
    public method extract {} {}
    public method build {} {}
    public method install {} {
        if {[info exists ::opts(postgres-connector-java.customDir)]} {
            file copy -force [findTarball] $::opts(postgres-connector-java.customDir)
        } elseif {[info exists ::opts(tomcat.lib)]} {
            file copy -force [findTarball] $::opts(tomcat.lib)
        } elseif {[info exists ::opts(resin.lib)]} {
            file copy -force [findTarball] $::opts(resin.lib)
        } elseif {[info exists ::opts(resin-pro.lib)]} {
            file copy -force [findTarball] $::opts(resin-pro.lib)
        } else {
            message error "Not tomcat or resin found. You can override the destination using ::opts(postgres-connector-java-customDir)"
            exit 1
        }

    }
    public method preparefordist {} {}
}

::itcl::class javaServiceWrapper {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name java-service-wrapper
        set version 32-3.5.7
        set tarballName wrapper-windows-x86-$version
        set licenseRelativePath README_en.txt
        set readmePlaceholder JAVASERVICEWRAPPER
    }
    public method srcdir {} {
        return [file join [$be cget -src] $tarballName]
    }
    public method build {} {}
    public method install {} {
        file copy -force [file join [srcdir] bin wrapper.exe] [prefix]
        file copy -force [file join [srcdir] lib wrapper.dll] [file join [prefix] lib]
        file copy -force [file join [srcdir] lib wrapper.jar] [file join [prefix] lib]
    }
    public method preparefordist {} {
        xampptcl::file::write [file join [prefix] wrapper.conf] {
set.JAVA_HOME=@@XAMPP_INSTALLDIR@@\java
wrapper.java.command=%JAVA_HOME%\bin\java
wrapper.java.library.path.1=lib
wrapper.java.classpath.1=lib/*.jar
wrapper.console.format=PM
wrapper.console.loglevel=INFO
wrapper.logfile.format=LPTM
wrapper.logfile.loglevel=INFO
wrapper.logfile.maxsize=0
wrapper.logfile.maxfiles=0
wrapper.syslog.loglevel=NONE
#wrapper.debug=TRUE
wrapper.ntservice.starttype=AUTO_START
wrapper.ntservice.interactive=false
wrapper.filter.trigger.1=java.lang.OutOfMemoryError
wrapper.filter.action.1=RESTART
        }
    }

}

::itcl::class resinJavaServiceWrapper {
    inherit javaServiceWrapper
    constructor {environment} {
        chain $environment
    } {}
    public method prefix {} {
        return $::opts(resin.prefix)
    }
    public method copyScripts {} {
        chain
        file copy -force [file join [$be cget -projectDir] base resin serviceinstall-javaservicewrapper.bat] [prefix]/scripts/serviceinstall.bat
        file copy -force [file join [$be cget -projectDir] base resin servicerun-javaservicewrapper.bat] [prefix]/scripts/servicerun.bat
    }
    public method preparefordist {} {
        chain
        if { ![file exists [prefix]/log] } {
            file mkdir [prefix]/log
        }
        xampptcl::file::append [file join [prefix] wrapper.conf] {
set.RESIN_HOME=@@XAMPP_INSTALLDIR@@\resin
wrapper.logfile=log/resin-service.log
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperStartStopApp
wrapper.app.parameter.1=com.caucho.boot.ResinBoot
wrapper.app.parameter.2=5
wrapper.app.parameter.3=-resin-home
wrapper.app.parameter.4=%RESIN_HOME%
wrapper.app.parameter.5=-root-directory
wrapper.app.parameter.6=%RESIN_HOME%
wrapper.app.parameter.7=start-with-foreground
wrapper.app.parameter.8=com.caucho.boot.ResinBoot
wrapper.app.parameter.9=TRUE
wrapper.app.parameter.10=5
wrapper.app.parameter.11=-resin-home
wrapper.app.parameter.12=%RESIN_HOME%
wrapper.app.parameter.13=-root-directory
wrapper.app.parameter.14=%RESIN_HOME%
wrapper.app.parameter.15=stop
wrapper.ntservice.name=@@XAMPP_RESIN_SERVICE_NAME@@
wrapper.ntservice.displayname=@@XAMPP_RESIN_SERVICE_NAME@@
wrapper.ntservice.description=@@XAMPP_RESIN_SERVICE_NAME@@

# Java settings
wrapper.java.initmemory=128
wrapper.java.maxmemory=512
        }
    }
}

::itcl::class tomcatNative {
    inherit library
    constructor {environment} {
	chain $environment
    } {
        set name tomcatnative
        # To check the correct version of Tomcat Native for tomcat, look for the text
        # "Update the packaged version of the Tomcat Native Library to"
        # https://tomcat.apache.org/tomcat-10.0-doc/changelog.html
        set version [versions::get "TomcatNative" stable]
        set licenseRelativePath ../LICENSE
        set downloadType wget
        set downloadUrl https://dlcdn.apache.org/tomcat/tomcat-connectors/native/${version}/source/tomcat-native-${version}-src.tar.gz
        set tarballName tomcat-native-$version-src
    }
    public method configureOptions {} {
        if [info exist ::opts(apache.apr)] {
            return [list --with-apr=$::opts(apache.apr) --with-ssl=$::opts(openssl.prefix)]
        } elseif [file exists [file join [$be cget -output] [$be cget -libprefix] bin apr-1-config]] {
            return [list --with-apr=[file join [$be cget -output] [$be cget -libprefix] bin apr-1-config] --with-ssl=$::opts(openssl.prefix)]
        } else {
            message error "Any apr-1-config file found"
	    exit 1
        }
    }
    public method srcdir {} {
        return [file join [$be cget -src] $tarballName native]
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        set downloadType wget
        set downloadUrl https://dlcdn.apache.org/tomcat/tomcat-connectors/native/${version}/source/tomcat-native-${version}-src.tar.gz
        set tarballName tomcat-native-$version-src
        chain
    }
}

