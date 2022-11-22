# stacks.tcl
# Stack class

::itcl::class stack {
    inherit tarballCommon
    public variable nojdk 0
    public variable components {}
    public variable componentsDependencies {}
    public variable be {}
    public variable pr
    public variable baseTarball ""
    protected variable stackComponentsAlreadyCreated 0
    constructor {environment} {
        set be $environment
    }
    # The following methods are called by proc createObject
    public method setBuildEnvironment {be} {}
    public method setEnvironment {} {}
    public method createStackComponents {{forBuilding 1}} {
        if {!$stackComponentsAlreadyCreated} {
            set stackComponentsAlreadyCreated 1
            foreach c $components {
                set componentName [lindex $c 0]
                # Do not do 'setEnvironment' because it may need parameters that are not available
                # For instance, 'version' may not be set so the 'prefix' method would not work
                if [catch {set pr($componentName) [createObject $componentName $be $forBuilding 0]} errorText] {
                    error "BUILD_TARBALL_ERROR: $errorText\nError creating component $componentName. Make sure that component name exists"
                }
                if {[llength $c] > 1} {
                    set c [lreplace $c 0 0]
                    foreach {option value} $c {
                        $pr($componentName) configure -$option $value
                    }
                }
                if {$forBuilding} {
                    $pr($componentName) setEnvironment
                }
            }
        }
    }

    public method setAndCreateStackComponentsDependencies {} {
        set componentsDependencies {}
        foreach c $components {
            set componentRef [getComponentRef [lindex $c 0]]
            if {[$componentRef isa rubyBitnamiProgram]} {
                foreach gem [$componentRef getAdditionalGems] {
                    set pr([lindex [split [$gem info class] :] end]) $gem
                    lappend componentsDependencies [lindex [split [$gem info class] :] end]
                }
            }
            if {[$componentRef isa pythonBitnamiProgram]} {
                foreach pythonModule [$componentRef getAdditionalPythonModules 0] {
                    set pr([lindex [split [$pythonModule info class] :] end]) $pythonModule
                    lappend componentsDependencies [lindex [split [$pythonModule info class] :] end]
                }
            }
        }
    }
    public method reportUsedComponents {productName} {
        set report "$productName Stack - [clock format [clock seconds] -format {%Y%m%d}]\n"
        foreach component $components {
            set c [$this getComponentRef $component]
            append report "[$c cget -name] [$c cget -version]\n"
        }
        ::xampptcl::file::write [file join [$be cget -output] ${productName}-[$be cget -target]-[clock format [clock seconds] -format "%Y%m%d"]-versions.txt] $report
    }
    public method getProgramsArray {} {
        return [array names pr]
    }
    public method componentsToBuild {} {
        return $components
    }
    public method preparefordist {} {
        file mkdir [file join [$be cget -output] common]
    }
    public method buildComponents {componentsToBuild} {
        $be evalTimer "compilation.total" {
            puts "Components to build: $componentsToBuild"
            foreach c $componentsToBuild {
                set componentName [lindex $c 0]
                if {[$pr($componentName) needsToBeBuilt]} {
                    message info2 "[$pr($componentName) cget -name] needs to be built. Building"
                    if {[$pr($componentName) cget -deleteSourceDirWhenBuilding]} {
                        file delete -force [$pr($componentName) srcdir]
                    }
                    $be evalTimer "extract.$componentName" {
                        $pr($componentName) extract
                    }

                    $be evalTimer "build.$componentName" {
                        $pr($componentName) build
                    }

                    ::xampptcl::file::write [$pr($componentName) srcdir]/.buildcomplete {}
                } else {
                    message info2 "Skipping build step for [$pr($componentName) cget -name] version [$pr($componentName) cget -version]"
                }
                $be evalTimer "install.$componentName" {
                    $pr($componentName) install
                }

                $pr($componentName) copyLicense
            }
        }
    }
    public method addComponents {args} {
        foreach c $args {
            lappend components $c
        }
    }
    public method removeComponents {args} {
        foreach c $args {
            set components [lremove $components $c]
            array unset pr $c
        }
    }
    public method replaceComponent {oldComponent newComponentList} {
        set componentListByName {}
        foreach c $components {
           lappend componentListByName [lindex $c 0]
        }
        #set position [lsearch -exact $components $oldComponent]
        set position [lsearch -exact $componentListByName $oldComponent]
        if {$position == "-1"} {
            error "Can't replace component $oldComponent with $newComponentList"
        } else {
            set components [lreplace $components $position $position]
            foreach c $newComponentList {
                set components [linsert $components $position $c]
                incr position
            }
            return 1
        }
    }
    public method hasComponents {componentList} {
        set hasAllComponents 1
        set hasThisComponent 0
        foreach component $componentList {
            foreach c [array names pr] {
                if {[$pr($c) isa $component]} {
                    set hasThisComponent 1
                }
            }
            set hasAllComponents [expr $hasAllComponents * $hasThisComponent]
            set hasThisComponent 0
        }
        return $hasAllComponents
    }
    public method copyProjectFiles {} {
        foreach c $components {
            set componentName [lindex $c 0]
            $pr($componentName) copyProjectFiles $this
            $pr($componentName) copyStackLogoImage
        }
    }
    public method getComponentRef {component} {
        return $pr([lindex $component 0])
    }
    protected method tarballPath {} {
        # Values are set in the buildEnvironment class
        set rc [concat [$be cget -betaTarballs] [recursiveGlobDir [$be cget -tarballs]] [recursiveGlobDir [$be cget -clientFilesDir]] [recursiveGlobDir [$be cget -compiledTarballs]]]
        if { [info exists ::env(TEMP_TARBALLS_DIR)]} {
            lappend rc $::env(TEMP_TARBALLS_DIR)
        }
        lappend rc "/tmp/tarballs"
        # set rc [concat $rc [getS3Paths]]
        return $rc
    }
    public method prepareConfiguredXmlFiles {} {
       foreach c $components {
           $pr([lindex $c 0]) prepareXmlFiles
        }
    }
    public method findTarball {} {
        if {$baseTarball == ""} {
            return ""
        }
        message info2 "Looking for $baseTarball"
        set baseName [join [lrange [split $baseTarball "-"] 0 end-1] "-"]
        if {[info exists ::env(BITNAMI_AUTOMATIC_BUILD)]} {
            if { [string first - $baseTarball] != -1 } {
                # Take the daily compiled tarball for testing
                set f [glob -nocomplain /opt/bitnami-stacks/dailytarballs/$baseName-*]
                if {[file exists $f]} {
                    message info2 "AUTOCOMPILED TARBALL FOUND AT $f"
                    return $f
                }
            }
        }  elseif {[info exists ::env(BITNAMI_AUTOMATIC_S3_BUILD)]} {
            if {[info exists ::env(BITNAMI_AUTOMATIC_S3_BUILD_FORCE)]} {
                # Fail only if the tarball we are looking for was compiled during the buildTarball step
                if {([info exists ::env(BUILD_TARBALLS_LIST)]) && (![string equal ${::env(BUILD_TARBALLS_LIST)} ""])} {
                    # Get built tarballs names and ensure unique values
                    set buildTarballsList [lsort -unique [split ${::env(BUILD_TARBALLS_LIST)} ","]]
                    puts "buildTarballsList: ${buildTarballsList}"
                    if {[xampptcl::util::listContains ${buildTarballsList} ${baseName}]} {
                        puts "The required tarball '${baseName}' was built in a previous step. We will look for that tarball instead"
                        foreach date {"now" "-1 day"} {
                            set date [clock format [clock scan $date] -format "%Y%m%d"]
                            set f [pathJoin /opt/bitnami-stacks/dailytarballs $baseName-$date.tar.gz]
                            if {[tarballExists $f]} {
                                return $f
                            }
                            set f [pathJoin s3://$::env(BITNAMI_AUTOMATIC_S3_BUILD) $baseName-$date.tar.gz]
                            if {[tarballExists $f]} {
                                return $f
                            }
                        }
                        # If not found yet
                        error "Tarball '${baseTarball}' (for baseName: '${baseName}') was not found in S3 '${::env(BITNAMI_AUTOMATIC_S3_BUILD)}' bucket but this tarball was built."
                    } else {
                        puts "Tarball '${baseName}' not found in '${buildTarballsList}'. Trying regular process to look for it."
                    }
                }
            }
        }
        foreach dir [tarballPath] {
            if {[info exists ::env(TEMP_TARBALLS_DIR)] && [file exists [pathJoin $::env(TEMP_TARBALLS_DIR) $baseTarball.tar.gz $be]]} {
                set f [pathJoin $::env(TEMP_TARBALLS_DIR) $baseTarball.tar.gz $be]
            } else {
                set f [pathJoin $dir $baseTarball.tar.gz $be]
            }
            if {[tarballExists $f]} {
                message info2 "Found tarball at $f"
                return $f
            }
        }
        if {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
            message info2 "Tarball $baseTarball ($baseName) not found - searched [llength [tarballPath]] directories"
        }
        message error "Tarball not found"
        exit 1
    }
}

::itcl::class product {
    inherit releasable
    markAsInternal
    public variable stack
    public variable dest
    public variable date
    public variable versionFile ""
    public variable versionPattern ""
    public variable versionMajorPattern ""
    public variable versionMinorPattern ""
    public variable versionPatchPattern ""
    public variable productGuid {}
    public variable unattendedPrefix {/opt/bitnami}
    # The disk was preformated before commit
    # Option 1: Growable (multiple 2GB files)
    public variable virtualDiskFormat 1
    public variable supportOVF 1
    public variable extraFilesList {}
    protected variable deleteRPath 1
    protected variable excludeRPathPattern {}
    protected variable stripBinaries 1
    protected variable excludeStripPattern {}
    protected variable deleteCompilationFiles 1
    protected variable substituteCommonFiles 0
    protected variable installAsUser {}
    protected variable baseStackinstallDir {}
    protected variable sourceApplicationDir {}
    protected variable tarOutputPrefix {}
    protected variable additionalComponents {}
    protected variable stackComponentsAlreadySetup 0
    # Cache variables
    protected variable builtComponentsList {}
    protected variable bundledComponentsList {}
    constructor {environment} {
        chain $environment
    } {
        if {[info exists appname]} {
            set fullname "${appname} packaged by Bitnami"
        }
        set dest [file join [$be cget -projectDir] pads]
        set date [clock seconds]
        set supportedHosts {}
        set supportedLinuxChroot "centos5"
    }
    public method supportsBuildApplicationTarball {} {
        set validProductTypes [list rubyProduct pythonProduct xamppProduct]
        set validProgramTypes [list rubyBitnamiProgram pythonBitnamiProgram]
        set skipProducts [list osqastack tracstack]
        set product [lindex [split [$this info class] :] end]
        # The following conditions need to be met:
        # 1: The product must not be blacklisted (e.g. tracstack does not have buildApplicationTarball)
        # 2: The product must have a valid type, listed above (e.g. "otherProduct" not allowed)
        # 3: The product must have a valid "application" class, and therefore cannot be an infrastructure stack
        # 4: The main program must have a valid type, listed above (e.g. "javaBitnamiProgram" not allowed)
        if {![elemMatchesFilters $product $skipProducts] && [elemIsA $this $validProductTypes] && [hasApplicationReference] && ![isInfrastructure]} {
            set program [[getApplicationClass] ::\#auto $be]
            return [expr {[elemIsA $program $validProgramTypes]}]
        }
        return 0
    }
    public method supportedPlatforms {} {
        set l {}
        # Native
        lappend l linux-x64 windows-x64 osx-x64

        return [lsort -unique $l]
    }

    public method setupStackComponents {} {
        if {!$stackComponentsAlreadySetup} {
            createStack
            modifyStackComponents
        }
        set stackComponentsAlreadySetup 1
    }
    public method getAllUsedClasses {} {
        set classList {}
        setupStackComponents
        $stack createStackComponents
        foreach component [$stack cget -components] {
            foreach parentClass [regsub -all {::} [[::itcl::local [lindex $component 0] #auto $be] info heritage] ""] {
                if {[lsearch $classList $parentClass] == -1} {
                    lappend classList $parentClass
                }
            }
        }
        return $classList
    }
    public method getInstallerProjectImageFiles {} {
        return [glob -nocomplain [file join [getImagesDirectory] *.png] [file join [getImagesDirectory] *.icns]]
    }

    public method getImagesDirectory {} {
        foreach d [list [file join [$be cget -projectDir] apps [getNameForPlatform] img]] {
            if {[file exists $d]} {
                return $d
            }
        }
    }
    public method getBaseNameForPlatform {} {
    }
    public method getFullNameForPlatform {} {
        if {[getBaseNameForPlatform] == "stack"} {
            # Stacks without any base component
            return [getBaseNameForPlatform]
        } else {
            # Note that Stackman Debian is based on Linux and not OS X
            set platformTarget [$be targetPlatform]
            if {[string match *solaris* $platformTarget]} {
                set platformTarget [string map {"-" ""} $platformTarget]
            } else {
                set platformTarget [string map {"-x" ""} $platformTarget]
            }
            return $platformTarget[getBaseNameForPlatform]
        }
    }
    public method createStack {} {
        if {![string match "::product" [$this info class]] && [$this cget -stack]=="<undefined>"} {
            set stack [createObject [getFullNameForPlatform] $be]
            set baseTarballIniFile [file join $::bitnami::rootPath metadata versions base_tarballs.ini]
            set baseTarballName [bitnami::iniFileGet ${baseTarballIniFile} [getBaseNameForPlatform] [$be targetPlatform] null]
            set defaultBaseTarballName [bitnami::iniFileGet ${baseTarballIniFile} [getBaseNameForPlatform] default null]
            if {$baseTarballName != "null"} {
              $stack configure -baseTarball [string map "@@target@@ [$be targetPlatform]" $baseTarballName]
            } elseif {$defaultBaseTarballName != "null"} {
              $stack configure -baseTarball [string map "@@target@@ [$be targetPlatform]" $defaultBaseTarballName]
            } elseif {[getFullNameForPlatform] != "stack"} {
              message error "Entry not found for [getBaseNameForPlatform] on platform [$be targetPlatform] in ${baseTarballIniFile}"
              exit 1
            }
        }
    }
    public method copyHtdocs {} {
        set htdocsOrig [$be cget -projectDir]/base/htdocs/htdocs-bitnami
        set htdocsFolder [$be cget -output]/apache2/htdocs
        set htdocsFiles [list bitnami.css index.html]
    }
    public method copyProjectFiles {} {
        lappend extraFilesList [list [getProjectFile]] [$be cget -output]
        foreach {fl location} $extraFilesList {
            foreach file $fl {
                if {[file isdirectory $file]} {
                    file delete -force $location/[file tail $file]
                }
                file copy -force $file $location
            }
        }
        foreach image [getInstallerProjectImageFiles] {
            file copy -force $image [file join [$be cget -output] images]
        }
        copyHtdocs
    }

    public method cleanUpBinaries {} {
        $be evalTimer "product.cleanUpBinaries" {
            message info "Calculating size of output before cleaning up binaries"
            set duFlags -s
            if {[$be targetPlatform] != "aix"} {
                append duFlags h
            }
            logexec du $duFlags [$be cget -output]

            message info "Starting to clean up binaries"
            if {[::xampptcl::util::isTargetPlatform "linux" $be] || [::xampptcl::util::isTargetPlatform "solaris" $be]} {
                if {$deleteRPath} {
                    runChrpath $be [$be cget -output] $excludeRPathPattern
                }
                if $stripBinaries {
                    runStrip $be [$be cget -output] $excludeStripPattern
                }
            }
            message info "Finished cleaning up binaries"

            message info "Calculating size of output after cleaning up binaries"
            logexec du $duFlags [$be cget -output]
        }
    }

    public method deleteCompilationFiles {} {
        $be evalTimer "product.deleteCompilationFiles" {
            if {$deleteCompilationFiles && [$be targetPlatform] != "aix" && [string match windows* [$be targetPlatform]] == 0 } {
                set excludePatternList [list *ImageMagick* */libruby*-static.a */libv8*.a]
                foreach f [glob -nocomplain -dir [$be cget -output] *] {
                    ::xampptcl::util::deleteFilesAccordingToPattern $f *.la $excludePatternList
                    ::xampptcl::util::deleteFilesAccordingToPattern $f *.a $excludePatternList
                    ::xampptcl::util::deleteFilesAccordingToPattern $f *.o $excludePatternList
                }
            }
        }
    }
    public method substituteCommonFiles {} {
        if {$substituteCommonFiles} {
            set toSubstituteFileList [::xampptcl::util::recursiveGlob [file join [$be cget -output] common] *]
            foreach f $toSubstituteFileList {
                if {![isBinaryFile $f] && ![file isdirectory $f] && [file type $f] != "link"} {
                    xampptcl::util::substituteParametersInFile $f \
                        [list [file join [$be cget -output] common] {@@XAMPP_COMMON_ROOTDIR@@}]
                    if [info exists ::opts(python.prefix)] {
                        xampptcl::util::substituteParametersInFile $f \
                            [list $::opts(python.prefix) {@@XAMPP_PYTHON_ROOTDIR@@}]
                    }
                }
            }
        }
    }


    protected method translateStack {translationLanguagesList} {
        $be evalTimer "product.translateStack" {
            set skipPoDiffCheck 0
            if {$translationLanguagesList == ""} {
                set translationLanguagesList "en"
                set skipPoDiffCheck 1
            }
            set translationDefaultLanguagesList {en es ja pt_BR ko zh_CN he de ro ru}
            message info "Translating Stack to: $translationLanguagesList"
            bitnami::copyCommonLanguageFiles $translationDefaultLanguagesList [$be cget -output]
            set localesDir [file join [$be cget -output] bitnami-locales]
            file mkdir $localesDir
            foreach component [$stack cget -components] {
                set c [$stack getComponentRef $component]
                if {[$c isa releasable] || [$c isa program]} {
                    set translationsInfo [$c copyTranslations $translationLanguagesList $localesDir]
                    foreach {code file} $translationsInfo {
                        xampptcl::translation::poFileAdd $file [$be cget -output]/bitnami-$code.po
                    }
                }
            }
            translator extract [$be cget -output]/project.xml --output-filename [$be cget -output]/project-temp.po --ignore-special-keys
            set result [translator diff [$be cget -output]/bitnami-en.po [$be cget -output]/project-temp.po --diff-checks new --ignored-keys [file join [toolsDir] translator ignore-strings-bitnami-en.po] ]
            if {[catch {set t [translator getcustomfilelist [$be cget -output]/project.xml]} kk]} {
                message error "Error checking included languages files in project [$be cget -output]/project.xml $kk"
                exit 1
                set t {}
            }
            array set includedTranslations [string trim $t]
            foreach langID $translationLanguagesList {
                foreach {k v} [xampptcl::translation::parsePoFile [$be cget -output]/project-temp.po] {
                    if {[string match "application_description|*" $k]} {
                        if {![info exists includedTranslations($langID)]} {
                            #puts "Untranslated key $k for language $langID, trying in default lang en"
                            set langID "en"
                        }
                        set found 0
                        foreach f $includedTranslations($langID) {
                            if {[xampptcl::translation::poKeyExists $f $k]} {
                                #puts "Found $k in $f!"
                                set found 1
                                break
                            }
                        }
                        if {$found == 0} {
                            message error "Untranslated key $k for language $langID"
                            exit 1
                        }
                    }
                }
            }
            if { $result != "" && $skipPoDiffCheck != 1} {
                message error "There are strings in the project that there are not in the language files"
                message error "translator diff-checks new [$be cget -output]/bitnami-en.po [$be cget -output]/project-temp.po --ignored-keys [file join [toolsDir] translator ignore-strings-bitnami-en.po]"
                puts "$result"
                if {![info exists ::env(BITNAMI_GENERATING_PO)]} {
                    exit 1
                }
            }
        }
    }
    public method quickpack {} {
        pack quickbuild
    }

    public method quickwrap {} {
        build
        generateInstaller quickbuild
    }
    public method debugpack {{type {build}}} {
        $be configure -enableDebugger 1
        pack $type
    }
    public method pack {{type {build}}} {
        $be evalTimer "product.pack" {
            switch -- $type {
                quickbuild {
                    quickbuild
                }
                default {
                    build
                }
            }
            generateInstaller $type
        }
        $be getTimerReport
    }
    public method downloadTranslations {} {
        checkPoFiles
    }
    public method copyStackDocumentation {} {
        if {![info exists stack]} {
            setupStackComponents
        }
        if {[$stack getProgramsArray]==""} {
            $stack createStackComponents
        }
        copyStackTxt
    }
    public method copyStackTxt {} {
        foreach file [glob [file join [$be cget -projectDir] apps $shortname *.txt]] {
            file copy -force $file [$be cget -output]
        }
        foreach c [$stack cget -components] {
            [$stack getComponentRef $c] buildReadme [file join [$be cget -output] README.txt]
        }
        buildReadme [file join [$be cget -output] README.txt]
        buildChangelog [file join [$be cget -output] changelog.txt]
    }
    public method getPreviousChangelogContent {changelog} {
        set versionCount 0
        set capturedChangelog ""
        foreach line [split $changelog "\n"] {
            if {[string match Version* $line]} {
                incr versionCount
            }
            if {$versionCount < 2} {
                if {![string match *CHANGELOG* $line]} {
                    append capturedChangelog "$line\n"
                }
            } else {
                break
            }
        }
        return [string trim $capturedChangelog "\n"]
    }


    public method buildReadme {readmeFile} {
        if {![info exists stack]} {
            setupStackComponents
        }
        if {[$stack getProgramsArray]==""} {
            $stack createStackComponents
        }
        foreach c [$stack cget -components] {
            [$stack getComponentRef $c] buildReadme $readmeFile
        }
        set date [clock format [clock seconds] -format {%Y-%m-%d}]
        if {[isTrial]} {
            set bitnamiproject_description {Bitnami was created to help spread the adoption of freely available, high quality web applications. Bitnami aims to make it easier than ever to discover, download and install software such as document and content management systems, wikis and blogging software.}
            set bitnami_distribution_license_description {}
        } else {
            set bitnamiproject_description {The Bitnami Project was created to help spread the adoption of freely available, high quality, open source web applications. Bitnami aims to make it easier than ever to discover, download and install open source software such as document and content management systems, wikis and blogging software.}
            set bitnami_distribution_license_description "$fullname is distributed for free under the Apache 2.0 license. Please see the appendix for the specific licenses of all open source components included."
        }

        xampptcl::util::substituteParametersInFile $readmeFile \
            [list {@@XAMPP_DATE@@} $date \
            {@@XAMPP_BITNAMIPROJECT_DESCRIPTION@@} [xampptcl::util::formatToScreen $bitnamiproject_description] \
            {@@XAMPP_BITNAMI_DISTRIBUTION_LICENSE_DESCRIPTION@@} [xampptcl::util::formatToScreen $bitnami_distribution_license_description] \
            {@@XAMPP_APPLICATION_DESCRIPTION@@} [xampptcl::util::formatToScreen [getDescription]] \
            {@@XAMPP_APPLICATION_VERSION@@} ${version}-${rev} \
            {@@XAMPP_APPLICATION_FULLNAME@@} $fullname \
            {@@XAMPP_APPLICATION_FULLNAME_UPPER@@} [string toupper $fullname] \
            {@@XAMPP_SHORTNAME@@} $shortname \
            {@@XAMPP_PRODUCT_NAME@@} $appname \
            {@@XAMPP_DEFAULT_USERNAME@@} $defaultApplicationUser \
            {@@XAMPP_DEFAULT_PASSWORD@@} $defaultApplicationPassword \
            {@@XAMPP_PROJECT_WEBSITE@@} $project_web_page \
            {@@XAMPP_REQUIRED_MEMORY@@} $requiredMemory \
            {@@XAMPP_REQUIRED_DISK_SIZE@@} $requiredDiskSize ]

        if {[string match windows* [$be cget -target]]} {
            foreach placeHolder {VARNISH RVM REDIS MEMCACHED} {
                xampptcl::util::substituteParametersInFileRegex $readmeFile [list [format {(\n\s*\-\s*[^\s]+)\s*@@XAMPP_%s_VERSION@@[^\n]*} $placeHolder] {\1 (Only supported on Linux and OS X)}]
            }
        }
    }
    public method validateChangelog {{f {}}} {
        if {$f == ""} {
            # get get a partially created changelog
            set f [getChangeLogFile]
            set pattern [format {.*?\s*Version:?\s*@@XAMPP_APPLICATION_VERSION@@\s+@@XAMPP_DATE@@[^\n]*\n+\s*(.*?)\s*(\nVersion:?|$)}]
        } else {
            # We expect a fully created changelog
            set pattern [format {.*?\s*Version:?\s*%s-%s[^\n]*\n+\s*(.*?)\s*(\nVersion:?|$)} $version $rev]
        }

        if {![file exist "$f"]} {
           error "Cannot find changelog file $f to validate"
        } else {
            set text [xampptcl::file::read $f]
            if {[regexp -- $pattern $text - currentVersionChanges]} {
                if {[string trim $currentVersionChanges] == ""} {
                    error "Empty changelog for current version"
                }
            } else {
                error "Cannot parse current changelog $f"
            }
        }
    }
    public method getChangelogLatestContent {} {
        file mkdir [$be cget -output]
        foreach file [glob [file join [$be cget -projectDir] apps $shortname *.txt]] {
            file copy -force $file [$be cget -output]
        }
        # Get necessary metadata
        set metadataOutputDir /tmp/metadata_dir_[xampptcl::util::uniqid]_tmp
        getMetadataForChangelog $metadataOutputDir

        # Build temporal changelog based on the metadata
        set changelogContent [buildTempChangelog $metadataOutputDir]

        message info "-----CHANGELOG LATEST CONTENT-----"
        puts $changelogContent
    }
    public method getChangelogCurentVersionContent {} {
        set changelogRepoFile [getChangeLogFile]
        set changelogContent [xampptcl::file::read $changelogRepoFile]

        set versionCount 0
        set capturedChangelog ""
        foreach line [split $changelogContent "\n"] {
            if {[string match "Version $version-$rev*" $line]} {
                incr versionCount
             } elseif {$versionCount == 1 && [string match Version* $line]} {
                incr versionCount
            }
            if {$versionCount == 1} {
                if {![string match *CHANGELOG* $line]} {
                    append capturedChangelog "$line\n"
                }
            } elseif {$versionCount > 1} {
                break
            }
        }
        if {$capturedChangelog != ""} {
            message info "-----CHANGELOG CONTENT FOR $version-$rev-----"
            puts $capturedChangelog
        } else {
            message warning "-----$version-$rev NOT FOUND IN CHANGELOG-----"
        }
    }

    public method buildTempChangelog {output} {
        set platform [$be targetPlatform]
        set metadataFound 0
        set generatedMetadataFile [file join $output [bitnamiPortalKey] $version-$rev $platform-0.xml]
        set lastReleasedMetadataFile [file join $output [bitnamiPortalKey] $version-$rev lastReleased$platform-0.xml]

        if {![file exists $generatedMetadataFile]} {
            message warning "Error getting last generated metadata"
        } else {
            if {![file exists $lastReleasedMetadataFile]} {
                if {![file exists [file join $output [bitnamiPortalKey] $version-$rev lastReleasedlinux-x64-0.xml]]} {
                    message warning "Error getting last released metadata file"
                } else {
                    set lastReleasedMetadataFile [file join $output [bitnamiPortalKey] $version-$rev lastReleasedlinux-x64-0.xml]
                    set metadataFound 1
                }
            } else {
                set metadataFound 1
            }
        }

        set changelogDiff ""
        if {$metadataFound} {
            set changelogDiffCommand "diff --unified=0 $lastReleasedMetadataFile $generatedMetadataFile | tail -n +5 | grep ^+ | grep main_component=.true. | sed -n {s/^.*version=\"\\(.*\\)\".*type.*fullname=\"\\(.*\\)\".*$/* Updated \\2 to \\1/p}"
            if {[catch {set changelogDiff [eval exec $changelogDiffCommand]} kk]} {
                if {$::errorCode != "NONE" && [lindex [split $::errorCode] end] != "1"} {
                    message warning "There was an error executing command \"$changelogDiffCommand\". ERROR $::errorCode"
                    set changelogDiff "git diff command failed the changelog will not change."
                } else {
                    # Return code was 1, but it means there are differences
                    # Remove spurious 'child process exited abnormally' added by exec
                    regsub -all {child process exited abnormally} $kk {} changelogDiff
                }
            }
        }
        set changelogBlockMessage ""

        # Get existing changelog code
        set changelogRepoFile [getChangeLogFile]
        set changelogTempFile [file join /tmp changelog-[bitnamiPortalKey]]
        if {[file exists $changelogRepoFile]} {
            file copy -force $changelogRepoFile $changelogTempFile
            set changelogContent [xampptcl::file::read $changelogTempFile]
            set capturedChangelog [getPreviousChangelogContent $changelogContent]
            set previousChangelogContent ""
            foreach line [split $capturedChangelog "\n"] {
                if {! [string match Version* $line]} {
                    append previousChangelogContent "$line\n"
                }
            }
        }

        # Generate changelog based on the metadata
        append changelogBlockMessage "\n"
        append changelogBlockMessage $previousChangelogContent
        append changelogBlockMessage [string trim $changelogDiff "\n"]

        # Remove duplicated components
        set lines [split $changelogBlockMessage "\n"]
        set componentList {}
        set filteredChangelogContent ""
        # Iterate all the lines
        # If the regexp matches check if that component has been already added
        # If already added, skip it. If not append to the component list
        # If the line has not been skipped, append it to the result
        foreach line $lines {
            if {[regexp -- {^.*Updated\s+(.*)\s+to} $line - component]} {
                if {[xampptcl::util::listContains $componentList $component]} {
                    continue
                } else {
                    lappend componentList $component
                }
            }
            append filteredChangelogContent $line \n
        }

        # Remove duplicated lines
        set changelogFinalMessage ""
        array set seen {}
        foreach line [split $filteredChangelogContent "\n"] {
            # blank lines should be avoided
            if {[string length [string trim $line]] == 0} {
                continue
            }
            # create the "key" for this line
            regsub {\mPoint \d+} $line {} key
            regsub {\mcolor=\w+} $key {} key
            # print the line only if the key is unique
            if { ! [info exists seen($key)]} {
                append changelogFinalMessage "$line\n"
                set seen($key) true
            }
        }

        # Remove last \n
        regexp -- {(.*)\n} $previousChangelogContent - previousChangelogContent
        regexp -- {(.*)\n} $changelogFinalMessage - changelogFinalMessage
        # Substitute the changelog content in the temporal file
        xampptcl::util::substituteParametersInFileRegex $changelogTempFile \
            [list {Version\s+?@@XAMPP_APPLICATION_VERSION@@\s+?@@XAMPP_DATE@@(.*?)(Version|$)} "Version @@XAMPP_APPLICATION_VERSION@@      @@XAMPP_DATE@@\n$changelogFinalMessage\n\n\\2"] 1
        message default $changelogFinalMessage
        return $changelogFinalMessage
    }

    public method getMetadataForChangelog {metadataOutputDir} {
        # Generate necessary metadata to create the changelog
        set targetMetadataFilename "[$be targetPlatform]-0"
        generateReleaseData --kind stack --output $metadataOutputDir --read-file-properties 0 --read-changelog 0

        # Avoid issues with S3 command
        catch {unset ::env(LD_LIBRARY_PATH)}

        # Get metadata from latest version
        set releaseBucketApplicationPath "s3://apachefriends/files/stacks/[bitnamiPortalKey]"
        set directoryList [exec /usr/bin/s3cmd ls "${releaseBucketApplicationPath}/"]

        # Get previous published version
        set publishedVersions ""
        if { [catch {set publishedVersions [getPublishedVersions]}] } {
            if {[getIfPublished]} {
                message error "Not found published versions for a published app."
                exit 1
            } else {
                message warning "Not found published versions. App not published"
            }
        }

        # Get metadata is previous published versions were found
        if {$publishedVersions != ""} {
            if { [llength $publishedVersions] > 1 } {
                set majorVersion "[lindex [split $version .] 0].[lindex [split $version .] 1]"
                set foundSameMajor 0
                foreach publishedVersion [lsort $publishedVersions] {
                    set majorVersionPublished "[lindex [split $publishedVersion .] 0].[lindex [split $publishedVersion .] 1]"
                    if {[::xampptcl::util::compareVersions $majorVersion $majorVersionPublished] == 0} {
                        set foundSameMajor 1
                        set lastReleasedVersion $publishedVersion
                    }
                    if {!$foundSameMajor} {
                        set lastReleasedVersion $publishedVersion
                    }
                }
            } else {
                set lastReleasedVersion $publishedVersions
            }

            # Get metadata from latest released version
            set latestReleasedVersionDir [exec echo "$directoryList" | grep DIR | egrep "${lastReleasedVersion}" | tail -1 | awk {{print $2}}]
            set lastReleasedMetadataRegex [regsub -all "\[0-9\]+.xml" $targetMetadataFilename "\[0-9\]+.xml"]

            # Fix for new revisions of Blacksmith assets
            set latestReleasedVersionDirContent [exec /usr/bin/s3cmd ls "$latestReleasedVersionDir"]
            set completeVersion [file tail $latestReleasedVersionDir]
            set latestVersion [lindex [split $completeVersion -] 0]
            set latestRevision [lindex [split $completeVersion -] 1]
            while {$latestRevision > 0} {
                if {![string match *$lastReleasedMetadataRegex* $latestReleasedVersionDirContent]} {
                    message warning "* S3 path for version $latestVersion-$latestRevision does not contain the correct metadata"
                    message warning "It is probably due to a BlackSmith release"
                    incr latestRevision -1
                    set latestReleasedVersionDir "$releaseBucketApplicationPath/$latestVersion-$latestRevision/"
                    set latestReleasedVersionDirContent [exec /usr/bin/s3cmd ls "$latestReleasedVersionDir"]
                    message warning "Checking S3 path for version $latestVersion-$latestRevision"
                } else {
                    break
                }
            }

            if { [catch {set lastReleasedMetadata [exec /usr/bin/s3cmd ls "$latestReleasedVersionDir" | grep -P $lastReleasedMetadataRegex | tail -1 | awk {{print $4}}]} ]} {
                message warning "File for [$be targetPlatform] could not be found from s3. Trying with linux-x64"
                set targetMetadataFilename "linux-x64-0"
                set lastReleasedMetadataRegex [regsub -all "\[0-9\]+.xml" $targetMetadataFilename "\[0-9\]+.xml"]
                set lastReleasedMetadata [exec /usr/bin/s3cmd ls "$latestReleasedVersionDir" | grep -P $lastReleasedMetadataRegex | tail -1 | awk {{print $4}}]
            }

            set lastReleasedMetadataFile [file join $metadataOutputDir [bitnamiPortalKey] $version-$rev "lastReleased$targetMetadataFilename.xml"]
            if { [catch {exec /usr/bin/s3cmd get --force "$lastReleasedMetadata" ${lastReleasedMetadataFile}} downloadResult] } {
                message error "File could not be downloaded from s3: $downloadResult"
            }
        }
    }

    public method buildChangelog {{changelogFile {}}} {
        if { $changelogFile == "" } {
            set changelogFile [file join [$be cget -output] changelog.txt]
        }
        # Get necessary metadata
        set metadataOutputDir /tmp/metadata_dir_[xampptcl::util::uniqid]_tmp
        message info "Getting metadata to create changelog"
        getMetadataForChangelog $metadataOutputDir

        # Build temporal changelog based on the metadata
        message info "Building changelog based on the metadata"
        buildTempChangelog $metadataOutputDir

        set date [clock format [clock seconds] -format {%Y-%m-%d}]
        # If there is an entry like "Version\s+@@XAMPP_APPLICATION_VERSION@@\s+@@XAMPP_DATE@@"
        # then the changelog needs to be built
        set changelogTempFile [file join /tmp changelog-[bitnamiPortalKey]]
        if {![file exists $changelogTempFile]} {
            message warning "\nError getting temporal changelog file. Using $changelogFile instead.\n"
            set changelogContent [xampptcl::file::read $changelogFile]
        } else {
            set changelogContent [xampptcl::file::read $changelogTempFile]
        }

        if {[regexp -- {(^.*?\n\s*)(Version\s+@@XAMPP_APPLICATION_VERSION@@\s+@@XAMPP_DATE@@[^\n]*\n)(.*?)(Version.*|)$} $changelogContent - head lastEntryHead lastEntryContent oldEntries]} {
            set trimmedLastEntryContent [string trim $lastEntryContent]
            if {$trimmedLastEntryContent != ""} {
                xampptcl::file::write $changelogFile "$head$lastEntryHead$trimmedLastEntryContent\n\n$oldEntries"
            }

        # Fill the placeholders in the placeholder line to make it look like a legit changelog
        xampptcl::util::substituteParametersInFile $changelogFile \
           [list {@@XAMPP_DATE@@} $date \
               {@@XAMPP_APPLICATION_VERSION@@} ${version}-${rev}]
        }
    }
    public method setStackProductGuid {} {
        ::xampptcl::util::substituteParametersInFile [file join [$be cget -output] $projectFile] \
            [list {@@XAMPP_GUID@@} ${productGuid}]
    }
    public method setStackVersion {} {
        ::xampptcl::util::substituteParametersInFile [file join [$be cget -output] $projectFile] \
            [list {@@XAMPP_VERSION@@} ${version}-${rev}]
    }
    public method setStackFullname {} {
        # In our tests it is easier to detect @@ than an empty fullname
        if { $fullname != ""} {
          ::xampptcl::util::substituteParametersInFile [file join [$be cget -output] $projectFile] \
            [list {@@XAMPP_APPLICATION_FULLNAME@@} $fullname]
        }
    }
    public method setStackInstallerName {} {
        if {[isBitnami]} {
            lappend setvars "project.installerFilename=[$this getInstallerName]"
        }
    }
    public method extractBaseTarball {{dest {}}} {
        $be evalTimer "product.extractBaseTarball" {
            if {[$be cget -buildType]=="fromTarball" && [$stack cget -baseTarball]!=""} {
                set tarballPath [$stack findTarball]
                message info "Uncompressing Base System from Tarball: $tarballPath"
                if {[catch {
                    if {[$be cget -target]=="osx-x64"} {
                        set dest [file join [$be cget -output] xamppfiles]
                    }
                    if {$dest == ""} {
                        set dest [$be cget -output]
                    }
                    file mkdir $dest
                    if { [info exists ::env(TEMP_TARBALLS_DIR)] } {
                        file copy -force $tarballPath $::env(TEMP_TARBALLS_DIR)
                    }
                    puts [eval {exec tar zxf $tarballPath -C $dest}]} err]} {
                    if {$::errorCode != "NONE"} {
                        message error $err
                    } else {}
                }
            }
        }
    }
    public method prepareStackComponents {} {
        # Keep a copy of the PATH, which will be modified during component building
        set oldPath $::env(PATH)
        $be setupEnvironment
        $be setupDirectories
        setupStackComponents
        extractBaseTarball
        $stack createStackComponents
        $stack buildComponents [$stack componentsToBuild]
        # Restore the PATH not to interfere with system components (T15293)
        set ::env(PATH) $oldPath
    }
    public method modifyStackComponents {} {}
    public method prepareOutputFiles {} {
        prepareStackComponents
        checkVersion [$this cget -versionFile] [$this cget -versionPattern] [$this cget -versionMajorPattern] [$this cget -versionMinorPattern] [$this cget -versionPatchPattern]
        $stack copyProjectFiles
        foreach c [$stack componentsToBuild] {
            [$stack getComponentRef $c] preparefordist
        }
        copyProjectFiles
        copyStackDocumentation
        $stack preparefordist
        preparefordist
        $stack prepareConfiguredXmlFiles
        foreach directory [::xampptcl::util::recursiveGlob [$be cget -output] *CVS] {
            file delete -force $directory
        }
        setStackVersion
        setStackFullname
        setStackInstallerName
        setStackProductGuid
        file rename [file join [$be cget -output] $projectFile] [file join [$be cget -output] project.xml]
    }
    public method build {} {
        $be evalTimer "product.build" {
            prepareOutputFiles
            $stack reportUsedComponents $shortname
            translateStack $translationLanguagesList
        }
        if {[$be cget -action] == "build"} {
            $be getTimerReport
        }
    }
    public method postBuild {} {
        message info "Running Post Build actions"
        cd [$be cget -output]
        set fileList [glob -type f *.xml]
        set requiredXmls [lsort [xampptcl::util::getAllRequiredXmlFiles project.xml]]
        foreach f $fileList {
            if {![xampptcl::util::listContains $requiredXmls [file tail $f]]} {
                file delete -force $f
            }
        }
    }
    public method quickbuild {} {
        $be evalTimer "product.quickbuild" {
            $be setupEnvironment
            setupStackComponents
            $stack createStackComponents
            foreach c [$stack cget -components] {
                [$stack getComponentRef $c] copyXmlFiles $stack
            }
            copyProjectFiles
            foreach directory [::xampptcl::util::recursiveGlob [$be cget -output] *CVS] {
                file delete -force $directory
            }
            $stack prepareConfiguredXmlFiles
            setStackVersion
            setStackFullname
            setStackInstallerName
            setStackProductGuid
            file delete [file join [$be cget -output] project.xml]
            file rename [file join [$be cget -output] $projectFile] [file join [$be cget -output] project.xml]
        }
        $be getTimerReport
    }
    public method preparefordist {} {
        if {[$be cget -target]=="osx-x86"} {
            ::xampptcl::util::substituteParametersInFile [file join [$be cget -output] $projectFile] \
                [list {-${platform_name}-} {-${platform_name}-x86-}]
            $be configure -setvars "[$be cget -setvars] node_osx_arch=x86"
        } elseif {[$be cget -target]=="osx-ppc"} {
            ::xampptcl::util::substituteParametersInFile [file join [$be cget -output] $projectFile] \
                [list {-${platform_name}-} {-${platform_name}-powerpc-}]
        } elseif {[$be cget -target]=="osx-x64"} {
            $be configure -setvars "[$be cget -setvars] python_osx_arch=x86_64 ruby_osx_arch=x86_64 java_osx_arch=x86_64"
            ::xampptcl::util::substituteParametersInFile [file join [$be cget -output] $projectFile] \
                [list {-${platform_name}-} {-${platform_name}-x86_64-}]
        }

        xampptcl::util::substituteParametersInFile [$be cget -output]/$projectFile \
            [list {@@BUILD_BITROCK_FULLNAME@@} $fullname \
            {@@BUILD_BITROCK_SHORTNAME@@} $shortname \
            {@@BUILD_BITROCK_VERSION@@} $version ]

        if {[string match windows* [$be cget -target]]} {
            if { [file exists [$be cget -output]/README.txt] } {
                foreach placeHolder {VARNISH RVM REDIS MEMCACHED} {
                    xampptcl::util::substituteParametersInFileRegex [$be cget -output]/README.txt [list [format {(\n\s*\-\s*[^\s]+)\s*@@XAMPP_%s_VERSION@@[^\n]*} $placeHolder] {\1 (Only supported on Linux and OS X)}]
                }
            }
        }
        if { [file exists [file join [$be cget -output] apache2 htdocs]] && [isBitnami] } {
            file copy -force [file join [$be cget -projectDir] base htdocs htdocs-bitnami favicon.ico] [file join [$be cget -output] apache2 htdocs ]
        }
        if { [file exists [file join [$be cget -output] banner htdocs]] && [isBitnami] } {
            file copy -force [file join [$be cget -projectDir] base htdocs htdocs-bitnami favicon.ico] [file join [$be cget -output] banner htdocs ]
        }
    }
    public method buildComponents {componentList} {
        $be configure -buildType fromSource
        foreach c [$stack cget -components] {
            $stack removeComponents $c
        }
        foreach c $componentList {
            $stack addComponents $c
        }
        $be setupEnvironment
        $be setupDirectories
        setupStackComponents
        $stack createStackComponents
        $stack buildComponents [$stack componentsToBuild]
    }
    public method buildComponentsWithPreparefordist {componentList} {
        buildComponents $componentList
        foreach c [$stack componentsToBuild] {
            [$stack getComponentRef $c] preparefordist
        }
        $stack preparefordist
        preparefordist
    }
    public method buildTarball {} {
        $be evalTimer "product.buildTarball" {
            $be setupEnvironment
            if {[$be cget -buildType]!="continueAt"} {
                $be setupDirectories
            }
            setupStackComponents
            $stack createStackComponents
            set components [$stack componentsToBuild]
            if {[$be cget -buildType]=="continueAt"} {
                puts "Info: Continues compiling at [$be cget -continueAtComponent]"
                # Find the component by its name, not its entire metadata (e.g. "component -version 1.0")
                set componentListByName {}
                foreach c $components {
                   set componentListByName [lappend componentListByName [lindex $c 0]]
                }
                set pos [lsearch -exact $componentListByName [$be cget -continueAtComponent]]
                if {$pos != -1} {
                    set components [lrange $components $pos end]
                } else {
                    error "Component '[$be cget -continueAtComponent]' not found in '$components'"
                }
            }
            $stack buildComponents $components
            foreach c [$stack cget -components] {
                $be evalTimer "preparefordist.$c" {
                    [$stack getComponentRef $c] preparefordist
                }

                $be evalTimer "removeDocs.$c" {
                    [$stack getComponentRef $c] removeDocs
                }
            }
            if ![string match windows* [$be targetPlatform]] {
                $be evalTimer "product.fixAbsoluteSymbolicLinks" {
                    fixAbsoluteSymbolicLinks [$be cget -output]
                }
            }
            deleteCompilationFiles
            cleanUpBinaries
            substituteCommonFiles
            compressTarball
        }
        $be getTimerReport
    }
    public method compressTarball {} {
        $be evalTimer "product.compressTarball" {
            cd [$be cget -output]
            set timeStamp [clock format [clock seconds] -format %Y%m%d]
            set tarballNameRoot [$stack cget -baseTarball]
            set newTarballName [regsub -- {-\d*$} $tarballNameRoot {}]-$timeStamp
            logexec tar cf [file join [$be cget -tmpDir] $newTarballName].tar .
            logexec gzip [file join [$be cget -tmpDir] $newTarballName].tar
            file rename -force [file join [$be cget -tmpDir] $newTarballName].tar.gz [$be cget -output]
            message info "Tarball location: [file join [$be cget -output] $newTarballName.tar.gz]"
        }
    }
    public method getBaseTarball {} {
        createStack
        puts [$stack cget -baseTarball]
    }
    public method supportedChroot {} {
        return $supportedLinuxChroot
    }
    public method getSupportedChroot {} {
        puts [supportedChroot]
    }
    public method supportedOSXChroots {} {
        return $supportedHosts
    }
    public method getSupportedOSXChroots {} {
        puts [supportedOSXChroots]
    }
    public method getStackVersion {} {
        createStack
        puts $version-$rev
    }
    public method getInstallerName {{type stack}} {
        if {[info exists ::env(BITNAMI_INSTALLER_NAME)]} {
            set name $::env(BITNAMI_INSTALLER_NAME)
        } else {
            set name [[$be cget -product] cget -installerName]
            set installerPlatformName [getPlatformName [$be cget -target]]
            if {$name != ""} {
                # TODO: any better solution for a module installer here?
                if {$type == "module"} {
                    set suffix "-$installerPlatformName-installer"
                    if {![regexp -- "-module${suffix}\\." $name]} {
                        regsub -- "${suffix}\\.(...)\$" $name "-module${suffix}.\\1" name
                    }
                }
            } else {
                set name [getProductFileName $type [$be cget -target]]
                if {[string match "stackman*" [$be cget -platformID]]} {
                    append name -vm
                } else {
                    append name -installer
                }
                append name .[$be getOutputSuffix]
            }
        }
        return $name
    }

    public method getStackInstallerName {} {
        createStack
        puts [getInstallerName]
    }

    public method baseTarballOutputDir {} {
        if {[$be cget -baseTarballOutputDir] != ""} {
            set dir [$be cget -baseTarballOutputDir]
            puts $dir
            return $dir
        } else {
            set dir [getOutputDirectory]
            return $dir
        }
    }

    public method getOutputDirectory {} {
        puts [$be cget -output]
        return [$be cget -output]
    }

    public method getApplicationTarballName {} {
        if {[supportsBuildApplicationTarball]} {
            puts [[[getApplicationClass] ::\#auto $be] getApplicationTarballName]
        }
    }

    public method gemOpts {} {
        setupStackComponents
        $stack createStackComponents
        puts "\n$fullname Components\n"
        xampptcl::file::write /tmp/config {}
        set componentList {}
        foreach c [$stack cget -components] {
            set componentRef [$stack getComponentRef $c]
        }
    }
    public method getComponents {} {
        set result {}
        if { $builtComponentsList != {} } {
            # Restore from cache
            set result $builtComponentsList
        } else {
            $be setupEnvironment
            setupStackComponents
            $stack createStackComponents 0
            # $stack setAndCreateStackComponentsDependencies
            set result {}
            foreach c [$stack cget -components] {
                lappend result [$stack getComponentRef $c]
            }
            foreach c [$stack cget -componentsDependencies] {
                lappend result [$stack getComponentRef $c]
            }
            # Save the result in a global variable for cache
            set builtComponentList $result
        }
        return $result
    }

    public method logComponents {} {
        puts "\n$fullname Components\n"
        foreach c [getComponents] {
            if {[$c isa builddependency]} {
                message info "[$c cget -name] [$c cget -version] (build-time only)"
            } else {
                message info "[$c cget -name] [$c cget -version]"
            }
        }
    }
    public method getBasePlatformName {} {
        puts "$fullname Base Platform Name:"
        set basePlatformName [getBaseNameForPlatform]
        puts "$basePlatformName"
    }
    public method getStackDependencyList {} {
        set projectXMLFiles [getXMLFilesIncludedInProject]
        message info2 "Looking for stack dependencies (Ruby gems)"
        # List of stack dependencies
        set dependencyList {}
        # Skipped paths will AVOID failure if the path was not added to getGemPaths
        # They will also NOT be checked for licenses
        set skippedPaths [getBaseTarballPlatformDependencyPathsToSkip]
        # Paths that are not hardcoded/whitelisted WILL CAUSE FAILURE, and detected below
        # They MAY be checked for licenses (unless skipped in 'skippedPaths')
        set hardcodedPaths {}
        # Will be used to verify that no additional paths were found
        # Get key-value list for platform-specific dependencies (e.g. NodeJS modules or Ruby Gems)
        foreach component [$stack componentsToBuild] {
            set c [$stack getComponentRef $component]
            set dependencyList [concat $dependencyList [$c getPlatformDependencyList]]
            # Whitelist individual components' dependency directories
            # Some paths we just might want to ignore (e.g. directories named 'node_modules' but that doesn't contain modules)
            set skippedPaths [concat $skippedPaths [$c getPlatformDependencyPathsToSkip]]
        }
        # Get key-value list for dependencies in base tarballs
        set baseTarballGemPaths [getBaseTarballGemPaths]
        if {![isBitnami]} {
            return
        }
        # Validate that we are aware of all dependency folders
        # We will hardcode ALL paths to dependencies (NodeJS modules, gems...) to avoid false positives
        # However, this check will allow us to detect any missing path dynamically
        message info2 "Looking for undeclared dependency folders"
        # Dynamically find dependency directories
        set foundDependencyFolders [findPlatformDependencyFolders]
        # Merge the list paths we know are OK (hardcodedPaths), with the ones we know we want to skip (skippedPaths)
        set hardcodedPaths [concat $hardcodedPaths $baseTarballGemPaths]
        if {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
            # Minor tweak to reduce the list size (drastically)
            set foundPaths [listFilter $foundDependencyFolders {*/gems/*/gems}]
            foreach var {found hardcoded skipped} {
                if {[set ${var}Paths] != ""} {
                    message warning "\nFull list of ${var} paths:\n- [join [lsort [set ${var}Paths]] "\n- "]"
                }
            }
        }
        # Subtract hardcoded and skipped paths from the ones we found dynamically, to detect missing paths
        set filteredDependencyFolders [lsort [listFilter $foundDependencyFolders [concat $hardcodedPaths $skippedPaths]]]
        if {$filteredDependencyFolders != ""} {
            message warning "The following paths contain platform dependencies and need to be added to 'getPlatformDependencyList':\n- [join $filteredDependencyFolders "\n- "]\nYou can remove these paths in 'getPlatformDependencyPathsToSkip'."
        }
        # If everything went well, return a list of dictionaries with the metadata for all found dependencies
        return $dependencyList
    }
    # Hardcoded paths to base tarball's Gem paths
    protected method getBaseTarballGemPaths {} {
        set p {}
        lappend p [file join [$be cget -output] ruby lib ruby gems ?.?.? gems]
        lappend p [file join [$be cget -output] ruby lib ruby gems ?.?.? cache]
        lappend p [file join [$be cget -output] gems]
        return $p
    }
    protected method getMissingStackDependenciesError {missingComponents} {
        set sampleMetadata ""
        set errorText "The following components could not be found in any metadata file:\n"
        set alreadyReportedComponents {}
        foreach c $missingComponents {
            if {[xampptcl::util::listContains $alreadyReportedComponents [$c getUniqueIdentifier]]} {
                # We don't want to report a specific component twice
                continue
            }
            lappend alreadyReportedComponents [$c getUniqueIdentifier]
            append errorText "- [$c getUniqueIdentifier]\n"
            append sampleMetadata "\n\[[$c getUniqueIdentifier]\]\n"
            foreach {metadataKey objKey} {url downloadUrl licenses licenseNotes} {
                # Show license (even if empty) and any field that may include metadata
                if {[$c cget -$objKey] != "" || $metadataKey == "licenses"} {
                    append sampleMetadata "$metadataKey=[$c cget -$objKey]\n"
                }
            }
            # TODO Find some way of detecting the license URL
            # append sampleMetadata "license_url=\n"
        }
        append errorText "\nPlease find below a sample of the needed metadata, please review and complete each entry:\n$sampleMetadata"
        return $errorText
    }
    public method checkVersion {{vFile {}} {vVersionPattern {}} {vMajorPattern {}} {vMinorPattern {}} {vPatchPattern {}}} {
        if [string equal "" ${vFile}] {
            message info "No file provided for checking version. It is necessary to validate the version."
        } elseif {[file exists $vFile]} {
            if { $vVersionPattern != "" } {
                set vPattern $vVersionPattern
                message info "Checking version $version in $vFile with this pattern:"
                message info "$vPattern"
                if {[catch {set matchVersion [exec cat "$vFile" | grep "$vPattern"]} kk]} {
                    message error "Error validating version $version in $vFile"
                    exit 1
                } else {
                    message info "Version validated: $matchVersion"
                }
            } elseif { $vMajorPattern != "" || $vMinorPattern != "" || $vPatchPattern != ""} {
                foreach vPattern "${vMajorPattern} ${vMinorPattern} ${vPatchPattern}" {
                    message info "Checking version $version in $vFile with this pattern:"
                    message info "$vPattern"
                    if {[catch {set matchVersion [exec cat "$vFile" | grep $vPattern]} kk]} {
                        message error "Error validating version $version in $vFile"
                        exit 1
                    } else {
                        message info "Version validated: $matchVersion"
                    }
                }
            } else {
                message info "Version validated: No pattern provided for checking version."
                message info "We assume you only want to check the existence of the file $vFile."
            }
        } else {
            message error "File $vFile does not exists."
            exit 1
        }
    }
    protected method getPlatformDependencyFolderPatterns {} {
        set p {}
        # Ruby Gems are located inside a directory named "gems", or in "cache" directories (Windows)
        lappend p */gems */vendor/cache */gems/?.?.?/cache
        return $p
    }
    # Skipped paths will NOT fail if not added to getGemPaths
    # They will also NOT be checked for licenses
    protected method getBaseTarballPlatformDependencyPathsToSkip {} {
        set p {}
        # Don't include "gems" directories inside another one (e.g. Diaspora dependencies)
        lappend p */gems/*/gems
        # Avoid the following directory, since Ruby's gems are located inside gems/VERSION/gems
        lappend p */ruby/lib/ruby/gems
        return $p
    }
    # Find all dependency folders, which we will use to validate that we are aware of all of them
    protected method findPlatformDependencyFolders {} {
        set l {}
        set patterns [getPlatformDependencyFolderPatterns]
        foreach pattern $patterns {
            # Find all directories following the blacklist pattern
            set candidates [xampptcl::util::recursiveGlob [$be cget -output] $pattern]
            foreach candidateDir $candidates {
                # Don't add empty directories
                set gemsInCandidateDir [glob -nocomplain $candidateDir/*]
                if {$gemsInCandidateDir != "" && $gemsInCandidateDir != "NOTEMPTY"} {
                    lappend l $candidateDir
                }
            }
        }
        return $l
    }
    public method getBundledComponents {} {
        if { $bundledComponentsList != {} } {
            # Restore from cache
            set result $bundledComponentsList
        } else {
            set builtComponentsList [getComponents]
            set result {}
            set uniqueListNotIncluded {}
            set xmlFilesIncludedInProject [getXMLFilesIncludedInProject]
            foreach e [lsort -unique $builtComponentsList] {
                set class [lindex [split [$e info class] :] end]
                if { [$e getMainComponentXMLName] != "" } {
                    if {[isComponentIncluded $e $xmlFilesIncludedInProject]} {
                        if {![info exists done($class)]} {
                            set done($class) 1
                            lappend result $e
                        }
                    } elseif {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                        lappend uniqueListNotIncluded $e
                    }
                } else {
                    if {![info exists done($class)]} {
                        set done($class) 1
                        lappend result $e
                    }
                }
            }

            if {[info exists ::env(XAMPPDEBUG)] || [info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                message info2 "Not bundled stack components: $uniqueListNotIncluded"
            }
            # Save the result in a global variable for cache
            set bundledComponentsList $result
        }

        return $result
    }
    public method isComponentIncluded {component xmlFilesIncludedInProject} {
        if { $builtComponentsList == {} } {
            set builtComponentsList [getComponents]
        }
        # Get all components in the base tarball and then check the component against that list
        if { [$component cget -isReportableComponent] && ![$component isInternal] &&  ![$component isa builddependency] } {
            if {![lsearch $builtComponentsList $component] == -1} {
                return 0
            } else {
                if {[$this isMainComponent $component]} {
                    # Present and it is a main component, check against the xml files included in the project
                    set c [$component getMainComponentXMLName]
                    if {[::xampptcl::util::listContains $xmlFilesIncludedInProject "$c.xml"]} {
                        return 1
                    } else {
                        return 0
                    }
                } else {
                    # Present and it is not a main component. Assume it is included because there is no easy way of checking it
                    return 1
                }
            }
        } else {
            return 0
        }
    }
    public method getUniqueStackDependencyList {} {
        set depList {}
        set objList {}
        foreach depObj [getStackDependencyList] {
            set depName [$depObj getUniqueIdentifier]
            if {[xampptcl::util::listContains $depList $depName]} {
                # We don't want to show dependencies twice
                continue
            }
            lappend depList [$depObj getUniqueIdentifier]
            lappend objList $depObj
        }
        return $objList
    }
    # Also includes dependencies like NPM modules and Gems
    public method getBundledComponentsAndDependencies {} {
        return [concat [getBundledComponents] [getUniqueStackDependencyList]]
    }
    public method logBundledComponents {} {
        puts "\n$fullname Bundled Components\n"
        foreach c [getBundledComponents] {
            message info "[$c cget -name] [$c cget -version]"
        }
    }
    public method logBundledComponentsAndDependencies {} {
        puts "\n$fullname Bundled Components and Dependencies\n"
        foreach c [getBundledComponentsAndDependencies] {
            message info "[$c cget -name] [$c cget -version]"
        }
    }

    public method checkLicenses {} {
        set missingLicenses {}
        set errors {}
        array set reported {}
        set reportedList {}
        set csvEntries {}
        prepareStackComponents
        set objList [getBundledComponentsAndDependencies]
        # Process the list of objects and dependencies
        foreach obj $objList {
            set class [$obj getUniqueIdentifier]
            if {![$obj cget -isReportableComponent]} {
                continue
            }
            if {[info exists reported($class)]} {
                continue
            }
            if {[catch {set compLicenseList [$obj getLicenses]} kk]} {
                message error2 "Errors validating $class licenses: $kk"
	        set compLicenseList ""
            } elseif {$compLicenseList == ""} {
                lappend missingLicenses $class
            }
            if {[string trim $compLicenseList] == "BITNAMI"} {
                continue
            }
            lappend reportedList $obj
            set reported([$obj getUniqueIdentifier]) $compLicenseList
        }
        # Print the results to the output
        foreach reportedObj $reportedList {
            set class [$reportedObj getUniqueIdentifier]
            set compLicenseList $reported($class)
            if {$reported($class) != ""} {
                set version [$reportedObj cget -version]
                set downloadUrl [$reportedObj getDownloadUrl]
                set compLicenseUrl [$reportedObj getLicenseUrl]
                set compLicenseFile ""
                foreach l [split $compLicenseList ";"] {
                    if {[string length [$reportedObj cget -licenseRelativePath]]} {
                        set compLicenseFile [$reportedObj getOutputLicenseFile]
                    } else {
                        lappend compLicenseFile [$reportedObj cget -name]-$l.txt
                    }
                }
                set compLicenseFile [join $compLicenseFile ";"]

                if {[$reportedObj isNotGoogleWhitelisted] == 0} {
                    set srcComponent "Whitelisted licenses (MIT BSD and Apache)"
                } elseif {[$reportedObj isNotGoogleWhitelisted] == 1} {
                    set srcComponent [file tail [$reportedObj getS3SourcesTarballLocation]]
                } else {
                    message error "Can't obtain license."
                }
                if { $downloadUrl == "" } {
                    set downloadUrl "Fill me in the metadata .ini files"
                }
                if { $compLicenseUrl == "" } {
                    set compLicenseUrl "Fill me in the metadata .ini files"
                }
            }
            lappend csvEntries "$class,$version,$downloadUrl,$compLicenseList,$compLicenseUrl,$compLicenseFile,$srcComponent"
        }
        puts "CSV REPORT\n========================================"
        puts [join $csvEntries \n]
        if {$errors != "" || [llength $missingLicenses] > 0} {
            message error2 "MISSING LICENSES:\n[join $missingLicenses \n]\nERRORS:\n[join $errors \n]\n"
            exit 1
        } else {
            exit 0
        }
    }
    public method logLicenses {{fromOutput 0}} {
        set objList [getComponents]
        if {$fromOutput} {
            if {![file exist [$be cget -src]]} {
                error "We can not check the licenses. Run the build to extract all dependencies in [$be cget -src] folder"
                exit 1
            }
            set licenseReportFile licenses_report.csv
            ::xampptcl::file::write [$be cget -output]/$licenseReportFile ""
            foreach c $objList {
                if {[$c isa builddependency]} {
                    message info2 "[$c cget -name] <build dependency>"
                    continue
                }
                set licenseOutputPath [$c cget -name].txt
                if {[catch {set licenseList [detectLicense $be [$be cget -licensesDirectory] $licenseOutputPath]} kk]} {
                    set licenseDetected $kk
                    set errorLevel error
                } else {
                    set licenseDetected $licenseList
                    if { ![string length $licenseList] } {
                        set errorLevel warning
                    } else {
                        set errorLevel info
                    }
                }
                message $errorLevel "Component: $c - File: $licenseOutputPath - License: $licenseDetected - Notes: [$c cget -licenseNotes]"
                if { $licenseDetected == "unknown" || $licenseDetected == "UNKNOWN" || $licenseDetected == "License NOT found!"} {
                    set licenseDetected ""
                }
                ::xampptcl::file::append [$be cget -output]/$licenseReportFile "\"$fullname\",\"$c\",\"[$c cget -name]\",\"$licenseDetected\",\"[$c cget -licenseNotes]\",\"$errorMessage\"\n"
            }
        } else {
            set text {}
            foreach obj $objList {
                set class [lindex [split [$obj info class] :] end]
                if {[::itcl::isInternalClass $class]} {
                    continue
                }
                if {[$obj isa builddependency]} {
                    continue
                }
                if {[catch {set licenses_info [$obj getLicenses]} kk]} {
                    message error2 "Errors validating $class licenses: $kk"
                    set licenses_info ""
                } elseif {$licenses_info == ""} {
                    message error2 "Missing license info for $class"
                }
                if {[string match *,* $licenses_info]} {
                    set licenses_info \"$licenses_info\"
                }
                append text [join [list $class [$obj getUniqueIdentifier] [$obj cget -name] $licenses_info] ,] \n
            }
            set licenseReportFile [xampptcl::util::uniqueFile /tmp/licenses_report.csv]
            ::xampptcl::file::write $licenseReportFile "class,unique_name,name,licenses\n$text"
            message info "Written license report $licenseReportFile"

        }
    }
    protected method debugClassInfo {c object} {
        if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
            message info2 "Adding tarballs for class $c; class [$object info class]; heritage: [join [$object info heritage]]"
        }
    }
    public method logTarballs {} {
        setupStackComponents
        $stack createStackComponents
        set chrpath [createObject chrpath $be]
        puts "$fullname Components"
        set tarballsList {}
        debugClassInfo "Stack" $stack
        foreach d [$stack cget -additionalFileList] {
             append tarballsList "[$stack findFile $d]\n"
        }
        foreach c [$stack cget -components] {
            debugClassInfo $c [$stack getComponentRef $c]
            append tarballsList "[[$stack getComponentRef $c] findTarball]\n"
            if {[[$stack getComponentRef $c] isa phpWindowsX64]} {
                set pearWindows [createObject pearWindows $be]
                append tarballsList "[$pearWindows findTarball]\n"
            }
            foreach d [[$stack getComponentRef $c] cget -patchList] {
                append tarballsList "[[$stack getComponentRef $c] findFile $d]\n"
            }
            foreach d [[$stack getComponentRef $c] cget -additionalFileList] {
                append tarballsList "[[$stack getComponentRef $c] findFile $d]\n"
            }
        }
        append tarballsList "[$chrpath findTarball]\n"
        puts $tarballsList
    }
    public method logApplicationTarballs {} {
        if {$application == ""} {
            set application $shortname
        }
        setupStackComponents
        $stack createStackComponents
        if {[supportsBuildApplicationTarball]} {
            $be configure -buildApplicationType "fromApplicationModifiedSource"
            puts [[$application ::\#auto $be] findTarball]
        }
    }
    public method logPackTarballs {} {
        setupStackComponents
        $stack createStackComponents
        puts "$fullname Components"
        set tarballsList {}
        debugClassInfo "Stack" $stack
        foreach d [$stack cget -additionalFileList] {
            append tarballsList "[$stack findFile $d]\n"
        }
        foreach c [$stack componentsToBuild] {
            debugClassInfo $c [$stack getComponentRef $c]
            set f [[$stack getComponentRef $c] findTarball]
            if {$f != ""} {
                append tarballsList "[[$stack getComponentRef $c] findTarball]\n"
            }
            foreach d [[$stack getComponentRef $c] cget -patchList] {
                if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                    message info2 "Looking for $d patch from patchList"
                }
                append tarballsList "[[$stack getComponentRef $c] findPatch $d]\n"
            }
            set name [[$stack getComponentRef $c] cget -name]
            set version [[$stack getComponentRef $c] cget -version]
            foreach d [[$stack getComponentRef $c] cget -tarballNameList] {
                if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                    message info2 "Looking for $d tarball from tarballNameList"
                }
                append tarballsList "[[$stack getComponentRef $c] findTarball [subst $d]]\n"
            }
            foreach d [[$stack getComponentRef $c] cget -pluginsList] {
                if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                    message info2 "Looking for $d tarball from pluginsList"
                }
                append tarballsList "[[$stack getComponentRef $c] findTarball [subst $d]]\n"
            }
            foreach d [[$stack getComponentRef $c] cget -additionalFileList] {
                if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                    message info2 "Looking for $d file from additionalFileList"
                }
                append tarballsList "[[$stack getComponentRef $c] findFile $d]\n"
            }
            if {[[$stack getComponentRef $c] isa rubyBitnamiProgram]} {
                foreach d [[$stack getComponentRef $c] cget -additional_gems] {
                    if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                        message info2 "Looking for $d file from additional_gems"
                    }
                    append tarballsList "[[$stack getComponentRef $c] findFile $d]\n"
                }
            }
            if {[[$stack getComponentRef $c] isa pythonBitnamiProgram]} {
                foreach d [[$stack getComponentRef $c] cget -additional_python_modules] {
                    if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
                        message info2 "Looking for $d file from additional_python_modules"
                    }
                    set additional_python_module [createComponent $d $be 0]
                    append tarballsList "[$additional_python_module findTarball]\n"
                }
            }
        }
        if {[info exists ::env(XAMPPDEBUGCLASSINFO)]} {
            message info2 "Looking for stack tarball"
        }
        append tarballsList "[$stack findTarball]\n"
        puts $tarballsList
    }
    public method tarOutput {} {
        if {$tarOutputPrefix == ""} {
            set tarOutputPrefix ${shortname}
        }
        build
        postBuild
        populateEmptyDirs [$be cget -output]
        generateInstaller build 1
        file mkdir [$be cget -tarOutputDir]
        cd [file dirname [$be cget -output]]
        logexec tar czf [file join [$be cget -tarOutputDir] ${tarOutputPrefix}-output-[$be cget -target]-[clock format [clock seconds] -format "%Y%m%d"].tar.gz] [file tail [$be cget -output]]
    }
    public method release {} {
        file delete -force [$be cget -src]
        tarOutput
        set releaseDir /opt/bitnami-stacks/releases/$shortname/[clock format [clock seconds] -format "%Y%m%d"]
        file mkdir $releaseDir
        file rename [glob [file join [$be cget -tarOutputDir] *.tar.gz]] $releaseDir
        generateInstaller build
        set outputBinariesDir [file join $::env(HOME)/installbuilder-[findInstallBuilderVersion $be]/output]
        file rename [file join  $outputBinariesDir [exec ls -rt $outputBinariesDir | tail -1]] $releaseDir
    }
    public method versionNumber {} {
        return $version
    }
    public method revisionNumber {} {
        return $rev
    }
    public method getUnattendedOptions {} {
        set stackObject [[getApplicationClass] ::\#auto $be]
        if {[string match *unattendedOptions* [$stackObject configure]]} {
            puts [$stackObject cget -unattendedOptions]
            exit 0
        } else {
            set stackObject [${shortname}stack ::\#auto $be]
            if {[string match *unattendedOptions* [$stackObject configure]]} {
                puts [$stackObject cget -unattendedOptions]
                exit 0
            }
        }
    }
    public method substitutePhp7Readme {readmeFile} {
        xampptcl::util::substituteParametersInFileRegex $readmeFile \
            [list {[^\n]+@@XAMPP_PHPCOUCHBASE_VERSION@@\n} {}] 1
        # Remove AWS SDK PHP in Windows and OSX (originally used in Linux for DreamFactory)
        if {![string match "*linux*" [$be cget -target]]} {
            xampptcl::util::substituteParametersInFileRegex $readmeFile \
                [list {[^\n]+@@XAMPP_AWSSDKPHP_VERSION@@\n} {}] 1
        }
    }
}

source xamppstacks.tcl
source xamppwindows.tcl
source xamppwindows64.tcl
source xampp-components.tcl
