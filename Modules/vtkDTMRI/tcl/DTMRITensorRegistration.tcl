#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRITensorRegistration.tcl,v $
#   Date:      $Date: 2006/07/31 21:27:43 $
#   Version:   $Revision: 1.30 $
# 
#===============================================================================
# FILE:        DTMRITensorRegistration.tcl
# PROCEDURES:  
#   DTMRITensorRegistrationInit
#   DTMRIBuildRegistFrame
#   DTMRIRegModifyOptions optClass value
#   DTMRIRegCheckErrors
#   DTMRIRegDeformationVolume
#   DTMRIRegPrepareResultVolume
#   DTMRIWritevtkImageData
#   DTMRIRegIntensityTransform
#   DTMRIRegTransformScale
#   DTMRIRegWriteHomogeneous t ii
#   DTMRIRegWriteGrid t ii
#   DTMRIRegRun
#   DTMRIRegMenuCoregister
#   DTMRIRegCoregister
#   DTMRIRegPreprocess
#   DTMRIRegResample
#   DTMRIRegNormalize
#   DTMRIReadvtkImageData image filename
#   DTMRIRegPrmdSetup
#   DTMRIReg2DUpate
#   DTMRIRegUpdateInitial meth
#   DTMRIRegTurnInitialOff
#   DTMRIRegCreateLinMat
#   DTMRIRegSaveGridTransform
#   DTMRIRegColorComparison
#   DTMRIRegHelpUpdate initial
#   DTMRIRegCommandline targetname sourcename resultname
#==========================================================================auto=

#   ==================================================
#   SubModule: DTMRITensorRegistration
#   Author: Matthan Caan
#   Email: see Google 
#
#   This submodule forms one tab of the DTMRI module in the Slicer
#   DTMRIInit calls this tcl-file
#   DTMRIUpdateMRML updates the buttons
#   ==================================================
#   Copyright (C) 2004-2005  
#
#   See DTMRI.tcl for Copyright details

#-------------------------------------------------------------------------------
# .PROC DTMRITensorRegistrationInit
#  This procedure is called from DTMRIInit and initializes the
#  Tensor Registration Module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITensorRegistrationInit {} {
    global DTMRI Module Volume Transform Tensor Gui
    
    # Version info for files within DTMRI module
    #------------------------------------
    set m "TensorRegistration"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.30 $} {$Date: 2006/07/31 21:27:43 $}]

    # Does the AG module exist? If not the registration tab will not be displayed
    if {[catch "package require vtkAG"]} {
      set DTMRI(reg,AG) 0
    } else {
    set DTMRI(reg,AG) 1
    }
    if {(!$DTMRI(reg,AG))} {
      return 0
    }    
    
    set DTMRI(InputTensorSource) $Tensor(idNone)
    set DTMRI(InputTensorTarget) $Tensor(idNone)
    set DTMRI(ResultTensor) -5
    set DTMRI(InputCoregVol) $Volume(idNone)
    set DTMRI(TargetMaskVol) $Volume(idNone)
    set DTMRI(SourceMaskVol) $Volume(idNone)
    
    # set DTMRI(reg,DEBUG) to 1 to display more information.
    set DTMRI(reg,Debug) 1
   
    set DTMRI(reg,Linear)    "1"
    set DTMRI(reg,Warp)      "1"

    set DTMRI(reg,Initial_tfm) "0"
    set DTMRI(reg,Initial_lin)  "0"
    set DTMRI(reg,Initial_grid) "0"
    set DTMRI(reg,Initial_prev) "0"
    set DTMRI(reg,Initial_AG) "0"
    set DTMRI(reg,Initial_lintxt) "Off"
    set DTMRI(reg,Initial_gridtxt) "Off"
    set DTMRI(reg,Initial_prevtxt) "Off"
    set DTMRI(reg,Initial_AGtxt) "Off"
        
    #GCR options
    set DTMRI(reg,Linear_group)  "2"
    set DTMRI(reg,Gcr_criterion) "2"

    #Demons options
    set DTMRI(reg,Channels) "1"
    set DTMRI(reg,Tensors)  "1"
    set DTMRI(reg,Interpolation) "1"
    set DTMRI(reg,Iteration_min) "10"
    set DTMRI(reg,Iteration_max)  "50"
    set DTMRI(reg,Level_min)  "-1"
    set DTMRI(reg,Level_max)  "-1"
    set DTMRI(reg,Epsilon)    "5e-4"
    set DTMRI(reg,Stddev_min) "1"
    # [expr sqrt(-1./(2.*log(.5)))] = 0.85
    set DTMRI(reg,Stddev_max) "1"
    set DTMRI(reg,SSD)    "1" 

    #Intensity correction
    set DTMRI(reg,Intensity_tfm) "mono-functional"   
    set DTMRI(reg,Force)   "1"
    set DTMRI(reg,Degree)   1
    set DTMRI(reg,Ratio)    1
    set DTMRI(reg,Nb_of_functions)  1
    set DTMRI(reg,Nb_of_pieces)    {}
    set DTMRI(reg,Use_bias)        0
    set DTMRI(reg,Boundaries)      {}

    set DTMRI(reg,2Dcolor) $Gui(activeWorkspace)
    set DTMRI(reg,Help) 0
    set DTMRI(reg,NrUpdateCalled) 0
    set DTMRI(reg,Scope) 1
    set DTMRI(reg,Scalarmeas) "Trace"
    set DTMRI(reg,TestReadingWriting) 0   
    set DTMRI(reg,CountNewResults) 1
    #set DTMRI(reg,checkx) "10"
    #set DTMRI(reg,checky) "10"
    #set DTMRI(reg,checkz) "10"
    set DTMRI(reg,Verbose)  "2"
    set DTMRI(reg,Scale)    "-1"
    set DTMRI(reg,2D)        "0"
    set DTMRI(reg,Labelmap) 0

    DTMRIRegHelpUpdate 1

    # Event bindings! (see DTMRIEnter, DTMRIExit, tcl-shared/Events.tcl)
    set DTMRI(reg,eventManager)  { \
        {all <Shift-1> {DTMRIBindingCallback Shift-1 %W %X %Y %x %y %t}} \
        {all <Shift-2> {DTMRIBindingCallback Shift-2 %W %X %Y %x %y %t}} \
        {all <Shift-3> {DTMRIBindingCallback Shift-3 %W %X %Y %x %y %t}} }
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
# .PROC DTMRIBuildRegistFrame
#
#   Create the Regist frame in DTMRI module
# .END
#-------------------------------------------------------------------------------
proc DTMRITensorRegistrationBuildGUI {} {

  global Gui Module Volume Tensor DTMRI Matrix

    if {!$DTMRI(reg,AG)} {
      set fRegist $Module(DTMRI,fRegist)
      set f $fRegist.fNoAG
      frame $f -bg $Gui(activeWorkspace)
      pack $f -side left -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
      DevAddLabel $f.lNoAG "AG module not available."
      pack $f.lNoAG -side left -padx $Gui(pad) -pady $Gui(pad) -anchor w
      return
    }
    
    #-------------------------------------------
    # Regist frame
    #-------------------------------------------
    set fRegist $Module(DTMRI,fRegist)
    set f $fRegist
    frame $f.fTitle -bg $Gui(backdrop)
    pack $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w

    if { [catch "package require BLT" ] } {
        DevErrorWindow "Must have the BLT package to create GUI."
        return
    }

    #--- create blt notebook
    blt::tabset $f.fNotebook -relief flat -borderwidth 0
    pack $f.fNotebook -fill both -expand 1

    #--- notebook configure
    $f.fNotebook configure -width 240
    $f.fNotebook configure -height 360
    $f.fNotebook configure -background $::Gui(activeWorkspace)
    $f.fNotebook configure -activebackground $::Gui(activeWorkspace)
    $f.fNotebook configure -selectbackground $::Gui(activeWorkspace)
    $f.fNotebook configure -tabbackground $::Gui(activeWorkspace)
    $f.fNotebook configure -foreground black
    $f.fNotebook configure -activeforeground black
    $f.fNotebook configure -selectforeground black
    $f.fNotebook configure -tabforeground black
    $f.fNotebook configure -relief flat
    $f.fNotebook configure -tabrelief raised     
    $f.fNotebook configure -highlightbackground $::Gui(activeWorkspace)
    $f.fNotebook configure -highlightcolor $::Gui(activeWorkspace) 
        #--- tab configure
    set i 0
    foreach t "{Main} {Tfm} {Prmd} {Adv} {Help}" {
        $f.fNotebook insert $i $t
        frame $f.fNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        $f.fNotebook tab configure $t -window $f.fNotebook.f$t  \
            -fill both -padx $::Gui(pad) -pady $::Gui(pad)
        incr i
    } 

    set f $fRegist.fNotebook
         
    set FrameMain $f.fMain
    set FrameTfm $f.fTfm
    set FramePrmd $f.fPrmd
    set FrameAdvanced $f.fAdv
    set FrameHelp $f.fHelp 
    
    foreach frame "$FrameMain $FrameTfm $FramePrmd $FrameAdvanced $FrameHelp" {
        $frame configure -relief groove -bd 3
    }

    #-------------------------------------------
    # Regist->Title frame->Welcome
    #-------------------------------------------
    set f $fRegist.fTitle.fWelcome
    frame $f -bg $Gui(backdrop) 
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x 
    
    DevAddLabel $f.lWelcome "Tensor Registration"
    $f.lWelcome configure -fg White -font {helvetica 8 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
    pack $f.lWelcome -side top -padx $Gui(pad) 

    #-------------------------------------------
    # Regist->Main frame->Title
    #-------------------------------------------
    set f $FrameMain.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Main screen"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -anchor w

    #-------------------------------------------
    # Regist->Main frame->Input/Output Frame
    #-------------------------------------------
    set f $FrameMain.fTarget
    frame $f -bg $Gui(activeWorkspace) -width 30
    pack $f -side top -padx $Gui(pad) -pady 0  -anchor w
    DevAddSelectButton DTMRI $f InputTensorTarget "Target: " Pack "Select target (fixed) tensor volume." 30 
    lappend Tensor(mbInputTensorTarget) $f.mbInputTensorTarget
    lappend Tensor(mInputTensorTarget) $f.mbInputTensorTarget.m
    
    set f $FrameMain.fSource
    frame $f -bg $Gui(activeWorkspace) -width 30
    pack $f -side top -padx $Gui(pad) -pady 0  -anchor w 
    DevAddSelectButton DTMRI $f InputTensorSource "Source:" Pack "Select source (moving) tensor volume." 30
    lappend Tensor(mbInputTensorSource) $f.mbInputTensorSource
    lappend Tensor(mInputTensorSource) $f.mbInputTensorSource.m

    set f $FrameMain.fResult
    frame $f -bg $Gui(activeWorkspace) -width 30
    pack $f -side top -padx $Gui(pad) -pady 0  -anchor w
    DevAddSelectButton DTMRI $f ResultTensor "Result: " Pack "Select result tensor volume." 30
    lappend Tensor(mbResultTensor) $f.mbResultTensor
    lappend Tensor(mResultTensor) $f.mbResultTensor.m

    set f $FrameMain.fTargetMask
    frame $f -bg $Gui(activeWorkspace) -width 30
    pack $f -side top -padx $Gui(pad) -pady 0 -anchor w 
    DevAddSelectButton DTMRI $f TargetMaskVol "Target Mask:   " Pack "Select target mask volume (optional)." 30
    lappend Volume(mbTargetMaskList) $f.mbTargetMaskVol
    lappend Volume(mTargetMaskList) $f.mbTargetMaskVol.m

    set f $FrameMain.fSourceMask
    frame $f -bg $Gui(activeWorkspace) -width 30
    pack $f -side top -padx $Gui(pad) -pady 0 -anchor w 
    DevAddSelectButton DTMRI $f SourceMaskVol "Source Mask:   " Pack "Select source mask volume (optional)." 30
    lappend Volume(mbSourceMaskList) $f.mbSourceMaskVol
    lappend Volume(mSourceMaskList) $f.mbSourceMaskVol.m

    #-------------------------------------------
    # Regist->Main frame->Method Frame
    #-------------------------------------------

    set f $FrameMain.fMethod
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x 

    DevAddLabel $f.l "Method:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    eval {label $f.lInitial} $Gui(WLA)
    eval {checkbutton $f.cInitialLabel \
        -text  "Initial" -command DTMRIRegTurnInitialOff -variable DTMRI(reg,Initial_tfm) \
         -indicatoron 0 } $Gui(WCA)
    pack $f.lInitial $f.cInitialLabel -side left 
    TooltipAdd $f.cInitialLabel "Click to set initial transformation(s) off."

    eval {label $f.lLinear} $Gui(WLA)
    eval {checkbutton $f.cLinearLabel \
        -text  "Linear" -variable DTMRI(reg,Linear) \
         -indicatoron 0 } $Gui(WCA)
    pack $f.lLinear $f.cLinearLabel -side left -padx 2
    TooltipAdd $f.cLinearLabel "Perform a linear registration. Can be combined with non-linear."
 
    eval {label $f.lNonLinear} $Gui(WLA)
  
    eval {checkbutton $f.cNonLinearLabel \
        -text "Non-linear" -variable DTMRI(reg,Warp) \
        -indicatoron 0 } $Gui(WCA)
    pack $f.lInitial $f.lNonLinear $f.cNonLinearLabel -side left  
    TooltipAdd $f.cNonLinearLabel "Perform a non-linear registration. Can be combined with linear."


    #set f $FrameMain.fScope
    #frame $f -bg $Gui(activeWorkspace)
    #pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x 

    #DevAddLabel $f.l "Scope:  "
    #pack $f.l -side left -padx $Gui(pad) -pady 0

    #eval {radiobutton $f.rMode0 -text 2D -value 0 -variable DTMRI(reg,Scope) -command {DTMRIReg2DUpdate} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 4}
    #pack $f.rMode0 -side left -padx 0 -pady 0
    #eval {radiobutton $f.rMode1 -text 3D -value 1 -variable DTMRI(reg,Scope) -command {DTMRIReg2DUpdate} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 4}
    #pack $f.rMode1 -side left -padx 0 -pady 0
    #TooltipAdd $f.rMode0 "2D-registration on slice currently viewed in scanning direction."
    #TooltipAdd $f.rMode1 "Registration based on the whole volume."

    #set f $f.2DUupdate
    #frame $f -bg $DTMRI(reg,2Dcolor)
    #pack $f -side left -padx 0 -pady 0
    #DevAddLabel $f.2dlabel ""
    #set DTMRI(reg,2dlabel) $f.2dlabel
    #pack $f.2dlabel -side left -padx 10 -pady 0

    #-------------------------------------------
    # Regist->Main frame->Run Frame
    #-------------------------------------------
    set f $FrameMain.fRun
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w

    DevAddButton $f.bRun "Run" "DTMRIRegRun"
    pack $f.bRun  
    TooltipAdd $f.bRun "Start the registration process."

    set f $FrameMain.fColorComparison
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w

    DevAddButton $f.bColorComp "Color comparison" "DTMRIRegColorComparison"
    pack $f.bColorComp -side top -pady 0 -padx $Gui(pad) 
    TooltipAdd $f.bColorComp "Create image with FA of the result as magenta and the target as green channel."

    set f $FrameMain.fCoreg
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x 
    DevAddLabel $f.lCoregLabel "Scalar volume Coregistration"
    pack $f.lCoregLabel -side top -padx $Gui(pad) -pady 0

    set f $FrameMain.fCoregbutton
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 -fill x 
    DevAddSelectButton DTMRI $f InputCoregVol "" Grid "Select scalar volume, aligned with tensor source." 20
    lappend Volume(mbCoregList) $f.mbInputCoregVol
    lappend Volume(mCoregList) $f.mbInputCoregVol.m

    set f $FrameMain.fDoCoreg
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 -fill x 
    DevAddButton $f.bDoCoreg "Coregister" "DTMRIRegMenuCoregister"
    pack $f.bDoCoreg -pady 0
    TooltipAdd $f.bDoCoreg "Coregister a scalar volume based on the computed transformation."


    ##########################################################
    #  TRANSFORM
    ##########################################################

    #-------------------------------------------
    # Regist->Tfm frame->Title
    #-------------------------------------------
    set f $FrameTfm.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Transforms"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    set f $FrameTfm.fInitial
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w
    DevAddLabel $f.linittfms "Initial Transforms"
    $f.linittfms configure -font {helvetica 9 bold}
    pack $f.linittfms -side top -padx $Gui(pad) -pady 2 -anchor w

    set f $FrameTfm.fInitialLinear
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
        -textvariable DTMRI(reg,Initial_lintxt) -command "DTMRIRegUpdateInitial lin" \
    -variable DTMRI(reg,Initial_lin) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitLin -side left -padx 0 -pady 0
    TooltipAdd $f.cInitLin "Set initial linear transform on/off."

    set f $FrameTfm.fInitialGrid
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 
    DevAddFileBrowse $f DTMRI regInitGridTfmName "Load VTK grid-transform" "" "vtk"
    eval {label $f.lInitialGrid} $Gui(WLA)
    TooltipAdd $f.lInitialGrid "Select 3 scalar component VTK-file for initial non-linear transform."
    DevAddLabel $f.lSpace " "
    pack $f.lSpace -side left -padx 40 -pady 0

    eval {checkbutton $f.cInitGrid \
        -textvariable DTMRI(reg,Initial_gridtxt) -command "DTMRIRegUpdateInitial grid" \
    -variable DTMRI(reg,Initial_grid) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitGrid -side left -padx 0 -pady 0
    TooltipAdd $f.cInitGrid "Set initial grid transform on/off."

    set f $FrameTfm.fInitialCalc
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    DevAddLabel $f.lInitPrev "Previous"
    pack $f.lInitPrev -side left -padx $Gui(pad) -padx $Gui(pad)
    eval {checkbutton $f.cInitPrev \
        -textvariable DTMRI(reg,Initial_prevtxt) -command "DTMRIRegUpdateInitial prev" \
    -variable DTMRI(reg,Initial_prev) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitPrev -side left -padx 0 -pady 0
    TooltipAdd $f.cInitPrev "Set on/off to use previous calculated transform as initial transform."

    DevAddLabel $f.lInitAG "   AG"
    pack $f.lInitAG -side left -padx $Gui(pad) -padx $Gui(pad)
    eval {checkbutton $f.cInitAG \
        -textvariable DTMRI(reg,Initial_AGtxt) -command "DTMRIRegUpdateInitial AG" \
    -variable DTMRI(reg,Initial_AG) -indicatoron 0 } $Gui(WCA) {-width 4}
    pack $f.cInitAG -side left -padx 0 -pady 0
    TooltipAdd $f.cInitAG "Set on/off to use transform calculated with the AG-module as initial transform."


    set f $FrameTfm.fSaveTfm
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w
    DevAddLabel $f.lsavetfm "Save Transforms"
    $f.lsavetfm configure -font {helvetica 9 bold}
    pack $f.lsavetfm -side top -padx $Gui(pad) -pady 2 -anchor w


    set f $FrameTfm.fCreateLin
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddButton $f.bCreateLin "Create lin.tfm. matrix" "DTMRIRegCreateLinMat"
    pack $f.bCreateLin  
    TooltipAdd $f.bCreateLin "Save a just computed linear transform as a matrix in the main data view."
    
    set f $FrameTfm.fSaveGrid
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 
    DevAddButton $f.bSaveGridTfm "Save VTK grid-transform" {DTMRIRegSaveGridTransform}
    pack $f.bSaveGridTfm -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bSaveGridTfm "Save just computed non-linear transform to file."

        
    ##########################################################
    #  PYRAMID
    ##########################################################

    #-------------------------------------------
    # Regist->Prmd frame->Title
    #-------------------------------------------
    set f $FramePrmd.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Pyramid setup"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    #-------------------------------------------
    # Regist->Prmd frame->Explain Frame
    #-------------------------------------------
    set f $FramePrmd.fExplain
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w

    set ExplainText    "Use this tab to determine min and max level\n"
    append ExplainText "of the registration pyramid used in non-\n"
    append ExplainText "linear registration. See help for more info.\n"
    
    DevAddLabel $f.lExplain "$ExplainText"
    pack $f.lExplain -side top -padx $Gui(pad) -pady 2 -anchor w

    #-------------------------------------------
    # Regist->Prmd frame->Generate Frame
    #-------------------------------------------

    set f $FramePrmd.fLevels
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    

    DevAddLabel $f.lStuff ""
    pack $f.lStuff -side top -padx $Gui(pad) -fill x -anchor w
    set DTMRI(reg,lStuff) $f.lStuff

    set f $FramePrmd.fLevelsset
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
 
    eval {label $f.lLevel_max -text "Max Level:"} $Gui(WLA) 
    eval {entry $f.eLevel_max -justify left -width 8 -textvariable DTMRI(reg,Level_max)} $Gui(WEA)
    grid $f.lLevel_max $f.eLevel_max -pady 2 -padx $Gui(pad) -sticky w   
    TooltipAdd $f.eLevel_max  "Enter the maximum level in pyramid."

    eval {label $f.lLevel_min  -text "Min Level:"} $Gui(WLA) 
    eval {entry $f.eLevel_min -justify left -width 8 -textvariable DTMRI(reg,Level_min)} $Gui(WEA)
    grid $f.lLevel_min $f.eLevel_min -pady 2 -padx $Gui(pad) -sticky w   
    TooltipAdd $f.eLevel_min  "Enter the minimum level in pyramid."


    ##########################################################
    #  ADVANCED
    ##########################################################

    #-------------------------------------------
    # Regist->Advanced frame->Title
    #-------------------------------------------
    set f $FrameAdvanced.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Advanced settings"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    #-------------------------------------------
    # Regist->Advanced frame->All the stuff
    #-------------------------------------------

    set f $FrameAdvanced.fAdv
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w


    # constrain for linear registration.    
    eval {label $f.lLR -text "Linear registration:"} $Gui(WLA)
    set DTMRI(reg,LRName) "affine group"
    eval {menubutton $f.mbLR -text "$DTMRI(reg,LRName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbLR.m} $Gui(WMBA)
    eval {menu $f.mbLR.m} $Gui(WMA)
    set DTMRI(reg,mbLR) $f.mbLR
    set m $DTMRI(reg,mbLR).m
    foreach v "{translation} {rigid group} {similarity group} {affine group}" {
       $m add command -label $v -command "DTMRIRegModifyOption LinearRegistration {$v}"
    }
    TooltipAdd $f.mbLR "Choose how to restrict linear registration." 
    #pack $f.lLR $f.mbLR  -padx $Gui(pad) -side left -anchor w   
    grid $f.lLR  $f.mbLR -pady 2 -padx $Gui(pad) -sticky w


    # Criterion
    eval {label $f.lCriterion -text "Criterion:"} $Gui(WLA)
    set DTMRI(reg,CriterionName) "GCR L2 norm"
    eval {menubutton $f.mbCriterion -text "$DTMRI(reg,CriterionName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbCriterion.m} $Gui(WMBA)
    eval {menu $f.mbCriterion.m} $Gui(WMA)
    set DTMRI(reg,mbCriterion) $f.mbCriterion
    set m $DTMRI(reg,mbCriterion).m
    foreach v "{GCR L1 norm} {GCR L2 norm} {Correlation} {mutual information}" {
       $m add command -label $v -command "DTMRIRegModifyOption Criterion {$v}"
    }
    TooltipAdd $f.mbCriterion "Choose the criterion." 
    grid $f.lCriterion $f.mbCriterion   -pady 2 -padx $Gui(pad) -sticky w

    # Scalar measure
    eval {label $f.lScalmeas -text "Linear channel:"} $Gui(WLA)
    set DTMRI(reg,ScalmeasName) "Trace"
    eval {menubutton $f.mbScalmeas -text "$DTMRI(reg,Scalarmeas)" -relief raised -bd 2 -width 15 \
        -menu $f.mbScalmeas.m} $Gui(WMBA)
    eval {menu $f.mbScalmeas.m} $Gui(WMA)
    set DTMRI(reg,mbScalmeas) $f.mbScalmeas
    set m $DTMRI(reg,mbScalmeas).m
    foreach v $DTMRI(scalars,operationList) {
       $m add command -label $v -command "DTMRIRegModifyOption Scalarmeas {$v}"
    }
    TooltipAdd $f.mbScalmeas "Choose the scalar measure to derive from tensors for linear registration." 
    grid $f.lScalmeas $f.mbScalmeas   -pady 2 -padx $Gui(pad) -sticky w

    # Warp channels
    eval {label $f.lChannels -text "Warp channels:"} $Gui(WLA)
    set DTMRI(reg,Channels) "TraceFA"
    eval {menubutton $f.mbChannels -text "$DTMRI(reg,Channels)" -relief raised -bd 2 -width 15 \
        -menu $f.mbChannels.m} $Gui(WMBA)
    eval {menu $f.mbChannels.m} $Gui(WMA)
    set DTMRI(reg,mbChannels) $f.mbChannels
    set m $DTMRI(reg,mbChannels).m

    foreach v "{FractionalAnisotropy} {TraceFA} {TensorComponents}" {
       $m add command -label $v -command "DTMRIRegModifyOption Channels {$v}"
    }
    TooltipAdd $f.mbChannels "Choose channels used in warping, FA (1 channel), Trace and FA (2 channels) or 6 tensor channels." 
    grid $f.lChannels $f.mbChannels   -pady 2 -padx $Gui(pad) -sticky w

# warp and force
#    eval {label $f.lWarp -text "Warp method:"} $Gui(WLA)
#    set DTMRI(reg,WarpName) "demons"
#    eval {menubutton $f.mbWarp -text "$DTMRI(reg,WarpName)" -relief raised -bd 2 -width 15 \
#        -menu $f.mbWarp.m} $Gui(WMBA)
#    eval {menu $f.mbWarp.m} $Gui(WMA)
#    set DTMRI(reg,mbWarp) $f.mbWarp
#    set m $DTMRI(reg,mbWarp).m
#   foreach v "{demons}" {
#       $m add command -label $v -command "DTMRIRegModifyOption Warp {$v}"
#   }
#    TooltipAdd $f.mbWarp "Choose how to warp." 
#    #pack $f.lWarp $f.mbWarp -after $f.lLR  -padx $Gui(pad) -side left -anchor w   
#    grid $f.lWarp $f.mbWarp   -pady 2 -padx $Gui(pad) -sticky w

    # Intensity transformation
    eval {label $f.lIntensityTFM -text "Intensity Transform:"} $Gui(WLA)
    set DTMRI(reg,IntensityTFMName) "mono functional"
    eval {menubutton $f.mbIntensityTFM -text "$DTMRI(reg,IntensityTFMName)" -relief raised -bd 2 -width 15 \
        -menu $f.mbIntensityTFM.m} $Gui(WMBA)
    eval {menu $f.mbIntensityTFM.m} $Gui(WMA)
    set DTMRI(reg,mbIntensityTFM) $f.mbIntensityTFM
    set m $DTMRI(reg,mbIntensityTFM).m
    foreach v "{mono functional} {piecewise median} {no intensity transform}" {
       $m add command -label $v -command "DTMRIRegModifyOption IntensityTFM {$v}"
    }
    TooltipAdd $f.mbIntensityTFM "Choose intensity transform typehow."  
    grid $f.lIntensityTFM $f.mbIntensityTFM   -pady 2 -padx $Gui(pad) -sticky w

    eval {label $f.lEstimateBias -text "Bias:"} $Gui(WLA)
    eval {checkbutton $f.cEstimateBias \
        -text  "Estimate Bias" -variable DTMRI(reg,Use_bias) \
        -width 15  -indicatoron 0 } $Gui(WCA)
    grid $f.lEstimateBias $f.cEstimateBias  -pady 2 -padx $Gui(pad) -sticky w
    TooltipAdd $f.cEstimateBias "Press to set/unset to estimate bias with intensity transformation."

    eval {label $f.lDegree -text "Degree:"} $Gui(WLA) 
    eval {entry $f.eDegree -justify right -width 6 -textvariable DTMRI(reg,Degree)} $Gui(WEA)
    grid $f.lDegree $f.eDegree -pady 2 -padx $Gui(pad) -sticky w   
    TooltipAdd $f.eDegree  "Enter the degree of polynomials in intensity transformation."

    eval {label $f.lRatio -text "Ratio of points:"} $Gui(WLA) 
    eval {entry $f.eRatio -justify right -width 6 -textvariable DTMRI(reg,Ratio)} $Gui(WEA)
    grid $f.lRatio $f.eRatio -pady 2 -padx $Gui(pad) -sticky w   
    TooltipAdd $f.eRatio  "Enter the ratio of points used for polynomial estimate in intensity transformation."

    eval {label $f.lNb_of_functions -text "Number of functions:"} $Gui(WLA) 
    eval {entry $f.eNb_of_functions -justify right -width 6 -textvariable DTMRI(reg,Nb_of_functions)} $Gui(WEA)
    grid $f.lNb_of_functions $f.eNb_of_functions -pady 2 -padx $Gui(pad) -sticky w   
    TooltipAdd $f.eNb_of_functions  "Enter the number of intensity transformation functions."

    eval {label $f.lEpsilon -text "Epsilon:"} $Gui(WLA) 
    eval {entry $f.eEpsilon -justify right -width 6 -textvariable DTMRI(reg,Epsilon)} $Gui(WEA)
    grid $f.lEpsilon $f.eEpsilon -pady 2 -padx $Gui(pad) -sticky w   
    TooltipAdd $f.eEpsilon  "Enter the maximum SSD value between successive iterations ."

    set f $FrameAdvanced.fIter
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 0 -fill x -anchor w
  
    eval {label $f.lIteration_min -text "Iteration min-max:   "} $Gui(WLA) 
    eval {entry $f.eIteration_min -justify right -width 6 -textvariable DTMRI(reg,Iteration_min)} $Gui(WEA)
    pack $f.lIteration_min $f.eIteration_min -pady 0 -padx $Gui(pad) -side left 
    TooltipAdd $f.eIteration_min  "Enter the number of minumum iterations at each level."
     
    eval {entry $f.eIteration_max -justify right -width 6 -textvariable DTMRI(reg,Iteration_max)} $Gui(WEA)
    pack $f.eIteration_max -pady 0 -padx $Gui(pad) -side left
    TooltipAdd $f.eIteration_max  "Enter the number of maxmimum iterations at each level."

    set f $FrameAdvanced.fStddev
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -anchor w
    eval {label $f.lStddev_min -text "Stddev. min-max:    "} $Gui(WLA) 
    eval {entry $f.eStddev_min -justify right -width 6 -textvariable DTMRI(reg,Stddev_min)} $Gui(WEA)
    pack $f.lStddev_min $f.eStddev_min -padx $Gui(pad) -pady 2 -side left   
    TooltipAdd $f.eStddev_min  "Enter the minimum standard deviation of displacement field smoothing kernel ."

    eval {label $f.lStddev_max} $Gui(WLA) 
    eval {entry $f.eStddev_max -justify right -width 6 -textvariable DTMRI(reg,Stddev_max)} $Gui(WEA)
    pack $f.eStddev_max -padx $Gui(pad) -pady 2 -side left   
    TooltipAdd $f.eStddev_max  "Enter the maximum standard deviation of displacement field smoothing kernel."
  
    #-------------------------------------------
    # Regist->Help frame->Title
    #-------------------------------------------
    set f $FrameHelp.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    DevAddLabel $f.lnumber "Help  "
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side left -padx $Gui(pad) -pady $Gui(pad) -anchor w

    eval {radiobutton $f.rIntro -text Intro -value 0 -variable DTMRI(reg,Help) -command {DTMRIRegHelpUpdate 0} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 5}
    pack $f.rIntro -side left -padx 0 -pady 0
    eval {radiobutton $f.rMain -text Main -value 1 -variable DTMRI(reg,Help) -command {DTMRIRegHelpUpdate 0} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 5}
    pack $f.rMain -side left -padx 0 -pady 0
    eval {radiobutton $f.rTfm -text Tfm -value 2 -variable DTMRI(reg,Help) -command {DTMRIRegHelpUpdate 0} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 5}
    pack $f.rTfm -side left -padx 0 -pady 0
    eval {radiobutton $f.rPrmd -text Prmd -value 3 -variable DTMRI(reg,Help) -command {DTMRIRegHelpUpdate 0} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 5}
    pack $f.rPrmd -side left -padx 0 -pady 0
    eval {radiobutton $f.rAdv -text Adv -value 4 -variable DTMRI(reg,Help) -command {DTMRIRegHelpUpdate 0} -indicatoron 0} $Gui(WCA) {-bg $Gui(activeWorkspace) -selectcolor $Gui(activeWorkspace) -width 5}
    pack $f.rAdv -side left -padx 0 -pady 0
    TooltipAdd $f.rIntro "Get general info about this module."
    TooltipAdd $f.rMain "Get help on the main tab."
    TooltipAdd $f.rTfm "Get help on the transforms tab."
    TooltipAdd $f.rPrmd "Get help on the pyramid tab."
    TooltipAdd $f.rAdv "Get help on the advanced tab."

    set f $FrameHelp.fText
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady 2 -fill x -anchor w
    
    eval {label $f.lText -text $DTMRI(reg,InitialHelpText) -justify left} $Gui(WLA)
    set DTMRI(reg,HelpText) $f.lText
    pack $f.lText -side top -padx $Gui(pad) -pady 2 -anchor w

    # This invokes updating of the prmd tab whenever a never targetvol is selected
    trace variable DTMRI(InputTensorTarget) w DTMRIPrmdSetup

}


#-------------------------------------------------------------------------------
# .PROC DTMRIRegModifyOptions
#  Modify the options for registration according to the user 
#  selection
# .ARGS
# string optClass
# int value
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegModifyOptions {optClass value} {
    global  DTMRI Volume Gui Tensor
  
    switch $optClass {
        LinearRegistration  { 
            set DTMRI(reg,LRName)  $value
            $DTMRI(reg,mbLR) config -text $DTMRI(reg,LRName)
            
            switch $value {
                "translation" { 
                    set DTMRI(reg,Linear_group) -1
                    puts "translation"
                }
                "rigid group" {
                    set DTMRI(reg,Linear_group) 0
                    puts "rigid group"
                    
                }
                "similarity group" {
                    set DTMRI(reg,Linear_group) 1
                    puts "similarity group"
                }
                "affine group" {
                    set DTMRI(reg,Linear_group) 2
                    puts "affine group"
                    puts "DTMRI(SSD) is $DTMRI(reg,SSD)"
                    puts "DTMRI(reg,Scale) is $DTMRI(reg,Scale)"
                }
                default {
                    set DTMRI(reg,Linear) 1
                    set DTMRI(reg,Linear_group) 2
                }
            }  
        }
        Warp {
            
            set DTMRI(reg,WarpName)  $value
            $DTMRI(reg,mbWarp) config -text $DTMRI(reg,WarpName)
            switch $value {
                "demons" {
                    set DTMRI(reg,Warp)  1
                    set DTMRI(reg,Force) 1
                }
                "optical flow" {
                    set DTMRI(reg,Warp)  1
                    set DTMRI(reg,Force) 2
                }
                default {
                    set DTMRI(reg,Warp)  1
                    set DTMRI(reg,Force) 1  
                }
            }
        }
        
        IntensityTFM {
            
            set DTMRI(reg,IntensityTFMName)  $value
            $DTMRI(reg,mbIntensityTFM) config -text $DTMRI(reg,IntensityTFMName)
            switch $value {
                "no intensity transform" {
                    set  DTMRI(reg,Intensity_tfm) "none"
                }
                "mono functional" {
                    set DTMRI(reg,Intensity_tfm)  "mono functional"
                    
                }
                "piecewise median" {
                    set DTMRI(reg,Intensity_tfm)  "piecewise median"
                    
                }
                default {
                    set DTMRI(reg,Intensity_tfm)  "mono functional"
                    
                }
            }
        }
        
        Criterion {
            
            set DTMRI(reg,CriterionName)  $value
            $DTMRI(reg,mbCriterion) config -text $DTMRI(reg,CriterionName)
            switch $value {
                "GCR L1 norm" {
                    set  DTMRI(reg,Gcr_criterion) 1
                }
                "GCR L2 norm" {
                    set DTMRI(reg,Gcr_criterion)  2
                    
                }
                "Correlation" {
                    set DTMRI(reg,Gcr_criterion)  3

                }
                
                "mutual information" {
                    set DTMRI(reg,Gcr_criterion)  4
                    
                }
                default {
                    set DTMRI(reg,Gcr_criterion)  2
                    
                }
            }
        }
        
        Scalarmeas {
            set DTMRI(reg,Scalarmeas) $value
            $DTMRI(reg,mbScalmeas) config -text $DTMRI(reg,Scalarmeas)
        }
        
        Channels {
        set DTMRI(reg,Channels) $value
        $DTMRI(reg,mbChannels) config -text $DTMRI(reg,Channels)
    }
    
        Verbose {
            set DTMRI(reg,VerboseName)  $value
            $DTMRI(reg,mbVerbose) config -text $DTMRI(reg,VerboseName)
            set  DTMRI(reg,Verbose)  $value
        }
    }
    return
}
#end  DTMRIRegModifyOption

#-------------------------------------------------------------------------------
# .PROC DTMRIRegCheckErrors
#   Check for Errors in the setup
#   returns 1 if there are errors, 0 otherwise
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegCheckErrors {} {
    global DTMRI Volume Tensor
    if {  ($DTMRI(InputTensorSource) == $Tensor(idNone)) || \
        ($DTMRI(InputTensorTarget) == $Tensor(idNone)) || \
        ($DTMRI(ResultTensor)   == $Tensor(idNone))}  {
    DevErrorWindow "You cannot use Volume \"None\" for input or output"
    return 1
    }

    if {  ($DTMRI(InputTensorSource) == $DTMRI(ResultTensor)) || \
        ($DTMRI(InputTensorTarget) == $DTMRI(ResultTensor))}  {
        DevErrorWindow "You cannot use one of the input Volumes as the result Volume"
        return 1
    }
    
    set extent_arr [[Tensor($DTMRI(InputTensorSource),data) GetOutput] GetExtent]
    set spacing [[Tensor($DTMRI(InputTensorSource),data) GetOutput] GetSpacing]
    if { ([lindex $extent_arr 1] < 0) || ([lindex $extent_arr 3] < 0) || ([lindex $extent_arr 5] < 0)   } {
    DevErrorWindow "Source is not correct or empty"
    Source Delete
    Target Delete
    return 1
    }
    set extent_arr [[Tensor($DTMRI(InputTensorTarget),data) GetOutput] GetExtent]
    set spacing [[Tensor($DTMRI(InputTensorTarget),data) GetOutput] GetSpacing]
    if { ([lindex $extent_arr 1] < 0) || ([lindex $extent_arr 3] < 0) || ([lindex $extent_arr 5] < 0)   } {
    DevErrorWindow "Target is not correct or empty"
    Target Delete
    Source Delete
    return 1
    }

    # Check size of masks
    if {$DTMRI(TargetMaskVol) != $Volume(idNone)} {
      set maskdims  [[Volume($DTMRI(TargetMaskVol),vol) GetOutput] GetDimensions]
      set dims [[Tensor($DTMRI(InputTensorTarget),data) GetOutput] GetDimensions]

      for {set  f  0}  {$f < 3} {incr f} {
    if {[lindex $maskdims $f]!=[lindex $dims $f]} {
      DevErrorWindow "Target mask and target tensor volume are of different size"
      return 1
    }
      }
    }
    if {$DTMRI(SourceMaskVol) != $Volume(idNone)} {
      set maskdims  [[Volume($DTMRI(SourceMaskVol),vol) GetOutput] GetDimensions]
      set dims [[Tensor($DTMRI(InputTensorSource),data) GetOutput] GetDimensions]

      for {set  f  0}  {$f < 3} {incr f} {
    if {[lindex $maskdims $f]!=[lindex $dims $f]} {
      DevErrorWindow "Source mask and source tensor volume are of different size"
      return 1
    }
      }
    }
    
    # Let user confirm registration if pyramid level 0 is selected 
    # with 256^2 data and non-linear registration
    #set dims [[Tensor($DTMRI(InputTensorTarget),data) GetOutput] GetDimensions]
    
    #if {($DTMRI(reg,Level_min)<1) && ([lindex $dims 0]>128) && $DTMRI(reg,Warp)} {
    #  switch [DevYesNo "You included level 0 of the Pyramid (see Prmd tab), which will take long computation time because of the in-plane resolution of [lindex $dims 0]. Do you want to continue?"] {
    #    "no" { return 1 }}
    #}
    
    return 0
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegDeformationVolume
#  Export the grid transform deformation to slicer's mrml tree for use
#  with the TransformVolume module
#  .END
#-------------------------------------------------------------------------------
proc DTMRIRegDeformationVolume {}  {
     global DTMRI Volume Tensor Slice

    if { [info command warp] == "" } {
        DevErrorWindow "No Grid Transform yet"
        return
    }

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i
    
    # set the name and description of the volume
    $n SetName Deformation
    $n SetDescription "Deformation volume"

    set id "warp_image"
    catch "$id Delete"
    vtkImageData  $id
    $id DeepCopy [warp GetDisplacementGrid]
    
    ::Volume($i,node) SetNumScalars 3
    ::Volume($i,node) SetScalarType [$id GetScalarType]
    
    eval ::Volume($i,node) SetSpacing [$id GetSpacing]
    
    ::Volume($i,node) SetScanOrder LR
    ::Volume($i,node) SetDimensions [lindex [$id GetDimensions] 0] [lindex [$id GetDimensions] 1]
    ::Volume($i,node) SetImageRange 1 [lindex [$id GetDimensions] 2]
    
    ::Volume($i,node) ComputeRasToIjkFromScanOrder [::Volume($i,node) GetScanOrder]
    ::Volume($i,vol) SetImageData $id
    $id Delete
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegPrepareResultVolume
#  Create the New Volume if necessary. Otherwise, ask to overwrite.
#   returns 1 if there is are errors 0 otherwise
#  .END
#-------------------------------------------------------------------------------
proc DTMRIRegPrepareResultVolume {}  {
     global DTMRI Volume Tensor Slice
   
    #Make or Copy the result volume node from target volume ( but should keep
    # the win, level setting).
    set t1 $DTMRI(InputTensorTarget)
    set t2 $DTMRI(ResultTensor)
    
    # Do we need to Create a New Tensor?
    # If so, let's do it.
    
    if {$t2 == -5} {
    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol Copy Tensor($t1,node)
    $newvol SetDescription "DTMRI volume"
    set name "Result_$DTMRI(reg,CountNewResults)"
    append name "-Tensor"
    $newvol SetName $name
    set t2 [$newvol GetID]
    
    #MainDataCreate Tensor $t2 Volume
    TensorCreateNew $t2 
    #Tensor($t2,data) SetImageData [Tensor($t1,data) GetOutput]
        
        #set t2 [DevCreateNewCopiedVolume $t1 ""  "ResTensor_$DTMRI(reg,CountNewResults)"]
    #set node [Tensor($t2,data) GetMrmlNode]
    #Mrml(dataTree) RemoveItem $node
    #set nodeBefore [Tensor($t1,data) GetMrmlNode]
    #Mrml(dataTree) InsertAfterItem $nodeBefore $node
    set DTMRI(ResultTensor) $t2
    
    incr DTMRI(reg,CountNewResults)

    #MainDataSetActive Tensor $t2
    DTMRISetActive $t2
    
    } else {
        # Are We Overwriting a volume?
        # If so, let's ask. If no, return.
    
        set t2name  [Tensor($t2,node) GetName]
        set continue [DevOKCancel "Overwrite $t2name?"]
          
        if {$continue == "cancel"} { return 1 }
        # They say it is OK, so overwrite!
              
        Tensor($t2,node) Copy Tensor($t1,node)
    }    

    if {!$DTMRI(reg,Scope)} {
      set ras [Tensor($DTMRI(ResultTensor),node) GetRasToVtkMatrix]
      set ras2 [lindex $ras 0]
      for {set i 1} {$i<16} {incr i} {
        if {$i==11} {
          if {($DTMRI(reg,scanorder)=="IS")||($DTMRI(reg,scanorder)=="SI")} {
         lappend ras2 [expr -$Slice(0,offset)*[lindex $ras 10]]
          }          
          if {($DTMRI(reg,scanorder)=="LR")||($DTMRI(reg,scanorder)=="RL")} {
             lappend ras2 [expr -$Slice(1,offset)*[lindex $ras 8]]
      }          
          if {($DTMRI(reg,scanorder)=="AP")||($DTMRI(reg,scanorder)=="PA")} {
         lappend ras2 [expr -$Slice(2,offset)*[lindex $ras 9]]
      }          
    } else {
      lappend ras2 [lindex $ras $i]
    }
      }
      Tensor($DTMRI(ResultTensor),node) SetRasToVtkMatrix $ras2
    }
    MainUpdateMRML
    return 0
}

#-------------------------------------------------------------------------------
# .PROC DTMRIWritevtkImageData
# Write vtkImageData to file using the vtkStructuredPointWriter
#
#-----------------------------------------------------------------------------
proc DTMRIWritevtkImageData {image filename} {

    global DTMRI
    catch "writer Delete"
    vtkStructuredPointsWriter  writer
    if {$DTMRI(reg,Debug) == 1} {
    writer DebugOn
    }
    writer SetFileTypeToBinary
    writer SetInput  $image
    writer SetFileName $filename
    writer Write
    writer Delete
}




#-------------------------------------------------------------------------------
# .PROC DTMRIRegIntensityTransform
# According to the options, set the intensity transformation. 
#  
# .END
#------------------------------------------------------------------------------
proc DTMRIRegIntensityTransform {Source} {
    global DTMRI Volume Tensor

    catch {$DTMRI(reg,inttfm) Delete}
    switch $DTMRI(reg,Intensity_tfm) {
      "mono-functional"  {
          puts "$DTMRI(reg,Intensity_tfm)==mono-functional is true"
          catch "tfm Delete"
      vtkLTSPolynomialIT tfm
          tfm SetDegree $DTMRI(reg,Degree)
          tfm SetRatio $DTMRI(reg,Ratio)  
          tfm SetNumberOfFunctions $DTMRI(reg,Nb_of_functions)
          if { $DTMRI(reg,Use_bias) == 1 } {
             tfm UseBiasOn
          }
          set DTMRI(reg,inttfm) tfm
          return 0
      }
      "piecewise-median" {
          puts " intensity+tfm is piecewise-median"
          catch "tfm Delete"
      vtkPWMedianIT tfm
          if {([llength $DTMRI(reg,Nb_of_pieces)] == 0) && ($DTMRI(reg,Boundaries) == 0)} { 
            $Source  Update
            set low_high [$Source  GetScalarRange]
            set low [lindex $low_high 0]
            set high [lindex $low_high 1]
            for {set index 0} {$index < $DTMRI(reg,Nb_of_functions)} {incr index} {
              lappend DTMRI(reg,Nb_of_pieces) [expr $high-$low+1]
            }
         
            for {set index2 $low+1} {$index2 < $hight+1} {incr index2} {
               lappend DTMRI(reg,Boundaries) $index2
            }
          }
   
          set nf $DTMRI(reg,Nb_of_functions)
          set np $DTMRI(reg,Nb_of_pieces)
          set bounds $DTMRI(reg,Boundaries)
          if {( [llength $np] == 0) || ( [llength $np] != $nf)} {
             #raise Exception
             puts "length of number of pieces doesn\'t match number of functions"
             return 1
          }
       
          tfm SetNumberOfFunctions $nf
          for {set  f  0}  {$f < $nf} {incr f} {
            tfm SetNumberOfPieces {$f [lindex $np $f]}
            set i 0
            for {set p 0} {$p <  [lindex $np $f]-1} {incr p}{
              tfm SetBoundary {$f $p [lindex $bounds $i]}
              incr i
            }
          }  
          set DTMRI(reg,inttfm) tfm
          return 0
      }

      "none" {
         #set tfm None
         return 1

      }

      default  {
           puts "unknown intensity tfm type: $DTMRI(reg,Intensity_tfm)"
           #raise exception
           #set tfm None
           return 1

      }
  }    
  
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegTransformScale
# According to the options, do the scale transformation. 
#  
# .END
#------------------------------------------------------------------------------
proc DTMRIRegTransformScale { Source Target} {
#def TransformScale(Target,Source,scale):   
   #    log=vtkImageMathematics()
   #    log.SetOperationToLog()
   #    log.SetInput1(cast.GetOutput())
   global DTMRI Volume Tensor

   if { $DTMRI(reg,Scale) <= 0} {
    return 0
   }
   catch "div Delete"
   vtkImageMathematics div
   div SetOperationToMultiplyByK
   div SetConstantK  $DTMRI(reg,Scale)
   div SetInput 0 $Target
   div SetInput 1 $Target
# [Volume($DTMRI(reg,InputVolTarget),vol) GetOutput]
   div Update
  # [Volume($DTMRI(reg,InputVolTarget),vol) GetOutput] DeepCopy [div GetOutput]
  $Target  DeepCopy [div GetOutput]  
 # or Volume($DTMRI(reg,InputVolTarget),vol) SetImageData [div GetOutput] , but maybe they share the same copy of data.

   div Delete
   catch "div2 Delete"
   vtkImageMathematics div2
   div2 SetOperationToMultiplyByK
   div2 SetConstantK $DTMRI(reg,Scale)
  # div2 SetInput1  [Volume($DTMRI(reg,InputVolSource),vol) GetOutput]
   
   div2 SetInput 0  $Source
   div2 SetInput 1  $Source
   div2 Update
   #[Volume($DTMRI(reg,InputVolSource),vol) GetOutput] DeepCopy [div2 GetOutput]
   $Source  DeepCopy [div2 GetOutput]
   div2 Delete
   return 1
}


#-------------------------------------------------------------------------------
# .PROC DTMRIRegWriteHomogeneous
# 
# .ARGS
# int t
# int ii
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegWriteHomogeneous {t ii} {
    global DTMRI
    
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

    # mat_copy is vtk_to_vtk transform, we want world_to_world
    catch "ModelRasToVtk Delete"
    vtkMatrix4x4 ModelRasToVtk
    set position [Tensor($DTMRI(InputTensorTarget),node) GetPositionMatrix]
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
            #puts $fileid  "  $one_element "
    }
   # puts $fileid "\n"
    }
 
    puts " m is $m"
    puts " str is ---$str"
   
    # SetMatrix $str
    puts " finish saving homogeneous Transform"
    MainUpdateMRML
    DevInfoWindow "Matrix $m generated."
} 

#-------------------------------------------------------------------------------
# .PROC DTMRIRegWriteGrid
# 
# .ARGS
# int t
# int ii
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegWriteGrid {t ii} {      

    set g [$t GetDisplacementGrid]
    if { $g == 0}  return

    set fname [tk_getSaveFile -defaultextension ".vtk" -title "Save non-linear transform"]
    if { $fname == "" } {
    return 0
    }

    DTMRIWritevtkImageData $g  $fname
    return 1
}




#-------------------------------------------------------------------------------
# .PROC DTMRIRegRun
#  Run the Registration.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegRun {} {

  global DTMRI Volume Gui Tensor Slice AG Matrix

  set intesity_transform_object 0

  # Do nothing if no linear, warp, or initial transform.
  if {(!$DTMRI(reg,Initial_lin))&&(!$DTMRI(reg,Initial_grid))&&(!$DTMRI(reg,Initial_prev))&&(!$DTMRI(reg,Initial_AG))} {
    set DTMRI(reg,Initial_tfm) 0
  } else {
    set DTMRI(reg,Initial_tfm) 1
  }
  if {!(($DTMRI(reg,Linear) || $DTMRI(reg,Warp)) || $DTMRI(reg,Initial_tfm))} {
    DevInfoWindow "all work and no play makes jack a dull boy"
    return
  }

  puts "DTMRIRegRun 1: Check Error"
  
  if {[DTMRIRegCheckErrors]} {return}

  puts "DTMRIRegRun 2: Prepare Result Volume"

  if {[DTMRIRegPrepareResultVolume]} {return}

  catch "Target Delete"
  catch "Source Delete"

  vtkImageData Target
  vtkImageData Source

  if {$DTMRI(reg,Scale) > 0 } {
       DTMRIRegTransformScale Source Target 
  }


  if {[info exist DTMRI(reg,Transform)]} {
      if {!($DTMRI(reg,Initial_prev))} {
          catch "TransformDTMRI Delete"
          catch {$DTMRI(reg,Transform) Delete}
          vtkGeneralTransform TransformDTMRI
      }
  } else {
      if {$DTMRI(reg,Initial_prev)} {
        DevErrorWindow "Previous computed transform as initial transform requested, but not available."
    return
      }
      catch "TransformDTMRI Delete"
      vtkGeneralTransform TransformDTMRI
  }
  

  if {$DTMRI(reg,Initial_tfm)} {      
      puts "Initial Transform"
      # A previous transf might exist, so set PreMultiply and add Grid and Linear,
      # then set PostMultiply, so we have Linear->Grid->Previous_lin->Previous_grid
      TransformDTMRI PreMultiply
      if {$DTMRI(reg,Initial_grid)} {
          catch "wrp Delete"
          vtkImageData wrp
          catch "grd Delete"
          vtkGridTransform grd

          if {![DTMRIReadvtkImageData wrp $DTMRI(regInitGridTfmName)]} {
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
          TransformDTMRI Concatenate grd
          grd Delete
          wrp Delete
      }
      
      if {$DTMRI(reg,Initial_lin)} {
          catch "ModelRasToVtk Delete"
          vtkMatrix4x4 ModelRasToVtk
          set position [Tensor($DTMRI(InputTensorTarget),node) GetPositionMatrix]
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

      TransformDTMRI Concatenate Linear
          ModelRasToVtk Delete
          Ras1ToRas2 Delete
          RasToVtk Delete
          InvRasToVtk Delete
          Vtk1ToVtk2 Delete
      Linear Delete
      }
      TransformDTMRI PostMultiply

      if {$DTMRI(reg,Initial_AG)} {
          if {[info exist AG(Transform)]} {
        set nrtrans [TransformAG GetNumberOfConcatenatedTransforms]
        for {set i 0} {$i < $nrtrans} {incr i} {
          TransformDTMRI Concatenate [TransformAG GetConcatenatedTransform $i]
        }
      } else {
        DevErrorWindow "AG Transformation does not exist. Please compute first."
        return
      }
      }      
      
      set  DTMRI(reg,Inentisy_transform) 1
  } else {
      puts "No initial transform"
      TransformDTMRI PostMultiply 
      set  DTMRI(reg,Inentisy_transform) 0
  }


  if {$DTMRI(reg,Linear)} {
      puts "6. Linear registration"
      if { [info commands __dummy_transform] == ""} {
              vtkTransform __dummy_transform
      }
      
      catch "GCR Delete"
      vtkImageGCR GCR
      GCR SetVerbose $DTMRI(reg,Verbose)

      # Do linear registration based on given tensor derived scalar channel
      catch "math Delete"
      vtkTensorMathematics math
      #math SetScaleFactor $DTMRI(reg,scalars,scaleFactor)
      math SetInput 0 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
      math SetInput 1 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
      math SetOperationTo$DTMRI(reg,Scalarmeas)
      math Update
      if {($DTMRI(TargetMaskVol)!=$Volume(idNone))} {
        catch "mask Delete"
    vtkImageMask mask
    catch "shift Delete"
    vtkImageShiftScale shift
    mask SetImageInput [math GetOutput]
    shift SetInput [Volume($DTMRI(TargetMaskVol),vol) GetOutput]
    shift SetOutputScalarTypeToUnsignedChar
    mask SetMaskInput [shift GetOutput]
    mask Update
    Target DeepCopy [mask GetOutput]
      } else {
        Target DeepCopy [math GetOutput]
      }    

      catch "math Delete"
      vtkTensorMathematics math
      #math SetScaleFactor $DTMRI(reg,scalars,scaleFactor)
      math SetInput 0 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
      math SetInput 1 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
      math SetOperationTo$DTMRI(reg,Scalarmeas)
      math Update
      if {($DTMRI(SourceMaskVol)!=$Volume(idNone))} {
        catch "mask Delete"
    vtkImageMask mask
    catch "shift Delete"
    vtkImageShiftScale shift
        mask SetImageInput [math GetOutput]
    shift SetInput [Volume($DTMRI(SourceMaskVol),vol) GetOutput]
    shift SetOutputScalarTypeToUnsignedChar
    mask SetMaskInput [shift GetOutput]
        mask Update
    Source DeepCopy [mask GetOutput]
    mask Delete
    shift Delete
      } else {
        Source DeepCopy [math GetOutput]
      }    

      # Preprocessing resamples source to target frame and applies initial tfm
      puts "Preprocessing source and target..."
      DTMRIRegPreprocess Source Target $DTMRI(InputTensorSource)  $DTMRI(InputTensorTarget) 
      puts "done."
      
      GCR SetTarget Target
      GCR SetSource Source
      
      math Delete
      GCR PostMultiply      

      # It seems that the following line will result in error, the affine matrix used in the resampling and writing is only
      # identical matrix.
      
      # Initial transform is handled in preprocessing, so commented here
      
      GCR SetInput  __dummy_transform  
      [GCR GetGeneralTransform] SetInput TransformDTMRI
      
      GCR SetCriterion $DTMRI(reg,Gcr_criterion)
      GCR SetTransformDomain $DTMRI(reg,Linear_group)
      GCR SetTwoD $DTMRI(reg,2D)
      
      GCR Update     
      TransformDTMRI Concatenate [[GCR GetGeneralTransform] GetConcatenatedTransform 0]
  }

  if {$DTMRI(reg,Warp)} {
      puts "7. Starting warp..."
      puts "7a. Starting channel extraction..."
      switch $DTMRI(reg,Channels) {
          "FractionalAnisotropy" {
          # Warp using FA as channel, no tensor reorientation needed
          catch "math Delete"
          vtkTensorMathematics math
          if {($DTMRI(TargetMaskVol)!=$Volume(idNone))} {
            #mask SetScalarMask [Volume($DTMRI(TargetMaskVol),vol) GetOutput]
            #mask MaskWithScalarsOn
          }
          #math SetScaleFactor $DTMRI(reg,scalars,scaleFactor)
          math SetInput 0 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
          math SetInput 1 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
          #math SetOperationTo$DTMRI(reg,Scalarmeas)
          math SetOperationToFractionalAnisotropy
          math Update
          Target DeepCopy [math GetOutput]

          catch "math Delete"
          vtkTensorMathematics math
          if {($DTMRI(SourceMaskVol)!=$Volume(idNone))} {
            #math SetScalarMask [Volume($DTMRI(SourceMaskVol),vol) GetOutput]
            #math MaskWithScalarsOn
          }
          math SetOperationToFractionalAnisotropy
          math SetInput 0 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
          math SetInput 1 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
          math Update
          Source DeepCopy [math GetOutput]
          math Delete
          #setT Delete
      }
      "TraceFA" {
          # Warp using Westin's measures Cl Cp Cs as channels
          # No tensor reorientation needed
          catch "appcomp Delete"
          vtkImageAppendComponents appcomp
          catch "math Delete"
          vtkTensorMathematics math
          # Do not mask Trace because of high signal in ventricles
      math SetOperationToTrace
          math SetScaleFactor 1000
          math SetInput 0 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
          math SetInput 1 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
          math Update
          appcomp SetInput 0 [math GetOutput]
          appcomp Update
          catch "math Delete"
          vtkTensorMathematics math
          if {($DTMRI(TargetMaskVol)!=$Volume(idNone))} {
            math SetScalarMask [Volume($DTMRI(TargetMaskVol),vol) GetOutput]
            math MaskWithScalarsOn
          }

          math SetOperationToFractionalAnisotropy
          math SetScaleFactor 1000
          math SetInput 0 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
          math SetInput 1 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
          math Update
          appcomp SetInput 2 [math GetOutput]
          appcomp Update
          Target DeepCopy [appcomp GetOutput]

          # SOURCE
      catch "appcomp Delete"
          vtkImageAppendComponents appcomp
          catch "math Delete"
          vtkTensorMathematics math
          math SetOperationToTrace
          math SetScaleFactor 1000
          math SetInput 0 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
          math SetInput 1 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
          math Update
          appcomp SetInput 0 [math GetOutput]
          appcomp Update
          catch "math Delete"
          vtkTensorMathematics math
          if {($DTMRI(SourceMaskVol)!=$Volume(idNone))} {
            math SetScalarMask [Volume($DTMRI(SourceMaskVol),vol) GetOutput]
            math MaskWithScalarsOn
          }
          math SetOperationToFractionalAnisotropy
          math SetScaleFactor 1000
          math SetInput 0 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
          math SetInput 1 [Tensor($DTMRI(InputTensorSource),data) GetOutput]
          math Update
          appcomp SetInput 1 [math GetOutput]
          appcomp Update
          Source DeepCopy [appcomp GetOutput]

          appcomp Delete
          math Delete
      }
      "TensorComponents" {
          # Warp using 6 tensor channels, including tensor reorientation

      catch "extractT  Delete"
      vtkImageGetTensorComponents extractT     
      extractT SetInput [Tensor($DTMRI(InputTensorSource),data) GetOutput] 
      extractT Update
      if {($DTMRI(SourceMaskVol)!=$Volume(idNone))} {
            catch "mask Delete"
        vtkImageMask mask
        catch "shift Delete"
        vtkImageShiftScale shift
            mask SetImageInput [extractT GetOutput]
        shift SetInput [Volume($DTMRI(SourceMaskVol),vol) GetOutput]
        shift SetOutputScalarTypeToUnsignedChar
        mask SetMaskInput [shift GetOutput]
            mask Update
        Source DeepCopy [mask GetOutput]
        mask Delete
        shift Delete
      } else {
          Source DeepCopy [extractT GetOutput]
      }    
      extractT Delete

      vtkImageGetTensorComponents extractT     
      extractT SetInput [Tensor($DTMRI(InputTensorTarget),data) GetOutput] 
      extractT Update
      if {($DTMRI(TargetMaskVol)!=$Volume(idNone))} {
            catch "mask Delete"
        vtkImageMask mask
        catch "shift Delete"
        vtkImageShiftScale shift
            mask SetImageInput [extractT GetOutput]
        shift SetInput [Volume($DTMRI(TargetMaskVol),vol) GetOutput]
        shift SetOutputScalarTypeToUnsignedChar
        mask SetMaskInput [shift GetOutput]
            mask Update
        Target DeepCopy [mask GetOutput]
        mask Delete
        shift Delete
      } else {
          Target DeepCopy [extractT GetOutput]
      }    
      extractT Delete

      }
      }
      puts "done."

      puts "Preprocessing source and target..."
      DTMRIRegPreprocess Source Target $DTMRI(InputTensorSource)  $DTMRI(InputTensorTarget) 
      puts "done."

      catch "warp Delete"
      vtkImageWarp warp
      
      warp SetSource Source
      warp SetTarget Target
      
      if {$DTMRI(reg,Channels)=="TensorComponents"} {
        # TODO set to 1
        warp SetResliceTensors 1
      } else {
        warp SetResliceTensors 0
      }

      #if { ($DTMRI(MaskVol)   != $Volume(idNone)) } {
      #    catch "Mask Delete"
      #    vtkImageData Mask
      #    Mask DeepCopy  [ Volume($DTMRI(MaskVol),vol) GetOutput]
      #    warp SetMask Mask
      #}
      
      # Set the options for the warp
      warp SetVerbose $DTMRI(reg,Verbose)
      [warp GetGeneralTransform] SetInput TransformDTMRI
      warp SetForceType $DTMRI(reg,Force)   
      warp SetMinimumIterations  $DTMRI(reg,Iteration_min) 
      warp SetMaximumIterations $DTMRI(reg,Iteration_max)  
      warp SetMinimumLevel $DTMRI(reg,Level_min)  
      warp SetMaximumLevel $DTMRI(reg,Level_max)  
      warp SetUseSSD $DTMRI(reg,SSD)    
      warp SetSSDEpsilon  $DTMRI(reg,Epsilon)    
      warp SetMinimumStandardDeviation $DTMRI(reg,Stddev_min) 
      warp SetMaximumStandardDeviation $DTMRI(reg,Stddev_max) 
 
      if {[DTMRIRegIntensityTransform Source] == 0 } {
      warp SetIntensityTransform $DTMRI(reg,inttfm)
      set intesity_transform_object 1
          
      }  else  {
      set intesity_transform_object 0
      }
      #DTMRIWritevtkImageData Source "source.vtk"
      #DTMRIWritevtkImageData Target "target.vtk"
      warp Update
      TransformDTMRI Concatenate warp
  }
  # end warp
  if {$DTMRI(reg,Debug)} {
      if {$DTMRI(reg,Warp)} {
      
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
  catch "warp Delete"
  Target Delete
  Source Delete
  
  vtkImageData Source
  vtkImageData Target
  #Target2 DeepCopy [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
  #Source2 DeepCopy [Tensor($DTMRI(InputTensorSource),data) GetOutput]

  catch "extractT  Delete"
  vtkImageGetTensorComponents extractT     
  extractT SetInput [Tensor($DTMRI(InputTensorSource),data) GetOutput] 
  extractT Update
  Source DeepCopy [extractT GetOutput]
  extractT Delete

  vtkImageGetTensorComponents extractT     
  extractT SetInput [Tensor($DTMRI(InputTensorTarget),data) GetOutput] 
  extractT Update
  Target DeepCopy [extractT GetOutput]
  extractT Delete
  #Target2 Delete
  #Source2 Delete
  
  puts "Moving Source-tensorfield to Target frame of reference..."
  # Temporarily set initial_tfm off, because RegResample will also apply it
  set previous_initial_tfm $DTMRI(reg,Initial_tfm)
  set DTMRI(reg,Initial_tfm) 0
  DTMRIRegPreprocess Source Target $DTMRI(InputTensorSource)  $DTMRI(InputTensorTarget) 
  set DTMRI(reg,Initial_tfm) $previous_initial_tfm
  puts "done."
  
  catch "Resampled Delete"
  vtkImageData Resampled

  # Do not delete   DTMRI(reg,Transform), otherwise, it will be wrong. ( delete the just allocated "TransformDTMRI")
  set DTMRI(reg,Transform) TransformDTMRI 

  set DTMRI(reg,Tensors)  "1"
  puts "Starting resampling..."
  DTMRIRegResample Source Target Resampled
  puts "done."
  #set v Resampled 
  Source Delete
  Target Delete
  
  # Build up full tensor again from 6 tensor components
  catch "setT Delete"
  vtkImageSetTensorComponents setT
  setT SetInput Resampled
  setT Update
  Tensor($DTMRI(ResultTensor),data) SetImageData [setT GetOutput]
  setT Delete
  Resampled Delete
  
  #warp scalar data from source and add to result
  #if no scalar data present, do not warp
  set sourcerange [[[[Tensor($DTMRI(InputTensorSource),data) GetOutput] GetPointData] GetScalars] GetRange]
  if {[lindex $sourcerange 1]>1e-20} {
    catch "SourceScalar Delete"
    vtkImageData SourceScalar
    catch "TargetScalar Delete"
    vtkImageData TargetScalar
    SourceScalar DeepCopy [Tensor($DTMRI(InputTensorSource),data) GetOutput] 
    TargetScalar DeepCopy [Tensor($DTMRI(InputTensorTarget),data) GetOutput] 
    catch "Resampled Delete"
    vtkImageData Resampled
    DTMRIRegPreprocess SourceScalar TargetScalar $DTMRI(InputTensorSource)  $DTMRI(InputTensorTarget) 
    if {$DTMRI(reg,Scale) > 0 } {
         DTMRIRegTransformScale SourceScalar TargetScalar 
    }
  
    set DTMRI(reg,Tensors)  "0"
    DTMRIRegResample SourceScalar TargetScalar Resampled
    [[Tensor($DTMRI(ResultTensor),data) GetOutput] GetPointData] SetScalars [[Resampled GetPointData] GetScalars]
    SourceScalar Delete
    TargetScalar Delete
    Resampled Delete
  }
  #MainDataSetActive Tensor $DTMRI(ResultTensor)
  DTMRISetActive $DTMRI(ResultTensor)
  
  MainUpdateMRML


  #Target Delete
  #Source Delete
  #if { ($DTMRI(MaskVol) != $Volume(idNone)) } {
  #    Mask Delete
  #}
  #if {$DTMRI(reg,glyphsWereOn)} {
  #  set DTMRI(mode,visualizationType,glyphsOn) "On"
  #  DTMRIUpdate
  #}
  puts "Finished Tensor Registration and Transformation"

}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegMenuCoregister
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegMenuCoregister {} {
    global DTMRI Volume Tensor
    if {!$DTMRI(reg,Scope)} {
      DevErrorWindow "Co-registration not supported for 2D Scope."
      return
    }
    if {$DTMRI(InputCoregVol)==$Volume(idNone)} {
      DevErrorWindow "Please select a volume for coregistration."
      return
    }
    if {$DTMRI(InputTensorTarget)==$Tensor(idNone)} {
      DevErrorWindow "Please select the target volume used in the registration."
      return
    }
    if {[info exist DTMRI(reg,Transform)]} {
      DTMRIRegCoregister $DTMRI(InputCoregVol) $DTMRI(InputTensorTarget)
      MainSlicesSetVolumeAll Back $DTMRI(InputCoregVol)
    } else {
      DevErrorWindow "Please run a registration first."
    return
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegCoregister
#Transform a scalar volume to a new volume based on the target tensor and the
# transform stored in DTMRI(transform)
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegCoregister {SourceVolume TargetTensor} {
    global DTMRI Volume Gui Tensor
    
    # Create a new volume based on the name of the source volume and the node descirption of the target volume
    set v1 $SourceVolume
    set v2name  [Volume($SourceVolume,node) GetName]
    #set v2 [DevCreateNewCopiedVolume $v1 ""  "resample_$v2name" ]
    set v2 [DTMRICreateEmptyVolume $TargetTensor "" "resample_$v2name" ]
    set node [Volume($v2,vol) GetMrmlNode]
    Mrml(dataTree) RemoveItem $node 
    set nodeBefore [Tensor($TargetTensor,data) GetMrmlNode]
    Mrml(dataTree) InsertAfterItem $nodeBefore $node
   
    catch "Source Delete"
    vtkImageData Source  
    catch "Target Delete"
    vtkImageData Target
    catch "math Delete"
    vtkTensorMathematics math
    math SetInput 0 [Tensor($TargetTensor,data) GetOutput]
    math SetInput 1 [Tensor($TargetTensor,data) GetOutput]
    math SetOperationTo$DTMRI(reg,Scalarmeas)
    math Update
    Target DeepCopy  [ math GetOutput]
    math Delete
    Source DeepCopy  [ Volume($SourceVolume,vol) GetOutput]

    # Do preprocessing. As we register scalar to tensor, it's slightly
    # different from DTMRIRegPreprocess
    set spacing [Target GetSpacing]
    set dims  [Target GetDimensions]
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
    Target  SetOrigin  $origin_0 $origin_1 $origin_2
    catch "NormalizedSource Delete"
    vtkImageData NormalizedSource
    set  SourceScanOrder [Volume($SourceVolume,node) GetScanOrder]
    set  TargetScanOrder [Tensor($TargetTensor,node) GetScanOrder]
    
    # Do we have a labelmap? If so, nearest neighbour interp will be used
    set DTMRI(reg,Labelmap) [Volume($SourceVolume,node) GetLabelMap]
    if {$DTMRI(reg,Labelmap)} {
      Volume($v2,node) SetLabelMap $DTMRI(reg,Labelmap)
      Volume($v2,node) SetInterpolate [expr !$DTMRI(reg,Labelmap)]
    }
    
    puts $DTMRI(reg,Labelmap)
    # Temporarily set initial_tfm off, such that it won't be applied twice
    # (once in RegNormalize and once in RegResample)
    set previous_initial_tfm $DTMRI(reg,Initial_tfm)
    set DTMRI(reg,Initial_tfm) 0
    DTMRIRegNormalize Source Target NormalizedSource $SourceScanOrder $TargetScanOrder
    set DTMRI(reg,Initial_tfm) $previous_initial_tfm
    Source DeepCopy NormalizedSource

    NormalizedSource Delete
    set dims  [Source GetDimensions]
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
    Source  SetOrigin  $origin_0 $origin_1 $origin_2
    # end preprocessing        

    set ext [Source GetExtent]
    for {set i 0} {$i<6} {incr i} {
      set ext$i [lindex $ext $i]
    }
    Source SetUpdateExtent $ext0 $ext1 $ext2 $ext3 $ext4 $ext5

    catch "Resampled Delete"
    vtkImageData Resampled
    set DTMRI(reg,Tensors)  "0"

    DTMRIRegResample Source Target Resampled
    Resampled SetOrigin 0 0 0
    Volume($v2,vol) SetImageData  Resampled
    MainVolumesUpdate $v2
    MainUpdateMRML

    Source Delete
    Target Delete
    set DTMRI(reg,Labelmap) 0

}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegPreprocess
#  Check the source and target, and set the target's origin to be at the
#  center. Set source to be at the same orientation and resolution as the target
# 
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegPreprocess {Source Target SourceVol TargetVol} {
 global DTMRI Volume Gui Tensor

  set spacing [$Target GetSpacing]
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

  set  SourceScanOrder [Tensor($SourceVol,node) GetScanOrder]
  set  TargetScanOrder [Tensor($TargetVol,node) GetScanOrder]

  DTMRIRegNormalize $Source $Target NormalizedSource $SourceScanOrder $TargetScanOrder
  $Source Delete
  vtkImageData $Source
  $Source DeepCopy NormalizedSource
  NormalizedSource Delete

  set dims  [$Source GetDimensions]

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
  
  set ext [$Source GetExtent]
  for {set i 0} {$i<6} {incr i} {
    set ext$i [lindex $ext $i]
  }
  $Source SetUpdateExtent $ext0 $ext1 $ext2 $ext3 $ext4 $ext5

  if {$DTMRI(reg,Debug) == 1} {
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
      set ScalarComponents [$Target GetNumberOfScalarComponents]
      puts " Target, $ScalarComponents scalar components."
      

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
      set ScalarComponents [$Source GetNumberOfScalarComponents]
      puts " Source, $ScalarComponents scalar components."
  }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegResample
# .Resample a new source according to the target and the transform saved i
# DTMRI(Transform).
#
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegResample {Source Target Resampled} {

  global DTMRI Volume Gui Tensor
#Test to transform the source using the computed transform.

  set None 0
 
  set ResampleOptions(interp) $DTMRI(reg,Interpolation)
  set ResampleOptions(intens) 0
  set ResampleOptions(like) 1
  #set ResampleOptions(like) $None
  set ResampleOptions(inverse) 0
  set ResampleOptions(tensors) $DTMRI(reg,Tensors)
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
  if {$DTMRI(reg,Labelmap)} {
    Cast SetOutputScalarType [$Source GetScalarType]
  }
  catch "ITrans Delete"
  vtkImageTransformIntensity ITrans

  ITrans SetInput [Cast GetOutput]
  
  if  {$ResampleOptions(intens) == 1 } {
      if {$DTMRI(reg,Warp)} {
        ITrans SetIntensityTransform $DTMRI(reg,inttfm)
      }
  }

  catch "Reslicer Delete"
  if {$ResampleOptions(tensors) == 0} {
     puts "Reslicer: No tensors"
      vtkImageReslice Reslicer
  } else {
      puts "Reslicer: Tensors"
      vtkImageResliceST Reslicer
  }

  Reslicer SetInput [ITrans GetOutput]
  Reslicer SetInterpolationMode $ResampleOptions(interp)
  Reslicer SetInterpolationModeToCubic
  if {$DTMRI(reg,Labelmap)} {
    Reslicer SetInterpolationModeToNearestNeighbor
    Reslicer SetInterpolationMode 0
    [Reslicer GetOutput] SetScalarTypeToShort
  }
  
# Should it be this way, or inverse in the other way?     
  if {$ResampleOptions(inverse) == 1} {
      Reslicer SetResliceTransform $DTMRI(reg,Transform) 
  } else {
      Reslicer SetResliceTransform [$DTMRI(reg,Transform)  GetInverse]
  }

  #Reslicer SetInformationInput Target
  if  {$ResampleOptions(like) !=  $None} {
      Reslicer SetInformationInput $Target
  }
  
  set spacing [Source GetSpacing]
  Reslicer SetOutputSpacing [lindex $spacing 0] [lindex $spacing 1] [lindex $spacing 2]
  if {$DTMRI(reg,2D)} {
    Reslicer SetOutputOrigin 0 0 0
  }
  puts "  updating now with spacing $spacing"
  Reslicer Update

  if {$DTMRI(reg,Debug) == 1} {

      set scalar_range [[Reslicer GetOutput] GetScalarRange]
      puts "Resclier's scalar range is : $scalar_range"
      

      set DataType [[Reslicer GetOutput] GetDataObjectType]
      puts " Reliscer output, data type is $DataType"

      set dim_arr [[Reslicer GetOutput] GetDimensions]

      puts " Reliscer output, dimensions:$dim_arr"
      
      set origin_arr [[Reslicer GetOutput] GetOrigin]

      puts " Reliscer output, origin : $origin_arr"
      
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
  
  $Resampled DeepCopy [Reslicer GetOutput]
  $Resampled SetOrigin 0 0 0
  
  Reslicer Delete
  ITrans Delete
  Cast Delete

}


#-------------------------------------------------------------------------------
# .PROC DTMRIRegNormalize
#   Run the Orientation Normalization.
#
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegNormalize { SourceImage TargetImage NormalizedSource SourceScanOrder TargetScanOrder} {

    global DTMRI Volume Gui Tensor

    
    catch "ijkmatrix Delete"
    catch "reslice Delete"

    vtkMatrix4x4 ijkmatrix
    if {[$SourceImage GetNumberOfScalarComponents]==6} {
      vtkImageResliceST reslice
    } else {
      vtkImageReslice reslice
    }
   
    reslice SetInterpolationModeToCubic
    reslice SetInterpolationMode $DTMRI(reg,Interpolation)
    if {$DTMRI(reg,Labelmap)} {
      reslice SetInterpolationModeToNearestNeighbor
      reslice SetInterpolationMode 0
    }
  
    catch "xform Delete"
    catch "changeinfo Delete"
    vtkTransform xform
    vtkImageChangeInformation changeinfo
    changeinfo CenterImageOn


    changeinfo SetInput $SourceImage
    # [Volume($DTMRI(reg,InputVolSource),vol) GetOutput]

    reslice SetInput [changeinfo GetOutput]

    switch  $SourceScanOrder {    
    "LR" { set axes {  0  0 -1  -1  0  0   0  1  0 } }
    "RL" { set axes {  0  0  1  -1  0  0   0  1  0 } }
    "IS" { set axes {  1  0  0   0  1  0   0  0  1 } }
    "SI" { set axes {  1  0  0   0  1  0   0  0 -1 } }
    "PA" { set axes {  1  0  0   0  0  1   0  1  0 } }
    "AP" { set axes {  1  0  0   0  0  1   0 -1  0 } }
    }


    if {$DTMRI(reg,Debug) == 1} {
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

 

    if {$DTMRI(reg,Debug) == 1} {
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

    if {$DTMRI(reg,Debug) == 1} {
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

    catch "gentrans Delete"
    vtkGeneralTransform gentrans
    gentrans PostMultiply
    gentrans Concatenate xform
    
    # Also apply initial transform, if requested.
    #if {$DTMRI(reg,Initial_tfm)} {
    #  gentrans Concatenate [TransformDTMRI GetInverse]
    #}

    reslice SetResliceTransform gentrans
    
    reslice SetOutputSpacing $outspa_0 $outspa_1 $outspa_2
    reslice SetOutputExtent $outext_0 $outext_1 $outext_2 $outext_3 $outext_4 $outext_5
    [reslice GetOutput] SetUpdateExtent $outext_0 $outext_1 $outext_2 $outext_3 $outext_4 $outext_5
    if {$DTMRI(reg,Debug) == 1} {
        puts " out dim:  $outdim"
        puts " out spacing :  $outspa" 
    }
   
    reslice Update
    [reslice GetOutput] SetUpdateExtent $outext_0 $outext_1 $outext_2 $outext_3 $outext_4 $outext_5
    
    gentrans Delete
    
    #Volume($DTMRI(reg,ResultVol),vol) SetImageData  [reslice GetOutput]
    #DTMRIWritevtkImageData [reslice GetOutput] "test.vtk"

    [reslice GetOutput]  SetOrigin 0 0 0

    $NormalizedSource DeepCopy  [reslice GetOutput]
  
   
    if {$DTMRI(reg,Debug) == 1} {

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
    set update_extent_arr [[reslice GetOutput] GetUpdateExtent]
    puts "Reslicer output, update extent: $update_extent_arr"
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
    #reslice UnRegisterAllOutputs
    reslice Delete
}




#-------------------------------------------------------------------------------
# .PROC DTMRIReadvtkImageData
# 
# .ARGS
# string image
# path filename
# .END
#-------------------------------------------------------------------------------
proc DTMRIReadvtkImageData {image filename}  {
    

    catch "TReader Delete"

    vtkStructuredPointsReader TReader

    TReader SetFileName $filename

    #TReader.SetNumberOfScalarComponents(2)
    TReader Update
    
    if {[TReader GetErrorCode]} {
      DevErrorWindows "Unable to open file $filename, errorcode [TReader GetErrorCode]."
      return 0
    }

    $image DeepCopy [TReader GetOutput]

    TReader Delete
    return 1
}



#-------------------------------------------------------------------------------
# .PROC DTMRIRegPrmdSetup
#
# .END
#-------------------------------------------------------------------------------
proc DTMRIPrmdSetup {args} {
    global DTMRI Tensor
    
    if {($DTMRI(InputTensorTarget) != $Tensor(idNone))} {
        catch "PrmdSetup Delete"
        vtkImageData PrmdSetup
        PrmdSetup DeepCopy [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
    set dims [PrmdSetup GetDimensions]
        set dim_0     [lindex $dims 0]        
        set dim_1     [lindex $dims 1]      
        set dim_2     [lindex $dims 2]
    
    set max [expr {$dim_0 > $dim_1 ? $dim_0 : $dim_1}]
        set max [expr {$dim_2 > $max ? $dim_2 : $max}]
        set pyr $max
    set pyrcount 0
        while {$max>=60} {
        set max [expr round($max.0/2)]
        lappend pyr $max
        incr pyrcount
    }
    
    set insertText ""
    set Stddev_max $DTMRI(reg,Stddev_max)
    set Stddev_min $DTMRI(reg,Stddev_min)    
    for {set i 0} {$i < [expr $pyrcount]} {incr i} {
        set level [expr $pyrcount-$i]
        append insertText "Level $level: resolution [lindex $pyr $level] Std $Stddev_max\n"
        #$DTMRI(reg,lStuff) insert end $insertText
    }
        set std $Stddev_max
    set level 0
        while {$std>$Stddev_min} {
        append insertText "Level $level: resolution [lindex $pyr $level] Std $std\n"
        #$DTMRI(reg,lStuff) insert end $insertText
        set std [expr $std-.25]
    }
    append insertText "Level $level: resolution [lindex $pyr $level] Std $Stddev_min\n"
    if {[lindex $pyr $level]>128} {
      append insertText "\nLong computation time\n when including level 0!\n"
    }
    $DTMRI(reg,lStuff) config -text "$insertText"
    set DTMRI(reg,Level_max) $pyrcount
    set DTMRI(reg,Level_min) 0
    } else {
    $DTMRI(reg,lStuff) config -text "Target volume not set."
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIReg2DUpate
#
# .END
#-------------------------------------------------------------------------------
proc DTMRIReg2DUpdate {} {
    #global DTMRI Tensor Gui
    #if {$DTMRI(InputTensorTarget)!=$Tensor(idNone)} {
    #  set DTMRI(reg,scanorder) [Tensor($DTMRI(InputTensorTarget),node) GetScanOrder]
    #  switch $DTMRI(reg,scanorder) {
    #    "IS" {
    #      $DTMRI(reg,2dlabel) config -text "Axial" -bg $Gui(slice0)
    #}
    #    "SI" {
    #      $DTMRI(reg,2dlabel) config -text "Axial" -bg $Gui(slice0)
    #}
    #"LR" {
    #      $DTMRI(reg,2dlabel) config -text "Sagittal" -bg $Gui(slice1)
    #}
    #"RL" {
    #      $DTMRI(reg,2dlabel) config -text "Sagittal" -bg $Gui(slice1)
    #}
    #"AP" {
    #      $DTMRI(reg,2dlabel) config -text "Coronal" -bg $Gui(slice2)
    #}
    #"PA" {
    #      $DTMRI(reg,2dlabel) config -text "Coronal" -bg $Gui(slice2)
    #}
    #  }
    #  if {$DTMRI(reg,Scope)} {
    #    $DTMRI(reg,2dlabel) config -text "" -bg $Gui(activeWorkspace)
    #  }    
    #}
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegUpdateInitial
# 
# .ARGS
# string meth
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegUpdateInitial {meth} {
    global DTMRI Matrix AG
    switch $meth {
      "lin" {
        if {$Matrix(activeID)!="" && $DTMRI(reg,Initial_lin)} {
          set DTMRI(reg,Initial_lintxt) "On"
          set DTMRI(reg,Initial_tfm) 1
        } else {
          set DTMRI(reg,Initial_lintxt) "Off"
      set DTMRI(reg,Initial_lin) "0"
        }
      }
      "grid" {
        if {$DTMRI(regInitGridTfmName)!="" && $DTMRI(reg,Initial_grid)} {
          set DTMRI(reg,Initial_gridtxt) "On"
          set DTMRI(reg,Initial_tfm) 1
        } else {
          set DTMRI(reg,Initial_gridtxt) "Off"
      set DTMRI(reg,Initial_grid) "0"
        }
      
      }
      "prev" {
        if {[info exist DTMRI(reg,Transform)] && $DTMRI(reg,Initial_prev)} {
          set DTMRI(reg,Initial_prevtxt) "On"
          set DTMRI(reg,Initial_tfm) 1
        } else {
          set DTMRI(reg,Initial_prevtxt) "Off"
      set DTMRI(reg,Initial_prev) "0"
        }
      
      }
      "AG" {
        if {[info exist AG(Transform)] && $DTMRI(reg,Initial_AG)} {
          set DTMRI(reg,Initial_AGtxt) "On"
          set DTMRI(reg,Initial_tfm) 1
        } else {
          set DTMRI(reg,Initial_AGtxt) "Off"
      set DTMRI(reg,Initial_AG) "0"
        }
      
      }
    }
    if {(!$DTMRI(reg,Initial_lin))&&(!$DTMRI(reg,Initial_grid))&&(!$DTMRI(reg,Initial_prev))&&(!$DTMRI(reg,Initial_AG))} {
      set DTMRI(reg,Initial_tfm) 0
    }

}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegTurnInitialOff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegTurnInitialOff {} {
    global DTMRI
    set DTMRI(reg,Initial_tfm) 0
    set DTMRI(reg,Initial_lin) 0
    set DTMRI(reg,Initial_grid) 0
    set DTMRI(reg,Initial_prev) 0
    set DTMRI(reg,Initial_AG) 0
    DTMRIRegUpdateInitial "lin"
    DTMRIRegUpdateInitial "grid"
    DTMRIRegUpdateInitial "prev"
    DTMRIRegUpdateInitial "AG"
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegCreateLinMat
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegCreateLinMat {} {
    global DTMRI
    if {![info exist DTMRI(reg,Transform)]} {
        DevErrorWindow "No transformation available, matrix generation aborted."
    return
    }
    set n [TransformDTMRI GetNumberOfConcatenatedTransforms]
    if {$DTMRI(reg,Debug) == 1} {
        puts " There are $n concatenated transforms"
    }
    set done 0
    for {set i [expr $n-1]}  {$i >= 0} {set i [expr $i-1]} {
        set t [TransformDTMRI GetConcatenatedTransform $i]
        set int_H [$t IsA vtkHomogeneousTransform]
        if { ($int_H != 0) && !$done} {
            set done 1
        #DTMRIRegWriteHomogeneous creates the matrix
        DTMRIRegWriteHomogeneous $t $i 
        }
    }
    if {!$done} {
        DevErrorWindow "No linear transform computed."
    return
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegSaveGridTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegSaveGridTransform {} {
    global DTMRI
    if {![info exist DTMRI(reg,Transform)]} {
        DevErrorWindow "No transformation available, grid-file not saved."
    return
    }
    set n [TransformDTMRI GetNumberOfConcatenatedTransforms]
    if {$DTMRI(reg,Debug) == 1} {
        puts " There are $n concatenated transforms"
    }
    set done 0
    for {set i [expr $n-1]}  {$i >= 0} {set i [expr $i-1]} {
        set t [TransformDTMRI GetConcatenatedTransform $i]
        set int_G [$t IsA vtkGridTransform]
        if { ($int_G != 0) && !$done } {
            set done 1
        if {![DTMRIRegWriteGrid $t $i]} {
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
# .PROC DTMRIRegColorComparison
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegColorComparison {} {
    global DTMRI Tensor Volume Slice

    if {$DTMRI(InputTensorTarget)==$Tensor(idNone)} {
      DevErrorWindow "Please select a target volume"
      return
    }
    if {$DTMRI(ResultTensor)==-5} {
      DevErrorWindow "Please select a result volume"
      return
    }

    catch "app Delete"
    vtkImageAppendComponents app
    
    set input [[[Tensor($DTMRI(InputTensorTarget),data) GetOutput] GetPointData] GetTensors]
    set rangexx [$input GetRange 0]
    set rangeyy [$input GetRange 4]
    set rangezz [$input GetRange 8]
    set maxTrace [expr [lindex $rangexx 1] + [lindex $rangeyy 1] + [lindex $rangezz 1]]
    

    #set operation $DTMRI(reg,Scalarmeas)
    #switch -regexp -- $operation {
    #{^(Trace|Determinant|D11|D22|D33|MaxEigenvalue|MiddleEigenvalue|MinEigenvalue)$} {
    #    set DTMRI(reg,scaleFactor) [expr 255 / $maxTrace]
    #}
    #{^(RelativeAnisotropy|FractionalAnisotropy|LinearMeasure|PlanarMeasure|SphericalMeasure|ColorByOrientation)$} {
        set DTMRI(reg,scaleFactor) 255
    #}
    #}
    puts "Computing result FA..."
    catch "math Delete"
    vtkTensorMathematics math
    math SetScaleFactor $DTMRI(reg,scaleFactor)
    math SetOperationToFractionalAnisotropy
    math SetInput 0 [Tensor($DTMRI(ResultTensor),data) GetOutput]
    math SetInput 1 [Tensor($DTMRI(ResultTensor),data) GetOutput]
    
    # Create absolute value, just in case.
    #catch "abs Delete"
    #vtkImageMathematics abs
    #abs SetInput 0 [math GetOutput]
    #abs SetInput 1 [math GetOutput]
    #abs SetOperationToAbsoluteValue
    
    #check SetInput1 [math GetOutput]

    catch "shift Delete"
    vtkImageShiftScale shift    
    shift SetInput [math GetOutput]
    shift SetOutputScalarTypeToUnsignedChar
    shift Update
    app SetInput 0 [shift GetOutput]
    app SetInput 2 [shift GetOutput]
    
    puts "computing target FA..."
    catch "math Delete"
    vtkTensorMathematics math
    math SetScaleFactor $DTMRI(reg,scaleFactor)
    math SetOperationToFractionalAnisotropy
    math SetInput 0 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
    math SetInput 1 [Tensor($DTMRI(InputTensorTarget),data) GetOutput]
    math Update
    
    # Reslice target to results' frame
    #puts "reslicing target FA to result FA..."
    #catch "reslice Delete"
    #vtkImageReslice reslice
    #reslice SetInput [math GetOutput]
    #reslice SetInformationInput [Tensor($DTMRI(ResultTensor),data) GetOutput]

    catch "shift Delete"
    vtkImageShiftScale shift    
    shift SetInput [math GetOutput]
    shift SetOutputScalarTypeToUnsignedChar
    shift Update
    app SetInput 1 [shift GetOutput]

    
    set dim0 [[app GetInput 0] GetDimensions]
    set dim1 [[app GetInput 1] GetDimensions]
    foreach d0 $dim0 d1 $dim1 {
      if {$d0!=$d1} {
        DevErrorWindow "Dimensionalities of result and target do not match. If you did a 2D-registration, set Scope back to 2D."
        return
      }
    }
    
    app Update
    
    # Create a new volume based on the name of the source volume and the node descirption of the target volume
    set v2 [DTMRICreateEmptyVolume $DTMRI(ResultTensor) ""  "Color Comparison" ]

    Volume($v2,node) SetInterpolate 0
    Volume($v2,vol) SetImageData [app GetOutput]
    MainVolumesUpdate $v2
    Volume($v2,node) SetScalarType [[shift GetOutput] GetScalarType]
    math Delete
    #abs Delete
    app Delete
    Volume($v2,node) SetInterpolate 0
    MainUpdateMRML    
    MainSlicesSetVolumeAll Back $v2
    MainSlicesSetVolumeAll Fore $Volume(idNone)
    RenderAll
    puts "done."
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegHelpUpdate
# 
# .ARGS
# string initial
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegHelpUpdate {initial} {
    global DTMRI
    # As Help is a notebook tab we can't use the HTML-stuff :-(
    # Main = printed at startup
    if {$initial||$DTMRI(reg,Help)==0} {
      set HelpText    "The Tensor Registration module alignes two\n"
      append HelpText "tensor volumes with each other. It enables\n"
      append HelpText "linear transformations up to affine, and\n"
      append HelpText "non-linear transformation using the\n" 
      append HelpText "demons algorithm. The tensors are reorien-\n"
      append HelpText "ted during transformation, to preserve\n" 
      append HelpText "tensor structure.\n\n"
      append HelpText "Suggested strategy:\n"
      append HelpText "- Do a registration without level 0\n"
      append HelpText "of the image pyramid.\n"
      append HelpText "- If the global transformation is good, use\n"
      append HelpText "the previous transform as initial and\n" 
      append HelpText "compute a non-linear transform with only\n"
      append HelpText "level 0 of the pyramid.\n"
      append HelpText "- Repeat the last step with Std.dev\n"
      append HelpText "min-max both e.g. 0.7 if the result isn't\n"
      append HelpText "satisfactory yet."
      set DTMRI(reg,InitialHelpText) $HelpText
    }
    if {$DTMRI(reg,Help)==1} {
      append HelpText "The target volume is the fixed volume, the \n"
      append HelpText "source volume the moving volume.\n"
      append HelpText "Method describes which transforms to\n" 
      append HelpText "apply.\n" 
      append HelpText "Set up the initial transform at the Tfm tab.\n"
      append HelpText "Generate a color image with result as\n"
      append HelpText "magenta and target as green channel to\n"
      append HelpText "analyze the result of the registration. A\n"
      append HelpText "scalar measure of result and target is\n"
      append HelpText "derived which can bechosen at the Adv tab.\n"
      append HelpText "If a scalar volume in alignment with tensor\n"
      append HelpText "source volume is available, this can be co-\n"
      append HelpText "registered."
    }
    # Transform
    if {$DTMRI(reg,Help)==2} {
      set HelpText "A initial linear transformation matrix can be\n"
      append HelpText "used. Use Alignments module to view matrix.\n"
      append HelpText "A VTK-file with 3 scalarcomponents (x,y,z\n"
      append HelpText "in VTK-coordinates) can be used as initial\n"
      append HelpText "grid-transform.\n"
      append HelpText "Using the Previous calculated transforma-\n"
      append HelpText "tion as initial can be useful to compute\n"
      append HelpText "an extra number of iterations if the result\n"
      append HelpText "is not satisfactory yet.\n"
      append HelpText "The AG module registers scalar volumes. The\n"
      append HelpText "output of this module can be used as initial.\n"
      append HelpText "The sequence of applying initial transforms\n"
      append HelpText "is linear->grid->previous->AG. Using them\n"
      append HelpText "all will however likely not make sense.\n"
      append HelpText "After running, the computed linear trans-\n"
      append HelpText "form can be saved in the main Data tree to\n"
      append HelpText "apply it to scalar data, or inspect \n"
      append HelpText "in the Alignment module. The non-linear\n"
      append HelpText "warping can be saved as VTK-file with 3\n"
      append HelpText "scalar components (x,y,z)."
    
    }
    # Pyramid
    if {$DTMRI(reg,Help)==3} {
      set HelpText "Non-linear registration is done at several \n"
      append HelpText "levels with different resolution. Use this \n"
      append HelpText "tab to select which levels to use. Level 0 \n"
      append HelpText "is computed several times decreasing the \n"
      append HelpText "standard deviation from max to min, see\n"
      append HelpText "Adv tab. Select levels and standard\n"
      append HelpText "deviation interval wisely to reduce\n" 
      append HelpText "computation time."
    
    }
    # Advanced
    if {$DTMRI(reg,Help)==4} {
      set HelpText "Linear registration is done on a scalar mea-\n"
      append HelpText "sure derived from the tensor.\n"
      append HelpText "Warping is done using a demons algorithm.\n"
      append HelpText "Modify options relating intensity transform \n"
      append HelpText "here. Set a higher number of minimal itera-\n"
      append HelpText "tions to force registration to continue if \n"
      append HelpText "it stops too early.\n"
      append HelpText "A low standard deviation of the smoothing \n"
      append HelpText "kernel of the deformation field will allow \n"
      append HelpText "bigger deformations, making the warping\n"
      append HelpText "more sensitive to noise. The interval\n"
      append HelpText "between min and max influences the number\n"
      append HelpText "of level 0 steps of the image pyramid,\n"
      append HelpText "see Prmd tab."
    }

    if {!$initial} {
      $DTMRI(reg,HelpText) config -text $HelpText
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIRegCommandline
# This proc can be used to do commandline registration.
# It assumes that currently no data is loaded, loads source and target,
# does registration with default options and saves result vtk-file.
# Scanorder of source and target are assumed to be equal
# .ARGS
# string targetname
# string sourcename
# string resultname
# .END
#-------------------------------------------------------------------------------
proc DTMRIRegCommandLine { {targetname} {sourcename} {resultname} } {
  # have args as extra arg
  global DTMRI Tensor Volume
  
  # read target and source
  set ::Volume(activeID) "NEW"
  set ::Volume(VolTensor,FileName) $targetname
  set ::Volume(scanOrder) "IS"
  VolTensorApply
  set ::Volume(activeID) "NEW"
  set ::Volume(VolTensor,FileName) $sourcename
  set ::Volume(scanOrder) "IS"
  VolTensorApply
  
  # set target and source for registration
  set ::DTMRI(InputTensorTarget) 0
  set ::DTMRI(InputTensorSource) 1
  # create new result volume = -5
  set ::DTMRI(ResultTensor) -5

  # and run
  DTMRIRegRun

  # save output
  DTMRIWritevtkImageData [Tensor($DTMRI(ResultTensor),data) GetOutput] $resultname
}

