# You need to add common/instantclient/ to LD_LIBRARY_PATH
::itcl::class oracleInstantclientLib {
    inherit library
    constructor {environment} {
        chain $environment
    } {
	set name instantclient
        set version 10.1.0.5-20060511
        set supportsParallelBuild 0
	set tarballName instantclient-basic-linux32-${version}
    } 
    public method setEnvironment {} {
	chain
        set ::opts(instantclient.prefix) [prefix]
        set ::opts(instantclient.srcdir) [srcdir]        
    }
    public method prefix {} {
        return [file join [$be cget -output] [$be cget -libprefix] $name]
    }
    public method build {} {}
    public method srcdir {} {
        return [$be cget -src]/instantclient10_1
    }    
    public method extract {} {
        chain
        set sdk [findTarball]
        set sdk [file join [file dirname $sdk] [string map {-basic- -sdk-} $tarballName]]
        cd [$be cget -src]
        logexec unzip -qo $sdk
    }
    public method install {} {
	file copy -force [srcdir] [prefix]
	cd [prefix]
        set majorVersion [lindex [split $version .] 0]
	logexec ln -s libclntsh.so.$majorVersion.1 libclntsh.so
	logexec ln -s libocci.so.$majorVersion.1 libocci.so
    }
}

::itcl::class oracle-instantclient {
    inherit baseBitnamiProgram

    constructor {environment} {
        chain $environment
    } {
        set name instantclient
        set version 11.2.0.1.0
        set dependencies {oracle {oracle-instantclient.xml}}
        set tarballName instantclient-basic-linux32-11.2.0.1
        if { [$be cget -target] == "windows" } {
            set tarballName instantclient-basic-win32-$version
        }
    }

    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base oracle]
    }

    public method setEnvironment {} {
        set ::opts(instantclient.prefix) [prefix]
        set ::opts(instantclient.srcdir) [srcdir]
        chain
    }

    public method build {} {}
    public method srcdir {} {
        return [$be cget -src]/instantclient_11_2
    }

    public method extract {} {
        chain
        set sdk [findTarball]
        set sdk [file join [file dirname $sdk] [string map {-basic- -sdk-} $tarballName]]
        cd [$be cget -src]
        logexec unzip -qo $sdk
    }

    public method install {} {
        file copy -force [srcdir] [prefix]
	if { [$be cget -target] != "windows" } {
	    cd [prefix]
	    logexec ln -s libclntsh.so.11.1 libclntsh.so
	    logexec ln -s libocci.so.11.1 libocci.so
	    
        }
    }

    public method preparefordist {} {
        if {[$be cget -target]=="windows"} {
        } else {
            foreach f {adrci genezi} {
                prepareWrapper [file join [prefix] $f] INSTANTCLIENT
            }
        }
    }
}
