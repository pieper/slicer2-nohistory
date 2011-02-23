#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: LevelSets.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.36 $
# 
#===============================================================================
# FILE:        LevelSets.tcl
# PROCEDURES:  
#   LevelSetsInit
#   LevelSetsUpdateGUI
#   LevelSetsBuildGUI
#   LevelSetsBuildHelpFrame
#   LevelSetsBuildInitFrame
#   LevelSetsBuildInitFrame
#   myDevAddSelectButton TabName f aLabel message tooltip width color
#   DevAddImageButton ButtonName Message Command Width
#   LevelSetsBuildMainFrame
#   LevelSetsBuildEquFrame
#   LevelSetsEnter
#   LevelSetsExit
#   LevelSetsBindingCallback event W X Y x y t
#   LevelSetsPrepareResult
#   LevelSetsPrepareResultVolume
#   LevelSetsUpdateResults
#   LevelSetsUpdateParams
#   LevelSetsShowProgress progress
#   LevelSetsEndProgress
#   LevelSetsRun
#   LevelSetsStart
#   LevelSetsPause
#   LevelSetsContinue
#   LevelSetsEnd
#   LevelSetsCreateModel
#   SetSPGR_WM_Param
#   SetMRAParam
#   SetUSLiver
#   SetUSLiver
#   LevelSetsSaveParam
#==========================================================================auto=
#   ==================================================
#   Module : vtkLevelSets
#   Authors: Karl Krissian
#   Email  : karl@bwh.harvard.edu
#
#   This module implements a Active Contour evolution
#   for segmentation of 2D and 3D images.
#   It implements a 'codimension 2' levelsets as an
#   option for the smoothing term.
#   It comes with a Tcl/Tk interface for the '3D Slicer'.
#   ==================================================
#   Copyright (C) 2003  LMI, Laboratory of Mathematics in Imaging, 
#   Brigham and Women's Hospital, Boston MA USA
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
#   The full GNU Lesser General Public License file is in vtkLevelSets/LesserGPL_license.txt



#-------------------------------------------------------------------------------
#  Description
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are (some of) the variables defined by this module.
# 
#  list LevelSets(eventManager)  list of event bindings used by this module
#  widget LevelSets(textBox)  the text box widget
#-------------------------------------------------------------------------------
package require Iwidgets



#-------------------------------------------------------------------------------
# .PROC LevelSetsInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LevelSetsInit {} {
    global LevelSets Module Volume Gui
    
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
    set m LevelSets
    set Module($m,row1List) "Help  Main Init Prob Equ"
    set Module($m,row1Name) "{Help} {Main} {Init} {Prob} {Equ}"
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
    #   set Module($m,procVTK) LevelSetsBuildVTK
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
    set Module($m,procGUI)   LevelSetsBuildGUI
    set Module($m,procEnter) LevelSetsEnter
    set Module($m,procExit)  LevelSetsExit
    set Module($m,procMRML)  LevelSetsUpdateGUI

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) "Fiducials"

    set Module($m,overview) "Active Contour evolution for segmentation of 2D and 3D images."
    set Module($m,author) "Karl Krissian, SPL, karl@bwh.harvard.edu"
    set Module($m,category) "Segmentation"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.36 $} {$Date: 2006/01/06 17:57:56 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
 
    # Initialization Paramaters
    set LevelSets(InitVol)                    $Volume(idNone)
    set LevelSets(InitThreshold)              "30"
    # Initial image Bright or Dark
    set LevelSets(InitVolIntensityList)       { 0 1}
    set LevelSets(InitVolIntensity0)          "Bright"
    set LevelSets(InitVolIntensity1)          "Dark"
    set LevelSets(InitVolIntensity)           $LevelSets(InitVolIntensity0)

    set LevelSets(GreyScaleName) "LevelSetsResult"
    set LevelSets(LabelMapName)  "LS_labelmap"

    set LevelSets(upsample_xcoeff)            "1"
    set LevelSets(upsample_ycoeff)            "1"
    set LevelSets(upsample_zcoeff)            "1"

    set LevelSets(LowIThreshold)              "-1"
    set LevelSets(HighIThreshold)             "-1"

    set LevelSets(FidPointList)               0

    # Initialization option
    set LevelSets(InitSchemeList)             { 0 1 2}
    set LevelSets(InitScheme0)                "Fiducials"
    set LevelSets(InitScheme1)                "Label Map"
    set LevelSets(InitScheme2)                "GreyScale Image"
    set LevelSets(InitScheme)                 $LevelSets(InitScheme0)

    # Remove this part ...
    set LevelSets(NumInitPoints)              "0"
    set LevelSets(InitRadius)                 "4"

    set LevelSets(MeanIntensity)              "100"
    set LevelSets(SDIntensity)                "15"
    set LevelSets(BalloonCoeff)               "0.3"
    set LevelSets(ProbabilityThreshold)       "0.3"
    set LevelSets(ProbabilityHighThreshold)   "0"

    # Main Parameters
    set LevelSets(InputVol)                   $Volume(idNone)
    set LevelSets(ResultVol)                  -5
    set LevelSets(LabelResultVol)             -5
    set LevelSets(LabelMapValue)              5

    set LevelSets(Dimension)                  "3"


    set LevelSets(HistoGradThreshold)         "0.2"
    set LevelSets(AdvectionCoeff)                "1"

    # Advection Scheme
    set LevelSets(AdvectionSchemeList)        { 0 2}
    set LevelSets(AdvectionScheme0)           "Upwind Vector"
    set LevelSets(AdvectionScheme2)           "Upwind Scalar"
    set LevelSets(AdvectionScheme)            $LevelSets(AdvectionScheme2)

    # Smoothing Scheme
    set LevelSets(SmoothingSchemeList)        { 0 1}
    set LevelSets(SmoothingScheme0)           "Minimal Curvature"
    set LevelSets(SmoothingScheme1)           "Mean Curvature"
    set LevelSets(SmoothingScheme)            $LevelSets(SmoothingScheme1)

    set LevelSets(StepDt)                     "0.8"

    set LevelSets(ReinitFreq)                 "6"
    set LevelSets(SmoothingCoeff)                  "0.2"




    set LevelSets(DMethod)                    "DISMAP_FASTMARCHING"

    set LevelSets(BandSize)                   "3"
    set LevelSets(TubeSize)                   "2"

    set LevelSets(NumIters)                   "50"

    set LevelSets(DisplayFreq)                "10"
  
    # get the default number of threads
    vtkMultiThreader LevelSets(vtk,v)
    set LevelSets(NumberOfThreads)            [LevelSets(vtk,v) GetGlobalDefaultNumberOfThreads]
    LevelSets(vtk,v) Delete

    set LevelSets(Processing)                 "OFF"

    # Event bindings! (see LevelSetsEnter, LevelSetsExit, tcl-shared/Events.tcl)
    set LevelSets(eventManager)  { \
        {all <KeyPress-l> {LevelSetsBindingCallback KeyPress-l %W %X %Y %x %y %t}} \
        {all <KeyPress-L> {LevelSetsBindingCallback KeyPress-L %W %X %Y %x %y %t}} \
        {all <Control-KeyPress-l> {LevelSetsBindingCallback Control-KeyPress-l %W %X %Y %x %y %t}} \
                   }
    
#        {all <Shift-1> {LevelSetsBindingCallback Shift-1 %W %X %Y %x %y %t}} \
#        {all <Shift-2> {LevelSetsBindingCallback Shift-2 %W %X %Y %x %y %t}} \
#        {all <Shift-3> {LevelSetsBindingCallback Shift-3 %W %X %Y %x %y %t}} 
    
# Workspace Title Attributes (myWTA)
lappend attr myWTA 
set Gui(myWTA) {-font {helvetica 8} \
            -background $Gui(activeWorkspace) \
            -foreground $Gui(textDark) \
            -padx 1 -pady 1 -relief flat }

# Workspace Entry Attributes (WEA)
lappend attr myWEA 
set Gui(myWEA) { -font {helvetica 8} \
         -background $Gui(normalButton) -foreground $Gui(textDark) \
           -highlightthickness 0 \
           -relief sunken}

# Workspace Label Attributes (myWLA)
lappend attr myWLA 
set Gui(myWLA) {  -font {helvetica 8} \
          -background $Gui(activeWorkspace) -foreground $Gui(textDark) \
            -padx 1 -pady 1 -relief flat }

}


#-------------------------------------------------------------------------------
# .PROC LevelSetsUpdateGUI
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
proc LevelSetsUpdateGUI {} {
    global LevelSets Volume
    
    DevUpdateNodeSelectButton Volume LevelSets InputVol        InputVol        DevSelectNode
    DevUpdateNodeSelectButton Volume LevelSets InitVol         InitVol         DevSelectNode 
#    DevUpdateNodeSelectButton Volume LevelSets ResultVol       ResultVol       DevSelectNode 0 1 0
#    DevUpdateNodeSelectButton Volume LevelSets LabelResultVol  LabelResultVol  DevSelectNode 0 1 1
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
# .PROC LevelSetsBuildGUI
#
# Create the Graphical User Interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBuildGUI {} {
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Parameters" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(LevelSets,fMain)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Parameters
    #-------------------------------------------
    
    LevelSetsBuildHelpFrame
    LevelSetsBuildMainFrame
    LevelSetsBuildInitFrame
    LevelSetsBuildProbFrame
    LevelSetsBuildEquFrame
}

#-------------------------------------------------------------------------------
# .PROC LevelSetsBuildHelpFrame
#
#   Create the Help frame
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBuildHelpFrame {} {


    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The LevelSets module contains a version of 
    a Active Contour Segmentation Tool using the Level Set Method.
    <P>
    The Main parameters are:
    <BR>
    <UL>
    <LI><B> Input image:</B>
    <LI><B> 2D or 3D mode:</B> 
    <LI><B> HistoGradThreshold:  </B> Threshold on the norm of the smoothed gradient 
    <LI><B> AdvectionCoeff:         </B> Coefficient of the contour attachment term 
    <LI><B> StepDt:              </B> Evolution Step for the PDE
    <LI><B> NumIters:            </B> Number of iterations
    <LI><B> NumberOfThreads:     </B> Number of threads
    <P>
    The Init parameters are:
    <BR>
    <LI><B> Initial Level Set:</B> To specify an initial image (label map, etc...), not available yet
    <LI><B> Threshold:        </B> Starting threshold in case the number of initial points is 0.
It should use the Initial Level Set image if there is one, or the Input image otherwise.
    <LI><B> Radius:            </B> Radii of the initial spheres centered on the selected initial points
    <LI><B> LevelSets-seed:    </B> List of initial centers of spheres, all the fudicials of the list are used, use 'p' to add a point, 'd' to delete (check fiducials documentation).
    <LI><B> Low Intensity      </B> allows preprocessing the image by putting all points lower  than L to L, -1 means inactive
    <LI><B> High Intensity     </B> allows preprocessing the image by putting all points higher than H to H, -1 means inactive
    <LI><B> Mean Intensity        </B> mean intensity of the tissue to segment, use to design the expansion force.
    <LI><B> Standard Deviation    </B> standard deviation of the intensity of the tissue to segment.
    <LI><B> Probability Threshold </B> probability threshold is used to threshold a Gaussian based on the mean and the standard deviation: the function 'exp(-(I-mean)*(I-mean)/sd/sd)-threshold' is used for the expansion force, which allows shrinking the levelset surface when the intensity is far from the tissue statistics.
    <LI><B> Probability High Threshold </B> allows to intensities higher than the threshold to give a probability of 1, and thus allows evolution in high intensity areas independently of the tissue statistics given by a Gaussian function.
    <BR>
    <P>
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags LevelSets $help
    MainHelpBuildGUI  LevelSets

}
#----- LevelSetsBuildHelpFrame


#-------------------------------------------------------------------------------
# .PROC LevelSetsBuildInitFrame
#
#   Compute the initial level set
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBuildInitFrame {} {
#    -----------------------

    global Gui LevelSets Module Volume

    #-------------------------------------------
    # Init frame
    #-------------------------------------------
    set fInit $Module(LevelSets,fInit)
    set f $fInit
  
    frame $f.fInitScheme           -bg $Gui(activeWorkspace) 
    frame $f.fFloatingFrame        -bg $Gui(activeWorkspace) -height 350 


#    pack  \
#          $f.fInitScheme    \
#          $f.fInitImage     \
#          $f.fInitThreshold \
#          $f.fInitRadius    \
#          $f.fInitFidPoints \
#      -side top -padx 0 -pady 1 -fill x 
   
    pack  \
          $f.fInitScheme    \
          $f.fFloatingFrame    \
      -side top -padx 0 -pady 1 -fill x -expand true



    #-------------------------------------------
    # FloatingFrame
    #-------------------------------------------
    set f $fInit.fFloatingFrame

    foreach i  $LevelSets(InitSchemeList) {
      frame $f.fInitScheme$i -bg $Gui(activeWorkspace) -relief groove -bd 3 
      place $f.fInitScheme$i -in $f -relheight 1.0 -relwidth 1.0
    }

    foreach i $LevelSets(InitSchemeList) {
      if { $LevelSets(InitScheme) == $LevelSets(InitScheme${i}) } {
      raise  $f.fInitScheme$i
      }
    }

    #-------------------------------------------
    # Parameters->InitScheme Frame
    #-------------------------------------------
    set f $fInit.fInitScheme

    eval {label $f.lInitScheme -text "Initialize with:"} $Gui(myWLA)

    #--------------------------------------------------
    proc SetInitScheme { i } {
      global Module LevelSets

      set LevelSets(InitScheme) $LevelSets(InitScheme$i)
      raise  $Module(LevelSets,fInit).fFloatingFrame.fInitScheme$i
      focus  $Module(LevelSets,fInit).fFloatingFrame.fInitScheme$i
    }

    eval {menubutton $f.mInitScheme  \
                      -relief raised -indicatoron on -takefocus 1 \
                      -width 16 -justify right \
                      -menu $f.mInitScheme.m \
                      -textvariable  LevelSets(InitScheme) } $Gui(myWEA)
    eval {menu $f.mInitScheme.m -tearoff 0   }
    
    foreach i $LevelSets(InitSchemeList) {
      $f.mInitScheme.m add command \
          -label   $LevelSets(InitScheme$i) \
          -command "SetInitScheme $i " 
    }

    grid $f.lInitScheme $f.mInitScheme  -pady 0 -padx $Gui(pad) -sticky e


    #-------------------------------------------
    # Parameters->fInitScheme0 : Fiducials
    #-------------------------------------------

    set fch0 $fInit.fFloatingFrame.fInitScheme0

    # Parameters->Radius Frame
    frame $fch0.fRadius      -bg $Gui(activeWorkspace) -relief groove -bd 1
    set f $fch0.fRadius
    eval {label $f.lInitRadius -text "Radius:"} $Gui(myWLA)

    eval {entry $f.eInitRadius -justify right -width 4 \
          -textvariable  LevelSets(InitRadius)  } $Gui(myWEA)    
        
    eval {scale $f.sInitRadius -from 1 -to 5     \
          -variable  LevelSets(InitRadius)\
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)

    grid $f.lInitRadius $f.eInitRadius $f.sInitRadius

    # Parameters->FidPoints Frame
    frame $fch0.fFidPoints      -bg $Gui(activeWorkspace) -relief groove -bd 1
    FiducialsAddActiveListFrame $fch0.fFidPoints 275 10 "LevelSets-seed"

    pack $fch0.fRadius $fch0.fFidPoints      -side top -padx 0 -pady 1 -fill x -expand true

    #-------------------------------------------
    # Parameters->fInitScheme1 : Label Map
    #-------------------------------------------

    set f $fInit.fFloatingFrame.fInitScheme1
    
    # Add menus that list models and volumes
    myDevAddSelectButton  LevelSets $f InitVol "Initial Level Set" Grid

    # Parameters->Threshold
    eval {label $f.lInitThreshold -text "Threshold:"\
          -width 16 -justify right } $Gui(myWLA)

    eval {entry $f.eInitThreshold -justify right -width 6 \
          -textvariable  LevelSets(InitThreshold)  } $Gui(myWEA)

    grid $f.lInitThreshold $f.eInitThreshold -pady $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.eInitThreshold  -sticky w

    #-------------------------------------------
    # Parameters->fInitScheme2 : Greyscale Image
    #-------------------------------------------

    set f $fInit.fFloatingFrame.fInitScheme2
    
    # Add menus that list models and volumes
    myDevAddSelectButton  LevelSets $f InitVol "Initial Level Set" Grid

    # Parameters->Threshold
    eval {label $f.lInitThreshold -text "Threshold:"\
          -width 16 -justify right } $Gui(myWLA)

    eval {entry $f.eInitThreshold -justify right -width 6 \
          -textvariable  LevelSets(InitThreshold)  } $Gui(myWEA)

    grid $f.lInitThreshold $f.eInitThreshold -pady $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.eInitThreshold  -sticky w

    # Parameters->Interior
    eval {label $f.lInitVolIntensity -text "Intensity:" \
          -width 16 -justify right} $Gui(myWLA)

    #--------------------------------------------------
    proc SetInitVolIntensity { i } {
      global Module LevelSets

      set LevelSets(InitVolIntensity) $LevelSets(InitVolIntensity$i)
    }

    eval {menubutton $f.mInitVolIntensity  \
                      -relief raised -indicatoron on -takefocus 1 \
                      -width 6 -justify right \
                      -menu $f.mInitVolIntensity.m \
                      -textvariable  LevelSets(InitVolIntensity) } $Gui(myWEA)
    eval {menu $f.mInitVolIntensity.m -tearoff 0   }
    
    foreach i $LevelSets(InitVolIntensityList) {
      $f.mInitVolIntensity.m add command \
          -label   $LevelSets(InitVolIntensity$i) \
          -command "SetInitVolIntensity $i " 
    }

    grid $f.lInitVolIntensity $f.mInitVolIntensity  -pady  $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.mInitVolIntensity  -sticky w

}
#----- LevelSetsBuildInitFrame


#-------------------------------------------------------------------------------
# .PROC LevelSetsBuildInitFrame
#
#   Compute the initial level set
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBuildProbFrame {} {
#    -----------------------

    global Gui LevelSets Module Volume

    #-------------------------------------------
    # Intensity Probability frame
    #-------------------------------------------
    set fProb $Module(LevelSets,fProb)
    set f $fProb
  
    frame $f.fIntensityThresholds  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fIntensityProba       -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack  \
          $f.fIntensityThresholds \
          $f.fIntensityProba \
      -side top -padx 0 -pady 1 -fill x
    
    #-------------------------------------------
    # Parameters->Intensity Thresholds
    #-------------------------------------------
    set f $fProb.fIntensityThresholds

    eval {label $f.lLIT -text "Low Intensity Thresh.:"} $Gui(myWLA)
    eval {entry $f.eLIT -justify right -width 4 \
          -textvariable  LevelSets(LowIThreshold)  } $Gui(myWEA)

    eval {label $f.lHIT -text "High Intensity Thresh.:"} $Gui(myWLA)
    eval {entry $f.eHIT -justify right -width 4 \
           -textvariable  LevelSets(HighIThreshold)  } $Gui(myWEA)
       
    grid $f.lLIT $f.eLIT -pady $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.lHIT $f.eHIT -pady $Gui(pad) -padx $Gui(pad) -sticky e

    #-------------------------------------------
    # Parameters->Intensity Probability Frame
    #-------------------------------------------
    set f $fProb.fIntensityProba

    eval {label $f.lMeanI -text "Mean Intensity:"} $Gui(myWLA)
    eval {entry $f.eMeanI -justify right -width 4 \
          -textvariable  LevelSets(MeanIntensity)  } $Gui(myWEA)

    eval {label $f.lSDI -text "Standard Deviation:"} $Gui(myWLA)
    eval {entry $f.eSDI -justify right -width 4 \
          -textvariable  LevelSets(SDIntensity)  } $Gui(myWEA)
       
    eval {label $f.lProTh -text "Probability Threshold:"} $Gui(myWLA)
    eval {entry $f.eProTh -justify right -width 4 \
          -textvariable  LevelSets(ProbabilityThreshold)  } $Gui(myWEA)
       
    eval {label $f.lProHighTh -text "Prob. High Threshold:"} $Gui(myWLA)
    eval {entry $f.eProHighTh -justify right -width 4 \
          -textvariable  LevelSets(ProbabilityHighThreshold)  } $Gui(myWEA)
       
   grid $f.lMeanI     $f.eMeanI     -pady $Gui(pad) -padx $Gui(pad) -sticky e
   grid $f.lSDI       $f.eSDI       -pady $Gui(pad) -padx $Gui(pad) -sticky e
   grid $f.lProTh     $f.eProTh     -pady $Gui(pad) -padx $Gui(pad) -sticky e
   grid $f.lProHighTh $f.eProHighTh -pady $Gui(pad) -padx $Gui(pad) -sticky e
}
#----- LevelSetsBuildProbFrame

#-------------------------------------------------------------------------------
# .PROC myDevAddSelectButton
# .ARGS
# string TabName
# windowpath f
# string aLabel
# string message
# string tooltip defaults to empty string
# int width defaults to 13
# string color defaults to WLA
# .END
#-------------------------------------------------------------------------------
proc myDevAddSelectButton { TabName f aLabel message {tooltip ""} \
                            {width 13} {color WLA}} {
  
  global Gui Module 
  upvar 1 $TabName LocalArray

  # if the variable is not 1 procedure up, try 2 procedures up.

  if {0 == [info exists LocalArray]} {
      upvar 2 $TabName LocalArray 
  }

  if {0 == [info exists LocalArray]} {
      DevErrorWindow "Error finding $TabName in DevAddSelectButton"
      return
  }

  set Label       "$f.l$aLabel"
  set menubutton  "$f.mb$aLabel"
  set menu        "$f.mb$aLabel.m"
   
  DevAddLabel $Label $message $color

  eval {menubutton $menubutton -text "None" \
            -relief raised -bd 2 -width $width -menu $menu} $Gui(WMBA)
  eval {menu $menu} $Gui(WMA)

#  pack $Label $menubutton -side left   -padx $Gui(pad) -pady 0 

  grid $Label $menubutton -padx $Gui(pad) -pady $Gui(pad)

#  grid $Label      -sticky n -padx $Gui(pad) -pady $Gui(pad)
#  grid $menubutton -sticky e -padx $Gui(pad) -pady $Gui(pad)
#  grid $menubutton -sticky w

  if {$tooltip != ""} {
    TooltipAdd $menubutton $tooltip
  }
    
  set LocalArray(mb$aLabel) $menubutton
  set LocalArray(m$aLabel) $menu

  # Note: for the automatic updating, we can use
  # lappend Volume(mbActiveList) $f.mb$VolLabel
  # lappend Volume(mActiveList)  $f.mbActive.m
  # 
  # or we can use DevUpdateVolume in the MyModuleUpdate procedure
}
#----- myDevAddSelectButton

   
#-------------------------------------------------------------------------------
# .PROC DevAddImageButton
#
# .ARGS
# string ButtonName
# string Message 
# string Command 
# int Width defaults to 0
# .END
#-------------------------------------------------------------------------------
proc DevAddImageButton { ButtonName Message Command {Width 0} } {
    global Gui
    if {$Width == 0 } {
        set Width [expr [string length $Message] +2]
    }
    eval  {button $ButtonName -text $Message -width $Width \
            -command $Command } $Gui(WBA)
} 


#-------------------------------------------------------------------------------
# .PROC LevelSetsBuildMainFrame
#
#   Create the Main frame
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBuildMainFrame {} {
#    -----------------------

    global Gui LevelSets Module Volume

    #-------------------------------------------
    # Main frame
    #-------------------------------------------
    set fMain $Module(LevelSets,fMain)
    set f $fMain
  
    #frame $f.flogoLMI             -bg $Gui(activeWorkspace) 
    frame $f.fProtocol            -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $f.fIO                  -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $f.fDimension           -bg $Gui(activeWorkspace)
    frame $f.fUpSample            -bg $Gui(activeWorkspace)
    frame $f.fScaleParams         -bg $Gui(activeWorkspace)
    frame $f.fRun                 -bg $Gui(activeWorkspace) 
    frame $f.fModel               -bg $Gui(activeWorkspace)

    #pack  $f.flogoLMI  -side top 
#-anchor w

    pack  $f.fProtocol \
          $f.fIO \
          $f.fUpSample  \
          $f.fDimension  \
          $f.fScaleParams \
          $f.fRun $f.fModel\
          -side top -padx 0 -pady 1 -fill x
    
    #-------------------------------------------
    # Parameters->logoLMI: LMI logo
    #-------------------------------------------
    #set f $fMain.flogoLMI
    
    #image create photo ilogoLMI \
    #    -file [ExpandPath [file join $::PACKAGE_DIR_VTKLevelSets/../../../images/LMI_logo_2.ppm]]
    #eval {label $f.llogoLMI -image ilogoLMI  \
    #       -anchor w -justify left} $Gui(myWLA)

    #TooltipAdd $f.llogoLMI     " Laboratory of Mathematics in Imaging "
    #pack $f.llogoLMI

    #-------------------------------------------
    # Parameters->Protocol Frame
    #-------------------------------------------
    set f $fMain.fProtocol


    proc SelectProtocol {} {
    global Module
    switch [$Module(LevelSets,fMain).fProtocol.protocol get] { 
        "SPGR WM"   {SetSPGR_WM_Param}
        MRA         {SetMRAParam}
        "US liver"  {SetUSLiverParam}
        "Heart CT"  {SetHeartCTParam}
    }
    }


    iwidgets::optionmenu $f.protocol \
    -labeltext "Protocol:" \
    -command SelectProtocol \
    -background "#e2cdba" -foreground "#000000" 

    pack $f.protocol -side top 

    foreach o {"SPGR WM" "MRA" "US liver" "Heart CT"} {
    $f.protocol insert end $o
    }

    #-------------------------------------------
    # Parameters->Input/Output Frame
    #-------------------------------------------
    set f $fMain.fIO
    myDevAddSelectButton  LevelSets $f InputVol       "Input"     Pack
    myDevAddSelectButton  LevelSets $f ResultVol      "Greyscale" Pack

    eval {label $f.lGreyScaleName -text "GS name:"\
          -width 12 -justify right } $Gui(myWTA)
    eval {entry $f.eGreyScaleName -justify left -width 14 \
          -textvariable  LevelSets(GreyScaleName)  } $Gui(myWEA)
  
    grid $f.lGreyScaleName $f.eGreyScaleName -pady $Gui(pad) -padx $Gui(pad) -sticky w


    myDevAddSelectButton  LevelSets $f LabelResultVol "Labelmap"  Pack


   eval {label $f.lLabelMapName -text "LM name:"\
          -width 12 -justify right } $Gui(myWTA)
    eval {entry $f.eLabelMapName -justify left -width 14 \
          -textvariable  LevelSets(LabelMapName)  } $Gui(myWEA)

    grid $f.lLabelMapName $f.eLabelMapName  -pady $Gui(pad) -padx $Gui(pad) -sticky w

    DevUpdateNodeSelectButton Volume LevelSets ResultVol       ResultVol       DevSelectNode 0 1 0
    DevUpdateNodeSelectButton Volume LevelSets LabelResultVol  LabelResultVol  DevSelectNode 0 1 1
  


    #-------------------------------------------
    # Parameters->Dimension frame
    #-------------------------------------------
    set f $fMain.fDimension
    

    eval {label $f.l -text "Dimension:"\
          -width 16 -justify right } $Gui(myWLA)
    pack $f.l -side left -padx $Gui(pad) -pady 0

#    puts "WCA  $Gui(WCA)"
    
    foreach value "2 3" width "5 5" {
    eval {radiobutton $f.r$value              \
          -width $width                   \
          -text "$value"                  \
          -value "$value"                 \
          -variable LevelSets(Dimension)  \
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
    # Parameters->UpSample frame
    #-------------------------------------------
    set f $fMain.fUpSample
    

    eval {label $f.l -text "UpSample:"\
          -width 16 -justify right } $Gui(myWLA)
#    pack $f.l -side left -padx $Gui(pad) -pady 0

#    puts "WCA  $Gui(WCA)"
    
    eval {entry $f.eCx -justify right -width 3 \
          -textvariable  LevelSets(upsample_xcoeff)  } $Gui(myWEA)
    eval {entry $f.eCy -justify right -width 3 \
          -textvariable  LevelSets(upsample_ycoeff)  } $Gui(myWEA)
    eval {entry $f.eCz -justify right -width 3 \
          -textvariable  LevelSets(upsample_zcoeff)  } $Gui(myWEA)

    grid  $f.l $f.eCx $f.eCy $f.eCz  -pady $Gui(pad) -padx $Gui(pad) -sticky w
    

    #-------------------------------------------
    # Parameters->HistoGradThreshold 
    #-------------------------------------------
    set f $fMain.fScaleParams
        
    eval {label $f.lHistoGradThreshold -text "GradHistoTh:"\
          -width 12 -justify right } $Gui(myWTA)
    eval {entry $f.eHistoGradThreshold -justify right -width 4 \
          -textvariable  LevelSets(HistoGradThreshold)  } $Gui(myWEA)

    eval {scale $f.sHistoGradThreshold -from 0.01 -to 0.99        \
          -variable  LevelSets(HistoGradThreshold)\
          -orient vertical     \
          -resolution .01      \
          } $Gui(WSA)

    grid $f.lHistoGradThreshold $f.eHistoGradThreshold $f.sHistoGradThreshold 


    #-------------------------------------------
    # Parameters->NumIters 
    #-------------------------------------------
    
    eval {label $f.lNumIters -text "Iterations:"\
          -width 11 -justify right } $Gui(myWTA)

    eval {entry $f.eNumIters -justify right -width 4 \
          -textvariable  LevelSets(NumIters)  } $Gui(myWEA)

    eval {scale $f.sNumIters -from 1 -to 500     \
          -variable  LevelSets(NumIters)\
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)

    grid $f.lNumIters $f.eNumIters $f.sNumIters
#    -pady 2 -padx $Gui(pad) -sticky e


    #-------------------------------------------
    # Parameters->NumberOfThreads 
    #-------------------------------------------
    
    eval {label $f.lNumberOfThreads -text "Threads:"\
          -width 8 -justify right } $Gui(myWLA)

    eval {entry $f.eNumberOfThreads -justify right -width 4 \
          -textvariable  LevelSets(NumberOfThreads)  } $Gui(myWEA)

    eval {scale $f.sNumberOfThreads -from 1 -to 50     \
          -variable  LevelSets(NumberOfThreads)\
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)

    grid $f.lNumberOfThreads $f.eNumberOfThreads $f.sNumberOfThreads
#    -pady 2 -padx $Gui(pad) -sticky 


    #-------------------------------------------
    # Parameters->Run Frame
    #-------------------------------------------
    set f $fMain.fRun

    DevAddButton $f.bRun       "Start/Continue"  "LevelSetsRun"
    DevAddButton $f.bPause     "Pause"           "LevelSetsPause"
    DevAddButton $f.bEnd       "End"             "LevelSetsEnd"

    $f.bRun configure -image \
          [image create bitmap \
           -file [ExpandPath [file join $::PACKAGE_DIR_VTKLevelSets/../../../images/play.xbm]]] \
           -width 20 
    $f.bPause configure -image \
          [image create bitmap \
           -file [ExpandPath [file join $::PACKAGE_DIR_VTKLevelSets/../../../images/tpause.xbm]]] \
           -width 20
    $f.bEnd configure -image \
           [image create bitmap \
        -file [ExpandPath [file join $::PACKAGE_DIR_VTKLevelSets/../../../images/stop.xbm]]] \
           -width 20

    TooltipAdd $f.bRun     " Start/Continue the current evolution "
    TooltipAdd $f.bPause   " Pause the evolution "
    TooltipAdd $f.bEnd     " Stop the current evolution "

    pack  $f.bRun $f.bPause $f.bEnd -side left -padx 3 -pady 2 -expand 0

    #-------------------------------------------
    # Parameters->Model Frame
    #-------------------------------------------
    set f $fMain.fModel

    iwidgets::buttonbox $f.bb -background $Gui(normalButton) -foreground $Gui(textDark) \
    -padx 1 -pady 1

    $f.bb add bUpdate -text UpdateResult -command LevelSetsUpdateResults
    $f.bb buttonconfigure bUpdate  -font {helvetica 8} \
         -background $Gui(normalButton) -foreground $Gui(textDark)  \
           -highlightthickness 0

    $f.bb add bModel -text CreateModel -command LevelSetsCreateModel
    $f.bb buttonconfigure bModel  -font {helvetica 8} \
         -background $Gui(normalButton) -foreground $Gui(textDark)  \
           -highlightthickness 0

    $f.bb add bParam -text SaveParam -command LevelSetsSaveParam
    $f.bb buttonconfigure bParam  -font {helvetica 8} \
         -background $Gui(normalButton) -foreground $Gui(textDark)  \
           -highlightthickness 0

#    DevAddFileBrowse $f  Custom Prefix \"File\"

    pack $f.bb -side top

}
#----- LevelSetsBuildMainFrame


#-------------------------------------------------------------------------------
# .PROC LevelSetsBuildEquFrame
#
#   Create the Equation frame
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBuildEquFrame {} {
#    ----------------------

    global Gui LevelSets Module Volume

    #-------------------------------------------
    # Equation frame
    #-------------------------------------------
    set fEqu $Module(LevelSets,fEqu)
    set f $fEqu
  
    frame $f.fSmoothingParam     -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fAdvectionParam     -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fEquationParam      -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fNarrowBandParam    -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack \
    $f.fSmoothingParam \
    $f.fAdvectionParam \
    $f.fEquationParam  \
    $f.fNarrowBandParam   \
    -side top -padx 0 -pady 2 -fill x
    
    #-------------------------------------------
    # Parameters->SmoothingParam Frame
    #-------------------------------------------
    set f $fEqu.fSmoothingParam

    eval {label $f.lSmoothingParam -text "Smoothing:"} $Gui(myWLA)
#    grid $f.lSmoothingParam     -pady 2 -padx $Gui(pad) -sticky e


    #--------------------------------------------------
    proc SetSmoothingScheme { i } {
      global LevelSets
      set LevelSets(SmoothingScheme) $LevelSets(SmoothingScheme$i)
    }

    eval {menubutton $f.mSmoothingScheme  \
                      -relief raised -indicatoron on -takefocus 1 \
                      -width 16 -justify right \
                      -menu $f.mSmoothingScheme.m \
                      -textvariable  LevelSets(SmoothingScheme) } $Gui(myWEA)
    eval {menu $f.mSmoothingScheme.m -tearoff 0   }
    
    foreach i $LevelSets(SmoothingSchemeList) {
      $f.mSmoothingScheme.m add command \
          -label   $LevelSets(SmoothingScheme$i) \
          -command "SetSmoothingScheme $i " 
    }

    grid $f.lSmoothingParam $f.mSmoothingScheme  -pady 0 -padx $Gui(pad) -sticky e

#    eval {label $f.lDoMean -text "DoMean:" \
#          -width 16 -justify right } $Gui(myWLA)
#    eval {entry $f.eDoMean -justify right -width 6 \
#          -textvariable  LevelSets(DoMean)  } $Gui(myWEA)
#    TooltipAdd $f.lDoMean " {0,1};  '0': minimal curvature evolution, '1': mean curvature evolution. "
#    grid $f.lDoMean $f.eDoMean -pady 0 -padx $Gui(pad) -sticky e
#    grid $f.eDoMean  -sticky w


    #-------------------------------------------
    # Parameters->AdvectionParam Frame
    #-------------------------------------------
    set f $fEqu.fAdvectionParam

    eval {label $f.lAdvectionParam -text "Advection:"} $Gui(myWLA)
#   grid $f.lAdvectionParam     -pady 2 -padx $Gui(pad) -sticky e



    #--------------------------------------------------
    proc SetAdvectionScheme { i } {
      global LevelSets
      set LevelSets(AdvectionScheme) $LevelSets(AdvectionScheme$i)
    }
 

    eval {menubutton $f.mAdvectionScheme  \
                      -relief raised -indicatoron on -takefocus 1 \
                      -width 16 -justify right \
                      -menu $f.mAdvectionScheme.m \
                      -textvariable  LevelSets(AdvectionScheme) } $Gui(myWEA)


   TooltipAdd $f.mAdvectionScheme "ADVECTION VECTOR: standard scheme, gradient of the gradient norm scalar the levelset normal, \n ADVECTION SCALAR: normalized zero-crossing of the sec. order derivatives in the gradient direction."

    eval {menu $f.mAdvectionScheme.m -tearoff 0   }
    
    foreach i $LevelSets(AdvectionSchemeList) {
      $f.mAdvectionScheme.m add command \
          -label   $LevelSets(AdvectionScheme$i) \
          -command "SetAdvectionScheme $i " 
    }

    grid $f.lAdvectionParam $f.mAdvectionScheme  -pady 0 -padx $Gui(pad) -sticky e
      
#    eval {label $f.lAdvectionScheme -text "Advection scheme:" \
#          -width 16 -justify right } $Gui(myWLA)

#    TooltipAdd $f.lAdvectionScheme " {0,1 or 2};  \n '1': ADVECTION_CENTRAL_VECTORS Liana's code scheme, \n '0': ADVECTION_UPWIND_VECTORS standard scheme, gradient of the gradient norm scalar the levelset normal, \n '2': ADVECTION_MORPHO normalized zero-crossing of the sec. order derivatives in the gradient direction"

#    eval {entry $f.eAdvectionScheme -justify right -width 6 \
#          -textvariable  LevelSets(AdvectionScheme)  } $Gui(myWEA)
#    grid $f.lAdvectionScheme $f.eAdvectionScheme     -pady 0 -padx $Gui(pad) -sticky e
#    grid $f.eAdvectionScheme  -sticky w


    #-------------------------------------------
    # Parameters->EquationParam Frame
    #-------------------------------------------
    set f $fEqu.fEquationParam

    eval {label $f.lEquationParam -text "Coefficents:"} $Gui(myWLA)
        
    grid $f.lEquationParam -pady 2 -padx $Gui(pad)

    #--------------------------------------------------
    eval {label $f.lBalloonCoeff -text "Expansion:" -width 12 } $Gui(myWLA)

    eval {entry $f.eBalloonCoeff -justify right -width 4 \
          -textvariable  LevelSets(BalloonCoeff)  } $Gui(myWEA)

    eval {scale $f.sBalloonCoeff -from 0.00 -to 1.00        \
          -variable  LevelSets(BalloonCoeff)\
          -orient vertical     \
          -resolution .01      \
          } $Gui(WSA)

    grid $f.lBalloonCoeff $f.eBalloonCoeff $f.sBalloonCoeff  -pady 0 -padx 0



    #--------------------------------------------------
    eval {label $f.lAdvectionCoeff -text "Advection:" \
          -width 10 } $Gui(myWLA)

    eval {entry $f.eAdvectionCoeff -justify right -width 4 \
          -textvariable  LevelSets(AdvectionCoeff)  } $Gui(myWEA)
    
    eval {scale $f.sAdvectionCoeff -from 0.00 -to 1.00        \
          -variable  LevelSets(AdvectionCoeff)\
          -orient vertical     \
          -resolution .01      \
          } $Gui(WSA)

    grid $f.lAdvectionCoeff $f.eAdvectionCoeff  $f.sAdvectionCoeff  -pady 0 -padx 0


    #--------------------------------------------------
    eval {label $f.lSmoothingCoeff -text "Smoothing:" \
          -width 10  } $Gui(myWLA)

    eval {entry $f.eSmoothingCoeff -justify right -width 4 \
          -textvariable  LevelSets(SmoothingCoeff)  } $Gui(myWEA)

    eval {scale $f.sSmoothingCoeff -from 0.00 -to 1.00        \
          -variable  LevelSets(SmoothingCoeff)\
          -orient vertical     \
          -resolution .01      \
          } $Gui(WSA)


    grid $f.lSmoothingCoeff $f.eSmoothingCoeff $f.sSmoothingCoeff -pady 0 -padx 0


    #--------------------------------------------------
    eval {label $f.lStepDt -text "StepDt:" \
          -width 10  } $Gui(myWLA)
    eval {entry $f.eStepDt -justify right -width 4 \
          -textvariable  LevelSets(StepDt)  } $Gui(myWEA)

    eval {scale $f.sStepDt -from 0.01 -to 1.00        \
          -variable  LevelSets(StepDt)\
          -orient vertical     \
          -resolution .01      \
          } $Gui(WSA)

    grid $f.lStepDt $f.eStepDt  $f.sStepDt    -pady 0 -padx 0


    #-------------------------------------------
    # Parameters->NarrowBandParam Frame
    #-------------------------------------------
    set f $fEqu.fNarrowBandParam

    eval {label $f.lNarrowBandParam -text "Narrow Band Params:"} $Gui(myWLA)

    #--------------------------------------------------
    eval {label $f.lBandSize -text "Band Size:" \
          -width 16 -justify right } $Gui(myWLA)
    eval {entry $f.eBandSize -justify right -width 6 \
          -textvariable  LevelSets(BandSize)  } $Gui(myWEA)


    #--------------------------------------------------
    eval {label $f.lTubeSize -text "Tube Size:" \
          -width 16 -justify right } $Gui(myWLA)
    eval {entry $f.eTubeSize -justify right -width 6 \
          -textvariable  LevelSets(TubeSize)  } $Gui(myWEA)



    #--------------------------------------------------
    eval {label $f.lReinitFreq -text "Re-init. Frequency:" \
          -width 16 -justify right } $Gui(myWLA)
    eval {entry $f.eReinitFreq -justify right -width 6 \
          -textvariable  LevelSets(ReinitFreq)  } $Gui(myWEA)

    grid $f.lNarrowBandParam     -pady 2 -padx $Gui(pad) -sticky e


    grid $f.lBandSize  $f.eBandSize     -pady 0 -padx $Gui(pad) -sticky e
    grid $f.eBandSize  -sticky w

    grid $f.lTubeSize  $f.eTubeSize     -pady 0 -padx $Gui(pad) -sticky e
    grid $f.eTubeSize  -sticky w

    grid $f.lReinitFreq $f.eReinitFreq     -pady 0 -padx $Gui(pad) -sticky e
    grid $f.eReinitFreq  -sticky w


}
#----- LevelSetsBuildEquFrame


#-------------------------------------------------------------------------------
# .PROC LevelSetsEnter
#
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LevelSetsEnter {} {
#    --------------

    global LevelSets
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $LevelSets(eventManager)


    if {$LevelSets(FidPointList) == 0} {
      set LevelSets(FidPointList) 1
      FiducialsCreateFiducialsList "default" "LevelSets-seed"
    }
    FiducialsSetActiveList "LevelSets-seed"

#Change welcome logo if it exits under ./image
    set modulepath $::PACKAGE_DIR_VTKLevelSets/../../../images
    if {[file exist [ExpandPath [file join \
                     $modulepath "welcome.ppm"]]]} {
        image create photo iWelcome \
        -file [ExpandPath [file join $modulepath "welcome.ppm"]]
    }

}
#----- LevelSetsEnter


#-------------------------------------------------------------------------------
# .PROC LevelSetsExit
#
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LevelSetsExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager

    #Remove Fiducial List
#    FiducialsDeleteList "LevelSets-seed"

   #Restore standar slicer logo
    image create photo iWelcome \
        -file [ExpandPath [file join gui "welcome.ppm"]]

}

#-------------------------------------------------------------------------------
# .PROC LevelSetsBindingCallback
#
# Callback routine for bindings
# 
# .ARGS
# string event 
# string W 
# int X 
# int Y 
# int x 
# int y 
# int t 
# .END
#-------------------------------------------------------------------------------
proc LevelSetsBindingCallback { event W X Y x y t } {

    global LevelSets Interactor

    set slice_x $x
    set slice_y [expr 255-$y]
    set slice_nr $Interactor(s)
    
    $Interactor(activeSlicer) SetReformatPoint $slice_nr $slice_x $slice_y
    
    scan [$Interactor(activeSlicer) GetIjkPoint] "%g %g %g" xi yi zi
    
    if {[string compare $event "KeyPress-p"] == 0} {
        puts "Adding Fiducial..."
    }
    if {[string compare $event "KeyPress-d"] == 0} {
        puts "Removing Fiducial..."
    }

}


#-------------------------------------------------------------------------------
# .PROC LevelSetsPrepareResult
#
#   Create the New Volume if necessary. Otherwise, ask to overwrite.
#   returns 1 if there is are errors 0 otherwise
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsCheckErrors {} {
    global LevelSets Volume

    if { ($LevelSets(InputVol) == $Volume(idNone)) || \
         ($LevelSets(ResultVol) == $Volume(idNone)) || \
         ($LevelSets(LabelResultVol) == $Volume(idNone)) } {

        DevErrorWindow "You cannot use Volume \"None\""
        return 1
    }
    return 0
}
#----- LevelSetsCheckErrors


#-------------------------------------------------------------------------------
# .PROC LevelSetsPrepareResultVolume
#
#   Check for Errors in the setup
#   returns 1 if there are errors, 0 otherwise
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsPrepareResultVolume {}  {
#    ----------------------------

    global LevelSets

    set v1 $LevelSets(InputVol)
    set v2 $LevelSets(ResultVol)
    set lm $LevelSets(LabelResultVol)

    # Check for Greyscale result
    if {$v2 == -5 } {
        set v2 [DevCreateNewCopiedVolume $v1 ""  $LevelSets(GreyScaleName) ]
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
    set LevelSets(ResultVol) $v2
    

    # Check for Labelmap result
    if {$lm == -5 } {
        set lm [DevCreateNewCopiedVolume $v1 ""  $LevelSets(LabelMapName) ]
        set node [Volume($lm,vol) GetMrmlNode]
        Mrml(dataTree) RemoveItem $node 
        set nodeBefore [Volume($v1,vol) GetMrmlNode]
        Mrml(dataTree) InsertAfterItem $nodeBefore $node
        MainUpdateMRML
    } else {
        # Are We Overwriting a volume?
        # If so, let's ask. If no, return.
        set lmname  [Volume($lm,node) GetName]
        set continue [DevOKCancel "Overwrite $lmname?"]
        if {$continue == "cancel"} { return 1 }
        # They say it is OK, so overwrite!
        Volume($lm,node) Copy Volume($v1,node)
    }
    set LevelSets(LabelResultVol) $lm

    return 0
}
#----- LevelSetsPrepareResultVolume



#-------------------------------------------------------------------------------
# .PROC LevelSetsUpdateResults
#
#   Update the Greyscale, Labelmap results and
#   the display
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsUpdateResults {} {
#    ----------------------

  global LevelSets Volume Gui Slice

  set input $LevelSets(InputVol)
  set res   $LevelSets(ResultVol)
  set lm    $LevelSets(LabelResultVol)

  [Volume($input,vol) GetOutput]  SetSpacing [lindex $LevelSets(spacing) 0] \
     [lindex $LevelSets(spacing) 1] \
     [lindex $LevelSets(spacing) 2]

  LevelSets(output)       SetSpacing [lindex $LevelSets(spacing) 0] \
     [lindex $LevelSets(spacing) 1] \
     [lindex $LevelSets(spacing) 2]

  # Set the Greyscale result
  Volume($res,vol) SetImageData LevelSets(output)
  Volume($res,node) SetScalarTypeToFloat

  # Set the LabelMap result
  vtkImageThreshold vtk_th
  vtk_th SetInput  LevelSets(output)
  vtk_th ThresholdByUpper 0 
  vtk_th ReplaceInOn
  vtk_th ReplaceOutOn
  vtk_th SetInValue 0
  vtk_th SetOutValue $LevelSets(LabelMapValue)
  vtk_th SetOutputScalarTypeToShort
  Volume($lm,vol)  SetImageData [vtk_th GetOutput]
  Volume($lm,node) SetScalarTypeToShort

  # set interpolation OFF
  Volume($lm,node) InterpolateOff
  foreach s $Slice(idList) {
    set Slice($s,labelVolID) $lm
    set Slice($s,foreVolID)  0
  }
  set Slice(opacity) 0.2
  MainSlicesSetOpacityAll
  # set the window and level
  set Volume(activeID) $lm
  MainVolumesSetParam Window 10
  MainVolumesSetParam Level  5
  MainVolumesRender
  MainVolumesUpdate $lm
  RenderAll
  vtk_th   Delete

}
#----- LevelSetsUpdateResults


#-------------------------------------------------------------------------------
# .PROC LevelSetsUpdateParams
#
#   Update the parameters that don't need reinitialization
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsUpdateParams {} {
#    ----------------------

  global LevelSets 

  # Number of iterations
  LevelSets(curv) SetNumIters            $LevelSets(NumIters)
  LevelSets(curv) SetAdvectionCoeff      $LevelSets(AdvectionCoeff)
  LevelSets(curv) Setcoeff_curvature     $LevelSets(SmoothingCoeff)
  LevelSets(curv) Setballoon_coeff       $LevelSets(BalloonCoeff)

  foreach i $LevelSets(SmoothingSchemeList) {
      if { $LevelSets(SmoothingScheme) == $LevelSets(SmoothingScheme${i}) } {
      LevelSets(curv) SetDoMean              $i
      }
  }

  LevelSets(curv) SetStepDt              $LevelSets(StepDt)
  LevelSets(curv) SetEvolveThreads       $LevelSets(NumberOfThreads)

  # ------ Set Narrow Band Size ------------------------ 
  LevelSets(curv) SetBand                $LevelSets(BandSize)
  LevelSets(curv) SetTube                $LevelSets(TubeSize)
  LevelSets(curv) SetReinitFreq          $LevelSets(ReinitFreq)
}
#----- LevelSetsUpdateParams


#-------------------------------------------------------------------------------
# .PROC LevelSetsShowProgress
#
# .ARGS   
# string progress
# .END
#-------------------------------------------------------------------------------
proc LevelSetsShowProgress { progress } {
    global  LevelSets BarId TextId Gui

    set k [LevelSets(curv) Getstep]

    set progress $progress
    set height   [winfo height $Gui(fStatus)]
    set width    [winfo width $Gui(fStatus)]

    if {[info exists BarId] == 1} {
        $Gui(fStatus).canvas delete $BarId
    }
    if {[info exists TextId] == 1} {
        $Gui(fStatus).canvas delete $TextId
    }
       
    set BarId [$Gui(fStatus).canvas create rect 0 0 [expr $progress*$width] \
        $height -fill [MakeColorNormalized ".5 .5 1.0"]]
 
    
    set TextId [$Gui(fStatus).canvas create text [expr $width/2] \
        [expr $height/3] -anchor center -justify center -text \
        "step $k"]
 
    update idletasks
}
#--- LevelSetsShowProgress


#-------------------------------------------------------------------------------
# .PROC LevelSetsEndProgress
#
# Clears the progress bar (for when done reading off disk, etc.)
# 
# .END
#-------------------------------------------------------------------------------
proc LevelSetsEndProgress {} {
    global BarId TextId Gui
    
    if {[info exists BarId] == 1} {
        $Gui(fStatus).canvas delete $BarId
    }
    if {[info exists TextId] == 1} {
        $Gui(fStatus).canvas delete $TextId
    }
    set height   [winfo height $Gui(fStatus)]
    set width    [winfo width $Gui(fStatus)]
    set BarId [$Gui(fStatus).canvas create rect 0 0 $width \
        $height -fill [MakeColorNormalized ".7 .7 .7"]]
    update idletasks
}
# --- LevelSetsEndProgress

#-------------------------------------------------------------------------------
# .PROC LevelSetsRun
#
#   Starts or Continues the current Level Set evolution
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsRun {} {
#    --------------

  global LevelSets Slice

  if { $LevelSets(Processing) == "OFF" } {
      LevelSetsStart
  } else {
      LevelSetsContinue
  }

}
#----- LevelSetsRun


#-------------------------------------------------------------------------------
# .PROC LevelSetsStart
#
#   Initialize and run the Level Set
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsStart {} {
#    -----------------

  global LevelSets Volume Gui Slice

  puts "RunLevelSets 1"
  if {[LevelSetsPrepareResultVolume] == 1} {
      return
  }

  puts "RunLevelSets 2"
  if {[LevelSetsCheckErrors] == 1} {
      return
  }

  set input   $LevelSets(InputVol)
  set res     $LevelSets(ResultVol)
  set lm      $LevelSets(LabelResultVol)
  set initvol $LevelSets(InitVol)

  #
  # the upsampling should not be used: NOT TESTED YET ...
  #
  if {($LevelSets(upsample_xcoeff) != "1")||\
      ($LevelSets(upsample_ycoeff) != "1")||\
      ($LevelSets(upsample_zcoeff) != "1")} {
    vtkImageResample magnify
    magnify SetDimensionality 3
    magnify SetInput [Volume($input,vol) GetOutput]

    magnify SetAxisMagnificationFactor 0 2
    magnify SetAxisMagnificationFactor 1 2
    magnify SetAxisMagnificationFactor 2 2

    magnify ReleaseDataFlagOff

    set InputImage  [magnify GetOutput]

    magnify Delete
  }  else {
    set InputImage [Volume($input,vol) GetOutput]
  }

  set LevelSets(spacing) [$InputImage GetSpacing]
  $InputImage   SetSpacing 1 1 1

  puts "RunLevelSets 3"

  #
  # ------ Level Set instanciation --------------------
  #
  vtkLevelSets LevelSets(curv)
  set LevelSets(Processing) "ON"

  #
  # ------ Debug Options ---------------------------------
  #
  LevelSets(curv) Setsavedistmap         0

  #
  # ------ Set Parameters -----------------------------
  #

  LevelSetsUpdateParams

  # Set the Dimension
  LevelSets(curv) SetDimension           $LevelSets(Dimension)
  # Threshold on the cumulative gradient histogram
  LevelSets(curv) SetHistoGradThreshold  $LevelSets(HistoGradThreshold)

  # Scheme and Coefficient for the advection force
  foreach i $LevelSets(AdvectionSchemeList) {
      if { $LevelSets(AdvectionScheme) == $LevelSets(AdvectionScheme${i}) } {
      LevelSets(curv) Setadvection_scheme              $i
      }
  }

  if {$LevelSets(LowIThreshold) > 0} {
      LevelSets(curv) SetUseLowThreshold 1
      LevelSets(curv) SetLowThreshold $LevelSets(LowIThreshold)
  }

  if {$LevelSets(HighIThreshold) > 0} {
      LevelSets(curv) SetUseHighThreshold 1
      LevelSets(curv) SetHighThreshold $LevelSets(HighIThreshold)
  }

  #
  # ------ Set Method & Threads ------------------------
  #

  # Method 0: Liana's code, 1: Fast Marching, 2: Fast Chamfer Distance
  LevelSets(curv) SetDMmethod            2

  #
  # ------ Set the expansion image ---------------------
  #

  # image between -1 and 1 in float format: evolution based on tissue statistics
  LevelSets(curv) SetNumGaussians         1
  puts "Mean intensity ="
  puts $LevelSets(MeanIntensity)
  puts "SD intensity ="
  puts $LevelSets(SDIntensity)
  LevelSets(curv) SetGaussian                 0 $LevelSets(MeanIntensity) $LevelSets(SDIntensity)
  LevelSets(curv) SetProbabilityThreshold     $LevelSets(ProbabilityThreshold)
  LevelSets(curv) SetProbabilityHighThreshold $LevelSets(ProbabilityHighThreshold)


  #
  # ------ Initialize the level set ---------------------
  #

  #
  #------- Check Initial Level Set Image
  #

  puts "LevelSets(InitScheme)=$LevelSets(InitScheme)"
  case $LevelSets(InitScheme) in {
  {"GreyScale Image" "Label Map"} {
      if { $initvol !=  $Volume(idNone) } {
        if { $initvol != $input } {
          puts "SetinitImage"
          LevelSets(curv) SetinitImage [Volume($initvol,vol) GetOutput]
        }
        puts "SetInitThreshold"
        LevelSets(curv) SetInitThreshold       $LevelSets(InitThreshold)
        if { $LevelSets(InitVolIntensity) == "Bright" } {
        LevelSets(curv) SetInitIntensityBright
        } else {
        if { $LevelSets(InitVolIntensity) == "Dark" } {
            LevelSets(curv) SetInitIntensityDark
        }
      }
      }
  }
  Fiducials {
      puts "Fiducials"

      #
      #------- Check Fiducial list
      #
      set fidlist [FiducialsGetPointIdListFromName "LevelSets-seed"]
      
      #Update numPoints module variable  
      set LevelSets(NumInitPoints) [llength $fidlist]
      
      if {$LevelSets(NumInitPoints) > 0} {
      LevelSets(curv) SetNumInitPoints $LevelSets(NumInitPoints)
      }
      

      #
      # Get the transform
      #

      set voltransf [SGetTransfromMatrix $input]
      puts "Transform ? \n"
      puts [$voltransf GetClassName]
      puts [$voltransf Print]
      $voltransf Inverse

      set radius 4
      set RASToIJKMatrix [Volume($input,node) GetRasToIjk]
      for {set n 0} {$n < $LevelSets(NumInitPoints)} {incr n} {
      set coord [FiducialsGetPointCoordinates [lindex $fidlist $n]]
      set cr [lindex $coord 0]
      set ca [lindex $coord 1]
      set cs [lindex $coord 2]
      #Transform from RAS to IJK
      scan [$voltransf TransformPoint $cr $ca $cs] "%g %g %g " xi1 yi1 zi1
      scan [$RASToIJKMatrix MultiplyPoint $xi1 $yi1 $zi1 1] "%g %g %g %g" xi yi zi hi
      puts "LevelSets(curv) SetInitPoint  $n $xi $yi $zi $LevelSets(InitRadius)"
      LevelSets(curv) SetInitPoint  $n [expr round($xi)] [expr round($yi)] \
          [expr round($zi)] $LevelSets(InitRadius)
      
      
      }
      $voltransf Delete
  }
  }

  #
  # ---------- Set input image and evolve ---------------
  #
  vtkImageData                           LevelSets(output)
  LevelSets(curv) InitParam              $InputImage LevelSets(output)

  #  set p LevelSets(curv)
  set Gui(progressText) "Pre-processing for Level Set"
    LevelSets(curv) AddObserver StartEvent MainStartProgress
    LevelSets(curv) AddObserver ProgressEvent "MainShowProgress LevelSets(curv)"
    LevelSets(curv) AddObserver EndEvent MainEndProgress

  LevelSets(curv) InitEvolution

#  LevelSetsCreateModel

  set k 0
  for {set j 0} { ($j < $LevelSets(NumIters)) && ($LevelSets(Processing) == "ON")} {incr j} {
    LevelSetsShowProgress [expr  1.*$j/$LevelSets(NumIters)]
    LevelSets(curv) Iterate
    update
    set k [expr $k+1]
    if { ($k == $LevelSets(DisplayFreq)) &&  ($LevelSets(DisplayFreq) > 0)} {
      set k 0
      LevelSetsUpdateResults
    }
  }

#  set Gui(progressText)   "executing one iteration"
#  curv SetStartMethod      MainStartProgress
#  curv SetProgressMethod  "MainShowProgress curv"
#  curv SetEndMethod        MainEndProgress

  LevelSetsUpdateResults
  LevelSetsEndProgress

}
#----- LevelSetsStart


#-------------------------------------------------------------------------------
# .PROC LevelSetsPause
#
#   Stops the current Level Set evolution
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsPause {} {
#    -------------

  global LevelSets 

  set LevelSets(Processing)  "STOP"

}
#----- LevelSetsPause


#-------------------------------------------------------------------------------
# .PROC LevelSetsContinue
#
#   Continues the current Level Set evolution
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsContinue {} {
#    --------------

  global LevelSets Slice

  set input $LevelSets(InputVol)
  set res   $LevelSets(ResultVol)
  set lm    $LevelSets(LabelResultVol)

  set LevelSets(Processing) "ON"

  [Volume($input,vol) GetOutput]   SetSpacing 1 1 1
  LevelSets(output)                SetSpacing 1 1 1

  LevelSetsUpdateParams

  set k 0
  for {set j 0} {($j < $LevelSets(NumIters))&& ($LevelSets(Processing) == "ON")} {incr j} {
#    puts $j
    LevelSetsShowProgress [expr  1.*$j/$LevelSets(NumIters)]
    LevelSets(curv) Iterate
    update
    set k [expr $k+1]
    if { ($k == $LevelSets(DisplayFreq)) &&  ($LevelSets(DisplayFreq) > 0)} {
      set k 0
      LevelSetsUpdateResults
    }
  }

  LevelSetsUpdateResults
  LevelSetsEndProgress

}
#----- LevelSetsContinue


#-------------------------------------------------------------------------------
# .PROC LevelSetsEnd
#
#   Ends the current evolution
#
# .END
#-------------------------------------------------------------------------------
proc LevelSetsEnd {} {

  global LevelSets 

  set input $LevelSets(InputVol);
  set res $LevelSets(ResultVol);

  LevelSets(curv) EndEvolution

  Volume($res,vol) SetImageData LevelSets(output)
  MainVolumesUpdate $res

  LevelSets(curv) UnRegisterAllOutputs
  LevelSets(curv) Delete
  LevelSets(output) Delete

  set LevelSets(Processing) "OFF"

}
#----- LevelSetsEnd


#-------------------------------------------------------------------------------
# .PROC LevelSetsCreateModel
#
#   Create a 3D model from the 0-isosurface
#
# .END
#-------------------------------------------------------------------------------
proc  LevelSetsCreateModel {} {
#     --------------------

  global LevelSets 

  set res $LevelSets(ResultVol);


  if { ($LevelSets(Processing) == "ON") ||  ($LevelSets(Processing) == "STOP") } {

    vtkImageMathematics vtk_immath
    vtk_immath SetInput1 LevelSets(output)
    vtk_immath SetOperationToMultiplyByK
    vtk_immath SetConstantK -1

    Volume($res,vol) SetImageData [vtk_immath GetOutput]

    vtk_immath Delete
  }

  if { $LevelSets(Processing) != "OFF" } {
    SModelMakerCreate [Volume($res,node) GetName] "LS_Model[LevelSets(curv) Getstep]" 0 0 1
  }

}
#----- LevelSetsCreateModel


#----------------------------------------------------------------------
# .PROC SetSPGR_WM_Param
#
#   Predefined parameters for White Matter Segmentation
#
# .END
#----------------------------------------------------------------------
proc SetSPGR_WM_Param {} {
#    ----------------

  global LevelSets Volume Gui

  set LevelSets(Dimension)              "3"
  set LevelSets(HistoGradThreshold)     "0.2"
  set LevelSets(AdvectionCoeff)            "1"
  set LevelSets(StepDt)                 "0.8"
  set LevelSets(ReinitFreq)             "6"
  set LevelSets(SmoothingCoeff)              "0.2"
  set LevelSets(SmoothingScheme)        "Mean Curvature"
  set LevelSets(BandSize)               "3"
  set LevelSets(TubeSize)               "2"
  set LevelSets(NumIters)               "50"
  set LevelSets(MeanIntensity)          "100"
  set LevelSets(SDIntensity)            "15"
  set LevelSets(BalloonCoeff)           "0.3"
  set LevelSets(ProbabilityThreshold)   "0.3"
  set LevelSets(NumInitPoints)          "0"
  
}
#----- SetSPGR_WM_Param


#----------------------------------------------------------------------
# .PROC SetMRAParam
#
#   Predefined parameters for MRA Segmentation
#
# .END
#----------------------------------------------------------------------
proc SetMRAParam {} {
#    -----------

  global LevelSets Volume Gui

  #
  set LevelSets(Dimension)                  "3"
  set LevelSets(HistoGradThreshold)         "0.4"
  set LevelSets(AdvectionCoeff)                "0.8"
  set LevelSets(StepDt)                     "0.8"
  set LevelSets(SmoothingScheme)            "Minimal Curvature"
  set LevelSets(ReinitFreq)                 "6"
  set LevelSets(SmoothingCoeff)                  "0.1"
  set LevelSets(BandSize)                   "3"
  set LevelSets(TubeSize)                   "2"
  set LevelSets(NumIters)                   "100"
  set LevelSets(MeanIntensity)              "80"
  set LevelSets(SDIntensity)                "45"
  set LevelSets(BalloonCoeff)               "0.8"
  set LevelSets(ProbabilityThreshold)       "0.2"
  set LevelSets(ProbabilityHighThreshold)   "100"
  set LevelSets(NumInitPoints)              "0"
  set LevelSets(InitThreshold)              "200"

}
#----- SetMRAParam


#----------------------------------------------------------------------
# .PROC SetUSLiver
#
#   Predefined parameters for US Liver
#
# .END
#----------------------------------------------------------------------
proc SetUSLiverParam {} {
#    -----------

  global LevelSets Volume Gui

  #
  set LevelSets(Dimension)                  "3"
  set LevelSets(HistoGradThreshold)         "0.3"
  set LevelSets(AdvectionCoeff)             "0.8"
  set LevelSets(StepDt)                     "0.6"
  set LevelSets(SmoothingScheme)            "Minimal Curvature"
  set LevelSets(ReinitFreq)                 "6"
  set LevelSets(SmoothingCoeff)             "0.3"
  set LevelSets(BandSize)                   "3"
  set LevelSets(TubeSize)                   "2"
  set LevelSets(NumIters)                   "200"
  set LevelSets(MeanIntensity)              "25"
  set LevelSets(SDIntensity)                "12"
  set LevelSets(BalloonCoeff)               "0.5"
  set LevelSets(ProbabilityThreshold)       "0.2"
  set LevelSets(NumInitPoints)              "0"
  # upwind vectors scheme
  set LevelSets(AdvectionScheme)            $LevelSets(AdvectionScheme0)

}
#----- SetUSLiverParam

#----------------------------------------------------------------------
# .PROC SetUSLiver
#
#   Predefined parameters for US Liver
#
# .END
#----------------------------------------------------------------------
proc SetHeartCTParam {} {
#    ---------------

  global LevelSets Volume Gui

  #
  # Main
  #
  set LevelSets(Dimension)                  "3"
  set LevelSets(HistoGradThreshold)         "0.2"
  #
  # Equation
  #
  set LevelSets(AdvectionCoeff)             "0.5"
  set LevelSets(StepDt)                     "0.6"
  set LevelSets(SmoothingScheme)            "Minimal Curvature"
  set LevelSets(ReinitFreq)                 "6"
  set LevelSets(SmoothingCoeff)             "0.2"
  set LevelSets(BalloonCoeff)               "0.5"
  set LevelSets(BandSize)                   "3"
  set LevelSets(TubeSize)                   "2"
  set LevelSets(NumIters)                   "300"
  #
  # Prob
  #
  set LevelSets(LowIThreshold)              "970"
  set LevelSets(MeanIntensity)              "1070"
  set LevelSets(SDIntensity)                "25"
  set LevelSets(ProbabilityThreshold)       "0.3"
  set LevelSets(NumInitPoints)              "0"
  # upwind vectors scheme
  # set LevelSets(AdvectionScheme)            $LevelSets(AdvectionScheme0)

}
#----- SetUSLiverParam


#----------------------------------------------------------------------
# .PROC LevelSetsSaveParam
#
#   Predefined parameters for US Liver
#
# .END
#----------------------------------------------------------------------
proc LevelSetsSaveParam {} {
#    -----------

  global LevelSets Volume Gui Module

#  iwidgets::fileselectiondialog .fsd \
#   -mask "*.lvp" \
#   -directory "../" \
#  -fileslabel "Level Sets Parameters" 

#  if [.fsd activate] {

    set fileid [open "LevelSetsParams.txt" w]

    #
    puts $fileid "Dimension:           $LevelSets(Dimension)"
    puts $fileid "HistoGradThreshold   $LevelSets(HistoGradThreshold)"
    puts $fileid "\n"
    puts $fileid "InitScheme           $LevelSets(InitScheme)"

    puts $fileid "InitRadius           $LevelSets(InitRadius)"
    set fidlist [FiducialsGetPointIdListFromName "LevelSets-seed"]
    for {set n 0} {$n < $LevelSets(NumInitPoints)} {incr n} {
    set coord [FiducialsGetPointCoordinates [lindex $fidlist $n]]
    puts $fileid "  Fiducial    $n ( $coord )"
    }
    
    puts $fileid "NumInitPoints        $LevelSets(NumInitPoints)"
    puts $fileid "\n"
    puts $fileid "SmoothingScheme      $LevelSets(SmoothingScheme)"
    puts $fileid "SmoothingCoeff       $LevelSets(SmoothingCoeff)"
    puts $fileid "\n"
    puts $fileid "MeanIntensity        $LevelSets(MeanIntensity)"
    puts $fileid "SDIntensity          $LevelSets(SDIntensity)"
    puts $fileid "ProbabilityThreshold $LevelSets(ProbabilityThreshold)"
    puts $fileid "BalloonCoeff         $LevelSets(BalloonCoeff)"
    puts $fileid "\n"
    puts $fileid "AdvectionScheme      $LevelSets(AdvectionScheme)"
    puts $fileid "AdvectionCoeff       $LevelSets(AdvectionCoeff)"
    puts $fileid "\n"
    puts $fileid "NumIters             $LevelSets(NumIters)"
    puts $fileid "Total iterations     [LevelSets(curv) Getstep]"
    puts $fileid "BandSize             $LevelSets(BandSize)"
    puts $fileid "TubeSize             $LevelSets(TubeSize)"
    puts $fileid "ReinitFreq           $LevelSets(ReinitFreq)"


  # upwind vectors scheme


    close $fileid
#}

}
#----- LevelSetsSaveParam

