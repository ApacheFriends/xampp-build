::itcl::class imagemagick {
    inherit baseBitnamiProgram

    constructor {environment} {
        chain $environment
    } {
        set name imagemagick
        set fullname ImageMagick
        set dependencies {imagemagick {imagemagick.xml imagemagick-functions.xml imagemagick-properties.xml}}
        set moduleDependencies {imagemagick {imagemagick-functions.xml imagemagick-properties.xml}}
        set readmePlaceholder IMAGEMAGICK
        set mainComponentXMLName imagemagick
    }

    public method setEnvironment {} {
        set ::opts(imagemagick.prefix) [prefix]
    }
}

::itcl::class imagemagickWindows {
    inherit imagemagick

    constructor {environment} {
        chain $environment
    } {
        set version 7.0.7-11
	# It requires to build rmagick gem
        set name imagemagick
        set licenseRelativePath LICENSE
    }
    public method getTarballName {} {
            return ImageMagick-${version}-vc15-x64
    }
    public method srcdir {} {
        return [file join [$be cget -src] ${name}]
    }
    # For this specific version of imagemagick (6.5.3-10-Q8) we need to include the vc++2008 dlls and manifest
    # with this, we don't need to require the user to have installed vc++ 2008 runtime.
    public method extract {} {
        set t [findTarball]
        file mkdir [srcdir]
        unzipFile $t [srcdir]
    }
    public method build {} {}
    public method install {} {
        file copy [srcdir] [$be cget -output]
    }
    public method preparefordist {} {
         xampptcl::file::write [file join [$be cget -output] imagemagick bin convert.bat] {
@ECHO OFF
CALL "@@XAMPP_INSTALLDIR@@\scripts\setenv.bat"
start "" convert %*
}
     }

}

::itcl::class imagemagickLinux {
    inherit imagemagick
    constructor {environment} {
        chain $environment
    } {
        set tarballName ImageMagick-6.9.8-3
        set version 6.9.8
        set supportsParallelBuild 0
        set licenseRelativePath LICENSE
        set licenseNotes {ImageMagick License: Allows you to use ImageMagick software in packages or distributions that you create. http://www.imagemagick.org/script/license.php}
    }
    public method build {} {
        if {[$be cget -target] == "osx-x64" && [info exists ::env(DYLD_LIBRARY_PATH)]} {
            set oldDYLD $::env(DYLD_LIBRARY_PATH)
            unset ::env(DYLD_LIBRARY_PATH)
        }
        # in order to compile new versions in old chroots:
        # http://www.imagemagick.org/discourse-server/viewtopic.php?t=25866
        # http://stackoverflow.com/questions/24768622/imagemagick-pthread-h-multiple-definition
        set old_cflags $::env(CFLAGS)
        set ::env(CFLAGS) "-std=gnu89 $::env(CFLAGS)"
        chain
        set ::env(CFLAGS) $old_cflags
        if {[$be cget -target] == "osx-x64" && [info exists oldDYLD]} {
            set ::env(DYLD_LIBRARY_PATH) $oldDYLD
        }
    }
    public method srcdir {} {
        # ImageMagick tarballs do not always follow standard structure
        # We detect the name of the extracted folder in the tarball in order
        # to avoid the need to overwrite the method for each new version
        set ImageMagick [file join [$be cget -src] [lindex [exec tar -tzf [findTarball]] 0]]
        return ${ImageMagick}
    }

    # disable openmp dps and X option when compiling imagemagick
    public method configureOptions {} {
        return [list --with-perl=no --with-jpeg=yes --disable-openmp --disable-opencl --without-dps --without-x --with-modules --with-wmf]
    }
    public method install {} {
        chain
        if {[$be cget -target] == "osx-x64"} {
            set fileList [glob [file join [prefix] lib libMagickWand-*.dylib]]
            foreach f $fileList {
                file copy -force $f [file join [prefix] lib libMagickWand.dylib]
            }
            set fileList [glob [file join [prefix] lib libMagickCore-*.dylib]]
            foreach f $fileList {
                file copy -force $f [file join [prefix] lib libMagickCore.dylib]
            }
        } else {
            set fileList [glob [file join [prefix] lib libMagickWand-*.so]]
            foreach f $fileList {
                file copy -force $f [file join [prefix] lib libMagickWand.so]
            }
            set fileList [glob [file join [prefix] lib libMagickCore-*.so]]
            foreach f $fileList {
                file copy -force $f [file join [prefix] lib libMagickCore.so]
            }
        }
    }
    public method prefix {} {
        return [file join [$be cget -output] ImageMagick]
    }
    public method preparefordist {} {
            set fileList {
                bin animate
                bin compare
                bin composite
                bin conjure
                bin convert
                bin display
                bin identify
                bin import
                bin mogrify
                bin montage
                bin stream
            }
            foreach {d f} $fileList {
                prepareWrapper [file join [prefix] $d $f] IMAGEMAGICK
            }
	set fileList [concat [glob [file join [prefix] lib ImageMagick* config* *]] [glob [file join [prefix] lib *.la]] [glob [file join [prefix] lib ImageMagick* modules* coders *.la]] [glob [file join [prefix] lib ImageMagick* modules* filters *.la]]  [glob [file join [prefix] lib pkgconfig *.pc]] [glob [file join [prefix] include ImageMagick* *agick* *.h]] [glob -nocomplain [file join [prefix] include ImageMagick* *.h]] [glob [file join [prefix] share man man1 *.1]] [glob [file join [prefix] bin *-config]]]
        foreach f $fileList {
	    if {![isBinaryFile $f] && ![file isdirectory $f] && [file type $f] != "link"} {
		xampptcl::util::substituteParametersInFile $f \
		    [list [prefix] @@XAMPP_IMAGEMAGICK_ROOTDIR@@ [file join [$be cget -output] [$be cget -libprefix]] @@XAMPP_COMMON_ROOTDIR@@]
	    }
        }
        set fileList [glob [file join [srcdir] www source *.xml]]
        foreach f $fileList {
            file copy -force $f [glob [file join [prefix] lib ImageMagick* config*]]
        }
    }
    public method prepareXmlFiles {} {
        regexp {^ImageMagick-(.*)} [file tail [glob [file join [prefix] lib ImageMagick*]]] match bitrock_imagemagick_version
        xampptcl::util::substituteParametersInFile [file join [$be cget -output] imagemagick.xml] \
            [list @@XAMPP_IMAGEMAGICK_VERSION@@ $bitrock_imagemagick_version ]
    }
}

::itcl::class imagemagickLinux7 {
    inherit imagemagickLinux
    constructor {environment} {
        chain $environment
    }  {
        set tarballName ImageMagick-7.0.5-2
        set version 7.0.5
        set supportsParallelBuild 0
        set licenseRelativePath LICENSE
        set licenseNotes {ImageMagick License: Allows you to use ImageMagick software in packages or distributions that you create. http://www.imagemagick.org/script/license.php}
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        callConfigure
        eval logexec [make]
    }
}

