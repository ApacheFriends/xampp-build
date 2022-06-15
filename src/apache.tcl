::itcl::class gettext {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name gettext
        set version 0.19.8.1
        set supportsParallelBuild 0
        set licenseRelativePath COPYING
    }
    public method setEnvironment {} {
        set ::opts(gettext.prefix) [prefix]
    }
    public method build {} {
	if {[$be targetPlatform] == "linux"} {
	    set oldCflags {}
	    catch {set oldCflags $::env(CFLAGS)}
	    set ::env(CFLAGS) "$oldCflags -march=i486"
	    chain
	    set ::env(CFLAGS) $oldCflags
	} else {
	    chain
	}
    }
    public method configureOptions {} {
        return [list --disable-libasprintf]
    }
    public method preparefordist {} {
        prepareWrapper [file join [prefix] bin gettext] COMMON
        file delete -force [file join [prefix] share doc gettext]
    }
    public method install {} {
        chain
        # OS X 10.10 COMPILATION
        if {[::xampptcl::util::isOSX1010Chroot]} {
            # Avoid the error below when executing `du -sh`:
            #   ERROR: line 22: regexec error 17, (illegal byte sequence)
            file delete [file join [$be cget -output] common share gettext po boldquot.sed]
            file delete [file join [$be cget -output] common share gettext po quot.sed]
        }
    }
}

# It can't be "zlib" because it is already defined in TCL
::itcl::class zlib1 {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name zlib
        set version 1.2.11
        set licenseRelativePath README
    }
    public method setEnvironment {} {
        set ::opts(zlib.prefix) [prefix]
        set ::opts(zlib.dir) [prefix]
    }
    public method configureOptions {} {
        return [list --shared]
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        # Sun Studio cc compiler does not understand xcg89 flag
        if {$::tcl_platform(os) == "SunOS"} {
            xampptcl::util::substituteParametersInFile [file join [srcdir] configure] \
                { {-xcg89} {} }
        }
        eval [list logexec ./configure --prefix=[prefix]] [configureOptions]
        eval logexec [make]
    }
}

::itcl::class openssl {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name openssl
        set fullname OpenSSL
        set version [versions::get "OpenSSL" stable]
        set dependencies {openssl {openssl-functions.xml openssl.xml openssl-without-apache.xml}}
        set readmePlaceholder OPENSSL
        set downloadType wget
        set downloadUrl http://www.openssl.org/source/openssl-$version.tar.gz
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        set downloadType wget
        set downloadUrl http://www.openssl.org/source/openssl-$version.tar.gz
        chain
    }
    public method prefix {} {
        return [file join [$be cget -output] [$be cget -libprefix]]
    }
}

::itcl::class opensslWindows {
    inherit openssl
    constructor {environment} {
        chain $environment
    } {
        set licenseRelativePath {}
    }
    public method install {} {}
    public method extract {} {}
    public method needsToBeBuilt {} {
        return 0
    }
}

::itcl::class opensslWindowsWithoutApache {
    inherit openssl
    constructor {environment} {
        chain $environment
    } {
        set version "0.9.8h-1"
        set tarballName "openssl-${version}-bin"
        set dependencies {openssl {openssl-without-apache.xml}}
        lappend additionalFileList {openssl-vcruntime-60.zip}
        set licenseRelativePath {}
    }
    public method install {} {
        file copy -force [srcdir] [prefix]
    }
    public method build {} {}
    public method prefix {} {
        return [$be cget -output]/openssl
    }
    public method extract {} {
        cd [extractDirectory]
        set f [findTarball]
        # The catch is here to avoid problems with extracting tarballs that have been generated in a machine with its time set in the future
        if {[catch {
            unzipFile $f [srcdir]
            } err]} {
            if {$::errorCode != "NONE"} {
                message error $err
            } else {}
        }
        unzipFile [$be cget -tarballs]/openssl/openssl-vcruntime-60.zip [srcdir]/bin
    }
}



::itcl::class opensslUnix {
    inherit openssl
    constructor {environment} {
        chain $environment
    } {
        set supportsParallelBuild 0   ;# Apparently only FreeBSD stuff. But its better to disable it on all platforms
        set licenseRelativePath LICENSE
        set licenseNotes http://www.openssl.org/source/license.html
    }
    public method getPatchesToApply {} {
        if { [$be cget -target] == "osx-x64" && [::xampptcl::util::compareVersions $version 1.0.2g] == 0 } {
            #gcc issue interpreting binary symbols (https://www.mail-archive.com/openssl-dev%40openssl.org/msg43035.html)
            set patchLevel 1
            set patchList {openssl-1.0.2g.OS-X.patch}
        } else {
            set patchList {}
        }
        return $patchList
    }
    public method setEnvironment {} {
        set ::opts(openssl.prefix) [prefix]
        set ::opts(openssl.srcdir) [srcdir]
        chain
    }
    public method getSharedLibraryFlag {} {
	if { [$be cget -target] == "osx-x64" } {
	    return "darwin64-x86_64-cc"
	} else {
	    return {-fPIC}
	}
    }
    public method configureOptions {} {
        set sslopts [list --openssldir=[prefix]/openssl --libdir=lib]
        #puts "XXX: NOT IMPLEMENTED YET. MUST BE TESTED. FOR SPLUNK/SOLARIS: ./config --prefix=$PREFIX --openssldir=$PREFIX/openssl shared no-err "
        # https://www.openssl.org/docs/faq.html#LEGAL1
        lappend sslopts no-idea no-mdc2 no-rc5 shared  ;# RSA/Exports issues
	if { [$be cget -target] != "aix" } {
	    set sslopts [concat $sslopts [getSharedLibraryFlag]]
	}
        return $sslopts
    }
    public method callConfigure {} {
        cd [srcdir]
	if { [$be cget -target] == "osx-x64" } {
	    eval [list logexec ./Configure --prefix=[prefix]] [configureOptions]
	}  elseif { ([$be cget -target] == "hpux") && ($::tcl_platform(machine) == "ia64") } {
	    # compile as 32-bit binaries for IA-64
	    eval [list logexec ./Configure hpux-ia64-cc --prefix=[prefix]] [configureOptions]
	} else {
	    eval [list logexec ./config --prefix=[prefix]] [configureOptions]
	}
    }
    public method build {} {
        cd [srcdir]
	if { [$be cget -target] == "aix" } {
	    # Fix openssl core dump on AIX
	    xampptcl::util::substituteParametersInFile [srcdir]/Configure \
		[list {cc:-q32} {cc:-q32 -lc -lm}]
	}
        callConfigure
        setVersionInformation
        # Necessary because we removed some algorithms
        logexec [make] depend
        logexec [make]
    }

    protected method rndFileInstallDir {} {
        return [file join [prefix] openssl/]
    }
    public method preparefordist {} {
        # https://www.openssl.org/docs/man1.1.1/man1/openssl-rand.html
        exec [prefix]/bin/openssl rand -out [file join [rndFileInstallDir] .rnd] [expr {int(rand()*1000)}]
        if { ![file exists [file join [rndFileInstallDir] .rnd]] } {
            message error "seeding file not found - http://www.openssl.org/support/faq.html#USER1"
        }

        file rename -force [prefix]/bin/openssl [prefix]/bin/openssl.bin
        xampptcl::file::write  [prefix]/bin/openssl {#!/bin/sh
LD_LIBRARY_PATH="@@XAMPP_COMMON_ROOTDIR@@/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
DYLD_FALLBACK_LIBRARY_PATH="@@XAMPP_COMMON_ROOTDIR@@/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
OPENSSL_CONF="@@XAMPP_COMMON_ROOTDIR@@/openssl/openssl.cnf"
OPENSSL_ENGINES="@@XAMPP_COMMON_ROOTDIR@@/lib/engines"
export LD_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH
export OPENSSL_CONF
export OPENSSL_ENGINES
exec @@XAMPP_COMMON_ROOTDIR@@/bin/openssl.bin "$@"
}
        file attributes [prefix]/bin/openssl -permissions 0755
    }
    public method setVersionInformation {} {}
}


::itcl::class opensslUnixVersioned {
    inherit opensslUnix
    constructor {environment} {
        chain $environment
    } {}
    public method getPatchesToApply {} {
        if { [$be cget -target] == "osx-x64" && [::xampptcl::util::compareVersions $version 1.0.2g] == 0 } {
            #gcc issue interpreting binary symbols (https://www.mail-archive.com/openssl-dev%40openssl.org/msg43035.html)
            set patchLevel 1
            set patchList {openssl-1.0.2g.OS-X.patch}
        } else {
            set patchList {}
        }
        return $patchList
    }
    public method setVersionInformation {} {
        if [string match linux* [$be cget -target]] {
           regexp (\[0-9.\]*) $version majorVersion
           xampptcl::file::write [srcdir]/openssl.ld "OPENSSL_$majorVersion {\nglobal:\n*;\n};\n"
	   if { [xampptcl::util::compareVersions $majorVersion 1.0.0] == 1 } {
	       xampptcl::file::append [srcdir]/openssl.ld "OPENSSL_1.0.0 {\nglobal:\n*;\n};\n"
	   }
	   # --version-script=openssl.ld <- this white space is important
           xampptcl::util::substituteParametersInFile [srcdir]/Makefile \
               [list "\nSHARED_LDFLAGS=" "\nSHARED_LDFLAGS=-Wl,--version-script=openssl.ld "]
        }
    }
}

::itcl::class libxml2 {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libxml2
        set version 2.9.4
        set licenseRelativePath Copyright
        set patchStrip 0
        set patchList {CVE-2016-9318.patch}
    }
    public method setEnvironment {} {
        chain
        set ::opts(libxml2.prefix) [prefix]
    }
    public method needsToBeBuilt {} {
        return 1
    }
    protected method configureOptions {} {
        return [list --without-python]
    }
    public method build {} {
        if {[string match osx* [$be cget -target]] && [lindex [$this info heritage] 0] == [uplevel namespace current]} {
            error "This component cannot be included in OS X stacks are it conflicts with the system libraries. Please use its native version 'libxml2OsxNative' instead"
        }
        if { [catch {glob [file join [srcdir] doc examples *.html]} err]} {
            xampptcl::util::substituteParametersInFile [file join [srcdir] doc examples Makefile.in] \
                [list {$(srcdir)/*.html} {}]
        }
        chain
    }
    public method install {} {
        cd [srcdir]
        # Not use [make]
        eval logexec make install
        file attributes [file join [prefix] bin xml2-config] -permissions 0755
    }
    public method preparefordist {} {
        chain
        foreach f {xmllint xmlcatalog} {
            prepareWrapper [file join [prefix] bin $f] COMMON
        }
    }
}

::itcl::class libxml2OsxNative {
    inherit libxml2
    constructor {environment} {
	 chain $environment
    } {}
    public method setEnvironment {} {
        set ::opts(libxml2.prefix) /usr
        set ::env(LIBXML_LIBS) "-L$::opts(libxml2.prefix)/lib -lxml2"
        set ::env(LIBXML_CFLAGS) "-I$::opts(libxml2.prefix)/include/libxml2"
    }
    public method copyLicense {} {}
    public method build {} {}
    public method needsToBeBuilt {} {
	return 0
    }
    public method install {} {}
    public method extract {} {}
    public method configureOptions {} {
        return {}
    }
    public method preparefordist {} {}
}

::itcl::class libpng {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libpng
        set version 1.5.26
        set licenseRelativePath LICENSE
	    set licenseNotes http://www.libpng.org/pub/png/src/libpng-LICENSE.txt
    }
    public method setEnvironment {} {
        set ::opts(libpng.prefix) [prefix]
    }
}
::itcl::class expatLib {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name expat
        set version 2.2.0
        set licenseRelativePath COPYING
        set licenseNotes "MIT http://www.jclark.com/xml/copying.txt"
    }
    public method setEnvironment {} {
        set ::opts(expat.prefix) [prefix]
    }
    protected method configureOptions {} {
        return {}
    }
}
::itcl::class sqlite {
    inherit baseBitnamiProgram
    public variable tarballVersion
    constructor {environment} {
        chain $environment
    } {
        set name sqlite
        set fullname SQLite
        set version [versions::get "SQLite" stable]
        set dependencies {sqlite {sqlite.xml}}
        set readmePlaceholder SQLITE
        set licenseRelativePath {}
        set licenseNotes http://www.sqlite.org/copyright.html

        # Fix to find SQLite tarballs
        set majorVersion [lindex [split $version .] 0]
        set minorVersion [lindex [split $version .] 1]
        set patchVersion [lindex [split $version .] 2]
        set tailVersion ""
        foreach v "$minorVersion $patchVersion" {
            if {[string length $v] < 2} {
                set tailVersion ${tailVersion}0$v
            } else {
                set tailVersion $tailVersion$v
            }
        }
        set tarballVersion ${majorVersion}${tailVersion}00
        set tarballName $name-autoconf-$tarballVersion
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        # Fix to find SQLite tarballs
        set majorVersion [lindex [split $version .] 0]
        set minorVersion [lindex [split $version .] 1]
        set patchVersion [lindex [split $version .] 2]
        set tailVersion ""
        foreach v "$minorVersion $patchVersion" {
            if {[string length $v] < 2} {
                set tailVersion ${tailVersion}0$v
            } else {
                set tailVersion $tailVersion$v
            }
        }
        set tarballVersion ${majorVersion}${tailVersion}00
        set tarballName $name-autoconf-$tarballVersion

        set downloadType wget
        set downloadUrl https://www.sqlite.org/2022
        set tarballNameListForDownload [list $name-autoconf-$tarballVersion.tar.gz\
                                            $name-src-$tarballVersion.zip \
                                            $name-tools-win32-x86-$tarballVersion.zip \
                                            $name-dll-win32-x86-$tarballVersion.zip \
                                            $name-dll-win64-x64-$tarballVersion.zip]
        chain
    }
}

::itcl::class db {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name db
        set version 4.3.29.NC
	set licenseRelativePath LICENSE
     }
    public method setEnvironment {} {
       set ::opts(db.prefix) [prefix]
    }
    public method build {} {
       cd [srcdir]/build_unix
       eval [list logexec ../dist/configure --prefix=[prefix]] [configureOptions]
       eval logexec [make]
    }

    public method install {} {
       cd [srcdir]/build_unix
       eval logexec [make] install
    }
}

::itcl::class nghttp2 {
    inherit library
    constructor {environment} {
            chain $environment
    } {
            set name "nghttp2"
            set version 1.18.1
            set licenseRelativePath COPYING
    }
}


# This class is only intended for downloading the Apache upstream tarballs
::itcl::class apache {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name apache
        set fullname Apache
        set version [versions::get "Apache" stable]
        set folderAtThirdparty [$be cget -tarballs]/lamp
    }
    public method download {} {
        set version [getVersionFromVtracker]
        set downloadType wget
        set downloadTarballName httpd-$version.tar.gz
        set downloadUrl http://apache.uvigo.es/httpd/$downloadTarballName
        chain
        # 32 bits is necessary for zlib1 in drupal
        foreach winVersion [list win32 win64] {
            set version [getVtrackerField windows-apache version infrastructure]
            foreach vcVersion [list VC15 VS16] {
                set downloadTarballName httpd-$version-$winVersion-$vcVersion.zip
                if { $vcVersion == "VS16" } {
                    set downloadUrl https://www.apachelounge.com/download/$vcVersion/binaries/$downloadTarballName
                } else {
                    set downloadUrl https://home.apache.org/~steffenal/$vcVersion/binaries/$downloadTarballName
                }
                chain
            }
        }
    }
}

::itcl::class httpd {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name apache
        set fullname Apache
        set licenseRelativePath LICENSE
        set separator -
        set scriptFiles {ctl.sh {linux osx solaris-intel solaris-sparc} {servicerun.bat serviceinstall.bat} windows}
        set readmePlaceholder APACHE
        set dependencies {httpd {apache.xml apache-bitnami.xml apache-functions.xml apache-service.xml apache-properties.xml apache-upgrade.xml} {mysql} {apache-mysql.xml} php {apache-mysql.xml apache-php.xml} gem_mongrel {apache-mongrel-cluster.xml apache-mongrel-module.xml apache-mongrel-module-properties.xml} subversion {apache-subversion.xml} sqlite {apache-sqlite.xml} python {apache-wsgi.xml}  postgresql {apache-postgres.xml}}
        set moduleDependencies {httpd {apache-functions.xml apache-properties.xml} gem_mongrel {apache-mongrel-module.xml apache-mongrel-module-properties.xml apache-passenger.xml} ruby {apache-thin-module.xml apache-thin-module-properties.xml} nodejs {apache-forever-module.xml apache-forever-module-properties.xml}}
        set upgradable 1
    }
    public method applicationOutputDir {} {
        return [file join [$be cget -output] apache2]
    }
    public method setEnvironment {} {
	set ::opts(apache.apxs) [file join [prefix] bin apxs]
	set ::opts(apache.apr) [file join [prefix] bin apr-1-config]
	set ::opts(apache.apu) [file join [prefix] bin apu-1-config]
        set ::opts(apache.prefix) [prefix]
        set ::opts(apache.srcdir) [srcdir]
    }
    public method prefix {} {
        return [file join [$be cget -output] apache2]
    }
    public method srcdir {} {
        return [file join [$be cget -src] httpd-$version]
    }
    public method preparefordist {} {
	foreach f [glob -nocomplain [prefix]/conf/{/,/extra/}*.conf] {
	    xampptcl::util::substituteParametersInFile $f \
		{{Listen 80} {Listen @@XAMPP_APACHE_PORT@@}\
		     {443} {@@XAMPP_APACHE_SSL_PORT@@}\
		     {#ServerName www.example.com:80} {ServerName localhost:@@XAMPP_APACHE_PORT@@}}
	}
    }
}

::itcl::class php {
    inherit baseBitnamiProgram
    public variable composerVersion
    constructor {environment} {
        chain $environment
    } {
        set name php
        set fullname PHP
        set dependencies {php {php.xml php-functions.xml}}
        set moduleDependencies {}
        set scriptFiles {{ctl.sh} {linux osx}}
        set readmePlaceholder PHP

        set php_dir [file join /bitnami lamp56 php]
        set php_bin $php_dir/bin/php
        set target_php [file join [$be cget -output] php]
        set ::opts(pear.command) "$php_bin -C -q -d output_buffering=1 -d variables_order=EGPCS -d open_basedir=\"\" -d safe_mode=0 -d register_argc_argv=\"On\" -d auto_prepend_file=\"\" -d auto_append_file=\"\" ${target_php}/PEAR/pearcmd.php"
        set upgradable 1

        set composerComponent [::itcl::local composer #auto $be]
        set composerVersion [$composerComponent cget -version]
        set downloadType wget
    }
    public method prefix {} {
        return [file join [$be cget -output] php]
    }
    public method download {} {
        foreach version [list [getVtrackerField PHP74 version infrastructure] [getVtrackerField PHP80 version infrastructure] [getVtrackerField PHP81 version infrastructure]] {
            set downloadTarballName $name-$version.tar.gz
            set downloadUrl http://php.net/get/php-$version.tar.gz/from/this/mirror
            chain
            if { [::xampptcl::util::compareVersions $version 7.0.0] < 0 } {
                set vcVersion VC11
            } elseif { [::xampptcl::util::compareVersions $version 7.2.0] < 0 } {
                set vcVersion VC14
            } elseif { [::xampptcl::util::compareVersions $version 8.0.0] < 0 } {
                set vcVersion VC15
            } else {
                set vcVersion VS16
            }
            set downloadTarballName $name-$version-Win32-$vcVersion-x64.zip
            set downloadUrl http://windows.php.net/downloads/releases/php-$version-Win32-$vcVersion-x64.zip
            chain
        }
    }
}

#php on linux: some class are not correclty derivated and there are problems
#with the configure options
::itcl::class phpUnix {
     inherit php
     constructor {environment} {
         chain $environment
     } {
         set licenseRelativePath LICENSE
         set supportsParallelBuild 0
     }
     public variable includePear 1

     public method setEnvironment {} {
         chain
         set ::opts(php.prefix) [prefix]
         set ::opts(php.srcdir) [srcdir]
         set ::opts(pear.prefix) $::opts(php.prefix)/lib/php
         #Fix OSX make install-pear error
         if {[$be targetPlatform] == "osx-x64"} {
             set ::env(DYLD_LIBRARY_PATH) $::env(DYLD_LIBRARY_PATH):[file join $::opts(mysql.prefix) lib]
         }
         # Set pkg-config environment variable to properly find missing dependencies
         if [info exists ::env(PKG_CONFIG_PATH)] {
             set ::env(PKG_CONFIG_PATH) "[$be cget -output]/common/lib/pkgconfig:$::env(PKG_CONFIG_PATH)"
         } else {
             set ::env(PKG_CONFIG_PATH) "[$be cget -output]/common/lib/pkgconfig"
         }
     }
     protected method configureOptions {} {
         set list [list --with-apxs2=$::opts(apache.apxs) --with-iconv=$::opts(libiconv.dir) \
                       --with-expat-dir=$::opts(expat.prefix)  --with-mysql=$::opts(mysql.prefix) --with-zlib-dir=$::opts(zlib.dir) \
                       --enable-mbstring=all --enable-soap --enable-bcmath --enable-ftp \
                       --with-xmlrpc --enable-fastcgi --enable-force-cgi-redirect]
         if {[string match osx* [$be cget -target]]} {
             lappend list --with-gettext=$::opts(gettext.prefix)
         } else {
             lappend list --with-gettext
         }

        if {[::xampptcl::util::compareVersions $version 7.4.0] >= 0} {
            # New options for PHP 7.4.0
            lappend list [list --with-libxml=shared,$::opts(libxml2.prefix) --with-pear --enable-gd --with-jpeg --with-libwebp --with-freetype]
        } else {
            lappend list [list --with-libxml-dir=$::opts(libxml2.prefix) --with-gd]
        }

         return $list
     }
     public method preparefordist {} {
         chain
         xampptcl::file::write [file join [prefix] bin fixreg.php] {<?php
/*
(c) 2004-2006 BitRock SL http://www.bitrock.com
*/
$directory = $argv[1];
/* "@@XAMPP_PHP_ROOT@@";*/
$placeholder= $argv[2];
$bitrock_php_path = $argv[3];

set_magic_quotes_runtime(0);

function my_array_walk_and_replace ($myarray) {
    global $bitrock_php_path;
    global $placeholder;
    $localarray = array();
    foreach ($myarray as $key => $value) {
        if (is_array($value)) {
            $value = my_array_walk_and_replace($value);
        } elseif(is_string($value))  {
            $value = str_replace($placeholder, $bitrock_php_path, $value);
        } else {
            //number, no need to subst
        }
        $localarray[str_replace($placeholder, $bitrock_php_path, $key)] = $value;
    }
    return $localarray;
}
foreach (glob($argv[1] . "/*.reg") as $file) {
    echo "Patching $file\n";
    $array = unserialize(file_get_contents($file));
    $array=my_array_walk_and_replace($array);
    $f = fopen($file, "w");
    fwrite($f,serialize($array));
    fclose($f);
}
foreach (glob($argv[1] . "/pear.conf") as $file) {
    echo "Patching $file\n";
    $contents = file_get_contents($file);
    preg_match('/^\#PEAR_Config\s+(\S+)\s+/si', $contents, $matches);
    $version = $matches[1];
    $contents = substr($contents, strlen($matches[0]));
    $array = unserialize($contents);
    $array=my_array_walk_and_replace($array);
    $f = fopen($file, "w");
    fwrite($f,"#PEAR_Config $version\n" . serialize($array) . "\n");
    fclose($f);
}
exit(0);
?>

}
    if { $version >= "5.3" } {
         xampptcl::util::substituteParametersInFile [file join [prefix] bin fixreg.php] \
           [list {set_magic_quotes_runtime(0);} {ini_set("magic_quotes_runtime", 0);}]
    }

        file attributes [file join [prefix] bin fixreg.php] -permissions 0755
	# For some reason, it still exits with wrong code
	logexecIgnoreErrors [file join [prefix] bin php] -q \
	    [file join [prefix] bin fixreg.php] [file join [prefix] lib php .registry] [prefix] @@XAMPP_PHP_ROOT@@
        # Apache substitutions
	logexecIgnoreErrors [file join [prefix] bin php] -q \
	    [file join [prefix] bin fixreg.php] [file join [prefix] lib php .registry] $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@
        foreach f [glob -nocomplain [prefix]/lib/php/.registry/.channel*] {
            logexecIgnoreErrors [file join [prefix] bin php] -q \
	    [file join [prefix] bin fixreg.php] $f [prefix] @@XAMPP_PHP_ROOT@@
            # Apache substitutions
	    logexecIgnoreErrors [file join [prefix] bin php] -q \
	    [file join [prefix] bin fixreg.php] $f $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@
        }
	# We need to remove first line
	logexecIgnoreErrors [file join [prefix] bin php] -q \
	    [file join [prefix] bin fixreg.php] [file join [prefix] etc] [prefix] @@XAMPP_PHP_ROOT@@

	if {$includePear == 0} {
		file mkdir [file join [prefix] etc]
	}

        if {![file exists [file join [prefix] etc php.ini]]} {
            file mkdir [file join [prefix] etc]
            if {[file exists [file join [srcdir] php.ini-recommended]]} {
                file copy [file join [srcdir] php.ini-recommended] [file join [prefix] etc php.ini]
            } elseif {[file exists [file join [srcdir] php.ini-production]]} {
                # PHP 5.3 ships two default php.ini files: php.ini-production and php.ini-development
                file copy [file join [srcdir] php.ini-production] [file join [prefix] etc php.ini]
            } else {
                message error "Any default php.ini file found"
                exit 1
            }
        }

        # Ref T3264 - use UTF-8 charset by default
       xampptcl::util::substituteParametersInFile [file join [prefix] etc php.ini] {{;default_charset = "UTF-8"} {default_charset = "UTF-8"}}

       xampptcl::util::substituteParametersInFile [file join [prefix] etc php.ini] {
	       {;include_path = ".:/php/includes"} {include_path = ".:@@XAMPP_PHP_ROOTDIR@@/lib/php"}
           {extension_dir = "./"} {extension_dir = "@@XAMPP_PHP_ROOTDIR@@/lib/php/extensions"}
    	   {mysql.default_port =} {mysql.default_port = @@XAMPP_MYSQL_PORT@@}
           {mysqli.default_port = 3306} {mysqli.default_port = @@XAMPP_MYSQL_PORT@@}
           {;date.timezone =} {date.timezone = "UTC"}
           {;sendmail_path =} {;sendmail_path = "env -i /usr/sbin/sendmail -t -i"}
	}
	# PHP 5.3
	xampptcl::util::substituteParametersInFileRegex [file join [prefix] etc php.ini] \
           [list {;\s*extension_dir\s*=\s*"@@XAMPP_PHP_ROOTDIR@@/lib/php/extensions"} {extension_dir = "@@XAMPP_PHP_ROOTDIR@@/lib/php/extensions"}]

        file rename [file join [prefix] bin php] [file join [prefix] bin php.bin]
        xampptcl::file::write [file join [prefix] bin php] {#!/bin/sh
PHPRC=@@XAMPP_PHP_ROOTDIR@@/etc
export PHPRC
PHP_PEAR_SYSCONF_DIR=@@XAMPP_PHP_ROOTDIR@@/etc
export PHP_PEAR_SYSCONF_DIR
LD_LIBRARY_PATH="@@XAMPP_PHP_ROOTDIR@@/lib:@@XAMPP_COMMON_ROOTDIR@@/lib:@@XAMPP_APACHE_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH
DYLD_FALLBACK_LIBRARY_PATH="@@XAMPP_PHP_ROOTDIR@@/lib:@@XAMPP_COMMON_ROOTDIR@@/lib:@@XAMPP_APACHE_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
export DYLD_FALLBACK_LIBRARY_PATH
exec @@XAMPP_PHP_ROOTDIR@@/bin/php.bin "$@"
}
        file attributes [file join [prefix] bin php] -permissions 0755
        if {[file exists [file join [prefix] bin php-cgi]]} {
        file rename [file join [prefix] bin php-cgi] [file join [prefix] bin php-cgi.bin]
        xampptcl::file::write [file join [prefix] bin php-cgi] {#!/bin/sh
PHPRC=@@XAMPP_PHP_ROOTDIR@@/etc
export PHPRC
PHP_PEAR_SYSCONF_DIR=@@XAMPP_PHP_ROOTDIR@@/etc
export PHP_PEAR_SYSCONF_DIR
LD_LIBRARY_PATH="@@XAMPP_PHP_ROOTDIR@@/lib:@@XAMPP_APACHE_ROOTDIR@@/../common/lib:@@XAMPP_APACHE_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH
DYLD_FALLBACK_LIBRARY_PATH="@@XAMPP_PHP_ROOTDIR@@/lib:@@XAMPP_APACHE_ROOTDIR@@/../common/lib:@@XAMPP_APACHE_ROOTDIR@@/lib:@@XAMPP_MYSQL_ROOTDIR@@/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
export DYLD_FALLBACK_LIBRARY_PATH
exec @@XAMPP_PHP_ROOTDIR@@/bin/php-cgi.bin "$@"
}
        file attributes [file join [prefix] bin php-cgi] -permissions 0755
	}

        set fileList {
         include/php/main build-defs.h
         include/php/main php_config.h
         bin php-config
         bin phpize
         bin php
        }
		if {$includePear == 1} {
			lappend fileList lib/php pearcmd.php lib/php peclcmd.php bin pear bin pecl bin peardev
        }
        foreach {d f} $fileList {
          set fp [file join [prefix] $d $f]
          if {[file exists $fp] && [info exist ::opts(swig.mysql)]} {
	      xampptcl::util::substituteParametersInFile \
		  $fp \
    [list [prefix] @@XAMPP_PHP_ROOTDIR@@ $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@ $::opts(mysql.prefix) @@XAMPP_MYSQL_ROOTDIR@@ [file join [$be cget -output] [$be cget -libprefix]] @@XAMPP_COMMON_ROOTDIR@@]
	  } elseif {[file exists $fp]} {
	      xampptcl::util::substituteParametersInFile \
		  $fp \
    [list [prefix] @@XAMPP_PHP_ROOTDIR@@ $::opts(apache.prefix) @@XAMPP_APACHE_ROOTDIR@@ [file join [$be cget -output] [$be cget -libprefix]] @@XAMPP_COMMON_ROOTDIR@@]
          }
        }
        set text [xampptcl::file::read [file join $::opts(apache.prefix) conf httpd.conf]]
        append text "\nAddType application/x-httpd-php .php .phtml\n"
        xampptcl::file::write [file join $::opts(apache.prefix) conf httpd.conf] $text
        if {[file exists $::opts(apache.prefix)/libexec/libphp4.so]} {
          strip [prefix]/bin/php $::opts(apache.prefix)/libexec/libphp4.so
        } else {
          strip [prefix]/bin/php $::opts(apache.prefix)/modules/libphp5.so
        }
        if { [file exists [file join [prefix] bin phar.phar]] } {
            cd [prefix]/bin
            file delete -force [prefix]/bin/phar
            # T360 relative symlinks only works in recent Tcl versions
            eval logexec ln -s phar.phar phar
            # T5330 The shebang points to php location inside the chroot
            xampptcl::util::substituteParametersInFileRegex [file join [prefix] bin phar.phar] [list {^#![^\n]+} {#!@@XAMPP_PHP_ROOTDIR@@/bin/php}]
            cd [srcdir]
        }

    }
    protected method configureEnvironment {} {
        set common [file join [$be cget -output] [$be cget -libprefix]]
        set newCppFlags -I$common/include
        set newCFlags "$::env(CFLAGS)"
        if { $::tcl_platform(os) == "SunOS" } {
             set newLdFlags "-L$common/lib"
             if { [string match solaris-intel-x64 [$be cget -target]] }  {
                 #set newLdFlags "-L/usr/lib/64 -lCrun $newLdFlags"
             }
        } else {
             set newCFlags "-O2 $::env(CFLAGS)"
             set newLdFlags "-L$common/lib -liconv"
        }
        if {[$be cget -target] == "osx-x64" && [::xampptcl::util::compareVersions $::opts(php.version) 7.2.0] >= 0 && [info exists ::env(DYLD_LIBRARY_PATH)]} {
            unset ::env(DYLD_LIBRARY_PATH)
        }

        if { $::tcl_platform(os) == "Darwin" } {
            if {[info exists ::env(DYLD_LIBRARY_PATH)]} {
                set newLdLibraryPath $common/lib:$::env(DYLD_LIBRARY_PATH)
                set newEnvList [list CPPFLAGS $newCppFlags DYLDFLAGS $newLdFlags DYLD_LIBRARY_PATH $newLdLibraryPath]
            } else {
                set newEnvList [list CPPFLAGS $newCppFlags DYLDFLAGS $newLdFlags]
            }
        } else {
            set newLdLibraryPath $common/lib:$::env(LD_LIBRARY_PATH)
            set newEnvList [list CFLAGS $newCFlags CPPFLAGS $newCppFlags LDFLAGS $newLdFlags LD_LIBRARY_PATH $newLdLibraryPath]
            if { [string match solaris-intel-x64 [$be cget -target]] }  {
                set newEnvList [concat $newEnvList EXTRA_LIBS -lCrun]
            }
        }

        set newEnvList [concat $newEnvList EXTENSION_DIR [prefix]/lib/php/extensions]

        return $newEnvList
    }
    public method callConfigure {} {
        if {[$be cget -target] == "osx-x64" && [info exists ::env(DYLD_LIBRARY_PATH)] && [::xampptcl::util::compareVersions $::opts(php.version) 7.2.0] >= 0} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        eval [list logexecEnv [configureEnvironment] ./configure --prefix=[prefix]] [configureOptions]
        if {[$be cget -target] == "osx-x64" && [info exists oldDYLD]} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
    public method install {} {
       chain
       file copy -force [srcdir]/php-cgi [prefix]/bin/php-cgi
    }
   public method build {} {
       xampptcl::util::substituteParametersInFile [srcdir]/configure {
           {echo "configure: error: installation or configuration problem: C++ compiler cannot create executables." 1>&2; exit 1;}
           {echo "configure: error: installation or configuration problem: C++ compiler cannot create executables." 1>&2; }
       }
       # Fix for PHP 5.3 win intl in Solaris, refs #9069
       # inline improves the performance but not compatible with older cc
       if {[string match solaris* [$be cget -target]] } {
           foreach f [list [file join ext intl grapheme grapheme_string.c] [file join ext intl grapheme grapheme_util.h]] {
               if { [file exists [file join [srcdir] $f]]} {
                   xampptcl::util::substituteParametersInFile [file join [srcdir] $f] \
	               [list {inline int32_t
} {int32_t }]
               }
           }
       }
       # Build first w/o apxs so the 'cgi' version gets built.
       cd [srcdir]
       set options [configureOptions]
       set pos [lsearch -glob $options *apxs*]
       set options [lreplace $options $pos $pos]
       set ::env(PROG_SENDMAIL) /usr/bin/sendmail
       if {[$be cget -target] == "osx-x64" && [info exists ::env(DYLD_LIBRARY_PATH)] && [::xampptcl::util::compareVersions $::opts(php.version) 7.2.0] >= 0} {
           set oldDYLD $::env(DYLD_LIBRARY_PATH)
           unset ::env(DYLD_LIBRARY_PATH)
       }

       # Show environment
       showEnvironmentVars

       if {[::xampptcl::util::compareVersions $version 7.4.0] >= 0} {
           set ::env(PKG_CONFIG_PATH) "[$be cget -output]/sqlite/lib/pkgconfig:$::env(PKG_CONFIG_PATH)"
           set ::env(LDFLAGS) "-L[$be cget -output]/sqlite/lib $::env(LDFLAGS)"
           eval [list logexecEnv [list LDFLAGS $::env(LDFLAGS) PKG_CONFIG_PATH $::env(PKG_CONFIG_PATH) [configureEnvironment]] ./configure --prefix=[prefix]] [configureOptions]
       } else {
           eval [list logexecEnv [configureEnvironment] ./configure --prefix=[prefix]] $options
       }
       eval logexec [make]
       file copy -force [srcdir]/sapi/cgi/php-cgi [srcdir]/php-cgi
       # Need to first do make clean, otherwise message about
       # symbol: php_module_shutdown_wrapper
       # when trying to load module into server
       eval logexec [make] clean
       chain
       if {[$be cget -target] == "osx-x64" && [info exists oldDYLD]} {
           set ::env(DYLD_LIBRARY_PATH) $oldDYLD
       }
   }
}

::itcl::class gd {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name gd
        set version 2.0.35
        set licenseRelativePath COPYING
        set licenseNotes https://bitbucket.org/pierrejoye/gd-libgd/src/733361a31aab7fe1e5e58881ea87ece5ad787ed7/src/COPYING?at=default
    }
    public method setEnvironment {} {
	chain
        set ::opts(gd.prefix) [prefix]
    }
    public method build {} {
        cd [srcdir]
        if {[string match linux* [$be targetPlatform]]} {
            set aclocal ""
            if {[info exists ::env(ACLOCAL)]} {
                set aclocal $::env(ACLOCAL)
            }
            if {[info exists ::opts(libtool.prefix)] && [info exists ::opts(gettext.prefix)]} {
                set ::env(ACLOCAL) "aclocal -I [prefix]/share/aclocal -I $::opts(libtool.prefix)/share/aclocal"
            } elseif {[info exists ::opts(libtool.prefix)]} {
                set ::env(ACLOCAL) "aclocal -I $::opts(libtool.prefix)/share/aclocal"
            }
        }
        callConfigure
        eval logexecIgnoreErrors [make]
        eval logexec [make]

        if {[string match linux* [$be targetPlatform]]} {
            if {$aclocal != ""} {
                set ::env(ACLOCAL) $aclocal
            } else {
                unset -nocomplain ::env(ACLOCAL)
            }
        }
    }
    public method install {} {
        chain
        file attributes [file join [prefix] bin gdlib-config] -permissions 0755
    }
}

::itcl::class cacertificates {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name cacertificates
        set version [getVtrackerField cacertificates version frameworks]
        set licenseRelativePath {}
        set licenseNotes https://curl.haxx.se/docs/caextract.html
        set downloadType wget
        set downloadTarballName curl-ca-bundle-$version.crt
        set downloadUrl https://curl.haxx.se/ca/cacert-$version.pem
    }
    public method setEnvironment {} {}
    protected method configureOptions {} {}
    public method build {} {}
    public method install {} {}
}


::itcl::class curl {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name curl
        set version [versions::get "Curl" stable]
        set licenseRelativePath COPYING
        set licenseNotes http://curl.haxx.se/legal/licmix.html
        set downloadType wget
        set downloadUrl https://curl.haxx.se/download/$name-$version.tar.gz
    }
    public method setEnvironment {} {
	chain
        set ::opts(curl.prefix) [prefix]
    }
    protected method configureOptions {} {
        return [list --without-ssl]
    }
    public method download {} {
        set version  [getVersionFromVtracker]
        set downloadUrl https://curl.haxx.se/download/$name-$version.tar.gz
        chain
        set curlComponent [curlsslWindows64 ::\#auto $be]
        $curlComponent download
    }
    public method build {} {
       cd [srcdir]
       regsub -all {\-I[^ ]+} $::env(CFLAGS) "" newCFlags
       set newCppFlags $::env(CPPFLAGS)
       if { [regsub -all {\-D_FORTEC_} $newCFlags "" newCFlags] } {
           lappend newCppFlags "-D_FORTECT_"
       }
       eval [list logexecEnv [list CFLAGS $newCFlags CPPFLAGS $newCppFlags] ./configure --prefix=[prefix]] [configureOptions]
       eval logexec [make]
    }

    public method install {} {
	chain
	if {[$be targetPlatform] == "solaris-intel" || [$be targetPlatform] == "solaris-sparc" } {
           foreach f [glob [file join [srcdir] include curl *.h]] {
               file copy -force $f [prefix]/include/curl/
           }
        }
        file attributes [file join [prefix] bin curl-config] -permissions 0755
    }
}

::itcl::class curlssl {
    inherit curl
    constructor {environment} {
        chain $environment
    } {}
    protected method configureOptions {} {
        return [list --with-ssl=$::opts(openssl.prefix)]
    }
}

::itcl::class curlsslEnv {
    inherit curlssl
    constructor {environment} {
        chain $environment
    } {
        set supportsParallelBuild 0
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        lappend additionalFileList curl-ca-bundle-${cacertificatesVersion}.crt
    }
    public method build {} {
        cd [srcdir]
        regsub -all {\-I[^ ]+} $::env(CFLAGS) "" newCFlags
        eval [list logexecEnv [list CFLAGS $newCFlags CPPFLAGS $::env(CPPFLAGS)] ./configure --prefix=[prefix]] [configureOptions]
        eval logexec [make]
    }
    public method preparefordist {} {
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        file copy -force [findFile curl-ca-bundle-${cacertificatesVersion}.crt] [file join [prefix] openssl certs curl-ca-bundle.crt]
        file rename -force [prefix]/bin/curl [prefix]/bin/curl.bin
        xampptcl::file::write  [prefix]/bin/curl {#!/bin/sh
LD_LIBRARY_PATH="@@XAMPP_COMMON_ROOTDIR@@/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
DYLD_FALLBACK_LIBRARY_PATH="@@XAMPP_COMMON_ROOTDIR@@/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
CURL_CA_BUNDLE="@@XAMPP_COMMON_ROOTDIR@@/openssl/certs/curl-ca-bundle.crt"
export LD_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH
export CURL_CA_BUNDLE
exec @@XAMPP_COMMON_ROOTDIR@@/bin/curl.bin "$@"
}
        file attributes [prefix]/bin/curl -permissions 0755
        xampptcl::util::substituteParametersInFile [file join [prefix] bin curl-config] \
            [list [prefix] @@XAMPP_COMMON_ROOTDIR@@ "/etc/pki/tls/certs/ca-bundle.crt" @@XAMPP_COMMON_ROOTDIR@@/openssl/certs/curl-ca-bundle.crt]
        xampptcl::util::substituteParametersInFile [file join [prefix] lib pkgconfig libcurl.pc] \
            [list [prefix] @@XAMPP_COMMON_ROOTDIR@@]
        xampptcl::util::substituteParametersInFile [file join [prefix] lib libcurl.la] \
            [list [prefix] @@XAMPP_COMMON_ROOTDIR@@]
    }

}

::itcl::class curlsslWindows64 {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name curl
        set version [versions::get "Curl" stable]
        set downloadType wget
        set tarballName $name-$version-win64-mingw.zip
        set downloadUrl https://curl.haxx.se/windows/dl-$version/$tarballName
        set licenseRelativePath COPYING.txt
    }
    public method build {} {}
    public method srcdir {} {
        return [file join [$be cget -src] $name-$version-win64-mingw]
    }
    public method install {} {
        file mkdir [file join [$be cget -output] common bin]
        foreach f [glob -nocomplain [srcdir]/bin/*.{dll,exe}] {
            file copy -force $f [file join [$be cget -output] common bin]
        }
    }
}

::itcl::class jpegsrc {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name jpegsrc
        set version 8d
        set tarballName jpegsrc.v$version
        set licenseRelativePath README
        set licenseNotes http://www.ijg.org/
        set supportsParallelBuild 0
        set ::opts(jpegsrc.prefix) [prefix]
    }
    public method srcdir {} {
        return [file join [$be cget -src] jpeg-$version]
    }

    public method setEnvironment {} {
        chain
        set ::opts(jpegsrc.prefix) [prefix]
        set ::env(JPEG_LIBS) "-L[prefix]/lib -ljpeg"
        set ::env(JPEG_CFLAGS) "-I[prefix]/include"
        if {$::tcl_platform(os) == "Darwin"} {
            set ::env(MACOSX_DEPLOYMENT_TARGET) "10.5"
        }
    }
    protected method configureOptions {} {
        return [list  --enable-shared --enable-static]
    }

    public method build {} {
	cd [srcdir]
	# i can't put this in patch list since it's only for fbsd
        #if {$::tcl_platform(os) == "FreeBSD"} {
        #   logexec patch -p0 < [$be cget -projectDir]/patches/jpeg-6b_freebsd.diff
        #}
	# This patch isnt needed aparently
	#logexec ln -s /opt/splunk/bin/libtool .
	if {$::tcl_platform(os) == "Darwin"} {
	    foreach dir {/usr/share/libtool/ /usr/share/libtool/config} {
		foreach file {config.guess config.sub} {
		    if {[file exists [file join $dir $file]]} {
			file copy -force [file join $dir $file] .
			break
		    }
		}
	    }
	}
	#jpegsrc is using a old version of libtool which does not know about 64 libs
	#platforms, so we need copy a more updated config.* files to avoid failures like:
	# Invalid configuration `x86_64-unknown-linux-gnu': machine `x86_64-unknown' not recognized
	if {[$be targetPlatform] == "linux-x64"} {
	    foreach d [concat /usr/share/misc [glob -nocomplain /usr/share/automake*]] {
		if {[file exists [file join $d config.guess]]} {
		    break
		}
	    }
	    file copy -force [file join $d config.guess] .
	    file copy -force [file join $d config.sub] .
	}
	cd [srcdir]
        showEnvironmentVars
        callConfigure
        if {$::tcl_platform(os) == "Darwin"} {
	    if {[file exists /usr/bin/glibtool]} {
		file delete -force [srcdir]/libtool
		eval logexec ln -s /usr/bin/glibtool [srcdir]/libtool
	    }
	}
	if {[$be targetPlatform] == "osx-x64"} {
	    xampptcl::util::substituteParametersInFile Makefile \
		[list {-o libjpeg.la} {$(CFLAGS) -o libjpeg.la}]
	}
        eval logexec [make]
    }
    public method install {} {
        file delete [srcdir]/.buildcomplete
        file mkdir [file join [prefix] man]
        file mkdir [file join [prefix] man man1]
        #eval logexec [make] install-headers
	#eval logexec [make] install-lib
	chain
    }

    public method preparefordist {} {
	prepareWrapper [file join [prefix] bin jpegtran] COMMON
    }
}

::itcl::class imap {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set name imap
        set version 2007f
        set separator -
	set licenseRelativePath LICENSE.txt
    }
    public method setEnvironment {} {
	chain
        set ::opts(imap.src) [srcdir]
    }
    public method build {} {
        cd [srcdir]
	if {[string match osx-x64 [$be cget -target]]} {
	    xampptcl::util::substituteParametersInFile \
		[file join [srcdir] Makefile] \
		[list {-DMAC_OSX_KLUDGE=1} {}]
	}


        set makeTarget slx

        switch $::tcl_platform(os) {
            "FreeBSD" {
                set makeTarget bsf
            }
            "SunOS" {
                set makeTarget gso
            }
            "Darwin" {
                set makeTarget oxp
                xampptcl::util::substituteParametersInFile \
                    [file join [srcdir] src osdep unix Makefile] \
                    [list {-g -O -Wno-pointer-sign} {-g -O}]
                #Fuera kerberos.
                xampptcl::util::substituteParametersInFile \
                    [file join [srcdir] Makefile] \
                    [list {$(EXTRAAUTHENTICATORS) gss} {$(EXTRAAUTHENTICATORS)}]
            }
        }

        if {[$be targetPlatform] == "linux-x64"} {
            xampptcl::util::substituteParametersInFile \
                [file join [srcdir] src osdep unix Makefile] \
                [list {BASECFLAGS="-g -fno-omit-frame-pointer $(GCCOPTLEVEL)"} \
                     {BASECFLAGS="-g -fno-omit-frame-pointer -fPIC $(GCCOPTLEVEL)"} \
                     {EXTRACFLAGS=} {EXTRACFLAGS=-fPIC}]
        }

        eval logexec echo y | [make] $makeTarget SSLTYPE=none
    }

    public method install {} {
    }

}

::itcl::class imapssl {
    inherit imap
    constructor {environment} {
        chain $environment
        set patchLevel 1
        set patchStrip 0
        set patchList {imap-2007f-openssl-1.1.patch}
    } {}
    public method build {} {
        cd [srcdir]
        xampptcl::util::substituteParametersInFile \
           [file join [srcdir] src osdep unix Makefile] \
           [list SSLDIR=/usr/local/ssl SSLDIR=$::opts(openssl.srcdir)]
        xampptcl::util::substituteParametersInFile \
           [file join [srcdir] src osdep unix Makefile] \
           [list {SSLLIB=$(SSLDIR)/lib} SSLLIB=$::opts(openssl.prefix)/lib]
	if {[string match osx-x64 [$be cget -target]]} {
	    set supportsParallelBuild 0
	    xampptcl::util::substituteParametersInFile \
		[file join [srcdir] Makefile] \
		[list {-DMAC_OSX_KLUDGE=1} {}]
	}

        if {[$be targetPlatform] == "linux-x64"} {
            xampptcl::util::substituteParametersInFile \
                [file join [srcdir] Makefile] \
                [list {EXTRACFLAGS=
} {EXTRACFLAGS=-fPIC
}]
        }

        if {$::tcl_platform(os) == "Darwin"} {
        xampptcl::util::substituteParametersInFile \
           [file join [srcdir] src osdep unix Makefile] \
           [list {-Wno-pointer-sign} {}]
	    if { [$be cget -target] == "osx-x64" } {
		xampptcl::util::substituteParametersInFile \
		    [file join [srcdir] src osdep unix Makefile] \
		    [list {GCCCFLAGS=} {GCCCFLAGS= -arch x86_64}]
	    }

        xampptcl::util::substituteParametersInFile \
           [file join [srcdir] Makefile] \
	    [list {SSLINCLUDE=/usr/include/openssl} SSLINCLUDE=$::opts(openssl.prefix)/include \
		 {SSLLIB=/usr/lib} SSLLIB=$::opts(openssl.prefix)/lib \
		 {SSLCERTS=/System/Library/OpenSSL/certs} SSLCERTS=$::opts(openssl.prefix)/openssl/certs \
		 {SSLKEYS=/System/Library/OpenSSL/private} SSLKEYS=$::opts(openssl.prefix)/openssl/private \
		 {GSSINCLUDE=/usr/include} GSSINCLUDE=$::opts(openssl.prefix)/include \
		 {GSSLIB=/usr/lib} GSSLIB=$::opts(openssl.prefix)/lib ]

        #Fuera kerberos.
        xampptcl::util::substituteParametersInFile \
           [file join [srcdir] Makefile] \
           [list {$(EXTRAAUTHENTICATORS) gss} {$(EXTRAAUTHENTICATORS)}]
        }

        set makeTarget slx

        if {$::tcl_platform(os) == "FreeBSD"} {
            set makeTarget bsf
        }

        if {$::tcl_platform(os) == "Darwin"} {
            set makeTarget oxp
        }

        if {$::tcl_platform(os) == "SunOS"} {
	    if {[$be targetPlatform] == "solaris-intel"} {
		xampptcl::util::substituteParametersInFile \
		    [file join [srcdir] src osdep unix Makefile] \
		    [list {CC=/opt/SUNWspro/bin/cc} {CC=/opt/bin/cc}]
		set makeTarget soc
	    } elseif {[$be targetPlatform] == "solaris-sparc"} {
		xampptcl::util::substituteParametersInFile \
		    [file join [srcdir] src osdep unix Makefile] \
		    [list {BASECFLAGS="-g -O -w"} {BASECFLAGS="-xO3 -Xa -xstrconst -mt -D_FORTEC_ -xarch=v9 -KPIC"} \
			 {BASELDFLAGS="-lsocket -lnsl -lgen"} {BASELDFLAGS="-lsocket -lnsl -lgen -xarch=v9"}]
                if {[eval {exec uname -r}]=="5.8"} {
		    xampptcl::util::substituteParametersInFile \
                        [file join [srcdir] src osdep unix Makefile] \
                        [list {CC=/opt/SUNWspro/bin/cc} {CC=/bitrock/SUNWspro/bin/cc}]
                } else {
		    xampptcl::util::substituteParametersInFile \
                        [file join [srcdir] src osdep unix Makefile] \
                        [list {CC=/opt/SUNWspro/bin/cc} {CC=/export/home/sunstudio12/SUNWspro/bin/cc}]
                }

		set makeTarget soc
	    }
        }

        eval logexec echo y | [make] $makeTarget SSLTYPE=unix
    }
}


::itcl::class libiconv {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libiconv
        set version 1.16
        set separator -
	set licenseRelativePath COPYING.LIB
     }
    public method setEnvironment {} {
        chain
        set ::opts(libiconv.dir) [prefix]
    }

    protected method configureOptions {} {
        return {}
    }
    public method preparefordist {} {
        foreach p {lib/libiconv_plug.so lib/libiconv.so.2.2.0} {
          strip [prefix]/$p
        }
    }
    public method build {} {
	if {[string match osx* [$be cget -target]] && [lindex [$this info heritage] 0] == [uplevel namespace current]} {
	    error "This component cannot be included in OS X stacks are it conflicts with the system libraries. Please use its native version 'libiconvOsxNative' instead"
	} else {
	    chain
	}
    }
    public method install {} {
        cd [srcdir]
        eval logexec [make] install-lib
        if [file exists [file join [prefix] bin iconv]] {
            file delete -force [file join [prefix] bin iconv]
        }
    }
}

::itcl::class libiconvOsxNative {
    inherit libiconv
    constructor {environment} {
	 chain $environment
    } {}

    public method setEnvironment {} {
        set ::opts(libiconv.dir) /usr
    }
    public method build {} {}
    public method copyLicense {} {}
    public method needsToBeBuilt {} {
	return 0
    }
    public method install {} {}
    public method extract {} {}

    public method configureOptions {} {
        return {}
    }
    public method preparefordist {} {}

}


::itcl::class pearprogram {
    inherit program
    protected variable moduleList
    public variable channel {}
    constructor {environment} {
        chain $environment
    } {
        set mainComponentXMLName php
        set isReportableAsMainComponent 0
    }
    public method build {} {
	file mkdir [file join [$be cget -output] pear]
    }
    public method install {} {
        if {$channel != ""} {
            set channelReg [findFile $channel.reg 0]
            if {[file exists $channelReg]} {
                message info "Copying  $channelReg to [file join $::opts(php.prefix)/lib/php/.channels]"
                file copy -force $channelReg [file join $::opts(php.prefix)/lib/php/.channels]
            } else {
                message info "Discovering $channel"
                catch {logexecIgnoreErrors $::opts(php.prefix)/bin/pear channel-discover $channel} kk
                puts $kk
            }
        }
	logexec $::opts(php.prefix)/bin/pear install --force [findTarball]
	return
        cd [srcdir]
        foreach {module root} $moduleList {
	    puts "Copying file copy -force $module $::opts(pear.prefix)/$root"
	    file copy -force $module $::opts(pear.prefix)/$root
	    file copy -force $module.php $::opts(pear.prefix)/$root
        }
    }
}

::itcl::class pearprogramWindows {
    inherit pearprogram
    public variable pearBatFileNameList {}
    constructor {environment} {
        chain $environment
    } {
        set mainComponentXMLName php
        set isReportableAsMainComponent 0
    }
    public method install {} {

        # substitutions for bat files
        set pearBatFileSubstitutions [list \
            @include_path@ @@XAMPP_PHP_ROOTDIR@@\\PEAR \
            @PHP-BIN@ @@XAMPP_PHP_ROOTDIR@@\\php.exe \
            @php_bin@ @@XAMPP_PHP_ROOTDIR@@\\php.exe \
            @PHP-DIR@ @@XAMPP_PHP_ROOTDIR@@ \
            @php_dir@ @@XAMPP_PHP_ROOTDIR@@ \
            @PEAR-DIR@ @@XAMPP_PHP_ROOTDIR@@\\PEAR \
            @pear_dir@ @@XAMPP_PHP_ROOTDIR@@\\PEAR \
            @BIN-DIR@ @@XAMPP_PHP_ROOTDIR@@ \
            @bin_dir@ @@XAMPP_PHP_ROOTDIR@@ \
            @DATA-DIR@ @@XAMPP_PHP_ROOTDIR@@\\PEAR\\data \
            @data_dir@ @@XAMPP_PHP_ROOTDIR@@\\PEAR\\data \
        ]
        set tarball [findTarball]
	puts [eval exec [join [list $::opts(pear.command) install $tarball]]]
        foreach {pearBatFileOrigin pearBatFileDestination} $pearBatFileNameList {
            file copy -force [xampptcl::util::recursiveGlob [srcdir] *$pearBatFileOrigin*] $::opts(php.prefix)/$pearBatFileDestination
            xampptcl::util::substituteParametersInFile $::opts(php.prefix)/$pearBatFileDestination $pearBatFileSubstitutions
        }
    }
    public method needsToBeBuilt {} {
        return 1
    }
    public method build {} {}
}

::itcl::class libmcrypt {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libmcrypt
        set version 2.5.8
        set licenseRelativePath COPYING.LIB
    }
    public method needsToBeBuilt {} {
	return 1
    }
    # Fix /usr/bin/ld: cannot find -lltdl
    public method build {} {
        if {$::tcl_platform(os) == "SunOS"} {
          xampptcl::util::substituteParametersInFile [file join [srcdir] configure] \
	    {{echo -n} {echo}}
          if {[$be targetPlatform] == "solaris-sparc"} {
	    if {[eval {exec uname -r}]=="5.8"} {
              xampptcl::util::substituteParametersInFile [file join [srcdir] configure] \
	        {{ac_ext=cc} {ac_ext=c}}
	    }
	  }
	}
        if { [$be cget -target] != "aix" } {
	    cd [file join [srcdir] libltdl]
            eval logexec ./configure --prefix=[prefix] --enable-ltdl-install
	    eval logexec [make] install
        }
	chain
    }
    public method setEnvironment {} {
        set ::opts(mcrypt.prefix) [prefix]
        set ::env(LIBMCRYPT_CONFIG) [prefix]/bin/libmcrypt-config
    }
}

::itcl::class libbzip2 {
   inherit library
    constructor {environment} {
        chain $environment
    } {
        set name bzip2
        set version 1.0.6
        set licenseRelativePath LICENSE
    }
    public method setEnvironment {} {
        set ::opts(bzip2.prefix) [prefix]
    }
    public method build {} {
        cd [srcdir]
        eval logexec [make] -f Makefile-libbz2_so
    }
    public method install {} {
        set libbz2File libbz2.so.$version
        if {[file exists [file join [srcdir] $libbz2File]]} {
            cd [file join [prefix] lib]
            file copy -force [file join [srcdir] $libbz2File] .
            # Create libbz2.so.A and libbz2.so.A.B from libbz2.so.A.B.C
            logexec ln -s $libbz2File [file rootname [file rootname $libbz2File]]
            logexec ln -s $libbz2File [file rootname $libbz2File]
        }
    }
}

::itcl::class bzip2 {
    inherit libbzip2
    constructor {environment} {
        chain $environment
    } {
    }
    public method build {} {}
    public method install {} {
        chain
        cd [srcdir]
        if {[$be cget -target] == "linux-x64"} {
            xampptcl::util::substituteParametersInFile [file join [srcdir] Makefile] \
                [list {CFLAGS=} {CFLAGS=-fPIC }]
        }
        eval logexec [make] install PREFIX=[prefix]
    }
    public method preparefordist {} {
        chain
        cd [$be cget -output]/common/bin
        foreach {s d} {bzcmp bzdiff bzegrep bzgrep bzfgrep bzgrep bzless bzmore} {
            file delete -force $s
            # T329 relative symlinks only works in recent Tcl versions
            eval logexec ln -s $d $s
        }
    }
}

