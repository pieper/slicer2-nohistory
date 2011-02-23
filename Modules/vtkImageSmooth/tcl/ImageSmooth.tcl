#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ImageSmooth.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:54 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        ImageSmooth.tcl
# PROCEDURES:  
#   ImageSmoothInit
#   ImageSmoothUpdateGUI
#   ImageSmoothBuildGUI
#   ImageSmoothBuildHelpFrame
#   ImageSmoothBuildMainFrame
#   ImageSmoothEnter
#   ImageSmoothExit
#   ImageSmoothCount
#   ImageSmoothShowFile
#   ImageSmoothBindingCallback event W X Y x y t
#   ImageSmoothPrepareResult
#   ImageSmoothPrepareResultVolume
#   RunImageSmooth
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
#   The full GNU Lesser General Public License file is in vtkImageSmooth/LesserGPL_license.txt



#-------------------------------------------------------------------------------
#  Description
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are (some of) the variables defined by this module.
# 
#  int ImageSmooth(count) counts the button presses for the demo 
#  list ImageSmooth(eventManager)  list of event bindings used by this module
#  widget ImageSmooth(textBox)  the text box widget
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC ImageSmoothInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothInit {} {
    global ImageSmooth Module Volume 
    
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
    set m ImageSmooth
    set Module($m,row1List) "Help Main"
    set Module($m,row1Name) "{Help} {Main}"
    set Module($m,row1,tab) Main

    set Module($m,author) "Karl Krissian, BWH, karl@bwh.harvard.edu"
    set Module($m,summary) "This module implements a version of anisotropic diffusion.\n It aims at restoring 2D and 3D images with the ability to preserve small and elongated structures."
    set Module($m,category) "Filtering"

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
    #   set Module($m,procVTK) ImageSmoothBuildVTK
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
    set Module($m,procGUI)   ImageSmoothBuildGUI
    set Module($m,procEnter) ImageSmoothEnter
    set Module($m,procExit)  ImageSmoothExit
    set Module($m,procMRML)  ImageSmoothUpdateGUI

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
        {$Revision: 1.5 $} {$Date: 2006/01/06 17:57:54 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
 
    set ImageSmooth(InputVol)      $Volume(idNone)
    set ImageSmooth(ResultVol)     $Volume(idNone)
    set ImageSmooth(Dimension)     "3"
    #set ImageSmooth(StandardDev)   "1"
    #set ImageSmooth(Threshold)     "10"
    #set ImageSmooth(Attachment)    "0.05"
    set ImageSmooth(Iterations)    "5"
    #set ImageSmooth(IsoCoeff)      "0.2"
    #set ImageSmooth(TruncNegValues)  "0"
    #set ImageSmooth(NumberOfThreads) "4"

    #set ImageSmooth(TangCoeff)     "1"

    #set ImageSmooth(MincurvCoeff)  "1"
    #set ImageSmooth(MaxcurvCoeff)  "0.1"

    # Event bindings! (see ImageSmoothEnter, ImageSmoothExit, tcl-shared/Events.tcl)
    set ImageSmooth(eventManager)  { \
        {all <Shift-1> {ImageSmoothBindingCallback Shift-1 %W %X %Y %x %y %t}} \
        {all <Shift-2> {ImageSmoothBindingCallback Shift-2 %W %X %Y %x %y %t}} \
        {all <Shift-3> {ImageSmoothBindingCallback Shift-3 %W %X %Y %x %y %t}} }
}


#-------------------------------------------------------------------------------
# .PROC ImageSmoothUpdateGUI
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
proc ImageSmoothUpdateGUI {} {
    global ImageSmooth Volume
    
    DevUpdateNodeSelectButton Volume ImageSmooth InputVol   InputVol   DevSelectNode
    DevUpdateNodeSelectButton Volume ImageSmooth ResultVol  ResultVol  DevSelectNode 0 1 1
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
# .PROC ImageSmoothBuildGUI
#
# Create the Graphical User Interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothBuildGUI {} {
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Parameters" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(ImageSmooth,fMain)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Parameters
    #-------------------------------------------
    
    ImageSmoothBuildHelpFrame
       
    #ImageSmoothBuildExpertFrame

    ImageSmoothBuildMainFrame


}

#-------------------------------------------------------------------------------
# .PROC ImageSmoothBuildHelpFrame
#
#   Create the Help frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothBuildHelpFrame {} {


    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The ImageSmooth module contains a version of Anisotropic Diffusion
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
    MainHelpApplyTags ImageSmooth $help
    MainHelpBuildGUI  ImageSmooth

}
# end ImageSmoothBuildHelpFrame


#-------------------------------------------------------------------------------
# .PROC ImageSmoothBuildMainFrame
#
#   Create the Main frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothBuildMainFrame {} {

    global Gui ImageSmooth Module Volume

    #-------------------------------------------
    # Main frame
    #-------------------------------------------
    set fMain $Module(ImageSmooth,fMain)
    set f $fMain
  
    frame $f.fIO               -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fDimension        -bg $Gui(activeWorkspace)
    #frame $f.fThreshold        -bg $Gui(activeWorkspace)
    frame $f.fIterations       -bg $Gui(activeWorkspace)
    #frame $f.fNumberOfThreads  -bg $Gui(activeWorkspace)
    #frame $f.fTruncNegValues   -bg $Gui(activeWorkspace)
    frame $f.fRun              -bg $Gui(activeWorkspace)

    pack  $f.fIO \
      $f.fDimension  \
      $f.fIterations \
          $f.fRun \
      -side top -padx 0 -pady 1 -fill x
    
    #-------------------------------------------
    # Parameters->Input/Output Frame
    #-------------------------------------------
    set f $fMain.fIO
    
    # Add menus that list models and volumes
    DevAddSelectButton  ImageSmooth $f InputVol "Input Volume" Grid

    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
#    lappend Volume(mbActiveList) $f.mbInputVol
#    lappend Volume(mActiveList)  $f.mbInputVol.m
 
    #-------------------------------------------
    # Parameters->ResultVol Frame
    #-------------------------------------------
#    set f $fMain.fResultVol
    
    # Add menus that list models and volumes
    DevAddSelectButton  ImageSmooth $f ResultVol "Result Volume" Grid

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
          -variable ImageSmooth(Dimension)   \
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
    # Parameters->Iterations Frame
    #-------------------------------------------
    set f $fMain.fIterations
    
    
    eval {label $f.lIterations -text "Iterations:"\
          -width 16 -justify right } $Gui(WLA)
    eval {entry $f.eIterations -justify right -width 6 \
          -textvariable  ImageSmooth(Iterations)  } $Gui(WEA)
    grid $f.lIterations $f.eIterations \
    -pady 2 -padx $Gui(pad) -sticky e



    #-------------------------------------------
    # Parameters->Run Frame
    #-------------------------------------------
    set f $fMain.fRun
    
    DevAddButton $f.bRun "Run" "RunImageSmooth"
    
    pack $f.bRun


}
# end ImageSmoothBuildMainFrame

#-------------------------------------------------------------------------------
# .PROC ImageSmoothEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothEnter {} {
    global ImageSmooth
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $ImageSmooth(eventManager)

    # clear the text box and put instructions there
#    $ImageSmooth(textBox) delete 1.0 end
#    $ImageSmooth(textBox) insert end "Shift-Click anywhere!\n"

}

#-------------------------------------------------------------------------------
# .PROC ImageSmoothExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothExit {} {

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
# .PROC ImageSmoothCount
#
# This routine demos how to make button callbacks and use global arrays
# for object oriented programming.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothCount {} {
    global ImageSmooth
    
    incr ImageSmooth(count)
    $ImageSmooth(lParameters) config -text "You clicked the button $ImageSmooth(count) times"
}


#-------------------------------------------------------------------------------
# .PROC ImageSmoothShowFile
#
# This routine demos how to make button callbacks and use global arrays
# for object oriented programming.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothShowFile {} {
    global ImageSmooth
    
    $ImageSmooth(lfile) config -text "You entered: $ImageSmooth(FileName)"
}


#-------------------------------------------------------------------------------
# .PROC ImageSmoothBindingCallback
# Demo of callback routine for bindings
# 
# .ARGS
# string event
# windowpath W
# int X
# int Y
# int x
# int y
# int t
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothBindingCallback { event W X Y x y t } {
    global ImageSmooth

    set insertText "$event at: $X $Y\n"
    
    switch $event {
    "Shift-2" {
        set insertText "Don't poke the Slicer!\n"
    }
    "Shift-3" {
        set insertText "Ouch!\n"
    }

    }
#    $ImageSmooth(textBox) insert end $insertText

}


#-------------------------------------------------------------------------------
# .PROC ImageSmoothPrepareResult
#   Create the New Volume if necessary. Otherwise, ask to overwrite.
#   returns 1 if there is are errors 0 otherwise
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothCheckErrors {} {
    global ImageSmooth Volume

    if {  ($ImageSmooth(InputVol) == $Volume(idNone)) || \
          ($ImageSmooth(ResultVol)   == $Volume(idNone))}  {
        DevErrorWindow "You cannot use Volume \"None\""
        return 1
    }
    return 0
}


#-------------------------------------------------------------------------------
# .PROC ImageSmoothPrepareResultVolume
#   Check for Errors in the setup
#   returns 1 if there are errors, 0 otherwise
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ImageSmoothPrepareResultVolume {}  {
    global ImageSmooth

    set v1 $ImageSmooth(InputVol)
    set v2 $ImageSmooth(ResultVol)

    # Do we need to Create a New Volume?
    # If so, let's do it.
    
    if {$v2 == -5 } {
        set v2 [DevCreateNewCopiedVolume $v1 ""  "SmoothResult" ]
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

    set ImageSmooth(ResultVol) $v2
    

    return 0
}


#-------------------------------------------------------------------------------
# .PROC RunImageSmooth
#   Run the fast marching
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RunImageSmooth {} {

  global ImageSmooth Volume Gui

  puts "RunImageSmooth 1"

  if {[ImageSmoothPrepareResultVolume] == 1} {
      return
  }

  puts "RunImageSmooth 2"

  if {[ImageSmoothCheckErrors] == 1} {
      return
  }

  set input $ImageSmooth(InputVol);
  set res $ImageSmooth(ResultVol);

  puts "RunImageSmooth 3"

  vtkImageSmooth ImgSmooth

  ImgSmooth SetInput               [ Volume($input,vol) GetOutput]

  ImgSmooth SetNumberOfIterations  $ImageSmooth(Iterations)

  
  set Gui(progressText)     "executing one iteration"
  ImgSmooth AddObserver StartEvent MainStartProgress
  ImgSmooth AddObserver ProgressEvent "MainShowProgress ImgSmooth"
  ImgSmooth AddObserver EndEvent MainEndProgress

  puts "RunImageSmooth 4"

  # This is necessary so that the data is updated correctly.
  # If the programmers forgets to call it, it looks like nothing
  # happened.

  puts "RunImageSmooth 5"

  Volume($res,vol) SetImageData [ImgSmooth GetOutput]
  MainVolumesUpdate $res
  RenderAll

  puts "RunImageSmooth 6"

  ImgSmooth Delete

}
