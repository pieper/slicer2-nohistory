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
#   Module:    $RCSfile: slicerget.tcl,v $
#   Date:      $Date: 2007/02/09 21:01:48 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        slicerget.tcl
# PROCEDURES:  
#==========================================================================auto=

#
# slicerget - sp 2005-10-27
# - communicates with slicerd
# - gets nrrd streams from slicer and puts them into stdout
#

array set vtk_to_nrrd_types { 2 char 3 "unsigned char" 4 short 5 ushort 6 int 7 uint 10 float 11 double }
array set vtk_types_sizes { 2 1  3 1  4 2  5 2  6 4  7 4  10 4  11 8 }

set id [lindex $argv 0]
if { $id == "" } {
    puts stderr "usage: slicerget <id>"
    exit 1
}

set sock [socket localhost 18943]
puts $sock "get $id"
flush $sock

gets $sock line ;# should be "image $volid" 
if {$line eq "get error: bad id"} {
     puts stderr "No volume with id or name $id currently loaded in Slicer.\n"
     puts stdout "No volume with id or name $id currently loaded in Slicer.\n"
     exit 1
}
gets $sock name; set name [lindex $name 1]
gets $sock scalar_type; set scalar_type [lindex $scalar_type 1]
gets $sock dimensions; set dimensions [lrange $dimensions 1 3]
gets $sock space_origin; set space_origin [lrange $space_origin 1 end]
gets $sock space_directions; set space_directions [lrange $space_directions 1 end]

puts stderr "NRRD0001"
puts stderr "content: $name"
puts stderr "type: [set vtk_to_nrrd_types($scalar_type)]"
puts stderr "dimension: 3"
puts stderr "space: right-anterior-superior"
puts stderr "sizes: $dimensions"
puts stderr "space origin $space_origin"
puts stderr "space_directions $space_directions"
puts stderr "" ;# blank line before data

puts stdout "NRRD0001"
puts stdout "content: $name"
puts stdout "type: [set vtk_to_nrrd_types($scalar_type)]"
puts stdout "dimension: 3"
puts stdout "space: right-anterior-superior"
puts stdout "sizes: $dimensions"
puts stdout "space origin: $space_origin"
puts stdout "space directions: $space_directions"
puts stdout "encoding: raw"
puts stdout "endian: little" ;# TODO - this should be passed in!
puts stdout "" ;# blank line before data

set size [expr \
        [set vtk_types_sizes($scalar_type)] \
        * [lindex $dimensions 0] \
        * [lindex $dimensions 1] \
        * [lindex $dimensions 2] ]
        
puts stderr "want to read $size bytes"

fconfigure $sock -translation binary -encoding binary
set imagedata [read $sock $size]
puts stderr "read [string length $imagedata] bytes"
fconfigure stdout -translation binary -encoding binary
puts -nonewline stdout $imagedata
flush stdout
close $sock

exit 0

