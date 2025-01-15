# util.tcl
# Commonly used procedures
package provide bitnami::util 1.0

proc declareClass {className args} {
    array set options [list parentClass {} name $className version {} licenseRelativePath COPYING licenseNotes {} setValuesIfEmpty 1]
    foreach {k v} $args {
        if {![string match -* $k]} {
            error "Invalid class declaration 'declareClass $className $args'. Expected a flag but got $k "
        }
        set k [string trimleft $k -]
        set options($k) $v
    }
    if {$options(parentClass) != ""} {
        set inheritFrom "inherit $options(parentClass)"
    } else {
        set inheritFrom ""
    }
    unset -nocomplain options(parentClass)
    set variableDefinitionText {}
    foreach {name value} [array get options] {
        if {$name == "setValuesIfEmpty"} {
            continue
        }
        if {!$options(setValuesIfEmpty) && $value == ""} {
            continue
        }
        append variableDefinitionText [format {
                set %s "%s"} $name $value]
    }
    set definition [format {
        ::itcl::class %s {
            %s
            constructor {environment} {
                chain $environment
            } {
                %s
            }
        }
    } $className $inheritFrom $variableDefinitionText]
    uplevel $definition
}

proc hasTool {be shortname tool} {
    if {[file exist [$be cget -projectDir]/apps/$shortname/$shortname-$tool.xml] || [file exist [$be cget -projectDir]/base/$shortname/$shortname-$tool.xml]} {
            return 1
        } else {
            return 0
        }
}

proc extractChrootCentosVersion {id} {
    if {$id=="centos7" || $id=="centos6" || $id=="6" || $id=="7"} {
        return [lindex [split [lindex [split [read [open "/etc/redhat-release" r]] "\n"] 0]] 3]
    } elseif {$id=="centos5" || $id=="5"} {
        return [lindex [split [lindex [split [read [open "/etc/redhat-release" r]] "\n"] 0]] 2]
    } else {
        message fatalerror "\n Unsupported linux chroot for $product. You must use: $slchr \n\n"
    }
}

proc getCentosVersion {id} {
    switch -glob -- $id {
        5 - centos5 { return "5" }
        6 - centos6 { return "6.0" }
        7 - centos7 { return "7.3.1611" }
        default { error "Unknown centos version $id" }
    }
}

proc setGLibRestrictionsCentos7 {be} {
    if {[$be cget -target]=="linux-x64"} {
        $be configure -setvars "[$be cget -setvars] component(bitnamisettings).parameter(bitnamisettings_minimum_glibc_version).value=2.17"
        $be configure -setvars "[$be cget -setvars] component(bitnamisettings).parameter(bitnamisettings_minimum_glibcxx_version).value=3.4.18"
    }
}

proc toolsDir {} {
    return [file join $::opts(srcdir) tools]
}

proc translator {args} {
    if {$::tcl_platform(os) == "Darwin"} {
        set translatorTool [file join [toolsDir] translator translator-osx-intel.run]
    } else {
        set translatorTool [file join [toolsDir] translator translator-linux-x64.run]
    }
    eval logexec [list $translatorTool] $args
}

proc addWinserv {be shortname} {
    if { [string match windows* [$be cget -target]] } {
        file mkdir [$be cget -output]/$shortname/scripts
        file copy -force [$be cget -projectDir]/base/winserv/winserv.exe [$be cget -output]/$shortname/scripts
    }
}

proc addProcrun {be shortname} {
    if { [string match windows* [$be targetPlatform]] } {
        file mkdir [file join [$be cget -output] $shortname scripts]
        foreach f [glob [file join [$be cget -src] procrun pr*.exe]] {
            file copy -force $f [file join [$be cget -output] $shortname scripts]
        }
    }
}

proc unzipFile {zipFile {extractDirectory {}} {unzipArgs {-qo}}} {
    if {$extractDirectory == ""} {
        set extractDirectory [pwd]
    }
    return [logexec /usr/bin/unzip $unzipArgs $zipFile -d $extractDirectory]
}

proc waitForText {filename pattern {time_slot {3}} {counter {60}} {graceful {0}} } {
    set text [xampptcl::file::read $filename]
    while {![string match *$pattern* $text] && $counter > 0} {
	set counter [expr $counter-1]
	after [expr $time_slot*1000]
	set text [xampptcl::file::read $filename]
    }
    if { $counter == 0 } {
	message error "waitForText timeout"
        if { $graceful == 0 } {
            exit 1
        }
        return 0
    } else {
	message info "String $pattern matches in $filename"
        return 1
    }
}


proc lremove {list elements} {
    foreach e $elements {
        while {[set position [lsearch -exact $list $e]] != "-1"} {
            set list [lreplace $list $position $position]
        }
    }
    return $list
}

proc disableComponentsString  {elements} {
    set list ""
    foreach e $elements {
        set list "$list component($e).selected=0 component($e).show=0"
    }
    return $list
}

proc lremoveExact {list element} {
    set listAux [join $list " "]
    regsub -- "$element" $listAux "" listAux
    return [string trim $listAux]
}


proc isWrapperFile {f} {
    if {![file exists $f] || ![file isfile $f] || [file type $f] == "link"} {
        return 0
    } else {
        set fh [open $f r]
        set shebang [read $fh 2]
        if {$shebang == "#!"} {
            return 1
        } else {
            return 0
        }
    }
}

proc getPlatformName {target} {
    if {$target == "osx-x64"} {
        return "osx-x86_64"
    }
    return $target
}

# binaries or libraries
proc isBinaryFile {f} {
    set f [xampptcl::file::readlink $f]
    set fileOutput [exec file $f]
    # We consider fonts as binary and they return "raw G3 data" and "font program data".
    if {$::tcl_platform(os) == "AIX" || $::tcl_platform(os) == "HPUX" || $::tcl_platform(os) == "HP-UX"} {
        if {[string match "*executable*" $fileOutput] || [string match "*raw G3 data*" $fileOutput]
            || [string match "*font program data*" $fileOutput]} {
            return 1
        } else {
            return 0
        }
    }
    if {$::tcl_platform(os) == "SunOS"} {
        if {[string match "*MSB executable*" $fileOutput]
        || [string match "*LSB executable*" $fileOutput] || [string match "*raw G3 data*" $fileOutput]
        || [string match "*raw G3 data*" $fileOutput]} {
            return 1
        } else {
            return 0
        }
    }
    set fileLOutput [exec file -L $f]
    if {[string match "*LSB executable*" $fileLOutput]
        || [string match "*MSB executable*" $fileLOutput]
        || [string match "* executable i386*" $fileLOutput]
        || [string match "* executable ppc*" $fileLOutput]
        || [string match "*ELF*" $fileLOutput]
        || [string match "*Mach-O*" $fileLOutput]
        || [string match "*raw G3 data*" $fileLOutput]
        || [string match "*raw G3 data*" $fileLOutput]} {
        return 1
    }
    return 0
}
proc isSymbolicLink {f} {
    if { [catch {file link $f}] } {
        return 0
    }
    return 1
}
proc fixAbsoluteSymbolicLinks {path} {
    message info2 "Checking links with absolute path $path..."
    foreach f [split [exec find $path] \n] {
        if {[isSymbolicLink $f] && [string match $path* [file readlink $f]] } {
            set absolutelink [file readlink $f]

            regsub $path/ $f {} rf
            regsub $path/ $absolutelink {} rl

            set rfdir [split [file dirname $rf] /]
            set rldir [split [file dirname $rl] /]
            set c 0
            set rellinkpath {}
            foreach i $rfdir j $rldir {
                if { ![string match $i $j] || [string match "" $i]} {
                    foreach d [lrange $rfdir $c end] {
                        lappend rellinkpath ..
                    }
                    break
                } else {
                    incr c
                }
            }

            puts "Fixing link: $f $absolutelink"
            set rellinkpath [file join [join $rellinkpath /] [join [lrange $rldir $c end] /] [file tail $absolutelink]]
            file delete -force $f
            logexec ln -s $rellinkpath $f

        }
    }
    message info "Checking links with absolute path...Done"
}
proc uploadFileToS3 {local remote {s3Args ""}} {
    if {[info exists ::env(DRY_RUN)]} {
        lappend s3Args "--dry-run"
    }
    if { [catch {eval logexec s3cmd put $s3Args --multipart-chunk-size-mb=7 -f $local s3://$remote >@stdout 2>@stderr} uploadResult] } {
        message error "File from $local could not be uploaded to s3://$remote"
    } else {
        message info "File from $local has been uploaded to s3://$remote successfully"
    }
}
proc normalizeLicense {license {stripExtraInfo 0}} {
    set result ""
    if {[isKnonwLicense $license]} {
        set result $license
    } else {
        foreach {name url aliases notes} [knownLicensesInfo] {
            if {[string match $name $license]} {
                set result $license
                break
            }
            set foundAlias ""
            foreach alias $aliases {
                if {[string match -nocase $alias $license]} {
                    set foundAlias $name
                    break
                }
            }
            if {$foundAlias != ""} {
                set result $foundAlias
                break
            }
        }
    }
    if {$stripExtraInfo} {
        set result [lindex [split $result =] 0]
    }
    return $result
}

proc isKnonwLicense {license} {
    foreach {name url aliases notes} [knownLicensesInfo] {
        lappend allowed $name
        if {[string match $name $license]} {
            return 1
        }
    }
    return 0
}
proc checkLicense {license} {
    set allowed {}
    if {![isKnonwLicense $license]} {
        error "Unknown license $license. Allowed types are: [join $allowed ,]"
    } else {
        if {[string first * $license] != -1} {
            set licName [lindex [split $license =] 0]
            set url [join [lrange [split $license =] 1 end] =]
            if {$url == ""} {
                error "License type $licName requires providing an explanatory URL"
            }
        }
        return
    }
}
# http://opensource.org/licenses/alphabetical
# https://fedoraproject.org/wiki/Licensing:BSD?rd=Licensing/BSD
proc knownLicensesInfo {} {
    return {
        AGPL2 http://www.affero.org/agpl2.html {} {}
        AGPL3 http://www.gnu.org/licenses/agpl-3.0.html {} {}
        AGPL1 http://www.affero.org/oagpl.html {} {}
        AGPL http://www.gnu.org/licenses/agpl-3.0.html {agpl} {}
        AAL http://opensource.org/licenses/AAL {aal} {}
        CC0 https://creativecommons.org/publicdomain/zero/1.0/legalcode {cc0} {}
        CPAL http://opensource.org/licenses/CPAL-1.0 {} {}
        CC-BY-2 https://creativecommons.org/licenses/by/2.0/legalcode {cc-by-2} {}
        CC-BY-3 https://creativecommons.org/licenses/by/3.0/legalcode {cc-by-3} {}
        CC-BY-4 https://creativecommons.org/licenses/by/4.0/legalcode {cc-by-4} {}
        APACHE1.1 http://www.apache.org/licenses/LICENSE-1.1 {} {}
        APACHE2 http://www.apache.org/licenses/LICENSE-2.0.txt {apache2 apachev2 apache_2 Apache2 Apache_2} {}
        APACHE http://www.apache.org/licenses/LICENSE-2.0.txt {apache Apache} {}
        APACHE-Style http://www.apache.org/licenses/LICENSE-2.0.txt {apache_ish} {}
        GPL1 https://www.gnu.org/licenses/old-licenses/gpl-1.0.txt {} {}
        GPL2 https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt {gpl2 gplv2 gpl_2} {}
        GPL2+ https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt {gpl2+ gplv2 gpl2} {}
        GPL3+ https://www.gnu.org/licenses/gpl-3.0.txt {gpl3_or_later} {}
        GPL3 https://www.gnu.org/licenses/gpl-3.0.txt {gpl3}  {}
        GPL https://www.gnu.org/licenses/gpl-3.0.txt {gpl} {}
        GPL_Classpath_Exception http://en.wikipedia.org/wiki/GPL_linking_exception {} {}
        ISC https://opensource.org/licenses/ISC {isc} {}
        LGPL2 https://www.gnu.org/licenses/lgpl-2.0.txt {LGPLv2} {}
        LGPL21+ https://www.gnu.org/licenses/lgpl-2.1.txt {LGPLv2.1+} {}
        LGPL21 https://www.gnu.org/licenses/lgpl-2.1.txt {LGPL2.1 LGPL2} {}
        LGPL3 https://www.gnu.org/licenses/lgpl-3.0.txt {lgpl3 LGPL-3} {}
        LGPL https://www.gnu.org/licenses/lgpl-3.0.txt {lgpl} {}
        LGPL_OpenSSL_Exception http://en.wikipedia.org/wiki/OpenSSL#Licensing {} {}
        MIT http://opensource.org/licenses/MIT {mit} {}
        MIT-Style=* http://opensource.org/licenses/MIT {} {}
        MIT-Style http://opensource.org/licenses/MIT {} {}
        MIT-Compiled-License=* http://opensource.org/licenses/MIT {} {}
        ZPL http://opensource.org/licenses/ZPL-2.0 {Zope} {}
        ZPL21 http://old.zope.org/Resources/License/ZPL-2.1 {Zope21} {}
        MPL11 http://opensource.org/licenses/mozilla1.0.php {MPL1.1}  {}
        MPL11-Style=* http://opensource.org/licenses/mozilla1.0.php {} {}
        MPL http://opensource.org/licenses/MPL-2.0 {} {}
        BEERWARE http://en.wikipedia.org/wiki/Beerware {Beerware BeerWare} {}
        AFL21 https://spdx.org/licenses/AFL-2.1.html {} {}
        AFL3 http://opensource.org/licenses/AFL-3.0 {} {}
        AFL http://opensource.org/licenses/AFL-3.0 {} {}
        BSD2 http://opensource.org/licenses/BSD-2-Clause {bsd2} {}
        BSD3 http://opensource.org/licenses/BSD-3-Clause {bsd3 BSD-3-Clause} {}
        BSD-ORGIGINAL http://en.wikipedia.org/wiki/BSD_licenses#4-clause_license_.28original_.22BSD_License.22.29 {} {}
        BSD http://opensource.org/licenses/BSD-3-Clause {bsd} {}
        BSD-Style=* http://opensource.org/licenses/BSD-3-Clause {} {}
        BSD-Style http://opensource.org/licenses/BSD-3-Clause {BSD_like BSD_style BSD-style "BSD like"} {}
        OSL3 http://opensource.org/licenses/OSL-3.0 {OSL-3 osl3 OSL-3.0} {}
        OSL http://opensource.org/licenses/OSL-3.0 {} {}
        Artistic http://opensource.org/licenses/artistic-license-1.0 {artistic} {}
        Artistic_2 http://opensource.org/licenses/Artistic-2.0 {Artistic_License_2_0} {}
        Artistic_Perl http://opensource.org/licenses/Artistic-Perl-1.0 {PERL perl Perl} {}
        PSFL http://opensource.org/licenses/Python-2.0 {Python python PSF} {}
        Python2 http://opensource.org/licenses/Python-2.0 {} {}
        PHP3 http://opensource.org/licenses/PHP-3.0 {} {}
        PHP http://opensource.org/licenses/PHP-3.0 {php} {}
        BITNAMI {} {Bitnami bitnami} {}
        COMMERCIAL=* {The provided URL} {} {}
        COMMERCIAL {} {Zenoss zenoss commercial} {}
        CYRUS-SASL http://cyrusimap.org/mediawiki/index.php/Downloads#Licensing {} {Is a modified BSD license}
        ZLIB http://opensource.org/licenses/Zlib {zlib libpng ZLib zlib_libpng} {}
        CUSTOM=* {The provided URL} {} {}
        RUBY https://www.ruby-lang.org/en/about/license.txt {Ruby ruby} {}
        EPL https://www.eclipse.org/legal/epl-v10.html {} {}
        Public_Domain http://creativecommons.org/licenses/publicdomain/ {public_domain} {}
        Erlang http://www.erlang.org/EPLICENSE {erlang} {}
        POSTGRESQL http://opensource.org/licenses/postgresql {postgresql} {}
        AMAZON http://aws.amazon.com/asl/ {amazon Amazon} {}
        CDDL http://opensource.org/licenses/CDDL-1.0 {} {}
        BCL http://www.oracle.com/technetwork/java/javase/downloads/java-se-archive-license-1382604.html {} {}
        CPL http://opensource.org/licenses/cpl1.0.php {} {}
        OpenLDAP http://www.openldap.org/software/release/license.html {OpenLDAP_Public_License} {}
        OpenSSL http://www.openssl.org/source/license.html {openssl} {}
        Sleepycat http://opensource.org/licenses/Sleepycat {} {}
        WTFPL http://www.wtfpl.net/txt/copying/ {} {}
        OFL11 https://opensource.org/licenses/OFL-1.1 {} {}
        UNICODE https://www.unicode.org/license.html {} {}
        Unlicense https://unlicense.org/ {} {}
        W3C https://opensource.org/licenses/W3C {} {}
    }
}
proc detectLicense {be srcDir relativeLicensePath} {
    set licensePath [file join $srcDir $relativeLicensePath]
    set licenseList ""
    if [file exists $licensePath] {
	set licenseText [::xampptcl::file::read $licensePath]
	foreach {pattern name} [list "*AFFERO*" "AGPL" \
"*licensed under GNU AGPL 3*" "AGPL" \
"*distributed under the Affero GPLv3*" "AGPL" \
"*Apache Software License*" "Apache" \
"*Apache License*Version 2.0*" "Apache-2" \
"*GNU GENERAL PUBLIC LICENSE*Version 1*" "GPL-1" \
"*GNU GENERAL PUBLIC LICENSE*Version 2*" "GPL-2" \
"*GNU LIBRARY GENERAL PUBLIC LICENSE*Version 2*" "GPL-2" \
"*GNU General Public License version 2*" "GPL-2" \
"*GNU GENERAL PUBLIC LICENSE*ersion 3*" "GPL-3" \
"*GNU LESSER GENERAL PUBLIC LICENSE*Version 2.1*" "LGPL-2.1" \
"*GNU LESSER GENERAL PUBLIC LICENSE*Version 3*" "LGPL-3" \
"*GNU Lesser General Public License*" "LGPL" \
"*LGPL*" "LGPL" \
"*MIT \[lL\]icense*" "MIT" \
"*Permission is hereby granted, free of charge, to any person obtaining a copy*" "MIT" \
"*without restriction, including without limitation*" "MIT-Style" \
"*http://java.com/license*" "Java-Oracle" \
"*under the terms of the \"BSD\"*" "BSD" \
"*BSD License*" "BSD" \
"*New BSD license*" "BSD" \
"*released under the BSD license*" "BSD" \
"*PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2*" "Python-2" \
"*distributed under Python-style license*" "Python-Style" \
"*Artistic License*" "Artistic" \
"*same terms as Perl*" "Perl" \
"*PHP License, version 3.01*" "PHP-3.01" \
"*code is released under the libpng license*" "ZLib" \
"*dual license*" "Dual" \
"*under the Ruby's license*" "Ruby" \
"*Amazon Software License*" "Amazon" \
"*COMMON DEVELOPMENT AND DISTRIBUTION LICENSE*" "CDDL" \
"*Common Public License Version*" "CPL"] {
	    if [string match $pattern $licenseText] {
                if { !($name == "MIT-Style" && [string match *MIT* $licenseList]) } {
		    lappend licenseList $name
                }
	    }
	}
        # Python Packages
        if { $licenseList == "" } {
           regexp {.*\nLicense:\s*([^\n]+).*} $licenseText - licenseList
           set licenseList [join $licenseList -]
        }
        # npm packages and composer (.json)
        if { $licenseList == "" } {
           regexp {.*\n\s*"license":\s*"([^"]+)".*} $licenseText - licenseList
           set licenseList [join $licenseList -]
        }
        if { $licenseList == "" } {
           regexp {.*\n\s*"licenses":\s*\[[^\]]*"type"\s*:\s*"([^"]+)".*} $licenseText - licenseList
           set licenseList [join $licenseList -]
        }
        if { $licenseList == "" } {
           regexp {.*\n\s*<license[^>]*>([^<]+)</license>.*} $licenseText - licenseList
           set licenseList [join $licenseList -]
        }
        # META.yml perl
        if { $licenseList == "" } {
           regexp {.*\n\s*license:\s*([^\n]+).*} $licenseText - licenseList
           set licenseList [join $licenseList -]
        }

	return $licenseList
    } else {
	error "License NOT found!"
    }
}

# Returns the path of a binary using the machine's default environment (ignoring bitnami-code setenv)
proc findBinary {binary {defaultDir /usr/bin}} {
    set binPath $defaultDir/$binary
    if {![file exists $binPath]} {
        if {[catch {set binPath [exec env -i bash -c ". /etc/profile; which $binary"]}]} {
            message fatalerror "Could not find path to \"$binary\"!"
        }
    }
    return $binPath
}

proc massSubstitution {pattern_list value dir dirPattern} {
    set oldPath $::env(PATH)
    set oldLibraryPath $::env(LD_LIBRARY_PATH)
    # Clean the PATH environment variable because some stacks could include "find" or other tools, so
    # you can not execute these binaries files if you build for other platforms such as linux-x64
    set ::env(PATH) "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    set ::env(LD_LIBRARY_PATH) ""
    set pwdt [pwd]
    cd $dir
    set resultList {}
    foreach pattern $pattern_list {
        catch {[exec find $dir | xargs grep "$pattern" | sed -e s/:.*$//g | sort -u | grep -v Binary >> masssubst.log]}
        set fp [open "masssubst.log" r]
        set fileList [read $fp]
        close $fp
        if {![info exists fileList] || $fileList == {}} {
            continue
        }
        foreach {f} $fileList {
            # Added rule to avoid substituting pkg files
            if {![file exists $f] || [file extension $f]==".pkg"} {
                continue
            }
            if {![file writable $f]} {
                set tempPerm [file attributes $f -permissions]
                file attributes $f -permissions u+w
            }
            xampptcl::util::substituteParametersInFile \
                $f \
                [list ${pattern} ${value}]
            append resultList "[string map [list $dir $dirPattern] $f];"
        }
    }
    cd $pwdt
    set ::env(PATH) $oldPath
    set ::env(LD_LIBRARY_PATH) $oldLibraryPath
    return $resultList
}

# turck mmcache runs phpize which requires autoheader
# the freebsd4 ports system installs multiple versions
# of autoconf if different ports require different version
# autotools.
# the ports system will, however, install one version
# of autoconf as in /usr/local/bin/autoconf
# furthermore, the freebsd4 ports system does not install
# autoheader as /usr/local/bin/autoheader but as
# /usr/local/bin/autoheaderVVV (where VVV is the version
# number). this dichotomy between autoconf and autoheader
# causes a build problem. the solution is to figure out
# which version of autoconf is /usr/local/bin/autoconf
# and include in the PATH /usr/local/libexec/autoconfVVV
# which includes the autoheader binary without the VVV
# suffix.
# actually, you can understand this by reading the
# code below.

proc getFreebsdPathToAutoheader {} {
    set fl [open "| autoconf --version"]
    set data [read $fl]
    set words [split $data]
    set version [lindex $words 2]
    set version [string replace $version 1 1]
    set ::env(PATH) "$::env(PATH):/usr/local/libexec/autoconf$version"
}

if {$::tcl_platform(os) == "FreeBSD"} {
    getFreebsdPathToAutoheader
}

proc clk {} {
    return [clock format [clock seconds] -format "\[%Y-%m-%d %H:%M:%S\]"]
}

proc logexecIgnoreErrors {args} {
    message default "[clk] Running command \"$args\" in [pwd]"
    catch {eval exec $args} kk
    message default "[clk] Running command \"$args\" in [pwd] completed"
    message default $kk
}

proc logexec {args} {
    message default "[clk] Running command \"$args\" in [pwd]"
    if {[catch {eval exec $args} kk]} {
        if {$::errorCode != "NONE"} {
            message error "************************ Running command \"$args\" in [pwd] ************************"
            message error "************************ ERROR $::errorCode ************************"
            flush stdout
            message default "*** $kk"
            message error "Build Aborted"
            exit 1
        }
    }
    message default $kk
    message default "[clk] Running command \"$args\" in [pwd] completed"
    return $kk
}

proc execEnv {vars code {verbose 0}} {
    array set previous {}
    foreach {name value} $vars {
        if {[info exists ::env($name)]} {
            set previous($name) $::env($name)
        }
        if {$verbose != 0} {
            message default "::env($name) $value"
        }
        set ::env($name) $value
    }
    set result [uplevel 1 $code]
    foreach {name value} $vars {
        if {[info exists previous($name)]} {
            set ::env($name) $previous($name)
        } else {
            unset ::env($name)
        }
    }
    return $result
}

proc logexecEnv {vars args} {
    execEnv $vars {
        eval logexec $args
    } 1
}

proc createComponent {info be {forBuilding 1}} {
    set componentName [lindex $info 0]
    if [catch {set obj [createObject $componentName $be $forBuilding]} errorText] {
        error "$errorText\nError creating component $componentName. Make sure that component name exists"
    }
    if {[llength $info] > 1} {
        set info [lreplace $info 0 0]
        foreach {option value} $info {
            $obj configure -$option $value
        }
        if {$forBuilding} {
            $obj setEnvironment
        }
    }
    return $obj

}
proc createObject {p be {forBuilding 1} {setEnvironment 1}} {
    set pr [::$p ::\#auto $be]
    if {$forBuilding} {
        if {[$pr isa program]} {
            $pr initialize $be
        }
        $pr setBuildEnvironment $be
        if {$setEnvironment} {
            $pr setEnvironment
        }
    } else {
        $pr setBuildEnvironment $be
    }
    return $pr
}

proc runChrpath {be dir {excludePattern {}}} {
    set chrpath [createObject chrpath $be]
    $chrpath extract
    $chrpath build
    $chrpath install
    foreach f [split [exec find $dir] \n] {
        if {![string match $excludePattern $f] && ![string match *fonts* $f] && [isBinaryFile $f]} {
            message info2 "Deleting rpath from $f"
            catch {exec chrpath -d $f}
        }
    }
}

proc runStrip {be dir {excludePattern {}}} {
    set saveLdLibraryPath {}
    if {[info exists ::env(LD_LIBRARY_PATH)]} {
        set saveLdLibraryPath $::env(LD_LIBRARY_PATH)
        unset ::env(LD_LIBRARY_PATH)
    }
    foreach f [split [exec find $dir] \n] {
        if {![string match *fonts* $f] && [isBinaryFile $f]} {
            if {[string match $excludePattern $f]} {
                message info2 "Skipping strip for $f"
            } else {
                message info2 "Strip binary $f"
                catch {exec strip $f}
            }
        }
    }
    set ::env(LD_LIBRARY_PATH) $saveLdLibraryPath
}

proc convertSymlinksToDirs {directory} {
    if {![file exists $directory]} {
        message fatalerror "Directory $directory does not exist"
    }
    set cwd [pwd]
    cd $directory
    catch {
        foreach f [exec find -type l 2>/dev/null] {
            set target [file normalize [file join $f .. [file readlink $f]]]
            file delete -force $f
            file copy -force $target $f
        }
    }
    cd $cwd
}

proc getVersion {className environment} {
    set cn [::$className ::\#auto $environment]
    set version [$cn versionNumber]
    ::itcl::delete object $cn
    return $version
}

proc getRevision {className environment} {
    set cn [::$className ::\#auto $environment]
    set rev [$cn revisionNumber]
    ::itcl::delete object $cn
    return $rev
}

proc getDescription {className environment} {
    set cn [::$className ::\#auto $environment]
    set desc [$cn getDescription]
    ::itcl::delete object $cn
    return $desc
}

proc elemMatchesFilters {e filters} {
    foreach f $filters {
        if {[string match $f $e]} {
            return 1
        }
    }
    return 0
}

proc listFilter {list filters} {
    set r {}
    foreach e $list {
        if {![elemMatchesFilters $e $filters]} {
            lappend r $e
        }
    }
    return $r
}

proc listSelect {list filters} {
    set r {}
    foreach e $list {
        if {[elemMatchesFilters $e $filters]} {
            lappend r $e
        }
    }
    return $r
}

proc elemIsA {obj filters} {
    foreach f $filters {
        if {[$obj isa $f]} {
            return 1
        }
    }
    return 0
}

proc buildProgram {p be} {
    set pr [::$p ::\#auto $be]
    $pr setBuildEnvironment $be
    $pr setEnvironment
    message info "* Building [$pr cget -name] version [$pr cget -version]"
    if {[$pr needsToBeBuilt]} {
        file delete -force [$pr srcdir]
        $pr extract
        $pr build

        ::xampptcl::file::write [$pr srcdir]/.buildcomplete {}
    } else {
        message info2 "Skipping build step for [$pr cget -name] version [$pr cget -version]"
    }
    $pr install
    $pr copyLicense
    message info "Finished [$pr cget -name] version [$pr cget -version]\n\n"
    return $pr
}

proc buildProject {project be buildType {license {}} {extraSetVars {}} {onlyGenerateScript 0}} {
    set IBversion 24.7.0
    populateEmptyDirs [file dirname $project]
    message info "Building installer with IB version $IBversion"
    if {[info exists ::env(BITNAMI_AUTOMATIC_BUILD)]} {
	set IBPath [file join $::env(BITNAMI_BUILD_DIR) installbuilder-$IBversion]
	file mkdir [file join $IBPath output]
        if {[file normalize ~/installbuilder-$IBversion] != [file normalize $IBPath]} {
            file delete -force [file join $IBPath bin]
            file copy -force ~/installbuilder-$IBversion/bin $IBPath
            file delete -force [file join $IBPath paks]
            file copy -force ~/installbuilder-$IBversion/paks $IBPath
        }
    } else {
	set IBPath {}
    }

    if {$IBPath == {}} {
        if {$::tcl_platform(os)=="Darwin"} {
            foreach d [list "/Applications/BitRock InstallBuilder Enterprise $IBversion" ~/installbuilder-$IBversion] {
                if {[file exists $d]} {
                    set IBPath [file normalize $d]
                }
            }
            if {![file exists $IBPath]} {
                puts stderr "Could not determine IB Path"
                exit 1
            }
        } else {
            set IBPath [file normalize ~/installbuilder-$IBversion]
        }
    }
    if {$license != ""} {
        file copy -force $license $IBPath/license.xml
    }
    set srcdir [pwd]
    cd [file dirname $project]
    set setvars [$be cget -setvars]
    lappend setvars project.osxPlatforms=[$be cget -osxPlatforms]

    if {[$be cget -enableDebugger]} {
        lappend setvars project.enableDebugger=1
    }

    if {[string match "windows-x64" [$be cget -target]]} {
      lappend setvars project.windows64bitMode=1
    }


    if {[llength [$be cget -filesToIgnoreWhenPacking]] > 0} {
        lappend setvars project.filesToIgnoreWhenPacking=[$be cget -filesToIgnoreWhenPacking]
    }

    if {[info exists ::env(COMPRESSIONALGORITHM)] && ($::env(COMPRESSIONALGORITHM) != "")} {
        lappend setvars project.compressionAlgorithm=$::env(COMPRESSIONALGORITHM)
    }

    if {$extraSetVars != ""} {
        set setvars [concat $setvars $extraSetVars]
    }

    if {[llength $setvars] > 0} {
        set setvars "--setvars \"[join $setvars "\" \""]\""
        message default "Specifying variables: $setvars"
    }

    if {$::tcl_platform(os)=="Darwin"} {
        set ibBuilderBinary [file join $IBPath bin/Builder.app/Contents/MacOS/osx-intel]
    } else {
        set ibBuilderBinary [file join $IBPath bin/builder]
    }

    if {$::tcl_platform(os)=="Darwin"} {
        if {$onlyGenerateScript == 0} {
            puts [eval exec $ibBuilderBinary $buildType $project [$be cget -target] $setvars >@stdout 2>@stderr]
        }
        file delete -force $IBPath/license.xml
    } else {
	puts "START BUILD -- [clock format [clock seconds] -format %H%M%S]"
	puts "building with IBPATH $ibBuilderBinary"
    if { [string match solaris-intel-x64 [$be cget -target]] } {
        set targetIB solaris-intel
	} else {
	    set targetIB [$be cget -target]
	}
	set ::env(BROPTIMIZEFORSIZE) 1
	set checkEvaluationLicense "[file normalize $ibBuilderBinary] $buildType $project $targetIB $setvars --verbose"
	puts "END BUILD -- [clock format [clock seconds] -format %H%M%S]"
    puts $checkEvaluationLicense

    set buildOutputFile [file join [$be cget -output] build.txt]
    exec touch $buildOutputFile
    set buildShDestination [file join [$be cget -output] build.sh]
    xampptcl::file::write $buildShDestination "#!/bin/sh

INSTALLBUILDER_PATH=\$1

if \[ -z \"\$INSTALLBUILDER_PATH\" ]; then
    ~/installbuilder-$IBversion/bin/builder $buildType $project $targetIB $setvars --verbose
else
    if \[ -e \$INSTALLBUILDER_PATH/bin/builder ]; then
        \$INSTALLBUILDER_PATH/bin/builder $buildType $project $targetIB $setvars --verbose
    else
        echo \"Builder binary not found\"
    fi
fi
"

    file attributes $buildShDestination -permissions 0755

    $be startTimer "product.installBuilder"
    if {$onlyGenerateScript == 0} {
        puts [exec sh $buildShDestination >@stdout 2>@stderr | tee $buildOutputFile | grep -v "Packing " | grep -v "Creating directory " ]
        set buildOutput [xampptcl::file::read $buildOutputFile]

        # The last 30 lines is fine, checking the full output could give us false positives
        # when checking for the evaluation version
        set tail [join [lrange [split $buildOutput \n] end-30 end] \n]
        # Make sure we have valid output to process
        if {![string match {*Build Complete*} $tail]} {
            error "Failed to parse InstallBuilder output: missing \"Build Complete\""
        }
        if {[string match windows* $targetIB]} {
            if {![regexp -- {\s+Installer placed at\s+([^\n]+)} $tail - outputFilename]} {
                error "failed to extract output filename from builder output"
            }
            set outputFilename [string trim $outputFilename]
        }
        if {[string match *evaluation* $tail]} {
            message error "EVALUATION VERSION: Please update the InstallBuilder license"
                if { ![info exists ::env(BR_LICENSE_NOFORCE)] && ![$be cget -enableDebugger] } {
                    exit 1
                }
	    }
        }
    }
    $be stopTimer "product.installBuilder"

    message beep ""
    message beep ""
    message beep ""
    cd $srcdir
}

proc includeCplusplus {be {destination {}}} {
    set libDir "lib"
    if {[$be cget -target] == "linux-x64"} {
	set libDir "lib64"
    }
    if {$destination == ""} {
	set destination [file join [$be cget -output] common lib]
    }
    if {[$be targetPlatform] == "linux-x64" || [$be targetPlatform] == "linux"} {

	if [file exists [glob -nocomplain [$be cget -builddep]/gcc-*]] {
	    foreach f [glob [$be cget -builddep]/gcc-*/$libDir/libstdc++.*] {
		file copy -force  $f $destination
	    }
	} else {
	    foreach f [glob /usr/$libDir/libstdc++.*] {
		file copy -force  $f $destination
	    }
	}
    }
}
proc includeLibGcc {be {destination {}}} {
    set libDir "lib"
    if {[$be cget -target] == "linux-x64"} {
	set libDir "lib64"
    }
    if {$destination == ""} {
	set destination [file join [$be cget -output] common lib]
    }
    if {[$be targetPlatform] == "linux-x64" || [$be targetPlatform] == "linux"} {
        foreach f [glob /$libDir/libgcc_s.*] {
            file copy -force  $f $destination
        }
    }
}

proc populateEmptyDirs {directory} {
    # The reason is that when the customers uncompress the files we send to them
    # for building on their side, some Winzip utilities would ignore by default
    # empty directories and would cause all kind of problems as for examples
    # apache would not find logs/ directory, etc.
    set l [glob -nocomplain $directory/*]
    if {$l == ""} {
        puts "Dir $directory is empty"
        exec touch $directory/NOTEMPTY
    }
    foreach d $l {
        if {[file isdirectory $d] && [file type $d] != "link"} {
            populateEmptyDirs $d
        }
    }
}

proc prepareWrapper {binaryPath componentName {wrapper_relative_dir {bin}} {wrapper_arguments {}} {extraCommands {}}} {
    global be
    set binaryBaseName [file dirname $binaryPath]
    set binaryTail .[file tail $binaryPath].bin
    set configFile .[file tail $binaryPath].setenv

    file rename $binaryPath [file join $binaryBaseName $binaryTail]

    xampptcl::file::write $binaryPath {#!/bin/sh

. @@XAMPP_SET_ENVIRONMENT_SCRIPT@@
BITROCK_EXTRA_COMMANDS
exec @@XAMPP_COMPONENT_NAME_ROOTDIR@@/RELATIVE_DIR/BINARY_TAIL ARGUMENTS "$@"
}
    xampptcl::util::substituteParametersInFile $binaryPath [list {COMPONENT_NAME} $componentName]
    xampptcl::util::substituteParametersInFile $binaryPath [list {BINARY_TAIL} $binaryTail]
    xampptcl::util::substituteParametersInFile $binaryPath [list {BITROCK_EXTRA_COMMANDS} $extraCommands]
    xampptcl::util::substituteParametersInFile $binaryPath [list {ARGUMENTS} $wrapper_arguments]
    xampptcl::util::substituteParametersInFile $binaryPath [list {RELATIVE_DIR} $wrapper_relative_dir]
    file attributes $binaryPath -permissions 0755
}
proc parsePropertiesFile {filename} {
    array set tmpArray {}
    if {![file exists $filename]} {
        return ""
    } else {
        foreach l [split [xampptcl::file::read $filename] \n] {
            set l [string trim $l]
            if {[string match #* $l] || ![string match *=* $l]} {
                continue
            }
            set k [string trim [lindex [split $l =] 0]]
            set v [string trim [lindex [split $l =] 1]]
            # Add debug
            puts "Setting key $k with value $v"
            set tmpArray($k) $v
        }
    }
    return [array get tmpArray]
}
proc propertiesFileSet {filename key val} {
    if {![file exists $filename]} {
        xampptcl::file::write $filename $key=$val\n
        return
    }
    set tempPerm [file attributes $filename -permissions]
    file attributes $filename -permissions u+w

    set parsedOrig {}
    set key_exists 0
    foreach l [split [xampptcl::file::read $filename] \n] {
        set s [split $l =]
        if {[string equal -nocase [string trim [lindex $s 0]] $key]} {
		 lappend parsedOrig "$key=$val"
            set key_exists 1
        } else {
            lappend parsedOrig $l
        }
    }
    if {!$key_exists} {
        lappend parsedOrig "$key=$val"
    }
    if {[catch {
        xampptcl::file::write $filename [join $parsedOrig \n]
        file attributes $filename -permissions $tempPerm
    } kk]} {
        puts $kk
    }
}

proc dateToSeconds {date {format "%Y-%m-%d"}} {
    return [clock scan $date -format $format]
}

proc dateToDays {date {format "%Y-%m-%d"}} {
    return [clock format [dateToSeconds $date $format] -format %J]
}

proc getElapsedDays {date {format "%Y-%m-%d"}} {
    set today [clock format [clock seconds] -format %J]
    return [expr {$today - [dateToDays $date $format]}]
}

proc getDetailedElapsedTime {date {format "%Y-%m-%d_%H:%M"}} {
    set seconds [dateToSeconds $date $format]

    #Getting the number of seconds elapsed from the date provided
    set difference [expr {[clock seconds] - $seconds}]

    #Extracting the number of days
    set days [expr {$difference / (24*60*60)}]
    set difference [expr {$difference % (24*60*60)}]

    #Extracting the number of days and ignoring the rest
    set hours [expr {$difference / (60*60)}]

    return [list $days $hours]
}

proc isPidRunning {pid} {
    if {[catch {exec kill -0 $pid}]} {
        return 0
    } else {
        return 1
    }
}

namespace eval buildsystem {
    proc findAllClassesByType {type be} {
        set returnList {}
        foreach class [::itcl::find classes] {
            if {![catch {set instance [::itcl::local $class \#auto $be]}]} {
                if [$instance isa $type] {
                    lappend returnList $class
                }
            }
        }
        return $returnList
    }
    proc classExists {name} {
        return [expr [lsearch -exact [::itcl::find classes] $name] >= 0]
    }
    proc getInstances {class} {
        return [itcl::find objects -class $class]
    }
}
namespace eval xampptcl::translation {

    proc getStringsFromPoEntry {entry} {
        foreach {msgIdLine msgStrLine} $entry {
            set msgIdLine [string trim $msgIdLine]
            set msgStrLine [string trim $msgStrLine]
            if {![regexp -- {msgid\s+"(.*)"\s*} $msgIdLine match id]} {
                error "malformed file: malformed id line $msgIdLine" "malformed file: malformed id line $msgIdLine" XAMPPERROR
            } elseif {![regexp -- {msgstr\s+"(.*)"\s*} $msgStrLine match str]} {
                error "malformed file: malformed str line $msgStrLine" "malformed file: malformed str line $msgStrLine" XAMPPERROR
            } else {
                foreach elem [list $id $str] {
                    lappend result [string map [list {\n} \n {\t} \t {\"} \"] $elem]
                }
                return $result
            }
        }
    }
    proc parsePoFile {filename {encoding utf-8}} {
	set text [xampptcl::file::read $filename $encoding]
	set result {}
	set linesToProcess {}
	if {[catch {
            set lineList [split $text \n]
            set i 0
            set max [llength $lineList]
            while {$i < $max} {
                set line [string trim [lindex $lineList $i]]
                if {[string trim $line] == "" || [string match #* $line]} {
                    incr i
		    continue
		} elseif {[regexp -- {msgid\s+"(.*)"\s*} $line]} {
                    lappend linesToProcess $line
                    incr i
                    continue
                } elseif {[regexp -- {msgstr\s+"(.+)"\s*} $line]} {
                    lappend linesToProcess $line
                    incr i
                    continue
                } elseif {[regexp -- {msgstr\s+""\s*} $line]} {
                    # Rework 'msgstr ""' format
                    incr i
                    set text {}
                    while {[regexp -- {"(.*)"\s*} [string trim [lindex $lineList $i]] match subString]} {
                        append text $subString
                        incr i
                    }
                    set normalizedText "\"[string map [list \n {\n} \t {\t} \" {\"}] $text]\""
                    lappend linesToProcess "msgstr $normalizedText"
                } else {
                    error "Unrecognized string type '$line'"
                }
            }
	    foreach {idLine strLine} $linesToProcess {
                set result [concat $result [getStringsFromPoEntry [list $idLine $strLine]]]
	    }
	} kk]} {
	    set msg "Error processing .po file $filename: $kk"
	    error $msg $msg XAMPPERROR
	}
        # If the first key is empty, it correspond to the header, for now we just ignore it
        if {[lindex $result 0] == ""} {
            set result [lreplace $result 0 1]
        }
	return $result
    }
    proc poFileAdd {source dest {encoding utf-8} {onlyIfNotPresent 0}} {
        if {![file exists $dest]} {
            xampptcl::file::write $dest {} $encoding
        }
	foreach {k v} [parsePoFile $source $encoding] {
	    if {$onlyIfNotPresent != 1 || ![poKeyExists $dest $k]} {
		poFileSet $dest $k $v
	    }
	}
    }
    proc poKeyExists {file key {encoding utf-8}} {
        array set poStrings [parsePoFile $file $encoding]
        if {[info exists poStrings($key)]} {
            return 1
        } else {
            return 0
        }
    }
    proc poFileGet {file key {encoding utf-8}} {
        array set poStrings [parsePoFile $file $encoding]
        if {[info exists poStrings($key)]} {
            return $poStrings($key)
        } else {
            return ""
        }
    }
    proc formatPoEntry {original translation} {
        set normalizedOrig \"[string map [list \n {\n} \t {\t} \" {\"}] $original]\"
	set normalizedTr \"[string map [list \n {\n} \t {\t} \" {\"}] $translation]\"
	return "msgid $normalizedOrig\nmsgstr $normalizedTr"
    }

    proc poFileSet {file key value {encoding utf-8}} {
        array set poStrings [parsePoFile $file $encoding]
        set poStrings($key) $value
        set entries {}
        foreach {msgId msgStr} [array get poStrings] {
            lappend entries [xampptcl::translation::formatPoEntry $msgId $msgStr]
        }
        xampptcl::file::write $file [join $entries \n\n] $encoding
    }
    proc poFileDelete {file key {encoding utf-8}} {
        array set poStrings [parsePoFile $file $encoding]
        unset -nocomplain poStrings($key)
        set entries {}
        foreach {msgId msgStr} [array get poStrings] {
            lappend entries [xampptcl::translation::formatPoEntry $msgId $msgStr]
        }
        xampptcl::file::write $file [join $entries \n\n] $encoding
    }

}

namespace eval bitnami {

    set ::bitnami::rootPath ""
    set ::bitnami::cfgFilePath ""

    # This gets called when doing package require bitnami::util
    proc initialize {} {
        if {[catch {
            global auto_path
            set ::bitnami::rootPath [file dirname [file dirname [file normalize [info script]]]]
            if {[info exists ::env(BITNAMI_CFG_PATH)]} {
                set ::bitnami::cfgFilePath [file normalize $::env(BITNAMI_CFG_PATH)]
            } else {
                set ::bitnami::cfgFilePath [file join $::bitnami::rootPath .bitnamicfg]
            }
            lappend auto_path [file join $::bitnami::rootPath lib]
            package require inifile
        } kk]} {
            puts stderr "Cannot properly initialize ::bitnami::util package: $kk"
        }
    }
    proc storageDir {} {
        return [cfgGetPath "storage_dir" [file normalize ~/.bitnami/]]
    }
    proc curlBinary {} {
        if {[file exists [file join / usr bin curl] ]} {
            set curlPath "/usr/bin/curl"
        } else {
            set curlPath curl
        }
        return $curlPath
    }
    proc httpGet {url {timeout 10000} {headers {}} {withResponseHeaders false}} {
        package require http
        package require tls
        # Configure HTTPS
        ::http::register https 443 ::tls::socket

        set token [http::geturl $url -timeout $timeout -headers $headers]
        set ncode [http::ncode $token]
        if {$ncode != "200"} {
            catch {http::cleanup $token}
            message error "Cannot retrieve url $url\nError code: $ncode"
            exit 1
        } else {
            set data [http::data $token]
            set meta [http::meta $token]
            catch {http::cleanup $token}
            if {$withResponseHeaders} {
                dict set result data $data
                dict set result headers $meta
                return $result
            } else {
                return $data
            }
        }
    }

    proc cfgPath {} {
        if {[info exists ::env(BITNAMI_CFG_FILE)]} {
            return $::env(BITNAMI_CFG_FILE)
        } else {
            if {$::bitnami::cfgFilePath == ""} {
                puts stderr "::bitnami::cfgFilePath is not defined. Did you properly loaded bitnami::util package?"
                return ""
            } else {
                return $::bitnami::cfgFilePath
            }
        }
    }

    proc iniGet {fp s k {default {}}} {
        set res $default

        if {$k == ""} {
            if {[catch {
                set keys [::ini::keys $fp $s]
                array set data {}
                if {[xampptcl::util::listContains $keys "include"]} {
                    set v [iniGet $fp $s "include"]
                    array set data [iniGet $fp "$v" {}]
                }

                foreach k [::ini::keys $fp $s] {
                    if {$k == "include"} {
                        continue
                    }
                    set data($k) [::ini::value $fp $s $k]
                }
                set res [array get data]
            } kk]} {
                return $res
            }
        } else {
            if {[catch {
                set res [::ini::value $fp $s $k]
            }]} {
                set res $default
            }
        }
        return $res
    }
    proc iniFileGet {file s k {default {}}} {
        set res $default
        if {[catch {
            set fp [::ini::open $file r]
        }]} {
        } else {
            set res [iniGet $fp $s $k $default]
            ::ini::close $fp
        }
        return $res
    }
    proc iniFileSet {file section key value} {
        if {[catch {
            if {![file exists $file]} {
                xampptcl::file::write $file {}
            }
            set fp [::ini::open $file]
        } kk]} {
            xampptcl::util::debug $kk
            set msg "Error reading file $file"
            error $msg $msg XAMPPERROR
        } else {
            if {[catch {
                set err [::ini::set $fp $section $key $value]
                ::ini::commit $fp
            } kk]} {
                xampptcl::util::debug $kk
                set msg "Error writing ini file: $file"
                error $msg $msg XAMPPERROR
            }
            ::ini::close $fp
        }
    }
    proc cfgGetPath {path {default ""}} {
        set p [cfgGet $path "Paths" $default]
        if {$p != ""} {
            if {[file pathtype $p] == "relative"} {
                # If we get a relative path, absolutize with bitnami-code, if only binary name, look in path
                if {[llength [file split $p]] > 1 || [auto_execok $p] == ""} {
                    set p [file join $::bitnami::rootPath $p]
                } else {
                    set p [auto_execok $p]
                }
            }
            set p [file normalize $p]
        }
        return $p
    }
    proc fileDescriptorHasSection {fp section} {
        set sections [::ini::sections $fp]
        if {[xampptcl::util::listContains $sections $section]} {
            return 1
        }
        return 0
    }
    proc hasSection {f section} {
        set res 0
        if {[catch {
            set fp [::ini::open $f r]
        }]} {
            return ""
        } else {
            set res [fileDescriptorHasSection $fp $section]
        }
        catch {::ini::close $fp}
        return $res
    }
    proc cfgGetKeys {{section General} {includeValues 0}} {
        set res {}
        if {[catch {
            set fp [::ini::open [cfgPath] r]
        }]} {
            return ""
        } else {
            set sections [::ini::sections $fp]
            if {[xampptcl::util::listContains $sections $section]} {
                set keys [::ini::keys $fp $section]
            } else {
                set keys ""
            }
        }
        if {$includeValues} {
            foreach k $keys {
                if {[catch {
                    set v [::ini::value $fp $section $k ""]
                }]} {
                    set v ""
                }
                lappend res $k $v
            }
        } else {
            set res $keys
        }
        catch {::ini::close $fp}
        return $res
    }
    proc cfgGet {key {section General} {default ""}} {
        set v ""
        if {[set p [cfgPath]] != ""} {
            set v [iniFileGet $p $section $key]
            if {$v == ""} {
                return $default
            }
        }
        return $v
    }
    proc copyCommonLanguageFiles {localeList dest} {
        foreach langID $localeList {
            set destFile [file join $dest bitnami-$langID.po]
            file copy -force [file join [toolsDir] translator bitnami $langID bitnami.po] $destFile
            translator clean $destFile
        }
    }
}

namespace eval xampptcl::util {
    proc debug {msg} {
        if {[info exists ::env(XAMPPDEBUG)]} {
            puts "$msg"
        }
    }
    proc generateHashMetadata {origin dest} {
        set file [file tail $origin]
        set md5 [xampptcl::util::md5 $origin]
        set sha1 [xampptcl::util::sha1 $origin]
        set sha256 [xampptcl::util::sha256 $origin]
        set size [file size $origin]
        set etag [xampptcl::util::etag $origin]
        if {([file extension $origin] == ".zip") || [string match "*.tar" $origin] || [string match "*.tar.gz" $origin]} {
            set uncompressed_size [xampptcl::util::uncompressedSize $origin]
        } else {
            set uncompressed_size ""
        }
        set mtime [clock format [file mtime $origin] -format {%Y-%m-%d %H:%M:%S} -gmt 1]
        set t {}
        foreach k [list file md5 sha1 sha256 size uncompressed_size mtime etag] {
            if {[set $k] == ""} {
                continue
            }
            lappend t "$k=[set $k]"
        }
        xampptcl::file::write $dest [join $t \n]
    }
    proc uncompressedSize {origin} {
        if {([file extension $origin] == ".zip")} {
            set d [exec unzip -l $origin | tail -n 1]
            set rc [lindex [string trim $d] 0]
        }  elseif {[string match "*.tar" $origin] || [string match "*.tar.gz" $origin] || [string match "*.tgz" $origin]} {
            set options -tvf
            if {[string match "*gz" $origin]} {
                set options -tzvf

            }
            set output [exec tar $options $origin]
            if {![regexp {\s([0-9]+)\s+....-..-..} $output - rc]} {
                error "Unable to determine uncompressed file size"
            }
        }
        return $rc
    }
    proc dummyInstallerEnvironment {cmd args} {
        switch -- $cmd {
            subst {
                return [lindex $args 0]
            }
            setInstallerVariable {
            }
            default {
                error "Unknown command $cmd"
            }
        }
    }
    proc temporaryFile {} {
        set f [file join /tmp temp[uniqid]]
        set i 0
        if {[file exists $f$i]} {
            incr i
        }
        return $f$i
    }
    proc uniqueFile {f} {
        if {![file exists $f]} {
            return $f
        } else {
            set suffix 1
            set r [file rootname $f]
            set ext [file extension $f]
            while {[file exists $r$suffix$ext]} {
                incr suffix
            }
            return $r$suffix$ext
        }
    }
    proc uniqid {} {
        return [expr int(10000000 * rand())]
    }
    proc uuid {} {
        return [string toupper [string trim [exec uuidgen]]]
    }
    proc etag {f {chunkSize {7}}} {
        set chunkSize [expr {$chunkSize * 1024*1024}]

        set fh [open $f r]
        fconfigure $fh -encoding binary -translation binary
        set parts 0
        set md5list {}
        while {![eof $fh]} {
            set cs [read $fh $chunkSize]
            set md5 [md5FromStr $cs]
            append md5list $md5
            incr parts
        }
        close $fh
        return [md5FromStr [hexString2hex [join $md5list ""]]]-$parts
    }
    proc hexString2hex {str} {
        set res {}
        if {[regexp -- {^0x(.*)} $str - rest] } {
            set str $rest
        }
        while {[regexp -- {^(..)(.*)} $str -- pair str]} {
            eval append res \\x$pair
        }
        return $res
    }
    proc md5FromStr {data} {
        set f [temporaryFile]
        set fh [open $f w+]
        fconfigure $fh -encoding binary -translation binary
        puts -nonewline $fh $data
        close $fh
        set md5 [md5 $f]
        file delete -force $f
        return $md5
    }
    proc md5 {f} {
        if {$::tcl_platform(os) == "Darwin"} {
            return [string trim [exec md5 -q [file normalize $f]]]
        } else {
            return [lindex [exec md5sum [file normalize $f]] 0]
        }
    }
    proc size {f} {
        return [lindex [exec stat --format="%s" [file normalize $f]] 0]
    }
    proc sha1 {f} {
        if {$::tcl_platform(os) == "Darwin"} {
            return [lindex [exec shasum -b -a1 [file normalize $f]] 0]
        } else {
            return [lindex [exec sha1sum [file normalize $f]] 0]
        }
    }
    proc sha256 {f} {
        if {$::tcl_platform(os) == "Darwin"} {
            return [lindex [exec shasum -b -a256 [file normalize $f]] 0]
        } else {
            return [lindex [exec sha256sum [file normalize $f]] 0]
        }
    }
    proc listContains {list element} {
        return [expr [lsearch -exact $list $element] != -1]
    }
    proc listContainsGlob {list element} {
        return [expr [lsearch -glob $list $element] != -1]
    }
    proc listContainsInIndex {list element index} {
        return [expr [lsearch -exact -index $index $list $element] != -1]
    }
    proc listContainsNoCase {list element} {
        return [expr [lsearch -exact [string toupper $list] [string toupper $element]] != -1]
    }
    proc listRemove {list element} {
        set result {}
        foreach e $list {
            if {$e != $element} {
                lappend result $e
            }
        }
        return $result
    }
    proc listRemoveMultiple {list elements} {
        set result $list
        foreach e $elements {
            set result [listRemove $result $e]
        }
        return $result
    }

    proc listSearchByFirstIndex {list element} {
        foreach e $list {
            if {[llength $e] > 1} {
                set component [lindex $e 0]
            } else {
                set component $e
            }

            if {$component == $element} {
                return $e
            }
        }
    }
    proc isBooleanYes {text} {
        foreach try {yes 1 true on} {
            if [string equal -nocase $text $try] {
                return 1
            }
        }
        return 0
    }
    proc listRemoveNoCase {list element} {
        set result {}
        foreach e $list {
            if {![string equal -nocase $e $element]} {
                lappend result $e
            }
        }
        return $result
    }
    proc copyDirectory {origin destination} {
        if {$::tcl_platform(os) == "Darwin"} {
            exec cp -Rp $origin $destination
        } else {
            exec cp -rp $origin $destination
        }
    }
    proc normalizeVersionElement {elem} {
        # Elements beginning with 0 are treated as octal
        set elem [string trimleft $elem 0]
        if {$elem == ""} {
            return 0
        } else {
            return $elem
        }
    }
    proc compareVersions {version1 version2} {
        foreach elemVersion1 [split $version1 {._-}] elemVersion2 [split $version2 {._-}] {
            if {[normalizeVersionElement $elemVersion1] > [normalizeVersionElement $elemVersion2]} {
                return 1
            } elseif {[normalizeVersionElement $elemVersion1] < [normalizeVersionElement $elemVersion2]} {
                return -1
            }
        }
        return 0
    }

    proc getRegexpToList {pattern dat} {
        set total [regexp -all $pattern $dat]
        set position {0 0}
        set result {}
        for {set i 0} {$i < $total} {incr i} {
            regexp -indices -start [lindex $position 1] $pattern $dat position varNamePosition
            set varName [string range $dat [lindex $varNamePosition 0] [lindex $varNamePosition 1] ]
            if {[lsearch $result $varName] == -1} {
                lappend result $varName
            }
        }
        return $result
    }

    proc isPresentInFile {filename pattern} {
        set text [xampptcl::file::read $filename]
        if {[regexp -lineanchor $pattern $text]} {
            return 1
        } else {
            return 0
        }
    }

    proc substituteParametersInFile {filename substitutionParams {raiseErrorIfNotMatch 0} {encoding {}}} {
        set text [xampptcl::file::read $filename $encoding]
	set found 0
	foreach {pattern value} $substitutionParams {
	    if {[string first $pattern $text] != "-1"} {
		set text [string map [list $pattern $value] $text]
		set found 1
	    } elseif {$raiseErrorIfNotMatch } {
		set msg "Error substituting parameters in file. Pattern '$pattern' does not match"
		error $msg $msg
	    }
	}
	if { $found == "1" } {
	    xampptcl::file::write $filename $text $encoding
	}
    }

    proc substituteParametersInFileRegex {filename substitutionParams {raiseErrorIfNotMatch 0} {line 0}} {
        set text [xampptcl::file::read $filename]
	if {([llength $substitutionParams] % 2) != 0} {
	    set msg "The provided list of substitution parameters '$substitutionParams' does not have an even number of arguments"
	    error $msg $msg
	}
	set found 0
        foreach {name value} $substitutionParams {
	    if {$line} {
		set result [regsub -all -line -- $name $text $value text]
	    }  else  {
		set result [regsub -all -- $name $text $value text]
	    }
	    if {$result} {
		set found 1
	    } elseif {$raiseErrorIfNotMatch} {
		set msg "Error substituting parameters in file. Pattern '$name' does not match"
		error $msg $msg
	    }
	}
	if {$found == 1} {
	    xampptcl::file::write $filename $text
	}
    }

    proc isOSXChroot {} {
        return [expr [string match osx-compilation-* [info hostname]]]
    }

    proc isOSX1010Chroot {} {
        return [expr [string match osx-compilation-1010* [info hostname]]]
    }


    # Issues detecting 64-bit environment:
    # Neither tcl_platform(machine) nor tcl_platform(wordSize) works as expected when dealing
    # with chroot'ed environments, will throw wrong information. Also, we assume that "64-bit environment"
    # stands for "64-bit running kernel", but as we point out, a 32-bit chrooted system or even a
    # pure 32-system can be running a 64-bit kernel (for example, as noted on debian-amd64:
    # "Running 32bit userland with a 64bit kernel is recommended only for servers needing the
    # absolute stability of 10 years of 32bit debian, but without the memory limitations the
    # IA32 architecture bears, for example a 64bit mysql server on a system with 8GB or 16GB memory.")
    # Other forms of detection like autotools-dev's config.guess has also been taken into account
    # without success.

    proc platform {} {
        if {$::tcl_platform(platform) == "windows"} {
            return windows
        } else {
            switch $::tcl_platform(os) {
                Darwin {return osx}
                Linux {
                    if {$::tcl_platform(machine) == "ppc"} {
                        return linux-ppc
                    } elseif {$::tcl_platform(machine) == "s390" || $::tcl_platform(machine) == "s390x"} {
                        return linux-s390
                    } else {
                        return linux
                    }
                }
                AIX {return aix}
                HP-UX {return hpux}
                IRIX - IRIX64 {return irix-n32}
                SunOS {
                    if {$::tcl_platform(machine) == "i86pc"} {
                        return solaris-intel
                    } else {
                        return solaris-sparc
                    }
                }
                FreeBSD {
                    switch -glob -- $::tcl_platform(osVersion) {
                        4* {
                            return freebsd4
                        } 5* {
                            return freebsd
                        } 6* - default {
                        #return freebsd6
                            return freebsd
                        }
                    }
                } default {
                    error "Unknown platform $::tcl_platform(platform)"
                }
            }
        }
    }

    proc isTargetPlatform {platform be} {
        set p [$be cget -target]

        switch -- $platform {
            unix {
                if {![string match windows* $p]} {
                    return 1
                }
            } solaris {
                if {[string match {solaris*} $p]} {
                    return 1
                }
            } linux {
                if {[string match {linux*} $p]}  {
                    return 1
                }
            } windows-nt {
                if {$p == "windows" && $::tcl_platform(os) == "Windows NT"} {
                    return 1
                }
            } windows-9x {
                if {$p == "windows" && $::tcl_platform(os) != "Windows NT"} {
                    return 1
                }
            } default {
                if {$p == $platform} {
                    return 1
                }
            }
        }
        return 0
    }

    # http://wiki.tcl.tk/1474
    # We need to assign a value to dir because when calling recursively,
    # we may reach a point in which we call recursiveGlob without arguments
    proc recursiveGlob {{dir .} args} {
        set res {}
	foreach i [lsort [concat [glob -nocomplain -dir $dir *] [glob -nocomplain -types hidden -dir $dir *]]] {
	    if {[file tail $i] == "." || [file tail $i] == ".." } {
		continue
	    }
            if {[file isdirectory $i]} {
                if {[file type $i] == "link"} {
                    continue
                }
                if {[llength $args]} {
                    foreach arg $args {
                        if {[string match $arg $i]} {
                            lappend res $i
                            break
                        }
                    }
                }
                eval [list lappend res] [eval [linsert $args 0 recursiveGlob $i]]
            } else {
                if {[llength $args]} {
                    foreach arg $args {
                        if {[string match $arg $i]} {
                            lappend res $i
                            break
                        }
                    }
                } else {
                    lappend res $i
                }
            }
        }
        return $res
    } ;# JH

    proc recursiveGlobDir {{dir .} args} {
        set res {}
        foreach d [lsort [glob -nocomplain -dir $dir -type d *]] {
            # We skip links to directories to avoid infinite recursions. We are checking all the child directories so we will find the target directory anyways
            if {[file type $d] == "link"} {
                continue
            }
            lappend res $d
            eval [list lappend res] [eval [linsert $args 0 recursiveGlobDir $d]]
        }
        return $res
    }

    proc fileMatchesPatterns {file patternList} {
        foreach p $patternList {
            if {[string match $p $file]} {
                return 1
            }
        }
        return 0
    }

    proc deleteFilesAccordingToPattern {{dir .} pattern {excludePatternList {}}} {
        message info "Deleting ${pattern} extras"
        set toDeleteFileList [::xampptcl::util::recursiveGlob $dir $pattern]
        foreach f $toDeleteFileList {
            if {![fileMatchesPatterns $f $excludePatternList]} {
                puts "Deleting $f"
                file delete -force $f
            }
        }
    }

    proc getIncludedXmlFiles {file} {
        package require tdom
        set files {}
        set data [xampptcl::file::read $file]
        set dom [dom parse $data]
        set doc [$dom documentElement]
        set includes [$dom getElementsByTagName "include"]
        foreach node $includes {
            lappend files [file tail [$node getAttribute "file"]]
        }
        return $files
    }

    proc getAllRequiredXmlFiles {file} {
        set dir [file dirname $file]
        set res {}
        lappend res [file tail $file]
        foreach f [getIncludedXmlFiles $file] {
            if {[file exists [file join $dir $f]]} {
                set res [concat $res [getAllRequiredXmlFiles [file join $dir $f]]]
            }
        }
        return $res
    }

    proc nonBlockingExecUnix {program arguments {retrieveStdoutAndStderr 0} {stdindata {}} {timeout 0}} {
        # Timeout parameters
        set stepTime 200
        set counter 0
        set nWaitForKill 3

        if {$timeout > 0} {
            ::xampptcl::util::debug "Running command '$program $arguments' with a timeout of '$timeout' milliseconds"
        }

        # To account for pipelines and white space (OS X)
        # Otherwise, if multiple | it returns empty
        set cmdline "\"$program\" $arguments"
        if {[catch {
            set pipe [open |[list /bin/sh -c $cmdline] RDWR]
        } kk]} {
            ::xampptcl::util::debug "Error calling command $::errorCode $::errorInfo"
            # This occurs for example if stdout redirected
            if {$::errorCode == "NONE"} {
                return ""
            } else {
                error $kk
            }
        }
        fconfigure $pipe -buffering none -blocking 0
        if {[string length $stdindata] > 0} {
            puts -nonewline $pipe $stdindata
            flush $pipe
        }

        after 300


        set text {}
        while {![eof $pipe]} {
            while {[string length [set got [read $pipe]]]} {
                ::xampptcl::util::debug "Read $got"
                append text $got
            }
            after $stepTime
            update
            if {[eof $pipe]} {
                break
            }
            flush $pipe
            if {$timeout > 0} {
                if {$counter >= $timeout} {
                    set pid [pid $pipe]
                    ::xampptcl::util::debug "Killing '$program $arguments' process with PID '$pid' due to timeout of '$timeout' milliseconds"
                    if {[catch {exec kill $pid} errorMsg]} {
                        puts "Error killing process with PID '$pid': $errorMsg"
                    }

                    set i 0
                    while {[set running  [isPidRunning $pid]] && $i < $nWaitForKill} {
                        after 1000
                        incr i
                    }
                    if {$running} {
                        ::xampptcl::util::debug "Force-killing '$program $arguments' process with PID '[pid $pipe]' due to timeout of '$timeout' milliseconds"
                        if {[catch {exec kill -9 $pid} errorMsg]} {
                             puts "Error force-killing process with PID '$pid': $errorMsg"
                         }
                    }
                    break
                } else {
                    set counter [expr {$counter + $stepTime}]
                }
            }
        }
        # Make it like exec
        if {[string index $text end] == "\n"} {
            set text [string range $text 0 end-1]
        }
        # Necessary, otherwise stderr may not be sent.
        # http://groups.google.com/group/comp.lang.tcl/msg/83f0fb5e468d74c3
        fconfigure $pipe -blocking 1
        if {[catch {close $pipe} kk]} {
            if {$::errorCode == "NONE" || $::errorCode == "ECHILD"} {
                # stderr but no error exit code
                if {$retrieveStdoutAndStderr} {
                    return [list 0 $text $kk]
                } else {
                    ::xampptcl::util::debug "Error None with $kk"
                    return $text
                }
            } elseif {[string match -nocase "child process exited abnormally*" $::errorInfo]} {
                if {$retrieveStdoutAndStderr} {
                    return [list [lindex $::errorCode end] $text $kk]
                } else {
                    ::xampptcl::util::debug "$kk $::errorCode $::errorInfo"
                    # No stderr, but error exit code
                    error "Error exit code"
                }
            } else {
                if {$retrieveStdoutAndStderr} {
                    return [list [lindex $::errorCode end] $text $kk]
                } else {
                    # stderr & exit code of error
                    ::xampptcl::util::debug "Error with $kk"
                    error $kk
                }
            }
        } else {
            ::xampptcl::util::debug "No error: $kk with text $text"
            if {$retrieveStdoutAndStderr} {
                return [list 0 $text {}]
            } else {
                return $text
            }
        }
    }

    proc formatToScreen {text {size 80}} {
        set i 0
        set textLength [string length $text]
        while {$i < $textLength} {
            set locationNewline [string first \n $text $i]
            if {$locationNewline != "-1" && \
                    [expr $locationNewline - $i] <= $size} {
                set i $locationNewline
                incr i
            } elseif {$textLength - $i > $size} {
                # This means there is still space for breaking
                set j 0
                # Going backwards trying to find break
                while {$j < $size} {
                    set pos [expr $i + $size -$j]
                    set char [string index $text $pos]
                    if {[string is space $char]} {
                        set i $pos
                        break
                    }
                    incr j
                }
                if {$j == $size} {
                    incr i $size
                }
                incr i
                set char [string index $text $i]
                set text [string replace $text $i $i \n$char]
                incr textLength
                incr i
            } else {
                break
            }
        }
        return $text
    }
    proc retryCode {code {attempts 30} {delay 1000}} {
        while {$attempts > 0} {
            incr attempts -1
            if {[set c [catch {
                uplevel 1 $code
            } kk]]} {
                if {($c == 2) || ($c == 3)} {
                    # 2 = return ; 3 = break
                    return $kk
                }
                if {$attempts == 0} {
                    error $kk $::errorInfo $::errorCode
                }
                after $delay
            }  else  {
                return $kk
            }
        }
        # should never reach here
        error "Unknown error"
    }

    proc killChrootProcesses {chroot args} {
	foreach g [glob /proc/*] {
	    if {[catch {set link [xampptcl::file::readlink $g/root] ; set exe [xampptcl::file::readlink $g/exe]} kk]} {
		continue
	    }
	    if {$link == $chroot} {
		set kill 0
		set pid [file tail $g]
		foreach pattern $args {
		    if {[string match $pattern $exe]} {
			set kill 1
			break
		    }
		}
		if {$kill} {
		    message info "Killing process $pid ($exe)"
		    exec kill $pid
		    after 5000
		    # ensure the process was stopped or kill it
		    if {![catch {set exe2 [xampptcl::file::readlink $g/exe]}] && [string equal $exe $exe2]} {
			message info "Force-killing process $pid ($exe)"
			exec kill -9 $pid
		    }
		}
	    }
	}
    }

    proc loadNbdModule {} {
        if {![regexp -line {^nbd} [exec lsmod]]} {
            exec modprobe nbd max_part=63 nbds_max=64
        }
    }

    proc createNbdDevices {dev {all true}} {
        # reasonable default if module was loaded with maxpart=63
        set minorDifference 64
        # determine difference between nbd1 and nbd0 in block device
        # minor type to determine increase between devices
        catch {
            set nbd1 [string trim [exec stat -c "0x%T" /dev/nbd1]]
            set nbd0 [string trim [exec stat -c "0x%T" /dev/nbd0]]
            set minorDifference [expr {$nbd1 - $nbd0}]
        }
        set major 43

        set minor [expr {$dev * $minorDifference}]

        lappend devices /dev/nbd${dev} $major $minor
        if {$all} {
            for {set i 1} {$i < 16} {incr i} {
                 lappend devices /dev/nbd${dev}p${i} $major [expr {$minor + $i}]
            }
        }
        foreach {device major minor} $devices {
            if {![file exists $device]} {
                logexec mknod $device b $major $minor
                file attributes $device -group disk -permissions 060661
            }
        }
    }

    proc createNbdDevice {args} {
        loadNbdModule
        for {set dev 0} {$dev < 64} {incr dev} {
            set nbd /dev/nbd$dev
            # create main device only
            createNbdDevices $dev false
            if {[catch {
                # use cache=unsafe which is fastest and only really not safe in case of
                # power failure which we are not worried about
                exec qemu-nbd --cache=unsafe -c $nbd {*}$args
            } kk]} {
                xampptcl::util::debug "Unable to create NBD for $nbd : $kk"
            }  else  {
                # delay so devices are created automatically if possible
                after 2000
                createNbdDevices $dev true
                return $nbd
            }
        }
        error "Unable to find free nbd device"
    }

    # Useful to transfer more than 1 file through rsync
    proc initialiazeSshSession {host password {timeout 3}} {
        set id [xampptcl::util::uniqid]
        set tmpSshSocket [file join /tmp temp_ssh_[xampptcl::util::uniqid]]
        file delete -force $tmpSshSocket
        # SSH prompts for the password using a different
        set command "setsid ssh -N -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -o ControlMaster=yes -o ControlPath=$tmpSshSocket $host &"
        xampptcl::file::write ${tmpSshSocket}.secret "#!/bin/sh
echo \"$password\""
        file attributes ${tmpSshSocket}.secret -permissions 0755
        set sessionPid [execEnv [list DISPLAY "" SSH_ASKPASS ${tmpSshSocket}.secret] {
            eval exec $command
        }]
        after [expr {$timeout*1000}]
        file delete -force ${tmpSshSocket}.secret
        if {[isPidRunning $sessionPid]} {
            xampptcl::file::write ${tmpSshSocket}.pid "$sessionPid"
        } else {
            error "Error creating SSH session to $host"
        }
        return $tmpSshSocket
    }
    proc closeSshSession {tmpSshSocket {host {}}} {
        set sessionPid [xampptcl::file::read ${tmpSshSocket}.pid]
        if {$host == ""} {
            if {[isPidRunning $sessionPid]} {
                exec kill -9 $sessionPid
            }
        } else {
            if {[catch {xampptcl::util::nonBlockingExecUnix ssh "-O exit -o ControlPath=\"$tmpSshSocket\" $host"} kk]} {
                kill -9 $sessionPid
            }
        }
        file delete -force $tmpSshSocket
        file delete -force ${tmpSshSocket}.pid
    }

    proc reverseMapList {map} {
        # Covers degenerate case of 1 or 0 elements
        set result {}
        if {[expr [llength $map] % 2] != 0} {
          # We discard the last element
          set map [lrange $map 0 end-1]
        }
        foreach {a b} $map {
          lappend result $b $a
        }
        return $result
    }

    proc showPasswordQuestion {msg} {
        puts -nonewline "$msg \[********\]: "
        flush stdout
        catch {exec stty -echo}
        set pass [gets stdin]
        catch {exec stty echo}
        puts { }
        return $pass
    }
}

namespace eval ::xampptcl::file {
    proc prependTextToFile {dest text {encoding {}}} {
        if {![file exists $dest]} {
            xampptcl::file::write $dest {} $encoding
        }
        set prevText [xampptcl::file::read $dest $encoding]
        xampptcl::file::write $dest $text$prevText $encoding
    }
    proc addTextToFile {dest text {encoding {}}} {
        if {![file exists $dest]} {
            xampptcl::file::write $dest {} $encoding
        }
        set prevText [xampptcl::file::read $dest $encoding]
        xampptcl::file::write $dest $prevText$text $encoding
    }
    proc write {dest text {encoding {}}} {
        set f [open $dest w]
	if {$encoding != ""} {
	    fconfigure $f -encoding $encoding
	}
        puts -nonewline $f $text
        close $f
    }

    proc read {dest {encoding {}}} {
        set f [open $dest r]
	if {$encoding != ""} {
	    fconfigure $f -encoding $encoding
	}

        set r [::read $f]
        close $f
        return $r
    }
    proc fileContains {f pattern {type glob}} {
        set text [read $f]
        if {$type == "glob"} {
            return [string match *$pattern* $text]
        } else {
            if {[catch {
                set r [regexp -- $pattern $text]
            } kk]} {
                error "Error checking fileContains $f $pattern"
            }
            return $r
        }
    }
    proc append {dest text} {
        set t [read $dest]
        ::append t $text
        write $dest $t
    }
    proc readlink {file} {
        set target $file
        # Counter to avoid infinite loop with symlink to the same file
        set counter 0
        while {[file type $target] == "link" && $counter < 20 } {
            incr counter
            set target [file join [file dirname $target] [file readlink $target]]
        }
        if { $counter >= 20 } {
            puts "Infinite loop in link $target"
        }
        return [file normalize $target]
    }
}
