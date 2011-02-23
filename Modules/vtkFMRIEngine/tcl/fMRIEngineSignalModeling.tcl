#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineSignalModeling.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:38 $
#   Version:   $Revision: 1.30 $
# 
#===============================================================================
# FILE:        fMRIEngineSignalModeling.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForSignalModeling  parent
#   fMRIEngineBuildUIForModelEstimation
#   fMRIEngineLoadBetaVolume
#   fMRIEngineSaveBetaVolume
#   fMRIEngineViewCoefficients
#   fMRIEngineSelectRunForModelFitting run
#   fMRIEngineUpdateRunsForModelFitting
#   fMRIEngineSelectAllConditionsForSignalModeling
#   fMRIEngineSelectConditionForSignalModeling
#   fMRIEngineUpdateConditionsForSignalModeling
#   fMRIEngineGetRunForCurrentCondition
#   fMRIEngineSelectWaveFormForSignalModeling form
#   fMRIEngineSelectConvolutionForSignalModeling conv
#   fMRIEngineSelectNumDerivativesForSignalModeling
#   fMRIEngineShowTrendModelForSignalModeling
#   fMRIEngineShowDefaultHighpassTemporalCutoff
#   fMRIEngineShowCustomHighpassTemporalCutoff
#   fMRIEngineSelectTrendModelForSignalModeling pass
#   fMRIEngineSelectDefaultHighpassTemporalCutoff
#   fMRIEngineSelectCustomHighpassTemporalCutoff
#   fMRIEngineComputeDefaultHighpassTemporalCutoff
#   fMRIEngineSelectLowpassTemporalCutoff
#   fMRIEngineAddOrEditEV
#   fMRIEngineDeleteEV index
#   fMRIEngineShowEVToEdit
#   fMRIEngineAddInputVolumes run
#   fMRIEngineCheckMultiRuns
#   fMRIEngineAddRegressors run
#   fMRIEngineCountEVs
#   fMRIEngineAppendEVNamesToRun
#   fMRIEngineIncrementEVCountForRun
#   fMRIEngineAddDerivativeSignalsToRun
#   fMRIEngineCombineRunDerivativeCheck
#   fMRIEngineUpdateProgressText
#   fMRIEngineFitModel
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForSignalModeling 
# Creates UI for task "Signal Modeling" 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForSignalModeling {parent} {
    global fMRIEngine Gui

    frame $parent.fChoices      -bg $Gui(activeWorkspace)
    frame $parent.fModeling     -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fFiltering -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fMoreModeling -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $parent.fOK           -bg $Gui(activeWorkspace)
    frame $parent.fEVs          -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $parent.fEstimate     -bg $Gui(activeWorkspace) -relief groove -bd 1
 
    pack $parent.fChoices $parent.fModeling $parent.fFiltering $parent.fMoreModeling \
        $parent.fOK $parent.fEVs  -side top -fill x -pady 2 -padx 1

    #-------------------------------------------
    # Choices frame 
    #-------------------------------------------
    set f $parent.fChoices
    eval {checkbutton $f.cApplyAll \
              -variable fMRIEngine(checkbuttonApplyAllConditions) \
              -indicatoron 1 -relief flat -text "Model all conditions identically" \
              -command "fMRIEngineSelectAllConditionsForSignalModeling" } $Gui(WEA) 
    $f.cApplyAll deselect 
    pack $f.cApplyAll -padx 1 -pady 2 -fill x


    #-------------------------------------------
    # Modeling frame 
    #-------------------------------------------
    set f $parent.fModeling
    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fMenus -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fMenus -side top -fill x -pady 1 -padx 1 


    #-----------------------
    # Menus 
    #-----------------------

    set f $parent.fModeling.fTitle
    DevAddLabel $f.l "Model a condition:" 
    pack $f.l -side top -pady 7 -fill x

    set f $parent.fModeling.fMenus

    # Build pulldown menu for all conditions 
    DevAddLabel $f.lCond "Condition:"

    set condiList [list {none}]
    set df [lindex $condiList 0] 
    eval {menubutton $f.mbType -text $df \
          -relief raised -bd 2 -width 15 \
          -indicatoron 1 \
          -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    #--- wjp 11/11/05 may want to uncomment this...
    bind $f.mbType <1> "fMRIEngineUpdateConditionsForSignalModeling"
    
    foreach m $condiList  {
        $f.mbType.m add command -label $m \
            -command "fMRIEngineSelectConditionForSignalModeling $m"
    }

    # Save menubutton for config
    set fMRIEngine(gui,conditionsMenuButtonForSignal) $f.mbType
    set fMRIEngine(gui,conditionsMenuForSignal) $f.mbType.m

    # Build pulldown menu for wave forms 
    DevAddLabel $f.lWave "Waveform:"
    DevAddButton $f.bWaveHelp "?" "fMRIEngineHelpSetupWaveform" 2 
 
    set waveForms [list {Box Car} {Half Sine}]
    set df [lindex $waveForms 0] 
    eval {menubutton $f.mbType2 -text $df \
          -relief raised -bd 2 -width 15 \
          -indicatoron 1 \
          -menu $f.mbType2.m} $Gui(WMBA)
    eval {menu $f.mbType2.m} $Gui(WMA)

    foreach m $waveForms  {
        $f.mbType2.m add command -label $m \
            -command "fMRIEngineSelectWaveFormForSignalModeling \{$m\}" 
    }

    # Save menubutton for config
    set fMRIEngine(gui,waveFormsMenuButtonForSignal) $f.mbType2
    set fMRIEngine(gui,waveFormsMenuForSignal) $f.mbType2.m
    set fMRIEngine(curWaveFormForSignal) $df

    # Build pulldown menu for convolution functions 
    DevAddLabel $f.lConv "Convolution:"
    DevAddButton $f.bConvHelp "?" "fMRIEngineHelpSetupHRFConvolution" 2 
 
    set convFuncs [list {none} {HRF}]
    set df [lindex $convFuncs 0] 
    eval {menubutton $f.mbType3 -text $df \
          -relief raised -bd 2 -width 15 \
          -indicatoron 1 \
          -menu $f.mbType3.m} $Gui(WMBA)
    eval {menu $f.mbType3.m} $Gui(WMA)

    foreach m $convFuncs  {
        $f.mbType3.m add command -label $m \
            -command "fMRIEngineSelectConvolutionForSignalModeling \{$m\}" 
    }
    set fMRIEngine(gui,convolutionMenuButtonForSignal) $f.mbType3
    set fMRIEngine(gui,convolutionMenuForSignal) $f.mbType3.m
    set fMRIEngine(curConvolutionForSignal) $df 

    #-----------------------
    # Temporal derivative 
    #-----------------------
    DevAddLabel $f.lDeriv "Derivatives:"
    DevAddButton $f.bDerivHelp "?" "fMRIEngineHelpSetupTempDerivative" 2 
    #--- wjp changed 09/01/05
    set ::fMRIEngine(numDerivatives) 0
    set ::fMRIEngine(curDerivativesForSignal) $::fMRIEngine(numDerivatives)
    set ::fMRIEngine(derivOptions) [ list {none} {1st} {1st+2nd} ]
    set df [lindex $::fMRIEngine(derivOptions) 0 ]
    eval { menubutton $f.mbDeriv -text $df \
               -relief raised -bd 2 -width 15 \
               -indicatoron 1 \
               -menu $f.mbDeriv.m } $Gui(WMBA)
    eval {menu $f.mbDeriv.m } $Gui(WMA)
    foreach m $::fMRIEngine(derivOptions) {
        $f.mbDeriv.m add command -label $m \
            -command "fMRIEngineSelectNumDerivativesForSignalModeling $m"
    }
    set ::fMRIEngine(gui,derivativeMenuButtonForSignal) $f.mbDeriv

    blt::table $f \
        0,0 $f.lCond -padx 1 -pady 1 -anchor e \
        0,1 $f.mbType -fill x -padx 1 -pady 1 -anchor w \
        1,0 $f.lWave -padx 1 -pady 1 -anchor e \
        1,1 $f.mbType2 -fill x -padx 1 -pady 1 -anchor w \
        1,2 $f.bWaveHelp -padx 1 -pady 1 \
        2,0 $f.lConv -padx 1 -pady 1 -fill x -anchor e \
        2,1 $f.mbType3 -fill x -padx 1 -pady 1 -anchor w \
        2,2 $f.bConvHelp -padx 1 -pady 1 \
        3,0 $f.lDeriv -fill x -padx 1 -pady 1 -anchor e \
        3,1 $f.mbDeriv -padx 1 -pady 1 -anchor w \
        3,2 $f.bDerivHelp -padx 1 -pady 1
    
    #-------------------------------------------
    # Filtering frame 
    #-------------------------------------------
    set f $parent.fFiltering
    frame $f.fTitle    -bg $Gui(activeWorkspace)
    frame $f.fHighpass -bg $Gui(activeWorkspace) -relief groove -bd 1 
    #frame $f.fLowpass -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $f.fGlobalEffects -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $f.fActions  -bg $Gui(activeWorkspace)
    #commenting out lowpass frame 10/16/05
    #pack $f.fTitle $f.fHighpass $f.fLowpass $f.fGlobalEffects $f.fActions -side top -fill x -pady 1 -padx 1 
    pack $f.fTitle $f.fHighpass $f.fGlobalEffects $f.fActions -side top -fill x -pady 1 -padx 1 

    #-----------------------
    # Filtering->Title
    # Filtering->Highpass
    # Filtering->Lowpass
    # Filtering->GlobalEffects
    #-----------------------
    set f $parent.fFiltering.fTitle
    DevAddLabel $f.l "Nuissance signal modeling:" 
    pack $f.l -side top -pady 7 -fill x

    #--- highpass filter
    set f $parent.fFiltering.fHighpass
    DevAddLabel $f.lHighpass "Trend model:"
    DevAddButton $f.bHighpassHelp "?" "fMRIEngineHelpSetupHighpassFilter" 2 
    set highpassFilters [list {none} {Discrete Cosine}]
    set df [lindex $highpassFilters 0] 
    eval {menubutton $f.mbType -text $df \
          -relief raised -bd 2 -width 15 \
          -indicatoron 1 \
          -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)

    foreach m $highpassFilters  {
        $f.mbType.m add command -label $m \
            -command "fMRIEngineSelectTrendModelForSignalModeling \{$m\}" 
    }
    set fMRIEngine(gui,highpassMenuButtonForSignal) $f.mbType
    set fMRIEngine(gui,highpassMenuForSignal) $f.mbType.m
    set fMRIEngine(curHighpassForSignal) $df 

    #--- just wiring this in now... 10/04/05
    set ::fMRIEngine(curRunForSignal) 0
    DevAddLabel $f.lCutoff "Cutoff period:"
    eval {entry $f.eCutoff -width 18  \
        -textvariable fMRIEngine(entry,highpassCutoff) } $Gui(WEA)
    bind $f.eCutoff <Return> "fMRIEngineSelectCustomHighpassTemporalCutoff"
    set ::fMRIEngine(entry,highpassCutoff) "default"
    DevAddButton $f.bHighpassCutoffHelp "?" "fMRIEngineHelpSelectHighpassCutoff" 2 
    DevAddButton $f.bHighpassDefault "use default cutoff" "fMRIEngineSelectDefaultHighpassTemporalCutoff" 2
    set ::fMRIEngine(curHighpassCutoff) "default"
    blt::table $f \
        0,0 $f.lHighpass -padx 1 -pady 1 \
        0,1 $f.mbType -fill x -padx 1 -pady 1 \
        0,2 $f.bHighpassHelp -padx 1 -pady 1 \
        1,0 $f.lCutoff -padx 1 -pady 1 \
        1,1 $f.eCutoff -fill x -padx 1 -pady 1 \
        1,2 $f.bHighpassCutoffHelp -padx 1 -pady 1 \
        2,1 $f.bHighpassDefault -padx 1 -fill x -pady 1

    #comment out lowpass; forget temporal smoothing for now.
    if { 0 } {
        #--- lowpass filter
        #set f $parent.fFiltering.fLowpass
        #DevAddLabel $f.lLowpass "Lowpass:"
        #DevAddButton $f.bLowpassHelp "?" "fMRIEngineHelpSetupLowpassFilter" 2 
        #set lowpassFilters [list {none} {Gaussian}]
        #set df [lindex $lowpassFilters 0] 
        #eval {menubutton $f.mbType2 -text $df \
        #          -relief raised -bd 2 -width 15 \
        #         -indicatoron 1 \
        #        -menu $f.mbType2.m} $Gui(WMBA)
        #eval {menu $f.mbType2.m} $Gui(WMA)

        #foreach m $lowpassFilters  {
        #   $f.mbType2.m add command -label $m \
        #      -command "fMRIEngineSelectLowpassForSignalModeling \{$m\}" 
        #}
        #set fMRIEngine(gui,lowpassMenuButtonForSignal) $f.mbType2
        #set fMRIEngine(gui,lowpassMenuForSignal) $f.mbType2.m
        #set fMRIEngine(curLowpassForSignal) $df

        #DevAddLabel $f.lCutoff "FWHM (s):"
        #eval {entry $f.eCutoff -width 18 -state disabled \
        #          -textvariable fMRIEngine(entry,lowpassCutoff)} $Gui(WEA)
        #set ::fMRIEngine(entry,lowpassCutoff) 0.0
        #DevAddButton $f.bLowpassCutoffHelp "?" "fMRIEngineHelpSetupLowpassFilter" 2  
        #DevAddButton $f.bLowpassDefault "use default FWHM" "fMRIEngineSelectLowpassTemporalCutoff" 2
        #blt::table $f \
        #    0,0 $f.lLowpass -padx 1 -pady 1 \
        #   0,1 $f.mbType2 -fill x -padx 1 -pady 1 \
        #  0,2 $f.bLowpassHelp -padx 1 -pady 1 \
        #    1,0 $f.lCutoff -padx 1 -pady 1 \
        #   1,1 $f.eCutoff -fill x -padx 1 -pady 1 \
        #  1,2 $f.bLowpassCutoffHelp -padx 1 -pady 1 \
        #    2,1 $f.bLowpassDefault -padx 1 -fill x -pady 1
    }
    

    #--- remove global effects
    #--- why oh why does this checkbutton show up with sunken relief???
    set f $parent.fFiltering.fGlobalEffects
    DevAddLabel $f.lIntensity "Intensity:"

    eval {checkbutton $f.cGrandMean \
        -variable fMRIEngine(checkbuttonGrandMean) -width 18 \
        -relief flat -indicatoron 1 -text "grand mean" -anchor w } $Gui(WEA) 
    $f.cGrandMean select 
    DevAddButton $f.bGrandMeanHelp "?" "fMRIEngineHelpSetupGrandMeanFX" 2 

    eval {checkbutton $f.cGlobalMean \
        -variable fMRIEngine(checkbuttonGlobalMean) \
        -relief flat -indicatoron 1 -text "global mean" -anchor w } $Gui(WEA) 
    $f.cGlobalMean deselect 
    DevAddButton $f.bGlobalMeanHelp "?" "fMRIEngineHelpSetupGlobalMeanFX" 2 

    eval {checkbutton $f.cPrewhiten \
        -variable fMRIEngine(checkbuttonPreWhiten) \
        -relief flat -indicatoron 1 -text "pre-whiten data" -anchor w } $Gui(WEA) 
    DevAddButton $f.bPrewhitenHelp "?" "fMRIEngineHelpPreWhitenData" 2 
    $f.cPrewhiten deselect 
    
    blt::table $f \
        0,0 $f.lIntensity -padx 2 -pady 1 -anchor e \
        0,1 $f.cGrandMean -fill x -padx 1 -pady 1 -anchor e \
        0,2 $f.bGrandMeanHelp -padx 1 -pady 1 -anchor e \
        1,1 $f.cGlobalMean -fill x -padx 1 -pady 1 -anchor e \
        1,2 $f.bGlobalMeanHelp -padx 1 -pady 1 -anchor e \
        2,1 $f.cPrewhiten -fill x -padx 1 -pady 1 -anchor e \
        2,2 $f.bPrewhitenHelp -padx 1 -pady 1 -anchor e


    #-----------------------
    # Custom 
    #-----------------------
    set f $parent.fMoreModeling
    frame $f.fTitle    -bg $Gui(activeWorkspace)
    frame $f.fCustom -bg $Gui(activeWorkspace) -relief groove -bd 1 
    pack $f.fTitle $f.fCustom -side top -fill x -pady 1 -padx 0

    DevAddLabel $f.fTitle.lTitle "Additional modeling:" 
    pack $f.fTitle.lTitle -side top -pady 7 -fill x

    set f $parent.fMoreModeling.fCustom
    DevAddLabel $f.lCustom "Custom:"
    eval {entry $f.eCustom -width 18 -state disabled \
        -textvariable fMRIEngine(entry,custom)} $Gui(WEA)
    DevAddButton $f.bCustomHelp "?" "fMRIEngineHelpSetupCustomFX" 2 
    blt::table $f \
        0,0 $f.lCustom -padx 1 -pady 1 -anchor e \
        0,1 $f.eCustom -fill x -padx 1 -pady 1 -anchor e \
        0,2 $f.bCustomHelp -padx 1 -pady 1 -anchor e
    

    #-------------------------------------------
    # OK frame 
    #-------------------------------------------
    set f $parent.fOK
    DevAddButton $f.bOK "add to model" "fMRIEngineAddOrEditEV" 13 
    grid $f.bOK -padx 1 -pady 3 

    #-------------------------------------------
    # EVs frame 
    #-------------------------------------------
    #-----------------------
    # EV list 
    #-----------------------
    set f $parent.fEVs
    frame $f.fUp      -bg $Gui(activeWorkspace)
    frame $f.fMiddle  -bg $Gui(activeWorkspace)
    frame $f.fDown    -bg $Gui(activeWorkspace)
    pack $f.fUp $f.fMiddle $f.fDown -side top -fill x -pady 1 -padx 2 

    set f $parent.fEVs.fUp
    DevAddLabel $f.l "Specified explanatory variables:"
    grid $f.l -padx 1 -pady 3

    set f $parent.fEVs.fMiddle
    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    scrollbar $f.hs -orient horizontal -bg $Gui(activeWorkspace)
    set fMRIEngine(evsVerScroll) $f.vs
    set fMRIEngine(evsHorScroll) $f.hs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -yscrollcommand {$::fMRIEngine(evsVerScroll) set} \
        -xscrollcommand {$::fMRIEngine(evsHorScroll) set}
    set fMRIEngine(evsListBox) $f.lb
    $fMRIEngine(evsVerScroll) configure -command {$fMRIEngine(evsListBox) yview}
    $fMRIEngine(evsHorScroll) configure -command {$fMRIEngine(evsListBox) xview}

    blt::table $f \
        0,0 $fMRIEngine(evsListBox) -padx 1 -pady 1 \
        1,0 $fMRIEngine(evsHorScroll) -fill x -padx 1 -pady 1 \
        0,1 $fMRIEngine(evsVerScroll) -cspan 2 -fill y -padx 1 -pady 1

    #-----------------------
    # Action  
    #-----------------------
    set f $parent.fEVs.fDown
    DevAddButton $f.bView "Edit" "fMRIEngineShowEVToEdit" 6 
    DevAddButton $f.bDelete "Delete" "fMRIEngineDeleteEV" 6 
    grid $f.bView $f.bDelete -padx 2 -pady 3 


}




#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForModelEstimation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForModelEstimation {parent} {
    global Gui fMRIEngine
    
    frame $parent.fEstimate -bg $::Gui(activeWorkspace) -relief groove -bd 1
    frame $parent.fBetaVol -bg $::Gui(activeWorkspace) -relief groove -bd 1
    pack $parent.fEstimate $parent.fBetaVol -side top -fill x -pady 4 -padx 1

    #-------------------------------------------
    # Estimate frame 
    #-------------------------------------------
    set f $parent.fEstimate
    frame $f.fTop      -bg $::Gui(activeWorkspace)
    #frame $f.fBot    -bg $::Gui(activeWorkspace)
    #pack $f.fTop $f.fBot -side top -fill x -pady 1 -padx 2 
    pack $f.fTop -side top -fill x -pady 1 -padx 2 

    set f $parent.fEstimate.fTop
    #--- add a title
    DevAddLabel $f.lTitle "Estimate model:" 
    #--- add a label for choosing run
    DevAddLabel $f.lRun "Choose run(s):" 
    #--- add run menu
    set runList [list {none}]
    set df [lindex $runList 0] 
    eval {menubutton $f.mbWhichRun -text $df \
        -relief raised -bd 2 -width 9 \
        -indicatoron 1 \
        -menu $f.mbWhichRun.m} $::Gui(WMBA)
#    bind $f.mbWhichRun <1> "fMRIEngineUpdateRunsForModelFitting" 
    eval {menu $f.mbWhichRun.m} $::Gui(WMA)
    TooltipAdd $f.mbWhichRun "Specify which run is going to be used for LM model fitting.\
    \nSelect 'concatenated' if you have multiple runs and want to use them all."
    #--- Add menu items
    foreach m $runList  {
        $f.mbWhichRun.m add command -label $m \
            -command "fMRIEngineUpdateRunsForModelFitting" 
    }
    #--- add buttons for estimating
    DevAddButton $f.bWhichRunHelp "?" "fMRIENgineHelpEstimateWhichRun" 2
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetupEstimate" 2
    DevAddButton $f.bEstimate "Fit Model" "fMRIEngineFitModel" 15 
    DevAddButton $f.bSave "Save Beta" "fMRIEngineSaveBetaVolume" 15 
    DevAddButton $f.bLoad "Load Beta" "fMRIEngineLoadBetaVolume" 15 

    set fMRIEngine(curRunForModelFitting) run1 
    # Save menubutton for config
    set fMRIEngine(gui,runListMenuButtonForModelFitting) $f.mbWhichRun
    set fMRIEngine(gui,runListMenuForModelFitting) $f.mbWhichRun.m

    blt::table $f \
        0,0 $f.lTitle -padx 2 -pady 7 -anchor c -fill x \
        1,0 $f.lRun -padx 2 -pady 1 -anchor e \
        1,1 $f.mbWhichRun -padx 1 -pady 1 -anchor e -fill x \
        1,2 $f.bWhichRunHelp -padx 1 -pady 1 -anchor e \
        2,1 $f.bEstimate -padx 1 -pady 1 -anchor e -fill x \
        2,2 $f.bHelp -padx 1 -pady 1 -anchor e \
        3,1 $f.bSave -padx 1 -pady 1 -anchor e \
        4,1 $f.bLoad -padx 1 -pady 1 -anchor e 

#    set f $parent.fBetaVol.fBot
#    DevAddButton $f.bView "View Coefficients" "fMRIEngineViewCoefficients" 27 

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineLoadBetaVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineLoadBetaVolume {} {
    global fMRIEngine 

    if {$fMRIEngine(curRunForModelFitting) == "none"} {
        DevErrorWindow "Select a valid run for beta volume loading."
        return 
    }

    # Pvti file is the output of vtkXMLPImageDataWriter
    # Basically, pvti file is an xml header for the image data.
    # Vti file is the real image file whose contents are not 
    # human readable. There are probably multiple vti files.
    set fileType {{"PVTI" *.pvti}}
    set fileName [tk_getOpenFile -filetypes $fileType -parent .]

    if {[string length $fileName]} {

        # the following commands set some parameters for
        # contrast computation
        if { ! [ fMRIEngineCountEVs] } {
            return
        }
        set done [fMRIModelViewGenerateModel]
        if {! $done} {
            DevErrorWindow "Error in generating model for model fitting."
            return 
        }
        set run $fMRIEngine(curRunForModelFitting)
        fMRIEngineAddRegressors $run

        # read data from file
        if {[info commands fMRIEngine(pvtiReader)] != ""} {
            fMRIEngine(pvtiReader) Delete
            unset -nocomplain fMRIEngine(pvtiReader)
        }
        vtkXMLPImageDataReader fMRIEngine(pvtiReader)

        fMRIEngine(pvtiReader) SetFileName $fileName
        fMRIEngine(pvtiReader) Update
        set fMRIEngine(actBetaVolume) [fMRIEngine(pvtiReader) GetOutput]
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSaveBetaVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSaveBetaVolume {} {
    global fMRIEngine 

    if {! [info exists fMRIEngine(actBetaVolume)]} {
        DevErrorWindow "Estimate the model first."
        return
    }

    # write data to file
    set fileType {{"PVTI" *.pvti}}
    set fileName [tk_getSaveFile -filetypes $fileType -parent .]
    if {[string length $fileName]} {
        set pvti ".pvti"
        set ext [file extension $fileName]
        if {$ext != $pvti} {
            set fileName "$fileName$pvti"
        }

        if {[info commands fMRIEngine(pvtiWriter)] != ""} {
            fMRIEngine(pvtiWriter) Delete
            unset -nocomplain fMRIEngine(pvtiWriter)
        }
        vtkXMLPImageDataWriter fMRIEngine(pvtiWriter)

        fMRIEngine(pvtiWriter) SetInput $fMRIEngine(actBetaVolume)
        fMRIEngine(pvtiWriter) SetNumberOfPieces 1 
        fMRIEngine(pvtiWriter) SetFileName $fileName
        fMRIEngine(pvtiWriter) Write
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineViewCoefficients
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineViewCoefficients {} {
    global fMRIEngine 
 

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectRunForModelFitting
# 
# .ARGS
# string run
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectRunForModelFitting {run} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,runListMenuButtonForModelFitting) config -text $run
    if {$run == "concatenated" || $run == "none"} {
        set fMRIEngine(curRunForModelFitting) $run 
    } else {
        set r [string range $run 3 end]
        set fMRIEngine(curRunForModelFitting) $r 
    }
}




 
#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateRunsForModelFitting
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateRunsForModelFitting {} {
    global fMRIEngine 
 
    set fMRIEngine(noOfSpecifiedRuns) [$fMRIEngine(seqListBox) size] 

    $fMRIEngine(gui,runListMenuForModelFitting) delete 0 end
    set runs [$fMRIEngine(seqListBox) size] 
    if {$runs == 0} {
        fMRIEngineSelectRunForModelFitting none 
        $fMRIEngine(gui,runListMenuForModelFitting) add command -label none \
            -command "fMRIEngineSelectRunForModelFitting none"
    } else { 
        if {$runs > 1} {
            fMRIEngineSelectRunForModelFitting concatenated 
            $fMRIEngine(gui,runListMenuForModelFitting) add command -label concatenated \
                -command "fMRIEngineSelectRunForModelFitting concatenated"
        }

        set count 1
        while {$count <= $runs} {
            fMRIEngineSelectRunForModelFitting "run$count"
            $fMRIEngine(gui,runListMenuForModelFitting) add command -label "run$count" \
                -command "fMRIEngineSelectRunForModelFitting run$count"
            incr count
        }   
    }
}






#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectAllConditionsForSignalModeling
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectAllConditionsForSignalModeling { } {
    global fMRIEngine
    
    if { $fMRIEngine(checkbuttonApplyAllConditions) } {
        $fMRIEngine(gui,conditionsMenuButtonForSignal) config -text "all"
        set fMRIEngine(curConditionForSignal) "all"
        $fMRIEngine(gui,conditionsMenuButtonForSignal) config -text "all"
    } else {
        $fMRIEngine(gui,conditionsMenuButtonForSignal) config -text "none"
        set fMRIEngine(curConditionForSignal) "none"
        $fMRIEngine(gui,conditionsMenuButtonForSignal) config -text "none"
    }

    #--- which run are we talking about?
    set ::fMRIEngine(curRunForSignal) [ fMRIEngineGetRunForCurrentCondition ]

    #--- display the current selection for run's cosine transforms
    set r $::fMRIEngine(curRunForSignal)
    if { [info exists ::fMRIEngine(Design,Run$r,HighpassCutoff)] } {
        set ::fMRIEngine(entry,highpassCutoff) "default"
        #set ::fMRIEngine(entry,highpassCutoff) $::fMRIEngine(Design,Run$r,HighpassCutoff)
    } else {
        set ::fMRIEngine(entry,highpassCutoff) "default"
    }

}




#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectConditionForSignalModeling
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectConditionForSignalModeling { cond } {
    global fMRIEngine 
    #--- cancel the 'allconditions' button by selecting a condition from menu
    #--- and select the newly specified appropriate condition
    if { $cond == "all"} {
        set ::fMRIEngine(checkbuttonApplyAllConditions) 1
    } else {
        set ::fMRIEngine(checkbuttonApplyAllConditions) 0
    }
    #--- which run are we talking about?
    set fMRIEngine(curConditionForSignal) $cond
    $fMRIEngine(gui,conditionsMenuButtonForSignal) config -text $cond

    set ::fMRIEngine(curRunForSignal) [ fMRIEngineGetRunForCurrentCondition ]

    #--- display the current selection for run's cosine transforms
    set r $::fMRIEngine(curRunForSignal)
    if { ([info exists ::fMRIEngine(Design,Run$r,HighpassCutoff)]) && ($cond != "all") } {
        set ::fMRIEngine(entry,highpassCutoff) $::fMRIEngine(Design,Run$r,HighpassCutoff)
    } else {
        set ::fMRIEngine(entry,highpassCutoff) "default"
    }
}





#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateConditionsForSignalModeling
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateConditionsForSignalModeling { } {
    global fMRIEngine 

    #--- wjp 11/11/05 commenting out reset....
    #--- reset the checkbox. 
    #set ::fMRIEngine(checkbuttonApplyAllConditions) 0
    
    #--- regenerate conditions menu and callbacks
    $fMRIEngine(gui,conditionsMenuForSignal) delete 0 end 
    set start 1
    set end $fMRIEngine(noOfRuns)
    #--- list all conditions for each run...
    set firstCondition ""
    set i $start
    while {$i <= $end} {
        if {[info exists fMRIEngine($i,conditionList)]} {  
            set len [llength $fMRIEngine($i,conditionList)]
            set count 0
            while {$count < $len} {
                set title [lindex $fMRIEngine($i,conditionList) $count]
                set l "r$i:$title"
                $fMRIEngine(gui,conditionsMenuForSignal) add command -label $l \
                    -command "fMRIEngineSelectConditionForSignalModeling $l"
                if {$firstCondition == ""} {
                    set firstCondition $l
                }
                incr count
            }
        }
        incr i 
    }
    #--- add the none and all options onto the list at the end
    if {$firstCondition == ""} {
        set firstCondition "none"
        fMRIEngineSelectConditionForSignalModeling $firstCondition
        $fMRIEngine(gui,conditionsMenuForSignal) add command -label "none" \
            -command "fMRIEngineSelectConditionForSignalModeling none"
    }
    $fMRIEngine(gui,conditionsMenuForSignal) add command -label "all" \
        -command "fMRIEngineSelectConditionForSignalModeling all"            

    set cond [$fMRIEngine(gui,conditionsMenuForSignal) entrycget 0 -label]
    fMRIEngineSelectConditionForSignalModeling $cond

}





#-------------------------------------------------------------------------------
# .PROC fMRIEngineGetRunForCurrentCondition
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineGetRunForCurrentCondition { } {

    #--- this sets current run as 1 if all conditions are being
    #--- modeled the same way; returns 0 if no conditions are
    #--- currently selected, and pulls the run number out of haiying'
    #--- if some condition name is selected.
    set c $::fMRIEngine(curConditionForSignal)
    if { $c == "all" } {
        return 1
    } elseif { $c == "none" } {
        return 0
    } else {
        set i [ string first "r" $::fMRIEngine(curConditionForSignal) ]
        set j [ string first ":" $::fMRIEngine(curConditionForSignal) ]
        set start [ expr $i + 1]
        set stop [ expr $j - 1]
        if { $start <= $stop } {
            set currun [ string range $::fMRIEngine(curConditionForSignal) $start $stop ]
        }
        return $currun
    }
}






#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectWaveFormForSignalModeling
# 
# .ARGS
# string form
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectWaveFormForSignalModeling {form} {
    global fMRIEngine 

    # configure menubutton
    if { ($form == "Half Sine") && ($::fMRIEngine(paradigmDesignType) != "blocked") } {
        DevErrorWindow "Must use box-car waveform for event-related or mixed designs."
        return
    }
    $fMRIEngine(gui,waveFormsMenuButtonForSignal) config -text $form
    set fMRIEngine(curWaveFormForSignal) $form 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectConvolutionForSignalModeling
# 
# .ARGS
# string conv
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectConvolutionForSignalModeling {conv} {
    global fMRIEngine 

   # configure menubutton
    $fMRIEngine(gui,convolutionMenuButtonForSignal) config -text $conv
    set fMRIEngine(curConvolutionForSignal) $conv 
}



#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectNumDerivativesForSignalModeling
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectNumDerivativesForSignalModeling { option } {

    #--- can select one or two temporal derivative options for signal modeling.
    if { ($option == "none")  || ($option == 0) } {
        set ::fMRIEngine(numDerivatives) 0
    } elseif { ($option == "1st") || ($option == 1) } {
        set ::fMRIEngine(numDerivatives) 1
    } elseif { ($option == "1st+2nd") || ($option == 2) } {
        set ::fMRIEngine(numDerivatives) 2
    } else {
        set ::fMRIEngine(numDerivatives) 0
    }
    $::fMRIEngine(gui,derivativeMenuButtonForSignal) config -text $option
    set ::fMRIEngine(curDerivativesForSignal) $::fMRIEngine(numDerivatives)
}




#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowTrendModelForSignalModeling
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowTrendModelForSignalModeling { pass } {

    #--- configure menubutton; right now, the only trend model
    #--- we have available is a set of Discrete Cosine basis functions.
    #--- This routine sets the variable that configures a condition,
    #--- or configures ALL conditions, if they're to be modeled identically.
    $::fMRIEngine(gui,highpassMenuButtonForSignal) config -text $pass
    set ::fMRIEngine(curHighpassForSignal) $pass 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowDefaultHighpassTemporalCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowDefaultHighpassTemporalCutoff { } {

    #--- configures entry widget to reflect use of default temporal
    #--- trend model cutoff frequency
    set ::fMRIEngine(entry,highpassCutoff) "default"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowCustomHighpassTemporalCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowCustomHighpassTemporalCutoff { r } {

    #--- configures entry widget to reflect use of custom temporal
    #--- trend model cutoff frequency
    if {$::fMRIModelView(Design,Run$r,UseDCBasis) } {
        set ::fMRIEngine(entry,highpassCutoff) $::fMRIEngine(Design,Run$r,HighpassCutoff)
    }
}




#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectTrendModelForSignalModeling
# 
# .ARGS
# string pass
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectTrendModelForSignalModeling {pass} {
    global fMRIEngine 

    #--- configure menubutton; right now, the only trend model
    #--- we have available is a set of Discrete Cosine basis functions.
    #--- This routine sets the variable that configures a condition,
    #--- or configures ALL conditions, if they're to be modeled identically.
    fMRIEngineShowTrendModelForSignalModeling $pass
    if { $pass == "Discrete Cosine" } {
        set run $::fMRIEngine(curRunForSignal)
        set ::fMRIModelView(Design,Run$run,UseDCBasis) 1
        fMRIEngineSelectDefaultHighpassTemporalCutoff
    }

}



#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectDefaultHighpassTemporalCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectDefaultHighpassTemporalCutoff { } {

    #--- error checking...
    #--- set default cutoff frequency for the chosen highpass temporal filter
    set run $::fMRIEngine(curRunForSignal)
    if { [ info exists ::fMRIModelView(Design,Run$run,UseDCBasis)] } {
        if {$::fMRIModelView(Design,Run$run,UseDCBasis) == 0 } {
            DevErrorWindow "Please select trend model first."
            return
        }
    }
    if { ![ info exists ::fMRIEngine(curConditionForSignal) ]} {
        DevErrorWindow "Either no runs have been defined or no condition is selected."
        fMRIEngineShowDefaultHighpassTemporalCutoff
        return
    }
    if { $run <= 0 } {
        DevErrorWindow "No runs have been defined yet!"
        #--- reset widget to default state
        fMRIEngineShowDefaultHighpassTemporalCutoff
        return
    }
    #--- setting default conditions...
    fMRIEngineShowDefaultHighpassTemporalCutoff

    #---11/15/05 try this instead
    set ::fMRIEngine(curUseCustomCutoff) 0
    set ::fMRIEngine(curHighpassCutoff) "default"

}





#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectCustomHighpassTemporalCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectCustomHighpassTemporalCutoff { } {

    #--- error checking
    set run $::fMRIEngine(curRunForSignal)
    if { $run <= 0 } {
        DevErrorWindow "No runs have been defined yet! No parameters set."
        #--- reset widget to default state
        fMRIEngineShowDefaultHighpassTemporalCutoff
        return
    }
    if { [ info exists ::fMRIModelView(Design,Run$run,UseDCBasis)] } {
        if {$::fMRIModelView(Design,Run$run,UseDCBasis) == 0 } {
            DevErrorWindow "Please select trend model first."
            return
        }
    }
    if { ($::fMRIEngine(entry,highpassCutoff) == "default") ||
     ($::fMRIEngine(entry,highpassCutoff) == "Default") ||
     ($::fMRIEngine(entry,highpassCutoff) == "DEFAULT") } {
        fMRIEngineSelectDefaultHighpassTemporalCutoff
        return
    }
    #--- more error checking and setting custom value
    if { $::fMRIEngine(entry,highpassCutoff) != "default" } {
        set tst $::fMRIEngine(entry,highpassCutoff)
        if { (! [ string is integer -strict $tst]) && (! [ string is double -strict $tst]) } {
            DevErrorWindow "Cutoff period must be either an integer or floating point value"
            fMRIEngineSelectDefaultHighpassTemporalCutoff 
            return
        }
        if { $tst == 0 || $tst == 0.0 } {
            DevErrorWindow "Cutoff period should be non-zero."
            fMRIEngineSelectDefaultHighpassTemporalCutoff 
            return
        }

        #---11/15/05 try this instead
        set ::fMRIEngine(curUseCustomCutoff) 1
        set ::fMRIEngine(curHighpassCutoff) $::fMRIEngine(entry,highpassCutoff)
    }
}






#-------------------------------------------------------------------------------
# .PROC fMRIEngineComputeDefaultHighpassTemporalCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineComputeDefaultHighpassTemporalCutoff { r } {

    #--- Here's how the default cutoff frequency is computed:
    #--- Presume T = 1/f_lowest, is the longest epoch spacing in the run.
    #--- fmin is the cutoff frequency of the high-pass filter (lowest frequency
    #--- that we let pass through. Choose to let fmin = 0.666666/T (just less than the
    #--- lowest frequency in paradigm). As recommended in S.M. Smith, "Preparing fMRI
    #--- data for statistical analysis, in 'Functional MRI, an introduction to methods', Jezzard,
    #--- Matthews, Smith Eds. 2002, Oxford University Press.

    if { [ fMRIModelViewLongestEpochSpacing $r ] } {
        #--- T is the number of seconds in the longest epoch
        set T $::fMRIModelView(Design,Run$r,longestEpoch)
        #--- set the model parameter, cutoff Period
        set ::fMRIEngine(Design,Run$r,HighpassCutoff)  [ expr 1.5 * $T ]
        #--- update the GUI
        if { $::fMRIEngine(checkbuttonApplyAllConditions) } {
            set ::fMRIEngine(entry,highpassCutoff) "default"
        } else {
            set ::fMRIEngine(entry,highpassCutoff) $::fMRIEngine(Design,Run$r,HighpassCutoff)
        }
        #set ::fMRIEngine(entry,highpassCutoff) $::fMRIEngine(Design,Run$r,HighpassCutoff)
    } else {
        #--- set the model parameter
        set ::fMRIEngine(Design,Run$r,HighpassCutoff) 0.0
        #--- update the GUI
        #set ::fMRIEngine(entry,highpassCutoff) 0.0
    }
}



#-------------------------------------------------------------------------------
proc fMRIEngineSelectLowpassForSignalModeling {pass} {
    global fMRIEngine 

   #--- configure menubutton
   # configure menubutton
    $fMRIEngine(gui,lowpassMenuButtonForSignal) config -text $pass
    set fMRIEngine(curLowpassForSignal) $pass
    fMRIEngineSelectLowpassTemporalCutoff
}




#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectLowpassTemporalCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectLowpassTemporalCutoff { } {
    global fMRIEngine 

    #--- set default cutoff frequency for the lowpass temporal filter
    if { [ info exists ::fMRIModelView(Design,Run1,TR) ] } {
        set ::fMRIModelView(Design,LowpassCutoff) $::fMRIModelView(Design,Run1,TR)
    } else {
        DevErrorWindow "Lowpass: Specify run(s) and condition(s) before modeling."
        set ::fMRIModelView(Design,LowpassCutoff) 0.0
    }
}






#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddOrEditEV
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddOrEditEV {} {
    global fMRIEngine 

    set con $fMRIEngine(curConditionForSignal)
    if { ($con == "none") && (!$fMRIEngine(checkbuttonApplyAllConditions)) } {
        DevErrorWindow "Select a valid condition."
        return
    }
    #--- wjp 11/02/05
    #--- if current condition is "all", then just pick the first in the list.
    if {$con == "all"} {
        set conditiontitle [lindex $fMRIEngine(1,conditionList) 0 ]
        set con "r1:$conditiontitle"
    }

    set wform $fMRIEngine(curWaveFormForSignal) 
    set conv  $fMRIEngine(curConvolutionForSignal) 
    
    #--- wjp 09/01/06
    set deriv $fMRIEngine(curDerivativesForSignal)
    #set deriv $fMRIEngine(checkbuttonTempDerivative) 
    set hpass $fMRIEngine(curHighpassForSignal)
    #set lpass $fMRIEngine(curLowpassForSignal) 
    set effes 0
    #set ev "$con:$wform:$conv:$deriv:$hpass:$lpass:$effes"
    set ev "$con:$wform:$conv:$deriv:$hpass:$effes"
    
    if { 0 } {
    if {[info exists fMRIEngine($ev,ev)]} {
        DevErrorWindow "This EV already exists:\n$ev"
        if {! $fMRIEngine(checkbuttonApplyAllConditions)} {
            return
        }
    }
    }

    #--- Deleting evs from the evlistbox
    #--- that use the same condition...
    set i 0
    set found -1 
    set index -1
    set size [$fMRIEngine(evsListBox) size]
    while {$i < $size} {  
        set v [$fMRIEngine(evsListBox) get $i] 
        if {$v != ""} {
            if {! $fMRIEngine(checkbuttonApplyAllConditions)} {
                #--- If adding an edited version of the EV, find old
                #--- version and delete it  remove it;
                set found [string first $con $v]
                if {$found >= 0} {
                    fMRIEngineDeleteEV $i
                    break
                }
            } else {
                set found [string first "baseline" $v]
                #--- else, if adding or editing evs for all conditions,
                #--- delete all EVs but baselines; We'll add each of these
                #--- again with their new modeling specifications.
                if {$found == -1} {
                    $fMRIEngine(evsListBox) delete $i end 
                    break
                }
            }
        } 
        incr i
    }

    # add EVs
    set j 0
    set end [$fMRIEngine(gui,conditionsMenuForSignal) index end] 
    while {$j <= $end} {  
        set v [$fMRIEngine(gui,conditionsMenuForSignal) entrycget $j -label] 
        if { ($v != "") && ($v != "all") && ($v != "none") } {
            set i 1 
            set i2 [string first ":" $v]
            set run [string range $v $i [expr $i2-1]] 
            set run [string trim $run]
            set title [string range $v [expr $i2+1] end] 
            set title [string trim $title]

            #set ev "$v:$wform:$conv:$deriv:$hpass:$lpass:$effes"
            set ev "$v:$wform:$conv:$deriv:$hpass:$effes"

            if {$fMRIEngine(checkbuttonApplyAllConditions) ||
                ((! $fMRIEngine(checkbuttonApplyAllConditions)) && $con == $v)} {

                set fMRIEngine($ev,ev)               $ev
                set fMRIEngine($ev,run)              $run
                set fMRIEngine($ev,title,ev)         $title
                set fMRIEngine($ev,condition,ev)     $v
                set fMRIEngine($ev,waveform,ev)      $wform
                set fMRIEngine($ev,convolution,ev)   $conv
                set fMRIEngine($ev,derivative,ev)    $deriv
                set fMRIEngine($ev,highpass,ev)      $hpass
                #set fMRIEngine($ev,lowpass,ev)       $lpass
                set fMRIEngine($ev,globaleffects,ev) $effes
                set fMRIEngine($ev,highpassCutoff,ev) $::fMRIEngine(curHighpassCutoff)

                $fMRIEngine(evsListBox) insert end $ev
            }
        } 

        incr j 
    }
    set ::fMRIEngine(SignalModelDirty) 1
} 


#-------------------------------------------------------------------------------
# .PROC fMRIEngineDeleteEV
# 
# .ARGS
# int index defaults to -1
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineDeleteEV {{index -1}} {
    global fMRIEngine 

    if {$index == -1} {
        set curs [$fMRIEngine(evsListBox) curselection]
    } else {
        set curs $index
    }

    if {$curs != ""} {
        set ev [$fMRIEngine(evsListBox) get $curs] 
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
            unset -nocomplain fMRIEngine($ev,highpassCutoff,ev) 
        }

        $fMRIEngine(evsListBox) delete $curs 
    } else {
        DevErrorWindow "Select an EV to delete."
    }
    set ::fMRIEngine(SignalModelDirty) 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowEVToEdit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowEVToEdit {} {
    global fMRIEngine 

    set curs [$fMRIEngine(evsListBox) curselection]
    if {$curs != ""} {
        set ev [$fMRIEngine(evsListBox) get $curs] 
        if {$ev != "" &&
            [info exists fMRIEngine($ev,ev)]} {
            #--- update gui to reflect parameters of current ev's signal
            fMRIEngineSelectConditionForSignalModeling   $fMRIEngine($ev,condition,ev)
            fMRIEngineSelectWaveFormForSignalModeling    $fMRIEngine($ev,waveform,ev)   
            fMRIEngineSelectConvolutionForSignalModeling $fMRIEngine($ev,convolution,ev)
            #fMRIEngineSelectNumDerivativesForSignalModeling $fMRIEngine($ev,derivative,ev)
            set m [ lindex $::fMRIEngine(derivOptions) $::fMRIEngine($ev,derivative,ev) ]
            fMRIEngineSelectNumDerivativesForSignalModeling $m
            fMRIEngineShowTrendModelForSignalModeling    $fMRIEngine($ev,highpass,ev) 
            #--- this was computed post-input, so is represented differently from others
            fMRIEngineShowCustomHighpassTemporalCutoff $::fMRIEngine(curRunForSignal)
            #fMRIEngineSelectLowpassForSignalModeling     $fMRIEngine($ev,lowpass,ev) 
            #--- wjp 09/06/05
            set fMRIEngine(numDerivatives) $fMRIEngine($ev,derivative,ev)
            #set fMRIEngine(checkbuttonTempDerivative) $fMRIEngine($ev,derivative,ev)
            set fMRIEngine(checkbuttonGlobalEffects)  $fMRIEngine($ev,globaleffects,ev) 
            #--- need to update gui with DCBasis info
            set fMRIEngine(entry,highpassCutoff) $fMRIEngine($ev,highpassCutoff,ev) 
        }
    } else {
        DevErrorWindow "Select an EV to edit." 
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddInputVolumes
# 
# .ARGS
# string run
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddInputVolumes {run} {
    global MultiVolumeReader fMRIEngine

    if {$run == "none"} {
        return
   }

    set start $run
    set last $run
    if {$run == "concatenated"} {
        set start 1
        set last [$fMRIEngine(seqListBox) size] 
    }

    set fMRIEngine(totalVolsForModelFitting) 0
    for {set r $start} {$r <= $last} {incr r} { 
        set seqName $fMRIEngine($r,sequenceName)
        set id $MultiVolumeReader($seqName,firstMRMLid)
        set id2 $MultiVolumeReader($seqName,lastMRMLid)
        # puts "id = $id"
        # puts "id2 = $id2"
        while {$id <= $id2} {
            Volume($id,vol) Update
            fMRIEngine(actEstimator) AddInput [Volume($id,vol) GetOutput]
            incr fMRIEngine(totalVolsForModelFitting)
 
            incr id
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCheckMultiRuns
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCheckMultiRuns {} {
    global fMRIEngine

    # check number of condition EVs
    for {set r 2} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        if {$fMRIEngine($r,noOfEVs) != $fMRIEngine(1,noOfEVs)} {
            DevErrorWindow "Run1 and run$r are not equal in number of condition EVs."
            return 1
        }
    }

    # check types of condition EVs
    for {set r 2} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        foreach n1 $fMRIEngine(1,namesOfEVs) \
                n2 $fMRIEngine($r,namesOfEVs) {
            if {! [string equal -nocase $n1 $n2]} {
                DevErrorWindow "The names of condition EVs differ between Run1 and run$r."
                return 1
            }
        }
    }

    return 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddRegressors
# 
# .ARGS
# string run
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddRegressors {run} {
    global MultiVolumeReader fMRIEngine fMRIModelView 

    if {$run == "none"} {
        return 1
    }

    if {[info commands fMRIEngine(designMatrix)] != ""} {
        fMRIEngine(designMatrix) Delete
        unset -nocomplain fMRIEngine(designMatrix)
    }
    vtkFloatArray fMRIEngine(designMatrix)

    #--- Additional EVs: baseline and DCBasis for each run...
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        set fMRIEngine($r,totalEVs) [expr $fMRIEngine($r,noOfEVs)]
        if {$::fMRIModelView(Design,Run$r,UseBaseline)} {
            incr fMRIEngine($r,totalEVs)
        }
        if {$::fMRIModelView(Design,Run$r,UseDCBasis)} {
            set fMRIEngine($r,totalEVs) [expr $fMRIEngine($r,totalEVs) + \
                                            $::fMRIEngine(Design,Run$r,numCosines) ]
        }
    }
    #--- if runs are being analyzed separately...
    if {$run != "concatenated"} {
        # single run
        set ::fMRIEngine($run,totalEVs) [ expr int ($::fMRIEngine($run,totalEVs)) ]
        fMRIEngine(designMatrix) SetNumberOfComponents $fMRIEngine($run,totalEVs)
        set seqName $fMRIEngine($run,sequenceName)
        set vols $MultiVolumeReader($seqName,noOfVolumes) 
        fMRIEngine(designMatrix) SetNumberOfTuples $vols

        for {set j 0} {$j < $vols} {incr j} { 
            for {set i 0} {$i < $fMRIEngine($run,totalEVs)} {incr i} { 
                set index [expr $i+1]
                set data $fMRIModelView(Data,Run$run,EV$index,EVData)
                set e [lindex $data $j]
                fMRIEngine(designMatrix) InsertComponent $j $i $e 
            }
        }
    } else {
        # runs are being concatenated together and analyzed together.
        if {[fMRIEngineCheckMultiRuns] == 1} {
            return 1
        }

        #--- How many columns are in the design matrix when we are combining
        #--- multiple runs into the same analysis?
        #--- * We will concatenate matching conditions into one design matrix column.
        #--- * We will concatenate matching condition derivatives into one design matrix column.
        #---    (Actually, we should take a new derivative of each concatenated condition.)
        #--- * We must keep the means for each run in an independent design matrix column.
        #--- * We must keep the basis functions modeling nuissance signals (i.e. Discrete Cosines)
        #---    for each run in an independent design matrix column.
        #--- SO: total number of columns for concatenated analysis = number of condition EVs +
        #--- number of runs (for the means) + number of DCbasis functions for each run.

        #--- count up number of columns the design matrix needs for concatenated runs
        set numcols [expr $fMRIEngine(1,noOfEVs)]
        for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
            #--- add a column for the mean for this run.
            if {$::fMRIModelView(Design,Run$r,UseBaseline)} {
                incr numcols
            }
            #--- add columns for the basis functions for this run
            if {$::fMRIModelView(Design,Run$r,UseDCBasis)} {
                set numcols [expr $numcols + [ expr int ($::fMRIEngine(Design,Run$r,numCosines))] ]
            }
        }
        fMRIEngine(designMatrix) SetNumberOfComponents $numcols
        
        set vols 0
        for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
            set seqName $fMRIEngine($r,sequenceName)
            set vols [expr $MultiVolumeReader($seqName,noOfVolumes) + $vols]
        }
        fMRIEngine(designMatrix) SetNumberOfTuples $vols
        
        #--- Now make a set of long data arrays for the concatenated condition-related data
        #--- and a set of long data arrays with the mean and basis functions inserted
        #--- at the right timepoint.
        #--- data arrays for conditions (with signal inserted):
        set startcol 1
        set stopcol $::fMRIEngine(1,noOfEVs)

        for { set i $startcol } { $i <= $stopcol } { incr i } {
            set data ""
            for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
                set data [concat $data $fMRIModelView(Data,Run$r,EV$i,EVData)]
            }
            set fMRIEngine($i,concatenatedEVs) $data
        }

        #--- Now make a set of data arrays for the means and basis functions.
        #--- data arrays for for baseline and basis functions; fill with zeros:
        set startcol [ expr $stopcol + 1 ]
        set stopcol $numcols
        for {set i $startcol } {$i <= $stopcol } {incr i} {
            set data ""
            for { set t 0 } { $t < $vols } { incr t } {
                lappend data 0.0
            }
            set fMRIEngine($i,concatenatedEVs) $data                         
        }

        #--- insert baseline and basis functions for each run into data arrays
        set col $startcol
        set offset 0
        for {set r 1 } {$r <= $::fMRIEngine(noOfSpecifiedRuns) } {incr r} {
            set runlen [ llength $fMRIModelView(Data,Run$r,EV1,EVData)]
            #--- insert the baseline and move to next data array:
            set ev [ expr $::fMRIEngine($r,noOfEVs) + 1 ]
            set newvals $::fMRIModelView(Data,Run$r,EV$ev,EVData)
            set end [ expr $offset + $runlen ]
            set j 0
            set i $offset
            while { $i < $end } {
                set newval [ lindex $::fMRIModelView(Data,Run$r,EV$ev,EVData) $j ]
                set ::fMRIEngine($col,concatenatedEVs) [lreplace \
                                                            $::fMRIEngine($col,concatenatedEVs) \
                                                            $i $i $newval]
                incr i
                incr j
            }
            incr col
            incr ev
            #--- insert each basisfunction and move to next data array:
            set num $::fMRIEngine(Design,Run$r,numCosines)
            for { set count 0 } { $count < $num } { incr count } {
                set newvals $::fMRIModelView(Data,Run$r,EV$ev,EVData)
                set end [ expr $offset + $runlen ]
                set j 0
                set i $offset
                while { $i < $end } {
                    set newval [ lindex $::fMRIModelView(Data,Run$r,EV$ev,EVData) $j ]
                    set ::fMRIEngine($col,concatenatedEVs) [lreplace \
                                                                $::fMRIEngine($col,concatenatedEVs) \
                                                                $i $i $newval]
                    incr i
                    incr j
                }
                incr col
                incr ev
            }
            #--- compute the offset in the data array
            set offset [ expr $offset + $runlen ]
        }

        #--- Now add all that data into the design matrix.
        #--- order of columns will be:
        #--- cond1-condN, baseline1, basis1-basisM, baseline2, basis 2-basisM, etc.
        #--- Will have to re-interpret contrast vector to match this.

        for { set i 0 } { $i < $numcols } { incr i } {
            for {set j 0} {$j < $vols} {incr j} {
                set index [expr $i+1]
                set data $fMRIEngine($index,concatenatedEVs)
                set e [lindex $data $j]
                fMRIEngine(designMatrix) InsertComponent $j $i $e 
            }
        }
        #--- end of wjp 11/07/05 changes.
    }
    return 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCountEVs
# Counts real EVs for each run
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCountEVs {} {
    global fMRIEngine

    #--- wjp 09/02/05 changed derivative modeling
    # cleaning up
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
        set ::fMRIModelView(Design,Run$r,UseBaseline) 0
        set ::fMRIModelView(Design,Run$r,UseDCBasis) 0 
        unset -nocomplain fMRIEngine($r,noOfEVs)
        unset -nocomplain fMRIEngine($r,namesOfEVs)
        unset -nocomplain fMRIEngine($r,namesOfConditionEVs)
    }

    # how many real (not including baseline and DCBasis) evs for each run
    set i 0
    set size [$fMRIEngine(evsListBox) size]
    while {$i < $size} {  
        set ev [$fMRIEngine(evsListBox) get $i]
        unset -nocomplain namelist
        if {$ev != ""} {
            set found [string first "baseline" $ev]
            if {$found >= 0} {
                # baseline ev
                set i1 1 
                set i2 [string first ":" $ev]
                set r [string range $ev $i1 [expr $i2-1]] 
                set r [string trim $r]
                set ::fMRIModelView(Design,Run$r,UseBaseline) 1
            } else { 
                set run $fMRIEngine($ev,run)
                set wform $fMRIEngine($ev,waveform,ev)   
                set conv  $fMRIEngine($ev,convolution,ev)
                set deriv $fMRIEngine($ev,derivative,ev)
                set hpass $fMRIEngine($ev,highpass,ev)
                set cutoff $fMRIEngine($ev,highpassCutoff,ev)
                set title $fMRIEngine($ev,title,ev)
                set mycon [ lsearch $::fMRIEngine($run,conditionList) $title ]
                incr mycon
                
                #--- wjp 09/02/05
                #--- accrue names of EVs for each run inside each
                #--- individual case; and count up number of EVs
                #--- for each run inside each case too. Made this change
                #--- because adding derivatives ADDS more EVs
                #--- instead of REPLACING the original paradigm signal,
                #--- which is how we mistakenly implemented it at first.
                #--- EV signal type: tedious, but try it for now...
                #--- First, if we're NOT using temporal derivatives in modeling...
                if { $deriv == 0 } {
                    if {$conv == "none"} {
                        if {$wform == "Box Car"} {
                            set wf "boxcar"
                        } else {
                            set wf "halfsine"
                        }
                    } else {
                        if {$wform == "Box Car"} {
                            set wf "boxcar_cHRF"
                        } else {
                            set wf "halfsine_cHRF"
                        }
                    }
                    #--- append name, count ev, and set signal type
                    lappend namelist $title
                    #--- add the namelist to fMRIEngine($r,namesOfEVs)
                    fMRIEngineAppendEVNamesToRun $run $namelist
                    fMRIEngineIncrementEVCountForRun $run 1
                    set fMRIEngine($run,$title,signalType) $wf                    
                    set ::fMRIEngine($run,$title,myCondition) $mycon
                } else { 
                    #--- Now if we ARE using temporal derivatives in modeling
                    if {$conv == "none"} {
                        #--- using derivatives without convolution
                        if {$wform == "Box Car"} {
                            set base "boxcar"
                            if { $deriv == 1 } {
                                set wf "boxcar_dt1"
                                #--- append names, count ev, and set signal type
                                lappend namelist $title ${title}_dt1
                                set numevs 2
                            } elseif { $deriv == 2 } {
                                set wf "boxcar_dt2"
                                lappend namelist $title ${title}_dt1 ${title}_dt2
                                set numevs 3
                            } elseif { $deriv == 3 } {
                                set wf "boxcar _dt3"
                                lappend namelist $title ${title}_dt1 ${title}_dt2 ${title}_dt3
                                set numevs 4
                            }
                        } else {
                            set base "halfsine"
                            if { $deriv == 1 } {
                                set wf "halfsine_dt1"
                                lappend namelist $title ${title}_dt1
                                set numevs 2
                            } elseif { $deriv == 2 } {
                                set wf "halfsine_dt2"
                                lappend namelist $title ${title}_dt1 ${title}_dt2
                                set numevs 3
                            } elseif { $deriv == 3 } {
                                set wf "halfsine_dt3"
                                lappend namelist $title ${title}_dt1 ${title}_dt2 ${title}_dt3
                                set numevs 4
                            }
                        }
                    } else {
                        #--- using derivatives and convolution
                        if {$wform == "Box Car"} {
                            set base "boxcar_cHRF"
                            if { $deriv == 1 } {
                                set wf "boxcar_cHRF_dt1"
                                lappend namelist $title ${title}_dt1
                                set numevs 2
                            } elseif { $deriv == 2 } {
                                set wf "boxcar_cHRF_dt2"
                                lappend namelist $title ${title}_dt1 ${title}_dt2
                                set numevs 3
                            } elseif { $deriv == 3 } {
                                set wf "boxcar _cHRF_dt3"
                                lappend namelist $title ${title}_dt1 ${title}_dt2 ${title}_dt3
                                set numevs 4
                            }
                        } else {
                            set base "halfsine_cHRF"
                            if { $deriv == 1 } {
                                set wf "halfsine_cHRF_dt1"
                                lappend namelist $title ${title}_dt1
                                set numevs 2
                            } elseif { $deriv == 2 } {
                                set wf "halfsine_cHRF_dt2"
                                lappend namelist $title ${title}_dt1 ${title}_dt2
                                set numevs 3
                            } elseif { $deriv == 3 } {
                                set wf "halfsine_cHRF_dt3"
                                lappend namelist $title ${title}_dt1 ${title}_dt2 ${title}_dt3
                                set numevs 4
                            }
                        }
                    }
                    fMRIEngineAppendEVNamesToRun $run $namelist
                    fMRIEngineIncrementEVCountForRun $run $numevs
                    set ::fMRIEngine($run,$title,myCondition) $mycon                    
                    fMRIEngineAddDerivativeSignalsToRun  $run $title $base $deriv $mycon
                }
                # DCBasis
                if {$hpass == "Discrete Cosine"} {
                    set ::fMRIModelView(Design,Run$run,UseDCBasis) 1
                    #--- we are flagging this here, but not counting the basis functions yet.
                    #---WJP: 09/15/05
                    #lappend fMRIEngine($run,namesOfEVs) $title
                    #if {! [info exists fMRIEngine($run,noOfEVs)]} {
                    #    set fMRIEngine($run,noOfEVs) 1
                    #} else {
                    #    incr fMRIEngine($run,noOfEVs) 
                    #}
                }
                #--- set the highpass cutoff.
                set run $::fMRIEngine($ev,run)
                if { $cutoff == "default" } {
                    set ::fMRIEngine(Design,Run$run,useCustomCutoff) 0
                    set ::fMRIEngine(Design,Run$run,HighpassCutoff) $cutoff
                } else {
                    set ::fMRIEngine(Design,Run$run,useCustomCutoff) 1
                    set ::fMRIEngine(Design,Run$run,HighpassCutoff) $cutoff
                }
            }

            #--- end if ev != baseline
        }
        #-- end if ev != ""
        incr i
    }

    # if signal modeling has not been done yet but the user wants 
    # to view the design, warn him/her.
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        if {! [info exists fMRIEngine($r,namesOfEVs)]} {
            DevErrorWindow "Complete signal modeling first for run$r."
            return 0
        }
    }


    #--- Re-order the name lists of all runs to match the order of EVs
    #--- in the first run. This organizes the design matrix so that
    #--- appropriate EVs from each run are concatenated in analysis.
    for {set r 2} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
        unset -nocomplain names
        foreach name $fMRIEngine(1,namesOfEVs) {
            set found [lsearch -exact $fMRIEngine($r,namesOfEVs) $name]
            if {$found >= 0} {
                lappend names $name
                # delete it from the list of run r
                set fMRIEngine($r,namesOfEVs) \
                    [lreplace $fMRIEngine($r,namesOfEVs) $found $found]
            }
        }
        if { ! [ info exists names] } {
            DevErrorWindow "Runs can't be concatenated; EV names across runs may differ."
            return 0
        } else {
            set fMRIEngine($r,namesOfEVs) [concat $names $fMRIEngine($r,namesOfEVs)]
        }
    }

    #--- wjp add: this lists EVs that are associated only with conditions
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        foreach name $::fMRIEngine($r,namesOfEVs) {
            set deriv [ string first "_dt" $name ]
            set bline [ string first "baseline" $name ]
            set basis [ string first "DCbasis" $name ]
            if { ($deriv < 0 ) && ( $bline < 0 ) && ( $basis < 0 ) } {
                lappend ::fMRIEngine($r,namesOfConditionEVs) $name
            }
        }
    }

    return 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAppendEVNamesToRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAppendEVNamesToRun { run namelist } {

    # Append list of  names of EVs for each run.
    foreach n $namelist {
        lappend ::fMRIEngine($run,namesOfEVs) $n
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineIncrementEVCountForRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineIncrementEVCountForRun { run numToAdd } {

    # Count number of EVs for each run
    if {! [info exists ::fMRIEngine($run,noOfEVs)]} {
        set ::fMRIEngine($run,noOfEVs) $numToAdd
    } else {
        set ::fMRIEngine($run,noOfEVs) [expr $::fMRIEngine($run,noOfEVs) + $numToAdd ]
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddDerivativeSignalsToRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddDerivativeSignalsToRun { run title base derivnum condition } {

    #--- Recording the signal type of each derivative signal and
    #--- associating these derivative signals (used in the linear regression)
    #--- with the condition for which they are modeling latency.
    #--- We do this because the derivative signals are generated by
    #--- first building the waveform with appropriately specified onsets and
    #--- durations, and THEN taking the derivative(s) of it.
    set ::fMRIEngine($run,$title,signalType) $base
    if { $derivnum > 0 } {
        set ::fMRIEngine($run,${title}_dt1,signalType) "${base}_dt1"
        set ::fMRIEngine($run,${title}_dt1,myCondition) $condition
    }
    if {$derivnum > 1 } {
        set ::fMRIEngine($run,${title}_dt2,signalType) "${base}_dt2"
        set ::fMRIEngine($run,${title}_dt2,myCondition) $condition
    }
    if {$derivnum > 2 } {
        set ::fMRIEngine($run,${title}_dt3,signalType) "${base}_dt3"
        set ::fMRIEngine($run,${title}_dt3,myCondition) $condition
    }
}



#-------------------------------------------------------------------------------
# .PROC fMRIEngineCombineRunDerivativeCheck
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCombineRunDerivativeCheck { } {
    

    #--- currently, don't do any checking.
    #--- instead, we rely on the text in the help button
    #--- in estimation panel to guide user to specify the
    #--- modeling correctly.
    #--- Eventually, please build this check into code.
    #--- successful
    return 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateProgressText
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateProgressText {} {
    global fMRIEngine Gui 

    incr fMRIEngine(progressCount)
    MainShowProgress fMRIEngine(actEstimator)

    # The progress event of vtkGLMEstimator (new fMRIEngine(actEstimator)) is 
    # composed of two parts: first part is for computing means and the second
    # part is for glm. Each part has 100 steps. When the count reachs 100, it 
    # means computing means is done and then we update the progress text for 
    # glm computing.
    if {$fMRIEngine(progressCount) == 100 && $Gui(progressText) != $fMRIEngine(glmProgressText)} {
        puts "...done"
        set Gui(progressText) $fMRIEngine(glmProgressText) 
        puts $Gui(progressText)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineFitModel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineFitModel {} {
    global fMRIEngine Gui Volume MultiVolumeReader

    if {$fMRIEngine(curRunForModelFitting) == "none"} {
        DevErrorWindow "Select a valid run for model fitting."
        return 
    }

    if {$fMRIEngine(noOfSpecifiedRuns) == 0} {
        DevErrorWindow "No run has been specified."
        return
    }

    if { ! [ fMRIEngineCountEVs] } {
        return
    }

    set start $fMRIEngine(curRunForModelFitting)
    set last $start
    if {$start == "concatenated"} {
        set start 1
        set last $fMRIEngine(noOfSpecifiedRuns)
        #--- check to see if all condition EVs have same
        #--- number of derivatives across runs:
        #--- if run1: ev1 has 2 derivatives, run2: ev2 should have 2
        #--- so runs concatenate properly. If not, error and return.
        set chk [ fMRIEngineCombineRunDerivativeCheck ]
        if { $chk == 0 } {
            DevErrorWindow "To concatenate them, corresponding conditions should be modeled with same number of derivatives across runs."
            return
        }
    }
    for {set r $start} {$r <= $last} {incr r} { 
        if {! [info exists fMRIEngine($r,noOfEVs)]} {
            DevErrorWindow "Complete signal modeling first for run$r."
            return
        }
    }


    # generates data without popping up the model image 
    #--- for now just do it. (testing for ways to keep model.)
    if { $::fMRIEngine(SignalModelDirty) } {
        set done [fMRIModelViewGenerateModel]
        if {! $done} {
            DevErrorWindow "Error in generating model for model fitting."
            return 
        }
    }


    # always uses a new instance of vtkActivationEstimator 
    if {[info commands fMRIEngine(actEstimator)] != ""} {
        fMRIEngine(actEstimator) Delete
        unset -nocomplain fMRIEngine(actEstimator)
    }
    vtk$fMRIEngine(detectionMethod)Estimator fMRIEngine(actEstimator)
    fMRIEngine(actEstimator) SetPreWhitening $fMRIEngine(checkbuttonPreWhiten)
    fMRIEngineAddInputVolumes $fMRIEngine(curRunForModelFitting)

    # set option of global effect
    if {$fMRIEngine(checkbuttonGrandMean) && $fMRIEngine(checkbuttonGlobalMean)} {
       set op 3
    } elseif {$fMRIEngine(checkbuttonGrandMean)} {
        set op 1
    } elseif {$fMRIEngine(checkbuttonGlobalMean)} {
        set op 2
    } else {
        set op 0
    }
    fMRIEngine(actEstimator) SetGlobalEffect $op 

    # adds progress bar
    if {$fMRIEngine(curRunForModelFitting) == "concatenated"} {
        set fMRIEngine(glmProgressText) "Estimating all runs..."
    } else {
        set fMRIEngine(glmProgressText) "Estimating run$fMRIEngine(curRunForModelFitting); may take awhile..."
    }
    if {$op > 0} {
        set Gui(progressText) "Performing intensity normalization..."
    } else {
        set Gui(progressText) $fMRIEngine(glmProgressText)
    }
    puts $Gui(progressText)

    # set up observers for progress event 
    set obs1 [fMRIEngine(actEstimator) AddObserver StartEvent MainStartProgress]
    set obs2 [fMRIEngine(actEstimator) AddObserver ProgressEvent fMRIEngineUpdateProgressText]
    set obs3 [fMRIEngine(actEstimator) AddObserver EndEvent MainEndProgress]
    set fMRIEngine(progressCount) 0 


    # always uses a new instance of vtkActivationDetector
    if {[info commands fMRIEngine(detector)] != ""} {
        fMRIEngine(detector) Delete
        unset -nocomplain fMRIEngine(detector)
    }
    vtk$fMRIEngine(detectionMethod)Detector fMRIEngine(detector)

    set rt [fMRIEngineAddRegressors $fMRIEngine(curRunForModelFitting)]
    if {$rt == 1} {
        puts "...failed"
        return 
    }

    fMRIEngine(detector) SetDetectionMethod 1
    fMRIEngine(detector) SetDesignMatrix fMRIEngine(designMatrix) 
    if {[info exists fMRIEngine(lowerThreshold)]} {
        fMRIEngine(actEstimator) SetLowerThreshold $fMRIEngine(lowerThreshold)
    }
    fMRIEngine(actEstimator) SetDetector fMRIEngine(detector)  
    fMRIEngine(actEstimator) Update
    set fMRIEngine(actBetaVolume) [fMRIEngine(actEstimator) GetOutput]

    # remove observers for progress event 
    fMRIEngine(actEstimator) RemoveObserver $obs1 
    fMRIEngine(actEstimator) RemoveObserver $obs2 
    fMRIEngine(actEstimator) RemoveObserver $obs3 

    puts "...done"
}
