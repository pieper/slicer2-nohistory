#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: BIRNDUP.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:06 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        BIRNDUP.tcl
# PROCEDURES:  
#   BIRNDUPInit
#   BIRNDUPBuildGUI
#   BIRNDUPEnter
#   BIRNDUPExit
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
# This module support BIRN Deidentification and Upload (BIRNDUP)
# To find it when you run the Slicer, click on More->BIRNDUP.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC BIRNDUPInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc BIRNDUPInit {} {
    global BIRNDUP Module Volume Model

    set m BIRNDUP
    
    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "Perform Deidentification and Upload."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Steve Pieper, SPL, pieper@bwh.harvard.edu"

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
    set Module($m,row1List) "Help BIRNDUP"
    set Module($m,row1Name) "{Help} {BIRNDUP}"
    set Module($m,row1,tab) BIRNDUP



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
    #   set Module($m,procVTK) BIRNDUPBuildVTK
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
    set Module($m,procGUI) BIRNDUPBuildGUI
    set Module($m,procEnter) BIRNDUPEnter
    set Module($m,procExit) BIRNDUPExit

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
        {$Revision: 1.6 $} {$Date: 2006/01/06 17:57:06 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set BIRNDUP(dir)  ""
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
# .PROC BIRNDUPBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc BIRNDUPBuildGUI {} {
    global Gui BIRNDUP Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "LDMM" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(BIRNDUP,fLDMM)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # LDMM
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
    The BIRNDUP Module is used or organize dicom files for deidentification and upload.
    <BR>
    <LI><B>CREDIT:</B> Steve Pieper, Dingying Wei, Brian Boyd, Burak Ozyurt, Bruce Fischl and the Morphometry BIRN
    <BR>
    <LI><B>CREDIT:</B> See www.nbirn.net for BIRN details.
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>BIRNDUP:</B> Select the base directory that contains the dicom study.  Dialog box allows you to pick series to apply defacing algorithm to.  Other studies will be masked by the output of the \"master\" deface series.
    <BR>
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags BIRNDUP $help
    MainHelpBuildGUI BIRNDUP
    
# DDD1
    #-------------------------------------------
    # Deface frame
    #-------------------------------------------
    set fDeface $Module(BIRNDUP,fBIRNDUP)
    set f $fDeface
    # Frames
    frame $f.fActive -bg $Gui(backdrop) -relief sunken -bd 2 -height 20
    frame $f.fRange  -bg $Gui(activeWorkspace) -relief flat -bd 3

    pack $f.fActive -side top -pady $Gui(pad) -padx $Gui(pad)
    pack $f.fRange  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x



    #-------------------------------------------
    # Deface->Active frame
    #-------------------------------------------
    set f $fDeface.fActive

    eval {label $f.lActive -text "Active Volume: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Deface->Range frame
    #-------------------------------------------
    set f $fDeface.fRange

    eval {button $f.select -text "Run Interface" -width 20 -command "BIRNDUPInterface"} $Gui(WBA)
    
    pack $f.select -pady $Gui(pad) -side top -fill y -expand 1

# DDD2 
}

#-------------------------------------------------------------------------------
# .PROC BIRNDUPEnter
# Called when this module is entered by the user.  Place holder.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc BIRNDUPEnter {} {
    global BIRNDUP
}

#-------------------------------------------------------------------------------
# .PROC BIRNDUPExit
# Called when this module is exited by the user.   Place holder.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc BIRNDUPExit {} {
}


