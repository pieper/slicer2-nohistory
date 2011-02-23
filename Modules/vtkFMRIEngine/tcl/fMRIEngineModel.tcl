#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineModel.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:37 $
#   Version:   $Revision: 1.20 $
# 
#===============================================================================
# FILE:        fMRIEngineModel.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForSetupTab parent
#   fMRIEngineLoadModel
#   fMRIEngineSaveModel
#   fMRIEngineClearModel
#   fMRIEngineViewModel
#   fMRIEngineBuildUIForTasks parent
#   fMRIEngineSetModelTask task
#   fMRIEngineUpdateSetupTab
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForSetupTab
# Creates UI for model tab 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForSetupTab {parent} {
    global fMRIEngine Gui

    frame $parent.fHelp    -bg $Gui(activeWorkspace)
    frame $parent.fMethods -bg $Gui(backdrop)
    frame $parent.fModel   -bg $Gui(activeWorkspace)
    frame $parent.fTasks   -bg $Gui(activeWorkspace) \
        -relief groove -bd 3

    pack $parent.fHelp $parent.fMethods \
        -side top -fill x -pady 2 -padx 5 
    pack $parent.fModel $parent.fTasks \
        -side top -fill x -pady 3 -padx 5 

    #-------------------------------------------
    # Help frame 
    #-------------------------------------------
#    set f $parent.fHelp
#    DevAddButton $f.bHelp "?" "fMRIEngineShowHelp" 2 
#    pack $f.bHelp -side left -padx 1 -pady 1 

    #-------------------------------------------
    # Methods frame 
    #-------------------------------------------
    set f $parent.fMethods
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetupChooseDetector" 2 
    pack $f.bHelp -side left -padx 1 -pady 1 

    # Build pulldown menu image format 
    eval {label $f.l -text "Analysis method:"} $Gui(BLA)
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w

    # GLM is default format 
    set detectorList [list {Linear Modeling}]
    set df [lindex $detectorList 0] 
    eval {menubutton $f.mbType -text $df \
          -relief raised -bd 2 -width 16 \
          -indicatoron 1 \
          -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    pack  $f.mbType -side left -pady 1 -padx $Gui(pad)

    # Add menu items
    foreach m $detectorList  {
        $f.mbType.m add command -label $m \
            -command ""
    }

    # Save menubutton for config
    set fMRIEngine(gui,mbActDetector) $f.mbType

    #-------------------------------------------
    # Model frame 
    #-------------------------------------------
    set f $parent.fModel
    DevAddButton $f.bLoad "Load Design" "fMRIEngineLoadParadigm"   15 
    DevAddButton $f.bSave "Save Design" "fMRIEngineSaveParadigm"   15 
    DevAddButton $f.bView "View Design" "fMRIEngineViewModel"   15 
    DevAddButton $f.bClear "Clear Design" "fMRIEngineClearModel" 15 
    set ::fMRIEngine(SignalModelDirty) 1
    grid $f.bLoad $f.bSave -padx 1 -pady 1 -sticky e
    grid $f.bView $f.bClear -padx 1 -pady 1 -sticky e

    #-------------------------------------------
    # Tabs frame 
    #-------------------------------------------
    fMRIEngineBuildUIForTasks $parent.fTasks
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineLoadModel
# Loads a saved model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineLoadModel {} {
    global fMRIEngine Gui
    
    puts "load model"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSaveModel
# Saves the current model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSaveModel {} {
    global fMRIEngine Gui
    
    puts "save model"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineClearModel
# Clears the current model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineClearModel {} {
    global fMRIEngine

    set fMRIEngine(baselineEVsAdded)  0
 
    # clear paradigm design panel
    set fMRIEngine(paradigmDesignType) blocked
    set fMRIEngine(checkbuttonRunIdentical) 0
    
    fMRIEngineSelectRunForConditionConfig 1

    set fMRIEngine(entry,title) ""
    set fMRIEngine(entry,tr) ""
    set fMRIEngine(entry,startVol) ""
    set fMRIEngine(entry,onsets) ""
    set fMRIEngine(entry,durations) ""

    fMRIEngineSelectRunForConditionShow 1

    $fMRIEngine(condsListBox) delete 0 end 

    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        if {[info exists fMRIEngine($r,conditionList)]} {
            foreach title $fMRIEngine($r,conditionList) {
                unset -nocomplain fMRIEngine($r,$title,title)
                unset -nocomplain fMRIEngine($r,$title,startVol)
                unset -nocomplain fMRIEngine($r,$title,onsets)
                unset -nocomplain fMRIEngine($r,$title,durations)
            }
            unset -nocomplain fMRIEngine($r,tr)
            unset -nocomplain fMRIEngine($r,conditionList)
        }
    }

    # clear signal modeling panel
    fMRIEngineUpdateConditionsForSignalModeling 
    fMRIEngineSelectWaveFormForSignalModeling {Box Car} 
    fMRIEngineSelectConvolutionForSignalModeling {none} 
    fMRIEngineSelectTrendModelForSignalModeling {none} 
    fMRIEngineShowDefaultHighpassTemporalCutoff 
    #fMRIEngineSelectLowpassForSignalModeling {none}
    #--- wjp 09/01/05
    set fMRIEngine(numDerivatives) 0
    #set fMRIEngine(checkbuttonTempDerivative) 0
    set fMRIEngine(checkbuttonGlobalEffects)  0

    set size [$fMRIEngine(evsListBox) size]
    set i 0
    while {$i < $size} {  
        set ev [$fMRIEngine(evsListBox) get $i] 
        if {$ev != ""} {
            unset -nocomplain fMRIEngine($ev,ev)            
            unset -nocomplain fMRIEngine($ev,run)
            unset -nocomplain fMRIEngine($ev,title,ev) 
            unset -nocomplain fMRIEngine($ev,condition,ev) 
            unset -nocomplain fMRIEngine($ev,waveform,ev)   
            unset -nocomplain fMRIEngine($ev,convolution,ev)
            unset -nocomplain fMRIEngine($ev,derivative,ev)
            unset -nocomplain fMRIEngine($ev,highpass,ev) 
            #unset -nocomplain fMRIEngine($ev,lowpass,ev) 
            unset -nocomplain fMRIEngine($ev,globaleffects,ev)
        }
        incr i
    }
    $fMRIEngine(evsListBox) delete 0 end 
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        set str "r$r:baseline"
        $fMRIEngine(evsListBox) insert end $str 
    }

    # clear contrasts panel
    set fMRIEngine(contrastOption) t 
    set fMRIEngine(entry,contrastName) ""
    set fMRIEngine(entry,contrastVolName) ""
    set fMRIEngine(entry,contrastVector) ""

    set size [$fMRIEngine(contrastsListBox) size]
    for {set i 0} {$i < $size} {incr i} {
        set name [$fMRIEngine(contrastsListBox) get $i] 
        if {$name != ""} {
            unset -nocomplain fMRIEngine($name,contrastName) 
            unset -nocomplain fMRIEngine($name,contrastVolName) 
            unset -nocomplain fMRIEngine($name,contrastVector)
        }
    } 
    $fMRIEngine(contrastsListBox) delete 0 end 
    set ::fMRIEngine(SignalModelDirty) 1
    # clear model view
    fMRIModelViewCloseAndCleanAndExit
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineViewModel
# Views the current model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineViewModel {} {
    global fMRIEngine

    #--- wjp 10/27/05 -- need to count evs before viewing model...
    if {$fMRIEngine(noOfSpecifiedRuns) == 0} {
        DevErrorWindow "No run has been specified."
        return 
    }

    if { ! [ fMRIEngineCountEVs] } {
        return 
    }

    #--- are EVs defined for each specified run?
    #--- If not, don't view
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
        if {! [info exists fMRIEngine($r,noOfEVs)]} {
            DevErrorWindow "Complete signal modeling first for run$r."
            return 
        }
    }

    #--- test to see if all evs are defined yet for each run.
    #--- If not, don't view
    set j 0
    set end [$fMRIEngine(gui,conditionsMenuForSignal) index end] 
    while {$j <= $end} {  
        set v [$fMRIEngine(gui,conditionsMenuForSignal) entrycget $j -label] 
        if { ($v != "") && ($v != "all") && ($v != "none") } {
            set v $v:

            # for each condition, search it over the specified evs
            # if found, it has been modeled.
            set size [$fMRIEngine(evsListBox) size]
            set i 0
            while {$i < $size} {  
                set ev [$fMRIEngine(evsListBox) get $i] 
                if {$ev != ""} {
                    set found [string first $v $ev 0] 
                    if {$found >= 0} {
                        break
                    }
                }

                incr i
            }

            # not found, the condition is not modeled.
            if {$found == -1} {
                DevErrorWindow "Please model all conditions first"
                return 
            }
        }

        incr j
    }

    #--- looks reasonable. Count evs and launch view.
    if { [ fMRIEngineCountEVs ] } {
        if { ! [ fMRIModelViewLaunchModelView ] } {
            DevErrorWindow "Error in model specification. No model generated."
            return 
        } 
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForTasks
# Creates UI for tasks in model 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForTasks {parent} {
    global fMRIEngine Gui

    frame $parent.fTop  -bg $Gui(backdrop)
    frame $parent.fHelp -bg $Gui(activeWorkspace)
    frame $parent.fBot  -bg $Gui(activeWorkspace) -height 560
    pack $parent.fTop $parent.fHelp $parent.fBot \
        -side top -fill x -pady 2 -padx 5 

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetup" 2 
    pack $f.bHelp -side left -padx 1 -pady 1 
 
    # Build pulldown task menu 
    eval {label $f.l -text "Specify:"} $Gui(BLA)
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w

    # Paradigm design is default task 
    set taskList [list {Paradigm} {Modeling} {Estimation} {Contrasts}]
    set df [lindex $taskList 0] 
    eval {menubutton $f.mbTask -text $df \
          -relief raised -bd 2 -width 33 \
          -indicatoron 1 \
          -menu $f.mbTask.m} $Gui(WMBA)
    eval {menu $f.mbTask.m} $Gui(WMA)
    pack  $f.mbTask -side left -pady 1 -padx $Gui(pad)

    # Save menubutton for config
    set fMRIEngine(gui,currentModelTask) $f.mbTask

    # Add menu items
    set count 1
    foreach m $taskList {
        $f.mbTask.m add command -label $m \
            -command "fMRIEngineSetModelTask {$m}"
    }

    #-------------------------------------------
    # Help frame 
    #-------------------------------------------
#    set f $parent.fHelp
#    DevAddButton $f.bHelp "?" "fMRIEngineShowHelp" 2 
#    pack $f.bHelp -side left -padx 5 -pady 1 

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBot

    # Add menu items
    set count 1
    foreach m $taskList {
        # Makes a frame for each reader submodule
        frame $f.f$count -bg $Gui(activeWorkspace) 
        place $f.f$count -relwidth 1.0 -relx 0.0 -relheight 1.0 -rely 0.0 
        switch $m {
            "Paradigm" {
                fMRIEngineBuildUIForParadigmDesign $f.f$count
            }
            "Modeling" {
                fMRIEngineBuildUIForSignalModeling $f.f$count
            }
            "Estimation" {
                fMRIEngineBuildUIForModelEstimation $f.f$count
            }
            "Contrasts" {
                fMRIEngineBuildUIForContrasts $f.f$count
            }
        }
        set fMRIEngine(f$count) $f.f$count
        incr count
    }

    # raise the default one 
    raise $fMRIEngine(f1)

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSetModelTask
# Switches model task 
# .ARGS
# string task the model task 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSetModelTask {task} {
    global fMRIEngine
    
    set fMRIEngine(currentModelTask) $task

    # configure menubutton
    $fMRIEngine(gui,currentModelTask) config -text $task

    set count -1 
    switch $task {
        "Paradigm" {
            set count 1
        }
        "Modeling" {
            set count 2
            fMRIEngineUpdateConditionsForSignalModeling
       }
        "Estimation" {
            set count 3
        }
        "Contrasts" {
            set count 4
        }
    }

    set f  $fMRIEngine(f$count)
    raise $f
    focus $f
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateSetupTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateSetupTab {} {
    global fMRIEngine

    set fMRIEngine(currentTab) "Set up"
}
