# We need to pass a message and the list of applications we want to update
source [file normalize [info script]/../../../src/util.tcl]

if {[lindex $argv 0]=="help" || [llength $argv]==0} {
    puts "Usage: tclkit update-changelog.tcl \"message\" \"list of applications (use shortname)\""
    exit
}

set applist [lindex $argv 1]

foreach f $applist {
    set changelogFile [file normalize [info script]/../../../apps/$f/changelog.txt]
    if { [xampptcl::util::isPresentInFile $changelogFile @@XAMPP_DATE@@] } {
        xampptcl::util::substituteParametersInFile $changelogFile \
            [list {@@XAMPP_DATE@@} "@@XAMPP_DATE@@\n* [lindex $argv 0]"]
        puts "$f changelog updated."
    } else {
        xampptcl::util::substituteParametersInFileRegex $changelogFile \
           [list "=* CHANGELOG =*" "============ CHANGELOG =============\n\nVersion @@XAMPP_APPLICATION_VERSION@@      @@XAMPP_DATE@@\n*[lindex $argv 0]"]
           if { [xampptcl::util::isPresentInFile $changelogFile @@XAMPP_DATE@@] } {
               puts "$f changelog updated."
           } else {
               puts "$f changelog was not updated."
          }
    }
    exec git add $changelogFile
}
