::itcl::class perl {
    inherit baseBitnamiProgram
    constructor {environment} {
        chain $environment
    } {
        set name perl
        set fullname Perl
        # Check the use -Duserelocatableinc and review wrapper creation for Perl when we upgrade to Perl 5.10 or later
        set version [versions::get "Perl" stable]
        set dependencies {perl {perl.xml}}
        set readmePlaceholder PERL
        set downloadType wget
        set downloadTarballName $name-$version.tar.gz
        regexp -- {^([0-9]+)\.[0-9]+\.[0-9]+$} $version - majorVersion
        set downloadUrl http://www.cpan.org/src/$majorVersion.0/$downloadTarballName
    }
}

::itcl::class perlLinux {
    inherit perl
    constructor {environment} {
        chain $environment
    } {
        set separator -
        set supportsParallelBuild 0
        set licenseRelativePath Copying
    }
    public method setEnvironment {} {
        set ::opts(perl.srcdir) [srcdir]
        set ::opts(perl.prefix) [prefix]
    }
    protected method configureOptions {} {
    ### find out more about configuration options:
    # check sh Configure --help
    # http://www.perl.com/doc/manual/html/READMEs/INSTALL.html
    # http://www.xav.com/perl/lib/Config.html#description
      set opts [list -de -Dusethreads -Duseithreads -Dcc=$::env(CC) "-Dccflags=$::env(CFLAGS)" "-Dldflags=$::env(LDFLAGS)"]
      return $opts
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        eval [list logexec sh Configure -Dprefix=[prefix]] [configureOptions]
        if { [xampptcl::util::compareVersions $version 5.20.2] == -1 } {
            foreach p [list [file join [srcdir] makefile] [file join [srcdir] x2p makefile]] {
                if [file exists $p] {
                    xampptcl::util::substituteParametersInFile $p \
                        [list {# If this runs make out of memory, delete /usr/include lines.
0} {# If this runs make out of memory, delete /usr/include lines.}]
                }
            }
        }
        if {[$be targetPlatform] == "osx-x64"} {
            xampptcl::util::substituteParametersInFile [file join [srcdir] makedepend.SH] [list {.*<command line>/d} {.*<command[ -]line>/d}]
            eval [list logexec sh Configure -Dprefix=[prefix]] [configureOptions]
        }
        eval logexec [make]
        #eval logexec [make] test
    }
    public method install {} {
        cd [srcdir]
        eval logexec [make] install

        #By executing 'perl Makefile.pl' to build modules, the CFLAGS and
        #LDFLAGS that are taken into account are generated dynamically asking
        #directly to the perl binary and getting the CFLAGS and LDFLAGS
        #variables which with the binary was created.

        #It is possible to change these variables, though, by setting
        #appropriately PERL_CFLAGS and PERL_LDFLAGS environment variables.
        #However, this resulted in another error as the libraries that we were
        #trying to build the module against were not the same version than the
        #Perl binary. This, at the end, pointed me where the error was, and I
        #have modified the build system so that the compiled Perl is added to
        #the PATH in the Build System.
        set ::env(PATH) "[prefix]/bin:$::env(PATH)"
    }
    public method preparefordist {} {
        # Solaris Sparc 8 does not support setenv() function.
        # This patch replaces this function with putenv().
        if { [$be targetPlatform] == "solaris-sparc" } {
           if {[eval {exec uname -r}] == "5.8"} {
               cd [file join [$be cget -projectDir]/src]
               logexec patch -p0 < wrapper-solarissparc8.patch
           }
        }
        set fileList [list bin perl]
        if {[file exists [file join [prefix] bin a2p]]} {
            lappend fileList bin a2p
        }
        foreach {d f} $fileList {
            prepareWrapper [file join [prefix] $d $f] PERL
        }
        prepareWrapper [file join [prefix] bin [join "$name $version" {}]] PERL
    }
    public method copyProjectFiles {stack} {
        chain $stack
        xampptcl::util::substituteParametersInFile \
            [file join [$be cget -output] perl.xml] \
            [list @@XAMPP_PERL_FILES_TO_CHANGE@@ [massSubstitution [list [prefix] [regsub -- "\-[$be cget -target]" [prefix] {}]] @@XAMPP_PERL_ROOTDIR@@ [prefix] {${installdir}/perl}]]
    }
}

