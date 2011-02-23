#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRITractography.tcl,v $
#   Date:      $Date: 2006/08/15 16:44:56 $
#   Version:   $Revision: 1.53 $
# 
#===============================================================================
# FILE:        DTMRITractography.tcl
# PROCEDURES:  
#   DTMRITractographyInit
#   DTMRITractographyBuildGUI
#   DTMRISelectRemoveHyperStreamline x y z
#   DTMRISelectChooseHyperStreamline x y z
#   DTMRISelectStartHyperStreamline x y z render
#   DTMRIUpdateStreamlineSettings
#   DTMRIUpdateStreamlines
#   DTMRIUpdateTractingMethod TractingMethod
#   DTMRIUpdateBSplineOrder SplineOrder
#   DTMRIUpdateTractColorToSolid
#   DTMRIUpdateTractColorToSolidFromShowLabels
#   DTMRIUpdateROILabelWidgetFromShowLabels
#   DTMRIUpdateROILabelWidgetFromShowLabels
#   DTMRIUpdateTractColorToMulti
#   DTMRIUpdateTractColor mode
#   DTMRIRemoveAllStreamlines
#   DTMRIAddAllStreamlines
#   DTMRIDeleteAllStreamlines
#   DTMRISeedStreamlinesInROI
#   DTMRISeedStreamlinesFromSegmentation verbose
#   DTMRISeedStreamlinesFromSegmentationAndIntersectWithROI
#   DTMRISeedAndSaveStreamlinesFromSegmentation verbose
#   DTMRIFindStreamlinesThroughROI verbose
#   DTMRIDeleteStreamlinesNotPassTest
#   DTMRIResetStreamlinesThroughROI
#   DTMRITractographySetClipping
#   DTMRITractographyUpdateAllStreamlineSettings
#==========================================================================auto=




#-------------------------------------------------------------------------------
# .PROC DTMRITractographyInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractographyInit {} {

    global DTMRI Volume Label

    # Version info for files within DTMRI module
    #------------------------------------
    set m "Tractography"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.53 $} {$Date: 2006/08/15 16:44:56 $}]

    #------------------------------------
    # Tab 1: Settings (Per-streamline settings)
    #------------------------------------

    # type of tract coloring
    set DTMRI(mode,tractColor) SolidColor;
    set DTMRI(mode,tractColorList) {SolidColor MultiColor}
    set DTMRI(mode,tractColorList,tooltip) "Color tracts with a solid color \nOR MultiColor by scalars from the menu below."
    
    # Label/color value for coloring tracts
    set DTMRI(TractLabel) $DTMRI(defaultLabel)
    # Name of this label/color
    set DTMRI(TractLabelName) ""
    # Color ID corresponding to the label
    set DTMRI(TractLabelColorID) ""


    # types of tractography: subclasses of vtkHyperStreamline
    #------------------------------------
    set DTMRI(stream,tractingMethod) NoSpline
    # put the default last so its GUI is built on top.
    set DTMRI(stream,tractingMethodList) {BSpline NoSpline Teem}
    set DTMRI(stream,tractingMethodList,tooltip) {Method for interpolating signal}


    #-------------------------------------------------------------------------------------
    # vtkHyperStreamlineDTMRI tractography variables
    # Initialize here (some can be changed in the GUI).
    #------------------------------------
    # Max length (in number of steps?)
    set DTMRI(stream,MaximumPropagationDistance)  600.0

    set DTMRI(stream,MinimumPropagationDistance)  30.0

    # Terminal Eigenvalue
    set DTMRI(stream,TerminalEigenvalue)  0.0

    # integration step size in millimiters
    set DTMRI(stream,IntegrationStepLength)  0.5

    # radius of (polydata) tube that is displayed
    #set DTMRI(stream,Radius)  0.2 
    set DTMRI(stream,Radius)  0.4
    # sides of tube
    #set DTMRI(stream,NumberOfSides)  4
    set DTMRI(stream,NumberOfSides)  6

    # What type of value to use for a threshold
    # default must match the vtk class
    set DTMRI(stream,StoppingMode) LinearMeasure; 
    set DTMRI(stream,StoppingMode,menu) {LinearMeasure FractionalAnisotropy}         

    # threshold of above value
    set DTMRI(stream,StoppingThreshold) 0.15

    # Radius of curvature
    #set DTMRI(stream,MaxCurvature) 1.15
    # this is 1/1.15
    set DTMRI(stream,RadiusOfCurvature) 0.87


    # "NoSpline" tractography variables (lists are for GUI creation)
    #------------------------------------
    set DTMRI(stream,variableList) \
        [list \
             MaximumPropagationDistance IntegrationStepLength \
             RadiusOfCurvature StoppingMode StoppingThreshold \
             Radius  NumberOfSides ]

    set DTMRI(stream,variableList,type) \
         "entry entry entry menu entry entry entry"

    set DTMRI(stream,variableList,text) \
        [list \
             "Max Length (each half)" "Step Size" \
              "Radius of Curvature > " \
             "Anisotropy Type" "Anisotropy Threshold " \
             "Tube Radius"  "Tube Sides"]
    set DTMRI(stream,variableList,tooltips) \
        [list \
             "MaximumPropagationDistance (mm): Tractography stops after this distance, in each direction from the start point." \
             "IntegrationStepLength (mm): step size when following path" \
             "Radius of Curvature (mm): Minimum (tightest) turn allowed "\
             "Stopping by: If this shape measure falls below stopping threshold, tractography stops" \
             "Stopping Threshold: If value falls below this value, tracking stops" \
             "Radius (tube): Radius (thickness) of displayed tube" \
             "NumberOfSides (tube): Number of sides of displayed tube" ]


             

    #-------------------------------------------------------------------------------------
    # vtkHyperStreamlineTeem tractography variables
    # Initialize here (some can be changed in the GUI).
    #------------------------------------
    # Max length (in number of steps?)
    set DTMRI(teem,MaximumPropagationDistance)  600.0

    # Terminal Eigenvalue
    set DTMRI(teem,TerminalEigenvalue)  0.0

    # integration step size in millimiters
    set DTMRI(teem,IntegrationStepLength)  0.5

    # radius of (polydata) tube that is displayed
    #set DTMRI(teem,Radius)  0.2 
    set DTMRI(teem,Radius)  0.4
    # sides of tube
    #set DTMRI(teem,NumberOfSides)  4
    set DTMRI(teem,NumberOfSides)  6

    # What type of value to use for a threshold
    # default must match the vtk class
    set DTMRI(teem,StoppingMode) LinearMeasure; 
    set DTMRI(teem,StoppingMode,menu) {LinearMeasure PlanarMeasure SphericalMeasure FractionalAnisotropy}    
    # threshold of above value
    set DTMRI(teem,StoppingThreshold) 0.15

    # Radius of curvature
    #set DTMRI(teem,MaxCurvature) 1.15
    # this is 1/1.15
    set DTMRI(teem,RadiusOfCurvature) 0.87


    # Teem tractography variables (lists are for GUI creation)
    #------------------------------------
    set DTMRI(teem,variableList) \
        [list \
             MaximumPropagationDistance IntegrationStepLength \
             RadiusOfCurvature StoppingMode StoppingThreshold \
             Radius  NumberOfSides ]

    set DTMRI(teem,variableList,type) \
         "entry entry entry menu entry entry entry"

    set DTMRI(teem,variableList,text) \
        [list \
             "Max Length (each half)" "Step Size" \
              "Radius of Curvature > " \
             "Anisotropy Type" "Anisotropy Threshold " \
             "Tube Radius"  "Tube Sides"]
    set DTMRI(teem,variableList,tooltips) \
        [list \
             "MaximumPropagationDistance (mm): Tractography stops after this distance, in each direction from the start point." \
             "IntegrationStepLength (mm): step size when following path" \
             "Radius of Curvature (mm): Minimum (tightest) turn allowed "\
             "Stopping by: If this shape measure falls below stopping threshold, tractography stops" \
             "Stopping Threshold: If value falls below this value, tracking stops" \
             "Radius (tube): Radius (thickness) of displayed tube" \
             "NumberOfSides (tube): Number of sides of displayed tube" ]


    #-------------------------------------------------------------------------------------


    # B-spline tractography variables (lists are for GUI creation)
    #------------------------------------
    set DTMRI(stream,methodvariableList) \
        [list UpperBoundBias LowerBoundBias CorrectionBias ]

    set DTMRI(stream,methodvariableList,text) \
        [list "High Fractional Anisotropy" "Low Fractional Anisotropy" "Correction Bias Magnitude" ]

    set DTMRI(stream,methodvariableList,tooltips) \
        [list \
             "Inferior bound for fractional anisotropy before adding a regularization bias"\
             "Lowest fractional anisotropy allowable for tractography"\
             "Magnitude of the correction bias added for tractography" ]

    set DTMRI(stream,precisevariableList) \
        [list \
             MaximumPropagationDistance MinimumPropagationDistance TerminalEigenvalue \
             IntegrationStepLength \
             StepLength Radius  NumberOfSides  \
             MaxStep MinStep MaxError MaxAngle LengthOfMaxAngle]

    set DTMRI(stream,precisevariableList,text) \
        [list \
             "Max Length" "Min Length" "Terminal Eigenvalue"\
             "Step Size" \
             "Smoothness (along)" "Radius"  "Smoothness (around)" \
             "Max Step" "Min Step" "Max Error" "Max Angle" "Length for Max Angle"]
    set DTMRI(stream,precisevariableList,tooltips) \
        [list \
             "MaximumPropagationDistance: Tractography will stop after this distance" \
             "MinimumPropagationDistance: Streamline will be rejected if total length is under this value" \
             "TerminalEigenvalue: Set minimum propagation speed"\
             "IntegrationStepLength: step size when following path" \
             "StepLength: Length of each displayed tube segment" \
             "Radius: Initial radius (thickness) of displayed tube" \
             "NumberOfSides: Number of sides of displayed tube" \
             "MaxStep: Maximum step size when following path" \
             "MinStep: Minimum step size when following path" \
             "MaxError: Maximum Error of each step" \
             "MaxAngle: Maximum Angle allowed per fiber" \
             "MaxError: Length of fiber when considering maximum angle" ]

    # BSpline Orders
    set DTMRI(stream,BSplineOrder) "3"
    set DTMRI(stream,BSplineOrderList) {"0" "1" "2" "3" "4" "5"}
    set DTMRI(stream,BSplineOrderList,tooltip) {"Order of the BSpline interpolation."}

    # Method Orders
    set DTMRI(stream,MethodOrder) "rk4"
    set DTMRI(stream,MethodOrderList) {"rk2" "rk4" "rk45"}
    set DTMRI(stream,MethodOrderList,tooltip) {"Order of the tractography"}

    # Upper Bound to add regularization Bias
    set DTMRI(stream,UpperBoundBias)  0.3
    # Lower Bound to add regularization Bias
    set DTMRI(stream,LowerBoundBias)  0.2
    # Magnitude of the correction bias
    set DTMRI(stream,CorrectionBias)  0.5

    # Set/Get the Minimum Step of integration
    set DTMRI(stream,MinStep) 0.001
    # Set/Get the Maximum Step of integration
    set DTMRI(stream,MaxStep) 1.0
    # Set/Get the Maximum Error per step of integration
    set DTMRI(stream,MaxError) 0.000001

    # Set/Get the Maximum Angle of a fiber
    set DTMRI(stream,MaxAngle) 30

    # Set/Get the length of the fiber when considering the maximum angle
    set DTMRI(stream,LengthOfMaxAngle) 1


    #------------------------------------
    # Tab 2: Seeding (automatic from ROI)
    #------------------------------------

    # Labelmap volume that gives input seed locations
    set DTMRI(ROILabelmap) $Volume(idNone)
    set DTMRI(ROI2Labelmap) $Volume(idNone)
    # Label value indicating seed location
    set DTMRI(ROILabel) $DTMRI(defaultLabel)
    # Label value indicating seed location
    set DTMRI(ROI2Label) $DTMRI(defaultLabel)
    # Color value corresponding to the label
    set DTMRI(ROILabelColorID) ""
    # Color value corresponding to the label
    set DTMRI(ROI2LabelColorID) ""


    #------------------------------------
    # Tab 3: Selection (select tracts using ROI)
    #------------------------------------  
    set DTMRI(ROISelection) $Volume(idNone)
    
    #------------------------------------
    # Tab 3: Display of (all) streamlines
    #------------------------------------

    # whether we are currently displaying tracts
    set DTMRI(mode,visualizationType,tractsOn) 0n
    set DTMRI(mode,visualizationType,tractsOnList) {On Off Delete}
    set DTMRI(mode,visualizationType,tractsOnList,tooltip) \
        [list \
             "Display all 'tracts'" \
             "Hide all 'tracts'" \
             "Clear all 'tracts'" ]
    # guard against multiple actor add/remove from GUI
    set DTMRI(vtk,streamline,actorsAdded) 1

    # Non-labelmap volume that can be used for coloring tracts
    set DTMRI(ColorByVolume) $Volume(idNone)

    # whether we are currently clipping tracts with slice planes
    set DTMRI(mode,visualizationType,tractsClip) 0ff
    set DTMRI(mode,visualizationType,tractsClipList) {On Off}
    set DTMRI(mode,visualizationType,tractsClipList,tooltip) \
        [list \
             "Clip tracts with slice planes. Clipping settings are in Models->Clip." \
             "Do not clip tracts." ]
    
    set DTMRI(activeStreamlineID) ""
    
    #------------------------------------
    # Variable to Find tracts that pass through ROI values
    #------------------------------------
    set DTMRI(stream,ListANDLabels) ""
    set DTMRI(stream,ListNOTLabels) ""
    set DTMRI(stream,threshhold) 0
    set DTMRI(stream,threshold,max) 1
    set DTMRI(stream,threshold,min) 0
}


#-------------------------------------------------------------------------------
# .PROC DTMRITractographyBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractographyBuildGUI {} {

    global DTMRI Tensor Module Gui Label Volume

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Tract
    #    Active
    #    Notebook
    #       Settings
    #          Colors
    #          TractingMethod
    #          TractingVar
    #             BSpline
    #                BSplineOrder
    #                MethodOrder
    #                MethodVariables ...
    #                PreciseVariables ...
    #             NoSpline
    #                Variables...
    #             Teem
    #                Variables...
    #       Seeding
    #
    #       Display
    #          OnOffDelete
    #          ColorBy
    #          ColorByVol
    #-------------------------------------------

    #-------------------------------------------
    # Tract frame
    #-------------------------------------------
    set fTract $Module(DTMRI,fTract)
    set f $fTract

    # active tensor frame
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    # notebook frame (to contain settings, seeding,  select, display frames)

    if { [catch "package require BLT" ] } {
        DevErrorWindow "Must have the BLT package to create GUI."
        return
    }

    #--- create blt notebook
    blt::tabset $f.fNotebook -relief flat -borderwidth 0
    pack $f.fNotebook -side top -padx $Gui(pad) -pady $Gui(pad) -fill both -expand true

    #--- notebook configure
    $f.fNotebook configure -width 400
    $f.fNotebook configure -height 500
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
    foreach t "{Settings} {Seed} {Select} {Display}" {
        $f.fNotebook insert $i $t
        frame $f.fNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        $f.fNotebook tab configure $t -window $f.fNotebook.f$t  \
            -fill both -padx $::Gui(pad) -pady $::Gui(pad)
        incr i
    } 

    #-------------------------------------------
    # Tract->Active frame
    #-------------------------------------------
    set f $fTract.fActive

    # menu to select active DTMRI
    DevAddSelectButton  DTMRI $f ActiveTract "Active DTMRI:" Pack \
        "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActiveTract
    lappend Tensor(mActiveList) $f.mbActiveTract.m


    #-------------------------------------------
    # Tract->Notebook frame
    #-------------------------------------------
    set f $fTract.fNotebook
    
    set fSettings $f.fSettings
    set fSeeding $f.fSeed
    set fSelection $f.fSelect
    set fDisplay $f.fDisplay    
    
    foreach frame "$fSettings $fSeeding $fSelection $fDisplay" {
        $frame configure -relief groove -bd 3
    }


    ##########################################################
    #
    #  Settings Frame
    #
    ##########################################################

    #-------------------------------------------
    # Tract->Notebook->Settings frame
    #-------------------------------------------
    set f $fSettings

    foreach frame "Colors TractingMethod TractingVar" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }


    #-------------------------------------------
    # Tract->Notebook->Settings->Colors frame
    #-------------------------------------------
    set f $fSettings.fColors

    # label/color for new tracts we create
    eval {button $f.bOutput -text "Color:" -width 8 \
              -command "ShowLabels DTMRIUpdateTractColorToSolidFromShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
              -textvariable DTMRI(TractLabel)} $Gui(WEA)
    bind $f.eOutput <Return>   "DTMRIUpdateTractColorToSolid"
    eval {entry $f.eName -width 14 \
              -textvariable DTMRI(TractLabelName)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    #grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    #grid $f.eOutput $f.eName -sticky w
    pack $f.bOutput -padx $Gui(pad) -pady $Gui(pad) -side left
    pack $f.eName $f.eOutput -padx $Gui(pad) -pady $Gui(pad) -side right

    # save for changing color later
    set DTMRI(TractLabelWidget) $f.eName


    #-------------------------------------------
    # Tract->Notebook->Settings->TractingMethod frame
    #-------------------------------------------
    set f $fSettings.fTractingMethod

    eval {label $f.lVis -text "Interpolation Method: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(stream,tractingMethod) \
              -relief raised -bd 2 -width 11 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis -side left -pady 1 -padx $Gui(pad)
    pack $f.mbVis -side right -pady 1 -padx $Gui(pad)
    foreach vis $DTMRI(stream,tractingMethodList) {
        $f.mbVis.m add command -label $vis \
            -command "DTMRIUpdateTractingMethod $vis"
    }
    # save menubutton for config
    set DTMRI(gui,mbTractingMethod) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(stream,tractingMethodList,tooltip)

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar frame
    #-------------------------------------------
    set f $fSettings.fTractingVar

    # note the height is necessary to place frames inside later
    $f configure -height 500

    foreach frame $DTMRI(stream,tractingMethodList) {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        # for raising one frame at a time
        place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
        #pack $f.f$frame -side top -padx 0 -pady 1 -fill x
        set DTMRI(stream,tractingFrame,$frame) $f.f$frame
    }

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->NoSpline->Variables frames
    #-------------------------------------------

    foreach entry $DTMRI(stream,variableList) \
        text $DTMRI(stream,variableList,text) \
        tip $DTMRI(stream,variableList,tooltips) \
        type $DTMRI(stream,variableList,type) {

            set f $DTMRI(stream,tractingFrame,NoSpline)

            frame $f.f$entry -bg $Gui(activeWorkspace)
            pack $f.f$entry -side top -padx 0 -pady 1 -fill x
            set f $f.f$entry

            eval {label $f.l$entry -text "$text:"} $Gui(WLA)
            TooltipAdd $f.l$entry $tip
            pack $f.l$entry -side left  -padx $Gui(pad)


            if {$type == "entry"} {

                eval {entry $f.e$entry -width 8 \
                          -textvariable DTMRI(stream,$entry)} \
                    $Gui(WEA)

                TooltipAdd $f.e$entry $tip
                pack $f.e$entry -side right  -padx $Gui(pad)

            } elseif {$type == "menu"} {

                eval {menubutton $f.mb$entry -text "$DTMRI(stream,$entry)" \
                          -relief raised -bd 2 -width 20 \
                          -menu $f.mb$entry.m} $Gui(WMBA)
                eval {menu $f.mb$entry.m} $Gui(WMA)
                pack $f.mb$entry -side right -padx $Gui(pad)

                # save menubutton for config
                set DTMRI(stream,mb$entry) $f.mb$entry
                # Add a tooltip
                TooltipAdd $f.mb$entry $tip

                # add menu items
                foreach item $DTMRI(stream,$entry,menu) {
                    $f.mb$entry.m add command \
                        -label $item \
                        -command "set DTMRI(stream,$entry) $item; \
                    $f.mb$entry config -text $item"
                }
            }
        }

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->NoSpline
    #-------------------------------------------

    set f $DTMRI(stream,tractingFrame,NoSpline)

    eval {button $f.bApply -text "Apply to all tracts" \
              -command "DTMRITractographyUpdateAllStreamlineSettings"} $Gui(WBA)
    pack $f.bApply -padx $Gui(pad) -pady $Gui(pad) -side top


    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->BSpline frame
    #-------------------------------------------
    set f $DTMRI(stream,tractingFrame,BSpline)
    
    frame $f.fBSplineOrder -bg $Gui(activeWorkspace) 
    pack $f.fBSplineOrder -side top -padx 0 -pady 0 -fill x

    frame $f.fMethodOrder -bg $Gui(activeWorkspace) 
    pack $f.fMethodOrder -side top -padx 0 -pady 0 -fill x

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->BSpline->BSplineOrder frame
    #-------------------------------------------
    set f $DTMRI(stream,tractingFrame,BSpline).fBSplineOrder

    eval {label $f.lVis -text "Spline Order: "} $Gui(WLA)

    eval {menubutton $f.mbVis -text $DTMRI(stream,BSplineOrder) \
              -relief raised -bd 2 -width 11 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis  -side left -pady 1 -padx $Gui(pad)
    pack $f.mbVis -side right -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(stream,BSplineOrderList) {
        $f.mbVis.m add command -label $vis \
            -command "DTMRIUpdateBSplineOrder $vis"
    }
    # save menubutton for config
    set DTMRI(gui,mbBSplineOrder) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(stream,BSplineOrderList,tooltip)

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->BSpline->MethodOrder frame
    #-------------------------------------------
    set f $DTMRI(stream,tractingFrame,BSpline).fMethodOrder

    eval {label $f.lVis -text "Method Order: "} $Gui(WLA)

    eval {menubutton $f.mbVis -text $DTMRI(stream,MethodOrder) \
              -relief raised -bd 2 -width 11 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis  -side left -pady 1 -padx $Gui(pad)
    pack $f.mbVis -side right -pady 1 -padx $Gui(pad)
    # save menubutton for config
    set DTMRI(gui,mbMethodOrder) $f.mbVis
    # Add menu items
    foreach vis $DTMRI(stream,MethodOrderList) {
        $f.mbVis.m add command -label $vis \
            -command "set DTMRI(vtk,ivps) DTMRI(vtk,$vis); $DTMRI(gui,mbMethodOrder) config -text $vis"
    }
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(stream,BSplineOrderList,tooltip)

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->BSpline->MethodVariables frames
    #-------------------------------------------
    foreach entry $DTMRI(stream,methodvariableList) \
        text $DTMRI(stream,methodvariableList,text) \
        tip $DTMRI(stream,methodvariableList,tooltips) {
            
            set f $DTMRI(stream,tractingFrame,BSpline)
            
            frame $f.f$entry -bg $Gui(activeWorkspace)
            #place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
            pack $f.f$entry -side top -padx 0 -pady 1 -fill x
            set f $f.f$entry

            eval {label $f.l$entry -text "$text:"} $Gui(WLA)
            eval {entry $f.e$entry -width 8 \
                      -textvariable DTMRI(stream,$entry)} \
                $Gui(WEA)
            TooltipAdd $f.l$entry $tip
            TooltipAdd $f.e$entry $tip
            pack $f.l$entry -side left  -padx $Gui(pad)
            pack $f.e$entry -side right  -padx $Gui(pad)
        }

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->BSpline->PreciseVariables frames
    #-------------------------------------------
    foreach entry $DTMRI(stream,precisevariableList) \
        text $DTMRI(stream,precisevariableList,text) \
        tip $DTMRI(stream,precisevariableList,tooltips) {
            
            set f $DTMRI(stream,tractingFrame,BSpline)
            
            frame $f.f$entry -bg $Gui(activeWorkspace)
            #place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
            pack $f.f$entry -side top -padx 0 -pady 1 -fill x
            set f $f.f$entry

            eval {label $f.l$entry -text "$text:"} $Gui(WLA)
            eval {entry $f.e$entry -width 8 \
                      -textvariable DTMRI(stream,$entry)} \
                $Gui(WEA)
            TooltipAdd $f.l$entry $tip
            TooltipAdd $f.e$entry $tip
            pack $f.l$entry -side left  -padx $Gui(pad)
            pack $f.e$entry -side right  -padx $Gui(pad)
        }


    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->Teem->Variables frames
    #-------------------------------------------

    foreach entry $DTMRI(teem,variableList) \
        text $DTMRI(teem,variableList,text) \
        tip $DTMRI(teem,variableList,tooltips) \
        type $DTMRI(teem,variableList,type) {

            set f $DTMRI(stream,tractingFrame,Teem)

            frame $f.f$entry -bg $Gui(activeWorkspace)
            pack $f.f$entry -side top -padx 0 -pady 1 -fill x
            set f $f.f$entry

            eval {label $f.l$entry -text "$text:"} $Gui(WLA)
            TooltipAdd $f.l$entry $tip
            pack $f.l$entry -side left  -padx $Gui(pad)


            if {$type == "entry"} {

                eval {entry $f.e$entry -width 8 \
                          -textvariable DTMRI(teem,$entry)} \
                    $Gui(WEA)

                TooltipAdd $f.e$entry $tip
                pack $f.e$entry -side right  -padx $Gui(pad)

            } elseif {$type == "menu"} {

                eval {menubutton $f.mb$entry -text "$DTMRI(teem,$entry)" \
                          -relief raised -bd 2 -width 20 \
                          -menu $f.mb$entry.m} $Gui(WMBA)
                eval {menu $f.mb$entry.m} $Gui(WMA)
                pack $f.mb$entry -side right -padx $Gui(pad)

                # save menubutton for config
                set DTMRI(teem,mb$entry) $f.mb$entry
                # Add a tooltip
                TooltipAdd $f.mb$entry $tip

                # add menu items
                foreach item $DTMRI(teem,$entry,menu) {
                    $f.mb$entry.m add command \
                        -label $item \
                        -command "set DTMRI(teem,$entry) $item; \
                    $f.mb$entry config -text $item"
                }
            }
        }

    #-------------------------------------------
    # Tract->Notebook->Settings->TractingVar->Teem
    #-------------------------------------------

    set f $DTMRI(stream,tractingFrame,Teem)

    eval {button $f.bApply -text "Apply to all tracts" \
              -command "DTMRITractographyUpdateAllStreamlineSettings"} $Gui(WBA)
    pack $f.bApply -padx $Gui(pad) -pady $Gui(pad) -side top

    #Bring the right frame up depending on the tracting method
    raise $DTMRI(stream,tractingFrame,$DTMRI(stream,tractingMethod))
    focus $DTMRI(stream,tractingFrame,$DTMRI(stream,tractingMethod))

    ##########################################################
    #
    #  Seeding Frame
    #
    ##########################################################

    #-------------------------------------------
    # Tract->Notebook->Seeding frame
    #-------------------------------------------
    set f $fSeeding

    foreach frame "Title ROIMethod" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }
    $f.fROIMethod config -relief groove -bd 2 
 
    #-------------------------------------------
    # Tract->Notebook->Seeding->Title frame
    #-------------------------------------------
    set f $fSeeding.fTitle

    DevAddLabel $f.l "Seed tracts in a region of interest (ROI)."
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Tract->Notebook->Seeding->ROIMethod frame
    #-------------------------------------------
    set f $fSeeding.fROIMethod
    foreach frame "ROI ChooseLabel ROI2 ChooseLabel2 Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady 2 -fill both
    }

    #-------------------------------------------
    # Tract->Notebook->Seeding->ROIMethod->ROI frame
    #-------------------------------------------
    set f $fSeeding.fROIMethod.fROI

    # menu to select a volume: will set DTMRI(ROILabelmap)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name ROILabelmap
    DevAddSelectButton  DTMRI $f $name "Seed ROI:" Pack \
        "The region of interest in which to seed tracts."\
        13
    
    #-------------------------------------------
    # Tract->Notebook->Seeding->ROIMethod->ChooseLabel frame
    #-------------------------------------------
    set f $fSeeding.fROIMethod.fChooseLabel
    
    # label in input ROI for seeding
    eval {button $f.bOutput -text "Seed Label:" \
              -command "ShowLabels DTMRIUpdateROILabelWidgetFromShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 4 \
              -textvariable DTMRI(ROILabel)} $Gui(WEA)

    bind $f.eOutput <Return>   "DTMRIUpdateLabelWidget ROILabel"
    eval {entry $f.eName -width 14 \
              -textvariable DTMRI(ROILabelName)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    # save for changing color later
    set DTMRI(ROILabelWidget) $f.eName

    set tip \
        "Choose the color (label) of the region of interest."
    TooltipAdd  $f.bOutput $tip
    TooltipAdd  $f.eOutput $tip
    TooltipAdd  $f.eName $tip

    #-------------------------------------------
    # Tract->Notebook->Seeding->ROIMethod->ROI2 frame
    #-------------------------------------------
    set f $fSeeding.fROIMethod.fROI2

    # menu to select a volume: will set DTMRI(ROI2Labelmap)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name ROI2Labelmap
    DevAddSelectButton  \
        DTMRI $f $name "Selection ROI (Optional):" Pack \
        "Tracts will selected if they pass through this ROI.\nChoose None to skip this step." \
        13

    #-------------------------------------------
    # Tract->Notebook->Seeding->ROIMethod->ChooseLabel2 frame
    #-------------------------------------------
    set f $fSeeding.fROIMethod.fChooseLabel2
    
    # label in input ROI for seeding
    eval {button $f.bOutput -text "Select Label:" \
              -command "ShowLabels DTMRIUpdateROI2LabelWidgetFromShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 4 \
              -textvariable DTMRI(ROI2Label)} $Gui(WEA)

    bind $f.eOutput <Return>   "DTMRIUpdateLabelWidget ROI2Label"
    eval {entry $f.eName -width 14 \
              -textvariable DTMRI(ROI2LabelName)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    # save for changing color later
    set DTMRI(ROI2LabelWidget) $f.eName

    set tip \
        "Choose the color (label) of the region of interest."
    TooltipAdd  $f.bOutput $tip
    TooltipAdd  $f.eOutput $tip
    TooltipAdd  $f.eName $tip

    #-------------------------------------------
    # Tract->Notebook->Seeding->ROIMethod->Apply frame
    #-------------------------------------------
    set f $fSeeding.fROIMethod.fApply
    DevAddButton $f.bApply "Seed Tracts" \
        {puts "Seeding streamlines"; DTMRISeedStreamlinesInROI}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Seed tracts in the region of interest.\nThis can be slow for large ROIs."
 

    ##########################################################
    #
    #  Selection Frame
    #
    ##########################################################

    #-------------------------------------------
    # Tract->Notebook->Selection frame
    #-------------------------------------------
    set f $fSelection
    
    foreach frame "Title SelectMethod" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }
    $f.fSelectMethod config -relief groove -bd 2 
  
    #-------------------------------------------
    # Tract->Notebook->Selection->Title frame
    #-------------------------------------------
    set f $fSelection.fTitle

    DevAddLabel $f.l "Choose Tracts that pass through\na set of labels"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Tract->Notebook->Selection->SelectMethod frame
    #-------------------------------------------
    set f $fSelection.fSelectMethod
    foreach frame "ROI ListANDLabels ListNOTLabels Sensitivity Apply1 Apply2" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Tract->Notebook->Selection->SelectMethod->ROI frame
    #-------------------------------------------
    set f $fSelection.fSelectMethod.fROI

    # menu to select a volume: will set DTMRI(ROISelection)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name ROISelection
    DevAddSelectButton  DTMRI $f $name "ROI Labelmap:" Pack \
        "Labelmap with the regions to use in the selection method."\
        13

    #-------------------------------------------
    # Tract->Notebook->Selection->SelectMethod->ListLabels frame
    #-------------------------------------------
    set f $fSelection.fSelectMethod.fListANDLabels
    
    DevAddLabel $f.l "List of labels:"
    pack $f.l
    
     DevAddLabel $f.lAND "AND:"
    eval {entry $f.eAND -width 25 \
              -textvariable DTMRI(stream,ListANDLabels)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace)}
    
    pack $f.lAND $f.eAND -side left
    set tip "List of label numbers that tracts are intersecting.\n \
                The list is defined as a list of number with spaces in between."
    TooltipAdd  $f.eAND $tip
        
    set f $fSelection.fSelectMethod.fListNOTLabels
    
    DevAddLabel $f.lNOT "NOT:"
    eval {entry $f.eNOT -width 25 \
              -textvariable DTMRI(stream,ListNOTLabels)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace)}
    
    pack $f.lNOT $f.eNOT -side left
    set tip "List of label numbers that tracts are not intersecting.\n \
                The list is defined as a list of number with spaces in between."
    TooltipAdd  $f.eNOT $tip
    
    set f $fSelection.fSelectMethod.fSensitivity
    
    DevAddLabel $f.l "Sensitivity (H<->L):"
    eval {entry $f.e -width 3 \
                      -textvariable DTMRI(stream,threshold)} \
                $Gui(WEA)
    eval {scale $f.s -from $DTMRI(stream,threshold,min) \
                     -to $DTMRI(stream,threshold,max)    \
          -variable  DTMRI(stream,threshold) \
          -orient vertical     \
          -resolution 0.01      \
          } $Gui(WSA)
      
    pack $f.l $f.e $f.s -side left
    set tip "Sensitivity of tract selection. A low number means HIGH \n \
                sensitivity while a high number means LOW. \n \
                With high sensitivity, a fiber just needs to cross a voxel of the\n \
                ROI to be selected. With low sensitivity, several voxels need to be \n \
                crossed by the fiber before this is selected."
                
    TooltipAdd  $f.s $tip
    
    #-------------------------------------------
    # Tract->Notebook->Selection->SelectMethod->Apply frame
    #-------------------------------------------
    set f $fSelection.fSelectMethod.fApply1
    
    DevAddButton $f.bApply1 "Find 'Tracts' through ROI" \
        {DTMRIFindStreamlinesThroughROI}
    pack $f.bApply1 -side top -padx $Gui(pad) -pady $Gui(pad)

    set tip "Find tracts that fulfill the criterion defines by the list of labels.\n \
                Selected labels will be shown in red. Use this button before\n \
                Apply or Reset."
    TooltipAdd  $f.bApply1 $tip

    set f $fSelection.fSelectMethod.fApply2
    
    DevAddButton $f.bApply2 "Apply" \
        {DTMRIDeleteStreamlinesNotPassTest}
    DevAddButton $f.bApply3 "Reset" \
        {DTMRIResetStreamlinesThroughROI}
        
    pack $f.bApply2 $f.bApply3 -side left -padx $Gui(pad) -pady $Gui(pad)
    
    set tip "Apply the result: selected tracts will be kept and the rest will be removed.\n \
                Use this button when you are happy with your result after using\n \
                \" Find 'Tracts' through ROI\" "
    TooltipAdd  $f.bApply2 $tip
    
    set tip "Reset the result: restate the 3D viewer to the state that is was before you\n \
                hit  \" Find 'Tracts' through ROI\"."
   TooltipAdd  $f.bApply3 $tip                 
    
    ##########################################################
    #
    #  Display Frame
    #
    ##########################################################

    #-------------------------------------------
    # Tract->Notebook->Display frame
    #-------------------------------------------
    set f $fDisplay

    foreach frame "OnOffDelete ColorBy ColorByVol Clip" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }


    #-------------------------------------------
    # Tract->Notebook->Display->OnOffDelete frame
    #-------------------------------------------
    set f $fDisplay.fOnOffDelete
    eval {label $f.lVis -text "Display 'Tracts': "} $Gui(WLA)
    pack $f.lVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationType,tractsOnList) \
        tip $DTMRI(mode,visualizationType,tractsOnList,tooltip) {
            eval {radiobutton $f.r$vis \
                      -text $vis \
                      -command "DTMRIUpdateStreamlines" \
                      -value $vis \
                      -variable DTMRI(mode,visualizationType,tractsOn) \
                      -indicatoron 0} $Gui(WCA)

            pack $f.r$vis -side left -fill x
            TooltipAdd $f.r$vis $tip
        }

    #-------------------------------------------
    # Tract->Notebook->Display->ColorBy frame
    #-------------------------------------------
    set f $fDisplay.fColorBy
    eval {label $f.lVis -text "Color by: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(mode,tractColor) \
              -relief raised -bd 2 -width 12 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,tractColorList) {
        $f.mbVis.m add command -label $vis \
            -command "set DTMRI(mode,tractColor) $vis; DTMRIUpdateTractColor"
    }
    # save menubutton for config
    set DTMRI(gui,mbTractColor) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(mode,tractColorList,tooltip)

    #-------------------------------------------
    # Tract->Notebook->Display->ColorByVol frame
    #-------------------------------------------
    set f $fDisplay.fColorByVol

    # menu to select a volume: will set DTMRI(ColorByVolume)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name ColorByVolume
    DevAddSelectButton  DTMRI $f $name "Color by Volume:" Pack \
        "First select Color by MultiColor, \nthen select the volume to use \nto color the tracts. \nFor example to color by FA, \ncreate the FA volume using the \n<More...> tab in this module, \nthen the <Scalars> tab.  \nThen select that volume from this list." \
        13

    #-------------------------------------------
    # Tract->Notebook->Display->Clip frame
    #-------------------------------------------
    set f $fDisplay.fClip

    eval {label $f.lVis -text "Clip 'Tracts': "} $Gui(WLA)
    pack $f.lVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationType,tractsClipList) \
        tip $DTMRI(mode,visualizationType,tractsClipList,tooltip) {
            eval {radiobutton $f.r$vis \
                      -text $vis \
                      -command "DTMRITractographySetClipping" \
                      -value $vis \
                      -variable DTMRI(mode,visualizationType,tractsClip) \
                      -indicatoron 0} $Gui(WCA)

            pack $f.r$vis -side left -fill x
            TooltipAdd $f.r$vis $tip
        }    

}


################################################################
#  visualization procedures that deal with tracts
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRISelectRemoveHyperStreamline
#  Remove the selected hyperstreamline
# .ARGS
# int x
# int y
# int z
# .END
#-------------------------------------------------------------------------------
proc DTMRISelectRemoveHyperStreamline {x y z} {
    global DTMRI
    global Select

    puts "Select Picker  (x,y,z):  $x $y $z"

    # see which actor was picked
    set actor [DTMRI(vtk,picker) GetActor]
    DTMRI(vtk,streamlineControl) DeleteStreamline DTMRI(vtk,picker)
    
}


#-------------------------------------------------------------------------------
# .PROC DTMRISelectChooseHyperStreamline
# 
# .ARGS
# int x
# int y
# int z
# .END
#-------------------------------------------------------------------------------
proc DTMRISelectChooseHyperStreamline {x y z} {
    global DTMRI
    global Select

    puts "Select Picker  (x,y,z):  $x $y $z"

    # see which actor was picked
    set actor [DTMRI(vtk,picker) GetActor]
    set DTMRI(activeStreamlineID) \
        [[DTMRI(vtk,streamlineControl) GetDisplayTracts] \
             GetStreamlineIndexFromActor $actor]
}

#-------------------------------------------------------------------------------
# .PROC DTMRISelectStartHyperStreamline
# Given x,y,z in world coordinates, starts a streamline from that point
# in the active DTMRI dataset.
# .ARGS
# int x 
# int y
# int z 
# bool render Defaults to true
# .END
#-------------------------------------------------------------------------------
proc DTMRISelectStartHyperStreamline {x y z {render "true"} } {
    global DTMRI Tensor Color Label Volume
    global Select


    set t $Tensor(activeID)
    if {$t == "" || $t == $Tensor(idNone)} {
        puts "DTMRISelect: No DTMRIs have been read into the slicer"
        return
    }
    
    # set mode to On (the Display Tracts button will go On)
    set DTMRI(mode,visualizationType,tractsOn) On


    # Set up all parameters from the user
    # NOTE: TODO: make an Apply button and only call this 
    # when the user changes settings. Here it is too slow.
    DTMRIUpdateStreamlineSettings

    # actually create and display the streamline
    [DTMRI(vtk,streamlineControl) GetSeedTracts] SeedStreamlineFromPoint $x $y $z
    [DTMRI(vtk,streamlineControl) GetDisplayTracts] AddStreamlinesToScene

    # Force pipeline execution and render scene
    #------------------------------------
    if { $render == "true" } {
        Render3D
    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateStreamlineSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateStreamlineSettings {} {
    global DTMRI

    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    # set up type of streamline to create
    switch $DTMRI(stream,tractingMethod) {
        "BSpline" {

            # What type of streamline object to create
            $seedTracts UseVtkPreciseHyperStreamlinePoints

            # apply correct settings to example streamline object
            set streamline "streamlineControl,vtkPreciseHyperStreamlinePoints"

            DTMRI(vtk,$streamline) SetMethod $DTMRI(vtk,ivps)
            if {$DTMRI(stream,LowerBoundBias) > $DTMRI(stream,UpperBoundBias)} {
                set DTMRI(stream,UpperBoundBias) $DTMRI(stream,LowerBoundBias)
            }
            DTMRI(vtk,$streamline) SetTerminalFractionalAnisotropy \
                $DTMRI(stream,LowerBoundBias)
            foreach var $DTMRI(stream,methodvariableList) {
                DTMRI(vtk,itf) Set$var $DTMRI(stream,$var)
            }
            foreach var $DTMRI(stream,precisevariableList) {
                if { $var == "MaxAngle" } {
                    DTMRI(vtk,$streamline) Set$var \
                        [ expr cos( $DTMRI(stream,$var) * 3.14159265 / 180 ) ]
                } else {
                    DTMRI(vtk,$streamline) Set$var $DTMRI(stream,$var)
                }
                
            }

        }

        "NoSpline" {
            # What type of streamline object to create
            $seedTracts UseVtkHyperStreamlinePoints

            # apply correct settings to example streamline object
            set streamline "streamlineControl,vtkHyperStreamlinePoints"
            foreach var $DTMRI(stream,variableList) \
                type  $DTMRI(stream,variableList,type) {

                    if {$type == "menu" } {

                        DTMRI(vtk,$streamline) Set${var}To$DTMRI(stream,$var)

                    } else {
                        
                        DTMRI(vtk,$streamline) Set$var $DTMRI(stream,$var)

                    }
            }
            
        }

       "Teem" {
            # What type of streamline object to create
            $seedTracts UseVtkHyperStreamlineTeem

            # apply correct settings to example streamline object
            set streamline "streamlineControl,vtkHyperStreamlineTeem"
            foreach var $DTMRI(teem,variableList) \
                type  $DTMRI(teem,variableList,type) {

                    if {$type == "menu" } {

                        DTMRI(vtk,$streamline) Set${var}To$DTMRI(teem,$var)

                    } else {
                        
                        DTMRI(vtk,$streamline) Set$var $DTMRI(teem,$var)

                    }
            }
            
        }


    }

    # No matter what kind we are making, set the display parameters
    # This is cheating since only the superclass of these classes
    # actually uses this information to build a tube. These classes
    # only output lines, but for now they holw the desired display
    # info also.
    set radius [DTMRI(vtk,$streamline) GetRadius]
    set sides [DTMRI(vtk,$streamline) GetNumberOfSides]
    
    set display [DTMRI(vtk,streamlineControl) GetDisplayTracts]
    $display SetTubeRadius $radius
    $display SetTubeNumberOfSides $sides

}



#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateStreamlines
# show/hide/delete all
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateStreamlines {} {
    global DTMRI
    
    set mode $DTMRI(mode,visualizationType,tractsOn)

    switch $mode {
        "On" {
            # add actors
            DTMRIAddAllStreamlines
        }
        "Off" {
            # hide actors
            DTMRIRemoveAllStreamlines
        }
        "Delete" {
            # kill all objects
            DTMRIDeleteAllStreamlines
            # set mode to Off (will be set to On when add new stream)
            set DTMRI(mode,visualizationType,tractsOn) Off
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractingMethod
# .ARGS
# string TractingMethod
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractingMethod { TractingMethod } {
    global DTMRI Tensor
    
    if {$TractingMethod != $DTMRI(stream,tractingMethod) } {
        set DTMRI(stream,tractingMethod) $TractingMethod
        switch $DTMRI(stream,tractingMethod) {
            "NoSpline" {
                raise $DTMRI(stream,tractingFrame,NoSpline)
                focus $DTMRI(stream,tractingFrame,NoSpline)
                $DTMRI(gui,mbTractingMethod)    config -text $TractingMethod
                
            }
            "Teem" {
                raise $DTMRI(stream,tractingFrame,Teem)
                focus $DTMRI(stream,tractingFrame,Teem)
                $DTMRI(gui,mbTractingMethod)    config -text $TractingMethod
                
            }
            "BSpline" {
                raise $DTMRI(stream,tractingFrame,BSpline)
                focus $DTMRI(stream,tractingFrame,BSpline)
                $DTMRI(gui,mbTractingMethod)    config -text $TractingMethod

                # Apparently all of these Updates really are needed
                # set up the BSpline tractography pipeline
                set t $Tensor(activeID)
                
                if {$t != "" } {
                    set DTMRI(vtk,BSpline,data) 1
                    set DTMRI(vtk,BSpline,init) 1;
                    DTMRI(vtk,itf) SetDataBounds [Tensor($t,data) GetOutput]
                    for {set i 0} {$i < 6} {incr i} {
                        DTMRI(vtk,extractor($i)) SetInput [Tensor($t,data) GetOutput]
                    }
                    for {set i 0} {$i < 6} {incr i} {
                        DTMRI(vtk,extractor($i)) Update
                        DTMRI(vtk,bspline($i)) SetInput [DTMRI(vtk,extractor($i)) GetOutput]
                    }          
                    DTMRIUpdateBSplineOrder $DTMRI(stream,BSplineOrder)
                    for {set i 0} {$i < 6} {incr i} {
                        DTMRI(vtk,bspline($i)) Update
                        DTMRI(vtk,impComp($i)) SetInput [DTMRI(vtk,bspline($i)) GetOutput]
                    }
                }

            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateBSplineOrder
# .ARGS
# string SplineOrder
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateBSplineOrder { SplineOrder } {
    global DTMRI
    if { $SplineOrder != $DTMRI(stream,BSplineOrder) } {
        set DTMRI(stream,BSplineOrder) $SplineOrder
        $DTMRI(gui,mbBSplineOrder)    config -text $SplineOrder

        for {set i 0} {$i < 6} {incr i 1} {
            DTMRI(vtk,impComp($i)) SetSplineOrder $SplineOrder
            DTMRI(vtk,bspline($i)) SetSplineOrder $SplineOrder
            if { $DTMRI(vtk,BSpline,init) == 1 } {
                DTMRI(vtk,bspline($i)) Update
                DTMRI(vtk,impComp($i)) SetInput [DTMRI(vtk,bspline($i)) GetOutput]
            }
        }

    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColorToSolid
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColorToSolid {} {

    # update the color and label numbers
    DTMRIUpdateLabelWidget TractLabel

    # update our pipeline
    DTMRIUpdateTractColor SolidColor
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColorToSolidFromShowLabels
# Callback after ShowLabels window receives a label selection
# from the user.  Gets this value from Label(label) and stores 
# it as DTMRI(TractLabel).  Then calls DTMRIUpdateTractColorToSolid.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColorToSolidFromShowLabels {} {

    # update the color and label numbers
    DTMRIUpdateLabelWidgetFromShowLabels TractLabel

    # update our pipeline
    DTMRIUpdateTractColor SolidColor
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateROILabelWidgetFromShowLabels
# Callback after ShowLabels window receives a label selection
# from the user.  Calls DTMRIUpdateLabelWidgetFromShowLabels
# with an argument (which is not possible to do directly as the
# callback proc).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateROILabelWidgetFromShowLabels {} {

    DTMRIUpdateLabelWidgetFromShowLabels ROILabel

}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateROILabelWidgetFromShowLabels
# Callback after ShowLabels window receives a label selection
# from the user.  Calls DTMRIUpdateLabelWidgetFromShowLabels
# with an argument (which is not possible to do directly as the
# callback proc).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateROI2LabelWidgetFromShowLabels {} {

    DTMRIUpdateLabelWidgetFromShowLabels ROI2Label

}



#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColorToMulti
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColorToMulti {} {
    DTMRIUpdateTractColor MultiColor
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColor
# configure the coloring to be solid or scalar per triangle 
# .ARGS
# string mode Optional, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColor {{mode ""}} {
    global DTMRI Volume Tensor Color Label

    if {$mode == ""} {
        set mode $DTMRI(mode,tractColor)
    }

    set displayTracts [DTMRI(vtk,streamlineControl) GetDisplayTracts]

    # whether scalars should be displayed
    switch $mode {
        "SolidColor" {

            # Get the color calculated in UpdateLabelWidget procs
            set c $DTMRI(TractLabelColorID)

            # display new mode while we are working...
            $DTMRI(gui,mbTractColor)    config -text $mode

            # set up properties of the new actors we will create
            set prop [$displayTracts GetStreamlineProperty] 
            if { $c != "" } {
                #$prop SetAmbient       [Color($c,node) GetAmbient]
                #$prop SetDiffuse       [Color($c,node) GetDiffuse]
                #$prop SetSpecular      [Color($c,node) GetSpecular]
                #$prop SetSpecularPower [Color($c,node) GetPower]
                eval "$prop SetColor" [Color($c,node) GetDiffuseColor] 
            }

            # display solid colors instead of scalars
            $displayTracts ScalarVisibilityOff
        }
        "MultiColor" {
            # put the volume we wish to color by as the Scalars field 
            # in the tensor volume.
            set t $Tensor(activeID)            
            set v $DTMRI(ColorByVolume)

            # make sure they have the same extent
            set ext1 [[Tensor($t,data) GetOutput] GetWholeExtent]
            set ext2 [[Volume($v,vol) GetOutput] GetWholeExtent]
            if {[string equal $ext1 $ext2]} {

                $DTMRI(gui,mbTractColor)    config -text $mode

                # put the scalars there
                DTMRI(vtk,streamline,merge) SetScalars [Volume($v,vol) GetOutput]

                # setting scalars like this caused a crash in
                # the vtkMrmlDataVolume's vtkImageAccumulateDiscrete. why??
                #[[Tensor($t,data) GetOutput] GetPointData] SetScalars \
                    #    [[[Volume($v,vol) GetOutput] GetPointData] GetScalars]

                $displayTracts ScalarVisibilityOn
                eval {[$displayTracts GetStreamlineLookupTable] \
                          SetRange} [[Volume($v,vol) GetOutput] GetScalarRange]
                
                # set up properties of the new actors we will create
                set prop [$displayTracts GetStreamlineProperty] 
                # By default make them brighter than slicer default colors
                # slicer's colors have ambient 0, diffuse 1, and specular 0
                #$prop SetAmbient       0.5
                #$prop SetDiffuse       0.1
                #$prop SetSpecular      0.2

            } else {
                set message "Please select a volume with the same dimensions as the DTMRI dataset (for example one you have created from the Scalars tab)."
                set result [tk_messageBox  -message $message]

            }
        }
    }

    Render3D
}



#-------------------------------------------------------------------------------
# .PROC DTMRIRemoveAllStreamlines
# Remove all streamline actors from scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRemoveAllStreamlines {} {
    global DTMRI

    [DTMRI(vtk,streamlineControl) GetDisplayTracts] RemoveStreamlinesFromScene
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAddAllStreamlines
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIAddAllStreamlines {} {
    global DTMRI

    [DTMRI(vtk,streamlineControl) GetDisplayTracts] AddStreamlinesToScene
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIDeleteAllStreamlines
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIDeleteAllStreamlines {} {
    global DTMRI

    DTMRI(vtk,streamlineControl) DeleteAllStreamlines
    Render3D
}


#-------------------------------------------------------------------------------
# .PROC DTMRISeedStreamlinesInROI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISeedStreamlinesInROI {} {
    global DTMRI Volume

    # call the seeding procedure depending on whether
    # a selection ROI was chosen
    if {$DTMRI(ROI2Labelmap) == $Volume(idNone) || $DTMRI(ROI2Labelmap) == ""} {

        # no selection ROI
        DTMRISeedStreamlinesFromSegmentation

    } else {

        # we have a selection ROI
        DTMRISeedStreamlinesFromSegmentationAndIntersectWithROI
    }
    Render3D

}


#-------------------------------------------------------------------------------
# .PROC DTMRISeedStreamlinesFromSegmentation
# Seeds streamlines at all points in a segmentation.
# .ARGS
# int verbose Defaults to 1
# .END
#-------------------------------------------------------------------------------
proc DTMRISeedStreamlinesFromSegmentation {{verbose 1}} {
    global DTMRI Label Tensor Volume

    set t $Tensor(activeID)
    set v $DTMRI(ROILabelmap)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }

    # ask for user confirmation first
    if {$verbose == "1"} {
        set name [Volume($v,node) GetName]
        set msg "About to seed streamlines in all labelled voxels of volume $name.  This may take a while, so make sure the Tracts settings are what you want first. Go ahead?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }
    }

    # set mode to On (the Display Tracts button will go On)
    set DTMRI(mode,visualizationType,tractsOn) On

    # cast to short (as these are labelmaps the values are really integers
    # so this prevents errors with float labelmaps which come from editing
    # scalar volumes derived from the tensors).
    vtkImageCast castVSeedROI
    castVSeedROI SetOutputScalarTypeToShort
    castVSeedROI SetInput [Volume($v,vol) GetOutput] 
    castVSeedROI Update

    # set up the input segmented volume
    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    $seedTracts SetInputROI [castVSeedROI GetOutput] 
    $seedTracts SetInputROIValue $DTMRI(ROILabel)

    # color the streamlines like this ROI
    set DTMRI(TractLabel) $DTMRI(ROILabel)
    DTMRIUpdateTractColorToSolid

    # make sure the settings are current
    DTMRIUpdateStreamlineSettings
    
    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($v,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    $seedTracts SetROIToWorld transform
    transform Delete

    # create all streamlines
    puts "Original number of tracts: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"
    $seedTracts SeedStreamlinesInROI
    puts "New number of tracts will be: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"
    puts "Creating and displaying new tracts..."

    # actually display streamlines 
    # (this is the slow part since it causes pipeline execution)
    [DTMRI(vtk,streamlineControl) GetDisplayTracts] AddStreamlinesToScene

    castVSeedROI Delete
}



#-------------------------------------------------------------------------------
# .PROC DTMRISeedStreamlinesFromSegmentationAndIntersectWithROI
# Seed streamlines in all points in ROI, keep those that pass through
# ROI2.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISeedStreamlinesFromSegmentationAndIntersectWithROI {{verbose 1}} {
    global DTMRI Label Tensor Volume

    set t $Tensor(activeID)
    # seed at the labeled voxels in this volume
    set vSeedROI $DTMRI(ROILabelmap)
    # save and display the tracts that hit labeled voxels in this volume
    set vSaveROI $DTMRI(ROI2Labelmap)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($vSeedROI,node) GetLabelMap] != 1} {
        set name [Volume($vSeedROI,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }
    # make sure they are using a segmentation (labelmap)
    if {[Volume($vSaveROI,node) GetLabelMap] != 1} {
        set name [Volume($vSaveROI,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }

    # ask for user confirmation first
    if {$verbose == "1"} {
        set name1 [Volume($vSeedROI,node) GetName]
        set name2 [Volume($vSaveROI,node) GetName]
        set msg "Ready to seed tracts in all labeled voxels of volume $name1, and keep the ones that pass through labeled voxels in volume $name2.  This may take a while, so make sure the Tracts settings are what you want first. Go ahead?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }
    }

    # set mode to On (the Display Tracts button will go On)
    set DTMRI(mode,visualizationType,tractsOn) On

    # make sure the settings are current
    DTMRIUpdateTractColor
    DTMRIUpdateStreamlineSettings
    
    # cast to short (as these are labelmaps the values are really integers
    # so this prevents errors with float labelmaps which come from editing
    # scalar volumes derived from the tensors).
    vtkImageCast castVSeedROI
    castVSeedROI SetOutputScalarTypeToShort
    castVSeedROI SetInput [Volume($vSeedROI,vol) GetOutput] 
    castVSeedROI Update

    vtkImageCast castVSaveROI
    castVSaveROI SetOutputScalarTypeToShort
    castVSaveROI SetInput [Volume($vSaveROI,vol) GetOutput] 
    castVSaveROI Update

    # set up the input segmented volumes
    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    $seedTracts SetInputROI [castVSeedROI GetOutput]
    $seedTracts SetInputROIValue $DTMRI(ROILabel)

    $seedTracts SetInputROI2 [castVSaveROI GetOutput]
    $seedTracts SetInputROI2Value $DTMRI(ROI2Label)
    
    
    # Get positioning information from the MRML node for the seed ROI
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($vSeedROI,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    $seedTracts SetROIToWorld transform
    transform Delete

    # Get positioning information from the MRML node for the second ROI
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($vSaveROI,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    $seedTracts SetROI2ToWorld transform
    transform Delete

    # create all streamlines
    puts "Original number of tracts: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"

    
    $seedTracts SeedStreamlinesFromROIIntersectWithROI2
    puts "New number of tracts will be: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"

    # actually display streamlines 
    # (this is the slow part since it causes pipeline execution)
    puts "Creating and displaying new tracts..."
    [DTMRI(vtk,streamlineControl) GetDisplayTracts] AddStreamlinesToScene

    castVSeedROI Delete
    castVSaveROI Delete
}

#-------------------------------------------------------------------------------
# .PROC DTMRISeedAndSaveStreamlinesFromSegmentation
# Seeds streamlines at all points in a segmentation.
# This does not display anything, just one by one seeds
# the streamline and saves it to disk. So nothing is 
# visualized, this is for exporting files only.
# (Actually displaying all of the streamlines would be impossible
# with a whole brain ROI.)
# .ARGS
# int verbose Defaults to 1
# .END
#-------------------------------------------------------------------------------
proc DTMRISeedAndSaveStreamlinesFromSegmentation {{verbose 1}} {
    global DTMRI Label Tensor Volume

    set t $Tensor(activeID)
    set v $DTMRI(ROILabelmap)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }

    # cast to short (as these are labelmaps the values are really integers
    # so this prevents errors with float labelmaps which come from editing
    # scalar volumes derived from the tensors).
    vtkImageCast castVSeedROI
    castVSeedROI SetOutputScalarTypeToShort
    castVSeedROI SetInput [Volume($v,vol) GetOutput] 
    castVSeedROI Update

    # set base filename for all stored files
    set filename [tk_getSaveFile  -title "Save Tracts: Choose Initial Filename"]
    if { $filename == "" } {
        return
    }


    # make a subdirectory for them, named the same as the files                            
    set name [file root [file tail $filename]]
    set dir [file dirname $filename]
    set newdir [file join $dir tract_files_$name]
    file mkdir $newdir
    set filename [file join $newdir $name]
    # make a subdirectory for the vtk models                                               
    set newdir2 [file join $newdir vtk_model_files]
    file mkdir $newdir2
    set filename2 [file join $newdir2 $name]

    # ask for user confirmation first
    if {$verbose == "1"} {
        set name [Volume($v,node) GetName]
        set msg "About to seed streamlines in all labelled voxels of volume $name.  This may take a while, so make sure the Tracts settings are what you want first. Go ahead?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }
    }

    # make sure the settings are current for the models we save to disk              
    #DTMRIUpdateTractColor                                                          
    DTMRIUpdateStreamlineSettings

    # set up the input segmented volume
    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    $seedTracts SetInputROI [castVSeedROI GetOutput] 
    $seedTracts SetInputROIValue $DTMRI(ROILabel)

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($v,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    $seedTracts SetROIToWorld transform
    transform Delete

    # create all streamlines
    puts "Starting to seed streamlines. Files will be $filename*.*"
    $seedTracts SeedAndSaveStreamlinesInROI \
        $filename  $filename2

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts. The filename is: $filename*.*"
        tk_messageBox -message $msg
    }

    castVSeedROI Delete
}

#-------------------------------------------------------------------------------
# .PROC DTMRIFindStreamlinesThroughROI
# Seeds streamlines at all points in a segmentation.
# .ARGS
# int verbose defaults to 1
# .END
#-------------------------------------------------------------------------------
proc DTMRIFindStreamlinesThroughROI { {verbose 1} } {
    global DTMRI Label Tensor Volume

    set t $Tensor(activeID)
    set v $DTMRI(ROISelection)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }

    # set mode to On (the Display Tracts button will go On)
    set DTMRI(mode,visualizationType,tractsOn) On

    # make sure the settings are current
    DTMRIUpdateTractColor
    DTMRIUpdateStreamlineSettings
    
    #Define list of ROI Values
   set numLabels [llength $DTMRI(stream,ListANDLabels)]
    
    DTMRI(vtk,ListANDLabels) SetNumberOfValues $numLabels
    set idx 0
    foreach value $DTMRI(stream,ListANDLabels) {
        eval "DTMRI(vtk,ListANDLabels) SetValue" $idx $value
        incr idx
    }
    
    set numLabels [llength $DTMRI(stream,ListNOTLabels)]
    
    DTMRI(vtk,ListNOTLabels) SetNumberOfValues $numLabels
    set idx 0
    foreach value $DTMRI(stream,ListNOTLabels) {
        eval "DTMRI(vtk,ListNOTLabels) SetValue" $idx $value
        incr idx
    }    
 
    # set up the input segmented volume
    set ROISelectTracts DTMRI(vtk,ROISelectTracts)
    
    $ROISelectTracts SetInputROI [Volume($v,vol) GetOutput] 
    
    $ROISelectTracts SetInputROIValue $DTMRI(ROILabel)
    $ROISelectTracts SetInputANDROIValues DTMRI(vtk,ListANDLabels)
    $ROISelectTracts SetInputNOTROIValues DTMRI(vtk,ListNOTLabels)
    $ROISelectTracts SetConvolutionKernel DTMRI(vtk,convKernel)    
    $ROISelectTracts SetPassThreshold $DTMRI(stream,threshold)

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space    
    [$ROISelectTracts GetROIWldToIjk] SetMatrix [Volume($v,node) GetWldToIjk]
    $ROISelectTracts SetStreamlineWldToScaledIjk [[$ROISelectTracts GetStreamlineController] GetWorldToTensorScaledIJK]
    
    # create all streamlines
    puts "Initial number of tracts: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"
    $ROISelectTracts FindStreamlinesThatPassThroughROI
 
    puts "Creating and displaying new tracts..."
    $ROISelectTracts HighlightStreamlinesPassTest
    # actually display streamlines 
    # (this is the slow part since it causes pipeline execution)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIDeleteStreamlinesNotPassTest
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIDeleteStreamlinesNotPassTest { {verbose 1} } {

  global DTMRI
  
  DTMRI(vtk,ROISelectTracts) DeleteStreamlinesNotPassTest
  puts "Final number of tracts: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"
  Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIResetStreamlinesThroughROI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIResetStreamlinesThroughROI { {verbose 1} } {

  global DTMRI
  
  DTMRI(vtk,ROISelectTracts) ResetStreamlinesPassTest
  Render3D
}  


#-------------------------------------------------------------------------------
# .PROC DTMRITractographySetClipping
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractographySetClipping {{val ""}} {
    global Tensor DTMRI

    if {$val ==""} {
        switch $DTMRI(mode,visualizationType,tractsClip) {
            "On" {
                set val 1
            }
            "Off" {
                set val 0
            }
        }
    }

    if {$val ==  "1"} {
        
        if {[[Slice(clipPlanes) GetFunction] GetNumberOfItems] < 1} {
            set DTMRI(mode,visualizationType,tractsClip) Off
            set message "First select slice planes to clip by in the Models->Clip tab."
            tk_messageBox  -message $message
            return
        }


        # Use the current clip planes from the models GUI
        # copy its properties into a new object since
        # we have to transform it.
        vtkImplicitBoolean clipPlanes
        clipPlanes SetOperationType [Slice(clipPlanes) GetOperationType]
        set functions [Slice(clipPlanes) GetFunction]
        $functions InitTraversal
        set func [$functions GetNextItemAsObject]

        while {$func != ""} {
            puts $func
            eval {clipPlanes AddFunction} $func
            set func [$functions GetNextItemAsObject]            
        }

        # They have to be transformed into scaled IJK of the tensors
        catch "transform Delete"
        vtkTransform transform
        # WorldToTensorScaledIJK
        set t $Tensor(activeID)
        DTMRICalculateActorMatrix transform $t    
        #transform Inverse
        clipPlanes SetTransform transform
        transform Delete  
        
        [DTMRI(vtk,streamlineControl) GetDisplayTracts] \
            SetClipFunction clipPlanes
        clipPlanes Delete
    }

    # Turn clipping on/off
    [DTMRI(vtk,streamlineControl) GetDisplayTracts] \
        SetClipping $val

    # display it
    Render3D
    
}

#-------------------------------------------------------------------------------
# .PROC DTMRITractographyUpdateAllStreamlineSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractographyUpdateAllStreamlineSettings {} {

    DTMRIUpdateStreamlineSettings

    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    $seedTracts UpdateAllHyperStreamlineSettings

    set display [DTMRI(vtk,streamlineControl) GetDisplayTracts]
    $display UpdateAllTubeFiltersWithCurrentSettings

    Render3D
}
