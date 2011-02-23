#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareInteractor.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:23 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareInteractor.tcl
# PROCEDURES:  
#   CompareInteractorInit
#   CompareInteractorBind TkWidget
#   CompareInteractorXY int int int 'xs ys) the y) means
#   CompareInteractorCursor int int int int int
#   CompareInteractorMultiCursor
#   CompareInteractorKeyPress string TkWidget
#   CompareInteractorMotion TkWidget int int
#   CompareInteractorB2Motion TkWidget int int
#   CompareInteractorB3Motion TkWidget int int
#   CompareInteractorPan int int int int int
#   CompareInteractorZoom int int int int int
#   CompareInteractorExpose TkWidget
#   CompareInteractorRender
#   CompareInteractorEnter TkWidget int int
#   CompareInteractorExit TkWidget
#   CompareInteractorStartMotion TkWidget int int
#   CompareInteractorEndMotion TkWidget int int
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC CompareInteractorInit
# Set CompareInteractor array to the proper initial values.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorInit {} {
    global CompareInteractor Module

    set CompareInteractor(s)      0
    set CompareInteractor(xLast)  0
    set CompareInteractor(yLast)  0
    set CompareInteractor(xsLast) 0
    set CompareInteractor(ysLast) 0
}

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
# CompareInteractor(s)               : active slice id
# CompareInteractor(xLast)           : x coordinate for last screen point
# CompareInteractor(yLast)           : y coordinate for last screen point
# CompareInteractor(x)               : x coordinate for current screen point
# CompareInteractor(y)               : y coordinate for current screen point

#-------------------------------------------------------------------------------
# .PROC CompareInteractorBind
# Binds actions to event occuring on the parameter widget
#
# .ARGS
# widget TkWidget The widget to bind (cf Slices and Mosaik building in CompareViewer.tcl)
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorBind {widget} {

    # Cursor
    bind $widget <Enter>             {CompareInteractorEnter %W %x %y;}
    bind $widget <Leave>             {CompareInteractorExit %W}
    bind $widget <Expose>            {CompareInteractorExpose %W}
    bind $widget <Motion>            {CompareInteractorMotion %W %x %y}
    bind $widget <Any-ButtonPress>   {CompareInteractorStartMotion %W %x %y}
    bind $widget <Any-ButtonRelease> {CompareInteractorEndMotion %W %x %y}

    # B2
   bind $widget <B2-Motion>          {CompareInteractorB2Motion %W %x %y}

    # B3
   bind $widget <B3-Motion>          {CompareInteractorB3Motion %W %x %y}

    # Shift-B1
    bind $widget <Shift-B1-Motion>   {CompareInteractorB2Motion %W %x %y}

    # Keyboard
    bind $widget <Left>              {CompareInteractorKeyPress Left  %W %x %y}
    bind $widget <Right>             {CompareInteractorKeyPress Right %W %x %y}
    bind $widget <KeyPress-g>        {CompareInteractorKeyPress g %W %x %y}
    bind $widget <KeyPress-r>        {CompareInteractorKeyPress r %W %x %y}
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorXY
# Converts a screen point coordinates to Reformatted image coodinates
#
# .ARGS
# s int The considered slice id
# x int The screen point abscisse
# y int The screen point ordonnee
#
# returns 'xs ys x y'
#
# (xs, ys) is the point relative to the lower, left corner
# of the slice window (0-255 or 0-511).
#
# (x, y) is the point with Zoom and Double taken into consideration
# (zoom=2 means range is 64-128 instead of 1-256)
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorXY {s x y} {
    global CompareInteractor

    # Compute screen coordinates
    set y [expr $CompareInteractor(ySize) - 1 - $y]
    set xs $x
    set ys $y

    # Convert Screen coordinates to Reformatted image coordinates
    $CompareInteractor(activeSlicer) SetScreenPoint $s $x $y
    scan [$CompareInteractor(activeSlicer) GetReformatPoint] "%d %d" x y

    return "$xs $ys $x $y"
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorCursor
# 1. Use reformatted coordinates (x and y arguments) to compute RAS, IJK or
# XY coordinates
# 2. Updates annotation mappers input (for pixel coordinates and
# values)
# 3. Moves cursor according to screen point coordinates
#
# .ARGS
# s int the considered slice (i-e the slice on which the mouse cursor is)
# xs int The screen point abscisse (used only to move the cursor [display])
# ys int The screen point ordonnee (used only to move the cursor [display])
# x int The reformatted point abscisse (cf. CompareInteractorXY)
# y int The reformatted point ordonnee (cf. CompareInteractorXY)
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorCursor {s xs ys x y} {
    global CompareSlice CompareAnno CompareInteractor CompareMosaik CompareViewer

    # pixel value
    set forePix [$CompareInteractor(activeSlicer) GetForePixel $s $x $y]
    set backPix [$CompareInteractor(activeSlicer) GetBackPixel $s $x $y]

    # pixel display format from scalar type
    set id VolID
    set f PixelDispFormat

    foreach m "back fore" {
        if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
            set v $CompareSlice($s,$m$id)
        } else {
            set v $CompareMosaik($m$id)
        }
        if {$v} {
            set scalarType [Volume($v,node) GetScalarType]
            set b [expr {$scalarType == 10 || $scalarType == 11}]
            # if the data is real, display first 2 decimals
            if { ($b == 1) && ($CompareAnno(pixelDispFormat) == "%.f") }  {
                set CompareAnno($m$f) "%6.2f"
            } else {
                set CompareAnno($m$f) $CompareAnno(pixelDispFormat)
            }
        }
    }

    # Get RAS and IJK coordinates
    $CompareInteractor(activeSlicer) SetReformatPoint $s $x $y
    scan [$CompareInteractor(activeSlicer) GetWldPoint] "%g %g %g" xRas yRas zRas
    scan [$CompareInteractor(activeSlicer) GetIjkPoint] "%g %g %g" xIjk yIjk zIjk

    # Write Annotation
    foreach name "$CompareAnno(mouseList)" {
        if {$name != "msg"} {
            # Warning: actor may not exist yet, so check!
            if {[info command CompareAnno($s,$name,actor)] != ""} {
                CompareAnno($s,$name,actor) SetVisibility 1
            }
        }
    }
    if {[info command CompareAnno($s,cur1,mapper)] != ""} {
        switch $CompareAnno(cursorMode) {
            "RAS" {
                CompareAnno($s,cur1,mapper) SetInput [format "R %.f" $xRas]
                CompareAnno($s,cur2,mapper) SetInput [format "A %.f" $yRas]
                CompareAnno($s,cur3,mapper) SetInput [format "S %.f" $zRas]
            }
            "IJK" {
                CompareAnno($s,cur1,mapper) SetInput [format "I %.f" $xIjk]
                CompareAnno($s,cur2,mapper) SetInput [format "J %.f" $yIjk]
                CompareAnno($s,cur3,mapper) SetInput [format "K %.f" $zIjk]
            }
            "XY" {
                CompareAnno($s,cur1,mapper) SetInput [format "X %.f" $x]
                CompareAnno($s,cur2,mapper) SetInput [format "Y %.f" $y]
                CompareAnno($s,cur3,mapper) SetInput " "
            }
        }
    }
    if {[info command CompareAnno($s,curBack,mapper)] != ""} {
        if {$CompareAnno(backPixelDispFormat) == "%f"} {
            CompareAnno($s,curBack,mapper) SetInput "Bg $backPix"
            CompareAnno($s,curFore,mapper) SetInput "Fg $forePix"
        } else {
            CompareAnno($s,curBack,mapper) SetInput \
                [format "Bg $CompareAnno(backPixelDispFormat)" $backPix]
            CompareAnno($s,curFore,mapper) SetInput \
                [format "Fg $CompareAnno(forePixelDispFormat)" $forePix]
        }

    }

    # replace raw value by label value if a label map is displayed on
    # back or/and fore layer
    set backnode [[$CompareInteractor(activeSlicer) GetBackVolume $s] GetMrmlNode]
    set ::CompareAnno(curBack,label) ""
    if { [$backnode GetLUTName] == -1 } {
        set curtext [CompareAnno($s,curBack,mapper) GetInput]
        set labelid [MainColorsGetColorFromLabel $backPix]
        if { $labelid != "" } {
            set label [Color($labelid,node) GetName]
        } else {
            set label unknown
        }
        CompareAnno($s,curBack,mapper) SetInput "$curtext : $label"
        set ::CompareAnno(curBack,label) $label
    } else {
        set ::CompareAnno(curBack,label) ""
    }
    set forenode [[$CompareInteractor(activeSlicer) GetForeVolume $s] GetMrmlNode]
    set ::CompareAnno(curFore,label) ""
    if { [$forenode GetLUTName] == -1 } {
        set curtext [CompareAnno($s,curFore,mapper) GetInput]
        set labelid [MainColorsGetColorFromLabel $forePix]
        if { $labelid != "" } {
            set label [Color($labelid,node) GetName]
        } else {
            set label unknown
        }
        CompareAnno($s,curFore,mapper) SetInput "$curtext : $label"
        set ::CompareAnno(curFore,label) $label
    } else {
        set ::CompareAnno(curFore,label) ""
    }

    # Move cursor
    $CompareInteractor(activeSlicer) SetCursorPosition $s $xs $ys
}





#-------------------------------------------------------------------------------
# .PROC CompareInteractorMultiCursor
# Procedure used to display cursor and annotations on every slice in linked
# mode. Cf CompareInteractorCursor for detailed processing
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorMultiCursor {xs ys x y} {
    global CompareSlice CompareAnno CompareInteractor CompareViewer

    for {set s 0} {$s < $CompareViewer(mode)} {incr s} {
        CompareInteractorCursor $s $xs $ys $x $y
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorKeyPress
#
# Called when a key is pressed .
# Deals with Left, Right, g and r.
#
# Left and Right moves the slice offset.
# r resets zoom and pan
# g toggles the fading
#
# .ARGS
# key string The key pressed
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor is when the key is pressed
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorKeyPress {key widget x y} {
    global CompareSlice CompareInteractor CompareViewer

    focus $widget

    set s $CompareInteractor(s)
    if {$s == ""} {return}

    CompareInteractorMotion $widget $x $y

    switch $key {
        "Right" {
            scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y
            if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
            if {$CompareViewer(linked) == "off"} {
               CompareSlicesSetOffset $s Next;
               CompareInteractorCursor $s $xs $ys $x $y
            } else {
               CompareSlicesSetOffsetAll Next;
               CompareInteractorMultiCursor $xs $ys $x $y
            }
            } else {
               CompareMosaikSetOffset Next;
               CompareInteractorCursor $s $xs $ys $x $y
            }

            CompareInteractorRender
        }
        "Left" {
            scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y
            if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
            if {$CompareViewer(linked) == "off"} {
               CompareSlicesSetOffset $s Prev;
               CompareInteractorCursor $s $xs $ys $x $y
            } else {
               CompareSlicesSetOffsetAll Prev;
               CompareInteractorMultiCursor $xs $ys $x $y
            }
            } else {
               CompareMosaikSetOffset Prev;
               CompareInteractorCursor $s $xs $ys $x $y
            }

            CompareInteractorRender
        }
        "g" {
            # call the toggle between fore and background volumes
            if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
                CompareSlicesSetOpacityToggle
                CompareRenderSlices
            } else {
                CompareMosaikSetOpacityToggle
                CompareRenderMosaik
            }
        }
        "r" {
            # resets zoom and pan
            if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
                CompareSlicesResetZoomAll
                CompareRenderSlices
            } else {
                CompareMosaikResetZoom
                CompareRenderMosaik
            }
        }
   }
}



#-------------------------------------------------------------------------------
# .PROC CompareInteractorMotion
# Procedure called when the mouse cursor is moved over a slice. Retrieves
# the reformatted coordinates and updates cursor and annotations
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor moves
# x int the screen point abscisse
# y int the screen point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorMotion {widget x y} {
    global CompareInteractor CompareViewer CompareMosaik

    set s $CompareInteractor(s)
    scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y

    if {$CompareViewer(linked) == "on" && $CompareViewer(multiOrMosaik) == "multiSlice"} {
        CompareInteractorMultiCursor $xs $ys $x $y
    } else {
        CompareInteractorCursor $s $xs $ys $x $y
    }

    # Render this slice
    CompareInteractorRender
}


#-------------------------------------------------------------------------------
# .PROC CompareInteractorB2Motion
# Procedure called when the mouse cursor is moved over a slice, B2 being pressed.
# Retrieves the reformatted coordinates, performs pan and updates cursor and annotations
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor moves
# x int the screen point abscisse
# y int the screen point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorB2Motion {widget x y} {
    global CompareInteractor CompareViewer

    set s $CompareInteractor(s)
    scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y

    if {$CompareViewer(linked) == "on" && $CompareViewer(multiOrMosaik) == "multiSlice"} {
      CompareInteractorPan $s $xs $ys $CompareInteractor(xsLast) $CompareInteractor(ysLast)
      # Cursor
      CompareInteractorMultiCursor $xs $ys $x $y
    } else {
      CompareInteractorPan $s $xs $ys $CompareInteractor(xsLast) $CompareInteractor(ysLast)
      # Cursor
      CompareInteractorCursor $s $xs $ys $x $y
    }

    set CompareInteractor(xLast)  $x
    set CompareInteractor(yLast)  $y
    set CompareInteractor(xsLast) $xs
    set CompareInteractor(ysLast) $ys

    # Render this slice
    CompareInteractorRender
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorB3Motion
# Procedure called when the mouse cursor is moved over a slice, B3 being pressed.
# Retrieves the reformatted coordinates, performs zoom and updates cursor and annotations
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor moves
# x int the screen point abscisse
# y int the screen point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorB3Motion {widget x y} {
    global CompareInteractor Module CompareViewer

    set s $CompareInteractor(s)
    scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y

    # Zoom using screen coordinates so that the same number
    # of screen pixels covered (not % of image) produces the
    # same zoom factor. To put it another way, I want the
    # user to have to drag the mouse a consistent distance
    # across the mouse pad.
    #
    CompareInteractorZoom $s $xs $ys $CompareInteractor(xsLast) $CompareInteractor(ysLast)

    # Cursor

    if {$CompareViewer(linked) == "on" && $CompareViewer(multiOrMosaik) == "multiSlice"} {
      CompareInteractorMultiCursor $xs $ys $x $y
    } else {
      CompareInteractorCursor $s $xs $ys $x $y
    }

    set CompareInteractor(xLast)  $x
    set CompareInteractor(yLast)  $y
    set CompareInteractor(xsLast) $xs
    set CompareInteractor(ysLast) $ys

    # Render this slice
    CompareInteractorRender
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorPan
# Performs pan. Computes pan coefficient depending on (x,y) to (xLast,yLast)
# distance and zoom coefficient
#
# .ARGS
# s int The considered slice id.
# x int The current reformatted point abscisse
# y int The current reformatted point ordonnee
# xLast int The last reformatted point abscisse
# yLast int The last reformatted point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorPan {s x y xLast yLast} {
     global CompareAnno CompareSlice CompareViewer

     set dx [expr $xLast - $x]
     set dy [expr $yLast - $y]
     MultiSlicer GetZoomCenter
     if {$CompareViewer(linked) == "on" && $CompareViewer(multiOrMosaik) == "multiSlice"} {
        # if linking is off
        scan [MultiSlicer GetZoomCenter$s] "%g %g" cx cy

        set z [MultiSlicer GetZoom $s]

        if {$CompareViewer(mode) == "2" || $CompareViewer(mode) == "3" || $CompareViewer(mode) == "4"} {
           set z [expr $z * 2.0]
        }
        set refresh 0

        # TODO : develop specific funtions in order to remove the 2 following loops
        foreach slice $CompareSlice(idList) {
           if {[MultiSlicer GetZoomAutoCenter $slice] == 1} {
               MultiSlicer SetZoomAutoCenter $slice 0
               set refresh 1
               # FIXME : removed and called after only once, using refresh flag
               #MultiSlicer Update
           }
        }
        if {$refresh == 1} {
           MultiSlicer Update
        }
        set cx [expr $cx + $dx / $z]
        set cy [expr $cy + $dy / $z]

        foreach slice $CompareSlice(idList) {
           MultiSlicer SetZoomCenter $slice $cx $cy
        }
     } else {
     # if linking is off
        scan [MultiSlicer GetZoomCenter$s] "%g %g" cx cy

        set z [MultiSlicer GetZoom $s]
        if {$CompareViewer(mode) == "2" || $CompareViewer(mode) == "3" || $CompareViewer(mode) == "4"} {
           set z [expr $z * 2.0]
        }

        if {[MultiSlicer GetZoomAutoCenter $s] == 1} {
           MultiSlicer SetZoomAutoCenter $s 0
           MultiSlicer Update
        }
        set cx [expr $cx + $dx / $z]
        set cy [expr $cy + $dy / $z]
        MultiSlicer SetZoomCenter $s $cx $cy
     }
 }


#-------------------------------------------------------------------------------
# .PROC CompareInteractorZoom
# Performs zoom. Computes zoom coefficient depending on y to yLast
# distance.
#
# .ARGS
# s int The considered slice id.
# x int The current reformatted point abscisse
# y int The current reformatted point ordonnee
# xLast int The last reformatted point abscisse
# yLast int The last reformatted point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorZoom {s x y xLast yLast} {
    global CompareAnno CompareViewer CompareSlice

     set dy [expr $yLast - $y]

     # log base b of x = log(x) / log(b)
     set b      1.02
     set zPrev  [MultiSlicer GetZoom $s]
     set dyPrev [expr log($zPrev) / log($b)]

     set zoom [expr pow($b, ($dy + $dyPrev))]
     if {$zoom < 0.01} {
         set zoom 0.01
     }
     set z [format "%.2f" $zoom]

     CompareAnno($s,msg,mapper)  SetInput "ZOOM: x $z"

     if {$CompareViewer(linked) == "on" && $CompareViewer(multiOrMosaik) == "multiSlice"} {
       foreach slice $CompareSlice(idList) {
          CompareSlicesSetZoom $slice $z
       }
     } else {
       CompareSlicesSetZoom $s $z
     }
 }


#-------------------------------------------------------------------------------
# .PROC CompareInteractorExpose
# a litle more complex than just "bind $widget <Expose> {%W Render}"
# we have to handle all pending expose events otherwise they queue up.
#
# .ARGS
# widget TkWidget The exposed widget
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorExpose {widget} {

   # Do not render if we are already rendering
   if {[::vtk::get_widget_variable_value $widget Rendering] == 1} {
      return
   }

   # empty the que of any other expose events
   ::vtk::set_widget_variable_value $widget Rendering 1
   update
   ::vtk::set_widget_variable_value $widget Rendering 0

   # ignore the region to redraw for now.
   $widget Render
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorRender
# Calls the render procedure, according to the current display settings
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorRender {} {
    global CompareInteractor CompareSlice CompareViewer

    if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
      if {$CompareViewer(linked) == "off"} {
        set s $CompareInteractor(s)
        CompareRenderSlice $s
      } else {
         CompareRenderSlices
      }
    } else {
       CompareRenderMosaik
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorEnter
# Sets several CompareInteractor array values (id, size and center position),
# depending on the widget on which the mouse enters
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor enters
# x int the screen point abscisse
# y int the screen point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorEnter {widget x y} {
    global CompareInteractor Gui CompareViewer CompareMosaik

    # Determine what slice this is
    if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
       set s [string index $widget [expr [string length $widget] - 4]]
       set CompareInteractor(s) $s
    } else {
       set s $CompareMosaik(mosaikIndex)
       set CompareInteractor(s) $s
    }

    # Focus
    # - do click focus on PC, but focus-follows-mouse on unix
    if { !$Gui(pc) } {
        set CompareInteractor(oldFocus) [focus]
        focus $widget
    }

    # Get the renderer window dimensions
    set CompareInteractor(xSize) [lindex [$widget configure -width] 4]
    set CompareInteractor(ySize) [lindex [$widget configure -height] 4]

    set CompareInteractor(xCenter) [expr double($CompareInteractor(xSize))/2.0]
    set CompareInteractor(yCenter) [expr double($CompareInteractor(ySize))/2.0]
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorExit
# Resets display : recenters cursor and turns off annotations
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget from which the mouse cursor exits
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorExit {widget} {
    global CompareInteractor CompareAnno Gui CompareViewer CompareSlice CompareMosaik

    if {$CompareViewer(multiOrMosaik) == "multiSlice"} {
       if {$CompareViewer(linked) == "off"} {
          set s $CompareInteractor(s)

          # Center cursor
          $CompareInteractor(activeSlicer) SetCursorPosition $s \
              [expr int($CompareInteractor(xCenter))] [expr int($CompareInteractor(yCenter))]

          # Turn off cursor anno
          foreach name "$CompareAnno(mouseList)" {
              if {[info command CompareAnno($s,$name,actor)] != ""} {
                  CompareAnno($s,$name,actor) SetVisibility 0
              }
          }
       } else {
          foreach s $CompareSlice(idList) {
             # Center cursor
             $CompareInteractor(activeSlicer) SetCursorPosition $s \
                 [expr int($CompareInteractor(xCenter))] [expr int($CompareInteractor(yCenter))]

             # Turn off cursor anno
             foreach name "$CompareAnno(mouseList)" {
                if {[info command CompareAnno($s,$name,actor)] != ""} {
                    CompareAnno($s,$name,actor) SetVisibility 0
                }
             }
          }
       }
    } else {
      set s $CompareMosaik(mosaikIndex)

       # Center cursor
       $CompareInteractor(activeSlicer) SetCursorPosition $s \
           [expr int($CompareInteractor(xCenter))] [expr int($CompareInteractor(yCenter))]

       # Turn off cursor anno
       foreach name "$CompareAnno(mouseList)" {
           if {[info command CompareAnno($s,$name,actor)] != ""} {
               CompareAnno($s,$name,actor) SetVisibility 0
           }
       }
    }

    # Render
    CompareInteractorRender

    # Return the focus
    if { !$Gui(pc) } {
        focus $CompareInteractor(oldFocus)
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorStartMotion
# Procedure called when the mouse cursor is moved over a TkWidget while
# any button is pressed. Initializes various CompareInteractor values (xLast,
# yLast, xsLast, ysLast).
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor begins moving
# x int the screen point abscisse
# y int the screen point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorStartMotion {widget x y} {
    global CompareInteractor CompareAnno

    set s $CompareInteractor(s)
    CompareSlicesSetActive $s

    scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y
    set CompareInteractor(xLast)  $x
    set CompareInteractor(yLast)  $y
    set CompareInteractor(xsLast) $xs
    set CompareInteractor(ysLast) $ys

    CompareAnno($s,msg,mapper)  SetInput ""
    CompareAnno($s,msg,actor)   SetVisibility 1

    return "$xs $ys $x $y"
}

#-------------------------------------------------------------------------------
# .PROC CompareInteractorEndMotion
#
# .ARGS
# widget TkWidget The vtkTkRenderWidget on which the mouse cursor stops moving
# x int the screen point abscisse
# y int the screen point ordonnee
# .END
#-------------------------------------------------------------------------------
proc CompareInteractorEndMotion {widget x y} {
    global CompareInteractor

    set s $CompareInteractor(s)
    scan [CompareInteractorXY $s $x $y] "%d %d %d %d" xs ys x y

    # Cursor
    CompareInteractorCursor $s $xs $ys $x $y

    CompareAnno($s,msg,actor)  SetVisibility 0

    CompareInteractorRender
}
