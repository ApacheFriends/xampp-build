set additionalOutputDirectory [lindex $argv 0]

if {($additionalOutputDirectory != "") && (![regexp {^s3://} $additionalOutputDirectory]) && [file exists $additionalOutputDirectory]} {
    puts "Looking for selenium tarballs with the form 'selenium-screenshots-*.tar.gz' in '$additionalOutputDirectory'"
    set filelist [glob -tails -nocomplain -directory $additionalOutputDirectory selenium-screenshots-*.tar.gz]

    # only generate the HTMl file if screenshots were present
    if {[llength $filelist] != 0} {

        foreach g $filelist {
            set wd [pwd]
            if {[catch {
                cd $additionalOutputDirectory
                exec tar -xzf $g 2>@1
                # file delete $g
            } kk]} {
                puts "downloadAdditionalOutput: unable to unpack screenshots file $g: $kk"
            }
            cd $wd
        }
        set filelist [lsort -dictionary [glob -tails -nocomplain -directory $additionalOutputDirectory screenshots/*.png]]

        if {[llength $filelist] > 0} {
            set imghtml {<html><body><ul>}
            foreach img $filelist {
                # first in a batch
                if {[regexp {^(.*?)-1\.png$} [file tail $img] - prefix]} {
                    append imghtml \n\n\n "<br /><br />"
                    append imghtml \n\n\n "<h2 style=\"border-bottom: 1px; border-top: 0px; border-left: 0px; border-right: 0px; border-style: solid; border-color: #000000; width: 90%\">$prefix</h2>\n"
                }
                set imgsize {0 0}
                catch {
                    set imgsize [getImageSizePng [file join $additionalOutputDirectory $img]]
                }
                if {[join $imgsize x] != "0x0"} {
                    set scale 4
                    set imgsize " width=\"[expr {[lindex $imgsize 0] / $scale}]\" height=\"[expr {[lindex $imgsize 1] / $scale}]\""

                }  else  {
                    set imgsize ""
                }
                append imghtml \n "<a href=\"$img\"><img src=\"$img\" $imgsize alt=\"[file tail $img]\" style=\"margin-right: 10px; margin-bottom: 20px; border-width: 1px; border-style: solid; border-color: black; vertical-align: top;\"/></a>"
            }
            append imghtml \n {</ul></body></html>}

            set htmlFilePrefix "selenium-"

            set htmlFile [file join $additionalOutputDirectory ${htmlFilePrefix}screenshots.html]
            puts "Generating HTML for Selenium screenshot results at $htmlFile"
            set fh [open $htmlFile w]
            puts $fh $imghtml
            close $fh
        }
    } else {
        puts "Casper tarballs not found. Usage:"
        puts ""
        puts "  $ tclkit $argv0 </path/to/folder/with/selenium/tarballs>"
        puts ""
    }

} else {
    puts "You need to provide a folder as input to work:"
    puts ""
    puts "  $ tclkit $argv0 </path/to/folder/with/selenium/tarballs>"
    puts ""
}
