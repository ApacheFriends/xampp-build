# common.tcl
# common classes

lappend ::auto_path .
source color.tcl
package require bitnami::util
package require bitnami::itcl

# http://www.planetpenguin.de/manpage-1-cli.1.html
# Also take a look at packagers site for how they build it on different platforms

if {![info exists prefix]} {
    set prefix [file normalize [file dirname [info script]]/..]
}

#message info "Using prefix $prefix"

source timer.tcl
package require bitnami::timer

source versions.tcl
package require bitnami::versions

package require bitnami::itcl
package require vfs
catch {package require mk4vfs}
catch {package require Mk4tcl}
catch {package require vfs::mk4}

array set ::opts [list \
    cvsroot /var/cvsroot/ \
    buildroot /bitnami \
    tarballs /tmp/tarballs \
    srcdir [file dirname [file dirname [file normalize [info script]]]]]


if {![info exists ::env(LD_LIBRARY_PATH)]} {
    set ::env(LD_LIBRARY_PATH) ""
}

if {$::tcl_platform(os) == "SunOS"} {
# Need to get first /usr/local/bin to pickup make, patch, etc.
    set ::env(PATH) "/usr/local/bin:$::env(PATH):/usr/ccs/bin"
    set ::env(CFLAGS) "-fPIC"
    set ::env(CC) gcc
    set ::env(CXX) g++
}

::itcl::class apachePhpSettingsNormalizer {
    public variable ifmodulesStack {}
    public variable rewrote 0
    constructor {} {

    }
    public method textWasRewritten {} {
        return $rewrote
    }
    public method insideIfPhpModule {} {
        if {[::xampptcl::util::listContains $ifmodulesStack "mod_php5.c"] || [::xampptcl::util::listContains $ifmodulesStack "mod_php4.c"] || [::xampptcl::util::listContains $ifmodulesStack "php5_module"]} {
            return 1
        } else {
            return 0
        }
    }
    public method ifModuleStart {text} {
        set module [string trim $text " \">"]
        lappend ifmodulesStack $module
    }
    public method ifModuleEnd {args} {
        set module [lindex $ifmodulesStack end]
        #puts "Unloading $module"
        set ifmodulesStack [lrange $ifmodulesStack 0 end-1]
    }

    public method phpCommand {cmd args} {
        if {![insideIfPhpModule]} {
            #   puts "Executed $cmd $args outside ifmodule!"
        }
    }
    public method shouldWrapPhpCmd {cmd rest} {
        if {[insideIfPhpModule]} {
            return 0
        } else {
            return 1
        }
    }
    public method cleanText {f} {
        set t [getCleanedText $f]
        if {[textWasRewritten]} {
            set perm [file attributes $f -permissions]
            xampptcl::file::write $f $t
            file attributes $f -permissions $perm
        }
    }
    public method getCleanedText {f} {
        set lines {}
        set rewrote 0
        set previousLineWasPhpSetting 0
        foreach lorig [split [::xampptcl::file::read $f] \n] {
            set l [string trim $lorig]

            regexp {^([^\s]+)((\s+.*)?)$} $l - cmd rest
            switch -- $cmd {
                php_flag - php_value - php_admin_value - php_admin_flag {
                    if {[shouldWrapPhpCmd $cmd $rest]} {
                        puts "Wrapping php setting '$cmd $rest' from $f in ifModule"
                        set rewrote 1
                        set previousLineWasPhpSetting 1
                        ifModuleStart mod_php5.c
                        lappend lines "<IfModule mod_php5.c>"
                    }
                    lappend lines $lorig
                }
                "<IfModule" {
                    if {$previousLineWasPhpSetting} {
                        lappend lines "</IfModule>"
                        ifModuleEnd
                        set previousLineWasPhpSetting 0
                    }
                    ifModuleStart $rest
                    lappend lines $lorig
                }
                "</IfModule>" {
                    if {$previousLineWasPhpSetting} {
                        lappend lines "</IfModule>"
                        ifModuleEnd
                        set previousLineWasPhpSetting 0
                    }
                    ifModuleEnd
                    lappend lines $lorig
                }
                default {
                    if {$previousLineWasPhpSetting} {
                        lappend lines "</IfModule>"
                        ifModuleEnd
                        set previousLineWasPhpSetting 0
                    }
                    lappend lines $lorig
                }
            }
        }
        # Close if the lines ended and we are inside a phpmodule
        if {[insideIfPhpModule]} {
            lappend lines "</IfModule>"
            ifModuleEnd
            set previousLineWasPhpSetting 0
        }
        return [join $lines \n]
    }
}


::itcl::class metadataObject {
    public variable identifier {}

    public variable translationLanguagesList {}

    public variable be {}

    public variable ohlohId {}
    protected variable ohlohUrl {}

    public variable uniqueIdentifier {}

    protected variable appProjectDir {}

    protected variable _metadata

    public variable fullname {}
    public variable organization {}
    public variable supportUrl {}

    public variable rubyVersion
    public variable rubyMajorVersion

    public variable apiName ""
    public variable apiFile ""

    public variable docsBaseUrl "https://docs.bitnami.com/"
    public variable credentialInformation ""

    protected variable metadataFiles [list \
        [file join $::bitnami::rootPath metadata components general.ini]]

    array set _metadata {}

    constructor {environment} {
        set be $environment
    }

    public method markAsInternal {} {
        if {[lindex [$this info heritage] 0] == [uplevel namespace current]} {
            setMetadata this {isInternalClass 1}
        }
    }
    public method useGCC49Env {} {
        if {![string match *$::env(GCC49_BIN)* $::env(PATH)]} {
            set ::env(OLD_PATH) $::env(PATH)
            set ::env(PATH) $::env(GCC49_BIN):$::env(PATH)
            if { [string match linux-x64 [$be cget -target]] } {
                set ::env(OLD_LD_LIBRARY_PATH) $::env(LD_LIBRARY_PATH)
                set ::env(LD_LIBRARY_PATH) $::env(GCC49_LIB64):$::env(LD_LIBRARY_PATH)
            } elseif { [string match osx* [$be cget -target]] } {
                set ::env(OLD_DYLD_LIBRARY_PATH) $::env(DYLD_LIBRARY_PATH)
                set ::env(OLD_LD_LIBRARY_PATH) $::env(LD_LIBRARY_PATH)
                set ::env(DYLD_LIBRARY_PATH) $::env(GCC49_LIB):$::env(DYLD_LIBRARY_PATH)
                set ::env(LD_LIBRARY_PATH) $::env(GCC49_OUTPUT):$::env(LD_LIBRARY_PATH)
            }
        }
    }

    public method unuseGCC49Env {} {
        if {[string match *$::env(GCC49_BIN)* $::env(PATH)]} {
            set ::env(PATH) $::env(OLD_PATH)
            catch {unset ::env(OLD_PATH)}
            if { [string match linux-x64 [$be cget -target]] } {
                set ::env(LD_LIBRARY_PATH) $::env(OLD_LD_LIBRARY_PATH)
                catch {unset ::env(OLD_LD_LIBRARY_PATH)}
            } elseif { [string match osx* [$be cget -target]] } {
                set ::env(DYLD_LIBRARY_PATH) $::env(OLD_DYLD_LIBRARY_PATH)
                set ::env(LD_LIBRARY_PATH) $::env(OLD_LD_LIBRARY_PATH)
                catch {unset ::env(OLD_LD_LIBRARY_PATH)}
                catch {unset ::env(OLD_DYLD_LIBRARY_PATH)}
            }
        }
    }

    public method useGcc8Env {} {
        if {![string match *$::env(GCC8_BIN)* $::env(PATH)]} {
            set ::env(OLD_PATH) $::env(PATH)
            set ::env(PATH) $::env(GCC8_BIN):$::env(PATH)
            if { [string match linux-x64 [$be cget -target]] } {
                set ::env(OLD_LD_LIBRARY_PATH) $::env(LD_LIBRARY_PATH)
                set ::env(LD_LIBRARY_PATH) $::env(GCC8_LIB64):$::env(LD_LIBRARY_PATH)
            } elseif { [string match osx* [$be cget -target]] } {
                set ::env(OLD_DYLD_LIBRARY_PATH) $::env(DYLD_LIBRARY_PATH)
                set ::env(OLD_LD_LIBRARY_PATH) $::env(LD_LIBRARY_PATH)
                set ::env(DYLD_LIBRARY_PATH) $::env(GCC8_LIB):$::env(DYLD_LIBRARY_PATH)
                set ::env(LD_LIBRARY_PATH) $::env(GCC8_OUTPUT):$::env(LD_LIBRARY_PATH)
            }
        }
    }

    public method unuseGcc8Env {} {
        if {[string match *$::env(GCC8_BIN)* $::env(PATH)]} {
            set ::env(PATH) $::env(OLD_PATH)
            catch {unset ::env(OLD_PATH)}
            if { [string match linux-x64 [$be cget -target]] } {
                set ::env(LD_LIBRARY_PATH) $::env(OLD_LD_LIBRARY_PATH)
                catch {unset ::env(OLD_LD_LIBRARY_PATH)}
            } elseif { [string match osx* [$be cget -target]] } {
                set ::env(DYLD_LIBRARY_PATH) $::env(OLD_DYLD_LIBRARY_PATH)
                set ::env(LD_LIBRARY_PATH) $::env(OLD_LD_LIBRARY_PATH)
                catch {unset ::env(OLD_LD_LIBRARY_PATH)}
                catch {unset ::env(OLD_DYLD_LIBRARY_PATH)}
            }
        }
    }

    public method setMetadata {args} {
        foreach {variable metadata} $args {
            if {[llength $metadata] % 2 != 0} {
                error "Uneven number of arguments in metadata"
            }
            foreach {key value} $metadata {
                set _metadata($variable.$key) $value
            }
        }
    }
    public method getMetadata {variable key} {
        if {[info exists _metadata($variable.$key)]} {
            #xampptcl::util::debug "Returning $this: $variable $key"
            return $_metadata($variable.$key)
        }
        switch -- $key {
            isInternalClass {
                return 0
            }
            default {
                return ""
            }
        }
    }
    public method isInternal {} {
        set class [lindex [split [$this info class] :] end]
        if {[::itcl::isInternalClass $class]} {
            return 1
        } elseif {[xampptcl::util::isBooleanYes [getMetadata this isInternalClass]]} {
            return 1
        } else {
            return 0
        }
    }
    public method getExternalMetadataFiles {} {
        return $metadataFiles
    }

    public method getOhlohUrl {} {
        if {$ohlohUrl != ""} {
            return $ohlohUrl
        }
        set apiKey [bitnami::cfgGet api_key Ohloh]
        if {$apiKey == ""} {
            message warning "Cannot find Ohloh api_key in config file"
            return
        }
        if {$ohlohId != ""} {
            set ohlohUrl http://www.ohloh.net/p/$ohlohId.xml?api_key=$apiKey
        } elseif {[set ohlohId [getExternalMetadataKey ohloh_id]] != ""} {
            set ohlohUrl http://www.ohloh.net/p/$ohlohId.xml?api_key=$apiKey
        }
        return $ohlohUrl
    }
    public method getCacheDir {} {
        return [file join [bitnami::storageDir] cache]
    }
    public method getMetadataFromOhloh {} {
        if {$ohlohId == "" && [regexp {^http://www.ohloh.net/p/(.*?)\.xml.*} [getOhlohUrl] - id]} {
            set ohlohId $id
        }
        set cacheFile [file join [getCacheDir] ohloh $ohlohId.xml]

        if {[file exists $cacheFile]} {
            set xmlData [xampptcl::file::read $cacheFile]
        } else {
            file mkdir [file dirname $cacheFile]
            set xmlData [bitnami::httpGet [getOhlohUrl]]
            ::xampptcl::file::write $cacheFile $xmlData
        }
        set res {}
        if {[catch {
            package require tdom
            set dom [dom parse $xmlData]
            set doc [$dom documentElement]
            set status [$doc selectNodes {string(/response/status)}]
            if {$status != "success"} {
                error "Incorrect status '$status', expected 'success'"
            }
            set xPathRoot "/response/result/project"
            foreach {key xpathExpr} [list description description url homepage_url download_url download_url] {
                set val [$doc selectNodes string($xPathRoot/$xpathExpr)]
                lappend res $key $val
            }
            set licenses {}
            foreach lic [$doc selectNodes $xPathRoot/licenses/license] {
                set licName [$lic selectNodes string(./name)]
                set licNiceName [$lic selectNodes string(./nice_name)]

                lappend licenses [list $licName $licNiceName]
            }
            lappend res licenses $licenses
        } kk]} {
            error "Cannot parse response from Ohloh: $kk"
        }
        return $res
    }

    public method getMetadataFromRemoteSource {} {
        set res {}
        if {[set url [getOhlohUrl]] != ""} {
            set res [getMetadataFromOhloh]
        } else {

        }
        return $res
    }
    public method isUnreportedLicenseType {vendor licenseType {section {}}} {
        if {$section == ""} {
            set section [getUniqueIdentifier]
        }
        foreach l [split [getLicenses $section] \;] {
            if {[string match $licenseType [string tolower [normalizeLicense $l]]]} {
                set reportedVendors [getExternalMetadataKey "reported_vendors" $section]
                foreach v [split $reportedVendors \;] {
                    set v [string trim $v]
                    if {[string equal -nocase $v $vendor]} {
                        return 0
                    }
                }
                return 1
            }
        }
        return 0
    }
    public method isAgpl {} {
        return [string match -nocase *AGPL* [$this getLicenses]]
    }
    public method isCddl {} {
        return [string match -nocase *CDDL* [$this getLicenses]]
    }
        public method isWtfpl {} {
        return [string match -nocase *WTFPL* [$this getLicenses]]
    }
    # Non-whitelisted licenses are those which are something other than MIT, BSD or APACHE
    public method isNotGoogleWhitelisted {} {
        # This splits the licenses and returns 1 if any of them is something other than MIT, BSD or APACHE
        set obtainedLicenses [$this getLicenses]
        set exitCode 0
        if { $obtainedLicenses == "" } {
            set exitCode 2
        } else {
            foreach l [split $obtainedLicenses \;] {
                if {![string match -nocase *MIT* $l] && ![string match -nocase *BSD* $l] && ![string match -nocase *APACHE* $l]} {
                    set exitCode 1
                }
            }
        }
        return $exitCode
    }
    public method isUnreportedGpl {vendor} {
        return [isUnreportedLicenseType $vendor gpl*]
    }
    public method isUnreportedAgpl {vendor} {
        return [isUnreportedLicenseType $vendor agpl*]
    }
    public method isUnreportedWtfpl {vendor} {
        return [isUnreportedLicenseType $vendor wtfpl*]
    }
    public method isUnreportedCommercial {vendor} {
        return [isUnreportedLicenseType $vendor commercial*]
    }

    public method getLocalPhpBin {{version 8.0}} {
        set localPhpBin php
        set lampstackPhpBin /home/bitnami/lampstack-${version}/php/bin/php

        # Use sandbox if local lampstack is found
        if {[file exists $lampstackPhpBin]} {
            set phpBin $lampstackPhpBin
        } else {
            set phpBin $localPhpBin
        }

        if {[catch {eval exec $phpBin -v} err]} {
            message error "$phpBin was not found. Please, install php $version to generate tarballs."
            exit 1
        }

        set phpVersion [exec $phpBin -v | grep -v Copyright]
        if {![regexp "\\s*PHP\\s*$version.*" $phpVersion]} {
            message error "Your php version is not $version. Please, install php $version to generate tarballs."
            exit 1
        }
        return $phpBin
    }

    public method getMainComponentLicense {} {
        set licenses [split [getExternalMetadataKey "licenses"] \;]
        set licensesLen [llength $licenses]
        set main_license [getExternalMetadataKey "main_license"]
        set component_name [getExternalMetadataKey "name"]
        if {$main_license != ""} {
            if {$licensesLen <= 1 } {
                error "If there is only one license for $component_name, you should set it in licenses"
            } elseif {![xampptcl::util::listContains $licenses $main_license]} {
                error "The $main_license main_license for $component_name should be part of the licenses list"
            }
            return $main_license
        } else {
            if {$licensesLen > 1} {
                error "If the $component_name component have more than one license, you should set main_license"
            } else {
                return [lindex $licenses 0]
            }
        }
    }
    public method getMainComponentLicenseURL {} {
        set license [$this getMainComponentLicense]
        return [getLicenseMainURL $license]
    }

    public method getLicenseMainURL {license} {
        if {[string match CUSTOM=* $license] || [string match COMMERCIAL=* $license]} {
            return [lindex [split $license =] 1]
        }
        foreach {name url aliases notes} [knownLicensesInfo] {
            if {[string match $name $license]} {
                return $url
            }
        }
    }

    public method getLicenses {{section {}}} {
        if {$section == ""} {
            set section [getUniqueIdentifier]
        }
        set licenses [getExternalMetadataKey "licenses" $section]
        set errors {}
        foreach l [split $licenses \;] {
            if {[catch {checkLicense $l} kk]} {
                lappend invalidLicenses $l
                lappend errors  "Error validating license for component $section: $kk"
            }
        }
        if {$errors != ""} {
            error [join $errors \n]
        }
        return $licenses
    }

    public method getLicenseUrl {{section {}}} {
        if {$section == ""} {
            set section [getUniqueIdentifier]
        }
        set licenseUrl [getExternalMetadataKey "license_url" $section]
        return $licenseUrl
    }

    public method getDownloadUrl {{section {}}} {
        if {$section == ""} {
            set section [getUniqueIdentifier]
        }

        if {[$this cget -downloadType] != "" && [$this cget -downloadUrl] != ""} {
            set downloadUrl [$this cget -downloadUrl]
        } elseif {[getExternalMetadataKey "download_url" $section] != ""} {
            set downloadUrl [getExternalMetadataKey "download_url" $section]
        } else {
            if [string match nodejs_* $section] {
                set nodeModule  [string map {nodejs_ ""} $section]
                set downloadUrl "https://www.npmjs.com/package/$nodeModule"
            } elseif [string match gem_* $section] {
                set gem [string map {gem_ ""} $section]
                set downloadUrl "https://rubygems.org/gems/$gem"
            } elseif [string match python_* $section] {
                set module [string map {python_ ""} $section]
                set downloadUrl "https://pypi.org/project/$module/#files"
            } else {
                message error "The component $section does not have a valid download URL"
            }
        }
        return $downloadUrl
    }

    protected common externalMetadataIni {}
    public method loadExternalMetadataFiles {} {
        # keep ini file open to significantly speed up license checks
        if {$externalMetadataIni == {}} {
            foreach f [getExternalMetadataFiles] {
                lappend externalMetadataIni [::ini::open [file join $f] r]
            }
        }
    }

    public method externalMetadataHasSection {section} {
        loadExternalMetadataFiles
        foreach fp $externalMetadataIni {
            if {[::bitnami::fileDescriptorHasSection $fp $section]} {
                return 1
            }
        }
        return 0
    }

    public method getExternalMetadataKey {k {section {}}} {
        loadExternalMetadataFiles
        if {$section == ""} {
            set section [getUniqueIdentifier]
        }
        foreach fp $externalMetadataIni {
            array set data [::bitnami::iniGet $fp $section {}]
            # return on first match
            if {[info exists data($k)]} {
                return $data($k)
            }
        }
        return ""
    }

    public method getMainComponentXMLName {} {
        if {[$this cget -mainComponentXMLName] == ""} {
            return [string tolower [getUniqueIdentifier]]
        } else {
            return [$this cget -mainComponentXMLName]
        }
    }

    public method getUniqueIdentifier {} {
        if {$uniqueIdentifier != ""} {
            return $uniqueIdentifier
        } elseif {[$this cget -name] != "<undefined>"} {
            return [$this cget -name]
        } else {
            return [lindex [split [$this info class] :] end]
        }
    }


    # Change this so we only have name, not name and shortname
    public method getIdentifier {} {
        if {$identifier != ""} {
            return $identifier
        } elseif {[$this isa releasable]} {
            return [$this cget -shortname]
        } else {
            return [$this cget -name]
        }
    }

    # Unique key that identifies a particular product in bitnami.com and the rest of our services
    public method bitnamiPortalKey {} {
        return [getIdentifier]
    }

    public method confFileName {} {
        set cn [string map {:: ""} [$this info class]]
        return [string map {stack ""} $cn]
    }

    public method getAppProjectDir {} {
	if {$appProjectDir != ""} {
	    return $appProjectDir
	} else {
	    return [getIdentifier]
	}
    }

    public method validTimeStamp {directory} {
        set valid 0
        set timestampFile [file join $directory .timestamp]
        # We consider an invalid TimeStamp when it has expired
        # or when can't retrieve the timestamp from the file.
        if {[file exists $timestampFile]} {
          set oldTimeStamp [xampptcl::file::read $timestampFile]
            if {$oldTimeStamp != ""} {
                set elapsedTime [expr [clock seconds] - $oldTimeStamp]
                set expirationDays 7
                set validTime [expr {$expirationDays * 24 * 3600}]
                if {$elapsedTime < $validTime} {
                    set valid 1
                }
            }
        }
        return $valid
    }
    protected method localesDirectory {} {
        return [file join [$be cget -poDirectory] [bitnamiPortalKey] locales]
    }
    protected method getLocaleDescKey {} {
        return "application_description|[bitnamiPortalKey]"
    }
    protected method getLocaleLicenseDescKey {} {
        return "application_license_description|[bitnamiPortalKey]"
    }
    protected method translationsRelativeOutputDir {} {
        return [file join [bitnamiPortalKey] locales]
    }
    public method copyTranslations {lngList dest} {
	array set tmpArray {}
	set lngList [lsort -unique [concat $lngList $translationLanguagesList]]
	set destinationDir [file join $dest [translationsRelativeOutputDir]]
	set translations [glob -nocomplain [file join [localesDirectory] *]]
	if {$translations == ""} {
	    return
	}
	file mkdir $destinationDir
	foreach f $translations {
	    file copy -force $f $destinationDir/
	}
	set defaultLngFile [getPoFile]

	if {![file exists $defaultLngFile]} {
	    return
	}

	foreach langID $lngList {
	    set destFile $destinationDir/$langID.po
	    if {![file exists $destFile]} {
		file copy -force $defaultLngFile $destFile
	    }
            xampptcl::translation::poFileAdd $defaultLngFile $destFile utf-8 1
	    set tmpArray($langID) $destFile
	}
	return [array get tmpArray]
    }

    public method getNameForPlatform {} {
        return [$this cget -name]
    }
    public method isWindows {} {
        return [string match windows* [$be cget -target]]
    }
    public method isWindows64 {} {
        return [string match windows-x64 [$be cget -target]]
    }
    public method getImagesDirectory {} {
        set d [file join [$be cget -projectDir] apps [getNameForPlatform] img]
        if {[file exists $d]} {
            return $d
        }
    }

    public method getStackLogoImage {{flavour ""}} {
        if { $flavour != "" } {
            set logoFile [getNameForPlatform]-$flavour.png
        } else {
            set logoFile [getNameForPlatform].png
        }
        return [file join [getImagesDirectory] $logoFile]
    }
    public method getStackFixedImage {} {
        # We will use the same image as the one we use in the manager until we have another one for that purpose
        return [getStackLogoImage "manager"]
    }

}

::itcl::class buildEnvironment {
    public variable action
    public variable root
    public variable tarballs
    public variable betaTarballs
    public variable src
    public variable output
    public variable builddep
    public variable tarOutputDir
    public variable baseTarballOutputDir {}
    public variable projectDir
    public variable networkServiceBinDir
    public variable binaries
    public variable clientFilesDir
    public variable compiledTarballs
    public variable utils
    public variable libprefix {}
    public variable licensesDirectory
    public variable poDirectory "/bitnami/bitnami-locales"
    public variable target
    public variable platformID
    public variable product
    public variable buildType fromTarball
    public variable buildApplicationType fromApplicationTarball
    public variable continueAtComponent {}
    public variable tmpDir "/tmp"
    public variable filesToIgnoreWhenPacking "CVS .svn .DS_Store .git .buildcomplete NOTEMPTY .history"
    public variable osxPlatforms "osx-intel osx-x86_64"
    public variable setvars {project.showFileUnpackingProgress=0}
    public variable enableDebugger 0
    public variable removeDocs 1
    public variable rootS3TarballPath "s3://apachefriends"
    public variable thirdpartyPath
    public variable thirdpartyS3Path
    public variable disableTempTarballPath 0
    public variable vtrackerParser {}
    public variable timer {}
    public variable verifyLicences 0

    constructor {} {
        if {![info exists ::env(DISABLE_LZMA_ULTRA)]} {
            lappend setvars project.compressionAlgorithm=lzma-ultra
        } else {
            lappend setvars project.compressionAlgorithm=zip
        }
        set prefix $::prefix
        set projectDir $prefix
        set clientFilesDir /opt/client-files
        set networkServiceBinDir /opt/network-binaries
        set tarballs /tmp/tarballs
        set compiledTarballs /tmp/compiled-tarballs
        set betaTarballs /tmp
        set libprefix common
        set thirdpartyPath "/tmp/tarballs"
        set thirdpartyS3Path "apachefriends/opt/thirdparty/tarballs"

        initializeVtracker [list [file join $projectDir tools vtracker applications] \
                                [file join $projectDir tools vtracker infrastructure] \
                                [file join $projectDir tools vtracker base]]

        # Timer
        set timer [bitnami::timer ::\#auto]
    }

    public method setTimerValues {productName {productVersion 0} {productRevision 0}} {
        set jobNumber 0
        if {[info exists ::env(BUILD_NUMBER)]} {
            set jobNumber $::env(BUILD_NUMBER)
        }
        if {[info exists ::env(JOB_NAME)]} {
            regsub "stackbuild-" $::env(JOB_NAME) {} jobFolder
        } else {
            if {[string match *stack* $productName] == 1} {
                regsub "stack" $productName {} jobFolder
            } elseif {[string match *module* $productName] == 1} {
                regsub "module" $productName {} jobFolder
            }
        }

        $timer setValues $action $productName $jobNumber $target $jobFolder $productVersion $productRevision
    }
    public method clearTimer {{event {}}} {
        $timer clear $event
    }
    public method startTimer {event} {
        $timer start $event
    }
    public method stopTimer {event} {
        $timer stop $event
    }
    public method evalTimer {event {code {}}} {
        $timer start $event
        uplevel 1 $code
        $timer stop $event
    }
    public method getTimerReport {} {
        $timer getReport
    }

    public method initializeVtracker {f} {
        set vtrackerParser [vtrackerParser ::\#auto]
        foreach trackerFile $f {
            $vtrackerParser loadFile $trackerFile
        }
    }

    public method targetPlatform {} {
        set result {}
        if {[info exists target] && $target != ""} {
            set result $target
        } else {
            set result [xampptcl::util::platform]
        }
        return $result
    }
    public method checkEnvironment {} {
        if {$::tcl_platform(os) == "Darwin"} {
            return
        }
        if {[string match linux* $target]} {
            if {![file isfile /proc/devices]} {
                error "Your /proc folder does not have devices file. A possible cause is that you do not have mounted the /proc folder in the chroot."
            }
        }
    }

    public method setupEnvironment {} {
        # Initial configuration
        set prefix $::prefix
        set projectDir $prefix
        set ::env(CFLAGS) "-I$output/common/include"
	# debugging
	set ::env(CPPFLAGS) "-I$output/common/include"
        set ::env(LDFLAGS) -L$output/common/lib
        set ::env(LD_LIBRARY_PATH) $output/common/lib
        set ::env(DYLD_LIBRARY_PATH) $output/common/lib
        set ::env(CC) "gcc"
        if {$target=="linux" || $target=="linux-x64"} {
            set ::env(CFLAGS) "$::env(CFLAGS) -fPIC"
        }
        if {$target=="linux-x64"} {
            set ::env(CFLAGS) "$::env(CFLAGS) -m64"
        } elseif {$target=="linux"} {
	    set ::env(CFLAGS) "$::env(CFLAGS) -m32"
	    # -march=i486
	}
        if {$target=="osx-x64"} {
            set ::env(CFLAGS) "$::env(CFLAGS) -arch x86_64"
            set ::env(LDFLAGS) "$::env(LDFLAGS) -arch x86_64"
            set ::env(CPPFLAGS) "$::env(CPPFLAGS) -arch x86_64"
            if {[xampptcl::util::isOSX1010Chroot]} {
                set ::env(CXX) clang++
            }
        }
        if {$target=="aix" || $target=="hpux"} {
	    set ::env(CC) "cc"
	}
        if {$target=="aix"} {
             set ::env(CPPFLAGS) "-D_LINUX_SOURCE_COMPAT $::env(CPPFLAGS)"
        }
        if {$target=="solaris-intel"} {
            set ::env(CC) "cc"
            set ::env(CXX) "CC"
            set ::env(LD_LIBRARY_PATH) "/opt/lib:/usr/local/lib:$::env(LD_LIBRARY_PATH)"
	    set ::env(CFLAGS) "";
	    set ::env(PATH) "/opt/bin:/usr/local/bin:$::env(PATH)"
        }
        if {$target=="solaris-intel-x64"} {
            set ::env(CC) "cc -xarch=amd64"
            set ::env(CXX) "CC -xarch=amd64"
            set ::env(LD_LIBRARY_PATH) "/opt/lib/amd64:$::env(LD_LIBRARY_PATH)"
	    set ::env(CFLAGS) "-KPIC";
	    set ::env(LDSHARED) "cc -G -xarch=amd64";
	    set ::env(PATH) "/opt/bin:/usr/local/bin:$::env(PATH)"
        }
        if {$target=="solaris-sparc"} {
            if {[eval {exec uname -r}]=="5.8"} {
                set ::env(CFLAGS) "-xO3 -Xa -xstrconst -mt -D_FORTEC_ -xarch=v9 -KPIC";
                set ::env(LDFLAGS) "-xarch=v9";
                set ::env(LDSHARED) "cc -G -xarch=v9";
		set ::env(LD_LIBRARY_PATH) "/bitrock/SUNWspro/lib:$::env(LD_LIBRARY_PATH)"
		set ::env(PATH) "/bitrock/SUNWspro/bin:/usr/local/bin:$::env(PATH)"
	        set ::env(CXX) "cc"
            } else {
                set ::env(CFLAGS) "-xO3 -Xa -xstrconst -mt -D_FORTEC_ -m64 -KPIC";
		set ::env(CXXFLAGS) "-m64 -KPIC";
                set ::env(LDFLAGS) "-m64";
                set ::env(LDSHARED) "cc -G -m64";
                set ::env(LD_LIBRARY_PATH) "/opt/solarisstudio12.3/lib/sparc/64:/usr/lib/sparcv9:/usr/sfw/lib/sparcv9:/opt/solarisstudio12.3/lib:/usr/local/lib:/usr2/local/lib:/usr/sfw/lib:$::env(LD_LIBRARY_PATH)"
                set ::env(PATH) "/opt/solarisstudio12.3/bin/sparcv9:/usr/local/bin/sparcv9:/usr/sbin/sparcv9:/usr/bin/sparcv9:/opt/solarisstudio12.3/bin:/usr/local/bin:/usr2/local/bin:$::env(PATH)"
	        set ::env(CXX) "CC"
            }
	    set ::env(CC) "cc"
        }
    }

    public method setupDirectories {} {
        set dirList {output licensesDirectory}
        if {$buildType=="fromSourceComplete" || $target=="windows"} {
            lappend dirList src
        }
        foreach dir $dirList {
            if {[file exists [file join $dir proc]]} {
              # just in case if we had unclean build
              set unattendedPrefix [[$be cget -product] cget -unattendedPrefix]
              catch {exec chroot $dir] [file join / opt $unattendedPrefix ctlscript.sh] stop;after 5000}
              catch {exec umount [file join $dir proc]; after 3000}
              catch {exec umount [file join $dir dev]; after 3000}
              catch {amiumount [$be cget -output]}
            }
            foreach f [glob -nocomplain [file join [set $dir] *]] {
                if { [file exists $f] } {
                  file delete -force $f
                }
            }
        }
        foreach dir {output licensesDirectory src} {
            file mkdir [set $dir]
        }
    }
    public method getOutputSuffix {} {
        switch -- $target {
            windows - windows-x64 {
                set outputsuffix exe
            }
            linux - linux-x64 {
                set outputsuffix run
            }
            osx-x86 - osx-x64 {
                set outputsuffix app
            }
            default {
                set outputsuffix run
            }
        }
        return $outputsuffix
    }

}

::itcl::class tarballCommon {
    protected common s3filelistInitialized false
    protected common s3filelist {}
    protected common s3filelistMap
    protected common s3paths {}
    protected common recursiveGlobCache

    public variable additionalFileList {}
    constructor {} {
	initializeS3
    }
    protected method initializeS3 {} {
        if {[file exists /bitnami/s3-filelist] && !$s3filelistInitialized} {
            set s3filelist [xampptcl::file::read /bitnami/s3-filelist]
            set s3paths {}
            foreach s3path $s3filelist {
                set s3filelistMap($s3path) 1
                # add file's directory and all directories to list of S3 directories
                for {set i 1} {$i < ([llength [split $s3path /]] - 1)} {incr i} {
                    set s3dirname [join [lrange [split $s3path /] 0 $i] /]
                    if {![info exists s3done($s3dirname)]} {
                        lappend s3paths $s3dirname
                        set s3done($s3dirname) 1
                    }
                }
            }
            set s3filelistInitialized 1
        }
    }
    protected proc recursiveGlobDir {dir} {
        if {![info exists recursiveGlobCache($dir)]} {
            set recursiveGlobCache($dir) [lsort -unique [concat [list $dir] [xampptcl::util::recursiveGlobDir $dir]]]
        }
        return $recursiveGlobCache($dir)
    }
    protected method tarballPath {} {
        set rc [recursiveGlobDir [$be cget -tarballs]]
        set rc [concat $rc [recursiveGlobDir [$be cget -clientFilesDir]]]
        return $rc
    }
    protected method pathJoin {dir name {be {}}} {
	if {[string match s3://* $dir]} {
	    return "$dir/$name"
	}  elseif  {$be != ""}  {
	    return [file join [$be cget -tarballs] $dir $name]
	}  else  {
	    return [file join $dir $name]
	}
    }
    protected method tarballExists {f} {
        if {[string match s3://* $f]} {
            if {[info exists s3filelistMap($f)]} {
                return 1
            }  else  {
                return 0
            }
        } elseif {[file exists $f]} {
            return 1
        } else {
            return 0
        }
    }
    public method findFile {fileName {exitOnError 1}} {
	if {[file pathtype $fileName] == "absolute"} {
	    if {[tarballExists $fileName]} {
		return $fileName
	    }  else  {
		message error "Not found file for $fileName"
		if {$exitOnError} {
		    exit 1
		} else {
		    return ""
		}
	    }
	}
        set dirTarballPath [tarballPath]
        foreach dir $dirTarballPath {
	    if { [string match */CVS $dir] } {
		continue
	    }
	    set f [pathJoin $dir $fileName]
	    if {[tarballExists $f]} {
		message info2 "Found file at $f"
		return $f
	    }
	}
        if {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
	    message info2 "File $fileName not found - searched [llength [tarballPath]] directories"
	}
        message error "Not found file for $fileName"
        if {$exitOnError} {
            exit 1
        } else {
            return ""
        }
    }
}

::itcl::class vtrackerParser {
    protected variable entries
    protected variable keys {}
    constructor {} {
        array set entries {}
    }
    public method config {args} {}
        public method prog {name equal data} {
            if {$equal != "="} {
                error "Cannot parse entry $name"
            }
            set entries([string tolower $name]) $data
            lappend keys $name
        }
    public method getEntry {name} {
        set name [string tolower $name]
        if {[info exists entries($name)]} {
            return $entries($name)
        } else {
            return ""
        }
    }
    public method getKeys {} {
        return $keys
    }
    public method getKey {section key} {
        set d [getEntry $section]
        if {$d != ""} {
            foreach l [split $d \n] {
                if {[regexp {^(\s*([^\s]+)\s*=\s*)(.*?)\s*$} $l match first k v]} {
                    if {[string equal -nocase [string trim $k] $key]} {
                        return $v
                    }
                }
            }
        } else {
            return ""
        }

    }
    public method updateEntry {name key value} {
        set d [getEntry $name]
        if {$d == ""} {
            return
        }
        set newData $d
        foreach l [split $d \n] {
            if {[regexp {^(\s*([^\s]+)\s*=\s*)(.*?)\s*$} $l match first k v]} {
                if {[string trim $k] == $key} {
                    set newData [string map [list $l $first$value] $newData]
                }
            }
        }
        return $newData
    }
    public method loadFile {f} {
        parse [xampptcl::file::read $f]
    }
    public method parse {data} {
        if {[catch {
            eval $data
        } kk]} {
            error "Error parsing vtracker data: $kk"
        }
    }
}


::itcl::class program {
    inherit tarballCommon metadataObject
    public variable name
    public variable vtrackerName {}
    public variable bitnamiPortalNames {}
    public variable version
    public variable rev 0
    #protected variable be
    protected variable separator -
    public variable patchList {}
    public variable patchStrip 1
    public variable patchLevel 0
    public variable licenseRelativePath COPYING
    public variable supportsParallelBuild 1
    public variable tarballName {}
    public variable tarballNameList {}
    public variable readmePlaceholder {}
    public variable moduleDependencies {}
    public variable deleteSourceDirWhenBuilding 1
    public variable pluginsList {}
    public variable pluginsDir {}
    public variable themesList {}
    public variable themesDir {}
    public variable licenseNotes {}
    public variable removeDocs 1
    public variable downloadUrl {}
    public variable downloadType {}
    public variable noCheckCertificate 0
    public variable downloadTarballName {}
    public variable downloadSearchStringPattern {}
    public variable downloadDepth 1
    public variable folderAtThirdparty {}
    public variable repositoryCheckout {}
    public variable splitRepositoryCheckout 1
    public variable requiredMemory 512
    public variable requiredDiskSize 10
    public variable requiredCores 1
    public variable supportsBanner 0
    public variable databaseManagementTool {}

    public variable isTrial 0
    public variable upgradable 0

    # Name of the xml where the component is bundled
    public variable mainComponentXMLName ""
    # Set if it is a main component
    # Displayed executing `tclkit createstack.tcl logProperties` and listed in the metadata we sent for the cloud vendors
    public variable isReportableAsMainComponent 1
    # Set if the component will be shown in the xml that we publish when we do a release
    public variable isReportableComponent 1
    protected common versionMapCache

    constructor {environment} {
        set be $environment
	metadataObject::constructor $environment
        set translationLanguagesList {en}
    } {}

    public method supportsParallelBuild {} {
        return $supportsParallelBuild
    }

    protected method getLicenseRelativePath {} {
        return $licenseRelativePath
    }
    public method  prepareXmlFiles {} {}
    public method copyStackLogoImage {} {}
    public method getProgramFiles {} {
    }
    public method getDescription {} {
        return
    }
    public method getLicenseDescription {} {
        return
    }

    public method getInstallerProjectXMLFiles {stack} {
    }

    public method getInstallerProjectImageFiles {} {
        return [glob -nocomplain [file join [getImagesDirectory] *.png] [file join [getImagesDirectory] *.icns]]
    }
    public method xmlDirectory {} {
    }
    public method copyModuleXMLFiles {} {
        foreach {module xmlFiles} $moduleDependencies {
	    foreach f $xmlFiles {
		file copy -force [xmlDirectory]/$f [$be cget -output]
	    }
        }
    }
    public method copyXmlFiles {stack} {
        foreach f [getInstallerProjectXMLFiles $stack] {
            file copy -force [file join [xmlDirectory] $f] [$be cget -output]
        }
    }
    public method copyProjectFiles {stack} {
	file mkdir [$be cget -output]/images
        copyXmlFiles $stack
        foreach f [getInstallerProjectImageFiles] {
            file copy -force $f [$be cget -output]/images/
        }

        if {$isTrial && [file exists [file join [getImagesDirectory] [getIdentifier]-favicon.ico]]} {
            file mkdir [$be cget -output]/img
            file copy -force [file join [getImagesDirectory] [getIdentifier]-favicon.ico] [$be cget -output]/img/
        }
    }

    public method buildReadme {readmeFile} {
        xampptcl::util::substituteParametersInFile $readmeFile \
            [list @@XAMPP_${readmePlaceholder}_VERSION@@ [$this versionNumber]]
    }
    public method versionNumber {} {
        return $version
    }
    public method revisionNumber {} {
        if {[info exists ::env(BITNAMI_NEW_VERSION)] && [xampptcl::util::isBooleanYes $::env(BITNAMI_NEW_VERSION)]} {
            return 0
        } else {
            return $rev
        }
    }
    public method getDefaultApplicationUser {} {
        return user
    }
    public method getDefaultApplicationPassword {} {
        return bitnami
    }

    public method needsToBeBuilt {} {
        if {[file exists [file join [srcdir] .buildcomplete]]} {
            return 0
        } else {
            return 1
        }
    }
    public method getOutputLicenseFile {} {
        if {[string length [getLicenseRelativePath]]} {
            set extension ".txt"
            set licenseExtension [file extension [srcdir]/[getLicenseRelativePath]]
            if {$licenseExtension == ".pdf" || $licenseExtension == ".html"} {
                set extension $licenseExtension
            }
        }
        set outputLicenseFile $name$extension
        return $outputLicenseFile
    }
    public method copyLicense {} {
        if {[string length [getLicenseRelativePath]]} {
            if {[catch {
                file mkdir [$be cget -licensesDirectory]
                file copy -force [srcdir]/[getLicenseRelativePath]  [$be cget -licensesDirectory]/[getOutputLicenseFile]
            } kk]} {
                if {[info exists ::env(IGNORE_MISSING_LICENSES)]} {
                    puts $kk
                    exec echo $kk >> /tmp/missing-licenses.txt
                } else {
                    error $kk $kk
                }
            }
        } else {
            foreach l [split [$this getLicenses] \;] {
                if {[file exists [$be cget -thirdpartyPath]/licenses/$l.txt]} {
                    file copy -force [$be cget -thirdpartyPath]/licenses/$l.txt  [$be cget -licensesDirectory]/$name-$l.txt
                }
            }
        }
    }
    public method initialize {be} {
    }
    public method cleanUp {} {
    }

    public method setBuildEnvironment {buildEnvironment} {
        set be $buildEnvironment
    }
    protected method temporaryTarballsDirectory {} {
        if { [info exists ::env(TEMP_TARBALLS_DIR)]} {
	    set temp_tarballs_dir $::env(TEMP_TARBALLS_DIR)
	} else {
	    set temp_tarballs_dir "/tmp/tarballs"
	}
        return $temp_tarballs_dir
    }
    protected method tarballPath {} {
        if { [$be cget -disableTempTarballPath] } {
          set temp_tarballs_dir ""
        } else {
          set temp_tarballs_dir [temporaryTarballsDirectory]
        }
        set rc $temp_tarballs_dir
	set rc [concat $rc [recursiveGlobDir $temp_tarballs_dir]]
	set rc [concat $rc [$be cget -tarballs]]
	set rc [concat $rc [recursiveGlobDir [$be cget -tarballs]]]
	set rc [concat $rc [recursiveGlobDir [$be cget -clientFilesDir]]]
        set rc [concat $rc [recursiveGlobDir [$be cget -compiledTarballs]]]
	set rc [concat $rc [$be cget -networkServiceBinDir]]
	set rc [concat $rc [recursiveGlobDir [$be cget -networkServiceBinDir]]]
	return $rc
    }
    protected method strip {args} {
        catch {eval logexecIgnoreErrors  strip $args}
    }
    public method findPatch {file} {
        return [findFile $file]
    }
    public method getTarballName {} {
        if { [info exists tarballName] && [string length [subst $tarballName]] } {
            return [subst $tarballName]
        } else {
            return ""
        }
    }
    public method getSourcesTarballName {} {
        return [getTarballName]
    }
    public method getS3SourcesTarballLocation {} {
        set componentSourcesTarballPath [$this findSourcesTarball]
        if {![string match *[$be cget -rootS3TarballPath]* $componentSourcesTarballPath] } {
            set componentSourcesTarballPath "[$be cget -rootS3TarballPath]$componentSourcesTarballPath"
        }
        return $componentSourcesTarballPath
    }
    public method findSourcesTarball {} {
        # Currently this is used for the release metadata, we set the buildType
        # to take the right tarball path for ruby apps (not the compiled tarball). We may
        # want to change this and also use this method when preparing the applicationTarball
        set currentBuildType [$be cget -buildType]
        $be configure -buildType fromSource
        set currentDistableTempTarballPath [$be cget -disableTempTarballPath]
        $be configure -disableTempTarballPath 1
        set sourceTarball [findTarball [getSourcesTarballName]]
        $be configure -buildType $currentBuildType
        $be configure -disableTempTarballPath $currentDistableTempTarballPath
        return $sourceTarball
    }
    public method findTarball {{tarball {}}} {
        set dirTarballPath [tarballPath]
        foreach extension {.tar.gz .tgz .tar.bz2 .tar.Z .tzr.gz .zip .gem .src.rock .msi .py .exe .egg .rpm .vmx.tar.gz {.7z} .tar.xz .whl ""} {
            foreach dir $dirTarballPath {
                if { [string match */CVS $dir] } {
                    continue
                }
                if { $tarball != "" } {
                    set list $tarball
                } elseif {[string length [getTarballName]]} {
                    set list [getTarballName]
                } else {
                    set list [list $name-$version ${name}_$version $name$version $name.$version $name-$version-py2.py3-none-any $name-$version-py2-none-any $name-$version-py3-none-any]
                }
                foreach n $list {
                    set f [pathJoin $dir $n$extension $be]
                    if {[tarballExists $f]} {
                        message info2 "Found tarball at $f"
                        return $f
                    }
                }
            }
        }
        message error [tarballNotFoundError $list]
        exit 1
    }
    public method tarballNotFoundError {{list {}}} {
        return "Not found tarball for $name $version - looking for $list. Check if there are two tarballs with the same name in S3."
    }
    public method tar {} {
        if {$::tcl_platform(os) == "SunOS"} {
            return /usr/local/bin/tar
        } else {
            return tar
        }
    }
    public method make {} {
        if {[supportsParallelBuild]} {
            if {[string match *fast* [info hostname]]} {
                return [list [findMake] --jobs=5]
            } elseif {[string match *osx-compilation-106-native* [info hostname]]} {
                return [list [findMake] --jobs=9]
            } elseif {[string match *osx-compilation-106-vm* [info hostname]]} {
                return [list [findMake] --jobs=5]
            } elseif {[info hostname] == "sun1k"} {
                return [list [findMake] --jobs=3]
            } elseif {$::tcl_platform(os) == "HP-UX"} {
                return [findMake]
            } elseif {$::tcl_platform(os) == "AIX"} {
                return [findMake]
            } elseif {$::tcl_platform(os) == "Linux"} {
                return [list [findMake] --jobs=[getLinuxJobsCount]]
            } elseif {[::xampptcl::util::isOSX1010Chroot]} {
                # New OS X machines have a VM with 8 cores and 2 chroots each one.
                # Here we split those 8 cores between both chroots.
                return [list [findMake] --jobs=5]
            } else {
                return [list [findMake] --jobs=5]
            }
        } else {
            return [findMake]
        }
    }
    public method findMake {} {
        if {$::tcl_platform(os) == "SunOS"} {
            return /usr/local/bin/make
        } elseif {$::tcl_platform(os) == "FreeBSD"} {
            return gmake
        } else {
            return make
        }
    }
    public method patch {} {
        if {$::tcl_platform(os) == "SunOS" && $::tcl_platform(osVersion) == "5.10"} {
            return patch
        } elseif { $::tcl_platform(os) == "AIX" } {
	    return /opt/freeware/bin/patch
	} else {
            return patch
        }
    }
    public method extractDirectory {} {
        return [$be cget -src]
    }
    public method getLicense {} {
        extract
        if {[getLicenseRelativePath] != ""} {
            if {[catch {set licenseList [detectLicense $be [srcdir] [getLicenseRelativePath]]} kk]} {
                       message error "$name [getLicenseRelativePath] - License: $kk - Notes: $licenseNotes"
            } elseif {$licenseList == ""} {
                       message warning "$name [getLicenseRelativePath] - License: unknown license - Notes: $licenseNotes"
            } else {
                       message info "$name [getLicenseRelativePath] - License: $licenseList - Notes: $licenseNotes"
            }
        } else {
            message info2 "$name License file <unknown> - Notes: $licenseNotes"
        }
    }
    public method extract {} {
        if { ![file exists [extractDirectory]] } {
            file mkdir [extractDirectory]
        }
        cd [extractDirectory]
        set f [findTarball]
        extractTarball $f
        applyPatches
    }
    public method extractTarball {f} {
        if { [info exists ::env(TEMP_TARBALLS_DIR)] && [file dirname $f]!="$::env(TEMP_TARBALLS_DIR)"} {
            file copy -force $f $::env(TEMP_TARBALLS_DIR)
        }
        # The catch is here to avoid problems with extracting tarballs that have been generated in a machine with its time set in the future
        if {[catch {
            if {[string match *bz2 $f]} {
                set bunzipDirectory /bin
                if {![file exists $bunzipDirectory/bunzip2]} {
                    set bunzipDirectory /usr/bin
                }
                if {$::tcl_platform(os) == "FreeBSD" || $::tcl_platform(os)=="Darwin" || [$::be targetPlatform] == "linux-x64" || $::tcl_platform(os) == "HP-UX"} {
                    catch {
                        logexec $bunzipDirectory/bunzip2 -c $f | [tar] xf -
                    }
                } else {
                    logexec $bunzipDirectory/bunzip2 -c $f | [tar] xf -
                }
            } elseif {[string match *gz $f]} {
                if {$::tcl_platform(os) == "FreeBSD" || $::tcl_platform(os) == "Darwin" || $::tcl_platform(os) == "HP-UX" || $::tcl_platform(os) == "AIX" || ( $::tcl_platform(os) == "SunOS" && $::tcl_platform(osVersion) == "5.10" )} {
                    # AGR, in FreeBSD it always catchs error. Lets assume that if doesnt uncompress ok it will not compile
                    logexecIgnoreErrors gunzip -c $f | [tar] xf -
                } elseif { [$::be targetPlatform] == "windows" && [string match *tgz $f] } {
                    #otherwise error with tar: Read 4096 bytes from -
                    regsub "^(.):/" [file normalize $f] "/\\1/" f
                    catch {logexec tar xzf $f} kk
                    puts $kk
                } elseif { [$::be targetPlatform] == "linux-x64" || [string match *tgz $f] } {
                    #otherwise error with tar: Read 4096 bytes from -
                    catch {logexec tar xzf $f} kk
                    puts $kk
                } else {
                    catch {logexec gunzip -c $f | [tar] xf -}
                }
            } elseif {[string match *Z $f]} {
                catch {
                    if {$::tcl_platform(os) == "HP-UX"} {
                        catch {logexec gunzip -c $f | [tar] xf -}
                    } else {
                        catch {logexec [tar] xfz $f}
                    }
                }
            } elseif {[string match *xz $f]} {
                if {![catch {logexec which xz}]} {
                    catch {logexec [tar] --use-compress-program xz -xf $f}
                } else {
                    catch {logexec [tar] xfJ $f}
                }
            } elseif {[string match {*7z} $f]} {
                logexec {7z} x $f
            } elseif {[string match {*sh} $f]} {
                file copy -force $f .
            } else {
                unzipFile $f
            } } err]} {
            if {$::errorCode != "NONE"} {
                message error $err
            } else {}
        }
    }
    public method applyPatches {} {
        foreach p [getPatchesToApply] {
            cd [patchWorkingDirectory]
            message info2 "Patching $p"
            if { $patchStrip == 1} {
                if {[$be cget -target] == "hpux"} {
                    # On HP-UX, --strip is not a valid option
                    logexec [patch] -p$patchLevel < [findPatch $p]
                }  else  {
                    logexec [patch] -p$patchLevel --strip 1 < [findPatch $p]
                }
            } else {
                logexec [patch] -p$patchLevel < [findPatch $p]
            }
            message info2 "Patching succeeded"
        }
    }
    public method getPatchesToApply {} {
	return $patchList
    }
    public method setEnvironment {} {
    }
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        callConfigure
        eval logexec [make]
    }
    public method showEnvironmentVars {} {
        file delete /tmp/setenv.sh
        ::xampptcl::file::write "/tmp/setenv.sh" {}
        foreach v [array names ::env] {
            puts "::env($v) = [set ::env($v)]"
            ::xampptcl::file::append /tmp/setenv.sh "export $v=\"[set ::env($v)]\"\n"
        }
    }
    public method callConfigure {} {
        eval [list logexec ./configure --prefix=[prefix]] [configureOptions]
    }
    public method install {} {
        cd [srcdir]
        eval logexec [make] install
    }
    public method preparefordist {} {
    }
    public method removeDocs {} {
	if {[$be cget -removeDocs] && $removeDocs} {
	    foreach f [recursiveGlobDir [prefix]] {
		foreach g [list manual man docs doc gtk-doc info] {
		    if [string match */${g} $f] {
			message info "Deleting ${f}"
			file delete -force $f
		    }
		}
	    }
	}
    }
    protected method configureOptions {} {
    }
    public method srcdir {} {
        return [file join [$be cget -src] $name$separator$version]
    }
    public method prefix {} {
        return [file join [$be cget -output] $name]
    }
    public method patchWorkingDirectory {} {
        return [srcdir]
    }
    protected method substituteOptions {text optionPairs} {
        set result {}
        foreach opt $text {
            foreach {old new} $optionPairs {
                if {[string match $old $opt]} {
                    set opt $new
                    break
                }
            }
            lappend result $opt
        }
        return $result
    }
    protected method getLinuxJobsCount {} {
	set count 2
	if {[catch {
        set fh [open /proc/cpuinfo r]
		set result [read $fh]
        close $fh
		set count [regexp -all {processor\s+:} $result]
	} kk]} {
	    puts "[clk] getLinuxJobsCount: Error: $kk"
	}
	puts "[clk] getLinuxJobsCount: count=$count"
	return $count
    }

    public method getS3StoragePath {path} {
        return [$be cget -rootS3TarballPath][file normalize [file join / $path]]
    }
    public method isTarballDownloaded {tarballPath} {
        # S3 lookup
        set tarballS3Path [getS3StoragePath $tarballPath]
        set numEncounters 0

        message info2 "Looking for tarball in $tarballS3Path"
        if {[catch {set numEncounters [exec s3cmd ls $tarballS3Path | wc -l]} kk]} {
            message fatalerror "Could not check if $tarballS3Path exists: $kk"
        }

        return [expr $numEncounters != 0]
    }

    public method download {} {
        if {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
            message info "Initial download parameters:"
	    message info2 "downloadType '$downloadType'"
	    message info2 "downloadUrl '$downloadUrl'"
	    message info2 "downloadTarballName '$downloadTarballName'"
	    if {[info exists downloadSearchString]} {
                message info2 "downloadSearchString '$downloadSearchString'"
            }
	    message info2 "tarballName '$tarballName'"
	    message info2 "folderAtThirdparty '$folderAtThirdparty'"
	    message info2 "name '$name'"
	}
        if {$folderAtThirdparty == ""} {
            if {[$this isa npmPackage]} {
                set folderAtThirdparty [$be cget -tarballs]/nodejs
            } elseif { $isTrial } {
                set folderAtThirdparty [$be cget -clientFilesDir]/client-$name
            } else {
                set folderAtThirdparty [$be cget -tarballs]/$name
            }
        }
        if { $downloadType != "" } {
            if { $tarballName == "" } {
                set tarballName $name-$version
            }
            if { $downloadTarballName == "" && $downloadType == "wget" } {
                set downloadTarballName [lindex [split $downloadUrl /] end]
            } elseif { $downloadTarballName == "" } {
                set downloadTarballName $tarballName.tar.gz
            }
            set tarballPath [file join $folderAtThirdparty $downloadTarballName]
            if {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                message info "Final download parameters:"
                message info2 "downloadType '$downloadType'"
                message info2 "downloadUrl '$downloadUrl'"
                message info2 "downloadTarballName '$downloadTarballName'"
                if {[info exists downloadSearchString]} {
                    message info2 "downloadSearchString '$downloadSearchString'"
                }
                message info2 "tarballName '$tarballName'"
                message info2 "folderAtThirdparty '$folderAtThirdparty'"
                message info2 "name '$name'"
            }
            if {[isTarballDownloaded $tarballPath]} {
                message info2 "Skipping download for $name - file [getS3StoragePath $tarballPath] already exists"
            } else {
                file delete -force /home/bitnami/.composer/cache
                file delete -force /home/bitnami/.npm/*
                getTarball
                prepareTarball
                uploadTarball
                message info2 "Successfully downloaded file for $name: [getS3StoragePath $tarballPath]"
                file delete -force [$be cget -tmpDir]/$downloadTarballName
            }
        } else {
            message info2 "Skipping download for $name - downloadType not defined"
        }
    }
    public method getTarball {} {
        file delete -force [$be cget -tmpDir]/$downloadTarballName
        set thirdpartyPath [$be cget -thirdpartyPath]
        set checkCertificateFlag ""
        if { $noCheckCertificate } {
            set checkCertificateFlag "--no-check-certificate"
        }
        if { $downloadType == "wget" } {
            if { $downloadUrl != "" } {
                message info "Download for $name started..."
                set extraOptions ""
                if {![string match *sourceforge.net* $downloadUrl]} {
                    set extraOptions "-U Mozilla/55.0"
                }
                if {[catch {eval logexec wget -p $extraOptions $checkCertificateFlag $downloadUrl -O [$be cget -tmpDir]/$downloadTarballName 2>/dev/null >/dev/null} err]} {
                    message error "$::errorCode \n $err"
                    exit 1
                } else {
                    message info "File from $downloadUrl downloaded correctly"
                }
            } else {
                message error "Download selected method is 'wget' but you downloadUrl has not been specified"
                exit 1
            }
        } elseif { $downloadType == "gitrepository" } {
            message info "Cloning for $name at $downloadUrl started..."
            if { $downloadUrl != "" } {
                cd [$be cget -tmpDir]
                set repositoryFolderName [lindex [split $downloadUrl /] end]
                if {[string match *.git $repositoryFolderName]} {
                    # Remove .git (e.g. used in GitLab repositories)
                    set repositoryFolderName [file rootname $repositoryFolderName]
                }
                if { $tarballName != "" } {
                    file delete -force [$be cget -tmpDir]/$tarballName
                }
                if { $repositoryFolderName != "" } {
                    file delete -force [$be cget -tmpDir]/$repositoryFolderName
                }
                set gitBranchOption {}
                if { $repositoryCheckout != "" } {
                    if { $splitRepositoryCheckout == 1} {
                        set gitBranchOption "-b [lindex [split $repositoryCheckout /] end]"
                    } else {
                        set gitBranchOption "-b $repositoryCheckout"
                    }
                }
                if {[catch {eval logexec git clone ${downloadUrl} --recursive --depth $downloadDepth $gitBranchOption} err]} {
                    message error "$::errorCode \n $err"
                    exit 1
                } else {
                    message info "Repository for $name from $downloadUrl cloned correctly"
                }
                cd [$be cget -tmpDir]/$repositoryFolderName
                #T3558 Cloning directly from a specific tag makes the user unable to checkout to master
                if {[catch {eval logexec git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"} err]} {
                    message error "$::errorCode \n $err"
                } else {
                    message info "Remotes fetch enabled"
                }
                if {[catch {eval logexec git fetch --tags} err]} {
                    message error "$::errorCode \n $err"
                    } else {
                        message info "Tags fetched correctly"
                    }
            } else {
                message error "Download selected method is 'gitrepository' but the 'downloadUrl' has not been specified"
                exit 1
            }
        } elseif { $downloadType == "wgetWithoutUrl" } {
            if { $downloadUrl != "" } {
                message info "Getting the page to get the link for $name..."
                if { $downloadSearchStringPattern == "" } {
                    # Avoid <> characters not to match more than one url
                    set downloadSearchStringPattern "(http\[^<>\]*?${downloadTarballName})"
                }
                file delete -force [$be cget -tmpDir]/$name.html
                if {[catch {eval logexec wget -nc $checkCertificateFlag $downloadUrl -O [$be cget -tmpDir]/$name.html 2>/dev/null >/dev/null} err]} {
                    message error "$::errorCode \n $err"
                    exit 1
                } else {
                    set downloadApplicationPageContent [xampptcl::file::read [$be cget -tmpDir]/$name.html]
                    if {[regexp -line $downloadSearchStringPattern $downloadApplicationPageContent - realUrl]} {
                        message info "Got real page: $realUrl"
                        if {![string match http* $realUrl]} {
                            regexp -line "(http.*//\[^/\]*)/.*" $downloadUrl - prefixRealUrl
                            set realUrl "${prefixRealUrl}${realUrl}"
                            message info "Added prefix to page: $realUrl"
                        }
                        if {[catch {eval logexec wget -nc $checkCertificateFlag $realUrl -O [$be cget -tmpDir]/$downloadTarballName 2>/dev/null >/dev/null} err]} {
                            message error "$::errorCode \n $err"
                            exit 1
                        } else {
                            message info "File from $realUrl downloaded correctly"
                        }
                    } else {
                        message error "String pattern $downloadSearchStringPattern not found in $downloadUrl"
                        exit 1
                    }
                }
            } else {
                message error "Download selected method is 'wgetWithoutUrl' but you downloadUrl has not been specified"
                exit 1
            }
        } elseif { $downloadType == "gem" } {
                message info "$name is a gem with gem name: $name-$version.gem"
        } elseif { $downloadType == "pear" } {
            set channelUrl $repositoryCheckout
            if {[catch {eval exec pear} err]} {
                message error "pear is required to generate tarballs for $name"
                exit 1
            } else {
                if {[catch {eval exec pear channel-discover ${channelUrl}} err]} {
                    message error "$::errorCode \n $err"
                    exit 1
                } else {
                    catch {exec pear channel-info ${channelUrl}} getChannelAlias
                    regexp -line "^Alias\\s*(.*)\$" $getChannelAlias - channelAlias
                    message info "Channel $channelAlias added successfully"
                }
		set pearInstall "pear install --force $downloadUrl"
                message info "Running $pearInstall..."
                catch {eval exec ${pearInstall}} err
                catch {exec pear list -c "$channelAlias"} listOfInstalledChannelPackages
                foreach package [split [string trim $listOfInstalledChannelPackages] \n] {
                    if {[string match *\d** $package]} {
                        regexp -- "^(\\w*)\\s*.*" $package - packageName
                        catch {exec pear uninstall -n $channelAlias/${packageName}} output
                    }
                }
                catch {eval exec pear channel-delete ${channelUrl}} err
                message info "pear execution finished successfully"
            }
        } elseif { $downloadType == "pip" } {
            if {[catch {eval exec pip} err]} {
                message fatalerror "pip is required to download tarballs for $name"
            }
            if {[catch {logexec pip download $name==$version --no-binary :all: --no-deps --dest [$be cget -tmpDir] --disable-pip-version-check} err]} {
                message fatalerror "Could not download $name==$version!"
            }
        } elseif { $downloadType == "custom" } {
            # This option disable the getTarball method
        }
    }
    public method prepareTarball {} {
        if { $downloadType == "gitrepository" } {
            message info "Preparing the tarball from the cloned repository..."
            if { $tarballName == "" } {
                set tarballName "$name-$version"
            }
            if { $downloadUrl != "" } {
                set repositoryFolderName [lindex [split $downloadUrl /] end]
                if {[string match *.git $repositoryFolderName]} {
                    # Remove .git (e.g. used in GitLab repositories)
                    set repositoryFolderName [file rootname $repositoryFolderName]
                }
                cd [$be cget -tmpDir]/$repositoryFolderName
                if {[catch {eval logexec git checkout -q ${repositoryCheckout}} err]} {
                    message error "$::errorCode \n $err"
                    exit 1
                } else {
                    if {[file exists [$be cget -tmpDir]/$repositoryFolderName/.gitmodules]} {
                        if {[catch {eval logexec git submodule update --init --recursive} err]} {
                            message error "$::errorCode \n $err"
                            exit 1
                        }
                        message info "Replacing path in the .git submodules logic with @@XAMPP_INSTALLDIR@@"
                        foreach f [::xampptcl::util::recursiveGlob [file join [$be cget -tmpDir] $repositoryFolderName] *.git*] {
                            if {[file isfile $f] && ![string match *.pack $f] && [string match "*[file join [$be cget -tmpDir] $repositoryFolderName]*" [xampptcl::file::read $f]]} {
                                puts "Replacing path in $f"
                                xampptcl::util::substituteParametersInFile $f \
                                    [list [file join [file join [$be cget -tmpDir] $repositoryFolderName]] @@XAMPP_INSTALLDIR@@]
                            }
                        }
                    }
                    cd [$be cget -tmpDir]
                    if {[catch {eval logexec tar cfz $tarballName.tar.gz ${repositoryFolderName}} err]} {
                        message error "$::errorCode \n $err"
                        exit 1
#                    } else {
#		        file delete -force [$be cget -tmpDir]/$repositoryFolderName
                    }
                    if { $downloadTarballName == "" } {
                        set downloadTarballName $tarballName
                    }
                    message info "File $downloadTarballName successfully prepared to be uploaded"
                }
            } else {
                message error "Download selected method is 'gitrepository' but the 'downloadUrl' has not the path to the project"
                exit 1
            }
        } elseif { $downloadType == "npm" } {
            message info "Preparing the tarball from the execution of npm..."
            if { $downloadTarballName == "" } {
                set downloadTarballName "${name}-cache-${version}.tar.gz"
            }
            cd [$be cget -tmpDir]
            if {[catch {eval logexec tar cfz $downloadTarballName ${name}-cache-${version}} err]} {
                message error "$::errorCode \n $err"
                exit 1
            } else {
	        file delete -force [$be cget -tmpDir]/${name}-cache-${version}
            }
            message info "File $downloadTarballName successfully prepared to be uploaded"
        } elseif { $downloadType == "pear" } {
            message info "Preparing the tarball from the execution of pear..."
            if { $downloadTarballName == "" } {
                set downloadTarballName "${name}-${version}.zip"
            }
            cd [$be cget -tmpDir]
            file rename -force /tmp/pear/download [$be cget -tmpDir]/${name}-${version}
            catch {eval exec yes | pear uninstall ${downloadUrl}} err
            file delete -force /tmp/pear
            if {[catch {eval logexec zip -r $downloadTarballName ${name}-${version}} err]} {
                message error "$::errorCode \n $err"
                exit 1
            } else {
	        file delete -force [$be cget -tmpDir]/${name}-${version}
            }
            message info "File $downloadTarballName successfully prepared to be uploaded"
	}
    }
    public method uploadTarball {} {
        set thirdpartyPath [$be cget -thirdpartyPath]
        set thirdpartyS3Path [$be cget -thirdpartyS3Path]
        if {[file exists $folderAtThirdparty/$downloadTarballName]} {
            message info "File exists!"
            set md5NewFile [lindex [split [exec md5sum [$be cget -tmpDir]/$downloadTarballName] " "] 0]
            set md5OldFile [lindex [split [exec md5sum $folderAtThirdparty/$downloadTarballName] " "] 0]
            if { $md5OldFile == $md5NewFile } {
                message info "And it is the same!"
                message info "File will not be uploaded"
            } else {
                message error "It will be overwritten right now!"
                uploadTarballToS3 [$be cget -tmpDir]/$downloadTarballName $thirdpartyS3Path/[file tail $folderAtThirdparty]/
            }
        } else {
            uploadTarballToS3 [$be cget -tmpDir]/$downloadTarballName $thirdpartyS3Path/[file tail $folderAtThirdparty]/
            message info "Wait a few minutes while /opt/thirdparty synchronizes with s3 bucket"
        }
    }

    public method uploadTarballToS3 {local remote} {
        uploadFileToS3 $local $remote
    }

    public method getVtrackerField {name field file} {
        set vtrackerParser [vtrackerParser ::\#auto]
        $vtrackerParser loadFile [file join [$be cget -projectDir] tools vtracker $file]
        set fieldValue [$vtrackerParser getKey $name $field]
        return $fieldValue
    }

     public method getAppKeyFromVtracker {field} {
        set vtrackerParser [$be cget -vtrackerParser]
        if { $vtrackerName == "" } {
            set vtrackerName $name
        }
        set v [$vtrackerParser getKey $vtrackerName $field]
        # trim quotes if used
        set v [string trim $v "\""]
        if {$v == ""} {
            message error "$field not found in the vtracker of $name"
            exit 1
        } else {
            return $v
        }
    }

    public proc getNameListAppKeyFromVersionMap {namelist field {default {}}} {
        if {[info exists ::env(BITNAMI_VERSION_MAP)]} {
            if {![info exists versionMapCache]} {
                set fh [open $::env(BITNAMI_VERSION_MAP) r]
                fconfigure $fh -encoding utf-8
                set versionMapCache [read $fh]
                close $fh
            }
            array set m $versionMapCache
            foreach n $namelist {
                if {[info exists m($n)]} {
                    array set mi $m($n)
                    return $mi($field)
                }
            }
        }
        return $default
    }

    public method getAppKeyFromVersionMap {field {default {}}} {
        set namelist {}
        foreach n [concat [list [namespace tail [info class]]] $bitnamiPortalNames] {
            lappend namelist $n ${n}stack
            if {[regexp {^(.*?)(SecondDev|Dev|Leg)} $n - base suffix]} {
                lappend namelist ${base}stack${suffix}
            }
        }
        return [getNameListAppKeyFromVersionMap $namelist $field $default]
    }
    public method getVersionFromVersionMap {{default {}}} {
        return [getAppKeyFromVersionMap name $default]
    }
    public method getRevisionFromVersionMap {{default {}}} {
        return [getAppKeyFromVersionMap revision $default]
    }
    public proc getNameListVersionFromVersionMap {namelist {default {}}} {
        return [getNameListAppKeyFromVersionMap $namelist name $default]
    }
    public proc getNameListRevisionFromVersionMap {namelist {default {}}} {
        return [getNameListAppKeyFromVersionMap $namelist revision $default]
    }

    public method getVersionFromVtracker {} {
        if {[getVersionFromVersionMap] != {}} {
            return [getVersionFromVersionMap]
        }  elseif {[info exists ::env(BITNAMI_NEW_VERSION)] && [xampptcl::util::isBooleanYes $::env(BITNAMI_NEW_VERSION)]} {
            set field "version"
        }  else  {
            set field "dlversion"
        }
        return [getAppKeyFromVtracker $field]
    }
    public method getRevisionFromVtracker {} {
        if {[getRevisionFromVersionMap] != {}} {
            return [getRevisionFromVersionMap]
        }  elseif {[info exists ::env(BITNAMI_NEW_VERSION)] && [xampptcl::util::isBooleanYes $::env(BITNAMI_NEW_VERSION)]} {
            return 0
        }
        return [getAppKeyFromVtracker "rev"]
    }
    public method getBuildFromVtracker {} {
        if {[info exists ::env(BITNAMI_NEW_VERSION)] && [xampptcl::util::isBooleanYes $::env(BITNAMI_NEW_VERSION)]} {
            set field "version"
        }  else  {
            set field "dlversion"
        }
        return [getAppKeyFromVtracker $field]
    }
    public method getFullName {} {
        if { $fullname != "" } {
                puts $fullname
        } else {
                puts $name
        }
    }
    # List of vendor paths (can be more than one, i.e. some applications have multiple locations)
    public method getRubyVendorPaths {} {
        set l {}
        set dir [prefix]
        if [$this isa bitnamiProgram] {
            set dir [file join [$this applicationOutputDir] htdocs]
        }
        if {[file exists [file join $dir vendor]]} {
            set l [file join $dir vendor]
        }
        return $l
    }
    # Returns full dictionary list of dependencies (e.g. node modules and gems)
    # Each element should have the following structure: {key metadataId somekey someval ...}
    public method getPlatformDependencyList {} {
        set l {}
        return $l
    }
    # These paths will not be included in the platform dependency list (bundled components)
    # However, it will allow skipping certain directories in the undeclared dependency validation
    public method getPlatformDependencyPathsToSkip {} {
    }
}

::itcl::class chrpath {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set name chrpath
        set version 0.13
    }
    public method prefix {} {
        return [srcdir]
    }
    public method setEnvironment {} {
        set ::env(PATH) $::env(PATH):[prefix]/bin
    }
}

::itcl::class library {
    inherit program
    constructor {environment} {
        chain $environment
    } {
        set mainComponentXMLName common
    }
    public method prefix {} {
        return [file join [$be cget -output] [$be cget -libprefix]]
    }
}

::itcl::class builddependency {
    inherit library
    constructor {environment} {
        chain $environment
    } {
	set licenseRelativePath {}
    }
    public method prefix {} {
        return [file join [$be cget -builddep] $name-$version]
    }
    public method copyLicense {} {}
    public method setEnvironment {} {
        set ::env(PATH) [prefix]/bin:$::env(PATH)
    }

}

::itcl::class bitnamiProgram {
    inherit program
    public variable dependencies {}
    public variable scriptFiles {}
    public variable tags {}
    public variable properties
    public variable project_web_page {}
    public variable createHtaccessFile 0
    public variable overwriteHtaccessFile 1
    public variable installAsUser {}
    public variable baseStackinstallDir {}
    public variable applicationTarballName {}
    public variable sourceApplicationDir {}

    public variable supportsFtp 0
    public variable supportsSmtp 0
    public variable supportsVhost 0
    public variable supportsVhostOnly 0; # Force BCH to use virtual host (used for apps in root)
    public variable supportsSeveralInstances 0
    public variable supportsIpChange 0
    public variable supportsAppurl 0
    public variable tarballNameListForDownload {}
    public variable tarballListForDownload {}

    # Application url prefix, if it doesn't default to /<key>
    public variable urlPrefix {}
    # Path to access to administrator relative to the application path. For example: "/admin"
    public variable adminUrl {}

    protected variable virtualEnvInfo

    protected method bnconfigId {} {
        return $name
    }
    constructor {environment} {
        chain $environment
        array set properties {}
        array set virtualEnvInfo {}
        if {[info exists name]} {
            set readmePlaceholder [string toupper $name]
            set fullname [string totitle $name]
            set dependencies "$name {$name.xml}"
        }
    } {
        # We have to revisit all this info exists stuff...
        if {$sourceApplicationDir == "" && [info exists name]} {
            set sourceApplicationDir $name
        }
    }
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] apps $name]
    }
    public method changeLogDirectory {} {
        return [file join [$be cget -projectDir] apps $name]
    }
    public method build {} {}
    public method install {} {
        file mkdir [applicationOutputDir]/conf
        file mkdir [applicationOutputDir]/conf/certs
    }
    public method applicationOutputDir {} {
        return [file join [$be cget -output] $name]
    }
    public method getProgramFiles {} {
        return [list conf scripts]
    }
    public method getTextFiles {} {
        return [list README.txt changelog.txt]
    }
    public method getChangeLogFile {} {
        return [file join [changeLogDirectory] changelog.txt]
    }

    public method getInstallerProjectXMLFiles {stack} {
        set list {}
        foreach {componentList fileList} [subst $dependencies] {
            if {[$stack hasComponents $componentList]} {
                set list [concat $list $fileList]
            }
        }
        if {[llength $list] > 0} {
            puts "Dependencies: $list"
        }
        return $list
    }
    protected method programFilesDestDir {} {
        return [applicationOutputDir]
    }
    public method copyProgramFiles {} {
        file mkdir [programFilesDestDir]
        foreach f [getProgramFiles] {
            set dest [file join [programFilesDestDir] [file tail $f]]
            if {[file exists $dest] && [file isdirectory $dest]} {
                foreach g [glob [file join [xmlDirectory] $f *]] {
                    file copy -force $g $dest
                }
            } else {
                file copy -force [file join [xmlDirectory] $f] $dest
            }
        }
    }
    public method copyProjectFiles {stack} {
        file mkdir [applicationOutputDir]
        copyProgramFiles
        foreach f [getTextFiles] {
            file copy -force  [file join [xmlDirectory] $f] [$be cget -output]
        }
        if {[string length [getLicenseRelativePath]] && [file exists [srcdir]] } {
            file mkdir [applicationOutputDir]/licenses
            file copy -force [srcdir]/[getLicenseRelativePath] [applicationOutputDir]/licenses/
        }
        chain $stack
    }
    public method copyScripts {} {}
    public method getScriptFiles {} {
        set list {}
        foreach {scriptList platformList} $scriptFiles {
            foreach platform $platformList {
                if {[string match *$platform* [$be cget -target]]} {
                    set list [concat $list $scriptList]
                }
            }
        }
        return $list
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
    public method htaccessTextContainsPhpSettings {data} {
        return [regexp -- {^.*\s*php_(value|flag|admin_value|admin_flag)\s+[^\s]+\s+[^\s]+} $data]
    }

    public method phpSettingSet {userIni phpFpmSettingsFile data} {
        if {$data != ""} {
            if {[htaccessTextContainsPhpSettings $data]} {
                while {[regexp -- {^(|.*?\n)(\s*(php_(value|flag|admin_value|admin_flag))\s+([^\s]+)\s+([^\s]+)).*} $data - - inner flagType - k v]} {
                    set data [string map [list $inner {}] $data]
                    if {$flagType == "php_admin_flag" || $flagType == "php_flag"} {
                        if {[xampptcl::util::isBooleanYes $v]} {
                            set v "on"
                        } else {
                            set v "off"
                        }
                    }
                    # Disabled for now, we handle it in php-fpm
                    #phpUserIniFileSet $userIni $k $v
                    phpFpmPhpSettingsFileSet $phpFpmSettingsFile $flagType $k $v
                }

            }
        }
    }
    public method phpFpmPhpSettingsFileSet {f flagType key value} {
        set k "$flagType\[$key\]"
        file mkdir [file dirname $f]
        propertiesFileSet $f $k $value
    }

    public method phpUserIniFileSet {f key value} {
        file mkdir [file dirname $f]
        propertiesFileSet $f $key $value
    }
    protected method sortElemByPathDephInt {e1 e2} {
        set l1 [llength [file split [file normalize $e1]]]
        set l2 [llength [file split [file normalize $e2]]]
        if {$l1 == $l2} {
            return 0
        } elseif {$l1 > $l2} {
            return 1
        } else {
            return -1
        }
    }
    protected method sortByPathDeph {list {reverse 0}} {
        if {$reverse} {
            return [lsort -command sortElemByPathDephInt -decreasing $list]
        } else {
            return [lsort -command sortElemByPathDephInt $list]
        }
    }
    public method createHtaccessFile {} {
        message info "Creating htaccess.conf file: [applicationOutputDir]"
        set phpUserIniFiles {}
        set apachePhpSettingsNormalizer [::apachePhpSettingsNormalizer ::\#auto]
        foreach i [::xampptcl::util::recursiveGlob [applicationOutputDir] */.htaccess] {
            if ![file exist [applicationOutputDir]/conf/htaccess.conf] {
                file mkdir [applicationOutputDir]/conf
                xampptcl::file::write [applicationOutputDir]/conf/htaccess.conf {}
            }
            set htaccessFileContent [xampptcl::file::read $i]
            set htaccessConfFileContent [xampptcl::file::read [applicationOutputDir]/conf/htaccess.conf]
            set userIniFile [file join [file dirname $i] .user.ini]
            set phpFpmSettingsFile  [applicationOutputDir]/conf/php-fpm/php-settings.conf
            phpSettingSet $userIniFile $phpFpmSettingsFile $htaccessFileContent
            if {[file exists $userIniFile]} {
                file attributes $userIniFile -permissions 0440
                lappend phpUserIniFiles $userIniFile
            }
            if {![string match "*This configuration has been moved to the application config file for performance and security reasons*" $htaccessFileContent]} {
                    puts "$i"
                set htaccessFilePath [file dirname [string map [list [file normalize [applicationOutputDir]]/ {}] [file normalize $i]]]
                if { $htaccessFilePath == "." } {
                    set htaccessFilePath ""
                }
                set htaccessFileContent "<Directory \"@@XAMPP_APPLICATION_INSTALLDIR@@/$htaccessFilePath\">
$htaccessFileContent
</Directory>
"
                if {![string match "*$htaccessFileContent*" $htaccessConfFileContent]} {
                    xampptcl::file::append [applicationOutputDir]/conf/htaccess.conf $htaccessFileContent
                }
                if $overwriteHtaccessFile {
                    xampptcl::file::write $i {# This configuration has been moved to the application config file for performance and security reasons
}
# You can find more info at https://docs.bitnami.com/general/apps/wordpress/administration/use-htaccess/ }
                    file attributes $i -permissions 0640
                }

            }
            if {[file exists [applicationOutputDir]/conf/htaccess.conf]} {
                $apachePhpSettingsNormalizer cleanText [applicationOutputDir]/conf/htaccess.conf
            }
            # This is related to the .user.ini files, disabled for now
            set c {
                array set dataArray {}
                foreach f [sortByPathDeph $phpUserIniFiles 1] {
                    set dataArray([file dirname $f]) [parsePropertiesFile $f]
                }

                foreach f [sortByPathDeph $phpUserIniFiles] {

                    set path $f
                    while {[set dirname [file dirname $path]] != "/"} {
                        set path $dirname
                        if {[info exists dataArray($dirname)]} {
                            lappend tmpPaths $dirname
                        }
                    }
                    unset -nocomplain tmpArray
                    array set tmpArray {}

                    foreach d [sortByPathDeph $tmpPaths] {
                        array set tmpArray [parsePropertiesFile $d/.user.ini]
                    }
                    foreach {k v} [array get tmpArray] {
                        propertiesFileSet $f $k $v
                    }
                }
            }
    }
    public method requirementList {} {}

    public method download {} {
        if {[llength $tarballNameListForDownload] > 0} {
            set tarballNameOriginal $tarballName
            set downloadUrlBase $downloadUrl
            foreach item $tarballNameListForDownload {
                if {$downloadType == "gitrepository"} {
                    set tarballName $item-$version
                } else {
                    set tarballName $item
                }
                set downloadUrl $downloadUrlBase/$item
                chain
                set downloadTarballName "" ;#to use default value every time
            }
            set tarballName $tarballNameOriginal
        } elseif {[llength $tarballListForDownload] > 0} {
            foreach {url item} $tarballListForDownload {
                set downloadUrl $url
                set downloadTarballName $item
                chain
            }
            set downloadTarballName ""
        } else {
            chain
        }
    }
    public method getApplicationTarballName {} {
        return $applicationTarballName
    }
    public method usingApplicationTarball {} {
        return [expr {
            [$be cget -buildApplicationType] != "fromApplicationModifiedSource" &&
            [getApplicationTarballName] != "" &&
            [getApplicationTarballName] == [getTarballName]
        }]
    }
    public method getDirectoryToScan {} {
        return [file join $baseStackinstallDir apps $name htdocs]
    }
    public method activateVirtualenv {venv} {
        set virtualEnvInfo($venv) ""
        foreach var [list PATH PYTHONHOME PYTHON PYTHON_ROOT] {
            if {[info exists ::env($var)]} {
                lappend virtualEnvInfo($venv) $var $::env($var)
            }
        }
        set ::env(VIRTUALENV) "$venv"
        set ::env(PATH) "$venv/bin:$::env(PATH)"
        unset -nocomplain ::env(PYTHON)
        unset -nocomplain ::env(PYTHONHOME)
        unset -nocomplain ::env(PYTHON_ROOT)
    }

    public method deactivateVirtualenv {venv} {
        if {![info exists virtualEnvInfo($venv)]} {
            error "You tried to deactivate a virtual env ($venv) that was not previously activated"
        }
        unset -nocomplain ::env(VIRTUALENV)
        foreach {var value} $virtualEnvInfo($venv) {
            set ::env($var) $value
        }
    }
}

::itcl::class baseBitnamiProgram {
    inherit bitnamiProgram
    constructor {environment} {
        chain $environment
    } {
    }
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base [string tolower $name]]
    }
    public method copyStackLogoImage {} {}
    public method build {} {
        cd [srcdir]
        showEnvironmentVars
        callConfigure
        eval logexec [make]
    }
    public method install {} {
        cd [srcdir]
        eval logexec [make] install
    }
    public method getProgramFiles {} {
        return {}
    }
    public method getTextFiles {} {}
    public method getInstallerProjectImageFiles {} {
        return {}
    }
    public method applicationOutputDir {} {
        return [file join [$be cget -output] $name]
    }
    public method copyScripts {} {
        foreach f [getScriptFiles] {
            file mkdir [file join [applicationOutputDir] scripts]
            file copy -force [file join [xmlDirectory] $f] [file join [applicationOutputDir] scripts]
        }
    }
    public method copyXmlFiles {stack} {
        foreach f [getInstallerProjectXMLFiles $stack] {
            file copy -force [file join [xmlDirectory] $f] [$be cget -output]
        }
    }
    public method copyProjectFiles {stack} {
        copyXmlFiles $stack
        copyProgramFiles
        copyScripts
    }
}


::itcl::class baseFiles {
    inherit bitnamiProgram
    markAsInternal
    constructor {environment} {
        chain $environment
    } {
        set name "bitnami"
        set fullname "Bitnami"
        set version 1.0
        set licenseRelativePath {}
    }
    public method findTarball {{tarball {}}} {}
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base bitnami]
    }
    public method needsToBeBuilt {} {
        return 0
    }
    public method install {} {
    }
    public method applicationOutputDir {} {
        return [$be cget -output]
    }
    public method getProgramFiles {} {}
    public method getTextFiles {} {}
    public method getImagesDirectory {} {
        return [file join [$be cget -projectDir] base [getNameForPlatform] images]
    }

    public method getInstallerProjectImageFiles {} {
        return [glob -nocomplain [file join [getImagesDirectory] *.png]]
    }
    public method copyProjectFiles {stack} {
        chain $stack
        foreach f [getScriptFiles] {
            file copy [file join [$be cget -projectDir] base $name $f] [$be cget -output]
        }
        file mkdir [$be cget -output]/img
        file copy -force [$be cget -projectDir]/base/bitnami/images/bitnami.ico [$be cget -output]/img/
    }
    public method copyStackLogoImage {} {}
}

::itcl::class bitnamiFiles {
    inherit baseFiles
    markAsInternal
    constructor {environment} {
        chain $environment
    } {
        set dependencies {httpd {base-apache-settings.xml} mysql {base-mysql-settings.xml} \
                              tomcat {base-tomcat-settings.xml} \
                              bitnamiFiles {base-write-properties.xml \
                              base-functions.xml base-parameter-adminaccount.xml base-parameter-dir.xml \
                              bitnami-functions.xml bitnami-settings.xml common.xml ctlscript.sh \
                              serviceinstall.bat servicerun.bat base-logrotate.xml base-monit.xml}}
        set moduleDependencies {}
    }
}

::itcl::class manager {
    inherit program
    public variable control
    markAsInternal
    constructor {environment} {
        chain $environment
    } {
        set name manager
        set uniqueIdentifier bitnami-manager
        set version "1"
        set licenseRelativePath {}
    }

    public method initialize {be} {
        chain $be
        set control [getControlBinary]
    }
    public method getControlBinary {} {
        switch -- [$be targetPlatform] {
            windows-x64 {
                set control manager-windows-x64.exe
            }
            linux {
                set control manager-linux-xampp.run
            }
            linux-x64 {
                set control manager-linux-x64-xampp.run
            }
            osx-x86 - osx-x64 {
                set control manager-osx-xampp.app.zip
            }
        }
        return $control
    }
    public method findTarball {{tarball {}}} {}
    public method needsToBeBuilt {} {
        return 0
    }
    public method extract {} {}
    public method build {} {}
    public method copyProjectFiles {stack} {
        chain $stack
        file copy -force [$be cget -projectDir]/tools/manager/manager-core.xml [file join [$be cget -output] manager.xml]
    }
    public method install {} {
        file delete -force [$be cget -output]/$control
        if {[string match osx* [$be cget -target]]} {
            unzipFile [$be cget -projectDir]/tools/manager/$control.zip [$be cget -output]
        } else {
            file copy -force [$be cget -projectDir]/tools/manager/$control [$be cget -output]
            # Keep using the current name for the manager on windows
            if {[string match windows-x64 [$be cget -target]]} {
                file rename -force [file join [$be cget -output] $control] [file join [$be cget -output] manager-windows.exe]
            }
        }
    }
}

::itcl::class bitnamiBanner {
    inherit bitnamiProgram
    public variable padding 0
    markAsInternal
    constructor {environment} {
        chain $environment
    } {
        set name bitnami-banner
        set version "1"
	set licenseRelativePath {}
        set dependencies {bitnamiBanner {bitnami-banner.xml}}
        set isReportableComponent 0
    }
    public method copyProjectFiles {stack} {
        copyXmlFiles $stack
        file delete -force [$be cget -output]/banner
        file mkdir [$be cget -output]/banner
        file copy -force [file join [xmlDirectory] htdocs] [$be cget -output]/banner
        set bannerHtdocs [file join [$be cget -output] banner htdocs]
        file mkdir $bannerHtdocs
        [$be cget -product] createDocumentation $bannerHtdocs "installer"
        set apacheRes {}
        set bannerText [::xampptcl::file::read [file join [xmlDirectory] banner.html]]
        if {$padding != "" && $padding > 0} {
            set bannerText [format {<div style="height:%spx"/>} $padding]$bannerText
        }
        foreach l [split $bannerText \n] {
            if {[string trim $l] == ""} {
                continue
            }
            append apacheRes [string map [list ' \\'] [string trimright $l]] " \\" \n
        }
        set apacheText [format {
<IfDefine !DISABLE_BANNER>
            <If "!-f '@@BITNAMI_BANNER_DISABLE_FILE@@' && %%{HTTP_COOKIE} !~ /_bitnami_closed_banner_(global|@@BITNAMI_BANNER_ID@@)=/">
       Substitute 's|</body>| \
    %s \
</body>|i'
   </If>
</IfDefine>
        } $apacheRes]
        file mkdir [$be cget -output]/banner/conf/
        xampptcl::file::write [$be cget -output]/banner/conf/banner-substitutions.conf $apacheText
    }

    public method findTarball {{tarball {}}} {}
    public method extract {} {
        file mkdir [srcdir]
    }
        public method install {} {
            file mkdir [srcdir]
#            chain
        }
    public method build {} {
    }
    public method xmlDirectory {} {
        return [file join [$be cget -projectDir] base bitnami-banner]
    }
}

::itcl::class nativeadapter {
    inherit bitnamiProgram
    constructor {environment} {
        set name nativeadapter
        chain $environment
    } {
        set fullname "Native Adapter"
        set version [getVersionFromVersionMap 1.4]
        set rev [getRevisionFromVersionMap 48]
        set tarballName {}
	set licenseRelativePath {}
        lappend tags MySQL Apache PHP RedHat
        set project_web_page {}
        set dependencies {mysql {mysql-properties.xml mysql-functions.xml}}
	set moduleDependencies {nativeadapter {environment-autodetection-functions.xml native-apache-adapter.xml native-mysql-adapter.xml common-native-adapter.xml apache-autodetection-functions.xml mysql-autodetection-functions.xml php-autodetection-functions.xml}}
        markAsInternal
    }
    public method findTarball {{tarball {}}} {}
    public method getInstallerProjectXMLFiles {stack} {
        return [list native-adapter.xml native-apache-adapter.xml common-native-adapter.xml native-mysql-adapter.xml environment-autodetection-functions.xml apache-autodetection-functions.xml mysql-autodetection-functions.xml php-autodetection-functions.xml]
    }
    public method copyStackLogoImage {} {}

    public method copyProjectFiles {stack} {
        copyXmlFiles $stack
    }
    public method install {} {
	file delete -force [$be cget -output]/files
        file copy -force [srcdir]/files [$be cget -output]
	file copy -force [$be cget -projectDir]/base/htdocs-xampp [$be cget -output]
    }
    public method build {} {}
    public method srcdir {} {
        return [$be cget -src]
    }
    public method extract {} {
        file delete -force [$be cget -src]/files
        file mkdir [$be cget -src]/files
        foreach dir [glob  [xmlDirectory]/files/*] {
            file copy -force $dir [$be cget -src]/files
        }
    }
    public method needsToBeBuilt {} {
        return 1
    }
}

source releasable.tcl
source platforms.tcl
source apache.tcl
source mysql.tcl
source php.tcl
source java.tcl
source imagemagick.tcl
source perl.tcl
source cpan.tcl
source libraries.tcl
source oracle.tcl
