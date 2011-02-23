#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineCompute.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:37 $
#   Version:   $Revision: 1.22 $
# 
#===============================================================================
# FILE:        fMRIEngineCompute.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForComputeTab parent
#   fMRIEngineComputeContrasts
#   fMRIEngineUpdateMRML 
#   fMRIEngineUpdateContrastList
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForComputeTab
# Creates UI for the compute tab 
# .ARGS
# windowpath parent
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForComputeTab {parent} {
    global fMRIEngine Gui

    frame $parent.fTop -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $parent.fBot -bg $Gui(activeWorkspace)
    pack $parent.fTop $parent.fBot \
        -side top -fill x -pady 5 -padx 5 

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    frame $f.fBox    -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    pack $f.fBox $f.fButtons -side top -fill x -pady 2 -padx 1 

    set f $parent.fTop.fBox
    DevAddLabel $f.l "Select contrast(s):"

    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(computeVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -selectmode multiple \
        -yscrollcommand {$::fMRIEngine(computeVerScroll) set}
    set fMRIEngine(computeListBox) $f.lb
    $fMRIEngine(computeVerScroll) configure -command {$fMRIEngine(computeListBox) yview}

    blt::table $f \
        0,0 $f.l -cspan 2 -fill x -padx 1 -pady 5 \
        1,0 $fMRIEngine(computeListBox) -fill x -padx 1 -pady 1 \
        1,1 $fMRIEngine(computeVerScroll) -fill y -padx 1 -pady 1

    set f $parent.fTop.fButtons
    DevAddButton $f.bHelp "?" "fMRIEngineHelpComputeActivationVolume" 2 
    DevAddButton $f.bCompute "Compute" "fMRIEngineComputeContrasts" 10 
    grid $f.bHelp $f.bCompute -padx 1 -pady 3 

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBot
    DevAddLabel $f.l "Computing volume for this contrast:"
    eval {entry $f.eStatus -width 20 \
                -textvariable fMRIEngine(actVolName)} $Gui(WEA)
    pack $f.l $f.eStatus -side top -expand false -fill x -padx 5 -pady 3 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineComputeContrasts
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineComputeContrasts {} {
    global fMRIEngine Gui MultiVolumeReader Volume

    set curs [$fMRIEngine(computeListBox) curselection] 
    if {$curs != ""} {
        if {! [info exists fMRIEngine(actBetaVolume)]} {
            DevErrorWindow "Estimating the model first."
            return
        }

        # generates data without popping up the model image 
        if {! [fMRIModelViewGenerateModel ]} {
            DevErrorWindow "Error in model specification. No model generated."
            return 
        }

        unset -nocomplain fMRIEngine(actVolumeNames)

        # MRML id for the new volume
        set i -1

        set size [llength $curs]
        for {set ii 0} {$ii < $size} {incr ii} {
            set jj [lindex $curs $ii]
            set name [$fMRIEngine(computeListBox) get $jj] 

            if {$name != ""} {
                # always uses a new instance of vtkActivationVolumeGenerator 
                if {[info commands fMRIEngine(actVolumeGenerator)] != ""} {
                    fMRIEngine(actVolumeGenerator) Delete
                        unset -nocomplain fMRIEngine(actVolumeGenerator)
                }
                vtk$fMRIEngine(detectionMethod)VolumeGenerator fMRIEngine(actVolumeGenerator)
                fMRIEngine(actVolumeGenerator) SetPreWhitening $::fMRIEngine(checkbuttonPreWhiten)

                # adds progress bar
                set obs1 [fMRIEngine(actVolumeGenerator) AddObserver StartEvent MainStartProgress]
                set obs2 [fMRIEngine(actVolumeGenerator) AddObserver ProgressEvent \
                    "MainShowProgress fMRIEngine(actVolumeGenerator)"]
                set obs3 [fMRIEngine(actVolumeGenerator) AddObserver EndEvent MainEndProgress]
                
                set fMRIEngine(actVolName) $name 

                set Gui(progressText) "Computing $name..."
                puts $Gui(progressText)

                # Extract contrast info from the long contrast vector for all concatenated runs.
                set vec $fMRIEngine($name,contrastVector) 
                set originalContrastVector [split $vec " "]

                #--- determine contrast string for each run specified...
                set first 0
                for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
                    set last [expr $first+$fMRIEngine($r,totalEVs)-1]
                    set last [ expr int ($last) ]
                    set fMRIEngine($r,contrastVector) [lrange $originalContrastVector $first $last]
                    set fMRIEngine($r,contrastString) [join $fMRIEngine($r,contrastVector) " "]
                    set first [expr $first+$fMRIEngine($r,totalEVs)]
                    set first [ expr int ($first) ]
                }
                #--- wjp 11/08/05
                #--- The contrast string must be the same for each run being concatenated
                #--- for matching conditions. Since we only concatenate condition-EVs in
                #--- the concatenated run analysis (and don't concatenate baselines or
                #--- columns containing low frequency nuissance filters), we only
                #--- need to check that corresponding conditions have identical
                #--- contrast specifications.
                set run $fMRIEngine(curRunForModelFitting)
                if {$run == "concatenated"} {
                    #--- wjp 11/08/05
                    #--- First find target contrast string for run1 (only need condition-related EVs):
                    #--- here, fMRIEngine(1,noOfEVs) counts up only condition-related EVs.
                    #--- search for $numConditionEVs spaces in the string and use all characters
                    #--- but for the last space....
                    set spacecntr 0
                    set indx 0
                    set cntrst [ string trim $::fMRIEngine(1,contrastString) ]
                    while { $spacecntr < $::fMRIEngine(1,noOfEVs) } {
                        incr indx
                        set indx [ string first " " $cntrst $indx ]
                        incr spacecntr
                    }
                    set len [ string len $cntrst ]
                    set target [ string range $cntrst 0 $indx ]
                    set target [ string trim $target ]
                    #--- and get contrast weights for other EVs (baseline and DC basis) in run 1
                    set other [ string range $cntrst $indx $len ]
                    set other [ string trim $other ]
                    set contrVector $target
                    set contrVector [ concat $contrVector $other ]

                    #--- compare all other contrast strings to this target for run 1
                    for {set r 2} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
                        set spacecntr 0
                        set indx 0
                        set cntrst [ string trim $::fMRIEngine($r,contrastString) ]
                        while { $spacecntr < $::fMRIEngine($r,noOfEVs) } {
                            incr indx
                            set indx [ string first " " $cntrst $indx ]
                            incr spacecntr
                        }
                        set len [ string len $cntrst ]
                        set snip [ string range $cntrst 0 $indx ]
                        set snip [ string trim $snip ]
                        if {! [string equal -nocase $target $snip ] } {
                            #if {! [string equal -nocase $fMRIEngine(1,contrastString) $fMRIEngine($r,contrastString)]} 
                            DevErrorWindow "Bad contrast vector for concatenated runs:\nName: $name\nVector: $vec"
                            return 
                        }
                        #--- and get contrast weights for other EVs (baseline and DC basis) in run
                        set other [ string range $cntrst $indx $len ]
                        set other [ string trim $other ]
                        set contrVector [ concat $contrVector $other ]
                    }

                    #--- Ok, now we know all runs contain combinable contrasts.
                    #--- now assemble a new contrast vector for concatenated analysis.
                    #--- This has to look like $target run1basis run1DCs run2basis, run2DCs etc.
                } else {
                    set contrVector $fMRIEngine($run,contrastVector)
                }
                #--- end wjp 11/08/05 changes.
                
                set len [llength $contrVector]
                if {[info commands fMRIEngine(contrast)] != ""} {
                    fMRIEngine(contrast) Delete
                    unset -nocomplain fMRIEngine(contrast)
                }
                vtkIntArray fMRIEngine(contrast)

                fMRIEngine(contrast) SetNumberOfTuples $len 
                fMRIEngine(contrast) SetNumberOfComponents 1
                set count 0
                foreach entry $contrVector {
                    fMRIEngine(contrast) SetComponent $count 0 $entry 
                    incr count
                }


                fMRIEngine(actVolumeGenerator) SetContrastVector fMRIEngine(contrast)
                fMRIEngine(actVolumeGenerator) SetDesignMatrix fMRIEngine(designMatrix)
                fMRIEngine(actVolumeGenerator) SetInput $fMRIEngine(actBetaVolume)
                set act [fMRIEngine(actVolumeGenerator) GetOutput]
                $act Update
                set fMRIEngine(act) $act

                fMRIEngine(actVolumeGenerator) RemoveObserver $obs1 
                fMRIEngine(actVolumeGenerator) RemoveObserver $obs2 
                fMRIEngine(actVolumeGenerator) RemoveObserver $obs3 
                MainStartProgress
                MainShowProgress fMRIEngine(actVolumeGenerator) 
 
                # add a mrml node
                set n [MainMrmlAddNode Volume]
                set i [$n GetID]
                MainVolumesCreate $i

                # set the name and description of the volume
                $n SetName "$name" 
                lappend fMRIEngine(actVolumeNames) "$name"
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

                Volume($i,vol) SetRangeLow [fMRIEngine(actVolumeGenerator) GetLowRange] 
                Volume($i,vol) SetRangeHigh [fMRIEngine(actVolumeGenerator) GetHighRange] 

                # To keep variables 'RangeLow' and 'RangeHigh' as float 
                # in vtkMrmlDataVolume for float volume, use this function:
                Volume($i,vol) SetRangeAuto 0

                # set the lower threshold to the actLow 
                Volume($i,node) AutoThresholdOff
                Volume($i,node) ApplyThresholdOn
                Volume($i,node) SetLowerThreshold [fMRIEngine(actVolumeGenerator) GetLowRange]
                # Volume($i,node) SetLowerThreshold 1

                set fMRIEngine($i,actLow) [fMRIEngine(actVolumeGenerator) GetLowRange] 
                set fMRIEngine($i,actHigh) [fMRIEngine(actVolumeGenerator) GetHighRange] 

                MainSlicesSetVolumeAll Fore $i
                MainVolumesSetActive $i

                # set the act volume to the color of FMRI 
                MainVolumesSetParam LutID 7 

                # Save contrast vector for activation volume
                # This will be used for % signal change
                set fMRIEngine($i,contrastVector) $contrVector

                MainEndProgress
                puts "...done"
            }
        } 

        set fMRIEngine(actVolName) "" 
        set Gui(progressText) "Updating..."
        puts $Gui(progressText)
        MainStartProgress
        MainShowProgress fMRIEngine(actVolumeGenerator) 
        MainUpdateMRML

        RenderAll
        MainEndProgress

        puts "...done"
    } else {
        DevErrorWindow "Select contrast(s) to compute."
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateMRML 
# Updates the MRML tree following addition of volume(s). This version will speed 
# up the updating process if Slicer has loaded many volumes in memory. Proc
# MainVolumesUpdateMRML takes time to complete.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateMRML {} {
    global Module Label
        
    # Call each "MRML" routine that's not part of a module
    #-------------------------------------------
    MainMrmlUpdateMRML
    MainColorsUpdateMRML
#    MainVolumesUpdateMRML
#    MainTensorUpdateMRML
    MainModelsUpdateMRML
    MainTetraMeshUpdateMRML

    MainAlignmentsUpdateMRML

    foreach p $Module(procMRML) {
        $p
    }

    # Call each Module's "MRML" routine
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,procMRML)] == 1} {
            $Module($m,procMRML)
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateContrastList
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateContrastList {} {
    global fMRIEngine

    set fMRIEngine(currentTab) "Compute"

    $fMRIEngine(computeListBox) delete 0 end

    set size [$fMRIEngine(contrastsListBox) size]
    for {set i 0} {$i < $size} {incr i} {
        set name [$fMRIEngine(contrastsListBox) get $i] 
        if {$name != ""} {
            $fMRIEngine(computeListBox) insert end $name
        }
    } 
}


