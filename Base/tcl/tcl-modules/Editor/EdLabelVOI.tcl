#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdLabelVOI.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.7 $
# 
#===============================================================================
# FILE:        EdLabelVOI.tcl
# PROCEDURES:  
#   EdLabelVOIInit
#   EdLabelVOIBuildGUI
#   EdLabelVOIEnter
#   EdLabelVOIStartMethod
#   EdLabelVOIExit
#   EdLabelVOIApply
#   EdLabelVOIB1
#   EdLabelVOIUpdateVOIBox
#   EdLabelVOIRoundFloat float
#   EdLabelVOIGetActiveSlice
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC EdLabelVOIInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIInit {} {
    global Ed

    set e EdLabelVOI
    set Ed($e,name)      "Label VOI"
    set Ed($e,initials)  "LV"
    set Ed($e,desc)      "Label VOI: keep/delete subvolume."
    set Ed($e,rank)      10
    set Ed($e,procGUI)   EdLabelVOIBuildGUI
    set Ed($e,procEnter) EdLabelVOIEnter
    set Ed($e,procExit)  EdLabelVOIExit

    # Required
    set Ed($e,scope) 3D 
    set Ed($e,input) Working
    
    set Ed($e,corner1X) 0
    set Ed($e,corner1Y) 0
    set Ed($e,corner1Z) 0
    set Ed($e,corner2X) 0
    set Ed($e,corner2Y) 0
    set Ed($e,corner2Z) 0
    set Ed($e,corner1x) 0
    set Ed($e,corner1y) 0
    set Ed($e,corner2x) 0
    set Ed($e,corner2y) 0
    set Ed($e,activeCorner) "corner1"

    # keep subvolume by default
    set Ed(EdLabelVOI,method) 0
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIBuildGUI {} {
    global Ed Gui Label

    #-------------------------------------------
    # ChangeLabel frame
    #-------------------------------------------
    set f $Ed(EdLabelVOI,frame)
    
#    frame $f.fInput   -bg $Gui(activeWorkspace)
#    frame $f.fScope   -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    frame $f.fMethod -bg $Gui(activeWorkspace)
#    pack $f.fGrid $f.fInput $f.fScope $f.fMethod $f.fApply \
\#    -side top -pady $Gui(pad)
    pack $f.fGrid $f.fMethod $f.fApply -side top -pady $Gui(pad)
    
#    EdBuildScopeGUI $Ed(EdLabelVOI,frame).fScope Ed(EdLabelVOI,scope) Multi
#    EdBuildInputGUI $Ed(EdLabelVOI,frame).fInput Ed(EdLabelVOI,input)

    #-------------------------------------------
    # ChangeLabel->Grid frame
    #-------------------------------------------
    set f $Ed(EdLabelVOI,frame).fGrid
    
    foreach name {corner1 corner2} caption {{Corner 1} {Corner 2}} {
    #eval {label $f.l$name -text "$caption"} $Gui(WLA)
    eval {radiobutton $f.r$name -width 8 -indicatoron 0 \
          -text "$caption" -value "$name" -variable Ed(EdLabelVOI,activeCorner) \
          -command ""} $Gui(WCA)
     eval {entry $f.e${name}X -width 6 -state disabled \
          -textvariable Ed(EdLabelVOI,${name}X)} $Gui(WEA)
     eval {entry $f.e${name}Y -width 6 -state disabled \
          -textvariable Ed(EdLabelVOI,${name}Y)} $Gui(WEA)
     eval {entry $f.e${name}Z -width 6 -state disabled \
          -textvariable Ed(EdLabelVOI,${name}Z)} $Gui(WEA)
    grid $f.r$name $f.e${name}X $f.e${name}Y $f.e${name}Z -padx $Gui(pad) -pady $Gui(pad) -sticky w
    }
    
#     # Input label
#     set Ed(fOpChangeLabelGrid) $f
#     eval {label $f.lInput -text "Value to change:"} $Gui(WLA)
#     eval {entry $f.eInput -width 6 \
#         -textvariable Ed(EdLabelVOI,inputLabel)} $Gui(WEA)

#     # Output label
#     eval {button $f.bOutput -text "Output:" -command "ShowLabels"} $Gui(WBA)
#     eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
#     bind $f.eOutput <Return>   "LabelsFindLabel"
#     bind $f.eOutput <FocusOut> "LabelsFindLabel"
#     eval {entry $f.eName -width 14 \
#         -textvariable Label(name)} $Gui(WEA) \
#         {-bg $Gui(activeWorkspace) -state disabled}

#     lappend Label(colorWidgetList) $f.eName

#     grid $f.lInput $f.eInput -padx $Gui(pad) -pady $Gui(pad) -sticky e
#     grid $f.bOutput $f.eOutput $f.eName -padx $Gui(pad) -pady $Gui(pad) -sticky e

    #-------------------------------------------
    # ChangeLabel->Method frame
    #-------------------------------------------
    set f $Ed(EdLabelVOI,frame).fMethod

    eval {radiobutton $f.rKeep \
          -text "Keep subvolume" -command "" \
          -variable Ed(EdLabelVOI,method) -value 0 -width 16 \
          -indicatoron 0} $Gui(WCA)
    eval {radiobutton $f.rDelete \
          -text "Delete subvolume" -command "" \
          -variable Ed(EdLabelVOI,method) -value 1 -width 16 \
          -indicatoron 0} $Gui(WCA)

    pack $f.rKeep $f.rDelete -side left -padx 0

    #-------------------------------------------
    # ChangeLabel->Apply frame
    #-------------------------------------------
    set f $Ed(EdLabelVOI,frame).fApply
    
    eval {button $f.bApply -text "Apply" \
          -command "EdLabelVOIApply"} $Gui(WBA) {-width 8}
    pack $f.bApply -side top -padx $Gui(pad) -pady 2
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIEnter {} {
    global Ed

    LabelsColorWidgets
    [Slicer GetImageDrawROI] SetStartMethod EdLabelVOIStartMethod
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIStartMethod
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIStartMethod {} {
    EdLabelVOIUpdateVOIBox 0
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIExit {} {
    global Ed
    
    Slicer DrawDeleteAll
    [Slicer GetImageDrawROI] SetStartMethod 0
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIApply {} {
    global Ed Volume Label Gui

    set e EdLabelVOI
    set v [EditorGetInputID $Ed($e,input)]

#     # Validate input
#     if {[ValidateInt $Ed($e,inputLabel)] == 0} {
#         tk_messageBox -message "Value To Change is not an integer."
#         return
#     }
#     if {[ValidateInt $Label(label)] == 0} {
#         tk_messageBox -message "Output label is not an integer."
#         return
#     }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native

    set Gui(progressText) "Removing Labels from [Volume($v,node) GetName]"
    
#    set fg       $Ed($e,inputLabel)
#    set fgNew    $Label(label)
#    Ed(editor)   ChangeLabel $fg $fgNew

    Ed(editor) LabelVOI $Ed($e,corner1X) $Ed($e,corner1Y) $Ed($e,corner1Z) $Ed($e,corner2X) $Ed($e,corner2Y) $Ed($e,corner2Z) $Ed(EdLabelVOI,method)
    Ed(editor)   SetInput ""
    Ed(editor)   UseInputOff

    EdUpdateAfterApplyEffect $v
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIB1
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIB1 {x y} {
    global Ed

    set s [Slicer GetActiveSlice]
    Slicer SetReformatPoint $s $x $y
    scan [Slicer GetIjkPoint] "%g %g %g" xIjk yIjk zIjk
    set corner $Ed(EdLabelVOI,activeCorner)
    set Ed(EdLabelVOI,${corner}X) [EdLabelVOIRoundFloat $xIjk]
    set Ed(EdLabelVOI,${corner}Y) [EdLabelVOIRoundFloat $yIjk]
    set Ed(EdLabelVOI,${corner}Z) [EdLabelVOIRoundFloat $zIjk]
    set Ed(EdLabelVOI,${corner}x) $x
    set Ed(EdLabelVOI,${corner}y) $y

    EdLabelVOIUpdateVOIBox 1
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIUpdateVOIBox
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIUpdateVOIBox {render} {
    global Ed

    Slicer DrawSetShapeToPolygon
    Slicer DrawSetRadius 1
    Slicer DrawSetColor 1.0 0.0 0.0
    Slicer DrawSetSelectedPointColor 1.0 0.0 0.0
    Slicer DrawDeleteAll

    set slice [EdLabelVOIGetActiveSlice]
    
    if {$Ed(EdLabelVOI,corner1Z) < $Ed(EdLabelVOI,corner2Z)} {
    set minZ $Ed(EdLabelVOI,corner1Z)
    set maxZ $Ed(EdLabelVOI,corner2Z)
    } else {
    set minZ $Ed(EdLabelVOI,corner2Z)
    set maxZ $Ed(EdLabelVOI,corner1Z)
    }

    if {($slice < $minZ) || ($slice > $maxZ)} {
    if {$render == "1"} {
        RenderAll
    }
    return
    }    

    if {$Ed(EdLabelVOI,corner1x) < $Ed(EdLabelVOI,corner2x)} {
    set minX $Ed(EdLabelVOI,corner1x)
    set maxX $Ed(EdLabelVOI,corner2x)
    } else {
    set minX $Ed(EdLabelVOI,corner2x)
    set maxX $Ed(EdLabelVOI,corner1x)
    }

    if {$Ed(EdLabelVOI,corner1y) < $Ed(EdLabelVOI,corner2y)} {
    set minY $Ed(EdLabelVOI,corner1y)
    set maxY $Ed(EdLabelVOI,corner2y)
    } else {
    set minY $Ed(EdLabelVOI,corner2y)
    set maxY $Ed(EdLabelVOI,corner1y)
    }

    Slicer DrawInsertPoint $minX $minY
    Slicer DrawInsertPoint $minX $maxY
    Slicer DrawInsertPoint $maxX $maxY
    Slicer DrawInsertPoint $maxX $minY
    Slicer DrawInsertPoint $minX $minY

    if {$render == "1"} {
    RenderAll
    }
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIRoundFloat
# Mathematically not perfect, but this is the way it is used
# in other Slicer modules, and without this, discrepancies would
# occur.
# .ARGS
#   x    float number
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIRoundFloat {x} {
    if {$x >= 0} {
    set ret [expr int($x + 0.49)]
    } else {
    set ret [expr int($x - 0.51)]
    }

    return $ret
}

#-------------------------------------------------------------------------------
# .PROC EdLabelVOIGetActiveSlice
#   Returns the active slice number.
#   Works on native slices only.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLabelVOIGetActiveSlice {} {
    # Get IJK coordinates
    set s [Slicer GetActiveSlice]
    Slicer SetReformatPoint $s 0 0
    scan [Slicer GetIjkPoint] "%g %g %g" xIjk yIjk zIjk

    if {$zIjk >= 0} {
    set z [expr int($zIjk + 0.49)]
    } else {
    set z [expr int($zIjk - 0.51)]
    }

    return $z
}
