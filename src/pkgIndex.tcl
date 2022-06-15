package ifneeded bitnami::colors 1.0 [list source [file join $dir color.tcl]]
package ifneeded bitnami::util 1.0 [format {source [file join %s util.tcl];::bitnami::initialize} $dir]
package ifneeded bitnami::itcl 1.0 [list source [file join $dir bitnami-itcl.tcl]]
