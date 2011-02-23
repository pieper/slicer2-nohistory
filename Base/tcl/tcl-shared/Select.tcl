#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Select.tcl,v $
#   Date:      $Date: 2006/03/06 19:24:26 $
#   Version:   $Revision: 1.16 $
# 
#===============================================================================
# FILE:        Select.tcl
# PROCEDURES:  
#   SelectInit
#   SelectClose
#   SelectBuildVTK
#   SelectBuildGUI
#   SelectRefreshVTK
#   SelectPick
#   SelectPickRenderer
#   SelectPickable
#   SelectPick2D
#   SelectModelOn
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC SelectInit
# Initialize global Select variables
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectInit {} {
    global Selected Module Select

    set m Select
    # set Module($m,procVTK) SelectBuildVTK
    # set Module($m,procGUI) SelectBuildGUI

    
    lappend Module(procGUI) SelectBuildGUI
    lappend Module(procVTK) SelectBuildVTK

    set Select(actor) ""
    set Select(xyz) ""
    set Select(xy) ""
    set Select(cellId) ""
    set Select(pointId) ""

    # used in Measure and Xform 
    set Selected(Model) ""
}

#-------------------------------------------------------------------------------
# .PROC SelectClose
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectClose {} {
    global Select

    if {$::Module(verbose)} { 
        puts "Resetting Select array to emtpy strings"
    }
    set Select(actor) ""
    set Select(xyz) ""
    set Select(xy) ""
    set Select(cellId) ""
    set Select(pointId) ""

    # used in Measure and Xform 
    set Selected(Model) ""

}

#-------------------------------------------------------------------------------
# .PROC SelectBuildVTK
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectBuildVTK {} {
    global Select

    vtkFastCellPicker Select(picker)
    #    vtkCellPicker Select(picker)
    Select(picker) SetTolerance 0.001
    Select(picker) PickFromListOff

    vtkPointPicker Select(ptPicker)
    Select(ptPicker) SetTolerance 0.001
}

#-------------------------------------------------------------------------------
# .PROC SelectBuildGUI
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectBuildGUI {} {
    global SelectEventMgr Gui

    array set SelectEventMgr [subst { \
        $Gui(fViewWin),<Enter> {focus %W} \
        $Gui(fViewWin),<Control-1> {addGlyphPoint %W %x %y} \
        $Gui(fViewWin),<KeyPress-p> {addGlyphPoint %W %x %y} \
        $Gui(fViewWin),<KeyPress-c> {ExtractComponent %W %x %y} \
        $Gui(fSl0Win),<KeyPress-p> {addGlyphPoint2D %W 0 %x %y} \
        $Gui(fSl1Win),<KeyPress-p> {addGlyphPoint2D %W 1 %x %y} \
        $Gui(fSl2Win),<KeyPress-p> {addGlyphPoint2D %W 2 %x %y} \
        $Gui(fViewWin),<Shift-Control-1> {selGlyphPoint %W %x %y} \
        $Gui(fViewWin),<Control-2> {selGlyphPoint %W %x %y} \
        $Gui(fViewWin),<KeyPress-q> {selGlyphPoint %W %x %y} \
        $Gui(fViewWin),<Control-3> {delGlyphPoint %W %x %y} \
        $Gui(fViewWin),<KeyPress-d> {delGlyphPoint %W %x %y} \
        $Gui(fViewWin),<Control-B1-Motion> {set noop 0} \
        $Gui(fViewWin),<Control-B2-Motion> {set noop 0} \
        $Gui(fViewWin),<Control-B3-Motion> {set noop 0} } ]

    set SelectEventMgr1 ""
    lappend SelectEventMgr1 {$Gui(fViewWin) <KeyPress-x> \
        { if { [SelectPick Select(picker) %W %x %y] != 0 } \
              { eval MainSlicesAllOffsetToPoint $Select(xyz) } } }
    lappend SelectEventMgr1 {$Gui(fSl0Win) <KeyPress-x> \
        { if { [SelectPick2D %W %x %y] != 0 } \
              { eval MainSlicesAllOffsetToPoint $Select(xyz) } } }
    lappend SelectEventMgr1 {$Gui(fSl1Win) <KeyPress-x> \
        { if { [SelectPick2D %W %x %y] != 0 } \
              { eval MainSlicesAllOffsetToPoint $Select(xyz) } } }
    lappend SelectEventMgr1 {$Gui(fSl2Win) <KeyPress-x> \
        { if { [SelectPick2D %W %x %y] != 0 } \
              { eval MainSlicesAllOffsetToPoint $Select(xyz) } } }
    # puts $SelectEventMgr1
    pushEventManager $SelectEventMgr1
    }

#-------------------------------------------------------------------------------
# .PROC SelectRefreshVTK
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectRefreshGUI {} {
}

#-------------------------------------------------------------------------------
# .PROC SelectPick
# Invoke the picker for a given widget, location, and renderer
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectPick { picker widget x y } {
    global Select Fiducials

    # Note: y coordinate must be transformed to account for
    # origin in upper left.
    set y1 [expr [lindex [$widget configure -height] 4] - $y - 1]
    set renderer [SelectPickRenderer $widget $x $y1]
    if { $renderer == "" } {
        return 0
    } elseif { ([$picker Pick $x $y1 0 $renderer] == 0) || \
                   ([$picker IsA vtkCellPicker] && [$picker GetCellId] < 0) || \
                   ([$picker IsA vtkPointPicker] && [$picker GetPointId] < 0)} {
        return 0
    } else {
        # new way of picking the FIRST actor hit by the ray in vtk3.2
        set assemblyPath [$picker GetPath]
        $assemblyPath InitTraversal
        set assemblyNode [$assemblyPath GetLastNode]
        set Select(actor) [$assemblyNode GetProp]
        
        if { $Select(actor) == ""} {
            return 0
        }
        set Select(actor) [$picker GetActor]
        set Select(xyz) [$picker GetPickPosition]
        
        if {[$picker IsA vtkCellPicker]} {
            set Select(cellId) [$picker GetCellId]
            
            #
            # This part handles the fact that picking a point
            # should return the point XYZ, not the picked XYZ.
            #
            foreach fid $Fiducials(idList) {
                if { $Select(actor) == "Fiducials($fid,actor)" } {
                    set pid [FiducialsPointIdFromGlyphCellId $fid $Select(cellId)]
                    set Select(xyz) [FiducialsWorldPointXYZ $fid $pid]
                }
            }
        }
        if {[$picker IsA vtkPointPicker]} {
            set Select(pointId) [$picker GetPointId]
        }
        return 1
    }
}

#-------------------------------------------------------------------------------
# .PROC SelectPickRenderer
# there can be multiple renderers in a view port and this figures
# out which one the pick point falls by looking at the viewports.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectPickRenderer { widget x y } {
    set rWin [$widget GetRenderWindow]
    set winWidth [lindex [$rWin GetSize] 0]
    set winHeight [lindex [$rWin GetSize] 1]
    set rList [$rWin GetRenderers]
    set retRen ""
    $rList InitTraversal
    for { set thisR [$rList GetNextItem] } { $thisR != "" } \
        { set thisR [$rList GetNextItem] } {
        set vPort [$thisR GetViewport]
        set minX [expr [lindex $vPort 0] * $winWidth]
        set maxX [expr [lindex $vPort 2] * $winWidth]
        set minY [expr [lindex $vPort 1] * $winHeight]
        set maxY [expr [lindex $vPort 3] * $winHeight]
        if { $x>=$minX && $x<=$maxX && $y>=$minY && $y<=$maxY } {
            set retRen $thisR
        }
    }
    return $retRen
}

#-------------------------------------------------------------------------------
# .PROC SelectPickable
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectPickable { group value } {
    # group is one of: Anno, Models, Slices, Points
}

#-------------------------------------------------------------------------------
# .PROC SelectPick2D
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectPick2D { widget x y } {
    global Select Interactor

    set s $Interactor(s)
    if { $s != "" } {
        scan [MainInteractorXY $s $x $y] "%d %d %d %d" xs yz x y
        Slicer SetReformatPoint $s $x $y
        scan [Slicer GetWldPoint] "%g %g %g" xRas yRas zRas
        set Select(xyz) "$xRas $yRas $zRas"
        set Select(xy) "$widget $x $y"
        if {$::Module(verbose)} {
            puts "SelectPick2d: widget $widget, x $x, y $y -> ras = $Select(xyz)"
        }
        return 1
    } else {
        return 0
    }
}

#-------------------------------------------------------------------------------
# .PROC SelectModelOn
# Set up handlers and pickability for Model selection
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SelectModelOn { picker widget x y renderer } {
    global Select
}
