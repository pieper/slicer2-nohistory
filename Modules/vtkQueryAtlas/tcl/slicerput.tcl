#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: slicerput.tcl,v $
#   Date:      $Date: 2006/05/26 19:58:14 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        slicerput.tcl
# PROCEDURES:  
#==========================================================================auto=

#
# slicerput - sp 2005-09-23
# - communicates with slicerd
# - reads nrrd streams from stdin and puts them into slicer
#

array set nrrd_to_vtk_types { char 2 "unsigned char" 3 short 4 ushort 5 int 6 uint 7 float 10 double 11 }

set name [lindex $argv 0]
if { $name == "" } {
    set name "from_slicerput"
}


gets stdin magic
if { ! [string match "NRRD*" $magic] } {
    puts stderr "bad magic number $magic"
    exit -1
}

set dimensions ""
set space_origin "(0,0,0)"
set space_directions "(1,0,0) (0,1,0) (0,0,1)"
set components 1
set scalar_type $nrrd_to_vtk_types(short)


while { [gets stdin line] > 0 } {
    switch -glob -- $line {
        "type:*" {
            set scalar_type $nrrd_to_vtk_types([lrange $line 1 end])
        }
        "dimension:*" {
            if { [lindex $line 1] != 3 } {
                puts stderr "only 3 dimensional images supported"
            }
        }
        "sizes:*" {
            set dimensions [lrange $line 1 end]
        }
        "space directions:*" {
            set space_directions [lrange $line 2 end]
        }
        "space origin:*" {
            set space_origin [lrange $line 2 end]
        }
    }
}

puts "put"
puts "image $name"
puts "dimensions $dimensions"
puts "space_origin $space_origin"
puts "space_directions $space_directions"
puts "components $components"
puts "scalar_type $scalar_type"

set sock [socket localhost 18943]
puts $sock "put"
puts $sock "image $name"
puts $sock "dimensions $dimensions"
puts $sock "space_origin $space_origin"
puts $sock "space_directions $space_directions"
puts $sock "components $components"
puts $sock "scalar_type $scalar_type"
flush $sock

fconfigure stdin -translation binary -encoding binary
fconfigure $sock -translation binary -encoding binary
set imagedata [read -nonewline stdin]
puts "read [string length $imagedata] bytes"
puts -nonewline $sock $imagedata
flush $sock
close $sock

exit 0
