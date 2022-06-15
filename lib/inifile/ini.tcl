# ini.tcl --
#
#       Querying and modifying old-style windows configuration files (.ini)
#
# Copyright (c) 2003-2007    Aaron Faupell <afaupell@users.sourceforge.net>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: ini-20120307.tcl,v 1.1 2012-03-12 09:41:39 juanjo Exp $
#
# 2012-03-01 MODIFIED by miguel@bitrock.com
#   - insure that the file format is respected, including comments and ordering 
#   - remove comment read/write capabilities
#   - replace arrays by list searches
#

package provide inifile 0.2.1

namespace eval ini {
    variable nexthandle; if {![info exists nexthandle]} {set nexthandle 0}
    variable commentchars; if {![info exists commentchars]} {set commentchars [list \; \#]}
    variable preserveunrecognizedlines 0
}

proc ::ini::open {ini {mode r+}} {
    variable nexthandle

    if { ![regexp {^(w|r)\+?$} $mode] } {
        error "$mode is not a valid access mode"
    }

    ::set fh ini$nexthandle
    ::set tmp [::open $ini $mode]
    fconfigure $tmp -translation auto

    namespace eval ::ini::$fh {
        variable lines {}
        variable data;     array set data     {}
    }
    ::set ::ini::${fh}::channel $tmp
    ::set ::ini::${fh}::file    [_normalize $ini]
    ::set ::ini::${fh}::mode    $mode

    incr nexthandle
    if { [string match "r*" $mode] } {
        _loadfile $fh
    }
    return $fh
}

# close the file and delete all stored info about it
# this does not save any changes. see ::ini::commit

proc ::ini::close {fh} {
    _valid_ns $fh
    ::close [::set ::ini::${fh}::channel]
    namespace delete ::ini::$fh
}

# write all changes to disk

proc ::ini::commit {fh} {
    _valid_ns $fh
    namespace eval ::ini::$fh {
        if { $mode == "r" } {
            error "cannot write to read-only file"
        }
        ::close $channel
        ::set channel [::open $file w]

	foreach line $lines {
	    puts $channel [string map {\3 {=}} [lindex [split $line \1] end]]
        }
        close $channel
        ::set channel [::open $file r+]
    }
    return
}

# internal command to read in a file
# see open and revert for public commands

proc ::ini::_loadfile {fh} {
    namespace eval ::ini::$fh {
        ::set cur {}
        ::set com {}
        ::set chars ^\\s*\[[join $::ini::commentchars {}]\]
        seek $channel 0 start

	::set lines {}
	::set cur {}
        foreach line [split [read $channel] "\n"] {
            if { ($line == "") || [regexp $chars $line] } {
		# a comment
		lappend lines $line
            } elseif { [string match {\[*\]} $line] } {
		# section start, mark with \1
		::set cur [string trim [string range $line 1 end-1]]
		lappend lines \1$line
            } elseif { [string match {*=*} $line] } {
		# value def, mark with \2$cur\1$key\3$val
		set line [string trim $line]
		lappend lines \2$cur\1[regsub {[ ]*=[ ]*} $line \3]
            } elseif {$::ini::preserveunrecognizedlines == 1} {
                lappend lines $line
            }

        }
        catch { unset line }
	if {[lindex $lines end] == ""} {
	    # remove extra empty line at end created by [split]
	    set lines [lrange $lines 0 end-1]
        }
    }
}

# internal command to escape glob special characters

proc ::ini::_globescape {string} {
    return [string map {* \\* ? \\? \\ \\\\ \[ \\\[ \] \\\]} $string]
}

# internal command to check if a section or key is nonexistant

proc ::ini::_exists {fh sec args} {
    ::set lines [::set ::ini::${fh}::lines]
    ::set idx [lsearch -exact $lines \1\[$sec\]]
    if { $idx == -1 } {
        error "no such section \"$sec\""
    }
    if { [llength $args] > 0 } {
        ::set key [lindex $args 0]
	::set idx [lsearch -glob -start $idx $lines [_globescape \2$sec\1$key\3]*]
	if {$idx == -1} {
            error "can't read key \"$key\""
        }
    }
}

# internal command to check validity of a handle

if { [package vcompare [package provide Tcl] 8.4] < 0 } {
    proc ::ini::_normalize {path} {
	return $path
    }
    proc ::ini::_valid_ns {name} {
	variable ::ini::${name}::data
	if { ![info exists data] } {
	    error "$name is not an open INI file"
	}
    }
} else {
    proc ::ini::_normalize {path} {
	file normalize $path
    }
    proc ::ini::_valid_ns {name} {
	if { ![namespace exists ::ini::$name] } {
	    error "$name is not an open INI file"
	}
    }
}

# get and set the ini comment character

proc commentchars { {new {}} } {
    ::set err 0
    if {![llength new]} {::set err 1}
    foreach ch $new {
	if {[string length $ch] != 1} {
	    ::set err 1
	    break
	}
    }
    if {$err} {
        error "commentchars argument should be a list of single characters"
    }

    ::set ::ini::commentchars $new
    return $::ini::commentchars
}

# return all section names

proc ::ini::sections {fh} {
    _valid_ns $fh
    ::set lines [::set ::ini::${fh}::lines]
    ::set slines [lsearch -glob -all -inline $lines \1*]
    ::set res {}
    foreach line $slines {
	# strip the \1 and [ at start, also the ] at end
	lappend res [string range $line 2 end-1]
    }
    return $res
}

# return boolean indicating existance of section or key in section

proc ::ini::exists {fh sec {key {}}} {
    _valid_ns $fh
    ::set cmd [list _exists $fh $sec]
    if { $key != "" } {
	lappend cmd $key
    }
    return [expr {![catch $cmd]}]
}

# return all key names of section
# error if section is nonexistant

proc ::ini::keys {fh sec} {
    _valid_ns $fh
    _exists $fh $sec
    ::set lines [::set ::ini::${fh}::lines]
    ::set keys {}
    foreach line [lsearch -all -inline -glob $lines [_globescape \2$sec\1]*] {
	# kval is a 2-list {key value}
	::set kval [split [lindex [split $line \1] end] \3]
	lappend keys [lindex $kval 0]
    }
    return $keys
}

# return all key value pairs of section
# error if section is nonexistant

proc ::ini::get {fh sec} {
    _valid_ns $fh
    _exists $fh $sec

    ::set lines [::set ::ini::${fh}::lines]
    ::set res {}
    foreach line [lsearch -all -inline -glob $lines [_globescape \2$sec\1]*] {
	# kval is a 2-list {key value}
	::set kval [split [lindex [split $line \1] end] \3]
	lappend res [lindex $kval 0] [lindex $kval 1]
    }

    return $res
}

# return the value of a key
# return default value if key or section is nonexistant otherwise error

proc ::ini::value {fh sec key {default {}}} {
    _valid_ns $fh

    ::set lines [::set ::ini::${fh}::lines]
    ::set idx [lsearch -glob $lines [_globescape \2$sec\1$key\3]*]

    if {$idx == -1} {
	if {$default != ""} {
        return $default
    }
	# get the correct error msg
    _exists $fh $sec $key
    }
    return [lindex [split [lindex $lines $idx] \3] end]
}

# set the value of a key
# new section or key names are created

proc ::ini::set {fh sec key value} {
    _valid_ns $fh
    upvar 0 ::ini::${fh}::lines lines

    ::set sec [string trim $sec]
    ::set key [string trim $key]
    if { $sec == "" || $key == "" } {
        error "section or key may not be empty"
    }

    ::set newline \2\$sec\1$key\3$value

    ::set secstart [lsearch -exact $lines \1\[$sec\]]
    if {$secstart == -1} {
	# section does not exist: create it!
	lappend lines \1\[$sec\]
	lappend lines $newline
	return $value
    }

    incr secstart
    ::set keyline [lsearch -start $secstart -glob $lines [_globescape \2$sec\1$key\3]*]

    if {$keyline != -1} {
	# found the line: replace it
	lset lines $keyline $newline
	return $value
    }

    # no corresponding line: compute where to insert it, at section end
 
    ::set secend [lsearch -start $secstart -glob $lines \1*]
    if {$secend == -1} {
	# last section, insert at end
	::set secend [llength $lines]
    }

    ::set lines [linsert $lines $secend $newline]
    return $value
}

# delete a key or an entire section
# may delete nonexistant keys and sections

proc ::ini::delete {fh sec {key {}}} {
    _valid_ns $fh
    upvar 0 ::ini::${fh}::lines lines

    if { $key == "" } {
	# delete section lines
	::set idxs [lsearch -exact -all $lines \1\[$sec\]]
	foreach idx $idxs {
	    lset lines $idx \0
    }

	# find all key/value lines in the section
	::set idxs [lsearch -glob -all $lines [_globescape \2$sec\1]*]
    } else {
	# find the key/value line2 
	::set idxs [lsearch -glob -all $lines [_globescape \2$sec\1$key\3]*]
    }

    foreach idx $idxs {
	lset lines $idx \0
    }

    ::set old $lines
    ::set lines {}
    foreach line $old {
	if {[string equal $line \0]} continue
	lappend lines $line
    }
}

# return the physical filename for the handle

proc ::ini::filename {fh} {
    _valid_ns $fh
    return [::set ::ini::${fh}::file]
}

# reload the file from disk losing all changes since the last commit

proc ::ini::revert {fh} {
    _valid_ns $fh
    namespace eval ::ini::$fh {
        array set data     {}
        array set comments {}
        array set sections {}
	variable section_order {}
    }
    if { ![string match "w*" $mode] } {
        _loadfile $fh
    }
}
