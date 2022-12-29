# 64-bits components and base classes for XAMPP

::itcl::class windows64XamppVcredist {
    inherit windowsXamppVcredist
    public variable vcVersion
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppVcredist
        set version 2012
        set vcVersion VC11
        set tarballName vcredist_x64_${version}.exe
    }
    public method install {} {
        set xamppoutputdir [file join [${be} cget -output] xampp]
        file copy -force [findTarball ${tarballName}] [file join [$be cget -output] vcredist_x64.exe]
        file copy -force [findTarball test_php_${vcVersion}.bat] [file join [$be cget -output] xampp test_php.bat]
        setReadmeVersion VCREDIST ${version}
    }
}

::itcl::class windows64XamppVcredist2015 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2015
        set vcVersion VC14
        set tarballName vcredist_x64_${version}.exe
    }
}

::itcl::class windows64XamppVcredist2017 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2017
        set vcVersion VC15
        set tarballName vcredist_x64_${version}.exe
        # if you find issues because VCRedist 2017 can't be found in the machine, ensure the Windows registry entry
        # being check in 'test_php_VC15.bat' exists
        # source: https://stackoverflow.com/questions/46178559/how-to-detect-if-visual-c-2017-redistributable-is-installed
    }
}

::itcl::class windows64XamppVcredist2019 {
    inherit windows64XamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set version 2019
        set vcVersion VS16
        set tarballName vcredist_x64_${version}.exe
    }
}

::itcl::class windows64XamppApache {
    inherit windowsXamppApache
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppApache
        set tarballName httpd-${version}-win64-VC11.zip
    }
}

::itcl::class windows64XamppApachePhp7 {
    inherit windows64XamppApache
    constructor {environment} {
	chain $environment
    } {
        set tarballName httpd-${version}-win64-VC14.zip
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php5" "php7"]
    }
}
::itcl::class windows64XamppApachePhp8 {
    inherit windows64XamppApache
    constructor {environment} {
	chain $environment
    } {
        set tarballName httpd-${version}-win64-VS16.zip
    }
    public method preparefordist {} {
        chain
        xampptcl::util::substituteParametersInFile $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php8_module" "php_module"]
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php5" "php8"]
        # PHP 8.0 is installed as 'php_module', and .7z and .zip assets don't run the preparefordist method
        xampptcl::util::substituteParametersInFile $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php8_module" "php_module"] 1
    }
}

::itcl::class windows64XamppApachePhp74 {
    inherit windows64XamppApachePhp7
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VC15.zip
    }
    public method preparefordist {} {
        chain
        # PHP 7.4.x prevents Apache and MariaDB from starting if vcruntime140.dll is present
        # "PHP Warning:  'vcruntime140.dll' 14.0 is not compatible with this PHP build linked with 14.16 in Unknown on line 0"
        file delete -force [file join $xamppoutputdir apache2/bin/vcruntime140.dll]
    }
}

::itcl::class windows64XamppApachePhp80 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS16.zip
    }
}
::itcl::class windows64XamppApachePhp81 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS16.zip
    }
}
::itcl::class windows64XamppApachePhp82 {
    inherit windows64XamppApachePhp8
    constructor {environment} {
	    chain $environment
    } {
        set tarballName httpd-${version}-win64-VS16.zip
    }
}

::itcl::class windows64XamppPhpAddons {
    inherit windowsXamppPhpAddons
    constructor {environment} {
        chain $environment
    } {
    }

    public method install {} {
        chain
        # Ensure OpenSSL-x64 binary
        file copy -force [file join $xamppoutputdir apache bin openssl.exe] [file join $xamppoutputdir php extras openssl openssl.exe]
    }
}

::itcl::class windows64XamppMysql {
  inherit windowsXamppMysql
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppMysql
        set tarballName mysql-${version}-win64.zip
        set pathName mysql-${version}-win64
    }
}

::itcl::class windows64XamppMariaDb {
  inherit windows64XamppMysql
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppMariaDb
        set fullname MariaDB
        set version [versions::get "MariaDB" "10"]
        set tarballName mariadb-${version}-winx64.zip
        set pathName mariadb-${version}-winx64
        lappend additionalFileList vcruntime140_1.dll
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFile [file join $xamppoutputdir mysql bin my.ini] [list skip-federated #skip-federated]
        setReadmeVersion MARIADB ${version}
        file copy -force [findFile vcruntime140_1.dll] [file join $xamppoutputdir mysql bin vcruntime140_1.dll]
    }

}

::itcl::class windows64XamppMysql55 {
  inherit windowsXamppMysql55
    constructor {environment} {
        chain $environment
    } {
        set tarballName mysql-${version}-win64.zip
    }
}

::itcl::class windows64XamppPerl {
    inherit windowsXamppPerl
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPerl
        set version [versions::get "Perl" "portable"]
        set tarballName strawberry-perl-${version}-64bit-portable.zip
    }

    public method install {} {
        chain
        setReadmeVersion PERL ${version}
    }
}

::itcl::class windows64XamppPhp {
    inherit windowsXamppPhp
    public variable vcVersion
    public variable opensslVersion
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp
        set fullname PHP
        set version [::xampp::php::getXAMPPVersion 55]
        set vcVersion VC11
        set opensslVersion 1.0.2j
        set licenseRelativePath {}
        set tarballName php-${version}-Win64-${vcVersion}-x86.zip
    }

    public method install {} {
        chain
        file copy -force [file join [$be cget -src] windowsXamppPhp] [file join $xamppoutputdir php]
        file copy -force [file join [$be cget -src] windowsXamppPhp php.ini-development] [file join $xamppoutputdir php php.ini]

        foreach f [glob -directory [file join [$be cget -src] windowsXamppPhp] icu*.dll libsasl.dll] {
            file copy -force $f [file join $xamppoutputdir apache bin]
        }

        phpiniSubstitutions
        copyFilesFromWorkspace
	setReadmeVersion PHP "$version (${vcVersion} X86 64bit thread safe)"
	# SSL is determined by PHP version, so best to set it here
	setReadmeVersion OPENSSL ${opensslVersion}
    }
}

::itcl::class windows64XamppPhp7 {
  inherit windows64XamppPhp
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp7
        set vcVersion VC14
        set opensslVersion [versions::get "OpenSSL" stable]
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp8 {
  inherit windows64XamppPhp
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp8
        set vcVersion VS16
        set opensslVersion [versions::get "OpenSSL" stable]
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
    public method install {} {
        chain
        # Fix warning message related to SQLite not being properly loaded
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list \
          "LoadModule\\s+php_module" "LoadFile \"/xampp/php/libsqlite3.dll\"\nLoadModule php_module"] 1
    }
}

::itcl::class windows64XamppPhp74 {
  inherit windows64XamppPhp7
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp74
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set vcVersion VC15
        set opensslVersion 1.1.0g
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
     public method install {} {
        chain
        # Fix warning message related to SQLite not being properly loaded
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list \
          "LoadModule\\s+php7_module" "LoadFile \"/xampp/php/libsqlite3.dll\"\nLoadModule php7_module"] 1
    }
}

::itcl::class windows64XamppPhp80 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp80
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set vcVersion VS16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp81 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp81
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set vcVersion VS16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppPhp82 {
  inherit windows64XamppPhp8
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhp82
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
        set vcVersion VS16
        set opensslVersion 1.1.1p
        set tarballName php-${version}-Win32-${vcVersion}-x64.zip
    }
}

::itcl::class windows64XamppCurl {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppCurl
        set version 7.64.0
        set licenseRelativePath {}
        set tarballName curl-${version}-win64-mingw
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        lappend additionalFileList curl-ca-bundle-${cacertificatesVersion}.crt
        set mainComponentXMLName xampp-apache
    }

    public method install {} {
        chain
        set curlDir [file join ${xamppoutputdir} apache bin]
        file mkdir ${curlDir}
        set srcDir [file join [$be cget -src] ${tarballName} bin]
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        file copy -force [findFile curl-ca-bundle-${cacertificatesVersion}.crt] [file join ${curlDir} curl-ca-bundle.crt]
        file copy -force [file join ${srcDir} curl.exe] [file join ${curlDir} curl.exe]
        file copy -force [file join ${srcDir} libcurl-x64.dll] [file join ${curlDir} libcurl.dll]
    }
}

::itcl::class windows64XamppPhpADODB {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhpADODB
        set version 518a
        set licenseRelativePath {}
        set tarballName adodb${version}.zip
        set mainComponentXMLName xampp-php
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] adodb5] [file join $xamppoutputdir php/pear/adodb]
        copyFilesFromWorkspace
        setReadmeVersion ADODB ${version}
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windows64XamppPhpXdebug {
  inherit windowsXamppComponent
    protected variable tarballBaseName {}
    protected variable libraryName {}
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppPhpXdebug
        set version 2.5.5-5.6
        set licenseRelativePath {}
        set tarballBaseName php_xdebug-${version}-vc11-x86_64
        set tarballName $tarballBaseName.zip
        set mainComponentXMLName xampp-php
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] xdebug]
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] xdebug php_xdebug.dll] [file join $xamppoutputdir php/ext/php_xdebug.dll]
    }
}

::itcl::class windows64XamppPhp74Xdebug {
  inherit windows64XamppPhpXdebug
    constructor {environment} {
        chain $environment
    } {
        set version 2.8.1-7.4
        set libraryName php_xdebug-${version}-vc15-x86_64.dll
        set tarballName ${libraryName}
        lappend additionalFileList ${libraryName}
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile ${libraryName}] [file join [$be cget -output] xampp php ext php_xdebug.dll]
    }
}

::itcl::class windows64XamppPhp80Xdebug {
  inherit windows64XamppPhpXdebug
    constructor {environment} {
        chain $environment
    } {
        set version 3.1.2-8.0
        set libraryName php_xdebug-${version}-vs16-x64.dll
        set tarballName ${libraryName}
        lappend additionalFileList ${libraryName}
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile ${libraryName}] [file join [$be cget -output] xampp php ext php_xdebug.dll]
    }
}

::itcl::class windows64XamppPhp81Xdebug {
  inherit windows64XamppPhpXdebug
    constructor {environment} {
        chain $environment
    } {
        set version 3.1.2-8.q
        set libraryName php_xdebug-${version}-vs16-x64.dll
        set tarballName ${libraryName}
        lappend additionalFileList ${libraryName}
    }
    public method extract {} {}
    public method install {} {
        file copy -force [findFile ${libraryName}] [file join [$be cget -output] xampp php ext php_xdebug.dll]
    }
}

::itcl::class windows64XamppTomcat {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windows64XamppTomcat
        set version [versions::get "Tomcat" "85"]
        set licenseRelativePath {}
        set tarballName apache-tomcat-${version}-windows-x64.zip
        set mainComponentXMLName xampp-tomcat
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] apache-tomcat-${version}] [file join $xamppoutputdir tomcat]
        copyFilesFromWorkspace
        setReadmeVersion TOMCAT ${version}
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace catalina_service.bat catalina_start.bat catalina_stop.bat
        copyFromWorkspace tomcat/catalina_start.bat tomcat/catalina_stop.bat tomcat/tomcat_service_install.bat tomcat/tomcat_service_uninstall.bat
    }
}

::itcl::class windows64XamppInstallerStack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist \
	    windows64XamppApache \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp \
	    windows64XamppPhpAddons \
	    windows64XamppPhpXdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandard
    }
}

::itcl::class windows64XamppInstallerPhp74Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2017 \
	    windows64XamppApachePhp74 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp74 \
	    windows64XamppPhpAddons \
	    windows64XamppPhp74Xdebug \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandardPhp74
    }
}

::itcl::class windows64XamppInstallerPhp80Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp80 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp80 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp80
    }
}

::itcl::class windows64XamppInstallerPhp82Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp82 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp82 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp82
    }
}

::itcl::class windows64XamppInstallerPhp81Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp81 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp81 \
	    windows64XamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windows64XamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
        windowsXamppStandardPhp81
    }
}


::itcl::class windows64XamppPortableInstallerStack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist \
	    windows64XamppApache \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp \
	    windows64XamppPhpAddons \
	    windowsXamppPhpXdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortable
    }
}

::itcl::class windows64XamppPortableInstallerPhp74Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2017 \
	    windows64XamppApachePhp74 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp74 \
	    windowsXamppPhpAddons \
	    windows64XamppPhp74Xdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp74
    }
}

::itcl::class windows64XamppPortableInstallerPhp80Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp80 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp80 \
	    windowsXamppPhpAddons \
        windows64XamppPhp80Xdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp80
    }
}

::itcl::class windows64XamppPortableInstallerPhp81Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp81 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp81 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp81
    }
}
::itcl::class windows64XamppPortableInstallerPhp82Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windows64XamppVcredist2019 \
	    windows64XamppApachePhp82 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windows64XamppMariaDb \
	    windowsXamppMysqlData \
	    windows64XamppPerl \
	    windowsXamppPerlAddons \
	    windows64XamppPhp82 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windows64XamppCurl \
	    windows64XamppTomcat \
	    windowsXamppPortablePhp82
    }
}
