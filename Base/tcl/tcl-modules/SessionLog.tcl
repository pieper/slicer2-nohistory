#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: SessionLog.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:01 $
#   Version:   $Revision: 1.22 $
# 
#===============================================================================
# FILE:        SessionLog.tcl
# PROCEDURES:  
#   SessionLogInit
#   SessionLogShouldWeLog
#   SessionLogBuildGUI
#   SessionLogEnter
#   SessionLogExit
#   SessionLogToggleLogging tk
#   SessionLogStopLogging tk
#   SessionLogStartLogging tk
#   SessionLogGetVersionInfo
#   SessionLogSetFilenameAutomatically
#   SessionLogLog
#   SessionLogShowLog
#   SessionLogEndSession
#   SessionLogWriteLog
#   SessionLogReadLog
#   SessionLogStorePresets p
#   SessionLogRecallPresets p
#   SessionLogGenericLog m
#   SessionLogTraceSliceOffsets
#   SessionLogTraceSliceOffsetsCallback  variableName indexIfArray operation
#   SessionLogTraceSliceDescriptionCallback variableName indexIfArray operation
#   SessionLogStartTimingSlice s
#   SessionLogStartTimingAllSlices
#   SessionLogStopTimingAllSlices
#   SessionLogStartTiming d
#   SessionLogStopTiming d
#   SessionLogUnTraceSliceOffsets
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
#  This module outputs a record of a segmentation session.
#  This will be used to compare efficiency of segmentation methods.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are the variables defined by this module.
# 
#  widget SessionLog(textBox)  the text box widget
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SessionLogInit
#  The "Init" procedure is called automatically by the slicer. <br> 
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.<br>
# This procedure can automatically log certain users if the path is set
# for logging and the file UsersToAutomaticallyLog exists.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogInit {} {
    global SessionLog Module Volume Model Path env
    set m SessionLog
    
    # Set up GUI tabs
    set Module($m,row1List) "Help Start Log"
    set Module($m,row1Name) "{Help} {Start Here} {Log}"
    set Module($m,row1,tab) Start

    # Module Summary Info
    set Module($m,overview) "Logging of Editor sessions."
    set Module($m,category)  "Segmentation"
    set Module($m,author) "Core"

    # Register procedures that will be called 
    set Module($m,procGUI) SessionLogBuildGUI
    set Module($m,procEnter) SessionLogEnter
    set Module($m,procExit) SessionLogExit
    # the proc that will log things this module keeps track of
    set Module($m,procSessionLog) SessionLogLog

    # Set our presets
    #lappend Module(procStorePresets) SessionLogStorePresets
    #lappend Module(procRecallPresets) SessionLogRecallPresets
    #set Module(SessionLog,presets) ""

    #   Record any other modules that this one depends on.
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.22 $} {$Date: 2006/01/06 17:57:01 $}]

    # Initialize module-level variables
    set SessionLog(fileName)  ""
    set SessionLog(currentlyLogging) 0
    set SessionLog(autoLogging) 0

    # list of variables that we will trace
    set SessionLog(traceVarlist) "{Module(activeID)} {Editor(activeID)} {Editor(idWorking)} \
        {Editor(idOriginal)} {Label(label)} {Slice(activeID)}"

    # default directory to log to (used for auto logging)
    # (should be set from Options.xml)
    #set SessionLog(defaultDir) [file join $Path(program) logs]
    set SessionLog(defaultDir) ""

    if {[file isdirectory $SessionLog(defaultDir)] == 0} {
        puts $SessionLog(defaultDir) 
        #puts "No logging enabled"
        set SessionLog(defaultDir) ""
    }
    
    # event bindings
    set SessionLog(eventManager)  ""

    # for now, automatically log everyone (use SessionLogShouldWeLog
    # to selectively log users).
    # if we know who this user is
    if {[info exists env(LOGNAME)] == 1} {

        # if the logging directory exists
        if {[file isdirectory $SessionLog(defaultDir)]} {
            
            puts "Automatically logging user $env(LOGNAME).  Thanks!"
            set SessionLog(autoLogging) 1
            SessionLogStartLogging
            SessionLogSetFilenameAutomatically
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC SessionLogShouldWeLog
# Figure out if we should automatically log this user.<br>
# (This info should be in Options.xml but then people could save their
# own and old Options.xml files would ruin the auto-logging experiment)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogShouldWeLog {} {
    global SessionLog env

    
    # if username is set in the env global array
    if {[info exists env(LOGNAME)] == 1} {
        #puts "logname: $env(LOGNAME)"
        set logname $env(LOGNAME)


        # if the file listing which users to log exists
        # ExpandPath looks first in current dir then in program directory
        set filename [ExpandPath "UsersToAutomaticallyLog"]
        if {[file exists $filename]} {
            
            #puts "file $filename found"
            set in [open $filename]
            set users [read $in]
            close $in
            
            # check and see if this user in file (then should be logged)
            foreach user $users {
                #puts $user
                if {$logname == $user} {
                    #puts "match: $user == $logname"
                    
                    # automatically log this user
                    set SessionLog(autoLogging) 1
                    puts "Automatically logging user $user.  Thanks!"
                    SessionLogStartLogging
                    SessionLogSetFilenameAutomatically
                    
                    return 1
                }
            }
        }
    }
    
    return 0
}

#-------------------------------------------------------------------------------
# .PROC SessionLogBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc SessionLogBuildGUI {} {
    global Gui SessionLog Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Start" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(SessionLog,fStart)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Start
    #   Top
    #   Middle
    #   Bottom
    #     FileLabel
    #     CountDemo
    # Bindings
    #   TextBox
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The SessionLog module records info about your segmentation session 
    for research purposes and to improve the Slicer. 
    <BR>Editing mouse motions and clicks are recorded. 
    <BR>This modules will log information for any module that's defined a procSessionLog and adds information to the record.
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Start:</B> Set the log file name here, and start/stop logging.
    <LI><B>Log:</B> View the logged information here. Click on Show Current Log to see information.
    "
    regsub -all "\n" $help {} help
    # remove emacs-style indentation from the 'html'
    regsub -all "    " $help {} help
    MainHelpApplyTags SessionLog $help
    MainHelpBuildGUI SessionLog
    
    #-------------------------------------------
    # Start frame
    #-------------------------------------------
    set fStart $Module(SessionLog,fStart)
    set f $fStart
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # Start->Top frame
    #-------------------------------------------
    set f $fStart.fTop

    # file browse box
    DevAddFileBrowse $f SessionLog fileName "Log File:" [] \
        "txt" [] "Save" "Select Log File" \
        "Choose the log file for this grayscale volume."\
        "Absolute"
    
    #-------------------------------------------
    # Start->Middle frame
    #-------------------------------------------
    set f $fStart.fMiddle
    
    DevAddLabel $f.lLogging "Logging is off."
    pack $f.lLogging -side top -padx $Gui(pad) -fill x
    set SessionLog(lLogging) $f.lLogging
    
    # if we are already logging (automatically)
    if {$SessionLog(currentlyLogging) == "1"} {
        set red [MakeColor "200 60 60"]
        $SessionLog(lLogging) config -text \
            "Logging is on." \
            -fg $red
    }

    #-------------------------------------------
    # Start->Bottom frame
    #-------------------------------------------
    set f $fStart.fBottom
    
    # make frames inside the Bottom frame for nice layout
    foreach frame "Start" {
        frame $f.f$frame -bg $Gui(activeWorkspace) 
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Start->Bottom->Start frame
    #-------------------------------------------
    set f $fStart.fBottom.fStart

    # call start logging with a 1 if triggered by the button press
    # DevAddButton $f.bStart "Start Logging" {SessionLogStartLogging 1} 15
    # TooltipAdd $f.bStart "Start logging each time before editing."
    # pack $f.bStart -side top -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $f.bToggle "Toggle Logging" {SessionLogToggleLogging 1} 15
    TooltipAdd $f.bToggle "Start logging each time before editing."
    pack $f.bToggle -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Log frame
    #-------------------------------------------
    set fLog $Module(SessionLog,fLog)
    set f $fLog

    foreach frame "TextBox" {
        frame $f.f$frame -bg $Gui(activeWorkspace) 
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    $f.fTextBox config -relief groove -bd 3 
    
    #-------------------------------------------
    # Log->TextBox frame
    #-------------------------------------------
    set f $fLog.fTextBox

    # this is a convenience proc from tcl-shared/Developer.tcl
    DevAddButton $f.bBind "Show Current Log" SessionLogShowLog
    pack $f.bBind -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    # here's the text box widget from tcl-shared/Widgets.tcl
    set SessionLog(textBox) [ScrolledText $f.tText]
    pack $f.tText -side top -pady $Gui(pad) -padx $Gui(pad) \
        -fill x -expand true

    
}

#-------------------------------------------------------------------------------
# .PROC SessionLogEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogEnter {} {
    global SessionLog
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $SessionLog(eventManager)

    # clear the text box
    $SessionLog(textBox) delete 1.0 end

}

#-------------------------------------------------------------------------------
# .PROC SessionLogExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
}

#-------------------------------------------------------------------------------
# .PROC SessionLogToggleLogging
# Check SessionLog(currentlyLogging), if currently logging, call SessionLogStopLogging, if not, 
# call SessionLogStartLogging.
# .ARGS
# int tk optional flag, defaults to 0, if 1, was called from a button press
# .END
#-------------------------------------------------------------------------------
proc SessionLogToggleLogging {{tk "0"}} {
    global SessionLog

    if {$SessionLog(currentlyLogging) == 0} {
        SessionLogStartLogging $tk
    } else {
        SessionLogStopLogging $tk
    }
}

#-------------------------------------------------------------------------------
# .PROC SessionLogStopLogging
# Undo everything SessionLogStartLogging started.
# .ARGS
# int tk optional flag, defaults to 0, if 1, was called from a button press
# .END
#-------------------------------------------------------------------------------
proc SessionLogStopLogging {{tk "0"}} {
    global SessionLog

    if {$::Module(verbose)} { 
        puts "SessionLogStopLogging: tk $tk" 
    }

    # if this proc was called by hitting a button, tk is 1
    if {$tk == "1"} {
        if {$SessionLog(currentlyLogging) == 0} {
            tk_messageBox -message "Already stopped logging."
            return
        }
        # let users know we aren't logging any more
        $SessionLog(lLogging) config -text \
            "Logging is off" -fg black
    }

    # in case any module wants to know if we are logging or not
    set SessionLog(currentlyLogging) 0

    SessionLogEndSession

    # stop tracing variables
    SessionLogUnTraceSliceOffsets
}

#-------------------------------------------------------------------------------
# .PROC SessionLogStartLogging
# Start logging.  Set SessionLog(currentlyLogging) to 1, log initial items,
# start timing slice info, the works.
# .ARGS
# int tk optional flag, defaults to 0, if 1, was called from a button press
# .END
#-------------------------------------------------------------------------------
proc SessionLogStartLogging {{tk "0"}} {
    global SessionLog env

    if {$::Module(verbose)} { 
        puts "SessionLogStartLogging: tk $tk" 
    }
    # if this proc was called by hitting a button, $tk ==1
    if {$tk == "1"} {
        if {$SessionLog(currentlyLogging) == 1} {
            tk_messageBox -message "Already logging."
            return
        }
        # make sure we have a filename.
        if {$SessionLog(fileName) == ""} {
            tk_messageBox -message "Please choose a filename first."
            return
        }
        # let users know we are logging
        set red [MakeColor "200 60 60"]
        $SessionLog(lLogging) config -text \
            "Logging is on." \
            -fg $red
    }
    
    # in case any module wants to know if we are logging or not
    set SessionLog(currentlyLogging) 1

    # set up things this module is going to log
    set datatype "{{date,start}}"
    set SessionLog(log,$datatype) [clock format [clock seconds]]
    set datatype "{{misc,machine}}"
    set SessionLog(log,$datatype) [info hostname]
    # record user name
    set datatype "{{misc,user}}"
    set SessionLog(log,$datatype) ""
    if {[info exists env(LOGNAME)] == 1} {
        set SessionLog(log,$datatype) $env(LOGNAME)
    }

    SessionLogTraceSliceOffsets
    SessionLogGetVersionInfo
}

#-------------------------------------------------------------------------------
# .PROC SessionLogGetVersionInfo
# Extract version info for each module, 
# dependent on string formatting in $Module(versions)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogGetVersionInfo {}  {
    global SessionLog Module

    foreach ver $Module(versions) {
        set module [lindex $ver 0]
        set revision [lindex [lindex $ver 1] 1]
        set date [lindex [lindex $ver 2] 1]
        set time [lindex [lindex $ver 2] 2]
        set var "\{\{modversion,$module\},\{date,$date\},\{time,$time\}\}"
        set value "$revision"
        set SessionLog(log,$var) $value
    }
}

#-------------------------------------------------------------------------------
# .PROC SessionLogSetFilenameAutomatically
# Create a unique log filename using the user's id and the time
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogSetFilenameAutomatically {} {
    global SessionLog

    # day of year (1-366), hour, min, sec, and year
    set formatstr "_%j_%H_%M_%S_%Y"
    set unique [clock format [clock seconds] -format $formatstr]
    set datatype "{{misc,user}}"
    set filename "$SessionLog(log,$datatype)$unique.log"
    set wholename [file join $SessionLog(defaultDir) $filename]
    
    # test if this has worked
    if {[file exists $wholename] == 1} {
        set wholename [file join $SessionLog(defaultDir) "$SessionLog(log,userName)${unique}Error.log"]
        puts "Automatically generated log filename already exists!"
    }

    puts "Session log will be automatically saved as $wholename"
    set SessionLog(fileName) $wholename
}


#-------------------------------------------------------------------------------
# .PROC SessionLogLog
# Returns the things this module logs, in a formatted string
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogLog {} {
    global SessionLog

    # final things this module will log
    set datatype "{{date,end}}"
    set SessionLog(log,$datatype) [clock format [clock seconds]]


    # call generic function to grab all SessionLog(log,*)
    SessionLogGenericLog SessionLog
}

#-------------------------------------------------------------------------------
# .PROC SessionLogShowLog
# Show the current stuff each module is keeping track of<br>
# (the log file will be written when the user exits)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogShowLog {} {
    global Module SessionLog
    
    # display the output that will be written to the file.
    set log ""
    foreach m $Module(idList) {
        if {[info exists Module($m,procSessionLog)] == 1} {
            set log "${log}Module: $m\n[$Module($m,procSessionLog)]"
        }
    }

    # clear the text box
    $SessionLog(textBox) delete 1.0 end
    # put the new log there
    $SessionLog(textBox) insert end $log

}

#-------------------------------------------------------------------------------
# .PROC SessionLogEndSession
#  Called on program exit to finish logging and call WriteLog
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogEndSession {} {
    global SessionLog

    if {$SessionLog(currentlyLogging) == 0} {
        if {$::Module(verbose)} { 
            puts "SessionLogEndSession:\nSession log is currently logging, cannot end session" 
        }
        return
    }
    
    if {$SessionLog(fileName) == ""} {
        SessionLogSetFilenameAutomatically
    }

    # make sure we record final times
    SessionLogStopTimingAllSlices    

    puts "Saving session log file as $SessionLog(fileName)"

    SessionLogWriteLog

}

#-------------------------------------------------------------------------------
# .PROC SessionLogWriteLog
# Actually grab log info from all modules and write the file
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogWriteLog {} {
    global Module SessionLog

    # append everything modules decided to record.
    set out [open $SessionLog(fileName) a]
    
    # get the goods:
    foreach m $Module(idList) {
        if {[info exists Module($m,procSessionLog)] == 1} {
            puts "LOGGING: $m"
            set info [$Module($m,procSessionLog)]
            
            set info "\{\n\{_Module $m\}\n\{$info\}\n\}\n"
            #puts $out "\n_Module $m"
            #puts $out "\n_ModuleLogItems"
            puts $out $info
            #puts $out "\n_EndModule"
        }
    }

    close $out
    
}

#-------------------------------------------------------------------------------
# .PROC SessionLogReadLog
# Read in a log (text) file and display in the box
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogReadLog {} {
    global SessionLog

    # read in a log file for kicks.
    set in [open $SessionLog(fileName)]
    $SessionLog(textBox) insert end [read $in]
    close $in
}


#-------------------------------------------------------------------------------
# .PROC SessionLogStorePresets
# Put things into the presets Options node in Options.xml, which is
# read in when slicer starts up)
# .ARGS
# int p not used - view id?
# .END
#-------------------------------------------------------------------------------
proc SessionLogStorePresets {p} {
    global Preset SessionLog

    # store the current default directory
    set Preset(SessionLog,defaultDir) $SessionLog(defaultDir) 

}

#-------------------------------------------------------------------------------
# .PROC SessionLogRecallPresets
# Get startup info from the Options.xml file (through the Preset array). <br>
# This is used for a configurable default storage dir for automatic
# logging.  Edit slicer/program/Options.xml to change this directory.
# .ARGS
# int p not used
# .END
#-------------------------------------------------------------------------------
proc SessionLogRecallPresets {p} {
    global Preset SessionLog
    
    # test if the default dir exists
    if {[info exists Preset(SessionLog,defaultDir)] == 1} {
        set dir $Preset(SessionLog,defaultDir)
        if {[file isdirectory $dir] == 1} {
            set SessionLog(defaultDir) $dir
        } else {
            puts "Error in SessionLog: default directory from Options.xml does not exist"
        }
    } else {
        puts "SessionLog: no default dir in Options.xml."
    }
    # get the user names we should log for. ???
}

########################################################
# Utility functions to help other modules log
######################################################

#-------------------------------------------------------------------------------
# .PROC SessionLogGenericLog
# Generic logging procedure
# which grabs everything in $m(log,*) and returns a formatted 
# string that can then be returned by a module's logging procedure.
# .ARGS
# str m global array name that contains the log.
# .END
#-------------------------------------------------------------------------------
proc SessionLogGenericLog {m} {
    global $m

    set log "" 

    # get everything that was stored in the log part of the array
    set loglist [array names $m log,*]
    #puts $loglist

    # format the things this module will log
    foreach item $loglist {
        set name ""
        # get name without leading 'log,'
        regexp {log,(.*)} $item match name
        # get matching value stored in array
        eval {set val} \$${m}($item)
        # append to list
        lappend log "\{$name   \{$val\}\}"
        #set log "${log}\{${name}: ${val}\}\n"
    }

    # alphabetize the list
    set alpha [lsort -dictionary $log]

    # add newlines between items so it's readable
    set final ""
    foreach item $alpha {
        set final "$final\n$item"
    }

    return $final
}

#-------------------------------------------------------------------------------
# .PROC SessionLogTraceSliceOffsets
# Uses tcl "trace variable" command to be notified whenever slice offsets change.<br>
# This allows timing of editing, etc., per slice without hacking MainSlices.<br>
# Also traces other variables used in the "description" of the slice time
# (like current label, etc.) so that we can time, for example, time per slice per label.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogTraceSliceOffsets {}  {
    global Slice SessionLog
    global Module Editor Label
    foreach s $Slice(idList) {
        # callback will be called whenever variable is written to ("w")
        trace variable Slice($s,offset) w SessionLogTraceSliceOffsetsCallback
        
        # initialize vars
        if {[info exists SessionLog(trace,prevSlice$s)] == 0} {
            set SessionLog(trace,prevSlice$s) ""
        }
    }

    # trace all variables we are using as part of the slice time description
    # this is needed to keep an accurate time count...
    # otherwise we won't start and stop timing when description 
    # changes and none of this will work.

    foreach var $SessionLog(traceVarlist) {
        trace variable $var w SessionLogTraceSliceDescriptionCallback
        #puts $var
        #eval {puts } \$$var
    }

    return

}

#-------------------------------------------------------------------------------
# .PROC SessionLogTraceSliceOffsetsCallback 
# Called when slice offset tcl var changes.<br>
# Initiates timing of time spent in slice
# .ARGS
# str variableName where to find the slice number
# int indexIfArray index into variableName
# str operation not used
# .END
#-------------------------------------------------------------------------------
proc SessionLogTraceSliceOffsetsCallback {variableName indexIfArray operation} {
    global Slice Module Editor


    # we only care about editing time per slice
    if {$Module(activeID) != "Editor"} {
        if {$::Module(verbose)} {
            puts "SessionLogTraceSliceOffsetsCallback: active module is not Editor, returning."
        }
        return
    }

    # Lauren what if slice is not active?

    # get slice number
    upvar 1 $variableName var
    set num $var($indexIfArray)

    # get slice id number
    set s [lindex [split $indexIfArray ","] 0]

    SessionLogStartTimingSlice $s
}

#-------------------------------------------------------------------------------
# .PROC SessionLogTraceSliceDescriptionCallback
# Called when any var that is used as part of the description of
# the slice time changes.  Restarts timing of all slices w/ new description.
# .ARGS
# str variableName not used
# int indexIfArray not used
# str operation not used
# .END
#-------------------------------------------------------------------------------
proc SessionLogTraceSliceDescriptionCallback {variableName indexIfArray operation} {
    
    SessionLogStartTimingAllSlices

}

#-------------------------------------------------------------------------------
# .PROC SessionLogStartTimingSlice
# Form description string that describes current situation we are timing.<br>
# Record start time for this description. Stop timing previous description.
# .ARGS
# int s slice number
# .END
#-------------------------------------------------------------------------------
proc SessionLogStartTimingSlice {s} {
    global SessionLog Slice Module Editor Label

    # this copies a bunch of Editor code, it could all be in same place...

    # form description of exact event
    # key-value pairs describing the event
    set datatype "{sliceTime,elapsed}"
    set module "{module,$Module(activeID)}"
    set submodule "{submodule,$Editor(activeID)}"
    set workingid "{workingid,$Editor(idWorking)}"
    set originalid "{originalid,$Editor(idOriginal)}"
    set label "{label,$Label(label)}"
    set slice  "{slice,$s}"
    set sliceactive  "{sliceactive,$Slice(activeID)}"
    set slicenum "{slicenum,$Slice($s,offset)}"
    #set eventinfo "{eventinfo,}"
    set var "\{$datatype,$module,$submodule,$workingid,$originalid,$label,$slice,$slicenum\}"
    
    # previous slice timing description
    set prev $SessionLog(trace,prevSlice$s)

    # actually record the time
    if {$var != $prev} {

        SessionLogStartTiming $var
        
        # stop timing previous slice
        if {$prev != ""} {
            SessionLogStopTiming $prev
        }
        # remember this one for next time
        set SessionLog(trace,prevSlice$s)  $var
    }
}


#-------------------------------------------------------------------------------
# .PROC SessionLogStartTimingAllSlices
# For each slice, start timing that slice
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogStartTimingAllSlices {} {
    global SessionLog Slice
    
    foreach s $Slice(idList) {
        SessionLogStartTimingSlice $s
    }

}

#-------------------------------------------------------------------------------
# .PROC SessionLogStopTimingAllSlices
# Only use this before exiting the program to record final time
# for all slices.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogStopTimingAllSlices {} {
    global SessionLog Slice
    
    foreach s $Slice(idList) {

        # stop timing previous slice
        set prev $SessionLog(trace,prevSlice$s)
        if {$prev != ""} {
            SessionLogStopTiming $prev
        }
        # clear the previous slice since we are not timing one
        set SessionLog(trace,prevSlice$s)  ""
    }
}

#-------------------------------------------------------------------------------
# .PROC SessionLogStartTiming
# Grab clock value now
# .ARGS
# str d  description pseudo-list of whatever we are timing
# .END
#-------------------------------------------------------------------------------
proc SessionLogStartTiming {d} {
    global SessionLog

    set SessionLog(logInfo,$d,startTime) [clock seconds]
}

#-------------------------------------------------------------------------------
# .PROC SessionLogStopTiming
# Add to the total time in editor (or submodule) so far
# .ARGS
# str d description pseudo-list of whatever we are timing
# .END
#-------------------------------------------------------------------------------
proc SessionLogStopTiming {d} {
    global SessionLog

    # can't stop if we never started
    if {[info exists SessionLog(logInfo,$d,startTime)] == 0} {
        return
    }

    set SessionLog(logInfo,$d,endTime) [clock seconds]
    set elapsed \
        [expr $SessionLog(logInfo,$d,endTime) - $SessionLog(logInfo,$d,startTime)]
    
    # variable name is a list describing the exact event
    # the first thing is datatype: time is the database table
    # it should go in, and elapsed describes the type of time...
    set var $d

    # initialize the variable if needed
    if {[info exists SessionLog(log,$var)] == 0} {
        set SessionLog(log,$var) 0
    }
    
    # increment total time
    set total [expr $elapsed + $SessionLog(log,$var)]
    set SessionLog(log,$var) $total    
}

#-------------------------------------------------------------------------------
# .PROC SessionLogUnTraceSliceOffsets
# Undo what SessionLogTraceSliceOffsets does, removing trace commands from variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SessionLogUnTraceSliceOffsets {} {
    global Slice SessionLog Module Editor Label

    foreach s $Slice(idList) {
        trace vdelete Slice($s,offset) w SessionLogTraceSliceOffsetsCallback

        # reset vars
        if {[info exists SessionLog(trace,prevSlice$s)] == 1} {
            set SessionLog(trace,prevSlice$s) ""
        }
    }

    foreach var $SessionLog(traceVarlist) {
        if {$::Module(verbose)} {
            puts "SessionLogUnTraceSliceOffsets: deleting trace on $var"
        }
        trace vdelete $var w SessionLogTraceSliceDescriptionCallback
    }
}
