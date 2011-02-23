#=auto==========================================================================
# Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#  See Doc/copyright/copyright.txt
#  or http://www.slicer.org/copyright/copyright.txt for details.
# 
#  Program:   3D Slicer
#  Module:    $RCSfile: Go.tcl,v $
#  Date:      $Date: 2007/03/16 20:01:41 $
#  Version:   $Revision: 1.123 $
#===============================================================================
# FILE:        Go.tcl
# PROCEDURES:  
#   exit code
#   Usage msg
#   SplashRaise fileName verbose
#   SplashKill
#   SplashShow delayms
#   VTK_AT_LEAST version
#   ReadModuleNames filename
#   FindNames dir
#   ReadModuleNamesLocalOrCentral name ext
#   GetFullPath name ext dir verbose
#   START_THE_SLICER
#==========================================================================auto=

# remove the toplevel window until it has something useful to show
wm withdraw .
update

#-------------------------------------------------------------------------------
# .PROC exit
#
# override the built in exit routine to provide cleanup
# (for people who type exit into the console)
# .ARGS
# str code optional exit code to pass back to the calling process
# .END
#-------------------------------------------------------------------------------
rename exit tcl_exit
proc exit { "code 0" } {
    if { [info command MainExitProgram] != "" } {
        MainExitProgram $code
    } else {
        tcl_exit $code
    }
}


#-------------------------------------------------------------------------------
# .PROC bgerror
#
# override the built in bgerror routine to provide extra feedback on memory condidtions
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc bgerror {err} {slicer_bgerror $err}
proc slicer_bgerror { err } {
    SplashKill ;# get rid of the splash screen if it exists
    set msg "Slicer has experienced an application error and may no longer be in a stable state (restart slicer if you observe unusual behavior).\n\nIt is possible you have run out of memory.\n\nThe following dialog box provides support information.  If this is a repeatable issue, please file a bug report at http://www.na-mic.org/Bug"
    DevErrorWindow $msg
    ::tk::dialog::error::bgerror $err
    proc bgerror {err} {slicer_bgerror $err}
}


#######################
# version number control for slicer
#

# bump major when incompatibile changes happen either within slicer
# or in vtk or tcl

set ::SLICER(major_version) 2

# bump minor when features accumulate to a stable state for release

set ::SLICER(minor_version) 8

# bump revision for something that has been given out to non-developers
# (e.g. bump revsion before packaging, then again after packaging
#  so there's a unique label for the packaged version)

set ::SLICER(revision) ""

# when packaging a release for distribution, set state to "-opt"
# when packaging a release candidate, set state to "-rc#" with the candidate number
# when packaging a release for testing, set state to the date as "-YYYY-MM-DD"
#  otherwise leave it as "-dev"

set ::SLICER(state) "-dev"

set ::SLICER(version) "$::SLICER(major_version).$::SLICER(minor_version)$::SLICER(revision)$::SLICER(state)"


#
######################




#-------------------------------------------------------------------------------
# .PROC Usage
# simple command line argument parsing
# .ARGS
# str msg optional preamble to the message, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc Usage { {msg ""} } {
    global SLICER
    
    set msg "$msg\nusage: slicer2-<arch> \[options\] \[MRML file name .xml | dir with MRML file | tcl script\]"
    set msg "$msg\n  <arch> is one of win32.exe, solaris-sparc, or linux-x86"
    set msg "$msg\n  \[options\] is one of the following:"
    set msg "$msg\n   --help : prints this message and exits"
    set msg "$msg\n   --verbose : turns on extra debugging output"
    set msg "$msg\n   --no-threads : disables multi threading"
    set msg "$msg\n   --no-tkcon : disables tk console"
    set msg "$msg\n   --load-dicom <dir> : read dicom files from <dir>"
    set msg "$msg\n   --load-freesurfer-volume <COR-.info> : read freesurfer files"
    set msg "$msg\n   --load-freesurfer-label-volume <COR-.info> : read freesurfer label files"
    set msg "$msg\n   --load-freesurfer-model <file> : read freesurfer model file"
    set msg "$msg\n   --load-freesurfer-scalar <file> : read a freesurfer scalar file for the active model"
    set msg "$msg\n   --load-freesurfer-annot <file> : read a freesurfer annotation file for the active model"
    set msg "$msg\n   --load-freesurfer-qa <file> : read freesurfer QA subjects.csh file"
    set msg "$msg\n   --load-bxh <file.bxh> : read bxh file from <file.bxh>"
    set msg "$msg\n   --script <file.tcl> : script to execute after slicer loads"
    set msg "$msg\n   --exec <tcl code> : some code to execute after slicer loads"
    set msg "$msg\n                       (note: cannot specify scene after --exec)"
    set msg "$msg\n                       (note: use ,. instead of ; between tcl statements)"
    set msg "$msg\n   --eval <tcl code> : like --exec, but doesn't load slicer first"
    set msg "$msg\n   --all-info : print out all of the version info and continue"
    set msg "$msg\n   --enable-stereo : set the flag to allow use of frame sequential stereo"
    set msg "$msg\n   --old-voxel-shift : start slicer with voxel coords in corner not center of image pixel"
    set msg "$msg\n   --immediate-mode : turn on immediate mode rendering (slower)"
    puts stderr $msg
    tk_messageBox -message $msg -title $::SLICER(version) -type ok
}

#
# simple arg parsing 
#
set ::SLICER(threaded) "true"
set ::SLICER(tkcon) "true"
set verbose 0
set Module(verbose) 0
set ::SLICER(load-dicom) ""
set ::SLICER(crystal-eyes-stereo) "false"
set ::SLICER(old-voxel-shift) "false"
set ::SLICER(immediate-mode) "false"
set ::SLICER(load-freesurfer-volume) ""
set ::SLICER(load-freesurfer-label-volume) ""
set ::SLICER(load-freesurfer-model) ""
set ::SLICER(load-freesurfer-scalar) ""
set ::SLICER(load-freesurfer-annot) ""
set ::SLICER(load-freesurfer-qa) ""
set ::SLICER(load-bxh) ""
set ::SLICER(script) ""
set ::SLICER(exec) ""
set ::SLICER(eval) ""
set ::SLICER(versionInfo) ""
# these scripts will be evaluated after Slicer is done booting up
set ::SLICER(utilScripts) ""

set strippedargs ""
set argc [llength $argv]
for {set i 0} {$i < $argc} {incr i} {
    set a [lindex $argv $i]
    switch -glob -- $a {
        "--verbose" -
        "-v" {
            set verbose 1
            set Module(verbose) 1
        }
        "--help" -
        "-h" {
            Usage
            exit 1
        }
        "--enable-stereo" {
            # this needs to be set when using frame sequential stereo, interlaced and
            # red blue stereo work without this flag being set
            set ::SLICER(crystal-eyes-stereo) "true"
        }
        "--no-threads" {
            set ::SLICER(threaded) "false"
        }
        "--no-tkcon" {
            set ::SLICER(tkcon) "false"
        }
        "--load-dicom" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                set dicomarg [lindex $argv $i]
                if { [file type $dicomarg] == "file" } {
                    # user picked a file, load all dicoms in same dir
                    lappend ::SLICER(load-dicom) [file dir $dicomarg]
                } else {
                    lappend ::SLICER(load-dicom) $dicomarg
                }
            }
        }
        "--load-freesurfer-volume" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-freesurfer-volume) [lindex $argv $i]
            }
        }
        "--load-freesurfer-label-volume" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-freesurfer-label-volume) [lindex $argv $i]
            }
        }
        "--load-freesurfer-model" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-freesurfer-model) [lindex $argv $i]
            }
        }
        "--load-freesurfer-scalar" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-freesurfer-scalar) [lindex $argv $i]
            }
        }
        "--load-freesurfer-annot" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-freesurfer-annot) [lindex $argv $i]
            }
        }
        "--load-freesurfer-qa" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-freesurfer-qa) [lindex $argv $i]
            }
        }
        "--load-bxh" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                lappend ::SLICER(load-bxh) [lindex $argv $i]
            }
        }
        "--old-voxel-shift" {
            set ::SLICER(old-voxel-shift) "true"
        }
        "--immediate-mode" {
            set ::SLICER(immediate-mode) "true"
        }
        "--script" {
            incr i
            if { $i == $argc } {
                Usage "missing argument for $a\n"
            } else {
                set ::SLICER(script) [lindex $argv $i]
            }
        }
        "--exec*" {
            set embeddedarg ""
            scan $a "--exec%s" embeddedarg
            set ::SLICER(exec) "$::SLICER(exec) $embeddedarg"
            incr i
            if { $i == $argc && $embeddedarg == ""} {
                Usage "missing argument for $a\n"
            } else {
                while { $i < $argc } {
                    set term [lindex $argv $i]
                    if { [string match "--*" $term] } {
                        break
                    } else {
                        set ::SLICER(exec) "$::SLICER(exec) $term"
                        incr i
                    } 
                }
                # allow a ".," to mean ";" in argument to facilitate scripting
                # (it looks like a semicolon turned on it side
                regsub -all {\.,} $::SLICER(exec) ";" ::SLICER(exec)
                regsub -all {,\.} $::SLICER(exec) ";" ::SLICER(exec)
            }
        }
        "--eval*" {
            set embeddedarg ""
            scan $a "--eval%s" embeddedarg
            set ::SLICER(eval) "$::SLICER(eval) $embeddedarg"
            incr i
            if { $i == $argc && $embeddedarg == ""} {
                Usage "missing argument for $a\n"
            } else {
                while { $i < $argc } {
                    set term [lindex $argv $i]
                    if { [string match "--*" $term] } {
                        break
                    } else {
                        set ::SLICER(eval) "$::SLICER(eval) $term"
                        incr i
                    } 
                }
                # allow a ".," to mean ";" in argument to facilitate scripting
                # (it looks like a semicolon turned on it side
                regsub -all {\.,} $::SLICER(eval) ";" ::SLICER(eval)
                regsub -all {,\.} $::SLICER(eval) ";" ::SLICER(eval)
            }
        }
        "--all-info" {
            # for data provenance, print out the executable name, version, vtk and version, compiler name and version and arguments
            # executable-name version libname libversion [compilername compilerversion] cvstag -arg1 val1 -arg2 val2
            set execName ""
            switch $tcl_platform(os) {
                "SunOS" {
                    set execName "slicer2-solaris-sparc"
                }
                "Linux" {
                    set execName "slicer2-linux-x86"
                }
                "Darwin" {
                    set execName "slicer2-darwin-ppc"
                }
                default {
                    set execName "slicer2-win32.exe"
                }
            }
            # add in the compiler info after MainBoot is called
            set ::SLICER(versionInfo)  "ProgramName: $execName ProgramArguments: $argv\nTimeStamp: [clock format [clock seconds] -format "%D-%T-%Z"] User: $::env(USER) Machine: $tcl_platform(machine) Platform: $tcl_platform(os) PlatformVersion: $tcl_platform(osVersion)"

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

if {$argc > 1 } {
    Usage
    exit 1
}


#
# Determine Slicer's home directory from the ::SLICER_HOME environment 
# variable, or the root directory of this script ($argv0).
#
if {[info exists ::env(::SLICER_HOME)] == 0 || $::env(::SLICER_HOME) == ""} {
    # set prog [file dirname $argv0]
    set prog [file dirname [info script]]
} else {
    set prog [file join $::env(::SLICER_HOME) Base/tcl]
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


#-------------------------------------------------------------------------------
# .PROC SplashRaise
#
# Simple splash screen 
# <br>                    
# Do this before loading vtk dlls so people have something
# to look at during startup (and so they see the important
# warning message!)
# .ARGS
# str fileName the name of the file to read
# int verbose if 1, print out information. Defaults to 1.
# .END
#------------------------------------------------------------------------------- 
proc SplashRaise {} { 
    # don't raise it if there's an error message up
    set winlist [winfo children .]
    if {$::Module(verbose)} {
        puts "Is there a tk message box up: [lsearch $winlist ".__tk_*"]"
    }
    if {[lsearch $winlist ".__tk_*"] != -1} {
        # message is up, don't raise it now, but try later
        after 100 "after idle SplashRaise"
    } elseif {[winfo exists .splash]} {
        raise .splash
    
        # and keep the focus on it so that it captures key presses
        focus .splash

        if {[grab current .splash] == ""} {
            # do a local grab so that all mouse clicks will go into the 
            # splash screen and not queue up while it's up. 
            catch {grab set .splash}
            update idletasks
        }
        after 100 "after idle SplashRaise"
    }
}

#-------------------------------------------------------------------------------
# .PROC SplashKill
# Release the application grab on the splash window, destroy the window, and delete the image.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SplashKill {} { 
    global splashim

    if {$::verbose} {
        puts "Releasing grab and destroying splash window."
    }

    # clear out the event queue
    update

    # because this is called from bgerror, don't cause any errors 
    if {[info command .splash] != ""} {
        # release the grab
        grab release .splash
        destroy .splash
    }
    if { [info exists splasim] } {
        if { [lsearch [image names] $splashim] != -1 } {
            image delete $splashim
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC SplashShow
# Builds and displays a splash screen, .splash
# .ARGS
# int delayms how long to show the splash screen, defaults to 7000, in milliseconds
# .END
#-------------------------------------------------------------------------------
proc SplashShow { {delayms 7000} } {
    global Path SLICER splashim

    set oscaling [tk scaling]
    # ignore screen based default scaling and pick scale so words show up nicely inside box
    tk scaling 1.5
    set splashfont [font create -family Helvetica -size 10]
    set splashfontb [font create -family Helvetica -size 10 -weight bold]
    toplevel .splash -relief raised -borderwidth 6 -width 500 -height 400 -bg white
    wm overrideredirect .splash 1
    wm geometry .splash +[expr [winfo screenwidth .splash]/2-250]+[expr [winfo screenheight .splash]/2-200]

    # add the program path so slicer can find the picture no matter what directory it is started in 
    set splashim [image create photo -file [file join $Path(program) gui/welcome.ppm]]
    label .splash.l -image $splashim
    place .splash.l -relx 0.5 -rely 0.35 -anchor center
    label .splash.t1 -text "Slicer is NOT an FDA approved medical device \nand is for Research Use Only." -bg white -fg red -font $splashfontb
    label .splash.t2 -text "See www.slicer.org for license details." -bg white -fg red -font $splashfont
    place .splash.t1 -relx 0.5 -rely 0.70 -anchor center
    place .splash.t2 -relx 0.5 -rely 0.80 -anchor center
    label .splash.v -text "Version: $::SLICER(version)" -bg white -fg darkblue -font $splashfont
    place .splash.v -relx 0.5 -rely 0.95 -anchor center
    # after $delayms SplashKill
    # add SplashKill to a list of procs to call after startup   
    lappend ::SLICER(utilScripts) "SplashKill"
    SplashRaise
    update
    # commented the bind - don't allow bypass of the grab
    bind .splash <1> SplashKill
    tk scaling $oscaling
}


#
# put up the splash screen, but only if the rest of the interface is going to come up
#
if { $::SLICER(eval) == "" && $::SLICER(exec) == "" && $::SLICER(script) == "" } {
    SplashShow
}


#
# startup with the tkcon
#
if { $::SLICER(tkcon) == "true" } { 
    set av $argv; set argv "" ;# keep tkcon from trying to interpret command line args
    source $prog/tkcon.tcl
    if { ![winfo exists .tkcon] } {
        ::tkcon::Init -root .tkcon
    }
    tkcon attach main
    wm geometry .tkcon +10-90
    set argv $av
}

SplashRaise
update

#
# eval
# - allows you to invoke entry points into applications that use slicer packages
#   and the boot process, but don't use the slicer interface
# - take tcl code from the command line and evaluate it before slicer starts up
# - if the global eval_finished variable is set before exit is called, the script will continue
#   and slicer will boot.  
#   If exit is called, slicer will quit without running the interface
#
if { $::SLICER(eval) != "" } {
    SplashKill
    eval $::SLICER(eval)
    set ::eval_finished 0
    vwait ::eval_finished 
}


#
# load the tcl packages and shared libraries of cxx code
# (proper environment is set up in launch.tcl)
#

puts "Loading VTK..."
set ::SLICER(VTK_VERSION) [package require vtk]

#-------------------------------------------------------------------------------
# .PROC VTK_AT_LEAST
# Compares the passed in required version to the currnet vtk version. Returns 0 
# if vtk is not at least the required version, 1 otherwise.
# .ARGS
# str version a string in %d.%d.%d format giving the major, minor and patch versions
# .END
#-------------------------------------------------------------------------------
proc VTK_AT_LEAST {version} {

    foreach "major minor patch" "0 0 0" {}
    foreach "vtkmajor vtkminor vtkpatch" "0 0 0" {}
    scan $version "%d.%d.%d" major minor patch
    scan $::SLICER(VTK_VERSION) "%d.%d.%d" vtkmajor vtkminor vtkpatch
    if { $major > $vtkmajor } { return 0 }
    if { $major < $vtkmajor } { return 1 }
    if { $minor > $vtkminor } { return 0 }
    if { $minor < $vtkminor } { return 1 }
    if { $patch > $vtkpatch } { return 0 }
    if { $patch < $vtkpatch } { return 1 }
    return 1
}

puts "Loading Base..."
package require vtkSlicerBase ;# this pulls in all of slicer

if { $::SLICER(old-voxel-shift) == "true" } {
    # for backwards compatibility with old slicer default
    vtkMrmlVolumeNode _dummy_node
    _dummy_node SetGlobalVoxelOffset 0.0;
    _dummy_node Delete
}


## TODO - this is needed to avoid long model loading times on the mac
# it may go away with future updates to mac osx opengl display lists
catch "pdm_dummy Delete"
vtkPolyDataMapper pdm_dummy
if {$tcl_platform(os) == "Darwin" || $::SLICER(immediate-mode) == "true"} {
    pdm_dummy GlobalImmediateModeRenderingOn
} else {
    pdm_dummy GlobalImmediateModeRenderingOff
}
pdm_dummy Delete


# this is required by the widget interactors
package require vtkinteraction

#
# turn off if user wants - re-enabled threading by default
# based on Raul's fixes to vtkImageReformat 2002-11-26
#
puts "threaded is $::SLICER(threaded)"
if { $::SLICER(threaded) == "false" } {
    vtkMultiThreader tempMultiThreader
    tempMultiThreader SetGlobalDefaultNumberOfThreads 1
    tempMultiThreader Delete
}


# Source Tcl scripts
# Source optional local copies of files with programming changes


#-------------------------------------------------------------------------------
# .PROC ReadModuleNames
# Reads Options.xml. <br>
# Returns ordered and suppressed modules.
# .ARGS 
# str filename the full path to Options.xml
# .END
#-------------------------------------------------------------------------------
proc ReadModuleNames {filename} {
    global Options verbose

    set retList ""
    foreach m $Options(moduleTypes) {
        lappend retList ""
    }

    if {$filename == ""} {
        return $retList
    }

    if {$verbose} { puts "ReadModuleNames: about to read $filename" }
    set tags [MainMrmlReadVersion2.0 $filename 0]
    if {$tags == 0} {
        return $retList
    }

    foreach pair $tags {
        set tag  [lindex $pair 0]
        set attr [lreplace $pair 0 0]
        
        switch $tag {
            
            "Options" {
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    set node($key) $val
                }
                if {$node(program) == "slicer" && $node(contents) == "modules"} {
                    # return [list $node(ordered) $node(suppressed)]
                    set retList ""
                    foreach m  $Options(moduleTypes) {
                        if {[info exist node($m)]} {
                            lappend retList $node($m)
                        } else {
                            lappend retList ""
                        }
                    }
                    if {$verbose} { puts "Got retList from Options.xml $retList" }
                    return $retList
                    
                }
            }
        }
    }
    return $retList
}

#-------------------------------------------------------------------------------
# .PROC FindNames
#
# Looks for all the modules.<br>
# For example, for a non-essential module, looks first for ./tcl-modules/*.tcl <br>
# Then looks for $::SLICER_HOME/program/tcl-modules/*.tcl
#
# .ARGS
# path dir name of the directory in which to look for file names
# .END
#-------------------------------------------------------------------------------
proc FindNames {dir} {
    global prog
    set names ""

    # Form a full path by appending the name (ie: Volumes) to
    # a local, and then central, directory.
    set local   $dir
    set central [file join $prog $dir]

    # Look locally
    foreach fullname [glob -nocomplain $local/*] {
        if {[regexp "$local/(\.*).tcl$" $fullname match name] == 1} {
            lappend names $name
        }
    }
    # Look centrally
    foreach fullname [glob -nocomplain $central/*] {
        if {[regexp "$central/(\.*).tcl$" $fullname match name] == 1} {
            if {[lsearch $names $name] == -1} {
                lappend names $name
            }
        }
    }
    return $names
}

#-------------------------------------------------------------------------------
# .PROC ReadModuleNamesLocalOrCentral
# Read module names from path built from the name and ext.
# .ARGS
# str name  name of the file to check
# str ext extension of the file to check
# .END
#-------------------------------------------------------------------------------
proc ReadModuleNamesLocalOrCentral {name ext} {
    global prog verbose

    set path [GetFullPath $name $ext "" 0]
    puts "Reading $path"
    set names [ReadModuleNames $path]
    return $names
}

#-------------------------------------------------------------------------------
# .PROC GetFullPath
# Try to find a full path to a file from the local dir or a the global prog dir.
# .ARGS
# str name name of the file to check
# str ext extension of the file to check
# str dir optional, defaults to empty string
# int verbose Print out information if 1. Optional, defaults to zero.
# .END
#-------------------------------------------------------------------------------
proc GetFullPath {name ext {dir "" } {verbose 0}} {
    global prog

    # Form a full path by appending the name (ie: Volumes) to
    # a local, and then central, directory.
    set local   [file join $dir $name].$ext
    set central [file join [file join $prog $dir] $name].$ext

    if {[file exists $local] == 1} {
        if {$verbose} { 
            puts "GetFullPath returning local $local"
        }
        return $local
    } elseif {[file exists $central] == 1} {
        if {$verbose} { 
            puts "GetFullPath returning central $central" 
        }
        return $central
    } else {
        if {$verbose == 1} {
            set msg "GetFullPath: File '$name.$ext' cannot be found (dir = $dir)"
            puts $msg
            tk_messageBox -message $msg
        }
        return ""
    }
}


#-------------------------------------------------------------------------------
# .PROC START_THE_SLICER
#
# Looks in ./tcl-shared ./tcl-modules and ./tcl-shared for names of tcl files.<br>
# Also looks in $central/tcl-shared ... (which is $::SLICER_HOME/program/..)<br>
#
# Source those files<br>
# Boot the slicer<br>
#
# If the environment variable ::SLICER_SCRIPT exist, 
# and it points to a tcl file, source the file. <br>
# Then, if the function SlicerScript exists, run it after booting.<br>
# (not a callable procedure, just a series of statements in Go.tcl)
#
# .END
#-------------------------------------------------------------------------------

# Steps to sourcing files:
# 1.) Get an ordered list of module names (ie: Volumes, not Volumes.tcl).
# 2.) Append names of other existing modules to this list.
# 3.) Remove names from the list that are in the "suppressed" list.
#

# Source Parse.tcl to read the XML
set path [GetFullPath Parse tcl tcl-main]
source $path

# this should be set in the OptionsInit proc, but need it now
set ::Options(moduleTypes) {ordered suppressed ignored}
# set path [GetFullPath Options tcl tcl-modules]
# source $path

# Look for an Options.xml file locally and then centrally
set moduleNames [ReadModuleNamesLocalOrCentral Options xml]

# Get the list of module types from the Options.xml file
for {set i 0} {$i < [llength $::Options(moduleTypes)]} {incr i} {
    set listname [lindex $::Options(moduleTypes) $i]
   
    set $listname [lindex $moduleNames $i]
    if {$verbose} { puts "Got list name $listname = [subst $$listname]"}
}

# Find all Base module names
set found [FindNames tcl-modules]

if {$verbose == 1} {
    puts "found=$found"
    foreach mType $::Options(moduleTypes) {
        puts "$mType = [subst $$mType]"
    }
    # puts "ordered=$ordered"
    # puts "suppressed=$suppressed"
}

# Append found names to ordered names
# - after this ordered includes:
# --- specifically named modules from Options.xml
# --- modules found by looking for tcl files
foreach name $found {
    if {[lsearch $ordered $name] == -1} {
        lappend ordered $name
    }
}

# Suppress unwanted (need a more PC term for this) modules
foreach name [concat $suppressed $ignored] {
    set i [lsearch $ordered $name]
    if {$i != -1} {
        set ordered [lreplace $ordered $i $i]
    }
}

# this should be using TCL_LIB_DIR, but Go.tcl currently isn't sourcing slicer_variables.tcl
# This is to take care of the "BLT package is required..." error message on Darwin

if {$::env(BUILD) == "darwin-ppc"} { 
    if {[catch "load $::env(SLICER_HOME)/Lib/$::env(BUILD)/tcl-build/lib/libBLT24.so" ERRMSG] == 1} {
        puts "Unable to load BLT: $ERRMSG"
    }
}

foreach m $::env(SLICER_MODULES_TO_REQUIRE) {
    if {[lsearch $ignored $m] == -1} {
        puts "Loading Module $m..."
        if { [catch {package require $m} errVal] } {
            puts stderr "Warning: can't load module $m:\n$errVal"
            puts stderr "\tContinuing without this module's functionality."
        }
    } else {
        if {$verbose} {
            puts "IGNORING $m"
        }
    }
}

# Source the modules that haven't been package required
set foundOrdered ""
foreach name $ordered {
    if {[lsearch $::env(SLICER_MODULES_TO_REQUIRE) $name] == -1 &&
        [lsearch $::env(SLICER_MODULES_TO_REQUIRE) vtk${name}] == -1} {
        # the module hasn't been package required yet, so the tcl file hasn't been sourced,
        # so this should be a Base module that needs to be sourced
        if { [info command ${name}Init] == "" } {
            if {$verbose} { puts "Sourcing modules from ordered list: ${name}Init hasn't been loaded yet, searching for it in tcl-modules"}
            # if the entry point proc doesn't exist yet,
            # then read the file (Modules loaded through 
            # 'package require' will already have had their code sourced
            set path [GetFullPath $name tcl tcl-modules]
            if {$path != ""} {
                if {$verbose == 1} {puts "Found and sourcing $path"}
                source $path
                lappend foundOrdered $name
            } 
        } else {
            if {$verbose == 1} {puts "Sourcing stuff from ordered list: already sourced $name"}
            lappend foundOrdered $name
        }
    } else {
        if {$verbose} {
            puts "Sourcing the modules from ordered list: ${name} is in the SLICER_MODULES_TO_REQUIRE list, not sourcing it from tcl-modules. Just adding to foundOrdered list"
        }
        lappend foundOrdered $name
    }
}

# Add any custom Modules to foundOrdered, they will have had to have added
# their name to Module(customModules)
# otherwise would have to leave out any that are loaded by 
# sub sections of the interface, ie the Volumes or the Editors scripts 
# ie no matches for Vol*Init or Ed*Init
if {[info exists Module(customModules)]  == 1} {
    if { $verbose == 1 } {
        puts "Custom modules we need to add: $Module(customModules)"
    }
    # it's already been sourced, so just add to the foundOrdered list 
    foreach customModule $Module(customModules) {
        if {[lsearch $foundOrdered $customModule] == -1 && 
            [lsearch $suppressed $customModule] == -1 &&
            [lsearch $ignored $customModule] == -1} {
            # it's not already on the foundOrdered list, nor on the suppressed or ignored list.
            # You can get duplicates if a custom module was saved to a local 
            # Options.xml file, or is on the suppressed list, and slicer will crash 
            # with a tcl error as it tries to build two gui's for a module.
            lappend foundOrdered $customModule
        }
    }
}
# Kilian : For some reason my EMSegment is in there a couple of times 
#          creating problems later when going into Main.tcl 
#          Make sure every module is included only once in ordered


if {$verbose} {
    puts "Copying foundOrdered into ordered without duplicates:"
    puts "ordered = $ordered"
    puts "foundOrdered = $foundOrdered"
}
# Ordered list only contains modules that exist, are not suppressed or ignored
set ordered ""
foreach Entry $foundOrdered {
    if {[lsearch $ordered $Entry] < 0 &&
        [lsearch $suppressed $Entry] == -1 &&
        [lsearch $ignored $Entry] == -1} {
        lappend ordered $Entry
    } else {
        if {$verbose} {
            puts "Checking through foundOrdered, not adding $Entry"
        }
    }
}  

# Source Base shared files either locally or globally
# For example for a module MyModule, we look for
# ./tcl-modules/MyModule.tcl and then for $::SLICER_HOME/Base/tcl/tcl-modules/MyModule.tcl
# Similar for tcl-shared and tcl-main

set shared [FindNames tcl-shared]
foreach name $shared {
    set path [GetFullPath $name tcl tcl-shared]
    if {$path != ""} {
        if {$verbose == 1} {puts "source $path"}
        source $path
    }
}

# Source main stuff either locally or globally
set main [FindNames tcl-main]
foreach name $main {
    set path [GetFullPath $name tcl tcl-main]
    if {$path != ""} {
        if {$verbose == 1} {puts "source $path"}
        source $path
    }
}

# Set global variables
set Module(idList)     $ordered
set Module(mainList)   $main
set Module(sharedList) $shared
set Module(supList)    $suppressed
set Module(ignoredList) $ignored
# don't add the ignored list here, as it's a list of modules that aren't loaded or sourced at all
set Module(allList)    [concat $ordered $suppressed]

if {$verbose == 1} {
    puts "After sourcing all tcl files:"
    puts "ordered=$ordered"
    puts "main=$main"
    puts "shared=$shared"
    puts "allList = $Module(allList)"
    puts "idList = $Module(idList)"
    puts "ignored = $ignored"
}

# Bootup
set ::View(render_on) 0
MainBoot [lindex $argv 0]
set ::View(render_on) 1

### print out the versioning info
if { $::SLICER(versionInfo) != "" } {
    # have to get the compiler information after MainBoot
    set compilerVersion [Slicer GetCompilerVersion]
    set compilerName [Slicer GetCompilerName]
    set vtkVersion [Slicer GetVTKVersion]
    if {[info command vtkITKVersion] == ""} {
        set itkVersion "none"
    } else {
        catch "vtkITKVersion vtkitkver"
        catch "set itkVersion [vtkitkver GetITKVersion]"
        catch "vtkitkver Delete"
    }
    set libVersions "LibName: VTK LibVersion: ${vtkVersion} LibName: TCL LibVersion: ${tcl_patchLevel} LibName: TK LibVersion: ${tk_patchLevel} LibName: ITK LibVersion: ${itkVersion}"
    set SLICER(versionInfo) "$SLICER(versionInfo)  Version: $SLICER(version) CompilerName: ${compilerName} CompilerVersion: $compilerVersion ${libVersions} CVS: [ParseCVSInfo "" {$Id: Go.tcl,v 1.123 2007/03/16 20:01:41 nicole Exp $}] "
    puts "$SLICER(versionInfo)"
}

#
# adapt to the vtk version
#
catch "__vtkVersionInstance Delete"
vtkVersion __vtkVersionInstance
if { [string match "4.2*" [__vtkVersionInstance GetVTKVersion]] } {
    set ::getScalarComponentAs GetScalarComponentAsFloat
    set ::setScalarComponentFrom SetScalarComponentFromFloat
} else {
    set ::getScalarComponentAs GetScalarComponentAsDouble
    set ::setScalarComponentFrom SetScalarComponentFromDouble
}
__vtkVersionInstance Delete

#
# read dicom volumes specified on command line
# - if it's a dir full of files, load that dir as a volume
# - if it's a dir full of dirs, load each dir as a volume
# - if it's "", it will be ignored
# - note: the flag can be set if a directory is specified on the command line
#
foreach arg $::SLICER(load-dicom) {
    DICOMLoadStudy $arg
}

#
# read freesurfer data command line
#
foreach arg $::SLICER(load-freesurfer-volume) {
    if { [catch "package require vtkFreeSurferReaders"] } {
        DevErrorWindow "vtkFreeSurferReaders Module required for --load-freesufer-volume option."
        break
    }
    vtkFreeSurferReadersLoadVolume $arg
    RenderSlices
}

#
# read freesurfer data command line
#
foreach arg $::SLICER(load-freesurfer-label-volume) {
    if { [catch "package require vtkFreeSurferReaders"] } {
        DevErrorWindow "vtkFreeSurferReaders Module required for --load-freesufer-label-volume option."
        break
    }
    vtkFreeSurferReadersLoadVolume $arg 1
    RenderSlices
}

#
# read freesurfer data command line
#
foreach arg $::SLICER(load-freesurfer-model) {
    if { [catch "package require vtkFreeSurferReaders"] } {
        DevErrorWindow "vtkFreeSurferReaders Module required for --load-freesufer-model option."
        break
    }
    vtkFreeSurferReadersLoadModel $arg
    Render3D
}

#
# read freesurfer scalar command, gets associated with active (last loaded) model
#
foreach arg $::SLICER(load-freesurfer-scalar) {
    if { [catch "package require vtkFreeSurferReaders"] } {
        DevErrorWindow "vtkFreeSurferReaders Module required for --load-freesufer-scalar option."
        break
    }
    vtkFreeSurferReadersLoadScalarFile $arg
    Render3D
}

#
# read freesurfer annotation command, gets associated with the active (last loaded) model
#
foreach arg $::SLICER(load-freesurfer-annot) {
    if { [catch "package require vtkFreeSurferReaders"] } {
        DevErrorWindow "vtkFreeSurferReaders Module required for --load-freesufer-annot option."
        break
    }
    vtkFreeSurferReadersLoadAnnotationFile $arg
    Render3D
}

#
# read in freesurfer QA command line
# 
foreach arg $::SLICER(load-freesurfer-qa) {
    if { [catch "package require vtkFreeSurferReaders"] } {
        DevErrorWindow "vtkFreeSurferReaders Module required for --load-freesufer-qa option."
        break
    }
    vtkFreeSurferReadersLoadQA $arg
    # can only do one at a time right now
    break
}

#
# read bxh volumes specified on command line
#
foreach arg $::SLICER(load-bxh) {
    if { [catch "package require vtkCISGFile"] } {
        DevErrorWindow "vtkCISGFile Module required for --load-bxh option."
        break
    }
    if { [catch "package require vtkBXH"] } {
        DevErrorWindow "vtkBXH Module required for --load-bxh option."
        break
    }

    set ::VolBXH(bxh-fileName) $arg
    VolBXHLoadVolumes  
}


### Did someone set the ::SLICER_SCRIPT environment variable
### If they did and it is a tcl file, source it.
### If the SlicerScript function exists, run it

if {[info exists ::env(SLICER_SCRIPT)] != 0 && $::env(SLICER_SCRIPT) != ""} {

    ## Is it a tcl file
    if {[regexp "\.tcl$\s*$" $::env(SLICER_SCRIPT)] == 1} {
        source $::env(SLICER_SCRIPT)
        if {[info commands SlicerScript] != ""} {
            puts "Running slicer script..."
            SlicerScript
            puts "Done running slicer script."
        }
    }
}

### or run a script specified on the command line with --script

if { $::SLICER(script) != "" } {
    source $::SLICER(script)
}

if { $::SLICER(exec) != "" } {
    eval $::SLICER(exec)
}

### and then run any utility scripts that we set up (ie killing the splash screen)
if { $::SLICER(utilScripts) != ""} {
    foreach cmd $::SLICER(utilScripts) {
        eval $cmd
    }
}
