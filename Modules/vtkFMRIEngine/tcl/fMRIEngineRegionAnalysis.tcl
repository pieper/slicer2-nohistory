#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineRegionAnalysis.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:38 $
#   Version:   $Revision: 1.15 $
# 
#===============================================================================
# FILE:        fMRIEngineRegionAnalysis.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForROITab parent
#   fMRIEngineBuildUIForROITasks parent
#   fMRIEngineBuildUIForROIChoose
#   fMRIEngineSelectLabelMap
#   fMRIEngineLoadLabelMap
#   fMRIEngineBuildUIForROIShape
#   fMRIEngineBuildUIForROIAnatomy
#   fMRIEngineGotoEditor
#   fMRIEngineSelectBG
#   fMRIEngineBuildUIForROIActivation
#   fMRIEngineBuildUIForLabelmap
#   fMRIEngineBuildUIForROIActivation
#   fMRIEngineBuildUIForROIStats
#   fMRIEngineUpdateCondsForROIPlot
#   fMRIEngineSelectCondForROIPlot cond count
#   fMRIEngineResetLabelMap
#   fMRIEngineDoROIStats type
#   fMRIEngineCloseROIStatsWindow
#   fMRIEnginePlotROIStats type
#   fMRIEngineDoRegionTimecourse
#   fMRIEngineCreateLabelMap
#   fMRIEngineCreateLabelMapReal
#   fMRIEngineCastActivation
#   fMRIEngineSetROITask task
#   fMRIEngineUpdateBGVolumeList
#   fMRIEngineUpdateLabelMapList
#   fMRIEngineClickROI
#   fMRIEngineCloseDataWindow
#   fMRIEngineSaveRegionVoxels
#   fMRIEnginePrepareForRegionStats
#   fMRIEngineShowRegionStats
#   fMRIEngineCreateHistogram
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROITab
# Creates UI for ROI tab 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROITab {parent} {
    global fMRIEngine Gui Module

    set f $Module(fMRIEngine,fROI)

    #--- create blt notebook
    blt::tabset $f.tsNotebook -relief flat -borderwidth 0
    pack $f.tsNotebook -side top

    #--- notebook configure
    $f.tsNotebook configure -width 240
    # $f.tsNotebook configure -height 356 
    $f.tsNotebook configure -height 350 
    $f.tsNotebook configure -background $::Gui(activeWorkspace)
    $f.tsNotebook configure -activebackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -selectbackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -tabbackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -highlightbackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -highlightcolor $::Gui(activeWorkspace)
    $f.tsNotebook configure -foreground black
    $f.tsNotebook configure -activeforeground black
    $f.tsNotebook configure -selectforeground black
    $f.tsNotebook configure -tabforeground black
    $f.tsNotebook configure -relief flat
    $f.tsNotebook configure -tabrelief raised

    #--- tab configure
    set i 0
    foreach t "{RegionMap} Stats" {
        $f.tsNotebook insert $i $t
        frame $f.tsNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        fMRIEngineBuildUIForROI${t} $f.tsNotebook.f$t

        $f.tsNotebook tab configure $t -window $f.tsNotebook.f$t 
        $f.tsNotebook tab configure $t -activebackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -selectbackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -background $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -fill both -padx $::Gui(pad) -pady $::Gui(pad) 
        incr i
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROITasks
# Creates UI for tasks in ROI 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROITasks {parent} {
    global fMRIEngine Gui

    frame $parent.fTop  -bg $Gui(backdrop)
    frame $parent.fBot  -bg $Gui(activeWorkspace) -height 300 
    pack $parent.fTop $parent.fBot \
        -side top -fill x -pady 2 -padx 5 

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    eval {label $f.l -text "Label map:"} $Gui(BLA)
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
 
    # Build pulldown task menu 
    # eval {label $f.l -text "Label map:"} $Gui(BLA)
    # pack $f.l -side left -padx $Gui(pad) -fill x -anchor w

    # Paradigm design is default task 
    set taskList [list {Load} {New}]
    set df [lindex $taskList 0] 
    eval {menubutton $f.mbTask -text $df \
          -relief raised -bd 2 -width 33 \
          -indicatoron 1 \
          -menu $f.mbTask.m} $Gui(WMBA)
    eval {menu $f.mbTask.m} $Gui(WMA)
    pack  $f.mbTask -side left -pady 1 -padx $Gui(pad)

    # Save menubutton for config
    set fMRIEngine(gui,currentROITask) $f.mbTask

    # Add menu items
    set count 1
    set cList [list {Anatomy} {Activation}]
    foreach mi $taskList {
        if {$mi == "New"} {
            $f.mbTask.m add cascade -label $mi -menu $f.mbTask.m.sub
            set m2 [eval {menu $f.mbTask.m.sub -tearoff 0} $Gui(WMA)]
            foreach c $cList {
                $m2 add command -label $c \
                    -command "fMRIEngineSetROITask {$c}"
            }
        } else {
            $f.mbTask.m add command -label $mi \
                -command "fMRIEngineSetROITask {$mi}"
        }
    }

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBot

    set fList [list {Load} {Anatomy} {Activation}]
    set count 1
    foreach m $fList {
        # Makes a frame for each submodule
        frame $f.f$count -bg $Gui(activeWorkspace) 
        place $f.f$count -relwidth 1.0 -relx 0.0 -relheight 1.0 -rely 0.0 
        fMRIEngineBuildUIForROI$m $f.f$count

        set fMRIEngine(fROI$count) $f.f$count
        incr count
    }

    # raise the default one 
    raise $fMRIEngine(fROI1)
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROIChoose
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIChoose {parent} {
    global fMRIEngine Gui

    frame $parent.fTop -bg $Gui(activeWorkspace)
    pack $parent.fTop -side top -fill x -pady 5 -padx 5 

    set f $parent.fTop
    frame $f.fBox    -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    pack $f.fBox $f.fButtons -side top -fill x -pady 2 -padx 1 

    set f $parent.fTop.fBox
    DevAddLabel $f.l "Choose a loaded label map:"

    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(LMVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -selectmode simple \
        -yscrollcommand {$::fMRIEngine(LMVerScroll) set}
    set fMRIEngine(LMListBox) $f.lb
    $fMRIEngine(LMVerScroll) configure -command {$fMRIEngine(LMListBox) yview}

    blt::table $f \
        0,0 $f.l -cspan 2 -fill x -padx 1 -pady 5 \
        1,0 $fMRIEngine(LMListBox) -fill x -padx 1 -pady 1 \
        1,1 $fMRIEngine(LMVerScroll) -fill y -padx 1 -pady 1

    set f $parent.fTop.fButtons
    DevAddButton $f.bCompute "Select" "fMRIEngineSelectLabelMap" 10 
    grid $f.bCompute -padx 1 -pady 3 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectLabelMap
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectLabelMap {} {
    global fMRIEngine 

    set curs [$fMRIEngine(LMListBox) curselection] 
    if {$curs != ""} {
        set name [$fMRIEngine(LMListBox) get $curs] 
        set id [MIRIADSegmentGetVolumeByName $name] 
        MainSlicesSetVolumeAll Label $id
        RenderAll
    }
}

 
proc fMRIEngineBuildUIForROILoad {parent} {
    global fMRIEngine Gui
   
    frame $parent.fLabel   -bg $Gui(activeWorkspace)
    frame $parent.fFile    -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fApply   -bg $Gui(activeWorkspace)
    pack $parent.fLabel $parent.fFile $parent.fApply -side top -pady 1 

    set f $parent.fLabel
    DevAddLabel $f.lLabel "Load a label map:"
    pack $f.lLabel -side top -pady 5 

    set f $parent.fFile
    DevAddFileBrowse $f fMRIEngine "lmFileName" "File Name:" \
        "" "xml .mrml" "\$Volume(DefaultDir)" "Open" "Browse for an xml file" "" "Absolute"

    set f $parent.fApply
    DevAddButton $f.bApply "Apply" "fMRIEngineLoadLabelMap" 12 
    pack $f.bApply -side top -pady 3 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineLoadLabelMap
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineLoadLabelMap {} {
    global fMRIEngine File Mrml Volume

    set fileName $fMRIEngine(lmFileName)

    # Do nothing if the user cancelled
    if {$fileName == ""} {return}

    # Make it a relative prefix
    set File(filePrefix) [MainFileGetRelativePrefix $fileName]

    # If it's MRML instead of XML, then add the .mrml back
    if {[regexp {.*\.mrml$} $fileName] == 1} {
        set File(filePrefix) $File(filePrefix).mrml
    }

    # Prefix cannot be blank
    if {$File(filePrefix) == ""} {
        DevWarningWindow "No file to open specified."
        return
    }
    
    # Relative to root.
    # If it's MRML instead of XML, then don't add the .xml
    if {[regexp {.*\.mrml$} $File(filePrefix)] == 0} {
        set filename [file join $Mrml(dir) $File(filePrefix).xml]
    } else {
        set filename [file join $Mrml(dir) $File(filePrefix)]
    }

    # Bring nodes from a mrml file into the current tree
    MainMrmlImport $filename

    set size [llength $Volume(idList)]
    # In Volume(idList), the last one is the id for None volume
    # and the second last one is the id for the volume just added.
    set i [expr $size - 2]
    set id [lindex $Volume(idList) $i]
    # This is a labelmap
    MainSlicesSetVolumeAll Label $id

    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROIShape
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIShape {parent} {
    global fMRIEngine Gui

    frame $parent.fTitle  -bg $Gui(activeWorkspace)
    frame $parent.fTop -bg $Gui(activeWorkspace) -relief groove -bd 1 
    pack $parent.fTitle $parent.fTop -side top -fill x -pady 5 -padx 5 

    set f $parent.fTitle
    DevAddLabel $f.l "Create a label map from shape:"
    pack $f.l -side top -fill x -pady 2 -padx 5 

    set f $parent.fTop
    frame $f.fBox    -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    pack $f.fBox $f.fButtons -side top -fill x -pady 2 -padx 1 

    set f $parent.fTop.fBox
    DevAddLabel $f.l "Choose a background volume:"

    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(ShapeBGVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -selectmode simple \
        -yscrollcommand {$::fMRIEngine(ShapeBGVerScroll) set}
    set fMRIEngine(ShapeBGListBox) $f.lb
    $fMRIEngine(ShapeBGVerScroll) configure -command {$fMRIEngine(ShapeBGListBox) yview}

    blt::table $f \
        0,0 $f.l -cspan 2 -fill x -padx 1 -pady 5 \
        1,0 $fMRIEngine(ShapeBGListBox) -fill x -padx 1 -pady 1 \
        1,1 $fMRIEngine(ShapeBGVerScroll) -fill y -padx 1 -pady 1

    set f $parent.fTop.fButtons
    DevAddButton $f.bCompute "Go to Editor Module" "fMRIEngineSelectBG {ShapeBGListBox}" 20 
    grid $f.bCompute -padx 1 -pady 3
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROIAnatomy
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIAnatomy {parent} {
    global fMRIEngine Gui

    frame $parent.fTop -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fMiddle -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $parent.fBottom -bg $Gui(activeWorkspace) -relief groove -bd 1
    pack $parent.fTop $parent.fMiddle $parent.fBottom -side top -fill x -pady 5 -padx 5 

    # tope frame
    set f $parent.fTop
    frame $f.fBox    -bg $Gui(activeWorkspace)
    frame $f.fButton -bg $Gui(activeWorkspace)
    pack $f.fBox $f.fButton -side top -fill x -pady 2 -padx 1 

    set f $parent.fTop.fBox
    DevAddLabel $f.l "Choose a background volume:"

    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(AnatomyBGVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -selectmode simple \
        -yscrollcommand {$::fMRIEngine(AnatomyBGVerScroll) set}
    set fMRIEngine(AnatomyBGListBox) $f.lb
    $fMRIEngine(AnatomyBGVerScroll) configure -command {$fMRIEngine(AnatomyBGListBox) yview}

    blt::table $f \
        0,0 $f.l -cspan 2 -fill x -padx 1 -pady 5 \
        1,0 $fMRIEngine(AnatomyBGListBox) -fill x -padx 1 -pady 1 \
        1,1 $fMRIEngine(AnatomyBGVerScroll) -fill y -padx 1 -pady 1

    set f $parent.fTop.fButton
    DevAddButton $f.bSelect "Select" "fMRIEngineSelectBG {AnatomyBGListBox}" 20 
    grid $f.bSelect -padx 1 -pady 3

    # middle frame
    set f $parent.fMiddle
    DevAddLabel $f.lName "Label map name:"
    eval {entry $f.eName -width 15  \
        -textvariable fMRIEngine(entry,labelMapName) } $Gui(WEA)
    pack $f.lName $f.eName -side top -fill x -pady 3 -padx 3 

    # bottom frame
    set f $parent.fBottom
    DevAddLabel $f.lNote "Label map will be created \nin the Editor module \nusing its drawing tools:"
    DevAddButton $f.bGo "Go to Editor Module" "fMRIEngineGotoEditor" 20 
    pack $f.lNote $f.bGo -side top -padx 3 -pady 3
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineGotoEditor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineGotoEditor {} {
    global fMRIEngine Editor 

    set name $fMRIEngine(entry,labelMapName)
    set name [string trim $name]

    # if the user has a name for the label map, use it;
    # otherwise, use the default name, i.e. Working
    if {$name != ""} {
        set Editor(nameWorking) $fMRIEngine(entry,labelMapName)
    }

    Tab Editor row1 Volumes 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectBG
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectBG {lb} {
    global fMRIEngine 

    set curs [$fMRIEngine($lb) curselection] 
    if {$curs != ""} {
        set name [$fMRIEngine($lb) get $curs] 
        set id [MIRIADSegmentGetVolumeByName $name] 
        MainSlicesSetVolumeAll Back $id
        RenderAll
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROIActivation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIActivation {parent} {
    global fMRIEngine Gui Module
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForLabelmap
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIRegionMap {parent} {
    global fMRIEngine Gui Label 

    frame $parent.fTasks   -bg $Gui(activeWorkspace) 
    pack $parent.fTasks -side top -fill x -pady 3 -padx 5 

    fMRIEngineBuildUIForROITasks $parent.fTasks
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROIActivation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIActivation {parent} {
    global fMRIEngine Gui Label 

    frame $parent.fTop -bg $Gui(activeWorkspace)
    pack $parent.fTop -side top -fill x -pady 5 -padx 5 

    #---------------------------------
    # Make label map 
    #---------------------------------
    set f $parent.fTop
    DevAddButton $f.bApply "Create label map from activation" "fMRIEngineCreateLabelMap" 33 
    pack $f.bApply -side top -pady 1 -padx 5
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForROIStats
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForROIStats {parent} {
    global fMRIEngine Gui Label 

    frame $parent.fStats -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fPlot -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fReset -bg $Gui(activeWorkspace)
    pack $parent.fStats $parent.fPlot -side top -fill x -pady 5 -padx 5 
    pack $parent.fReset -side top -fill x -pady 5 -padx 20 

    set f $parent.fStats
    DevAddLabel $f.lTitle "Region statistics:"
    DevAddLabel $f.lNote "Select label(s) by clicking region(s)."
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSelectLabels" 2 
    DevAddButton $f.bShow "Show stats" "fMRIEngineShowRegionStats" 20 
    DevAddButton $f.bSave "Save region voxels" "fMRIEngineSaveRegionVoxels" 20 
    blt::table $parent.fStats \
        0,0 $f.lTitle -padx 1 -pady 5 -fill x -cspan 2 \
        1,0 $f.bHelp -padx 1 -pady 5 -anchor e \
        1,1 $f.lNote -padx 1 -pady 5 -anchor w \
        2,0 $f.bShow -padx 1 -pady 5 -cspan 2 \
        3,0 $f.bSave -padx 1 -pady 5 -cspan 2

    set f $parent.fPlot
    DevAddLabel $f.lTitle "Region plot:"
    pack $f.lTitle -side top -fill x -pady 5 -padx 3 

    frame $f.fConds        -bg $Gui(activeWorkspace)
    frame $f.fTimecourse   -bg $Gui(activeWorkspace)
    frame $f.fPeristimulus -bg $Gui(activeWorkspace)
    frame $f.fPlot         -bg $Gui(activeWorkspace)
    pack $f.fConds $f.fTimecourse $f.fPeristimulus $f.fPlot -side top -padx 2 -pady 1 

    set f $parent.fPlot.fConds
    DevAddLabel $f.lLabel "Condition:"

    set condList [list {none}]
    set df [lindex $condList 0] 
    eval {menubutton $f.mbType -text $df \
         -relief raised -bd 2 -width 15 \
         -indicatoron 1 \
         -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    foreach m $condList  {
        $f.mbType.m add command -label $m \
            -command ""
    }
    grid $f.lLabel $f.mbType -padx 1 -pady 3 
    # Save menubutton for config
    set fMRIEngine(gui,condsMenuButtonROI) $f.mbType
    set fMRIEngine(gui,condsMenuROI) $f.mbType.m

    set f $parent.fPlot.fTimecourse
    set param Long 
    set name {Timecourse}
    eval {radiobutton $f.r$param -width 25 -text $name \
        -variable fMRIEngine(tcPlottingOption) -value $param \
        -relief raised -offrelief raised -overrelief raised \
        -selectcolor white} $Gui(WEA)
    set fMRIEngine(tcPlottingOption) "Long"
    pack $f.r$param -side top -pady 2 
    set fMRIEngine(gui,roiTimecourseRadioButton) $f.r$param 

    set f $parent.fPlot.fPeristimulus
    set param Short 
    set name {Peristimulus histogram}
    eval {radiobutton $f.r$param -width 25 -text $name \
        -variable fMRIEngine(tcPlottingOption) -value $param \
        -relief raised -offrelief raised -overrelief raised \
        -selectcolor white} $Gui(WEA)
    pack $f.r$param -side top -pady 2 
    set fMRIEngine(gui,roiPeristimulusRadioButton) $f.r$param 

    set f $parent.fPlot.fPlot
    DevAddButton $f.bPlot "Plot time series" "fMRIEngineDoRegionTimecourse" 20 
    pack $f.bPlot -side top -pady 5 -padx 1 

    set f $parent.fReset
    DevAddButton $f.bReset "Clear selections" "fMRIEngineResetLabelMap" 20 
    pack $f.bReset -side top -fill x -pady 1 -padx 2 

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateCondsForROIPlot
# Updates condition list for ROI timecourse plotting 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateCondsForROIPlot {} {
    global fMRIEngine

    # Peristimulus histogram plotting will be disabled if the paradigm desgin is 
    # event-related or mixed.
    if {$fMRIEngine(paradigmDesignType) != "blocked"} {
        $fMRIEngine(gui,roiTimecourseRadioButton) select 
        $fMRIEngine(gui,roiPeristimulusRadioButton) config -state disabled
    } else {
        $fMRIEngine(gui,roiPeristimulusRadioButton) config -state normal 
    }

    set run $fMRIEngine(curRunForModelFitting)
    if {$run == "none"} {
        return
    }

    if {$run == "concatenated"} {
        set run 1
    }

    if {! [info exists fMRIEngine($run,namesOfConditionEVs)]} {
        return
    }

    if {[llength $fMRIEngine($run,namesOfConditionEVs)] > 0} {
        #--- wjp changed 09/21/05: filter out temporal derivative EV names
        $fMRIEngine(gui,condsMenuROI) delete 0 end
        set count 1 
        foreach name $fMRIEngine($run,namesOfConditionEVs) { 
            $fMRIEngine(gui,condsMenuROI) add command -label $name \
                -command "fMRIEngineSelectCondForROIPlot $name $count"

            fMRIEngineSelectCondForROIPlot $name $count 
            incr count
        }
    }
} 


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectCondForROIPlot
# 
# .ARGS
# string cond 
# int count
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectCondForROIPlot {cond count} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,condsMenuButtonROI) config -text $cond
    set fMRIEngine(curEVIndexForPlotting) $count 
    set fMRIEngine(curEVForPlotting) $cond 

    if {[info exists fMRIEngine(timeCourseToplevel)] &&
        $fMRIEngine(tcPlottingOption) == "Long"} {
            # re-plot due to condition switch
            fMRIEngineDrawPlotLong
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineResetLabelMap
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineResetLabelMap {} {
    global fMRIEngine Slicer Volume Interactor

    if {[info exists fMRIEngine(roiStatsLabelMapOriginal)]} {
        set s $Interactor(s)
        set foreNode [[Slicer GetForeVolume $s] GetMrmlNode]
        set v [$foreNode GetID]
        Volume($v,vol) SetImageData $fMRIEngine(roiStatsLabelMapOriginal)

        MainVolumesUpdate $v
        MainUpdateMRML
        RenderAll
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCloseROIStatsWindow
# Cleans up if the data window is closed 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCloseROIStatsWindow {} {
    global fMRIEngine

    if {[info exists fMRIEngine(roiStatsTable)]} {
        destroy $fMRIEngine(roiStatsTable)
        unset -nocomplain fMRIEngine(roiStatsTable)
    }

    if {[info exists fMRIEngine(roiStatsToplevel)]} {
        destroy $fMRIEngine(roiStatsToplevel)
        unset -nocomplain fMRIEngine(roiStatsToplevel)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEnginePlotROIStats
# 
# .ARGS
# string type type can be "intensity," or "t." 
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePlotROIStats {type} {
    global fMRIEngine

    fMRIEngineCloseROIStatsWindow

    set w .roiStatsWin
    toplevel $w
    wm title $w "Region Stats" 
    wm minsize $w 250 160 
    # wm geometry $w "+898+200" 
    # wm geometry $w "+850+200" 
    wm geometry $w "+320+440" 

    # data table headers
    label $w.count -text "Count" -font fixed
    label $w.max -text "Max" -font fixed
    label $w.min -text "Min" -font fixed
    label $w.mean -text "Mean" -font fixed
    blt::table $w \
        $w.count 0,0 $w.max 0,1 $w.min 0,2 $w.mean 0,3

    label $w.countVal -text $fMRIEngine($type,count) -font fixed
    label $w.maxVal -text $fMRIEngine($type,max) -font fixed
    label $w.minVal -text $fMRIEngine($type,min) -font fixed
    label $w.meanVal -text $fMRIEngine($type,mean) -font fixed

    # todo: expression didn't have numeric value
    set count 1
    blt::table $w \
        $w.countVal $count,0 $w.maxVal $count,1 \
        $w.minVal $count,2 $w.meanVal $count,3

    button $w.bClose -text "Close" -font fixed -command "fMRIEngineCloseROIStatsWindow"
    incr count
    blt::table $w $w.bClose $count,2 

    wm protocol $w WM_DELETE_WINDOW "fMRIEngineCloseROIStatsWindow" 
    set fMRIEngine(roiStatsToplevel) $w
    set fMRIEngine(roiStatsTable) $w.table
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineDoRegionTimecourse
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineDoRegionTimecourse {{plot 1}} {
    global fMRIEngine Slice Volume

    set r [fMRIEnginePrepareForRegionStats]
    # if error, return
    if {$r == 1} {
        return 
    }

    set voxels [fMRIEngine(actROIStats) GetRegionVoxels]
    fMRIEngine(actEstimator) SetRegionVoxels $voxels
    set fMRIEngine(timecourse) [fMRIEngine(actEstimator) GetRegionTimeCourse] 
    set fMRIEngine(timecoursePlot) "Region"

    if {$plot} {
        fMRIEnginePlotTimecourse 
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCreateLabelMap
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCreateLabelMap {} {

    set r [fMRIEngineCastActivation]
    # Got error!
    if {$r == 1} {
        return
    }

    fMRIEngineCreateLabelMapReal 
}

 
#-------------------------------------------------------------------------------
# .PROC fMRIEngineCreateLabelMapReal
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCreateLabelMapReal {} {
    global fMRIEngine Editor Ed Volume Slice Label Gui

    set n $Volume(idNone)
    foreach s $Slice(idList) {
        set id $Slice($s,foreVolID)
        if {$n != $id} {
            continue
        }
    }

    if {$n == $id} {
        DevErrorWindow "Put your activation volume into the foreground."
        return 1 
    }

    set Gui(progressText) "Creating label map..."
    puts $Gui(progressText)

    #---------------------------------
    # Create label map 
    #---------------------------------

    EditorEnter

    # Editor->Volumes->Setup
    #-----------------------
    EditorSetOriginal $id 
    EditorSetWorking "NEW" 

    set actName [Volume($fMRIEngine(activeActivationID),node) GetName]
    set t $fMRIEngine(tStat)
    # Say t = 3.3. Dot is not allowed in the volume name in slicer
    # the regsub replaces . by dot.
    regsub -all {\.} $t dot t 
    set Editor(nameWorking) "$actName-t$t-labelMap" 

    # Editor->Details->to 
    # (press) ->Th
    #-----------------------
    set e "EdThreshold"
    # Remember prev
    set prevID $Editor(activeID)
    # Set new
    set Editor(activeID) $e 
    set Editor(btn) $e 

    # Reset Display
    EditorResetDisplay
    RenderAll
    EditorExitEffect $prevID
    # execute enter procedure
    EditorUpdateEffect

    # Editor->Details->Th
    #-----------------------
    set Label(label) 2 
    set Ed($e,lower) 1 
    set Ed($e,upper) $Ed(EdThreshold,rangeHigh) 
    set Ed($e,interact) "3D"
    EdThresholdApply

    #---------------------------------
    # Identify islands in label map:
    # each label has a unique value (id)
    #---------------------------------

    # Editor->Details->to 
    # (press) ->II
    #-----------------------
    set e "EdIdentifyIslands"
    # Remember prev
    set prevID $Editor(activeID)
    set Editor(activeID) $e 
    set Editor(btn) $e 

    EditorResetDisplay
    RenderAll
    EditorExitEffect $prevID
    EditorUpdateEffect

    # Editor->Details->II
    #-----------------------
    set Ed($e,inputLabel) 0
    set Ed($e,scope) "3D"
    EdIdentifyIslandsApply

    #---------------------------------
    # Change all labels to high values 
    # so that they all display white in
    # slicer
    #---------------------------------
 
    # always uses a new instance of vtkLabelMapWhitening
    if {[info commands fMRIEngine(labelMapWhitening)] != ""} {
        fMRIEngine(labelMapWhitening) Delete
        unset -nocomplain fMRIEngine(labelMapWhitening)
    }
    vtkLabelMapWhitening fMRIEngine(labelMapWhitening)

    set id [MIRIADSegmentGetVolumeByName $Editor(nameWorking)] 
    set lmVol [Volume($id,vol) GetOutput] 
    fMRIEngine(labelMapWhitening) SetInput $lmVol 
    fMRIEngine(labelMapWhitening) Update 
    $lmVol DeepCopy [fMRIEngine(labelMapWhitening) GetOutput]

    MainUpdateMRML
    RenderAll
    EditorExit

    set id $fMRIEngine(activeActivationID)
    Volume($id,node) InterpolateOff
    MainSlicesSetVolumeAll Back $id 
    MainUpdateMRML
    RenderAll
    puts "...done"

    return 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCastActivation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCastActivation {} {
    global fMRIEngine Volume Slice

    set n $Volume(idNone)
    foreach s $Slice(idList) {
        set id $Slice($s,foreVolID)
        if {$n != $id} {
            continue 
        }
    }

    if {$n == $id} {
        DevErrorWindow "Put your activation volume into the foreground."
        return 1 
    }

    set fMRIEngine(activeActivationID) $id

    # always uses a new instance of vtkActivationVolumeCaster 
    if {[info commands fMRIEngine(actVolumeCaster)] != ""} {
        fMRIEngine(actVolumeCaster) Delete
        unset -nocomplain fMRIEngine(actVolumeCaster)
    }
    vtkActivationVolumeCaster fMRIEngine(actVolumeCaster)

    set low [[Volume($id,vol) GetIndirectLUT] GetLowerThreshold]
    set high [[Volume($id,vol) GetIndirectLUT] GetUpperThreshold]
    fMRIEngine(actVolumeCaster) SetLowerThreshold $low
    fMRIEngine(actVolumeCaster) SetUpperThreshold $high

    fMRIEngine(actVolumeCaster) SetInput [Volume($id,vol) GetOutput] 

    set act [fMRIEngine(actVolumeCaster) GetOutput]
    $act Update

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i

    # set the name and description of the volume
    if {! [info exists fMRIEngine(actCastVolNameExt)]} {
        set fMRIEngine(actCastVolNameExt) 1 
    } else { 
        incr fMRIEngine(actCastVolNameExt)
    }
    set name "actCastVol-$fMRIEngine(actCastVolNameExt)"
    $n SetName "$name" 
    $n SetDescription "$name"

    eval Volume($i,node) SetSpacing [$act GetSpacing]
    Volume($i,node) SetScanOrder [Volume($fMRIEngine(firstMRMLid),node) GetScanOrder]
    Volume($i,node) SetNumScalars [$act GetNumberOfScalarComponents]
    set ext [$act GetWholeExtent]
    Volume($i,node) SetImageRange [expr 1 + [lindex $ext 4]] [expr 1 + [lindex $ext 5]]
    Volume($i,node) SetScalarType [$act GetScalarType]
    Volume($i,node) SetDimensions [lindex [$act GetDimensions] 0] [lindex [$act GetDimensions] 1]
    Volume($i,node) ComputeRasToIjkFromScanOrder [Volume($i,node) GetScanOrder]

    Volume($i,vol) SetImageData $act

    Volume($i,vol) SetRangeLow [fMRIEngine(actVolumeCaster) GetLowRange] 
    Volume($i,vol) SetRangeHigh [fMRIEngine(actVolumeCaster) GetHighRange] 

    # set the lower threshold to the actLow 
    Volume($i,node) AutoThresholdOff
    Volume($i,node) ApplyThresholdOn
    Volume($i,node) SetLowerThreshold [fMRIEngine(actVolumeCaster) GetLowRange]
    Volume($i,node) InterpolateOff

    MainUpdateMRML
    MainSlicesSetVolumeAll Fore $i
    MainVolumesSetActive $i
    RenderAll

    return 0
} 


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSetROITask
# Switches roi task 
# .ARGS
# string task the roi task 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSetROITask {task} {
    global fMRIEngine
    
    set fMRIEngine(currentROITask) $task

    set l $task
    if {$task != "Load"} {
        set l "New"
    }

    # configure menubutton
    $fMRIEngine(gui,currentROITask) config -text $l

    set count -1 
    switch $task {
        "Load" {
            set count 1
        }
        "Anatomy" {
            set count 2 
        }
        "Activation" {
            set count 3 
        }
    }

    set f  $fMRIEngine(fROI$count)
    raise $f
    focus $f
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateBGVolumeList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateBGVolumeList {} {
    global fMRIEngine Volume
 
    set fMRIEngine(currentTab) "ROI"

    $fMRIEngine(AnatomyBGListBox) delete 0 end
    # $fMRIEngine(ShapeBGListBox) delete 0 end
 
    foreach v $Volume(idList) {
        if {$v > 0} {
            set b [Volume($v,node) GetLabelMap]
            if {! $b} {
                set volName [Volume($v,node) GetName] 
                if {$volName != ""} {
                    $fMRIEngine(AnatomyBGListBox) insert end $volName
                    # $fMRIEngine(ShapeBGListBox) insert end $volName
                }
            }
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateLabelMapList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateLabelMapList {} {
    global fMRIEngine Volume
 
    set fMRIEngine(currentTab) "ROI"

    $fMRIEngine(LMListBox) delete 0 end
    foreach v $Volume(idList) {
        if {$v > 0} {
            set b [Volume($v,node) GetLabelMap]
            if {$b} {
                set volName [Volume($v,node) GetName] 
                if {$volName != ""} {
                    $fMRIEngine(LMListBox) insert end $volName
                }
            }
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineClickROI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineClickROI {x y} {
    global fMRIEngine Interactor Ed Editor Volume

    set s $Interactor(s)

    set backNode [[Slicer GetBackVolume $s] GetMrmlNode]
    set backName [$backNode GetName]
    if {$backName == "None"} {
        DevErrorWindow "Put your activation volume in the background (Bg)."
        return
    }

    set foreNode [[Slicer GetForeVolume $s] GetMrmlNode]
    set foreName [$foreNode GetName]
    set labelMap [$foreNode GetLabelMap]
    if {$foreName == "None" || $labelMap != "1"} {
        DevErrorWindow "Put your labelmap volume in the foreground (Fg)."
        return
    }

    set labelNode [[Slicer GetLabelVolume $s] GetMrmlNode]
    set labelName [$labelNode GetName]
    if {$labelName == "None"} {
        DevErrorWindow "Make your labelmap visible (in Lb)."
        return
    }

    # Save a copy of the labelmap volume
    if {! [info exists fMRIEngine(roiStatsLabelMapOriginal)]} {
        vtkImageData data

        set v [$foreNode GetID]
        data DeepCopy [Volume($v,vol) GetOutput]
        set fMRIEngine(roiStatsLabelMapOriginal) data
    }
     
    # The value of forePix is the labelmap of the region selected.
    set xs $x
    set ys $y
    scan [MainInteractorXY $s $xs $ys] "%d %d %d %d" xs ys x y
    set forePix [$Interactor(activeSlicer) GetForePixel $s $x $y]

    # The colors of all labels are white although they have 
    # different values. If a label is clicked, we are trying
    # to change its color (i.e. change its value). 

    # The background has a value > 0
    if {$forePix > 0} {
        EditorEnter

        set e EdChangeLabel
        set v [$foreNode GetID]
        EditorSetOriginal [$backNode GetID] 
 
        set prevID $Editor(activeID)
        set Editor(activeID) $e 
        set Editor(btn) $e 
        EditorResetDisplay
        RenderAll
        EditorExitEffect $prevID
        EditorUpdateEffect

        set Ed($e,inputLabel) $forePix
        # 16 = color of domino
        set Label(label) 16 
        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native

        set fg       $Ed($e,inputLabel)
        set fgNew    $Label(label)
        Ed(editor)   ChangeLabel $fg $fgNew
        Ed(editor)   SetInput ""
        Ed(editor)   UseInputOff

        EdUpdateAfterApplyEffect $v

        EditorExit
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCloseDataWindow
# Cleans up if the data window is closed 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCloseRegionStatsWindow {} {
    global fMRIEngine

    destroy $fMRIEngine(regionStatsToplevel)
    unset -nocomplain fMRIEngine(regionStatsToplevel)
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSaveRegionVoxels
# Saves voxel information in the defined roi
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSaveRegionVoxels {} {
    global fMRIEngine Volume Slice

    set r [fMRIEnginePrepareForRegionStats]
    # if error, return
    if {$r == 1} {
        return 
    }

    # write data to file
    set fileType {{"Text" *.txt}}
    set fileName [tk_getSaveFile -filetypes $fileType -parent .]
    if {[string length $fileName]} {
        set txt ".txt"
        set ext [file extension $fileName]
        if {$ext != $txt} {
            set fileName "$fileName$txt"
        }
        set fHandle [open $fileName w]
        set note "This text file saves the coordinates and t values \n of all voxels in the defined region of interest.\n"
        puts $fHandle $note
        if {$fMRIEngine(thresholdingOption) == "uncorrected"} {
            puts $fHandle "p threshold: $fMRIEngine(pValue)(uncorrected)"
        } else {
            puts $fHandle "p threshold: $fMRIEngine(pValue)(corrected)"
        }
        puts $fHandle "t threshold: $fMRIEngine(tStat)\n"
        puts $fHandle "x\ty\tz\tt\n" 

        set voxels [fMRIEngine(actROIStats) GetRegionVoxels]
        set size [$voxels GetNumberOfTuples]
        for {set idx 0} {$idx < $size} {incr idx} {
            set x [$voxels GetComponent $idx 0]
            set y [$voxels GetComponent $idx 1] 
            set z [$voxels GetComponent $idx 2] 
            set t [$voxels GetComponent $idx 3] 

            set str [format "%d\t%d\t%d\t%.1f" $x $y $z $t]
            puts $fHandle $str
        }
        close $fHandle
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEnginePrepareForRegionStats
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePrepareForRegionStats {} {
    global fMRIEngine fMRIModelView Volume Slice

    set n $Volume(idNone)
    set tId $n 
    set lId $n 
    foreach s $Slice(idList) {
        if {$tId == $n} {
            set tId $Slice($s,backVolID)
        }
        if {$lId == $n} {
            set lId $Slice($s,labelVolID)
        }
    }

    if {$n == $tId} {
        DevErrorWindow "Put your activation volume into the background."
        return 1 
    }
    if {$n == $lId} {
        DevErrorWindow "Your label map is not visible."
        return 1 
    }

    # Always uses a new instance of vtkActivationRegionStats 
    # vtkActivationRegionStats computes stats for a defined 
    # ROI. The required input for this class includes:
    # 1. The label map volume which defines an ROI.
    # 2. The activation volume.
    # 3. The beta volume which holds % signal change for each
    #    regressors (evs) and each voxel. For now, the beta
    #    volume is the output of the GLM estimation. In the
    #    future, if we add new detection methods into fMRIEngine, 
    #    we need to do some changes here.
    if {[info commands fMRIEngine(actROIStats)] != ""} {
        fMRIEngine(actROIStats) Delete
        unset -nocomplain fMRIEngine(actROIStats)
    }
    vtkActivationRegionStats fMRIEngine(actROIStats)

    fMRIEngine(actROIStats) AddInput [Volume($lId,vol) GetOutput]
    fMRIEngine(actROIStats) AddInput [Volume($tId,vol) GetOutput]
    fMRIEngine(actROIStats) AddInput $fMRIEngine(actBetaVolume) 
    fMRIEngine(actROIStats) SetLabel 16 
    fMRIEngine(actROIStats) Update 

    set count [fMRIEngine(actROIStats) GetCount] 

    if {$count == 0} {
        DevErrorWindow "No label has been selected."
        return 1
    }

    set fMRIEngine(roiStatsOutput) [fMRIEngine(actROIStats) GetOutput] 
 
    # average % signal changes from defined ROI; one for each ev
    set percent [fMRIEngine(actROIStats) GetPercentSignalChanges] 

    set vector $fMRIEngine($tId,contrastVector)
    set names $fMRIModelView(Design,evNames)
    set index 0
    foreach v $vector n $names {
        if {$v != 0} {
            set p [$percent GetComponent $index 0]
            set fMRIEngine($n,signalChange) $p
        }
        incr index
    }

    return 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowRegionStats
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowRegionStats {} {
    global fMRIEngine fMRIModelView Volume Slice

    set r [fMRIEnginePrepareForRegionStats]
    # if error, return
    if {$r == 1} {
        return 1
    }


    if {[info exists fMRIEngine(regionStatsToplevel)]} {
        fMRIEngineCloseRegionStatsWindow
    }

    # Create the GUI, i.e. two Tk image viewer, one for the image
    # the other for the histogram, and a slice slider
    set w .regionStats 
    toplevel $w -bg white 
    set fMRIEngine(regionStatsToplevel) $w
 
    wm title $w "Region Stats" 
#    wm minsize $w $plotWidth $plotHeight
#    set plotGeometry "+335+200"
    set plotGeometry "+400+30"
    wm geometry $w $plotGeometry 

    # Set the window manager (wm command) so that it registers a
    # command to handle the WM_DELETE_WINDOW protocal request. This
    # request is triggered when the widget is closed using the standard
    # window manager icons or buttons. In this case the exit callback
    # will be called and it will free up any objects we created then exit
    # the application.
    wm protocol $w WM_DELETE_WINDOW "fMRIEngineCloseRegionStatsWindow" 
    
    # Pack all gui elements
    frame $w.f1 -bg white
    frame $w.f2 -bg white 
    pack $w.f1 $w.f2 -side left -padx 5 -pady 5 -fill both -expand t

    # Create the histogram widget
    fMRIEngineCreateHistogram $w.f1 600 400 

    # show region stats
    if {$fMRIEngine(thresholdingOption) == "uncorrected"} {
        set pLabel "p threshold\n(uncorrected)"
    } else {
        set pLabel "p threshold\n(corrected)"
    }
    label $w.f2.lPValue -text $pLabel -bg white 
    eval {label $w.f2.lPVal -textvariable fMRIEngine(pValue) -bg white} 
    label $w.f2.lTValue -text "t threshold:" -bg white
    eval {label $w.f2.lTVal -textvariable fMRIEngine(tStat) -bg white} 
    label $w.f2.lCount -text "Voxel count:" -bg white
    eval {label $w.f2.lCountVal -textvariable fMRIEngine(regionVoxelCount) -bg white} 
    label $w.f2.lMin -text "Min: " -bg white
    eval {label $w.f2.lMinVal -textvariable fMRIEngine(regionMin) -bg white} 
    label $w.f2.lMax -text "Max:" -bg white
    eval {label $w.f2.lMaxVal -textvariable fMRIEngine(regionMax) -bg white} 
    label $w.f2.lMean -text "Mean:" -bg white
    eval {label $w.f2.lMeanVal -textvariable fMRIEngine(regionMean) -bg white} 
    label $w.f2.lSD -text "Standard deviation:" -bg white
    eval {label $w.f2.lSDVal -textvariable fMRIEngine(regionStandardDeviation) -bg white} 
    label $w.f2.lSC -text "Signal change:" -bg white

    blt::table $w.f2 \
        0,0 $w.f2.lPValue -padx 1 -pady 1 -anchor e \
        0,1 $w.f2.lPVal -fill x -padx 5 -pady 1 -anchor w \
        1,0 $w.f2.lTValue -padx 1 -pady 1 -anchor e \
        1,1 $w.f2.lTVal -fill x -padx 5 -pady 1 -anchor w \
        2,0 $w.f2.lCount -padx 1 -pady 1 -anchor e \
        2,1 $w.f2.lCountVal -fill x -padx 5 -pady 1 -anchor w \
        3,0 $w.f2.lMin -padx 1 -pady 1 -anchor e \
        3,1 $w.f2.lMinVal -fill x -padx 5 -pady 1 -anchor w \
        4,0 $w.f2.lMax -padx 1 -pady 1 -anchor e \
        4,1 $w.f2.lMaxVal -fill x -padx 5 -pady 1 -anchor w \
        5,0 $w.f2.lMean -padx 1 -pady 1 -anchor e \
        5,1 $w.f2.lMeanVal -fill x -padx 5 -pady 1 -anchor w \
        6,0 $w.f2.lSD -padx 1 -pady 1 -anchor e \
        6,1 $w.f2.lSDVal -fill x -padx 5 -pady 1 -anchor w \
        7,0 $w.f2.lSC -padx 1 -pady 1 -anchor e

    set c 8 
    foreach ev $fMRIModelView(Design,evNames) {
        if {[info exists fMRIEngine($ev,signalChange)] && $fMRIEngine($ev,signalChange) != ""} {
            set ev2 $ev
            regsub -all {\.} $ev _ ev 
            set sc [format "%.2f" $fMRIEngine($ev2,signalChange)]
            label $w.f2.l$ev -text "$ev2" -bg white
            set sc "$sc %" 
            eval {label $w.f2.lv$ev -text $sc -bg white} 

            blt::table $w.f2 \
                $c,0 $w.f2.l$ev -padx 1 -pady 1 -anchor e \
                $c,1 $w.f2.lv$ev -fill x -padx 5 -pady 1 -anchor w \

            incr c
        }
    }

    button $w.f2.btn -text "Close" -command "fMRIEngineCloseRegionStatsWindow" -width 15 -bg white
    blt::table $w.f2 \
        $c,0 $w.f2.btn -padx 5 -pady 30 -cspan 2

    return 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCreateHistogram
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCreateHistogram {parent {width 350} {height 250}} {
    global fMRIEngine

    set input $fMRIEngine(roiStatsOutput) 
    set dim [$input GetDimensions]

    set extent [$input GetWholeExtent] 
    scan $extent "%d %d %d %d %d %d" x1 x2 y1 y2 z1 z2

    set range [$input GetScalarRange]
    set minX [lindex $range 0]
    set maxX [lindex $range 1]

    # set numBins [expr $width / 2]
    set numBins 100 

    set origin $minX 
    set spacing [expr 1.0 * ($maxX - $origin) / $numBins]

    if {[info command fMRIEngine(imageAccumulate)] != ""} {
        fMRIEngine(imageAccumulate) Delete
        unset -nocomplain fMRIEngine(imageAccumulate)
    }
    vtkImageAccumulate fMRIEngine(imageAccumulate)
    fMRIEngine(imageAccumulate) SetInput $input
    fMRIEngine(imageAccumulate) SetComponentExtent 0 [expr $numBins - 1] 0 0 0 0
    fMRIEngine(imageAccumulate) SetComponentOrigin $origin 0.0 0.0
    fMRIEngine(imageAccumulate) SetComponentSpacing $spacing 1.0 1.0
    fMRIEngine(imageAccumulate) Update 

    # region stats
    set fMRIEngine(regionVoxelCount) [fMRIEngine(imageAccumulate) GetVoxelCount]

    set fMRIEngine(regionMin) [format "%.2f" $minX] 
    set fMRIEngine(regionMax) [format "%.2f" $maxX]
    set mean [format "%.2f" [lindex [fMRIEngine(imageAccumulate) GetMean] 0]]
    set fMRIEngine(regionMean) $mean 
    set sd 0.0
    if {$fMRIEngine(regionVoxelCount) > 1} {
        set sd [format "%.2f" [lindex [fMRIEngine(imageAccumulate) GetStandardDeviation] 0]]
    }
    set fMRIEngine(regionStandardDeviation) $sd   

    set data [fMRIEngine(imageAccumulate) GetOutput]
    set histRange [[[$data GetPointData] GetScalars] GetRange]
    set minY [lindex $histRange 0]
    set maxY [lindex $histRange 1]

    # step size for x axis
    set div [expr ($maxX-$minX)/18]
    if {$div <= 0.25} {
        set xStep 0.25
    } elseif {$div > 0.25 && $div <= 0.5} {
        set xStep 0.5
    } elseif {$div > 0.5 && $div <= 1.0} {
        set xStep 1.0
    } else {
        set xStep [expr ceil($div)]
    }

    # step size for y axis
    set div [expr ($maxY-$minY)/18]
    if {$div < 1.0} {
        set yStep 1 
    } else {
        set yStep [expr ceil($div)]
    }

    blt::graph $parent.graph -bg white -width $width -height $height 
    pack $parent.graph -side top  
    set fMRIEngine(regionHistogram) $parent.graph

    if {$minX == $maxX} {
        set maxX [expr $maxX + 1]
    }
    $fMRIEngine(regionHistogram) axis configure x \
        -min $minX \
        -max $maxX \
        -stepsize $xStep \
        -title "t value"

    $fMRIEngine(regionHistogram) grid configure \
        -color lightblue \
        -hide no

    $fMRIEngine(regionHistogram) axis configure y \
        -min $minY \
        -max $maxY \
        -stepsize $yStep \
        -title "No of voxels"

    # draw histogram
    for {set idx 0} {$idx < $numBins} {incr idx} {
        set x [expr $origin + $idx * $spacing + ($spacing / 2.0)]
        set y [$data GetScalarComponentAsDouble $idx 0 0 0]
        set lmName "ln$idx"
        $fMRIEngine(regionHistogram) marker create line \
            -coords {$x 0 $x $y} -name $lmName -linewidth 1 \
            -outline black 
    }
}
