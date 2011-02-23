#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"


###############################################################
# Run this script to automatically comment tcl files.
# Then fill in the comment headers.
# See slicer2/Modules/vtkCustomModule/tcl/@Modulename@.tcl.in 
# for an example of how to fill in the headers.  
###############################################################

set cwd [pwd]
cd [file dirname [info script]]
cd ..
set SLICER_HOME [pwd]
cd $cwd

puts "SLICER_HOME = $::SLICER_HOME"

proc Usage { {msg ""} } {
    set msg "$msg\nAutomatically comments tcl files (empty comment header\nfor each proc and copyright message at the top)"
    set msg "$msg\nusage: comment.tcl  \[options\] \[filename\]"
    set msg "$msg\n  \[options\] is one of the following:"
    set msg "$msg\n   --help : prints this message and exits"
    set msg "$msg\n   --nomods : don't comment the module files"
    set msg "$msg\n   --mod: the filename is the name of a module, just comment it"
    set msg "$msg\n   --verbose: print out lots of info about the processing"
    set msg "$msg\n  \[filename\] if provided will be commented, otherwise all tcl and cxx files will be commented."
    puts stderr $msg
}

# read any command line args
set argc [llength $argv]

set strippedargs ""
set ::doModsFlag 1
set ::isModFlag 0
set ::verbose 0

for {set i 0} {$i < $argc} {incr i} {
    set a [lindex $argv $i]
    switch -glob -- $a {
        "--help" -
        "-h" {
            Usage
            exit 1
        }
        "--nomods" {
            set ::doModsFlag 0
        }
        "--mod" {
            set ::isModFlag 1
        }
        "--verbose" {
            set ::verbose 1
        }
        "-*" {
            Usage "unknown option $a\n"
            exit 1
        }
        default {
            lappend strippedargs $a
        }
    }
}
set argv $strippedargs
set argc [llength $argv]

# Comment the tcl files and add copyrights
puts "Commenting the requested files"
source $::SLICER_HOME/Base/tcl/GoComment.tcl 

