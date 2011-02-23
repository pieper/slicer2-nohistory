
# Check if the user invoked this script incorrectly
if {$argc > 1} {
    puts "UNIX Usage: tclsh GoComment.tcl [optional file]"
    puts "Windows Usage: tclsh82.exe GoComment.tcl [optional file]"
    exit
}

# Determine Slicer's home directory from the SLICER_HOME environment 
# variable, or the root directory of this script ($argv0).
if {[info exists ::SLICER_HOME] == 0 || $::SLICER_HOME == ""} {
    set ::SLICER_HOME [file normalize [file join [file dirname $argv0] .. ..]]
}
set prog [file join $::SLICER_HOME Base/tcl]
set moddir [file join $::SLICER_HOME Modules]


# Read source files
source [file join $prog [file join tcl-main Comment.tcl]]


# Run on one file if requested, otherwise on ALL files
set file [lindex $argv 0]
if {$file != ""} {
    puts $file
    # if the user noted that this is a module, just run on the module
    # if it's a directory, check if it's a module
    if {$::isModFlag || [file isdirectory [file join $moddir $file]]} {
        if {$::verbose} { puts "$file is a module" }
        # check to see that it exists
        set file [file join $moddir $file]
        if {[file exists $file] &&  [file isdirectory $file]} {
            ProcessModule $file $verbose
            return
        }
    } 

    # otherwise deal with it as a single file
    if {[file exists $file]} {
        set filename $file
    } else {
        # assume it's not been fully qualified
        # try adding it to this dir
        if {[file exists [file normalize [file join [file dirname $argv0] $file]]]} {
            set filename [file normalize [file join [file dirname $argv0] $file]]
        } else {
            if {[file exists [file join $::SLICER_HOME $file]]} {
                # slicer home dir
                set filename [file join $::SLICER_HOME $file]
            } else {
                if {[file exists [file join $prog $file]]} {
                    # Base/tcl subdir
                    set filename [file join $prog $file]
                } else {
                    #  modules dir
                    if {[file exists [file join $moddir $file]]} {
                        set filename [file join $moddir $file]
                    } else {
                        puts "Can't find this file $file, please call with a fully qualified path"
                        exit
                    }
                }
            }
        }
    }

    if {$::verbose} {
        # puts "NOT filename = $filename"
            puts "GoComment, calling \"ProcessFile $filename\""
    }
    ProcessFile $filename $verbose
} else {
    # Process all files
    set dirs "tcl-main tcl-modules tcl-shared ../cxx"
    if {[file exists [file join $prog tcl-modules Editor]] == 1} {
        set dirs "$dirs tcl-modules/Editor"
    }
    # add the Volumes sub dir
    if {[file exists [file join $prog tcl-modules Volumes]] == 1} {
        set dirs "$dirs tcl-modules/Volumes"
    }
    if {0} {  
     foreach dir $dirs {
        foreach file "[glob -nocomplain $prog/$dir/*.tcl] \
            [glob -nocomplain $prog/$dir/*.h] \
            [glob -nocomplain $prog/$dir/*.cxx]" {
            puts $file
            set filename [file join $prog $file]
            if {$::verbose} {
                #            puts "GoComment: NOT calling \"ProcessFile $filename\""
                puts "$filename"
            }
            ProcessFile $filename $::verbose
        }
    }
    }

    if {$::doModsFlag == 1} {
        puts "Processing modules..."
        # process files in modules
        set modulePaths [glob -nocomplain $moddir/*]
        foreach modpath $modulePaths {
            ProcessModule $modpath $::verbose

        }
    }
}


# exit
