# Load dependencies
lappend ::auto_path .
package require bitnami::util

package provide bitnami::versions 1.0

# Default ini files locations
set _versionsFile [file join $::bitnami::rootPath metadata versions versions.ini]
set _revisionsFile [file join $::bitnami::rootPath metadata versions revisions.ini]

# ENV vars configuration
set versionsEnv "BITNAMI_VERSIONS_INI_FILE"
set revisionsEnv "BITNAMI_REVISIONS_INI_FILE"

# Override ini files locations from the environment
if { [info exists ::env(${versionsEnv})] && $::env(${versionsEnv}) != ""} {
    set _versionsFile $::env(${versionsEnv})
}
if { [info exists ::env(${revisionsEnv})] && $::env(${revisionsEnv}) != ""} {
    set _revisionsFile $::env(${revisionsEnv})
}

namespace eval versions {
    variable versionsFile "${_versionsFile}"

    #
    # Ini file expected structure:
    #
    # [section]
    # key=value
    #
    proc getFromFile {section {key "default"} {iniFile ""}} {
        if {$section == ""} {
            return -code error "Provide a component to get the version from"
        }
        if {$key == ""} {
            return -code error "Provide an id to get the version from"
        }
        if {$iniFile == ""} {
            return -code error "Provide a file to get the version from"
        } else {
            if {![file exists $iniFile]} {
                return -code error "${iniFile} does not exist"
            }
        }

        set value [bitnami::iniFileGet $iniFile $section $key "undefined"]
        if {$value == "undefined"} {
            return -code error "Unknown component '${section}' or id '$key'"
        }

        return $value
    }

    proc get {component id} {
        return [getFromFile $component $id $::versions::versionsFile]
    }
}

namespace eval revisions {
    variable revisionsFile "${_revisionsFile}"

    #
    # Ini file expected structure:
    #
    # [section]
    # key=value
    #
    proc getFromFile {section {key "default"} {iniFile ""}} {
        if {$section == ""} {
            return -code error "Provide a component to get the revision from"
        }
        if {$key == ""} {
            return -code error "Provide an id to get the revision from"
        }
        if {$iniFile == ""} {
            return -code error "Provide a file to get the revision from"
        } else {
            if {![file exists $iniFile]} {
                return -code error "${iniFile} does not exist"
            }
        }

        set value [bitnami::iniFileGet $iniFile $section $key "undefined"]
        if {$value == "undefined"} {
            error "Unknown component '${section}' or id '$key'"
        }

        return $value
    }

    proc get {component {id "default"}} {
        if {$component == ""} {
            error "Provide a component to get the version from"
        }

        return [getFromFile $component $id $::revisions::revisionsFile]
    }
}
