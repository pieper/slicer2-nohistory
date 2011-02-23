#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: KullbackLeiblerRegistration.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:03 $
#   Version:   $Revision: 1.14 $
# 
#===============================================================================
# FILE:        KullbackLeiblerRegistration.tcl
# PROCEDURES:  
#   KullbackLeiblerRegistrationInit
#   KullbackLeiblerRegistrationBuildSubGui f
#   KullbackLeiblerRegistrationSetLevel
#   VolumeMathUpdateGUI
#   KullbackLeiblerRegistrationBuildVTK
#   KullbackLeiblerRegistrationCoarseParam
#   KullbackLeiblerRegistrationFineParam
#   KullbackLeiblerRegistrationGSlowParam
#   KullbackLeiblerRegistrationGSlowParam
#   KullbackLeiblerRegistrationEnter
#   KullbackLeiblerRegistrationExit
#   KullbackLeiblerRegistrationAutoRun
#   KullbackLeiblerRegistrationStop
#   KullbackLeiblerSetMetricOption vtkITKKL
#   KullbackLeiblerRegistrationSetOptimizerOption vtkITKMI
#   RigidIntensityRegistrationCheckParametersKL
#   KullbackLeiblerRegistrationGetTrainingTransform
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationInit {} {
    global RigidIntensityRegistration KullbackLeiblerRegistration
    global Module Volume Model

    set m KullbackLeiblerRegistration

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This is a module to do Mutual Information Registration"

    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Samson Timoner MIT AI Lab"

    # Define Tabs
    #------------------------------------
    # Description:
    #   Each module is given a button on the Slicer's main menu.
    #   When that button is pressed a row of tabs appear, and there is a panel
    #   on the user interface for each tab.  If all the tabs do not fit on one
    #   row, then the last tab is automatically created to say "More", and 
    #   clicking it reveals a second row of tabs.
    #
    #   Define your tabs here as shown below.  The options are:
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #
#    set Module($m,row1List) "Help Stuff"
#    set Module($m,row1Name) "{Help} {Tons o' Stuff}"
#    set Module($m,row1,tab) Stuff

    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #

    set Module($m,procVTK) KullbackLeiblerRegistrationBuildVTK

    #
    #   All the options are:

    #   procGUI   = Build the graphical user interface
    #   procVTK   = Construct VTK objects
    #   procMRML  = Update after the MRML tree changes due to the creation
    #               of deletion of nodes.
    #   procEnter = Called when the user enters this module by clicking
    #               its button on the main menu
    #   procExit  = Called when the user leaves this module by clicking
    #               another modules button
    #   procCameraMotion = Called right before the camera of the active 
    #                      renderer is about to move 
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."

#    set Module($m,procGUI) KullbackLeiblerRegistrationBuildGUI
#    set Module($m,procVTK) KullbackLeiblerRegistrationBuildVTK
#    set Module($m,procEnter) KullbackLeiblerRegistrationEnter
#    set Module($m,procExit) KullbackLeiblerRegistrationExit
     set Module($m,procMRML) KullbackLeiblerRegistrationUpdateGUI

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   

    ## Should be ITK or vtkITK, but this does not seem to work.
    set Module($m,depend) ""

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.14 $} {$Date: 2006/01/06 17:58:03 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #

    ## put here to show KL specific param
    set KullbackLeiblerRegistration(NumberOfSamples)         50
    set KullbackLeiblerRegistration(SourceStandardDeviation) 0.4
    set KullbackLeiblerRegistration(TargetStandardDeviation) 0.4

    set KullbackLeiblerRegistration(HistSizeSource) 64
    set KullbackLeiblerRegistration(HistSizeTarget) 64
    set KullbackLeiblerRegistration(Epsilon)        1e-12

    ## Set the default to fast registration
    KullbackLeiblerRegistrationVerySlowParam

    global Volume
    set KullbackLeiblerRegistration(TrainRefVol) $Volume(idNone)
    set KullbackLeiblerRegistration(TrainMovVol) $Volume(idNone)
}
#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationBuildSubGui
#
# Build the sub-gui under $f whatever frame is calling this one
#
# Example Useg: MIBuildSubGui $f.fMI
#
# .ARGS
# frame f frame name
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationBuildSubGui {f} {
    global Gui Matrix RigidIntensityRegistration KullbackLeiblerRegistration

    set framename $f

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Select
    # Level
    #   Help
    #   Normal
    #   Advanced
    # Props
    #   Top
    #     Active
    #     Type
    #   Bot
    #     Basic
    #     Advanced
    # Manual
    # Auto
    #-------------------------------------------

    # The select and Level Frames
    frame $f.fSelect -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fLevel  -bg $Gui(activeWorkspace) -height 500
    pack $f.fSelect $f.fLevel -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Select frame
    #-------------------------------------------

    set f $framename.fSelect

    foreach level "Help Normal Advanced" {
        eval {radiobutton $f.r$level \
            -text "$level" -command "KullbackLeiblerRegistrationSetLevel" \
            -variable KullbackLeiblerRegistration(Level) -value $level -width 10 \
            -indicatoron 0} $Gui(WRA)
        set KullbackLeiblerRegistration(r${level}) $f.r$level
        pack $f.r$level -side left -padx 0 
    }

    set KullbackLeiblerRegistration(Level) Normal

    #-------------------------------------------
    # Level frame
    #-------------------------------------------

    set f $framename.fLevel
    #
    # Swappable Frames for Normal and Advanced Screens
    #
    foreach type "Help Normal Advanced" {
        frame $f.f${type} -bg $Gui(activeWorkspace)
        place $f.f${type} -in $f -relheight 1.0 -relwidth 1.0
        set KullbackLeiblerRegistration(f${type}) $f.f${type}
    }
    raise $KullbackLeiblerRegistration(fNormal)

    set fnormal   $framename.fLevel.fNormal
    set fadvanced $framename.fLevel.fAdvanced
    set fhelp     $framename.fLevel.fHelp

    #-------------------------------------------
    # Level->Help frame
    #-------------------------------------------

    set help "
    <UL>
    <LI><B>The Algorithm </B> 
    This is an automatic method of registering two images using mutual information of the two images. It is based on the methods of Wells and Viola (1996).
    <LI><B>Limitations</B>
    The algorithm has a finite capture range. Rotations of more than 30 degrees will likely not be found. Rotations of 10 degrees will likely be found. Thus, an initial alignment can be important. Anything with gantry tilt (like CT) 
will not work. Also, arbitrary cascades of transforms are not allowed. All of the transforms that affect the Reference volume must also affect the Moving volume. The Moving volume must have one additional matrix, which will be set by this method.
    <LI><B>Easiest way to begin</B>
    Select a \"Volume to Move\" and a \"Reference Volume\" and click \"Start\".
    <LI><B>Normal: Coarse</B>
    The Coarse method will generally do a good job on all images. It takes 5 to 10 minutes to run. It requires no user intervention; though, it updates regularly so that the user can stop the algorithm is she is satisfied. 
    <LI><B>Normal: Fine</B>
    The Fine method can be run after the Coarse method to fine tune the result. Again, the Fine method updates regularly so that the user can stop the algorithm if she is satified. Otherwise, it never stops.
    <LI><B>Normal: Good and Slow</B>
    This method is designed for the user to be able to walk away, and come back and find a good registration. This method sometimes yields a good result. It does not update the alignment until finished.
    <LI><B>Normal: Very Good and Very Slow</B>
    This method is designed for the user to be able to walk away, and come back and find a good registration. This method can be very slow, but it generally works very, very well. It does not update the alignment until finished.
    <LI><B>Advanced</B>
    Change these at your own risk. The input images are normalized, so that the source and target standard deviations should generally be smaller than 1. There are arguments they should be much smaller than 1, but changing them does not seem to make a big difference. The number of samples per iteration can be increased, but also does not seem to help alot. The translation scale is roughly a measure of how much to scale translations over rotations. A variety of numbers may work here. The learning rate should generally be less than 0.001, and often much smaller. The number of update iterations is generally between 100 and 2500
    <LI><B>Known Bugs</B>
    The .kl window is left open and the pipeline is left taking lots of 
    memory.
    </UL>"

    regsub -all "\n" $help { } help
    MainHelpApplyTags KullbackLeiblerRegistration $help
#    MainHelpBuildGUI  KullbackLeiblerRegistration 

    global Help
    set f  $fhelp
    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true
    set tmp [HelpWidget $f.fWidget]
    MainHelpShow $tmp KullbackLeiblerRegistration

    #-------------------------------------------
    # Level->Normal frame
    #-------------------------------------------

    set f $fnormal

    frame $f.fDesc     -bg $Gui(activeWorkspace)
    frame $f.fTraining -bg $Gui(activeWorkspace)
    frame $f.fSpeed    -bg $Gui(activeWorkspace)
    frame $f.fRepeat   -bg $Gui(activeWorkspace)
    frame $f.fRun      -bg $Gui(activeWorkspace)

    pack $f.fDesc $f.fTraining $f.fSpeed $f.fRepeat $f.fRun -pady $Gui(pad) 

    #-------------------------------------------
    # Level->Normal->Desc frame
    #-------------------------------------------
    set f $fnormal.fDesc

   if {[Slicer GetCompilerName] == "GCC" && \
       [Slicer GetCompilerVersion] < 30000 } {
     eval {label $f.l -text "KL WILL NOT WORK. IT NEEDS \n A NEWER COMPILER TO WORK"} $Gui(WLA)
     pack $f.l -pady $Gui(pad)
   } else {
      eval {label $f.l -text "\Press 'Start' to perform automatic\n registration by Kullback Leibler.\n\Your manual registration is used\n\ as an initial pose.\ "} $Gui(WLA)
    pack $f.l -pady $Gui(pad)
   }

    #-------------------------------------------
    # Level->Normal->Training frame
    #-------------------------------------------
     ## 
    set f $fnormal.fTraining

    DevAddSelectButton KullbackLeiblerRegistration $f \
        TrainMovVol "TrainingMoving"     Grid
    DevAddSelectButton KullbackLeiblerRegistration $f \
        TrainRefVol "TrainingReference:" Grid

   if {[Slicer GetCompilerName] == "GCC" && \
       [Slicer GetCompilerVersion] < 30000 } {
   return 
      }

    #-------------------------------------------
    # Level->Normal->Speed Frame
    #-------------------------------------------
    set f $fnormal.fSpeed

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side left -padx 5

    eval {label $f.fTitle.lSpeed -text "Run\n Objective:"} $Gui(WLA)
    pack $f.fTitle.lSpeed -anchor w

    # the first row and second row
    frame $f.fBtns.1 -bg $Gui(inactiveWorkspace)
    frame $f.fBtns.2 -bg $Gui(inactiveWorkspace)
    frame $f.fBtns.3 -bg $Gui(inactiveWorkspace)
    pack $f.fBtns.1 $f.fBtns.2 $f.fBtns.3 -side top -fill x -anchor w

    set row 1
    foreach text "Coarse Fine {Good and Slow} {Very Good and Very Slow}" value "Coarse Fine GSlow VerySlow" \
        width "6 6 15 21" {
        eval {radiobutton $f.fBtns.$row.r$value -width $width \
        -text "$text" -value "$value" \
        -command KullbackLeiblerRegistration${value}Param \
        -variable KullbackLeiblerRegistration(Objective) \
        -indicatoron 0} $Gui(WCA) 
        pack $f.fBtns.$row.r$value -side left -padx 4 -pady 2
        if { $value == "Fine" } {incr row};
        if { $value == "GSlow" } {incr row};
    }

   set KullbackLeiblerRegistration(Objective) VerySlow

    #-------------------------------------------
    # Level->Normal->Repeat Frame
    #-------------------------------------------
    set f $fnormal.fRepeat
    
    eval {label $f.l -text "Repeat:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x

    foreach value "1 0" text "Yes No" width "4 3" {
        eval {radiobutton $f.f.r$value -width $width \
              -indicatoron 0 -text "$text" -value "$value" \
              -variable RigidIntensityRegistration(Repeat) } $Gui(WCA)
        pack $f.f.r$value -side left -fill x -anchor w
    }

    #-------------------------------------------
    # Level->Normal->Run frame
    #-------------------------------------------
    set f $fnormal.fRun

    eval {button $f.bRun -text "Start" -width [expr [string length "Start"]+1] \
            -command "KullbackLeiblerRegistrationAutoRun"} $Gui(WBA)

    pack $f.bRun -side left -padx $Gui(pad) -pady $Gui(pad)
    set KullbackLeiblerRegistration(b1Run) $f.bRun

    #-------------------------------------------
    # Level->Advanced
    #-------------------------------------------

    set f $fadvanced

    frame $f.fParam    -bg $Gui(activeWorkspace)
    frame $f.fRun      -bg $Gui(activeWorkspace)

    pack $f.fParam $f.fRun -pady $Gui(pad) 

    foreach param { \
                   {SourceShrinkFactors} \
                   {TargetShrinkFactors} \
                   } name \
                  { \
                   {Source MultiRes Reduction} \
                   {Target Multires Reduction} \
                   } {
        set f $fadvanced.fParam
        frame $f.f$param   -bg $Gui(activeWorkspace)
        pack $f.f$param -side top -fill x -pady 2

        set f $f.f$param
        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 10 -textvariable RigidIntensityRegistration($param)} $Gui(WEA)
        pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
        pack $f.e$param -side left -padx $Gui(pad) -expand 1
    }

    foreach param { \
                   {UpdateIterations} \
                   {LearningRate} \
                   {TranslateScale} \
                   {NumberOfSamples} \
                   {SourceStandardDeviation} \
                   {TargetStandardDeviation} \
                   {HistSizeSource} \
                   {HistSizeTarget} \
                   {Epsilon} \
                   } name \
                  { \
                   {Update Iterations} \
                   {Learning Rate} \
                   {Translate Scale} \
                   {Number Of Samples} \
                   {Source Standard Deviation} \
                   {Target Standard Deviation} \
           {Histogram Size Source} \
           {Histogram Size Target} \
           {Epsilon to replace 0 bins} \
           } {
        set f $fadvanced.fParam
        frame $f.f$param   -bg $Gui(activeWorkspace)
        pack $f.f$param -side top -fill x -pady 2
        
        set f $f.f$param
        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 10 -textvariable KullbackLeiblerRegistration($param)} $Gui(WEA)
        pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
        pack $f.e$param -side left -padx $Gui(pad) -expand 1
    }

    #-------------------------------------------
    # Level->Advanced->Run frame
    #-------------------------------------------
    set f $fadvanced.fRun

    foreach str "Run" {
        eval {button $f.b$str -text "$str" -width [expr [string length $str]+1] \
            -command "KullbackLeiblerRegistrationAuto$str"} $Gui(WBA)
        set KullbackLeiblerRegistration(b$str) $f.b$str
    }
    pack $f.bRun -side left -padx $Gui(pad) -pady $Gui(pad)
    set KullbackLeiblerRegistration(b2Run) $f.bRun

}  

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationSetLevel
#
# Set the registration mechanism depending on which button the user selected in
# the Auto tab.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationSetLevel {} {
    global RigidIntensityRegistration KullbackLeiblerRegistration

    set level $KullbackLeiblerRegistration(Level)
    raise $KullbackLeiblerRegistration(f${level})
    focus $KullbackLeiblerRegistration(f${level})
}

#-------------------------------------------------------------------------------
# .PROC VolumeMathUpdateGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationUpdateGUI {} {
    global KullbackLeiblerRegistration Volume

### I once ran into errors that KullbackLeiblerRegistration(TrainRefVol)
### did not exist. Might need to check for it one day and set it if
### it does not exist

    DevUpdateNodeSelectButton Volume KullbackLeiblerRegistration \
      TrainRefVol TrainRefVol DevSelectNode
    DevUpdateNodeSelectButton Volume KullbackLeiblerRegistration \
      TrainMovVol TrainMovVol DevSelectNode
}

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationBuildVTK {} {
    global KullbackLeiblerRegistration Volume

    ### normalize and center the training target
    vtkImageChangeInformation KLTrainTargetChangeInfo
    KLTrainTargetChangeInfo SetInput [Volume($Volume(idNone),vol) GetOutput]
    KLTrainTargetChangeInfo CenterImageOn

    vtkImageCast KLTrainTargetCast
    KLTrainTargetCast SetOutputScalarTypeToFloat
    KLTrainTargetCast SetInput [KLTrainTargetChangeInfo GetOutput]

    if {[info command vtkITKNormalizeImageFilter] == ""} {
        DevErrorWindow "Rigid Intensity Registration:\nERROR: vtkITKNormalizeImageFilter does not exist.\nThis module depends on a missing module, vtkITK, and will not work properly."
    } else {
        vtkITKNormalizeImageFilter KLTrainTargetNorm
        KLTrainTargetNorm SetInput [KLTrainTargetCast GetOutput]
    }

    ### normalize and center the training source
    vtkImageChangeInformation KLTrainSourceChangeInfo
    KLTrainSourceChangeInfo SetInput [Volume($Volume(idNone),vol) GetOutput]
    KLTrainSourceChangeInfo CenterImageOn

    vtkImageCast KLTrainSourceCast
    KLTrainSourceCast SetOutputScalarTypeToFloat
    KLTrainSourceCast SetInput [KLTrainSourceChangeInfo GetOutput]


    if {[info command vtkITKNormalizeImageFilter] == ""} {
        DevErrorWindow "Rigid Intensity Registration:\nERROR: vtkITKNormalizeImageFilter does not exist.\nThis module depends on a missing module, vtkITK, and will not work properly."
    } else { 
        vtkITKNormalizeImageFilter KLTrainSourceNorm
        KLTrainSourceNorm SetInput [KLTrainSourceCast GetOutput]
    }
}

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationCoarseParam
#
#  These parameters should allow the user the ability to intervene
#  and decide when he/she is done.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationCoarseParam {} {
    global KullbackLeiblerRegistration RigidIntensityRegistration

    set RigidIntensityRegistration(Resolution)       128
    set RigidIntensityRegistration(SourceShrinkFactors)   "1 1 1"
    set RigidIntensityRegistration(TargetShrinkFactors)   "1 1 1"
    set RigidIntensityRegistration(Repeat) 1

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set KullbackLeiblerRegistration(LearningRate)    3e-5
    set KullbackLeiblerRegistration(UpdateIterations) 100
    set KullbackLeiblerRegistration(TranslateScale)   320

    set KullbackLeiblerRegistration(NumberOfSamples)  50
    set KullbackLeiblerRegistration(SourceStandardDeviation) 0.4
    set KullbackLeiblerRegistration(TargetStandardDeviation) 0.4
    set KullbackLeiblerRegistration(HistSizeSource) 64
    set KullbackLeiblerRegistration(HistSizeTarget) 64
    set KullbackLeiblerRegistration(Epsilon)        1e-12
}


#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationFineParam
#
#  These parameters should allow the user the ability to intervene
#  and decide when he/she is done.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationFineParam {} {
    global KullbackLeiblerRegistration RigidIntensityRegistration

    set RigidIntensityRegistration(Resolution)       128
    set RigidIntensityRegistration(SourceShrinkFactors)   "1 1 1"
    set RigidIntensityRegistration(TargetShrinkFactors)   "1 1 1"
    set RigidIntensityRegistration(Repeat) 1

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set KullbackLeiblerRegistration(LearningRate)    3e-6
    set KullbackLeiblerRegistration(UpdateIterations) 100
    set KullbackLeiblerRegistration(TranslateScale)   320

    set KullbackLeiblerRegistration(SourceStandardDeviation) 0.4
    set KullbackLeiblerRegistration(TargetStandardDeviation) 0.4
    set KullbackLeiblerRegistration(NumberOfSamples)  50
    set KullbackLeiblerRegistration(HistSizeSource) 64
    set KullbackLeiblerRegistration(HistSizeTarget) 64
    set KullbackLeiblerRegistration(Epsilon)        1e-12
}


#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationGSlowParam
#
# This should run until completion and give a good registration
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationGSlowParam {} {
    global KullbackLeiblerRegistration RigidIntensityRegistration

    set RigidIntensityRegistration(Resolution)       128
    set RigidIntensityRegistration(SourceShrinkFactors)   "2 2 2"
    set RigidIntensityRegistration(TargetShrinkFactors)   "2 2 2"
    set RigidIntensityRegistration(Repeat) 0

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set KullbackLeiblerRegistration(LearningRate)    "0.0001 0.00001"
    set KullbackLeiblerRegistration(UpdateIterations) "500 1000"
    set KullbackLeiblerRegistration(TranslateScale)   320

    set KullbackLeiblerRegistration(NumberOfSamples)  50
    set KullbackLeiblerRegistration(SourceStandardDeviation) 0.4
    set KullbackLeiblerRegistration(TargetStandardDeviation) 0.4
    set KullbackLeiblerRegistration(HistSizeSource) 64
    set KullbackLeiblerRegistration(HistSizeTarget) 64
    set KullbackLeiblerRegistration(Epsilon)        1e-12
}

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationGSlowParam
#
# This should run until completion and give a good registration
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationVerySlowParam {} {
    global KullbackLeiblerRegistration RigidIntensityRegistration

    set RigidIntensityRegistration(Resolution)       128 
    set RigidIntensityRegistration(SourceShrinkFactors)   "4 4 1"
    set RigidIntensityRegistration(TargetShrinkFactors)   "4 4 1"
    set RigidIntensityRegistration(Repeat) 0

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set KullbackLeiblerRegistration(LearningRate)    "1e-4 1e-5 5e-6 1e-6 5e-7"
    set KullbackLeiblerRegistration(UpdateIterations) "2500 2500 2500 2500 2500"
    set KullbackLeiblerRegistration(TranslateScale)   320

    set KullbackLeiblerRegistration(NumberOfSamples)          "50"
    set KullbackLeiblerRegistration(SourceStandardDeviation) 0.4
    set KullbackLeiblerRegistration(TargetStandardDeviation) 0.4
    set KullbackLeiblerRegistration(HistSizeSource) 64
    set KullbackLeiblerRegistration(HistSizeTarget) 64
    set KullbackLeiblerRegistration(Epsilon)        1e-12
}


#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module.   This never gets called. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationEnter {} {
    global RigidIntensityRegistration KullbackLeiblerRegistration
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $KullbackLeiblerRegistration(eventManager)

    # clear the text box and put instructions there
    $KullbackLeiblerRegistration(textBox) delete 1.0 end
    $KullbackLeiblerRegistration(textBox) insert end "Shift-Click anywhere!\n"
}


#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.   This never gets called. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationExit {} {

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
# .PROC KullbackLeiblerRegistrationAutoRun
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationAutoRun {} {
    global Matrix RigidIntensityRegistration KullbackLeiblerRegistration

    if {[RigidIntensityRegistrationSetUp] == 0} {
      return 0
    }

    global Path env Gui Matrix Volume 
    global RigidIntensityRegistration KullbackLeiblerRegistration

    if {$KullbackLeiblerRegistration(TrainMovVol) == $Volume(idNone)} {
        DevWarningWindow "The Training Moving Volume is None! Please choose one."
        return 0
    }

    if {$KullbackLeiblerRegistration(TrainRefVol) == $Volume(idNone)} {
        DevWarningWindow "The Training Reference Volume is None! Please choose one."        return 0
    }


    # TODO make islicer a package
    source $env(SLICER_HOME)/Modules/iSlicer/tcl/isregistration.tcl

    ## if it is not already there, create it.
    set notalreadythere [catch ".kl cget -background"]
    if {$notalreadythere} {
        toplevel .kl
        wm withdraw .kl
        isregistration .kl.reg 
    }
    # catch "destroy .kl"

    .kl.reg config \
        -source          $RigidIntensityRegistration(sourceId)          \
        -target          $RigidIntensityRegistration(targetId)          \
        -resolution      $RigidIntensityRegistration(Resolution)        \
        -update_procedure RigidIntensityRegistrationUpdateParam         \
        -stop_procedure    KullbackLeiblerRegistrationStop              \
        -set_metric_option KullbackLeiblerRegistrationSetMetricOption   \
        -set_metric_option KullbackLeiblerRegistrationSetOptimizerOption \
        -vtk_itk_reg       vtkITKKullbackLeiblerTransform

    if {$::Module(verbose)} {
        puts "to see the pop-up window, type: pack .kl.reg -fill both -expand true"
    }
  #  pack .kl.reg -fill both -expand true
    $KullbackLeiblerRegistration(b1Run) configure -command \
                                      "KullbackLeiblerRegistrationStop"
    $KullbackLeiblerRegistration(b2Run) configure -command \
                                      "KullbackLeiblerRegistrationStop"
    $KullbackLeiblerRegistration(b1Run) configure -text "Stop"
    $KullbackLeiblerRegistration(b2Run) configure -text "Stop"
    .kl.reg start
}

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationStop
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationStop {} {
    global RigidIntensityRegistration KullbackLeiblerRegistration
.kl.reg stop
$KullbackLeiblerRegistration(b1Run) configure -command \
                                      "KullbackLeiblerRegistrationAutoRun"
$KullbackLeiblerRegistration(b2Run) configure -command \
                                      "KullbackLeiblerRegistrationAutoRun"
$KullbackLeiblerRegistration(b1Run) configure -text "Start"
$KullbackLeiblerRegistration(b2Run) configure -text "Start"
}

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerSetMetricOption
#
# takes in a vtkITKKullbackLeibler object
#
# .ARGS
# vtkITKKullbackLeibler vtkITKKL
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationSetMetricOption { vtkITKKL } {
    global KullbackLeiblerRegistration 

    $vtkITKKL SetSourceStandardDeviation $KullbackLeiblerRegistration(SourceStandardDeviation)
    $vtkITKKL SetTargetStandardDeviation $KullbackLeiblerRegistration(TargetStandardDeviation)
    $vtkITKKL SetNumberOfSamples $KullbackLeiblerRegistration(NumberOfSamples)

    $vtkITKKL SetHistSizeSource $KullbackLeiblerRegistration(HistSizeSource)
    $vtkITKKL SetHistSizeTarget $KullbackLeiblerRegistration(HistSizeSource)
    $vtkITKKL SetHistEpsilon    $KullbackLeiblerRegistration(Epsilon)

    KLTrainSourceChangeInfo SetInput \
        [Volume($KullbackLeiblerRegistration(TrainMovVol),vol) GetOutput]
    KLTrainSourceNorm Update
    KLTrainTargetChangeInfo SetInput \
        [Volume($KullbackLeiblerRegistration(TrainRefVol),vol) GetOutput]
    KLTrainTargetNorm Update

    $vtkITKKL SetTrainingSourceImage [KLTrainSourceNorm GetOutput]
    $vtkITKKL SetTrainingTargetImage [KLTrainTargetNorm GetOutput]
    $vtkITKKL SetTrainingTransform   [KullbackLeiblerRegistrationGetTrainingTransform ]
}

#-------------------------------------------------------------------------------
# .PROC  KullbackLeiblerRegistrationSetOptimizerOption
#
# takes in a vtkITKMutualInformation object
#
# .ARGS
# vtkITKMutualInformation vtkITKMI
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationSetOptimizerOption { vtkITKMI } {
    global KullbackLeiblerRegistration
    
    $vtkITKMI SetTranslateScale $KullbackLeiblerRegistration(TranslateScale)
    
    # set for MultiResStuff
    $vtkITKMI ResetMultiResolutionSettings

    foreach iter  $KullbackLeiblerRegistration(UpdateIterations) {
        $vtkITKMI SetNextMaxNumberOfIterations $iter
    }
    foreach rate $KullbackLeiblerRegistration(LearningRate) {
        $vtkITKMI SetNextLearningRate  $rate
    }
}

#-------------------------------------------------------------------------------
# .PROC RigidIntensityRegistrationCheckParametersKL
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RigidIntensityRegistrationCheckParametersKL {} {
    global MutualInformationRegistration RigidIntensityRegistration

    if {[llength $KullbackLeiblerRegistration(LearningRate) ] != \
        [llength $KullbackLeiblerRegistration(UpdateIterations) ] } {
        DevErrorWindow "Must Have same number of levels of iterations as learning rates"
       return 0
     }
    return 1
}

#-------------------------------------------------------------------------------
# .PROC KullbackLeiblerRegistrationGetTrainingTransform
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc KullbackLeiblerRegistrationGetTrainingTransform {}  {
    global KullbackLeiblerRegistration

   catch {vtkMatrix4x4 KLp1}
   catch {vtkMatrix4x4 KLp2}
   catch {vtkMatrix4x4 KLTrainMat}

   # p1 mat^-1 p2^-1  = p1 (p2 mat)^-1

   # target, reference,
   GetSlicerWldToItkMatrix \
      Volume($KullbackLeiblerRegistration(TrainRefVol),node) \
      KLp2

   KLp2 Invert

   # source, reference,
   GetSlicerWldToItkMatrix \
      Volume($KullbackLeiblerRegistration(TrainMovVol),node) \
      KLp1

   KLTrainMat Multiply4x4 KLp1 KLp2 KLTrainMat

   KLp1 Delete
   KLp2 Delete

   return KLTrainMat
# 0.979259 0.13248 0.153206 6.05993 
# -0.153108 0.979288 0.132382 -6.94748 
# -0.132494 -0.153123 0.979272 -0.00871529 
# -0 0 -0 1
}
