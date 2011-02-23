#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: TkInteractor.tcl,v $
#   Date:      $Date: 2006/03/06 19:22:51 $
#   Version:   $Revision: 1.37 $
# 
#===============================================================================
# FILE:        TkInteractor.tcl
# PROCEDURES:  
#   CreateAndBindTkEvents  widget
#   Expose widget
#   Render
#   UpdateRenderer widget x y
#   Enter widget x y
#   Leave widget x y
#   StartMotion widget x y
#   EndMotion widget x y
#   Rotate widget x y
#   Pitch widget x y
#   Yaw widget x y
#   Roll widget x y
#   LR widget x y
#   BF widget x y
#   UD widget x y
#   Pan widget x y
#   Zoom widget x y
#   Reset widget x y
#   Wireframe
#   Surface
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC CreateAndBindTkEvents 
# 
#  This procedure creates 3 types of event sets:<br>
#  - regular events set: events that are always associated with the widget
#     ( e.g KeyPress-u brings up the interactor)<br>
#  - mouse click event set: events associated with mouse buttons pressed or 
#    released. If a Csys is selected, the motion events will be applied to the
#    selected Csys. Otherwise, the motion events are applied to the virtual
#    camera of the renderer where the user clicked the mouse. <br>
#  - motion events set: events to interact with the selected item from the 
#    mouse click event (either a Csys or a virtual camera).<br>
# <br>
#   Then those 3 event sets are bound to the widget and all 3 bindings 
#   are activated
# .ARGS
# windowpath widget the window for which to make bindings
# .END
#-------------------------------------------------------------------------------
proc CreateAndBindTkEvents { widget } {
    global Gui Ev
    
    EvDeclareEventHandler tkMouseClickEvents <Any-ButtonPress> {StartMotion %W %x %y}
    EvDeclareEventHandler tkMouseClickEvents <Any-ButtonRelease> {EndMotion %W %x %y}
    EvDeclareEventHandler tkMotionEvents <B1-Motion> {Rotate %W %x %y}
    EvDeclareEventHandler tkMotionEvents <B2-Motion> {Pan %W %x %y}
    EvDeclareEventHandler tkMotionEvents <B3-Motion> {Zoom %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Alt-B1-Motion> {Pan %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Control-B1-Motion> {LR %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Control-B2-Motion> {UD %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Control-B3-Motion> {BF %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Shift-B1-Motion> {Pitch %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Shift-B2-Motion> {Roll %W %x %y}
    EvDeclareEventHandler tkMotionEvents <Shift-B3-Motion> {Yaw %W %x %y}

    EvDeclareEventHandler tkRegularEvents <KeyPress-r> {Reset %W %x %y}
    EvDeclareEventHandler tkRegularEvents <KeyPress-u> {wm deiconify .vtkInteract}
    EvDeclareEventHandler tkRegularEvents <KeyPress-w> Wireframe
    EvDeclareEventHandler tkRegularEvents <KeyPress-s> Surface
    EvDeclareEventHandler tkRegularEvents <Control-s> Save3DImage
    EvDeclareEventHandler tkRegularEvents <Enter> {Enter %W %x %y;}
    EvDeclareEventHandler tkRegularEvents <Leave> {Leave %W %x %y;}
    EvDeclareEventHandler tkRegularEvents <Expose> {Expose %W}

  # jeanette 
    
    if { [IsModule Endoscopic] == 1 } {
    EvDeclareEventHandler tkRegularEvents <KeyPress-t> { if { [SelectPick Endoscopic(picker) %W %x %y] != 0 } \
    { eval EndoscopicAddTargetFromWorldCoordinates [lindex $Select(xyz) 0] [lindex $Select(xyz) 1] [lindex $Select(xyz) 2]}}
    }
     
  # end
  
    if {[IsModule Fiducials] == 1 ||[IsModule Alignments] == 1} {
        EvDeclareEventHandler tkRegularEvents <KeyPress-p> { 
            if { [SelectPick Fiducials(picker) %W %x %y] != 0 } \
                { eval FiducialsCreatePointFromWorldXYZ "default" $Select(xyz) ; MainUpdateMRML; Render3D}
        }
    
        EvDeclareEventHandler tkRegularEvents <KeyPress-q> {
            if { [SelectPick Fiducials(picker) %W %x %y] != 0} \
                {FiducialsSelectionFromPicker $Select(actor) $Select(cellId)}
        }
    
        EvDeclareEventHandler tkRegularEvents <KeyPress-d> {
            if { [SelectPick Fiducials(picker) %W %x %y] != 0} \
                {FiducialsDeleteFromPicker $Select(actor) $Select(cellId)}
        }
    }

     # surreal: added for Navigator module
     if {[IsModule Navigator] == 1} {
       EvDeclareEventHandler tkRegularEvents <KeyPress-n> { 
           vtkCellPicker TempCellPicker
           # have to have really low tolerance or the picker will
           # pick cell 0 by default
           TempCellPicker SetTolerance 0.0001
           if { [SelectPick TempCellPicker %W %x %y] != 0} {
               puts "CreateAndBindTkEvents: Navigator: not a slice"
               set x [lindex $Select(xyz) 0]
               set y [lindex $Select(xyz) 1]
               set z [lindex $Select(xyz) 2]
               NavigatorPick3DPoint %W $x $y $z
           }
           TempCellPicker Delete       
       }
     }


    ###### binding of event set that contains all the regular events ######
    EvAddWidgetToBindingSet bindTkRegularAndMotionEvents $widget {{tkMouseClickEvents} {tkMotionEvents} {tkRegularEvents}}
    
    ###### binding of event set that contains all the motion events #######
    EvAddWidgetToBindingSet bindTkRegularEvents $widget {tkRegularEvents}
    
    #### activate the regular and motion events binding 
    #### (should be deactivated when a new set of motion events are to be used
    ####  instead, see tcl-modules/Endoscopic.tcl for example)
    EvActivateBindingSet bindTkRegularAndMotionEvents 
}

#-------------------------------------------------------------------------------
# .PROC Expose
# a litle more complex than just "bind $widget <Expose> {%W Render}"
# we have to handle all pending expose events otherwise they queue up.
# .ARGS
# windowpath widget element to operate upon
# .END
#-------------------------------------------------------------------------------
proc Expose {widget} {

   if {[::vtk::get_widget_variable_value $widget InExpose] == 1} {
      return
   }
   ::vtk::set_widget_variable_value $widget InExpose 1
   update
   [$widget GetRenderWindow] Render
   ::vtk::set_widget_variable_value $widget InExpose 0
}
 
# Global variable keeps track of whether active renderer was found
set RendererFound 0

#-------------------------------------------------------------------------------  
# .PROC Render
# Set the current light's position and focal point, then call Render3D.
#
# .ARGS  
# .END  
#-------------------------------------------------------------------------------  
proc Render {} {
    global CurrentCamera CurrentLight CurrentRenderWindow
    global View

    eval $CurrentLight SetPosition [$CurrentCamera GetPosition]
    eval $CurrentLight SetFocalPoint [$CurrentCamera GetFocalPoint]

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC UpdateRenderer
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc UpdateRenderer {widget x y} {
    global CurrentCamera CurrentLight 
    global CurrentRenderWindow CurrentRenderer
    global RendererFound LastX LastY
    global WindowCenterX WindowCenterY

    # Get the renderer window dimensions
    set WindowX [lindex [$widget configure -width] 4]
    set WindowY [lindex [$widget configure -height] 4]

    # Find which renderer event has occurred in
    set CurrentRenderWindow [$widget GetRenderWindow]
    set renderers [$CurrentRenderWindow GetRenderers]
    set numRenderers [$renderers GetNumberOfItems]

    $renderers InitTraversal; set RendererFound 0
    for {set i 0} {$i < $numRenderers} {incr i} {
    set CurrentRenderer [$renderers GetNextItem]
    set vx [expr double($x) / $WindowX]
    set vy [expr ($WindowY - double($y)) / $WindowY]
    set viewport [$CurrentRenderer GetViewport]
    set vpxmin [lindex $viewport 0]
    set vpymin [lindex $viewport 1]
    set vpxmax [lindex $viewport 2]
    set vpymax [lindex $viewport 3]
    if { $vx >= $vpxmin && $vx <= $vpxmax && \
    $vy >= $vpymin && $vy <= $vpymax} {
            set RendererFound 1
            set WindowCenterX [expr double($WindowX)*(($vpxmax - $vpxmin)/2.0\
                                + $vpxmin)]
            set WindowCenterY [expr double($WindowY)*(($vpymax - $vpymin)/2.0\
                        + $vpymin)]
            break
        }
    }
    
    set CurrentCamera [$CurrentRenderer GetActiveCamera]
    set lights [$CurrentRenderer GetLights]
    $lights InitTraversal; set CurrentLight [$lights GetNextItem]

    set LastX $x
    set LastY $y
}

#-------------------------------------------------------------------------------
# .PROC Enter
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Enter {widget x y} {
    global oldFocus Gui

    if { !$Gui(pc) } {
        set oldFocus [focus]
        focus $widget
    }
    UpdateRenderer $widget $x $y
}

#-------------------------------------------------------------------------------
# .PROC Leave
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Leave {widget x y} {
    global oldFocus Gui

    if { !$Gui(pc) } {
        focus $oldFocus
    }
}

#-------------------------------------------------------------------------------
# .PROC StartMotion
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc StartMotion {widget x y} {
    global CurrentCamera CurrentLight 
    global CurrentRenderWindow CurrentRenderer
    global LastX LastY
    global RendererFound

    focus $widget

    # check to see if a csys is selected
    # if a csys was selected (indicated by the fact that the call to 
    # CsysActorSelected returns a 1), then a new event handler is activated 
    # to handle the motion of the csys until the mouse button is released 
    # (at which point the usual event handler becomes active again)

    if { [CsysActorSelected $widget $x $y] == 0} {

        # if no Csys was selected, update the renderer as usual
        UpdateRenderer $widget $x $y

        if { ! $RendererFound } { return }
        
        $CurrentRenderWindow SetDesiredUpdateRate 5.0
    }
}

#-------------------------------------------------------------------------------
# .PROC EndMotion
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc EndMotion {widget x y} {
    global CurrentRenderWindow
    global RendererFound

    if { ! $RendererFound } {return}
    $CurrentRenderWindow SetDesiredUpdateRate 0.01
    Render
}

#-------------------------------------------------------------------------------
# .PROC Rotate
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Rotate {widget x y} {
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module

    if { ! $RendererFound } { return }

    if { [info exists ::FiducialEventHandled] && $::FiducialEventHandled } { 
        # special flag to handle point widget - TODO: generalize
        set ::FiducialEventHandled 0
        return
    }
    
    $CurrentCamera Azimuth [expr ($LastX - $x)]
    $CurrentCamera Elevation [expr ($y - $LastY)]
    $CurrentCamera OrthogonalizeViewUp

    set LastX $x
    set LastY $y

    # Call each Module's "CameraMotion" routine
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,procCameraMotion)] == 1} {
            $Module($m,procCameraMotion)
        }
    }

    Render
}


#-------------------------------------------------------------------------------
# .PROC Pitch
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Pitch {widget x y} {
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module Endoscopic

    if { ! $RendererFound } { return }
    
    if {[info exists Module(Endoscopic,procEnter)] == 1} {
        set tmp $Endoscopic(cam,rxStr) 
        set Endoscopic(cam,rxStr) [expr $tmp + (-$LastY + $y)]
        EndoscopicSetCameraDirection "rx"
        Render3D
        set LastY $y
    }
    
}


#-------------------------------------------------------------------------------
# .PROC Yaw
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Yaw {widget x y} {
    
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module Endoscopic
    
    if { ! $RendererFound } { return }
    
    if {[info exists Module(Endoscopic,procEnter)] == 1} {
        set tmp $Endoscopic(cam,rzStr) 
        set Endoscopic(cam,rzStr) [expr $tmp + (-$LastX + $x)]
        EndoscopicSetCameraDirection "rz"
        Render3D
        set LastX $x
    }

}

#-------------------------------------------------------------------------------
# .PROC Roll
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Roll {widget x y} {
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module Endoscopic
    
    if { ! $RendererFound } { return }
   
    if {[info exists Module(Endoscopic,procEnter)] == 1} {
        set tmp $Endoscopic(cam,ryStr) 
        set Endoscopic(cam,ryStr) [expr $tmp + (-$LastX + $x)]
        EndoscopicSetCameraDirection "ry"
        Render3D
        set LastX $x
   }
    
}


#-------------------------------------------------------------------------------
# .PROC LR
# Sets the Endoscopic camera X position. 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc LR {widget x y} {
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module Endoscopic


    if { ! $RendererFound } { return }
    
    if {[info exists Module(Endoscopic,procEnter)] == 1} {    
        set tmp $Endoscopic(cam,xStr) 
        set Endoscopic(cam,xStr) [expr $tmp + ($LastX - $x)]
        EndoscopicSetCameraPosition
        Render3D
        
        set LastX $x
   }

}


#-------------------------------------------------------------------------------
# .PROC BF
# Set's the endocsopic camera's Y position
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc BF {widget x y} {
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module Endoscopic


    if { ! $RendererFound } { return }
    
    if {[info exists Module(Endoscopic,procEnter)] == 1} {   
        set tmp $Endoscopic(cam,yStr) 
        set Endoscopic(cam,yStr) [expr $tmp + (-$LastY + $y)]
        EndoscopicSetCameraPosition
        Render3D
        set LastY $y    
    }
    
}


#-------------------------------------------------------------------------------
# .PROC UD
# Set's the endoscopic camera's Z position
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc UD {widget x y} {
    global CurrentCamera 
    global LastX LastY
    global RendererFound
    global View Module Endoscopic


    if { ! $RendererFound } { return }
    
    if {[info exists Module(Endoscopic,procEnter)] == 1} {   
        set tmp $Endoscopic(cam,zStr) 
        set Endoscopic(cam,zStr) [expr $tmp + ($LastY - $y)]
        EndoscopicSetCameraPosition
        Render3D
        
        set LastY $y
    }

}

#-------------------------------------------------------------------------------
# .PROC Pan
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Pan {widget x y} {
    global CurrentRenderer CurrentCamera
    global WindowCenterX WindowCenterY LastX LastY
    global RendererFound
    global View Module

    if { ! $RendererFound } { return }

    if { [info exists ::FiducialEventHandled] && $::FiducialEventHandled } { 
        # special flag to handle point widget - TODO: generalize
        set ::FiducialEventHandled 0
        return
    }

    set FPoint [$CurrentCamera GetFocalPoint]
    set FPoint0 [lindex $FPoint 0]
    set FPoint1 [lindex $FPoint 1]
    set FPoint2 [lindex $FPoint 2]

    set PPoint [$CurrentCamera GetPosition]
    set PPoint0 [lindex $PPoint 0]
    set PPoint1 [lindex $PPoint 1]
    set PPoint2 [lindex $PPoint 2]

    $CurrentRenderer SetWorldPoint $FPoint0 $FPoint1 $FPoint2 1.0
    $CurrentRenderer WorldToDisplay
    set DPoint [$CurrentRenderer GetDisplayPoint]
    set focalDepth [lindex $DPoint 2]

    set APoint0 [expr $WindowCenterX + ($x - $LastX)]
    set APoint1 [expr $WindowCenterY - ($y - $LastY)]

    $CurrentRenderer SetDisplayPoint $APoint0 $APoint1 $focalDepth
    $CurrentRenderer DisplayToWorld
    set RPoint [$CurrentRenderer GetWorldPoint]
    set RPoint0 [lindex $RPoint 0]
    set RPoint1 [lindex $RPoint 1]
    set RPoint2 [lindex $RPoint 2]
    set RPoint3 [lindex $RPoint 3]
    if { $RPoint3 != 0.0 } {
        set RPoint0 [expr $RPoint0 / $RPoint3]
        set RPoint1 [expr $RPoint1 / $RPoint3]
        set RPoint2 [expr $RPoint2 / $RPoint3]
    }

    $CurrentCamera SetFocalPoint \
      [expr ($FPoint0 - $RPoint0)/2.0 + $FPoint0] \
      [expr ($FPoint1 - $RPoint1)/2.0 + $FPoint1] \
      [expr ($FPoint2 - $RPoint2)/2.0 + $FPoint2]

    $CurrentCamera SetPosition \
      [expr ($FPoint0 - $RPoint0)/2.0 + $PPoint0] \
      [expr ($FPoint1 - $RPoint1)/2.0 + $PPoint1] \
      [expr ($FPoint2 - $RPoint2)/2.0 + $PPoint2]

    set LastX $x
    set LastY $y

   # only move the annotations if the mainView camera is panning
    if {[info exists View(viewCam)] == 1} {
        if {$CurrentCamera == $View(viewCam)} {
            MainAnnoUpdateFocalPoint $FPoint0 $FPoint1 $FPoint2
        }
    }

    # Call each Module's "CameraMotion" routine
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,procCameraMotion)] == 1} {
            $Module($m,procCameraMotion)
        }
    }

    Render
}




#-------------------------------------------------------------------------------
# .PROC Zoom
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Zoom {widget x y} {
    global CurrentCamera
    global LastX LastY
    global RendererFound
    global View Module

    if {$::View(parallelProjection) == 1} {
        if {$::Module(verbose)} { 
            puts "TkInteractor Zoom: parallel proj on = $::View(parallelProjection), no zooming allowed" 
        }
        return
    }

    if { ! $RendererFound } { return }

    if { [info exists ::FiducialEventHandled] && $::FiducialEventHandled } { 
        # special flag to handle point widget - TODO: generalize
        set ::FiducialEventHandled 0
        return
    }

    set zoomFactor [expr pow(1.02,($y - $LastY))]
    set clippingRange [$CurrentCamera GetClippingRange]
    set minRange [lindex $clippingRange 0]
    set maxRange [lindex $clippingRange 1]

    $CurrentCamera SetClippingRange [expr $minRange / $zoomFactor] \
                                    [expr $maxRange / $zoomFactor]
    $CurrentCamera Dolly $zoomFactor
    
    if {[$CurrentCamera GetParallelProjection] == 1} {
        $CurrentCamera SetParallelScale \
            [expr [$CurrentCamera GetParallelScale] / $zoomFactor]
    }


    set LastX $x
    set LastY $y

    # Call each Module's "CameraMotion" routine
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,procCameraMotion)] == 1} {
            $Module($m,procCameraMotion)
        }
    }

   Render
}



#-------------------------------------------------------------------------------
# .PROC Reset
# 
# .ARGS
# windowpath widget
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc Reset {widget x y} {
    global CurrentRenderWindow
    global RendererFound
    global CurrentRenderer

    # Get the renderer window dimensions
    set WindowX [lindex [$widget configure -width] 4]
    set WindowY [lindex [$widget configure -height] 4]

    # Find which renderer event has occurred in
    set CurrentRenderWindow [$widget GetRenderWindow]
    set renderers [$CurrentRenderWindow GetRenderers]
    set numRenderers [$renderers GetNumberOfItems]

    $renderers InitTraversal; set RendererFound 0
    for {set i 0} {$i < $numRenderers} {incr i} {
    set CurrentRenderer [$renderers GetNextItem]
    set vx [expr double($x) / $WindowX]
    set vy [expr ($WindowY - double($y)) / $WindowY]

    set viewport [$CurrentRenderer GetViewport]
    set vpxmin [lindex $viewport 0]
    set vpymin [lindex $viewport 1]
    set vpxmax [lindex $viewport 2]
    set vpymax [lindex $viewport 3]
    if { $vx >= $vpxmin && $vx <= $vpxmax && \
                $vy >= $vpymin && $vy <= $vpymax} {
            set RendererFound 1
            break
        }
    }

    if { $RendererFound } {$CurrentRenderer ResetCamera}

    Render
}

#-------------------------------------------------------------------------------
# .PROC Wireframe
# Set all actors in the current renderer to be represented as wire frame, then Render. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Wireframe {} {
    global CurrentRenderer

    set actors [$CurrentRenderer GetActors]

    $actors InitTraversal
    set actor [$actors GetNextItem]
    while { $actor != "" } {
        [$actor GetProperty] SetRepresentationToWireframe
        set actor [$actors GetNextItem]
    }

    Render
}

#-------------------------------------------------------------------------------
# .PROC Surface
# Set all actors in the current renderer to be represented as surfaces, then Render. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Surface {} {
    global CurrentRenderer

    set actors [$CurrentRenderer GetActors]

    $actors InitTraversal
    set actor [$actors GetNextItem]
    while { $actor != "" } {
        [$actor GetProperty] SetRepresentationToSurface
        set actor [$actors GetNextItem]
    }

    Render
}
