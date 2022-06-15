#
#                        platform
#                           |
#                    nativeInstaller
#                           |
# ---------------------------------------------------------
# windows linux osx-ppc osx-x86 solaris-intel solaris-sparc
#


::itcl::class platform {
# This should not inherit from program
    inherit program
    public variable fullname {}
    public variable platform_type {}
    public variable kind {}

    public variable bundled_os_id {}
    public variable bundled_os_name {}
    public variable bundled_os_version {}
    public variable bundled_os_rev {}

    public variable tags {}
    public variable properties
    public variable rev 0

    constructor {environment} {
        set be $environment
        chain $environment
    } {
        array set properties {}
    }


    # This should not inherit from program
    public method initialize {be} {
    }

    public method propertyList {} {
        return [array get properties]
    }
    public method setProperty {name value} {
        set properties($name) $value
    }
    public method getProperty {name} {
        return $properties($name)
    }

    public method validate {} {
        if {[lsearch $valid_kinds $kind] == -1} {
            message error "Invalid platform kind '$kind' for '$name' target"
            return false
        }
        return true
    }
}

::itcl::class nativeInstaller {
    inherit platform
    constructor {environment} {
        chain $environment
    } {
        set platform_type nativeInstaller
        set fullname "Native Installer"
        lappend tags Easy Multiplatform Integrated Independent
    }
}

# Native targets
::itcl::class windows {
    inherit nativeInstaller
    constructor {environment} {
        chain $environment
    } {
        set name windows
        set fullname Windows
    }
}

::itcl::class windows-x64 {
    inherit nativeInstaller
    constructor {environment} {
        chain $environment
    } {
        set name windows-x64
        set fullname Windows
    }
}

::itcl::class linux {
    inherit nativeInstaller
    constructor {environment} {
        chain $environment
    } {
        set name linux
        set fullname Linux
    }
}

::itcl::class osx-x64 {
    inherit nativeInstaller
    constructor {environment} {
        chain $environment
    } {
        set name osx-x64
        set fullname {Mac OS X X64}
    }
}

::itcl::class linux-x64 {
    inherit nativeInstaller
    constructor {environment} {
        chain $environment
    } {
        set name linux-x64
        set fullname {Linux x64}
    }
}

