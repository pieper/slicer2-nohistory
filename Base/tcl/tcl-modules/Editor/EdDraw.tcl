#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdDraw.tcl,v $
#   Date:      $Date: 2006/06/08 22:14:14 $
#   Version:   $Revision: 1.39 $
# 
#===============================================================================
# FILE:        EdDraw.tcl
# PROCEDURES:  
#   EdDrawInit
#   EdDrawBuildGUI
#   EdDrawEnter
#   EdDrawExit
#   EdDrawLabel
#   EdDrawUpdate
#   EdDrawApply
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC EdDrawInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawInit {} {
    global Ed

    set e EdDraw
    set Ed($e,name)      "Draw"
    set Ed($e,initials)  "Dr"
    set Ed($e,desc)      "Draw: label pixels using a brush."
    set Ed($e,rank)      4
    set Ed($e,procGUI)   EdDrawBuildGUI
    set Ed($e,procEnter) EdDrawEnter
    set Ed($e,procExit)  EdDrawExit

    # Required
    set Ed($e,scope) Single 
    set Ed($e,input) Working

    set Ed($e,mode)   Draw
    set Ed($e,delete) Yes
    set Ed($e,radius) 0
    set Ed($e,shape)  Polygon
    set Ed($e,render) Active

    set Ed($e,eventManager) {}
    
}

#-------------------------------------------------------------------------------
# .PROC EdDrawBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawBuildGUI {} {
    global Ed Gui Label Editor

    #-------------------------------------------
    # Draw frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame)

    frame $f.fRender  -bg $Gui(activeWorkspace)
    frame $f.fMode    -bg $Gui(activeWorkspace)
    frame $f.fDelete  -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fBtns    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    frame $f.fStats   -bg $Gui(activeWorkspace)
    frame $f.fToggle  -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fBtns $f.fMode $f.fDelete $f.fRender $f.fApply\
        -side top -pady 2 -fill x
    pack $f.fStats $f.fToggle -side bottom -pady 4 -fill x
    
    EdBuildRenderGUI $Ed(EdDraw,frame).fRender Ed(EdDraw,render)

    #-------------------------------------------
    # Draw->Mode frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fMode

    frame $f.fMode -bg $Gui(activeWorkspace)
    eval {label $f.fMode.lMode -text "Mode:"} $Gui(WLA)
    pack $f.fMode.lMode -side left -padx 0 -pady 0
    foreach mode "Draw Select Move" {
        eval {radiobutton $f.fMode.r$mode \
            -text "$mode" -variable Ed(EdDraw,mode) -value $mode \
            -width [expr [string length $mode] +1] \
            -indicatoron 0} $Gui(WCA)
        pack $f.fMode.r$mode -side left -padx 0 -pady 0
    }
    pack $f.fMode -side top -pady 5 -padx 0 

    #-------------------------------------------
    # Draw->Delete frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fDelete

    eval {label $f.l -text "Delete points after apply:"} $Gui(WLA)
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach s "Yes No" text "Yes No" width "4 3" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
            -text "$text" -value "$s" -variable Ed(EdDraw,delete)} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }

    #-------------------------------------------
    # Draw->Grid frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fGrid

    # Output label
    eval {button $f.bOutput -text "Output:" \
        -command "ShowLabels EdDrawLabel"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
        -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdDrawLabel"
    bind $f.eOutput <FocusOut> "EdDrawLabel"
    eval {entry $f.eName -width 14 \
        -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}

    lappend Label(colorWidgetList) $f.eName

    set Editor(toggleAutoSample) 0
    eval {checkbutton $f.cAuto -width 4 -indicatoron 0 \
        -variable Editor(toggleAutoSample) \
        -text "Auto" } $Gui(WCA) 
    TooltipAdd  $f.cAuto "Automatically set label value depending on location of first click."

    grid $f.bOutput $f.eOutput $f.eName $f.cAuto -padx 0 -pady $Gui(pad)
    #grid $f.eOutput $f.eName -sticky w


    # Radius
    eval {label $f.lRadius -text "Pt Radius:"} $Gui(WLA)
    eval {entry $f.eRadius -width 6 \
        -textvariable Ed(EdDraw,radius)} $Gui(WEA)
        bind $f.eRadius <Return> "EdDrawUpdate SetRadius; RenderActive"
    grid $f.lRadius $f.eRadius -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.eRadius -sticky w

    #-------------------------------------------
    # Draw->Btns frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fBtns

    eval {button $f.bSelectAll -text "Select All" \
        -command "EdDrawUpdate SelectAll; RenderActive"} $Gui(WBA) {-width 16}
    eval {button $f.bDeselectAll -text "Deselect All" \
        -command "EdDrawUpdate DeselectAll; RenderActive"} $Gui(WBA) {-width 16}
    eval {button $f.bDeleteSel -text "Delete Selected" \
        -command "EdDrawUpdate DeleteSelected; RenderActive"} $Gui(WBA) {-width 16}
    eval {button $f.bDeleteAll -text "Delete All" \
        -command "EdDrawUpdate DeleteAll; RenderActive"} $Gui(WBA) {-width 16}

    grid $f.bSelectAll $f.bDeselectAll  -padx $Gui(pad) -pady $Gui(pad)
    grid $f.bDeleteSel $f.bDeleteAll    -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Draw->Stats frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fStats
    
    eval {button $f.bStats -width 16 \
        -text "Label Statistics"  \
        -command EdDrawStatsDialog} $Gui(WBA) 
    pack $f.bStats -side top -padx $Gui(pad) -pady $Gui(pad)

    TooltipAdd  $f.bStats "Show dialog with statistics for Original data for each label in Working"

    #-------------------------------------------
    # Draw->Toggle frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fToggle
    
    set Editor(toggleWorking) 0
    eval {checkbutton $f.cW -width 21 -indicatoron 0 \
        -variable Editor(toggleWorking) \
        -text "Peek under labelmap"  \
        -command EditorToggleWorking} $Gui(WCA) 
    pack $f.cW -side top -padx $Gui(pad) -pady $Gui(pad)

    TooltipAdd  $f.cW "Click to see grayscale only."

    #-------------------------------------------
    # Draw->Apply frame
    #-------------------------------------------
    set f $Ed(EdDraw,frame).fApply

    frame $f.f -bg $Gui(activeWorkspace)
    eval {label $f.f.l -text "Shape:"} $Gui(WLA)
    pack $f.f.l -side left -padx $Gui(pad)

    foreach shape "Polygon Lines Points" {
        eval {radiobutton $f.f.r$shape -width [expr [string length $shape]+1] \
            -text "$shape" -variable Ed(EdDraw,shape) -value $shape \
            -command "EdDrawUpdate SetShape; RenderActive" \
            -indicatoron 0} $Gui(WCA)
        pack $f.f.r$shape -side left 
    }

    eval {button $f.bApply -text "Apply" \
        -command "EdDrawApply"} $Gui(WBA) {-width 8}

    pack $f.f $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)


}

#-------------------------------------------------------------------------------
# .PROC EdDrawEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawEnter {} {
    global Ed Label

    LabelsColorWidgets

    set e EdDraw
    Slicer DrawSetRadius $Ed($e,radius)
    Slicer DrawSetShapeTo$Ed($e,shape)
    if {$Label(activeID) != ""} {
        set color [Color($Label(activeID),node) GetDiffuseColor]
        eval Slicer DrawSetColor $color
    } else {
        Slicer DrawSetColor 0 0 0
    }

    # use the bindings stack for adding new bindings.
    pushEventManager $Ed($e,eventManager)
}

#-------------------------------------------------------------------------------
# .PROC EdDrawExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawExit {} {

    # Delete points
    EdDrawUpdate DeleteAll
    RenderActive

    popEventManager
}

#-------------------------------------------------------------------------------
# .PROC EdDrawLabel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawLabel {} {
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
# .PROC EdDrawUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawUpdate {type} {
    global Ed Volume Label Gui

    set e EdDraw
    
    switch -glob -- $type {
        NextMode {
            switch $Ed($e,mode) {
                "Draw" {
                    set Ed($e,mode) Select
                }
                "Select" {
                    set Ed($e,mode) Move
                }
                "Move" {
                    set Ed($e,mode) Draw
                }
            }
        }
        Delete {
            switch $Ed($e,mode) {
                "Draw" {
                    Slicer DrawDeleteSelected
                    if {0} {
                        EditorInsertPoint update
                    }
                    MainInteractorRender
                }
                "Select" {
                    # nothing
                }
                "Move" {
                    # nothing
                }
            }
        }
        "\[0-9\]" {
            switch $Ed($e,mode) {
                "Draw" {
                    $Ed(EdDraw,frame).fGrid.eOutput insert end $type
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
            EdDrawLabel
        }
        "-" {
            $Ed(EdDraw,frame).fGrid.eOutput delete 0 end
        }
        "CurrentSample" -
        "\\\\" {
            $Ed(EdDraw,frame).fGrid.eOutput delete 0 end
            $Ed(EdDraw,frame).fGrid.eOutput insert end $::Anno(curForePix)
            EdDrawLabel
        }
        SelectAll {
            Slicer DrawSelectAll
            set Ed($e,mode) Move
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
            Slicer DrawSetShapeTo$Ed($e,shape)
            set Ed($e,shape) [Slicer GetShapeString]
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDrawApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdDrawApply { {delete_pending true} } {
    global Ed Volume Label Gui

    set e EdDraw
    set v [EditorGetInputID $Ed($e,input)]
 
    # Validate input
    if {[ValidateInt $Label(label)] == 0} {
        DevErrorWindow "Output label is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,radius)] == 0} {
        DevErrorWindow "Point Radius is not an integer."
        return
    }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Active

    set Gui(progressText) "Draw on [Volume($v,node) GetName]"

    set label    $Label(label)
    set radius   $Ed($e,radius)
    set shape    $Ed($e,shape)

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

    Slicer DrawComputeIjkPoints
    set points [Slicer GetDrawIjkPoints]
    Ed(editor)   Draw $label $points $radius $shape

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
        EdDrawUpdate DeleteAll
    } else {
        EdDrawUpdate DeselectAll
    }

    if { $delete_pending == "true" } {
        # the "__EditorPending_Points" is a special vtk object to communicate to 
        # the Editor.tcl module that the user really wants to apply now
        catch {__EditorPending_Points Delete}
    }

    EdUpdateAfterApplyEffect $v $Ed($e,render)
}

#-------------------------------------------------------------------------------
# .PROC EdDrawStatsDialog
#   Generate a table of image statistics for current grayscale and labelmap
#
# .END
#-------------------------------------------------------------------------------
proc EdDrawStatsDialog {} {
    
    package require Iwidgets

    set d .edstatsdialog
    catch "destroy $d"
    iwidgets::dialogshell $d -title "Label Statistics"

    $d add dismiss -text "Dismiss" -command "$d deactivate"
    $d default dismiss
     
    #
    # Add something to the top of the dialog...
    #
    set win [$d childsite]
    iwidgets::scrolledtext $win.text -labeltext "Statistics: " -wrap none \
        -vscrollmode dynamic -hscrollmode dynamic \
        -width 5i -height 2i
    pack $win.text -expand true -fill both

    $win.text insert end "Calculating..."
    update
    $d activate
    update

    set stats [EdDrawLabelStats]
    
    $win.text clear
    $win.text insert end "Label\tMin\tMax\tCount\tMean\tStdDev\n"
    foreach l $stats {
        array set s $l
        $win.text insert end "$s(label)\t$s(min)\t$s(max)\t$s(voxelcount)\t$s(mean)\t$s(std)\n"
    }
}

#-------------------------------------------------------------------------------
# .PROC EdDrawLabelStats
#   calculate the contents of the stats dialog
#
# .END
#-------------------------------------------------------------------------------
proc EdDrawLabelStats {} {

    set labeldata [Volume($::Editor(idWorking),vol) GetOutput] 
    catch "stataccum Delete"
    vtkImageAccumulate stataccum
    stataccum SetInput $labeldata
    stataccum Update
    set lo [lindex [stataccum GetMin] 0]
    set hi [lindex [stataccum GetMax] 0]
    catch "stataccum Delete"

    set statlist ""

    for {set label $lo} {$label <= $hi} {incr label} {
        ## logic copied from VolumeMath MaskStat
        # create the binary volume of the label catch "editorThresh Delete"
        catch "editorThresh Delete"
        vtkImageThreshold editorThresh
        editorThresh SetInput $labeldata
        editorThresh SetInValue 1
        editorThresh SetOutValue 0
        editorThresh ReplaceOutOn
        editorThresh ThresholdBetween $label $label
        editorThresh SetOutputScalarType [[Volume($::Editor(idOriginal),vol) GetOutput] GetScalarType]
        
        # set up the VolumeMath Mask
        catch "MultMath Delete"
        vtkImageMathematics MultMath
        MultMath SetInput1 [Volume($::Editor(idOriginal),vol) GetOutput]
        MultMath SetInput2 [editorThresh GetOutput]
        MultMath SetOperationToMultiply

        # start copying in the ouput data.
        # taken from MainVolumesCopyData
        [MultMath GetOutput] Update

        # use vtk's statistics class with the labelmap as a stencil
        catch "stencil Delete"
        vtkImageToImageStencil stencil
        stencil SetInput [editorThresh GetOutput]
        stencil ThresholdBetween 1 1

        catch "stat1 Delete"
        vtkImageAccumulate stat1
        stat1 SetInput [Volume($::Editor(idOriginal),vol) GetOutput]
        stat1 SetStencil [stencil GetOutput]
        stat1 Update

        stencil Delete

        if { [stat1 GetVoxelCount] > 0 } {
            lappend statlist [list \
                    label $label \
                    voxelcount [stat1 GetVoxelCount] \
                    min [lindex [stat1 GetMin] 0] \
                    max [lindex [stat1 GetMax] 0] \
                    mean [lindex [stat1 GetMean] 0] \
                    std [lindex [stat1 GetStandardDeviation] 0] ]
        }

        MultMath Delete
        editorThresh Delete
        
        stat1 Delete
    }

    return $statlist
}
