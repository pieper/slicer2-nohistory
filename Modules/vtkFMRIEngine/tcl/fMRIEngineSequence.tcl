#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineSequence.tcl,v $
#   Date:      $Date: 2006/03/02 22:21:33 $
#   Version:   $Revision: 1.10 $
# 
#===============================================================================
# FILE:        fMRIEngineSequence.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForLoad the
#   fMRIEngineBuildUIForSelect the
#   fMRIEngineSetWindowLevelThresholds
#   fMRIEngineUpdateVolume the
#   fMRIEngineDeleteSeq-RunMatch
#   fMRIEngineAddSeq-RunMatch
#   fMRIEngineCheckNumRuns
#   fMRIEngineUpdateRuns
#   fMRIEngineSelectRun
#   fMRIEngineSelectSequence
#   fMRIEngineUpdateSequences
#==========================================================================auto=

proc fMRIEngineUpdateSequenceTab {} {
    global fMRIEngine

    set fMRIEngine(currentTab) "Sequence"
}

  
#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForLoad
# Creates UI for Load page 
# .ARGS
# parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForLoad {parent} {
    global fMRIEngine Gui

    frame $parent.fTop -bg $Gui(activeWorkspace)
    frame $parent.fBot -bg $Gui(activeWorkspace)
    pack $parent.fTop $parent.fBot -side top 
 
    set f $parent.fTop
    MultiVolumeReaderBuildGUI $f 1

    set f $parent.fBot
    set uselogo [image create photo -file \
        $fMRIEngine(modulePath)/tcl/images/LogosForIbrowser.gif]
    eval {label $f.lLogoImages -width 200 -height 45 \
        -image $uselogo -justify center} $Gui(BLA)
    pack $f.lLogoImages -side bottom -padx 0 -pady 0 -expand 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForSelect
# Creates UI for Select page 
# .ARGS
# parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForSelect {parent} {
    global fMRIEngine Gui

    frame $parent.fTop    -bg $Gui(activeWorkspace) -relief groove -bd 3 
    frame $parent.fBottom -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack $parent.fTop $parent.fBottom -side top -pady 5 -padx 0  

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    frame $f.fSeqs    -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $f.fOK      -bg $Gui(activeWorkspace)
    frame $f.fListbox -bg $Gui(activeWorkspace)
    pack $f.fSeqs $f.fOK $f.fListbox -side top -pady 3 -padx 1  

    #------------------------------
    # Loaded sequences 
    #------------------------------
    set f $parent.fTop.fSeqs

    DevAddLabel $f.lNo "Number of runs:"
    eval {entry $f.eRun -width 17 \
        -textvariable fMRIEngine(noOfRuns)} $Gui(WEA)
    bind $f.eRun  <Leave> "fMRIEngineCheckNumRuns"     
    set fMRIEngine(noOfRuns) 1

    # Build pulldown menu for all loaded sequences 
    DevAddLabel $f.lSeq "Choose a sequence:"
    set sequenceList [list {none}]
    set df [lindex $sequenceList 0] 
    eval {menubutton $f.mbType -text $df \
        -relief raised -bd 2 -width 13 \
        -indicatoron 1 \
        -menu $f.mbType.m} $Gui(WMBA)
    bind $f.mbType <1> "fMRIEngineUpdateSequences" 
    eval {menu $f.mbType.m} $Gui(WMA)

    # Add menu items
    foreach m $sequenceList {
        $f.mbType.m add command -label $m \
            -command ""
    }

    # Save menubutton for config
    set fMRIEngine(gui,sequenceMenuButton) $f.mbType
    set fMRIEngine(gui,sequenceMenu) $f.mbType.m

    # Build pulldown menu for all runs 
    DevAddLabel $f.lRun "Used for run#:"
    set runList [list {1}]
    set df [lindex $runList 0] 
    eval {menubutton $f.mbType2 -text $df \
        -relief raised -bd 2 -width 13 \
        -indicatoron 1 \
        -menu $f.mbType2.m} $Gui(WMBA)
    bind $f.mbType2 <1> "fMRIEngineUpdateRuns" 
    eval {menu $f.mbType2.m} $Gui(WMA)

    set fMRIEngine(currentSelectedRun) 1

    # Save menubutton for config
    set fMRIEngine(gui,runListMenuButton) $f.mbType2
    set fMRIEngine(gui,runListMenu) $f.mbType2.m
    fMRIEngineUpdateRuns

    blt::table $f \
        0,0 $f.lNo -padx 3 -pady 3 \
        0,1 $f.eRun -padx 2 -pady 3 \
        1,0 $f.lSeq -fill x -padx 3 -pady 3 \
        1,1 $f.mbType -padx 2 -pady 3 \
        2,0 $f.lRun -fill x -padx 3 -pady 3 \
        2,1 $f.mbType2 -padx 2 -pady 3 

    #------------------------------
    # OK  
    #------------------------------
    set f $parent.fTop.fOK
    DevAddButton $f.bOK "Add" "fMRIEngineAddSeq-RunMatch" 6 
    grid $f.bOK -padx 2 

    #-----------------------
    # List box  
    #-----------------------
    set f $parent.fTop.fListbox
    frame $f.fBox -bg $Gui(activeWorkspace)
    frame $f.fAction  -bg $Gui(activeWorkspace)
    pack $f.fBox $f.fAction -side top -fill x -pady 1 -padx 2 

    set f $parent.fTop.fListbox.fBox
    DevAddLabel $f.lSeq "Specified runs:"
    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(seqVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -yscrollcommand {$::fMRIEngine(seqVerScroll) set}
    set fMRIEngine(seqListBox) $f.lb
    set fMRIEngine(noOfSpecifiedRuns) [$fMRIEngine(seqListBox) size] 
    $fMRIEngine(seqVerScroll) configure -command {$fMRIEngine(seqListBox) yview}

    blt::table $f \
        0,0 $f.lSeq -cspan 2 -pady 5 -fill x \
        1,0 $fMRIEngine(seqListBox) -padx 1 -pady 1 \
        1,1 $fMRIEngine(seqVerScroll) -fill y -padx 1 -pady 1

    #-----------------------
    # Action  
    #-----------------------
    set f $parent.fTop.fListbox.fAction
    DevAddButton $f.bDelete "Delete" "fMRIEngineDeleteSeq-RunMatch" 6 
    grid $f.bDelete -padx 2 -pady 2 

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBottom
    frame $f.fLabel   -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    frame $f.fSlider  -bg $Gui(activeWorkspace)
    pack $f.fLabel $f.fButtons $f.fSlider -side top -fill x -pady 1 -padx 2 

    set f $parent.fBottom.fLabel
    DevAddLabel $f.lLabel "Navigate the sequence:"
    pack $f.lLabel -side top -fill x -pady 1 -padx 2 

    set f $parent.fBottom.fButtons
    DevAddButton $f.bHelp "?" "fMRIEngineHelpLoadVolumeAdjust" 2
    DevAddButton $f.bSet "Set Window/Level/Thresholds" \
        "fMRIEngineSetWindowLevelThresholds" 30 
    grid $f.bHelp $f.bSet -padx 1 

    set f $parent.fBottom.fSlider
    DevAddLabel $f.lVolno "Volume index:"
    eval { scale $f.sSlider \
        -orient horizontal \
        -from 0 -to 0 \
        -resolution 1 \
        -bigincrement 10 \
        -length 120 \
        -state active \
        -command {fMRIEngineUpdateVolume}} \
        $Gui(WSA) {-showvalue 1}
    grid $f.lVolno $f.sSlider 

    set fMRIEngine(slider) $f.sSlider
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSetWindowLevelThresholds
# For a time series, set window, level, and low/high thresholds for all volumes
# with the first volume's values
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSetWindowLevelThresholds {} {
   global fMRIEngine Volume 

    if {[info exists fMRIEngine(noOfVolumes)] == 0} {
        return
    }

    set low [Volume($fMRIEngine(firstMRMLid),node) GetLowerThreshold]
    set win [Volume($fMRIEngine(firstMRMLid),node) GetWindow]
    set level [Volume($fMRIEngine(firstMRMLid),node) GetLevel]
    set fMRIEngine(lowerThreshold) $low

    set i $fMRIEngine(firstMRMLid)
    while {$i <= $fMRIEngine(lastMRMLid)} {
        # If AutoWindowLevel is ON, 
        # we can't set new values for window and level.
        Volume($i,node) AutoWindowLevelOff
        Volume($i,node) SetWindow $win 
        Volume($i,node) SetLevel $level 
 
        Volume($i,node) AutoThresholdOff
        Volume($i,node) ApplyThresholdOn
        Volume($i,node) SetLowerThreshold $low 
        incr i
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateVolume
# Updates image volume as user moves the slider 
# .ARGS
# volumeNo the volume number
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateVolume {volumeNo} {
    global fMRIEngine

    if {$volumeNo == 0} {
#        DevErrorWindow "Volume number must be greater than 0."
        return
    }

    set v [expr $volumeNo-1]
    set id [expr $fMRIEngine(firstMRMLid)+$v]

    MainSlicesSetVolumeAll Back $id 
    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineDeleteSeq-RunMatch
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineDeleteSeq-RunMatch {} {
    global fMRIEngine 

    set curs [$fMRIEngine(seqListBox) curselection]
    if {$curs != ""} {
        set first [lindex $curs 0] 
        set last [lindex $curs end]
        $fMRIEngine(seqListBox) delete $first $last

        fMRIEngineUpdateRunsForModelFitting

        # delete baseline 
        set index [string first ":" $curs]
        set run [string range $curs 0 [expr $index-1]]

        set size [$fMRIEngine(evsListBox) size]
        set i 0 
        set found -1
        while {$i < $size} {  
            set v [$fMRIEngine(evsListBox) get $i] 
            if {$v != ""} {
                set found [string first "$run:baseline" $v]
                if {$found >= 0} {
                    break
                }
            } 
            incr i
        }
        if {$found >= 0} {
            $fMRIEngine(evsListBox) delete $i $i 
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddSeq-RunMatch
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddSeq-RunMatch {} {
    global fMRIEngine 

    # Add a sequence-run match
    if {! [info exists fMRIEngine(currentSelectedSequence)] ||
        $fMRIEngine(currentSelectedSequence) == "none"} {
        DevErrorWindow "Select a valid sequence."
        return
    }

    if {! [info exists fMRIEngine(currentSelectedRun)] ||
        $fMRIEngine(currentSelectedRun) == "none"} {
        DevErrorWindow "Select a valid run."
        return
    }

    set str \
        "r$fMRIEngine(currentSelectedRun):$fMRIEngine(currentSelectedSequence)"
    set i 0
    set foundRun 0
    set foundSeq 0
    set size [$fMRIEngine(seqListBox) size]
    while {$i < $size} {  
        set v [$fMRIEngine(seqListBox) get $i] 
        if {$v != ""} {
            set i1 1 
            set i2 [string first ":" $v]

            set run [string range $v $i1 [expr $i2-1]] 
            set run [string trim $run]
            set seq [string range $v [expr $i2+1] end]
            set seq [string trim $seq]

            if {$run == $fMRIEngine(currentSelectedRun)} {
                DevErrorWindow "r$run has been specified."
                return
            }
            if {$seq == $fMRIEngine(currentSelectedSequence)} {
                DevErrorWindow "$seq has been specified."
                return
            }
        }
        incr i
    }

    $fMRIEngine(seqListBox) insert end $str 
    set fMRIEngine($fMRIEngine(currentSelectedRun),sequenceName) \
        $fMRIEngine(currentSelectedSequence)

    fMRIEngineUpdateRunsForModelFitting

    # add baseline 
    set size [$fMRIEngine(evsListBox) size]
    set i 0 
    set found -1
    while {$i < $size} {  
        set v [$fMRIEngine(evsListBox) get $i] 
        if {$v != ""} {
            set found [string first "r$fMRIEngine(currentSelectedRun):baseline" $v]
            if {$found >= 0} {
                break
            }
        } 
        incr i
    }
    if {$found == -1} {
        $fMRIEngine(evsListBox) insert 0 "r$fMRIEngine(currentSelectedRun):baseline" 
    }
    set ::fMRIEngine(SignalModelDirty) 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCheckNumRuns
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCheckNumRuns { } {

    #--- fMRIEngine(noOfRuns) must be an integer.
    if { ! [string is digit $::fMRIEngine(noOfRuns) ] } {
        DevErrorWindow "Number of runs must be an integer value."
        set ::fMRIEngine(noOfRuns) 1
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateRuns
# Chooses one sequence from the sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateRuns {} {
    global fMRIEngine 

    set runs [string trim $fMRIEngine(noOfRuns)]
    if {$runs < 1} {
        DevErrorWindow "No of runs must be at least 1."
    } else { 
        $fMRIEngine(gui,runListMenu) delete 0 end
        set count 1
        while {$count <= $runs} {
            $fMRIEngine(gui,runListMenu) add command -label $count \
                -command "fMRIEngineSelectRun $count"
            incr count
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectRun {run} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,runListMenuButton) config -text $run
    set fMRIEngine(currentSelectedRun) $run
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectSequence
# Chooses one sequence from the sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectSequence {seq} {
    global fMRIEngine Ibrowser MultiVolumeReader Volume

    # configure menubutton
    $fMRIEngine(gui,sequenceMenuButton) config -text $seq
    set fMRIEngine(currentSelectedSequence) $seq
    if {$seq == "none"} {
        return
    }

    set l [string trim $seq]

    if {[info exists MultiVolumeReader(sequenceNames)]} {
        set found [lsearch -exact $MultiVolumeReader(sequenceNames) $seq]
        if {$found >= 0} {
            set fMRIEngine(firstMRMLid) $MultiVolumeReader($seq,firstMRMLid) 
            set fMRIEngine(lastMRMLid) $MultiVolumeReader($seq,lastMRMLid)
            set fMRIEngine(volumeExtent) $MultiVolumeReader($seq,volumeExtent) 
            set fMRIEngine(noOfVolumes) $MultiVolumeReader($seq,noOfVolumes) 
        }
    }


    # Sets range for the volume slider
    $fMRIEngine(slider) configure -from 1 -to $fMRIEngine(noOfVolumes)
    # Sets the first volume in the sequence as the active volume
    MainVolumesSetActive $fMRIEngine(firstMRMLid)

    # In the Load tab of Sequence, we use the value of Volume(name) for 
    # Load status - the latest load volume. However, proc MainVolumesSetActive
    # set Volume(name) the first volume name. That's why we need clean it again:
    set Volume(name) ""
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateSequences
# Updates sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateSequences {} {
    global fMRIEngine Ibrowser MultiVolumeReader 

    # clears the menu 
    $fMRIEngine(gui,sequenceMenu) delete 0 end 

    # checks sequence loaded from fMRIEngine
    set b [info exists MultiVolumeReader(sequenceNames)] 
    set n [expr {$b == 0 ? 0 : [llength $MultiVolumeReader(sequenceNames)]}]

    if {$n > 0} {
        set i 0 
        while {$i < $n} {
            set name [lindex $MultiVolumeReader(sequenceNames) $i]
            fMRIEngineSelectSequence $name
            $fMRIEngine(gui,sequenceMenu) add command -label $name \
                -command "fMRIEngineSelectSequence $name"
            incr i
        }
    } else {
        $fMRIEngine(gui,sequenceMenu) add command -label "none" \
            -command "fMRIEngineSelectSequence none"
    }
}
