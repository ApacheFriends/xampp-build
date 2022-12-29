proc pearProgram {name args} {
    array set options [list name $name version 1.0 licenseRelativePath {}]
    foreach {k v} $args {
	if {![string match -* $k]} {
	    error "Invalid pearprogram declaration 'pearProgram $name $args'. Expected a flag but got $k "
	}
	set k [string trimleft $k -]
	set options($k) $v
    }
    set variableDefinitionText {}
    foreach {name value} [array get options] {
	append variableDefinitionText [format {
            set %s "%s"} $name $value]
    }

    set definition [format {
        ::itcl::class %s {
            inherit pearprogram
            constructor {environment} {
                chain $environment
            } {
		%s
		if {$channel != ""} {
		    lappend additionalFileList $channel.reg
		}
            }
            public method getUniqueIdentifier {} {
                return pear_[chain]
            }
        }
    } $options(name) $variableDefinitionText]
    uplevel $definition
}

::itcl::class phpBitnamiProgram {
    inherit bitnamiProgram
    constructor {environment} {
       chain $environment
    } {
        set requiredMemory 512
        set supportsVhost 1
        set supportsBanner 0
        set supportsAppurl 1
    }
    public method build {} {
    }
    public method install {} {
        file mkdir [applicationOutputDir]
        file delete -force [applicationOutputDir]/htdocs
        file copy -force [srcdir] [applicationOutputDir]/htdocs
        addPluginsToApplication
        if $createHtaccessFile {
            createHtaccessFile
        }
        chain
    }
    public method copyStackLogoImage {} {
        if {![file exists [file join [$be cget -output] apache2 htdocs img]]} {
            file mkdir [file join [$be cget -output] apache2 htdocs img]
        }
        file copy -force [getStackLogoImage] [file join [$be cget -output] apache2 htdocs img]
    }
    public method getProgramFiles {} {
        return [lremove [chain] conf]
    }
    public method removeDocs {} {}
 }

::itcl::class phpWindowsX64 {
    inherit php
    public variable includePear
    public variable tool_php_directory

    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "PHP" 74]
        set tarballName php-${version}-Win32-VC14-x64
        set ::opts(php.version) $version
        set licenseRelativePath license.txt
        set includePear 1
        lappend additionalFileList vcredist_x64_2008.exe vcredist_x64_2012.exe vcredist_x64_2015.exe vcredist_x64_2017.exe vcredist_x64_2019.exe lamp56.tar.gz php/php5apache2_4.dll composer-$composerVersion.phar composer-license.txt windowstools/vcredist/msvcr110.dll windowstools/vcredist/msvcp110.dll
    }
    public method extractDirectory {} {
        if { [string match *Win32-VC6-x* $tarballName] || [string match *Win32-VC9-x* $tarballName] || [string match *Win32-VC1\[145\]-x* $tarballName] || [string match *Win32-VS1\[6\]-x* $tarballName]} {
            return [srcdir]
        } else {
            return [$be cget -src]
        }
    }
    public method extract {} {
      if { ![file exists [extractDirectory]] } {
          file mkdir [extractDirectory]
      }
      chain
    }
    public method setEnvironment {} {
        chain
        set ::opts(php.version) $version
        set ::opts(php.prefix) [prefix]
    }
    protected method copyVCRedist {} {
        if {[string match *Win32-VC9-x64* $tarballName]} {
            file copy -force [$be cget -tarballs]/windowstools/vcredist/vcredist_x64_2008.exe [prefix]
        } elseif {[string match *Win32-VC11-x64* $tarballName]} {
            file copy -force [$be cget -tarballs]/windowstools/vcredist/vcredist_x64_2012.exe [prefix]
        } elseif {[string match *Win32-VC14-x64* $tarballName]} {
            file copy -force [$be cget -tarballs]/windowstools/vcredist/vcredist_x64_2015.exe [prefix]
        } elseif {[string match *Win32-VC15-x64* $tarballName]} {
            file copy -force [$be cget -tarballs]/windowstools/vcredist/vcredist_x64_2017.exe [prefix]
        } elseif {[string match *Win32-VS16-x64* $tarballName]} {
            file copy -force [$be cget -tarballs]/windowstools/vcredist/vcredist_x64_2019.exe [prefix]
        }
    }
    public method install {} {
        set ::opts(php.prefix) [prefix]
        file delete -force [prefix]
        file copy -force [srcdir] [prefix]
        copyVCRedist

        #Install PEAR
        if { $includePear == 1 } {
            buildProgram pearWindows $be

            # configuring Linux PHP.
            # We use an installed lampstack for linux-x64 in /bitnami/lamp56. To get it, we would only need to install the stack at that path,
            # stop the services and pack it.
            # Once we have the stack there, we'll need to modify the pear.conf file and point to the target folder of Windows.
            set php_linux_parent_dir [file join /bitnami lamp56]
            if {![file exists $php_linux_parent_dir]} {
                file mkdir $php_linux_parent_dir
                logexec tar xzf [file join [$be cget -tarballs] lamp lamp56.tar.gz] -C $php_linux_parent_dir
            }
            set tool_php_directory $php_linux_parent_dir/php

            # getting fixreg.php
            file mkdir [file join [prefix] bin]
            file copy -force [$be cget -tarballs]/lamp/fixreg.php [file join [prefix] bin]
            if { $version >= "5.3" } {
                xampptcl::util::substituteParametersInFile [file join [prefix] bin fixreg.php] \
                  [list {set_magic_quotes_runtime(0);} {ini_set("magic_quotes_runtime", 0);}]
            }

            # Configure PEAR to use the directories where the tarball is being built
            file copy -force [file join [$be cget -projectDir] base php pear.conf] $tool_php_directory/etc/
            logexecIgnoreErrors $tool_php_directory/bin/php -q [prefix]/bin/fixreg.php $tool_php_directory/etc @@XAMPP_PHP_DIR@@ [prefix]
            logexecIgnoreErrors $tool_php_directory/bin/php -q [prefix]/bin/fixreg.php $tool_php_directory/etc @@XAMPP_PEAR_DIR@@ [prefix]/PEAR
        }
        if { [file exists [file join [prefix] php.ini-recommended]] } {
            file copy -force [file join [prefix] php.ini-recommended] [file join [prefix] php.ini]
        } elseif {[file exists [file join [srcdir] php.ini-production]]} {
            # PHP 5.3 ships two default php.ini files: php.ini-production and php.ini-development
            file copy [file join [srcdir] php.ini-production] [file join [prefix] php.ini]
        }
        if { [string match {5.4*} $version] } {
            file copy -force [findFile [file join php php5apache2_4.dll]] [file join [$be cget -output] php]
        }
        file delete -force [prefix]/.buildcomplete
    }
    public method build {} {}
    public method preparefordist {} {
        set ::opts(php.prefix) [prefix]
        chain
        if { $includePear == 1 } {

        # pear extensions tgz files are no longer needed at install time
        set fileList {
        docs
        download
        temp
        tests
        scripts
        }
        foreach {f} $fileList {
            file delete -force [file join [prefix] PEAR $f]
        }
        }

        # substitute hardcoded paths for @@
        set fileList {
            . peardev
            . pecl
            . pear
            PEAR peclcmd.php
            PEAR pearcmd.php
        }
        foreach {d f} $fileList {
            if {[file exists [file join [prefix] $d $f]]} {
                xampptcl::util::substituteParametersInFile [file join [prefix] $d $f] \
                    [list $::opts(php.prefix) @@XAMPP_PHP_ROOTDIR@@ \
                    $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@\
                    [file join bitnami php bin php] @@XAMPP_PHP_ROOTDIR@@/php/php.exe]
            }
        }

        # avoid duplicated names on Windows (pear and PEAR)
        file delete -force [prefix]/pear

        xampptcl::util::substituteParametersInFile [file join [prefix] php.ini] {{mysql.default_port =} {mysql.default_port = @@XAMPP_MYSQL_PORT@@} {;date.timezone =} {date.timezone = "UTC"}}

        # use UTF-8 charset by default
        xampptcl::util::substituteParametersInFile [file join [prefix] php.ini] {{;default_charset = "UTF-8"} {default_charset = "UTF-8"}}

        # substitute paths on registry files
        logexecIgnoreErrors [file join $tool_php_directory bin php] -q [file join $tool_php_directory bin fixreg.php] [file join [prefix] PEAR .registry] [prefix] @@XAMPP_PHP_ROOT@@
        logexecIgnoreErrors [file join $tool_php_directory bin php] -q [file join $tool_php_directory bin fixreg.php] [file join [prefix] PEAR .registry] $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@
        foreach f [glob -nocomplain [prefix]/PEAR/.registry/.channel*] {
            logexecIgnoreErrors [file join $tool_php_directory bin php] -q [file join $tool_php_directory bin fixreg.php] $f [prefix] @@XAMPP_PHP_ROOT@@
            logexecIgnoreErrors [file join $tool_php_directory bin php] -q [file join $tool_php_directory bin fixreg.php] $f $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@
        }
        logexecIgnoreErrors [file join $tool_php_directory bin php] -q [file join $tool_php_directory bin fixreg.php] [file join [prefix] etc] [prefix] @@XAMPP_PHP_ROOT@@

        xampptcl::util::substituteParametersInFile [file join [prefix] php.ini] {{extension_dir = "./"} {extension_dir = "@@XAMPP_PHP_ROOTDIR@@/ext"}}
        # PHP 5.3
        xampptcl::util::substituteParametersInFile [file join [prefix] php.ini] \
            [list {; extension_dir = "@@XAMPP_PHP_ROOTDIR@@/ext"} {extension_dir = "@@XAMPP_PHP_ROOTDIR@@/ext"} \
                 {;extension_dir = "@@XAMPP_PHP_ROOTDIR@@/ext"} {extension_dir = "@@XAMPP_PHP_ROOTDIR@@/ext"} \
                 {;\s*include_path\s*=\s*".;c:\php\includes"} {include_path = ".;@@XAMPP_PHP_ROOTDIR@@/PEAR"}]
        # Composer
        file copy -force [findFile composer-$composerVersion.phar] [file join [prefix] composer.phar]
        file copy -force [findFile composer-license.txt] [file join [$be cget -licensesDirectory] composer.txt]
        # Curl certificate file
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        file copy -force [findFile curl-ca-bundle-${cacertificatesVersion}.crt] [file join [$be cget -output] php curl-ca-bundle.crt]
    }
}

::itcl::class php7WindowsX64 {
    inherit phpWindowsX64
    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "PHP" 74]
        set tarballName php-${version}-Win32-VC14-x64
        set includePear 1
    }
}

::itcl::class php80WindowsX64 {
    inherit phpWindowsX64
    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "PHP" 80]
        set tarballName php-${version}-Win32-VS16-x64
        set includePear 1
    }
}

::itcl::class php81WindowsX64 {
    inherit phpWindowsX64
    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "PHP" 81]
        set tarballName php-${version}-Win32-VS16-x64
        set includePear 1
    }
}

::itcl::class php82WindowsX64 {
    inherit phpWindowsX64
    constructor {environment} {
        chain $environment
    } {
        set version [versions::get "PHP" 82]
        set tarballName php-${version}-Win32-VS16-x64
        set includePear 1
    }
}

::itcl::class Archive_Tar {
    inherit pearprogram

    constructor {environment} {
        chain $environment
    } {
        set name Archive_Tar
        set version 1.4.11
        set licenseRelativePath {}
    }

    public method install {} {
        file delete -force $::opts(pear.prefix)/Archive
        file copy -force [srcdir]/Archive $::opts(pear.prefix)
    }
}

::itcl::class Console_Getopt {
    inherit pearprogram

    constructor {environment} {
        chain $environment
    } {
        set name Console_Getopt
        set version 1.3.1
        set licenseRelativePath {}
    }

    public method install {} {
        file delete -force $::opts(pear.prefix)/Console
        file copy -force [srcdir]/Console $::opts(pear.prefix)
    }
}

::itcl::class Structures_Graph {
    inherit pearprogram

    constructor {environment} {
        chain $environment
    } {
        set name Structures_Graph
        set version 1.0.4
        set licenseRelativePath {}
    }

    public method install {} {
        file delete -force $::opts(pear.prefix)/Structures
        file copy -force [srcdir]/Structures $::opts(pear.prefix)
        file copy -force [srcdir]/LICENSE $::opts(pear.prefix)/Structures
    }
}

::itcl::class phpAWSSDK {
    inherit pearprogram

    constructor {environment} {
        chain $environment
    } {
        set name sdk
        set uniqueIdentifier aws-php-sdk
        set version 1.6.2
	set readmePlaceholder AWSSDKPHP
        set licenseRelativePath README.md
        set licenseNotes {Apache 2.0: http://aws.amazon.com/apache2.0}
        lappend additionalFileList pear/pear.amazonwebservices.com.reg
    }

    public method install {} {
	# Avoid to connect internet during the installation
	#logexec $::opts(php.prefix)/bin/pear channel-discover pear.amazonwebservices.com
	file copy [findFile pear.amazonwebservices.com.reg] [file join $::opts(php.prefix)/lib/php/.channels]
        chain
    }
}

::itcl::class phpAWSSDKWindows {
    inherit pearprogramWindows

    constructor {environment} {
        chain $environment
    } {
        set name sdk
        set uniqueIdentifier aws-php-sdk
        set version 1.5.13
	set readmePlaceholder AWSSDKPHP
	set licenseRelativePath README.md
    }

    public method install {} {
        eval exec [join [list $::opts(pear.command) channel-discover pear.amazonwebservices.com]]
        chain
    }
}
::itcl::class pearWindows {
    inherit program
    public variable dependencies
    constructor {environment} {
        chain $environment
    } {
	set name PEAR
	set version 1.10.1
	set tarballName PEAR-$version
	set licenseRelativePath LICENSE
	set dependencies [list Archive_Tar Console_Getopt Structures_Graph]
    }
    public method prefix {} {
	return $::opts(php.prefix)/PEAR
    }

    public method build {} {
    }

    public method setEnvironment {} {
	set ::opts(pear.prefix) [prefix]
    }

    public method install {} {
	if ![file exists [prefix]] {
	    file mkdir [prefix]
	}
	foreach file {OS PEAR PEAR.php PEAR5.php System.php} {
	    if [file exists [srcdir]/$file] {
		file delete -force [prefix]/$file
		file copy -force [srcdir]/$file [prefix]
	    }
	}
	file mkdir [prefix]/data/PEAR
	file copy -force [srcdir]/template.spec [prefix]/data/PEAR
	file copy -force [srcdir]/package.dtd [prefix]/data/PEAR
	file copy -force [srcdir]/scripts/pear.bat [prefix]/../
	file copy -force [srcdir]/scripts/pecl.bat [prefix]/../
	file copy -force [srcdir]/scripts/pearcmd.php [prefix]
	file copy -force [srcdir]/scripts/peclcmd.php [prefix]

	#Install required dependencies
	foreach dep $dependencies {
	    buildProgram $dep $be
	}
       file delete -force [prefix]/.buildcomplete
    }
}

::itcl::class php_perl {
    inherit program

    constructor {environment} {
        chain $environment
    } {
        set name perl
        set version 1.0.0
        set licenseRelativePath {}
        lappend additionalFileList pecl/php_perl_patch_for_5.3.c
    }

    public method configureOptions {} {
        return [list --with-perl=$::opts(perl.prefix) --with-php-config=$::opts(php.prefix)/bin/php-config]
    }

    public method setEnvironment {} {
        set ::env(PHP_PREFIX) $::opts(php.prefix)
        set ::env(PERL_PREFIX) $::opts(perl.prefix)
    }

    public method build {} {
        cd [srcdir]
        file copy -force [findFile pecl/php_perl_patch_for_5.3.c] [srcdir]/php_perl.c
        xampptcl::util::substituteParametersInFile [srcdir]/php_perl.c \
            [list {PHP_PERL_VERSION} {"$Extension version: 1.0.1 $"} {"$Revision: 1.91 $"} {"$Revision: 1.91 $"}]
        logexec $::opts(php.prefix)/bin/phpize
        xampptcl::util::substituteParametersInFile [srcdir]/configure {
            {echo "configure: error: installation or configuration problem: C++ compiler cannot create executables." 1>&2; exit 1;}
            {echo "configure: error: installation or configuration problem: C++ compiler cannot create executables." 1>&2; }
        }
        chain
    }
    public method preparefordist {} {
        set phpini [file join $::opts(php.prefix) etc php.ini]
        xampptcl::file::append $phpini {extension=perl.so
}
    }
}

::itcl::class pecl_extension {
    inherit program

    constructor {environment} {
        chain $environment
    } {
        set name pecl_extension
        set folderAtThirdparty [$be cget -tarballs]/php
        set mainComponentXMLName php
        set isReportableAsMainComponent 0
    }
    public method getUniqueIdentifier {} {
        return pecl_[chain]
    }

    public method configureOptions {} {
	return [list --with-php-config=$::opts(php.prefix)/bin/php-config]
    }
    public method build {} {
	cd [srcdir]
	logexec $::opts(php.prefix)/bin/phpize
	chain
    }
    public method preparefordist {} {
        set phpini [file join $::opts(php.prefix) etc php.ini]
        xampptcl::file::append $phpini ";extension=$name.so\n"
    }
}

::itcl::class pecl_extensionWindows {
    inherit program

    constructor {environment} {
        chain $environment
    } {
        set name pecl_extension
        set mainComponentXMLName php
        set isReportableAsMainComponent 0
    }
    public method needsToBeBuilt {} {
        return 1
    }
    public method extractDirectory {} {
	return [file join [$be cget -src] pecl]
    }
    public method srcdir {} {
	return [file join [$be cget -src] pecl]
    }
    public method configureOptions {} {}
    public method build {} {}
    public method install {} {
        cd [srcdir]
        file copy -force php_$name.dll [file join [$be cget -output] php ext]
    }
    public method preparefordist {} {
        set phpini [file join $::opts(php.prefix) php.ini]
        xampptcl::file::append $phpini ";extension=php_$name.dll\n"
    }
}
::itcl::class pecl_imagick {
    inherit pecl_extension
    constructor {environment} {
        chain $environment
    } {
        set name imagick
        set version 3.5.0
        set licenseRelativePath {}
        set licenseNotes "PHP License http://pecl.php.net/package/imagick"
    }
    public method build {} {
        if {[info exists ::env(PKG_CONFIG_PATH)]} {
             set ::env(PKG_CONFIG_PATH) "$::opts(imagemagick.prefix)/lib/pkgconfig:$::env(PKG_CONFIG_PATH)"
        } else {
             set ::env(PKG_CONFIG_PATH) "$::opts(imagemagick.prefix)/lib/pkgconfig"
        }
        set cflags $::env(CFLAGS)
        set ::env(CFLAGS) "$cflags -I$::opts(imagemagick.prefix)/include:-I$::opts(imagemagick.prefix)/include/ImageMagick-6"
        cd [srcdir]
        logexec $::opts(php.prefix)/bin/phpize
        showEnvironmentVars
        set f [file join [srcdir] configure]
        xampptcl::util::substituteParametersInFile $f [list "/include/ImageMagick/wand/MagickWand.h" "/include/ImageMagick-6/wand/MagickWand.h" ] 1
        callConfigure
		# it is valid for osx-x64 and linux-x64
		set f [file join [srcdir] Makefile]
		xampptcl::util::substituteParametersInFile $f [list "INCLUDES =" "INCLUDES = -I$::opts(imagemagick.prefix)/include/ImageMagick-6" ] 1
        #the -6.Q16 is for the new naming in latest imagemagick versions
        xampptcl::util::substituteParametersInFile [file join [srcdir] Makefile] [list {LDFLAGS = } "LDFLAGS = -L$::opts(imagemagick.prefix)/lib -lMagickWand-6.Q16 "]
        set ::env(CFLAGS) $cflags
    }
    public method configureOptions {} {
        set list [chain]
        lappend list --with-imagick=$::opts(imagemagick.prefix)
        return $list
    }
}

::itcl::class xdebug {
    inherit program
    constructor environment {
        chain $environment
    } {
        set name xdebug
        set version 3.1.2
        set supportsParallelBuild 0
        set licenseRelativePath LICENSE
        set licenseNotes "PHP-based license http://xdebug.org/license.php"
        set mainComponentXMLName php
        set isReportableAsMainComponent 0
    }
    public method build {} {
        cd [srcdir]
        logexec $::opts(php.prefix)/bin/phpize
        chain
    }
    protected method configureOptions {} {
        return [list --enable-xdebug --with-php-config=$::opts(php.prefix)/bin/php-config]
    }
    public method preparefordist {} {
        xampptcl::file::append [file join $::opts(php.prefix) etc php.ini] {
;[XDebug]
;; Only Zend OR (!) XDebug
;zend_extension="@@XAMPP_PHP_ROOTDIR@@/lib/php/extensions/xdebug.so"
;xdebug.mode=debug
;xdebug.client_host=127.0.0.1
;xdebug.client_port=9000
;xdebug.output_dir=/tmp
;xdebug.remote_handler=dbgp
}
    }
}


::itcl::class intlOsx {
    inherit program
    #This isn't a real component, it uses the code of PHP
    markAsInternal
    constructor {enviroment} {
        chain $enviroment
    } {
        set name intl
        set version 1.0.0
        set licenseRelativePath {}
    }
    public method needsToBeBuilt {} {
        return 0
    }
    public method srcdir {} {
       return $::opts(php.srcdir)/ext/intl
    }
    public method install {} {
        cd [srcdir]
        logexec $::opts(php.prefix)/bin/phpize

        # Special env for OS X
        if {[$be cget -target] == "osx-x64"} {
            set dyldFlags "$::env(DYLD_LIBRARY_PATH)"
            unset ::env(DYLD_LIBRARY_PATH)
        }
        eval [list logexec ./configure --prefix=$::opts(php.prefix) --enable-intl]
        eval logexec [make]
        if {[$be cget -target] == "osx-x64"} {
            set ::env(DYLD_LIBRARY_PATH) "$dyldFlags"
        }
        if { ![file exists $::opts(php.prefix)/lib/php/extensions/] } {
            file mkdir $::opts(php.prefix)/lib/php/extensions/
        }
        file copy -force [srcdir]/modules/intl.so $::opts(php.prefix)/lib/php/extensions/
    }
    public method preparefordist {} {
        set phpini [file join $::opts(php.prefix) etc php.ini]
        xampptcl::file::append $phpini "extension=intl.so\n"
    }
    public method extract {} {}
}

::itcl::class opcache {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set name opcache
        set version 7.0.5
        set licenseRelativePath {}
        set isReportableComponent 0
    }

    public method preparefordist {} {
        if {[isWindows]} {
            set phpini [file join $::opts(php.prefix) php.ini]
            xampptcl::util::substituteParametersInFile $phpini \
                [list {[opcache]} {[opcache]
zend_extension=php_opcache.dll}] 1
        } else {
            set phpini [file join $::opts(php.prefix) etc php.ini]
            xampptcl::util::substituteParametersInFile $phpini \
                [list {[opcache]} {[opcache]
zend_extension=opcache.so}] 1
            # Disable huge pages support (won't exist in previous versions)
            xampptcl::util::substituteParametersInFile $phpini \
                [list {opcache.huge_code_pages} {;opcache.huge_code_pages}]
        }
        xampptcl::util::substituteParametersInFileRegex $phpini \
            [list {;opcache.enable=\d} {opcache.enable=1} {;opcache.enable_cli=\d} {opcache.enable_cli=0} {;opcache.memory_consumption=\d*} {opcache.memory_consumption=128} {;opcache.max_accelerated_files=\d*} {opcache.max_accelerated_files=10000} {;opcache.revalidate_freq=\d*} {opcache.revalidate_freq=60} {;opcache.interned_strings_buffer=\d*} {opcache.interned_strings_buffer=8}] 1
        if {[::xampptcl::util::compareVersions $::opts(php.version) 7.2.0] < 0} {
            xampptcl::util::substituteParametersInFileRegex $phpini [list {;opcache.fast_shutdown=\d} {opcache.fast_shutdown=1}] 1
        }
        # Fix error 500 with opcache https://bugs.php.net/bug.php?id=71353
        if {[string match windows* [$be cget -target]] && [::xampptcl::util::compareVersions $::opts(php.version) 7.0.0] > 0} {
            xampptcl::util::substituteParametersInFileRegex $phpini [list {;opcache.mmap_base=} {opcache.mmap_base=0x20000000}] 1
        }
    }
    public method needsToBeBuilt {} {
        return 0
    }
    public method install {} {}
    public method findTarball {{tarball {}}} {}
}

::itcl::class composer {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set name composer
        set version [getVtrackerField $name version frameworks]
        regsub -all {\-} $version {} version
        set licenseRelativePath {}
        set downloadType wget
        set downloadUrl https://github.com/composer/composer/releases/download/$version/composer.phar
        set tarballName composer-$version.phar
        set downloadTarballName $tarballName
        set folderAtThirdparty /opt/thirdparty/tarballs/php
    }
}
