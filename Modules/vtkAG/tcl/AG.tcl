#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: AG.tcl,v $
#   Date:      $Date: 2007/07/30 19:21:40 $
#   Version:   $Revision: 1.25 $
# 
#===============================================================================
# FILE:        AG.tcl
# PROCEDURES:  
#   AGInit
#   AGBindingCallback
#   AGUpdateMRML
#   AGBuildGUI
#   AGStartCNIWebPage 
#   AGBuildHelpFrame
#   AGBuildMainFrame
#   AGBuildTransformFrame
#   AGBuildExpertFrame
#   Test
#   ModifyOptions
#   AGEnter
#   AGExit
#   AGPrepareResult
#   AGPrepareResultVolume
#   AGWritevtkImageData image filename
#   AGIntensityTransform Source
#   AGTransformScale Source Target
#   AGWriteHomogeneousOriginal
#   AGWriteHomogeneousOriginal
#   AGReadHomogeneousOriginal
#   AGReadHomogeneousOriginal
#   AGWriteHomogeneous
#   AGReadGrid
#   AGWriteGrid
#   WritePWConstant it fid
#   WritePolynomial it fileid
#   WriteIntensityTransform it fileid
#   AGReadLinearNonLinearTransform gt
#   AGWriteLinearNonLinearTransform gt flag it FileName
#   AGWriteTransform gt flag it FileName
#   AGThresholdedResampledData Source Target Output
#   RunAG
#   AGBatchProcessResampling
#   AGCoregister
#   AGTransformOneVolume SouceVolume TargetVolume
#   AGPreprocess Source Target SourceVol TargetVol
#   AGThresholdedResampledData Source Target Output
#   AGResample Source Target
#   AGNormalize SourceImage TargetImage NormalizeSource SourceScanOrder TargetScanOrder
#   AGTestWriting
#   AGReadvtkImageData
#   AGTestReadvtkImageData
#   AGUpdateInitial
#   AGTurnInitialOff
#   AGCreateLinMat
#   AGSaveGridTransform
#   AGColorComparison
#   AGCommandLine
#==========================================================================auto=
#   ==================================================
#   Module: vtkAG
#   Author: Lifeng Liu
#   Email:  liu@bwh.harvard.edu
#
#   This module implements a version of #    
#   It comes with a Tcl/Tk interface for the '3D Slicer'.
#   ==================================================
#   Copyright (C) 2003  
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
#   The full GNU Lesser General Public License file is in vtkAG/LesserGPL_license.txt



#-------------------------------------------------------------------------------
#  Description
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are (some of) the variables defined by this module.
# 
#  int AG(count) counts the button presses for the demo 
#  list AG(eventManager)  list of event bindings used by this module
#  widget AG(textBox)  the text box widget
#-------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# .PROC AGInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGInit {} {
    global AG Module Volume Transform
    
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
    set m AG
    set Module($m,row1List) "Help Main Transform Expert"
    set Module($m,row1Name) "{Help} {Main} {Transform} {Expert} "
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
    #   set Module($m,procVTK) AGBuildVTK
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
    set Module($m,procGUI)   AGBuildGUI
    set Module($m,procEnter) AGEnter
    set Module($m,procExit)  AGExit
    set Module($m,procMRML)  AGUpdateMRML

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
        {$Revision: 1.25 $} {$Date: 2007/07/30 19:21:40 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set AG(TestReadingWriting) 0   
    set AG(CountNewResults) 1
    set AG(InputVolSource2) $Volume(idNone)
    set AG(InputVolTarget2) $Volume(idNone)

    set AG(InputVolSource)  $Volume(idNone)
    set AG(InputVolTarget)  $Volume(idNone)
    set AG(InputVolMask)    $Volume(idNone)
    set AG(ResultVol)       -5
    set AG(ResultVol2)      $Volume(idNone)
    set AG(CoregVol)        $Volume(idNone)

    #General options

# set AG(DEBUG) to 1 to display more information.
    set AG(Debug) 0
   
    set AG(Linear)    "1"
    set AG(Warp)      "1"
    # It is not necessary to see all the information
    set AG(Verbose)   "0"
    set AG(Scale)    "-1"
    set AG(2D)        "0"
    
    #GCR options
    set AG(Linear_group)  "2"
    set AG(Gcr_criterion) "1"
   
    # Initial Transform options
    set AG(Initial_tfm) "0"
    set AG(Initial_lin)  "0"
    set AG(Initial_grid) "0"
    set AG(Initial_prev) "0"
    set AG(Initial_lintxt) "Off"
    set AG(Initial_gridtxt) "Off"
    set AG(Initial_prevtxt) "Off"

    #Demons options
    set AG(Tensors)  "0"
    set AG(Interpolation) "1"
    set AG(Iteration_min) "0"
    set AG(Iteration_max)  "50"
    set AG(Level_min)  "-1"
    set AG(Level_max)  "-1"
    set AG(Epsilon)    "1e-3"
    set AG(Stddev_min) "0.85"
    # [expr sqrt(-1./(2.*log(.5)))] = 0.85
    set AG(Stddev_max) "1.25"
    set AG(SSD)    "1" 

   #Intensity correction

    set AG(Intensity_tfm) "mono-functional"   
    set AG(Force)   "1"
    set AG(Degree)   1
    set AG(Ratio)    1
    set AG(Nb_of_functions)  1
    set AG(Nb_of_pieces)    {}
    set AG(Use_bias)        0
    set AG(Boundaries)      {}


    set AG(AskFlag) 1 
   # set AG(StandardDev)   "1"
   # set AG(Threshold)     "10"
   # set AG(Attachment)    "0.05"
   # set AG(Iterations)    "5"
   # set AG(IsoCoeff)      "0.2"
    #set AG(TruncNegValues)  "0"
   # set AG(NumberOfThreads) "4"

    #set AG(TangCoeff)     "1"

    #set AG(MincurvCoeff)  "1"
    #set AG(MaxcurvCoeff)  "0.1"

    # Event bindings! (see AGEnter, AGExit, tcl-shared/Events.tcl)
    set AG(eventManager)  { \
        {all <Shift-1> {AGBindingCallback Shift-1 %W %X %Y %x %y %t}} \
        {all <Shift-2> {AGBindingCallback Shift-2 %W %X %Y %x %y %t}} \
        {all <Shift-3> {AGBindingCallback Shift-3 %W %X %Y %x %y %t}} }
}

#-------------------------------------------------------------------------------
# .PROC AGBindingCallback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBindingCallback {args} {
    # placeholder for future callbacks
}


#-------------------------------------------------------------------------------
# .PROC AGUpdateMRML
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
proc AGUpdateMRML {} {
    global AG Volume
    
    DevUpdateNodeSelectButton Volume AG InputVolSource   InputVolSource   DevSelectNode
    DevUpdateNodeSelectButton Volume AG InputVolTarget   InputVolTarget   DevSelectNode
    DevUpdateNodeSelectButton Volume AG InputVolMask   InputVolMask   DevSelectNode
    DevUpdateNodeSelectButton Volume AG InputVolSource2   InputVolSource2   DevSelectNode
    DevUpdateNodeSelectButton Volume AG InputVolTarget2   InputVolTarget2   DevSelectNode
 
    DevUpdateNodeSelectButton Volume AG ResultVol  ResultVol  DevSelectNode  0 1 1
    DevUpdateNodeSelectButton Volume AG ResultVol2  ResultVol2  DevSelectNode 0 1 1

    if {[catch "Volume($AG(ResultVol),node) GetName"]==1} {
      set AG(ResultVol) -5
    }
    if {[catch "Volume($AG(ResultVol2),node) GetName"]==1} {
      set AG(ResultVol2) -5
    }
    DevSelectNode Volume $AG(ResultVol) AG ResultVol ResultVol
    DevSelectNode Volume $AG(ResultVol2) AG ResultVol2 ResultVol2
    
    DevUpdateNodeSelectButton Volume AG CoregVol CoregVol DevSelectNode 
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
# .PROC AGBuildGUI
#
# Create the Graphical User Interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBuildGUI {} {
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Parameters" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(AG,fMain)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Parameters
    #-------------------------------------------
    
    AGBuildHelpFrame
       
    AGBuildExpertFrame

    AGBuildMainFrame

    AGBuildTransformFrame
}

#-------------------------------------------------------------------------------
# .PROC AGStartCNIWebPage 
#
#   Start Browser and go to CNI Web
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGStartCNIWebPage {} {

    MainHelpLaunchBrowserURL http://cni.bwh.harvard.edu/

} 


# end AGStartCNIWebPage

#-------------------------------------------------------------------------------
# .PROC AGBuildHelpFrame
#
#   Create the Help frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBuildHelpFrame {} {

    global Gui AG Module Volume

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The AG module contains  <P>
    The input parameters are:
    <BR>
    <UL>
    <LI><B> Input Target Channel 1:</B> 
    <LI><B> Input Target Channel 2:</B>
    <LI><B> Input Source Channel 1:</B>
    <LI><B> Input Source Channel 2:</B>
    <LI><B> Input Mask  :</B> 
    <P> 

    If the Source channel 2 or Target channel 2 is empty, then only one channel is used for the registration. <P>
    If only an initial transform has to be applied to the data, select for source and target the same volume. <P>
"
    regsub -all "\n" $help {} help
    MainHelpApplyTags AG $help
    MainHelpBuildGUI  AG

    set fHelp $Module(AG,fHelp)
    set f $fHelp
    set f $f.fBtns

    eval {button $f.bCNIWeb -text "cni.bwh.harvard.edu" -width 25 \
        -command AGStartCNIWebPage } $Gui(WBA)
    
    pack  $f.bCNIWeb -side left -padx $Gui(pad)

}
# end AGBuildHelpFrame


#-------------------------------------------------------------------------------
# .PROC AGBuildMainFrame
#
#   Create the Main frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBuildMainFrame {} {


    global Gui AG Module Volume

    #-------------------------------------------
    # Main frame
    #-------------------------------------------
    set fMain $Module(AG,fMain)
    set f $fMain

    set f $fMain.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Main screen"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    set f $fMain  
    set volnames {"Target1" "Target2" "Source1" "Source2" "Mask" "Result1" "Result2"}
    foreach v $volnames {
      frame $f.f$v -bg $Gui(activeWorkspace)  -bd 3
    }


    pack  $f.fTarget1 $f.fSource1 $f.fResult1 $f.fMask \
          $f.fTarget2 $f.fSource2 $f.fResult2 \
      -side top -padx 0 -pady 1 -fill x
    
    #-------------------------------------------
    # Parameters->Input/Output Frame
    #-------------------------------------------
#    set f $fMain.fIO
    
    # Add menus that list models and volumes
    set f $fMain.fTarget1
    DevAddSelectButton  AG $f InputVolTarget "Target Channel 1 " Pack \
    "Select channel1 of the input target volume." 20
    set f $fMain.fTarget2
    DevAddSelectButton  AG $f InputVolTarget2 "Target Channel 2 " Pack \
    "Select channel 2 of the input target volume (optional)." 20
    set f $fMain.fSource1
    DevAddSelectButton  AG $f InputVolSource "Source Channel 1" Pack \
    "Select channel 1 of the input source volume." 20
    set f $fMain.fSource2
    DevAddSelectButton  AG $f InputVolSource2 "Source Channel 2" Pack \
    "Select channel 2 of the input source volume (optional)." 20  
    set f $fMain.fMask
    DevAddSelectButton  AG $f InputVolMask "Mask                   " Pack \
    "Select input mask volume (optional)." 20
    set f $fMain.fResult1
    DevAddSelectButton  AG $f ResultVol "Result Channel 1 " Pack \
    "Select channel 1 of the result volume" 20
    set f $fMain.fResult2
    DevAddSelectButton  AG $f ResultVol2 "Result Channel 2 " Pack \
    "Select channel 2 of the result volume (optional)." 20
    

    set f $fMain.fMethod
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x 

    DevAddLabel $f.l "Method:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    eval {label $f.lInitial} $Gui(WLA)
    eval {checkbutton $f.cInitialLabel \
        -text  "Initial" -command AGTurnInitialOff -variable AG(Initial_tfm) \
         -indicatoron 0 } $Gui(WCA)
    pack $f.lInitial $f.cInitialLabel -side left 
    TooltipAdd $f.cInitialLabel "Click to set initial transformation(s) off."

    eval {label $f.lLinear} $Gui(WLA)
    eval {checkbutton $f.cLinearLabel \
        -text  "Linear" -variable AG(Linear) \
         -indicatoron 0 } $Gui(WCA)
    pack $f.lLinear $f.cLinearLabel -side left -padx 2
    TooltipAdd $f.cLinearLabel "Perform a linear registration. Can be combined with non-linear."
 
    eval {label $f.lNonLinear} $Gui(WLA)
  
    eval {checkbutton $f.cNonLinearLabel \
        -text "Non-linear" -variable AG(Warp) \
        -indicatoron 0 } $Gui(WCA)
    pack $f.lInitial $f.lNonLinear $f.cNonLinearLabel -side left  
    TooltipAdd $f.cNonLinearLabel "Perform a non-linear registration. Can be combined with linear."

    #-------------------------------------------
    # Parameters->Run Frame
    #-------------------------------------------
    set f $fMain.fRun
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx 0 -pady $Gui(pad) -fill x
    DevAddButton $f.bRun "Run" "RunAG"
    DevAddButton $f.bColor "Color comparison" "AGColorComparison"
    DevAddButton $f.bTestBatch "Batch co-registration" "AGBatchProcessResampling"
    pack $f.bRun  $f.bColor -pady $Gui(pad)
    TooltipAdd $f.bRun "Run the registration process."
    TooltipAdd $f.bColor "Create image with result channel 1 as magenta and target channel 1 as green channel."
    #TooltipAdd $f.bTestBatch "Co-register all loaded volumes using the transformation just computed."

    set f $fMain.fCoregbutton
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx 0 -pady 2 -fill x
    DevAddSelectButton  AG $f CoregVol "Volume for co-registration" Grid \
    "Select volume in alignment with source volume to co-register to target." 20

    set f $fMain.fDoCoreg
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx 0 -pady 2 -fill x
    DevAddButton $f.bCoregister "Co-register" "AGCoregister"
    TooltipAdd $f.bCoregister "Run coregistration based on previous computed transformation."
    pack $f.bCoregister -pady 0
}

#-------------------------------------------------------------------------------
# .PROC AGBuildTransformFrame
#
#   Create the Transform frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBuildTransformFrame {} {
    global Gui AG Module Volume Matrix

    set fTransform $Module(AG,fTransform)
  
    set f $fTransform.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Transforms"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    
    #--------------------------------------------
    # Transforms -> Initial Transforms
    #--------------------------------------------
    
    set f $fTransform.fInitial
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w
    DevAddLabel $f.linittfms "Initial Transforms"
    $f.linittfms configure -font {helvetica 9 bold}
    pack $f.linittfms -side top -padx $Gui(pad) -pady 2 -anchor w

    set f $fTransform.fInitialLinear
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 -anchor w

    eval {label $f.lActive -text "Linear"} $Gui(WLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 15 \
            -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -padx $Gui(pad)
    TooltipAdd $f.lActive "Select linear transformation matrix for initial transform. Use Alignments-module to display/edit linear matrix."

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Matrix(mbActiveList) $f.mbActive
    lappend Matrix(mActiveList)  $f.mbActive.m

    eval {checkbutton $f.cInitLin \
        -textvariable AG(Initial_lintxt) -command "AGUpdateInitial lin" \
    -variable AG(Initial_lin) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitLin -side left -padx 0 -pady 0
    TooltipAdd $f.cInitLin "Set initial linear transform on/off."

    set f $fTransform.fInitialGrid
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 
    DevAddFileBrowse $f AG InitGridTfmName "Load VTK grid-transform" "" "vtk"
    eval {label $f.lInitialGrid} $Gui(WLA)
    TooltipAdd $f.lInitialGrid "Select 3 scalar component VTK-file for initial non-linear transform."
    DevAddLabel $f.lSpace " "
    pack $f.lSpace -side left -padx 40 -pady 0

    eval {checkbutton $f.cInitGrid \
        -textvariable AG(Initial_gridtxt) -command "AGUpdateInitial grid" \
    -variable AG(Initial_grid) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitGrid -side left -padx 0 -pady 0
    TooltipAdd $f.cInitGrid "Set initial grid transform on/off."

    set f $fTransform.fInitialCalc
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    DevAddLabel $f.lInitPrev "Previous"
    pack $f.lInitPrev -side left -padx $Gui(pad) -padx $Gui(pad)
    eval {checkbutton $f.cInitPrev \
        -textvariable AG(Initial_prevtxt) -command "AGUpdateInitial prev" \
    -variable AG(Initial_prev) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitPrev -side left -padx 0 -pady 0
    TooltipAdd $f.cInitPrev "Set on/off to use previous calculated transform as initial transform."

    #--------------------------------------------
    # Transforms -> Save Transforms
    #--------------------------------------------

    set f $fTransform.fSaveTfm
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w
    DevAddLabel $f.lsavetfm "Save Transforms"
    $f.lsavetfm configure -font {helvetica 9 bold}
    pack $f.lsavetfm -side top -padx $Gui(pad) -pady 2 -anchor w


    set f $fTransform.fCreateLin
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddButton $f.bCreateLin "Create lin.tfm. matrix" "AGCreateLinMat"
    pack $f.bCreateLin  
    TooltipAdd $f.bCreateLin "Save a just computed linear transform as a matrix in the main data view. The matrix is RAS to RAS only if target and source volumes have the same scan order."
    
    set f $fTransform.fSaveGrid
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 
    DevAddButton $f.bSaveGridTfm "Save VTK grid-transform" {AGSaveGridTransform}
    pack $f.bSaveGridTfm -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bSaveGridTfm "Save just computed non-linear transform to file."

  
    set f $fTransform.fSaveAll
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 
    DevAddButton $f.bSaveAllTfm "Save linear and grid transforms" {AGWriteLinearNonLinearTransform}
    pack $f.bSaveAllTfm -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bSaveAllTfm "Save computed linear and non-linear transforms to file."
  
    set f $fTransform.fReadAll
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 
    DevAddButton $f.bReadAllTfm "Read linear and grid-transforms" {AGReadLinearNonLinearTransform}
    pack $f.bReadAllTfm -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bReadAllTfm "Read  previous linear and non-linear transforms from file for co-registering."
  

  

}
# end AGBuildTransformFrame



#-------------------------------------------------------------------------------
# .PROC AGBuildExpertFrame
#
#   Create the Expert frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBuildExpertFrame {} {
    global Gui AG Module

    set fExpert $Module(AG,fExpert)

    set f $fExpert.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Expert settings"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    set f $fExpert.fExp
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
     
    # Use option menu 
    #set  menuLRoptions [tk_optionMenu $f.linearRegistrationOptions AG(LinearRegistrationOption) {do not compute linear transformation} one two three] 
   #$f.linearRegistrationOptions configure  -font {helvetica 8} 
   #$menuLRoptions configure -font {helvetica 8} 
  # pack $f.linearRegistrationOptions -side top -pady $Gui(pad) -padx $Gui(pad) -expand 1 -fill x
 # Use menu button.

# constrain for linear registration.    
   eval {label $f.lLR -text "Linear registration"} $Gui(WLA)
    set AG(LRName) "affine group"
    eval {menubutton $f.mbLR -text "$AG(LRName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbLR.m} $Gui(WMBA)
    eval {menu $f.mbLR.m} $Gui(WMA)
    set AG(mbLR) $f.mbLR
    set m $AG(mbLR).m
   foreach v "{translation} {rigid group} {similarity group} {affine group}" {
       $m add command -label $v -command "ModifyOptions LinearRegistration {$v}"
   }
    TooltipAdd $f.mbLR "Choose how to restrict linear registration." 
    #pack $f.lLR $f.mbLR  -padx $Gui(pad) -side left -anchor w   
   grid $f.lLR  $f.mbLR -pady 2 -padx $Gui(pad) -sticky w


# warp and force
    eval {label $f.lWarp -text "Warp"} $Gui(WLA)
    set AG(WarpName) "demons"
    eval {menubutton $f.mbWarp -text "$AG(WarpName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbWarp.m} $Gui(WMBA)
    eval {menu $f.mbWarp.m} $Gui(WMA)
    set AG(mbWarp) $f.mbWarp
    set m $AG(mbWarp).m
   foreach v "{demons} {optical flow}" {
       $m add command -label $v -command "ModifyOptions Warp {$v}"
   }
    TooltipAdd $f.mbWarp "Choose how to warp." 
    #pack $f.lWarp $f.mbWarp -after $f.lLR  -padx $Gui(pad) -side left -anchor w   
    grid $f.lWarp $f.mbWarp   -pady 2 -padx $Gui(pad) -sticky w

# Intensity transformation
    eval {label $f.lIntensityTFM -text "Intensity Transform"} $Gui(WLA)
    set AG(IntensityTFMName) "mono functional"
    eval {menubutton $f.mbIntensityTFM -text "$AG(IntensityTFMName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbIntensityTFM.m} $Gui(WMBA)
    eval {menu $f.mbIntensityTFM.m} $Gui(WMA)
    set AG(mbIntensityTFM) $f.mbIntensityTFM
    set m $AG(mbIntensityTFM).m
   foreach v "{mono functional} {piecewise median} {no intensity transform}" {
       $m add command -label $v -command "ModifyOptions IntensityTFM {$v}"
   }
    TooltipAdd $f.mbIntensityTFM "Choose intensity transform typehow."  
    grid $f.lIntensityTFM $f.mbIntensityTFM   -pady 2 -padx $Gui(pad) -sticky w

# Criterion
    eval {label $f.lCriterion -text "Criterion"} $Gui(WLA)
    set AG(CriterionName) "GCR L1 norm"
    eval {menubutton $f.mbCriterion -text "$AG(CriterionName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbCriterion.m} $Gui(WMBA)
    eval {menu $f.mbCriterion.m} $Gui(WMA)
    set AG(mbCriterion) $f.mbCriterion
    set m $AG(mbCriterion).m
   foreach v "{GCR L1 norm} {GCR L2 norm} {Correlation} {mutual information}" {
       $m add command -label $v -command "ModifyOptions Criterion {$v}"
   }
    TooltipAdd $f.mbCriterion "Choose the criterion." 
    grid $f.lCriterion $f.mbCriterion   -pady 2 -padx $Gui(pad) -sticky w



# checkbox type options:  not use SSD, 2D registration, estimate bias, last 6 channels of data are tensors
    eval {label $f.lUseSSD -text "SSD:"} $Gui(WLA)
  
    eval {checkbutton $f.cUseSSDLabel \
        -text  "Use SSD" -variable AG(SSD) \
        -width 15  -indicatoron 0 } $Gui(WCA)
    grid $f.lUseSSD $f.cUseSSDLabel  -pady 2 -padx $Gui(pad) -sticky w
    TooltipAdd $f.cUseSSDLabel "If set the algorithm halts when it converges. The method convergence when the difference between the Sum Squared Difference (SSD) score of two consecutive iterations is smaller then Epsilon* (SSD of last iteration)"    

    eval {label $f.lEstimateBias -text "Bias:"} $Gui(WLA)
    eval {checkbutton $f.cEstimateBias \
        -text  "Estimate Bias" -variable AG(Use_bias) \
        -width 15  -indicatoron 0 } $Gui(WCA)
    grid $f.lEstimateBias $f.cEstimateBias  -pady 2 -padx $Gui(pad) -sticky w
    TooltipAdd $f.cEstimateBias "Press to set/unset to estimate bias with intensity transformation." 
     eval {label $f.l2DRegistration -text "2D registration:"} $Gui(WLA)
  
    eval {label $f.lInterpolation -text "Interpolation:"} $Gui(WLA)
    eval {checkbutton $f.cInterpolation \
        -text  "Interpolate" -variable AG(Interpolation) \
        -width 15  -indicatoron 0 } $Gui(WCA)
    grid $f.lInterpolation $f.cInterpolation  -pady 2 -padx $Gui(pad) -sticky w
    TooltipAdd $f.cInterpolation "Press to set for cubic interpolation or unset (for nearest neighbor)" 


    eval {checkbutton $f.c2DRegistration \
        -text  "2D" -variable AG(2D) \
        -width 15  -indicatoron 0 } $Gui(WCA)
    grid $f.l2DRegistration  $f.c2DRegistration  -pady 2 -padx $Gui(pad) -sticky w
    TooltipAdd $f.c2DRegistration "Press to set/unset to do 2D registration."

    #eval {label $f.lTensor -text "Tensors:"} $Gui(WLA)
  
    #eval {checkbutton $f.cTensor \
    #    -text  "last 6 channels are tensors" -variable AG(Tensors) \
    #    -width 20  -indicatoron 0 } $Gui(WCA)
    #grid $f.lTensor $f.cTensor  -pady 2 -padx $Gui(pad) -sticky e
    #TooltipAdd $f.cTensor "Press to set/unset that last 6 channels are tensors."

# Verbose level
  #  eval {label $f.lVerbose -text "Verbose"} $Gui(WLA)
  #  set AG(VerboseName) "1"
  #  eval {menubutton $f.mbVerbose -text "$AG(VerboseName)" -relief raised -bd 2 -width 15 \
  #      -menu $f.mbVerbose.m} $Gui(WMBA)
  #  eval {menu $f.mbVerbose.m} $Gui(WMA)
  #  set AG(mbVerbose) $f.mbVerbose
  #  set m $AG(mbVerbose).m
  # foreach v "0 1 2" {
  #     $m add command -label $v -command "ModifyOptions Verbose {$v}"
  # }
  #  TooltipAdd $f.mbVerbose "Choose the Verbose." 
  #  grid $f.lVerbose $f.mbVerbose   -pady 2 -padx $Gui(pad) -sticky w

# entry type options

   eval {label $f.lScale -text "Scale factor:"} $Gui(WLA) 
   eval {entry $f.eScale -justify right -width 6 -textvariable AG(Scale)} $Gui(WEA)
   grid $f.lScale $f.eScale -pady 2 -padx $Gui(pad) -sticky w   
   TooltipAdd $f.eScale  "Enter the scale factor to scale the intensities before registration."
 
   eval {label $f.lDegree -text "Degree:"} $Gui(WLA) 
   eval {entry $f.eDegree -justify right -width 6 -textvariable AG(Degree)} $Gui(WEA)
   grid $f.lDegree $f.eDegree -pady 2 -padx $Gui(pad) -sticky w   
   TooltipAdd $f.eDegree  "Enter the degree of polynomials."

   eval {label $f.lRatio -text "Ratio of points:"} $Gui(WLA) 
   eval {entry $f.eRatio -justify right -width 6 -textvariable AG(Ratio)} $Gui(WEA)
   grid $f.lRatio $f.eRatio -pady 2 -padx $Gui(pad) -sticky w   
   TooltipAdd $f.eRatio  "Enter the ratio of points used for polynomial estimate."



   eval {label $f.lNb_of_functions -text "Number of functions:"} $Gui(WLA) 
   eval {entry $f.eNb_of_functions -justify right -width 6 -textvariable AG(Nb_of_functions)} $Gui(WEA)
   grid $f.lNb_of_functions $f.eNb_of_functions -pady 2 -padx $Gui(pad) -sticky w   
   TooltipAdd $f.eNb_of_functions  "Enter the number of intensity transformation functions."



   eval {label $f.lEpsilon -text "Epsilon:"} $Gui(WLA) 
   eval {entry $f.eEpsilon -justify right -width 6 -textvariable AG(Epsilon)} $Gui(WEA)
   grid $f.lEpsilon $f.eEpsilon -pady 2 -padx $Gui(pad) -sticky w  
   TooltipAdd $f.eEpsilon  "Enter the maximum SSD value between successive iterations ."

   
   set f $fExpert.fIter
   frame $f -bg $Gui(activeWorkspace)
   pack $f -side top -padx $Gui(pad) -pady 0 -fill x -anchor n

   eval {label $f.lIteration_min -text "Iteration min-max:   "} $Gui(WLA) 
   eval {entry $f.eIteration_min -justify right -width 6 -textvariable AG(Iteration_min)} $Gui(WEA)
   pack $f.lIteration_min $f.eIteration_min -pady 0 -padx $Gui(pad) -side left    
   TooltipAdd $f.eIteration_min  "Enter the number of minimum iterations at each level."
     
   #eval {label $f.lIteration_max -text "Iteration max:"} $Gui(WLA) 
   eval {entry $f.eIteration_max -justify right -width 6 -textvariable AG(Iteration_max)} $Gui(WEA)
   pack $f.eIteration_max -pady 0 -padx $Gui(pad) -side left   
   TooltipAdd $f.eIteration_max  "Enter the number of maximum iterations at each level."
    
   set f $fExpert.fLevel
   frame $f -bg $Gui(activeWorkspace)
   pack $f -side top -padx $Gui(pad) -pady 0 -fill x -anchor w
   
   eval {label $f.lLevel_min  -text "Level min-max:        "} $Gui(WLA) 
   eval {entry $f.eLevel_min -justify right -width 6 -textvariable AG(Level_min)} $Gui(WEA)
   pack $f.lLevel_min $f.eLevel_min -pady 2 -padx $Gui(pad) -side left   
   TooltipAdd $f.eLevel_min  "Enter the minimum level in pyramid. Level 0 is full resolution, \
   level 1 is half resolution, etc."

   #eval {label $f.lLevel_max -text "Max Level:"} $Gui(WLA) 
   eval {entry $f.eLevel_max -justify right -width 6 -textvariable AG(Level_max)} $Gui(WEA)
   pack $f.eLevel_max -pady 2 -padx $Gui(pad) -side left 
   TooltipAdd $f.eLevel_max  "Enter the maximum level in pyramid. Level 0 is full resolution, \
   level 1 is half resolution, etc. For volumes 256*256*z, level 3 is highest to choose (32*32*z)."

   set f $fExpert.fStddev
   frame $f -bg $Gui(activeWorkspace)
   pack $f -side top -padx $Gui(pad) -pady 0 -fill x -anchor w
  
   eval {label $f.lStddev_min -text "Stddev. min-max:    "} $Gui(WLA) 
   eval {entry $f.eStddev_min -justify right -width 6 -textvariable AG(Stddev_min)} $Gui(WEA)
   pack $f.lStddev_min $f.eStddev_min -pady 2 -padx $Gui(pad) -side left 
   TooltipAdd $f.eStddev_min  "Enter the minimum standard deviation of displacement field smoothing kernel ."
 

   #eval {label $f.lStddev_max -text "Max Stddev:"} $Gui(WLA) 
   eval {entry $f.eStddev_max -justify right -width 6 -textvariable AG(Stddev_max)} $Gui(WEA)
   pack $f.eStddev_max -pady 2 -padx $Gui(pad) -side left   
   TooltipAdd $f.eStddev_max  "Enter the maximum standard deviation of displacement field smoothing kernel."


}


#-------------------------------------------------------------------------------
# .PROC Test
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Test {}  {
  
  puts "AG(SSD) is $AG(SSD)"
}

#-------------------------------------------------------------------------------
# .PROC ModifyOptions
# 
#  Modify the options for registration according to the user 
#  selection
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModifyOptions {optClass value} {
    global  AG Volume Gui 
  
    switch $optClass {
      LinearRegistration  { 
         set AG(LRName)  $value
         $AG(mbLR) config -text $AG(LRName)

         switch $value {
                "translation" { 
                    set AG(Linear_group) -1
                    puts "translation" 
                }
                "rigid group" {
                    set AG(Linear_group) 0
                    puts "rigid group"

                }
"similarity group" {
    set AG(Linear_group) 1
    puts "similarity group"
}
"affine group" {
    set AG(Linear_group) 2
    puts "affine group"
                    puts "AG(SSD) is $AG(SSD)"
    puts "AG(Scale) is $AG(Scale)"
}
default {
    set AG(Linear) 1
    set AG(Linear_group) 2
}
    }  
}
Warp {

    set AG(WarpName)  $value
    $AG(mbWarp) config -text $AG(WarpName)
      switch $value {
"demons" {
    set AG(Force) 1
}
"optical flow" {
    set AG(Force) 2
}
default {
    set AG(Warp)  1
    set AG(Force) 1  
}
    }
}

IntensityTFM {

    set AG(IntensityTFMName)  $value
    $AG(mbIntensityTFM) config -text $AG(IntensityTFMName)
    switch $value {
      "no intensity transform" {
          set  AG(Intensity_tfm) "none"
      }
      "mono functional" {
          set AG(Intensity_tfm)  "mono-functional"
      
      }
      "piecewise median" {
          set AG(Intensity_tfm)  "piecewise-median"
      
      }
      default {
          set AG(Intensity_tfm)  "mono-functional"
        
      }
    }
}

    Criterion {
       set AG(CriterionName)  $value
      $AG(mbCriterion) config -text $AG(CriterionName)
      switch $value {
        "GCR L1 norm" {
             set  AG(Gcr_criterion) 1
        }
        "GCR L2 norm" {
             set AG(Gcr_criterion)  2
        }
        "Correlation" {
             set AG(Gcr_criterion)  3
        }
        "mutual information" {
             set AG(Gcr_criterion)  4
        }
default {
    set AG(Gcr_criterion)  1
  
}
    }
}

Verbose {
    set AG(VerboseName)  $value
    $AG(mbVerbose) config -text $AG(VerboseName)
    set  AG(Verbose)  $value
}
    }
    return
}
#end  ModifyOptions



#-------------------------------------------------------------------------------
# .PROC AGEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGEnter {} {
    global AG
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $AG(eventManager)

    # clear the text box and put instructions there
#    $AG(textBox) delete 1.0 end
#    $AG(textBox) insert end "Shift-Click anywhere!\n"

    Render3D

    #Update LMI logo
    set modulepath $::PACKAGE_DIR_VTKAG/../../../images
    if {[file exist [ExpandPath [file join \
                     $modulepath "cnilogo.ppm"]]]} {
        image create photo iWelcome \
        -file [ExpandPath [file join $modulepath "cnilogo.ppm"]]
    }

}

#-------------------------------------------------------------------------------
# .PROC AGExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGExit {} {

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
# .PROC AGPrepareResult
#   Create the New Volume if necessary. Otherwise, ask to overwrite.
#   returns 1 if there is are errors 0 otherwise
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGCheckErrors {} {
    global AG Volume

    if {  ($AG(InputVolSource) == $Volume(idNone)) || \
        ($AG(InputVolTarget) == $Volume(idNone)) || \
        ($AG(ResultVol)   == $Volume(idNone))}  {
    DevErrorWindow "You cannot use Volume \"None\" for input or output"
    return 1
    }

    if {  ($AG(InputVolSource) == $AG(ResultVol)) || \
        ($AG(InputVolTarget) == $AG(ResultVol)) || \
        ($AG(InputVolMask)   == $AG(ResultVol))}  {
        DevErrorWindow "You cannot use one of the input Volumes as the result Volume"
        return 1

    }

    if { ($AG(InputVolSource2) != $Volume(idNone)) && ($AG(InputVolTarget2) != $Volume(idNone)) }  {    
    if { ($AG(ResultVol2)   == $Volume(idNone))} {    
        DevErrorWindow "You cannot use Volume \"None\" for input or output"
        return 1
    }

    if {  ($AG(InputVolSource2) == $AG(ResultVol)) || ($AG(InputVolSource2) == $AG(ResultVol2)) || \
         ($AG(InputVolTarget2) == $AG(ResultVol)) || ($AG(InputVolTarget2) == $AG(ResultVol2)) ||\
         ($AG(InputVolSource) == $AG(ResultVol2)) || ($AG(InputVolTarget) == $AG(ResultVol2)) || \
         ($AG(InputVolMask)   == $AG(ResultVol2))}  {
         DevErrorWindow "You cannot use one of the input Volumes as the result Volume"
         return 1
     }
     }

     return 0
}


#-------------------------------------------------------------------------------
# .PROC AGPrepareResultVolume
#   Check for Errors in the setup
#   returns 1 if there are errors, 0 otherwise
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGPrepareResultVolume { }  {
     global AG Volume
   
    #Make or Copy the result volume node from target volume ( but should keep
    # the win, level setting).
    set v1 $AG(InputVolTarget)
    set v2 $AG(ResultVol)
    set v2_2 $AG(ResultVol2)
    # Do we need to Create a New Volume?
    # If so, let's do it.
    
    if {$v2 == -5 } {
        set v2 [DevCreateNewCopiedVolume $v1 ""  "AGResult_$AG(CountNewResults)" ]
        set node [Volume($v2,vol) GetMrmlNode]
        Mrml(dataTree) RemoveItem $node 
        set nodeBefore [Volume($v1,vol) GetMrmlNode]
        Mrml(dataTree) InsertAfterItem $nodeBefore $node
        set AG(ResultVol) $v2
        #VolumesUpdateMRML
        MainUpdateMRML
        #AGUpdateGUI
        incr AG(CountNewResults)

    } else { 
    
        # Are We Overwriting a volume?
        # If so, let's ask. If no, return.
    
        set v2name  [Volume($v2,node) GetName]
    if { $AG(AskFlag) } {
        set continue [DevOKCancel "Overwrite $v2name?"]    
        if {$continue == "cancel"} { return 1 }
        # They say it is OK, so overwrite!
    }
              
        Volume($v2,node) Copy Volume($v1,node)
    }


    if { ($AG(InputVolSource2) != $Volume(idNone)) && ($AG(InputVolTarget2) != $Volume(idNone)) } {

        if {($v2_2 == -5)} {
            
            set v1_2 $AG(InputVolTarget2)      
            set v2_2 [DevCreateNewCopiedVolume $v1_2 ""  "AGResult2_$AG(CountNewResults)" ]
            set node [Volume($v2_2,vol) GetMrmlNode]
            Mrml(dataTree) RemoveItem $node 
            set nodeBefore [Volume($v1_2,vol) GetMrmlNode]
            Mrml(dataTree) InsertAfterItem $nodeBefore $node
            set AG(ResultVol2) $v2_2
            #VolumesUpdateMRML
            MainUpdateMRML

            
        } else {
            
            set v2name_2  [Volume($v2_2,node) GetName]
            set continue [DevOKCancel "Overwrite $v2name_2?"]
            
            if {$continue == "cancel"} { return 1 }
            # They say it is OK, so overwrite
            Volume($v2_2,node) Copy Volume($AG(InputVolTarget2),node)
        }
    } 
    
    return 0
}

#-------------------------------------------------------------------------------
# .PROC AGWritevtkImageData
# Write vtkImageData to file using the vtkStructuredPointWriter
#
# .ARGS
# string image input to the writer
# string filename file to write out
# .END
#-----------------------------------------------------------------------------
proc AGWritevtkImageData {image filename} {

    global AG
    catch "writer Delete"
    vtkStructuredPointsWriter  writer
    if {$AG(Debug) == 1} {
    writer DebugOn
    }
    writer SetFileTypeToBinary
    writer SetInput  $image
    writer SetFileName $filename
    writer Write
    writer Delete
}




#-------------------------------------------------------------------------------
# .PROC AGIntensityTransform
# According to the options, set the intensity transformation. 
#  
# .ARGS
# string Source
# .END
#------------------------------------------------------------------------------
proc AGIntensityTransform {Source} {
    global AG Volume

    catch {$AG(tfm) Delete}
    switch $AG(Intensity_tfm) {
      "mono-functional"  {
          puts "$AG(Intensity_tfm)==mono-functional is true"
          catch "tfm Delete"
      vtkLTSPolynomialIT tfm
          tfm SetDegree $AG(Degree)
          tfm SetRatio $AG(Ratio)  
          tfm SetNumberOfFunctions $AG(Nb_of_functions)
          if { $AG(Use_bias) == 1 } {
             tfm UseBiasOn
          }
          set AG(tfm) tfm
          return 0
      }
      "piecewise-median" {
          puts " intensity+tfm is piecewise-median"
          catch "tfm Delete"
      vtkPWMedianIT tfm
          if {([llength $AG(Nb_of_pieces)] == 0) && ($AG(Boundaries) == 0)} { 
            $Source  Update
            set low_high [$Source  GetScalarRange]
            set low [lindex $low_high 0]
            set high [lindex $low_high 1]
            for {set index 0} {$index < $AG(Nb_of_functions)} {incr index} {
              lappend AG(Nb_of_pieces) [expr $high-$low+1]
            }
         
            for {set index2 $low+1} {$index2 < $hight+1} {incr index2} {
               lappend AG(Boundaries) $index2
            }
          }
   
          set nf $AG(Nb_of_functions)
          set np $AG(Nb_of_pieces)
          set bounds $AG(Boundaries)
          if {( [llength $np] == 0) || ( [llength $np] != $nf)} {
             #raise Exception
             puts "length of number of pieces doesn\'t match number of functions"
             return 1
          }
       
          tfm SetNumberOfFunctions $nf
          for {set  f  0}  {$f < $nf} {incr f} {
            tfm SetNumberOfPieces {$f [lindex $np $f]}
            set i 0
            for {set p 0} {$p <  [lindex $np $f]-1} {incr p} {
              tfm SetBoundary {$f $p [lindex $bounds $i]}
              incr i
            }
          }  
          set AG(tfm) tfm
          return 0
      }

      "none" {
         #set tfm None
         return 1

      }

      default  {
           puts "unknown intensity tfm type: $AG(Intensity_tfm)"
           #raise exception
           #set tfm None
           return 1

      }
  }    
  
}

#-------------------------------------------------------------------------------
# .PROC AGTransformScale
# According to the options, do the scale transformation. 
#  
# .ARGS
# string Source
# string Target
# .END
#------------------------------------------------------------------------------
proc AGTransformScale { Source Target} {
#def TransformScale(Target,Source,scale):   
   #    log=vtkImageMathematics()
   #    log.SetOperationToLog()
   #    log.SetInput1(cast.GetOutput())
   global AG Volume 

   if { $AG(Scale) <= 0} {
    return 0
   }
   catch "div Delete"
   vtkImageMathematics div
   div SetOperationToMultiplyByK
   div SetConstantK  $AG(Scale)
   div SetInput1 $Target
# [Volume($AG(InputVolTarget),vol) GetOutput]
   div Update
  # [Volume($AG(InputVolTarget),vol) GetOutput] DeepCopy [div GetOutput]
  $Target  DeepCopy [div GetOutput]  
  $Target  SetUpdateExtentToWholeExtent
 # or Volume($AG(InputVolTarget),vol) SetImageData [div GetOutput] , but maybe they share the same copy of data.

   div Delete
   catch "div2 Delete"
   vtkImageMathematics div2
   div2 SetOperationToMultiplyByK
   div2 SetConstantK $AG(Scale)
  # div2 SetInput1  [Volume($AG(InputVolSource),vol) GetOutput]
   
   div2 SetInput1  $Source
   div2 Update
   #[Volume($AG(InputVolSource),vol) GetOutput] DeepCopy [div2 GetOutput]
   $Source  DeepCopy [div2 GetOutput]
   $Source   SetUpdateExtentToWholeExtent

   div2 Delete
   return 1
}
#-------------------------------------------------------------------------------
# .PROC AGWriteHomogeneousOriginal
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC AGWriteHomogeneousOriginal
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGWriteHomogeneousOriginal {t ii fileid} {

   
    puts " Start to save homogeneous Transform"
    #puts $fileid "Homogeneous Transform\n"

    set str ""
    set m [DataAddTransform 1 0 0]
    #set matout [[Matrix($m,node)  GetTransform] GetMatrix]
    set trans [Matrix($m,node) GetTransform] 
    $trans Identity
    set mat [$t GetMatrix]
    catch "mat_copy Delete"
    vtkMatrix4x4 mat_copy
    mat_copy DeepCopy $mat
    $trans Concatenate mat_copy
   
    for {set  i  0}  {$i < 4} {incr i} {
    for {set  j  0}  {$j < 4} {incr j} {
        set one_element [$mat GetElement $i $j]
    #    $matout SetElement $i $j $one_element
        set str "$str $one_element"
            puts $fileid  "  $one_element "
        puts "  $one_element " 
    }
    #puts $fileid "\n"
    }
    close $fileid
    puts " m is $m"
    puts " str is ---$str"
    
   
# SetMatrix $str
    puts " finish saving homogeneous Transform"

} 


#-------------------------------------------------------------------------------
# .PROC AGReadHomogeneousOriginal
# 
# .ARGS   t: the general transform; fileid : file id of the file with homogenous transform matrix (one element per line)
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC AGReadHomogeneousOriginal
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGReadHomogeneousOriginal {t filename} {

   
    puts " Start to read homogeneous Transform"


    set fileid [open $filename r ]
    set str ""
    catch "mat Delete"
    vtkMatrix4x4 mat
    
    set i 0
    set j 0
    foreach line [split [read $fileid] \n] {
     if { $line != ""} {
     scan $line %f element
     
    mat SetElement $i $j $element
    incr j
    if {$j == 4} {
        incr i
        set j 0
    }
    if { $i ==4 } break
    }
    }
    if { $i ==4 } {
        catch "LinearT Delete"
    vtkTransform LinearT
    LinearT PostMultiply
    LinearT  SetMatrix mat
        $t Concatenate LinearT  
    } else {
        DevErrorWindow " The file is not complete "
        }
    
   
# SetMatrix $str
    puts " finish reading homogeneous Transform"

} 

#-------------------------------------------------------------------------------
# .PROC AGWriteHomogeneous
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGWriteHomogeneous {t fileid} {
    global AG
    
    puts " Start to save homogeneous Transform $fileid"
    # puts $fileid "Homogeneous Transform\n"

    set str ""
    set m [DataAddTransform 1 0 0]
    #set matout [[Matrix($m,node)  GetTransform] GetMatrix]
    set trans [Matrix($m,node) GetTransform] 
    $trans Identity
    set mat [$t GetMatrix]
    catch "mat_copy Delete"
    vtkMatrix4x4 mat_copy
    mat_copy DeepCopy $mat

    # mat_copy is vtk_to_vtk transform, we want world_to_world
    catch "ModelRasToVtk Delete"
    vtkMatrix4x4 ModelRasToVtk
    set position [Volume($AG(InputVolTarget),node) GetPositionMatrix]
    ModelRasToVtk Identity
    set ii 0
    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            # Put the element from the position string
            ModelRasToVtk SetElement $i $j [lindex $position $ii]
            incr ii
        }
    # Remove the translation elements
    ModelRasToVtk SetElement $i 3 0
    }
    # add a 1 at the for  M(4,4)
    ModelRasToVtk SetElement 3 3 1
    catch "RasToVtk Delete"
    vtkMatrix4x4 RasToVtk
    RasToVtk DeepCopy ModelRasToVtk    
    # Inverse Matrix RasToVtk
    catch "InvRasToVtk Delete"
    vtkMatrix4x4 InvRasToVtk
    InvRasToVtk DeepCopy ModelRasToVtk
    InvRasToVtk Invert
    # wldtfm is the world_to_world transform
    catch "wldtfm Delete"
    vtkMatrix4x4 wldtfm
    wldtfm Multiply4x4 mat_copy InvRasToVtk wldtfm
    wldtfm Multiply4x4 RasToVtk wldtfm wldtfm
    
    catch "linear Delete"
    vtkTransform linear
    linear SetMatrix wldtfm
    $trans Concatenate linear
    linear Delete
   
    for {set  i  0}  {$i < 4} {incr i} {
    for {set  j  0}  {$j < 4} {incr j} {
        set one_element [wldtfm GetElement $i $j]
    #    $matout SetElement $i $j $one_element
        set str "$str $one_element"
    if {$fileid!=-1} {puts $fileid  "  $one_element "}
    }
    if {$fileid!=-1} {puts $fileid "\n"}
    }
    close $fileid 
    # Add a transform to the slicer.
    puts " m is $m"
    puts " str is ---$str"
    puts " finish saving homogeneous Transform"
    MainUpdateMRML
    DevInfoWindow "Matrix $m generated."
} 

#-------------------------------------------------------------------------------
# .PROC AGReadGrid
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGReadGrid {t fname} {      

    catch "g Delete"
    vtkGridTransform g
    catch "gridImage Delete"
        vtkImageData gridImage

        if {![AGReadvtkImageData gridImage $fname]} {
            return
        }
    
        g SetDisplacementGrid gridImage
    g Inverse
    
    $t Concatenate g
        return 1
}

#-------------------------------------------------------------------------------
# .PROC AGWriteGrid
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGWriteGrid {t ii fileid} {      
    # Matthan: removed fileid as argument after t ii
    
    set g [$t GetDisplacementGrid]
    if { $g == 0}  return

    set fname [tk_getSaveFile -defaultextension ".vtk" -title "Save non-linear transform"]
    if { $fname == "" } {
    return 0
    }

    AGWritevtkImageData $g  $fname
    return 1

    # Matthan: commented lines below
    
    #puts  $fileid "Grid Transform\n" 
    #set inverse [$t GetInverseFlag]
    #puts $fileid   " $inverse \n"

    #set fname "transform.vtk"
   
    #puts $fileid "$fname \n"

    #AGWritevtkImageData $g  $fname
}

#-------------------------------------------------------------------------------
# .PROC WritePWConstant
#  Save the polynomial intensity transform to file
#
# .ARGS
# string it
# int fid
# .END
#-------------------------------------------------------------------------------
proc WritePWConstant {it fileid} {

    puts $fileid "Piecewise Constant IT\n"
    
    set nf [$it GetNumberOfFunctions]
    
    puts $fileid " nf \n"

    for {set f 0} {$f < $nf} {incr f} {
    set value [$it GetNumberOfPieces $f]
    puts $fileid " $value "
    }
    puts $fileid "\n"

    for {set f 0} {$f < $nf} {incr f} { 
    set np [$it GetNumberOfPieces $f]
    for {set p 0} {$p < [expr $np - 1]} {incr p} { 
        set value [$it GetBoundary $f $p]
        puts $fileid " $value " 
    }
    puts $fileid "\n"
    for {set p 0} {$p < $np} {incr p} { 
        set value [$it GetValue $f $p]
        puts $fileid " $value " 
    }
    puts $fileid "\n"
    }
    
}
#-------------------------------------------------------------------------------
# .PROC WritePolynomial
#  Save the polynomial intensity transform to file
#
# .ARGS
# string it
# int fileid
# .END
#-------------------------------------------------------------------------------
proc WritePolynomial {it fileid} {

    puts $fileid "Polynomial IT\n"

    set nf [$it GetNumberOfFunctions]
    set nd [$it GetDegree]

    puts $fileid " $nf $nd \n "
    for {set  f  0}  {$f < $nf} {incr f } {
    for {set  d  0}  {$d < [expr $nd + 1]} {incr d } {
        set value [$it GetAlpha $f $d]
        puts $fileid  " $value "
    }
    puts $fileid "\n"
    }
}


#-------------------------------------------------------------------------------
# .PROC WriteIntensityTransform
#  Save the transform to file
#
# .ARGS
# string it
# int fileid
# .END
#-------------------------------------------------------------------------------
proc WriteIntensityTransform {it fileid } {
      
    if {($it != 0)} {
    if {[$it IsA vtkPolynomialIT]} {
        WritePolynomial $it $fileid
    }
    if {[$it IsA vtkPWConstantIT]} {
        WritePWConstant $it    $fileid
    }
    }
}


#-------------------------------------------------------------------------------
# .PROC AGReadLinearNonLinearTransform
#  Read the transform from file
#
# .ARGS
# int gt  vtkGeneralTransform
# .END
#-------------------------------------------------------------------------------
proc AGReadLinearNonLinearTransform {} {

   global AG  
   if {[info exist AG(Transform)]} {          
          catch {$AG(Transform) Delete}
   }
   
   catch "gt Delete"
   vtkGeneralTransform gt
   
   gt  PostMultiply 
   
   set fname [tk_getOpenFile -defaultextension ".txt" -title "File for linear transform"]
   if { $fname != "" } {
       AGReadHomogeneousOriginal gt $fname
   }
   set fname2 [tk_getOpenFile -defaultextension ".vtk" -title "File for non-linear transform"]
   if { $fname2 != "" } {
      AGReadGrid gt $fname2        
   }
   set AG(Transform) gt
}


#-------------------------------------------------------------------------------
# .PROC AGWriteLinearNonLinearTransform
#  Save the transform to file
#
# .ARGS
# int gt
# int flag
# int it
# string FileName
# .END
#-------------------------------------------------------------------------------
proc AGWriteLinearNonLinearTransform { } {

    global AG  
    if {![info exist AG(Transform)]} {
        DevErrorWindow "No transformation available, grid-file not saved."
    return
    }
 
    set gt  $AG(Transform)
     
    if { ($gt != 0 ) } {
         set n [$gt GetNumberOfConcatenatedTransforms]
     if {$AG(Debug) == 1} {
        puts " There are $n concatenated transforms"
         }
     
     set linearDone 0
     set nonliearDOne 0
         for {set  i  0}  {$i < $n} {incr i } {
         set t [$gt GetConcatenatedTransform $i]
         set int_H [$t IsA vtkHomogeneousTransform]
         set int_G [$t IsA vtkGridTransform]
         if { ($int_H != 0)&& ($linearDone == 0) } {
      set fname [tk_getSaveFile -defaultextension ".txt" -title "File to save linear transform"]
      set fileid [ open $fname w ]
      puts "fileid is $fileid"
          AGWriteHomogeneousOriginal $t $i  $fileid
      set linearDone 1
      
         } 
         if { ($int_G != 0) && ($nonliearDOne == 0) } {
               
      AGWriteGrid $t $i -1
      
      set nonliearDOne 1
         }
     }
    }
}
#-------------------------------------------------------------------------------
# .PROC AGWriteTransform
#  Save the transform to file
#
# .ARGS
# int gt
# int flag
# int it
# string FileName
# .END
#-------------------------------------------------------------------------------
proc AGWriteTransform {gt flag it FileName} {

    global AG  
  
    set fileid [open $FileName  w+]

    seek $fileid 0 start

    puts $fileid "VTK Transform File\n"
     
    if { ($gt != 0 ) } {
         set n [$gt GetNumberOfConcatenatedTransforms]
     if {$AG(Debug) == 1} {
        puts " There are $n concatenated transforms"
         }
         for {set  i  0}  {$i < $n} {incr i } {
         set t [$gt GetConcatenatedTransform $i]
         set int_H [$t IsA vtkHomogeneousTransform]
         set int_G [$t IsA vtkGridTransform]
         if { ($int_H != 0) } {
         AGWriteHomogeneousOriginal $t $i  $fileid
         } 
         if { ($int_G != 0) } {
         AGWriteGrid $t $i $fileid
         }
     }
    }
    if {$flag == 1} {
    WriteIntensityTransform $it  $fileid
    }
    close $fileid
}

#-------------------------------------------------------------------------------
# .PROC AGThresholdedOutput
# Compares the max and min values of the Original and resampled Data and defines Output in such a way that it is like ResampledData 
# but in the same scalar range as OriginalData
#
# .ARGS
# vtkImageData OriginalData
# vtkImageData ResampledData
# vtkImageData Output
# .END
#-------------------------------------------------------------------------------  
proc AGThresholdedOutput { OriginalData ResampledData Output } {

    vtkImageAccumulate ia
    ia SetInput $OriginalData
    ia Update
    set InputMin [lindex [ia GetMin] 0]
    set InputMax [lindex [ia GetMax] 0]

    ia SetInput $ResampledData 
    ia Update
    set OutputMin [lindex [ia GetMin] 0]
    set OutputMax [lindex [ia GetMax] 0]

    ia Delete

    set CurrentOutput $ResampledData  

    if {$InputMin  > $OutputMin} {
    puts "AGThresholdedOutput: Change lower scalar value of data from $OutputMin to $InputMin"
    vtkImageThreshold lowerThr
               lowerThr SetInput $CurrentOutput 
               lowerThr ThresholdByLower $InputMin
           lowerThr SetInValue $InputMin
               lowerThr ReplaceOutOff 
    lowerThr Update
    set CurrentOutput [lowerThr GetOutput]
    }

    if {$InputMax  < $OutputMax} {
    puts "AGThresholdedOutput: Change upper scalar value of data from $OutputMax to $InputMax"
    vtkImageThreshold upperThr
               upperThr SetInput $CurrentOutput 
               upperThr ThresholdByUpper $InputMax
           upperThr SetInValue $InputMax
               upperThr ReplaceOutOff 
    upperThr Update
    set CurrentOutput [upperThr GetOutput]
    }


    $Output  DeepCopy  $CurrentOutput
    $CurrentOutput Update

    catch {lowerThr Delete}
    catch {upperThr Delete}
}

#-------------------------------------------------------------------------------
# .PROC RunAG
#   Run the Registration.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RunAG {} {

  global AG Volume Gui Matrix

  if {(!$AG(Initial_lin))&&(!$AG(Initial_grid))&&(!$AG(Initial_prev))} {
    set AG(Initial_tfm) 0
  } else {
    set AG(Initial_tfm) 1
  }

  set intesity_transform_object 0

  puts "RunAG 1: Check Error"

  if {[AGCheckErrors] == 1} {
      return
  }

  puts "RunAG 2: Prepare Result Volume"

  if {[AGPrepareResultVolume] == 1} {
      return
  }

  catch "Target Delete"
  catch "Source Delete"

  vtkImageData Target
  vtkImageData Source

#If source and target have two channels, combine them into one vtkImageData object 
  if { ($AG(InputVolSource2) == $Volume(idNone)) || ($AG(InputVolTarget2) == $Volume(idNone)) }  {
      Target DeepCopy  [ Volume($AG(InputVolTarget),vol) GetOutput]
      Source DeepCopy   [ Volume($AG(InputVolSource),vol) GetOutput]
  } else {
      catch "Target1 Delete"
      vtkImageData Target1 
      Target1 DeepCopy   [ Volume($AG(InputVolTarget),vol) GetOutput]
      catch "Source1 Delete"
      vtkImageData Source1
      Source1 DeepCopy   [ Volume($AG(InputVolSource),vol) GetOutput]
      catch "Target2 Delete"
      vtkImageData Target2 
      Target2 DeepCopy   [ Volume($AG(InputVolTarget2),vol) GetOutput]
      catch "Source2 Delete"
      vtkImageData Source2
      Source2 DeepCopy   [ Volume($AG(InputVolSource2),vol) GetOutput]

      set dims_arr1 [Source1  GetDimensions]     
      set dims_arr2 [Source2  GetDimensions]

      set dim1_0 [lindex $dims_arr1 0] 
      set dim1_1 [lindex $dims_arr1 1] 
      set dim1_2 [lindex $dims_arr1 2] 
    
      set dim2_0 [lindex $dims_arr2 0] 
      set dim2_1 [lindex $dims_arr2 1] 
      set dim2_2 [lindex $dims_arr2 2] 
 
 
      if {($dim1_0 != $dim2_0) || ($dim1_1 != $dim2_1) || ($dim1_2 != $dim2_2) } {
      DevErrorWindow "Two Source channels have different dimensions"
      Source1 Delete
      Source2 Delete
      Target1 Delete
      Target2 Delete
      Source Delete
      Target Delete
      
      return
      } 

    

      set dims_arr1 [Target1  GetDimensions]     
      set dims_arr2 [Target2  GetDimensions]

      set dim1_0 [lindex $dims_arr1 0] 
      set dim1_1 [lindex $dims_arr1 1] 
      set dim1_2 [lindex $dims_arr1 2] 
    
      set dim2_0 [lindex $dims_arr2 0] 
      set dim2_1 [lindex $dims_arr2 1] 
      set dim2_2 [lindex $dims_arr2 2] 
 
 
      if {($dim1_0 != $dim2_0) || ($dim1_1 != $dim2_1) || ($dim1_2 != $dim2_2) } {
      DevErrorWindow "Two Target channels have different dimensions"
      Source1 Delete
      Source2 Delete
      Target1 Delete
      Target2 Delete
      Source Delete
      Target Delete
      
      return
      } 
    
      catch "combineS  Delete"
      vtkImageAppendComponents combineS     
      combineS SetInput 0 Source1       
      combineS SetInput 1 Source2
      combineS Update
      Source DeepCopy [combineS GetOutput]
      Source Update 
      combineS  Delete 
      # ReleaseDataFlagOff
 
      catch "combineT  Delete"
      vtkImageAppendComponents combineT
      combineT SetInput  0 Target1 
      combineT SetInput  1 Target2
      combineT Update
      Target  DeepCopy [combineT GetOutput]
      Target Update
      combineT Delete 
      #ReleaseDataFlagOff
      Source1 Delete
      Source2 Delete
      Target1 Delete
      Target2 Delete
     #set $AG(Nb_of_functions) 2 ??
  }
 

 #set sourceType  [Source  GetDataObjectType]
  #puts "Source object type is $sourceType"
  #set sourcePointNum  [Source  GetNumberOfPoints]
  #puts "Source object has   $sourcePointNum points"
  #set sourceCellNum  [Source  GetNumberOfCells]
  #puts "Source object has   $sourceCellNum cells"

  set extent_arr [Source  GetExtent]
  #parray extent_arr
  #puts " Source, extent:$extent_arr"
  
  set spacing [Source GetSpacing]
  #puts " Source, spacing is  $spacing"
  
  #set origin [Source GetOrigin]
  #puts " Source, spacing is  $origin"
  #set scalarSize [Source GetScalarSize]
  #puts " Source, scalar size is  $scalarSize"
  #set scalarType [Source GetScalarType]
  #puts " Source, scalar type is  $scalarType"

 
  if { ([lindex $extent_arr 1] < 0) || ([lindex $extent_arr 3] < 0) || ([lindex $extent_arr 5] < 0)   } {
      DevErrorWindow "Source is not correct or empty"

      Source Delete
      Target Delete
      
      return 
  }


 
  #set targetType  [Target  GetDataObjectType]
  #puts "Targert object type is $targetType"
  #set targetPointNum  [Target  GetNumberOfPoints]
  #puts "Targert object has   $targetPointNum points"
  #set targetCellNum  [Target  GetNumberOfCells]
  #puts "Targert object has   $targetCellNum cells"

  set extent_arr [Target  GetExtent]
  #parray extent_arr
  #puts " Target, extent:$extent_arr"

  if { ([lindex $extent_arr 1] < 0) || ([lindex $extent_arr 3] < 0) || ([lindex $extent_arr 5] < 0)   } {
      DevErrorWindow "Target is not correct or empty"

      Target Delete
      Source Delete

      return 
  }


  # Initial transform stuff
  if {[info exist AG(Transform)]} {
      if {!($AG(Initial_prev))} {
          catch "TransformAG Delete"
          catch {$AG(Transform) Delete}
          vtkGeneralTransform TransformAG
      }
  } else {
      if {$AG(Initial_prev)} {
        DevErrorWindow "Previous computed transform as initial transform requested, but not available."
    return
      }
      catch "TransformAG Delete"
      vtkGeneralTransform TransformAG
  }
  

  if {$AG(Initial_tfm)} {      
      puts "Initial Transform"
      # A previous transf might exist, so set PreMultiply and add Grid and Linear,
      # then set PostMultiply, so we have Linear->Grid->Previous_lin->Previous_grid
      TransformAG PreMultiply
      if {$AG(Initial_grid)} {
          catch "wrp Delete"
          vtkImageData wrp
          catch "grd Delete"
          vtkGridTransform grd

          if {![AGReadvtkImageData wrp $AG(regInitGridTfmName)]} {
        return
      }
      if {[wrp GetNumberOfScalarComponents]!=3} {
        DevErrorWindow "Initial grid-transform file has [wrp GetNumberOfScalarComponents] components, must be 3."
        return
      }

          set dims  [wrp GetDimensions]
          set spacing [wrp GetSpacing]

          # set the origin to be the center of the volume for inputing to warp.  
          set spacing_x [lindex $spacing 0]
          set spacing_y [lindex $spacing 1]
          set spacing_z [lindex $spacing 2]
          set dim_0     [lindex $dims 0]        
          set dim_1     [lindex $dims 1]      
          set dim_2     [lindex $dims 2]

          set origin_0  [expr (1-$dim_0)*$spacing_x/2.0]
          set origin_1  [expr (1-$dim_1)*$spacing_y/2.0] 
          set origin_2  [expr (1-$dim_2)*$spacing_z/2.0] 

          # Must set origin for Target before using the reslice for orientation normalization.        
          wrp  SetOrigin  $origin_0 $origin_1 $origin_2
          grd SetDisplacementGrid wrp
          TransformAG Concatenate grd
          grd Delete
          wrp Delete
      }
      
      if {$AG(Initial_lin)} {
          catch "ModelRasToVtk Delete"
          vtkMatrix4x4 ModelRasToVtk
          set position [Volume($AG(InputVolTarget),node) GetPositionMatrix]
          ModelRasToVtk Identity
          set ii 0
          for {set i 0} {$i < 4} {incr i} {
              for {set j 0} {$j < 4} {incr j} {
                  # Put the element from the position string
                  ModelRasToVtk SetElement $i $j [lindex $position $ii]
                  incr ii
              }
          # Remove the translation elements
          ModelRasToVtk SetElement $i 3 0
          }
          # add a 1 at the for  M(4,4)
          ModelRasToVtk SetElement 3 3 1
          # Now we can build the Vtk1ToVtk2 matrix based on
          # ModelRasToVtk and ras1toras2
          # vtk1tovtk2 = inverse(rastovtk) ras1toras2 rastovtk
          # RasToVtk
          catch "RasToVtk Delete"
          vtkMatrix4x4 RasToVtk
          RasToVtk DeepCopy ModelRasToVtk    
          # Inverse Matrix RasToVtk
          catch "InvRasToVtk Delete"
          vtkMatrix4x4 InvRasToVtk
          InvRasToVtk DeepCopy ModelRasToVtk
          InvRasToVtk Invert
          # Ras1toRas2 given by the slicer MRML tree
          catch "Ras1ToRas2 Delete"    
          vtkMatrix4x4 Ras1ToRas2
          Ras1ToRas2 DeepCopy [[Matrix($Matrix(activeID),node) GetTransform] GetMatrix]
          # Now build Vtk1ToVtk2
          catch "Vtk1ToVtk2 Delete"    
          vtkMatrix4x4 Vtk1ToVtk2
          Vtk1ToVtk2 Identity
          Vtk1ToVtk2 Multiply4x4 Ras1ToRas2 RasToVtk  Vtk1ToVtk2
          Vtk1ToVtk2 Multiply4x4 InvRasToVtk  Vtk1ToVtk2 Vtk1ToVtk2
      catch "Linear Delete"
      vtkTransform Linear
      Linear SetMatrix Vtk1ToVtk2

      TransformAG Concatenate Linear
          ModelRasToVtk Delete
          Ras1ToRas2 Delete
          RasToVtk Delete
          InvRasToVtk Delete
          Vtk1ToVtk2 Delete
      Linear Delete
      }
      TransformAG PostMultiply

      set  AG(Inentisy_transform) 1
  } else {
      puts "No initial transform"
      TransformAG PostMultiply 
      set  AG(Inentisy_transform) 0
  }


  # if only linear transform, to not change resolution of source
  set AG(resamplesource) 0
  if {$AG(Initial_grid)} {
    set AG(resamplesource) 1
  }
  if {![info exist AG(Transform)]} {
    set n [TransformAG GetNumberOfConcatenatedTransforms]
    for {set i [expr $n-1]}  {$i >= 0} {set i [expr $i-1]} {
        set t [TransformAG GetConcatenatedTransform $i]
        set int_G [$t IsA vtkGridTransform]
        if { ($int_G != 0) && !$done} {
            set AG(resamplesource) 1
        }
    }
  }
  AGPreprocess Source Target $AG(InputVolSource)  $AG(InputVolTarget) 

  Source SetUpdateExtentToWholeExtent
  Target SetUpdateExtentToWholeExtent

  #AG(TestReadingWriting)
  if {$AG(TestReadingWriting) == 1} {
  #  if {$AG(Debug) == 1} {}

      AGWritevtkImageData Source "TestSource.vtk"
      AGWritevtkImageData Target "TestTarget.vtk"

      puts "finish writing vtkdata"

      Source Delete
      Target Delete 
  
      vtkImageData Source
      vtkImageData Target 
  
      AGReadvtkImageData  Source "TestSource.vtk"
      AGReadvtkImageData  Target "TestTarget.vtk"
      puts "finish reading vtkdata"

      if {$AG(Debug) == 1} {
      puts " Debug information \n\n" 
      set targetType  [Target  GetDataObjectType]
      puts "Targert object type is $targetType"
      set targetPointNum  [Target  GetNumberOfPoints]
      puts "Targert object has   $targetPointNum points"
      set targetCellNum  [Target  GetNumberOfCells]
      puts "Targert object has   $targetCellNum cells"

      set extent_arr [Target  GetExtent]
      #parray extent_arr
      puts " Target, extent:$extent_arr"


      set spacing [Target GetSpacing]
      puts " Target, spacing is  $spacing"
      
      set origin [Target GetOrigin]
      puts " Target, spacing is  $origin"
      
      set scalarSize [Target GetScalarSize]
      puts " Target, scalar size is  $scalarSize"
      set scalarType [Target GetScalarType]
      puts " Target, scalar type is  $scalarType"
      set ScalarComponents [Target GetNumberOfScalarComponents]
      puts " Target, $ScalarComponents scalar components."


      set sourceType  [Source  GetDataObjectType]
      puts "Source object type is $sourceType"
      set sourcePointNum  [Source  GetNumberOfPoints]
      puts "Source object has   $sourcePointNum points"
      set sourceCellNum  [Source  GetNumberOfCells]
      puts "Source object has   $sourceCellNum cells"

      set extent_arr [Source  GetExtent]
      #parray extent_arr
      puts " Source, extent:$extent_arr"
  
      set spacing [Source GetSpacing]
      puts " Source, spacing is  $spacing"
      
      set origin [Source GetOrigin]
      puts " Source, spacing is  $origin"
      set origin [Source GetOrigin]
      puts " Source, spacing is  $origin"
      set scalarSize [Source GetScalarSize]
      puts " Source, scalar size is  $scalarSize"
      set scalarType [Source GetScalarType]
      puts " Source, scalar type is  $scalarType"
      set ScalarComponents [Source GetNumberOfScalarComponents]
      puts " Source,  $ScalarComponents  scalar components."


      }
  }



  #Source DebugOn
  #Target DebugOn
  
  if {$AG(Scale) > 0 } {
       AGTransformScale Source Target 
  }


  #vtkIntensityTransform IntensityTransform 

#  catch "TransformAG Delete"
#  catch {$AG(Transform) Delete}
  
#  vtkGeneralTransform TransformAG

 
#  if {$AG(Initial_tfm)} {      
#      vtkGeneralTransformReader Reader
#      Reader SetFileName $AG(Initial_tfm)
#      Set TransformAG [Reader GetGeneralTransform]
#      TransformAG PostMultiply 
#   # How to use this intensity tranform, since it will be overwritten by the AGIntensity transform.
#      Set IntensityTransform [Reader GetIntensityTransform]
#      set  AG(Inentisy_transform) 1
#  } else {
#      TransformAG PostMultiply 
#      set  AG(Inentisy_transform) 0
#  }


  

  if {$AG(Linear)} {

      if { [info commands __dummy_transform] == ""} {
              vtkTransform __dummy_transform
      }

      catch "GCR Delete"
      vtkImageGCR GCR
      GCR SetVerbose $AG(Verbose)
     # GCR DebugOn
      GCR SetTarget Target
      GCR SetSource Source
      GCR PostMultiply      

      # It seems that the following line will result in error, the affine matrix used in the resampling and writing is only
      # identical matrix.
      GCR SetInput  __dummy_transform  
      [GCR GetGeneralTransform] SetInput TransformAG
      
      GCR SetCriterion $AG(Gcr_criterion)
      GCR SetTransformDomain $AG(Linear_group)
      GCR SetTwoD $AG(2D)
      GCR Update     
   

      #set AffineMatrix [[[GCR GetGeneralTransform] GetConcatenatedTransform 1] GetMatrix] 

      #catch "mat_copy Delete"    
      #vtkMatrix4x4 mat_copy
      #mat_copy DeepCopy $AffineMatrix
     
      #GCR Identity   
      #GCR Concatenate mat_copy
      #TransformAG Concatenate GCR
      TransformAG Concatenate [[GCR GetGeneralTransform] GetConcatenatedTransform 1]
   
  }

  if {$AG(Warp)} {
      catch "warp Delete"
      vtkImageWarp warp
      warp SetSource Source
      warp SetTarget Target 

      if { ($AG(InputVolMask)   != $Volume(idNone)) } {
          catch "Mask Delete"
    
          vtkImageData Mask

          Mask DeepCopy  [ Volume($AG(InputVolMask),vol) GetOutput]
          warp SetMask Mask
 
      }

# Set the options for the warp

      puts "RunAG 3"

      warp SetVerbose $AG(Verbose)
      [warp GetGeneralTransform] SetInput TransformAG
      warp SetResliceTensors $AG(Tensors)  
      warp SetForceType $AG(Force)   
      warp SetMinimumIterations  $AG(Iteration_min) 
      warp SetMaximumIterations $AG(Iteration_max)  
      warp SetMinimumLevel $AG(Level_min)  
      warp SetMaximumLevel $AG(Level_max)  
      warp SetUseSSD $AG(SSD)    
      warp SetSSDEpsilon  $AG(Epsilon)    
      warp SetMinimumStandardDeviation $AG(Stddev_min) 
      warp SetMaximumStandardDeviation $AG(Stddev_max) 
 

      puts "RunAG 4"
 
      if {[AGIntensityTransform Source] == 0 } {
          warp SetIntensityTransform $AG(tfm)
          set intesity_transform_object 1
          
      }  else  {
          set intesity_transform_object 0
      }

      # This is necessary so that the data is updated correctly.
      # If the programmers forgets to call it, it looks like nothing
      # happened.

      puts "RunAG 5"
      warp Update
      TransformAG Concatenate warp
  }


  catch "Resampled Delete"
  vtkImageData Resampled

  # Do not delete   AG(Transform), otherwise, it will be wrong. ( delete the just allocated "TransformAG")
  set AG(Transform) TransformAG 
 
    AGResample Source Target Resampled

  if { ($AG(InputVolSource2) == $Volume(idNone)) || ($AG(InputVolTarget2) == $Volume(idNone)) }  {     
      Volume($AG(ResultVol),vol) SetImageData  Resampled
      Resampled SetOrigin 0 0 0
      #Reslicer ReleaseDataFlagOff
# set ImageData only change the volume, but the discription of the volume is 
#not changed ( such as dimensions, extensions, spacings in the volume node, 
#so should copy the result node from the target node).
      MainVolumesUpdate $AG(ResultVol)
      #[Reslicer GetOutput] SetOrigin 0 0 0
  } else {
      catch "extractImage Delete"
      vtkImageExtractComponents extractImage
      extractImage SetInput Resampled
      #[Reslicer GetOutput]
      
      extractImage SetComponents 0  
      extractImage ReleaseDataFlagOff
      
      Volume($AG(ResultVol),vol) SetImageData [extractImage  GetOutput]
      
      catch "extractImage2 Delete"
      vtkImageExtractComponents extractImage2
      #extractImage2 SetInput [Reslicer GetOutput]
      extractImage2 SetInput Resampled
      
      extractImage2 SetComponents 1  
      extractImage2  ReleaseDataFlagOff
      Volume($AG(ResultVol2),vol) SetImageData [extractImage2  GetOutput]
      
      MainVolumesUpdate $AG(ResultVol)
      MainVolumesUpdate $AG(ResultVol2)
      
      [extractImage GetOutput] SetOrigin 0 0 0
      [extractImage2 GetOutput] SetOrigin 0 0 0
      
      extractImage UnRegisterAllOutputs
      extractImage2 UnRegisterAllOutputs
      
      extractImage Delete
      extractImage2 Delete
      Resampled Delete
  }
  
  if {$AG(Debug)} {
      if {$AG(Warp)} {
      
      set DataType [[warp GetDisplacementGrid] GetDataObjectType]
      puts " Transform displacementGrid, data type is $DataType"
      
      set dim_arr [[warp GetDisplacementGrid] GetDimensions]
      
      puts " Transform displacementGrid, dimensions:$dim_arr"
      
      #set {extent_1 extent_2 extent_3 extent_4 extent_5 extent_6} [[warp GetDisplacementGrid] GetExtent]

      set extent_arr [[warp GetDisplacementGrid] GetExtent]

      set origin_arr [[warp GetDisplacementGrid] GetOrigin]

      puts " Transform DisplacementGrid, origin : $origin_arr"
     
      #parray extent_arr
      puts " Transform displacementGrid, extent:$extent_arr"

    
      set ScalarSize [[warp GetDisplacementGrid] GetScalarSize]
      puts " Transform displacementGrid, ScalarSize is $ScalarSize"
      
      set ScalarType [[warp GetDisplacementGrid] GetScalarTypeAsString]
      puts " Transform displacementGrid, ScalarType is $ScalarType"
      
      set ScalarComponents [[warp GetDisplacementGrid] GetNumberOfScalarComponents]
      puts " Transform displacementGrid,  $ScalarComponents  scalar components."
      
      }
  }

  # Write  Transforms

  #if {$intesity_transform_object == 1} {
  #    AGWriteTransform TransformAG 1 $AG(tfm) "Test_transform.txt"
  #} else {
  #    AGWriteTransform TransformAG 0 0  "Test_transform.txt"
  #}

  # keep the transforms until the next round for registration.
  #if {$AG(Warp)} {
  #    warp Delete
  #}

  #if {$AG(Linear)} {
  #    GCR Delete
  #}
  
  #if {$intesity_transform_object == 1}  {
  #    $AG(tfm) Delete
  #}

  Target Delete
  Source Delete
  if { ($AG(InputVolMask)   != $Volume(idNone)) } {
      Mask Delete
  }

  puts "RunAG 6"
  MainSlicesSetVolumeAll Back $AG(ResultVol)

}

#-------------------------------------------------------------------------------
# .PROC AGBatchProcessResampling
# Transform all volumes(except the source and target) to  new volumes based on the target volume and the
# transform stored in AG(transform)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGBatchProcessResampling  {  }  {
    global AG Volume Gui
    if {[AGCheckErrors] == 1} {
    return
    }
 
    #upvar $ArrayName LocalArray
    upvar 0 Volume NodeType

    foreach v $NodeType(idList) {
    if { ($v != $NodeType(idNone)) && ($v !=  $AG(InputVolTarget)) && ($v != $AG(InputVolSource))} {
        
        set name [Volume($v,node) GetName]
        set subname [string range $name 0 7]

     
            if { ($subname != "resample") && ($name != "None") } {
        puts "Resample volume whose name is $name..."
        AGTransformOneVolume $v $AG(InputVolTarget)
        }
    }
    }

}

#-------------------------------------------------------------------------------
# .PROC AGCoregister
#Transform one volume to a new volume based on the target volume and the
# transform stored in AG(transform)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGCoregister {{ResultVolume -5}} {
   global AG Volume Gui
    if {$AG(CoregVol)==$Volume(idNone)} {
      DevErrorWindow "Please select a volume for coregistration."
      return
    }
    if {$AG(InputVolTarget)==$Volume(idNone)} {
      DevErrorWindow "Please select the target volume used in the registration."
      return
    }
    if {[info exist AG(Transform)]} {
      AGTransformOneVolume $AG(CoregVol) $AG(InputVolTarget) $ResultVolume
    } else {
      DevErrorWindow "Please run a registration first."
    }
    MainSlicesSetVolumeAll Back $AG(CoregVol)

}

#-------------------------------------------------------------------------------
# .PROC AGTransformOneVolume
#Transform one volume to a new volume based on the target volume and the
# transform stored in AG(transform)
# .ARGS
# string SouceVolume
# string TargetVolume
# string ResultVolume
# .END
#-------------------------------------------------------------------------------
proc AGTransformOneVolume {SourceVolume TargetVolume {ResultVolume -5} } {
 global AG Volume Gui
# Create a new volume based on the name of the source volume and the node descirption of the target volume

    set v1 $TargetVolume
    set v2name  [Volume($SourceVolume,node) GetName]
    if {$ResultVolume < 0 } {
    set v2 [DevCreateNewCopiedVolume $v1 ""  "resample_$v2name" ]
    set node [Volume($v2,vol) GetMrmlNode]
    Mrml(dataTree) RemoveItem $node 
    set nodeBefore [Volume($v1,vol) GetMrmlNode]
    Mrml(dataTree) InsertAfterItem $nodeBefore $node
    #VolumesUpdateMRML
    MainUpdateMRML
    } else {
    set v2 $ResultVolume
    set node [Volume($v2,vol) GetMrmlNode]
    }
    
    catch "Source Delete"
    vtkImageData Source  
    catch "Target Delete"
    vtkImageData Target
    Target DeepCopy  [ Volume($TargetVolume,vol) GetOutput]
    Source DeepCopy  [ Volume($SourceVolume,vol) GetOutput]


    catch "Resampled Delete"
    vtkImageData Resampled

    # if only linear transform, to not change resolution of source
    set AG(resamplesource) 0
    if {$AG(Initial_grid)} {
      set AG(resamplesource) 1
    }
    if {![info exist AG(Transform)]} {
      set n [TransformAG GetNumberOfConcatenatedTransforms]
      for {set i [expr $n-1]}  {$i >= 0} {set i [expr $i-1]} {
          set t [TransformAG GetConcatenatedTransform $i]
          set int_G [$t IsA vtkGridTransform]
          if { ($int_G != 0) && !$done} {
              set AG(resamplesource) 1
          }
      }
    }
    AGPreprocess Source Target $SourceVolume  $TargetVolume
      
    Source SetUpdateExtentToWholeExtent
    Target SetUpdateExtentToWholeExtent
 
    AGResample Source Target Resampled

    Volume($v2,vol) SetImageData  Resampled
    Resampled SetOrigin 0 0 0
    MainVolumesUpdate $v2

    Source Delete
    Target Delete

}

#-------------------------------------------------------------------------------
# .PROC AGPreprocess
#  Check the source and target, and set the target's origin to be at the
#  center. Set source to be at the same orientation and resolution as the target
# 
# .ARGS
# string Source
# string Target
# string SourceVol
# string TargetVol
# .END
#-------------------------------------------------------------------------------
proc AGPreprocess {Source Target SourceVol TargetVol} {
 global AG Volume Gui

  set spacing [$Target GetSpacing]
  #puts " Target, spacing is  $spacing"
  
  #set origin [Target GetOrigin]
  #puts " Target, spacing is  $origin"
  #set scalarSize [Target GetScalarSize]
  #puts " Target, scalar size is  $scalarSize"
  #set scalarType [Target GetScalarType]
  #puts " Target, scalar type is  $scalarType"

  set dims  [$Target GetDimensions]

# set the origin to be the center of the volume for inputing to warp.  

  set spacing_x [lindex $spacing 0]
  set spacing_y [lindex $spacing 1]
  set spacing_z [lindex $spacing 2]
  set dim_0     [lindex $dims 0]        
  set dim_1     [lindex $dims 1]      
  set dim_2     [lindex $dims 2]

  set origin_0  [expr (1-$dim_0)*$spacing_x/2.0]
  set origin_1  [expr (1-$dim_1)*$spacing_y/2.0] 
  set origin_2  [expr (1-$dim_2)*$spacing_z/2.0] 

  # Must set origin for Target before using the reslice for orientation normalization.        
  $Target  SetOrigin  $origin_0 $origin_1 $origin_2


  catch "NormalizedSource Delete"
  vtkImageData NormalizedSource

  set  SourceScanOrder [Volume($SourceVol,node) GetScanOrder]
  set  TargetScanOrder [Volume($TargetVol,node) GetScanOrder]
  AGNormalize $Source $Target NormalizedSource $SourceScanOrder $TargetScanOrder

  #Volume($AG(ResultVol),vol) SetImageData  NormalizedSource
  #return

  $Source DeepCopy NormalizedSource

  $Source SetUpdateExtentToWholeExtent

  NormalizedSource Delete

 

 


  #  Target SetOrigin  -119.53125 -119.53125 -87.0
  # Target SetSpacing  0.9375 0.9375 3

  #  Source SetOrigin  -119.53125 -119.53125 -87.0
  #  Source SetSpacing  0.9375 0.9375 3
  set dims  [$Source GetDimensions]

# set the origin to be the center of the volume for inputing to warp.  

  set spacing_x [lindex $spacing 0]
  set spacing_y [lindex $spacing 1]
  set spacing_z [lindex $spacing 2]
  set dim_0     [lindex $dims 0]        
  set dim_1     [lindex $dims 1]      
  set dim_2     [lindex $dims 2]

  set origin_0  [expr (1-$dim_0)*$spacing_x/2.0]
  set origin_1  [expr (1-$dim_1)*$spacing_y/2.0] 
  set origin_2  [expr (1-$dim_2)*$spacing_z/2.0] 
       
  $Source  SetOrigin  $origin_0 $origin_1 $origin_2

  if {$AG(Debug) == 1} {
      puts " Debug information \n\n" 
      set targetType  [$Target  GetDataObjectType]
      puts "Targert object type is $targetType"
      set targetPointNum  [$Target  GetNumberOfPoints]
      puts "Targert object has   $targetPointNum points"
      set targetCellNum  [$Target  GetNumberOfCells]
      puts "Targert object has   $targetCellNum cells"

      set extent_arr [$Target  GetExtent]
      #parray extent_arr
      puts " Target, extent:$extent_arr"


      set spacing [$Target GetSpacing]
      puts " Target, spacing is  $spacing"
      
      set origin [$Target GetOrigin]
      puts " Target, spacing is  $origin"
      
      set scalarSize [$Target GetScalarSize]
      puts " Target, scalar size is  $scalarSize"
      set scalarType [$Target GetScalarType]
      puts " Target, scalar type is  $scalarType"
      

      set sourceType  [$Source  GetDataObjectType]
      puts "Source object type is $sourceType"
      set sourcePointNum  [$Source  GetNumberOfPoints]
      puts "Source object has   $sourcePointNum points"
      set sourceCellNum  [$Source  GetNumberOfCells]
      puts "Source object has   $sourceCellNum cells"

      set extent_arr [$Source  GetExtent]
      #parray extent_arr
      puts " Source, extent:$extent_arr"
  
      set spacing [$Source GetSpacing]
      puts " Source, spacing is  $spacing"
      
      set origin [$Source GetOrigin]
      puts " Source, spacing is  $origin"
      set origin [$Source GetOrigin]
      puts " Source, spacing is  $origin"
      set scalarSize [$Source GetScalarSize]
      puts " Source, scalar size is  $scalarSize"
      set scalarType [$Source GetScalarType]
      puts " Source, scalar type is  $scalarType"
  }
}



#-------------------------------------------------------------------------------
# .PROC AGThresholdedResampledData
# Compares the max and min values of the Original and resampled Data and defines Output in such a way that it is like ResampledData 
# but in the same scalar range as OriginalData
#
# .ARGS
# vtkImageData Source
# vtkImageData Target
# vtkImageData Output
# .END
#-------------------------------------------------------------------------------
    
proc AGThresholdedOutput { OriginalData ResampledData Output } {

    vtkImageAccumulate ia
    ia SetInput $OriginalData
    ia Update
    set InputMin [lindex [ia GetMin] 0]
    set InputMax [lindex [ia GetMax] 0]

    ia SetInput $ResampledData 
    ia Update
    set OutputMin [lindex [ia GetMin] 0]
    set OutputMax [lindex [ia GetMax] 0]

    ia Delete

    set CurrentOutput $ResampledData  

    if {$InputMin  > $OutputMin} {
    puts "AGThresholdedOutput: Change lower scalar value of data from $OutputMin to $InputMin"
    vtkImageThreshold lowerThr
               lowerThr SetInput $CurrentOutput 
               lowerThr ThresholdByLower $InputMin
           lowerThr SetInValue $InputMin
               lowerThr ReplaceOutOff 
    lowerThr Update
    set CurrentOutput [lowerThr GetOutput]
    }

    if {$InputMax  < $OutputMax} {
    puts "AGThresholdedOutput: Change upper scalar value of data from $OutputMax to $InputMax"
    vtkImageThreshold upperThr
               upperThr SetInput $CurrentOutput 
               upperThr ThresholdByUpper $InputMax
           upperThr SetInValue $InputMax
               upperThr ReplaceOutOff 
    upperThr Update
    set CurrentOutput [upperThr GetOutput]
    }


    $Output  DeepCopy  $CurrentOutput
    $CurrentOutput Update

    catch {lowerThr Delete}
    catch {upperThr Delete}
}


#-------------------------------------------------------------------------------
# .PROC AGResample
# .Resample a new source according to the target and the transform saved i
# AG(Transform).
#
# .ARGS
# string Source
# string Target
# .END
#-------------------------------------------------------------------------------
proc AGResample {Source Target Resampled} {

  global AG Volume Gui
#Test to transform the source using the computed transform.

  set None 0
 
  set ResampleOptions(interp) $AG(Interpolation)
  set ResampleOptions(intens) 0
  set ResampleOptions(like) 1
  #set ResampleOptions $None
  set ResampleOptions(inverse) 0
  set ResampleOptions(tensors) 0
  set ResampleOptions(xspacing) $None
  set ResampleOptions(yspacing) $None
  set ResampleOptions(zspacing) $None
  set ResampleOptions(verbose) 0

  catch "Cast Delete"
  vtkImageCast Cast
  Cast SetInput $Source
  Cast SetOutputScalarType [$Source GetScalarType]
  if {$ResampleOptions(like) != $None} {
      #     Cast SetOutputScalarType [LReader.GetOutput().GetScalarType()]
      Cast SetOutputScalarType [$Target GetScalarType]
  }     else {
      Cast SetOutputScalarType [$Source GetScalarType]
  }
 
  catch "Reslicer Delete"
  if {$ResampleOptions(tensors) == 0} {     
      vtkImageReslice Reslicer
  } else {
      vtkImageResliceST Reslicer
  }

  if {($ResampleOptions(intens) == 1) && $AG(Warp)} {
      catch "ITrans Delete"
      vtkImageTransformIntensity ITrans
      ITrans SetInput [Cast GetOutput]
      ITrans SetIntensityTransform $AG(tfm)

      Reslicer SetInput [ITrans GetOutput]
  } else {
      Reslicer SetInput [Cast GetOutput]      
  }
  # Kilian - April 06: This is not consistent with AGNormalize and GUI   
  # Reslicer SetInterpolationMode $ResampleOptions(interp)
  # if ResampleOptions(interp) == 0 => Nearest Neighbor
  # if ResampleOptions(interp) == 1 => Linear 
  # Now changed it so that ResampleOptions(interp) == 1 => Cubic 
  if {$ResampleOptions(interp) } {
      Reslicer SetInterpolationModeToCubic
  }

# Should it be this way, or inverse in the other way?     
  if {$ResampleOptions(inverse) == 1} {
      Reslicer SetResliceTransform $AG(Transform) 
  } else {
      Reslicer SetResliceTransform [$AG(Transform)  GetInverse]
  }

  #Reslicer SetInformationInput Target
  if  {$ResampleOptions(like) !=  $None} {
      Reslicer SetInformationInput $Target
  }
  if {$ResampleOptions(xspacing) != $None} {
       Reslicer SetOutputSpacing {$ResampleOptions(xspacing),$ResampleOptions(yspacing),$ResampleOptions(zspacing)}
  }

  Reslicer Update

  if {$AG(Debug) == 1} {

      set scalar_range [[Reslicer GetOutput] GetScalarRange]
      puts "Resclier's scalar range is : $scalar_range"
      

      set DataType [[Reslicer GetOutput] GetDataObjectType]
      puts " Reliscer output, data type is $DataType"

      set dim_arr [[Reslicer GetOutput] GetDimensions]

      puts " Reliscer output, dimensions:$dim_arr"
      
   
      set origin_arr [[Reslicer GetOutput] GetOrigin]

      puts " Reliscer output, origin : $origin_arr"
      
      #set {extent_1 extent_2 extent_3 extent_4 extent_5 extent_6} [[Reslicer GetOutput] GetExtent]

      set extent_arr [[Reslicer GetOutput] GetExtent]



      #parray extent_arr
      puts " Reliscer output, extent:$extent_arr"


      set spacing_arr [[Reslicer GetOutput] GetSpacing]



      #parray extent_arr
      puts " Reliscer output, spacings:$spacing_arr"
      
    
      
    
      set ScalarSize [[Reslicer GetOutput] GetScalarSize]
      puts " Reliscer output, ScalarSize is $ScalarSize"
      
      set ScalarType [[Reslicer GetOutput] GetScalarTypeAsString]
      puts " Reliscer output, ScalarType is $ScalarType"
      
      set ScalarComponents [[Reslicer GetOutput] GetNumberOfScalarComponents]
      puts " Reliscer output,  $ScalarComponents  scalar comonents."



  }
  
          
  # Kilian April 06:
  # used to be $Resampled DeepCopy [Reslicer GetOutput]

  # vtkImageReslice with Cubic Interpolation can produce volumes with negative values even though 
  # input does not have any. The following insures that this does not happen 
  # If intensity transformation is activated make sure that intensity profile does not exceed target intensity profile
  if {($ResampleOptions(intens) == 1) && $AG(Warp)} {
      AGThresholdedOutput $Target [Reslicer GetOutput] $Resampled
  } else {
      AGThresholdedOutput [Cast GetOutput] [Reslicer GetOutput] $Resampled
  }

  $Resampled SetUpdateExtentToWholeExtent
  #if { ($AG(InputVolSource2) == $Volume(idNone)) || ($AG(InputVolTarget2) == $Volume(idNone)) }  {     
  #   Reslicer UnRegisterAllOutputs
  #}
  catch {Cast Delete}
  catch {ITrans Delete}
  Reslicer Delete

}





#-------------------------------------------------------------------------------
# .PROC AGNormalize
#   Run the Orientation Normalization.
#
# .ARGS
# string SourceImage
# string TargetImage
# string NormalizeSource
# string SourceScanOrder
# string TargetScanOrder
# .END
#-------------------------------------------------------------------------------
proc AGNormalize { SourceImage TargetImage NormalizedSource SourceScanOrder TargetScanOrder} {

    global AG Volume Gui

    
    catch "ijkmatrix Delete"
    catch "reslice Delete"

    vtkMatrix4x4 ijkmatrix
    vtkImageReslice reslice
   
    if {$AG(Interpolation)} {
       reslice SetInterpolationModeToCubic
    }

    catch "xform Delete"
    catch "changeinfo Delete"
    vtkTransform xform
    vtkImageChangeInformation changeinfo
    changeinfo CenterImageOn


    changeinfo SetInput $SourceImage
    # [Volume($AG(InputVolSource),vol) GetOutput]

    reslice SetInput [changeinfo GetOutput]

    switch  $SourceScanOrder {    
    "LR" { set axes {  0  0 -1  -1  0  0   0  1  0 } }
    "RL" { set axes {  0  0  1  -1  0  0   0  1  0 } }
    "IS" { set axes {  1  0  0   0  1  0   0  0  1 } }
    "SI" { set axes {  1  0  0   0  1  0   0  0 -1 } }
    "PA" { set axes {  1  0  0   0  0  1   0  1  0 } }
    "AP" { set axes {  1  0  0   0  0  1   0 -1  0 } }
    }


    if {$AG(Debug) == 1} {
    puts "  axes are $axes"
    }

  
    set ii 0
    for {set i 0} {$i < 3} {incr i} {
        for {set j 0} {$j < 3} {incr j} {
            # transpose for inverse - reslice transform requires it
            ijkmatrix SetElement $j $i [lindex $axes $ii]
            incr ii
        }
    }
    
    ijkmatrix SetElement 3 3 1

    # TODO - add other orientations here...
    catch "transposematrix Delete"
    vtkMatrix4x4 transposematrix
    
    switch $TargetScanOrder {

    "LR" {  
        transposematrix DeepCopy \
            0  0  -1  0 \
            -1  0   0  0 \
            0  1   0  0 \
            0  0   0  1 
    }
    "RL" {
        transposematrix DeepCopy \
            0  0  1  0 \
           -1  0  0  0 \
            0  1  0  0 \
            0  0  0  1 
    }
        
    "IS" {   transposematrix Identity }
        "SI" { 
        transposematrix  DeepCopy \
            1  0  0   0 \
            0  1  0   0 \
            0  0 -1   0 \
            0  0  0   1
    }
        "PA" {
        transposematrix  DeepCopy \
            1  0  0 0 \
            0  0  1 0 \
            0  1  0 0 \
            0  0  0 1    
    }
        "AP" {
        transposematrix  DeepCopy \
            1  0  0 0 \
            0  0  1 0 \
            0 -1  0 0 \
            0  0  0 1 
    }
    }

 

    if {$AG(Debug) == 1} {
    puts " before using the transpose matrix, ijkmatrix is:"
    for {set i 0} {$i < 4} {incr i} {    
        set element0 [ijkmatrix GetElement $i 0]
        set element1 [ijkmatrix GetElement $i 1]
        set element2 [ijkmatrix GetElement $i 2]
        set element3 [ijkmatrix GetElement $i 3]
        puts " $element0  $element1  $element2  $element3"
    }

    puts " transpose matrixis:"
    for {set i 0} {$i < 4} {incr i} {    
        set element0 [transposematrix GetElement $i 0]
        set element1 [transposematrix GetElement $i 1]
        set element2 [transposematrix GetElement $i 2]
        set element3 [transposematrix GetElement $i 3]
        puts " $element0  $element1  $element2  $element3"
    }
    }

    ijkmatrix Multiply4x4 ijkmatrix transposematrix ijkmatrix
    
    transposematrix Delete

    if {$AG(Debug) == 1} {
    puts " After using the transpose matrix, ijkmatrix is:"
    for {set i 0} {$i < 4} {incr i} {    
        set element0 [ijkmatrix GetElement $i 0]
        set element1 [ijkmatrix GetElement $i 1]
        set element2 [ijkmatrix GetElement $i 2]
        set element3 [ijkmatrix GetElement $i 3]
        puts "$element0  $element1  $element2  $element3" 
    }
    }
    

    xform SetMatrix ijkmatrix

    reslice SetResliceTransform xform 

    #reslice SetInformationInput $TargetImage
    set spacing [$SourceImage GetSpacing]
    set spa_0  [lindex $spacing 0]
    set spa_1  [lindex $spacing 1]
    set spa_2  [lindex $spacing 2]


    set outspa [xform TransformPoint $spa_0 $spa_1 $spa_2]
    
    set outspa_0 [lindex $outspa 0]
    set outspa_1 [lindex $outspa 1]
    set outspa_2 [lindex $outspa 2]
    
    set outspa_0 [expr abs($outspa_0)]
    set outspa_1 [expr abs($outspa_1)]
    set outspa_2 [expr abs($outspa_2)]

    set extent [$SourceImage  GetExtent]
    
    set ext_0 [lindex $extent 0] 
    set ext_1 [lindex $extent 1] 
    set ext_2 [lindex $extent 2] 
    set ext_3 [lindex $extent 3] 
    set ext_4 [lindex $extent 4] 
    set ext_5 [lindex $extent 5] 

    set dim_0 [expr $ext_1 -$ext_0+1]
    set dim_1 [expr $ext_3 -$ext_2+1]
    set dim_2 [expr $ext_5 -$ext_4+1]



    set outdim [xform TransformPoint $dim_0 $dim_1 $dim_2]
    
    set outdim_0 [lindex $outdim 0] 
    set outdim_1 [lindex $outdim 1] 
    set outdim_2 [lindex $outdim 2] 
    
    set outext_0 0    
    set outext_1 [expr abs($outdim_0)-1]  
    set outext_2 0    
    set outext_3 [expr abs($outdim_1)-1]  
    
    set outext_4 0    
    set outext_5 [expr abs($outdim_2)-1]  



    set spacing [$TargetImage GetSpacing]
    set outspa_0  [lindex $spacing 0]
    set outspa_1  [lindex $spacing 1]
    set outspa_2  [lindex $spacing 2]


   

    set extent [$TargetImage  GetExtent]
    
    set ext_0 [lindex $extent 0] 
    set ext_1 [lindex $extent 1] 
    set ext_2 [lindex $extent 2] 
    set ext_3 [lindex $extent 3] 
    set ext_4 [lindex $extent 4] 
    set ext_5 [lindex $extent 5] 

    set outdim_0 [expr $ext_1 -$ext_0+1]
    set outdim_1 [expr $ext_3 -$ext_2+1]
    set outdim_2 [expr $ext_5 -$ext_4+1]



   
    
    set outext_0 0    
    set outext_1 [expr abs($outdim_0)-1]  
    set outext_2 0    
    set outext_3 [expr abs($outdim_1)-1]  
    
    set outext_4 0    
    set outext_5 [expr abs($outdim_2)-1]  



    reslice SetOutputSpacing $outspa_0 $outspa_1 $outspa_2
    
    reslice SetOutputExtent $outext_0 $outext_1 $outext_2 $outext_3 $outext_4 $outext_5
    # [reslice GetOutput] SetUpdateExtent $outext_0 $outext_1 $outext_2 $outext_3 $outext_4 $outext_5
    
    if {$AG(Debug) == 1} {
        puts " out dim:  $outdim"
        puts " out spacing :  $outspa" 
    }

    reslice Update

    #Volume($AG(ResultVol),vol) SetImageData  [reslice GetOutput]

    [reslice GetOutput]  SetOrigin 0 0 0

    # vtkImageReslice with Cubic Interpolation can produce volumes with negative values even though 
    # input does not have any. The following insures that this does not happen 
    AGThresholdedOutput [changeinfo GetOutput] [reslice GetOutput] $NormalizedSource 
    $NormalizedSource SetUpdateExtentToWholeExtent
  
    if {$AG(Debug) == 1} {

      set scalar_range [[reslice GetOutput] GetScalarRange]
      puts "Resclier's scalar range is : $scalar_range"
        
  
      set DataType [[reslice GetOutput] GetDataObjectType]
      puts " Reliscer output, data type is $DataType"
  
      set dim_arr [[reslice GetOutput] GetDimensions]
  
      puts " Reliscer output, dimensions:$dim_arr"
        
     
      set origin_arr [[reslice GetOutput] GetOrigin]
  
      puts " Reliscer output, origin : $origin_arr"
        
      #set {extent_1 extent_2 extent_3 extent_4 extent_5 extent_6} [[reslice GetOutput] GetExtent]
  
      set extent_arr [[reslice GetOutput] GetExtent]
  
  
  
      #parray extent_arr
      puts " Reliscer output, extent:$extent_arr"
      
  
      set spacing_arr [[reslice GetOutput] GetSpacing]
      
  
  
      #parray extent_arr
      puts " Reliscer output, spacings:$spacing_arr"
      
      
        
      
      set ScalarSize [[reslice GetOutput] GetScalarSize]
      puts " Reliscer output, ScalarSize is $ScalarSize"
        
      set ScalarType [[reslice GetOutput] GetScalarTypeAsString]
      puts " Reliscer output, ScalarType is $ScalarType"
      
      set ScalarComponents [[reslice GetOutput] GetNumberOfScalarComponents]
      puts " Reliscer output,  $ScalarComponents  scalar comonents."

    }

    xform Delete
    changeinfo Delete
    reslice Delete
}

#-------------------------------------------------------------------------------
# .PROC AGTestWriting
# Test writing vtkImageData for the input.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGTestWriting {} {

  global AG Volume Gui

  set intesity_transform_object 0

  puts "RunAG 1: Check Error"

  if {[AGCheckErrors] == 1} {
      return
  }

 
  catch "Target Delete"
  catch "Source Delete"

  vtkImageData Target
  vtkImageData Source

#If source and target have two channels, combine them into one vtkImageData object 
  if { ($AG(InputVolSource2) == $Volume(idNone)) || ($AG(InputVolTarget2) == $Volume(idNone)) }  {
      Target DeepCopy  [ Volume($AG(InputVolTarget),vol) GetOutput]
      Source DeepCopy   [ Volume($AG(InputVolSource),vol) GetOutput]
  } else {
      catch "Target1 Delete"
      vtkImageData Target1 
      Target1 DeepCopy   [ Volume($AG(InputVolTarget),vol) GetOutput]
      catch "Source1 Delete"
      vtkImageData Source1
      Source1 DeepCopy   [ Volume($AG(InputVolSource),vol) GetOutput]
      catch "Target2 Delete"
      vtkImageData Target2 
      Target2 DeepCopy   [ Volume($AG(InputVolTarget2),vol) GetOutput]
      catch "Source2 Delete"
      vtkImageData Source2
      Source2 DeepCopy   [ Volume($AG(InputVolSource2),vol) GetOutput]

      set dims_arr1 [Source1  GetDimensions]     
      set dims_arr2 [Source2  GetDimensions]

      set dim1_0 [lindex $dims_arr1 0] 
      set dim1_1 [lindex $dims_arr1 1] 
      set dim1_2 [lindex $dims_arr1 2] 
    
      set dim2_0 [lindex $dims_arr2 0] 
      set dim2_1 [lindex $dims_arr2 1] 
      set dim2_2 [lindex $dims_arr2 2] 
 
 
      if {($dim1_0 != $dim2_0) || ($dim1_1 != $dim2_1) || ($dim1_2 != $dim2_2) } {
      DevErrorWindow "Two Source channels have different dimensions"
      Source1 Delete
      Source2 Delete
      Target1 Delete
      Target2 Delete
      Source Delete
      Target Delete
      
      return
      } 

    

      set dims_arr1 [Target1  GetDimensions]     
      set dims_arr2 [Target2  GetDimensions]

      set dim1_0 [lindex $dims_arr1 0] 
      set dim1_1 [lindex $dims_arr1 1] 
      set dim1_2 [lindex $dims_arr1 2] 
    
      set dim2_0 [lindex $dims_arr2 0] 
      set dim2_1 [lindex $dims_arr2 1] 
      set dim2_2 [lindex $dims_arr2 2] 
 
 
      if {($dim1_0 != $dim2_0) || ($dim1_1 != $dim2_1) || ($dim1_2 != $dim2_2) } {
      DevErrorWindow "Two Target channels have different dimensions"
      Source1 Delete
      Source2 Delete
      Target1 Delete
      Target2 Delete
      Source Delete
      Target Delete
      
      return
      } 
    
      catch "combineS  Delete"
      vtkImageAppendComponents combineS     
      combineS SetInput 0 Source1       
      combineS SetInput 1 Source2
      combineS Update
      Source DeepCopy [combineS GetOutput]
      Source Update 
      combineS  Delete 
      # ReleaseDataFlagOff
 
      catch "combineT  Delete"
      vtkImageAppendComponents combineT
      combineT SetInput  0 Target1 
      combineT SetInput  1 Target2
      combineT Update
      Target  DeepCopy [combineT GetOutput]
      Target Update
      combineT Delete 
      #ReleaseDataFlagOff
      Source1 Delete
      Source2 Delete
      Target1 Delete
      Target2 Delete
     #set $AG(Nb_of_functions) 2 ??
  }
 

 
 
  #set targetType  [Target  GetDataObjectType]
  #puts "Targert object type is $targetType"
  #set targetPointNum  [Target  GetNumberOfPoints]
  #puts "Targert object has   $targetPointNum points"
  #set targetCellNum  [Target  GetNumberOfCells]
  #puts "Targert object has   $targetCellNum cells"

  set extent_arr [Target  GetExtent]
  #parray extent_arr
  #puts " Target, extent:$extent_arr"

  if { ([lindex $extent_arr 1] < 0) || ([lindex $extent_arr 3] < 0) || ([lindex $extent_arr 5] < 0)   } {
      DevErrorWindow "Target is not correct or empty"

      Target Delete
      Source Delete

      return 
  }

  if {$AG(Debug) == 1} {
      puts " Debug information \n\n" 
      set targetType  [Target  GetDataObjectType]
      puts "Targert object type is $targetType"
      set targetPointNum  [Target  GetNumberOfPoints]
      puts "Targert object has   $targetPointNum points"
      set targetCellNum  [Target  GetNumberOfCells]
      puts "Targert object has   $targetCellNum cells"

      set extent_arr [Target  GetExtent]
      #parray extent_arr
      puts " Target, extent:$extent_arr"


      set spacing [Target GetSpacing]
      puts " Target, spacing is  $spacing"
      
      set origin [Target GetOrigin]
      puts " Target, spacing is  $origin"
      
      set scalarSize [Target GetScalarSize]
      puts " Target, scalar size is  $scalarSize"
      set scalarType [Target GetScalarType]
      puts " Target, scalar type is  $scalarType"
      

      set sourceType  [Source  GetDataObjectType]
      puts "Source object type is $sourceType"
      set sourcePointNum  [Source  GetNumberOfPoints]
      puts "Source object has   $sourcePointNum points"
      set sourceCellNum  [Source  GetNumberOfCells]
      puts "Source object has   $sourceCellNum cells"

      set extent_arr [Source  GetExtent]
      #parray extent_arr
      puts " Source, extent:$extent_arr"
  
      set spacing [Source GetSpacing]
      puts " Source, spacing is  $spacing"
      
      set origin [Source GetOrigin]
      puts " Source, spacing is  $origin"
      set origin [Source GetOrigin]
      puts " Source, spacing is  $origin"
      set scalarSize [Source GetScalarSize]
      puts " Source, scalar size is  $scalarSize"
      set scalarType [Source GetScalarType]
      puts " Source, scalar type is  $scalarType"
      set ScalarComponents [Source GetNumberOfScalarComponents]
      puts " Source,  $ScalarComponents  scalar components."

      set dim_arr [Source GetDimensions]
      
      puts "Source, dimensions:$dim_arr"
  }

  AGWritevtkImageData Source "testwrite.vtk"

}



#-------------------------------------------------------------------------------
# .PROC AGReadvtkImageData
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGReadvtkImageData {image filename}  {
    

    catch "TReader Delete"

    vtkStructuredPointsReader TReader

    TReader SetFileName $filename

    #TReader.SetNumberOfScalarComponents(2)
    TReader Update

    $image DeepCopy [TReader GetOutput]

    TReader Delete
    return 1
}


#-------------------------------------------------------------------------------
# .PROC AGTestReadvtkImageData
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGTestReadvtkImageData {}  {
  


    catch "SourceTest Delete"
    vtkImageData SourceTest
    
    AGReadvtkImageData  SourceTest  "testwrite.vtk"
   
    set sourceType  [SourceTest  GetDataObjectType]
      puts "Source object type is $sourceType"
      set sourcePointNum  [SourceTest  GetNumberOfPoints]
      puts "Source object has   $sourcePointNum points"
      set sourceCellNum  [SourceTest  GetNumberOfCells]
      puts "Source object has   $sourceCellNum cells"

      set extent_arr [SourceTest  GetExtent]
      #parray extent_arr
      puts " Source, extent:$extent_arr"
  
      set spacing [SourceTest GetSpacing]
      puts " Source, spacing is  $spacing"
      
      set origin [SourceTest GetOrigin]
      puts " Source, spacing is  $origin"
      set origin [SourceTest GetOrigin]
      puts " Source, spacing is  $origin"
      set scalarSize [SourceTest GetScalarSize]
      puts " Source, scalar size is  $scalarSize"
      set scalarType [SourceTest GetScalarType]
      puts " Source, scalar type is  $scalarType"
      set ScalarComponents [SourceTest GetNumberOfScalarComponents]
      puts " Source,  $ScalarComponents  scalar components."

      set dim_arr [SourceTest GetDimensions]
      
      puts "Source, dimensions:$dim_arr"

}

#-------------------------------------------------------------------------------
# .PROC AGUpdateInitial
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGUpdateInitial {meth} {
    global Matrix AG
    switch $meth {
      "lin" {
        if {$Matrix(activeID)!="" && $AG(Initial_lin)} {
          set AG(Initial_lintxt) "On"
          set AG(Initial_tfm) 1
        } else {
          set AG(Initial_lintxt) "Off"
      set AG(Initial_lin) "0"
        }
      }
      "grid" {
        if {$AG(InitGridTfmName)!="" && $AG(Initial_grid)} {
          set AG(Initial_gridtxt) "On"
          set AG(Initial_tfm) 1
        } else {
          set AG(Initial_gridtxt) "Off"
      set AG(Initial_grid) "0"
        }
      
      }
      "prev" {
        if {[info exist AG(Transform)] && $AG(Initial_prev)} {
          set AG(Initial_prevtxt) "On"
          set AG(Initial_tfm) 1
        } else {
          set AG(Initial_prevtxt) "Off"
      set AG(Initial_prev) "0"
        }
      
      }
      
    }
    
    if {(!$AG(Initial_lin))&&(!$AG(Initial_grid))&&(!$AG(Initial_prev))} {
      set AG(Initial_tfm) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC AGTurnInitialOff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGTurnInitialOff {} {
    global AG
    set AG(Initial_tfm) 0
    set AG(Initial_lin) 0
    set AG(Initial_grid) 0
    set AG(Initial_prev) 0
    AGUpdateInitial "lin"
    AGUpdateInitial "grid"
    AGUpdateInitial "prev"
}

#-------------------------------------------------------------------------------
# .PROC AGCreateLinMat
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGCreateLinMat {} {
    global AG
    if {![info exist AG(Transform)]} {
        DevErrorWindow "No transformation available, matrix generation aborted."
    return
    }
    set n [TransformAG GetNumberOfConcatenatedTransforms]
    if {$AG(Debug) == 1} {
        puts " There are $n concatenated transforms"
    }
    set done 0
    for {set i [expr $n-1]}  {$i >= 0} {set i [expr $i-1]} {
        set t [TransformAG GetConcatenatedTransform $i]
        set int_H [$t IsA vtkHomogeneousTransform]
        if { ($int_H != 0) && !$done} {
            set done 1

        set fname [tk_getSaveFile -defaultextension ".txt" -title "File to save linear transform"]
        set fileid [ open $fname w ]
        puts "fileid is $fileid"

            AGWriteHomogeneous $t $fileid
        }
    }
    if {!$done} {
        DevErrorWindow "No linear transform computed."
    return
    }
}

#-------------------------------------------------------------------------------
# .PROC AGSaveGridTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGSaveGridTransform {} {
    global AG
    if {![info exist AG(Transform)]} {
        DevErrorWindow "No transformation available, grid-file not saved."
    return
    }
    set n [TransformAG GetNumberOfConcatenatedTransforms]
    if {$AG(Debug) == 1} {
        puts " There are $n concatenated transforms"
    }
    set done 0
    for {set i [expr $n-1]}  {$i >= 0} {set i [expr $i-1]} {
        set t [TransformAG GetConcatenatedTransform $i]
        set int_G [$t IsA vtkGridTransform]
        if { ($int_G != 0) && !$done } {
            set done 1
        if {![AGWriteGrid $t $i 0]} {
          DevErrorWindow "Error saving file."
        }
        }
    }
    if {!$done} {
        DevErrorWindow "No non-linear transform computed."
    return
    }
    
}

#-------------------------------------------------------------------------------
# .PROC AGColorComparison
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGColorComparison {} {
    global AG Volume Slice

    if {$AG(InputVolTarget)==$Volume(idNone)} {
      DevErrorWindow "Please select a target volume"
      return
    }
    if {$AG(ResultVol)==-5} {
      DevErrorWindow "Please select a result volume"
      return
    }

    catch "app Delete"
    vtkImageAppendComponents app
    
    # Create absolute value, just in case.
    catch "abs Delete"
    vtkImageMathematics abs
    abs SetInput 0 [Volume($AG(ResultVol),vol) GetOutput]
    abs SetOperationToAbsoluteValue
    
    catch "shift Delete"
    vtkImageShiftScale shift    
    shift SetInput [abs GetOutput]
    shift SetOutputScalarTypeToUnsignedChar
    abs Update
    set r [[[[abs GetOutput] GetPointData] GetScalars] GetRange]
    puts $r
    set r [lindex $r 1]
    puts $r
    shift SetShift 0
    shift SetScale [expr 255.0/$r]
    shift Update
    app SetInput 0 [shift GetOutput]
    app SetInput 2 [shift GetOutput]
    catch "abs Delete"
    vtkImageMathematics abs
    abs SetInput 0 [Volume($AG(InputVolTarget),vol) GetOutput]
    abs SetOperationToAbsoluteValue
    
    catch "shift Delete"
    vtkImageShiftScale shift    
    shift SetInput [abs GetOutput]
    shift SetOutputScalarTypeToUnsignedChar
    abs Update
    set r [[[[abs GetOutput] GetPointData] GetScalars] GetRange]
    set r [lindex $r 1]
    shift SetScale [expr 255.0/$r]
    shift Update
    app SetInput 1 [shift GetOutput]
    
    set dim0 [[app GetInput 0] GetDimensions]
    set dim1 [[app GetInput 1] GetDimensions]
    foreach d0 $dim0 d1 $dim1 {
      if {$d0!=$d1} {
        DevErrorWindow "Dimensionalities of result and target do not match."
        return
      }
    }
    
    app Update
    
    # Create a new volume based on the name of the source volume and the node descirption of the target volume
    #set v1 $SourceVolume
    #set v2name  [Volume($SourceVolume,node) GetName]
    set v2 [DevCreateNewCopiedVolume $AG(ResultVol) ""  "Color Comparison" ]

    Volume($v2,vol) SetImageData [app GetOutput]
    #check Delete
    MainVolumesUpdate $v2
    Volume($v2,node) SetInterpolate 0
    Volume($v2,node) SetScalarType [[shift GetOutput] GetScalarType]
    abs Delete
    shift Delete
    app Delete
    MainUpdateMRML    
    MainSlicesSetVolumeAll Back $v2
    MainSlicesSetVolumeAll Fore $Volume(idNone)
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC AGCommandLine
# Command-line registration using AG. Currently, the input is analyze,
# output is vtk. A parameter-file is needed, you can use
# AGInitCommandLineParameters.tcl in the Modules/vtkAG/tcl directory.
# Coregistration file is mandatory at the moment. 
# Example usage:
#   1) Set up a virtual display:
#        Xvfb :2 -screen 0 800x600x16
#   2) Run Slicer and execute AG:
#        slicer2-linux-x86 -y --no-tkcon --exec AGCommandLine target.hdr 
#        source.hdr coreg.hdr AGInitCommandLineParameters.tcl , exit
#        -display :2 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGCommandLine { {targetname} {sourcename} {coregname} {paramfile} } {
  # have args as extra arg
  global AG Volume
  puts "Targetname: $targetname"
  puts "Sourcename: $sourcename"
  puts "Coregname: $coregname"
  puts "Paramfile: $paramfile"
  
  set resultname [string trimright $sourcename ".hdr"]
  append resultname "_warp.vtk"

  # source parameterfile, containing one proc
  source $paramfile
  # and run it
  AGInitCommandLineParameters
  puts "targetname"
  # They are vol 1 and 2
  set ::Volume(VolAnalyze,FileName) $targetname
  VolAnalyzeApply; RenderAll
  set ::Volume(VolAnalyze,FileName) $sourcename
  VolAnalyzeApply; RenderAll
  
  # set target and source for registration
  set ::AG(InputVolTarget) 1
  set ::AG(InputVolSource) 2
  # create new result volume = -5
  set ::AG(ResultVol) -5

  # and run
  RunAG

  # save output
  AGWritevtkImageData [Volume($AG(ResultVol),vol) GetOutput] $resultname
  
  # ResultVol is 3, CoregVol 4, ResultCoregVol 5
  # Do coregistration
  set ::Volume(VolAnalyze,FileName) $coregname
  VolAnalyzeApply; RenderAll
  set ::AG(CoregVol) 4

  AGCoregister
  set coregname [string trimright $coregname ".hdr"]
  append coregname "_coreg.vtk"
  AGWritevtkImageData [Volume(5,vol) GetOutput] $coregname

  # Write transforms to disk
  set lintransname [string trimright $sourcename ".hdr"]
  set gridtransname $lintransname
  append lintransname "_lintrans"
  append gridtransname "_gridtrans.vtk"
  AGWriteLinearNonLinearTransform $lintransname $gridtransname
}

