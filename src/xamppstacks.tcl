::itcl::class linuxXamppInstallerStack {
    inherit stack
    public variable pearModulesList {}
       constructor {environment} {
           chain $environment
       } {
           addComponents baseFiles
           addComponents m4 libtool ::xampp::pcre ::xampp::zlib ::xampp::libiconv
           addComponents ::xampp::gettext ::xampp::cmake

           # ming requires it
           addComponents bison flex
           addComponents ::xampp::ncurses ::xampp::bzip2 ::xampp::libpng ::xampp::tiff ::xampp::jpeg ::xampp::freetype libwebp libzip gd ::xampp::opensslVersioned ::xampp::openldap libmcrypt ::xampp::curl ::xampp::imap ::xampp::expatLib ::xampp::libxml2 ::xampp::libxslt ::xampp::apr ::xampp::aprutil
           addComponents chrpath ::xampp::oracleInstantclientLinuxX86Lib ::xampp::oracleInstantclientLinuxX86Sdk
           addComponents ::xampp::nghttp2 ::xampp::apache ::xampp::icu4c  ::xampp::freetds  ::xampp::sqlite  ::xampp::postgresql groff ::xampp::mariadb10 ::xampp::sablotron ::xampp::gdbm  ::xampp::perl libaio ::xampp::php ::xampp::phpPdfClasses ::xampp::fpdf ::xampp::ming ::xampp::pecl_radius ::xampp::pecl_ncurses ::xampp::modperl cpanArchiveZip cpanYAML cpanXSBuilder cpanIoZlib cpanBundleCpan cpanURI cpanIoCompress cpanHTML-Parser cpanHTML-Tagset cpanMakeMaker cpanParseRecDescent cpanDevelCheckLib cpanDBI cpanDBD-mariadb ::xampp::cpanLWP cpanDBDPgPP cpanDBD-SQLite ::xampp::libapreq2 ::xampp::zziplib ::xampp::proftpd ::xampp::mhash ::xampp::webalizer ::xampp::phpmyadmin

           # I changed order of XML_Parser and XML_NITF for OS X
           set pearModulesList {Archive_Tar File File_Find File_HtAccess File_SearchReplace Auth Auth_HTTP DB Auth_SASL Benchmark Cache XML_CSSML XML_fo2pdf XML_HTMLSax XML_image2svg  XML_Parser XML_NITF XML_RSS XML_SVG XML_Transformer XML_Tree XML_Util  XML_RPC XML_Serializer Cache_Lite Console_Getopt Console_Table System_Command Contact_Vcard_Build Contact_Vcard_Parse MP3_Id Crypt_CBC Crypt_RC4 Crypt_Xtea DBA DB_ado DB_DataObject DB_ldap DB_NestedSet DB_Pager DB_QueryTool MDB Log MDB_QueryTool FSM Tree HTML_BBCodeParser HTML_BBCodeParser2 HTML_Common HTML_Common2 HTML_Crypt HTML_CSS HTML_Form HTML_Menu HTML_Javascript HTML_Progress HTML_QuickForm I18N HTML_Select_Common HTML_Table HTML_Template_IT HTML_Template_PHPLIB HTML_Template_Sigma HTML_Template_Xipe HTML_TreeMenu Pager HTTP Image_Color Image_GIS Image_GraphViz Image_IPTC Mail Mail_Mime Mail_mimeDecode Mail_Queue Math_Integer Math_Basex Math_Fibonacci Math_Vector Math_Matrix Math_RPN Math_Stats Math_TrigOp Net_CheckIP Net_Curl Net_Dig Net_DNS Net_FTP Net_Geo Net_Ident Net_IPv4 Net_SmartIRC Net_Socket Net_SMTP Net_Sieve Net_NNTP Net_Ping Net_POP3 Net_Portscan Net_Finger Net_Dict Net_URL HTTP_Request HTTP_Upload Net_UserAgent_Detect Net_Whois Numbers_Roman Payment_Clieop Console_Getargs PEAR PEAR_Info PEAR_PackageFileManager_Plugins PEAR_PackageFileManager2 PhpDocumentor YAML File_Iterator Text_Template PHP_TokenStream PHP_CodeCoverage PHP_Timer PHPUnit_MockObject PHPUnit Var_Dump xdebug Science_Chemistry Stream_Var Text_Password Text_Statistics Translation}
           foreach pearModule $pearModulesList {
               # It also has dependencies with the old DB module
               if {[string match Translation $pearModule]} {continue}

               # They do not include it
               if {[string match PhpDocumentor $pearModule]} {continue}

               #*** WARNING: "pear/DB" is deprecated in favor of "pear/MDB2"
               #pear/DB_ado requires PHP extension "com"
               #No valid packages found
               #install failed
               if {[string match DB* $pearModule]} {
                   continue
               }
               #circular dependencies with File_CSV and File_Util
               if {$pearModule == "File"} {
                   continue
               }
               #** pear/XML_CSSML requires PHP (version >= 4.4.0, version <= 5.0.0, excluded versions: 5.0.0), installed version is 5.4.7
               if {$pearModule == "XML_CSSML" || $pearModule == "XML_Transformer"} {
                   continue
               }

               addComponents ::xampp::$pearModule
           }
           addComponents  ::xampp::sqlite2
           addComponents ::xampp::xamppSkeleton
           addComponents ::xampp::xamppHtdocsUnix
           addComponents ::xampp::manager
           addComponents nativeadapter
       }

    protected method getXamppOutputDir {} {
        return /opt/lampp
    }

    public method setEnvironment {} {
        set output [getXamppOutputDir]
        $be configure -baseTarballOutputDir [$be cget -output]
        switch -glob -- [$be cget -buildType] {
            fromSource* - continueAt {
                $be configure -output $output
                $be configure -licensesDirectory [file join [$be cget -output] licenses]
                $be configure -tmpDir /tmp/
            }
        }

        $be configure -libprefix ""
        $be configure -removeDocs 0
        setCompilationVariables $output
    }
    protected method setCompilationVariables {output} {
        set ::env(SHARED_LDFLAGS) "-Wl,--rpath -Wl,$output/lib -L$output/lib"
        set ::env(LDFLAGS) "-Wl,--rpath -Wl,$output/lib -L$output/lib -I$output/include"
        set ::env(LD_RUN_PATH) $output/lib
        set ::env(CPPFLAGS) "-O3 -L$output/lib -I$output/include -I$output/include/ncurses"
        set ::env(CFLAGS) "-O3 -L$output/lib -I$output/include -I$output/include/ncurses"
        set ::env(CXXFLAGS) "-O3 -L$output/lib -I$output/include"
        set ::env(LD_LIBRARY_PATH) "/opt/lampp/lib"
        if {[info exists ::env(PATH)]} {
            if {![string match /opt/lampp/bin:* $::env(PATH)]} {
                set ::env(PATH) "/opt/lampp/bin:$::env(PATH)"
            }
        } else {
	    set ::env(PATH) "/opt/lampp/bin"
        }
    }
    public method componentsToBuild {} {
        if {[$be cget -buildType]=="fromTarball"} {
            return [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]
        } else {
            return [lremove [chain] [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]]
        }
    }
    public method preparefordist {} {
        chain
        file copy -force [$be cget -output]/RELEASENOTES [file join [$be cget -output] "lampp"]
    }
}

::itcl::class linuxXamppInstallerXStack {
    inherit linuxXamppInstallerStack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::zziplib {{::xampp::zziplib version 0.13.62}}
        replaceComponent gd {libltdl ::xampp::gd}
        replaceComponent ::xampp::MDB {{::xampp::MDB2}}
        replaceComponent ::xampp::HTML_Form {{::xampp::HTML_QuickForm2}}
        removeComponents [list ::xampp::pecl_radius ::xampp::XML_HTMLSax ::xampp::xdebug ::xampp::Stream_SHM]
    }
    public method componentsToBuild {} {
        if {[$be cget -buildType]=="fromTarball"} {
            return [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]
        } else {
            return [lremove [chain] [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix]]
        }
    }
}

::itcl::class linuxXamppInstaller74Stack {
    inherit linuxXamppInstallerXStack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::php {oniguruma {::xampp::php74}}
    }
}
::itcl::class linuxXamppInstaller80Stack {
    inherit linuxXamppInstallerXStack
    constructor {environment} {
        chain $environment
    } {
        # There is an issue with PHP if gd is previously compiled
        removeComponents ::xampp::gd
        replaceComponent ::xampp::php {oniguruma {::xampp::php80} ::xampp::gd}
        replaceComponent ::xampp::xamppSkeleton ::xampp::xamppSkeletonDev
    }
    public method componentsToBuild {} {
        if {[$be cget -buildType]=="fromTarball"} {
            return [list ::xampp::xamppSkeletonDev ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]
        } else {
            return [lremove [chain] [list ::xampp::xamppSkeletonDev ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]]
        }
    }
}
::itcl::class linuxXamppInstaller81Stack {
    inherit linuxXamppInstaller80Stack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::php80 ::xampp::php81
    }
}
::itcl::class linuxXamppInstaller82Stack {
    inherit linuxXamppInstaller81Stack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::php81 ::xampp::php82
    }
}

::itcl::class linux64XamppInstallerStack {
    inherit linuxXamppInstallerStack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::zziplib {{::xampp::zziplib version 0.13.62}}
        replaceComponent ::xampp::oracleInstantclientLinuxX86Lib ::xampp::oracleInstantclientLinuxX64Lib
        replaceComponent ::xampp::oracleInstantclientLinuxX86Sdk  ::xampp::oracleInstantclientLinuxX64Sdk
    }
    protected method setCompilationVariables {output} {
        set ::env(SHARED_LDFLAGS) "-Wl,--rpath -Wl,$output/lib -L$output/lib"
        set ::env(LDFLAGS) "-Wl,--rpath -Wl,$output/lib -L$output/lib -I$output/include"
        set ::env(LD_RUN_PATH) $output/lib
        set ::env(CPPFLAGS) "-O3 -fPIC -L$output/lib -I$output/include -I$output/include/ncurses"
        set ::env(CFLAGS) "-O3 -fPIC -L$output/lib -I$output/include -I$output/include/ncurses"
        set ::env(CXXFLAGS) "-O3 -L$output/lib -I$output/include"
        set ::env(LD_LIBRARY_PATH) "/opt/lampp/lib"
        if {[info exists ::env(PATH)]} {
            if {![string match /opt/lampp/bin:* $::env(PATH)]} {
                set ::env(PATH) "/opt/lampp/bin:$::env(PATH)"
            }
        } else {
            set ::env(PATH) "/opt/lampp/bin"
        }
    }
}

::itcl::class linux64XamppInstaller74Stack {
    inherit linuxXamppInstaller74Stack
    constructor {environment} {
        chain $environment
    } {
    }
}
::itcl::class linux64XamppInstaller80Stack {
    inherit linuxXamppInstaller80Stack
    constructor {environment} {
        chain $environment
    } {
    }
}
::itcl::class linux64XamppInstaller81Stack {
    inherit linuxXamppInstaller81Stack
    constructor {environment} {
        chain $environment
    } {
    }
}
::itcl::class linux64XamppInstaller82Stack {
    inherit linuxXamppInstaller82Stack
    constructor {environment} {
        chain $environment
    } {
    }
}
::itcl::class osx64XamppInstallerStack {
    inherit linuxXamppInstallerStack
    constructor {environment} {
        chain $environment
    } {
        removeComponents [list chrpath]
        replaceComponent gd {::xampp::gd}
        replaceComponent ::xampp::zziplib {{::xampp::zziplib version 0.13.62}}
        replaceComponent ::xampp::oracleInstantclientLinuxX86Lib ::xampp::oracleInstantclientOsxX64Lib
        replaceComponent ::xampp::oracleInstantclientLinuxX86Sdk ::xampp::oracleInstantclientOsxX64Sdk
        replaceComponent ::xampp::libiconv libiconvOsxNative
        replaceComponent ::xampp::libxml2 libxml2OsxNative
        replaceComponent ::xampp::libxslt libxsltOsxNative
        replaceComponent ::xampp::cmake {{cmake version 3.9.6}}
        replaceComponent libmcrypt {autoconf pkgconfig libtool2 ::xampp::libmcrypt}
    }
    public method preparefordist {} {
        foreach f [glob [file join [$be cget -output] "xamppfiles" postgresql lib libpq.*]] {
            file copy -force $f [file join [$be cget -output] "xamppfiles" lib]
        }
        file mkdir [file join [$be cget -output] "xamppfiles" docs]
        file copy -force [$be cget -output]/RELEASENOTES [file join [$be cget -output] "xamppfiles"]
    }
    public method componentsToBuild {} {
        if {[$be cget -buildType]=="fromTarball"} {
            return [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]
        } else {
            return [lremove [chain] [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]]
        }
    }
    protected method getXamppOutputDir {} {
        return /Applications/XAMPP/xamppfiles
    }
    public method setCompilationVariables {output} {
        set ::env(SHARED_LDFLAGS) "-Wl,-rpath -Wl,$output/lib -L$output/lib"
        set ::env(LDFLAGS) "-Wl,-rpath -Wl,$output/lib -L$output/lib -I$output/include -arch x86_64"
        set ::env(LD_RUN_PATH) $output/lib
        set ::env(CPPFLAGS) "-O3 -L$output/lib -I$output/include -I$output/include/ncurses -arch x86_64"
        set ::env(CFLAGS) "-O3  -L$output/lib -I$output/include -I$output/include/ncurses -arch x86_64"
        set ::env(CXXFLAGS) "-O3 -L$output/lib -I$output/include"
        if {[info exists ::env(PATH)]} {
            if {![string match $output/bin:* $::env(PATH)]} {
                set ::env(PATH) "$output/bin:$::env(PATH)"
            }
        } else {
            set ::env(PATH) "$output/bin"
        }
        # Try to fix issues building 'groff' in one of the OS X machines (macmini3)
        set ::env(LANG) "C"
        set ::env(LC_ALL) "C"
    }
}

::itcl::class osx64XamppInstallerXStack {
    inherit osx64XamppInstallerStack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::MDB {{::xampp::MDB2}}
        replaceComponent ::xampp::HTML_Form {{::xampp::HTML_QuickForm2}}
        removeComponents [list ::xampp::pecl_radius ::xampp::XML_HTMLSax ::xampp::xdebug ::xampp::Stream_SHM]
    }
    public method componentsToBuild {} {
        if {[$be cget -buildType]=="fromTarball"} {
            return [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]
        } else {
            return [lremove [chain] [list ::xampp::xamppSkeleton ::xampp::xamppHtdocsUnix]]
        }
    }
}
::itcl::class osx64XamppInstaller74Stack {
    inherit osx64XamppInstallerXStack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::php {oniguruma {::xampp::php74}}
    }
}
::itcl::class osx64XamppInstaller80Stack {
    inherit osx64XamppInstallerXStack
    constructor {environment} {
        chain $environment
    } {
        removeComponents ::xampp::gd
        replaceComponent ::xampp::php {oniguruma {::xampp::php80} ::xampp::gd}
        replaceComponent ::xampp::xamppSkeleton ::xampp::xamppSkeletonDev
    }
    public method componentsToBuild {} {
        if {[$be cget -buildType]=="fromTarball"} {
            return [list ::xampp::xamppSkeletonDev ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]
        } else {
            return [lremove [chain] [list ::xampp::xamppSkeletonDev ::xampp::xamppHtdocsUnix nativeadapter ::xampp::manager ::xampp::phpmyadmin]]
        }
    }
}
::itcl::class osx64XamppInstaller81Stack {
    inherit osx64XamppInstaller80Stack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::php80 ::xampp::php81
    }
}
::itcl::class osx64XamppInstaller82Stack {
    inherit osx64XamppInstaller81Stack
    constructor {environment} {
        chain $environment
    } {
        replaceComponent ::xampp::php81 ::xampp::php82
    }
}
# XAMPP Installer - standard version
::itcl::class xamppinstallerstack {
    inherit product
    protected variable xampp_vcredist_name VC11
    constructor {environment} {
        set shortname xampp
        chain $environment
    } {
        set fullname XAMPP
        set name xampp
        set version [::xampp::php::getXAMPPVersion 55]
        set projectFile xampp-installer-standalone.xml
        set programming_language PHP
        lappend tags MySQL Apache PHP Tomcat
        set res {}
        foreach f {xampp-module-adapter.xml xampp-vcredist.xml xampp-common.xml xampp-server.xml xampp-tools.xml xampp-program-languages.xml xampp-phpmyadmin.xml xampp-apache.xml bitnami-xampp-shortcuts.xml xampp-sendmail.xml xampp-webalizer.xml xampp-perl.xml xampp-php.xml xampp-tomcat.xml xampp-mercury.xml xampp-mercury.xml xampp-filezilla.xml xampp-mysql.xml xampp-functions.xml} {
            lappend res [file join  [$be cget -projectDir]/apps/xampp/ $f]
        }
        lappend extraFilesList $res [$be cget -output]

        # Do not verify all components have a license (for now...)
        $be configure -verifyLicences 0
    }
    public method isBitnami {} {
        return 0
    }
    public method getNameForPlatform {} {
        return xampp
    }
    protected method shipReleaseNotes {} {
        set phpMajorVersion [join [lrange [split $version .] 0 1] ""]
        file copy -force /tmp/RELEASENOTES-$phpMajorVersion-[$be cget -target] [$be cget -output]/RELEASENOTES
    }
    public method updateReleaseNotes {} {
        set phpMajorVersion [join [lrange [split $version .] 0 1] ""]
        file copy -force [$be cget -projectDir]/apps/xampp/RELEASENOTES-$phpMajorVersion-[$be cget -target] /tmp/RELEASENOTES-$phpMajorVersion-[$be cget -target]
        puts "Updating RELEASENOTES based on the metadata"
        set componentsToList "PHP PEAR MariaDB phpMyAdmin Apache OpenSSL"
        set releaseNotesContent "This version of XAMPP contains the following software releases:"
        foreach c [getBundledComponents] {
            foreach C $componentsToList {
                if [string match $C [$c cget -fullname]] {
                    puts "[$c cget -fullname] [$c cget -version]"
                    append releaseNotesContent "\n   - [$c cget -fullname] [$c cget -version]"
                }
            }
        }

        set date [clock format [clock seconds] -format {%Y-%m-%d}]
        xampptcl::util::substituteParametersInFileRegex /tmp/RELEASENOTES-$phpMajorVersion-[$be cget -target] \
            [list {@@XAMPP_APPLICATION_VERSION@@\n+?This version of XAMPP contains the following software releases:} "@@XAMPP_APPLICATION_VERSION@@\n$releaseNotesContent" \
                 {@@XAMPP_DATE@@} $date \
                 {@@XAMPP_APPLICATION_VERSION@@} ${version}-${rev}]

    }
    public method copyProjectFiles {} {
        chain
        $be configure -setvars "[$be cget -setvars] xampp_vcredist_name=${xampp_vcredist_name}"
        lappend setvars "project.installerFilename=[${this} getInstallerName]"
        foreach f {apache/apache-functions.xml mysql/mysql-functions.xml php/php-functions.xml} {
            file copy -force [$be cget -projectDir]/base/$f [$be cget -output]
        }
        foreach f {native-mysql-adapter.xml native-apache-adapter.xml environment-autodetection-functions.xml mysql-autodetection-functions.xml apache-autodetection-functions.xml php-autodetection-functions.xml} {
            file copy -force [$be cget -projectDir]/apps/nativeadapter/$f [$be cget -output]
        }
        updateReleaseNotes
        shipReleaseNotes
    }
    public method copyStackTxt {} {}
    public method getBaseNameForPlatform {} {
        return XamppInstallerStack
    }
    public method preparefordist {} {
        foreach f [glob [file join [$be cget -output] xampp php icu*.dll]] {
            file copy -force $f [file join [$be cget -output] xampp apache bin]
        }
        if {[$be cget -target] == "windows"} {
            $be configure -setvars "[$be cget -setvars] bitnamisettings_windowsxp_support=0"
            file copy -force [$be cget -output]/RELEASENOTES [file join [$be cget -output] "xampp"]
        }
    }

    public method supportedPlatforms {} {
        return {windows-x64}
    }
}

::itcl::class xamppinstaller74stack {
    inherit xamppinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set application ::xampp::php74
        set xampp_vcredist_name VC15
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppInstallerPhp74Stack
    }
}
::itcl::class xamppinstaller80stack {
    inherit xamppinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set application ::xampp::php80
        set xampp_vcredist_name VS16
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppInstallerPhp80Stack
    }
}
::itcl::class xamppinstaller82stack {
    inherit xamppinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
        set application ::xampp::php82
        set xampp_vcredist_name VS16
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppInstallerPhp82Stack
    }
}
::itcl::class xamppinstaller81stack {
    inherit xamppinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set application ::xampp::php81
        set xampp_vcredist_name VS16
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppInstallerPhp81Stack
    }
}

# XAMPP Unix Installer
# Windows and Unix platforms are too different. It is better to have a different class
::itcl::class xamppunixinstallerXstack {
    inherit xamppinstallerstack
    markAsInternal
    constructor {environment} {
        chain $environment
        set supportedHosts {osx-x64-10-10-chroot-3 osx-x64-10-10-chroot-4 osx-x64-10-10-chroot-5 osx-x64-10-10-chroot-6}
    } {
        set extraFilesList {}
        set deleteRPath 0
        set projectFile xampp-unix-installer-standalone.xml
        set programming_language PHP
        lappend tags MySQL Apache PHP Tomcat
        set res {}
        foreach f {xampp-common.xml xampp-server.xml xampp-module-adapter.xml xampp-tools.xml xampp-program-languages.xml xampp-phpmyadmin.xml xampp-apache.xml bitnami-xampp-shortcuts.xml xampp-sendmail.xml xampp-webalizer.xml xampp-perl.xml xampp-php.xml xampp-tomcat.xml xampp-mercury.xml xampp-mercury.xml xampp-filezilla.xml xampp-mysql.xml} {
            lappend res [file join  [$be cget -projectDir]/apps/xampp/ $f]
        }
        lappend extraFilesList $res [$be cget -output]
        # Do not verify all components have a license (for now...)
        $be configure -verifyLicences 0
        set requiredMemory 1024
    }
    public method copyStackTxt {} {}
    public method deleteRPathFromBinaries {} {}
    public method getBundledComponents {} {
        return [lsort -unique [getComponents]]
    }
    public method getStackInstallerName {} {
        if {[$be cget -target] == "linux"} {
            puts "xampp-linux-${version}-${rev}-installer.run"
        } elseif {[$be cget -target] == "linux-x64"} {
	        puts "xampp-linux-x64-${version}-${rev}-installer.run"
        } else {
            chain
        }
    }
    public method preparefordist {} {
        if {[string match linux* [$be cget -target]]} {
            set destDir [file join [$be cget -output] lampp]
            foreach f [glob [file join [$be cget -output] "lampp" postgresql lib libpq.so*]] {
                file copy -force $f [file join [$be cget -output] "lampp" lib]
            }
        } else {
            set destDir [file join [$be cget -output] xamppfiles]
            foreach f [glob [file join [$be cget -output] "xamppfiles" postgresql lib libpq.*]] {
                file copy -force $f [file join [$be cget -output] "xamppfiles" lib]
            }
        }
        if {[$be targetPlatform] == "osx-x64"} {
            set xamppoutputdir [file join [$be cget -output] xamppfiles]
        } else {
            set xamppoutputdir [file join [$be cget -output] lampp]
        }
        foreach f [glob [file join [$be cget -output] htdocs-xampp *]] {
            file copy -force $f [file join $xamppoutputdir htdocs]
        }
        foreach f [glob -directory [file join $destDir htdocs] *.html */*.html */*/*.html */*/*/*.html */*/*/*/*.html */*/*/*/*/*.html] {
            xampptcl::util::substituteParametersInFile $f [list {@@XAMPP_VERSION@@} $version]
        }

        xampptcl::util::substituteParametersInFile $xamppoutputdir/etc/extra/httpd-xampp.conf [list "php5" "php7" "PHP5" "PHP7"]

        # Some applications require higher limits, such as WordPress for uploading big images
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/etc/php.ini [list \
            {\nmax_execution_time = [^\n]+} "\nmax_execution_time = 120" \
            {\nmemory_limit = [^\n]+} "\nmemory_limit = 512M" \
            {\npost_max_size = [^\n]+} "\npost_max_size = 40M" \
            {\nupload_max_filesize = [^\n]+} "\nupload_max_filesize = 40M" \
        ] 1
    }
    public method supportedPlatforms {} {
        return [concat linux-x64 osx-x64]
    }
    public method copyProjectFiles {} {
        chain
        foreach f {native-proftpd-adapter.xml native-mysql-adapter.xml native-apache-adapter.xml environment-autodetection-functions.xml} {
            file copy -force [$be cget -projectDir]/apps/nativeadapter/$f [$be cget -output]
        }
        foreach f {bitnami/base-functions.xml apache/apache-bitnami.xml apache/apache-functions.xml mysql/mysql-functions.xml php/php-functions.xml bitnami/bitnami-functions.xml} {
            file delete -force [file join [$be cget -output] [file tail $f]]
            file copy -force [$be cget -projectDir]/base/$f [$be cget -output]
        }
    }
    public method deleteCompilationFiles {} {
        if {$deleteCompilationFiles && [$be targetPlatform] != "aix" && [$be targetPlatform] != "windows"} {
            foreach f [glob -nocomplain -dir [$be cget -output] *] {
                if ![string match *ImageMagick* $f] {
                    ::xampptcl::util::deleteFilesAccordingToPattern $f *.o
                }
            }
        }
        if {[$be targetPlatform] != "osx-x64"} {
            set saveLdLibraryPath {}
            if {[info exists ::env(LD_LIBRARY_PATH)]} {
                set saveLdLibraryPath $::env(LD_LIBRARY_PATH)
                unset ::env(LD_LIBRARY_PATH)
            }
            foreach {dir pattern} [list {} *.so bin * sbin *] {
                foreach f [split [exec find [file join [$be cget -output] $dir] -name $pattern] \n] {
                    if {[isBinaryFile $f] && ![string match *fonts* $f]} {
                        message info "Stripping $f"
                        catch {exec strip $f}
                    }
                }
            }
            set ::env(LD_LIBRARY_PATH) $saveLdLibraryPath
        }
    }
    public method packCompressedFile {} {
        $be setupEnvironment
        $be setupDirectories
        createStack
        switch -glob [$be cget -target] {
            linux* {
                set relativeTopDir "lampp"
                set installPrefix "lampp"
                set destDir [$be cget -output]
                set virginSrc [file join [$be cget -output] "lampp"]
            }
            osx-x64 {
                set relativeTopDir "XAMPP"
                set destDir [file join [$be cget -output] XAMPP]
                set installPrefix "XAMPP/xamppfiles"
                set virginSrc [file join [$be cget -output] XAMPP xamppfiles]
            }
        }
        extractBaseTarball $destDir
        xampptcl::file::write [file join $virginSrc lib VERSION] $version
        file delete -force  [file join [$be cget -output] developer-addon $installPrefix]
        file mkdir [file join [$be cget -output] developer-addon $installPrefix]
        foreach dir {build include man docs manual info share/doc share/man share/openssl/man} {
            set dest [file join [$be cget -output] developer-addon $installPrefix $dir]
            file delete -force $dest
            file mkdir [file dirname $dest]
            file rename -force [file join $virginSrc $dir] [file dirname $dest]
        }
        foreach f [glob [file join $virginSrc postgresql lib libpq.*]] {
            file copy -force [file join $virginSrc lib]
        }
        file delete -force [file join $virginSrc postgresql]
        foreach dir {lib modules} {
            foreach f [xampptcl::util::recursiveGlob [file join $virginSrc $dir] *.a *.la] {
                set tail [string trimleft [string map [list $virginSrc {}] $f] /]
                set destFile [file join [$be cget -output] developer-addon $installPrefix $tail]
                file mkdir [file dirname $destFile]
                file delete -force $destFile
                file rename -force $f $destFile
            }
        }
        set releaseTgzName xampp-[$be cget -target]-$version.tar.gz
        set developerTgzName xampp-[$be cget -target]-${version}-dev.tar.gz
        cd [$be cget -output]
        logexec tar -czf $releaseTgzName $relativeTopDir
        message info "Created [file join [$be cget -output] $releaseTgzName]"
        cd [file join [$be cget -output] developer-addon]
        logexec tar -czf $developerTgzName $relativeTopDir
        file rename -force $developerTgzName [$be cget -output]
        message info "Created [file join [$be cget -output] $developerTgzName]"
    }
    public method compressTarball {} {
        if {[$be cget -target] != "windows"} {
            cd [file dirname [$be cget -output]]
            set timeStamp [clock format [clock seconds] -format %Y%m%d]
            set tarballNameRoot [$stack cget -baseTarball]
            set newTarballName [regsub -- {-\d*$} $tarballNameRoot {}]-$timeStamp
            logexec tar cf [file join [$be cget -tmpDir] $newTarballName].tar [file tail [$be cget -output]]
            file delete -force [file join [$be cget -tmpDir] $newTarballName].tar.gz
            logexec gzip [file join [$be cget -tmpDir] $newTarballName].tar
            if {[$be cget -baseTarballOutputDir] != ""} {
                set d [$be cget -baseTarballOutputDir]
            } else {
                set d [$be cget -output]
            }
            if {![file exists $d]} {
                file mkdir $d
            }
            file rename -force [file join [$be cget -tmpDir] $newTarballName].tar.gz $d
        } else {
            chain
        }
    }
}

::itcl::class xamppunixinstaller74stack {
    inherit xamppunixinstallerXstack
    constructor {environment} {
        chain $environment
    } {
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set application ::xampp::php74
    }
    public method getBaseNameForPlatform {} {
        return XamppInstaller74Stack
    }
    public method preparefordist {} {
        chain
        if {[$be targetPlatform] == "osx-x64"} {
            xampptcl::util::substituteParametersInFile [$be cget -output]/xamppfiles/etc/extra/httpd-xampp.conf [list "php5" "php7" "PHP5" "PHP7"]
        } else {
            xampptcl::util::substituteParametersInFile [$be cget -output]/lampp/etc/extra/httpd-xampp.conf [list "php5" "php7" "PHP5" "PHP7"]
        }
    }
    public method confFileName {} {
        return xamppinstallerphp74
    }
}

::itcl::class xamppunixinstaller80stack {
    inherit xamppunixinstallerXstack
    constructor {environment} {
        chain $environment
    } {
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set application ::xampp::php80
    }
    public method getBaseNameForPlatform {} {
        return XamppInstaller80Stack
    }
    public method confFileName {} {
        return xamppinstallerphp80
    }
}
::itcl::class xamppunixinstaller81stack {
    inherit xamppunixinstallerXstack
    constructor {environment} {
        chain $environment
    } {
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set application ::xampp::php81
    }
    public method getBaseNameForPlatform {} {
        return XamppInstaller81Stack
    }
    public method confFileName {} {
        return xamppinstallerphp81
    }
}
::itcl::class xamppunixinstaller82stack {
    inherit xamppunixinstallerXstack
    constructor {environment} {
        chain $environment
    } {
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
        set application ::xampp::php82
    }
    public method getBaseNameForPlatform {} {
        return XamppInstaller82Stack
    }
    public method confFileName {} {
        return xamppinstallerphp82
    }
}
# XAMPP Installer - portable lite version
::itcl::class xamppportableinstallerstack {
    inherit product
    protected variable xampp_vcredist_name VC11
    constructor {environment} {
        set shortname xampp
        chain $environment
    } {
        $targetInstance configure -kind portable
        set fullname "XAMPP Portable Lite"
        set name xampp
        set version [::xampp::php::getXAMPPVersion 55]
        set rev [::xampp::php::getXAMPPRevision 55]
        set projectFile xampp-installer-portable-standalone.xml
        set programming_language PHP
        lappend tags MySQL Apache PHP Tomcat
        set res {}
        foreach f {xampp-vcredist.xml xampp-common.xml xampp-server.xml xampp-tools.xml xampp-program-languages.xml xampp-phpmyadmin.xml xampp-apache.xml bitnami-xampp-shortcuts.xml xampp-sendmail.xml xampp-webalizer.xml xampp-perl.xml xampp-php.xml xampp-tomcat.xml xampp-mercury.xml xampp-mercury.xml xampp-filezilla.xml xampp-mysql.xml xampp-functions.xml} {
            lappend res [file join  [$be cget -projectDir]/apps/xampp/ $f]
        }
        lappend extraFilesList $res [$be cget -output]

        # Do not verify all components have a license (for now...)
        $be configure -verifyLicences 0
    }
    public method isBitnami {} {
        return 0
    }
    public method getNameForPlatform {} {
        return xampp
    }
    public method copyProjectFiles {} {
        chain
        $be configure -setvars "[$be cget -setvars] xampp_vcredist_name=${xampp_vcredist_name}"
        lappend setvars "project.installerFilename=[${this} getInstallerName]"
        foreach f {apache/apache-functions.xml mysql/mysql-functions.xml php/php-functions.xml} {
            file copy -force [$be cget -projectDir]/base/$f [$be cget -output]
        }
    }
    public method copyStackTxt {} {}
    public method getBaseNameForPlatform {} {
        return XamppPortableInstallerStack
    }
    public method preparefordist {} {
        $be configure -setvars "[$be cget -setvars] component(bitnamisettings).parameter(bitnamisettings_windowsxp_support).value=0"
    }
    public method supportedPlatforms {} {
        return {windows-x64}
    }
    public method getStackInstallerName {} {
        set installerName "xampp-portable-windows-x64-${version}-${rev}-${xampp_vcredist_name}-installer.exe"

        puts ${installerName}
        return ${installerName}
    }
}
::itcl::class xamppportableinstaller74stack {
    inherit xamppportableinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set application ::xampp::php74
        set xampp_vcredist_name VC15
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppPortableInstallerPhp74Stack
    }
    public method confFileName {} {
        return xamppinstallerphp74
    }
}
::itcl::class xamppportableinstaller80stack {
    inherit xamppportableinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set application ::xampp::php80
        set xampp_vcredist_name VS16
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppPortableInstallerPhp80Stack
    }
    public method confFileName {} {
        return xamppinstallerphp80
    }
}
::itcl::class xamppportableinstaller81stack {
    inherit xamppportableinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set application ::xampp::php81
        set xampp_vcredist_name VS16
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppPortableInstallerPhp81Stack
    }
    public method confFileName {} {
        return xamppinstallerphp81
    }
}
::itcl::class xamppportableinstaller82stack {
    inherit xamppportableinstallerstack
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
        set application ::xampp::php82
        set xampp_vcredist_name VS16
    } {
    }
    public method getBaseNameForPlatform {} {
        return XamppPortableInstallerPhp82Stack
    }
    public method confFileName {} {
        return xamppinstallerphp82
    }
}
::itcl::class xampp {
    inherit phpBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name xampp
        set version 1.8.1
        set licenseRelativePath {}
        set tarballName xampp-win32-${version}-VC11.zip
    }
    public method getTextFiles {} {}
    public method getProgramFiles {} {
        return [lremove [chain] [list scripts conf]]
    }
    public method srcdir {} {
        return [file join [$be cget -src] xampp]
    }
    public method install {} {
        file copy -force [srcdir] [$be cget -output]
    }
}

::itcl::class xamppFiles {
    inherit xampp
    constructor {environment} {
        chain $environment
    } {}
    public method needsToBeBuilt {} {
        return 0
    }
    public method extract {} {}
    public method build {} {}
    public method install {} {}
}


::itcl::class xamppstackman {
    public variable stackmanVersion {}
    constructor {environment} {
        chain $environment
        set stackmanVersion preview-1
    } {}
    public method fullVersion {} {
        set res [$this cget -version]-[$this cget -rev]-$stackmanVersion
        puts $res
        return $res
    }
    public method getFullProductFileName {} {
        return [file rootname [getStackInstallerName]].dmg
    }
    public method getStackInstallerName {} {
        set res xampp-osx-[$this cget -version]-[$this cget -rev]-vm.app
        puts $res
        return $res
    }
    public method supportedPlatforms {} {
        return {osx-x64}
    }
}

::itcl::class xamppstackman74stack {
    inherit xamppstackman xamppunixinstaller74stack
    constructor {environment} {
        chain $environment
    } {}
}
::itcl::class xamppstackman80stack {
    inherit xamppstackman xamppunixinstaller80stack
    constructor {environment} {
        chain $environment
    } {}
}
::itcl::class xamppstackman81stack {
    inherit xamppstackman xamppunixinstaller81stack
    constructor {environment} {
        chain $environment
    } {}
}
