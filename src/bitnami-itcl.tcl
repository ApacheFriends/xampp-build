package provide bitnami::itcl 1.0



package require Itcl

if {[info commands ::itcl::class_orig] == ""} {
    array set ::itcl::xamppInternallClasses {}
    rename itcl::class itcl::class_orig
    rename itcl::parser::inherit ::itcl::parser::inherit_orig
}

namespace eval itcl {
    proc class {className args} {
        # To simplify, we use just className
        set ::itcl::xamppCurrentClass $className
        uplevel 1 itcl::class_orig $className $args
    }
    proc parser::markAsInternal {args} {
        set ::itcl::xamppInternallClasses($::itcl::xamppCurrentClass) 1
    }
    proc parser::inherit {args} {
        foreach parent $args {
            lappend ::itcl::xamppClassParents($::itcl::xamppCurrentClass) $parent
        }
        uplevel 1 itcl::parser::inherit_orig $args
    }

    proc isClassType {className type} {
        if {$className == "$type"} {
            return 1
        } elseif {[info exists ::itcl::xamppClassParents($className)]} {
            foreach parent $::itcl::xamppClassParents($className) {
                if [itcl::isClassType $parent $type] {
                    return 1
                }
            }
            return 0
        } else {
            return 0
        }
    }
    proc isInternalClass {className} {
        return [info exists ::itcl::xamppInternallClasses($className)]
    }
    proc isProgramClass {className} {
        if {$className == "program"} {
            return 1
        } elseif {[info exists ::itcl::xamppClassParents($className)]} {
            foreach parent $::itcl::xamppClassParents($className) {
                if [itcl::isProgramClass $parent] {
                    return 1
                }
            }
            return 0
        } else {
            return 0
        }
    }
}
