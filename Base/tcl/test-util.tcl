
# a test utility script 
# - runs with a tkcon with the paths set by slicer.bat
# - accessed by  slicer.bat -test filename


global VTK_DATA_ROOT env

set VTK_DATA_ROOT $env(VTK_DATA_ROOT)


##################################################################################
##################################################################################
# copied from Go.tcl startup:


# Determine Slicer's home directory from the SLICER_HOME environment 
# variable, or the root directory of this script ($argv0).
    if {[info exists env(SLICER_HOME)] == 0 || $env(SLICER_HOME) == ""} {
        # set prog [file dirname $argv0]
    set prog [file dirname [info script]]
} else {
    set prog [file join $env(SLICER_HOME) Base/tcl]
}
# Don't use "."
    if {$prog == "."} {
    set prog [pwd]
}
# Ensure the program directory exists
    if {[file exists $prog] == 0} {
    tk_messageBox -message "The directory '$prog' does not exist."
    exit
}
    if {[file isdirectory $prog] == 0} {
    tk_messageBox -message "'$prog' is not a directory."
    exit
}
set Path(program) $prog


#
# set statup options - convert backslashes from windows
# version of SLICER_HOME var into to regular slashes
#
regsub -all {\\} $env(SLICER_HOME) / slicer_home
regsub -all {\\} $env(VTK_SRC_DIR) / vtk_src_dir
set auto_path "$slicer_home/Base/tcl $slicer_home/Base/Wrapping/Tcl/vtkSlicerBase $vtk_src_dir/Wrapping/Tcl $auto_path"

##################################################################################

set av ""
    if {$argv != ""} {
    set av $argv
    set argv ""
}

toplevel .dummy ;# avoid having tkcon show up in window "." so tests can use it
source $slicer_home/Base/tcl/tkcon.tcl
tkcon attach Main
destroy .dummy

    if {$av != ""} {
    source $av
}


#
# example - to run all the tests prompting for newline after each
# - these run in a new executable of slicer
# - as of 2002-05-09 this is enabled for windows only

    proc runall {} {
    set tests [glob Base/tests/*.tcl]
        foreach f $tests {
        puts $f
        catch "exec ./slicer.bat -test $f"
        puts "next...? (q to stop)"
        gets stdin line
            if {$line == "q"} {
            break
    }
}
}

