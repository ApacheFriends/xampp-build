package provide bitnami::colors 1.0
set color_beep      "\a"
set color_clear	    "\[0m"
set color_bold		"\[1m"
set color_blink  	"\[5m"

#Normal colors
set color_red       "\[0;31m"
set color_green     "\[0;32m"
set color_yellow    "\[0;33m"
set color_blue      "\[0;34m"
set color_magenta   "\[0;35m"
set color_cyan      "\[0;36m"
set color_white     "\[0;37m"

#bright colors
set color_bright_grey       "\[1;30m"	
set color_bright_red        "\[1;31m"
set color_bright_green      "\[1;32m"
set color_bright_yellow     "\[1;33m"
set color_bright_blue       "\[1;34m"
set color_bright_magenta    "\[1;35m"
set color_bright_cyan       "\[1;36m"
set color_bright_white      "\[1;37m"



proc message {code text args} {
    if {$code == "fatalerror"} {
        set fatal 1
    } elseif {$code == "error" && [lindex $args 0] == 1} {
        set fatal 1
    } else {
        set fatal 0
    }
    if {[info exists ::env(BITNAMI_STDERR_MESSAGES)]} {
        set out stderr
    }  else  {
        set out stdout
    }

    if {[info exists ::env(BITNAMI_QUIET_MODE)] && $fatal != 1} {
        return
    }
    if {[info exists ::env(BITNAMI_NOCOLOR)]} {
        switch $code {
            beep {puts ""}
            default {puts $out $text}
        }
    }  else  {
        switch $code {
            nocolor {puts $out $text ; flush $out}
            info {puts $out "${::color_bright_cyan}$text${::color_clear}" ; flush $out}
            info2 {puts $out "${::color_bright_grey}$text${::color_clear}" ; flush $out}
            beep {puts $out "${::color_beep}" ; flush $out}
            error - fatalerror {
                puts $out "${::color_red}$text${::color_clear}" ; flush $out
                if {$fatal} {
                    exit 1
                }
            }
            error2 {puts stderr "${::color_red}$text${::color_clear}" ; flush stderr}
            warning {puts $out "${::color_yellow}$text${::color_clear}" ; flush $out}
            default {puts $out $text ; flush $out}
        }
    }
}

