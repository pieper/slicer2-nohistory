#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Custom.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:58 $
#   Version:   $Revision: 1.35 $
# 
#===============================================================================
# FILE:        Custom.tcl
# PROCEDURES:  
#   CustomInit
#   CustomBuildGUI
#   CustomEnter
#   CustomExit
#   CustomUpdateGUI
#   CustomCount
#   CustomShowFile
#   CustomBindingCallback
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
#  This module is an example for developers.  It shows how to add a module 
#  to the Slicer.  To find it when you run the Slicer, click on More->Custom.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are (some of) the variables defined by this module.
# 
#  int Custom(count) counts the button presses for the demo 
#  list Custom(eventManager)  list of event bindings used by this module
#  widget Custom(textBox)  the text box widget
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC CustomInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CustomInit {} {
    global Custom Module Volume Model

    set m Custom
    
    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is an example of how to add modules to slicer."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "First name, last name, affiliation, email"

    #  Set the functional category that this module falls under, from the list defined in Main.tcl,
    #  Module(categories), or set your own.
    #  This is included in the Help->Module Categories menu item
    set Module($m,category) "Example"

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
    set Module($m,row1List) "Help Stuff"
    set Module($m,row1Name) "{Help} {Tons o' Stuff}"
    set Module($m,row1,tab) Stuff



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
    #   set Module($m,procVTK) CustomBuildVTK
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
    set Module($m,procGUI) CustomBuildGUI
    set Module($m,procEnter) CustomEnter
    set Module($m,procExit) CustomExit

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) ""

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.35 $} {$Date: 2006/01/06 17:56:58 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set Custom(count) 0
    set Custom(Volume1) $Volume(idNone)
    set Custom(Model1)  $Model(idNone)
    set Custom(FileName)  ""

    # Event bindings! (see CustomEnter, CustomExit, tcl-shared/Events.tcl)
    set Custom(eventManager)  { \
        {all <Shift-1> {CustomBindingCallback Shift-1 %W %X %Y %x %y %t}} \
        {all <Shift-2> {CustomBindingCallback Shift-2 %W %X %Y %x %y %t}} \
        {all <Shift-3> {CustomBindingCallback Shift-3 %W %X %Y %x %y %t}} }
    
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
# .PROC CustomBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc CustomBuildGUI {} {
    global Gui Custom Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(Custom,fStuff)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Stuff
    #   Top
    #   Middle
    #   Bottom
    #     FileLabel
    #     CountDemo
    #     TextBox
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The Custom module is an example for developers.  It shows how to add a module 
    to the Slicer.  The source code is in slicer/program/tcl-modules/Custom.tcl.
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Tons o' Stuff:</B> This tab is a demo for developers.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags Custom $help
    MainHelpBuildGUI Custom
    
    #-------------------------------------------
    # Stuff frame
    #-------------------------------------------
    set fStuff $Module(Custom,fStuff)
    set f $fStuff
    
    foreach frame "Top Middle Bottom" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # Stuff->Top frame
    #-------------------------------------------
    set f $fStuff.fTop
    
    #       grid $f.lStuff -padx $Gui(pad) -pady $Gui(pad)
    #       grid $menubutton -sticky w
    
    # Add menus that list models and volumes
    DevAddSelectButton  Custom $f Volume1 "Ref Volume" Grid
    DevAddSelectButton  Custom $f Model1  "Ref Model"  Grid
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbVolume1
    lappend Volume(mActiveList) $f.mbVolume1.m
    lappend Model(mbActiveList) $f.mbModel1
    lappend Model(mActiveList) $f.mbModel1.m
    
    #-------------------------------------------
    # Stuff->Middle frame
    #-------------------------------------------
    set f $fStuff.fMiddle
    
    # file browse box
    DevAddFileBrowse $f Custom FileName "File" CustomShowFile

    # confirm user's existence
    DevAddLabel $f.lfile "You entered: <no filename yet>"
    pack $f.lfile -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    set Custom(lfile) $f.lfile

    #-------------------------------------------
    # Stuff->Bottom frame
    #-------------------------------------------
    set f $fStuff.fBottom
    
    # make frames inside the Bottom frame for nice layout
    foreach frame "CountDemo TextBox" {
    frame $f.f$frame -bg $Gui(activeWorkspace) 
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    $f.fTextBox config -relief groove -bd 3 

    #-------------------------------------------
    # Stuff->Bottom->CountDemo frame
    #-------------------------------------------
    set f $fStuff.fBottom.fCountDemo

    DevAddLabel $f.lStuff "You clicked 0 times."
    pack $f.lStuff -side top -padx $Gui(pad) -fill x
    set Custom(lStuff) $f.lStuff
    
    # Here's a button with text "Count" that calls "CustomCount" when
    # pressed.
    DevAddButton $f.bCount Count CustomCount 
    
    # Tooltip example: Add a tooltip for the button
    TooltipAdd $f.bCount "Press this button to increment the counter."

    # entry box
    eval {entry $f.eCount -width 5 -textvariable Custom(count) } $Gui(WEA)
    
    pack $f.bCount $f.eCount -side left -padx $Gui(pad) -pady $Gui(pad)
    

    #-------------------------------------------
    # Stuff->Bottom->TextBox frame
    #-------------------------------------------
    set f $fStuff.fBottom.fTextBox

    # this is a convenience proc from tcl-shared/Developer.tcl
    DevAddLabel $f.lBind "Bindings Demo"
    pack $f.lBind -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    # here's the text box widget from tcl-shared/Widgets.tcl
    set Custom(textBox) [ScrolledText $f.tText]
    pack $f.tText -side top -pady $Gui(pad) -padx $Gui(pad) \
        -fill x -expand true
    
}

#-------------------------------------------------------------------------------
# .PROC CustomEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CustomEnter {} {
    global Custom
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $Custom(eventManager)

    # clear the text box and put instructions there
    $Custom(textBox) delete 1.0 end
    $Custom(textBox) insert end "Shift-Click anywhere!\n"

}

#-------------------------------------------------------------------------------
# .PROC CustomExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CustomExit {} {

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
# .PROC CustomUpdateGUI
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
proc CustomUpdateGUI {} {
    global Custom Volume
    
    DevUpdateNodeSelectButton Volume Custom Volume1 Volume1 DevSelectNode
    DevUpdateNodeSelectButton Model  Custom Model1  Model1  DevSelectNode
}



#-------------------------------------------------------------------------------
# .PROC CustomCount
#
# This routine demos how to make button callbacks and use global arrays
# for object oriented programming.
# .END
#-------------------------------------------------------------------------------
proc CustomCount {} {
    global Custom
    
    incr Custom(count)
    $Custom(lStuff) config -text "You clicked the button $Custom(count) times"
}


#-------------------------------------------------------------------------------
# .PROC CustomShowFile
#
# This routine demos how to make button callbacks and use global arrays
# for object oriented programming.
# .END
#-------------------------------------------------------------------------------
proc CustomShowFile {} {
    global Custom
    
    $Custom(lfile) config -text "You entered: $Custom(FileName)"
}


#-------------------------------------------------------------------------------
# .PROC CustomBindingCallback
# Demo of callback routine for bindings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CustomBindingCallback { event W X Y x y t } {
    global Custom

    set insertText "$event at: $X $Y\n"
    
    switch $event {
    "Shift-2" {
        set insertText "Don't poke the Slicer!\n"
    }
    "Shift-3" {
        set insertText "Ouch!\n"
    }

    }
    $Custom(textBox) insert end $insertText

}
