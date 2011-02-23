#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Realtime.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:01 $
#   Version:   $Revision: 1.23 $
# 
#===============================================================================
# FILE:        Realtime.tcl
# PROCEDURES:  
#   RealtimeInit
#   RealtimeBuildVTK
#   RealtimeUpdateMRML
#   RealtimeBuildGUI
#   RealtimeEnter
#   RealtimeSetEffect
#   RealtimeSetMode
#   RealtimeImageComponentCallback
#   RealtimeImageCompleteCallback
#   RealtimeMakeBaseline
#   RealtimeSetRealtime
#   RealtimeSetBaseline
#   RealtimeSetResult
#   RealtimeGetRealtimeID
#   RealtimeGetBaselineID
#   RealtimeGetResultID
#   RealtimeWrite
#   RealtimeRead
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC RealtimeInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeInit {} {
    global Realtime Gui Volume Module

    # Define Tabs
    set m Realtime
    set Module($m,row1List) "Help Processing"
    set Module($m,row1Name) "{Help} {Processing}"
    set Module($m,row1,tab) Processing

    # Module Summary Info
    set Module($m,overview) "Get realtime volumes from the scanner."
    set Module($m,author) "Core"
    set Module($m,category) "Application"

    # Define Procedures
    set Module($m,procGUI)   RealtimeBuildGUI
    set Module($m,procMRML)  RealtimeUpdateMRML
    set Module($m,procVTK)   RealtimeBuildVTK
    set Module($m,procEnter) RealtimeEnter

    # Define Dependencies
    set Module($m,depend) "Locator"

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.23 $} {$Date: 2006/01/06 17:57:01 $}]

    # Initialize globals
    set Realtime(idRealtime)     $Volume(idNone)
    set Realtime(idBaseline)     NEW
    set Realtime(idResult)       NEW
    set Realtime(prefixBaseline) ""
    set Realtime(prefixResult)   ""
    set Realtime(mode)           Off
    set Realtime(effectList)     "Copy"
    set Realtime(effect)         Copy
    set Realtime(pause)          0
}

#-------------------------------------------------------------------------------
# .PROC RealtimeBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeBuildVTK {} {
    global Realtime

}

#-------------------------------------------------------------------------------
# .PROC RealtimeUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeUpdateMRML {} {
    global Volume Realtime

    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $Realtime(idRealtime)] == -1} {
        RealtimeSetRealtime $n
    }
    if {$Realtime(idBaseline) != "NEW" && \
        [lsearch $Volume(idList) $Realtime(idBaseline)] == -1} {
        RealtimeSetBaseline NEW
    }
    if {$Realtime(idResult) != "NEW" && \
        [lsearch $Volume(idList) $Realtime(idResult)] == -1} {
        RealtimeSetResult NEW
    }

    # Realtime Volume menu
    #---------------------------------------------------------------------------
    set m $Realtime(mRealtime)
    $m delete 0 end
    foreach v $Volume(idList) {
        $m add command -label [Volume($v,node) GetName] -command \
            "RealtimeSetRealtime $v; RenderAll"
    }

    # Baseline Volume menu
    #---------------------------------------------------------------------------
    set m $Realtime(mBaseline)
    $m delete 0 end
    set idBaseline ""
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone) && $v != $Realtime(idResult)} {
            $m add command -label [Volume($v,node) GetName] -command \
                "RealtimeSetBaseline $v; RenderAll"
        }
        if {[Volume($v,node) GetName] == "Baseline"} {
            set idBaseline $v
        }
    }
    # If there is Baseline, then select it, else add a NEW option
    if {$idBaseline != ""} {
        RealtimeSetBaseline $idBaseline
    } else {
        $m add command -label NEW -command "RealtimeSetBaseline NEW; RenderAll"
    }

    # Result Volume menu
    #---------------------------------------------------------------------------
    set m $Realtime(mResult)
    $m delete 0 end
    set idResult ""
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone) && $v != $Realtime(idBaseline)} {
            $m add command -label [Volume($v,node) GetName] -command \
                "RealtimeSetResult $v; RenderAll"
        }
        if {[Volume($v,node) GetName] == "Result"} {
            set idResult $v
        }
    }
    # If there is working, then select it, else add a NEW option
    if {$idResult != ""} {
        RealtimeSetResult $idResult
    } else {
        $m add command -label NEW -command "RealtimeSetResult NEW; RenderAll"
    }
}

#-------------------------------------------------------------------------------
# .PROC RealtimeBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeBuildGUI {} {
    global Gui Volume Realtime Module Slice Path

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Processing
    #   Realtime
    #   Baseline
    #   Result
    #   Effects
    #     Menu
    #     Mode
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
This module allows real-time processing of images that are acquired using
the <B>Locator</B> module.  When the <B>Mode</B> is set to <I>On</I>, when
each image is acquired, the selected <B>Effect</B> is applied.  Sometimes,
a <B>Baseline</B> image is involved in the computation, such as subtracting
the <B>Realtime</B> image from the <B>Baseline</B> to form the <B>Result</B>
, for example.
<BR>
If there is no <B>Baseline</B> image, or its size does not match that of
<B>Realtime</B>, the the <B>Realtime</B> image is copied to form a new
<B>Baseline</B>.  This can also be achieved by pressing the <B>Make Baseline</B>
button."
    regsub -all "\n" $help { } help
    MainHelpApplyTags Realtime $help
    MainHelpBuildGUI Realtime


    ############################################################################
    #                                 Processing
    ############################################################################

    #-------------------------------------------
    # Processing frame
    #-------------------------------------------
    set fProcessing $Module(Realtime,fProcessing)
    set f $fProcessing

    frame $f.fRealtime  -bg $Gui(activeWorkspace)
    frame $f.fBaseline  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fResult    -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fEffects   -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack $f.fRealtime $f.fBaseline $f.fResult $f.fEffects \
        -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    #-------------------------------------------
    # Processing->Realtime
    #-------------------------------------------
    set f $fProcessing.fRealtime

    # Realtime Volume menu
    eval {label $f.lRealtime -text "Realtime Volume:"} $Gui(WTA)

    eval {menubutton $f.mbRealtime -text "None" -relief raised -bd 2 -width 18 \
        -menu $f.mbRealtime.m} $Gui(WMBA)
    eval {menu $f.mbRealtime.m} $Gui(WMA)
    pack $f.lRealtime -padx $Gui(pad) -side left -anchor e
    pack $f.mbRealtime -padx $Gui(pad) -side left -anchor w

    # Save widgets for changing
    set Realtime(mbRealtime) $f.mbRealtime
    set Realtime(mRealtime)  $f.mbRealtime.m


    #-------------------------------------------
    # Processing->Baseline
    #-------------------------------------------
    set f $fProcessing.fBaseline

    frame $f.fMenu -bg $Gui(activeWorkspace)
    frame $f.fPrefix -bg $Gui(activeWorkspace)
    frame $f.fBtns   -bg $Gui(activeWorkspace)
    pack $f.fMenu -side top -pady $Gui(pad)
    pack $f.fPrefix -side top -pady $Gui(pad) -fill x
    pack $f.fBtns -side top -pady $Gui(pad)

    #-------------------------------------------
    # Processing->Baseline->Menu
    #-------------------------------------------
    set f $fProcessing.fBaseline.fMenu

    # Volume menu
    eval {label $f.lBaseline -text "Baseline Volume:"} $Gui(WTA)

    eval {menubutton $f.mbBaseline -text "NEW" -relief raised -bd 2 -width 18 \
        -menu $f.mbBaseline.m} $Gui(WMBA)
    eval {menu $f.mbBaseline.m} $Gui(WMA)
    pack $f.lBaseline $f.mbBaseline -padx $Gui(pad) -side left

    # Save widgets for changing
    set Realtime(mbBaseline) $f.mbBaseline
    set Realtime(mBaseline)  $f.mbBaseline.m

    #-------------------------------------------
    # Processing->Baseline->Prefix
    #-------------------------------------------
    set f $fProcessing.fBaseline.fPrefix

    eval {label $f.l -text "Prefix:"} $Gui(WLA)
    eval {entry $f.e \
        -textvariable Realtime(prefixBaseline)} $Gui(WEA)
    pack $f.l -padx 3 -side left
    pack $f.e -padx 3 -side left -expand 1 -fill x

    #-------------------------------------------
    # Processing->Baseline->Btns
    #-------------------------------------------
    set f $fProcessing.fBaseline.fBtns

    eval {button $f.bWrite -text "Save" -width 5 \
        -command "RealtimeWrite Baseline; RenderAll"} $Gui(WBA)
    eval {button $f.bRead -text "Read" -width 5 \
        -command "RealtimeRead Baseline; RenderAll"} $Gui(WBA)
    eval {button $f.bSet -text "Copy Realtime" -width 14 \
        -command "RealtimeMakeBaseline; RenderAll"} $Gui(WBA)
    pack $f.bWrite $f.bRead $f.bSet -side left -padx $Gui(pad)


    #-------------------------------------------
    # Processing->Result
    #-------------------------------------------
    set f $fProcessing.fResult

    frame $f.fMenu -bg $Gui(activeWorkspace)
    frame $f.fPrefix -bg $Gui(activeWorkspace)
    frame $f.fBtns   -bg $Gui(activeWorkspace)
    pack $f.fMenu -side top -pady $Gui(pad)
    pack $f.fPrefix -side top -pady $Gui(pad) -fill x
    pack $f.fBtns -side top -pady $Gui(pad)

    #-------------------------------------------
    # Processing->Result->Menu
    #-------------------------------------------
    set f $fProcessing.fResult.fMenu

    # Volume menu
    eval {label $f.lResult -text "Result Volume:"} $Gui(WTA)

    eval {menubutton $f.mbResult -text "NEW" -relief raised -bd 2 -width 18 \
        -menu $f.mbResult.m} $Gui(WMBA)
    eval {menu $f.mbResult.m} $Gui(WMA)
    pack $f.lResult $f.mbResult -padx $Gui(pad) -side left

    # Save widgets for changing
    set Realtime(mbResult) $f.mbResult
    set Realtime(mResult)  $f.mbResult.m

    #-------------------------------------------
    # Processing->Result->Prefix
    #-------------------------------------------
    set f $fProcessing.fResult.fPrefix

    eval {label $f.l -text "Prefix:"} $Gui(WLA)
    eval {entry $f.e \
        -textvariable Realtime(prefixResult)} $Gui(WEA)
    pack $f.l -padx 3 -side left
    pack $f.e -padx 3 -side left -expand 1 -fill x

    #-------------------------------------------
    # Processing->Result->Btns
    #-------------------------------------------
    set f $fProcessing.fResult.fBtns

    eval {button $f.bWrite -text "Save" -width 5 \
        -command "RealtimeWrite Result; RenderAll"} $Gui(WBA)
    pack $f.bWrite -side left -padx $Gui(pad)



    #-------------------------------------------
    # Processing->Effects
    #-------------------------------------------
    set f $fProcessing.fEffects

    frame $f.fMenu   -bg $Gui(activeWorkspace)
    frame $f.fMode   -bg $Gui(activeWorkspace)
    pack $f.fMenu $f.fMode -side top -pady $Gui(pad)

    #-------------------------------------------
    # Processing->Effects->Menu
    #-------------------------------------------
    set f $fProcessing.fEffects.fMenu

    # Effects menu
    eval {label $f.l -text "Effect:"} $Gui(WTA)

    eval {menubutton $f.mbEffect -text $Realtime(effect) -relief raised -bd 2 -width 15 \
        -menu $f.mbEffect.m} $Gui(WMBA)
    eval {menu $f.mbEffect.m} $Gui(WMA)
    set Realtime(mbEffect) $f.mbEffect
    set m $Realtime(mbEffect).m
    foreach e $Realtime(effectList) {
        $m add command -label $e -command "RealtimeSetEffect $e"
    }
    pack $f.l $f.mbEffect -side left -padx $Gui(pad)
    
    #-------------------------------------------
    # Processing->Effects->Mode
    #-------------------------------------------
    set f $fProcessing.fEffects.fMode

    eval {label $f.lActive -text "Processing:"} $Gui(WLA)
    pack $f.lActive -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach s "On Off" text "On Off" width "3 4" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
            -text $text -value $s -variable Realtime(mode) \
            -command "RealtimeSetMode"} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }

    eval {checkbutton $f.cPause \
        -text "Pause" -variable Realtime(pause) -command "LocatorPause" -width 6 \
        -indicatoron 0} $Gui(WCA)
    pack $f.cPause -side left -padx $Gui(pad)
}

#-------------------------------------------------------------------------------
# .PROC RealtimeEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeEnter {} {
    global Realtime Volume Slice

    # If the Realtime volume is None, then select what's being displayed,
    # otherwise the first volume in the mrml tree.
    
    if {[RealtimeGetRealtimeID] == $Volume(idNone)} {
        set v [[[Slicer GetBackVolume $Slice(activeID)] GetMrmlNode] GetID]
        if {$v == $Volume(idNone)} {
            set v [lindex $Volume(idList) 0]
        }
        if {$v != $Volume(idNone)} {
            RealtimeSetRealtime $v
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC RealtimeSetEffect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeSetEffect {e} {
    global Realtime

    set Realtime(effect) $e

    # Change menu text
    $Realtime(mbEffect) config -text $Realtime(effect)

}

#-------------------------------------------------------------------------------
# .PROC RealtimeSetMode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeSetMode {} {
    global Realtime Locator

    switch $Realtime(mode) {
        "On" {
            if {$Realtime(idRealtime) == $Locator(idRealtime)} {
                LocatorRegisterCallback RealtimeImageComponentCallback
            } else {
                RealtimeImageComponentCallback
                set Realtime(mode) Off
            }
        }
        "Off" {
            if {$Realtime(idRealtime) == $Locator(idRealtime)} {
                LocatorUnRegisterCallback RealtimeImageComponentCallback
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC RealtimeImageComponentCallback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeImageComponentCallback {} {
    global Realtime

    # Images may have multiple components, so this callback is called
    # as each image component is received from the scanner.  Once all
    # components have been received, this callback calls
    # RealtimeImageCompleteCallback to process the complete image.
    #
    # For example, phase difference requires a real and imaginary
    # image.  As each component-image arrives, it can be added to the
    # complete-image as another component using vtkImageAppendComponent.

    # Do nothing if paused
    if {$Realtime(pause) == "1"} {return}

    switch $Realtime(effect) {
        "Copy" {
            RealtimeImageCompleteCallback
        }
        "Subtract" {
            RealtimeImageCompleteCallback
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC RealtimeImageCompleteCallback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeImageCompleteCallback {} {
    global Realtime Volume

    # Perform the realtime image processing

    set s [RealtimeGetRealtimeID]
    set b [RealtimeGetBaselineID]
    set r [RealtimeGetResultID]

    # Check extents
    set sExt [[Volume($s,vol) GetOutput] GetExtent]
    set bExt [[Volume($b,vol) GetOutput] GetExtent]
    if {$sExt != $bExt} {
        puts "Extents are not equal!\n\nRealtime = $sExt\nBaseline = $bExt"
        # Just make a new baseline
        RealtimeMakeBaseline
        return
    }

    # Perform the computation here
    switch $Realtime(effect) {

        # Copy
        "Copy" {
            vtkImageCopy copy
            copy SetInput [Volume($s,vol) GetOutput]
            copy Update
            copy SetInput ""
            Volume($r,vol) SetImageData [copy GetOutput]
            copy SetOutput ""
            copy Delete
        }

        # Subtract
        "Subtract" {
            # THIS DOES NOT WORK
            vtkImageMathematics math
            math SetInput 1 [Volume($s,vol) GetOutput]
            math SetInput 2 [Volume($b,vol) GetOutput]
            math SetOperationToSubtract
            math Update
            math SetInput 1 ""
            math SetInput 2 ""
            Volume($r,vol) SetImageData [math GetOutput]
            math SetOutput ""
            math Delete
        }
    }

    # Mark Result as unsaved
    set Volume($r,dirty) 1

    # r copies s's MrmlNode
    Volume($r,node) Copy Volume($s,node)

    # Update pipeline and GUI
    MainVolumesUpdate $r

    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC RealtimeMakeBaseline
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeMakeBaseline {} {
    global Volume

    # Copy the Realtime image to the Baseline image

    set s [RealtimeGetRealtimeID]
    set b [RealtimeGetBaselineID]

    # Copy image pixels
    vtkImageCopy copy
    copy SetInput [Volume($s,vol) GetOutput]
    copy Update
    copy SetInput ""
    Volume($b,vol) SetImageData [copy GetOutput]
    copy SetOutput ""
    copy Delete

    # Mark baseline as unsaved
    set Volume($b,dirty) 1

    # b copies s's MrmlNode
    Volume($b,node) Copy Volume($s,node)

    # Update pipeline and GUI
    MainVolumesUpdate $b
}


#-------------------------------------------------------------------------------
# .PROC RealtimeSetRealtime
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeSetRealtime {v} {
    global Realtime Volume

    if {$v == $Realtime(idBaseline)} {
        tk_messageBox -message "The Realtime and Baseline volumes must differ."
        return
    }
    if {$v == $Realtime(idResult)} {
        tk_messageBox -message "The Realtime and Result volumes must differ."
        return
    }

    set Realtime(idRealtime) $v
    
    # Change button text
    $Realtime(mbRealtime) config -text [Volume($v,node) GetName]
}

#-------------------------------------------------------------------------------
# .PROC RealtimeSetBaseline
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeSetBaseline {v} {
    global Realtime Volume

    if {$v == [RealtimeGetRealtimeID]} {
        tk_messageBox -message "The Realtime and Baseline volumes must differ."
        return
    }
    if {$v == $Realtime(idResult) && $v != "NEW"} {
        tk_messageBox -message "The Result and Baseline volumes must differ."
        return
    }
    set Realtime(idBaseline) $v
    
    # Change button text, and show file prefix
    if {$v == "NEW"} {
        $Realtime(mbBaseline) config -text $v
        set Realtime(prefixBaseline) ""
    } else {
        $Realtime(mbBaseline) config -text [Volume($v,node) GetName]
        set Realtime(prefixBaseline) [MainFileGetRelativePrefix \
            [Volume($v,node) GetFilePrefix]]
    }
}

#-------------------------------------------------------------------------------
# .PROC RealtimeSetResult
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeSetResult {v} {
    global Realtime Volume

    if {$v == [RealtimeGetRealtimeID]} {
        tk_messageBox -message "The Realtime and Result volumes must differ."
        return
    }
    if {$v == $Realtime(idBaseline) && $v != "NEW"} {
        tk_messageBox -message "The Baseline and Result volumes must differ."
        return
    }
    set Realtime(idResult) $v
    
    # Change button text, and show file prefix
    if {$v == "NEW"} {
        $Realtime(mbResult) config -text $v
        set Realtime(prefixResult) ""
    } else {
        $Realtime(mbResult) config -text [Volume($v,node) GetName]
        set Realtime(prefixResult) [MainFileGetRelativePrefix \
            [Volume($v,node) GetFilePrefix]]
    }
}

#-------------------------------------------------------------------------------
# .PROC RealtimeGetRealtimeID
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeGetRealtimeID {} {
    global Realtime
    
    return $Realtime(idRealtime)
}

#-------------------------------------------------------------------------------
# .PROC RealtimeGetBaselineID
#
# Returns the Baseline volume's ID.
# If there is no Baseline volume (Realtime(idBaseline)==NEW), then it creates one.
# .END
#-------------------------------------------------------------------------------
proc RealtimeGetBaselineID {} {
    global Realtime Volume Lut
        
    # If there is no Baseline volume, then create one
    if {$Realtime(idBaseline) != "NEW"} {
        return $Realtime(idBaseline)
    }
    
    # Create the node
    set n [MainMrmlAddNode Volume]
    set v [$n GetID]
    $n SetDescription "Baseline Volume"
    $n SetName        "Baseline"

    # Create the volume
    MainVolumesCreate $v

    RealtimeSetBaseline $v

    MainUpdateMRML

    # Copy Realtime
    RealtimeMakeBaseline; RenderAll

    return $v
}

#-------------------------------------------------------------------------------
# .PROC RealtimeGetResultID
#
# Returns the Result volume's ID.
# If there is no Result volume (Realtime(idResult)==NEW), then it creates one.
# .END
#-------------------------------------------------------------------------------
proc RealtimeGetResultID {} {
    global Realtime Volume Lut
        
    # If there is no Result volume, then create one
    if {$Realtime(idResult) != "NEW"} {
        return $Realtime(idResult)
    }
    
    # Create the node
    set n [MainMrmlAddNode Volume]
    set v [$n GetID]
    $n SetDescription "Result Volume"
    $n SetName        "Result"

    # Create the volume
    MainVolumesCreate $v

    RealtimeSetResult $v

    MainUpdateMRML

    return $v
}


#-------------------------------------------------------------------------------
# .PROC RealtimeWrite
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeWrite {data} {
    global Volume Realtime

    # If the volume doesn't exist yet, then don't write it, duh!
    if {$Realtime(id$data) == "NEW"} {
        tk_messageBox -message "Nothing to write."
        return
    }

    switch $data {
        Result   {set v [RealtimeGetResultID]}
        Baseline {set v [RealtimeGetBaselineID]}
    }

    # Show user a File dialog box
    set Realtime(prefix$data) [MainFileSaveVolume $v $Realtime(prefix$data)]
    if {$Realtime(prefix$data) == ""} {return}

    # Write
    MainVolumesWrite $v $Realtime(prefix$data)

    # Prefix changed, so update the Volumes->Props tab
    MainVolumesSetActive $v
}

#-------------------------------------------------------------------------------
# .PROC RealtimeRead
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealtimeRead {data} {
    global Volume Realtime Mrml

    # If the volume doesn't exist yet, then don't read it, duh!
    if {$Realtime(id$data) == "NEW"} {
        tk_messageBox -message "Nothing to read."
        return
    }

    switch $data {
        Result   {set v $Realtime(idResult)}
        Baseline {set v $Realtime(idBaseline)}
    }

    # Show user a File dialog box
    set Realtime(prefix$data) [MainFileOpenVolume $v $Realtime(prefix$data)]
    if {$Realtime(prefix$data) == ""} {return}
    
    # Read
    Volume($v,node) SetFilePrefix $Realtime(prefix$data)
    Volume($v,node) SetFullPrefix \
        [file join $Mrml(dir) [Volume($v,node) GetFilePrefix]]
    if {[MainVolumesRead $v] < 0} {
        return
    }

    # Update pipeline and GUI
    MainVolumesUpdate $v

    # Prefix changed, so update the Models->Props tab
    MainVolumesSetActive $v
}

