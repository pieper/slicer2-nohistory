#=auto==========================================================================
#   Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdGeometryDraw.tcl,v $
#   Date:      $Date: 2006/12/28 21:54:17 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        EdGeometryDraw.tcl
# PROCEDURES:  
#   EdGeometryDrawInit
#   EdGeometryDrawBuildGUI
#   EdGeometryDrawEnter
#   EdGeometryDrawExit
#   EdGeometryDrawMakeEntryBox
#   EdGeometryMakeColorSelectGUI
#   EdGeometryDrawSphere i j k radius label
#   EdGeometryDrawApplyFromClick r a s
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawInit {} {
    global Ed EdGeometryDraw Module Gui
    
    # The Ed array is how we communicate with the Editor module.
    set e EdGeometryDraw
    set Ed($e,name)      "GeometryDraw"
    set Ed($e,initials)  "GD"
    set Ed($e,desc)      "Draw geometric shapes."
    set Ed($e,rank)      15
    set Ed($e,procGUI)   EdGeometryDrawBuildGUI
    set Ed($e,procEnter) EdGeometryDrawEnter
    set Ed($e,procExit)  EdGeometryDrawExit

    # Define Dependencies
    set Ed($e,depend) ""

    # Required
    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active

    # Normally Editor submodules don't have all of this module-level
    # information, but since this is a separate module include it.
    # Module Summary Info
    #------------------------------------
    set m EditorGeometryDraw
    set Module($m,overview) "Allows sphere drawing."
    set Module($m,author) "Lauren O'Donnell MIT CSAIL ljo at mit dot edu"

    # Skip this one since the menu for arriving here won't work
    # (since this GUI is inside the editor module).
    #  This is included in the Help->Module Categories menu item
    #set Module($m,category) "Editor"

    # Event bindings for 2D interactions
    #------------------------------------
    # the left mouse key press selects a location for drawing
    EvDeclareEventHandler EdGeometryDrawSliceEvents  <Button-1> \
    { if { [SelectPick2D %W %x %y] != 0 } \
          {  eval EdGeometryDrawApplyFromClick $Select(xyz); Render3D } }
    
    EvAddWidgetToBindingSet EdGeometryDrawSlice0Events $Gui(fSl0Win) {EdGeometryDrawSliceEvents}
    EvAddWidgetToBindingSet EdGeometryDrawSlice1Events $Gui(fSl1Win) {EdGeometryDrawSliceEvents}
    EvAddWidgetToBindingSet EdGeometryDrawSlice2Events $Gui(fSl2Win) {EdGeometryDrawSliceEvents}


    # Module variables
    #------------------------------------
    set EdGeometryDraw(shapes) {Sphere}


    # Module variables: Sphere
    #------------------------------------
    set EdGeometryDraw(Sphere,help) {Sphere: Click on the 2D slices to draw spheres.}

    set EdGeometryDraw(sphere,radius) 10

}

#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawBuildGUI
# Build the user interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawBuildGUI {} {
    global Ed Gui EdGeometryDraw Help

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # GeometryDraw
    #   TabbedFrame
    #     Help
    #     Sphere
    #       Note
    #       Colors
    #       Draw
    #-------------------------------------------

    #-------------------------------------------
    # GeometryDraw frame
    #-------------------------------------------

    set f $Ed(EdGeometryDraw,frame)

    set label ""
    set subframes {Help Sphere }
    set buttonText {"Help" "Sphere"}
    set tooltips { "Help: instructions on this module." \
        "Sphere: Draw spheres." }
    set extraFrame 0
    set firstTab Sphere

    TabbedFrame EdGeometryDraw $f $label $subframes $buttonText \
        $tooltips $extraFrame $firstTab
    
    #-------------------------------------------
    # TabbedFrame->Help frame
    #-------------------------------------------
    set f $Ed(EdGeometryDraw,frame).fTabbedFrame.fHelp
    
    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true

    set Ed(EdGeometryDraw,helpWidget) [HelpWidget $f.fWidget]

    set title {Draw various geometric shapes}

    eval $Ed(EdGeometryDraw,helpWidget) tag configure normal   $Help(tagNormal)
    eval $Ed(EdGeometryDraw,helpWidget) tag configure heading5 $Help(tagHeading5)

    $Ed(EdGeometryDraw,helpWidget) insert insert $title heading5

    foreach shape $EdGeometryDraw(shapes) {
        set help $EdGeometryDraw($shape,help)
        $Ed(EdGeometryDraw,helpWidget) insert insert $help normal
    }

    #-------------------------------------------
    # TabbedFrame->Sphere frame
    #-------------------------------------------
    set f $Ed(EdGeometryDraw,frame).fTabbedFrame.fSphere

    foreach frame "Note Colors Draw" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }


    #-------------------------------------------
    # TabbedFrame->Sphere->Note frame
    #-------------------------------------------
    set f $Ed(EdGeometryDraw,frame).fTabbedFrame.fSphere.fNote

    set note "Click on a 2D slice to draw a sphere."
    eval {label $f.lNote -text "$note"} $Gui(WLA)
    pack $f.lNote -side left  -padx $Gui(pad)

    #-------------------------------------------
    # TabbedFrame->Sphere->Colors frame
    #-------------------------------------------
    set f $Ed(EdGeometryDraw,frame).fTabbedFrame.fSphere.fColors

    EdGeometryMakeColorSelectGUI $f

    #-------------------------------------------
    # TabbedFrame->Sphere->Draw frame
    #-------------------------------------------
    set f $Ed(EdGeometryDraw,frame).fTabbedFrame.fSphere.fDraw

    set name Radius
    set text "Sphere Radius (mm)"
    set tip "Radius of the sphere"
    set var "EdGeometryDraw(sphere,radius)"

    EdGeometryDrawMakeEntryBox $f $name $text $tip $var


}


#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawEnter
# Called when this editor submodule is entered. Activates our bindings 
# (clicking in 2D slice windows).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawEnter {} {

    # add event handling for slices
    EvActivateBindingSet EdGeometryDrawSlice0Events
    EvActivateBindingSet EdGeometryDrawSlice1Events
    EvActivateBindingSet EdGeometryDrawSlice2Events

}

#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawExit
# Called when this editor submodule is exited. Deactivates our bindings.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawExit {} {

    # add event handling for slices
    EvDeactivateBindingSet EdGeometryDrawSlice0Events
    EvDeactivateBindingSet EdGeometryDrawSlice1Events
    EvDeactivateBindingSet EdGeometryDrawSlice2Events

}


#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawMakeEntryBox
# Helper procedure to make an entry box in the user interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawMakeEntryBox {f name text tip var} {
    global Label Gui EdGeometryDraw

    frame $f.f$name -bg $Gui(activeWorkspace)
    pack $f.f$name -side top -padx $Gui(pad) -pady 1 
    set f $f.f$name

    eval {label $f.l$name -text "$text:"} $Gui(WLA)
    eval {entry $f.e$name -width 10 \
              -textvariable $var} \
        $Gui(WEA)
    TooltipAdd $f.l$name $tip
    TooltipAdd $f.e$name $tip
    pack $f.l$name -side left  -padx $Gui(pad)
    pack $f.e$name -side left  -padx $Gui(pad)

}


#-------------------------------------------------------------------------------
# .PROC EdGeometryMakeColorSelectGUI
# Helper procedure to make the color selection part of the user interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdGeometryMakeColorSelectGUI {f} {
    global Label Gui

    # Output label
    eval {button $f.bOutput -text "Output:" \
        -command "ShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
        -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "LabelsFindLabel"
    eval {entry $f.eName -width 14 \
        -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w

    lappend Label(colorWidgetList) $f.eName
}

#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawSphere
# Draws a sphere at the requested location in the volume.
# The volume is the current working volume in the slicer editor.
# Uses Ed(editor) object to run the pipeline, which allows undoing.
# The coordinate system is scaled IJK which refers to the voxels in the image
# array (with their size known) but no knowledge of rotations into RAS/World.
# .ARGS
# float i first coordinate of point in scaled i,j,k of the volume
# float j second coordinate of point in scaled i,j,k of the volume
# float k third coordinate of point in scaled i,j,k of the volume
# float radius radius of the sphere to draw in mm (or whatever units your voxel dimensions are measured in)
# int label value to assign to voxels within the sphere
# 
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawSphere {i j k radius label} {
    global Ed EdGeometryDraw Volume

    set e EdGeometryDraw

    set Ed($e,scope)  3D 
    set Ed($e,input)  Working
    set Ed($e,interact) Active   

    # Get the input working labelmap ID
    set w [ EditorGetWorkingID ]
    set v [ EditorGetOriginalID ]

    # Need to call this here so working volume extents are set up.
    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native


    if {0} {
    # Create a sphere using a vtk implicit function.
    # The coordinate system is scaled ijk of the working labelmap.
    # So this means the radius is in mm.
    catch {vtkSphere _sphere}
    _sphere SetCenter $i $j $k
    _sphere SetRadius $radius

    # Convert the implicit function to a stencil.
    # This is a labelmap stored in more compact form.
    # Its ijk coordinate system matches the working labelmap.
    catch {vtkImplicitFunctionToImageStencil _functionToStencil}
    _functionToStencil SetInput _sphere 
    # This is how the coordinate system/voxel size is set up
    # The first line is copied from a test for this vtk class.
    eval {[ _functionToStencil GetOutput ] SetUpdateExtent} \
        [ [ Volume($v,vol) GetOutput ] GetExtent ]
    eval {[ _functionToStencil GetOutput ] SetSpacing} \
        [ [ Volume($v,vol) GetOutput ] GetSpacing ]
    _functionToStencil Update
    #puts [[ _functionToStencil GetOutput ] Print]
    #_functionToStencil Print

    # Use the stencil to mask the working labelmap.
    # This adds a sphere.
    catch {vtkImageStencil _stencil}
    # The Ed(editor) object does the following line.
    #_stencil SetInput [ Volume($w,vol) GetOutput ]
    # Pass through (unchanged) the labelmap outside of the sphere
    _stencil ReverseStencilOn
    _stencil SetStencil [ _functionToStencil GetOutput ]
    # in the sphere (the "background"), use this label value
    _stencil SetBackgroundValue $label
    #_stencil Update
}
    # Text on the progress bar
    set Gui(progressText) "Draw sphere on [Volume($w,node) GetName]"

    # progress bar
    MainStartProgress

    if {0} {
    # Update the filter pipeline
    # This line makes sure our pipeline has the correct input volume.
    # I thought this would be handled by EdSetupBeforeApplyEffect but 
    # it isn't.
    Ed(editor) SetInput [ Volume($w,vol) GetOutput ]
    Ed(editor) UseInputOn
    # changes for vtk 5 compatibility
    Ed(editor) Apply  _stencil _stencil
}
    catch {_egd Delete}
    vtkEditorGeometryDrawSphere _egd
    _egd SetVol Volume($w,vol)
    _egd SetEd Ed(editor)
    _egd ApplySphere $i $j $k $radius $label 
# Volume($w,vol) Ed(editor)

    # progress bar
    MainEndProgress
    
    # Copied from other editor submodules. Disconnects (a bit of the) pipeline.
    Ed(editor)  SetInput ""
    Ed(editor)  UseInputOff

    # This allows undoing and puts the output into the working volume.
    EdUpdateAfterApplyEffect $v

    if {0} {
    # Putting the output into a slicer volume is done in EdUpdateAfterApplyEffect.
    # However it leaves the pipeline hooked up, so its filters never delete.
    # This caused a memory leak when we created new temporary objects here.  
    # So detach the pipeline with a data copy.
    vtkImageData _tmp
    _tmp DeepCopy [ _stencil GetOutput ] 
}
    # Get rid of external object reference counting to our temp objects
    Ed(editor)  SetFirstFilter ""
    Ed(editor)  SetLastFilter ""

    if {0} {
    # Delete temporary "local" objects (names begin with underscores).
    _stencil Delete
    _functionToStencil Delete
    _sphere Delete

    # Now that the pipeline is gone, put the output into the correct place for slicer.
    Volume($w,vol) SetImageData  _tmp
    # This does not really get rid of the object as Volume($w,vol) has
    # a reference to it already.
    _tmp Delete
}
    # This does not need to be done as EdUpdateAfterApplyEffect does it.
    # Mark the volume as changed
    #set Volume($w,dirty) 1
    # Update pipeline and GUI
    #MainVolumesUpdate $w
    # Render
    #RenderAll

}

#-------------------------------------------------------------------------------
# .PROC EdGeometryDrawApplyFromClick
# This procedure is called by the bindings on the 2D slices, 
# when the mouse is clicked.  It calls the appropriate drawing 
# procedure depending on the tab that is open (right now there is
# only the sphere drawing tab).  The clicked point is rounded to the 
# nearest voxel center so that all shapes drawn with a certain radius
# will have the same volume.
# .ARGS
# float r first coordinate of clicked point in world coordinates
# float a second coordinate of clicked point in world coordinates
# float s third coordinate of clicked point in world coordinates
# .END
#-------------------------------------------------------------------------------
proc EdGeometryDrawApplyFromClick {r a s} {

    global Ed EdGeometryDraw Volume Label

    # Validate input
    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Output label is not an integer."
        return
    }

    puts "world: $r $a $s"

    # Our input is in world coordinates.
    # Convert this to ijk coordinates of current volumes.
    vtkTransform _transform
    set v [ EditorGetOriginalID ]
    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    _transform SetMatrix [ Volume($v,node) GetWldToIjk ]
    # Transform to ijk space
    set point [ _transform TransformPoint $r $a $s ]
    _transform Delete
    scan "$point" "%f %f %f" i j k

    # We choose to draw shapes centered on a voxel. Otherwise due
    # to differences in click position, which affect how the shape
    # intersects the voxels, the output can slightly vary and give
    # different voxel volumes for two clicks with the same radius.  
    # So round the i,j,k coordinates here to choose the voxel center.
    set i [expr round($i)]
    set j [expr round($j)]
    set k [expr round($k)]

    # Transform to scaled ijk space
    set scale [ Volume($v,node) GetSpacing ]
    scan "$scale" "%f %f %f" si sj sk
    set i [expr $i * $si]
    set j [expr $j * $sj]
    set k [expr $k * $sk]
    
    puts "ijk: $i $j $k"

    # Figure out which Draw tab we are on.
    # Right now there is only the sphere tab but others can be added.
    set frameName $Ed(EdGeometryDraw,frame)

    puts $EdGeometryDraw(TabbedFrame,$frameName,tab)

    # Call the appropriate geometry draw function depending on tab
    switch $EdGeometryDraw(TabbedFrame,$frameName,tab) {

        "Sphere" {
            # Validate sphere-specific input
            if {[ValidateFloat $EdGeometryDraw(sphere,radius)] == 0} {
                tk_messageBox -message "Radius is not a number."
                return
            }
            
            # Apply the sphere drawing
            EdGeometryDrawSphere $i $j $k \
                $EdGeometryDraw(sphere,radius) $Label(label)
        }
        
    }

}

