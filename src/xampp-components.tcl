namespace eval xampp {
    ::itcl::class manager {
        inherit ::manager
        constructor {environment} {
            chain $environment
        } {
        }
        public method getControlBinary {} {
            switch -glob -- [$be targetPlatform] {
                linux {
                    set control manager-linux-xampp.run
                }
                linux-x64 {
                    set control manager-linux-x64-xampp.run
                }
                *osx-* {
                    set control manager-osx-xampp.app
                }
            }
            return $control
        }

        public method install {} {
            chain
            set origin [$be cget -output]/$control
            set dest [$be cget -output]/[string map {-xampp {}} $control]
            file delete -force $dest
            file rename -force $origin $dest
        }
    }

    ::itcl::class xamppControlOsx {
        inherit program

        public method needsToBeBuilt {} {
            return [chain]
        }
        constructor {environment} {
            chain $environment
        } {
            set name "XAMPP Control"
            set version "1.8.2"
            set tarballName xampp-control-osx-$version.app
            set licenseRelativePath ""
        }
        public method srcdir {} {
            return [$be cget -src]/xampp-control-osx
        }
        public method extract {} {
            file delete -force [srcdir]
            set zip [findTarball]
            logexec unzip -qo $zip -d [srcdir]
        }

        public method build {} {}
        public method install {} {
            file copy -force [srcdir]/$name.app [$be cget -output]
        }
    }

    ::itcl::class gcc4 {
        inherit ::gcc4
        constructor {environment} {
            chain $environment
        } {
        }

        protected method configureOptions {} {
            return [concat [chain] [list --with-libiconv-prefix=$::opts(libiconv.dir) ]]
        }
    }


    itcl::class oracleInstantclientLinuxX86Sdk {
        inherit ::library
        constructor {environment} {
            chain $environment
        } {
            set name instantclient-sdk
            set version 11.2.0.3.0
            set supportsParallelBuild 0
            set tarballName instantclient-sdk-linux-${version}
        }
        public method srcdir {} {
            return [$be cget -src]/instantclient-sdk/instantclient_11_2
        }
        public method build {} {}
        public method extract {} {
            set sdk [findTarball]
            file delete -force [$be cget -src]/instantclient-sdk
            file mkdir [$be cget -src]/instantclient-sdk
            cd [$be cget -src]/instantclient-sdk
            logexec unzip -qo $sdk
        }

        public method needsToBeBuilt {} {
            return 1
        }

        public method copyLicense {} {}
        public method prefix {} {
            return [file join [$be cget -output] lib instantclient-$version]
        }

        public method install {} {
            file delete -force [prefix]/sdk
            file copy -force [srcdir]/sdk [prefix]
        }
    }

    itcl::class oracleInstantclientLinuxX64Sdk {
        inherit oracleInstantclientLinuxX86Sdk
        constructor {environment} {
            chain $environment
        } {
            set name instantclient-sdk
            set version 11.2.0.3.0
            set supportsParallelBuild 0
            set tarballName instantclient-sdk-linux.x64-${version}
        }

    }
    itcl::class oracleInstantclientLinuxX86Lib {
        inherit ::oracleInstantclientLib
        constructor {environment} {
            chain $environment
        } {
            set version 11.2.0.3.0
            set supportsParallelBuild 0
            set tarballName instantclient-basic-linux-${version}
            lappend additionalFileList instant-client-license.txt
        }
        public method extract {} {
            set sdk [findTarball]
            #set sdk [file join [file dirname $sdk] [string map {-basic- -sdk-} $tarballName]]
            cd [$be cget -src]
            logexec unzip -qo $sdk
        }
        public method srcdir {} {
            return [$be cget -src]/instantclient_11_2
        }

        public method needsToBeBuilt {} {
            return 1
        }

        public method copyLicense {} {}
        public method prefix {} {
            return [file join [$be cget -output] lib instantclient-$version]
        }

        public method install {} {
            # We just use it to compile
            file delete -force [prefix]
            chain
            #cd /opt/lampp/lib/
            file delete -force [$be cget -output]/lib/instantclient
            exec ln -sf $::opts(instantclient.prefix) [$be cget -output]/lib/instantclient
            set f [findTarball instant-client-license.txt]
            file copy -force $f [$be cget -output]/licenses/$name.txt
        }
    }

    itcl::class oracleInstantclientLinuxX64Lib {
        inherit oracleInstantclientLinuxX86Lib
        constructor {environment} {
            chain $environment
        } {
            set version 11.2.0.3.0
            set supportsParallelBuild 0
            set tarballName instantclient-basic-linux.x64-${version}
        }
        public method srcdir {} {
            return [$be cget -src]/instantclient_11_2
        }

    }

    itcl::class oracleInstantclientOsxX64Sdk {
        inherit oracleInstantclientLinuxX86Sdk
        constructor {environment} {
            chain $environment
        } {
            set name instantclient-sdk
            set version 11.2.0.3.0
            set supportsParallelBuild 0
            set tarballName instantclient-sdk-macos.x64-${version}
        }

    }

    itcl::class oracleInstantclientOsxX64Lib {
        inherit oracleInstantclientLinuxX86Lib
        constructor {environment} {
            chain $environment
        } {
            set version 11.2.0.3.0
            set supportsParallelBuild 0
            set tarballName instantclient-basic-macos.x64-${version}
        }
        public method srcdir {} {
            return [$be cget -src]/instantclient_11_2
        }
        public method install {} {
            # We just use it to compile
            file delete -force [prefix]
            file copy -force [srcdir] [prefix]
            cd [prefix]
            set majorVersion [lindex [split $version .] 0]
            logexec ln -s libclntsh.dylib.$majorVersion.1 libclntsh.dylib
            logexec ln -s libocci.dylib.$majorVersion.1 libocci.dylib
            file delete -force [$be cget -output]/lib/instantclient
            exec ln -sf $::opts(instantclient.prefix) [$be cget -output]/lib/instantclient
            set f [findTarball instant-client-license.txt]
            file copy -force $f [$be cget -output]/licenses/$name.txt
        }
    }

    ::itcl::class cmake {
        inherit ::cmake
        constructor {environment} {
            chain $environment
        } {
            set name cmake
            set version 3.6.1
        }
        public method configureOptions {} {
            #return [list --system-curl]
        }
    }

    ::itcl::class Console_Getopt {
        inherit pearprogram

        constructor {environment} {
            chain $environment
        } {
            set name Console_Getopt
            set version 1.4.3
            set licenseRelativePath {}
        }

        public method install {} {
            file delete -force $::opts(pear.prefix)/Console
            file copy -force [srcdir]/Console $::opts(pear.prefix)
        }
    }

    ::itcl::class PEAR {
        inherit pearprogram
        constructor {environment} {
            chain $environment
        } {
            set name PEAR
            set fullname PEAR
            set version 1.7.1
            set licenseRelativePath ""
            set licenseNotes "PHP License http://www.php.net/license/3_0.txt"
        }
        public method install {} {
            logexec $::opts(php.prefix)/bin/pear upgrade [findTarball]
        }
    }
    ::itcl::class PhpDocumentor {
        inherit pearprogram
        constructor {environment} {
            chain $environment
        } {
            set name PhpDocumentor
            set version 1.4.1
        }
        public method build {} {}
        public method install {} {
            logexec $::opts(php.prefix)/bin/pear config-set data_dir $::opts(apache.prefix)/htdocs
            chain
            file delete ~/.pearrc
        }
        public method preparefordist {} {
        }
    }

    pearProgram Archive_Tar -version 1.4.11
    pearProgram XML_RPC -version 1.5.5
    pearProgram XML_Parser -version 1.3.4
    pearProgram Cache_Lite -version 1.7.15 -licenseRelativePath LICENSE
    pearProgram Console_Table -version 1.3.1 -licenseNotes "BSD http://pear.php.net/package/Console_Table/redirected"
    pearProgram Mail -version 1.4.1 -licenseNotes "BSD Style http://pear.php.net/package/Mail"
    pearProgram Net_SMTP -version 1.6.1 -licenseNotes "PHP License http://pear.php.net/package/Net_SMTP"
    pearProgram Net_Socket -version 1.0.14 -licenseNotes "PHP License http://pear.php.net/package/Net_Socket"
    pearProgram Mail_mimeDecode -version 1.5.5
    pearProgram Mail_Mime -version 1.10.0
    pearProgram Net_Curl -version 1.2.5
    pearProgram File -version 1.4.1
    pearProgram MDB2 -version 2.5.0b5
    pearProgram File_Util -version 1.0.0
    pearProgram File_CSV -version 1.0.0
    pearProgram File_Find -version 1.3.1
    pearProgram File_HtAccess -version 1.2.1
    pearProgram File_SearchReplace -version 1.1.4
    pearProgram Auth -version 1.6.4
    pearProgram Benchmark -version 1.2.9
    pearProgram Cache -version 1.5.6
    pearProgram Config -version 1.10.12
    pearProgram System_Command -version 1.0.8
    pearProgram Contact_Vcard_Build -version 1.1.2
    pearProgram Contact_Vcard_Parse -version 1.32.0
    pearProgram MP3_Id -version 1.2.2
    pearProgram Auth_HTTP -version 2.1.8
    pearProgram Auth_PrefManager -version 1.2.2
    pearProgram I18N -version 1.0.0
    pearProgram Auth_RADIUS -version 1.0.7
    pearProgram Auth_SASL -version 1.0.6
    pearProgram Crypt_CBC -version 1.0.1
    pearProgram Crypt_RC4 -version 1.0.3
    pearProgram Crypt_Xtea -version 1.1.0
    pearProgram DB -version 1.7.14
    pearProgram DBA -version 1.1.1
    pearProgram DB_ado -version 1.3.1
    pearProgram DB_DataObject -version "1.11.2"
    pearProgram DB_ldap -version "1.2.1"
    pearProgram DB_NestedSet -version "1.4.1"
    pearProgram DB_Pager -version "0.7"
    pearProgram DB_QueryTool -version "1.1.2"
    pearProgram MDB -version "1.3.0"
    pearProgram MDB_QueryTool -version "1.2.3"
    pearProgram FSM -version "1.3.1"
    pearProgram HTML_BBCodeParser -version "1.2.3"
    pearProgram HTML_BBCodeParser2 -version "0.1.0"
    pearProgram HTML_Common -version "1.2.5"
    pearProgram HTML_Common2 -version "2.1.1"
    pearProgram HTML_Crypt -version "1.3.4"
    pearProgram HTML_CSS -version "1.5.4"
    pearProgram HTML_Form -version "1.3.0"
    pearProgram HTML_Menu -version "2.1.4"
    pearProgram HTML_Javascript -version "1.1.2"
    pearProgram HTML_Progress -version "1.2.6"
    pearProgram HTML_QuickForm -version "3.2.13"
    pearProgram HTML_QuickForm2 -version "2.0.2"
    pearProgram HTML_Select_Common -version "1.2.0"
    pearProgram HTML_Table -version "1.8.3"
    pearProgram Tree -version "0.3.7"
    pearProgram HTML_Template_IT -version "1.3.0"
    pearProgram HTML_Template_PHPLIB -version "1.5.2"
    pearProgram HTML_Template_Sigma -version "1.2.0"
    pearProgram HTML_Template_Xipe -version "1.7.6"
    pearProgram HTML_TreeMenu -version "1.2.2"
    pearProgram Pager -version "2.4.8"
    pearProgram Pager_Sliding -version "1.6"
    pearProgram HTTP -version "1.4.1"
    pearProgram HTTP_Request -version "1.4.4"
    pearProgram HTTP_Upload -version "0.9.1"
    pearProgram Image_Color -version "1.0.4"
    pearProgram Image_GIS -version "1.1.2"
    pearProgram Image_GraphViz -version "1.3.0"
    pearProgram Image_IPTC -version "1.0.2"
    pearProgram Log -version "1.12.7"
    pearProgram Mail_Queue -version "1.2.7"
    pearProgram Math_Basex -version "0.3"
    pearProgram Math_Fibonacci -version "0.8"
    pearProgram Math_Integer -version "0.9.0"
    pearProgram Math_Vector -version "0.7.0"
    pearProgram Math_Matrix -version "0.8.0"
    pearProgram Math_RPN -version "1.1.2"
    pearProgram Math_Stats -version "0.8.5"
    pearProgram Math_TrigOp -version "1.0"
    pearProgram Net_CheckIP -version "1.2.2"
    pearProgram Net_Dict -version "1.0.7"
    pearProgram Net_Dig -version "0.1"
    pearProgram Net_DNS -version "1.0.7"
    pearProgram Net_Finger -version "1.0.1"
    pearProgram Net_FTP -version "1.3.7"
    pearProgram Net_Geo -version "1.0.5"
    pearProgram Net_Ident -version "1.1.0"
    pearProgram Net_IPv4 -version "1.3.4"
    pearProgram Net_NNTP -version "1.5.0"
    pearProgram Net_Ping -version "2.4.5"
    pearProgram Net_POP3 -version "1.3.8"
    pearProgram Net_Portscan -version "1.0.3"
    pearProgram Net_Sieve -version "1.3.2"
    pearProgram Net_SmartIRC -version "1.0.2"
    pearProgram Net_URL -version "1.0.15"
    pearProgram Net_UserAgent_Detect -version "2.5.2"
    pearProgram Net_Whois -version "1.0.5"
    pearProgram Numbers_Roman -version "1.0.2"
    pearProgram Payment_Clieop -version "0.1.1"
    pearProgram Console_Getargs -version "1.3.5"
    pearProgram PEAR_Info -version "1.9.2"
    pearProgram PEAR_PackageFileManager -version "1.7.0"
    pearProgram PEAR_PackageFileManager2 -version "1.0.2"
    pearProgram PEAR_PackageFileManager_Plugins -version "1.0.2"
    pearProgram Var_Dump -version "1.0.4"
    pearProgram Science_Chemistry -version "1.1.2"
    pearProgram Stream_SHM -version "1.0.0"
    pearProgram Stream_Var -version "1.1.0"
    pearProgram Text_Password -version "1.1.1"
    pearProgram Text_Statistics -version "1.0.1"
    pearProgram Translation -version "1.2.6pl1"
    pearProgram XML_CSSML -version "1.1.1"
    pearProgram XML_Serializer -version "0.20.2"
    pearProgram XML_fo2pdf -version "0.98"
    pearProgram XML_HTMLSax -version "2.1.2"
    pearProgram XML_image2svg -version "0.1"
    pearProgram XML_NITF -version "1.1.1"
    pearProgram XML_RSS -version "1.0.2"
    pearProgram XML_SVG -version "1.1.0"
    pearProgram XML_Transformer -version "1.1.2"
    pearProgram XML_Tree -version "1.1"
    pearProgram XML_Util -version 1.2.1
    pearProgram YAML -version 1.0.6 -channel "pear.symfony-project.com"
    pearProgram PHPUnit -version 3.6.0 -channel "pear.phpunit.de"
    pearProgram File_Iterator -version 1.3.3 -channel "pear.phpunit.de"
    pearProgram Text_Template -version 1.1.4 -channel "pear.phpunit.de"
    pearProgram PHP_TokenStream -version 1.1.5 -channel "pear.phpunit.de"
    pearProgram PHP_CodeCoverage -version 1.2.11 -channel "pear.phpunit.de"
    pearProgram PHP_Timer -version 1.0.4 -channel "pear.phpunit.de"
    pearProgram PHPUnit_MockObject -version 1.2.3 -channel "pear.phpunit.de"
    ::itcl::class xamppLibraryCommon {
        public method preparefordist {} {}
        public method addLibDir {dir {insertBefore 0}} {
            if {[info exists ::env(LDFLAGS)]} {
		if {$insertBefore} {
		    set ::env(LDFLAGS) "-L$dir $::env(LDFLAGS)"
		} else {
		    set ::env(LDFLAGS) "$::env(LDFLAGS) -L$dir"
		}
            } else {
                set ::env(LDFLAGS) "-L$dir"
            }
        }

        protected method includesDirPresent {dir content} {
            set dir [string trimright $dir /]
            foreach elem [split $content] {
                if {[string match -I* $elem]} {
                    set d [string trimright [string map {-I {}} $elem] /]
                    if {$d == $dir} {
                        return 1
                    }
                }
            }
            return 0
        }
        public method addIncludesDir {dir} {
            set cflags {}
            set releaseCflags {}
            set releaseCxxFlags {}
            foreach v {RELEASE_CFLAGS RELEASE_CXXFLAGS CFLAGS CXXFLAGS CPPFLAGS} {
                if {[info exists ::env($v)]} {
                    if {![includesDirPresent $dir $::env($v)]} {
                        set ::env($v) "-I$dir $::env($v)"
                    }
                } else {
                    set ::env($v) "-I$dir"
                }
            }
        }
        public method prefix {} {
            return [[$this cget -be] cget -output]
        }
    }


    ::itcl::class xamppLibrary {
        inherit xamppLibraryCommon library
        constructor {environment} {
            library::constructor $environment
        } {
        }

    }


    ::itcl::class xampp_pecl_extension {
        inherit pecl_extension
        constructor {environment} {
            chain $environment
        } {
        }
        public method preparefordist {} {}
    }

    ::itcl::class pecl_zip {
        inherit xampp_pecl_extension
        constructor {environment} {
            chain $environment
        } {
            set name zip
            set version 1.10.2
            set licenseRelativePath {}
            set licenseNotes ""
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-zlib-dir=$::opts(zlib.prefix)]]
        }

    }
    ::itcl::class pecl_apd {
        inherit xampp_pecl_extension
        constructor {environment} {
            chain $environment
        } {
            set name apd
            set version 1.0.1
            set licenseRelativePath {}
            set licenseNotes ""
        }
        public method build {} {
            cd [srcdir]

            xampptcl::util::substituteParametersInFile php_apd.h  [list "\#define APD_VERSION \"0.9\"" "\#define APD_VERSION \"$version\""]
            xampptcl::util::substituteParametersInFile php_apd.c  [list "switch (execd->opline->op2.u.constant.value.lval) \{" "switch (execd->opline->extended_value) \{" "function_entry apd_functions\[\] = \{" "zend_function_entry apd_functions\[\] = \{" "CG(extended_info) = 1;  /* XXX: this is ridiculous */" "CG(compiler_options) |= ZEND_COMPILE_EXTENDED_INFO;"]

            chain

        }
    }

    ::itcl::class pecl_radius {
        inherit xampp_pecl_extension
        constructor {environment} {
            chain $environment
        } {
            set name radius
            set version 1.2.5
            set licenseRelativePath {}
            set supportsParallelBuild 0
            set licenseNotes ""
        }
        public method build {} {
            cd [srcdir]
            logexec $::opts(php.prefix)/bin/phpize
            xampptcl::util::substituteParametersInFileRegex radius.c [list "\nfunction_entry radius_functions" "\nzend_function_entry radius_functions"]
            chain
        }
    }
    ::itcl::class pecl_ncurses {
        inherit xampp_pecl_extension
        constructor {environment} {
            chain $environment
        } {
            set name ncurses
            set version 5.9
            set licenseRelativePath {}
            set licenseNotes ""
        }
        public method configureOptions {} {
            return [concat [chain] [list  --with-ncurses=$::opts(ncurses.prefix)]]
        }

    }
    ::itcl::class eaccelerator {
        inherit xampp_pecl_extension
        constructor {environment} {
            chain $environment
        } {
            set name "eaccelerator"
            set version 42067ac
            #set version 0.9.6.1
        }
        public method configureOptions {} {
            return [concat [chain] [list --enable-eaccelerator=shared  --with-eaccelerator-shared-memory --with-eaccelerator-sessions --with-eaccelerator-content-caching]]
        }
        public method build {} {
            cd [srcdir]
            logexec $::opts(php.prefix)/bin/phpize
            #xampptcl::util::substituteParametersInFile configure [list "\#define MM_SEM_IPC" {OSWALD}]
            chain
        }
    }

    ::itcl::class xdebug {
        inherit ::xdebug
        constructor {environment} {
            chain $environment
        } {
        }
        public method preparefordist {} {}
    }


    ::itcl::class pcre {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "pcre"
            set version 8.40
        }

        public method setEnvironment {} {
            chain
        }
        public method configureOptions {} {
            return [list --disable-libtool-lock --disable-cpp --enable-utf8 --enable-unicode-properties]
        }
    }

    ::itcl::class zlib {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "zlib"
            set version 1.2.11
            set licenseRelativePath README
        }
        public method setEnvironment {} {
            set ::opts(zlib.prefix) [prefix]
        }

        public method configureOptions {} {
            return [concat [chain] [list --shared]]
        }
    }


    ::itcl::class gettext {
        inherit xamppLibraryCommon ::gettext
        constructor {environment} {
            chain $environment
        } {
            set name "gettext"
            set version 0.19.8.1
        }
        public method preparefordist {} {
            file delete -force [file join [prefix] share doc gettext]
        }
    }

    ::itcl::class bzip2 {
        inherit ::bzip2
        constructor {environment} {
            chain $environment
        } {
        }
        public method install {} {
            chain
            cd [prefix]/lib
            if {[$be targetPlatform] == "osx-x64"} {
                set compatVersion [join [lrange [split $version .] 0 1] .]
                exec ln -sf libbz2.$version.dylib libbz2.dylib
                exec ln -sf libbz2.$version.dylib libbz2.$compatVersion.dylib
            }
        }
        public method build {} {
            cd [srcdir]
            set compatVersion [join [lrange [split $version .] 0 1] .]
            if {[$be targetPlatform] == "osx-x64"} {
                set dylibTarget [format [join [list {libbz2.dylib: $(OBJS)} \
                                                   {rm -f libbz2.dylib} {$(CC) -dynamiclib $(OBJS) -o libbz2.%s.dylib -install_name $(PREFIX)/lib/libbz2.%s.dylib -compatibility_version %s -current_version %s} \
                                                   {ln -s libbz2.%s.dylib libbz2.%s.dylib} \
                                                   {ln -s libbz2.%s.dylib libbz2.dylib}] "\n\t"] \
                                     $version $compatVersion $compatVersion $version $version $compatVersion $version]
                xampptcl::util::substituteParametersInFile [file join [srcdir] Makefile] [list {check: test} "$dylibTarget\ncheck: test" \
                                                                                          {chmod a+r $(PREFIX)/lib/libbz2.a} "chmod a+r \$(PREFIX)/lib/libbz2.a\n\tcp -f libbz2.$version.dylib \$(PREFIX)/lib" \
                                                                                          {rm -f *.o libbz2.a bzip2 bzip2recover} {rm -f *.o libbz2.a libbz2.*.dylib bzip2 bzip2recover} \
                                                                                          {all: libbz2.a bzip2 bzip2recover test} {all: libbz2.a libbz2.dylib bzip2 bzip2recover test} \
                                                                                          {bzip2: libbz2.a bzip2.o} {bzip2: libbz2.a libbz2.dylib bzip2.o} \
                                                                                          {LDFLAGS=} "LDFLAGS= -Wl,-rpath -Wl,[prefix]/lib" \
                                                                                          {PREFIX=/usr/local} "PREFIX=[prefix]"]
            } else {
                set soTarget [join [list {libbz2.so.1.0.2: $(OBJS)} \
                                        {rm -f libbz2.so} {$(CC) -shared -o libbz2.so.1.0.2 $(OBJS)}] "\n\t"]
                xampptcl::util::substituteParametersInFile [file join [srcdir] Makefile] [list {check: test} "$soTarget\ncheck: test" \
                                                                                          {chmod a+r $(PREFIX)/lib/libbz2.a} "chmod a+r \$(PREFIX)/lib/libbz2.a\n\tcp -f libbz2.so.1.0.2 \$(PREFIX)/lib\n\tchmod a+r \$(PREFIX)/lib/libbz2.so.1.0.2\n\tln -s libbz2.so.1.0.2 \$(PREFIX)/lib/libbz2.so.1\n\tln -s libbz2.so.1.0.2 \$(PREFIX)/lib/libbz2.so" \
                                                                                          {rm -f *.o libbz2.a bzip2 bzip2recover} {rm -f *.o libbz2.a libbz2.so.1.0.2 bzip2 bzip2recover} \
                                                                                          {all: libbz2.a bzip2 bzip2recover test} {all: libbz2.a libbz2.so.1.0.2 bzip2 bzip2recover test} \
                                                                                          {bzip2: libbz2.a bzip2.o} {bzip2: libbz2.a libbz2.so.1.0.2 bzip2.o} \
                                                                                          {LDFLAGS=} "LDFLAGS= -Wl,-rpath -Wl,[prefix]/lib" \
                                                                                          {PREFIX=/usr/local} "PREFIX=[prefix]"]

            }
        }

        public method preparefordist {} {}
    }

    ::itcl::class libpng {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "libpng"
            set version 1.6.37
            set licenseRelativePath LICENSE
            set licenseNotes http://www.libpng.org/pub/png/src/libpng-LICENSE.txt
        }
        public method build {} {
            chain
            addIncludesDir [prefix]/include/libpng
            set c {
                set releaseCflags {}
                set releaseCxxFlags {}
                catch {set releaseCflags $::env(RELEASE_CFLAGS)}
                catch {set releaseCxxFlags $::env(RELEASE_CXXFLAGS)}
                set ::env(RELEASE_CFLAGS) "$releaseCflags -I[prefix]/include/libpng"
                set ::env(RELEASE_CXXFLAGS) "$releaseCxxFlags -I[prefix]/include/libpng"
            }
        }
        public method setEnvironment {} {
            set ::opts(libpng.prefix) [prefix]
        }

    }

    ::itcl::class freetype {
        inherit xamppLibraryCommon ::freetype
        constructor {environment} {
            chain $environment
        } {
            set name "freetype"
            set version 2.4.8
        }
        public method setEnvironment {} {
            chain
            addIncludesDir [prefix]/include/freetype2
        }

        public method install {} {
            chain
            addIncludesDir [prefix]/include/freetype2
        }
    }
    ::itcl::class libxml2 {
        inherit xamppLibraryCommon ::libxml2
        constructor {environment} {
            ::libxml2::constructor $environment
        } {
            set version 2.9.4
            set patchStrip 0
            set patchList {CVE-2016-9318.patch}
        }
        public method setEnvironment {} {
            set ::opts(libxml2.prefix) [prefix]
        }

        public method configureOptions {} {
            return [concat [chain] [list  --disable-ipv6]]
        }
	public method preparefordist {} {}
    }




    ::itcl::class libxslt {
        inherit xamppLibrary
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
            return [concat [chain] [list --disable-ipv6  --with-libxml-prefix=$::opts(libxml2.prefix)]]
        }
    }
    ::itcl::class expatLib {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name expat
            set version 2.0.1
            set licenseRelativePath COPYING
            set licenseNotes "MIT http://www.jclark.com/xml/copying.txt"
        }
        public method setEnvironment {} {
            set ::opts(expat.prefix) [prefix]
        }
	public method build {} {
	    # We get an error related to rpath:
	    # /bin/sh ./libtool --silent --mode=link gcc -O3  -L/opt/lampp/lib -I/opt/lampp/include -I/opt/lampp/include/ncurses -arch x86_64 -Wall -Wmissing-prototypes -Wstrict-prototypes -fexceptions -DHAVE_EXPAT_CONFIG_H  -O3 -L/opt/lampp/lib -I/opt/lampp/include -I/opt/lampp/include/ncurses -arch x86_64 -I./lib -I. -no-undefined -version-info 5:0:5 -rpath /opt/lampp/lib -Wl,-rpath -Wl,/opt/lampp/lib -L/opt/lampp/lib -I/opt/lampp/include -arch x86_64 -o libexpat.la lib/xmlparse.lo lib/xmltok.lo lib/xmlrole.lo
	    #ld: in /opt/lampp/lib, can't map file, errno=22 for architecture x86_64
	    if {[$be cget -target] == "osx-x64"} {
		set ldflags $::env(LDFLAGS)
		unset ::env(LDFLAGS)
		chain
		set ::env(LDFLAGS) $ldflags
	    } else {
		chain
	    }
	}
    }



    ::itcl::class openssl {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "openssl"
            set name OpenSSL
            set version [versions::get "OpenSSL" stable]
            set licenseRelativePath LICENSE
            set supportsParallelBuild 0
            if { [$be cget -target] == "osx-x64" } {
            #gcc issue interpreting binary symbols (https://www.mail-archive.com/openssl-dev%40openssl.org/msg43035.html)
                set patchLevel 1
                set patchList {openssl-1.0.2g.OS-X.patch}
            }
        }

        public method configureOptions {} {
	    set opts [list --prefix=[prefix] --openssldir=[prefix]/share/openssl shared no-sse2]
	    if {[$be cget -target] == "osx-x64"} {
		lappend opts darwin64-x86_64-cc
	    }
            return $opts
            #return [concat [chain] [list  shared no-sse2]]
        }
        public method build {} {
            cd [srcdir]
	    if { [$be cget -target] == "osx-x64" } {
		eval list logexec ./Configure [configureOptions]
	    } else {
		eval logexec ./config  [configureOptions]
	    }
            xampptcl::util::substituteParametersInFile Makefile [list {SHARED_LDFLAGS=} "SHARED_LDFLAGS=-Wl,-rpath -Wl,[prefix]/lib"]
            eval logexec [make]
        }
        public method install {} {
            chain
            set ::env(LD_LIBRARY_PATH) [prefix]/lib/:$::env(LD_LIBRARY_PATH)
            foreach d [list [prefix]/lib [prefix]] {
                addLibDir $d
            }
            addIncludesDir [prefix]/include/
            set c {
                set cflags {}
                set ldflags {}
                set cxxflags {}
                set releaseCflags {}
                set releaseCxxFlags {}
                catch {set releaseCflags $::env(RELEASE_CFLAGS)}
                catch {set releaseCxxFlags $::env(RELEASE_CXXFLAGS)}
                catch {set cflags $::env(CFLAGS)}
                catch {set ldflags $::env(LDFLAGS)}
                catch {set cxxflags $::env(CXXFLAGS)}
                set ::env(RELEASE_CFLAGS) "$releaseCflags -I[prefix]/include/"
                set ::env(CFLAGS) "$cflags -I[prefix]/include/"
                set ::env(RELEASE_CXXFLAGS) "$releaseCxxFlags -I[prefix]/include/"
                set ::env(CXXFLAGS) "$cxxflags -I[prefix]/include/"
                set ::env(LDFLAGS) "$ldflags -L[prefix]/lib -L[prefix]/"
            }
        }
    }

    ::itcl::class opensslVersioned {
        inherit xamppLibraryCommon opensslUnixVersioned
        constructor {environment} {
            opensslUnixVersioned::constructor $environment
	    set supportsParallelBuild 0
        } {
            set version [versions::get "OpenSSL" stable]
        }
        public method copyProjectFiles {s} {}
	public method preparefordist {} {}

        public method configureOptions {} {
            set sslopts [list  --openssldir=[prefix]/share/openssl --libdir=lib]
            lappend sslopts no-idea no-mdc2 no-rc5 shared  ;# RSA/Exports issues
            if { [$be cget -target] != "aix" } {
                set sslopts [concat $sslopts [getSharedLibraryFlag]]
            }
            return $sslopts
        }

	public method build {} {
	    cd [srcdir]
	    if { [$be cget -target] == "aix" } {
		# Fix openssl core dump on AIX
		xampptcl::util::substituteParametersInFile [srcdir]/Configure \
		    [list {cc:-q32} {cc:-q32 -lc -lm}]
	    }
	    if { [$be cget -target] == "osx-x64" } {
		eval [list logexec ./Configure --prefix=[prefix]] [configureOptions]
	    }  elseif { ([$be cget -target] == "hpux") && ($::tcl_platform(machine) == "ia64") } {
		# compile as 32-bit binaries for IA-64
		eval [list logexec ./Configure hpux-ia64-cc --prefix=[prefix]] [configureOptions]
	    } else {
		eval [list logexec ./config --prefix=[prefix]] [configureOptions]
	    }
	    xampptcl::util::substituteParametersInFileRegex Makefile [list {\nSHARED_LDFLAGS=} "\nSHARED_LDFLAGS=-Wl,-rpath -Wl,[prefix]/lib "]
	    # Necessary because we removed some algorithms
	    logexec [make] depend
	    setVersionInformation
	    logexec [make]
	}
        public method setVersionInformation {} {
            if {[string match linux* [$be cget -target]]} {
                chain
            } elseif {[string match osx* [$be cget -target]]} {
                # Maybe we could use "SHARED_LDFLAGS=-Wl,-current_version,$version"
            }
        }
        protected method rndFileInstallDir {} {
            return [file join [prefix] share openssl/]
        }

        public method install {} {
            chain
            set rndFile [file join [rndFileInstallDir] .rnd]
            xampptcl::util::substituteParametersInFileRegex [file join [prefix] share/openssl/openssl.cnf] [list {RANDFILE\s*=.*\.rnd} "RANDFILE = $rndFile"]

            set ::env(LD_LIBRARY_PATH) [prefix]/lib/:$::env(LD_LIBRARY_PATH)
            foreach d [list [prefix]/lib [prefix]] {
                addLibDir $d
            }
            addIncludesDir [prefix]/include/
        }
    }


    ::itcl::class openldap {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "openldap"
            set version 2.4.48
            set licenseRelativePath LICENSE
        }
        public method configureOptions {} {
            return [concat [chain] [list --disable-slapd --disable-slurpd --enable-static=no --with-tls=auto]]
        }
        public method install {} {
            chain
            cd [srcdir]/libraries
            eval logexec [make] install
            cd [srcdir]/include
            eval logexec [make] install
        }
    }


    ::itcl::class libmcrypt {
        inherit ::libmcrypt
        constructor {environment} {
            chain $environment
        } {
            set name libmcrypt
            set version 2.5.8
            set licenseRelativePath COPYING.LIB
            set licenseNotes "libltdl is LGPL too"
            set supportsParallelBuild 0
        }
        public method build {} {
            if {[$be targetPlatform] == "osx-x64"} {
                set ::env(CPPFLAGS) "-Qunused-arguments $::env(CPPFLAGS)"
                set ::env(CFLAGS) "-Qunused-arguments $::env(CFLAGS)"
            }
            chain
        }
    }

    # It seems they are not including it...
    ::itcl::class ddclient-lampp {
        inherit program

        constructor {environment} {
            chain $environment
        } {
            set name "ddclient-lampp"
            set version 1.0
            set tarballName ddclient-lampp
            set licenseRelativePath ""
            set licenseNotes ""
        }
        public method configureOptions {} {}
        public method build {} {}
        public method srcdir {} {
            return [$be cget -src]/$name
        }

        public method install {} {
            foreach d [glob [srcdir]/*] {
                xampptcl::util::copyDirectory $d [$be cget -output]
            }
        }
    }

    ::itcl::class phpPdfClasses {
        inherit program

        constructor {environment} {
            chain $environment
        } {
            set name "pdf-class"
            set version 0.11.7
            set tarballName pdfClassesAndExtensions_$version
            set licenseRelativePath ""
            set licenseNotes ""
        }

        public method extract {} {
            file mkdir [srcdir]
            set tarball [findTarball]
            puts [exec unzip -qb $tarball -d [srcdir]]
        }
        public method configureOptions {} {}
        public method build {} {}
	public method prefix {} {
	    return [$be cget -output]
	}
        public method install {} {
            cd [srcdir]/$version/src
            foreach f {Cezpdf.php Cpdf.php} {
                file copy -force $f [prefix]/lib/php
            }
            file mkdir [prefix]/lib/php/fonts
            foreach f [glob [file join [srcdir] $version src fonts *]] {
                if {![file isfile $f]} {
                    continue
                }
                file copy -force $f [prefix]/lib/php/fonts
            }
        }
    }


    ::itcl::class xamppSkeleton {
        inherit program

        constructor {environment} {
            chain $environment
        } {
            set name "xampp-skeleton"
            set version 1.8.6
            set rev 10
            set tarballName xampp-skeleton-dev-unix-${version}-${rev}
            set licenseRelativePath ""
            set licenseNotes ""
            set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
            lappend additionalFileList curl-ca-bundle-${cacertificatesVersion}.crt
        }
        public method srcdir {} {
            return [$be cget -src]/xampp-skeleton-dev-unix-${version}-${rev}
        }

        public method prefix {} {
            return [$be cget -output]
        }

        public method configureOptions {} {}
        public method build {} {
            # fix server status with empty pids
            xampptcl::util::substituteParametersInFile [file join [srcdir] share xampp xampplib] [list {if $ps ax} {if [ "x$pid" != "x" ] && $ps ax}]
            if {[$be targetPlatform] == "osx-x64"} {
                xampptcl::util::substituteParametersInFile [file join [srcdir] xampp] \
                    [list {$XAMPP_ROOT/bin/mysql.server} {unset DYLD_LIBRARY_PATH
                        $XAMPP_ROOT/bin/mysql.server}]
                xampptcl::util::substituteParametersInFile [file join [srcdir] etc/proftpd.conf] [list UseFtpUsers {#to login with "OSX Users"
AuthPAM on
AuthPAMConfig ftpd
UseFtpUsers}]
                xampptcl::util::substituteParametersInFileRegex  [file join [srcdir] etc/proftpd.conf] [list {#Group\s+[^\n]*} {Group      admin}]
            }

            return
	    foreach p {
		share/xampp-control-panel/*
		share/lampp/*
		share/xampp/*
		etc/*
                etc/extra/*
		htdocs/xampp/*
		htdocs/xampp/contrib/*
		htdocs/xampp/lang/*
		xampp
	    } {
		foreach f [glob -nocomplain [file join [srcdir] $p]] {
		    if {![file isfile $f]} {
			continue
		    }
		    xampptcl::util::substituteParametersInFile $f [list @@BITNAMI_XAMPP_ROOT@@ [prefix]]
		}
	    }
	}

        public method install {} {
            if {[string match osx* [$be cget -target]]} {
                set destDir [file join [prefix] xamppfiles]
                xampptcl::util::substituteParametersInFile [file join $destDir etc extra httpd-userdir.conf] \
                    [list {/home/} {/Users/}]
            } else {
                set destDir [file join [prefix] lampp]
            }
            file delete -force $destDir/etc/openssl.cnf
            file delete -force $destDir/htdocs
            foreach f [glob [srcdir]/*] {
                if {[string match [srcdir]/licenses $f]} {
                    continue
                }
                if {[file isfile $f]} {
                    file delete -force [file join $destDir [file tail $f]]
                }
                xampptcl::util::copyDirectory $f $destDir/
            }
            set instantclientDir [file tail [lindex [glob -nocomplain $destDir/lib/instantclient-*] 0]]
            if {$instantclientDir != ""} {
                foreach f {share/lampp/oci8install share/xampp/oci8install} {
                    if {![file exists [file join $destDir $f]]} {
                        continue
                    }
                    xampptcl::util::substituteParametersInFile [file join $destDir $f] [list {ora_home="/opt/oracle"} "ora_home=\"[file join @@BITNAMI_XAMPP_ROOT@@ lib $instantclientDir]\""]
                }
            }

            set id 0
            catch {exec id -u} id
            if {$::tcl_platform(user) == "root" || $id == "0" || [file writable /]} {
                foreach f {var/mysql htdocs/webalizer} {
                    logexec chown -R nobody [file join $destDir $f]
                }
            }
            set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
            file copy -force [findFile curl-ca-bundle-${cacertificatesVersion}.crt] [file join $destDir share curl curl-ca-bundle.crt]
            xampptcl::file::addTextToFile [file join $destDir etc php.ini] {
                openssl.cafile=@@BITNAMI_XAMPP_ROOT@@/share/curl/curl-ca-bundle.crt}

            if {[string match osx* [$be cget -target]]} {
                set destDir [file join [prefix] xamppfiles]
            } else {
                set destDir [file join [prefix] lampp]
            }
            file delete -force $destDir/temp/eaccelerator

        }
    }

    ::itcl::class xamppSkeletonDev {
        inherit xamppSkeleton
        constructor {environment} {
            chain $environment
        } {
            set name "xampp-skeleton"
            set version 1.8.6
            set rev 11
            set tarballName xampp-skeleton-dev-unix-${version}-${rev}
        }
    }

    ::itcl::class xamppHtdocsUnix {
        inherit program

	protected variable platform
	protected variable http_prefix

        constructor {environment} {
            chain $environment
        } {
	    if {[$be cget -target] == "osx-x64"} {
		set platform osx
	    }  else  {
		set platform linux
	    }
            set name "xampp-htdocs-$platform"
            set version 20221122
            set rev 0
            set tarballName $name-$version.tar.gz
            set licenseRelativePath ""
            set licenseNotes ""

	    set http_prefix /dashboard
        }
	public method extractDirectory {} {
	    return [file join [$be cget -src] xampp-htdocs-$platform]
	}
	public method srcdir {} {
	    return [extractDirectory]
	}
	public method prefix {} {
	    return [$be cget -output]
	}

        public method configureOptions {} {}

	public method build {} {}
        public method install {} {
            if {[string match osx* [$be cget -target]]} {
                set destDir [file join [prefix] xamppfiles]
            } else {
                set destDir [file join [prefix] lampp]
            }
            # clean up htdocs
            file delete -force [file join $destDir htdocs [string trim $http_prefix /]]
	    set directory [lindex [glob -directory [extractDirectory] *] 0]
	    foreach g [glob -tails -directory $directory -type f \
	      * */* */*/* */*/*/* */*/*/*/* */*/*/*/*/* */*/*/*/*/*/* */*/*/*/*/*/*/* */*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/*/*/*] {
		set source [file join $directory $g]
		set destination [file join $destDir htdocs [string trim $http_prefix /] $g]
		file mkdir [file dirname $destination]
		file copy -force $source $destination
	    }
            set id 0
            catch {exec id -u} id
            if {$::tcl_platform(user) == "root" || $id == "0" || [file writable /]} {
                logexec chown -R nobody [file join $destDir htdocs/[string trim $http_prefix /]]
            }
        }
    }

    ::itcl::class fpdf {
        inherit program

        constructor {environment} {
            chain $environment
        } {
            set name "fpdf"
            set version 1.7
            set tarballName fpdf17
            set licenseRelativePath ""
            set licenseNotes ""
        }
        public method srcdir {} {
            return [$be cget -src]/fpdf17
        }
	public method prefix {} {
	    return [$be cget -output]
	}

        public method configureOptions {} {}
        public method build {} {}


        public method install {} {
            cd [srcdir]
            file copy -force fpdf.php [prefix]/lib/php

            file mkdir [prefix]/lib/php/fonts
            foreach f [glob [srcdir]/font/*] {
                xampptcl::util::copyDirectory $f [prefix]/lib/php/fonts
            }
        }
    }

    ::itcl::class curl {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "curl"
            set version 7.53.1
            set licenseRelativePath COPYING
            set licenseNotes http://curl.haxx.se/legal/licmix.html
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-ssl=[prefix] --with-ca-bundle=[file join [$be cget -output] share/curl/curl-ca-bundle.crt]]]
        }
        public method build {} {
            foreach var {LDFLAGS CPPFLAGS CFLAGS} {
                set $var $::env($var)
            }
            set new_ldflags {}
            set new_cppflags {}
            set new_cflags {}

            foreach elem $LDFLAGS {
                if {[string match -I* $elem]} {
                    lappend new_cppflags $elem
                } else {
                    lappend new_ldflags $elem
                }
            }
            foreach elem $CPPFLAGS {
                if {[string match -L* $elem]} {
                    lappend new_ldflags $elem
                } else {
                    lappend new_cppflags $elem
                }
            }
            foreach elem $CFLAGS {
                if {[string match -L* $elem]} {
                    lappend new_ldflags $elem
                } elseif {[string match -I* $elem]} {
                    lappend new_cppflags $elem
                } else {
                    lappend new_cflags $elem
                }
            }
            foreach {var val} [list LDFLAGS $new_ldflags CPPFLAGS $new_cppflags CFLAGS $new_cflags] {
                set ::env($var) $val
            }
            chain
            foreach var {LDFLAGS CPPFLAGS CFLAGS} {
                set ::env($var) [set $var]
            }
        }
    }


    ::itcl::class libiconv {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "libiconv"
            set version 1.15
            set licenseRelativePath COPYING.LIB
        }
        public method setEnvironment {} {
            chain
            set ::opts(libiconv.dir) [prefix]
        }

    }


    ::itcl::class imap_old {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "imap"
            set version 2007e
            set licenseRelativePath LICENSE.txt
        }
        public method setEnvironment {} {
            chain
            set ::opts(imap.src) [srcdir]
        }

        public method build {} {
            cd [srcdir]
            if {[$be targetPlatform] == "linux-x64"} {
                xampptcl::util::substituteParametersInFileRegex Makefile [list {\nEXTRACFLAGS=[^\n]*} "\nEXTRACFLAGS=-fPIC -I[prefix]/include -I[prefix]/include/openssl -L[prefix]/lib" \
                                                                          {\nEXTRALDFLAGS=[^\n]*} "\nEXTRALDFLAGS=-L[prefix]/lib"]

            } else {
                xampptcl::util::substituteParametersInFileRegex Makefile [list {\nEXTRACFLAGS=[^\n]*} "\nEXTRACFLAGS=-I[prefix]/include -I[prefix]/include/openssl -L[prefix]/lib" \
                                                                          {\nEXTRALDFLAGS=[^\n]*} "\nEXTRALDFLAGS=-L[prefix]/lib"]
            }
	    set makeTarget slx

            eval logexec [make] [list $makeTarget]
            cd [srcdir]
            cd c-client
            eval logexec gcc $::env(CFLAGS) -shared -o libc-client.so osdep.o mail.o misc.o newsrc.o smanager.o utf8.o siglocal.o dummy.o pseudo.o netmsg.o flstring.o fdstring.o rfc822.o nntp.o smtp.o imap4r1.o pop3.o unix.o mbx.o mmdf.o tenex.o mtx.o news.o phile.o mh.o mx.o utf8aux.o
            file rename -force  c-client.a libc-client.a
            file rename -force libc-client.so libc-client.so.$version
            logexec ln -s libc-client.so.$version libc-client.so

        }
        public method install {} {
            cd [srcdir]
            cd c-client
            foreach f [glob libc*] {
                file copy -force $f [prefix]/lib
            }
            file mkdir [prefix]/include/c-client
            foreach f {flocksim.h utf8.h utf8aux.h c-client.h env.h env_unix.h fs.h ftl.h imap4r1.h linkage.h mail.h misc.h nl.h nntp.h osdep.h os_slx.h rfc822.h smtp.h tcp.h} {
                if {[file type $f] == "link"} {
                    set target [::xampptcl::file::readlink $f]
                    file copy -force $target [prefix]/include/c-client
                    if {[file tail $target] != [file tail $f]} {
                        cd [prefix]/include/c-client
                        exec ln -sf [file tail $target] [file tail $f]
                        cd [srcdir]/c-client
                    }
                } else {
                    file copy -force $f [prefix]/include/c-client
                }
            }

            addIncludesDir [prefix]/include/c-client
            set c {
                set ::env(CFLAGS) "$::env(CFLAGS) -I[prefix]/include/c-client"
                set ::env(CXXFLAGS) "$::env(CXXFLAGS) -I[prefix]/include/c-client"
            }
        }
    }

    ::itcl::class imap {
        inherit xamppLibraryCommon ::imapssl
        constructor {environment} {
            ::imapssl::constructor $environment
        } {
            set name "imap"
            set version 2007e
            set licenseRelativePath LICENSE.txt
	    set supportsParallelBuild 0
        }
        public method build {} {
            # Custom env
            set cflags "$::env(CFLAGS)"
            set ::env(CFLAGS) "$::env(CFLAGS) -I [srcdir]/c-client -I[srcdir]/src/c-client"
            set cxxflags "$::env(CXXFLAGS)"
            set ::env(CXXFLAGS) "$::env(CXXFLAGS) -I [srcdir]/c-client -I[srcdir]/src/c-client"
            set cppflags "$::env(CPPFLAGS)"
            set ::env(CPPFLAGS) "$::env(CPPFLAGS) -I [srcdir]/c-client -I[srcdir]/src/c-client"
            chain
            set ::env(CFLAGS) "$cflags"
            set ::env(CXXFLAGS) "$cxxflags"
            set ::env(CPPFLAGS) "$cppflags"
	    return
	    #this fails on osx with undefined symbols...
	    # this partially fixes it
	    # g++ -Wl,-U,_mm_flags,-U,_mm_nocritical,-U,_mm_critical,-U,_mm_login,-U,_mm_exists,-U,_mm_expunged,-U,_mm_dlog,-U,_mm_searched,-U,_mm_list,-U,_mm_lsub,-U,_mm_status,-U,_mm_notify,-U,_mm_fatal,-U,_mm_log,-U,_mm_diskerror -O3 -L/opt/lampp/lib -I/opt/lampp/include -I/opt/lampp/include/ncurses -arch x86_64 -shared -o libc-client.dylib osdep.o mail.o misc.o newsrc.o smanager.o utf8.o siglocal.o dummy.o pseudo.o netmsg.o flstring.o fdstring.o rfc822.o nntp.o smtp.o imap4r1.o pop3.o unix.o mbx.o mmdf.o tenex.o mtx.o news.o phile.o mh.o mx.o utf8aux.o
            cd [srcdir]
            cd c-client
	    eval logexec gcc $::env(CFLAGS) -shared -o libc-client.so osdep.o mail.o misc.o newsrc.o smanager.o utf8.o siglocal.o dummy.o pseudo.o netmsg.o flstring.o fdstring.o rfc822.o nntp.o smtp.o imap4r1.o pop3.o unix.o mbx.o mmdf.o tenex.o mtx.o news.o phile.o mh.o mx.o utf8aux.o
            file rename -force  c-client.a libc-client.a
            file rename -force libc-client.so libc-client.so.$version
            logexec ln -s libc-client.so.$version libc-client.so

        }
	public method prefix {} {
	    return [$be cget -output]
	}
        public method install {} {
            cd [srcdir]
            cd c-client
            file copy -force c-client.a [prefix]/lib
            cd [prefix]/lib
            exec ln -sf c-client.a libc-client.a
            cd [srcdir]/c-client
            #foreach f [glob c-client.a] {
            #    file copy -force $f [prefix]/lib
            #}
            file mkdir [prefix]/include/c-client
            foreach f {flocksim.h utf8.h utf8aux.h c-client.h env.h env_unix.h fs.h ftl.h imap4r1.h linkage.h mail.h misc.h nl.h nntp.h osdep.h os_slx.h rfc822.h smtp.h tcp.h} {
                if {[file type $f] == "link"} {
                    set target [::xampptcl::file::readlink $f]
                    file copy -force $target [prefix]/include/c-client
                    if {[file tail $target] != [file tail $f]} {
                        cd [prefix]/include/c-client
                        exec ln -sf [file tail $target] [file tail $f]
                        cd [srcdir]/c-client
                    }
                } else {
                    file copy -force $f [prefix]/include/c-client
                }
            }
            addIncludesDir [prefix]/include/c-client
        }

        public method install-old {} {
            cd [srcdir]
            cd c-client
            foreach f [glob libc*] {
                file copy -force $f [prefix]/lib
            }
            file mkdir [prefix]/include/c-client
            foreach f {flocksim.h utf8.h utf8aux.h c-client.h env.h env_unix.h fs.h ftl.h imap4r1.h linkage.h mail.h misc.h nl.h nntp.h osdep.h os_slx.h rfc822.h smtp.h tcp.h} {
                if {[file type $f] == "link"} {
                    set target [::xampptcl::file::readlink $f]
                    file copy -force $target [prefix]/include/c-client
                    if {[file tail $target] != [file tail $f]} {
                        cd [prefix]/include/c-client
                        exec ln -sf [file tail $target] [file tail $f]
                        cd [srcdir]/c-client
                    }
                } else {
                    file copy -force $f [prefix]/include/c-client
                }
            }

            addIncludesDir [prefix]/include/c-client
            set c {
                set ::env(CFLAGS) "$::env(CFLAGS) -I[prefix]/include/c-client"
                set ::env(CXXFLAGS) "$::env(CXXFLAGS) -I[prefix]/include/c-client"
            }
        }
    }

    ::itcl::class apr {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "apr"
            set version 1.5.2
            set licenseRelativePath LICENSE
        }
        public method configureOptions {} {
            return  [concat [chain] [list --with-installbuilddir=[prefix]/build]]
        }
    }


    ::itcl::class apache {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "apache"
            set fullname Apache
            set version [versions::get "Apache" stable]
            # To use the same as bitnami
            set uniqueIdentifier apache
            set licenseRelativePath LICENSE
            #lappend patchList update_child_status_internal_segfault.patch
            set patchLevel 1
            set supportsParallelBuild 0
            set tarballName httpd-$version.tar.gz
        }
        public method srcdir {} {
            return [file join [$be cget -src] httpd-$version]
        }
        public method setEnvironment {} {
            set ::opts(apache.prefix) [prefix]
        }

        public method configureOptions {} {
            set list  [concat [chain] [list --prefix=[prefix] --enable-nonportable-atomics --enable-so --enable-cgid --sysconfdir=[prefix]/etc --enable-auth-anon \
                                         --enable-auth-dbm --enable-auth-digest --enable-file-cache --enable-echo --enable-charset-lite --enable-cache \
                                         --enable-disk-cache --enable-mem-cache --enable-ext-filter --enable-case-filter --enable-case-filter-in --enable-deflate \
                                         --enable-mime-magic --enable-cern-meta --enable-expires --enable-headers --enable-usertrack --enable-unique-id --enable-proxy \
                                         --enable-proxy-connect --enable-proxy-ftp --enable-proxy-http --enable-bucketeer --enable-http --enable-info --enable-suexec \
                                         --enable-cgid --enable-vhost-alias --enable-speling --enable-rewrite --enable-so --with-z=[prefix]  \
                                         --with-expat=[prefix] --enable-dav --enable-dav-fs --enable-mods-shared=most --with-mpm=prefork \
                                         --with-suexec-caller=nobody --with-suexec-docroot=[prefix]/htdocs --without-berkeley-db --enable-ldap --with-ldap --enable-auth-ldap \
                                         --enable-authnz-ldap --enable-ipv6 --enable-dbd --enable-https --with-nghttp2=[prefix] --with-mysql=[prefix] --with-apr=[prefix]/bin/apr-1-config \
                                         --with-apr-util=[prefix]/bin/apu-1-config --with-pcre=[prefix] --enable-modules=all]]
            lappend list --enable-ssl --with-ssl=$::opts(openssl.prefix)
            return $list
        }
        public method build {} {
            cd [srcdir]
            set ::env(LD_LIBRARY_PATH) $::opts(instantclient.prefix):$::env(LD_LIBRARY_PATH)
            eval logexec ./configure  [configureOptions]
            xampptcl::util::substituteParametersInFile Makefile [list {SHARED_LDFLAGS=} "SHARED_LDFLAGS=-Wl,--rpath -Wl,[prefix]/lib"]
            cd [srcdir]
            eval logexec [make]
        }
        public method install {} {
            chain
            logexec chown nobody [file join [prefix] htdocs]
            if { ![file exists [file join [prefix] modules mod_ssl.so ]] } {
                error "mod_ssl.so file is not present"
                exit
            }
        }
    }

    ::itcl::class icu4c {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "icu4c"
            set version [versions::get "ICU4C" stable]
            set supportsParallelBuild 0
            set licenseRelativePath ../license.html
            set tVersion [string map {. _} $version]
            set tarballName icu4c-$tVersion-src
            set licenseNotes http://source.icu-project.org/repos/icu/icu/trunk/license.html
            set supportsParallelBuild 0

        }

        public method srcdir {} {
            return [$be cget -src]/icu/source
        }

        public method configureOptions {} {
            if {[$be targetPlatform] == "linux-x64"} {
                return [list Linux --prefix=[prefix] --enable-rpath]
            } elseif {[$be targetPlatform] == "osx-x64"} {
		return [list MacOSX --prefix=[prefix] --enable-rpath]
	    } else {
                return [list Linux --prefix=[prefix] --enable-rpath]
            }
        }

        public method build {} {
            cd [srcdir]
            if {[::xampptcl::util::compareVersions $version 67] >= 0 && [$be cget -target] == "linux-x64"} {
                useGCC49Env
            }
            eval logexec ./runConfigureICU [configureOptions]
            eval logexec [make]
            if {[::xampptcl::util::compareVersions $version 67] >= 0 && [$be cget -target] == "linux-x64"} {
                unuseGCC49Env
            }
        }
    }


    ::itcl::class pbxt {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name pbxt
            set version 1.0.11-6-pre-ga
            set licenseRelativePath ""
            set licenseNotes ""
            set supportsParallelBuild 0
        }

        public method configureOptions {} {
            return [concat [chain] [list --with-mysql=$::opts(mysql.srcdir)]]
        }
        public method build {} {
            cd [srcdir]
            eval logexec cmake . -DMYSQL-SOURCE=$::opts(mysql.srcdir) -DWITH-DEBUG=NO -DWITH-PBMS=OFF
            #-DMYSQL-SOURCE=<mysql-source-path>
            #-DWITH-DEBUG={YES/NO/FULL/...}
            #-DWITH-PBMS={ON/OFF}
            eval logexec [make]
        }
    }
    ::itcl::class pbmslib {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name pbmslib
            set version 0.5.15
            set licenseRelativePath ""
            set licenseNotes ""
            set supportsParallelBuild 0
        }
        public method build {} {
            parray ::env
            addIncludesDir [prefix]/include/curl
            chain
        }

    }

    ::itcl::class pbms {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name pbms
            set version 0.5.15-beta
            set licenseRelativePath ""
            set licenseNotes ""
            set supportsParallelBuild 0
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-mysql=$::opts(mysql.srcdir)]]
        }
    }

    ::itcl::class sqlite2 {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "sqlite"
            set version 2.8.17
            set readmePlaceholder SQLITE
            set licenseRelativePath {}
            set licenseNotes http://www.sqlite.org/copyright.html

        }
        public method setEnvironment {} {
            set ::opts(sqlite2.prefix) [prefix]
        }

        public method configureOptions {} {
            return [list --prefix=[prefix]]
        }
        public method build {} {
            cd [srcdir]
            file mkdir bld
            cd bld
            set cflags $::env(CFLAGS)
            set ::env(CFLAGS) "$cflags -DSQLITE_ENABLE_COLUMN_METADATA"
            eval logexec ../configure [configureOptions]
            eval logexec [make]
            set ::env(CFLAGS) "$cflags"
        }
        public method install {} {
            cd [srcdir]/bld
            eval logexec [make] install
        }
    }


    ::itcl::class sqlite {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "sqlite"
            set version [versions::get "SQLite" stable]
            set readmePlaceholder SQLITE
            set licenseRelativePath {}

            # Fix to find SQLite tarballs
            set majorVersion [lindex [split ${version} .] 0]
            set minorVersion [lindex [split ${version} .] 1]
            set patchVersion [lindex [split ${version} .] 2]
            set tailVersion ""
            foreach v "${minorVersion} ${patchVersion}" {
                if {[string length ${v}] < 2} {
                    set tailVersion "${tailVersion}0${v}"
                } else {
                    set tailVersion "${tailVersion}${v}"
                }
            }
            set tarballVersion "${majorVersion}${tailVersion}00"
            set tarballName "${name}-autoconf-${tarballVersion}"
            set licenseNotes http://www.sqlite.org/copyright.html

        }
        public method setEnvironment {} {
            set ::opts(sqlite.prefix) [prefix]
        }
        public method srcdir {} {
            return [file join [$be cget -src] ${tarballName}]
        }
        public method configureOptions {} {
            return [list --prefix=[prefix]]
        }
        public method build {} {
            cd [srcdir]
            file mkdir bld
            cd bld
            set cflags $::env(CFLAGS)
            set ::env(CFLAGS) "$cflags -DSQLITE_ENABLE_COLUMN_METADATA"
            eval logexec ../configure [configureOptions]
            eval logexec [make]
            set ::env(CFLAGS) "$cflags"
        }
        public method install {} {
            cd [srcdir]/bld
            eval logexec [make] install
        }
    }


    ::itcl::class mysql {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "mysql"
            #set version 5.6.10
            set version 5.6.26
            set supportsParallelBuild 1
        }
        public method needsToBeBuilt {} {
            return 1
        }
        public method setEnvironment {} {
            set ::opts(mysql.prefix) [prefix]
            set ::opts(mysql.srcdir) [srcdir]
        }
        public method install {} {
            chain
            foreach f {INSTALL-BINARY README COPYING data sql-bench docs mysql-test bin/mysql.server} {
                file delete -force [file join [prefix] $f]
            }
            cd [prefix]/bin/
            exec ln -sf ../share/mysql/mysql.server mysql.server
        }
        public method build {} {
            parray ::env
            cd [srcdir]
            if {[$be targetPlatform] == "linux-x64"} {
                set ::env(CXX) g++
            } elseif {[$be targetPlatform] == "osx-x64"} {
		set ::env(CXX) g++
	    } else {
		set ::env(CXX) gcc
            }
            if {[file exists [srcdir]/mysys/default.c.orig]} {
                file copy -force [srcdir]/mysys/default.c.orig [srcdir]/mysys/default.c
                file copy -force [srcdir]/mysys/my_sync.c.orig [srcdir]/mysys/my_sync.c
            } else {
                file copy -force [srcdir]/mysys/default.c [srcdir]/mysys/default.c.orig
                file copy -force [srcdir]/mysys/my_sync.c [srcdir]/mysys/my_sync.c.orig
            }
            xampptcl::util::substituteParametersInFile [srcdir]/mysys/default.c [list {/etc/} "[prefix]/etc/" {/etc/mysql/} {/etc/xampp/}]
            xampptcl::util::substituteParametersInFile [srcdir]/mysys/my_sync.c [list DBUG_PRINT //DBUG_PRINT DBUG_ENTER //DBUG_ENTER]
            set ldflags $::env(LDFLAGS)
            set ::env(LDFLAGS) "$ldflags -lssl -ldl"
            eval logexec cmake . -DCMAKE_INSTALL_PREFIX=[prefix] -DINSTALL_PLUGINDIR=lib/mysql/plugin -DENABLED_LOCAL_INFILE=ON -DMYSQL_UNIX_ADDR=[prefix]/var/mysql/mysql.sock -DINSTALL_SBINDIR=sbin -DSYSCONFDIR=[prefix]/etc  -DDEFAULT_SYSCONFDIR=[prefix]/etc -DMYSQL_DATADIR=[prefix]/var/mysql -DINSTALL_INFODIR=[prefix]/info -DWITH_SSL=system -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1  -DOPENSSL_INCLUDE_DIR=[prefix]/include -DOPENSSL_ROOT_DIR=[prefix]/ -DINSTALL_SCRIPTDIR=[prefix]/bin -DINSTALL_SUPPORTFILESDIR=[prefix]/share/mysql
            eval logexec [make]
            set ::env(LDFLAGS) $ldflags
        }
    }
    ::itcl::class mysql56 {
        inherit mysql
        constructor {environment} {
            chain $environment
        } {
            set name "mysql"
            set version 5.6.26
            set supportsParallelBuild 1
        }
        public method install {} {
            chain
            #http://bugs.mysql.com/bug.php?id=69254
            xampptcl::util::substituteParametersInFile [file join [prefix] bin/mysqld_safe] [list {msg="`date +'%y%m%d %H:%M:%S'` mysqld_safe $*"} {msg="`date +'%Y-%m-%d %H:%M:%S'` $$ mysqld_safe $*"}]
        }
        public method build {} {
            cd [srcdir]
            set ::env(CXX) g++

            if {[file exists [srcdir]/mysys_ssl/my_default.cc.orig]} {
                file copy -force [srcdir]/mysys_ssl/my_default.cc.orig [srcdir]/mysys_ssl/my_default.cc
                file copy -force [srcdir]/mysys/my_sync.c.orig [srcdir]/mysys/my_sync.c
            } else {
                file copy -force [srcdir]/mysys_ssl/my_default.cc [srcdir]/mysys_ssl/my_default.cc.orig
                file copy -force [srcdir]/mysys/my_sync.c [srcdir]/mysys/my_sync.c.orig
            }

            xampptcl::util::substituteParametersInFile [srcdir]/mysys_ssl/my_default.cc [list {/etc/} "[prefix]/etc/" {/etc/mysql/} {/etc/xampp/}]
            xampptcl::util::substituteParametersInFile [srcdir]/mysys/my_sync.c [list DBUG_PRINT //DBUG_PRINT DBUG_ENTER //DBUG_ENTER]
            xampptcl::util::substituteParametersInFile [srcdir]/cmake/ssl.cmake [list {REGEX "^#define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9].*"} {REGEX "^#[\t ]*define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9].*"}]

            set ldflags $::env(LDFLAGS)
            set ::env(LDFLAGS) "$ldflags -lssl -ldl -lstdc++"
            eval logexec cmake . -DCMAKE_INSTALL_PREFIX=[prefix] -DINSTALL_PLUGINDIR=lib/mysql/plugin -DENABLED_LOCAL_INFILE=ON -DMYSQL_UNIX_ADDR=[prefix]/var/mysql/mysql.sock -DINSTALL_SBINDIR=sbin -DSYSCONFDIR=[prefix]/etc  -DDEFAULT_SYSCONFDIR=[prefix]/etc -DMYSQL_DATADIR=[prefix]/var/mysql -DINSTALL_INFODIR=[prefix]/info -DWITH_SSL=system -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1  -DOPENSSL_INCLUDE_DIR=[prefix]/include -DOPENSSL_ROOT_DIR=[prefix]/ -DINSTALL_SCRIPTDIR=[prefix]/bin -DINSTALL_SUPPORTFILESDIR=[prefix]/share/mysql
            eval logexec [make]
            set ::env(LDFLAGS) $ldflags
        }
    }


    ::itcl::class mariadb10 {
        inherit mysql56
        constructor {environment} {
            chain $environment
        } {
            set name "mariadb"
            set fullname MariaDB
            set version [versions::get "MariaDB" "10"]
            if {[$be targetPlatform] == "osx-x64"} {
                set patchList {TokuDB-MacOS.patch mariadb-clock_realtime.patch}
            }
        }
        public method srcdir {} {
            return [$be cget -src]/mariadb-$version
        }
        public method build {} {
            cd [srcdir]
            set ::env(CXX) g++

            if {[file exists [srcdir]/mysys/my_default.c.orig]} {
                file copy -force [srcdir]/mysys/my_default.c.orig [srcdir]/mysys/my_default.c
                file copy -force [srcdir]/mysys/my_sync.c.orig [srcdir]/mysys/my_sync.c
            } else {
                file copy -force [srcdir]/mysys/my_default.c [srcdir]/mysys/my_default.c.orig
                file copy -force [srcdir]/mysys/my_sync.c [srcdir]/mysys/my_sync.c.orig
            }

            xampptcl::util::substituteParametersInFile [srcdir]/mysys/my_default.c [list {/etc/} "[prefix]/etc/" {/etc/mysql/} {/etc/xampp/}]
            xampptcl::util::substituteParametersInFile [srcdir]/mysys/my_sync.c [list DBUG_PRINT //DBUG_PRINT DBUG_ENTER //DBUG_ENTER]
            xampptcl::util::substituteParametersInFile [srcdir]/cmake/ssl.cmake [list {REGEX "^#define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9].*"} {REGEX "^#[\t ]*define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9].*"}]

            # See fixed on https://github.com/MariaDB/server/commit/36bf482
            if {[$be targetPlatform] == "osx-x64"} {
                xampptcl::util::substituteParametersInFile [srcdir]/storage/connect/xobject.cpp [list  "#include \"my_global.h\"" "#include \"my_global.h\"\n#include \"m_string.h\""]
                # MariaDB provides its own implementation of strnlen but it is not used when compiling the "auth_gssapi" plugin. We force it here.
                xampptcl::util::substituteParametersInFile [file join [srcdir] "plugin" "auth_gssapi" "client_plugin.cc"] [list  "#include \"common.h\"" "#include \"common.h\"\n#include \"m_string.h\""]
                xampptcl::file::prependTextToFile [file join [srcdir] "plugin" "auth_gssapi" "CMakeLists.txt"] \
                    {SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -lstrings -L../../strings" )
                        SET ( HAVE_KRB5_FREE_UNPARSED_NAME 1 )
                    }
            }

            set ldflags $::env(LDFLAGS)
            set ::env(LDFLAGS) "$ldflags -lssl -lcrypto -ldl -lstdc++ -L[prefix]/include/openssl -L[prefix]/share/openssl"
            if { [$be cget -target] == "osx-x64"} {
                # ROCKSDB_SUPPORT_THREAD_LOCAL: our OS X version does not support thread local features, but the CMAKE logic enables it by default for OS X platforms.
                # __MACH__: this macro doesn't only define OS X features but GNU/Hurd as well. Both platforms are based on the MACH microkernel. OS X compilation fails if set.
                set ::env(CPPFLAGS) "-Qunused-arguments -UROCKSDB_SUPPORT_THREAD_LOCAL -U__MACH__ $::env(CPPFLAGS)"
                set ::env(CFLAGS) "-Qunused-arguments -UROCKSDB_SUPPORT_THREAD_LOCAL -U__MACH__ $::env(CFLAGS)"

                # Starting from MariaDB 10.4.14, upstream is using ld arguments not present in our ld version (-z)
                xampptcl::util::substituteParametersInFile [file join [srcdir] CMakeLists.txt] [list {MY_CHECK_AND_SET_LINKER_FLAG("-Wl,-z,relro,-z,now")} {# MY_CHECK_AND_SET_LINKER_FLAG("-Wl,-z,relro,-z,now")}] 1
            }
            # Show environment
            showEnvironmentVars

            # Start building
            eval logexec cmake . -DCMAKE_INSTALL_PREFIX=[prefix] -DINSTALL_PLUGINDIR=lib/mysql/plugin -DENABLED_LOCAL_INFILE=ON -DMYSQL_UNIX_ADDR=[prefix]/var/mysql/mysql.sock -DINSTALL_SBINDIR=sbin -DSYSCONFDIR=[prefix]/etc  -DDEFAULT_SYSCONFDIR=[prefix]/etc -DMYSQL_DATADIR=[prefix]/var/mysql -DINSTALL_INFODIR=[prefix]/info -DWITH_SSL=system -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1  -DOPENSSL_INCLUDE_DIR=[prefix]/include -DOPENSSL_ROOT_DIR=[prefix]/ -DINSTALL_SCRIPTDIR=[prefix]/bin -DINSTALL_SUPPORTFILESDIR=[prefix]/share/mysql -DCMAKE_PREFIX_PATH=[prefix]/include/ncurses/ -DCURSES_INCLUDE_PATH=[prefix]/include/ncurses/ -DPLUGIN_TOKUDB=NO -DWITHOUT_MROONGA_STORAGE_ENGINE=YES

            # MariaDB is intended to be compiled using the OS-X system "libtool" library which includes the "-static" option.
            # The GNU "libtool" we add as a build dependency, since PHP requires, it does not have that option.
            # This is a patch to compile MariaDB with the OS-X system "libtool" library.
            if {[$be targetPlatform] == "osx-x64"} {
                xampptcl::util::substituteParametersInFile  [srcdir]/cmake/libutils.cmake [list {libtool -static} "/usr/bin/libtool -static"]
            }
            # Fix error "'mutable' and 'const' cannot be mixed"
            if {[string match osx* [$be cget -target]]} {
                xampptcl::util::substituteParametersInFile /Library/Developer/CommandLineTools/usr/include/c++/v1/iterator [list "mutable _Iter" "/* mutable */ _Iter"]
            }
            eval logexec [make]
            if {[string match osx* [$be cget -target]]} {
                xampptcl::util::substituteParametersInFile /Library/Developer/CommandLineTools/usr/include/c++/v1/iterator [list "/* mutable */ _Iter" "mutable _Iter"]
            }
            set ::env(LDFLAGS) $ldflags
        }
        public method install {} {
            chain
            foreach f { COPYING.LESSER CREDITS EXCEPTIONS-CLIENT scripts support-files} {
                file delete -force [file join [prefix] $f]
            }
            foreach f [glob -nocomplain [prefix]/include/mysql/*] {
                if {![file exists [file join [prefix] include [file tail $f]]]} {
                    file copy -force $f [prefix]/include/
                }
            }
            file delete -force [prefix]/include/mysql/
        }
    }

    ::itcl::class ncurses {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "ncurses"
            set version 5.9
            set licenseRelativePath ANNOUNCE
            set licenseNotes http://www.gnu.org/software/ncurses/ncurses.html
           if { [$be cget -target] == "osx-x64" } {
               # Issue http://lists.gnu.org/archive/html/bug-ncurses/2011-04/msg00002.html
               set patchStrip 1
               set patchList {ncurses-clang.patch}
           }
        }
        public method build {} {
            chain
            set releaseCflags {}
            set releaseCxxFlags {}
            catch {set releaseCflags $::env(RELEASE_CFLAGS)}
            catch {set releaseCxxFlags $::env(RELEASE_CXXFLAGS)}
            set ::env(RELEASE_CFLAGS) "$releaseCflags -I[prefix]/include/ncurses"
            set ::env(RELEASE_CXXFLAGS) "$releaseCxxFlags -I[prefix]/include/ncurses"

        }
        public method setEnvironment {} {
	    set ::opts(ncurses.prefix) [prefix]
            addIncludesDir [prefix]/include/ncurses
        }

        public method configureOptions {} {
            return [concat [chain] [list --with-shared]]
        }
    }


    ::itcl::class perl {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "perl"
            set version [versions::get "Perl" "stable"]
            set licenseRelativePath Copying
        }
        public method configureOptions {} {
            if {[$be targetPlatform] == "linux-x64"} {
                return [concat [chain] [list -Dprefix=[prefix] -des -Dcc=gcc -Dusethreads -Accflags='-fPIC']]
            } else {
                return [concat [chain] [list -Dprefix=[prefix] -des -Dcc=gcc -Dusethreads]]
            }
        }
        public method needsToBeBuilt {} {
            return 1
        }
        public method setEnvironment {} {
            set ::opts(perl.srcdir) [srcdir]
            set ::opts(perl.prefix) [prefix]
        }
        public method build {} {
            cd [srcdir]
            eval logexec sh Configure [configureOptions]
        }

    }


    ::itcl::class freetds {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "freetds"
            set version 0.91
        }
        public method configureOptions {} {
            return [concat [chain] [list --enable-shared --with-ssl]]
        }
    }


    ::itcl::class ming {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "ming"
            set version 0.4.5
            set supportsParallelBuild 0
        }
        public method configureOptions {} {
            # ::xampp::ming fails with http://stackoverflow.com/questions/15745753/ming-compilation-fails
            #return [concat [chain] [list --enable-php --with-freetype-config=[prefix]/bin/freetype-config]]
            return [concat [chain] [list --with-freetype-config=[prefix]/bin/freetype-config]]
        }
        public method build {} {
            set ::env(PHPIZE) [prefix]/bin/phpize
            set ::env(PHP) [prefix]/bin/php
            chain
        }

    }


    ::itcl::class gdbm {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "gdbm"
            set version 1.8.3
        }
        public method configureOptions {} {
            if {[$be targetPlatform] == "linux"} {
                return [concat [chain] [list --build=i386-lampp-linux --with-gnu-ld]]
            } elseif {[$be targetPlatform] == "osx-x64"} {
                return [chain]
            } else {
                return [concat [chain] [list --with-gnu-ld]]
	    }
        }
        public method build {} {
	    if {[$be targetPlatform] == "osx-x64"} {
		xampptcl::util::substituteParametersInFile [srcdir]/Makefile.in [list {prefix = /usr/local} "prefix = [prefix]" {-o $(BINOWN) -g $(BINGRP)} {}]
	    } else {
		xampptcl::util::substituteParametersInFile [srcdir]/Makefile.in [list {prefix = /usr/local} "prefix = [prefix]"]
	    }
            chain
        }
    }


    ::itcl::class tiff {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "tiff"
	        set version 4.0.1

            set licenseRelativePath COPYRIGHT
        }
        public method callConfigure {} {
	    chain
        }
    }

    # The project is essentially dead and has been purged from Debian and Ubuntu some time ago. A possible replacement is xsltproc.
    ::itcl::class sablotron {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "sablotron"
            set version 1.0.3
            set licenseRelativePath README
            set tarballName Sablot-$version
            set licenseNotes ""
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-expat=[prefix] --with-expat-prefix=[prefix]]]
        }
        public method build {} {
            if {[$be targetPlatform] == "linux"} {
		set ldflags $::env(LDFLAGS)
		set ::env(LDFLAGS) "-lstdc++ $::env(LDFLAGS)"
		chain
		set ::env(LDFLAGS) $ldflags
	    } else {
                chain
            }
        }
        public method srcdir {} {
            return [$be cget -src]/Sablot-$version
        }
    }

    ::itcl::class jpeg {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "jpeg"
            set uniqueIdentifier jpegsrc
            set version 9c
            set licenseRelativePath README
            set licenseNotes http://www.ijg.org/
            set tarballName jpegsrc.v$version
        }
        public method configureOptions {} {
            if {[$be targetPlatform] == "linux"} {
                return [concat [chain] [list --enable-shared --build=i386-lampp-linux]]
            } else {
                return [concat [chain] [list --enable-shared]]
            }
        }
        public method setEnvironment {} {
            set ::opts(jpegsrc.prefix) [prefix]
        }

    }


    ::itcl::class libapreq2 {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "libapreq2"
            set version 2.13
            set licenseRelativePath LICENSE
        }
        public method needsToBeBuilt {} {
            return 1
        }

        public method configureOptions {} {
            return [concat [chain] [list --prefix=[prefix] --with-apache2-apxs=[prefix]/bin/apxs --cflags="-L[prefix]/lib"]]
        }

        public method build {} {
            cd [srcdir]
            eval logexec perl Makefile.PL [configureOptions]
            eval logexec [make]
        }
    }


    ::itcl::class zziplib {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "zziplib"
            set version 0.13.23
            # this one requires python, not available in the xampp chroot...
            #set version 0.13.62
            set licenseRelativePath COPYING.LIB
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-zlib=[prefix]]]
        }
        public method build {} {
            xampptcl::util::substituteParametersInFile [srcdir]/bins/zziptest.c [list {(char *)hdr += hdr->d_reclen;} {hdr = (char *)hdr + hdr->d_reclen;}]
            chain
        }
    }

    ::itcl::class cpanLWP {
        inherit ::cpanLWP

        constructor {environment} {
            chain $environment
        } {
        }
        public method build {} {
            cd [srcdir]
            xampptcl::util::substituteParametersInFile [srcdir]/talk-to-ourself [list "\#!perl -w" "\#!perl -w\nexit 0;"]
            # using yes command results in child killed: write on pipe with no readers

            eval logexec [list echo "[string repeat y\n 20]"] | [file join [prefix] bin perl] Makefile.PL [configureOptions]
            eval logexec [make]
        }
        protected method configureOptions {} {}
    }

    ::itcl::class postgresql {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "postgresql"
            set version [versions::get "PostgreSQL" 14]
            set licenseRelativePath COPYRIGHT
            set licenseNotes {MIT License Style:Permission to use, copy, modify, and distribute this software}
        }
        public method configureOptions {} {
            return [concat [chain] [list  --without-readline --without-zlib --with-openssl]]
        }
        public method setEnvironment {} {
            set ::env(PATH) "[prefix]/bin:$::env(PATH)"
        }
        public method build {} {
            set cflags  $::env(CFLAGS)
            set cppflags $::env(CXXFLAGS)
            set ::env(CFLAGS) "-I[srcdir]/src/interfaces/ecpg/include $cflags"
            set ::env(CXXFLAGS) "-I[srcdir]/src/interfaces/ecpg/include $cppflags"
            chain
            set ::env(CFLAGS) "$cflags"
            set ::env(CXXFLAGS) "$cppflags"
        }
        public method install {} {
            chain
            # Php will expect finding the libs here
            foreach l [glob [file join [prefix] lib libpq.*]] {
                file copy -force $l [file join [$be cget -output] lib]
            }
        }
        public method prefix {} {
            return [file join [chain] postgresql]
        }
    }

    ::itcl::class gd {
        inherit xamppLibraryCommon ::gd
        constructor {environment} {
            ::gd::constructor $environment
        } {
            set version 2.2.5
        }
        public method srcdir {} {
            return [file join [$be cget -src] "libgd-gd-$version"]
        }
        public method cmakeOptions {} {
            return [list -DCMAKE_INSTALL_PREFIX=[$be cget -output] -DENABLE_FONTCONFIG=0 -DENABLE_XPM=0 \
                        -DENABLE_PNG=1 -DPNG_LIBRARY=[$be cget -output] -DPNG_PNG_INCLUDE_DIR=[$be cget -output]/include \
                        -DENABLE_JPEG=1 -DJPEG_LIBRARY=[$be cget -output] -DJPEG_INCLUDE_DIR=[$be cget -output]/include \
                        -DENABLE_TIFF=1 -DTIFF_LIBRARY=[$be cget -output] -DTIFF_INCLUDE_DIR=[$be cget -output]/include \
                        -DENABLE_FREETYPE=1 -DFREETYPE_LIBRARY=[$be cget -output] -DFREETYPE_INCLUDE_DIRS=[$be cget -output]/include \
                        -DENABLE_WEBP=1 -DWEBP_LIBRARY=[$be cget -output]]
        }

        public method build {} {
            cd [srcdir]

            # GD needs special flags
            set oldLdflags "$::env(LDFLAGS)"
            set ::env(LDFLAGS) "$::env(LDFLAGS) -lpng -ljpeg -lz -ltiff -lfreetype"
            eval logexec cmake . [cmakeOptions]

            eval logexec [make]

            # Restore LDFLAGS
            set ::env(LDFLAGS) "$oldLdflags"

            # Mark build as complete
            ::xampptcl::file::write [file join [srcdir] .buildcomplete] {}
        }
        public method install {} {
            # Avoid issue setting mkdir command before running make
            xampptcl::util::substituteParametersInFileRegex [srcdir]/Makefile \
                [list {mkdir_p\s*=[^\n]*} {mkdir_p = /bin/mkdir -p}]
            eval logexec make install

            # Install .so library at 'output/lib' instead of 'output/lib64'
            if {[file exists [file join [$be cget -output] lib64 libgd.so]]} {
                file rename -force [file join [$be cget -output] lib64 libgd.so] [file join [$be cget -output] lib libgd.so]
            }
        }
    }


    ::itcl::class firebird {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "firebird"
            set version 1.5.2.4731
            set supportsParallelBuild 0
        }
        public method setEnvironment {} {
            set ::env(PATH) "[prefix]/bin:$::env(PATH)"
        }

        public method prefix {} {
            return [file join [chain] firebird]
        }
        public method configureOptions {} {
            return [concat [chain] [list --without-editline]]
        }
        public method install {} {
            eval [list logexec yes | [make] install]
        }

    }


    ::itcl::class proftpd {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "proftpd"
            set version 1.3.6
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-modules=mod_sql:mod_sql_mysql:mod_tls --with-includes=[prefix]/include:[prefix]/include/ncurses --with-libraries=[prefix]/lib/]]
        }
        public method install {} {
            chain
            if {[$be targetPlatform] == "osx-x64"} {
                foreach bin {sbin/proftpd bin/ftpdctl} {
                    set bin [file join [prefix] $bin]
                    set out [exec otool -L $bin]
                    foreach l [split $out \n] {
                        set lib [lindex [string trim $l] 0]
                        if {[string match *libmariadb* $lib]} {
                            if {![string match [file join [prefix] lib/libmariadb*] $lib]} {
                                exec install_name_tool -change $lib [file join [prefix] lib [file tail $lib]] $bin
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    ::itcl::class mhash {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "mhash"
            set version 0.9.9.9
        }
	public method build {} {
	    # We get an error related to rpath:
	    # ld: in /opt/lampp/lib, can't map file, errno=22 for architecture x86_64
	    if {[$be cget -target] == "osx-x64"} {
		set ldflags $::env(LDFLAGS)
		unset ::env(LDFLAGS)
		chain
		set ::env(LDFLAGS) $ldflags
	    } else {
		chain
	    }
	}
    }


    ::itcl::class modperl {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name modperl
            set version 2.0.12
            set licenseRelativePath LICENSE
            set tarballName mod_perl-$version
        }
        public method needsToBeBuilt {} {
            return 1
        }
        public method srcdir {} {
            return [$be cget -src]/mod_perl-$version
        }

        public method configureOptions {} {
            set opts [concat [chain] [list MP_APXS=[prefix]/bin/apxs MP_APR_CONFIG=[prefix]/bin/apr-1-config -prefix=[prefix]  --prefix=[prefix] --cflags="-L[prefix]/lib"]]
            if {[$be targetPlatform] == "osx-x64"} {
                set opts [concat $opts [list MP_CCOPTS=-std=gnu89]]
            }
            return $opts
        }
        public method build {} {
            set ::opts(modperl.srcdir) [srcdir]
            cd [srcdir]
            eval logexec perl Makefile.PL [configureOptions]
            eval logexec [make]
        }
    }


    ::itcl::class openssh {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "openssh"
            set version 6.2p1
            set licenseRelativePath LICENCE
            #set version 4.5p1
        }
        public method configureOptions {} {
            return [concat [chain] [list --without-zlib-version-check]]
        }

        public method build {} {
            addIncludesDir [srcdir]
            chain
        }
    }


    ::itcl::class mmcache {
        inherit xampp_pecl_extension
        constructor {environment} {
            chain $environment
        } {
            set name "mmcache"
            set version 2.4.6
            set tarballName turck-mmcache-2.4.6
        }
        public method srcdir {} {
            return [$be cget -src]/turck-mmcache-$version
        }
        public method configureOptions {} {
            return [concat [chain] [list --enable-mmcache=shared]]
        }
    }


    ::itcl::class webalizer {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "webalizer"
            set version 2.23-05
            set tarballName webalizer-2.23-05-src
        }

        public method configureOptions {} {
            return [concat [chain] [list --with-gdlib=[prefix]/lib --with-gd=[prefix]/include --with-zlib=[prefix] --with-etcdir=[prefix]/etc --enable-dns --with-geodb=/opt/xampp/share/GeoDB]]
        }
    }


    ::itcl::class aprutil {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "apr-util"
            set version 1.5.4
            set licenseRelativePath LICENSE
        }
        public method configureOptions {} {
            return [concat [chain] [list --with-apr=[prefix] --with-ldap --with-ldap-include=[prefix]/include --with-ldap-lib=[prefix]/lib --with-expat=[prefix] --with-iconv=[prefix]]]
        }

        public method build {} {
            set ldLibPath {}
            catch {set ldLibPath $::env(LD_LIBRARY_PATH)}
            set ::env(LD_LIBRARY_PATH) [prefix]/lib:$ldLibPath
            chain
            set ::env(LD_LIBRARY_PATH) $ldLibPath
        }
    }

    ::itcl::class nghttp2 {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "nghttp2"
            set version 1.18.1
            set licenseRelativePath COPYING
        }
    }

    ::itcl::class phpmyadmin {
        inherit phpBitnamiProgram
        constructor {environment} {
            set name phpmyadmin
            chain $environment
        } {
            set fullname "phpMyAdmin"
            set version [getVtrackerField $name version frameworks]
            set tarballName phpMyAdmin-$version-all-languages
            set licenseRelativePath LICENSE
            set createHtaccessFile 1
        }
        public method srcdir {} {
            return [file join [$be cget -src] phpMyAdmin-$version-all-languages]
        }
        public method copyStackLogoImage {} {}
        public method copyProjectFiles {args} {}
	public method prefix {} {
	    return [$be cget -output]
	}
        public method install {} {
            file delete -force [prefix]/phpmyadmin
            file copy -force [srcdir] [prefix]/phpmyadmin
            cd [prefix]/phpmyadmin
            file copy -force config.sample.inc.php config.inc.php
            xampptcl::util::substituteParametersInFile [prefix]/phpmyadmin/config.inc.php [list {$cfg['blowfish_secret'] = ''; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */} {$cfg['blowfish_secret'] = 'xampp'; /* YOU SHOULD CHANGE THIS FOR A MORE SECURE COOKIE AUTH! */} \
                                                                                           {$cfg['Servers'][$i]['auth_type'] = 'cookie';} {$cfg['Servers'][$i]['auth_type'] = 'config';
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = '';} \
                                                                                           {$cfg['Servers'][$i]['host'] = 'localhost';} {//$cfg['Servers'][$i]['host'] = 'localhost';} \
                                                                                           {$cfg['Servers'][$i]['AllowNoPassword'] = false;} {$cfg['Servers'][$i]['AllowNoPassword'] = true;} \
                                                                                           {// $cfg['Servers'][$i]['controluser'] = 'pma';} {$cfg['Servers'][$i]['controluser'] = 'pma';} \
                                                                                           {// $cfg['Servers'][$i]['controlpass'] = 'pmapass';} {$cfg['Servers'][$i]['controlpass'] = '';} \
                                                                                           {// $cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';} {$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';} \
                                                                                           {// $cfg['Servers'][$i]['relation'] = 'pma__relation';} {$cfg['Servers'][$i]['relation'] = 'pma__relation';} \
                                                                                           {// $cfg['Servers'][$i]['table_info'] = 'pma__table_info';} {$cfg['Servers'][$i]['table_info'] = 'pma__table_info';} \
                                                                                           {// $cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';} {$cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';} \
                                                                                           {// $cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';} {$cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';} \
                                                                                           {// $cfg['Servers'][$i]['column_info'] = 'pma__column_info';} {$cfg['Servers'][$i]['column_info'] = 'pma__column_info';} \
                                                                                           {// $cfg['Servers'][$i]['history'] = 'pma__history';} {$cfg['Servers'][$i]['history'] = 'pma__history';} \
                                                                                           {// $cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';} {$cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';} \
                                                                                           {// $cfg['Servers'][$i]['tracking'] = 'pma__tracking';} {$cfg['Servers'][$i]['tracking'] = 'pma__tracking';} \
                                                                                           {// $cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';} {$cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';} \
                                                                                           {// $cfg['Servers'][$i]['recent'] = 'pma__recent';} {$cfg['Servers'][$i]['recent'] = 'pma__recent';
$cfg['Servers'][$i]['users'] = 'pma__users';
$cfg['Servers'][$i]['usergroups'] = 'pma__usergroups';
$cfg['Servers'][$i]['navigationhiding'] = 'pma__navigationhiding';
$cfg['Servers'][$i]['savedsearches'] = 'pma__savedsearches';
$cfg['Servers'][$i]['central_columns'] = 'pma__central_columns';
$cfg['Servers'][$i]['designer_coords'] = 'pma__designer_coords';
$cfg['Servers'][$i]['designer_settings'] = 'pma__designer_settings';
$cfg['Servers'][$i]['export_templates'] = 'pma__export_templates';
$cfg['Servers'][$i]['favorite'] = 'pma__favorite';} \
                                                                                           {// $cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';} {$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';}] 1

            catch {exec chown nobody [prefix]/phpmyadmin/config.inc.php}
        }
    }
    ::itcl::class php {
        inherit xamppLibrary
        constructor {environment} {
            chain $environment
        } {
            set name "php"
            set fullname PHP
            set version [::xampp::php::getXAMPPVersion 74]
            set licenseRelativePath LICENSE
            set supportsParallelBuild 0
        }

        public proc getXAMPPVersion {id} {
            switch -glob -- $id {
                7.4 - 74 { return [versions::get "PHP" 74] }
                8.0 - 80 { return [versions::get "PHP" 80] }
                8.1 - 81 { return [versions::get "PHP" 81] }
                8.2 - 82 { return [versions::get "PHP" 82] }
            }
        }

        public proc getXAMPPRevision {id} {
            switch -glob -- $id {
                7.4 - 74 { return [revisions::get "xamppstack" 74] }
                8.0 - 80 { return [revisions::get "xamppstack" 80] }
                8.1 - 81 { return [revisions::get "xamppstack" 81] }
                8.2 - 82 { return [revisions::get "xamppstack" 82] }
            }
        }
        public method configureOptions {} {
            # they had this and interbase compiled under /opt/interbase
            # --with-interbase=shared,/opt/interbase

            set opts [list --prefix=[prefix] --with-apxs2=[prefix]/bin/apxs --with-config-file-path=[prefix]/etc --with-mysql=mysqlnd --enable-inline-optimization --disable-debug \
                          --enable-bcmath --enable-calendar --enable-ctype --enable-exif --enable-ftp --enable-gd-native-ttf --enable-magic-quotes --enable-shmop \
                          --disable-sigchild --enable-sysvsem --enable-sysvshm --enable-wddx --with-gdbm=[prefix] --with-jpeg-dir=[prefix] --with-png-dir=[prefix] \
                          --with-freetype-dir=[prefix] --with-zlib=yes --with-zlib-dir=[prefix] --with-openssl=[prefix] --with-xsl=[prefix] --with-ldap=[prefix] \
                          --with-gd  --with-imap=$::opts(imap.src) --with-imap-ssl --with-gettext=[prefix]  --with-mssql=shared,[prefix] --with-pdo-dblib=shared,[prefix] --with-sybase-ct=[prefix] \
                          --with-mysql-sock=[prefix]/var/mysql/mysql.sock --with-oci8=shared,instantclient,[prefix]/lib/instantclient \
                          --with-mcrypt=[prefix] --with-mhash=[prefix] --enable-sockets --enable-mbstring=all --with-curl=[prefix] --enable-mbregex \
                          --enable-zend-multibyte --enable-exif --with-bz2=[prefix] --with-sqlite=shared,[prefix]  --with-sqlite3=[prefix] --with-libxml-dir=[prefix] \
                          --enable-soap --with-xmlrpc --enable-pcntl --with-mysqli=mysqlnd  --with-pgsql=shared,[prefix]/  --with-iconv=$::opts(libiconv.dir) --with-pdo-mysql=mysqlnd \
                          --with-pdo-pgsql=[prefix]/postgresql --with-pdo_sqlite=[prefix] --with-icu-dir=[prefix] --enable-fileinfo --enable-phar --enable-zip --enable-mbstring --disable-huge-code-pages]
            if {[$be targetPlatform] != "osx-x64"} {
                # Fails with:
                # /usr/include/c++/4.2.1/ctime:64: error: expected constructor, destructor, or type conversion before 'namespace'
                # make: *** [ext/intl/msgformat/msgformat_helpers.lo] Error 1
                lappend opts --enable-intl
            } else {
                # Fix for 5.5.18 (recent version should be fixed) https://bugs.php.net/bug.php?id=68114
                lappend opts ac_cv_decimal_fp_supported=no
            }

            lappend opts --with-libzip

            # Specific options for PHP 7.4.x
            if {[xampptcl::util::compareVersions $version "7.4.0"] >= 0} {
                lappend opts --with-pear --enable-gd --with-jpeg --with-libwebp --with-freetype --with-zip
            }

            set opts [listFilter $opts [list --with-oci8*]]

            return [concat [chain] $opts]
        }

        public method build {} {
            set oldCflags $::env(CFLAGS)
            set ::env(CFLAGS) "-std=gnu99 $::env(CFLAGS)"
            cd [srcdir]
            file delete ~/.pearrc
            if {[xampptcl::util::compareVersions $version "7.1.0"] < 0} {
                #exec ln -sf $::opts(instantclient.prefix) [$be cget -output]/lib/instantclient
                xampptcl::util::substituteParametersInFile [srcdir]/ext/mysqlnd/mysqlnd.c [list /tmp/mysql.sock [prefix]/var/mysql/mysql.sock]
            }

            #Avoid php 5.4.25 download install-pear-nozlib.phar
            if {[::xampptcl::util::compareVersions $version 7.4.0] < 0} {
                xampptcl::util::substituteParametersInFile [file join [srcdir] makedist]  \
                    [list {wget http://pear.php.net/install-pear-nozlib.phar -nd -P pear/} {ls pear/install-pear-nozlib.phar}]
            }  else {
                xampptcl::util::substituteParametersInFile [file join [srcdir] scripts dev makedist]  \
                    [list {wget http://pear.php.net/install-pear-nozlib.phar -nd -P pear/} {ls pear/install-pear-nozlib.phar}]
            }

            showEnvironmentVars

            if {[$be targetPlatform] == "osx-x64"} {
                file mkdir [srcdir]/configure-libs
                foreach f [glob [prefix]/lib/libbz2.*] {
                    file copy -force $f [srcdir]/configure-libs
                }
                eval logexecEnv [list [list DYLD_LIBRARY_PATH [srcdir]/configure-libs]] ./configure [configureOptions]
            } else {
                eval logexec ./configure [configureOptions]
            }

            xampptcl::util::substituteParametersInFileRegex  [srcdir]/Makefile [list {BZ2_SHARED_LIBADD =[^\n]*} {BZ2_SHARED_LIBADD = -Wl,-rpath,[prefix]/lib}]

            if {[string match *osx* [$be targetPlatform]]} {
                foreach f [glob $::opts(libtool.prefix)/lib/libltdl*] {
                    file copy -force $f [prefix]/lib
                }
            }
            xampptcl::util::substituteParametersInFile  [srcdir]/Makefile [list {-lltdl} "[prefix]/lib/libltdl.a"]
            eval logexec [make]
            set ::env(CFLAGS) $oldCflags
        }
        public method setEnvironment {} {
            set ::opts(php.prefix) [prefix]
            set ::env(PHP_PREFIX) [prefix]
            set ::opts(pear.prefix) $::opts(php.prefix)/lib/php

            # Set pkg-config environment variable to properly find missing dependencies
            if [info exists ::env(PKG_CONFIG_PATH)] {
                set ::env(PKG_CONFIG_PATH) "[prefix]/lib/pkgconfig:$::env(PKG_CONFIG_PATH)"
            } else {
                set ::env(PKG_CONFIG_PATH) "[prefix]/lib/pkgconfig"
            }
        }

        public method install {} {
            file delete -force [prefix]/lib/php
            chain
            file delete -force [prefix]/pear
            cd [srcdir]
            cd [prefix]/bin
            cd [prefix]/bin
            foreach f {php php-cgi phpize php-config} {
                file copy -force $f $f-$version
                exec ln -sf $f-$version $f
            }
            set ::opts(php.prefix) [prefix]
            set ::env(PHP_PREFIX) [prefix]
            set ::opts(pear.prefix) $::opts(php.prefix)/lib/php
	    if {[file exists [$be cget -output]/lib/instantclient] && [file type [$be cget -output]/lib/instantclient] == "link"} {
                set target [::xampptcl::file::readlink [$be cget -output]/lib/instantclient]
                if {![string match [$be cget -output]/* $target]} {
                    file delete -force [$be cget -output]/lib/instantclient
                }
            }
            includeCplusplus $be [prefix]/lib
            includeLibGcc $be [prefix]/lib
            if {[$be targetPlatform] == "osx-x64"} {
                regexp -- {^([0-9]*)\..*$} $version - shortVersion
                if {[xampptcl::util::compareVersions $version "8.0.0"] >= 0} {
                    set shortVersion ""
                }
                foreach bin [list bin/php-$version bin/php-cgi-$version modules/libphp$shortVersion.so] {
                    set bin [file join [prefix] $bin]
                    set out [exec otool -L $bin]
                    foreach l [split $out \n] {
                        set lib [lindex [string trim $l] 0]
                        if {[string match *libpq.* $lib]} {
                            if {![string match [file join [prefix] lib/libpq.*] $lib]} {
                                set targetLib [file normalize [file join [prefix] lib [file tail $lib]]]
                                exec install_name_tool -change $lib $targetLib $bin
                            }
                            break
                        }
                    }
                }
                if {[xampptcl::util::compareVersions $version "7.0.0"] < 0} {
                    set oci8 [lindex [glob [prefix]/lib/php/extensions/*/oci8.so] 0]
                    set out [exec otool -L $oci8]
                    set dependencyLibs {}
                    foreach l [split $out \n] {
                        set lib [lindex [string trim $l] 0]
                        if {[string match *libclntsh* $lib] || [string match *libnnz* $lib]} {
                            if {![string match [file join [prefix] lib/*] $lib]} {
                                set targetLib [file normalize [file join [prefix] lib/instantclient/ [file tail $lib]]]
                                exec install_name_tool -change $lib $targetLib $oci8
                                lappend dependencyLibs [::xampptcl::file::readlink $targetLib]
                            }
                            #break
                        }
                    }
                    foreach depLib $dependencyLibs {
                        set out [exec otool -L $depLib]
                        foreach l [split $out \n] {
                            set lib [lindex [string trim $l] 0]
                            set targetLib [file normalize [file join [prefix] lib/instantclient/ [file tail $lib]]]
                            if {![file exists $targetLib]} {
                                continue
                            }
                            if {[string match [file join [prefix] lib/*] $lib]} {
                                continue
                            }
                            exec install_name_tool -change $lib $targetLib $depLib
                            #break
                        }
                    }
                }
            }
            # Copy php.ini from php-production.ini
            file copy -force [srcdir]/php.ini-production [$be cget -output]/etc/php.ini
        }
    }
    ::itcl::class php74 {
        inherit php
        constructor {environment} {
            chain $environment
        } {
            set vtrackerName XAMPP74
            set version [::xampp::php::getXAMPPVersion 74]
        }
    }
    ::itcl::class php80 {
        inherit php
        constructor {environment} {
            chain $environment
        } {
            set vtrackerName XAMPP80
            set version [::xampp::php::getXAMPPVersion 80]
            if {[string match osx* [$be cget -target]]} {
                set patchList {fix-opcache-support-php-8.OS-X.patch}
            }
        }
    }
    ::itcl::class php81 {
        inherit php
        constructor {environment} {
            chain $environment
        } {
            set vtrackerName XAMPP81
            set version [::xampp::php::getXAMPPVersion 81]
            if {[string match osx* [$be cget -target]]} {
                set patchList {fix-opcache-support-php-8.OS-X.patch}
            }
        }
    }
    ::itcl::class php82 {
        inherit php
        constructor {environment} {
            chain $environment
        } {
            set vtrackerName XAMPP82
            set version [::xampp::php::getXAMPPVersion 82]
            if {[string match osx* [$be cget -target]]} {
                set patchList {fix-opcache-support-php-8.OS-X.patch}
            }
        }
    }
}
