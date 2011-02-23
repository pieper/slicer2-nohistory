#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineInspect.tcl,v $
#   Date:      $Date: 2006/03/02 22:22:22 $
#   Version:   $Revision: 1.31 $
# 
#===============================================================================
# FILE:        fMRIEngineInspect.tcl
# PROCEDURES:  
#   fMRIEngineScaleActivation no
#   fMRIEngineUpdateViewTab
#   fMRIEngineInspectActVolume
#   fMRIEngineBuildUIForViewTab parent
#   fMRIEngineBuildUIForChoose parent
#   fMRIEngineBuildUIForPlot parent
#   fMRIEngineToggleCutoff
#   fMRIEngineBuildUIForThreshold parent
#   fMRIEngineClickRadioButton which
#   fMRIEngineCheckCutoff
#   fMRIEngineComputeDefaultCutoff
#   fMRIEngineStatHighPassFiltering
#   fMRIEngineUpdateEVsForPlotting
#   fMRIEngineSelectEVForPlotting ev count
#==========================================================================auto=
     
#-------------------------------------------------------------------------------
# .PROC fMRIEngineScaleActivation
# Scales the activation volume 
# .ARGS
# int no the scale index 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineScaleActivation {v} {
    global Volume fMRIEngine MultiVolumeReader Slicer

    if {! [info exists fMRIEngine(currentActVolID)]} {
        DevErrorWindow "Choose an activation volume to view."
        return
    }

    if {[ValidateInt $fMRIEngine(DOF)] == 0 ||
        $fMRIEngine(DOF) < 1} {
        DevErrorWindow "Degree of freedom (DOF) must be a positive integer number."
        return
    }

    if {[ValidateInt $fMRIEngine(pValue)] == 0 &&
        [ValidateFloat $fMRIEngine(pValue)] == 0} {
        DevErrorWindow "p Value must be a floating point or integer number."
        return
    }

    set delta 0.0
    set delta [expr {$v == "+" ? 0.01 : $delta}]
    set delta [expr {$v == "-" ? -0.01 : $delta}]
    set fMRIEngine(pValue) [expr {$fMRIEngine(pValue) + $delta}] 
    set fMRIEngine(pValue) [expr {$fMRIEngine(pValue) < 0.0 ? 0.0 : $fMRIEngine(pValue)}] 
    set fMRIEngine(pValue) [expr {$fMRIEngine(pValue) > 1.0 ? 1.0 : $fMRIEngine(pValue)}] 

    if {$fMRIEngine(pValue) <= 0.0} {
        set fMRIEngine(tStat) "Inf" 
        # 32767 = max of signed short
        set t 32767.0
    } else {
        if {$fMRIEngine(thresholdingOption) == "uncorrected"} {
            if {[info command cdf] == ""} {
                vtkCDF cdf
            }
 
            set t [cdf p2t $fMRIEngine(pValue) $fMRIEngine(DOF)]
            cdf Delete
        } else {
            if {[info commands fMRIEngine(fdrThreshold)] != ""} {
                fMRIEngine(fdrThreshold) Delete
                unset -nocomplain fMRIEngine(fdrThreshold)
            }
            vtkActivationFalseDiscoveryRate fMRIEngine(fdrThreshold)

            set id $fMRIEngine(currentActVolID) 
            fMRIEngine(fdrThreshold) SetQ $fMRIEngine(pValue)

            set option 1
            if {$fMRIEngine(thresholdingOption) == "cdep"} {
                set option 2
            }
            fMRIEngine(fdrThreshold) SetOption $option 

            fMRIEngine(fdrThreshold) SetDOF $fMRIEngine(DOF)
            fMRIEngine(fdrThreshold) SetInput [Volume($id,vol) GetOutput]  
            fMRIEngine(fdrThreshold) Update
            set t [fMRIEngine(fdrThreshold) GetFDRThreshold]
        }
        set fMRIEngine(tStat) [format "%.1f" $t]
    }

    # render the thresheld image
    set id $fMRIEngine(currentActVolID) 
    if {$id > 0} {
        Volume($id,node) AutoThresholdOff
        Volume($id,node) ApplyThresholdOn
        Volume($id,node) SetLowerThreshold $t 
        MainVolumesRender
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateViewTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateViewTab {} {
    global fMRIEngine Gui Volume MultiVolumeReader

    set fMRIEngine(currentTab) "Inspect"

    if {[info exists MultiVolumeReader(noOfVolumes)]} {
        if {$fMRIEngine(DOF) == 1} {
            set dof [expr $MultiVolumeReader(noOfVolumes) - 1]
            set dof [expr {$dof > 0 ? $dof : 1}]
            set fMRIEngine(DOF) $dof
        }
    }
 
    # Peristimulus histogram plotting will be disabled if the paradigm desgin is 
    # event-related or mixed.
    if {$fMRIEngine(paradigmDesignType) != "blocked"} {
        $fMRIEngine(gui,viewTimecourseRadioButton) select 
        $fMRIEngine(gui,viewPeristimulusRadioButton) config -state disabled
    } else {
        $fMRIEngine(gui,viewPeristimulusRadioButton) config -state normal 
    }

    $fMRIEngine(inspectListBox) delete 0 end
    if {[info exists fMRIEngine(actVolumeNames)]} {
        set size [llength $fMRIEngine(actVolumeNames)]

        for {set i 0} {$i < $size} {incr i} {
            set name [lindex $fMRIEngine(actVolumeNames) $i] 
            if {$name != ""} {
                $fMRIEngine(inspectListBox) insert end $name
            }
        } 
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineInspectActVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineInspectActVolume {} {
    global fMRIEngine Gui Volume

    unset -nocomplain fMRIEngine(currentActVolID)

    set curs [$fMRIEngine(inspectListBox) curselection] 
    if {$curs != ""} {
        set name [$fMRIEngine(inspectListBox) get $curs] 

        set id [MIRIADSegmentGetVolumeByName $name] 
        set fMRIEngine(currentActVolID) $id
        set fMRIEngine(currentActVolName) $name

        MainSlicesSetVolumeAll Fore $id
        MainVolumesSetActive $id
        MainVolumesRender
    }
}
 

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForViewTab
# Creates UI for the view tab 
# .ARGS
# windowpath parent
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForViewTab {parent} {
    global fMRIEngine Gui

    set f $parent

    #--- create blt notebook
    blt::tabset $f.tsNotebook -relief flat -borderwidth 0
    pack $f.tsNotebook -side top

    #--- notebook configure
    $f.tsNotebook configure -width 240
    $f.tsNotebook configure -height 260 
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
    foreach t "Choose Thrshld Plot" {
        $f.tsNotebook insert $i $t
        frame $f.tsNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        if {$t == "Thrshld"} {
            fMRIEngineBuildUIForThreshold $f.tsNotebook.f$t
        } else {
            fMRIEngineBuildUIFor${t} $f.tsNotebook.f$t
        }

        $f.tsNotebook tab configure $t -window $f.tsNotebook.f$t 
        $f.tsNotebook tab configure $t -activebackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -selectbackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -background $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -fill both -padx 1 -pady $::Gui(pad) 
        incr i
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForChoose
# Creates UI for the choose tab 
# .ARGS
# windowpath parent
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForChoose {parent} {
    global fMRIEngine Gui

    frame $parent.fChoose    -bg $Gui(activeWorkspace)
    pack $parent.fChoose -side top -fill x -padx 5 -pady 3 

    #-------------------------------------------
    # Choose a volume tab 
    #-------------------------------------------
    set f $parent.fChoose
    DevAddLabel $f.l "Choose a volume to view:"

    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(inspectVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -yscrollcommand {$::fMRIEngine(inspectVerScroll) set}
    set fMRIEngine(inspectListBox) $f.lb
    $fMRIEngine(inspectVerScroll) configure -command {$fMRIEngine(inspectListBox) yview}

    DevAddButton $f.bGo "Select" "fMRIEngineInspectActVolume" 15 
 
    blt::table $f \
        0,0 $f.l -cspan 2 -fill x -padx 1 -pady 2 \
        1,0 $fMRIEngine(inspectListBox) -fill x -padx 1 -pady 1 \
        1,1 $fMRIEngine(inspectVerScroll) -fill y -padx 1 -pady 1 \
        2,0 $f.bGo -cspan 2 -padx 1 -pady 5 
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForPlot
# Creates UI for the plot tab 
# .ARGS
# windowpath parent
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForPlot {parent} {
    global fMRIEngine Gui

    frame $parent.fPlot -bg $Gui(activeWorkspace)
    pack $parent.fPlot -side top -fill x -padx 5 -pady 3 

    set f $parent.fPlot

    frame $f.fTitle    -bg $Gui(activeWorkspace)
    frame $f.fHighPass -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $f.fOptions  -bg $Gui(activeWorkspace) -relief groove -bd 1 
    pack $f.fTitle $f.fHighPass $f.fOptions -side top -fill x -padx 5 -pady 2 

    set f $parent.fPlot.fTitle
    DevAddButton $f.bHelp "?" "fMRIEngineHelpViewPlotting" 2
    DevAddLabel $f.lLabel "Time series plotting:"
    grid $f.bHelp $f.lLabel -padx 1 -pady 5 

    set f $parent.fPlot.fHighPass
    frame $f.fButton -bg $Gui(activeWorkspace)
    frame $f.fLabel  -bg $Gui(activeWorkspace)
    frame $f.fEntry  -bg $Gui(activeWorkspace)
    pack $f.fButton $f.fLabel $f.fEntry -side top -fill x -padx 5 -pady 2 

    set f $parent.fPlot.fHighPass.fButton
    eval {checkbutton $f.cbHighPass \
        -variable fMRIEngine(highPass) \
        -width 25 \
        -text "Apply high-pass filtering"} $Gui(WEA) 
    $f.cbHighPass deselect 
    pack $f.cbHighPass -side top -padx 5 -pady 2 
    bind $f.cbHighPass <1> "fMRIEngineToggleCutoff"

    set f $parent.fPlot.fHighPass.fLabel
    DevAddButton $f.bHelp "?" "fMRIEngineHelpViewHighPassFiltering" 2
    DevAddLabel $f.lCutoff "Cutoff frequency:"
    grid $f.bHelp $f.lCutoff -padx 1 -pady 1 

    set f $parent.fPlot.fHighPass.fEntry
    eval {entry $f.eCutoff -width 28 \
        -textvariable fMRIEngine(cutoff)} $Gui(WEA)
    $f.eCutoff config -state disabled
    set fMRIEngine(gui,cutoffFrequencyEntry) $f.eCutoff
    pack $f.eCutoff -side top -padx 5 -pady 2 

    # Options frame
    set f $parent.fPlot.fOptions
    frame $f.fConds        -bg $Gui(activeWorkspace)
    frame $f.fTimecourse   -bg $Gui(activeWorkspace)
    frame $f.fPeristimulus -bg $Gui(activeWorkspace)
    pack $f.fConds $f.fTimecourse $f.fPeristimulus -side top -padx 2 -pady 1 

    set f $parent.fPlot.fOptions.fConds
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
    grid $f.lLabel $f.mbType -padx 1 -pady 2 
    # Save menubutton for config
    set fMRIEngine(gui,condsMenuButtonForPlotting) $f.mbType
    set fMRIEngine(gui,condsMenuForPlotting) $f.mbType.m

    set f $parent.fPlot.fOptions.fTimecourse
    set param Long 
    set name {Timecourse}
    eval {radiobutton $f.r$param -width 25 -text $name \
        -variable fMRIEngine(tcPlottingOption) -value $param \
        -relief raised -offrelief raised -overrelief raised \
        -selectcolor white} $Gui(WEA)
    set fMRIEngine(tcPlottingOption) "Long"
    pack $f.r$param -side top -pady 2 
    set fMRIEngine(gui,viewTimecourseRadioButton) $f.r$param 

    set f $parent.fPlot.fOptions.fPeristimulus
    set param Short 
    set name {Peristimulus histogram}
    eval {radiobutton $f.r$param -width 25 -text $name \
        -variable fMRIEngine(tcPlottingOption) -value $param \
        -relief raised -offrelief raised -overrelief raised \
        -selectcolor white} $Gui(WEA)
    pack $f.r$param -side top -pady 2 
    set fMRIEngine(gui,viewPeristimulusRadioButton) $f.r$param 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineToggleCutoff
# Enables or disables the entry of cutoff for high pass filtering 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineToggleCutoff {} {
    global fMRIEngine

    set state [expr {$fMRIEngine(highPass) == 1 ? "disabled" : "normal"}]
    set hp [expr {$fMRIEngine(highPass) == 1 ? 0 : 1}]

    $fMRIEngine(gui,cutoffFrequencyEntry) config -state $state
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForThreshold
# Creates UI for the display tab 
# .ARGS
# windowpath parent
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForThreshold {parent} {
    global fMRIEngine Gui

    frame $parent.fVols -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $parent.fOptions -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $parent.fThreshold -bg $Gui(activeWorkspace) -relief groove -bd 1
    pack $parent.fVols $parent.fOptions $parent.fThreshold \
        -side top -fill x -padx 5 -pady 2 

    #-------------------------------------------
    # Vols frame 
    #-------------------------------------------
    set f $parent.fVols
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetDOF" 2
    DevAddLabel $f.lDOF "Degree of freedom:"
    eval {entry $f.eDOF -width 9 \
        -textvariable fMRIEngine(DOF)} $Gui(WEA)
    set fMRIEngine(DOF) 1 

    grid $f.bHelp $f.lDOF $f.eDOF -padx 1 -pady 2 -sticky e

    #-------------------------------------------
    # Options frame 
    #-------------------------------------------
    set f $parent.fOptions
    foreach m "Title Buttons" {
        frame $f.f${m} -bg $Gui(activeWorkspace)
        pack $f.f${m} -side top -fill x -pady 2 
    }

    set f $parent.fOptions.fTitle 
    DevAddButton $f.bHelp "?" "fMRIEngineHelpViewActivationThreshold" 2
    DevAddLabel $f.lLabel "Choose a thresholding option:"
    grid $f.bHelp $f.lLabel -padx 1 -pady 2 

    set f $parent.fOptions.fButtons 
    foreach param "Uncorrected CorrectedCind CorrectedCdep" \
            name "{uncorrected p value} {corrected p value (cind)} {corrected p value (cdep)}" \
            value "uncorrected cind cdep" {

        eval {radiobutton $f.r$param -width 25 -text $name \
            -variable fMRIEngine(thresholdingOption) -value $value \
            -relief raised -offrelief raised -overrelief raised \
            -selectcolor white} $Gui(WEA)

        pack $f.r$param -side top -pady 2 
        bind $f.r$param <1> "fMRIEngineClickRadioButton $value"
    }
    set fMRIEngine(thresholdingOption) uncorrected 

    #-------------------------------------------
    # Threshold frame 
    #-------------------------------------------
    set f $parent.fThreshold
    foreach m "Title Params" {
        frame $f.f${m} -bg $Gui(activeWorkspace)
        pack $f.f${m} -side top -fill x -pady 2 
    }

    set f $parent.fThreshold.fTitle 
    DevAddLabel $f.lLabel "Threshold the activation:"
    grid $f.lLabel -padx 1 -pady 2 

    set f $parent.fThreshold.fParams 
    frame $f.fStat  -bg $Gui(activeWorkspace) 
    pack $f.fStat -side top -fill x -padx 2 -pady 1 

    set f $parent.fThreshold.fParams.fStat 
    DevAddLabel $f.lPV "p Value:"
    DevAddLabel $f.lTS "t Stat:"
    set fMRIEngine(pValue) "0.0"
    set fMRIEngine(tStat) "Inf"
    eval {entry $f.ePV -width 15 \
        -textvariable fMRIEngine(pValue)} $Gui(WEA)
    eval {entry $f.eTS -width 15 -state readonly \
        -textvariable fMRIEngine(tStat)} $Gui(WEA)
    bind $f.ePV <Return> "fMRIEngineScaleActivation p"
    TooltipAdd $f.ePV "Input a p value and hit Return to threshold."

    DevAddButton $f.bPlus "+" "fMRIEngineScaleActivation +" 2
    TooltipAdd $f.bPlus "Increase the p value by 0.01 to threshold."
    DevAddButton $f.bMinus "-" "fMRIEngineScaleActivation -" 2
    TooltipAdd $f.bMinus "Decrease the p value by 0.01 to threshold."
 
    grid $f.lPV $f.ePV $f.bPlus $f.bMinus -padx 1 -pady 2 -sticky e
    grid $f.lTS $f.eTS -padx 1 -pady 2 -sticky e
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineClickRadioButton
# Handles the click event on radio buttons 
# .ARGS
# value which button is clicked
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineClickRadioButton {value} {
    global fMRIEngine

    set fMRIEngine(thresholdingOption) $value
    fMRIEngineScaleActivation p
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCheckCutoff
# Checks and updates the frequency cutoff for high pass filtering 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCheckCutoff {} {
    global fMRIEngine

    if {[info command fMRIEngine(actEstimator)] != ""} {
        set cutoff [string trim $fMRIEngine(cutoff)]

        set b [string is integer -strict $cutoff]
        set c [string is double -strict $cutoff]
        if {$cutoff == "" || ($b == 0 && $c == 0)} {
            set cutoff [fMRIEngineComputeDefaultCutoff]
        }

        set fMRIEngine(cutoff) $cutoff 
        fMRIEngine(actEstimator) SetCutoff $cutoff
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineComputeDefaultCutoff
# Calculates a default frequency cutoff from the user input 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineComputeDefaultCutoff {} {
    global fMRIEngine fMRIModelView

    # http://www-psych.stanford.edu/~kalina/SPM99/Protocols/spm99_analysis_prot.html
    # The formula is that the cutoff period should be twice the minimum interval 
    # between consecutive presentation of trials of the same type.
    
    # Find out the min interval between consecutive presentation 
    # of trials of the same type
    set min 1000000
    for {set r 1} {$r <= $fMRIModelView(Design,numRuns)} {incr r} {
        for {set i 1} {$i <= $fMRIModelView(Design,Run$r,numConditionEVs)} {incr i} {
            if {[info exists fMRIModelView(Design,Run$r,Condition$i,Onsets)]} {
                set a -1 
                foreach onset $fMRIModelView(Design,Run$r,Condition$i,Onsets) {
                    if {$a != -1} {
                        set b [expr {($onset - $a) * $fMRIEngine($r,tr)}]
                        if {$b < $min} {
                            set min $b
                        }
                    }
                    set a $onset
                }
            }
        }
    }

    set f [expr 1.0 / (2 * $min)]
    return $f
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineStatHighPassFiltering
# Performs the high-pass filtering 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineStartHighPassFiltering {} { 
    global fMRIEngine Gui

    if {[info command fMRIEngine(actEstimator)] == ""} {
        DevErrorWindow "No activation volume yet for inspecting."
        return 
    }

    fMRIEngine(actEstimator) EnableHighPassFiltering 0 

    set cutoff [split $fMRIEngine(cutoff) " "]
    set size [llength $cutoff]
    set errorMsg "Input valid values (float or integer) for cutoff." 

    if {$size != 1 && $size != 3} {
        DevErrorWindow $errorMsg
        return
    }

    foreach m $cutoff {
        set v [string trim $m]
        set b [string is integer -strict $v]
        set c [string is double -strict $v]
        if {$b == 0 && $c == 0} {
            DevErrorWindow $errorMsg 
            return
        }
    }

    if {$size == 1} {
        set x [lindex $cutoff 0] 
        fMRIEngine(actEstimator) SetCutoff $x $x $x
    } else {
        set x [lindex $cutoff 0] 
        set y [lindex $cutoff 1] 
        set z [lindex $cutoff 2] 
        fMRIEngine(actEstimator) SetCutoff $x $y $z
    }

    fMRIEngine(actEstimator) EnableHighPassFiltering 1 

    # adds progress bar
    set obs1 [fMRIEngine(actEstimator) AddObserver StartEvent MainStartProgress]
    set obs2 [fMRIEngine(actEstimator) AddObserver ProgressEvent \
              "MainShowProgress fMRIEngine(actEstimator)"]
    set obs3 [fMRIEngine(actEstimator) AddObserver EndEvent MainEndProgress]
    set Gui(progressText) "High-pass filtering..."
    puts $Gui(progressText)

    fMRIEngine(actEstimator) PerformHighPassFiltering

    MainEndProgress
    fMRIEngine(actEstimator) RemoveObserver $obs1 
    fMRIEngine(actEstimator) RemoveObserver $obs2 
    fMRIEngine(actEstimator) RemoveObserver $obs3 

    set Gui(progressText) ""
    puts "...done"
}
    

#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateEVsForPlotting
# Updates ev list for timecourse plotting 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateEVsForPlotting {} {
    global fMRIEngine

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
        $fMRIEngine(gui,condsMenuForPlotting) delete 0 end
        set count 1 
        foreach name $fMRIEngine($run,namesOfConditionEVs) { 
            $fMRIEngine(gui,condsMenuForPlotting) add command -label $name \
                -command "fMRIEngineSelectEVForPlotting $name $count"

            fMRIEngineSelectEVForPlotting $name $count 
            incr count
        }
    }
} 


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectEVForPlotting
# 
# .ARGS
# string ev
# int count
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectEVForPlotting {ev count} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,condsMenuButtonForPlotting) config -text $ev
    set fMRIEngine(curEVIndexForPlotting) $count 
    set fMRIEngine(curEVForPlotting) $ev 

    if {[info exists fMRIEngine(timeCourseToplevel)] &&
        $fMRIEngine(tcPlottingOption) == "Long"} {
            # re-plot due to ev switch
            fMRIEngineDrawPlotLong
    }
}

