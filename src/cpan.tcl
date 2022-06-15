::itcl::class cpanLibrary {
    inherit library
    public method prefix {} {
        return $::opts(perl.prefix)
    }

    constructor {environment} {
        chain $environment
    } {
        set supportsParallelBuild 0
        set licenseRelativePath META.yml
    }

    public method build {} {
        cd [srcdir]
        if {[$be targetPlatform] == "hpux"} {
            # for some reason, on HP-UX we need to install perl right before some components are configured, otherwise it may SEGV
            cd [lindex [glob -type d ../perl-5.8.9] 0]
            eval logexec [make] install
            cd [srcdir]
        }
        if { [file exists [file join [srcdir] Makefile.PL]] } {
            eval [list logexec [file join [prefix] bin perl] Makefile.PL] [configureOptions]
            eval logexec [make]
            #eval logexec [make] test
        } else {
            eval [list logexec [file join [prefix] bin perl] Build.PL] [configureOptions]
            eval [list logexec [file join [prefix] bin perl] Build] [configureOptions]
        }
    }
    public method configureOptions {} {
        set l [chain]
        if {[info exists ::opts(perl.usevendor)] && $::opts(perl.usevendor) == 1} {
            if {[file exists [file join [srcdir] Makefile.PL]]} {
                # For Makefile.PL
                lappend l "INSTALLDIRS=vendor"
            } else {
                # For Build.PL
                lappend l "--installdirs=vendor"
            }
        }
        return $l
    }
    public method getUniqueIdentifier {} {
        return cpan_[chain]
    }
    public method setEnvironment {} {
        set ::opts($name.prefix) [prefix]
    }
    public method install {} {
        cd [srcdir]
        # We need to refresh the Makefile timestamp, because Perl build system does sanity checks
        # to verify that the Perl installation is older than the module. This is not the case when
        # making incremental builds in our build system (and using .buildcomplete to determine what
        # needs to be recompiled and what simply can be 'make install'ed). Otherwise we get error
        # Makefile out-of-date with respect to /bitnami/groundworkstack/output/perl/lib/5.8.8/i686-linux/CORE/config.h
        # Cleaning current config before rebuilding Makefile...
        # make -f Makefile.old clean > /dev/null 2>&1
        # /bitnami/groundworkstack/output/perl/bin/perl Makefile.PL
        # Checking if your kit is complete...
        # Looks good
        # Writing Makefile for Term::ReadKey
        # ==> Your Makefile has been rebuilt. <==
        # ==> Please rerun the make command.  <==
        # false
        # make: *** [Makefile] Error 1
        foreach f [::xampptcl::util::recursiveGlob [srcdir] *Makefile] {
            file mtime $f [clock seconds]
        }
        if { [file exists [file join [srcdir] Makefile.PL]] } {
            chain
        } else {
            eval [list logexec [file join [prefix] bin perl] Build install]
        }
     }
}

proc declareCpanLibrary {className name version {pkgUrl None} {pkgRegex None} {licenseRelativePath META.yml} {licenseNotes {}}} {
    set definition [format {
        ::itcl::class %s {
            inherit cpanLibrary

            constructor {environment} {
                chain $environment
            } {
                set name %s
                set version %s
                set pkgUrl %s
                set pkgRegex %s
		set licenseRelativePath %s
		set licenseNotes %s
                set readmePlaceholder CPAN_[string toupper $name]
            }

        }

    } $className $name $version $pkgUrl $pkgRegex $licenseRelativePath $licenseNotes]

    uplevel $definition

}

::itcl::class cpanDBD-mysql {
    inherit cpanLibrary
    constructor {environment} {
        chain $environment
    } {
        set name DBD-mysql
        set version 4.023
        set licenseRelativePath META.yml
        set licenseNotes "Perl license http://search.cpan.org/~capttofu/DBD-mysql-4.022/lib/DBD/mysql.pm#COPYRIGHT"
    }
    protected method configureOptions {} {
        return [concat [chain] [list \
            --cflags=-I[file join $::opts(mysql.prefix) include] \
            --mysql_config=[file join $::opts(mysql.prefix) bin mysql_config] \
            --testsocket=[file join $::opts(mysql.prefix) tmp mysql.sock] \
            "--libs=-L[file join $::opts(mysql.prefix) lib] -lmysqlclient -lz" \
        ]]
    }
    public method build {} {
        cd [srcdir]
        eval logexec [file join [prefix] bin perl] Makefile.PL [configureOptions]
        eval logexec [make]
#        eval logexec [make] test
    }
}

::itcl::class cpanDBD-mariadb {
    inherit cpanDBD-mysql
    constructor {environment} {
        chain $environment
    } {
        set name DBD-mariadb
        set version 1.21
        set licenseRelativePath LICENSE
        set licenseNotes "Perl license https://metacpan.org/pod/distribution/DBD-MariaDB/lib/DBD/MariaDB.pod#LICENSE"
    }
     public method srcdir {} {
         return [file join [$be cget -src] DBD-MariaDB-$version]
     }
    protected method configureOptions {} {
        return [concat [chain] [list \
            --cflags=-I[file join $::opts(mysql.prefix) include] \
            --mysql_config=[file join $::opts(mysql.prefix) bin mysql_config] \
            --testsocket=[file join $::opts(mysql.prefix) tmp mysql.sock] \
            "--libs=-L[file join $::opts(mysql.prefix) lib] -lmariadbclient -lz" \
        ]]
    }
}

::itcl::class cpanDBD-SQLite {
    inherit cpanLibrary

    constructor {environment} {
        chain $environment
    } {
        set name DBD-SQLite
        set version 1.37
    }

    protected method configureOptions {} {
        return [concat [chain] [list \
            --cflags=-I[file join $::opts(sqlite.prefix) include] \
            "--libs=-L[file join $::opts(sqlite.prefix) lib] -lsqlite3" \
        ]]
    }
}

::itcl::class cpanHTML-Parser {
    inherit cpanLibrary

    constructor {environment} {
        chain $environment
    } {
        set name HTML-Parser
        set version 3.58
        set licenseRelativePath README
    }
}


::itcl::class cpanHTML-Tagset {
    inherit cpanLibrary

    constructor {environment} {
        chain $environment
    } {
        set name HTML-Tagset
        set version 3.20
    }
}

::itcl::class cpanLWP {
    inherit cpanLibrary

    constructor {environment} {
        chain $environment
    } {
        set name libwww-perl
        set version 5.805
        set licenseRelativePath {}
    }

    protected method configureOptions {} {
        return [concat [chain] [list -n]]
    }

}

::itcl::class cpanURI {
    inherit cpanLibrary

    constructor {environment} {
        chain $environment
    } {
        set name URI
        set version 1.35
        set licenseRelativePath {}
    }
}

declareCpanLibrary cpanDBI DBI 1.625 None None DBI.pm
declareCpanLibrary cpanArchiveZip Archive-Zip 1.30
declareCpanLibrary cpanXSBuilder ExtUtils-XSBuilder 0.28
declareCpanLibrary cpanIoZlib IO-Zlib 1.10
declareCpanLibrary cpanBundleCpan Bundle-CPAN 1.861
declareCpanLibrary cpanIoCompress IO-Compress 2.093
declareCpanLibrary cpanParseRecDescent Parse-RecDescent 1.967009
declareCpanLibrary cpanDBDPgPP DBD-PgPP 0.08
declareCpanLibrary cpanMakeMaker ExtUtils-MakeMaker 6.66
declareCpanLibrary cpanDevelCheckLib Devel-CheckLib 1.13
declareCpanLibrary cpanHTMLTree HTML-Tree 3.20

::itcl::class cpanYAML {
     inherit cpanLibrary

     constructor {environment} {
         chain $environment
     } {
         set name YAML
         set version 1.15
     }

     public method build {} {
        cd [srcdir]
        eval [list logexec echo y | [file join [prefix] bin perl] Makefile.PL] [configureOptions]
        eval logexec [make]
    }
 }

::itcl::class mod_perl {
    inherit cpanLibrary
    constructor {environment} {
        chain $environment
    } {
        set name mod_perl
        set version 2.0.12
        set licenseRelativePath LICENSE
    }
    protected method configureOptions {} {
        return [concat [chain] [list \
            MP_APXS=$::opts(apache.apxs) \
            MP_APR_CONFIG=$::opts(apache.apr) \
            LIBS=-L[file join [$be cget -output] [$be cget -libprefix] lib] \
            DEFINE=-I[file join [$be cget -output] [$be cget -libprefix] include] \
        ]]
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        eval [list logexec [file join [prefix] bin perl] Makefile.PL] [configureOptions]
        xampptcl::util::substituteParametersInFile [file join [srcdir] xs APR APR Makefile] \
            [list {:/usr/lib64} {}]
        eval logexec [make]
    }
}

