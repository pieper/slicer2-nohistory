

#-------------------------------------------------------------------------------
# .PROC dup_DefaceFindDICOM2
# 
# .ARGS
# path StartDir
# path AddDir
# string Pattern
# .END
#-------------------------------------------------------------------------------
proc dup_DefaceFindDICOM2 { StartDir AddDir Pattern } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames DICOMPatientIDs 

    # bail out early 
    if { [info exists ::DICOMabort] && $::DICOMabort == "true" } {
        return
    }


    set pwd [pwd]
    if [expr [string length $AddDir] > 0] {
        if [catch {cd $AddDir} err] {
            puts stderr $err
            return
        }
    }

    # add progress indicator
    set w .dicomprogress
    set ::DICOMabort "false"
    if { ![winfo exists $w] } {
        toplevel $w
        wm title $w "Collecting DICOM Files..."
        wm geometry $w 400x150
        set ::DICOMlabel "working..."
        pack [label $w.label -textvariable ::DICOMlabel] 
        pack [button $w.cancel -text "Stop Looking" -command {set ::DICOMabort "true"} ]

        update ;# make sure the window exists before grabbing events
        catch "grab $w" ;# this one just stops slicer from responding
    }
    
    vtkDCMParser parser
    foreach match [glob -nocomplain -- $Pattern] {
        #puts stdout [file join $StartDir $match]

        wm title $w "Searching [pwd]"
        set ::DICOMlabel "\n\nExamining $match\n\n$::FindDICOMCounter DICOM files so far.\n"
        update
        if { $::DICOMabort == "true" } {
            break
        } 

        if {[file isdirectory $match]} {
            continue
        }
        set FileName [file join $StartDir $AddDir $match]
        set found [parser OpenFile $match]
        if {[string compare $found "0"] == 0} {
            puts stderr "Can't open file [file join $StartDir $AddDir $match]"
        } else {
            set found [parser FindElement 0x7fe0 0x0010]
            if {[string compare $found "1"] == 0} {
                #
                # image data is available
                #
                
                set DICOMFiles($FindDICOMCounter,FileName) $FileName
                
                if [expr [parser FindElement 0x0010 0x0010] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set PatientName [parser ReadText $Length]
                    if {$PatientName == ""} {
                        set PatientName "noname"
                    }
                } else  {
                    set PatientName 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,PatientName) $PatientName
                dup_AddListUnique DICOMPatientNames $PatientName
                
                if [expr [parser FindElement 0x0010 0x0020] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set PatientID [string trim [parser ReadText $Length]]
                    if {$PatientID == ""} {
                        set PatientID "noid"
                    }
                } else  {
                    set PatientID 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,PatientID) $PatientID
                dup_AddListUnique DICOMPatientIDs $PatientID
                set add {}
                append add "<" $PatientID "><" $PatientName ">"
                dup_AddListUnique DICOMPatientIDsNames $add
                set DICOMFiles($FindDICOMCounter,PatientIDName) $add
                #DYW change to studyID if [expr [parser FindElement 0x0020 0x000d] == "1"] 
                if [expr [parser FindElement 0x0020 0x0010] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set StudyInstanceUID [string trim [parser ReadText $Length]]
                    set zeros [string length $StudyInstanceUID]
                    if { $zeros > 4 } {
                       set StudyInstanceUID [string range $StudyInstanceUID [expr $zeros - 4] end]
                    } else {
                       set zeros [expr 4 - $zeros]
                       for {set lloop $zeros} {$lloop > 0} {incr lloop -1} {
                          set StudyInstanceUID "0$StudyInstanceUID"
                       }
                    }             
                } else  {
                    set StudyInstanceUID 9999
                }
                set DICOMFiles($FindDICOMCounter,StudyInstanceUID) $StudyInstanceUID
                #DYW change to seriesID if [expr [parser FindElement 0x0020 0x000e] == "1"] 
                if [expr [parser FindElement 0x0020 0x0011] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set SeriesInstanceUID [string trim [parser ReadText $Length]]
                    set zeros [string length $SeriesInstanceUID ]
                    if { $zeros > 3 } {
                       set SeriesInstanceUID [string range $SeriesInstanceUID [expr $zeros - 3] end]
                    } else {
                       set zeros [expr 3 - $zeros]
                       for {set lloop 0} {$lloop < $zeros} {incr lloop } {
                          set SeriesInstanceUID "0$SeriesInstanceUID"
                       }
                    }             
                } else  {
                    set SeriesInstanceUID 999
                }
                set DICOMFiles($FindDICOMCounter,SeriesInstanceUID) $SeriesInstanceUID


                if [expr [parser FindElement 0x0020 0x0020] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set ProjectID [string trim [parser ReadText $Length]]
                    set zeros [string length $ProjectID ]
                    if { $zeros > 4 } {
                       set ProjectID [string range $ProjectID [expr $zeros - 4] end]
                    } else {
                       set zeros [expr 4 - $zeros]
                       for {set lloop 0} {$lloop < $zeros} {incr lloop } {
                          set ProjectID "0$ProjectID"
                       }
                    }             
                } else  {
                    set ProjectID  9999
                }
                set DICOMFiles($FindDICOMCounter,ProjectID) $ProjectID


                if [expr [parser FindElement 0x0020 0x0040] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set SubjectID [string trim [parser ReadText $Length]]
                    
                } else  {
                    set SubjectID 99999999
                }
                set DICOMFiles($FindDICOMCounter,SubjectID) $SubjectID


                if [expr [parser FindElement 0x0018 0x1314] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set FlipAngle [string trim [parser ReadText $Length]]
                } else  {
                    set FlipAngle 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,FlipAngle) $FlipAngle

                
        #set ImageNumber ""
        #if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        #    set NextBlock [lindex [split [parser ReadElement]] 4]
        #    set ImageNumber [parser ReadFloatAsciiNumeric $NextBlock]
        #} 
        #if { $ImageNumber == "" } {
            if [expr [parser FindElement 0x0020 0x0013] == "1"] {
            #set Length [lindex [split [parser ReadElement]] 3]
            #set ImageNumber [parser ReadText $Length]
            #scan [parser ReadText $length] "%d" ImageNumber
            
            set NextBlock [lindex [split [parser ReadElement]] 4]
            set ImageNumber [parser ReadIntAsciiNumeric $NextBlock]
            } else  {
            set ImageNumber 1
            }
        #}
                
                    set zeros [string length $ImageNumber  ]
                    if { $zeros > 3 } {
                       set SeriesInstanceUID [string range $ImageNumber [expr $zeros - 3] end]
                    } else {
                       set zeros [expr 3 - $zeros]
                       for {set lloop 0} {$lloop < $zeros} {incr lloop } {
                          set ImageNumber "0$ImageNumber"
                       }
                    }             
                set DICOMFiles($FindDICOMCounter,ImageNumber) $ImageNumber
                
                incr FindDICOMCounter
                #puts [file join $StartDir $AddDir $match]
            } else {
                #set dim 256
            }
            parser CloseFile
        }
    }
    parser Delete
    
    if { $::DICOMabort != "true" && $::DICOMrecurse == "true" } {
        foreach file [glob -nocomplain *] {
            if [file isdirectory $file] {
                dup_DefaceFindDICOM2 [file join $StartDir $AddDir] $file $Pattern
            }
        }
    }
    cd $pwd
}

#-------------------------------------------------------------------------------
# .PROC dup_DefaceFindDICOM
# 
# .ARGS
# path StartDir
# string Pattern
# .END
#-------------------------------------------------------------------------------
proc dup_DefaceFindDICOM { StartDir Pattern } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames DICOMPatientIDs 
    global DICOMStudyInstanceUIDList
    global DICOMSeriesInstanceUIDList
    global DICOMFileNameArray
    global DICOMFileNameList DICOMFileNameSelected
    
    if [array exists DICOMFiles] {
        unset DICOMFiles
    }
    if [array exists DICOMFileNameArray] {
        unset DICOMFileNameArray
    }
    set pwd [pwd]
    set FindDICOMCounter 0
    set DICOMPatientNames {}
    set DICOMPatientIDsNames {}
    set DICOMPatientIDs {}
    set DICOMStudyList {}
    set DICOMSeriesList {}
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    
    if [catch {cd $StartDir} err] {
        puts stderr $err
        cd $pwd
        return
    }
    dup_DefaceFindDICOM2 $StartDir "" $Pattern
    catch "grab relase .dicomprogress"
    catch "destroy .dicomprogress"
    catch "unset ::DICOMabort"
    cd $pwd
}

#-------------------------------------------------------------------------------
# .PROC dup_AddListUnique
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_AddListUnique { list arg } {
    upvar $list list2
    if { [expr [lsearch -exact $list2 $arg] == -1] } {
        lappend list2 $arg
    }
}

#-------------------------------------------------------------------------------
# .PROC dup_DevErrorWindow
#
#  Report an Error to the user. Force them to click OK to continue.<br>
#  Resets the tk scaling to 1 and then returns it to the original value.
#
# .ARGS
#  str message The error message. Default: \"Unknown Error\"
# .END
#-------------------------------------------------------------------------------
proc dup_DevErrorWindow {{message "Unknown Error"}} {
    set oscaling [tk scaling]
    tk scaling 1
    if {$::Module(verbose)} {
        puts "$message"
    }
    tk_messageBox -title Slicer -icon error -message $message -type ok
    tk scaling $oscaling
}

# DevErrorWindow is needed by the bgerror catcher
if { [info command DevErrorWindow] == "" } {
    proc DevErrorWindow {m} {dup_DevErrorWindow $m}
}

#-------------------------------------------------------------------------------
# .PROC dup_DevInfoWindow
#
#  Report Information to the user. Force them to click OK to continue.<br>
#  Resets the tk scaling to 1 and then returns it to the original value.
#
# .ARGS
#  str message The error message. Default: \"Unknown Warning\"
# .END
#-------------------------------------------------------------------------------
proc dup_DevInfoWindow {message} {
    set oscaling [tk scaling]
    tk scaling 1
    tk_messageBox -title "Slicer" -icon info -message $message -type ok
    tk scaling $oscaling
}

#-------------------------------------------------------------------------------
# .PROC dup_DevWarningWindow
#
#  Report a Warning to the user. Force them to click OK to continue.<br>
#  Resets the tk scaling to 1 and then returns it to the original value.
#
# .ARGS
#  str message The error message. Default: \"Unknown Warning\"
# .END
#-------------------------------------------------------------------------------
proc dup_DevWarningWindow {{message "Unknown Warning"}} {
    set oscaling [tk scaling]
    tk scaling 1
    tk_messageBox -title "Slicer" -icon warning -message $message
    tk scaling $oscaling
}

#-------------------------------------------------------------------------------
# .PROC dup_DevOKCancel
#
#  Ask the user an OK/Cancel question. Force the user to decide before continuing.<br>
#  Returns "ok" or "cancel". <br>
#  Resets the tk scaling to 1 and then returns it to the original value.
# .ARGS
#  str message The message to give.
# .END
#-------------------------------------------------------------------------------
proc dup_DevOKCancel {message} {
    set oscaling [tk scaling]
    
    if {$::Module(verbose)} {
        puts "dup_DevOKCancel: original scaling is $oscaling, changing it to 1 and then back"
    }

    tk scaling 1
    set retval [tk_messageBox -title Slicer -icon question -type okcancel -message $message]
    tk scaling $oscaling

    return $retval
}


# default to disabled tooltips when this file is first sourced
set dup_Tooltips(enabled) 0

#-------------------------------------------------------------------------------
# .PROC dup_TooltipAdd
# Call this procedure to add a tooltip (floating help text) to a widget. 
# The tooltip will pop up over the widget when the user leaves the mouse
# over the widget for a little while.
# .ARGS
# str widget name of the widget
# str tip text that you would like to appear as a tooltip.
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipAdd {widget tip} {

    # surround the tip string with brackets
    set tip "\{$tip\}"

    # bindings
    bind $widget <Enter> "dup_TooltipEnterWidget %W $tip %X %Y"
    bind $widget <Leave> dup_TooltipExitWidget


    # The following are fixes to make buttons work right with tooltips...

    # put the class (i.e. Button) first in the bindtags so it executes earlier
    # (this makes button highlighting work)
    # just swap the first two list elements
    set btags [bindtags $widget]
    if {[llength $btags] > 1} {
    set class [lindex $btags 1]
    set btags [lreplace $btags 1 1 [lindex $btags 0]]
    set btags [lreplace $btags 0 0 $class]
    }
    bindtags $widget $btags

    # if the button is pressed, this should be like a Leave event
    # (otherwise the tooltip will come up incorrectly)
    if {$class == "Button" || $class == "Radiobutton"} {
    set cmd [$widget cget -command]
    set cmd "dup_TooltipExitWidget; $cmd"
    }
}


#-------------------------------------------------------------------------------
# .PROC dup_TooltipEnterWidget
# Internal procedure for dup_Tooltips.tcl.  Called when the mouse enters the widget.
# This proc works with dup_TooltipExitWidget to pop up the tooltip after a delay.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipEnterWidget {widget tip X Y} {
    global dup_Tooltips


    # do nothing if tooltips disabled
    if {$dup_Tooltips(enabled) == 0} {
    return
    }

    # We are over the widget
    set dup_Tooltips(stillOverWidget) 1

    # reset dup_Tooltips(stillOverWidget) after a delay (to end the "vwait")
    set id [after 500 \
        {if {$dup_Tooltips(stillOverWidget) == 1} {set dup_Tooltips(stillOverWidget) 1}}]

    # wait until dup_Tooltips(stillOverWidget) is set (by us or by exiting the widget).
    # "vwait" allows event loop to be entered (but using an "after" does not)
    vwait dup_Tooltips(stillOverWidget)

    # if dup_Tooltips(stillOverWidget) is 1, the mouse is still over widget.
    # So pop up the tooltip!
    if {$dup_Tooltips(stillOverWidget) == 1} {
    dup_TooltipPopUp $widget $tip $X $Y
    } else {
    # the mouse exited the widget already, so cancel the waiting.
    after cancel $id
    }

}

#-------------------------------------------------------------------------------
# .PROC dup_TooltipExitWidget
# Internal procedure for dup_Tooltips.tcl.  Called when the mouse exits the widget. 
# This proc works with dup_TooltipEnterWidget to pop up the tooltip after a delay.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipExitWidget {} {
    global dup_Tooltips

    # mouse is not over the widget anymore, so stop the vwait.
    set dup_Tooltips(stillOverWidget) 0

    # remove the tooltip if there is one.
    dup_TooltipPopDown
}

#-------------------------------------------------------------------------------
# .PROC dup_TooltipPopUp
# Internal procedure for dup_Tooltips.tcl.  Causes the tooltip window to appear. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipPopUp {widget tip X Y} {
    global dup_Tooltips Gui

    # set tooltip window name
    if {[info exists dup_Tooltips(window)] == 0} {
    set dup_Tooltips(window) .wdup_Tooltips
    }

    # get rid of any other existing tooltip
    dup_TooltipPopDown

    # make a new tooltip window
    toplevel $dup_Tooltips(window)

    # add an offset to make tooltips fall below cursor
    set Y [expr $Y+15]

    # don't let the window manager "reparent" the tip window
    wm overrideredirect $dup_Tooltips(window) 1

    # display the tip text...
    wm geometry $dup_Tooltips(window) +${X}+${Y}
    eval {label $dup_Tooltips(window).l -text $tip } $Gui(WTTA)
    pack $dup_Tooltips(window).l -in $dup_Tooltips(window)
}

#-------------------------------------------------------------------------------
# .PROC dup_TooltipPopDown
# Internal procedure for dup_Tooltips.tcl.  Removes the tooltip window. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipPopDown {} {
    global dup_Tooltips

    catch {destroy $dup_Tooltips(window)}
}

#-------------------------------------------------------------------------------
# .PROC dup_TooltipDisable
# Turn off display of tooltips
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipDisable {} {
    global dup_Tooltips

    # get rid of any other existing tooltip
    dup_TooltipPopDown

    # disable tooltips
    set dup_Tooltips(enabled) 0
}

#-------------------------------------------------------------------------------
# .PROC dup_TooltipEnable
# Turn on display of tooltips
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipEnable {} {
    global dup_Tooltips

    # disable tooltips
    set dup_Tooltips(enabled) 1
}

#-------------------------------------------------------------------------------
# .PROC dup_TooltipToggle
# Toggle tooltip display on/off
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_TooltipToggle {} {
    global dup_Tooltips

    if {$dup_Tooltips(enabled) == 1} {
    set dup_Tooltips(enabled) 0
    } else {
    set dup_Tooltips(enabled) 1
    } 
}

## copied from tcllib ##
#
# ::fileutil::tempdir --
#
#    Return the correct directory to use for temporary files.
#    Python attempts this sequence, which seems logical:
#
#       1. The directory named by the `TMPDIR' environment variable.
#
#       2. The directory named by the `TEMP' environment variable.
#
#       3. The directory named by the `TMP' environment variable.
#
#       4. A platform-specific location:
#            * On Macintosh, the `Temporary Items' folder.
#
#            * On Windows, the directories `C:\\TEMP', `C:\\TMP',
#              `\\TEMP', and `\\TMP', in that order.
#
#            * On all other platforms, the directories `/tmp',
#              `/var/tmp', and `/usr/tmp', in that order.
#
#        5. As a last resort, the current working directory.
#
# Arguments:
#    None.
#
# Side Effects:
#    None.
#
# Results:
#    The directory for temporary files.

proc dup_tempdir {} {
    global tcl_platform env
    set attempdirs [list]

    foreach tmp {TMPDIR TEMP TMP} {
        if { [info exists env($tmp)] } {
            lappend attempdirs $env($tmp)
        }
    }

    switch $tcl_platform(platform) {
        windows {
            lappend attempdirs "C:\\TEMP" "C:\\TMP" "\\TEMP" "\\TMP"
        }
        macintosh {
            set tmpdir $env(TRASH_FOLDER)  ;# a better place?
        }
        default {
            lappend attempdirs [file join / tmp] \
            [file join / var tmp] [file join / usr tmp]
        }
    }

    foreach tmp $attempdirs {
        if { [file isdirectory $tmp] && [file writable $tmp] } {
            return $tmp
        }
    }

    # If nothing else worked...
    return [pwd]
}

# return the information required by the --all-info flag
proc dup_AllInfo { {argv {}} {programVersion "none"} } {

    if {[info exists ::SLICER(versionInfo)]} {
        set infoText $::SLICER(versionInfo)
    } else {
        set execName "slicer2-linux-x86"
        set infoText "ProgramName: $execName ProgramArguments: $argv\nTimeStamp: [clock format [clock seconds] -format "%D-%T-%Z"] User: $::env(USER) Machine: $::tcl_platform(machine) Platform: $::tcl_platform(os) PlatformVersion: $::tcl_platform(osVersion)"
    }

    if {$programVersion == "none"} {
        if {[info exist ::SLICER(version)]} {
            set programVersion $::SLICER(version)
        }
    }

    package require vtkSlicerBase
    catch "infoSlicer Delete"
    vtkMrmlSlicer infoSlicer

    set compilerVersion [infoSlicer GetCompilerVersion]
    set compilerName [infoSlicer GetCompilerName]
    set vtkVersion [infoSlicer GetVTKVersion]

    if {[info command vtkITKVersion] == ""} {
        set itkVersion "none"
    } else {
        catch "vtkITKVersion vtkitkver"
        catch "set itkVersion [vtkitkver GetITKVersion]"
        catch "vtkitkver Delete"
    }
    set libVersions "LibName: VTK LibVersion: ${vtkVersion} LibName: TCL LibVersion: $::tcl_patchLevel LibName: TK LibVersion: $::tk_patchLevel LibName: ITK LibVersion: ${itkVersion}"
    set cvsID {$Id: dup_slicer_utils.tcl,v 1.4 2006/03/17 21:58:49 nicole Exp $}
    set idText "BIRNDUP"
    foreach a $cvsID {
        lappend idText [string trim $a {$ \t}]
    }
    set infoText "$infoText  Version: $programVersion CompilerName: ${compilerName} CompilerVersion: $compilerVersion ${libVersions} CVS: $idText "

    infoSlicer Delete

    puts $infoText

    return $infoText
}
