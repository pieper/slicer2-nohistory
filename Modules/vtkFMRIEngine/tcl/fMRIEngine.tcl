#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngine.tcl,v $
#   Date:      $Date: 2006/05/30 19:45:32 $
#   Version:   $Revision: 1.29 $
# 
#===============================================================================
# FILE:        fMRIEngine.tcl
# PROCEDURES:  
#   fMRIEngineInit
#   fMRIEngineBuildGUI
#   fMRIEngineUpdateHelpTab
#   fMRIEngineEnter
#   fMRIEngineExit
#   fMRIEnginePushBindings 
#   fMRIEnginePopBindings 
#   fMRIEngineCreateBindings  
#   fMRIEngineProcessMouseEvent the
#==========================================================================auto=
#-------------------------------------------------------------------------------
#  Description
# This module computes activation volume from a sequence of fMRI images. 
# To find it when you run the Slicer, click on More->fMRIEngine.
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# .PROC fMRIEngineInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineInit {} {
    global fMRIEngine Module Volume Model env

    # module dependency on BLT 
    if { [catch "package require BLT"] } {
        DevErrorWindow "Must have the BLT package to load module fMRIEngine." 
        return
    }
    # module dependency on MultiVolumeReader 
    if {[catch "package require MultiVolumeReader"]} {
        DevErrorWindow "Must have module MultiVolumeReader to load module fMRIEngine." 
        return
    }
    # module dependency on vtkMIRIASegment 
    if {[catch "package require vtkMIRIADSegment"]} {
        DevErrorWindow "Must have module MIRIADSegment to load module fMRIEngine." 
        return
    } 

    set m fMRIEngine

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "Computes fMRI activation volume."

    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Wendy Plesniak, SPL, wjp@bwh.harvard.edu; Haiying Liu, SPL, hliu@bwh.harvard.edu"
    set Module($m,category) "Application"

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
    #   
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #
    set Module($m,row1List) "Help Sequence Setup Detect Priors ROI View"
    set Module($m,row1Name) "{Help} {Sequence} {Set Up} {Detect} {Priors} {ROI} {View}"
    set Module($m,row1,tab) Sequence 

    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources all *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #
    #   set Module($m,procVTK) fMRIEngineBuildVTK
    #
    #   All the options are:
    #
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
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) fMRIEngineBuildGUI
    set Module($m,procEnter) fMRIEngineEnter
    set Module($m,procExit) fMRIEngineExit

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
#    set Module($m,depend) "MultiVolumeReader"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.29 $} {$Date: 2006/05/30 19:45:32 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set fMRIEngine(dir)  ""
    set fMRIEngine(currentTab) "Sequence"
    set fMRIEngine(modulePath) "$env(SLICER_HOME)/Modules/vtkFMRIEngine"

    set fMRIEngine(baselineEVsAdded) 0
    set fMRIEngine(detectionMethod) GLM 

    # For now, spew heavily.
    # this bypasses the command line setting of --verbose or -v
    # set Module(verbose) 0
    
    # Creates bindings
    fMRIEngineCreateBindings 

    # Source all appropriate tcl files here. 
    source "$fMRIEngine(modulePath)/tcl/fMRIEnginePlot.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineModel.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineInspect.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineCompute.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineSequence.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineHelpText.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineContrasts.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineModelView.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineSignalModeling.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineParadigmDesign.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineRegionAnalysis.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineUserInputForModelView.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEngineSaveAndLoadParadigm.tcl"
    source "$fMRIEngine(modulePath)/tcl/fMRIEnginePriors.tcl"

  
}


# NAMING CONVENTION:
#-------------------------------------------------------------------------------
#
# Use the following starting letters for names:
# t  = toplevel
# f  = frame
# mb = menubutton
# m  = menu
# b  = button
# l  = label
# s  = slider
# i  = image
# c  = checkbox
# r  = radiobutton
# e  = entry
#
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildGUI
# Creates the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildGUI {} {
    global Gui fMRIEngine Module Volume Model

    # A frame has already been constructed automatically for each tab.
    # A frame named "FMRI" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(fMRIEngine,fFMRI)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # FMRI
    #   Top
    #   Middle
    #   Bottom
    #     FileLabel
    #     CountDemo
    #     TextBox
    #-------------------------------------------
    
    #-------------------------------------------
    # Help tab 
    #-------------------------------------------
    set b $Module(fMRIEngine,bHelp)
    bind $b <1> "fMRIEngineUpdateHelpTab" 

    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    set help "

    The fMRIEngine module is intended to process and display fMRI data.
    <BR><BR>
    <B>Sequence</B> allows you to load or select a sequence of fMRI \
    volumes to process.
    <BR>
    <B>Set Up</B> allows you to specify paradigm design, signal modeling and \
    contrasts, to estimate the linear modeling and save/load the beta volume, \
    and to save/load/view a design.
    <BR>
    <B>Detect</B> lets you to choose contrast(s) to compute \
    activation volume(s).
    <BR>
    <B>Priors</B> 
    <BR>
    <B>ROI</B> enables you to create a labelmap, to perform region of interest \
    analysis, and to view the stats results out of the defined roi.
    <BR>
    <B>View</B> gives you the ability to view the activation \
    at different thresholds and dynamically plot any voxel \
    time course.
    <BR><BR>
    Check the file README.txt in the docs directory of this module \
    for details about how to use the module.
    <BR><BR><B>Warning</B>: It may not be possible to run this process \
    to completion on Windows, due to memory allocation constraints.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags fMRIEngine $help
    MainHelpBuildGUI fMRIEngine

    set helpWidget $fMRIEngine(helpWidget) 
    $helpWidget configure -height 22

    #-------------------------------------------
    # Sequence tab 
    #-------------------------------------------
    set b $Module(fMRIEngine,bSequence)
    bind $b <1> "fMRIEngineUpdateSequenceTab" 

    set fSequence $Module(fMRIEngine,fSequence)
    set f $fSequence
    frame $f.fOption -bg $Gui(activeWorkspace) 
    grid $f.fOption -row 0 -column 0 -sticky ew 
    
    #------------------------------
    # Sequence->Option frame
    #------------------------------
    set f $fSequence.fOption

    #--- create blt notebook
    blt::tabset $f.tsNotebook -relief flat -borderwidth 0
    pack $f.tsNotebook -side top

    #--- notebook configure
    $f.tsNotebook configure -width 240
    $f.tsNotebook configure -height 410 
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
    foreach t "Load Select" {
        $f.tsNotebook insert $i $t
        frame $f.tsNotebook.f$t -bg $Gui(activeWorkspace) -bd 2 
        fMRIEngineBuildUIFor${t} $f.tsNotebook.f$t

        $f.tsNotebook tab configure $t -window $f.tsNotebook.f$t 
        $f.tsNotebook tab configure $t -activebackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -selectbackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -background $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -fill both -padx $::Gui(pad) -pady 1 

        incr i
    }
 
    #-------------------------------------------
    # Setup tab 
    #-------------------------------------------
    set fSetup $Module(fMRIEngine,fSetup)
    fMRIEngineBuildUIForSetupTab $fSetup
    set b $Module(fMRIEngine,bSetup)
    bind $b <1> "fMRIEngineUpdateSetupTab" 

    #-------------------------------------------
    # Priors tab 
    #-------------------------------------------
    set fPriors $Module(fMRIEngine,fPriors)
    fMRIEngineBuildUIForPriorsTab $fPriors
    set b $Module(fMRIEngine,bPriors)
    bind $b <1> "fMRIEngineUpdatePriorsTab $fPriors" 

    #-------------------------------------------
    # ROI tab 
    #-------------------------------------------
    set fROI $Module(fMRIEngine,fROI)
    fMRIEngineBuildUIForROITab $fROI
    set b $Module(fMRIEngine,bROI)
    bind $b <1> "fMRIEngineUpdateBGVolumeList; \
        fMRIEngineUpdateCondsForROIPlot"
 
    #-------------------------------------------
    # Detect tab 
    #-------------------------------------------
    set fDetect $Module(fMRIEngine,fDetect)
    fMRIEngineBuildUIForComputeTab $fDetect
    set b $Module(fMRIEngine,bDetect)
    bind $b <1> "fMRIEngineUpdateContrastList" 

    #-------------------------------------------
    # View tab 
    #-------------------------------------------
    set fView $Module(fMRIEngine,fView)
    fMRIEngineBuildUIForViewTab $fView
    set b $Module(fMRIEngine,bView)
    bind $b <1> "fMRIEngineUpdateViewTab;fMRIEngineUpdateEVsForPlotting"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateHelpTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateHelpTab {} {
    global fMRIEngine

    set fMRIEngine(currentTab) "Help"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineEnter
# Called when this module is entered by the user. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineEnter {} {
    global fMRIEngine Volume

    set Volume(name) ""

    fMRIEngineUpdateSequences

    #--- push all event bindings onto the stack.
    fMRIEnginePushBindings

    #--- For now, hide it; not fully integrated yet.
    #if {[winfo exists $toplevelName]} {
    #    lower $toplevelName
    #    wm iconify $toplevelName
    #}
}
 

#-------------------------------------------------------------------------------
# .PROC fMRIEngineExit
# Called when this module is exited by the user
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineExit {} {

    # pop event bindings
    fMRIEnginePopBindings
}


#-------------------------------------------------------------------------------
# .PROC fMRIEnginePushBindings 
# Pushes onto the event stack a new event manager that
# deals with events when the fMRIEngine module is active
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePushBindings {} {
   global Ev Csys

    EvActivateBindingSet FMRISlice0Events
    EvActivateBindingSet FMRISlice1Events
    EvActivateBindingSet FMRISlice2Events
}


#-------------------------------------------------------------------------------
# .PROC fMRIEnginePopBindings 
# Removes bindings when fMRIEnginer module is inactive
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEnginePopBindings {} {
    global Ev Csys

    EvDeactivateBindingSet FMRISlice0Events
    EvDeactivateBindingSet FMRISlice1Events
    EvDeactivateBindingSet FMRISlice2Events
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineCreateBindings  
# Creates fMRIEngine event bindings for the three slice windows 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineCreateBindings {} {
    global Gui Ev

    EvDeclareEventHandler fMRIEngineSlicesEvents <1> \
        {set xc %x; set yc %y; fMRIEngineProcessMouseEvent $xc $yc}

    EvAddWidgetToBindingSet FMRISlice0Events $Gui(fSl0Win) {fMRIEngineSlicesEvents}
    EvAddWidgetToBindingSet FMRISlice1Events $Gui(fSl1Win) {fMRIEngineSlicesEvents}
    EvAddWidgetToBindingSet FMRISlice2Events $Gui(fSl2Win) {fMRIEngineSlicesEvents}    
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineProcessMouseEvent
# Processes mouse click on the three slice windows
# .ARGS
# x the X coordinate; y the Y coordinate
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineProcessMouseEvent {x y} {
    global fMRIEngine 

    if {$fMRIEngine(currentTab) == "ROI"} {
        fMRIEngineClickROI $x $y
    } elseif {$fMRIEngine(currentTab) == "Inspect"} {
        set fMRIEngine(voxelLocation,x) $x
        set fMRIEngine(voxelLocation,y) $y
        set fMRIEngine(timecoursePlot) "Voxel"
        fMRIEnginePlotTimecourse
    } else {
    }
}
