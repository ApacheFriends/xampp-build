
declareClass automake -parentClass builddependency -version 1.9.5
declareClass make -parentClass builddependency -version 3.80
declareClass autoconf -parentClass builddependency -version 2.68
declareClass bisonBuild -parentClass builddependency -name bison -version 1.28
declareClass groff -parentClass builddependency -version 1.21
declareClass xz -parentClass library -version 5.2.1
declareClass yaml -parentClass library -version 0.1.5 -licenseRelativePath LICENSE
declareClass gperf -parentClass builddependency -name gperf -version 3.0.4
declareClass byacc -parentClass builddependency -version 20190617
declareClass binutils -parentClass builddependency -version 2.25
declareClass libuuid -parentClass library -name libuuid -version 1.0.3
declareClass lcms -parentClass library -version 1.18
declareClass openexr -parentClass library -version 2.2.0
declareClass libwebp -parentClass library -version 0.6.0
declareClass ilmbase -parentClass library -version 2.2.0
declareClass flex -parentClass library -name flex -version 2.6.4
declareClass harfbuzz -parentClass library -name harfbuzz -version 1.6.0
declareClass libpcap -parentClass library -name libpcap -version 1.9.0 -licenseRelativePath LICENSE

::itcl::class gdbm {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name gdbm
        set version 1.8.3
        set licenseRelativePath COPYING
    }
    public method setEnvironment {} {
        set ::opts(gdbm.prefix) [prefix]
    }
    public method install {} {
        if { [$be cget -target] == "osx-x64" } {
            # From Mac Ports
            xampptcl::util::substituteParametersInFile [file join [srcdir] Makefile] \
                [list {BINOWN = bin} {BINOWN = root} {BINGRP = bin} {BINGRP = wheel}]
        }
        chain
    }
}

::itcl::class bison {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name bison
        set version 2.1
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        callConfigure
        xampptcl::util::substituteParametersInFile Makefile [list examples {}]
        eval logexec [make]
    }
}

::itcl::class pkg-config {
    inherit library
    private variable oldPython
    constructor {environment} {
	chain $environment
    } {
        set name pkg-config
        set version 0.28
        set supportsParallelBuild 0
    }
    protected method configureOptions {} {
        set list [chain]
        lappend list --with-internal-glib
        return $list
    }
    public method callConfigure {} {
        if {[info exists ::env(PYTHON)]} {
            set oldPython $::env(PYTHON)
            unset ::env(PYTHON)
        }
        chain
    }
    public method install {} {
        chain
        if { [info exists oldPython]  } {
            set ::env(PYTHON) $oldPython
        }
    }
    public method setEnvironment {} {
        set ::env(PATH) $::env(PATH):[srcdir]
    }
    public method preparefordist {} {
        set substituteFileList [::xampptcl::util::recursiveGlob [prefix] lib pkgconfig *.pc]
        foreach f $substituteFileList {
            xampptcl::util::substituteParametersInFile $f \
                [list [prefix] @@XAMPP_COMMON_ROOTDIR@@]
        }
    }
}

::itcl::class pkg-configBuildDependency {
    inherit builddependency
    private variable oldPython
    constructor {environment} {
	chain $environment
    } {
        set name pkg-config
        set version 0.28
        set supportsParallelBuild 0
    }
    protected method configureOptions {} {
        set list [chain]
        lappend list --with-internal-glib
        return $list
    }
    public method callConfigure {} {
        if {[info exists ::env(PYTHON)]} {
            set oldPython $::env(PYTHON)
            unset ::env(PYTHON)
        }
        chain
    }
    public method install {} {
        chain
        if { [info exists oldPython]  } {
            set ::env(PYTHON) $oldPython
        }
    }
    public method setEnvironment {} {
        set ::env(PATH) $::env(PATH):[srcdir]
    }
}

declareClass pkgconfig -parentClass pkg-config -name pkg-config -version 0.28 -licenseRelativePath COPYING
declareClass pkgconfigBuildDependency -parentClass pkg-configBuildDependency -name pkg-config -version 0.28

::itcl::class zip {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name zip
        set version 3.0.0
        set tarballName zip30
        set licenseRelativePath LICENSE
    }
    public method srcdir {} {
        return [file join [$be cget -src] $tarballName]
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        xampptcl::util::substituteParametersInFile [file join [srcdir] unix Makefile] \
            [list "prefix = /usr/local" [concat "prefix = " [prefix]]]
        eval logexec [make] -f unix/Makefile generic_gcc
    }
    public method install {} {
        cd [srcdir]
        eval logexec [make] -f unix/Makefile install
    }
}

::itcl::class unzip {
    inherit zip
    constructor {environment} {
        chain $environment
    } {
        set name unzip
        set version 6.0.0
        set tarballName unzip60
    }
}

::itcl::class apr {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name apr
        set version 1.6.2
        set licenseRelativePath LICENSE
    }
    public method callConfigure {} {
        eval [list logexecEnv [list CONFIG_SHELL /bin/bash] ./configure --prefix=[prefix]] [configureOptions]
    }
    public method build {} {
        set oldLDflags {}
        catch {set oldLDflags $::env(LDFLAGS)}
        set ::env(LDFLAGS) "$::env(LDFLAGS) -ldl"
        chain
        set ::env(LDFLAGS) $oldLDflags
    }
}

::itcl::class aprutil {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name apr-util
        set version 1.6.0
        set licenseRelativePath LICENSE
    }

    public method setEnvironment {} {
        set ::env(PATH) [prefix]/bin:$::env(PATH)
    }
    protected method configureOptions {} {
        set options [list --with-expat=[prefix] --with-apr=[prefix]]
        if {[info exists ::opts(openldap.prefix)]} {
            lappend options --with-ldap-include=$::opts(openldap.prefix)/include --with-ldap-lib=$::opts(openldap.prefix)//lib --with-ldap
        }
        if {[info exists ::opts(mysql.prefix)]} {
            lappend options --with-mysql=$::opts(mysql.prefix)
        }
        if {[info exists ::opts(postgresql.prefix)]} {
            lappend options --with-pgsql=$::opts(postgresql.prefix)
        }
        return $options
    }
}

::itcl::class libtool {
    inherit builddependency
    constructor {environment} {
        chain $environment
    } {
        set name libtool
        set version 1.5.8
    }
    public method setEnvironment {} {
        set ::opts(libtool.prefix) [prefix]
        if {![info exists ::env(ACLOCAL_FLAGS)]} {
            set ::env(ACLOCAL_FLAGS) ""
        }
        append ::env(ACLOCAL_FLAGS) " -I [prefix]/share/aclocal"
        chain
    }
    public method install {} {
        chain
        set automakeAclocal [glob -nocomplain [$be cget -builddep]/automake-*/share/aclocal-*/]
        if [file exists $automakeAclocal] {
            foreach f [glob -nocomplain [prefix]/share/aclocal/*] {
                file copy -force $f $automakeAclocal
            }
        }
    }
}

::itcl::class libtool2 {
    inherit libtool
    constructor {environment} {
        chain $environment
    } {
        set version 2.2.2
    }
    public method setEnvironment {} {
        set ::opts(libtool2.prefix) [prefix]
    }
    public method build {} {
        # See issue: http://stackoverflow.com/questions/9659972/compiling-libgdiplus-2-10-9-on-centos5-for-mono
        set ::env(echo) echo
        chain
    }
}

::itcl::class libltdl {
    inherit libtool
    constructor {environment} {
        chain $environment
    } {}
    public method configureOptions {} {
        return [list --libdir=[file join [$be cget -output] [$be cget -libprefix] lib] --includedir=[file join [$be cget -output] [$be cget -libprefix] include]]
    }
    public method install {} {
        # the catch is because in custom stacks (alfresco) there is not such lib dir
        if {[file exists [$be cget -output]/[$be cget -libprefix]/lib/]} {
           if {[$be cget -target] == "osx-x64"} {
               eval logexec cp -fr [glob  [srcdir]/libltdl/.libs/libltdl*.dylib]  [$be cget -output]/[$be cget -libprefix]/lib/
           } else {
               eval logexec cp -fr [glob  [srcdir]/libltdl/.libs/libltdl.so*]  [$be cget -output]/[$be cget -libprefix]/lib/
           }
        }
        chain
    }
}

::itcl::class cmake {
    inherit builddependency
    constructor {environment} {
        chain $environment
    } {
        set name cmake
        set version 3.13.0
    }
    public method setEnvironment {} {
	chain
	#To avoid the error below in OS-X 10.0
	#    CMAKE_OSX_DEPLOYMENT_TARGET is '10.5' but CMAKE_OSX_SYSROOT:
	#    ""
	#    is not set to a MacOSX SDK with a recognized version.  Either set
	#    CMAKE_OSX_SYSROOT to a valid SDK or set CMAKE_OSX_DEPLOYMENT_TARGET to empty.
	if {[$be cget -target] == "osx-x64" && [::xampptcl::util::compareVersions $version 3.0] > 0} {
	    unset -nocomplain ::env(MACOSX_DEPLOYMENT_TARGET)
	}
    }
    public method build {} {
	if {[$be cget -target] == "osx-x64" && [::xampptcl::util::compareVersions $version 3.0] > 0} {
	    set ::env(MACOSX_DEPLOYMENT_TARGET) ""
	}
	cd [srcdir]
        file rename -force Source/CursesDialog/CMakeLists.txt Source/CursesDialog/CMakeLists.txt.bak
        exec touch Source/CursesDialog/CMakeLists.txt
        file rename -force Source/CursesDialog/form/CMakeLists.txt  Source/CursesDialog/form/CMakeLists.txt.bak
        exec touch Source/CursesDialog/form/CMakeLists.txt
        chain
	if {[$be cget -target] == "osx-x64" && [::xampptcl::util::compareVersions $version 3.0] > 0} {
	    unset ::env(MACOSX_DEPLOYMENT_TARGET)
        }
    }
    public method install {} {
        if {[$be cget -target] == "osx-x64"} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        chain
        if {[$be cget -target] == "osx-x64"} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
}

::itcl::class wrappedCmake {
    inherit cmake
    constructor {environment} {
        chain $environment
    } {
    }
    public method install {} {
        chain
        # Ref T1498 D535 Fix rugged issue with not found symbols
        if {[$be cget -target] == "linux"} {
            set cmakeBinary [file join [prefix] bin cmake]
            if {[isBinaryFile $cmakeBinary]} {
                file rename -force $cmakeBinary $cmakeBinary.orig
                xampptcl::file::write $cmakeBinary {#!/bin/bash
args=()
dir=`cd $(dirname $0) && pwd`
if [[ $1 != -* ]]
then
if [[ "$*" == *-DCMAKE_C_FLAGS=* ]]
then
  args=""
  for var in "$@"
  do
    if [[ "$var" == -DCMAKE_C_FLAGS=* ]]
    then
      val=${var/-DCMAKE_C_FLAGS=/}
      val=${val%[\"\']}
      val=${val#[\"\']}
      val="-DCMAKE_C_FLAGS='-march=i486 $val'"
      args=("${args[@]}" "$val")
    else
       args=("${args[@]}" "$var")
    fi
  done
else
  args=($@ "-DCMAKE_C_FLAGS='-march=i486'")
fi
exec $dir/cmake.orig "${args[@]}"
else
exec $dir/cmake.orig "$@"
fi
}
           file attributes $cmakeBinary -permissions 0755
          }
       }
    }
}

::itcl::class libaio {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libaio
        set version 0.3.107
        set tarballName libaio_0.3.107.orig
    }
    public method build {} {}
    public method install {} {
        if {[string match linux* [$be cget -target]]} {
            cd [srcdir]
            eval logexec [make] prefix=[prefix] install
        }
    }
}

::itcl::class libxslt {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libxslt
        set version 1.1.33
        set licenseRelativePath Copyright
    }
    public method setEnvironment {} {
        set ::opts(libxslt.prefix) [prefix]
    }
    public method configureOptions {} {
        return [linsert [chain] end --without-python --with-libxml-prefix=$::opts(libxml2.prefix)]
    }
    public method build {} {
	if {[string match osx* [$be cget -target]] && [lindex [$this info heritage] 0] == [uplevel namespace current]} {
	    error "This component cannot be included in OS X stacks are it conflicts with the system libraries. Please use its native version 'libxsltOsxNative' instead"
	} else {
	    chain
	}
    }

    public method preparefordist {} {
	chain
	prepareWrapper [file join [prefix] bin xsltproc] COMMON
    }
}
::itcl::class libxsltOsxNative {
    inherit libxslt
    constructor {environment} {
	 chain $environment
    } {}

    public method setEnvironment {} {
        set ::opts(libxslt.prefix) /usr
        set ::env(XSL_LIBS) "-L$::opts(libxslt.prefix)/lib -lxslt"
        set ::env(XSL_CFLAGS) "-I$::opts(libxslt.prefix)/include/libxslt"
    }
    public method copyLicense {} {}
    public method needsToBeBuilt {} {
	return 0
    }
    public method build {} {}
    public method install {} {}
    public method extract {} {}

    public method configureOptions {} {
        return {}
    }
    public method preparefordist {} {}
}

::itcl::class ncurses {
    inherit library

    constructor {environment} {
        chain $environment
    } {
        set name ncurses
        set version 5.9
        set supportsParallelBuild 0
        set licenseRelativePath ANNOUNCE
        set licenseNotes http://www.gnu.org/software/ncurses/ncurses.html
    }

    public method setEnvironment {} {
        set ::opts(ncurses.prefix) [prefix]
        set ::env(PATH) $::opts(ncurses.prefix)/bin:$::env(PATH)
    }
    public method needsToBeBuilt {} {
        return 1
    }
    public method configureOptions {} {
        return [list --without-cxx --without-cxx-binding --without-ada ]
    }
    public method build {} {
       set defaultCppFlags $::env(CPPFLAGS)
       set ::env(CPPFLAGS) "-I[srcdir]/include $defaultCppFlags"
       chain
       set ::env(CPPFLAGS) $defaultCppFlags
    }
    public method preparefordist {} {
    file delete -force [file join [prefix] bin clear]
    }
}

::itcl::class icu4c {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name icu4c
        set version [versions::get "ICU4C" stable]
        set supportsParallelBuild 0
        set licenseRelativePath ../license.html
        set licenseNotes http://source.icu-project.org/repos/icu/icu/trunk/license.html
    }
   public method setEnvironment {} {
       set ::opts(icu.prefix) [prefix]
   }
    public method getTarballName {} {
        set version [string map {. _} $version]
        return $name-$version-src
    }
    public method download {} {
        set downloadType wget
        set folderAtThirdparty [$be cget -tarballs]/$name
        set version [getVtrackerField $name version infrastructure]
        set tarballVersion [string map {. _} $version]
        set urlVersion [string map {. -} $version]
        set downloadUrl https://github.com/unicode-org/icu/releases/download/release-$urlVersion/$name-$tarballVersion-src.tgz
        chain
    }
    public method srcdir {} {
       return [$be cget -src]/icu/source
    }
    public method callConfigure {} {
        if { [string match solaris-intel [$be cget -target]] } {
            eval [list logexec ./runConfigureICU SolarisX86 --prefix=[prefix]] [configureOptions]
        } elseif { [string match solaris-sparc [$be cget -target]] } {
            eval [list logexec ./runConfigureICU Solaris --prefix=[prefix]] [configureOptions]
        } else {
            chain
        }
    }
    public method build {} {
        if { [string match osx* [$be cget -target]] } {
            xampptcl::util::substituteParametersInFile [srcdir]/common/uassert.h \
            [list {define U_ASSERT(exp) void()} {define U_ASSERT(exp) (void)0}]
        }
        if {[::xampptcl::util::compareVersions $version 67] >= 0 && [$be cget -target] == "linux-x64"} {
            useGCC49Env
        }
        chain
        if {[::xampptcl::util::compareVersions $version 67] >= 0 && [$be cget -target] == "linux-x64"} {
            unuseGCC49Env
        }
    }
    public method preparefordist {} {
        xampptcl::util::substituteParametersInFile [prefix]/bin/icu-config \
            [list [prefix] @@XAMPP_COMMON_ROOTDIR@@]
    }
}

# Do not install libstc++ in the systems where already exists
# Do not use a gcc compiler different than the current gcc in the chroot
declareClass gcc -parentClass builddependency -name gcc -version 3.3

::itcl::class gcc34 {
    inherit gcc
    constructor {environment} {
        chain $environment
    } {
        set version 3.4.6
	set supportsParallelBuild 0
    }

    public method cleanUp {} {
        file delete -force [prefix]
    }

    public method configureOptions {} {
       if { [string match linux-x64 [$be cget -target]] } {
           return [list --enable-languages=c,c++ --disable-multilib --without-libiberty]
       }
    }
    public method srcdir {} {
        return [$be cget -src]/$name-$version-build
    }
    protected method srcorigdir {} {
        return [$be cget -src]/$name-$version
    }
    public method callConfigure {} {
        eval [list logexec [srcorigdir]/configure --prefix=[prefix]] [configureOptions]
    }
    public method build {} {
        file mkdir [srcdir]
        chain
    }
    public method setEnvironment {} {
        chain
        set ::env(PATH) [prefix]/bin:$::env(PATH)
        if { [string match linux-x64 [$be cget -target]] } {
            set ::env(LD_LIBRARY_PATH) [prefix]/lib64:$::env(LD_LIBRARY_PATH)
        } else {
            set ::env(LD_LIBRARY_PATH) [prefix]/lib:$::env(LD_LIBRARY_PATH)
        }
    }
    public method install {} {
        if [file exists [glob -nocomplain [$be cget -builddep]/gcc-*]] {
            file delete -force [glob -nocomplain [$be cget -builddep]/gcc-*]
        }
        chain
    }
}

::itcl::class gcc4 {
    inherit gcc34
    constructor {environment} {
        set name gcc
        chain $environment
    } {
	set version 4.2.2
    }

    protected method configureOptions {} {
	return [concat [chain] [list --disable-libgcj]]
    }
}

# This class in a wrapper in order to pack libgfortran and libquadmath
# When we use a system gcc (like in centos7 chroot) this libs are not added
# Formerly they are adde in gcc43 and subsequents
::itcl::class gccSystemLibs {
    inherit builddependency
    constructor {environment} {
        set name gccSystemLibs
        chain $environment
    } {
       set version 1.0.0
    }
    public method findTarball {{tarball {}}} {
    }
    public method extract {} {
    }
    public method needsToBeBuilt {} {
        return 0
    }
    public method install {} {
        if {[string match linux* [$be cget -target]]} {
            foreach f [concat [glob -nocomplain /usr/lib*/libgfortran.so*] [glob -nocomplain /usr/lib*/libquadmath.so*]] {
                file copy -force $f [file join [$be cget -output] common lib]
            }
        }
    }
}

::itcl::class gcc43 {
    inherit gcc34
    constructor {environment} {
        set name gcc
        chain $environment
    } {
       set version 4.3.0
       set supportsParallelBuild 0
    }

    protected method configureOptions {} {
        return [concat [chain] [list --disable-libgcj --with-gmp=[file join [$be cget -output] [$be cget -libprefix]] --with-mpfr=[file join [$be cget -output] [$be cget -libprefix]] --disable-libssp]]
    }

    public method preparefordist {} {
        chain
        if {[string match linux* [$be cget -target]]} {
            foreach f [concat [glob -nocomplain [$be cget -builddep]/gcc-*/lib*/libgfortran.so*] [glob -nocomplain [$be cget -builddep]/gcc-*/lib*/libquadmath.so*]] {
                file copy -force $f [file join [$be cget -output] common lib]
            }
        }
    }
}


::itcl::class gcc45 {
    inherit gcc43
    constructor {environment} {
        set name gcc
        chain $environment
    } {
        set version 4.5.0
        set supportsParallelBuild 1
    }
    public method setEnvironment {} {
        chain
        if { [string match linux [$be cget -target]] } {
            set ::env(LD_LIBRARY_PATH) [prefix]/lib:$::env(LD_LIBRARY_PATH)
        } elseif { [string match linux-x64 [$be cget -target]] } {
            set ::env(LD_LIBRARY_PATH) [prefix]/lib64:$::env(LD_LIBRARY_PATH)
        } elseif { [string match osx* [$be cget -target]] } {
            set ::env(DYLD_LIBRARY_PATH) [prefix]/lib:$::env(DYLD_LIBRARY_PATH)
        }
    }
    protected method configureOptions {} {
        return [concat [chain] [list --with-mpc=[file join [$be cget -output] [$be cget -libprefix]]]]
    }
}

::itcl::class gcc49 {
    inherit gcc45
    constructor {environment} {
        set name gcc
        chain $environment
    } {
        set version 4.9.2
        set supportsParallelBuild 1
    }
    public method setEnvironment {} {
        set ::env(GCC49_BIN) [prefix]/bin
        if { [string match linux [$be cget -target]] } {
            set ::env(GCC49_LIB) [prefix]/lib
        } elseif { [string match linux-x64 [$be cget -target]] } {
            set ::env(GCC49_LIB64) [prefix]/lib64
        } elseif { [string match osx* [$be cget -target]] } {
            set ::env(GCC49_LIB) [prefix]/lib
            set ::env(GCC49_OUTPUT) [file join [$be cget -output] [$be cget -libprefix]]
        }

        if {[[$be cget -product] cget -isGcc49MainGcc] == 1} {
            #  Load the GCC 49 environment only if we are compiling the whole product with this gcc version
            useGCC49Env
        }
    }
    protected method configureOptions {} {
        if { [string match linux* [$be cget -target]] } {
            set options [concat [chain] [list --disable-multilib --enable-languages=c,c++,fortran]]

        } elseif { [string match osx-x64 [$be cget -target]] } {
            set options [concat [chain] [list --disable-multilib --disable-libsanitizer --enable-languages=c,c++,fortran]]
        }
        return $options
    }
    public method build {} {
        set oldCPPflags {}
        catch {set oldCPPflags $::env(CPPFLAGS)}
        set ::env(CPPFLAGS) "-I[srcorigdir]/include $::env(CPPFLAGS)"
        chain
        set ::env(CPPFLAGS) $oldCPPflags
    }
    public method install {} {
        chain
        if { [string match osx* [$be cget -target]] } {
            file mkdir [file join [$be cget -output] common fallback lib]
            file copy -force [$be cget -builddep]/gcc-$version/lib/libgcc_s.1.dylib [file join [$be cget -output] common fallback lib]
            file copy -force [$be cget -builddep]/gcc-$version/lib/libstdc++.6.dylib [file join [$be cget -output] common fallback lib]
        }
    }
}

::itcl::class gcc8 {
    inherit gcc49
    constructor {environment} {
        set name gcc
        chain ${environment}
    } {
        set version 8.2.0
        set supportsParallelBuild 1
    }
    protected method configureOptions {} {
        if { [string match linux* [$be cget -target]] } {
            set options [concat [chain] [list --with-default-libstdcxx-abi=gcc4-compatible --disable-libstdcxx-dual-abi]]
            set options [xampptcl::util::listRemove $options --without-libiberty]
        } else {
            set options [chain]
        }
        return $options
    }
    public method setEnvironment {} {
        set ::env(GCC8_BIN) "[prefix]/bin"

        if {[string equal "linux-x64" [${be} cget -target]]} {
            set ::env(GCC8_LIB64) "[prefix]/lib64"
        } else {
            message warning "Not setting GCC 8 environment for unknown platform"
        }

        if {[[${be} cget -product] cget -isGcc8MainGcc] == 1} {
            # Load the GCC 8 environment only if we are compiling the whole product with this GCC version
            useGcc8Env
        }
    }

    public method install {} {
        chain
        if {[string match "linux-x64" [${be} cget -target]]} {
            set fallbackLib64Directory [file join [${be} cget -output] common fallback lib64]
            set builddepLib64Dir [file join [${be} cget -builddep] "gcc-${version}" lib64]
            file mkdir ${fallbackLib64Directory}
            file copy -force [file join ${builddepLib64Dir} libgcc_s.so.1] ${fallbackLib64Directory}
            file copy -force [file join ${builddepLib64Dir} libstdc++.so.6.0.25] ${fallbackLib64Directory}
        }
    }
}

::itcl::class tiff {
    inherit library
    constructor {environment} {
	chain $environment
    } {
	set name tiff
	set version 4.2.0
	set licenseRelativePath COPYRIGHT
	set licenseNotes http://www.libtiff.org/misc.html
    }
    protected method configureOptions {} {
        return [list --disable-cxx]
    }
}

::itcl::class libffi {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libffi
        set version 3.2.1
        set licenseRelativePath {}
    }
    public method callConfigure {} {
        xampptcl::util::substituteParametersInFile [file join [srcdir] Makefile.in] [list {toolexeclibdir = @toolexeclibdir@} {toolexeclibdir = ${libdir}}] 1

        xampptcl::util::substituteParametersInFile [file join [srcdir] libffi.pc.in] [list {includedir=${libdir}/@PACKAGE_NAME@-@PACKAGE_VERSION@/include} {
includedir=${prefix}/include
includesdir = ${includedir}}] 1

        foreach f [list Makefile.am Makefile.in] {
            xampptcl::util::substituteParametersInFile [file join [srcdir] include $f] [list {includesdir = $(libdir)/@PACKAGE_NAME@-@PACKAGE_VERSION@/include} {includesdir = ${includedir}}] 1
        }

        chain
    }
}

::itcl::class freetds {
    inherit library
    constructor {environment} {
	chain $environment
    } {
        set name freetds
        set version 1.1.12
    }
    public method setEnvironment {} {
        chain
        set ::opts(freetds.prefix) [prefix]
    }
    public method install {} {
        cd [srcdir]
        eval logexec make install
    }
    protected method configureOptions {} {
        return [linsert [chain] end --enable-msdblib --with-openssl=$::opts(openssl.prefix)]
    }
    public method preparefordist {} {
        prepareWrapper [file join [prefix] bin tsql] COMMON
        xampptcl::util::substituteParametersInFileRegex [file join [prefix] etc freetds.conf] \
            [list  {text size = [^\n]*} {#text size = 20971520}] 1
    }
}

::itcl::class libzip {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name libzip
        set version 1.5.1
        set licenseRelativePath LICENSE
    }
    public method install {} {
        if { [$be cget -target] == "osx-x64"} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        cd [srcdir]
        file mkdir [srcdir]/build
        cd [srcdir]/build
        eval logexec [make] install
        if {[$be cget -target] == "osx-x64"} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
    public method build {} {
        if { [$be cget -target] == "osx-x64"} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        cd [srcdir]
        file mkdir [srcdir]/build
        cd [srcdir]/build
        eval logexec cmake .. -DCMAKE_INSTALL_PREFIX=[prefix] -DCMAKE_INSTALL_LIBDIR=lib
        eval logexec [make]
        if {[$be cget -target] == "osx-x64"} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
}

::itcl::class oniguruma {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name onig
        set version 6.9.4
    }
}

::itcl::class m4 {
    inherit builddependency
    constructor {environment} {
        chain $environment
    } {
        set name m4
        set version 1.4.11
    }
    public method setEnvironment {} {
        set ::opts(m4.prefix) [prefix]
    }
}

::itcl::class pcre {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name pcre
        set version 8.40
        set supportsParallelBuild 0
        set licenseRelativePath LICENCE
    }
    public method setEnvironment {} {
        set ::opts(pcre.prefix) [prefix]
        set ::opts(pcre.dir) [prefix]
        set ::opts(pcre.srcdir) [srcdir]
    }

    public method configureOptions {} {
        return [list --disable-libtool-lock --disable-cpp --enable-utf --enable-unicode-properties]
    }
}

::itcl::class freetype {
    inherit library
    constructor {environment} {
        chain $environment
    } {
        set name freetype
        set version 2.4.8
        set supportsParallelBuild 0
        set licenseRelativePath docs/LICENSE.TXT
    }
    public method setEnvironment {} {
        set ::opts(freetype.prefix) [prefix]
        set ::env(PATH) $::opts(freetype.prefix)/bin:$::env(PATH)
    }
    public method configureOptions {} {}
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        callConfigure
        cd builds/unix
        # It is necessary to configure the prefix
        callConfigure
        cd [srcdir]
        eval logexec [make]
    }
    public method preparefordist {} {
    }
}
