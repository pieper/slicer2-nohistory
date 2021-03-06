#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: AffineMattesMIRegistration.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:03 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        AffineMattesMIRegistration.tcl
# PROCEDURES:  
#   AffineMattesMIRegistrationInit
#   AffineMattesMIRegistrationBuildSubGui f
#   AffineMattesMIRegistrationSetLevel
#   AffineMattesMIRegistrationCoarseParam
#   AffineMattesMIRegistrationFineParam
#   AffineMattesMIRegistrationGSlowParam
#   AffineMattesMIRegistrationGSlowParam
#   AffineMattesMIRegistrationEnter
#   AffineMattesMIRegistrationExit
#   AffineMattesMIRegistrationAutoRun
#   AffineMattesMIRegistrationStop
#   MutualInformationSetMetricOption vtkITKMI
#   AffineMattesMIRegistrationSetOptimizerOption vtkITKMI
#   RigidIntensityRegistrationCheckParametersAffineMattesMI
#   AffineMattesMIRegistrationAutoRun_Vtk
#   AffineMattesMIRegistrationCopyRegImages res r v
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationInit {} {
    global RigidIntensityRegistration AffineMattesMIRegistration 
    global Module Volume Model

    set m AffineMattesMIRegistration

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
    #   set Module($m,procVTK) AffineMattesMIRegistrationBuildVTK
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

#    set Module($m,procGUI) AffineMattesMIRegistrationBuildGUI
#    set Module($m,procVTK) AffineMattesMIRegistrationBuildVTK
#    set Module($m,procEnter) AffineMattesMIRegistrationEnter
#    set Module($m,procExit) AffineMattesMIRegistrationExit

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
        {$Revision: 1.9 $} {$Date: 2006/01/06 17:58:03 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #

    ## put here to show MI specific param
    set AffineMattesMIRegistration(NumberOfSamples)  5000
    set AffineMattesMIRegistration(NumberOfHistogramBins) 256
    set AffineMattesMIRegistration(Resample) 1

    ## Set the default to fast registration
    AffineMattesMIRegistrationVerySlowParam
}

#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationBuildSubGui
#
# Build the sub-gui under $f whatever frame is calling this one
#
# Example Useg: MIBuildSubGui $f.fMI
#
# .ARGS
# frame f frame name
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationBuildSubGui {f} {
    global Gui Matrix RigidIntensityRegistration AffineMattesMIRegistration

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
            -text "$level" -command "AffineMattesMIRegistrationSetLevel" \
            -variable AffineMattesMIRegistration(Level) -value $level -width 10 \
            -indicatoron 0} $Gui(WRA)
        set AffineMattesMIRegistration(r${level}) $f.r$level
        pack $f.r$level -side left -padx 0 
    }

    set AffineMattesMIRegistration(Level) Normal

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
        set AffineMattesMIRegistration(f${type}) $f.f${type}
    }
    raise $AffineMattesMIRegistration(fNormal)

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
    The .mi window is left open and the pipeline is left taking lots of 
    memory.
    </UL>"

    regsub -all "\n" $help { } help
    MainHelpApplyTags AffineMattesMIRegistration $help
#    MainHelpBuildGUI  AffineMattesMIRegistration 

    global Help
    set f  $fhelp
    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true
    set tmp [HelpWidget $f.fWidget]
    MainHelpShow $tmp AffineMattesMIRegistration

    #-------------------------------------------
    # Level->Normal frame
    #-------------------------------------------

    set f $fnormal

    frame $f.fDesc    -bg $Gui(activeWorkspace)
    frame $f.fSpeed   -bg $Gui(activeWorkspace)
    frame $f.fRepeat  -bg $Gui(activeWorkspace)
    frame $f.fRun     -bg $Gui(activeWorkspace)

    pack $f.fDesc $f.fSpeed $f.fRepeat $f.fRun -pady $Gui(pad) 

    #-------------------------------------------
    # Level->Normal->Desc frame
    #-------------------------------------------
    set f $fnormal.fDesc

    eval {label $f.l -text "\Press 'Start' to perform automatic\n registration by Mutual Information.\n\Your manual registration is used\n\ as an initial pose.\ "} $Gui(WLA)
    pack $f.l -pady $Gui(pad)

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
        -command AffineMattesMIRegistration${value}Param \
        -variable AffineMattesMIRegistration(Objective) \
        -indicatoron 0} $Gui(WCA) 
        pack $f.fBtns.$row.r$value -side left -padx 4 -pady 2
        if { $value == "Fine" } {incr row};
        if { $value == "GSlow" } {incr row};
    }

   set AffineMattesMIRegistration(Objective) VerySlow

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
              -variable AffineMattesMIRegistration(Repeat) } $Gui(WCA)
        pack $f.f.r$value -side left -fill x -anchor w
    }

    #-------------------------------------------
    # Level->Normal->Run frame
    #-------------------------------------------
    set f $fnormal.fRun

    eval {button $f.bRun -text "Start" -width [expr [string length "Start"]+1] \
            -command "AffineMattesMIRegistrationAutoRun"} $Gui(WBA)

    pack $f.bRun -side left -padx $Gui(pad) -pady $Gui(pad)
    set AffineMattesMIRegistration(b1Run) $f.bRun

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
                   {Resample} \
                   {UpdateIterations} \
                   {MinimumStepLength} \
                   {MaximumStepLength} \
                   {TranslateScale} \
                   {NumberOfSamples} \
                   {NumberOfHistogramBins} \
                   } name \
                  { \
                   {Resample Dimension Reduction} \
                   {Update Iterations} \
                   {Minimum Step Length} \
                   {Maximum Step Length} \
                   {Translate Scale} \
                   {Number Of Samples} \
                   {Number Of Histogram Bins} \
                   } {
        set f $fadvanced.fParam
        frame $f.f$param   -bg $Gui(activeWorkspace)
        pack $f.f$param -side top -fill x -pady 2
        
        set f $f.f$param
        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 10 -textvariable AffineMattesMIRegistration($param)} $Gui(WEA)
        pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
        pack $f.e$param -side left -padx $Gui(pad) -expand 1
    }

    #-------------------------------------------
    # Level->Advanced->Run frame
    #-------------------------------------------
    set f $fadvanced.fRun

    foreach str "Run" {
        eval {button $f.b$str -text "$str" -width [expr [string length $str]+1] \
            -command "AffineMattesMIRegistrationAuto$str"} $Gui(WBA)
        set AffineMattesMIRegistration(b$str) $f.b$str
    }
    pack $f.bRun -side left -padx $Gui(pad) -pady $Gui(pad)
    set AffineMattesMIRegistration(b2Run) $f.bRun
}  

#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationSetLevel
#
# Set the registration mechanism depending on which button the user selected in
# the Auto tab.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationSetLevel {} {
    global AffineMattesMIRegistration RigidIntensityRegistration

    set level $AffineMattesMIRegistration(Level)
    raise $AffineMattesMIRegistration(f${level})
    focus $AffineMattesMIRegistration(f${level})
    set value $AffineMattesMIRegistration(Objective)
    AffineMattesMIRegistration${value}Param 
}

#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationCoarseParam
#
#  These parameters should allow the user the ability to intervene
#  and decide when he/she is done.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationCoarseParam {} {
    global AffineMattesMIRegistration RigidIntensityRegistration

    set AffineMattesMIRegistration(SourceShrinkFactors)   "1 1 1"
    set AffineMattesMIRegistration(TargetShrinkFactors)   "1 1 1"
    set AffineMattesMIRegistration(Repeat) 1

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set AffineMattesMIRegistration(Resample)       4
    set AffineMattesMIRegistration(MinimumStepLength)    0.01
    set AffineMattesMIRegistration(MaximumStepLength)    2.0
    set AffineMattesMIRegistration(UpdateIterations) 30
    set AffineMattesMIRegistration(TranslateScale)   0.0002

    set AffineMattesMIRegistration(NumberOfSamples)  3000
    set AffineMattesMIRegistration(NumberOfHistogramBins) 20
}


#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationFineParam
#
#  These parameters should allow the user the ability to intervene
#  and decide when he/she is done.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationFineParam {} {
    global AffineMattesMIRegistration RigidIntensityRegistration

    set AffineMattesMIRegistration(SourceShrinkFactors)   "1 1 1"
    set AffineMattesMIRegistration(TargetShrinkFactors)   "1 1 1"
    set AffineMattesMIRegistration(Repeat) 1

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set AffineMattesMIRegistration(Resample)       2
    set AffineMattesMIRegistration(MinimumStepLength)     0.01
    set AffineMattesMIRegistration(MaximumStepLength)     1.0
    set AffineMattesMIRegistration(UpdateIterations) 30
    set AffineMattesMIRegistration(TranslateScale)   0.0002

    set AffineMattesMIRegistration(NumberOfHistogramBins) 50
    set AffineMattesMIRegistration(NumberOfSamples)  8000
}


#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationGSlowParam
#
# This should run until completion and give a good registration
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationGSlowParam {} {
    global AffineMattesMIRegistration RigidIntensityRegistration

    set AffineMattesMIRegistration(SourceShrinkFactors)   "2 2 2"
    set AffineMattesMIRegistration(TargetShrinkFactors)   "2 2 2"
    set AffineMattesMIRegistration(Repeat) 0

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set AffineMattesMIRegistration(Resample)       1
    set AffineMattesMIRegistration(UpdateIterations) "500 1000"
    set AffineMattesMIRegistration(MinimumStepLength)    "0.02 0.01"
    set AffineMattesMIRegistration(MaximumStepLength)    "4.0 1.0"
    set AffineMattesMIRegistration(TranslateScale)   0.0002

    set AffineMattesMIRegistration(NumberOfSamples)  50000
    set AffineMattesMIRegistration(NumberOfHistogramBins) 200
}

#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationGSlowParam
#
# This should run until completion and give a good registration
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationVerySlowParam {} {
    global AffineMattesMIRegistration RigidIntensityRegistration

    set AffineMattesMIRegistration(SourceShrinkFactors)   "4 4 4"
    set AffineMattesMIRegistration(TargetShrinkFactors)   "4 4 4"
    set AffineMattesMIRegistration(Repeat) 0

    # If Wells, Viola, Atsumi, etal, 
    # used 2 and 4. Wells claims exact number not critical (personal communication)
    # They scaled data 0...256.
    # We scale data -1 to 1.
    # 2/256*2 = 0.015
    set AffineMattesMIRegistration(Resample)       1
    set AffineMattesMIRegistration(UpdateIterations) "1000 1000 1000"
    set AffineMattesMIRegistration(MinimumStepLength) "0.01 0.01 0.005"
    set AffineMattesMIRegistration(MaximumStepLength) "4.0 1 0.5"
    set AffineMattesMIRegistration(TranslateScale)   0.0002

    set AffineMattesMIRegistration(NumberOfSamples)   100000
    set AffineMattesMIRegistration(NumberOfHistogramBins) 256

}


#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. This never gets called.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationEnter {} {
    global AffineMattesMIRegistration RigidIntensityRegistration
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $AffineMattesMIRegistration(eventManager)

    # clear the text box and put instructions there
    $AffineMattesMIRegistration(textBox) delete 1.0 end
    $AffineMattesMIRegistration(textBox) insert end "Shift-Click anywhere!\n"
}


#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationExit
# Called when this module is exited by the user.  Pops the event manager
# for this module. This never gets called. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationExit {} {

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
# .PROC AffineMattesMIRegistrationAutoRun
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationAutoRun {} {
    global Matrix AffineMattesMIRegistration RigidIntensityRegistration

    if {[RigidIntensityRegistrationSetUp] == 0} {
      return 0
    }

    if {$::Module(verbose)} { 
        puts "Starting AffineMattesMIRegistrationAutoRun"
    }

#    Gering version disabled
#    AffineMattesMIRegistrationAutoRun_Vtk  

    global Path env Gui Matrix Volume AffineMattesMIRegistration

    # TODO make islicer a package
    source $env(SLICER_HOME)/Modules/iSlicer/tcl/isregistration.tcl

    # NOTE: destroying and creating isregistration
    # is not efficient but it's a workaround the cleanup issue
    # in isregistration

    ## if it is not already there, create it.
    #if { [info command .mi.reg] == "" } {
        catch ".mi.reg pre_delete"
        catch "destroy .mi"
        toplevel .mi
        wm withdraw .mi
        isregistration .mi.reg
    #}

    set RigidIntensityRegistration(SourceShrinkFactors) $AffineMattesMIRegistration(SourceShrinkFactors)
    set RigidIntensityRegistration(TargetShrinkFactors) $AffineMattesMIRegistration(TargetShrinkFactors)
    set RigidIntensityRegistration(Repeat) $AffineMattesMIRegistration(Repeat)

    .mi.reg config \
        -source          $RigidIntensityRegistration(sourceId)          \
        -target          $RigidIntensityRegistration(targetId)          \
        -update_procedure RigidIntensityRegistrationUpdateParam        \
        -stop_procedure    AffineMattesMIRegistrationStop            \
        -set_metric_option AffineMattesMIRegistrationSetMetricOption \
        -set_optimizer_option AffineMattesMIRegistrationSetOptimizerOption \
        -resample         $AffineMattesMIRegistration(Resample)          \
        -vtk_itk_reg       vtkITKAffineMattesMIRegistrationFilter               


    if {$::Module(verbose)} {
        puts "to see the pop-up window, type: pack .mi.reg -fill both -expand true"
    }
  #  pack .mi.reg -fill both -expand true
    $AffineMattesMIRegistration(b1Run) configure -command \
                                      "AffineMattesMIRegistrationStop"
    $AffineMattesMIRegistration(b2Run) configure -command \
                                      "AffineMattesMIRegistrationStop"
    $AffineMattesMIRegistration(b1Run) configure -text "Stop"
    $AffineMattesMIRegistration(b2Run) configure -text "Stop"
    if {$::Module(verbose)} {
        puts "AffineMattesMIRegistrationAutoRun: calling .mi.reg start"
    }
    .mi.reg start
    if {$::Module(verbose)} { 
        puts "AffineMattesMIRegistrationAutoRun: done .mi.reg"
    }
}

#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationStop
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationStop {} {
    global AffineMattesMIRegistration RigidIntensityRegistration
    .mi.reg stop
    $AffineMattesMIRegistration(b1Run) configure -command \
                                          "AffineMattesMIRegistrationAutoRun"
    $AffineMattesMIRegistration(b2Run) configure -command \
                                          "AffineMattesMIRegistrationAutoRun"
    $AffineMattesMIRegistration(b1Run) configure -text "Start"
    $AffineMattesMIRegistration(b2Run) configure -text "Start"
}


#-------------------------------------------------------------------------------
# .PROC MutualInformationSetMetricOption
#
# takes in a vtkITKMutualInformation object
#
# .ARGS
# vtkITKMutualInformation vtkITKMI
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationSetMetricOption { vtkITKMI } {
    global AffineMattesMIRegistration 

    $vtkITKMI SetNumberOfHistogramBins $AffineMattesMIRegistration(NumberOfHistogramBins)
    $vtkITKMI SetNumberOfSamples $AffineMattesMIRegistration(NumberOfSamples)

}


#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationSetOptimizerOption
#
# takes in a vtkITKMutualInformation object
#
# .ARGS
# vtkITKMutualInformation vtkITKMI
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationSetOptimizerOption { vtkITKMI } {
    global AffineMattesMIRegistration
    
    $vtkITKMI SetTranslateScale $AffineMattesMIRegistration(TranslateScale)
    
    # set for MultiResStuff
    $vtkITKMI ResetMultiResolutionSettings

    foreach iter  $AffineMattesMIRegistration(UpdateIterations) {
        $vtkITKMI SetNextMaxNumberOfIterations $iter
    }
    foreach step $AffineMattesMIRegistration(MinimumStepLength) {
        $vtkITKMI SetNextMinimumStepLength $step
        puts "min step = $step"
    }
    foreach step $AffineMattesMIRegistration(MaximumStepLength) {
        $vtkITKMI SetNextMaximumStepLength $step
        puts "max step = $step"
    }
}

#-------------------------------------------------------------------------------
# .PROC RigidIntensityRegistrationCheckParametersAffineMattesMI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RigidIntensityRegistrationCheckParametersAffineMattesMI {} {
    global AffineMattesMIRegistration RigidIntensityRegistration

    if {([llength $AffineMattesMIRegistration(MinimumStepLength) ] != \
        [llength $AffineMattesMIRegistration(UpdateIterations) ]) &&  \
        ([llength $AffineMattesMIRegistration(MaximumStepLength) ] != \
             [llength $AffineMattesMIRegistration(UpdateIterations) ])} {
        DevErrorWindow "Must Have same number of levels of iterations as learning rates"
       return 0
    }
    return 1
}


#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationAutoRun_Vtk
#
#
# These are the tools written by Dave Gering (and implemented by Hanifa Dostmohamed)
# They are not currently used, though they should work.
# But, I'm not really sure.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationAutoRun_Vtk {} {
    global Path env Gui Matrix Volume AffineMattesMIRegistration

    if {$::Module(verbose)} { puts "starting AffineMattesMIRegistrationAutoRun_Vtk..." }

    # v = ID of volume to register
    # r = ID of reference volume
    set v $Matrix(volume)
    set r $Matrix(refVolume)

    # Store which transform we're editing
    # If the user has not selected a tranform, then create a new one by default
    # and append it to the volume to register (ie. "Volume to Move")
    set t $Matrix(activeID)

    catch "refTrans Delete"
    catch "subTrans Delete"
    catch "initMatrix Delete"
    catch "initPose Delete"
    catch "reg Delete"

    vtkRasToIjkTransform refTrans
    eval refTrans SetExtent  [[Volume($r,vol) GetOutput] GetExtent]
    eval refTrans SetSpacing [[Volume($r,vol) GetOutput] GetSpacing]
    refTrans SetSlicerMatrix [Volume($r,node) GetRasToIjk]
    refTrans ComputeCornersFromSlicerMatrix

    vtkRasToIjkTransform subTrans
    eval subTrans SetExtent  [[Volume($v,vol) GetOutput] GetExtent]
    eval subTrans SetSpacing [[Volume($v,vol) GetOutput] GetSpacing]
    subTrans SetSlicerMatrix [Volume($v,node) GetRasToIjk]
    subTrans ComputeCornersFromSlicerMatrix

    # Get the initial Pose
    # This is either identity when no manual reg has been done
    # or the matrix obtained from manual registration
    set tran   [Matrix($t,node) GetTransform]
    set matrix [$tran GetMatrix]
    vtkMatrix4x4 initMatrix
    initMatrix DeepCopy $matrix
    initMatrix Invert
    vtkPose initPose
    initPose ConvertFromMatrix4x4 initMatrix
    if {$::Module(verbose)} { puts "Initial Pose = [initPose Print]" }

    # Run MI Registration
    vtkImageMIReg reg
    if {$::Module(verbose)} {
        puts "vtkImageMIReg: setting DebugOn for reg"
        reg DebugOn
    }
    reg SetReference [Volume($r,vol) GetOutput]
    reg SetSubject   [Volume($v,vol) GetOutput]
    reg SetRefTrans refTrans
    reg SetSubTrans subTrans
    reg SetInitialPose initPose

    # Set parameters (ordered from small res to large)
    reg SetNumIterations 16000 4000 4000 4000
    reg SetLambdaDisplacement .2 0.1 0.05 0.01
    reg SetLambdaRotation 0.00005 0.00002 0.000005 0.000001
    reg SetSampleSize 50
    reg SetSigmaUU 2
    reg SetSigmaVV 2
    reg SetSigmaV 4
    reg SetPMin 0.01
    reg SetUpdateIterations 200

    # Initialize (downsample images)
    set res -1
    set resDisplay 3
    set Gui(progressText) "MI Initializing"
    MainStartProgress
    MainShowProgress reg
    if {$::Module(verbose)} {
        puts "\t calling first reg Update"
    }
    reg Update
    if {$::Module(verbose)} {
        puts "\t done first reg Update"
    }

    # Iterate
    while {[reg GetInProgress] == 1} {
        reg Update
        if {$::Module(verbose)} {
            puts "\t done reg Update in progress loop"
        }
        # Update the pose (set the transform's matrix)
        set currentPose [reg GetCurrentPose]
        $currentPose ConvertToMatrix4x4 $matrix
        $matrix Invert

        # If we're not done, then display intermediate results
        if {[reg GetInProgress] == 1} {

          # Print out the current status
          set res  [reg GetResolution]
          set iter [reg GetIteration]
          set Gui(progressText) "MI res=$res iter=$iter"
          if {$::Module(verbose)} {
              puts "\t still in progress, set progressText to $Gui(progressText)"
          }
          MainShowProgress reg

          # Update the image data to display
          # Copy the new Subject if its resolution changed since last update
          if {$res != $resDisplay} {
              if {$::Module(verbose)} { puts "Current Pose at res=$res is: [$currentPose Print]" } 
            set resDisplay $res
            AffineMattesMIRegistrationCopyRegImages $res $r $v
          }
        }

        if {$::Module(verbose)} {
            puts "AffineMattesMIRegistration\t calling main update mrml and renderall"
        }
        # Update MRML and display
        MainUpdateMRML
        RenderAll
   }
    if {$::Module(verbose)} { 
        puts "\t AffineMattesMIRegistration done loop"
    }
   MainEndProgress

   # Cleanup
   refTrans Delete
   subTrans Delete
   initMatrix Delete
   initPose Delete
   reg Delete

   #Return the user back to the pick alignment mode tab
   set Matrix(regMode) ""
   raise $Matrix(fAlignBegin)
}

#-------------------------------------------------------------------------------
# .PROC AffineMattesMIRegistrationCopyRegImages
#
# Stuff for Dave Gering implementation
#
# .ARGS
# int res
# int r
# int v
# .END
#-------------------------------------------------------------------------------
proc AffineMattesMIRegistrationCopyRegImages {res r v} {
  global Volume

  #
  # Copy Subject
  #

  # Copy the downsampled ImageData
  vtkImageCopy copy
  copy SetInput [reg GetSub $res]
  copy Update
  copy SetInput ""
  Volume($v,vol) SetImageData [copy GetOutput]
  copy SetOutput ""
  copy Delete

  # Copy the RasToIjk matrix of downsampled data
  set imgMatrix [[reg GetSubRasToIjk $res] GetRasToIjk]
    if {$::Module(verbose)} { puts "Subject RasToIjk = [$imgMatrix Print]" }
  set n Volume($v,node)
  set str [$n GetMatrixToString $imgMatrix]
  $n SetRasToVtkMatrix $str
  $n UseRasToVtkMatrixOn

  # Update pipeline and GUI
  MainVolumesUpdate $v

  #
  # Copy Reference
  #

  # Copy the downsampled ImageData
  vtkImageCopy copy
  copy SetInput [reg GetRef $res]
  copy Update
  copy SetInput ""
  Volume($r,vol) SetImageData [copy GetOutput]
  copy SetOutput ""
  copy Delete

  # Copy the RasToIjk matrix of downsampled data
  set imgMatrix [[reg GetRefRasToIjk $res] GetRasToIjk]
  # puts "Reference RasToIjk = [$imgMatrix Print]"
  set n Volume($r,node)
  set str [$n GetMatrixToString $imgMatrix]
  $n SetRasToVtkMatrix $str
  $n UseRasToVtkMatrixOn

  # Update pipeline and GUI
  MainVolumesUpdate $r
}
