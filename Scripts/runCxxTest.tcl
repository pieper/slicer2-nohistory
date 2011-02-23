#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

# 
# usage: runCxxTest.tcl executable [arguments]
# Run executable within a slicer environment.
#
# This script is executed by launch.tcl and will run the executable together
# with all the arguments within the slicer environment. There all the paths,
# including library paths and tcl settings.

if { $::argc < 1 } {
  puts "Usage: $::argv0 <executable>"
  exit 1
}

set ::execName [ lindex $::argv 0 ]

if { ! [ file exists $::execName ] } {
  set ::execName "[ file dirname $::execName ]/$::env(VTK_BUILD_TYPE)/[ file tail $::execName]"

     if { ! [ file exists $::execName ] } {

     set ::execName "[ lindex $::argv 0 ].exe"

         if { ! [ file exists $::execName ] } {
            set ::execName "[ file dirname $::execName ]/$::env(VTK_BUILD_TYPE)/[ file tail $::execName]"

            if { ! [ file exists $::execName ] } {
                puts "Cannot find file: $::execName"
                exit 1
            }
        }
    }
}

puts "Execute test: $::execName"

set ::insideArgs [ lrange $::argv 1 end ]
set ::command [ concat "exec" "$::execName"  $::insideArgs ]

puts "Invoke command: $::command"

set ::res [ catch $::command ::output ]
puts $::output
exit $::res
