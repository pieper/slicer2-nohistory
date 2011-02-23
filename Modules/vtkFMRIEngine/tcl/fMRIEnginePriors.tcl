#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEnginePriors.tcl,v $
#   Date:      $Date: 2006/05/30 19:50:20 $
#   Version:   $Revision: 1.1 $
# 
#===============================================================================
# FILE:        fMRIEnginePriors.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForPriorsTab parent
#   fMRIEnginePriorsClickRadioButton value
#   fMRIEnginePriorsActivation v
#   fMRIEnginePriorsLoadList parent index
#   fMRIEnginePriorsDensSelection parent
#   fMRIEnginePriorsCreate
#   fMRIEnginePriorsApply
#   fMRIEngineUpdatePriorsTab parent
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForPriorsTab
# Creates UI for the ising priors tab 
# .ARGS
# windowpath parent
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForPriorsTab {parent} {
    global fMRIEngine Gui Volume Priors fileNames  

    set f $parent
    
    #--- create blt notebook
    blt::tabset $f.tsNotebook -relief flat -borderwidth 0
    pack $f.tsNotebook -side top

    #--- notebook configure
    $f.tsNotebook configure -width 240
    $f.tsNotebook configure -height 580 
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
    $f.tsNotebook configure -tabrelief raised
    
    #--- tab configure
    set i 0
    foreach t "Choose Meanfield" {
        $f.tsNotebook insert $i $t
        frame $f.tsNotebook.f$t -bg $Gui(activeWorkspace) -bd 2 

        $f.tsNotebook tab configure $t -window $f.tsNotebook.f$t 
        $f.tsNotebook tab configure $t -activebackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -selectbackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -background $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -fill both -padx 1 -pady $::Gui(pad) 

        incr i
    }
    
    set f $parent.tsNotebook
    frame $f.fChoose.fVolume -bg $Gui(activeWorkspace) \
        -relief groove -bd 3
    frame $f.fChoose.fSegmentation -bg $Gui(activeWorkspace) \
        -relief groove -bd 3
    frame $f.fChoose.fDensity -bg $Gui(activeWorkspace) \
        -relief groove -bd 3
    frame $f.fMeanfield.fMeanfield -bg $Gui(activeWorkspace) \
        -relief groove -bd 3
    frame $f.fMeanfield.fApply -bg $Gui(activeWorkspace) \
        -relief groove -bd 3
    
    pack $f.fChoose.fVolume $f.fChoose.fSegmentation $f.fChoose.fDensity \
        $f.fMeanfield.fMeanfield $f.fMeanfield.fApply -side top -fill x 
    
    #-------------------------------------------
    # Volume frame 
    #-------------------------------------------
    set f $parent.tsNotebook.fChoose.fVolume
    
    frame $f.fTitle -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fTitle2 -bg $Gui(backdrop) \
        -relief flat -bd 0    
    frame $f.fOptions -bg $Gui(activeWorkspace)\
        -relief flat -bd 0
    frame $f.fThreshold -bg $Gui(activeWorkspace)\
        -relief flat -bd 0
    frame $f.fLabelmap -bg $Gui(activeWorkspace)\
        -relief flat -bd 0
        
    pack $f.fTitle $f.fTitle2 $f.fOptions $f.fThreshold $f.fLabelmap\
        -side top -fill x -padx 2 -pady 2 
    
    set f $parent.tsNotebook.fChoose.fVolume.fTitle
    
    eval {label $f.lActive -text "Active volume:"} $Gui(BLA)
   
    # This can be used for Volume input instead of the following fMRIEngine input
    #
    #if {[info exists Volume(activeID)]} {
    #    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
    #        -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
    #    eval {menu $f.mbActive.m} $Gui(WMA)
    #    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
    #
    #    set sizeVol [llength $Volume(idList)]
    #    for {set i 0} {$i < $sizeVol} {incr i 1} {
    #        if {[Volume([lindex $Volume(idList) $i],node) GetLabelMap] != 1} {
    #            $f.mbActive.m add command -label [Volume([lindex $Volume(idList) $i],node) GetName] \
    #                -command "$f.mbActive config -text [Volume([lindex $Volume(idList) $i],node) GetName] 
    #                    set fMRIEngine(currentActVolID) [lindex $Volume(idList) $i]
    #                    set fMRIEngine(currentActVolName) [Volume([lindex $Volume(idList) $i],node) GetName]" 
    #        }       
    #    } 
    #} else {
    #    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
    #        -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
    #    eval {menu $f.mbActive.m} $Gui(WMA)
    #    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
    #    
    #    $f.mbActive.m add command -label None \
    #    -command "$f.mbActive config -text None" 
    #}
       
    if {[info exists fMRIEngine(actVolumeNames)]} {
        if {[info exists fMRIEngine(currentActVolID)]} {
            eval {menubutton $f.mbActive -text $fMRIEngine(currentActVolName) -relief raised -bd 2 -width 33 \
                -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
        } else {        
            eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
                -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
        }
        eval {menu $f.mbActive.m} $Gui(WMA)
        pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
     
        set sizeVol [llength $fMRIEngine(actVolumeNames)]
        for {set i 0} {$i < $sizeVol} {incr i 1} {
            $f.mbActive.m add command -label [lindex $fMRIEngine(actVolumeNames) $i] \
            -command "$f.mbActive config -text [lindex $fMRIEngine(actVolumeNames) $i] 
                set fMRIEngine(currentActVolID) [MIRIADSegmentGetVolumeByName [lindex $fMRIEngine(actVolumeNames) $i]]
                set fMRIEngine(currentActVolName) [lindex $fMRIEngine(actVolumeNames) $i]" 
        }
    } else {
        eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
            -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
        eval {menu $f.mbActive.m} $Gui(WMA)
        pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
        
        $f.mbActive.m add command -label None \
        -command "$f.mbActive config -text None" 
    }
    
    set f $parent.tsNotebook.fChoose.fVolume.fTitle2
    
    DevAddButton $f.bHelp "?" "fMRIEngineHelpViewActivationThreshold" 2 
    eval {label $f.l2 -text "Choose a thresholding option:"} $Gui(BLA)
    
    pack $f.bHelp -side left -padx 1 -pady 1 
    pack $f.l2 -side left -padx $Gui(pad) -fill x -anchor w

    set f $parent.tsNotebook.fChoose.fVolume.fOptions 

    foreach param "Uncorrected CorrectedCind CorrectedCdep" \
            name "{uncorrected p value     } {corrected p value (cind)} {corrected p value (cdep)}" \
            value "uncorrected cind cdep" {

        eval {radiobutton $f.r$param -width 25 -text $name \
            -variable fMRIEngine(thresholdingOption) -value $value \
            -relief raised -offrelief raised -overrelief raised \
            -selectcolor white} $Gui(WEA)

        pack $f.r$param -side top -pady 2 
        bind $f.r$param <1> "fMRIEnginePriorsClickRadioButton $value"
    }
    set fMRIEngine(thresholdingOption) uncorrected
    
    set f $parent.tsNotebook.fChoose.fVolume.fThreshold 
    
    foreach m "Title Params" {
        frame $f.f${m} -bg $Gui(activeWorkspace)
        pack $f.f${m} -side top -fill x -pady 2 
    }

    set f $parent.tsNotebook.fChoose.fVolume.fThreshold.fTitle 
    DevAddLabel $f.lLabel "Threshold the activation:"
    grid $f.lLabel -padx 1 -pady 2 

    set f $parent.tsNotebook.fChoose.fVolume.fThreshold.fParams 
    frame $f.fStat  -bg $Gui(activeWorkspace) 
    pack $f.fStat -side top -fill x -padx 2 -pady 1 

    set f $parent.tsNotebook.fChoose.fVolume.fThreshold.fParams.fStat 
    DevAddLabel $f.lPV "p Value:"
    DevAddLabel $f.lTS "t Stat:"
    set fMRIEngine(pValue) "0.0"
    set fMRIEngine(tStat) "Inf"
    eval {entry $f.ePV -width 15 \
        -textvariable fMRIEngine(pValue)} $Gui(WEA)
    eval {entry $f.eTS -width 15 -state readonly \
        -textvariable fMRIEngine(tStat)} $Gui(WEA)
    bind $f.ePV <Return> "fMRIEnginePriorsActivation p"

    DevAddButton $f.bPlus "+" "fMRIEnginePriorsActivation +" 2
    TooltipAdd $f.bPlus "Increase the p value by 0.01 to threshold."
    DevAddButton $f.bMinus "-" "fMRIEnginePriorsActivation -" 2
    TooltipAdd $f.bMinus "Decrease the p value by 0.01 to threshold."
 
    grid $f.lPV $f.ePV $f.bPlus $f.bMinus -padx 1 -pady 2 -sticky e
    grid $f.lTS $f.eTS -padx 1 -pady 2 -sticky e
    
    set f $parent.tsNotebook.fChoose.fVolume.fLabelmap 
    DevAddLabel $f.lLabel "Activation label map name:"
    eval {entry $f.eAlm -width 30 \
        -textvariable Priors(activationLabelmap)} $Gui(WEA)
    DevAddButton $f.bCreate "Create" "fMRIEnginePriorsCreate" 12 
    pack $f.lLabel -side top -fill x -padx 2 -pady 2
    pack $f.eAlm -side top -fill x -padx 6 -pady 2
    pack $f.bCreate -side top -padx 2 -pady 2
            
    #-------------------------------------------
    # Segmentation frame 
    #-------------------------------------------
    set f $parent.tsNotebook.fChoose.fSegmentation
    
    frame $f.fTitle2 -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fTitle -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fAction -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
    frame $f.fLoad -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
        
    pack $f.fTitle2 $f.fTitle $f.fAction $f.fLoad \
        -side top -fill x -pady 2 -padx 2 
    
    set f $parent.tsNotebook.fChoose.fSegmentation.fTitle2
    
    eval {label $f.lWorking -text "Anatomical label map:"} $Gui(BLA)
    
    set Priors(lamNameList) [list {None}]
    set Priors(lamIdList) [list {0}]
    set Priors(lamCurrentId) 0
    set df [lindex $Priors(lamNameList) 0] 
    eval {menubutton $f.mbWorking -text $df -relief raised -bd 2 -width 33 \
        -indicatoron 1 -menu $f.mbWorking.m} $Gui(WMBA)
    eval {menu $f.mbWorking.m} $Gui(WMA)
    pack $f.lWorking $f.mbWorking -side left -padx $Gui(pad) 
    
    $f.mbWorking.m add command -label None \
        -command "$f.mbWorking config -text None 
            set Priors(lamCurrentId) 0" 
    
    set sizeVol [llength $Volume(idList)]
    for {set i 0} {$i < $sizeVol} {incr i 1} {
        if {[Volume([lindex $Volume(idList) $i],node) GetLabelMap] == 1} {
            lappend Priors(lamNameList) [Volume([lindex $Volume(idList) $i],node) GetName] 
            lappend Priors(lamIdList) [lindex $Volume(idList) $i]
            set size [llength $Priors(lamNameList)]   
            $f.mbWorking.m add command -label [lindex $Priors(lamNameList) [expr $size-1]] \
                -command "$f.mbWorking config -text [lindex $Priors(lamNameList) [expr $size-1]] 
                    set Priors(lamCurrentId) [lindex $Volume(idList) $i]" 
        }       
    }
    
    set f $parent.tsNotebook.fChoose.fSegmentation.fTitle
    
    DevAddButton $f.bHelp "?" "fMRIEngineHelpPriorsLoadLabelmap" 2 
    eval {label $f.l -text "Load anatomical label map:"} $Gui(BLA)
    
    pack $f.bHelp -side left -padx 1 -pady 1 
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
    
    set f $parent.tsNotebook.fChoose.fSegmentation.fAction
    
    DevAddFileBrowse $f fileNames "lamName" "File Name:" \
        "" "xml .mrml" "\$Volume(DefaultDir)" "Open" "Browse for an xml file" "" "Absolute"
    
    set f $parent.tsNotebook.fChoose.fSegmentation.fLoad
    
    set index 3
    DevAddButton $f.bLoad "Load" "fMRIEnginePriorsLoadList $parent $index" 12 
    pack $f.bLoad -side top -pady 3 
               
    #-------------------------------------------
    # Density frame 
    #-------------------------------------------
    set f $parent.tsNotebook.fChoose.fDensity
    
    frame $f.fTitle -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fAction -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
        
    pack $f.fTitle $f.fAction \
        -side top -fill x -pady 2 -padx 2 
    
    set f $parent.tsNotebook.fChoose.fDensity.fTitle
    
    set Priors(maxTraining) 5000
    set Priors(numSearchSteps) 10
    set Priors(numCrossValFolds) 5
    set Priors(nullVariable) ""
    
    DevAddButton $f.bHelp "?" "fMRIEngineHelpPriorsDensityEstimation" 2 
    eval {label $f.l -text "Density estimation:"} $Gui(BLA)
    
    set estList [list {Gaussian}]
    set df [lindex $estList 0] 
    eval {menubutton $f.mb -text $df -relief raised -bd 2 -width 40 \
          -indicatoron 1 -menu $f.mb.m} $Gui(WMBA)
    eval {menu $f.mb.m} $Gui(WMA)
    foreach m $estList  {
        $f.mb.m add command -label $m \
            -command "$f.mb config -text $m
                set Priors(estSelection) [lsearch $estList $m]
                fMRIEnginePriorsDensSelection $parent"
    }
    
    pack $f.bHelp -side left -padx 1 -pady 1 
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
    pack  $f.mb -side left -pady 1 -padx $Gui(pad)   
    
    set f $parent.tsNotebook.fChoose.fDensity.fAction
    
    set Priors(estSelection) 0  
    DevAddLabel $f.lO "Options for parzen density estimation:"
    DevAddLabel $f.lM "Max size of training data:"
    DevAddLabel $f.lS " Number of search steps:"
    DevAddLabel $f.lC "    Cross validation folds:"
    eval {entry $f.eM -width 12 -state readonly\
        -textvariable Priors(nullVariable)} $Gui(WEA)
    eval {entry $f.eS -width 12 -state readonly\
        -textvariable Priors(nullVariable)} $Gui(WEA)
    eval {entry $f.eC -width 12 -state readonly\
        -textvariable Priors(nullVariable)} $Gui(WEA)
    blt::table $f \
        0,0 $f.lO -cspan 4 -pady 3 \
        1,0 $f.lM -cspan 2 -pady 1 \
        1,2 $f.eM -cspan 2 -pady 1 \
        2,0 $f.lS -cspan 2 -pady 1 \
        2,2 $f.eS -cspan 2 -pady 1 \
        3,0 $f.lC -cspan 2 -pady 1 \
        3,2 $f.eC -cspan 2 -pady 1 
    
    
    #-------------------------------------------
    # Meanfield frame 
    #-------------------------------------------
    set f $parent.tsNotebook.fMeanfield.fMeanfield
    
    frame $f.fTitle2 -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fAction -bg $Gui(activeWorkspace) \
        -relief flat -bd 0         
    frame $f.fTitle4 -bg $Gui(backdrop) \
        -relief flat -bd 0    
    frame $f.fAction2 -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
    frame $f.fLoad -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
    frame $f.fTitle3 -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fTitle5 -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fAction3 -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
    frame $f.fLoad2 -bg $Gui(activeWorkspace) \
        -relief flat -bd 0     
    pack $f.fTitle2 $f.fAction $f.fTitle4 $f.fAction2 $f.fLoad \
        $f.fTitle3 $f.fTitle5 $f.fAction3 $f.fLoad2 \
        -side top -fill x -pady 2 -padx 2 
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fTitle2
    
    eval {label $f.l -text "p(class | label):"} $Gui(BLA) 
    set Priors(palNameList) [list {None}]
    set Priors(palFileList) [list {None}]
    set Priors(palCurrentId) 0
    set df [lindex $Priors(palNameList) 0]    
    eval {menubutton $f.mb -text $df -relief raised -bd 2 -width 33 \
        -indicatoron 1 -menu $f.mb.m} $Gui(WMBA)
    eval {menu $f.mb.m} $Gui(WMA)
    foreach m $Priors(palNameList) {
        $f.mb.m add command -label $m -command "$f.mb config -text $m 
                set Priors(palCurrentId) [lsearch $Priors(palNameList) $m]"
    }
    pack $f.l $f.mb -side left -padx $Gui(pad)   
    
    set Priors(labelConfidence) 0.8
    set Priors(greyValue) ""
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fAction
    
    DevAddLabel $f.llC "Anatomical label confidence:"
    eval {entry $f.elC -width 12 -state readonly\
        -textvariable Priors(nullVariable)} $Gui(WEA)   
    DevAddLabel $f.lgV "  Label value of grey matter:"
    eval {entry $f.egV -width 12 -state readonly\
        -textvariable Priors(nullVariable)} $Gui(WEA)
    
    blt::table $f \
        0,0 $f.llC -cspan 4 -pady 1 \
        0,4 $f.elC -cspan 1 -pady 1 \
        1,0 $f.lgV -cspan 4 -pady 1 \
        1,4 $f.egV -cspan 1 -pady 1 
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fTitle4
    
    DevAddButton $f.bHelp "?" "fMRIEngineHelpPriorsProbability" 2 
    eval {label $f.l -text "Load p(class | label):"} $Gui(BLA)
    pack $f.bHelp -side left -padx 1 -pady 1 
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fAction2
    
    DevAddFileBrowse $f fileNames "palName" "File Name:" \
        "" "txt" "\$Volume(DefaultDir)" "Open" "Browse for p(activation | label)" "" "Absolute"
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fLoad
    
    set index 1
    DevAddButton $f.bLoad "Load" "fMRIEnginePriorsLoadList $parent $index" 12 
    pack $f.bLoad -side top -pady 3 
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fTitle3
    
    eval {label $f.l -text "Transition matrix:"} $Gui(BLA)
    set Priors(tramNameList) [list {None}]
    set Priors(tramFileList) [list {None}]
    set Priors(tramCurrentId) 0
    set df [lindex $Priors(tramNameList) 0]  
    eval {menubutton $f.mb -text $df -relief raised -bd 2 -width 33 \
        -indicatoron 1 -menu $f.mb.m} $Gui(WMBA)
    eval {menu $f.mb.m} $Gui(WMA)
    foreach m $Priors(tramNameList) {
        $f.mb.m add command -label $m -command "$f.mb config -text $m 
                set Priors(tramCurrentId) [lsearch $Priors(tramNameList) $m]"
    }
    pack $f.l $f.mb -side left -padx $Gui(pad)  
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fTitle5
    
    DevAddButton $f.bHelp "?" "fMRIEngineHelpPriorsTransitionMatrix" 2 
    eval {label $f.l -text "Load transition matrix:"} $Gui(BLA)
    pack $f.bHelp -side left -padx 1 -pady 1 
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fAction3
    
    DevAddFileBrowse $f fileNames "tramName" "File Name:" \
        "" "txt" "\$Volume(DefaultDir)" "Open" "Browse for a transition matrix" "" "Absolute"
    
    set f $parent.tsNotebook.fMeanfield.fMeanfield.fLoad2
  
    set index 2
    DevAddButton $f.bLoad "Load" "fMRIEnginePriorsLoadList $parent $index" 12 
    pack $f.bLoad -side top -pady 3 
    
    #-------------------------------------------
    # Apply frame 
    #-------------------------------------------
    set f $parent.tsNotebook.fMeanfield.fApply
    
    frame $f.fTitle -bg $Gui(backdrop) \
        -relief flat -bd 0
    frame $f.fAction -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
    frame $f.fApply -bg $Gui(activeWorkspace) \
        -relief flat -bd 0
        
    pack $f.fTitle $f.fAction $f.fApply -side top -fill x -pady 2 -padx 2
    
    set f $parent.tsNotebook.fMeanfield.fApply.fTitle
    
    DevAddButton $f.bHelp "?" "fMRIEngineHelpPriorsMeanfieldApproximation" 2 
    eval {label $f.l -text "Meanfield approximation:"} $Gui(BLA)
    pack $f.bHelp -side left -padx 1 -pady 1 
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
    
    set f $parent.tsNotebook.fMeanfield.fApply.fAction
    
    set Priors(iterations) 50
    
    eval {scale $f.s -label "Number of iterations:" -orient horizontal -from 1 -to 100 \
        -resolution 1 -bigincrement 10 -variable Priors(iterations) -state active} $Gui(WSA) {-showvalue 1}
    
    pack $f.s -side top -fill x -padx 4
    
    set f $parent.tsNotebook.fMeanfield.fApply.fApply
    
    DevAddLabel $f.lLabel "Priors activation label map name:"
    eval {entry $f.eAlm -width 30 \
        -textvariable Priors(priorsLabelmap)} $Gui(WEA)
    pack $f.lLabel -side top -fill x -padx 2 -pady 2
    pack $f.eAlm -side top -fill x -padx 6 -pady 2
    
    DevAddButton $f.bApply "Apply" "fMRIEnginePriorsApply" 12 
    pack $f.bApply -side top -pady 5 
    
    
}

#-------------------------------------------------------------------------------
# .PROC fMRIEnginePriorsClickRadioButton
# Handles the click event on radio buttons 
# .ARGS
# value which button is clicked
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePriorsClickRadioButton {value} {
    global fMRIEngine

    set fMRIEngine(thresholdingOption) $value
    fMRIEnginePriorsActivation p
}

#-------------------------------------------------------------------------------
# .PROC fMRIEnginePriorsActivation
# Scales the activation volume 
# .ARGS
# int no the scale index 
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePriorsActivation {v} {
    global Volume fMRIEngine MultiVolumeReader Slicer

    if {! [info exists fMRIEngine(currentActVolID)]} {
        DevErrorWindow "Choose an activation volume."
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
    
    # render the image
    set id $fMRIEngine(currentActVolID) 
    Volume($id,node) AutoThresholdOff
    Volume($id,node) ApplyThresholdOn
    Volume($id,node) SetLowerThreshold $t 
    MainSlicesSetVolumeAll Fore $id
    MainVolumesSetActive $id
    MainVolumesRender
}

#-------------------------------------------------------------------------------
# .PROC fMRIEnginePriorsLoadList
# Loads p(activation | label), transition matrix, and anatomical label map
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePriorsLoadList {parent index} {
    global Priors File Mrml Volume fileNames fMRIEngine 

    switch $index {
        1 {set fileName $fileNames(palName)
            # Do nothing if the user cancelled
            if {$fileName == ""} {return}
            if {[regexp {.*\.txt$} $fileName] != 1} {
                DevWarningWindow "Selected file is not a text file (.txt)"
                return
            }
        }
        2 {set fileName $fileNames(tramName)
            # Do nothing if the user cancelled
            if {$fileName == ""} {return}
            if {[regexp {.*\.txt$} $fileName] != 1} {
                DevWarningWindow "Selected file is not a text file (.txt)"
                return
            }
        }
        3 {set fileName $fileNames(lamName)
            # Do nothing if the user cancelled
            if {$fileName == ""} {return}
            if {[regexp {.*\.mrml$} $fileName] == 1} {
            } elseif {[regexp {.*\.xml$} $fileName] == 1} {
            } else {DevWarningWindow "Selected file is not a XML or MRML file (.xml, .mrml)"
                return
            }
            # Bring nodes from a mrml file into the current tree
            MainMrmlImport $fileName
        }
    }

    # Make it a relative prefix
    set filename [MainFileGetRelativePrefix $fileName]
    
    switch $index {
        1 {lappend Priors(palNameList) $filename
            lappend Priors(palFileList) $fileName
            set size [llength $Priors(palNameList)] 
            set f $parent.tsNotebook.fMeanfield.fMeanfield.fTitle2 
            set m [lindex $Priors(palNameList) [expr $size-1]]
            $f.mb.m add command -label $m -command "$f.mb config -text $m 
                set Priors(palCurrentId) [lsearch $Priors(palNameList) $m]"
        }
        2 {lappend Priors(tramNameList) $filename
            lappend Priors(tramFileList) $fileName
            set size [llength $Priors(tramNameList)] 
            set f $parent.tsNotebook.fMeanfield.fMeanfield.fTitle3 
            set m [lindex $Priors(tramNameList) [expr $size-1]]
            $f.mb.m add command -label $m -command "$f.mb config -text $m 
                set Priors(tramCurrentId) [lsearch $Priors(tramNameList) $m]"
        }
        3 {set sizeVol [llength $Volume(idList)]
            lappend Priors(lamNameList) [Volume([lindex $Volume(idList) [expr $sizeVol-2]],node) GetName] 
            lappend Priors(lamIdList) [lindex $Volume(idList) [expr $sizeVol-2]]
            set size [llength $Priors(lamNameList)] 
            set f $parent.tsNotebook.fChoose.fSegmentation.fTitle2
            set m [lindex $Priors(lamNameList) [expr $size-1]]
            $f.mbWorking.m add command -label $m -command "$f.mbWorking config -text $m 
                set Priors(lamCurrentId) [lindex $Volume(idList) [expr $sizeVol-2]]"
            set f $parent.tsNotebook.fMeanfield.fMeanfield.fAction
            $f.elC config -textvariable Priors(labelConfidence) -state normal 
            $f.egV config -textvariable Priors(greyValue) -state normal 
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC fMRIEnginePriorsDensSelection
# Enables and disables variables of the parzen density estimation
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePriorsDensSelection {parent} { 
    global Priors Gui
    
    set f $parent.tsNotebook.fChoose.fDensity.fAction    
        
    if {$Priors(estSelection) == 0} {
        $f.eM config -textvariable Priors(nullVariable) -state readonly 
        $f.eS config -textvariable Priors(nullVariable) -state readonly 
        $f.eC config -textvariable Priors(nullVariable) -state readonly   
    }
    if {$Priors(estSelection) == 1} {
        $f.eM config -textvariable Priors(maxTraining) -state normal 
        $f.eS config -textvariable Priors(numSearchSteps) -state normal 
        $f.eC config -textvariable Priors(numCrossValFolds) -state normal      
    }
}

#-------------------------------------------------------------------------------
# .PROC fMRIEnginePriorsCreate
# Creates an activation label map
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePriorsCreate {} { 
    global fMRIEngine Volume Slice Priors

    if {$Priors(activationLabelmap) != ""} {
        vtkIsingActivationThreshold Priors(threshold)
        puts "Creating activation label map..."
        Priors(threshold) SetInput [Volume($fMRIEngine(currentActVolID),vol) GetOutput]
        Priors(threshold) Setthreshold $fMRIEngine(tStat)
        Priors(threshold) SetthresholdID 1
        Priors(threshold) Update

        set act [Volume($fMRIEngine(currentActVolID),vol) GetOutput] 
        $act Update

        # add a mrml node
        set n [MainMrmlAddNode Volume]
        set i [$n GetID]
        MainVolumesCreate $i

        $n SetName $Priors(activationLabelmap) 
        $n SetDescription $Priors(activationLabelmap)

        eval Volume($i,node) SetSpacing [$act GetSpacing]
        
        # This can be used for Volume input instead of the following firstMRMLid input
        #        
        #Volume($i,node) SetScanOrder [Volume($fMRIEngine(currentActVolID),node) GetScanOrder]
        
        Volume($i,node) SetScanOrder [Volume($fMRIEngine(firstMRMLid),node) GetScanOrder]                   
        Volume($i,node) SetNumScalars [$act GetNumberOfScalarComponents]
        set ext [$act GetWholeExtent]
        Volume($i,node) SetImageRange [expr 1 + [lindex $ext 4]] [expr 1 + [lindex $ext 5]]
        Volume($i,node) SetScalarType [$act GetScalarType]
        Volume($i,node) SetDimensions [lindex [$act GetDimensions] 0] [lindex [$act GetDimensions] 1]
        Volume($i,node) ComputeRasToIjkFromScanOrder [Volume($i,node) GetScanOrder]
    
        Volume($i,node) SetInterpolate 0
        Volume($i,node) SetLUTName -1      
        Volume($i,node) SetLabelMap 1
        Volume($i,node) AutoThresholdOn
        Volume($i,node) ApplyThresholdOn

        Volume($i,vol) SetMrmlNode Volume($i,node)
        Volume($i,vol) SetImageData [Priors(threshold) GetOutput]
        Volume($i,vol) SetRangeLow 0 
        Volume($i,vol) SetRangeHigh 8 
        Volume($i,vol) SetLabelIndirectLUT Lut(-1,indirectLUT)
        Volume($i,vol) UseLabelIndirectLUTOn
        Volume($i,vol) SetLookupTable Lut(-1,lut)
        Volume($i,vol) SetHistogramHeight $Volume(histHeight)
        Volume($i,vol) SetHistogramWidth $Volume(histWidth)
        Volume($i,vol) Update
    
        set Volume($i,dirty) 1
        set Volume($i,fly) 1
   
        MainUpdateMRML
        set id [MIRIADSegmentGetVolumeByName $Priors(activationLabelmap)] 
    
        MainSlicesSetVolumeAll Fore $id
        MainVolumesSetActive $id
    
        MainVolumesRender
        
        Priors(threshold) Delete
        unset -nocomplain Priors(threshold)
    
        puts "...done"
    
    } else {
        DevErrorWindow "Enter name for new activation label map."
    }
}
    

#-------------------------------------------------------------------------------
# .PROC fMRIEnginePriorsApply
# Applies the meanfield approximation and creates a new volume
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePriorsApply {} { 
    global Priors fMRIEngine Gui Volume Slice  
    
    #-------------------------------------------
    # P(activation | label) file input
    #-------------------------------------------
    set palSegM 0
    set palClass 0
    set probGivenSegM($palSegM,$palClass) 0
    set palExists 0 
    if {$Priors(palCurrentId) != 0} {
        set palExists 1
        set fHandle [open [lindex $Priors(palFileList) $Priors(palCurrentId)] r]
        set data [read $fHandle]
        set lines [split $data "\n"]
        set palSegM 0
        set palClass2 0
        foreach line $lines {
            set sum 0
            set palClass 0
            set line [string trim $line]
            set first 0
            set last 0
            for {set i 0} {$i < [string length $line]} {incr i 1} {
                if {[string index $line $i] == "/"} {
                    set last [expr $i - 1]
                    set probGivenSegM($palSegM,$palClass) [string range $line $first $last]     
                    incr palClass 1 
                    set sum [expr $sum + [string range $line $first $last]]
                    set first [expr $i + 1]
                }
            }
            if {$palSegM == 0} {
                set palClass2 $palClass
            } else {
                if {$palClass2 != $palClass} {
                    set palExists 2
                }
            }        
            incr palSegM 1
            if {$sum > 1.01 || $sum < 0.99} {
                set palExists 3
            }
        }
        if {$palExists == 2} {
            DevErrorWindow "Activation probability given segmentation label file content is of invalid format."
        }
        if {$palExists == 3} {
            DevErrorWindow "Activation probability given segmentation label does not add up to value between 0.99 and 1.0 ."
        }
        close $fHandle
    }     
    
    #-------------------------------------------
    # Transition matrix file input
    #-------------------------------------------
    set tramExists 0 
    set tramRow 0
    if {$Priors(tramCurrentId) != 0} {
        set tramExists 1
        set fHandle [open [lindex $Priors(tramFileList) $Priors(tramCurrentId)] r]
        set data [read $fHandle]
        set lines [split $data "\n"]
        set tramRow 0
        set tramClass2 0
        foreach line $lines {
            set tramClass 0
            set line [string trim $line]
            set first 0
            set last 0
            for {set i 0} {$i < [string length $line]} {incr i 1} {
                if {[string index $line $i] == "/"} {
                    set last [expr $i - 1]
                    set transitionMatrix($tramRow,$tramClass) [string range $line $first $last]     
                    incr tramClass 1 
                    set first [expr $i + 1]
                }
            }
            if {$tramRow == 0} {
                set tramClass2 $tramClass
            } else {
                if {$tramClass2 != $tramClass} {
                    set tramExists 2
                }
            }        
            incr tramRow 1   
        }
        if {$tramExists == 2} {
            DevErrorWindow "Transition matrix file content is of invalid format."
        }
        if {$tramRow != $tramClass2} {
            DevErrorWindow "Transition matrix is not of size (class x class)."
            set tramExists 0
        }
        close $fHandle
    }     
    
    #-------------------------------------------
    # Meanfield approximation
    #-------------------------------------------
    if {[info exists fMRIEngine(currentActVolName)]} {  
    
        if {$Priors(priorsLabelmap) != ""} {  
        
            if {$Priors(lamCurrentId) == 0} {
                set Priors(greyValue) 1
                set Priors(labelConfidence) 0.8
            }
            if {[ValidateInt $Priors(greyValue)] != 0 } {
            
                if {[ValidateFloat $Priors(labelConfidence)] != 0} {
                    
                    #-------------------------------------------
                    # activation threshold
                    #-------------------------------------------
                    vtkIsingActivationThreshold Priors(threshold)
                    Priors(threshold) SetInput [Volume($fMRIEngine(currentActVolID),vol) GetOutput]
                    if {$Priors(lamCurrentId) != 0} {
                        Priors(threshold) AddInput [Volume($Priors(lamCurrentId),vol) GetOutput]
                    }
                    Priors(threshold) Setthreshold $fMRIEngine(tStat) 
                    Priors(threshold) SetthresholdID 2
                    Priors(threshold) Update
                    set x [Priors(threshold) Getx]
                    set y [Priors(threshold) Gety]
                    set z [Priors(threshold) Getz]
                    set numActivationStates [Priors(threshold) GetnumActivationStates]
                    set nType [Priors(threshold) GetnType]
                    set segInput [Priors(threshold) GetsegInput]
                    set segLabelTcl [Priors(threshold) GetsegLabel]
        
                    #-------------------------------------------
                    # creation of class volume
                    #-------------------------------------------
                    vtkIsingActivationTissue Priors(tissue)
                    Priors(tissue) SetInput [Priors(threshold) GetOutput] 
                    if {$Priors(lamCurrentId) != 0} {
                        Priors(tissue) AddInput [Volume($Priors(lamCurrentId),vol) GetOutput]
                    }
                    Priors(tissue) Setx $x
                    Priors(tissue) Sety $y
                    Priors(tissue) Setz $z
                    Priors(tissue) SetnumActivationStates $numActivationStates
                    Priors(tissue) SetnType $nType
                    Priors(tissue) SetgreyValue $Priors(greyValue)
                    Priors(tissue) SetsegInput $segInput
                    Priors(tissue) SetsegLabel $segLabelTcl
                    Priors(tissue) Update
                    set nGreyValue [Priors(tissue) GetnGreyValue]
                    set nonpp [Priors(tissue) Getnonpp]
                    set negpp [Priors(tissue) Getnegpp]
                    set pospp [Priors(tissue) Getpospp]
                    set activationFrequenceTcl [Priors(tissue) GetactivationFrequence]
       
                    #-------------------------------------------
                    # conditional distribution
                    #-------------------------------------------       
                    vtkIsingConditionalDistribution Priors(distribution)
                    # adds progress bar
                    set obs1 [Priors(distribution) AddObserver StartEvent MainStartProgress]
                    set obs2 [Priors(distribution) AddObserver ProgressEvent \
                            "MainShowProgress Priors(distribution)"]
                    set obs3 [Priors(distribution) AddObserver EndEvent MainEndProgress]  
                    set Gui(progressText) "Computing coditional distribution..."
                    puts $Gui(progressText)        
                    MainStartProgress
                    MainShowProgress Priors(distribution)  
                    Priors(distribution) SetInput [Priors(tissue) GetOutput]
                    Priors(distribution) AddInput [Volume($fMRIEngine(currentActVolID),vol) GetOutput]
                    Priors(distribution) Setx $x
                    Priors(distribution) Sety $y
                    Priors(distribution) Setz $z
                    Priors(distribution) SetnType $nType
                    Priors(distribution) SetdensityEstimate $Priors(estSelection)
                    Priors(distribution) SetnumSearchSteps $Priors(numSearchSteps)
                    Priors(distribution) SetnumCrossValFolds $Priors(numCrossValFolds)
                    Priors(distribution) SetmaxTraining $Priors(maxTraining)
                    Priors(distribution) Update
                    MainEndProgress
                    Priors(distribution) RemoveObserver $obs1 
                    Priors(distribution) RemoveObserver $obs2 
                    Priors(distribution) RemoveObserver $obs3 
     
                    puts "...done"
     
                    #-------------------------------------------
                    # initialization of inputs
                    #-------------------------------------------            
                    vtkFloatArray Priors(probGivenSegMArray)
               
                    if {$palExists == 1} {
                        if {$palSegM != $segInput || $palClass != $nType} {
                            DevErrorWindow "Activation probability given segmentation label file is not of size ($nType x $segInput)."
                            set palExists 0
                        } 
                    }        
                    if {$palExists == 1} {
                        for {set i 0} {$i < $palSegM} {incr i 1} {
                            for {set j 0} {$j < $palClass} {incr j 1} {                
                                Priors(probGivenSegMArray) InsertNextValue $probGivenSegM($i,$j)                  
                            }
                        }
                    } else {    
                        if {$Priors(lamCurrentId) != 0} {
                            for {set i 0} {$i < $segInput} {incr i 1} {
                                for {set j 0} {$j < $nType} {incr j 1} {
                                    Priors(probGivenSegMArray) InsertNextValue 0.0                                                             
                                } 
                            }
                            for {set i 0} {$i < $segInput} {incr i 1} {
                                for {set j 0} {$j < $segInput} {incr j 1} {
                                    for {set k 0} {$k < $numActivationStates} {incr k 1} {
                                        if {$i != $nGreyValue && $j != $nGreyValue} {                                          
                                            if {$i == $j && $k == 0} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] $Priors(labelConfidence)
                                            }
                                            if {$i == $j && $k != 0} { 
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] 0.0
                                            }
                                            if {$i != $j && $k == 0} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr [expr 1-$Priors(labelConfidence)]/[expr $segInput-1]]
                                            }
                                            if {$i != $j && $k != 0} { 
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] 0.0
                                            }
                                        }
                                        if {$i == $nGreyValue && $j != $nGreyValue} {                                          
                                            if {$k == 0} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr [expr 1-$Priors(labelConfidence)]/[expr $segInput-1]]
                                            }
                                            if {$k != 0} { 
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] 0.0
                                            }
                                        }
                                        if {$i != $nGreyValue && $j == $nGreyValue} { 
                                            if {$k == 0} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr [expr [expr 1-$Priors(labelConfidence)]/[expr $segInput-1]]*$nonpp]                                  
                                            }
                                            if {$k == 1} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr [expr [expr 1-$Priors(labelConfidence)]/[expr $segInput-1]]*$pospp]                                  
                                            }
                                            if {$k == 2} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr [expr [expr 1-$Priors(labelConfidence)]/[expr $segInput-1]]*$negpp]                                  
                                            }
                                        }
                                        if {$i == $nGreyValue && $j == $nGreyValue} { 
                                            if {$k == 0} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr $Priors(labelConfidence)*$nonpp]                                  
                                            }
                                            if {$k == 1} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr $Priors(labelConfidence)*$pospp]                                  
                                            }
                                            if {$k == 2} {
                                                Priors(probGivenSegMArray) SetValue [expr [expr [expr $i*$nType]+[expr $k*$segInput]]+$j] [expr $Priors(labelConfidence)*$negpp]                                  
                                            }
                                        }
                                    }
                                }
                            }   
                        } else {
                            for {set i 0} {$i < $segInput} {incr i 1} {
                                for {set j 0} {$j < $nType} {incr j 1} {
                                    Priors(probGivenSegMArray) InsertNextValue [expr 1.0/$nType]                                                             
                                } 
                            }
                        }
                    }                   
        
                    vtkIntArray Priors(transitionMatrixArray)
        
                    if {$tramExists == 1} {           
                        if {$tramRow != $nType} {
                            DevErrorWindow "Transition matrix is not of size ($nType x $nType)."
                            set tramExists 0
                        }  
                    }  
                    if {$tramExists == 1} {          
                        for {set i 0} {$i < $tramRow} {incr i 1} {
                            for {set j 0} {$j < $tramRow} {incr j 1} {
                                Priors(transitionMatrixArray) InsertNextValue $transitionMatrix($i,$j)                 
                            }
                        }
                    } else {           
                        for {set i 0} {$i < $nType} {incr i 1} {
                            for {set j 0} {$j < $nType} {incr j 1} {
                                Priors(transitionMatrixArray) InsertNextValue 0                  
                            }
                        }
                    }
        
                    set probGivenSegMTcl Priors(probGivenSegMArray)
                    set transitionMatrixTcl Priors(transitionMatrixArray)
        
                    #-------------------------------------------
                    # meanfield approximation
                    #-------------------------------------------        
                    vtkIsingMeanfieldApproximation Priors(meanfield)
                    set obs1 [Priors(meanfield) AddObserver StartEvent MainStartProgress]
                    set obs2 [Priors(meanfield) AddObserver ProgressEvent \
                            "MainShowProgress Priors(meanfield)"]
                    set obs3 [Priors(meanfield) AddObserver EndEvent MainEndProgress]  
                    set Gui(progressText) "Computing meanfield approximation..."
                    puts $Gui(progressText)      
                    MainStartProgress
                    MainShowProgress Priors(meanfield)
                    Priors(meanfield) SetInput [Priors(tissue) GetOutput]
                    Priors(meanfield) AddInput [Priors(distribution) GetOutput]
                    if {$Priors(lamCurrentId) != 0} {
                        Priors(meanfield) AddInput [Volume($Priors(lamCurrentId),vol) GetOutput]
                    }
                    Priors(meanfield) Setx $x
                    Priors(meanfield) Sety $y
                    Priors(meanfield) Setz $z
                    Priors(meanfield) SetnType $nType
                    Priors(meanfield) SetsegInput $segInput
                    Priors(meanfield) SetsegLabel $segLabelTcl
                    Priors(meanfield) Setiterations $Priors(iterations)
                    Priors(meanfield) SetnumActivationStates $numActivationStates
                    Priors(meanfield) SetprobGivenSegM $probGivenSegMTcl
                    Priors(meanfield) SettransitionMatrix $transitionMatrixTcl
                    Priors(meanfield) SetactivationFrequence $activationFrequenceTcl
                    Priors(meanfield) Update
                    MainEndProgress
                    Priors(meanfield) RemoveObserver $obs1 
                    Priors(meanfield) RemoveObserver $obs2 
                    Priors(meanfield) RemoveObserver $obs3 
        
                    puts "...done"
                    puts "Creating Priors activation label map..."
    
                    #-------------------------------------------
                    # create new volume for meanfield output
                    #-------------------------------------------    
                    set act [Volume($fMRIEngine(currentActVolID),vol) GetOutput] 
                    $act Update

                    # add a mrml node
                    set n [MainMrmlAddNode Volume]
                    set i [$n GetID]
                    MainVolumesCreate $i

                    $n SetName $Priors(priorsLabelmap) 
                    $n SetDescription $Priors(priorsLabelmap)

                    eval Volume($i,node) SetSpacing [$act GetSpacing]
                    
                    # This can be used for Volume input instead of the following firstMRMLid input
                    #
                    #Volume($i,node) SetScanOrder [Volume($fMRIEngine(currentActVolID),node) GetScanOrder]
                    
                    Volume($i,node) SetScanOrder [Volume($fMRIEngine(firstMRMLid),node) GetScanOrder]
                    Volume($i,node) SetNumScalars [$act GetNumberOfScalarComponents]
                    set ext [$act GetWholeExtent]
                    Volume($i,node) SetImageRange [expr 1 + [lindex $ext 4]] [expr 1 + [lindex $ext 5]]
                    Volume($i,node) SetScalarType [$act GetScalarType]
                    Volume($i,node) SetDimensions [lindex [$act GetDimensions] 0] [lindex [$act GetDimensions] 1]
                    Volume($i,node) ComputeRasToIjkFromScanOrder [Volume($i,node) GetScanOrder]
    
                    Volume($i,node) SetInterpolate 0
                    Volume($i,node) SetLUTName -1      
                    Volume($i,node) SetLabelMap 1
                    Volume($i,node) AutoThresholdOn
                    Volume($i,node) ApplyThresholdOn

                    Volume($i,vol) SetMrmlNode Volume($i,node)
                    Volume($i,vol) SetImageData [Priors(meanfield) GetOutput]
                    Volume($i,vol) SetRangeLow 0 
                    Volume($i,vol) SetRangeHigh 8 
                    Volume($i,vol) SetLabelIndirectLUT Lut(-1,indirectLUT)
                    Volume($i,vol) UseLabelIndirectLUTOn
                    Volume($i,vol) SetLookupTable Lut(-1,lut)
                    Volume($i,vol) SetHistogramHeight $Volume(histHeight)
                    Volume($i,vol) SetHistogramWidth $Volume(histWidth)
                    Volume($i,vol) Update
    
                    set Volume($i,dirty) 1
                    set Volume($i,fly) 1
   
                    MainUpdateMRML
                    set id [MIRIADSegmentGetVolumeByName $Priors(priorsLabelmap)] 
    
                    MainSlicesSetVolumeAll Fore $id
                    MainVolumesSetActive $id
    
                    MainVolumesRender
    
                    puts "...done"
  
                    #-------------------------------------------
                    # delete objects
                    #-------------------------------------------  
                    Priors(meanfield) Delete
                    unset -nocomplain Priors(meanfield)
                    Priors(distribution) Delete
                    unset -nocomplain Priors(distribution)
                    Priors(tissue) Delete
                    unset -nocomplain Priors(tissue)
                    Priors(threshold) Delete
                    unset -nocomplain Priors(threshold)
        
                    Priors(probGivenSegMArray) Delete
                    unset -nocomplain Priors(probGivenSegMArray)
                    Priors(transitionMatrixArray) Delete
                    unset -nocomplain Priors(transitionMatrixArray)
        
                } else {
                    DevErrorWindow "Anatomical label confidence is not a valid float value."
                }
        
            } else {
                DevErrorWindow "Grey matter label is not a valid integer value."
            }
        
        } else {
            DevErrorWindow "Enter name for new activation label map."
        }
        
    } else {
        DevErrorWindow "Choose an activation volume."
    }
    
}
 
#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdatePriorsTab
# Updates the Priors tab
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdatePriorsTab {parent} { 
    global fMRIEngine Volume Gui Priors

    set fMRIEngine(currentTab) "Priors"
    
    set f $parent.tsNotebook.fChoose.fSegmentation.fTitle2
    
    set sizeVol [llength $Volume(idList)]
    for {set i 0} {$i < $sizeVol} {incr i 1} {
        if {[lsearch $Priors(lamIdList) [lindex $Volume(idList) $i]] < 0} {
            if {[Volume([lindex $Volume(idList) $i],node) GetLabelMap] == 1} {
                lappend Priors(lamNameList) [Volume([lindex $Volume(idList) $i],node) GetName] 
                lappend Priors(lamIdList) [lindex $Volume(idList) $i] 
                set size [llength $Priors(lamNameList)]   
                $f.mbWorking.m add command -label [lindex $Priors(lamNameList) [expr $size-1]] \
                    -command "$f.mbWorking config -text [lindex $Priors(lamNameList) [expr $size-1]] 
                        set Priors(lamCurrentId) [lindex $Volume(idList) $i]" 
            }
        }       
    }
    
    set f $parent.tsNotebook.fChoose.fVolume.fTitle
    
    destroy $f.mbActive.m
    destroy $f.mbActive
    
    # This can be used for Volume input instead of the following fMRIEngine input
    #
    #if {[info exists Volume(activeID)]} {
    #    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
    #        -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
    #    eval {menu $f.mbActive.m} $Gui(WMA)
    #    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
    # 
    #    set sizeVol [llength $Volume(idList)]
    #    for {set i 0} {$i < $sizeVol} {incr i 1} {
    #        if {[Volume([lindex $Volume(idList) $i],node) GetLabelMap] != 1} {  
    #            $f.mbActive.m add command -label [Volume([lindex $Volume(idList) $i],node) GetName] \
    #                -command "$f.mbActive config -text [Volume([lindex $Volume(idList) $i],node) GetName] 
    #                    set fMRIEngine(currentActVolID) [lindex $Volume(idList) $i]
    #                    set fMRIEngine(currentActVolName) [Volume([lindex $Volume(idList) $i],node) GetName]" 
    #        }       
    #    }       
    #} else {
    #    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
    #        -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
    #    eval {menu $f.mbActive.m} $Gui(WMA)
    #    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
    #    
    #    $f.mbActive.m add command -label None \
    #    -command "$f.mbActive config -text None" 
    #}
    
    if {[info exists fMRIEngine(actVolumeNames)]} {
        if {[info exists fMRIEngine(currentActVolID)]} {
            eval {menubutton $f.mbActive -text $fMRIEngine(currentActVolName) -relief raised -bd 2 -width 33 \
                -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
        } else {        
            eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
                -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
        }
        eval {menu $f.mbActive.m} $Gui(WMA)
        pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
     
        set sizeVol [llength $fMRIEngine(actVolumeNames)]
        for {set i 0} {$i < $sizeVol} {incr i 1} {
            $f.mbActive.m add command -label [lindex $fMRIEngine(actVolumeNames) $i] \
            -command "$f.mbActive config -text [lindex $fMRIEngine(actVolumeNames) $i] 
                set fMRIEngine(currentActVolID) [MIRIADSegmentGetVolumeByName [lindex $fMRIEngine(actVolumeNames) $i]]
                set fMRIEngine(currentActVolName) [lindex $fMRIEngine(actVolumeNames) $i]" 
        }
    } else {
        eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 33 \
            -indicatoron 1 -menu $f.mbActive.m} $Gui(WMBA)
        eval {menu $f.mbActive.m} $Gui(WMA)
        pack $f.lActive $f.mbActive -side left -padx $Gui(pad) 
        
        $f.mbActive.m add command -label None \
        -command "$f.mbActive config -text None" 
    }
}
