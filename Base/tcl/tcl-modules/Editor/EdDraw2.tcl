#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdDraw2.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        EdDraw2.tcl
# PROCEDURES:  
#   EdDraw2Init
#   EdDraw2BuildGUI
#   EdDraw2Enter
#   EdDraw2Exit
#   EdDraw2Label
#   EdDraw2Update
#   EdDraw2Apply
#   EdDraw2Unapply
#   EdDraw2GetSlice
#   EdDraw2SetSlice
#   EdDraw2GetPolynum
#   EdDraw2SetPolynum
#   EdDraw2GetUnapplynum
#   EdDraw2SetUnapplynum
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC EdDraw2Init
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Init {} {
    global Ed

    set e EdDraw2
    set Ed($e,name)      "Draw2"
    set Ed($e,initials)  "D2"
    set Ed($e,desc)      "Draw2: label pixels using a spline outline brush."
    set Ed($e,rank)      4
    set Ed($e,procGUI)   EdDraw2BuildGUI
    set Ed($e,procEnter) EdDraw2Enter
    set Ed($e,procExit)  EdDraw2Exit

    # Required
    set Ed($e,scope) Single 
    set Ed($e,input) Working

    set Ed($e,mode)   Draw
    set Ed($e,delete) Yes
    set Ed($e,radius) 0
    set Ed($e,shape)  Polygon
    set Ed($e,preshape) Polygon
    set Ed($e,render) Active
    set Ed($e,density) 3
    set Ed($e,slice0) -1
    set Ed($e,slice1) -1
    set Ed($e,slice2) -1
    set Ed($e,polynum0) -1
    set Ed($e,polynum1) -1
    set Ed($e,polynum2) -1
    set Ed($e,unapplynum0) -1
    set Ed($e,unapplynum1) -1
    set Ed($e,unapplynum2) -1
    set Ed($e,closed) Closed
    set Ed($e,clear) No
    set Ed($e,spline) Yes

    set Ed($e,eventManager) {}
    
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2BuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2BuildGUI {} {
    global Ed Gui Label Editor

    #-------------------------------------------
    # Draw frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame)

    frame $f.fRender  -bg $Gui(activeWorkspace)
    frame $f.fMode    -bg $Gui(activeWorkspace)
    frame $f.fClear   -bg $Gui(activeWorkspace)
    frame $f.fDelete  -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fBtns    -bg $Gui(activeWorkspace)
    frame $f.fClosed  -bg $Gui(activeWorkspace)
    frame $f.fShape   -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    frame $f.fToggle  -bg $Gui(activeWorkspace)
    frame $f.fSpline  -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fBtns $f.fClosed $f.fMode $f.fClear $f.fDelete \
        $f.fSpline $f.fRender $f.fShape $f.fApply -side top -pady 2 -fill x
    pack $f.fToggle -side bottom -pady 4 -fill x
    
    EdBuildRenderGUI $Ed(EdDraw2,frame).fRender Ed(EdDraw2,render)

    #-------------------------------------------
    # Draw->Mode frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fMode

    frame $f.fMode -bg $Gui(activeWorkspace)
    eval {label $f.fMode.lMode -text "Mode:"} $Gui(WLA)
    pack $f.fMode.lMode -side left -padx 0 -pady 0
    foreach mode "Draw Select Move Insert" {
        eval {radiobutton $f.fMode.r$mode \
            -text "$mode" -variable Ed(EdDraw2,mode) -value $mode \
            -width [expr [string length $mode] +1] \
            -indicatoron 0} $Gui(WCA)
        pack $f.fMode.r$mode -side left -padx 0 -pady 0
    }
    pack $f.fMode -side top -pady 5 -padx 0 

    #-------------------------------------------
    # Draw->Clear frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fClear

    eval {label $f.l -text "Clear labelmap before apply:"} $Gui(WLA)
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach s "Yes No" text "Yes No" width "4 3" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
            -text "$text" -value "$s" -variable Ed(EdDraw2,clear)} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }

    #-------------------------------------------
    # Draw->Delete frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fDelete

    eval {label $f.l -text "Delete points after apply:"} $Gui(WLA)
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach s "Yes No" text "Yes No" width "4 3" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
            -text "$text" -value "$s" -variable Ed(EdDraw2,delete)} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }

    #-------------------------------------------
    # Draw->Grid frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fGrid

    # Output label
    eval {button $f.bOutput -text "Output:" \
        -command "ShowLabels EdDraw2Label"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
        -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdDraw2Label"
    bind $f.eOutput <FocusOut> "EdDraw2Label"
    eval {entry $f.eName -width 14 \
        -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w

    lappend Label(colorWidgetList) $f.eName

    # Radius
    eval {label $f.lRadius -text "Point Radius:"} $Gui(WLA)
    eval {entry $f.eRadius -width 3 \
        -textvariable Ed(EdDraw2,radius)} $Gui(WEA)
        bind $f.eRadius <Return> "EdDraw2Update SetRadius; RenderActive"

    # Sampling density
    eval {label $f.lDensity -width 12 -text "Sample Density:"} $Gui(WLA)
    eval {entry $f.eDensity -width 3 \
        -textvariable Ed(EdDraw2,density)} $Gui(WEA)

    grid $f.lRadius $f.eRadius $f.lDensity $f.eDensity -padx 2 -pady $Gui(pad) -sticky e
    grid $f.eRadius -sticky w
    grid $f.lDensity -sticky e 
    grid $f.eDensity -sticky w

    #-------------------------------------------
    # Draw->Btns frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fBtns

    eval {menubutton $f.mbEdit -text "Edit:" -relief raised -bd 2 \
        -width 6 -menu $f.mbEdit.m} $Gui(WMBA)
    eval {menu $f.mbEdit.m} $Gui(WMA)
    set editMenu $f.mbEdit.m
    $editMenu add command -label "Cut             (CTRL+X)" \
        -command "EdDraw2Update Cut; RenderActive"
    $editMenu add command -label "Copy            (CTRL+C)" \
        -command "EdDraw2Update Copy; RenderActive"
    $editMenu add command -label "Paste           (CTRL+V)" \
        -command "EdDraw2Update Paste; RenderActive"
    $editMenu add command -label "Select All      (CTRL+A)" \
        -command "EdDraw2Update SelectAll; RenderActive"
    $editMenu add command -label "Deselect All" \
        -command "EdDraw2Update DeselectAll; RenderActive"
    $editMenu add command -label "Delete Selected (DELETE)" \
        -command "EdDraw2Update DeleteSelected; RenderActive"
    $editMenu add command -label "Delete All      (CTRL+D)" \
        -command "EdDraw2Update DeleteAll; RenderActive"
    pack $f.mbEdit -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # Draw->Closed frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fClosed

    eval {label $f.clopen -text "Contour Topology:"} $Gui(WLA)
    pack $f.clopen -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach s "Closed Open" text "Closed Open" width "8 6" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
            -command "EdDraw2Update SetShape; RenderActive" \
            -text "$text" -value "$s" -variable Ed(EdDraw2,closed)} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }

    #-------------------------------------------
    # Draw->Spline frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fSpline

    eval {label $f.l -text "Show Spline:"} $Gui(WLA)
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach s "Yes No" text "Yes No" width "4 3" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
            -command "EdDraw2Update SetShape; RenderActive" \
            -text "$text" -value "$s" -variable Ed(EdDraw2,spline)} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }

    #-------------------------------------------
    # Draw->Toggle frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fToggle
    
    set Editor(toggleWorking) 0
    eval {checkbutton $f.cW -width 21 -indicatoron 0 \
        -variable Editor(toggleWorking) \
        -text "peek under labelmap"  \
        -command EditorToggleWorking} $Gui(WCA) 
    pack $f.cW -side top -padx $Gui(pad) -pady $Gui(pad)

    TooltipAdd  $f.cW "Click to see grayscale only."

    #-------------------------------------------
    # Draw->Shape frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fShape

    eval {label $f.l -text "Shape:"} $Gui(WLA)
    pack $f.l -side left -padx $Gui(pad) -pady $Gui(pad) -fill x

    foreach shape "Polygon Points" {
        eval {radiobutton $f.r$shape -width [expr [string length $shape]+1] \
            -text "$shape" -variable Ed(EdDraw2,preshape) -value $shape \
            -command "EdDraw2Update SetShape; RenderActive" \
            -indicatoron 0} $Gui(WCA)
        pack $f.r$shape -side left -fill x -anchor e
    }

    #-------------------------------------------
    # Draw->Apply frame
    #-------------------------------------------
    set f $Ed(EdDraw2,frame).fApply

    eval {button $f.bApply -text "Apply" \
        -command "EdDraw2Apply"} $Gui(WBA) {-width 8}
    eval {button $f.bUnapply -text "Unapply" \
        -command "EdDraw2Unapply; RenderActive"} $Gui(WBA) {-width 8}

    # To make Apply, Unapply in same line, make a new frame for them
    #pack $f.bApply $f.bUnapply -side top -padx $Gui(pad) -pady $Gui(pad)
    pack $f.bApply -side left -fill x -anchor e
    pack $f.bUnapply -side left -fill x -anchor e
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2Enter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Enter {} {
    global Ed Label

    LabelsColorWidgets

    set e EdDraw2
    Slicer DrawSetRadius $Ed($e,radius)
    Slicer DrawSetShapeTo$Ed($e,shape)
    if {$Label(activeID) != ""} {
        set color [Color($Label(activeID),node) GetDiffuseColor]
        eval Slicer DrawSetColor $color
    } else {
        Slicer DrawSetColor 0 0 0
    }
    if {$Ed($e,closed) == "Closed"} {
        Slicer DrawSetClosed 1
    } else {
        Slicer DrawSetClosed 0
    }
    Slicer DrawSetHideSpline 0

    # use the bindings stack for adding new bindings.
    pushEventManager $Ed($e,eventManager)
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2Exit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Exit {} {

    # Delete points
    EdDraw2Update DeleteAll
    RenderActive
    Slicer DrawSetHideSpline 1

    popEventManager
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2Label
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Label {} {
    global Label

    LabelsFindLabel

    if {$Label(activeID) != ""} {
        set color [Color($Label(activeID),node) GetDiffuseColor]
        eval Slicer DrawSetColor $color
    } else {
        Slicer DrawSetColor 0 0 0
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2Update
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Update {type} {
    global Ed Volume Label Gui

    set e EdDraw2

    switch -glob -- $type {
        NextMode {
            switch $Ed($e,mode) {
                "Draw" {
                    set Ed($e,mode) Select
                }
                "Select" {
                    set Ed($e,mode) Insert
                }
                "Move" {
                    set Ed($e,mode) Insert
                }
                "Insert" {
                    set Ed($e,mode) Draw
                }
            }
        }
        Delete {
            Slicer DrawDeleteSelected
            if {0} {
                EditorInsertPoint update
            }
            MainInteractorRender
        }
        "\[0-9\]" {
            switch $Ed($e,mode) {
                "Draw" {
                    $Ed(EdDraw2,frame).fGrid.eOutput insert end $type
                }
                "Select" {
                    # nothing
                }
                "Move" {
                    # nothing
                }
                "Insert" {
                    # nothing
                }
            }
        }
        "=" {
            EdDraw2Label
        }
        "-" {
            $Ed(EdDraw2,frame).fGrid.eOutput delete 0 end
        }
        SelectAll {
            Slicer DrawSelectAll
            set Ed($e,mode) Select
        }
        DeselectAll {
            Slicer DrawDeselectAll
            set Ed($e,mode) Select
        }
        DeleteSelected {
            Slicer DrawDeleteSelected
            set Ed($e,mode) Draw
        }
        DeleteAll {
            Slicer DrawDeleteAll
            set Ed($e,mode) Draw
        }
        SetRadius {
            Slicer DrawSetRadius $Ed($e,radius)
            set Ed($e,radius) [Slicer DrawGetRadius]
        }
        SetShape {
            if { $Ed($e,preshape) == "Points" } {
                set Ed($e,shape) "Points"
            } else { # preshape is Polygon
                if { $Ed($e,closed) == "Closed" } {
                    set Ed($e,shape) "Polygon"
                    Slicer DrawSetClosed 1
                } else {
                    set Ed($e,shape) "Lines"
                    Slicer DrawSetClosed 0
                }
            }
            if { $Ed($e,spline) == "Yes" } {
                Slicer DrawSetHideSpline 0
            } else {
                Slicer DrawSetHideSpline 1
            }
            Slicer DrawSetShapeTo$Ed($e,shape)
            set Ed($e,shape) [Slicer GetShapeString]
        }
        Cut {
            set n [Slicer DrawGetNumPoints]
            if { $n < 1 } {
                tk_messageBox -message "There is no polygon to Cut.  The last cut/copied polygon is still available."
                # don't delete current CopyPoly if PolyDraw is empty
                return
            }
            Slicer CopySetDrawPoints
            Slicer DrawDeleteAll
        }
        Copy {
            set n [Slicer DrawGetNumPoints]
            if { $n < 1 } {
                tk_messageBox -message "There is no polygon to Copy.  The last cut/copied polygon is still available."
                # don't delete current CopyPoly if PolyDraw is empty
                return
            }
            Slicer CopySetDrawPoints
        }
        Paste {
            set poly [Slicer CopyGetPoints]
            set n [$poly GetNumberOfPoints]
            if { $n < 1 } {
                tk_messageBox -message "There is nothing to Paste.  The current polygon you are drawing remains unchanged."
                # don't erase PolyDraw if CopyPoly is empty
                return
            }
            Slicer DrawDeleteAll
            # Add each point of CopyPoly to PolyDraw
            for {set i 0} {$i < $n} {incr i} {
                set p [$poly GetPoint $i]
                scan $p "%d %d %d" xx yy zz
                Slicer DrawInsertPoint $xx $yy
            }
            Slicer DrawSelectAll
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2Apply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Apply { {delete_pending true} } {
    global Ed Volume Label Gui Slice Interactor

    set e EdDraw2
    set v [EditorGetInputID $Ed($e,input)]
 
    # Validate input
    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Output label is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,radius)] == 0} {
        tk_messageBox -message "Point Radius is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,density)] == 0} {
        tk_messageBox -message "Sampling Density is not an integer."
        return
    }

    # (CTJ) Check that point radius and sampling density are nonnegative
    if {$Ed($e,radius) < 0} {
        tk_messageBox -message "Point Radius is negative."
        return
    }
    if {$Ed($e,density) < 0} {
        tk_messageBox -message "Sampling Density is negative."
        return
    }

    # (CTJ) If spline mode off, don't sample points on the spline!
    if { $Ed($e,spline) != "Yes" } {
        set Ed($e,density) 0
    }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Active

    set Gui(progressText) "Draw on [Volume($v,node) GetName]"

    set label    $Label(label)
    set radius   $Ed($e,radius)
    set shape    $Ed($e,shape)
    set density  $Ed($e,density)

    set inum [Slicer GetActiveSlice]
    set snum $Slice($inum,offset)

    #### How points selected by the user get here ###########
    # odonnell, 11-3-2000
    #
    # 1. Click point
    # 2. MainInteractorXY converts to "reformat point".
    #    This point is really just y-flipped and unzoomed.
    #    This does not actually use the reformat matrix at all.    
    # 3. Point goes on list in vtkMrmlSlicer, a vtkImageDrawROI object
    #    called PolyDraw.  This draws it on the screen.
    # 4. User hits Apply.
    # 5. Point is converted using reformat matrix from the volume
    #    in DrawComputeIjkPoints.  The output is "sort of 3D".  It is
    #    number,number,0 where the numbers are the i,j, or k
    #    coordinates for the point (and the slice would define 
    #    the other coordinate, but it is just 0).
    #    The regular ROI points would work in the original 
    #    (scanned) slice, but this conversion is needed for the 
    #    other two slices.
    #########################################################

    if { [EdDraw2GetSlice $inum] != $snum } {
        EdDraw2SetSlice $inum $snum
        EdDraw2SetPolynum $inum -1
        EdDraw2SetUnapplynum $inum -1
    }
    if { [EdDraw2GetUnapplynum $inum] != -1 } {
        # Remove unapplied polygon so we can reapply in same slot
        set unum [EdDraw2GetUnapplynum $inum]
        Slicer StackRemovePolygon $inum $snum $unum
        Volume($v,vol) StackRemovePolygon $inum $snum $unum
        Slicer RasStackRemovePolygon $inum $snum $unum
        Volume($v,vol) RasStackRemovePolygon $inum $snum $unum
    }
    set pnum [EdDraw2GetPolynum $inum]
    EdDraw2SetPolynum $inum [Slicer StackGetNextInsertPosition $inum $snum $pnum]
    set pnum [EdDraw2GetPolynum $inum]
    if { $pnum == -1 } { # Should only be true if polynum was -1 already
        return
    }
    if { $Ed($e,closed) == "Open" } {
        set closed 0
    } else {
        set closed 1
    }
    if { $Ed($e,preshape) == "Points" } {
        set preshape 0
    } else {
        set preshape 1
    }

    # set polygon and raspolygon in vtkMrmlSlicer and volume object
    Slicer StackSetPolygon $inum $snum $pnum $density $closed $preshape $label
    Volume($v,vol) StackSetPolygon $inum [Slicer DrawGetPoints] $snum $pnum $density $closed $preshape $label
    set raspoly [Slicer RasStackSetPolygon $inum $snum $pnum $density $closed $preshape $label]
    Volume($v,vol) RasStackSetPolygon $inum $raspoly $snum $pnum $density $closed $preshape $label

    EdDraw2SetUnapplynum $inum -1
    # (CTJ) For users who want to clear the current slice's labelmap reapply
    # all manually drawn polygons, there is now a "Clear" option that can be
    # chosen before applying; represented by the toggle variable Ed($e,clear)
    if { $Ed($e,clear) == "Yes" } {
        Ed(editor)   Clear
    }
    set numapply [Slicer StackGetNumApplyable $inum $snum]
    for {set q 0} {$q < $numapply} {incr q} {
        # Get index p of qth polygon to apply
        set p [Slicer StackGetApplyable $inum $snum $q]
        set poly [Slicer StackGetPoints $inum $snum $p]
        set n [$poly GetNumberOfPoints]
        # If polygon empty, don't apply it.  It was already removed above
        if { $n > 0 } {
            Slicer DrawComputeIjkPointsInterpolated $inum $snum $p
            set points [Slicer GetDrawIjkPoints]
            set preshape [Slicer StackGetPreshape $inum $snum $p]
            set label [Slicer StackGetLabel $inum $snum $p]
            if { $preshape == 0 } {
                set shape "Points"
            } else {
                if { $Ed($e,closed) == "Closed" } {
                    set shape "Polygon"
                } else {
                    set shape "Lines"
                }
            }
            Ed(editor)   Draw $label $points $radius $shape
        }
    }

    # Dump points
    # points selected by the user and sent through MainInteractorXY
    #set oldpoints   [Slicer DrawGetPoints]
    #set n [$points GetNumberOfPoints]
    # compare to points converted to '~3D space' in DrawComputeIJKPoints
    #for {set i 0} {$i < $n} {incr i} {
    #    puts "ijk: [$points GetPoint $i] 2D: [$oldpoints GetPoint $i]"
    #}
    
    Ed(editor)   SetInput ""
    Ed(editor)   UseInputOff

    # Delete points?
    if {$Ed($e,delete) == "Yes"} {
        EdDraw2Update DeleteAll
    } else {
        EdDraw2Update DeselectAll
    }

    if { $delete_pending == "true" } {
        # the "__EditorPending_Points" is a special vtk object to communicate to 
        # the Editor.tcl module that the user really wants to apply now
        catch {__EditorPending_Points Delete}
    }

    EdUpdateAfterApplyEffect $v $Ed($e,render)
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2Unapply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2Unapply {} {
    global Ed Volume Label Gui Slice Interactor

    set e EdDraw2
    set inum [Slicer GetActiveSlice]
    set snum $Slice($inum,offset)

    Slicer DrawDeleteAll
    if { [EdDraw2GetSlice $inum] != $snum } {
        set poly [Slicer StackGetPoints $inum $snum]
        set ind [Slicer StackGetRetrievePosition $inum $snum]
        set Label(label) [Slicer StackGetLabel $inum $snum $ind]
        EdDraw2Label
        # n == -1 if poly is NULL
        set n [Slicer StackGetNumberOfPoints $inum $snum]
        for {set i 0} {$i < $n} {incr i} {
            set p [$poly GetPoint $i]
            scan $p "%d %d %d" xx yy zz
            Slicer DrawInsertPoint $xx $yy
        }
        EdDraw2SetSlice $inum $snum
        EdDraw2SetPolynum $inum [Slicer StackGetRetrievePosition $inum $snum]
        EdDraw2SetUnapplynum $inum [EdDraw2GetPolynum $inum]
    } else {
        set pnum [EdDraw2GetPolynum $inum]
        EdDraw2SetPolynum $inum [Slicer StackGetNextRetrievePosition $inum $snum $pnum]
        set pnum [EdDraw2GetPolynum $inum]
        if { $pnum != -1 } {
            EdDraw2SetUnapplynum $inum $pnum
            set poly [Slicer StackGetPoints $inum $snum $pnum]
            set Label(label) [Slicer StackGetLabel $inum $snum $pnum]
            EdDraw2Label
            set n [$poly GetNumberOfPoints]
            for {set i 0} {$i < $n} {incr i} {
                set p [$poly GetPoint $i]
                scan $p "%d %d %d" xx yy zz
                Slicer DrawInsertPoint $xx $yy
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2GetSlice
#       
# .ARGS 
# .END      
#-------------------------------------------------------------------------------
proc EdDraw2GetSlice { windownum } {
    global Ed
            
    set e EdDraw2
            
    switch $windownum {
        0 { 
            return $Ed($e,slice0)
        }       
        1 {     
            return $Ed($e,slice1)
        }
        2 {
            return $Ed($e,slice2)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2SetSlice
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2SetSlice { windownum value } {
    global Ed

    set e EdDraw2

    switch $windownum {
        0 {
            set Ed($e,slice0) $value
        }
        1 {
            set Ed($e,slice1) $value
        }
        2 {
            set Ed($e,slice2) $value
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2GetPolynum
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2GetPolynum { windownum } {
    global Ed

    set e EdDraw2

    switch $windownum {
        0 {
            return $Ed($e,polynum0)
        }
        1 {
            return $Ed($e,polynum1)
        }
        2 {
            return $Ed($e,polynum2)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2SetPolynum
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2SetPolynum { windownum value } {
    global Ed

    set e EdDraw2

    switch $windownum {
        0 {
            set Ed($e,polynum0) $value
        }
        1 {
            set Ed($e,polynum1) $value
        }
        2 {
            set Ed($e,polynum2) $value
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2GetUnapplynum
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2GetUnapplynum { windownum } {
    global Ed

    set e EdDraw2

    switch $windownum {
        0 {
            return $Ed($e,unapplynum0)
        }
        1 {
            return $Ed($e,unapplynum1)
        }
        2 {
            return $Ed($e,unapplynum2)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDraw2SetUnapplynum
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDraw2SetUnapplynum { windownum value } {
    global Ed

    set e EdDraw2

    switch $windownum {
        0 {
            set Ed($e,unapplynum0) $value
        }
        1 {
            set Ed($e,unapplynum1) $value
        }
        2 {
            set Ed($e,unapplynum2) $value
        }
    }
}


