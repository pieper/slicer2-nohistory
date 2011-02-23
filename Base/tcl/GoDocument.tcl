
# Check if the user invoked this script incorrectly
if {$argc > 1} {
    puts "UNIX Usage: tclsh GoDocument.tcl [doc | tcl]"
    puts "Windows Usage: tclsh82.exe GoDocument.tcl [doc | tcl]"
    exit
}

# Determine Slicer's home directory from the SLICER_HOME environment 
# variable, or the root directory of this script ($argv0).
if {[info exists ::SLICER_HOME] == 0 || $::SLICER_HOME == ""} {
    set prog [file dirname $argv0]
} else {
    set prog [file join $::SLICER_HOME Base/tcl]
}

# Set the SLICER_DOC environment variable to output html files 
# into another doc directory.  If you want them to go into /mystuff/Doc,
# set SLICER_DOC to mystuff/Doc.

if {[info exists ::SLICER_DOC] == 0 || $::SLICER_DOC == ""} {
    set outputdir [file join $::SLICER_HOME Doc]
} else {
    set outputdir $::SLICER_DOC
}

puts "prog $prog output $outputdir"

# Read source files
source [file join [file join $prog tcl-main] Comment.tcl]
source [file join [file join $prog tcl-main] Document.tcl]

# Run
if {$::verbose} {
    puts "argv = $argv"
}

# change in the calling sequence, assumes you want to do both tcl and docs unless otherwise specified
set what ""
if {$::doTclFlag} {
    lappend what tcl
}
if {$::doDocFlag} {
    lappend what doc
}
if {$::verbose} {
    puts "what = $what, modulename = $::moduleName"
}
DocumentAll $prog $outputdir $what $::moduleName
# exit
