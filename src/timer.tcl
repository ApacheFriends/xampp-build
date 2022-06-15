package provide bitnami::timer 1.0

namespace eval bitnami {
    ::itcl::class timer {
        public variable times
        public variable events {}
        public variable elapsed
        public variable sections {}
        public variable date [clock format [clock seconds] -format "%Y%m%d"]
        public variable jobAction
        public variable jobProduct
        public variable jobNumber
        public variable jobTarget
        public variable file_output_directory
        public variable fileName
        public variable s3Path
        public variable outputFilePath
        public variable text ""
        public variable jobVersion
        public variable jobRevision

        constructor {} {
            array set times {}
            array set elapsed {}
        }
        public method start {eventName} {
            if {![info exists times(${eventName}.start)]} {
                lappend events $eventName
                addSection $eventName
                set elapsed($eventName) {}
                set times(${eventName}.start) [clock seconds]
            } else {
                message warning "Start time of event $eventName was already registered"
            }
        }
        public method stop {eventName} {
            if {[info exists times(${eventName}.stop)]} {
                message warning "Stop time of event $eventName was already registered"
            } elseif {![info exists times(${eventName}.start)]} {
                message warning "Event $eventName does not exist"
            } else {
                set times(${eventName}.stop) [clock seconds]
                set elapsed($eventName) [expr $times(${eventName}.stop) - $times(${eventName}.start)]
            }
        }
        public method clear {{eventName {}}} {
            if {$eventName == ""} {
                array unset times *
                array unset elapsed *
                array set times {}
                array set elapsed {}
                set text ""
            } elseif {![info exists elapsed($eventName)]} {
                message warning "Event $eventName does not exist"
            } else {
                array unset elapsed ${eventName}
                array unset times ${eventName}.start
                # The stop time may have not been registerd
                catch {unset times ${eventName}.stop}
                set events [lremove $events $eventName]
            }
        }
        public method setValues {jobAction jobProduct jobNumber jobTarget jobFolder jobVersion jobRevision} {
            set properties [list jobAction $jobAction jobProduct $jobProduct jobNumber $jobNumber jobTarget $jobTarget jobVersion $jobVersion jobRevision $jobRevision]
            foreach {property value} $properties {
                configure -${property} $value
            }

            configure -fileName ${jobAction}-${jobProduct}-${jobTarget}-${jobNumber}.time
            configure -s3Path apachefriends/stats/${jobFolder}/$date
            configure -file_output_directory /tmp/stats/${jobFolder}/$date
            configure -outputFilePath [file join $file_output_directory $fileName]

        }
        public method addSection {eventName} {
            set sectionName ""
            regexp -- {^([a-zA-Z0-9]+)\.?.*$} $eventName - sectionName
            if {[lsearch $sections $sectionName] == -1} {
                lappend sections $sectionName
            }
        }
        public method lremove {list elements} {
            foreach e $elements {
                while {[set position [lsearch -exact $list $e]] != "-1"} {
                    set list [lreplace $list $position $position]
                }
            }
            return $list
        }
        public method getEventsInSection {section} {
            set eventList {}
            foreach e $events {
                if {([string match $section* $e] == 1) && $elapsed($e) > 0} {
                    lappend eventList $e
                }
            }
            # Remove matched events so next calls will run faster
            set events [lremove $events $eventList]
            return $eventList
        }
        public method uploadToS3 {} {
            # jobNumber will be 0 when running from docker
            if {$jobNumber == 0 || ([info exists ::env(NO_TIMER_S3_REPORT)] && $::env(NO_TIMER_S3_REPORT))} {
                return
            }
            set uploaded 1
            if { [catch {
                set cwd [pwd]
                cd /tmp

                # Write script modifying environment to avoid /bitnami references
                xampptcl::file::write s3cmdUpload.sh "
#!/bin/bash

unset PYTHON
unset PYTHONHOME
unset PYTHON_ROOT
LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/lib/i386-linux-gnu:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

s3cmd put --multipart-chunk-size-mb=7 -f $outputFilePath s3://${s3Path}/${fileName}
"

                file attributes s3cmdUpload.sh -permissions 0755
                exec ./s3cmdUpload.sh 2>@1
                cd $cwd
            } uploadResult] } {
                # Could not be uploaded
                set uploaded 0
                puts $uploadResult
            }

            if {$uploaded == 1} {
                puts "------"
                puts "Uploading: $outputFilePath"
                puts "md5: [lindex [exec md5sum $outputFilePath] 0]"
                puts "Uploaded to s3://${s3Path}/${fileName}"
                puts "------"
            } else {
                puts "File from $outputFilePath could not be uploaded to s3://$s3Path"
            }
        }
        public method getReport {} {
            # Remove compilation section if we are not running a buildTarball
            if {$jobAction != "buildTarball"} {
                set sections [lremove $sections "compilation"]
            }

            # File header
            append text "\[data\]\ndate=${date}\nversion=${jobVersion}\nrevision=${jobRevision}\n"

            foreach s $sections {
                set eventList [getEventsInSection $s]
                if {$eventList != ""} {
                    append text "\[${s}\]\n"
                    foreach e $eventList {
                        append text "${e}=$elapsed(${e})\n"
                    }
                }
            }

            # Always show results on Jenkins report
            puts $text

            # Write result file and upload to s3
            if {![info exists $file_output_directory]} {
                file mkdir $file_output_directory
            }

            xampptcl::file::write $outputFilePath $text
            uploadToS3
        }
    }
}
