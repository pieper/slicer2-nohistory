package require vtkSlicerBase

# get the list of header files in the Base
set flist [glob $::env(SLICER_HOME)/Base/cxx/*.h]

puts "Testing [llength $flist] classes..."

set numFailedDeclare 0
set numFailedDelete 0
set numSuccess 0
set numSkipped 0
set successList {}
set failDeclareList {}
set failDeleteList {}
set skippedList {}
set exitCode 0
set curClassNum 1

foreach f $flist {
    # get a potential class name
    set classname [file root [file tail $f]]

    # is it a vtk class?
    if {[regexp "^vtk.*" $classname matchvar] == 1 &&
        [regexp ".*Macro$" $classname matchvar] == 0 &&
        [regexp ".*Header$" $classname matchvar] == 0 &&
        [regexp "^vtkMrmlData$" $classname matchvar] == 0 &&
        [regexp "^vtkMrmlNode$" $classname matchvar] == 0 &&
        [regexp "^vtkSlicer$" $classname matchvar] == 0} {
        puts "$curClassNum: Testing $classname"
        if {[catch "$classname myclass" errmsg] == 1} {
            puts "$errmsg"
            if {[regexp "^invalid command name" $errmsg] == 0} {
                incr numFailedDeclare
                lappend failDeclareList $classname
            } else {
                # it wasn't built, commented out in CMakeLists.txt most likely
                puts "\tskipping, not built"
                incr numSkipped
                lappend skippedList $classname
            }
        } else {
            puts "\tdeclaration passed, deleting"
            if {[catch "myclass Delete" errmsg] == 1} {
                puts "Delete failed: $errmsg"
                incr numFailedDelete
                lappend failDeleteList $classname
            } else {
                incr numSuccess
                lappend sucessList $classname
            }
        }
    } else { 
        puts "$curClassNum: Skipping $classname" 
        incr numSkipped
        lappend skippedList $classname
    }
    incr curClassNum
}

if {$numFailedDeclare > 0} {
    puts "Failed on Declare:"
    foreach d $failDeclareList {
        puts "\t$d"
    }
}
if {$numFailedDelete > 0} {
    puts "Failed on Delete:"
    foreach d $failDeleteList {
        puts "\t$d"
    }
}
if {$numSkipped > 0} {
    puts "Skipped:"
    foreach s $skippedList {
        puts "\t$s"
    }
}


set exitCode [expr $numFailedDeclare + $numFailedDelete]

puts "$numSuccess classes passed, $numFailedDeclare failed on declaration, $numFailedDelete failed on delete (skipped $numSkipped).\nExiting with code $exitCode"

exit $exitCode
