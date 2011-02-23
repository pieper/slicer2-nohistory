#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: FluxDiffusion.tcl,v $
#   Date:      $Date: 2006/05/26 19:38:25 $
#   Version:   $Revision: 1.15 $
# 
#===============================================================================
# FILE:        FluxDiffusion.tcl
# PROCEDURES:  
#   FluxDiffusionInit
#   FluxDiffusionUpdateGUI
#   FluxDiffusionBuildGUI
#   FluxDiffusionBuildHelpFrame
#   FluxDiffusionBuildMainFrame
#   FluxDiffusionBuildExpertFrame
#   FluxDiffusionEnter
#   FluxDiffusionExit
#   FluxDiffusionCount
#   FluxDiffusionShowFile
#   FluxDiffusionBindingCallback event W X Y x y t
#   FluxDiffusionPrepareResult
#   FluxDiffusionPrepareResultVolume
#   RunFluxDiffusion
#==========================================================================auto=
#   ==================================================
#   Module: vtkFluxDiffusion
#   Author: Karl Krissian
#   Email:  karl@bwh.harvard.edu
#
#   This module implements a version of anisotropic diffusion published in 
#    
#   "Flux-Based Anisotropic Diffusion Applied to Enhancement of 3D Angiographiam"
#   Karl Krissian
#   IEEE Trans. Medical Imaging, 21(11), pp 1440-1442, nov 2002.
#    
#   It aims at restoring 2D and 3D images with the ability to preserve
#   small and elongated structures.
#   It comes with a Tcl/Tk interface for the '3D Slicer'.
#   ==================================================
#   Copyright (C) 2002  Karl Krissian
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#   ================================================== 
#   The full GNU Lesser General Public License file is in vtkFluxDiffusion/LesserGPL_license.txt



#-------------------------------------------------------------------------------
#  Description
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are (some of) the variables defined by this module.
# 
#  int FluxDiffusion(count) counts the button presses for the demo 
#  list FluxDiffusion(eventManager)  list of event bindings used by this module
#  widget FluxDiffusion(textBox)  the text box widget
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionInit {} {
    global FluxDiffusion Module Volume 
    
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
    set m FluxDiffusion
    set Module($m,row1List) "Help Main Expert"
    set Module($m,row1Name) "{Help} {Main} {Expert}"
    set Module($m,row1,tab) Main

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
    #   set Module($m,procVTK) FluxDiffusionBuildVTK
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
    set Module($m,procGUI)   FluxDiffusionBuildGUI
    set Module($m,procEnter) FluxDiffusionEnter
    set Module($m,procExit)  FluxDiffusionExit
    set Module($m,procMRML)  FluxDiffusionUpdateGUI

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) ""

    set Module($m,overview) "Anisotropic diffusion, using the basis formed by the gradient\n\t\tand the principal curvature directions and smoothes differently in each direction."
    set Module($m,author) "Karl Krissian, SPL, karl@bwh.harvard.edu"
    set Module($m,category) "Filtering"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.15 $} {$Date: 2006/05/26 19:38:25 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
 
    set FluxDiffusion(InputVol)      $Volume(idNone)
    set FluxDiffusion(ResultVol)     $Volume(idNone)
    set FluxDiffusion(Dimension)     "3"
    set FluxDiffusion(StandardDev)   "1"
    set FluxDiffusion(Threshold)     "10"
    set FluxDiffusion(Attachment)    "0.05"
    set FluxDiffusion(Iterations)    "5"
    set FluxDiffusion(IsoCoeff)      "0.2"
    set FluxDiffusion(TruncNegValues)  "1"

    vtkMultiThreader FluxDiffusion(vtk,v)
    set FluxDiffusion(NumberOfThreads)   [FluxDiffusion(vtk,v) GetGlobalDefaultNumberOfThreads]
    FluxDiffusion(vtk,v) Delete

    set FluxDiffusion(TangCoeff)     "1"

    set FluxDiffusion(MincurvCoeff)  "1"
    set FluxDiffusion(MaxcurvCoeff)  "0.1"

    # Event bindings! (see FluxDiffusionEnter, FluxDiffusionExit, tcl-shared/Events.tcl)
    set FluxDiffusion(eventManager)  { \
        {all <Shift-1> {FluxDiffusionBindingCallback Shift-1 %W %X %Y %x %y %t}} \
        {all <Shift-2> {FluxDiffusionBindingCallback Shift-2 %W %X %Y %x %y %t}} \
        {all <Shift-3> {FluxDiffusionBindingCallback Shift-3 %W %X %Y %x %y %t}} }
}


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionUpdateGUI
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
proc FluxDiffusionUpdateGUI {} {
    global FluxDiffusion Volume
    
    DevUpdateNodeSelectButton Volume FluxDiffusion InputVol   InputVol   DevSelectNode
    DevUpdateNodeSelectButton Volume FluxDiffusion ResultVol  ResultVol  DevSelectNode 0 1 1
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
# .PROC FluxDiffusionBuildGUI
#
# Create the Graphical User Interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionBuildGUI {} {
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Parameters" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(FluxDiffusion,fMain)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Parameters
    #-------------------------------------------
    
    FluxDiffusionBuildHelpFrame
       
    FluxDiffusionBuildExpertFrame

    FluxDiffusionBuildMainFrame


}

#-------------------------------------------------------------------------------
# .PROC FluxDiffusionBuildHelpFrame
#
#   Create the Help frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionBuildHelpFrame {} {


    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The FluxDiffusion module contains a version of Anisotropic Diffusion
    developped by K. Krissian.
    It uses the basis formed by the gradient and the principal curvature
    directions and smoothes differently in each direction.
    <P>
    The input parameters are:
    <BR>
    <UL>
    <LI><B> Input image:</B>
    <LI><B> 2D or 3D mode:</B> 
    <LI><B> Standard Deviation:</B> Standard deviation of the Gaussian smoothing
    <LI><B> Threshold:         </B> Threshold on the norm of the smoothed gradient 
    <LI><B> Attachment:        </B> Coefficient of the data attachment term 
    <LI><B> Iterations:        </B> Number of iterations
    <LI><B> NumberOfThreads:   </B> Number of threads
    <LI><B> TruncNegValues:    </B> 0 or 1, if 1 set negative intensities to 0 after processing
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags FluxDiffusion $help
    MainHelpBuildGUI  FluxDiffusion

}
# end FluxDiffusionBuildHelpFrame


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionBuildMainFrame
#
#   Create the Main frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionBuildMainFrame {} {

    global Gui FluxDiffusion Module Volume

    #-------------------------------------------
    # Main frame
    #-------------------------------------------
    set fMain $Module(FluxDiffusion,fMain)
    set f $fMain
  
    frame $f.fIO               -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fDimension        -bg $Gui(activeWorkspace)
    frame $f.fThreshold        -bg $Gui(activeWorkspace)
    frame $f.fIterations       -bg $Gui(activeWorkspace)
    frame $f.fNumberOfThreads  -bg $Gui(activeWorkspace)
    frame $f.fTruncNegValues   -bg $Gui(activeWorkspace)
    frame $f.fRun              -bg $Gui(activeWorkspace)

    pack  $f.fIO \
      $f.fDimension  \
      $f.fThreshold  \
      $f.fIterations \
      $f.fNumberOfThreads \
      $f.fTruncNegValues \
          $f.fRun \
      -side top -padx 0 -pady 1 -fill x
    
    #-------------------------------------------
    # Parameters->Input/Output Frame
    #-------------------------------------------
    set f $fMain.fIO
    
    # Add menus that list models and volumes
    DevAddSelectButton  FluxDiffusion $f InputVol "Input Volume" Grid

    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
#    lappend Volume(mbActiveList) $f.mbInputVol
#    lappend Volume(mActiveList)  $f.mbInputVol.m
 
    #-------------------------------------------
    # Parameters->ResultVol Frame
    #-------------------------------------------
#    set f $fMain.fResultVol
    
    # Add menus that list models and volumes
    DevAddSelectButton  FluxDiffusion $f ResultVol "Result Volume" Grid

    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
#    lappend Volume(mbActiveList) $f.mbResultVol
#    lappend Volume(mActiveList)  $f.mbResultVol.m

    #-------------------------------------------
    # Parameters->Dimension frame
    #-------------------------------------------
    set f $fMain.fDimension
    

    eval {label $f.l -text "Dimension:"\
          -width 16 -justify right } $Gui(WLA)
    pack $f.l -side left -padx $Gui(pad) -pady 0

    # puts "WCA  $Gui(WCA)"
    
    foreach value "2 3" width "5 5" {
    eval {radiobutton $f.r$value              \
          -width $width                   \
          -text "$value"                  \
          -value "$value"                 \
          -variable FluxDiffusion(Dimension)   \
          -indicatoron 0                  \
          -bg $Gui(activeWorkspace)       \
          -fg $Gui(textDark)              \
          -activebackground               \
          $Gui(activeButton)              \
          -highlightthickness 0           \
          -bd $Gui(borderWidth)           \
          -selectcolor $Gui(activeButton)
        pack $f.r$value -side left -padx 2 -pady 2 -fill x
    
    }
    }
    


    #-------------------------------------------
    # Parameters->Threshold Frame
    #-------------------------------------------
    set f $fMain.fThreshold
    
    
    eval {label $f.lThreshold -text "Threshold:"\
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eThreshold -justify right -width 6 \
          -textvariable  FluxDiffusion(Threshold)  } $Gui(WEA)
    grid $f.lThreshold $f.eThreshold -pady $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.eThreshold  -sticky w


    #-------------------------------------------
    # Parameters->Iterations Frame
    #-------------------------------------------
    set f $fMain.fIterations
    
    
    eval {label $f.lIterations -text "Iterations:"\
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eIterations -justify right -width 6 \
          -textvariable  FluxDiffusion(Iterations)  } $Gui(WEA)
    grid $f.lIterations $f.eIterations \
    -pady 2 -padx $Gui(pad) -sticky e


    #-------------------------------------------
    # Parameters->NumberOfThreads Frame
    #-------------------------------------------
    set f $fMain.fNumberOfThreads
    
    
    eval {label $f.lNumberOfThreads -text "NumberOfThreads:"\
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eNumberOfThreads -justify right -width 6 \
          -textvariable  FluxDiffusion(NumberOfThreads)  } $Gui(WEA)
    grid $f.lNumberOfThreads $f.eNumberOfThreads \
    -pady 2 -padx $Gui(pad) -sticky e


    #-------------------------------------------
    # Parameters->TruncNegValues Frame
    #-------------------------------------------
    set f $fMain.fTruncNegValues
    
    
    eval {label $f.lTruncNegValues -text "TruncNegValues:"\
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eTruncNegValues -justify right -width 6 \
          -textvariable  FluxDiffusion(TruncNegValues)  } $Gui(WEA)
    grid $f.lTruncNegValues $f.eTruncNegValues \
    -pady 2 -padx $Gui(pad) -sticky e


    #-------------------------------------------
    # Parameters->Run Frame
    #-------------------------------------------
    set f $fMain.fRun
    
    DevAddButton $f.bRun "Run" "RunFluxDiffusion"
    
    pack $f.bRun


}
# end FluxDiffusionBuildMainFrame


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionBuildExpertFrame
#
#   Create the Expert frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionBuildExpertFrame {} {

    global Gui FluxDiffusion Module Volume

    #-------------------------------------------
    # Expert frame
    #-------------------------------------------
    set fExpert $Module(FluxDiffusion,fExpert)
    set f $fExpert
  
    frame $f.fStandardDev -bg $Gui(activeWorkspace)
    frame $f.fAttachment  -bg $Gui(activeWorkspace)
    frame $f.fIsoCoeff    -bg $Gui(activeWorkspace)
    frame $f.f2DParams    -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.f3DParams    -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack  $f.fStandardDev \
      $f.fAttachment  \
      $f.fIsoCoeff    \
      $f.f2DParams    \
      $f.f3DParams    \
    -side top -padx 0 -pady 1 -fill x
    
    #-------------------------------------------
    # Parameters->StandardDev Frame
    #-------------------------------------------
    set f $fExpert.fStandardDev
    
    
    eval {label $f.lStandardDev -text "Standard Dev.:" \
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eStandardDev -justify right -width 6 \
          -textvariable  FluxDiffusion(StandardDev)  } $Gui(WEA)
    grid $f.lStandardDev $f.eStandardDev -pady 0 -padx $Gui(pad) -sticky e
    grid $f.eStandardDev  -sticky w

    #-------------------------------------------
    # Parameters->Attachment Frame
    #-------------------------------------------
    set f $fExpert.fAttachment
    
    
    eval {label $f.lAttachment -text "Attachment:" \
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eAttachment -justify right -width 6 \
          -textvariable  FluxDiffusion(Attachment)  } $Gui(WEA)
    grid $f.lAttachment $f.eAttachment     -pady 0 -padx $Gui(pad) -sticky e
    grid $f.eAttachment  -sticky w


    #-------------------------------------------
    # Parameters->IsoCoeff Frame
    #-------------------------------------------
    set f $fExpert.fIsoCoeff
    
    
    eval {label $f.lIsoCoeff -text "IsoCoeff:" \
          -width 16 -justify right  } $Gui(WLA)
    eval {entry $f.eIsoCoeff -justify right -width 6 \
          -textvariable  FluxDiffusion(IsoCoeff)  } $Gui(WEA)
    grid $f.lIsoCoeff $f.eIsoCoeff     -pady $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.eIsoCoeff  -sticky w


    #-------------------------------------------
    # Parameters->2D parameters Frame
    #-------------------------------------------
    set f $fExpert.f2DParams
    
    
    eval {label $f.l2DParams -text "2D Param:"} $Gui(WLA)
    eval {label $f.lTangCoeff -text "Tangent:"} $Gui(WLA)
    eval {entry $f.eTangCoeff -justify right -width 4 \
          -textvariable  FluxDiffusion(TangCoeff)  } $Gui(WEA)

#    grid $f.l2DParams  -pady 2 -padx $Gui(pad) -sticky e
    grid $f.l2DParams  $f.lTangCoeff $f.eTangCoeff \
    -pady 2 -padx $Gui(pad) -sticky e

    #-------------------------------------------
    # Parameters->3D parameters Frame
    #-------------------------------------------
    set f $fExpert.f3DParams
    
    
    eval {label $f.l3DParams -text "3D Param:"} $Gui(WLA)

    eval {label $f.lMaxcurvCoeff -text "Max curv:"} $Gui(WLA)
    eval {entry $f.eMaxcurvCoeff -justify right -width 4 \
          -textvariable  FluxDiffusion(MaxcurvCoeff)  } $Gui(WEA)

    eval {label $f.lMincurvCoeff -text "Min curv:"} $Gui(WLA)
    eval {entry $f.eMincurvCoeff -justify right -width 4 \
          -textvariable  FluxDiffusion(MincurvCoeff)  } $Gui(WEA)

    grid $f.l3DParams     -pady 2 -padx $Gui(pad) -sticky e
    grid $f.lMaxcurvCoeff $f.eMaxcurvCoeff \
         $f.lMincurvCoeff $f.eMincurvCoeff -pady 2 -padx $Gui(pad) -sticky e



}
# end FluxDiffusionBuildExpertFrame


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionEnter {} {
    global FluxDiffusion
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $FluxDiffusion(eventManager)

    #Change welcome logo if it exits under ./image
    set modulepath $::PACKAGE_DIR_VTKFLUXDIFFUSION/../../../images
    if {[file exist [ExpandPath [file join \
                     $modulepath "welcome.ppm"]]]} {
        image create photo iWelcome \
        -file [ExpandPath [file join $modulepath "welcome.ppm"]]
    }

    # clear the text box and put instructions there
#    $FluxDiffusion(textBox) delete 1.0 end
#    $FluxDiffusion(textBox) insert end "Shift-Click anywhere!\n"

}

#-------------------------------------------------------------------------------
# .PROC FluxDiffusionExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
    
    #Restore standar slicer logo
    image create photo iWelcome \
        -file [ExpandPath [file join gui "welcome.ppm"]]

}


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionCount
#
# This routine demos how to make button callbacks and use global arrays
# for object oriented programming.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionCount {} {
    global FluxDiffusion
    
    incr FluxDiffusion(count)
    $FluxDiffusion(lParameters) config -text "You clicked the button $FluxDiffusion(count) times"
}


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionShowFile
#
# This routine demos how to make button callbacks and use global arrays
# for object oriented programming.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionShowFile {} {
    global FluxDiffusion
    
    $FluxDiffusion(lfile) config -text "You entered: $FluxDiffusion(FileName)"
}


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionBindingCallback
# Demo of callback routine for bindings
# 
# .ARGS
# string event 
# int W 
# int X 
# int Y 
# int x 
# int y 
# int t 
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionBindingCallback { event W X Y x y t } {
    global FluxDiffusion

    set insertText "$event at: $X $Y\n"
    
    switch $event {
    "Shift-2" {
        set insertText "Don't poke the Slicer!\n"
    }
    "Shift-3" {
        set insertText "Ouch!\n"
    }

    }
#    $FluxDiffusion(textBox) insert end $insertText

}


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionPrepareResult
#   Create the New Volume if necessary. Otherwise, ask to overwrite.
#   returns 1 if there is are errors 0 otherwise
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionCheckErrors {} {
    global FluxDiffusion Volume

    if {  ($FluxDiffusion(InputVol) == $Volume(idNone)) || \
          ($FluxDiffusion(ResultVol)   == $Volume(idNone))}  {
        DevErrorWindow "You cannot use Volume \"None\""
        return 1
    }
    return 0
}


#-------------------------------------------------------------------------------
# .PROC FluxDiffusionPrepareResultVolume
#   Check for Errors in the setup
#   returns 1 if there are errors, 0 otherwise
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FluxDiffusionPrepareResultVolume {}  {
    global FluxDiffusion

    set v1 $FluxDiffusion(InputVol)
    set v2 $FluxDiffusion(ResultVol)

    # Do we need to Create a New Volume?
    # If so, let's do it.
    
    if {$v2 == -5 } {
        set v2 [DevCreateNewCopiedVolume $v1 ""  "FluxDiffusionResult" ]
        set node [Volume($v2,vol) GetMrmlNode]
        Mrml(dataTree) RemoveItem $node 
        set nodeBefore [Volume($v1,vol) GetMrmlNode]
    Mrml(dataTree) InsertAfterItem $nodeBefore $node
        MainUpdateMRML
    } else {

        # Are We Overwriting a volume?
        # If so, let's ask. If no, return.
         
        set v2name  [Volume($v2,node) GetName]
    set continue [DevOKCancel "Overwrite $v2name?"]
          
        if {$continue == "cancel"} { return 1 }
        # They say it is OK, so overwrite!
              
        Volume($v2,node) Copy Volume($v1,node)
    }

    set FluxDiffusion(ResultVol) $v2
    

    return 0
}


#-------------------------------------------------------------------------------
# .PROC RunFluxDiffusion
#   Run the fast marching
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RunFluxDiffusion {} {

  global FluxDiffusion Volume Gui Slice


  if {[FluxDiffusionPrepareResultVolume] == 1} {
      return
  }


  if {[FluxDiffusionCheckErrors] == 1} {
      return
  }

  set input $FluxDiffusion(InputVol);
  set res $FluxDiffusion(ResultVol);

  vtkAnisoGaussSeidel aniso

  aniso SetInput               [ Volume($input,vol) GetOutput]

  aniso Setmode                $FluxDiffusion(Dimension)
  aniso Setsigma               $FluxDiffusion(StandardDev)
  aniso Setk                   $FluxDiffusion(Threshold)
  aniso Setbeta                $FluxDiffusion(Attachment)
  aniso SetIsoCoeff            $FluxDiffusion(IsoCoeff)

  aniso SetNumberOfIterations  $FluxDiffusion(Iterations)

  aniso SetTangCoeff           $FluxDiffusion(TangCoeff)

  aniso SetMincurvCoeff        $FluxDiffusion(MincurvCoeff)
  aniso SetMaxcurvCoeff        $FluxDiffusion(MaxcurvCoeff)


  set Gui(progressText)     "Processing Flux Diffusion"
  aniso AddObserver StartEvent MainStartProgress
  aniso AddObserver ProgressEvent "MainShowProgress aniso"
  aniso AddObserver EndEvent MainEndProgress

  aniso SetNumberOfThreads     $FluxDiffusion(NumberOfThreads)
  aniso SetTruncNegValues      $FluxDiffusion(TruncNegValues)


  # This is necessary so that the data is updated correctly.
  # If the programmers forgets to call it, it looks like nothing
  # happened.

  Volume($res,vol) SetImageData [aniso GetOutput]
  MainVolumesUpdate $res

  aniso UnRegisterAllOutputs
  aniso Delete

  #
  #  update display  
  #
  foreach s $Slice(idList) {
    set Slice($s,backVolID)  $input
    set Slice($s,foreVolID)  $res
  }

  Volume($res,vol)  SetRangeHigh [Volume($input,vol)  GetRangeHigh]
  Volume($res,vol)  SetRangeLow  [Volume($input,vol)  GetRangeLow]
  Volume($res,node) SetWindow    [Volume($input,node) GetWindow]
  Volume($res,node) SetLevel     [Volume($input,node) GetLevel]
  RenderAll

}
