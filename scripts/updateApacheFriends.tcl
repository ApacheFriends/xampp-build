# updateApachefriends.tcl

# Import required packages
package require yaml
package require bitnami::util
package require bitnami::colors

#
## Functions
#
proc parseYamlFile {yamlFile} {
    return [::yaml::yaml2dict [xampptcl::file::read ${yamlFile}]]
}

proc generateSequence {start ignore end} {
    set result ""
    for {set i ${start}} {${i} <= ${end}} {incr i} {
        lappend result ${i}
    }
    return ${result}
}

proc getDictParameter {dictionary platform listId key} {
    return [dict get [lindex [dict get ${dictionary} ${platform}] ${listId}] ${key}]
}

proc getPhpBranch {version} {
    set versionList [split ${version} "."]
    set major [lindex ${versionList} 0]
    set minor [lindex ${versionList} 1]
    return "${major}.${minor}"
}

proc getPhpVersionFromYaml {yamlFile phpBranch} {
    # Get required values
    set dictionary [parseYamlFile ${yamlFile}]
    set platform "linux"
    set linuxList [dict get ${dictionary} ${platform}]
    set listLength [llength ${linuxList}]
    set version ""

    foreach id [generateSequence 0 .. ${listLength}] {
        if {${id} < ${listLength}} {
            set auxVersion [getDictParameter ${dictionary} ${platform} ${id} "version"]

            if {[string match "${phpBranch}" [getPhpBranch ${auxVersion}]]} {
                set version ${auxVersion}
                break
            }
        }
    }

    return ${version}
}

proc getInstallerRevision {yamlFile version} {
    set platform "linux"
    set downloadArch "x64"
    set dictionary [parseYamlFile ${yamlFile}]
    set linuxList [dict get ${dictionary} ${platform}]
    set listLength [llength ${linuxList}]

    # Get the id of the dict that contains the required version/installer
    foreach id [generateSequence 0 .. ${listLength}] {
        if {${id} < ${listLength}} {
            set auxVersion [getDictParameter ${dictionary} ${platform} ${id} "version"]
            if {[string match ${version} ${auxVersion}]} {
                break
            }
        }
    }

    # Get the installer name from the dict with 'id' and get the revision number
    set auxDict [lindex [dict get ${dictionary} ${platform}] ${id}]
    set installername [file tail [dict get [dict get [dict get ${auxDict} "downloads"] ${downloadArch}] "url"]]
    set pattern [format {xampp.*\-[0-9]*\.[0-9]*\.[0-9]*\-([0-9]*)\-.*}]
    regexp -- ${pattern} ${installername} - revision

    return ${revision}
}

proc releasedPhpBranchesRevision {yamlFile phpBranches} {
    # Call 'releasedPhpBranches' with the 'includeRevisions' parameter on
    return [releasedPhpBranches ${yamlFile} ${phpBranches} "/" 1]
}

proc releasedPhpBranches {yamlFile phpBranches {separatedBy "/"} {includeRevisions 0}} {
    set releasedPhpBranches ""

    foreach phpBranch ${phpBranches} {
        set releasedVersion [getPhpVersionFromYaml ${yamlFile} ${phpBranch}]
        if {![string match ${releasedVersion} ""]} {
            # Add revision if required
            if {${includeRevisions} == 1} {
                set releasedVersion "${releasedVersion}-[getInstallerRevision ${yamlFile} ${releasedVersion}]"
            }

            # Set return value
            if {[string match ${releasedPhpBranches} ""]} {
                set releasedPhpBranches "${releasedVersion}"
            } else {
                set releasedPhpBranches "${releasedPhpBranches} ${separatedBy} ${releasedVersion}"
            }
        }
    }

    return ${releasedPhpBranches}
}

proc generateComponentVersionString {yamlFile component} {
    set dictionary [parseYamlFile ${yamlFile}]
    set platform "linux"
    set index 0
    set bundledComponents [split [getDictParameter ${dictionary} ${platform} ${index} "whats_included"] ","]
    set result ""

    foreach tuple ${bundledComponents} {
        set subList [split [string trim ${tuple}]]
        set c [lindex ${subList} 0]
        set v [lindex ${subList} end]
        if {[string match ${c} ${component}]} {
            # OpenSSL is a special case
            if {[string match "OpenSSL" ${component}]} {
                set result "- ${component} ${v} (UNIX only)"
            } else {
                set result "- ${component} ${v}"
            }
        }
    }
    return ${result}
}

proc addComponentsVersion {yamlFile componentsList phpBranches} {
    set result ""
    set additionalInfo "\*\*Additional information\*\*"
    if {[info exists ::env(BITNAMI_EXTRA_CHANGELOG)] && (![string match ${::env(BITNAMI_EXTRA_CHANGELOG)} ""])} {
        set extraChangelog "- ${::env(BITNAMI_EXTRA_CHANGELOG)}"
    }

    foreach component ${componentsList} {
        set componentVersionString [generateComponentVersionString ${yamlFile} ${component}]
        if {![string match ${componentVersionString} ""]} {
            if {[string match "PHP" ${component}]} {
                set componentVersionString "- PHP [releasedPhpBranches ${yamlFile} ${phpBranches} ","]"
            }
            set result "${result}\n${componentVersionString}"
        }
    }

    # Show additional custom message
    if {[info exists ::env(BITNAMI_EXTRA_CHANGELOG)] && (![string match ${::env(BITNAMI_EXTRA_CHANGELOG)} ""])} {
        set result "${result}\n\n${additionalInfo}"
        set result "${result}\n\n${extraChangelog}"
    }

    return ${result}
}

proc updateApacheFriendsRepo {} {
    # Variables
    set bitnamiCodePath [file dirname [file dirname [file normalize [info script]]]]
    set projectsDir [file dirname [file normalize ${bitnamiCodePath}]]
    set apachefriendsRepo [file join ${projectsDir} "apachefriends-web"]
    set phpBranches "7.4 8.0 8.1"
    set blogComponentsList "PHP Apache MariaDB Perl OpenSSL phpMyAdmin"

    # Clone apachefriends-web if necessary
    message info "Cloning 'apachefriends-web'..."
    if {![file exists ${apachefriendsRepo}]} {
        cd ${projectsDir}
        puts "Cloning 'apachefriends-web' repo..."
        logexec git clone ssh://git@endor.nami:/apachefriends-web
    } else {
        puts "'${apachefriendsRepo}' already exists"
    }

    # Update apachefriends-web/downloads.yaml file using yq
    message info "Updating 'downloads.yml' file..."
    set downloadsYamlFile [file join ${apachefriendsRepo} downloads.yml]
    set newDownloadsYamlFile [file join $::env(HOME) releases bitnami-code apps xampp xampprelease.yml]

    # Apply changes
    logexec yq write --inplace --script ${newDownloadsYamlFile} ${downloadsYamlFile}

    # Create new blog post
    message info "Generating new blog post..."
    set publishDate [clock format [clock seconds] -format "%Y%m%d"]
    set blogPostDate [clock format [clock seconds] -format "%Y/%m/%d"]
    set newBlogFile [file join ${apachefriendsRepo} "source" blog "new_xampp_${publishDate}.md"]
    set blogEntryText "\-\-\-
title: New XAMPP release [releasedPhpBranches ${newDownloadsYamlFile} ${phpBranches} ","]
date: ${blogPostDate}
\-\-\-

Hi Apache Friends!

We just released a new version of XAMPP. You can download these new installers at \[http://www.apachefriends.org/download.html\](/download.html).

These installers include the next components:

\*\*[releasedPhpBranchesRevision ${newDownloadsYamlFile} ${phpBranches}]\*\*
[addComponentsVersion ${newDownloadsYamlFile} ${blogComponentsList} ${phpBranches}]

Enjoy!
"

    # Write new blog file
    xampptcl::file::write ${newBlogFile} ${blogEntryText}

    # Create new commit
    message info "Updating 'apachefriends-web' repo..."
    cd ${apachefriendsRepo}
    logexec git add ${downloadsYamlFile}
    logexec git add ${newBlogFile}
    logexec git commit -m "Released XAMPP ${publishDate}"
    logexec git pull --rebase
    # The commit will launch a new deploy from jenkins-webdev
    logexec git push origin master
    cd ${bitnamiCodePath}
}

proc uploadToFastly {versions destinationBucket} {
    set filename [file tail $file]
    set version ""
    foreach version $versions {
        if {[string match *$version* $filename]} {
            # Revision is not present in the "version" variable
            break
        }
    }
    if {$version == ""} {
        ::release::logError "Cannot detect the version for uploading $f to Fastly's bucket on Google Cloud"
    }
    set origin $file
    if {![regexp -- {^s3://(.*)} $origin]} {
        set origin "s3://$origin"
    }

    set destination [join [list $destinationBucket $version {}] "/"]
    if {![regexp -- {^gs://(.*)} $destination]} {
        set destination "gs://$destination"
    }

    #Copying from the correct S3 bucket to Google Cloud bucket
    ::release::gsutil cp -a public-read $origin $destination
}
proc uploadToSourceForge {host remotePath sessionSocket {versions {}} {releasesDir {}}} {
    if {$releasesDir == ""} {
        set releasesDir [file join $::env(HOME) releases bitnami-code apps xampp]
    }
    set filename [file tail $file]
    set version {}
    foreach version $versions {
        if {[string match *$version* $filename]} {
            # Revision is not present in the "version" variable
            break
        }
    }
    if {$version == ""} {
        ::release::logError "Cannot detect the version for uploading $filename to SourceForge"
    }
    switch -glob -- $filename {
        xampp*osx* - XAMPP-VM-* {
            set platformDir "XAMPP Mac OS X"
        }
        xampp*linux* {
            set platformDir "XAMPP Linux"
        }
        xampp*windows-x64* {
            set platformDir "XAMPP Windows"
        }
        default {
            ::release::logError "Cannot detect the platform for uploading $filename to SourceForge"
        }
    }
    set remotePath [file join $remotePath $platformDir]

    #The dot, used with --relative below, creates the directory for the new version.
    set localPath [file join $releasesDir . $version]
    file mkdir $localPath
    file rename [file join $releasesDir $filename] [file join $localPath $filename]

    #Option to allow path with spaces
    set rsyncOpts "--protect-args --progress --delete-after"

    #Option to allow creating the folder for a new version
    set rsyncOpts "$rsyncOpts --relative"

    #Adding some flags to increase the upload speed
    set rsyncOpts "$rsyncOpts -HAaXxuv --numeric-ids -e \"ssh -T -c arcfour -o Compression=no -o 'ControlPath=$sessionSocket' -x\""

    ::release::logInfo "Uploading $filename..."
    ::release::debug   " rsync $rsyncOpts [file join $localPath $filename] ${host}:\"$remotePath\""
    xampptcl::util::nonBlockingExecUnix rsync "$rsyncOpts [file join $localPath $filename] ${host}:\"$remotePath\""
    ::release::logInfo "... done"
}

public method updateXamppDefaultInstallers {} {
    set platforms "linux-x64 windows-x64 osx-x64"
    set topologies {linux-x64 "linux-x64" windows-x64 "windows-x64" osx-x64 "stackmandebian-osx-x64"}
    set sourceForgeFolders {linux-x64 "XAMPP Linux" windows-x64 "XAMPP Windows" osx-x64 "XAMPP Mac OS X"}
    set sourceForgePlatforms {linux-x64 "linux" windows-x64 "windows" osx-x64 "mac"}
    set stackNames {linux-x64 "xamppunixinstaller74stack" windows-x64 "xamppinstaller74stack" osx-x64 "xamppunixinstaller74stack"}
    set curlCmd "/usr/bin/curl -i -# -X PUT -H \"Accept: application/json\" -d \"api_key=${::env(SOURCEFORGE_API_KEY)}\""
    set baseUrl "https://sourceforge.net/projects/xampp/files"

    foreach platform ${platforms} {
        set platformData "-d \"default=[dict get ${sourceForgePlatforms} ${platform}]\""
        set folder [dict get ${sourceForgeFolders} ${platform}]
        set phpVersion [::release::createStack getStackInfo [dict get ${stackNames} ${platform}] "version"]
        set installerName [::release::createStack getStackInstallerName [dict get ${stackNames} ${platform}] [dict get ${topologies} ${platform}]]
        # OS X is a .dmg file once signed
        if {[string match "osx-x64" ${platform}]} {
            set installerName [string map {app dmg} ${installerName}]
        }

        set url "${baseUrl}/${folder}/${phpVersion}/${installerName}"
        set scriptFile [file join [file normalize [pwd]] setDefaultInstaller.sh]
        set scriptText "#!/bin/bash
${curlCmd} ${platformData} \"${url}\"
"
        # Write script and execute
        xampptcl::file::write ${scriptFile} ${scriptText}
        file attributes ${scriptFile} -permissions 0775
        logexec ${scriptFile}
        file delete -force ${scriptFile}
    }
}

public method uploadXamppToSourceForge {versions unreleasedDir} {                                                                                                                                                                                                                   set apiUrl "frs.sourceforge.net"
    set remotePath "/home/frs/project/x/xa/xampp/"
    set user "bitnami"
    set project "XAMPP"
    set userlogin [join [list $user $project] ","]
    set host "$userlogin@$apiUrl"
    if {![isInteractive]} {
        set sfPassword [string trim $::env(SOURCEFORGE_PASSWORD)]
    } else {
        set sfPassword [xampptcl::util::showPasswordQuestion "Please enter the password for SourceForge."]
    }
    # SourceForge ssh first connection is quite slow, increasing the timeout to 10 seconds is needed
    set sessionSocket [xampptcl::util::initialiazeSshSession $host $sfPassword 10]
    if {![file exists $sessionSocket]} {
        ::release::logError "Error establishing SSH connection to $host, socket $sessionSocket not created"
    }

    ::release::logInfo "Connection established"
    foreach j [$this cget -jobs] {
        if {![$j failed]} {
            if {[catch {
                $j uploadToSourceForge $host $remotePath $sessionSocket $versions $unreleasedDir
            } kk]} {
                xampptcl::util::closeSshSession $sessionSocket
                ::release::logError $kk
            }
        }
    }
    xampptcl::util::closeSshSession $sessionSocket
    ::release::logInfo "Installers uploaded to SourceForge. Please go to https://sourceforge.net/projects/xampp and update the default installer for each platform."
}
