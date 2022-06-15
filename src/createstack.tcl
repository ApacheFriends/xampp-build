# Create Stack Script

fconfigure stdout -buffering line ; fconfigure stderr -buffering line
if {[lindex $argv 0]=="help" || [llength $argv]==0} {
    puts "Usage: tclkit createstack.tcl ACTION STACK TARGET \[TYPE_OF_BUILD\]"
    puts ""
    puts "ACTION"
    puts " * pack                                               - Builds the stack and creates the installer"
    puts " * quickpack                                          - Copies the xml files to the output and creates the"
    puts "                                                        installer with a quickbuild"
    puts " * debugpack                                          - Builds the stack and creates the installer with debugger enabled"
    puts " * build                                              - Builds the stack WITHOUT creating the installer"
    puts " * buildComponents='<components>'                     - Builds the selected components only"
    puts " * buildComponentsWithPreparefordist='<components>'   - Builds the selected components only and executes the"
    puts "                                                        preparefordist method on them"
    puts " * buildTarball                                       - Builds the tarball"
    puts " * buildApplicationTarball                            - Builds the application tarball"
    puts " * buildReadme                                        - Makes the needed substitutions in a README.txt file"
    puts " * checkLicenses                                      - Shows the license info for all the components in a"
    puts "                                                        stack (uses metadata.ini file)"
    puts " * download                                           - Download the application tarball"
    puts " * generateReleaseData                                - Generates release metadata information for specified stack and target"
    puts " * getBaseTarball                                     - Prints the base tarball name"
    puts " * getStackVersion                                    - Prints the stack version and revision"
    puts " * getStackInstallerName                              - Prints the stack installer name"
    puts " * getUnattendedOptions                               - Prints the options used when running in unattended mode"
    puts " * logComponents                                      - Prints the components that the base tarball of the stack contains"
    puts " * getBasePlatformName                                - Prints the base platform name of the stack"
    puts " * logBundledComponents                               - Prints the components bundled with the stack"
    puts " * logBundledComponentsAndDependencies                - Prints the components bundled with the stack and its dependencies"
    puts " * logProperties                                      - Prints the stack metadata info"
    puts " * logTarballs                                        - Prints the used tarballs required for compilation"
    puts " * logApplicationTarballs                             - Prints the used tarballs required for application compilation"
    puts " * logPackTarballs                                    - Prints the used tarballs required for building the stack"
    puts " * tarOutput                                          - Builds and compress the output folder"
    puts " * release                                            - Build the output tarball and the installer"
    puts " * remoteBuildTarball                                 - Builds the different base tarballs supported by a stack"
    puts "                                                        and retrieves them over the network"
    puts " * extract                                            - Extract the component tarball"
    puts ""
    puts "TARGET"
    puts " * linux-x64"
    puts " * windows-x64"
    puts " * osx-x64"
    puts ""
    puts "TYPE_OF_BUILD"
    puts " * fromTarball                                        - Using the proper base tarball. Default"
    puts " * fromSource                                         - Builds all the programs that are not already compiled"
    puts " * fromSourceComplete                                 - Builds ALL the programs"
    puts " * continueAt                                         - Continue the build at some point. It is necessary to specify"
    puts "                                                        the component name"
    puts ""
    puts "OTHER_TOOLS"
    puts " * checkLicenses                                      - Shows the license info for all our components"
    puts "                                                        (uses metadata.ini file)"
    puts " * getStacksForComponent <component>                  - This tool identify other stacks which use or inherit"
    puts "                                                        from this component"
    puts " * getMetadataStacksForComponent <component>\[@<version>\]    - Gets the name of all the stacks for which metadata should be updated for 'component'"
    puts " * getStackKeysWithPropertiesValue <key> \[value\]    - This tool finds the list of stacks that have a properties key set to a value."
    puts "                                                        If the value is not passed, it looks stacks where the key is non-empty."
    puts " * getBitnamiStacks                                   - This tool provides the list of all the Bitnami stacks"
    puts " * listBitnamiStacksAndTarballs <platform>             - This tool provides the list of all the Bitnami stacks"
    puts " * getBitnamiInternalStacks                           - This tool provides the list of all the Bitnami internal stacks"
    puts "                                                        and their base tarballs"
    puts " * getSupportedPlatforms                              - This tool provides the list of all the Bitnami stacks"
    puts "                                                        and their supported platforms"
    puts " * getCompiledApps                                    - This tool provides the list of all the Bitnami App stacks"
    puts "                                                        that supports buildApplicationTarball"
    puts " * getStackInfo <component> <attribute>               - Prints the info for the attribute provided"
    puts " * getBitnamiComponentsLinux                          - This tool provides the list of components that we ship in"
    puts "                                                        Bitnami stacks for linux-x64"
    puts " * checkBaseTarballs                                  - This tool checks that all base tarballs are available in S3"
    puts " * generateBuildConfFile <component>\[@<version>\]      - This tool will generate a custom build configuration file"
    puts "                                                        to build tarballs based on component(s) + pack + test"
    puts " * getInfrastructureUpdates                           - Get the list of infrastructure components that needs to be updated"
    puts " * updateInfrastructureMetadata                       - This tool takes the latest infrastructure versions and update them in the code"
    puts ""
    puts "Note that listing Bitnami Stacks wont list non-Bitnami stacks like XAMPP and custom stacks"
    exit
}

proc isRemoteMethod {method} {
    return [regexp {remote} $method]
}

proc isBuildMethod {method} {
    return [regexp {build(Tarball|ApplicationTarball)} $method]
}

proc today {} {
    return [clock format [clock seconds] -format %Y%m%d]
}

proc timestamp {} {
    return [clock format [clock seconds] -format %H%M%S]
}

set cwd [pwd]
cd [file dirname [info script]]

source common.tcl
source stacks.tcl

proc commandSupportsExtraArgs {cmd} {
    switch -- $cmd {
        "generateReleaseData" {
            return 1
        }
        "getStackMetadata" {
            return 1
        }
        default {
            return 0
        }
    }
}

set command [split [lindex $argv 0] =]
set method [lindex $command 0]
set args [lindex $command 1]
set product [lindex $argv 1]
set target [lindex $argv 2]

if {[commandSupportsExtraArgs $method]} {
    set extraArgs [lrange $argv 3 end]
} else {
    set extraArgs ""
}
set continueAtComponent {}

set platformID $target

set buildType "fromTarball"
set buildApplicationType "fromApplicationSource"

# Enabling the quiet mode will make any "message" not to be printed
switch $method {
    getStackVersion - baseTarballOutputDir {
        set ::env(BITNAMI_QUIET_MODE) 1
    }
}
if {$method=="buildTarball" || $method=="remoteBuildTarball"} {
    set buildType "fromSource"
}
if {$method=="buildApplicationTarball" ||$method=="remoteBuildApplicationTarball"} {
    set buildApplicationType "fromApplicationModifiedSource"
}
if {[llength $argv]>=4} {
    set buildType [lindex $argv 3]
}

if {$buildType=="fromSource"} {
    set buildApplicationType "fromApplicationModifiedSource"
}

if {[llength $argv]==5 && $buildType == "continueAt"} {
    set continueAtComponent [lindex $argv 4]
}

proc getAffectedProducts {affectedComponents {supportedBuildPlatforms "linux-x64 windows-x64"}} {
    if {[info exists ::env(BITNAMI_PLATFORM)]} {
        set supportedBuildPlatforms $::env(BITNAMI_PLATFORM)
    }

    set be [buildEnvironment ::\#auto]
    $be configure -buildType "fromTarball"
    set stacksWithoutPack "xamppunixinstallerXstack xamppunixinstaller71stack xamppinstaller71stack xamppinstaller72stack"
    set componentsWithoutCompilation " java tomcat "

    # Dicts containing the affected products with their affected platforms
    # affectedProductsToBuild contains the products that use a base tarball that include an affected component
    # affectedProductsToPack containst the products that bundle an affected component
    # We need to differenciate between both because it may happen that a base tarball includes a component
    # but the stack used to build that base tarball does not bundle it
    # (e.g. Pootle bundles Redis and uses the Python base tarball, but Django is used to build the Python base tarball and it does not bundle Redis)
    set affectedProductsToBuild [dict create]
    set affectedProductsToPack [dict create]

    foreach product [::buildsystem::findAllClassesByType product $be] {
        set p [$product ::\#auto $be]
        foreach os [$p supportedPlatforms] {
            if {![::xampptcl::util::listContains $supportedBuildPlatforms $os]} {
                # platform not supported
                continue
            }
            $be configure -target $os
            set p [$product ::\#auto $be]
            $be configure -product $p

            if {[$p isBitnami] && ![$p isInternal] && [$p getBaseNameForPlatform] !="" || [string match "*xampp*" $p]} {
                set builtComponents {}
                foreach c [${p} getComponents] {
                    lappend builtComponents "[string tolower [${c} cget -name]]@[${c} cget -version]"
                }
                set bundledComponents {}
                foreach c [$p getBundledComponents] {
                    lappend bundledComponents "[string tolower [$c cget -name]]@[$c cget -version]"
                }
                foreach component ${affectedComponents} {
                    if {[string match "*@*" ${component}] == 1} {
                        set searchComponent ${component}
                    } else {
                        set searchComponent "[string trim ${component} @]@"
                    }
                    set componentName [lindex [split ${searchComponent} @] 0]

                    if {[lsearch $builtComponents "${searchComponent}*"] != -1 && ![string match "* $componentName *" "$componentsWithoutCompilation"]} {
                        if {(![::xampptcl::util::listContains [dict keys ${affectedProductsToBuild}] ${product}]) || (![::xampptcl::util::listContains [dict get ${affectedProductsToBuild} ${product}] ${os}])} {
                            set affectedProductsToBuild [dict lappend affectedProductsToBuild ${product} ${os}]
                        }
                    }
                    if {[lsearch ${bundledComponents} "${searchComponent}*"] != -1} {
                        # component found. Add it only once
                        if { ![xampptcl::util::listContains [dict keys $affectedProductsToPack] $product] || ![xampptcl::util::listContains [dict get $affectedProductsToPack $product] $os]} {
                            if {[lsearch -glob ${stacksWithoutPack} "*[string map {:: ""} ${product}]*"] == -1} {
                                set affectedProductsToPack [dict lappend affectedProductsToPack ${product} $os]
                            }
                        }
                    }
                }
            }
        }
    }
    # merge both dictionaries into one single dictionary
    set productsDict [dict create "affectedProductsToBuild" ${affectedProductsToBuild} "affectedProductsToPack" ${affectedProductsToPack}]
    return ${productsDict}
}

proc getStacksForComponent {component} {
    set productsList [dict keys [dict get [getAffectedProducts ${component}] "affectedProductsToPack"]]
    set productsList [lsort -unique ${productsList}]
    return ${productsList}
}

proc getMetadataStacksForComponent {affectedComponent} {
    # clean products name
    set platformStacks "amp app"
    set productsList [string map {:: ""} [getStacksForComponent ${affectedComponent}]]
    set productsList [lsearch -inline -all -not ${productsList} "*xampp*"]

    # Substitute '*amp{number}' stacks with 'platform{number}'
    set auxProductsList {}
    foreach platformStackRegexp ${platformStacks} {
        # keep substituting elements while found
        while {[lsearch -glob ${productsList} "*${platformStackRegexp}*"] != -1} {
            set ampComponent [lindex ${productsList} [lsearch -glob ${productsList} "*${platformStackRegexp}*"]]
            regexp -- {^.*([0-9][0-9]).*$} ${ampComponent} - ampVersion
            set foundPlatformStacks [lsearch -inline -all ${productsList} "*${platformStackRegexp}${ampVersion}*"]
            set productsList [lsearch -inline -all -not ${productsList} "*${platformStackRegexp}${ampVersion}*"]

            # add if not found
            if {[lsearch ${auxProductsList} "*${platformStackRegexp}${ampVersion}*"] == -1} {
                set auxProductsList [lappend auxProductsList ${ampComponent}]
            }
        }
    }
    set productsList [concat ${productsList} ${auxProductsList}]
    return ${productsList}
}

proc getBitnamiStacksAndTarballs {platform} {
    set be [buildEnvironment ::\#auto]
    set defaultPlatform "linux-x64"
    if { $platform == "" } {
        puts "Platform not specified. Reporting Stacks and Tarballs for platform $defaultPlatform"
        set platform $defaultPlatform
    }
    set result {}
    $be configure -target $platform
    foreach product [::buildsystem::findAllClassesByType product $be] {
        set p [$product ::\#auto $be]
        if {![xampptcl::util::listContainsGlob [$p supportedPlatforms] $platform]} {
            continue
        }
        if {[$p isBitnami] && [$p getBaseNameForPlatform]!="" || [string match "*xampp*" $p]} {
            if {[string match -nocase *stack* $product]} {
                set stackName [lindex [split $product ":"] 2]
                $p createStack
                set stack [$p cget -stack]
                lappend result "$stackName" "[$stack cget -baseTarball]"
            }
        }
    }
    return $result
}

proc getInfrastructureUpdates {} {
    set bitnamiCodeDir [file dirname [file dirname [file normalize [info script]]]]
    set infrastructureVtrackerContent [xampptcl::file::read [file join $bitnamiCodeDir tools vtracker infrastructure]]
    set componentsList ""
    set componentsToAvoid " cacertificates windows-apache "
    set stringToAvoid "singlevm"

    foreach line [split $infrastructureVtrackerContent "\n"] {
        if {[string match *prog* $line]} {
            regsub {^\s*prog\s*([^ ]*)\s*.*$} $line {\1} component
            set component [string tolower $component]
        } elseif {[string match *dlversion* $line]} {
            regsub {^\s*dlversion\s*=\s*([^ ]*)\s*.*$} $line {\1} dlversion
            if { $version != $dlversion && ![string match "* $component *" $componentsToAvoid] && ![string match *$stringToAvoid* $component]} {
                regsub -all {[0-9]+} $component "" component
                switch -glob $component {
                    ruby* {
                        set component ruby
                    }
                    icu* {
                        set component icu4c
                    }
                    msys* {
                        set component msys2
                    }
                }
                if { $componentsList ==  ""} {
                    set componentsList "$component@$dlversion;$version"
                } else {
                    set componentsList "$componentsList $component@$dlversion;$version"
                }
            }
        } elseif {[string match *version* $line]} {
            regsub {^\s*version\s*=\s*([^ ]*)\s*.*$} $line {\1} version
        }
    }
    return "$componentsList"
}

set be [buildEnvironment ::\#auto]
switch -- $method {
    getStacksForComponent {
        set trimmedOutput {}
        set component [lindex $argv 1]
        foreach product [getStacksForComponent $component] {
            lappend trimmedOutput [string trim $product ":"]
        }
        puts [join [lsort -unique $trimmedOutput] \n]
        exit
    }

    listBitnamiStacksAndTarballs {
        set platform [lindex $argv 1]
        set outputList [getBitnamiStacksAndTarballs $platform]
        foreach {stack baseTarball} $outputList {
            puts "$stack $baseTarball"
        }
        exit
    }

    getBitnamiComponentsLinux {
        set componentsList {}
        $be configure -target linux-x64
        foreach product [::buildsystem::findAllClassesByType product $be] {
            set p [$product ::\#auto $be]
            if {[$p isBitnami] && [$p getBaseNameForPlatform]!=""} {
                $p setupStackComponents
                set stack [$p cget -stack]
                foreach c [$stack cget -components] {
                    set c [lindex [string trim $c] 0]
                    set component [$c ::\#auto $be]
                    if {![$component isa builddependency]} {
                        lappend componentsList $c
                    }
                }
            }
        }
        puts [join [lsort -unique $componentsList] \n]
        exit
    }

    updateInfrastructureMetadata {
        set bitnamiCodeDir [file dirname [file dirname [file normalize [info script]]]]
        set componentsList [getInfrastructureUpdates]
        if { $componentsList != "" } {
            cd [file join $bitnamiCodeDir scripts]
            message warning "COMPONENTS UPDATES FOUND: $componentsList"
            logexec ./update-metadata.sh -c "$componentsList"
        } else {
            message warning "No update was found"
        }
        exit
    }

    checkBaseTarballs {
        set platforms {linux-x64 windows-x64 osx-x64}
        set extension tar.gz
        set tarballsDir /opt/compiled-tarballs
        set bucket "s3://apachefriends$tarballsDir"
        set baseTarballs ""
        set result 0
        foreach platform $platforms {
            set stacksAndTarballs [getBitnamiStacksAndTarballs $platform]
            foreach {stack baseTarball} $stacksAndTarballs {
                lappend baseTarballs $baseTarball
            }
        }
        foreach baseTarball [lsort -unique $baseTarballs] {
            if {$baseTarball != ""} {
                regexp -- {^([a-z]*).*} $baseTarball - folder
                set searchLocation $bucket/$folder/$baseTarball.$extension
                if { [catch {set tarballLocation [exec s3cmd ls $searchLocation]} findResult] } {
                    message error "Error looking for $baseTarball: $findResult"
                } else {
                    if {$tarballLocation == ""} {
                        message warning "MISSING BASE TARBALL: $searchLocation not found"
                        set result 1
                    }
                }
            }
        }
        exit $result
    }

    getMetadataStacksForComponent {
        if {[llength ${argv}]==1} {
            set affectedComponents [getInfrastructureUpdates]
            regsub -all {;[^\s]*} ${affectedComponents} "" affectedComponents
            message warning "None component was provided, the tool will use all those with updates"
            message warning "COMPONENTS: ${affectedComponents}"
        } else {
            set affectedComponents [lrange ${argv} 1 end]
        }
        puts [getMetadataStacksForComponent ${affectedComponents}]
        exit 0
    }

    generateBuildConfFile {
        set osxUnsupportedTarballs "xamppstackman74stack xamppstackman80stack xamppstackman81stack"
        set osxUnsupportedTarballs [concat ${osxUnsupportedTarballs} "mapp74stack mapp80stack mapp81stack"]
        set osxUnsupportedTarballs [concat ${osxUnsupportedTarballs} "xamppunixinstallerXstack"]

        if {[llength $argv]==1} {
            set affectedComponents [getInfrastructureUpdates]
            regsub -all {;[^\s]*} $affectedComponents "" affectedComponents
            message warning "None component was provided, the tool will use all those with updates"
            message warning "COMPONENTS: $affectedComponents"
        } else {
            set affectedComponents [lrange $argv 1 end]
        }
        if { $affectedComponents != "" } {
            set date [clock format [clock seconds] -format {%Y%m%d} -gmt 1]
            set componentsFile /tmp/components-$date.conf
            xampptcl::file::write $componentsFile $affectedComponents

            set stacksWithoutTest " publifystack django3python38stack "
            set djangoProjects "SQLite MySQL PostgreSQL"
            set windowsTestMachines "windows-x64 windows-large-x64 windows-xlarge-x64"
            set linuxTestMachines "linux-x64 linux-large-x64 linux-xlarge-x64"

            set affectedProductsToBuild [dict get [getAffectedProducts ${affectedComponents}] "affectedProductsToBuild"]
            set affectedProductsToPack [dict get [getAffectedProducts ${affectedComponents}] "affectedProductsToPack"]
            # clean products names
            set affectedStacksToBuild [string map {:: ""} $affectedProductsToBuild]
            set affectedStacksToPack [string map {:: ""} $affectedProductsToPack]

            # Reading source of truth for buildTarballs (unstable-tarballs.conf)...
            set bitnamiCodeDir [file dirname [file dirname [file normalize [info script]]]]
            set unstableTarballsContent [xampptcl::file::read [file join $bitnamiCodeDir scripts builds unstable-tarballs.conf]]
            set sourceOfTarballs [dict get $unstableTarballsContent buildTarball.list]

            # Get all base tarballs that will be updated
            # Check each affectedProduct and its supported platforms against the list of base tarballs that will be updated
            # This will prevent packaging an application (in a specific platform) which base tarball is not going to be built
            set buildDict [dict create]
            set buildTasksCount 0
            foreach {affectedStack affectedPlatforms} $affectedStacksToBuild {
                if {[set affectedIndex [lsearch $sourceOfTarballs $affectedStack]] != -1} {
                    set affectedItemKey [lindex $sourceOfTarballs $affectedIndex]
                    set affectedItemValue [dict get $sourceOfTarballs $affectedItemKey]
                    set mapToBuildPlatforms [string map {linux centos*} $affectedPlatforms]
                    set platformsToBuild [listSelect $affectedItemValue $mapToBuildPlatforms]
                    dict set buildDict $affectedItemKey $platformsToBuild
                    incr buildTasksCount [llength $platformsToBuild]
                }
            }

            set packDict [dict create]
            set testDict [dict create]
            set packTasksCount 0
            set testTasksCount 0
            foreach {affectedStack affectedPlatforms} $affectedStacksToPack {
                dict set packDict $affectedStack $affectedPlatforms
                incr packTasksCount [llength $affectedPlatforms]
                if {![string match "*${affectedStack}*" $stacksWithoutTest]} {
                    if {[string match django* $affectedStack]} {
                        # Django run different tests per project
                        foreach project $djangoProjects {
                            set djangoApp [string map {stack ""} $affectedStack]
                            dict set testDict "\{${djangoApp} stack${project}\}" $affectedPlatforms
                            incr testTasksCount [llength $affectedPlatforms]
                        }
                    } elseif {![string match *Xstack* $affectedStack]} {
                        set app [string map {stack ""} $affectedStack]
                        set stackObject [::itcl::local $affectedStack #auto $be]
                        set confFile [$stackObject confFileName]
                        set confFileContent [xampptcl::file::read [file join $bitnamiCodeDir scripts builds $confFile.conf]]
                        regexp -- {stacktest.list\s*\{([^\.]*?)[\n]\}} $confFileContent - testContent
                        set affectedTestPlatforms [exec echo $testContent | grep $app | grep -v Button | grep -v module | tr -d \\n\{\} | sed {s/.*stack//g} | sed -e {s/^[ \t]*//}]
                        # Remove not affected platforms
                        if {![string match *linux-x64* $affectedPlatforms]} {
                            foreach testMachine $linuxTestMachines {
                                set affectedTestPlatforms [lremove $affectedTestPlatforms $testMachine]
                            }
                        } elseif {![string match *windows-x64* $affectedPlatforms]} {
                            foreach testMachine $windowsTestMachines {
                                set affectedTestPlatforms [lremove $affectedTestPlatforms $testMachine]
                            }
                        }
                        dict set testDict $affectedStack $affectedTestPlatforms
                        incr testTasksCount [llength $affectedTestPlatforms]
                    }
                }
            }

            set ciDict [dict create]
            foreach {affectedStack affectedPlatforms} $affectedStacksToPack {
                dict set ciDict $affectedStack {}
            }

            # Set number of parallel processes that will be spawned to listen to the tasks
            set testinstances 10

            set fileDict [dict create]
            dict set fileDict "buildTarball.timeout" "\"5 hours\""
            dict set fileDict "buildTarball.instances" $buildTasksCount
            dict set fileDict "buildTarball.instanceType" "c3.4xlarge"
            dict set fileDict "buildTarball.list" $buildDict
            dict set fileDict "pack.timeout" "\"5 hours\""
            dict set fileDict "pack.instances" $packTasksCount
            dict set fileDict "pack.instanceType" "m3.medium"
            dict set fileDict "pack.list" $packDict
            # Get number of instances to launch based on the number of parallel processes and the number of tasks
            # (use ceiling to get the nearest and largest number)
            dict set fileDict "stacktest.instances" [expr {round(ceil(double($testTasksCount)/$testinstances))}]
            dict set fileDict "stacktest.testinstances" $testinstances
            dict set fileDict "stacktest.seleniumcount" $testinstances
            dict set fileDict "stacktest.list" $testDict
            dict set fileDict "cibuild.list" $ciDict
            dict set fileDict "citest.list" $ciDict

            # Pretty print
            set fileOutput ""
            set mainKeys {buildTarball.list pack.list stacktest.list cibuild.list citest.list}
            foreach {key value} $fileDict {
                if {[lsearch $mainKeys $key] != -1} {
                    append fileOutput "$key {\n"
                    foreach {stack platforms} $value {
                        append fileOutput "    $stack {$platforms}\n"
                        if { ($key == "pack.list" || $key == "stacktest.list")  && [string match "*xampp*" $stack] && [string match *windows-x64* $affectedStacksToPack]} {
                            if {[regsub {.*(\d\d.*)} $stack {\1} stackVersion]} {
                                foreach xamppType "xampp xamppportable" {
                                    set windowsXampp "${xamppType}installer${stackVersion}"
                                    append fileOutput "    $windowsXampp {windows-x64}\n"
                                }
                            }
                        }
                    }
                    append fileOutput "}\n"
                } else {
                    append fileOutput "$key $value\n"
                }
            }

            set basetarballsFile /tmp/basetarballs-$date.conf
            if { $affectedStacksToPack != "" } {
                puts $fileOutput
                xampptcl::file::write $basetarballsFile $fileOutput
                message warning "Conf file: $basetarballsFile"
                message warning "------------------------------------"
            }
            # OSX base tarballs
            set buildDict [dict get [getAffectedProducts ${affectedComponents} "osx-x64"] "affectedProductsToBuild"]
            set osxBuildList {}
            # Get stacks name only
            foreach {affectedStack affectedPlatforms} ${buildDict} {
                lappend osxBuildList [string map {"::" ""} ${affectedStack}]
            }
            # Remove not supported tarballs
            set osxBuildList [lremove ${osxBuildList} ${osxUnsupportedTarballs}]
            set osxBuildList [join [lsort -unique $osxBuildList] \n]
            set basetarballsFile /tmp/basetarballs-osx-x64-$date.conf
            if { $osxBuildList != "" } {
                puts $osxBuildList
                xampptcl::file::write $basetarballsFile $osxBuildList
                message warning "Basetarballs file for osx-x64: $basetarballsFile"
            }
        }
        exit
    }

    getInfrastructureUpdates {
        puts [getInfrastructureUpdates]
        exit
    }

    getBitnamiInternalStacks {
        set platform [lindex $argv 1]
        set result {}
        foreach product [::buildsystem::findAllClassesByType product $be] {
            set p [$product ::\#auto $be]
            if {[$p isBitnami] && [$p isInternal]} {
                if {$platform!="" && ![xampptcl::util::listContainsGlob [$p supportedPlatforms] $platform]} {
                    continue
                }
                if {[string match -nocase *stack* $product]} {
                    set stackName [lindex [split $product ":"] 2]
                    lappend result $stackName
                }
            }
        }
        puts [join [lsort -unique $result] \n]
        exit
    }

    getBitnamiStacks {
        set platform [lindex $argv 1]
        set result {}
        foreach product [::buildsystem::findAllClassesByType product $be] {
            set p [$product ::\#auto $be]
            if {[$p isBitnami] && ![$p isInternal]} {
                if {$platform!="" && ![xampptcl::util::listContainsGlob [$p supportedPlatforms] $platform]} {
                    continue
                }
                if {[string match -nocase *stack* $product]} {
                    set stackName [lindex [split $product ":"] 2]
                    lappend result $stackName
                }
            }
        }
        puts [join [lsort -unique $result] \n]
        exit
    }

    getStackKeysWithPropertiesValue {
        set key [lindex $argv 1]
        set value [lindex $argv 2]
        set result {}
        foreach product [::buildsystem::findAllClassesByType product $be] {
            set p [$product ::\#auto $be]
            if {[$p isBitnami] && ![$p isInternal]} {
                if {![string match -nocase *stack* $product]} {
                    continue
                }
                if {($value == "" && [$p cget -$key] != "") || ($value != "" && [$p cget -$key] == $value)} {
                    lappend result [$p cget -shortname]
                }
            }
        }
        puts [join [lsort -unique $result] \n]
        exit
    }

    getSupportedPlatforms {
        set result {}
        foreach product [::buildsystem::findAllClassesByType product $be] {
            set p [$product ::\#auto $be]
            if {[$p isBitnami]} {
                if {[string match -nocase *stack* $product]} {
                    set stackName [lindex [split $product ":"] 2]
                    set list [$p supportedPlatforms]
                    lappend result "$stackName = [join $list ,]"
                }
            }
        }
        puts [join [lsort -unique $result] \n]
        exit
    }

    getCompiledApps {
        set result {}
        foreach product [::buildsystem::findAllClassesByType product $be] {
            set p [$product ::\#auto $be]
            if {[$p isBitnami]} {
                if {[string match -nocase *stack* $product]} {
                    set stackName [lindex [split $product ":"] 2]
                    if {[$p supportsBuildApplicationTarball]} {
                        set supportedChroot [$p supportedChroot]
                        if {[string match -nocase *osx-x64* [$p supportedPlatforms]]} {
                            set supportedOXChroots [$p supportedOSXChroots]
                            lappend result "$stackName can be compiled at $supportedChroot chroot and $supportedOXChroots chroots on OS X"
                        } else {
                            lappend result "$stackName can be compiled at $supportedChroot chroot."
                        }
                    }
                }
            }
        }
        puts [join [lsort -unique $result] \n]
        exit
    }
}
$be configure -target $target

if {[info exists env(BITNAMI_BINARIES_DIRECTORY)]} {
    $be configure -binaries $env(BITNAMI_BINARIES_DIRECTORY)
}  else  {
    $be configure -binaries /opt/bitnami-stacks/builds
}
if {[info exists env(BITNAMI_BUILD_DIRECTORY)]} {
    $be configure -output $env(BITNAMI_BUILD_DIRECTORY)/output
    $be configure -src $env(BITNAMI_BUILD_DIRECTORY)/src
    $be configure -builddep $env(BITNAMI_BUILD_DIRECTORY)/builddep
} elseif {[info exists ::env(BITNAMI_AUTOMATIC_BUILD)]} {
    $be configure -output [lindex $argv 4]/output
    $be configure -src [lindex $argv 4]/src
    $be configure -builddep [lindex $argv 4]/builddep
} else {
    $be configure -output [file join / bitnami $product-$target output]
    $be configure -src [file join / bitnami $product-$target src]
    $be configure -builddep [file join / bitnami $product-$target builddep]
}

$be configure -tarOutputDir [file join / bitnami $product tarOutput]
$be configure -licensesDirectory [file join [$be cget -output] licenses]

if {[isRemoteMethod $method]} {
    set stackObject [$product ::\#auto $be]
    file mkdir [file join logs [today]]
    if {[string match remoteBuildTarball* $method]} {
        set method [string map {remoteBuildTarball buildTarball} $method]
    } else {
        set method [string map {remoteBuildApplicationTarball buildApplicationTarball} $method]
    }
    set script_path [ file dirname [ file normalize [ info script ] ] ]
    foreach h [$stackObject cget -supportedHosts] {
        if {[lsearch $target $h]!=-1 || $target=="all"} {
            set log "logs/[today]/build_system_${product}_${method}_${h}_[timestamp].log"
            set cmd [list tclkit remotecreatestack.tcl $method $product $h $buildType]
            if {$continueAtComponent != ""} {
                lappend cmd $continueAtComponent
            }
            message info2 "Executing '${cmd}' in background...\nSending logs to '${script_path}/${log}'"
            eval exec $cmd [list > $log 2> $log &]
            exit
        }
    }
    puts stderr "Unsupported host $target for $product. The supported hosts are:\n\n[join [$stackObject cget -supportedHosts] \n]\n"
    exit 1
} else {
    if {$method == "download" || ($method == "autodownload")} {
        set stackObject [$product ::\#auto $be]
        eval [list $stackObject] [list $method] $args
        exit
    } elseif {$method == "getRemoteMetadata"} {
        if {$product != ""} {
            set stackObject [$product ::\#auto $be]
            set objList [eval [list $stackObject] [list getComponents] $args]
            foreach obj $objList {
                if {![$obj isa "program"] || [$obj isInternal] || [$obj isa builddependency]} {
                    continue
                }
                if {[info exists ::env(ONLY_NEW_COMPONENTS)]} {
                    if {[$obj getExternalMetadataKey "licenses"] != ""} {
                        continue
                    }
                }
                puts "\n\[[$obj getUniqueIdentifier]\]"
                unset -nocomplain meta
                array set meta [$obj getMetadataFromRemoteSource]
                if {[info exists meta(licenses)]} {
                    set v ""
                    foreach l $meta(licenses) {
                        lappend v [lindex $l 0]
                    }
                    puts "licenses=[join $v \;]"
                }
                foreach k {url download_url} {
                    if {[info exists meta($k)]} {
                        puts "$k=$meta($k)"
                    }
                }
            }
            exit 0
        } else {
             message error2 "You must provide a product to get metadata for"
            exit 1
        }
    } elseif {$method == "getStackInfo"} {
        if {$target != "-" && $target != "" && [llength $argv] >= 4} {
            $be configure -platformID $platformID
            $be checkEnvironment
            $be setupEnvironment
            set attribute [lindex $argv 3]
        } else {
            set attribute [lindex $argv 2]
        }
        set stackObject [$product ::\#auto $be]
        switch -- $attribute {
            bitnamiPortalKey {
                puts [$stackObject bitnamiPortalKey]
            }
            description {
                puts [$stackObject getDescription]
            }
            confFileName {
                puts [$stackObject confFileName]
            }
            supportedPlatforms {
                set list [$stackObject supportedPlatforms]
                puts [join $list ,]
            }
            isInternal {
                puts [$stackObject isInternal]
            }
            isInfrastructure {
                puts [$stackObject isInfrastructure]
            }
            kind {
                puts [[$stackObject cget -targetInstance] cget -kind]
            }
            imageRevision {
                puts [[$stackObject cget -targetInstance] cget -rev]
            }
            vtrackerName {
                set application [$stackObject cget -application]
                if {$application == ""} {
                    set application [$stackObject cget -shortname]
                }
                if {![catch {set cn [$application ::\#auto $be]}] && [$cn isa program]} {
                    # Try to get the vtrackerName property, if not, use the name
                    set vtrackerName [$cn cget -vtrackerName]
                    if {[$cn cget -vtrackerName] == ""} {
                        set vtrackerName [$cn cget -name]
                    }
                } else {
                    # Use the name of the product (shortname) as a fallback
                    set vtrackerName [$stackObject cget -shortname]
                }
                puts $vtrackerName
            }
            downloadUrl - fullname - licenseRelativePath {
                set application [$stackObject cget -application]
                if {$application == ""} {
                    set application [$stackObject cget -shortname]
                }
                if {![catch {set cn [$application ::\#auto $be]}] && [$cn isa program]} {
                    puts [$cn cget -$attribute]
                } else {
                    message fatalerror "Could not find 'program' component associated to $product"
                    exit 1
                }
            }
            vtrackerUrl - vtrackerVersion - vtrackerRegex {
                set application [$stackObject cget -application]
                if {$application == ""} {
                    set application [$stackObject cget -shortname]
                }
                if {$attribute == "vtrackerUrl"} {
                    set key url
                } elseif {$attribute == "vtrackerVersion"} {
                    set key version
                } elseif {$attribute == "vtrackerRegex"} {
                    set key regex
                }
                if {![catch {set cn [$application ::\#auto $be]}] && [$cn isa program]} {
                    puts [$cn getAppKeyFromVtracker $key]
                } else {
                    message fatalerror "Could not find 'program' component associated to $product"
                    exit 1
                }
            }
            mainLicense {
                set application [$stackObject cget -application]
                if {$application == ""} {
                    set application [$stackObject cget -shortname]
                }
                if {![catch {set cn [$application ::\#auto $be]}] && [$cn isa program]} {
                    puts [$cn getMainComponentLicense]
                } else {
                    message fatalerror "Could not find 'program' component associated to $product"
                    exit 1
                }
            }
            licenses {
                set application [$stackObject cget -application]
                if {$application == ""} {
                    set application [$stackObject cget -shortname]
                }
                if {![catch {set cn [$application ::\#auto $be]}] && [$cn isa program]} {
                    puts [$cn getLicenses]
                } else {
                    message fatalerror "Could not find 'program' component associated to $product"
                    exit 1
                }
            }
            default {
                if {[catch {
                    puts [$stackObject cget -$attribute]
                } kk]} {
                    puts stderr "Don't know how to get attribute $attribute from stack"
                }
            }
        }
        exit 0
    } elseif {$platformID == ""} {
        puts stderr "You must provide a platform"
        exit 1
    } elseif {[itcl::find classes $platformID] == ""} {
        puts stderr "Invalid platform id '$platformID'"
        exit 1
    }
    $be configure -platformID $platformID

    $be checkEnvironment
    $be setupEnvironment

    $be configure -buildType $buildType
    $be configure -buildApplicationType $buildApplicationType

    if {[itcl::find classes $product] == ""} {
        puts stderr "Stack $product does not exist"
        exit 1
    }
    set stackObject [$product ::\#auto $be]

    #Check if we are using the proper linux chroot
    if { $target=="linux-x64" && [isBuildMethod $method] && [$stackObject isBitnami]} {
        set slchr [$stackObject cget -supportedLinuxChroot]
        set extractedChrootVersion [extractChrootCentosVersion $slchr]
        if { ($extractedChrootVersion!=[getCentosVersion $slchr])} {
            message error "\n Unsupported linux chroot for $product. You must use: $slchr \n\n"
            exit 1
        }
    }
    #end for the linux chroot check

    if {[$stackObject isa product] && ![xampptcl::util::listContains [$stackObject supportedPlatforms] $platformID] && (![string match get* $method]) && (![string match log* $method])} {
        message warning "WARNING: Product $product does not support platform $platformID"
        message warning " - Supported platforms: [$stackObject supportedPlatforms]"
    }
    if {[catch {$stackObject info function $method}]} {
        switch -- $method {
            "pack" {
                puts stderr "$product does not support the 'pack' method"
            }
            default {
                puts stderr "Invalid command '$method' for product $product"
            }
        }
        exit 1
    }
    #$stackObject configure -targetInstance [::$platformID ::\#auto $be]

    $be configure -action $method
    $be configure -product $stackObject
    $be configure -continueAtComponent $continueAtComponent
    if {[string match -nocase *stack* $product]} {
        $be setTimerValues $product [$stackObject cget -version] [$stackObject cget -rev]
    }
    if {[catch {
        eval [list $stackObject] [list $method] $args $extraArgs
    } kk]} {

            puts stderr $::errorInfo

        puts stderr $kk
        exit 1
    }
}

cd $cwd
