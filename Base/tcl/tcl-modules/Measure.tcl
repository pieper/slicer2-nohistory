#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Measure.tcl,v $
#   Date:      $Date: 2006/04/21 18:20:06 $
#   Version:   $Revision: 1.27 $
# 
#===============================================================================
# FILE:        Measure.tcl
# PROCEDURES:  
#   MeasureInit
#   Test event W X Y x y t
#   MeasureBuildGUI
#   MeasureTopFrameBuildGUI
#   MeasureSetCsysVisibility
#   MeasureMiddleFrameBuildGUI
#   MeasureBottomFrameBuildGUI
#   BuildModelSelector fRoot
#   UpdateModelSelector fRoot
#   SelectModel  fRoot id
#   MeasureRefreshGUI
#   MeasureBuildVTK
#   MeasureEnter
#   MeasureExit
#   MeasurePosition
#   MeasureDistance
#   MeasureAngle
#   MeasureVolume
#   MeasureSurface
#   MeasureIntersection
#   MeasureOutput msg
#   get_distance a_id b_id
#   get_angle a_id b_id c_id
#   MeasureXSection
#   MeasureXSection1
#   addGlyphPoint widget x y
#   delGlyphPoint widget x y
#   selGlyphPoint widget x y
#   MeasureSetModelsPickable pickable
#   MeasureSetCsysPickable pickable
#   MeasureSetGlyphsPickable pickable
#   MeasureSetAllPickable pickable
#   MeasureCsysMotion actor angle dotprod unitX unitY unitZ
#==========================================================================auto=


# Measure.tcl
# 10/16/98 Peter C. Everett peverett@bwh.harvard.edu: Created
# 12/19/01 Krishna C. Yeshwant kcy@bwh.harvard.edu: Edited
# 05/21/02 Delphine Nain delfin@bwh : Edited

#-------------------------------------------------------------------------------
# .PROC MeasureInit
# Initialise the global variables for the Measure module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureInit {} {
    global Measure Module Model
    # Point
    
    # Definine Tabs
    set m Measure
    set Module($m,row1List) "Help Measure"
    set Module($m,row1Name) "{Help} {Measure}"
    set Module($m,row1,tab) Measure

    # Define Procedures
    set Module($m,procGUI) MeasureBuildGUI
    #    set Module($m,procMRML) MeasureUpdateGUI
    set Module($m,procVTK) MeasureBuildVTK
    set Module($m,procEnter) MeasureEnter
    set Module($m,procExit) MeasureExit
    # procedure called when a csys is moved
    set Module($m,procXformMotion) MeasureCsysMotion
    
    set Module($m,overview) "Use measurement tools to calculate positions, distances, angles for fiducials,\n\t\tand surface and volume of models, plus intersection volumes for models."
    set Module($m,author) "Krishna Yeshwant, SPL, kcy@bwh.harvard.edu"
    set Module($m,category) "Measurement"

    # Define Dependencies
    set Module($m,depend) ""
    
    # Set Version Info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.27 $} {$Date: 2006/04/21 18:20:06 $}]
    
    # Initialize module-level variables
    #    set Measure(Model1) $Model(idNone)
    array set Point {scale 5.0 selected {} \
        vtkPoints "Point(vtkPoints)" \
    vtkFloatArray "Point(vtkScalars)" -1,name "<None>"}

    # Event Bindings
#    set Measure(eventManager) { \
#        {$Gui(fViewWin) <Control-1> {addGlyphPoint %W %x %y}} \
#        {$Gui(fViewWin) <KeyPress-p> {addGlyphPoint %W %x %y}} \
#        {$Gui(fViewWin) <KeyPress-d> {delGlyphPoint %W %x %y}} \
#        {$Gui(fViewWin) <Control-2> {selGlyphPoint %W %x %y}} \
#        {$Gui(fViewWin) <KeyPress-c> {ExtractComponent %W %x %y}} \        
#    {$Gui(fViewWin) <KeyPress-q> {selGlyphPoint %W %x %y}} \    
#    {$Gui(fViewWin) <Shift-1> {addGlyphPoint %W %x %y}} }
}

#-------------------------------------------------------------------------------
# .PROC Test
# Does nothing.
# .ARGS
# str event
# widget W
# int X
# int Y
# int x
# int y
# int t
# .END
#-------------------------------------------------------------------------------
proc Test {event W X Y x y t } {
    #    puts "Button 1 pressed"
}

#-------------------------------------------------------------------------------
# .PROC MeasureBuildGUI
# Build the GUI for the Measure module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureBuildGUI {} {
    global Gui Measure Module 
    # Point Csys MeasureEventMgr
    # Tabs viewRen
    
    #    array set MeasureEventMgr [subst { \
        #        $Gui(fViewWin),<Enter> {focus %W} \
        #        $Gui(fViewWin),<Control-1> {addGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<KeyPress-p> {addGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<KeyPress-c> {ExtractComponent %W %x %y} \
        #        $Gui(fSl0Win),<KeyPress-p> {addGlyphPoint2D %W 0 %x %y} \
        #        $Gui(fSl1Win),<KeyPress-p> {addGlyphPoint2D %W 1 %x %y} \
        #        $Gui(fSl2Win),<KeyPress-p> {addGlyphPoint2D %W 2 %x %y} \
        #        $Gui(fViewWin),<Shift-Control-1> {selGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<Control-2> {selGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<KeyPress-q> {selGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<Control-3> {delGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<KeyPress-d> {delGlyphPoint %W %x %y} \
        #        $Gui(fViewWin),<Control-B1-Motion> {set noop 0} \
        #        $Gui(fViewWin),<Control-B2-Motion> {set noop 0} \
        #        $Gui(fViewWin),<Control-B3-Motion> {set noop 0} } ]
    
    #    DebugMsg "MeasureBuildGUI"
    
    #-----------------------------------------
    # Frame Hierarchy:
    #-----------------------------------------
    # Help
    # Measure
    #   Top
    #   Middle
    #   Bottom
    #-----------------------------------------
    
    #-----------------------------------------
    # Help frame
    #-----------------------------------------
    
    set help "
<B> Introduction to Measurement Tools </B>
The measurement tools can be used to calculate the: 
   <LI> position of a fiducial in world 
          coordinates
   <LI> distance between two fiducials
   <LI> angle formed by three fiducials
   <LI> surface area of a model
   <LI> volume of a model
   <LI> volume of interesection of two 
          models

   Fiducials can be added, grouped, edited, and deleted in the 'Fiducials' module (found by clicking on the 'More:' button above).  Models can be added and deleted in the 'Models' module (found at the top of this window).

<B>Using Measurement Tools</B>
   Below you will find a description of how to use the measurement tools found in this module.  Please recognize that these tools have not been validated.

   All of the Measurement Tools share a similar interface.  There are two sorts of objects the Measurement Tools work with: Fiducials and Models.  The user must first select one or more of these objects, as is appropriate, and then make the desired measurement by selecting from the list of tools found under the 'Measure' drop down list box found at the top of this pane (just under the 'Help' and 'Measure' tabs).  For example, to determine the coordinates of a fiducial, the user would first select the appropriate fiducial, and then select 'Position' from the 'Measure' drop down list box.  The coordinates will be reported in the text area just beneath the 'Measure' drop down button.  The user can click on 'Clear Output' to clear the text area at any time.

<LI> <B>position of a fiducial in world
          coordinates</B>
          Select one or more fiducials using 
          the Fiducials interface or by 
          pointing to the fiducials and 
          pressing the 'q' key.  Then select 
          'Position' from the 'Measure' drop 
          down list box.

<LI> <B>distance between two fiducials</B>
          Select two fiducials using the 
          Fiducials interface or by pointing 
          to the fiducials using the 'q' key.  
          Then select 'Distance' from the 
          'Measure' drop down list box.  
          Note that only the distance 
          between the first two fiducials 
          selected on the active list will be reported if
          more than one fiducial has been
          selected.

<LI> <B>angle formed by three fiducials</B>
          Select three fiducials using the 
          Fiducials interface or by pointing
          to the fiducials using the 'q'
          key.  Then select 'Angle' from
          the 'Measure' drop down list
          box.  Note that only the angle
          between the first three
          fiducials selected on the active list will be
          reported if more than one
          fiducial has been selected.
          Also, note that the angle
          measured is the angle between
          the vector formed by the
          first and second selected points
          and the vector formed by the
          second and third selected points.

<LI> <B>surface area of a model</B>
          Select a model from the 'Models:'
          drop down list box located below
          the text area and 'Clear Output'
          button on the 'Measure' tab. 
          The model will change color and
          will be denoted as selected in
          the drop down list box.  Then
          select 'Surface' from the
          Measure' drop down list box.

<LI> <B>volume of a model</B>
          Select a model from the 'Models:'
          drop down list box located below
          the text area and 'Clear Output'
          button on the 'Measure' tab. 
          The model will change color and
          will be denoted as selected in
          the drop down list box.  Then
          select 'Volume' from the
          Measure' drop down list box.

<LI> <B>volume of interesection of two
          models</B>
          Select two models from the
          Models:' drop down list box
          located below the
          text area and 'Clear Output'
          button on the 'Measure' tab.
          The models will change color
          and will be denoted as
          selected in the drop down
          list box.  Then select
          Intersection' from the
          Measure' drop down list box.

NOTE: None of the slicer measurement tools have been validated...the results may be (wildly) inaccurate.  The functionality is still under development.  Use at your own risk."  

    MainHelpApplyTags Measure $help
    MainHelpBuildGUI Measure
    
    
    #-----------------------------------------
    # Measure frame
    #-----------------------------------------
    set fMeasure $Module(Measure,fMeasure)
    set f $fMeasure
    
    # initialize Top and Bottom frames
    foreach frame "Top Middle Bottom" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-----------------------------------------
    # Measure->Top frame
    #-----------------------------------------
    MeasureTopFrameBuildGUI
    
    #-----------------------------------------
    # Measure->Middle frame
    #-----------------------------------------    
    #    SelectModelGUI $f 1
    MeasureMiddleFrameBuildGUI
    #    DevAddSelectButton Measure $f Model1 "Models:" Grid
    #    lappend Model(mbActiveList) $f.mbModel1
    #    lappend Model(mActiveList) $f.mbModel1.m
    
    #-----------------------------------------
    # Measure->Bottom frame
    #-----------------------------------------    
    MeasureBottomFrameBuildGUI
}

#-------------------------------------------------------------------------------
# .PROC MeasureTopFrameBuildGUI
# Build the top frame of the Measure module's gui.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureTopFrameBuildGUI {} {
    global Module Gui Measure
    
    set f $Module(Measure,fMeasure).fTop
    
    # Add measurement tool selections
    eval {menubutton $f.mb -menu $f.mb.menu -text "Measure" \
        -relief raised -bd 2 -width 9} $Gui(WMBA)
    eval {menu $f.mb.menu -tearoff 0} $Gui(WMA)
    
    # Note: Intersection removed for release-2-4 due to PolyBoolean bugs -sp
    foreach item { Position Distance Angle Volume Surface } {
    $f.mb.menu add command -label $item -command Measure$item
    }
    
    pack $f -side top -fill x -padx $Gui(pad) -pady $Gui(pad)
    pack $f.mb -in $f -side top
    
    
    # Add measurement output textbox
    frame $f.output -bg $Gui(activeWorkspace)
    set Measure(listbox) \
        [ScrolledListbox $f.output.lb 0 0 -width 40 -height 7]
    
    pack $f.output -side top -fill x -in $f
    pack $f.output.lb -side left -fill x -pady $Gui(pad) -in $f.output


    # Add clear button for output textbox
    set tmp {$foo}
    set c { button $f.clear -text "Clear Output" -bd 2 -width 13 \
        $Gui(WBA) -command {foreach foo {$Measure(listbox)} {$tmp delete 0 end}} } ; eval [subst $c]    
    
    pack $f.clear -side top -pady $Gui(pad) -in $f

    set Measure(Csys,visible) 0
    # Add Csys visibility button
    set c { checkbutton $f.cCsys -text "Csys" -variable Measure(Csys,visible) \
        -width 6 -indicatoron 0 -command "MeasureSetCsysVisibility" $Gui(WCA) }
    eval [subst $c]
    pack $f.cCsys -side bottom -pady $Gui(pad) -in $f

}

#-------------------------------------------------------------------------------
# .PROC MeasureSetCsysVisibility
# Set the Csys actor in the Measure module to be visible and pickable or not,
# depending on the value of the Measure(Csys,visible) variable.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureSetCsysVisibility {} { 
    global Measure 
    
    Measure(Csys,actor) SetVisibility $Measure(Csys,visible)
    MeasureSetCsysPickable $Measure(Csys,visible)
    Render3D 
}

#-------------------------------------------------------------------------------
# .PROC MeasureMiddleFrameBuildGUI
# Build the middle frame of the Measure module's gui.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureMiddleFrameBuildGUI {} {
    global Module

    BuildModelSelector $Module(Measure,fMeasure)
    #    UpdateModelSelector $Module(Measure,fMeasure).fSelModel.mb.m 1
}

#-------------------------------------------------------------------------------
# .PROC MeasureBottomFrameBuildGUI
# Add a fiducials interface here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureBottomFrameBuildGUI {} {
    global Module

    set f $Module(Measure,fMeasure).fBottom
    FiducialsAddActiveListFrame $f 275 10
}

#-------------------------------------------------------------------------------
# .PROC BuildModelSelector
# places a model selector in {$fRoot}.fSelModel
# with structure:<br>
# fRoot<br>
#   fSelModel : Selector containing frame<br>
#     .l      : "Models:" label<br>
#     .mb     : menubutton labeled "0-Selected" initially<br>
#       .m    : menu of models<br>
#     .bPick  : button labeled "Pick..."<br>
# .ARGS
# windowpath fRoot where to build the model selector
# .END
#-------------------------------------------------------------------------------
proc BuildModelSelector {fRoot} {
    global Gui Selected Model Module
    
    set f $fRoot.fSelModel
    
    frame $f -bg $Gui(activeWorkspace)
    set c { label $f.l -text "Models:" $Gui(WLA) }
    eval [subst $c]
    pack $f.l -side left
    set c { menubutton $f.mb -text "0-Selected" \
        -relief raised -bd 2 -width 15 \
        -menu $f.mb.m $Gui(WMBA) }
    eval [subst $c]
    set c { menu $f.mb.m $Gui(WMA) }
    eval [subst $c]
    pack $f.mb -side left
    #    set c { button $f.bPick -command "SelectPickModel $f" \
        -width 8 -bd 2 -text "Pick..." $Gui(WBA) }
    #    eval [subst $c]
    #    pack $f.bPick -side left
    pack $f -side top
    
    #    puts "test"
    #    puts $f.mb.m
    #    puts "done test"
}

#-------------------------------------------------------------------------------
# .PROC UpdateModelSelector
# Updates model selector passed in
# .ARGS
# windowpath fRoot where to update the model selector
# .END
#-------------------------------------------------------------------------------
proc UpdateModelSelector {fRoot} {
    global Model Measure Module
    global Mrml(dataTree)
    
    set m $fRoot.fSelModel.mb.m
    
    $m delete 0 end
    
    # fill $f.mb.m (i.e. $m) menu with existing Models
    # not sure if this is correct, only use 1st node of Mrml(dataTree)?
    set numModels [Mrml(dataTree) GetNumberOfModels]

    for {set i 0} {$i < $numModels} {incr i} {
        set currModel [Mrml(dataTree) GetNthModel $i]
        # use regular ID 
        set currID [$currModel GetID]
        if { $currID == "" } {
            # the model id from xml may not match up with the slicer 
            # assigned id, but try it as a backup
            set currID    [string trimleft [$currModel GetModelID] M]
        }
        if { $currID == "" } {
            puts "Warning: no ID for $currModel"
            continue
        }
        
        set r  [lindex $Module(Renderers) 0]
        
        if { [info exists Model($currID,selected)] == 0 } {
            set Model($currID,selected) 0        
        }
        if {[info command Model($currID,actor,$r)] == ""} {
            puts "Warning: current model $currModel id $currID does not have an actor in $r"
            continue
        }
        if { [Model($currID,actor,$r) GetVisibility] } {
            set state normal
        } else {
            set state disabled
        }
        $m add checkbutton -label [$currModel GetName] \
            -command "SelectModel $fRoot $currID" \
            -variable Model($currID,selected) -state $state
    }   
    
    $m add command -label "<None>" -command "SelectModel $fRoot -1"
}

#-------------------------------------------------------------------------------
# .PROC SelectModel 
# Selects the model with id of second parameter and updates
# fSelModel button in fRoot with number of models selected.
# .ARGS
# windowpath fRoot the model selector window
# int id the selected model id
# .END
#-------------------------------------------------------------------------------
proc SelectModel { fRoot id } {
    global Selected Model Module
    
    set index [lsearch $Selected(Model) $id]
    
    set r  [lindex $Module(Renderers) 0]
    if { $id == -1 } {
    # Unselect ALL
    foreach v $Selected(Model) {
        set Model($v,selected) 0
        [Model($v,actor,$r) GetProperty] SetAmbient 0
    }
    set Selected(Model) ""
    } elseif { $index > -1 } {
    # Remove from selection list
    set Selected(Model) [lreplace $Selected(Model) $index $index]
    set Model($id,selected) 0
    [Model($id,actor,$r) GetProperty] SetAmbient 0
    } else {
    # Add to selection list
    lappend Selected(Model) $id
    set Model($id,selected) 1    
    [Model($id,actor,$r) GetProperty] SetAmbientColor 1 0 0
    [Model($id,actor,$r) GetProperty] SetAmbient .6
    }
    
    set num [llength $Selected(Model)]
    $fRoot.fSelModel.mb config -text "$num-Selected"
    if { $num } {
    $fRoot.fSelModel.mb config -fg #ff0000
    $fRoot.fSelModel.mb config -activeforeground #ff0000
    } else {
    $fRoot.fSelModel.mb config -fg #000000
    $fRoot.fSelModel.mb config -activeforeground #000000
    }
    
    MeasureRefreshGUI
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MeasureRefreshGUI
# Update the model selector.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureRefreshGUI {} {
    global Module
    
#    DebugMsg "MeasureRefreshGUI"
    UpdateModelSelector $Module(Measure,fMeasure)
}

#-------------------------------------------------------------------------------
# .PROC MeasureBuildVTK
# Build the vtk structures needed in this module: coordinate system actor, cutter 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureBuildVTK {} {
    global Measure Csys
   
    PointsBuildVTK
    set Point(picker) [vtkCellPicker Point(picker)]
    Point(picker) SetTolerance 0.001
    
    CsysCreate Measure Csys -1 -1 -1
    # will not be pickable until the user enters the measure module
    set Measure(Csys,visible) 0
    MeasureSetCsysVisibility
    viewRen AddActor Measure(Csys,actor)
    
    # Initialize cutter (vtkPolyBoolean.h -> operation 4 -> A_TOUCHES_B)
    set Measure(cutter)  [vtkPolyBoolean Measure(cutter)]
    set Measure(filterA) [vtkTriangleFilter Measure(filterA)]
    set Measure(filterB) [vtkTriangleFilter Measure(filterB)]
    #    set Measure(filterC) [vtkTriangleFilter Measure(filterC)]
    set Measure(cutResult) [vtkPolyData Measure(cutResult)]
    Measure(cutter) SetOperation 2
    Measure(cutter) SetInput [Measure(filterA) GetOutput]
    Measure(cutter) SetPolyDataB [Measure(filterB) GetOutput]
    
#    set Measure(surfProps) [vtkSurfaceProps Measure(surfProps)]
}

#-------------------------------------------------------------------------------
# .PROC MeasureEnter
# Called when enter this module, refresh the gui. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureEnter {} {
    global Measure

#    pushEventManager $Measure(eventManager)
    MeasureRefreshGUI
}

#-------------------------------------------------------------------------------
# .PROC MeasureExit
# Called when exit this module. Currently does nothing.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureExit {} {
#    DebugMsg "Exiting Measure Tab"
#    popEventManager
}

#--------------------------------------
# Code to Report Surface Properties
#--------------------------------------

#-------------------------------------------------------------------------------
# .PROC MeasurePosition
# Get the point coordinates for all selected fiducials and report them in the 
# output list box.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasurePosition {} {
    set list [FiducialsGetAllSelectedPointIdList]

    if {[llength $list] < 1} {
        DevInfoWindow "Select a fiducial to see it's position."
        return
    }
    foreach id $list {
        set name [Point($id,node) GetName]
        set msg "$name: [FiducialsGetPointCoordinates $id]"
        MeasureOutput $msg
    }

#    global Point
#    
#    foreach id $Point(selected) {
#    set pos $Point($id,xyz)
#    set msg [eval format {"%s: %.2f %.2f %.2f"} $Point($id,name) \
#        $pos]
#    MeasureOutput $msg
#    }
#    foreach id $Point(selected) {
#    PointsSelect $id 0
#    }
#    MeasureRefreshGUI
#    Render3D
}


#-------------------------------------------------------------------------------
# .PROC MeasureDistance
# Measure the distance between the first selected points on the active fiducials list.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureDistance {} {
##    global Point

    # set list [FiducialsGetAllSelectedPointIdList]
    # get the selected points from the ACTIVE list
    set list [FiducialsGetActiveSelectedPointIdList]
    set idA [lindex $list 0]
    set idB [lindex $list 1]
    if {$idA == "" || $idB == ""} {
        set msg "Warning: the active list ($::Fiducials(activeList)) does not have two points selected to measure the distance between."
        MeasureOutput $msg
        return
    }
##    set idA [lindex $Point(selected) 0]
##    set idB [lindex $Point(selected) 1]
    #    MeasureTmpPoints SetNumberOfPoints 2
    #    eval MeasureTmpPoints InsertPoint 0 $Point($idA,xyz)
    #    eval MeasureTmpPoints InsertPoint 1 $Point($idB,xyz)
    #    MeasureTmpLines InsertNextCell 2
    #        MeasureTmpLines InsertCellPoint 0
    #        MeasureTmpLines InsertCellPoint 1
    set dist [format "%.2f" [get_distance $idA $idB]]

    set nameA [Point($idA,node) GetName]
    set nameB [Point($idB,node) GetName]

    set msg [concat "Distance from" $nameA "to" \
        $nameB "=" $dist "(mm)"]
    MeasureOutput $msg
##    PointsSelect $idA 0
##    PointsSelect $idB 0
    Render3D
    MeasureRefreshGUI
}

#-------------------------------------------------------------------------------
# .PROC MeasureAngle
#  Measure the angle between the first three active points on the active fiducials list.<br>
# Will print out an error message if three are not selected.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureAngle {} {
    global Point
    
    # set list [FiducialsGetAllSelectedPointIdList]
    # get the selected points from the ACTIVE list
    set list [FiducialsGetActiveSelectedPointIdList]
    set idA [lindex $list 0]
    set idB [lindex $list 1]
    set idC [lindex $list 2]
    set npts [llength $list]

    if {$idA == "" || $idB == "" || $idC == ""} {
        set msg "Warning: the active list ($::Fiducials(activeList)) does not have three points selected to measure the angle between."
        MeasureOutput $msg
        return
    }    
    
    if { $npts == 4 } {
        set idD [lindex $list 3]
    
        set xyzB [FiducialsGetPointCoordinates $idB]
        set xyzC [FiducialsGetPointCoordinates $idC]
        set xyzD [FiducialsGetPointCoordinates $idD]
        
        set cx [expr [lindex $xyzD 0] - \
                    [lindex $xyzC 0] + [lindex $xyzB 0 ]]
        set cy [expr [lindex $xyzD 1] - \
                    [lindex $xyzC 1] + [lindex $xyzB 1 ]]
        set cz [expr [lindex $xyzD 2] - \
                    [lindex $xyzC 2] + [lindex $xyzB 2 ]]
        set idC [PointsNew $cx $cy $cz]
    }    
    set angle [format "%.2f" [get_angle $idA $idB $idC]]

    set nameA [Point($idA,node) GetName]
    set nameB [Point($idB,node) GetName]
    set nameC [Point($idC,node) GetName]

    set msg [concat "Angle" $nameA $nameB \
        $nameC "=" $angle "deg."]
    MeasureOutput $msg
    Render3D
    MeasureRefreshGUI
}

#-------------------------------------------------------------------------------
# .PROC MeasureVolume
# Reports the volume of all selected models
# in the output listbox
# .END
#-------------------------------------------------------------------------------
proc MeasureVolume {} {
    global Model Selected Module
    global Mrml(dataTree)

    if {[llength $Selected(Model)] < 1} {
        DevInfoWindow "Please select a model from the Measure module's Models drop down menu"
        return
    }

    catch "surfProps Delete"
    vtkSurfaceProps surfProps
    set vol -1000
    
    

    foreach id $Selected(Model) {
        set currModel [Mrml(dataTree) GetNthModel $id]
        #    puts $name
        set name [$currModel GetName]
    
        set r  [lindex $Module(Renderers) 0]
       
        # changed viewRen to r since you get the first renderer above
        surfProps SetInput [Model($id,mapper,$r) GetInput]
        surfProps Update
        #    set vol [surfProps GetTest]
        set vol [surfProps GetVolume]
        if { $vol < 0.0 } {
            set vol [expr -1*$vol]
        }
        set msg [concat "Volume of" $name "=" [expr $vol*.001] "(ml)"]
        MeasureOutput $msg
        set err [surfProps GetVolumeError]
        if { [expr $err * 10000] > $vol } {
            set msg [concat "Warning:" $name "volume may not be valid."]
            MeasureOutput $msg
        }
    }
    
    # when vtk debugging is on, get an error after this Delete:
    # Deleting unknown object: vtkProcessObject
    # surfProps RemoveAllInputs doesn't get rid of it
    surfProps Delete
}



#-------------------------------------------------------------------------------
# .PROC MeasureSurface
# Show the surface area, for each selected model, in the output list box.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureSurface {} {
    global Model Selected
    
    if {[llength $Selected(Model)] < 1} {
        DevInfoWindow "Please select a model from the Measure module's Models drop down menu"
        return
    }

    catch "surfProps Delete"
    vtkSurfaceProps surfProps
    
    foreach id $Selected(Model) {
        set currModel [Mrml(dataTree) GetNthModel $id]
        set name [$currModel GetName]
        surfProps SetInput [Model($id,mapper,viewRen) GetInput]
        surfProps Update
        set area [surfProps GetSurfaceArea]
        set msg [concat "Area of" $name "=" $area "(mm^2)"]
        MeasureOutput $msg
    }

    surfProps Delete
}

#-------------------------------------------------------------------------------
# .PROC MeasureIntersection
# create large single triangle model<br>
# select single triangle model<br>
# orient triangle with Csys tool<br>
# select polyData model<br>
# intersect between polyData model and triangle<br>
# count number  of intersected triangles<br>
# scale and report count
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureIntersection { } {
    
    global Selected Measure Model
        
    # cut selected[0] with selected[1] for now
    set Measure(modelA) [lindex $Selected(Model) 0]
    set Measure(modelB) [lindex $Selected(Model) 1]
    
    set idA $Measure(modelA)
    set idB $Measure(modelB)
    
    #    DebugMsg "finding cross section of $idA with $idB"
    
    if { $idA > -1 && $idB > -1 && $idA != $idB } {
        Measure(filterA) SetInput [Model($idA,mapper,viewRen) GetInput]
        Measure(filterB) SetInput [Model($idB,mapper,viewRen) GetInput]
        Measure(cutter) SetXformA [Model($idA,actor,viewRen) GetMatrix]
        Measure(cutter) SetXformB [Model($idB,actor,viewRen) GetMatrix]
        #    Model($idA,mapper,viewRen) SetInput [Measure(cutter) GetOutput]
        Measure(cutter) UpdateCutter
        Measure(cutResult) Initialize
        Measure(cutResult) CopyStructure [Measure(cutter) GetOutput]
        Measure(cutResult) Squeeze
        Measure(cutResult) Modified
        

        # Measure volume of cutResult <vtkPolyData>
        vtkSurfaceProps surfProps
        set vol -1000
        
        surfProps SetInput Measure(cutResult)
        surfProps Update
        set vol [surfProps GetVolume]
        
        if { $vol < 0.0 } {
            set vol [expr -1*$vol]
        }

        ###    set name [$currModel GetName]
        set msg [concat "Volume of intersection =" [expr $vol*.001] "(ml)"]
        MeasureOutput $msg
        set err [surfProps GetVolumeError]
        if { [expr $err * 10000] > $vol } {
            set msg [concat "Warning: volume of intersection may not be valid."]
            MeasureOutput $msg
        }
        
        surfProps Delete
        
        #    puts [Measure(cutter) GetIntersectionCount]
        #    puts [Measure(cutter) GetTriangleCount]
        
        # previous method was to set the cutResult to be a model, then measure the volume
        # of that model
        #    Model($idB,mapper,viewRen) SetInput Measure(cutResult)
        
        #    puts  Measure(cutter) NodeCount
        
        Render3D
    } else {
        puts "Cutting not defined."
    }
}

#-------------------------------------------------------------------------------
# .PROC MeasureOutput
# Writes message into output listbox
# .ARGS
# str msg insert this string to the end of each Measure(listbox)
# .END
#-------------------------------------------------------------------------------
proc MeasureOutput { msg } {
    global Gui Measure
    
    foreach l $Measure(listbox) {
        $l insert end $msg
    }
}

#-------------------------------------------------------------------------------
# .PROC get_distance
# Get the posistions of two fiducials, and return the distance between them.
# .ARGS
# int a_id id of the first point
# int b_id id of the second point
# .END
#-------------------------------------------------------------------------------
proc get_distance { a_id b_id } {
    global Point
    
##    set a_pos $Point($a_id,xyz)
##    set b_pos $Point($b_id,xyz)
    set a_pos [FiducialsGetPointCoordinates $a_id]
    set b_pos [FiducialsGetPointCoordinates $b_id]
    set dist 0
    for { set ii 0 } { $ii<3 } { incr ii } {
        set delta [expr [lindex $a_pos $ii] - [lindex $b_pos $ii]]
        set delta [expr $delta * $delta]
        set dist [expr $dist + $delta]
    }
    set dist [expr sqrt( $dist )]
    #    DebugMsg [concat "Distance = " $dist "mm"]
    return $dist
}

#-------------------------------------------------------------------------------
# .PROC get_angle
# Get the locations of three points, and return the angle between them
# .ARGS
# int a_id id of the first point
# int b_id id of the second point
# int c_id id of the third point
# .END
#-------------------------------------------------------------------------------
proc get_angle { a_id b_id c_id } {
    global Point
    
##    set a_vec $Point($a_id,xyz)
##    set c_vec $Point($c_id,xyz)
##    set b_pos $Point($b_id,xyz)
    set a_vec [FiducialsGetPointCoordinates $a_id]
    set c_vec [FiducialsGetPointCoordinates $c_id]
    set b_pos [FiducialsGetPointCoordinates $b_id]
    set dotprod 0
    for { set ii 0 } { $ii<3 } { incr ii } {
        set delta [expr [lindex $a_vec $ii] - [lindex $b_pos $ii]]
        set a_vec [lreplace $a_vec $ii $ii $delta]
        set delta [expr [lindex $c_vec $ii] - [lindex $b_pos $ii]]
        set c_vec [lreplace $c_vec $ii $ii $delta]
        set dotprod [expr $dotprod + \
                         [lindex $a_vec $ii]*[lindex $c_vec $ii] ]
    }
    set xprodX [expr [lindex $a_vec 1]*[lindex $c_vec 2] - \
        [lindex $a_vec 2]*[lindex $c_vec 1] ]
    set xprodY [expr [lindex $a_vec 2]*[lindex $c_vec 0] - \
        [lindex $a_vec 0]*[lindex $c_vec 2] ]
    set xprodZ [expr [lindex $a_vec 0]*[lindex $c_vec 1] - \
        [lindex $a_vec 1]*[lindex $c_vec 0] ]
    set xprod [expr $xprodX*$xprodX + $xprodY*$xprodY + $xprodZ*$xprodZ]
    set xprod [expr sqrt( $xprod ) ]
    set angle [expr atan2( $xprod, $dotprod )*180/3.141592654]
    #    DebugMsg [concat "Angle = " $angle "degrees"]
    return $angle
}


### JUNK


#-------------------------------------------------------------------------------
# .PROC MeasureXSection
# Old intersection code:<br>
# create large single triangle model<br>
# select single triangle model<br>
# orient triangle with Csys tool<br>
# select polyData model<br>
# intersect between polyData model and triangle<br>
# count number of intersected triangles<br>
# scale and report count
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureXSection { } {
    
    global Selected Measure Model
    
    # cut selected[0] with selected[1] for now
    set Measure(targetModelID) [lindex $Selected(Model) 0]
    set Measure(xSectionToolModelID) [lindex $Selected(Model) 1]

    set idA $Measure(targetModelID)
    set idB $Measure(xSectionToolModelID)
    
    #    DebugMsg "finding cross section of $idA with $idB"
    
    if { $idA > -1 && $idB > -1 && $idA != $idB } {
        Measure(filterA) SetInput [Model($idA,mapper,viewRen) GetInput]
        Measure(filterB) SetInput [Model($idB,mapper,viewRen) GetInput]
        Measure(cutter) SetXformA [Model($idA,actor,viewRen) GetMatrix]
        Measure(cutter) SetXformB [Model($idB,actor,viewRen) GetMatrix]
        #    Model($idA,mapper,viewRen) SetInput [Measure(cutter) GetOutput]
        Measure(cutter) UpdateCutter
        Measure(cutResult) Initialize
        Measure(cutResult) CopyStructure [Measure(cutter) GetOutput]
        Measure(cutResult) Squeeze
        Measure(cutResult) Modified
        Model($idB,mapper,viewRen) SetInput Measure(cutResult)
        #    puts [Measure(cutter) GetIntersectionCount]
        #    puts [Measure(cutter) GetTriangleCount]
        #    puts  Measure(cutter) NodeCount
        
        Render3D
    } else {
        puts "Cutting not defined."
    }
}

#-------------------------------------------------------------------------------
# .PROC MeasureXSection1
# Code to Measure Cross Section<br>
# related to Cutting Code<br>
# use Csys tool to orient a cross section tool<br>
# select the model to measure<br>
# measure intersection of cross section tool and selected model
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureXSection1 { } {
    global Selected Measure Model
    
    # cut selected[0] with selected[1] for now
    set Measure(targetModelID) [lindex $Selected(Model) 0]
    set Measure(xSectionToolModelID) [lindex $Selected(Model) 1]
    
    set idA $Measure(targetModelID)
    set idB $Measure(xSectionToolModelID)
    
    #    DebugMsg "MeasureXSection  Testing TestIntersection Code"
    
    if { $idA > -1 && $idB > -1 && $idA != $idB } {
    Measure(filterA) SetInput [Model($idA,mapper,viewRen) GetInput]
    Measure(filterB) SetInput [Model($idB,mapper,viewRen) GetInput]
    Measure(cutter) SetXformA [Model($idA,actor,viewRen) GetMatrix]
    Measure(cutter) SetXformB [Model($idB,actor,viewRen) GetMatrix]
    
    Measure(cutter) SPLTestIntersection
    #    DebugMsg "TestIntersection Successful"
    #    puts [Measure(cutter) GetTestCount]
    }
}


#--------------------------------------
# Code to deal with Coordinate System
#--------------------------------------

#-------------------------------------------------------------------------------
# .PROC addGlyphPoint
# If a model is picked, places a landmark on the model.<br>
# If the Csys is picked allows movement of Csys,
# otherwise does nothing
# 
# .ARGS
# windowpath widget which window the picked model is in.
# int x picked point x coordinate
# int y picked point y coordinate
# .END
#-------------------------------------------------------------------------------
proc addGlyphPoint { widget x y } {
    global viewRen Point Model Module Measure
    
    #DebugMsg "addGlyphPoint"
    #tk_messageBox -message "addglyphpoint"
    MeasureSetModelsPickable 0
    MeasureSetGlyphsPickable 0
    #MeasureSetCsysPickable 1

    #
    # first see if an existing point was picked
    #
    if { [SelectPick Point(picker) $widget $x $y] == 0 } {
        #    DebugMsg "NoCsysPick"
        MeasureSetModelsPickable 1
        #MeasureSetCsysPickable 0

        #
        # then check for a model
        #
        if { [SelectPick Point(picker) $widget $x $y] == 0 } {
            #        DebugMsg [concat "Nothing picked at" $x "," $y "in" $widget ]
        } else {
            #
            # hit a model, means add a point
            #
            set actor [Point(picker) GetActor]
            set Point(model) ""
            foreach id $Model(idList) {
                foreach r $Module(Renderers) {
                    #            DebugMsg [concat "Check if " $actor " is " $id " " $r]
                    if { $actor == "Model($id,actor,$r)" } {    
                    #            DebugMsg [concat "Choosing model " $id]
                        set Point(model) Model($id,actor,$r)
                    } 
                }
            }
            eval PointsNew [Point(picker) GetPickPosition]
            MeasureRefreshGUI
            Render3D
        }  
    }
}

#-------------------------------------------------------------------------------
# .PROC delGlyphPoint
#  Delete a selected glyph point.
# .ARGS
# windowpath widget which window the picked model is in.
# int x picked point x coordinate
# int y picked point y coordinate
# .END
#-------------------------------------------------------------------------------
proc delGlyphPoint { widget x y } {
    global Point
    
    #    DebugMsg "delGlyphPoint"
    MeasureSetAllPickable 0
    MeasureSetGlyphsPickable 1
    set pntid [selGlyphPoint $widget $x $y]
    #    puts [concat "DEBUG: delGlyphPoint: " $pntid]
    if { $pntid != -1 } {
    PointsDelete $pntid
    #    MeasureRefreshGUI
    #    Render3D
    }
    MeasureRefreshGUI
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC selGlyphPoint
# Select a glyph point.
# .ARGS
# windowpath widget which window the picked model is in.
# int x picked point x coordinate
# int y picked point y coordinate
# .END
#-------------------------------------------------------------------------------
proc selGlyphPoint { widget x y } {
    global viewRen Point
    
    #    DebugMsg "selGlyphPoint"
    MeasureSetAllPickable 0
    MeasureSetModelsPickable 0
    MeasureSetGlyphsPickable 1
    #MeasureSetCsysPickable 1
    if { [SelectPick Point(picker) $widget $x $y] == 0 } {
        #    DebugMsg [concat "Nothing picked at" $x "," $y "in" $widget ]
        return -1
    } else {
        set actor [Point(picker) GetActor]
        #    DebugMsg [concat "Picked actor:" $actor]
        if { [$actor GetProperty] == [Measure(Csys,Xactor) GetProperty] } {
            #do nothing, handled by the main interactor
        } elseif { [$actor GetProperty] == [Measure(Csys,Yactor) GetProperty] } {
            #do nothing, handled by the main interactor
        } elseif { [$actor GetProperty] == [Measure(Csys,Zactor) GetProperty] } {
            #do nothing, handled by the main interactor
        } else {
            set pntid [PointIdFromGlyphCellId \
                           [Point(picker) GetCellId]]
            if { $pntid > -1 } {
                PointsSelect $pntid 1
                MeasureRefreshGUI
                Render3D
            }
            return $pntid
        }
    }
    return -1
}

#-------------------------------------------------------------------------------
# .PROC MeasureSetModelsPickable
# Go through the model list and set them all pickable or not. Invisible actors are not pickable.
# .ARGS
# int pickable if 1, set the models to be pickable, else not
# .END
#-------------------------------------------------------------------------------
proc MeasureSetModelsPickable { pickable } {
    global Model Slice Module
    
    #    DebugMsg MeasureSetModelsPickable
    foreach m $Model(idList) {
        set r  [lindex $Module(Renderers) 0]

        set actor Model($m,actor,$r)
        #    DebugMsg [concat Model $m SetPickable $pickable]
        if { [$actor GetVisibility] } {
            $actor SetPickable $pickable
        } else {
            $actor SetPickable 0
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MeasureSetCsysPickable
# Set the cooridinate system x, y, z actors and the active csys to be pickable or not
# .ARGS
# int pickable if 1, set the csys model to be pickable, else not
# .END
#-------------------------------------------------------------------------------
proc MeasureSetCsysPickable { pickable } {
    global Csys

    foreach m {Measure(Csys,Xactor) Measure(Csys,Yactor) Measure(Csys,Zactor)} {
        $m SetPickable $pickable
    }
    set Csys(active) $pickable
}

#-------------------------------------------------------------------------------
# .PROC MeasureSetGlyphsPickable
# Set the active point actor to be pickable or not.
# .ARGS
# int pickable if 1, set the model to be pickable, else not
# .END
#-------------------------------------------------------------------------------
proc MeasureSetGlyphsPickable { pickable } {
    global Point
    #    DebugMsg [concat Point(actor) SetPickable $pickable]
    $Point(actor) SetPickable $pickable
}

#-------------------------------------------------------------------------------
# .PROC MeasureSetAllPickable
# Go through the list of vtk actors and followers and set them all pickable or not
# .ARGS
# int pickable if 1, set the object to be pickable, else not
# .END
#-------------------------------------------------------------------------------
proc MeasureSetAllPickable { pickable } {

    foreach a [vtkActor ListInstances] {
        if { [$a GetVisibility] } {
            $a SetPickable $pickable
        } else {
            $a SetPickable 0
        }
    }
    foreach f [vtkFollower ListInstances] {
        $f SetPickable $pickable
    }
}

#-------------------------------------------------------------------------------
# .PROC MeasureCsysMotion
# Apply the rotation and translation of the cys to a selected model
# .ARGS
# str actor the name of the actor, only do stuff if it's the Measure(Csys,actor)
# float angle rotate using this angle
# float dotprod to multiply with the arbitrary vector
# float unitX x component of arbitrary vector to rotate around
# float unitY y component of arbitrary vector to rotate around
# float unitZ z component of arbitrary vector to rotate around
# .END
#-------------------------------------------------------------------------------
proc MeasureCsysMotion {actor angle dotprod unitX unitY unitZ} {

    global Csys Measure Selected Model

     if {$actor == "Measure(Csys,actor)"} {
    
         foreach id $Selected(Model) {
             Model($id,actor,viewRen) RotateWXYZ $angle $unitX $unitY $unitZ
             Model($id,actor,viewRen) AddPosition [expr $unitX*$dotprod] \
                 [expr $unitY*$dotprod] [expr $unitZ*$dotprod]
         }
         
         if { [info commands cutactor] != "" } {
             cutactor AddPosition [expr $unitX*$dotprod] \
                 [expr $unitY*$dotprod] [expr $unitZ*$dotprod]
             if { $lastAxis == 0 } {
                 cutactor RotateX $angle
             } else {
                 if { $lastAxis == 1 } {
                     cutactor RotateY $angle
                 } else {
                     cutactor RotateZ $angle
                 }   
             }
         }
     }
}
