#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DeformableDemonsRegistration.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:03 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        DeformableDemonsRegistration.tcl
# PROCEDURES:  
#   DeformableDemonsRegistrationInit
#   DeformableDemonsRegistrationBuildSubGui f
#   DeformableDemonsRegistrationSetLevel
#   DeformableDemonsRegistrationCoarseParam
#   DeformableDemonsRegistrationFineParam
#   DeformableDemonsRegistrationGSlowParam
#   DeformableDemonsRegistrationGSlowParam
#   DeformableDemonsRegistrationEnter
#   DeformableDemonsRegistrationExit
#   DeformableDemonsRegistrationAutoRun
#   DeformableDemonsRegistrationVolumeExists name
#   DeformableDemonsRegistrationStop
#   MutualInformationSetMetricOption vtkITKMI
#   DeformableDemonsRegistrationSetOptimizerOption vtkITKMI
#   RigidIntensityRegistrationCheckParametersDeformableDemons
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationInit {} {
    global RigidIntensityRegistration DeformableDemonsRegistration 
    global Module Volume Model

    set m DeformableDemonsRegistration

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
    #   set Module($m,procVTK) DeformableDemonsRegistrationBuildVTK
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

#    set Module($m,procGUI) DeformableDemonsRegistrationBuildGUI
#    set Module($m,procVTK) DeformableDemonsRegistrationBuildVTK
#    set Module($m,procEnter) DeformableDemonsRegistrationEnter
#    set Module($m,procExit) DeformableDemonsRegistrationExit

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
        {$Revision: 1.5 $} {$Date: 2006/01/06 17:58:03 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #

    ## put here to show MI specific param
    set DeformableDemonsRegistration(NumberOfHistogramLevels)  20
    set DeformableDemonsRegistration(StandardDeviations)  1.0
    set DeformableDemonsRegistration(UpdateFieldStandardDeviations)  0.0
    set DeformableDemonsRegistration(UpdateIterations) 50
    set DeformableDemonsRegistration(ThresholdAtMeanIntensity)  1
    set DeformableDemonsRegistration(Resample) 1
    set DeformableDemonsRegistration(defVolName) "deformation_volume"

    ## Set the default to fast registration
    DeformableDemonsRegistrationFineParam
}

#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationBuildSubGui
#
# Build the sub-gui under $f whatever frame is calling this one
#
# Example Useg: MIBuildSubGui $f.fMI
#
# .ARGS
# frame f frame name
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationBuildSubGui {f} {
    global Gui Matrix RigidIntensityRegistration DeformableDemonsRegistration

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
            -text "$level" -command "DeformableDemonsRegistrationSetLevel" \
            -variable DeformableDemonsRegistration(Level) -value $level -width 10 \
            -indicatoron 0} $Gui(WRA)
        set DeformableDemonsRegistration(r${level}) $f.r$level
        pack $f.r$level -side left -padx 0 
    }

    set DeformableDemonsRegistration(Level) Normal

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
        set DeformableDemonsRegistration(f${type}) $f.f${type}
    }
    raise $DeformableDemonsRegistration(fNormal)

    set fnormal   $framename.fLevel.fNormal
    set fadvanced $framename.fLevel.fAdvanced
    set fhelp     $framename.fLevel.fHelp

    #-------------------------------------------
    # Level->Help frame
    #-------------------------------------------

    set help "
    <UL>
    <LI><B>The Algorithm </B> 
    <LI><B>Limitations</B>
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
    Change these at your own risk. 
    <LI><B>Known Bugs</B>
    The .mi window is left open and the pipeline is left taking lots of 
    memory.
    </UL>"

    regsub -all "\n" $help { } help
    MainHelpApplyTags DeformableDemonsRegistration $help
#    MainHelpBuildGUI  DeformableDemonsRegistration 

    global Help
    set f  $fhelp
    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true
    set tmp [HelpWidget $f.fWidget]
    MainHelpShow $tmp DeformableDemonsRegistration

    #-------------------------------------------
    # Level->Normal frame
    #-------------------------------------------

    set f $fnormal

    frame $f.fDesc    -bg $Gui(activeWorkspace)
    frame $f.fSpeed   -bg $Gui(activeWorkspace)
    frame $f.fDeform  -bg $Gui(activeWorkspace)
    frame $f.fRun     -bg $Gui(activeWorkspace)

    pack $f.fDesc $f.fSpeed $f.fDeform $f.fRun -pady $Gui(pad) 

    #-------------------------------------------
    # Level->Normal->Desc frame
    #-------------------------------------------
    set f $fnormal.fDesc

    eval {label $f.l -text "\Press 'Start' to perform automatic\n registration by Demons Registration.\n\Your manual registration is used\n\ as an initial pose.\ "} $Gui(WLA)
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
        -command DeformableDemonsRegistration${value}Param \
        -variable DeformableDemonsRegistration(Objective) \
        -indicatoron 0} $Gui(WCA) 
        pack $f.fBtns.$row.r$value -side left -padx 4 -pady 2
        if { $value == "Fine" } {incr row};
        if { $value == "GSlow" } {incr row};
    }

    set DeformableDemonsRegistration(Objective) Fine
    
    
    #-------------------------------------------
    # Level->Normal->Deformation
    #-------------------------------------------
    set f $fnormal.fDeform
    
    eval {label $f.l -text "Deformation Volume name:"} $Gui(WLA)
    eval {entry $f.edeform -width 10 -textvariable DeformableDemonsRegistration(defVolName)} $Gui(WEA)
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w
    pack $f.edeform -side left -padx $Gui(pad) -expand 1

    #-------------------------------------------
    # Level->Normal->Run frame
    #-------------------------------------------
    set f $fnormal.fRun

    eval {button $f.bRun -text "Start" -width [expr [string length "Start"]+1] \
            -command "DeformableDemonsRegistrationAutoRun"} $Gui(WBA)

    pack $f.bRun -side left -padx $Gui(pad) -pady $Gui(pad)
    set DeformableDemonsRegistration(b1Run) $f.bRun

    #-------------------------------------------
    # Level->Advanced
    #-------------------------------------------

    set f $fadvanced

    frame $f.fParam    -bg $Gui(activeWorkspace)
    frame $f.fRun      -bg $Gui(activeWorkspace)

    pack $f.fParam $f.fRun -pady $Gui(pad) 

    foreach param { \
                   {Resample} \
                   {UpdateIterations} \
                   {StandardDeviations} \
                   {UpdateFieldStandardDeviations} \
                   {NumberOfHistogramLevels} \
                   {ThresholdAtMeanIntensity} \
                   } name \
                  { \
                   {Resample Dimension Reduction} \
                   {Update Iterations} \
                   {Standard Deviations} \
                   {UpdateField StandardDeviations} \
                   {Number Of Histogram Levels} \
                   {Threshold At Mean Intensity} \
                   } {
        set f $fadvanced.fParam
        frame $f.f$param   -bg $Gui(activeWorkspace)
        pack $f.f$param -side top -fill x -pady 2
        
        set f $f.f$param
        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 10 -textvariable DeformableDemonsRegistration($param)} $Gui(WEA)
        pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
        pack $f.e$param -side left -padx $Gui(pad) -expand 1
    }

    #-------------------------------------------
    # Level->Advanced->Run frame
    #-------------------------------------------
    set f $fadvanced.fRun

    foreach str "Run" {
        eval {button $f.b$str -text "$str" -width [expr [string length $str]+1] \
            -command "DeformableDemonsRegistrationAuto$str"} $Gui(WBA)
        set DeformableDemonsRegistration(b$str) $f.b$str
    }
    pack $f.bRun -side left -padx $Gui(pad) -pady $Gui(pad)
    set DeformableDemonsRegistration(b2Run) $f.bRun
}  

#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationSetLevel
#
# Set the registration mechanism depending on which button the user selected in
# the Auto tab.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationSetLevel {} {
    global DeformableDemonsRegistration RigidIntensityRegistration

    set level $DeformableDemonsRegistration(Level)
    raise $DeformableDemonsRegistration(f${level})
    focus $DeformableDemonsRegistration(f${level})
    set value $DeformableDemonsRegistration(Objective)
    DeformableDemonsRegistration${value}Param 
}

#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationCoarseParam
#
#  These parameters should allow the user the ability to intervene
#  and decide when he/she is done.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationCoarseParam {} {
    global DeformableDemonsRegistration RigidIntensityRegistration

    set DeformableDemonsRegistration(Resample)       3
    set DeformableDemonsRegistration(UpdateIterations) "50 50"
    set DeformableDemonsRegistration(StandardDeviations) 1.0
    set DeformableDemonsRegistration(UpdateFieldStandardDeviations) 0
    set DeformableDemonsRegistration(ThresholdAtMeanIntensity) 1
    set DeformableDemonsRegistration(NumberOfHistogramLevels) 40
}


#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationFineParam
#
#  These parameters should allow the user the ability to intervene
#  and decide when he/she is done.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationFineParam {} {
    global DeformableDemonsRegistration RigidIntensityRegistration

    set DeformableDemonsRegistration(Resample)       2
    set DeformableDemonsRegistration(UpdateIterations) "100 50 30"
    set DeformableDemonsRegistration(StandardDeviations) 1.0
    set DeformableDemonsRegistration(UpdateFieldStandardDeviations) 1.0
    set DeformableDemonsRegistration(ThresholdAtMeanIntensity) 1
    set DeformableDemonsRegistration(NumberOfHistogramLevels) 50
}


#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationGSlowParam
#
# This should run until completion and give a good registration
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationGSlowParam {} {
    global DeformableDemonsRegistration RigidIntensityRegistration

    set DeformableDemonsRegistration(Resample)       1
    set DeformableDemonsRegistration(UpdateIterations) "100 50"
    set DeformableDemonsRegistration(StandardDeviations) 1.0
    set DeformableDemonsRegistration(UpdateFieldStandardDeviations) 1.0
    set DeformableDemonsRegistration(ThresholdAtMeanIntensity) 1
    set DeformableDemonsRegistration(NumberOfHistogramLevels) 50
}

#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationGSlowParam
#
# This should run until completion and give a good registration
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationVerySlowParam {} {
    global DeformableDemonsRegistration RigidIntensityRegistration

    set DeformableDemonsRegistration(Resample)       1
    set DeformableDemonsRegistration(UpdateIterations) "100 100 50"
    set DeformableDemonsRegistration(StandardDeviations) 1.0
    set DeformableDemonsRegistration(UpdateFieldStandardDeviations) 1.0
    set DeformableDemonsRegistration(ThresholdAtMeanIntensity) 1
    set DeformableDemonsRegistration(NumberOfHistogramLevels) 50
}


#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. This never gets called.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationEnter {} {
    global DeformableDemonsRegistration RigidIntensityRegistration
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $DeformableDemonsRegistration(eventManager)

    # clear the text box and put instructions there
    $DeformableDemonsRegistration(textBox) delete 1.0 end
    $DeformableDemonsRegistration(textBox) insert end "Shift-Click anywhere!\n"
}


#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationExit
# Called when this module is exited by the user.  Pops the event manager
# for this module. This never gets called. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationExit {} {

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
# .PROC DeformableDemonsRegistrationAutoRun
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationAutoRun {} {
    global Matrix DeformableDemonsRegistration RigidIntensityRegistration

    if {[RigidIntensityRegistrationSetUp] == 0} {
      return 0
    }

    if {$::Module(verbose)} { 
        puts "Starting DeformableDemonsRegistrationAutoRun"
    }

#    Gering version disabled
#    DeformableDemonsRegistrationAutoRun_Vtk  

    global Path env Gui Matrix Volume DeformableDemonsRegistration

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

    set RigidIntensityRegistration(Repeat) 0

    .mi.reg config \
        -normalize  0 \
        -source          $RigidIntensityRegistration(sourceId)          \
        -target          $RigidIntensityRegistration(targetId)          \
        -update_procedure RigidIntensityRegistrationUpdateParam        \
        -stop_procedure    DeformableDemonsRegistrationStop            \
        -set_metric_option DeformableDemonsRegistrationSetMetricOption \
        -set_optimizer_option DeformableDemonsRegistrationSetOptimizerOption \
        -resample         $DeformableDemonsRegistration(Resample)          \
        -vtk_itk_reg       vtkITKDemonsTransformRegistrationFilter               


    if {$::Module(verbose)} {
        puts "to see the pop-up window, type: pack .mi.reg -fill both -expand true"
    }
  #  pack .mi.reg -fill both -expand true
    $DeformableDemonsRegistration(b1Run) configure -command \
                                      "DeformableDemonsRegistrationStop"
    $DeformableDemonsRegistration(b2Run) configure -command \
                                      "DeformableDemonsRegistrationStop"
    $DeformableDemonsRegistration(b1Run) configure -text "Stop"
    $DeformableDemonsRegistration(b2Run) configure -text "Stop"
    if {$::Module(verbose)} {
        puts "DeformableDemonsRegistrationAutoRun: calling .mi.reg start"
    }
    .mi.reg start
    if {$::Module(verbose)} { 
        puts "DeformableDemonsRegistrationAutoRun: done .mi.reg"
    }
    
    # create result name
    set resVolName $DeformableDemonsRegistration(defVolName)
        
    # check if the result name exists already
    if {[DeformableDemonsRegistrationVolumeExists $resVolName] == "1"} {
        set count 0
        while {1} {
            set name $resVolName
            append name $count
            if {[DeformableDemonsRegistrationVolumeExists $name] == "0"} {
                set resVolName $name
                break
            }
            incr count
        }
    }

    .mi.reg deformation_volume $resVolName
}

#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationVolumeExists
# 
# .ARGS
# string name
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationVolumeExists {name} {
    global Volume
    foreach v $Volume(idList) {
        set index [lsearch -exact $name [Volume($v,node) GetName]]
        if {$index > -1} {
            # name exists
            return 1
        }
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationStop
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationStop {} {
    global DeformableDemonsRegistration RigidIntensityRegistration
    .mi.reg stop
    $DeformableDemonsRegistration(b1Run) configure -command \
                                          "DeformableDemonsRegistrationAutoRun"
    $DeformableDemonsRegistration(b2Run) configure -command \
                                          "DeformableDemonsRegistrationAutoRun"
    $DeformableDemonsRegistration(b1Run) configure -text "Start"
    $DeformableDemonsRegistration(b2Run) configure -text "Start"
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
proc DeformableDemonsRegistrationSetMetricOption { vtkITKMI } {
    global DeformableDemonsRegistration 

}


#-------------------------------------------------------------------------------
# .PROC DeformableDemonsRegistrationSetOptimizerOption
#
# takes in a vtkITKMutualInformation object
#
# .ARGS
# vtkITKMutualInformation vtkITKMI
# .END
#-------------------------------------------------------------------------------
proc DeformableDemonsRegistrationSetOptimizerOption { vtkITKMI } {
    global DeformableDemonsRegistration
    
    $vtkITKMI ResetMultiResolutionSettings

    foreach iter  $DeformableDemonsRegistration(UpdateIterations) {
        $vtkITKMI SetNextMaxNumberOfIterations $iter
    }

    $vtkITKMI SetStandardDeviations $DeformableDemonsRegistration(StandardDeviations)
    $vtkITKMI SetUpdateFieldStandardDeviations $DeformableDemonsRegistration(UpdateFieldStandardDeviations)
    $vtkITKMI SetNumberOfHistogramLevels $DeformableDemonsRegistration(NumberOfHistogramLevels)
    if {$DeformableDemonsRegistration(ThresholdAtMeanIntensity) != 0} {
        $vtkITKMI ThresholdAtMeanIntensityOn
    } else {
        $vtkITKMI ThresholdAtMeanIntensityOff
    }
}

#-------------------------------------------------------------------------------
# .PROC RigidIntensityRegistrationCheckParametersDeformableDemons
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RigidIntensityRegistrationCheckParametersDeformableDemons {} {
    global DeformableDemonsRegistration RigidIntensityRegistration

    return 1
}
