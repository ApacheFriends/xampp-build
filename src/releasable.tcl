
::itcl::class releasable {
    inherit metadataObject tarballCommon
    protected variable license

    private variable componentsAlreadySetup 0

    protected variable fromInfo 0
    protected variable fromInfoData ""
    private variable fromInfoDataArray

    protected variable bitnamiProgramDescription {}
    protected variable bitnamiProgramLicenseDescription {}
    protected variable dirName {}

    public variable setvars {}
    public variable version {}
    public variable rev 0

    #public variable be
    public variable targetInstance
    public variable applicationInstance

    # This is equivalent to the key in bitnami.com, most of the release data depend on it (installer names, images directory, images name)
    public variable shortname
    public variable application {}
    public variable appname {}
    public variable supportedHosts {}
    # This is intended to be only one
    public variable supportedLinuxChroot
    public variable projectFile project.xml
    public variable installerName {}

    public variable databaseManagementTool {}

    public variable isBitnamiProduct 1
    public variable tags {Bitnami}
    public variable platform_tags {}
    public variable system_req {}
    public variable programming_language {}

    public variable unattendedOptions {}
    public variable defaultApplicationUser {}
    public variable defaultApplicationPassword {}
    public variable machineUser {bitnami}
    #Releases: This fixes the issue when having an application that inherits from another one
    public variable isAlreadyDefined 0


    public variable properties
    #properties(PADCategory)      Servers
    #properties(PADCategoryClass) {Web Servers}

    # Ports that need to be open to access the app
    public variable defaultAccessPorts {80 443}
    public variable requiredMemory 512
    public variable requiredDiskSize 10
    public variable requiredCores 1
    # Application url prefix, if it doesn't default to /<key>
    public variable urlPrefix {}
    # Path to access to administrator relative to the application path. For example: "/admin"
    public variable productAdminUrl {}

    public variable isTrial 0

    # License number used in Google Cloud Images, we need to ask for a new one for each application
    public variable mainComponentLicense {}
    public variable mainComponentLicenseURL {}

    protected variable changelogFilePath {}
    protected variable xmlDirectoryPath {}

    public variable supportsBanner 0
    public variable supportsFtp 0
    public variable supportsSmtp 0
    public variable supportsVhost 0
    public variable supportsVhostOnly 0; # Force BCH to use virtual host (used for apps in root)
    public variable supportsSeveralInstances 0
    public variable supportsIpChange 0

    private variable targetMD5 {}
    private variable targetEtag {}
    private variable targetSha1 {}
    private variable targetSha256 {}
    private variable targetSize {}
    private variable targetTime {}
    private variable targetUncompressedSize {}
    public variable project_web_page {}

    protected variable productTemplate [file join [file dirname [file dirname [file normalize [info script]]]] base bitnami product-metadata.xml]
    protected variable versionTemplate [file join [file dirname [file dirname [file normalize [info script]]]] base bitnami product-version-metadata.xml]
    protected variable targetTemplate  [file join [file dirname [file dirname [file normalize [info script]]]] base bitnami product-target-metadata.xml]
    protected variable filesPath
    protected variable releasesPath
    public variable isGcc49MainGcc 0
    public variable isGcc8MainGcc 0

    private variable valid_properties {PADCategory PADCategoryClass PADSpecialCategory manifest}

    protected variable applicationDataPopulated 0

    protected method generateInstaller {type {onlyGenerateScript 0}} {
        if {[string match osx* [$be cget -target]]} {
            $be configure -target osx
        }
        set extraSetVars $setvars
        if {[$be cget -target] == "windows-x64"} {
            lappend extraSetVars "bitnami_platform_arch=windows-x64"
        }
        if {[isTrial] && [isBitnami]} {
            lappend extraSetVars "project.fullName=$appname"
            lappend extraSetVars "project.productDisplayIcon=\$\{installdir\}/img/$shortname-favicon.ico"
            if {[$this isa product]} {
                if {![[$this cget -stack] hasComponents [list commercialManager]] && [isBitnami]} {
                    error "Trial Applications must bundle the commercialManager"
                }
                foreach k {organization supportUrl} {
                    if {[$this cget -$k] == ""} {
                        error "Commercial applications must configure the '$k' setting"
                    }
                }
                lappend extraSetVars "project.component(commercialManager).parameter(manager_organization).value=$organization" "project.component(commercialManager).parameter(manager_support_url).value=$supportUrl"
                lappend extraSetVars "enable_bitnamicloud_page=0"
            }
        }
        buildProject [$be cget -output]/project.xml $be $type {} $extraSetVars $onlyGenerateScript
    }

    public method supportsBanner {} {
        return [xampptcl::util::isBooleanYes [$this cget -supportsBanner]]
    }
    public method isTrial {} {
        return [xampptcl::util::isBooleanYes [$this cget -isTrial]]
    }
    public method isModule {} {
        return [expr {[$this isa module] || [$targetInstance cget -kind] == "module"}]
    }
    public method getXMLFilesIncludedInProject {} {
        set projectFilePath [getProjectFile]
        set dir [file dirname $projectFilePath]
        set result {}
        foreach includedFile [xampptcl::util::getIncludedXmlFiles $projectFilePath] {
            if {[file exists [file join $dir $includedFile]]} {
                set result [concat $result [xampptcl::util::getAllRequiredXmlFiles [file join $dir $includedFile]]]
            } else {
                lappend result $includedFile
            }
        }
        return $result
    }
    public method getProjectFile {} {
        set files {}
        # Overwrite projectFile when inheriting from standalone
        if {$xmlDirectoryPath != ""} {
            lappend files [file join $xmlDirectoryPath $projectFile]
        }
        if {![catch {$this info function "xmlDirectory"}]} {
            lappend files [file join [$this xmlDirectory] $projectFile]
        }
        lappend files [file join [$be cget -projectDir] apps $dirName $projectFile]
        foreach f $files {
            if {[file exists $f]} {
                return $f
            }
        }
        error "Cannot find project file for $this"
    }
    protected method hasApplicationReference {} {
        if {[info exists shortname] && $shortname != "<undefined>"} {
            return 1
        } else {
            return 0
        }
    }
    public method getChangeLogFile {} {
        if {$changelogFilePath != ""} {
            return $changelogFilePath
        } else {
            return [file join [$be cget -projectDir] apps $shortname changelog.txt]
        }
    }
    protected method getFileInfo {f k} {
        set m [getCommandLineData "$k"]
        if {[requiresLocalFile] || $m == ""} {
            if {![file exists $f]} {
                if {$k == "etag"} {
                    # For now we don't require the etag
                    return ""
                }
                if {$k == "mtime" && ![requiresLocalFile]} {
                    # We can leave without the mtime...
                    return [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S} -gmt 1]
                } else {
                    message fatalerror "File $f not found and is needed to calculate its $k ! \n All affected files should be built before generating release information."
                }
            } else {
                switch -- $k {
                    "md5" {
                        return [xampptcl::util::md5 $f]
                    }
                    "etag" {
                        return [xampptcl::util::etag $f]
                    }
                    "sha1" {
                        return [xampptcl::util::sha1 $f]
                    }
                    "sha256" {
                        return [xampptcl::util::sha256 $f]
                    }
                    "size" {
                        return [file size $f]
                    }
                    "uncompressed_size" {
                        return [xampptcl::util::uncompressedSize $f]
                    }
                    "mtime" {
                        return [clock format [file mtime $f] -format {%Y-%m-%d %H:%M:%S} -gmt 1]
                    }

                    default {
                        message error "Don't know how to obtain $k from $f"
                    }
                }
            }
        } else {
            return $m
        }

    }
    protected method md5sum {f} {
        return [getFileInfo $f "md5"]
    }
    protected method etag {f} {
        return [getFileInfo $f "etag"]
    }
    protected method sha1sum {f} {
        return [getFileInfo $f "sha1"]
    }
    protected method sha256sum {f} {
        return [getFileInfo $f "sha256"]
    }
    protected method fileSize {f} {
        return [getFileInfo $f "size"]
    }

    protected method uncompressedSize {f} {
        return [getFileInfo $f "uncompressed_size"]
    }

    protected method fileModTime {f} {
        return [getFileInfo $f "mtime"]
    }


    protected method fromCommandLineData {} {
        if {[llength [array get fromInfoDataArray]] > 0} {
            return 1
        } else {
            return 0
        }
    }

    protected method requiresLocalFile {} {
        if {[fromCommandLineData]} {
            return 0
        } else {
            return 1
        }
    }

    protected method parseCommandLineData {data} {
        array set fromInfoDataArray {}
        foreach l [split $data \;] {
            set k [string trim [lindex [split $l =] 0]]
            set v [string trim [join [lrange [split $l =] 1 end] =]]
            set fromInfoDataArray($k) $v
        }
        array get fromInfoDataArray
    }
    protected method getCommandLineData {k} {
        if {[info exists fromInfoDataArray($k)]} {
            return $fromInfoDataArray($k)
        } else {
            return ""
        }
    }


    constructor {environment} {
        array set fromInfoDataArray {}
        chain $environment
    } {
        set filesPath [file normalize ~/unreleased]
        set releasesPath [file normalize ~/releases/bitnami-code/apps]
        set be $environment
        if {[$be cget -platformID] != "<undefined>"} {
            set targetInstance [[$be cget -platformID] ::\#auto $be]
        } else {
            set targetInstance [platform ::\#auto $be]
        }
        if {[info exists ::env(BITNAMI_IMAGE_REVISION)]} {
            $targetInstance configure -rev $::env(BITNAMI_IMAGE_REVISION)
        }
        array set properties {}
        set properties(PADCategory)      Servers
        set properties(PADCategoryClass) {Web Servers}

        populateApplicationData
    }

    protected method getApplicationClass {} {
        if {$application != ""} {
            set appClassName $application
        } else {
            set appClassName $shortname
        }
        return $appClassName
    }

    protected method populateApplicationData {} {
        if {[hasApplicationReference] && !$isAlreadyDefined} {
            set isAlreadyDefined 1
            set dirName $shortname
            set projectFile ${shortname}-standalone.xml
            set appClassName [getApplicationClass]
            if {![$this isa $appClassName]} {
                if {[itcl::is class ::$appClassName]} {
                    set cn [::$appClassName ::\#auto $be]
                    if {[$cn isa bitnamiProgram]} {
                        setApplicationData $cn
                        set applicationDataPopulated 1
                    }
                    ::itcl::delete object $cn
                }
            }
        }
        if {!$applicationDataPopulated} {
            populateBitnamiLicense
            populateDefaultCredentials
        }
    }

    public method getNameForPlatform {} {
        return $shortname
    }
    public method getDescription {} {
	if {$bitnamiProgramDescription != ""} {
	    return $bitnamiProgramDescription
	} else {
	    return [xampptcl::translation::poFileGet [getPoFile] [getLocaleDescKey]]
	}
    }
    public method isInfrastructure {} {
        return 0
    }
    public method populateBitnamiLicense {} {
        if {$mainComponentLicense != ""} {
            set mainComponentLicenseURL [getLicenseMainURL $mainComponentLicense]
        } elseif {[isInfrastructure]} {
            set mainComponentLicense APACHE2
            set mainComponentLicenseURL [getLicenseMainURL $mainComponentLicense]
        }
    }
    public method populateDefaultCredentials {} {
        if {[isInfrastructure]} {
            set defaultApplicationPassword bitnami
        }
    }
    public method getShortDescription {} {
        return [getDescription]
    }
    public method getLicenseDescription {} {
        if { $isTrial } {
            if {$bitnamiProgramLicenseDescription != ""} {
	        return $bitnamiProgramLicenseDescription
	    } else {
                return [xampptcl::translation::poFileGet [getPoFile] [getLocaleLicenseDescKey]]
            }
        }
    }

    public method isBitnami {} {
        return $isBitnamiProduct
    }
    protected method propertiesUnderscoreMapping {prop} {
        array set map [list \
            appname product_name \
            fullname product_fullname \
            bitnamiProgramDescription product_description \
            defaultApplicationUser product_default_username \
            defaultApplicationPassword product_default_password \
            bitnamiProgramLicenseDescription product_license_description \
            shortname id \
            relativeDocumentationUrl product_doc_relative_url \
            documentationUrl product_doc_url \
            credentialInformation credential_information \
            ]
        if {[info exists map($prop)]} {
            return $map($prop)
        } else {
            return [string tolower [regsub -all {([A-Z])} $prop {_\1}]]
        }
    }
    protected method getDatabaseManagementTool {} {
        if {$databaseManagementTool != ""} {
            return $databaseManagementTool
        } else {
            set f [getProjectFile]
            set hasPhpMyadmin 0
            foreach dep [xampptcl::util::getIncludedXmlFiles $f] {
                set dep [regsub {^(.*)\.xml$} $dep {\1}]
                switch -- $dep {
                    "phpmyadmin" {
                        set hasPhpMyadmin 1
                    }
                }
            }
            if {$hasPhpMyadmin} {
                return "phpMyAdmin"
            } else {
                return ""
            }
        }
    }

    public method createDocumentation {dest type} {
        file mkdir $dest
        switch -- $type {
            "vm" {
                set template base/vm
            }
            default {
                set template base/$type
            }
        }
        set bitnamiHtmlRoot [file join $::bitnami::rootPath base/htdocs/bitnami-html]
        set bitnamiCloudLib [file join $::bitnami::rootPath base/bitnami-cloud-lib]
        set tmpFile [xampptcl::util::temporaryFile]
        set docProperties [join [getSerializedPropertiesForDocs] \n]
        xampptcl::file::write $tmpFile $docProperties utf-8
        set cwd [pwd]
        cd $bitnamiHtmlRoot
        set templates [list $template]
        if {[file exists [file join $bitnamiHtmlRoot base/apps/$shortname]]} {
            lappend templates base/apps/$shortname
        }
        if {([$targetInstance cget -kind] != {}) && [file exists [file join $bitnamiHtmlRoot base/apps/$shortname [$targetInstance cget -kind]]]} {
            lappend templates base/apps/$shortname/[$targetInstance cget -kind]
        }
        set cmd [list exec ruby $bitnamiCloudLib/templates/build.rb $tmpFile $dest]
        set cmd [concat $cmd $templates]
        eval $cmd
        catch {file delete -force $tmpFile}
        if {[isTrial]} {
            file copy -force [getStackFixedImage] $dest/logo.png
        }
        cd $cwd
    }

    public method serializePropertiesForDocs {} {
        puts [join [getSerializedPropertiesForDocs] \n]
    }

    public method getSerializedPropertiesForDocs {} {
        set t {}
        #set bitnamiProgramDescription [getDescription]
        foreach property {appname fullname defaultApplicationUser defaultApplicationPassword urlPrefix productAdminUrl defaultAccessPorts isTrial credentialInformation} {
            set rubyProp [propertiesUnderscoreMapping $property]
            lappend t "$rubyProp=[set $property]"
        }
        if {[isBitnami] && ![isInternal]} {
            lappend t "cloud_doc_url=https://docs.bitnami.com/installer/"
            lappend t "[propertiesUnderscoreMapping relativeDocumentationUrl]=[getRelativeDocumentationUrl]"
            lappend t "[propertiesUnderscoreMapping documentationUrl]=[getDocumentationUrl]"
            set dbManageTool [getDatabaseManagementTool]
            lappend t "[propertiesUnderscoreMapping bitnamiProgramDescription]=[getShortDescription]"
            lappend t "[propertiesUnderscoreMapping bitnamiProgramLicenseDescription]=[getLicenseDescription]"
            lappend t "database_management_tool=$dbManageTool"
            lappend t "database_management_url=/[string tolower $dbManageTool]"
            lappend t "product_organization=$organization"
            lappend t "product_support_url=$supportUrl"
            lappend t "is_infrastructure=[isInfrastructure]"
        }
        return $t
    }

    public method logBasicProperties {} {
        # disable any messages if stderr reporting is not enabled
        if {![info exists ::env(BITNAMI_STDERR_MESSAGES)] && (![info exists ::env(XAMPPDEBUG)] || $::env(XAMPPDEBUG) != 1)} {
            set ::env(BITNAMI_QUIET_MODE) 1
        }
        set t [getBasicSerializedProperties]
        puts [join [lsort $t] \n]
    }

    public method logProperties {} {
        # disable any messages if stderr reporting is not enabled
        if {![info exists ::env(BITNAMI_STDERR_MESSAGES)] && (![info exists ::env(XAMPPDEBUG)] || $::env(XAMPPDEBUG) != 1)} {
            set ::env(BITNAMI_QUIET_MODE) 1
        }
        $be configure -verifyLicences 0
        set t [getSerializedProperties]
        puts [join [lsort $t] \n]
    }

    public method logCloudProperties {} {
        logProperties
        foreach platform {linux-x64 linux} {
            $be configure -target $platform
            # manually patch installer name for those that have it hardcoded
            # and do not take changes above into account
            if {$platform == "linux"} {
                set nameMap {-linux-x64- -linux-}
            }  else  {
                set nameMap {}
            }
            if {[catch {
                set tempInstallerName [string map $nameMap [string trim [$this getInstallerName]]]
                puts "installer_name_$platform=$tempInstallerName"
            }]} {
                # return empty name in case of error
                puts "installer_name_$platform="
            }

            if {[catch {
                set tempInstallerName [string map $nameMap [string trim [$this getInstallerName module]]]
                puts "installer_name_module_$platform=$tempInstallerName"
            }]} {
                # return empty name in case of error
                puts "installer_name_module_$platform="
            }
        }
    }

    public method getFinalOutputName {{kind stack}} {
        $this createStack
        $this getStackInstallerName
    }

    public method getBasicSerializedProperties {} {
        set t [getSerializedPropertiesForDocs]
        foreach property {requiredMemory requiredDiskSize requiredCores supportsBanner supportsFtp supportsSmtp supportsVhost supportsVhostOnly supportsSeveralInstances supportsIpChange shortname} {
            set rubyProp [propertiesUnderscoreMapping $property]
            lappend t "$rubyProp=[set $property]"
        }
        lappend t "bitnami_portal_key=[bitnamiPortalKey]"
        lappend t "main_component_license=$mainComponentLicense"
        lappend t "main_component_license_url=$mainComponentLicenseURL"
        lappend t "main_components=[listMainComponents]"
        lappend t "supported_platforms=[$this supportedPlatforms]"
        lappend t "unattended_options=$unattendedOptions"
        lappend t "is_bitnami=[$this isBitnami]"
        # kind is used by Wordpress multisite
        lappend t kind=[$targetInstance cget -kind]
        # revision in this case is used as cloud image revision, not revision of the stack
        lappend t revision=[$targetInstance cget -rev]
        # version is the combination of version and revision as they will appear in the installer name
        lappend t version=$version-$rev

        # additional helper attributes for Jenkins build scripts
        set stackClass [namespace tail [$this info class]]
        set stacks [list $stackClass]
        lappend t "tcl_name=$stackClass"
        lappend t "stack_build_names=[join $stacks]"
        set moduleClass [regsub {stack$} $stackClass "module"]
        if {[info commands ::$moduleClass] != {}} {
            lappend t "stack_build_modules=1"
        }  else  {
            lappend t "stack_build_modules=0"
        }
    }

    public method getSerializedProperties {} {
        set t [getBasicSerializedProperties]
        # Initialize the product and get non-whitelisted components
        if {[$this isa product]} {
            setupComponents
            set hasAgpl 0
            set missingTarball 0
            set componentList [concat [$this listBundledComponents] [$this getUniqueStackDependencyList]]
            foreach c $componentList {
                set uniqueIdentifier [$c getUniqueIdentifier]
                if {![string match -nocase *builddependency* [$c info heritage]]} {
                    if {[$this cget -isTrial] != 1 && [isBitnami]} {
                        if {[$c isNotGoogleWhitelisted] != 0} {
                            if {[$c isNotGoogleWhitelisted] == 1} {
                                # License is NOT whitelisted by Google
                                if {[catch {set tarballLocation [$c getS3SourcesTarballLocation]} kk]} {
                                    message warning "S3 TarballLocation for $uniqueIdentifier not found."
                                    set missingTarball 1
                                } else {
                                    lappend t component_${uniqueIdentifier}_src=${tarballLocation}
                                }
                            } elseif {$shortname != "xampp"} {
                                # License is missing
                                if {[$be cget -action] != "checkLicenses"} {
                                    message warning "Can't obtain license for $uniqueIdentifier"
                                } else {
                                    message error "Can't obtain license for $uniqueIdentifier"
                                    exit 1
                                }
                            }
                        } else {
                            # Licenses BSD, MIT or Apache
                            message info "$uniqueIdentifier is white-listed"
                        }
                    } else {
                        message info "$uniqueIdentifier is trial or not a Bitnami product"
                    }
                }
                if {[$c isAgpl]} {
                    set hasAgpl 1

                    # This is a tarball with a list of nodejs modules manually downloaded
                    if {![string match *NpmModulesWin* $c]} {
                        if {[file exist [$be cget -licensesDirectory]]} {
                            # Add document with source links for AGPL-licensed components
                            set AgplFile [file join [$be cget -licensesDirectory] AGPL-source-links.txt]
                            if {![file exists $AgplFile]} {
                                exec touch $AgplFile
                                xampptcl::file::prependTextToFile $AgplFile "========== SOURCE CODE LINKS FOR AGPL-LICENSED COMPONENTS ==========
"
                            }
                            set cn [[getApplicationClass] ::\#auto $be]
                            set cnName [$cn cget -name]
                            set downloadLink [$c getDownloadUrl]
                            xampptcl::file::addTextToFile $AgplFile "
* $cnName: $downloadLink
"
                        }
                    }
                }
            }
            if {$missingTarball} {
                message error "One or more components' tarballs were not found."
                exit 1
            }
            lappend t has_agpl_components=$hasAgpl
            if {[$this cget -requiredDiskSize] < "10"} {
                message error "The minimum required disk size for the stacks is 10Gb."
                exit 1
            }
        }
        return $t
    }

    private method setApplicationData {cn} {
            if {[$cn isa bitnamiProgram]} {
                set version [$cn versionNumber]
                set rev [$cn revisionNumber]
                set appname [$cn cget -fullname]
                set organization [$cn cget -organization]
                set supportUrl [$cn cget -supportUrl]
                if {[isBitnami]} {
                    set bitnamiProgramDescription [$cn getDescription]
                    set bitnamiProgramLicenseDescription [$cn getLicenseDescription]
                    set project_web_page [$cn getProjectWebPage]
                }
                set tags    [concat $tags [$cn cget -tags]]
                set defaultApplicationUser [$cn getDefaultApplicationUser]
                set defaultApplicationPassword [$cn getDefaultApplicationPassword]
                set credentialInformation [$cn cget -credentialInformation]
                if {[isBitnami] && [$cn getIsTrialAPI] != ""} {
                    if {[xampptcl::util::isBooleanYes [$cn cget -isTrial]] != [xampptcl::util::isBooleanYes [$cn getIsTrialAPI]]} {
                        error "Trial information is different in bitnami.com and in the Build system metadata"
                    }
                }
                set isTrial [$cn cget -isTrial]
                array set p [$cn propertyList]
                foreach name [array names p] {
                    set properties($name) [string map [list {&} {&amp;}] $p($name)]
                }
                set changelogFilePath [$cn getChangeLogFile]
                set xmlDirectoryPath [$cn xmlDirectory]
                set urlPrefix                [$cn cget -urlPrefix]
                set productAdminUrl          [$cn cget -adminUrl]
                set supportsFtp              [$cn cget -supportsFtp]
                set supportsSmtp             [$cn cget -supportsSmtp]
                set supportsVhost            [$cn cget -supportsVhost]
                set supportsVhostOnly        [$cn cget -supportsVhostOnly]
                set supportsSeveralInstances [$cn cget -supportsSeveralInstances]
                set supportsIpChange         [$cn cget -supportsIpChange]
                set requiredMemory           [$cn cget -requiredMemory]
                set requiredDiskSize         [$cn cget -requiredDiskSize]
                set requiredCores            [$cn cget -requiredCores]
                set databaseManagementTool   [$cn cget -databaseManagementTool]
                set supportsBanner           [$cn cget -supportsBanner]
                set mainComponentLicense     [$cn getMainComponentLicense]
                set mainComponentLicenseURL  [$cn getMainComponentLicenseURL]
            }
    }

    public method generateReleaseData {args} {
        set outputText {}
        set s3filepath ""
        set reRelease 0
        set writeToStd 0
        set partialRelease 0
        set readFileProperties 1
        set readChangelog 1
        foreach {n v} $args {
            switch -- $n {
                "--kind" {
                    if {$v == "module"} {
                        $targetInstance configure -kind module
                    }
                }
                "--fromCommandLineData" {
                    puts [parseCommandLineData $v]
                }
                "--stdout" {
                    set writeToStd $v
                }
                "--s3filepath" {
                    set s3filepath $v
                }
                "--output" {
                    set releasesPath $v
                }
                "--re-release" {
                    set reRelease $v
                }
                "--partial-release" {
                    set partialRelease $v
                }
                "--read-file-properties" {
                    set readFileProperties $v
                }
                "--read-changelog" {
                    set readChangelog $v
                }
                default {
                    puts "skipping unkown arg $n"
                }
            }
        }

        if {![$this isa xamppProduct]} {
          message info "Platform [$be cget -platformID] not supported by ${shortname}"
          return {}
        }

        setupComponents
        if {$readFileProperties} {
            set linkFileName                [readFileProperties]
        } else {
            set linkFileName {}
        }
        set bundled_component_list      [getBundledComponentsXML]
        validateMetadata

        set targetProperties {}
        array set p [$targetInstance propertyList]
        foreach {name value} [array get p] {
            set targetProperties "${targetProperties}
                <property name=\"${name}\" value=\"[ escapeXmlText $value ]\"/>"
        }
        set productProperties {}
        foreach {name value} [array get properties] {
            set productProperties "${productProperties}
                <property name=\"${name}\" value=\"[ escapeXmlText $value ]\"/>"
        }

        set product_metadata_file "[bitnamiPortalKey]/product.xml"
        set version_metadata_file "[bitnamiPortalKey]/${version}-${rev}/version.xml"
        set target_metadata_file  "[bitnamiPortalKey]/${version}-${rev}/[$be cget -platformID]-[$targetInstance cget -rev].xml"

        if {[$targetInstance cget -kind] != {}}  {
            set target_metadata_file [string map "[$be cget -platformID]- [$be cget -platformID]-[$targetInstance cget -kind]-" ${target_metadata_file} ]
        }

        if {$linkFileName == {}} {
            message info "Adding target info: ${target_metadata_file}"
        } else {
            message info "Adding info for ${linkFileName} (size: ${targetSize} Bytes md5: ${targetMD5})"
        }

        file mkdir [file dirname $releasesPath/$version_metadata_file]
        file mkdir "${releasesPath}/[bitnamiPortalKey]"

        set targetFileName {}
        if {$s3filepath != ""} {
            set targetFileName $s3filepath
        } elseif {$linkFileName != {}} {
            set targetFileName "files/stacks/[bitnamiPortalKey]/${version}-${rev}/${linkFileName}"
        }
        file mkdir "${releasesPath}/[bitnamiPortalKey]/${version}-${rev}"
        if {$shortname != "xampp"} {
            file copy -force $targetTemplate  $releasesPath/$target_metadata_file
            foreach {pattern value} [list \
                {@@XAMPP_TARGET_PLATFORM_ID@@}   [$be cget -platformID] \
                {@@XAMPP_TARGET_PLATFORM_TYPE@@} [$targetInstance cget -platform_type] \
                {@@XAMPP_TARGET_PLATFORM_NAME@@} [$targetInstance cget -name] \
                {@@XAMPP_TARGET_REVISION@@}      [$targetInstance cget -rev] \
                {@@XAMPP_TARGET_VERSION_TYPE@@}  [$targetInstance cget -kind] \
                {@@XAMPP_TARGET_CREATED_AT@@}       $targetTime \
                {@@XAMPP_INSTALLBUILDER_VERSION@@} "" \
                {@@XAMPP_OPERATING_SYSTEM_ID@@}       [$targetInstance cget -bundled_os_id] \
                {@@XAMPP_OPERATING_SYSTEM_NAME@@}     [$targetInstance cget -bundled_os_name] \
                {@@XAMPP_OPERATING_SYSTEM_VERSION@@}  [$targetInstance cget -bundled_os_version] \
                @@XAMPP_DATABASE_MANAGEMENT_TOOL@@ [getDatabaseManagementTool] \
                @@XAMPP_SUPPORTS_BANNER@@ $supportsBanner \
                {@@XAMPP_OPERATING_SYSTEM_REVISION@@} [$targetInstance cget -bundled_os_rev] \
                {@@XAMPP_TARGET_FILENAME@@}   $targetFileName \
                {@@XAMPP_TARGET_SIZE@@}       $targetSize \
                {@@XAMPP_TARGET_MD5@@}        $targetMD5 \
                {@@XAMPP_TARGET_ETAG@@}       $targetEtag \
                {@@XAMPP_TARGET_SHA1@@}       $targetSha1 \
                {@@XAMPP_TARGET_SHA256@@}     $targetSha256 \
                {@@XAMPP_UNCOMPRESSED_SIZE@@} $targetUncompressedSize \
                {@@XAMPP_TARGET_ID1@@}        {} \
                {@@XAMPP_TARGET_ID2@@}        {} \
                {@@XAMPP_TARGET_TAGS@@}       [join [$targetInstance cget -tags] ,] \
                {@@XAMPP_TARGET_FOR_PAD@@}     [PADTargets] ] {
                xampptcl::util::substituteParametersInFile $releasesPath/$target_metadata_file [list $pattern [escapeXmlText $value ]]
            }
            xampptcl::util::substituteParametersInFile $releasesPath/$target_metadata_file [list \
              {@@XAMPP_BUNDLED_COMPONENTS@@} \n$bundled_component_list\n \
              {@@XAMPP_TARGET_PROPERTIES@@}  $targetProperties ]
            append outputText target_metadata_file=$releasesPath/$target_metadata_file \n
        } else {
            # XAMPP requires installers to be generated
            if {$linkFileName == {}} {
                message warning "Skipping generation of XAMPP YAML file"
                return
            }
            set firstLevel "downloads"
            set baseUrl "https://www.apachefriends.org/xampp-files"
            set sourceForgeBaseUrl "http://downloads.sourceforge.net/project/xampp/XAMPP%20"
            set shortComponentList {}
            if {[string match *windows* [$targetInstance cget -name]]} {
                regexp {^(?:.*, )?windows(?:64)?XamppApache ([^,]*),.*} $bundled_component_list_yml match apacheVersion
                set shortComponentList [lappend shortComponentList "Apache ${apacheVersion}, "]
                regexp {^.*, windows(?:64)?XamppMysql (\d*\.\d*\.\d*),.*} $bundled_component_list_yml match mysqlVersion
                if {[info exists mysqlVersion]} {
                    set shortComponentList [lappend shortComponentList "MySQL ${mysqlVersion}, "]
                } else {
                    regexp {^.*, windows(?:64)?XamppMariaDb (\d*\.\d*\.\d*),.*} $bundled_component_list_yml match mariadbVersion
                    set shortComponentList [lappend shortComponentList "MariaDB ${mariadbVersion}, "]
                }
                regexp {^.*, windows(?:64)?XamppPhp74 ([^,]*),.*} $bundled_component_list_yml match phpVersion
                regexp {^.*, windows(?:64)?XamppPhp80 ([^,]*),.*} $bundled_component_list_yml match phpVersion
                regexp {^.*, windows(?:64)?XamppPhp81 ([^,]*),.*} $bundled_component_list_yml match phpVersion
                set shortComponentList [lappend shortComponentList "PHP ${phpVersion}, "]
                regexp {^.*, windows(?:64)?XamppPhpMyAdmin ([^,]*),.*} $bundled_component_list_yml match phpmyadminVersion
                set shortComponentList [lappend shortComponentList "phpMyAdmin ${phpmyadminVersion}, "]
                if {[::xampptcl::util::compareVersions $phpVersion 7.2] < 0} {
                    set shortComponentList [lappend shortComponentList "OpenSSL 1.0.2, "]
                } else {
                    set shortComponentList [lappend shortComponentList "OpenSSL 1.1.1, "]
                }
                set shortComponentList [lappend shortComponentList "XAMPP Control Panel 3.2.4, "]
                regexp {^.*, windows(?:64)?XamppWebalizer ([^,]*),.*} $bundled_component_list_yml match webalizerVersion
                set shortComponentList [lappend shortComponentList "Webalizer ${webalizerVersion}, "]
                regexp {^.*, windows(?:64)?XamppMercuryMail ([^,]*),.*} $bundled_component_list_yml match mercuryVersion
                set shortComponentList [lappend shortComponentList "Mercury Mail Transport System ${mercuryVersion}, "]
                regexp {^.*, windows(?:64)?XamppFileZillaFTP ([^,]*),.*} $bundled_component_list_yml match filezillaVersion
                set shortComponentList [lappend shortComponentList "FileZilla FTP Server ${filezillaVersion}, "]
                regexp {^.*, windows(?:64)?XamppTomcat ([^,]*),.*} $bundled_component_list_yml match tomcatVersion
                set shortComponentList [lappend shortComponentList "Tomcat ${tomcatVersion} (with mod_proxy_ajp as connector), "]
                regexp {^.*, windows(?:64)?XamppPerl ([^,]*),.*} $bundled_component_list_yml match perlVersion
                set shortComponentList [lappend shortComponentList "Strawberry Perl ${perlVersion} Portable"]
            } else {
                regexp {^(?:.*, )?apache ([^,]*),.*} $bundled_component_list_yml match apacheVersion
                set shortComponentList [lappend shortComponentList "Apache ${apacheVersion}, "]
                regexp {^.*, mysql ([^,]*),.*} $bundled_component_list_yml match mysqlVersion
                if {[info exists mysqlVersion]} {
                    set shortComponentList [lappend shortComponentList "MySQL ${mysqlVersion}, "]
                } else {
                    regexp {^.*, mariadb (\d*\.\d*\.\d*),.*} $bundled_component_list_yml match mariadbVersion
                    set shortComponentList [lappend shortComponentList "MariaDB ${mariadbVersion}, "]
                }
                regexp {^.*, php ([^,]*),.*} $bundled_component_list_yml match phpVersion
                regexp {^.*, sqlite (2[^,]*),.*} $bundled_component_list_yml match sqlite2Version
                regexp {^.*, sqlite (3[^,]*),.*} $bundled_component_list_yml match sqlite3Version
                if {[string match 7* $phpVersion]} {
                    set shortComponentList [lappend shortComponentList "PHP ${phpVersion} + SQLite ${sqlite2Version}/${sqlite3Version} + multibyte (mbstring) support, "]
                } else {
                    set shortComponentList [lappend shortComponentList "PHP ${phpVersion} & PEAR + SQLite ${sqlite2Version}/${sqlite3Version} + multibyte (mbstring) support, "]
                }
                regexp {^.*, perl ([^,]*),.*} $bundled_component_list_yml match perlVersion
                set shortComponentList [lappend shortComponentList "Perl ${perlVersion}, "]
                regexp {^.*, proftpd ([^,]*),.*} $bundled_component_list_yml match proftpdVersion
                set shortComponentList [lappend shortComponentList "ProFTPD ${proftpdVersion}, "]
                regexp {^.*, phpmyadmin ([^,]*),.*} $bundled_component_list_yml match phpmyadminVersion
                set shortComponentList [lappend shortComponentList "phpMyAdmin ${phpmyadminVersion}, "]
                regexp {^.*, openssl ([^,]*),.*} $bundled_component_list_yml match opensslVersion
                set shortComponentList [lappend shortComponentList "OpenSSL ${opensslVersion}, "]
                regexp {^.*, gd ([^,]*),.*} $bundled_component_list_yml match gdVersion
                set shortComponentList [lappend shortComponentList "GD $gdVersion, "]
                regexp {^.*, freetype ([^,]*),.*} $bundled_component_list_yml match freetypeVersion
                set shortComponentList [lappend shortComponentList "Freetype2 ${freetypeVersion}, "]
                regexp {^.*, libpng ([^,]*),.*} $bundled_component_list_yml match libpngVersion
                set shortComponentList [lappend shortComponentList "libpng ${libpngVersion}, "]
                regexp {^.*, gdbm ([^,]*),.*} $bundled_component_list_yml match gdbmVersion
                set shortComponentList [lappend shortComponentList "gdbm ${gdbmVersion}, "]
                regexp {^.*, zlib ([^,]*),.*} $bundled_component_list_yml match zlibVersion
                set shortComponentList [lappend shortComponentList "zlib ${zlibVersion}, "]
                regexp {^.*, expat ([^,]*),.*} $bundled_component_list_yml match expatVersion
                set shortComponentList [lappend shortComponentList "expat ${expatVersion}, "]
                regexp {^.*, sablotron ([^,]*),.*} $bundled_component_list_yml match sablotronVersion
                set shortComponentList [lappend shortComponentList "Sablotron ${sablotronVersion}, "]
                regexp {^.*, libxml ([^,]*),.*} $bundled_component_list_yml match libxmlVersion
                set shortComponentList [lappend shortComponentList "libxml ${expatVersion}, "]
                regexp {^.*, ming ([^,]*),.*} $bundled_component_list_yml match mingVersion
                set shortComponentList [lappend shortComponentList "Ming ${mingVersion}, "]
                regexp {^.*, webalizer ([^,]*),.*} $bundled_component_list_yml match webalizerVersion
                set shortComponentList [lappend shortComponentList "Webalizer ${webalizerVersion}, "]
                regexp {^.*, pdf-class ([^,]*),.*} $bundled_component_list_yml match pdfclassVersion
                set shortComponentList [lappend shortComponentList "pdf class ${pdfclassVersion}, "]
                regexp {^.*, ncurses ([^,]*),.*} $bundled_component_list_yml match ncursesVersion
                set shortComponentList [lappend shortComponentList "ncurses ${ncursesVersion}, "]
                regexp {^.*, pdf-class ([^,]*),.*} $bundled_component_list_yml match pdfclassVersion
                set shortComponentList [lappend shortComponentList "pdf class ${pdfclassVersion}, "]
                regexp {^.*, modperl ([^,]*),.*} $bundled_component_list_yml match modperlVersion
                set shortComponentList [lappend shortComponentList "mod_perl ${modperlVersion}, "]
                regexp {^.*, freetds ([^,]*),.*} $bundled_component_list_yml match freetdsVersion
                set shortComponentList [lappend shortComponentList "FreeTDS ${freetdsVersion}, "]
                regexp {^.*, gettext ([^,]*),.*} $bundled_component_list_yml match gettextVersion
                set shortComponentList [lappend shortComponentList "gettext ${gettextVersion}, "]
                regexp {^.*, imap ([^,]*),.*} $bundled_component_list_yml match imapVersion
                set shortComponentList [lappend shortComponentList "IMAP C-Client ${imapVersion}, "]
                regexp {^.*, openldap ([^,]*),.*} $bundled_component_list_yml match openldapVersion
                set shortComponentList [lappend shortComponentList "OpenLDAP (client) ${openldapVersion}, "]
                regexp {^.*, libmcrypt ([^,]*),.*} $bundled_component_list_yml match libmcryptVersion
                set shortComponentList [lappend shortComponentList "mcrypt ${libmcryptVersion}, "]
                regexp {^.*, mhash ([^,]*),.*} $bundled_component_list_yml match mhashVersion
                set shortComponentList [lappend shortComponentList "mhash ${mhashVersion}, "]
                regexp {^.*, curl ([^,]*),.*} $bundled_component_list_yml match curlVersion
                set shortComponentList [lappend shortComponentList "cUrl ${curlVersion}, "]
                regexp {^.*, libxslt ([^,]*),.*} $bundled_component_list_yml match libxsltVersion
                set shortComponentList [lappend shortComponentList "libxslt ${libxsltVersion}, "]
                regexp {^.*, libapreq2 ([^,]*),.*} $bundled_component_list_yml match libapreqVersion
                set shortComponentList [lappend shortComponentList "libapreq ${libapreqVersion}, "]
                regexp {^.*, fpdf ([^,]*),.*} $bundled_component_list_yml match fpdfVersion
                set shortComponentList [lappend shortComponentList "FPDF ${fpdfVersion}, "]
                regexp {^.*, icu4c ([^,]*),.*} $bundled_component_list_yml match icu4cVersion
                set shortComponentList [lappend shortComponentList "ICU4C Library ${icu4cVersion}, "]
                regexp {^(?:.*, )?apr ([^,]*),.*} $bundled_component_list_yml match aprVersion
                set shortComponentList [lappend shortComponentList "APR ${aprVersion}, "]
                regexp {^.*, apr-util ([^,]*),.*} $bundled_component_list_yml match aprutilVersion
                set shortComponentList [lappend shortComponentList "APR-utils ${aprutilVersion}"]
            }
            set shortComponentListText ""
            foreach c $shortComponentList {
                set shortComponentListText "${shortComponentListText}${c}"
            }
            if {[string match *osx* [$targetInstance cget -name]]} {
                set firstLevel "apple"
                if {[string match *XAMPP-VM-osx* $linkFileName]} {
                    set requirements "Mac OS X 10.10.3 or later."
                } else {
                    set requirements "Mac OS X 10.6 or later."
                }
                set platformUrl "Mac%20OS%20X"
                set osTag "64"
            } elseif {[string match *linux* [$targetInstance cget -name]]} {
                set firstLevel "linux-x64"
                set requirements "Most all distributions of Linux are supported, including Debian, RedHat, CentOS, Ubuntu, Fedora, Gentoo, Arch, SUSE."
                set platformUrl "Linux"
                set osTag "64"
            } elseif {[string match *windows* [$targetInstance cget -name]]} {
                set firstLevel "windows"
                set platformUrl "Windows"
                set requirements "Windows 2008, 2012, Vista, 7, 8 (Important: XP or 2003 not supported)"
                set osTag "64"
            }
            if {$firstLevel == "linux" && $osTag == "64"} {
                xampptcl::file::write $releasesPath/[bitnamiPortalKey]/${version}-${rev}/$linkFileName.yml "      x${osTag}:
        checksum_md5: $targetMD5
        checksum_sha1: $targetSha1
        checksum_sha256: $targetSha256
        size: \"[expr $targetSize/(1024*1024)] Mb\"
        url: \"${baseUrl}/${version}/$linkFileName\"
        alternative_url: \"${sourceForgeBaseUrl}${platformUrl}/${version}/$linkFileName\"
"
            } else {
                xampptcl::file::write $releasesPath/[bitnamiPortalKey]/${version}-${rev}/$linkFileName.yml "  -
    version: $version
    php_version: $phpVersion
    whats_included: \"$shortComponentListText\"
    requirements: \"$requirements\"
    downloads:
      x${osTag}:
        checksum_md5: $targetMD5
        checksum_sha1: $targetSha1
        checksum_sha256: $targetSha256
        size: \"[expr $targetSize/(1024*1024)] Mb\"
        url: \"${baseUrl}/${version}/$linkFileName\"
        alternative_url: \"${sourceForgeBaseUrl}${platformUrl}/${version}/$linkFileName\"
"
            }
        }
        if {$writeToStd == 1} {
            puts -nonewline $outputText
        } else {
            return $outputText
        }
    }
    public method getProductFileName {{type stack} {target {}} {customSuffix {}}} {
        if {$customSuffix == "" && [info exists ::env(BITNAMI_IMAGE_REVISION)] && $::env(BITNAMI_IMAGE_REVISION) != 0} {
            set customSuffix -r[format "%02d" $::env(BITNAMI_IMAGE_REVISION)]
        }
        # Set installerName up to version-revision
        set revSuffix $rev$customSuffix
        if {${shortname} == "xampp"} {
            if {[string match *osx-x64* [$be cget -target]]} {
                set linkFileName "xampp-osx-${version}-${revSuffix}"
            } elseif {[string match *windows* [$be cget -target]]} {
                set linkFileName "xampp"
                if {[$targetInstance cget -kind] == "portable"} {
                    append linkFileName "-portable"
                }
                append linkFileName "-windows-x64-${version}-${revSuffix}"
                if {[string match *1.8.2* $version]} {
                    append linkFileName "-VC9"
                } elseif {[string match 5.* $version]} {
                    append linkFileName "-VC11"
                } elseif {[::xampptcl::util::compareVersions $version 7.2.0] < 0} {
                    append linkFileName "-VC14"
                } elseif {[::xampptcl::util::compareVersions $version 8.0.0] < 0} {
                    append linkFileName "-VC15"
                } else {
                    append linkFileName "-VS16"
                }
            } else {
                set linkFileName "xampp-[$be cget -target]-${version}-${revSuffix}"
            }
        } else {
            set mapping {}
            set linkFileName "bitnami-[string map $mapping [bitnamiPortalKey]]-${version}-${revSuffix}"
        }
        if {$target == ""} {
            set installerPlatformName [$targetInstance cget -name]
        } else {
            set installerPlatformName $target
        }
        if {[string match "*osx-x64" $installerPlatformName]} {
            set installerPlatformName osx-x86_64
        }
        # Define type of installer (dev, module...)
        if {![string match xampp* $shortname]} {
            if {[$targetInstance cget -kind] == {nojdk}} {
                set linkFileName "$linkFileName-$installerPlatformName-[$targetInstance cget -kind]"
            } elseif {[$targetInstance cget -kind] != {}} {
                set linkFileName "$linkFileName-[$targetInstance cget -kind]-$installerPlatformName"
            } else {
                set linkFileName "$linkFileName-$installerPlatformName"
            }
        }
        return $linkFileName
    }
    public method getFullProductFileName {} {
        set linkFileName [getProductFileName]
        # Not in getProductFileName because extension may change (e.g. .app to .dmg)
        switch -glob [$be cget -platformID] {
            linux* - solaris* { set linkFileName "${linkFileName}-installer.run" }
            windows*          { set linkFileName "${linkFileName}-installer.exe" }
            osx-*             { set linkFileName "${linkFileName}-installer.dmg" }
            vbox*             { set linkFileName "${linkFileName}-OVF.zip" }
            vm*               { set linkFileName "${linkFileName}.zip" }
            stackman*         { set linkFileName "${linkFileName}-vm.dmg" }
            default           { set linkFileName {} }
        }
        return $linkFileName
    }
    private method readFileProperties { } {
        set linkFileName [$this getFullProductFileName]
        if { $linkFileName != {} } {
            if {[requiresLocalFile] && ![file exists $filesPath/$linkFileName] } {
                message fatalerror "File $filesPath/$linkFileName not found ! \n All affected files should be built before generating release information."
            } else {
		set targetMD5 [md5sum $filesPath/$linkFileName]
		set targetEtag [etag $filesPath/$linkFileName]
		set targetSha1 [sha1sum $filesPath/$linkFileName]
		set targetSha256 [sha256sum $filesPath/$linkFileName]
		set targetSize [fileSize $filesPath/$linkFileName]
                if {$targetSize == 0} {
                    message fatalerror "File $filesPath/$linkFileName seems to be broken: it has 0 bytes."
                }
                if {[string match "*.tar" $linkFileName] || [string match "*.tar.gz" $linkFileName] || [string match "*.tgz" $linkFileName]} {
                    set targetUncompressedSize [uncompressedSize $filesPath/$linkFileName]
                }
                set targetTime [fileModTime $filesPath/$linkFileName]
            }
        } else {
            set targetTime [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S} -gmt 1]
        }
        return $linkFileName
    }
    private method getComponentType {c} {
        set componentType "component"
        if {[$c isa library]} {
            set componentType "library"
        }
        return $componentType
    }
    private method setupComponents {} {
        if {!$componentsAlreadySetup} {
            $be configure -buildType "fromTarball"
            if {[$this isa product]} {
                $this setupStackComponents
                [$this cget -stack] createStackComponents
                if {[[$this cget -stack] cget -nojdk] == 1} {
                    $targetInstance configure -kind nojdk
                }
            }
            set componentsAlreadySetup 1
        }
    }
    private method getBundledComponentsXML {} {
        set bundledComponentsXML {}
        set standaloneFileContent [xampptcl::file::read [getProjectFile]]
        foreach c [listBundledComponents] {
            set componentLicense ""
            set componentSourcesTarballPath ""
            set componentName [$c getUniqueIdentifier]
            if {[$c isAgpl]} {
                set componentLicense AGPL
            }
            if {[$c isCddl]} {
                set componentLicense CDDL
            }
            if {[$c isWtfpl]} {
                set componentLicense WTFPL
            }
            if {[$c isNotGoogleWhitelisted] != 0} {
                if {[$c isNotGoogleWhitelisted] == 1} {
                    if {[catch {set componentSourcesTarballPath [$c getS3SourcesTarballLocation]} kk]} {
                        message warning "S3 TarballLocation for [$c cget -name] not found."
                    }
                } elseif {$shortname != "xampp"} {
                    message error "Can't obtain license for $componentName"
                    exit 1
                }

            }
            set componentFullName [$c cget -fullname]
            set mainComponent "false"
            if {[isMainComponentBundled $c $standaloneFileContent]} {
                set mainComponent "true"
                if {$componentFullName == ""} {
                    error "The $componentName component is set as main component, but it has not set its fullname. Check if it is a valid main component, and if so, set a fullname."
                }
            }
            if {[string compare $componentSourcesTarballPath [$be cget -rootS3TarballPath]] != 0} {
                append bundledComponentsXML "<component name=\"$componentName\" version=\"[$c cget -version]\" type=\"[getComponentType $c]\" license=\"${componentLicense}\" source_url=\"${componentSourcesTarballPath}\" main_component=\"${mainComponent}\" fullname=\"${componentFullName}\" />" \n
            }
        }
        return $bundledComponentsXML
    }
    public method listMainComponents {} {
        set mainComponents {}
        if {![isModule]} {
            set standaloneFileContent [xampptcl::file::read [getProjectFile]]
            foreach c [listBundledComponents] {
                set componentName [$c getUniqueIdentifier]
                set componentFullName [$c cget -fullname]
                if {[isMainComponentBundled $c $standaloneFileContent]} {
                    append mainComponents "[$c cget -fullname]: [$c cget -version] "
                    if {$componentFullName == ""} {
                        error "The $componentName component is set as main component, but it has not set its fullname. Check if it is a valid main component, and if so, set a fullname."
                    }
                } else {
                    continue
                }
            }
        }
        return $mainComponents
    }
    public method isMainComponent {component} {
        if { [$component cget -isReportableComponent] && [$component cget -isReportableAsMainComponent] && [getComponentType $component] == "component" } {
            set mainComponentName [$component getMainComponentXMLName]
            if { $mainComponentName != "" } {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    private method isMainComponentBundled {component standaloneFileContent} {
        if { [isMainComponent $component] } {
            set mainComponentName [$component getMainComponentXMLName]
            if {[regexp -line "\".*${mainComponentName}\.xml\"" $standaloneFileContent]} {
                    return true
            }
        }
        return false
    }
    public method listBundledComponents {} {
        set bundledAndFilteredComponentsList {}
        setupComponents
        set xmlFilesIncludedInProject [getXMLFilesIncludedInProject]
        if {[isModule]} {
            set cn [[getApplicationClass] ::\#auto $be]
            lappend bundledAndFilteredComponentsList $cn
        } else {
            set components_to_ignore {bitnami rubystack}
            if { [$targetInstance cget -kind] == {nojdk}} {
                lappend components_to_ignore java
            }
            if {[$this isa xamppProduct] } {
                lappend components_to_ignore postgresql sqlite ruby
            } elseif { [$this isa xappProduct]} {
                lappend components_to_ignore mysql phpmyadmin sqlite ruby
            } elseif { [$this isa rubyProduct] && ![$this isa rubystackbase]} {
                lappend components_to_ignore phpmyadmin php mod_fastcgi perl {ruby 1.9.1-p129}
            }
            foreach c [$this getBundledComponents] {
                set component [$c info class]
                if {[lsearch $components_to_ignore component] == -1 \
                    && [lsearch $components_to_ignore "$component"] == -1} {
                    if {[$c cget -version] == ""} {
                        error "The [$c cget -fullname] ($c) component doesn't have any version specified. Please add a version"
                    }
                    lappend bundledAndFilteredComponentsList $c
                }
            }
        }
        return $bundledAndFilteredComponentsList
    }

    private method getBundledComponentsYml {} {
        set bundledComponents {}
        foreach c [listBundledComponents] {
            lappend bundledComponents "[$c cget -name] [$c cget -version]"
        }
        return [join $bundledComponents {, }]
    }

    private method PADTargets {} {
        # Portable Application Description
        set currentTargetPAD {}
        switch [$be cget -platformID] {
            windows { set currentTargetPAD "Win98,WinME,Win2000,Windows2000,Win2003,Windows2003,WinNT 3.x,WinNT 4.x,WinXP,WinVista,WinVista x64,Win7 x32,Win7 x64,WinOther,WinServer,Windows Vista Starter,Windows Vista Home Basic,Windows Vista Home Premium,Windows Vista Business,Windows Vista Enterprise,Windows Vista Ultimate" }
            linux - linux-x64  { set currentTargetPAD "Linux,Linux Console,Linux Gnome,Linux Open Source" }
            osx-x64 { set currentTargetPAD "Mac OS X,Mac Other" }
        }
        return $currentTargetPAD
    }

    private method validateMetadata {} {
        # Validate PAD Categories
        set pad_category $properties(PADCategory)::$properties(PADCategoryClass)
        if {![regexp {^(Audio & Multimedia::Audio Encoders\/Decoders|Audio & Multimedia::Audio File Players|Audio & Multimedia::Audio File Recorders|Audio & Multimedia::CD Burners|Audio & Multimedia::CD Players|Audio & Multimedia::Multimedia Creation Tools|Audio & Multimedia::Music Composers|Audio & Multimedia::Other|Audio & Multimedia::Presentation Tools|Audio & Multimedia::Rippers & Converters|Audio & Multimedia::Speech|Audio & Multimedia::Video Tools|Business::Accounting & Finance|Business::Calculators & Converters|Business::Databases & Tools|Business::Helpdesk & Remote PC|Business::Inventory & Barcoding|Business::Investment Tools|Business::Math & Scientific Tools|Business::Office Suites & Tools|Business::Other|Business::PIMS & Calendars|Business::Project Management|Business::Vertical Market Apps|Communications::Chat & Instant Messaging|Communications::Dial Up & Connection Tools|Communications::E-Mail Clients|Communications::E-Mail List Management|Communications::Fax Tools|Communications::Newsgroup Clients|Communications::Other Comms Tools|Communications::Other E-Mail Tools|Communications::Pager Tools|Communications::Telephony|Communications::Web\/Video Cams|Desktop::Clocks & Alarms|Desktop::Cursors & Fonts|Desktop::Icons|Desktop::Other|Desktop::Screen Savers: Art|Desktop::Screen Savers: Cartoons|Desktop::Screen Savers: Nature|Desktop::Screen Savers: Other|Desktop::Screen Savers: People|Desktop::Screen Savers: Science|Desktop::Screen Savers: Seasonal|Desktop::Screen Savers: Vehicles|Desktop::Themes & Wallpaper|Development::Active X|Development::Basic, VB, VB DotNet|Development::C \/ C\+\+ \/ C\#|Development::Compilers & Interpreters|Development::Components & Libraries|Development::Debugging|Development::Delphi|Development ::Help Tools|Development::Install & Setup|Development::Management & Distribution|Development::Other|Development::Source Editors|Education::Computer|Education::Dictionaries|Education::G eography|Education::Kids|Education::Languages|Education::Mathema tics|Education::Other|Education::Reference Tools|Education::Science|Education::Teaching & Training Tools|Games & Entertainment::Action|Games & Entertainment::Adventure & Roleplay|Games & Entertainment::Arcade|Games & Entertainment::Board|Games & Entertainment::Card|Games & Entertainment::Casino & Gambling|Games & Entertainment::Kids|Games & Entertainment::Online Gaming|Games & Entertainment::Other|Games & Entertainment::Puzzle & Word Games|Games & Entertainment::Simulation|Games & Entertainment::Sports|Games & Entertainment::Strategy & War Games|Games & Entertainment::Tools & Editors|Graphic Apps::Animation Tools|Graphic Apps::CAD|Graphic Apps::Converters & Optimizers|Graphic Apps::Editors|Graphic Apps::Font Tools|Graphic Apps::Gallery & Cataloging Tools|Graphic Apps::Icon Tools|Graphic Apps::Other|Graphic Apps::Screen Capture|Graphic Apps::Viewers|Home & Hobby::Astrology\/Biorhythms\/Mystic|Home & Hobby::Astronomy|Home & Hobby::Cataloging|Home & Hobby::Food & Drink|Home & Hobby::Genealogy|Home & Hobby::Health & Nutrition|Home & Hobby::Other|Home & Hobby::Personal Finance|Home & Hobby::Personal Interest|Home & Hobby::Recreation|Home & Hobby::Religion|Network & Internet::Ad  Blockers|Network & Internet::Browser Tools|Network & Internet::Browsers|Network & Internet::Download Managers|Network & Internet::File Sharing\/Peer to Peer|Network & Internet::FTP Clients|Network & Internet::Network Monitoring|Network & Internet::Other|Network & Internet::Remote Computing|Network & Internet::Search\/Lookup Tools|Network & Internet::Terminal & Telnet Clients|Network & Internet::Timers & Time Synch|Network & Internet::Trace & Ping Tools|Security & Privacy::Access Control|Security & Privacy::Anti-Spam & Anti-Spy Tools|Security & Privacy::Anti-Virus Tools|Security & Privacy::Covert Surveillance|Security & Privacy::Encryption Tools|Security & Privacy::Other|Security & Privacy::Password Managers|Servers::Firewall & Proxy Servers|Servers::FTP Servers|Servers::Mail Servers|Servers::News Servers|Servers::Other Server Applications|Servers::Telnet Servers|Servers::Web Servers|System Utilities::Automation Tools|System Utilities::Backup & Restore|System Utilities::Benchmarking|System Utilities::Clipboard Tools|System Utilities::File & Disk Management|System Utilities::File Compression|System Utilities::Launchers & Task Managers|System Utilities::Other|System Utilities::Printer|System Utilities::Registry Tools|System Utilities::Shell Tools|System Utilities::System Maintenance|System Utilities::Text\/Document Editors|Web Development::ASP & PHP|Web Development::E-Commerce|Web Development::Flash Tools|Web Development::HTML Tools|Web Development::Java & JavaScript|Web Development::Log Analysers|Web Development::Other|Web Development::Site Administration|Web Development::Wizards &Components|Web Development::XML\/CSS Tools)$} $pad_category] } {
            message fatalerror "Wrong PAD category configuration: '${pad_category}'"
        }
    }

    private method enumerate {elements {last_join and}} {
        if {[llength $elements] > 1} {
            return [concat [join [lrange $elements 0 end-1] {, }] $last_join [lindex $elements end]]
        } elseif {[llength $elements] == 1} {
            return [lindex $elements 0]
        } else {
            return {}
        }
    }

    private method escapeXmlText {text} {
        return [string map {& &amp; < &lt; > &gt; ' &apos; \" &quot;} $text]
    }

}
