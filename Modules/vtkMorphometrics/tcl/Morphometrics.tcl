#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Morphometrics.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:59 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        Morphometrics.tcl
# PROCEDURES:  
#   MorphometricsInit
#   MorphometricsBuildGUI
#   MorphometricsBuildVTK
#   MorphometricsEnter
#   MorphometricsExit
#   MorphometricsUpdateGUI
#   MorphometricsClearText textField
#   MorphometricsUpdateChooseMeasurementTab  tool
#   MorphometricsAddMeasurement nameOfTool nameOfWorkflow providedMeasurements initFunction
#   MorphometricsStartMeasure
#   MorphometricsGetTool nameOfTool
#   MorphometricsToolName tool
#   MorphometricsToolWorkflow tool
#   MorphometricsToolProvides tool
#   MorphometricsToolInitFunction tool
#   MorphometricsReplaceInitWithDummy
#==========================================================================auto=

# How to add a new morphometric tool:
# 1.) Write an initialization function for your tool. In this function you
#     call MorphometricsAddMeasurement with the tools name as well as the 
#     workflow of the tool, a list of measurements your tool provides and
#     a function which initializes your module.
#     For initializing your workflow use $Morphometrics(workflowFrame) as the
#     frame where the workflow should be displayed.
# 2.) Append your initialization function to the list of tool initialization 
#     functions:
#        lappend Morphometrics(measurementInitTools) <MyInitFunction>
#
# Comments:
#        - This two step approach is due to the fact that MorphometricsBuildGUI
#          has to be called prior to every call to MorphometricsAddMeasurement.
#        - Steps.tcl is a collection of step-factories, those may shorten 
#          development time for you ;)
#        - The Morphometrics module provides a Csys, helper functions are
#          available in CsysHelper.tcl
#===============================================================================
# Internal Structure:
# Basically the Morphometrics module keeps a list of available tools, updates
# the "Choose Morphometric Tool" tab whenever the user chooses another tool and
# provides a Csys for use by the tools. The list of available tools is 
# $Morphometrics(measurementTools), consider the entries of that list as objects
# and therefore use the "member" functions MorphometricsTool* to access information
# about a tool. $Morphometrics(measurementName) stores the name of the currently
# choosen tool. You can use MorphometricsGetTool in order to get the "object" 
# associated with a toolname.
#===============================================================================
#


#-------------------------------------------------------------------------------
# .PROC MorphometricsInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsInit {} {
    global Morphometrics Module Csys
    
    set m Morphometrics

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "Provides a framework for measuring anatomic structures as well as some concrete tools."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Axel Krauth, University of Passau, krauth@fmi.uni-passau.de"
    set Module($m,category) "Measurement"

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

    set Module($m,row1List) "Help ChooseMeasurement ToolWorkflow"
    set Module($m,row1Name) "{Help} {Choose Morphometric Tool} {<No tool choosen>}"
    set Module($m,row1,tab) ChooseMeasurement

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
    #   set Module($m,procVTK) MorphometricsBuildVTK
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
    #   
    set Module($m,procGUI) MorphometricsBuildGUI
    set Module($m,procVTK) MorphometricsBuildVTK
    set Module($m,procEnter) MorphometricsEnter
    set Module($m,procExit) MorphometricsExit
    set Module($m,procMRML) MorphometricsUpdateGUI

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) "Csys Workflow"
                                                                                
    # set to 1 when the Csys is visible and should be Picked on
    # mouse down
    set Csys(active) 1

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.9 $} {$Date: 2006/01/06 17:57:59 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set Morphometrics(measurementTools) {}
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
# .PROC MorphometricsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsBuildGUI {} {
    global Gui Morphometrics Module
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "ChooseMeasurement" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(Morphometrics,fChooseMeasurement)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # ChooseMeasurement
    #   Top
    #   Middle
    #    lProvides
    #    lProvidesText
    #   Bottom
    #    bStart
    # ToolWorkflow
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The Morphometrics module provides tools for measuring the geometry of anatomical structures. Furthermore
    it is a framework which allows rapid-prototyping of new morphometric tools.
    <BR>
    <BR>
    As a user you select an tool from the list of available tools, which is located at the top of the \"Choose Morphometric Tool\" tab. When you selected a tool, the measurements provided by the tool will appear below the list. Just press the \"Start measuring\" button to start the tool. 
    <BR>
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Help:</B> Guide to using the morphometrics module.
    <LI><B>Choose Morphometric Tool:</B> User specifies tool to use as well as can start the tool.
    <LI><B>\<nothing choosen yet\> (variable name):</B> Tab for the morphometric tools to display their workflow/results to the user
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags Morphometrics $help
    MainHelpBuildGUI Morphometrics


    #-------------------------------------------
    # ChooseMeasurement frame
    # Gives the user the possibility to
    # - choose which tool to use
    # - describe which measurement are provided
    # - start the choosen tool
    #-------------------------------------------
    set fChooseMeasurement $Module(Morphometrics,fChooseMeasurement)
    set f $fChooseMeasurement

    foreach frame "Top Middle Bottom" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # ChooseMeasurement-> Top frame : specify what you want to measure
    #-------------------------------------------
    set f $fChooseMeasurement.fTop

    label $f.lwhatToMeasure -padx 0 -pady $Gui(pad) -text "What to measure:" -bg $Gui(activeWorkspace)
    pack $f.lwhatToMeasure -side left -padx 0 -pady $Gui(pad)

    menubutton $f.mbAvailMeasurements -relief raised -bd 2 -width 13 -menu $f.mbAvailMeasurements.mAvailMeasurements -bg $Gui(activeWorkspace)
    menu $f.mbAvailMeasurements.mAvailMeasurements -tearoff false
    pack $f.mbAvailMeasurements -side left -padx 0 -pady $Gui(pad)

    pack $f.mbAvailMeasurements -side left -padx 0 -pady $Gui(pad)


    #-------------------------------------------
    # ChooseMeasurement-> Middle : let each tool write what it provides
    #-------------------------------------------
    set f $fChooseMeasurement.fMiddle
    label $f.lProvides  -padx 0 -pady $Gui(pad) -text "Provides:" -bg $Gui(activeWorkspace)
    pack $f.lProvides -side top -padx 0 -pady $Gui(pad)

    text $f.tProvidesText -wrap word -bg $Gui(normalButton) -height 5
    pack $f.tProvidesText -side top -padx $Gui(pad) -pady $Gui(pad)

    #--------------------------------------------
    # ChooseMeasurement-> Bottom : user starts the choosen tool
    #--------------------------------------------
    set f $fChooseMeasurement.fBottom
    DevAddButton $f.bStart "Start Measuring" MorphometricsStartMeasure
    pack $f.bStart -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ToolWorkflow frame : just empty
    #-------------------------------------------
    set Morphometrics(workflowFrame) $Module(Morphometrics,fToolWorkflow)

    # initialize factories    
    MorphometricsInitStepFactories

    # initialize every module
    if {[expr [llength $Morphometrics(measurementInitTools)] != 0]} {
    foreach iter $Morphometrics(measurementInitTools) {
        $iter
    }
    }


}
#-------------------------------------------------------------------------------
# .PROC MorphometricsBuildVTK
# as a Csys is always handy, one for general use is constructed
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsBuildVTK {} {
                                                                               
    global Morphometrics Csys

    CsysCreate Morphometrics csys -1 -1 -1
    Morphometrics(csys,actor) VisibilityOff
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsEnter
# Called when this module is entered by the user.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsEnter {} {
    global Morphometrics Csys
                                                                                
    MainAddActor Morphometrics(csys,actor)
    set Csys(active) 1
    Render3D
}



#-------------------------------------------------------------------------------
# .PROC MorphometricsExit
# Called when this module is exited by the user.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsExit {} {
    global Morphometrics Csys
                                                                                
    set Csys(active) 0
    MainRemoveActor Morphometrics(csys,actor)

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsUpdateGUI
# 
# This procedure is called to update the buttons
# due to such things as volumes or models being added or subtracted.
# (Note: to do this, this proc must be this module's procMRML.  Right now,
# these buttons are being updated automatically since they have been added
# to lists updated in VolumesUpdateMRML and ModelsUpdateMRML.  So this procedure
# is not currently used.)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsUpdateGUI {} {
}


#------------------------------------------------------------------------
# .PROC MorphometricsClearText
# Convenience function to clear a text field.
# .ARGS 
# str textField the name of the textfield to empty
# .END
#------------------------------------------------------------------------
proc MorphometricsClearText {textField} {
    $textField delete 1.0 end 
}


#------------------------------------------------------------------------
# .PROC MorphometricsUpdateChooseMeasurementTab 
# This function updates all visible entries in the ChooseMeasurementTab
# as well as some internal variables. The visible entries are the name of
# the "choose tool" menu at the top and which measurements are provided
# by the currently choosen tool.
# The function gets automatically called whenever the user choose one
# of the entries in the "choose tool" menu.
# .ARGS
# str tool name of the choosen tool
# .END
#------------------------------------------------------------------------
proc MorphometricsUpdateChooseMeasurementTab {tool} {
    global Morphometrics Module
    
    set tab $Module(Morphometrics,fChooseMeasurement)

    # set the name of the "choose tool" menu to the choosen tool in order
    # to give the user feedback which tool he has choosen
    $tab.fTop.mbAvailMeasurements configure -text [MorphometricsToolName [MorphometricsGetTool $tool]]

    # display which measurements are provided
    MorphometricsClearText $tab.fMiddle.tProvidesText 
    $tab.fMiddle.tProvidesText insert end [MorphometricsToolProvides [MorphometricsGetTool $tool]]

    # the name of the tool as well as the name of the workflow
    # are needed when the user presses the "start measuring" module    
    # todo: both variables should be superfluos
    set Morphometrics(measurementName) [MorphometricsToolName [MorphometricsGetTool $tool]]
    set Morphometrics(measurementWorkflow) [MorphometricsToolWorkflow [MorphometricsGetTool $tool]]
}


#------------------------------------------------------------------------
# .PROC MorphometricsAddMeasurement
#  Add a tool to the list of available morphometric tools. This is the only
#  function a tool has to call in order to be available through the Morphometrics
#  module.
# .ARGS
# str nameOfTool comprehensive name of the tool
# str nameOfWorkflow   name of the workflow of the tool
# str providedMeasurements list of measurements the user gets when using your tool
# str initFunction function which initializes the tool itself
# .END
#------------------------------------------------------------------------
proc MorphometricsAddMeasurement {nameOfTool nameOfWorkflow providedMeasurements initFunction} {
    global Morphometrics Module Gui

    # add it to the list of available tools
    lappend Morphometrics(measurementTools) [list $nameOfTool $nameOfWorkflow $providedMeasurements $initFunction]

    # add it to the user-visible list of available tools
    $Module(Morphometrics,fChooseMeasurement).fTop.mbAvailMeasurements.mAvailMeasurements add command -background $Gui(activeWorkspace) -command "MorphometricsUpdateChooseMeasurementTab [list $nameOfTool]" -label $nameOfTool

    # if it's the first tool to add, we call MorphometricsUpdateChooseMeasurementTab in order to have an
    # initially choosen tool
    if {[expr [llength $Morphometrics(measurementTools)] == 1]} {
    MorphometricsUpdateChooseMeasurementTab $nameOfTool
    }
}


#------------------------------------------------------------------------
# .PROC MorphometricsStartMeasure
# This function starts the workflow of the choosen tool. This consists of
# focusing and raising the tab where the workflow of each tool is located
# as well as starting the workflow
# .ARGS
# .END
#------------------------------------------------------------------------
proc  MorphometricsStartMeasure {} {
    global Morphometrics Module 

    # clean the workflowFrame
    set allSlaves [pack slaves $Morphometrics(workflowFrame)]
    foreach iter $allSlaves { destroy $iter}

    # set the title of the last tab to the anatomic module, focus and raise that tab
    set index_actual [lsearch $Module(Morphometrics,row1List) ToolWorkflow]
    
    lset Module(Morphometrics,row1Name) $index_actual $Morphometrics(measurementName)
    $Module(Morphometrics,bToolWorkflow) invoke
    $Module(Morphometrics,bToolWorkflow) configure -text $Morphometrics(measurementName)

    # initialize the module:
    eval [MorphometricsToolInitFunction [MorphometricsGetTool $Morphometrics(measurementName)]]
    
    # and replace its init function by a dummy call, thus the init function will be called once
    MorphometricsReplaceInitWithDummy

    # Then we start the workflow
    WorkflowStart [MorphometricsToolWorkflow [MorphometricsGetTool $Morphometrics(measurementName)]]
}


#------------------------------------------------------------------------
# .PROC MorphometricsGetTool
# Retrieve all the information the module has about the tool named "nameOfTool".
# Don't disassemble the result yourself, use MorphometricsTool* to get the information
# you're interested in.
# .ARGS
# str nameOfTool name of the tool for which information is needed
# .END
#------------------------------------------------------------------------
proc MorphometricsGetTool {nameOfTool} {
    global Morphometrics
    foreach tool $Morphometrics(measurementTools) {
    if { [expr [string compare [MorphometricsToolName $tool] $nameOfTool] == 0]} {
        return $tool
    }
    }
    return {}
}

#------------------------------------------------------------------------
# .PROC MorphometricsToolName
# Retrieve the name of the tool encapsulated in the variable tool, which
# is the internal representation of a morphometric tool
# .ARGS
# list tool internal representation of a tool
# .END
#------------------------------------------------------------------------
proc MorphometricsToolName {tool} {
    return [lindex $tool 0]
}

#------------------------------------------------------------------------
# .PROC MorphometricsToolWorkflow
# Retrieve the name of the workflow encapsulated in the variable tool, which
# is the internal representation of a morphometric tool
# .ARGS
# list tool internal representation of a tool
# .END
#------------------------------------------------------------------------
proc MorphometricsToolWorkflow {tool} {
   return [lindex $tool 1]
}

#------------------------------------------------------------------------
# .PROC MorphometricsToolProvides
# Retrieve a list of the measurements the tool provides. The variable tool
# is the internal representation of a morphometric tool
# .ARGS
# list tool internal representation of a tool
# .END
#------------------------------------------------------------------------
proc MorphometricsToolProvides {tool} {
    return [lindex $tool 2]
}

#------------------------------------------------------------------------
# .PROC MorphometricsToolInitFunction
# Retrieve the init function of the tool. The variable tool
# is the internal representation of a morphometric tool
# .ARGS
# list tool internal representation of a tool
# .END
#------------------------------------------------------------------------
proc MorphometricsToolInitFunction {tool} {
    return [lindex $tool 3]
}


#------------------------------------------------------------------------
# .PROC MorphometricsReplaceInitWithDummy
# Replaces the init function of the currently choosen tool by a dummy function.
# This is needed in order to ensure, that the init function is only called once.
# .ARGS
# .END
#------------------------------------------------------------------------
proc MorphometricsReplaceInitWithDummy {} {
    global Morphometrics
    set index [lsearch -exact $Morphometrics(measurementTools) [MorphometricsGetTool $Morphometrics(measurementName)]]
    set newTool [lreplace [MorphometricsGetTool $Morphometrics(measurementName)]  3 3 MorphometricsDoNothingOnEnterExit]
    set Morphometrics(measurementTools) [lreplace $Morphometrics(measurementTools) $index $index $newTool]
}
