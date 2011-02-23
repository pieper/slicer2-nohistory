#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

###############################################################
# Run this script to automatically generate the slicer website
# (with tcl code documentation!).
#
# Then open slicer2/Doc/index.html to SEE the website.
# 
# All auto* files in the slicer2/Doc subdirectories will be
# combined into one index.html file for that subdirectory,
# with the appropriate website formatting.
#
# Also, all tcl files in your SLICER_HOME/Base/tcl directory will
# be parsed to create the info pages under the Developer's Guide
# in the website.  The quality of the documentation depends on 
# the comment program having been run recently.  
# This is the script slicer2/Scripts/document.tcl.
#
# ######  To edit the website: ########
# 1.Look in the slicer2/Doc/devl for formatting examples,
# also visible under Developer's Guide in the website.
# 2. Edit appropriate file and run this script.
#
# ######  To add a new file to the website: ########
# 1. Add an autoXX.html file to a subdirectory of slicer2/Doc.
# (auto* files will be combined in alphabetical order into index.html)
# 2. Edit slicer2/Doc/index.html to add your new section to the 
# table of contents.
# 3. Run this script.
#
###############################################################

set cwd [pwd]
cd [file dirname [info script]]
cd ..
set SLICER_HOME [pwd]
cd $cwd

puts "SLICER_HOME = $::SLICER_HOME"

proc Usage { {msg ""} } {
    set msg "$msg\nusage: document.tcl  \[options\]"
    set msg "$msg\n  \[options\] is one of the following:"
    set msg "$msg\n   --help : prints this message and exits"
    set msg "$msg\n   --no-doc: don't create the web pages from the auto html files"
    set msg "$msg\n   --no-tcl: don't create the tcl source file documentation"
    set msg "$msg\n   --no-doxy : does not generate the vtk class doxygen pages"
    set msg "$msg\n   --no-mods : skip doing the documentation for the modules"
    set msg "$msg\n   --mod : just do the documentation for the module specified, suppresses the other modules"
    set msg "$msg\n   --verbose : print out extra debugging info"
    puts stderr $msg
}

# read any command line args
set argc [llength $argv]

set DOCUMENT(dodoxy) 1
set strippedargs ""
set ::doModsFlag 1
set ::isModFlag 0
set ::verbose 0
set ::doDocFlag 1
set ::doTclFlag 1

for {set i 0} {$i < $argc} {incr i} {
    set a [lindex $argv $i]
    switch -glob -- $a {
        "--no-doxy" { 
            set DOCUMENT(dodoxy) 0
        }
        "--no-tcl" {
            set ::doTclFlag 0
        }
        "--no-doc" {
            set ::doDocFlag 0
        }
        "--help" -
        "-h" {
            Usage
            exit 1
        }
        "--no-mods" {
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
set ::moduleName [lindex $argv 0]

# Produce the web pages and tcl documentation
# exec 
puts "Producing documentation pages - web site and tcl code docs"
source $::SLICER_HOME/Base/tcl/GoDocument.tcl

if {$DOCUMENT(dodoxy) == 1} {

    # Produce the VTK class documentation, need environment variables set for doxygen

    set ::env(SLICER_DOC) [file join $::SLICER_HOME Doc]
    set ::env(SLICER_HOME) $::SLICER_HOME
    puts "\nProducing the Base/cxx VTK documentation, based on:\n\tSLICER_HOME = ${SLICER_HOME}\n\tSLICER_DOC = $::env(SLICER_DOC)"
    catch "eval exec \"doxygen $::SLICER_HOME/Base/cxx/Doxyfile\"" res
    puts $res

    set modulePaths ""
    set ::modDir [file join $::SLICER_HOME Modules]
    set modsToLink ""

    if {$::isModFlag} {
        
        if {$::moduleName != ""} {
            # set up this module's path
            set modulePaths [file join $::modDir $::moduleName]
            if {$::verbose} { puts "isModFlag is true, modname = $::moduleName" }
        }
    } else {
        # otherwise do all the modules
        if {$::doModsFlag} {
            if {$::verbose} { 
                puts "\nisModFlag $isModFlag, doModsFlag $::doModsFlag. Getting modulepaths in $::modDir."
            }
            set modulePaths [glob -nocomplain $::modDir/*]
        }
    }
    if {$::verbose} {
        puts "modulePaths = $modulePaths"
    }

    # now iterate through the module paths
    foreach modpath $modulePaths {
        set doxyfile [file join $modpath cxx Doxyfile]
        if {[file exist $doxyfile]} {
            # the doxyfile uses the modname env var to get the source and output dirs
            set ::env(MODNAME) [file tail $modpath]

            if {$::verbose} { puts "Found Doxyfile $doxyfile, with modname set to $::env(MODNAME)" } 
                
            set moddocdir [file join $::env(SLICER_DOC) vtk Modules $::env(MODNAME)]
            # create the output dir, as doxygen will barf if it's not there
            if {[catch {file mkdir $moddocdir} errmsg] == 1} {
                puts "Error creating dir $moddocdir:\n$errmsg"
            } else {
                puts "\nProducing the VTK documentation for module $::env(MODNAME)"
                catch "eval exec \"doxygen $doxyfile\"" res
                puts $res
                lappend modsToLink $::env(MODNAME) 
            }
        } else { 
            if {$::verbose} {
                # it's not really an error, could have non cxx modules
                puts "Doxyfile not found: $doxyfile"
            }
        }
    }
    # if we made any module pages, link them in from a top level html file
    if {$modsToLink != ""} {
        set htmlString "<TITLE>Doxygen Documentation for Modules</TITLE><H1>Doxygen Documentation for Modules</H1>"
        append htmlString "<ul>"
        foreach mod $modsToLink {
            append htmlString "<li><a href=\"${mod}/html/index.html\">${mod}</a>"
        }
        append htmlString "</ul>"
        if {$::verbose} { puts $htmlString }
        set htmlFname [file join $::env(SLICER_DOC) vtk Modules index.html]
        if {[catch {set fid [open $htmlFname "w"]} errmsg] == 1} {
            puts "Error writing file $htmlFname: $errmsg"
            puts "Here's your file contents:\n$htmlString"
        } else {
            puts $fid $htmlString
            close $fid
            puts "Wrote modules index file in $htmlFname"
        }
    }
}

