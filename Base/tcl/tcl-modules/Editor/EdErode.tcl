#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdErode.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.16 $
# 
#===============================================================================
# FILE:        EdErode.tcl
# PROCEDURES:  
#   EdErodeInit
#   EdErodeBuildGUI
#   EdErodeEnter
#   EdErodeApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdErodeInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdErodeInit {} {
    global Ed

    set e EdErode
    set Ed($e,name)      "Erode"
    set Ed($e,initials)  "Er"
    set Ed($e,desc)      "Erode: re-label perimeter pixels."
    set Ed($e,rank)      2
    set Ed($e,procGUI)   EdErodeBuildGUI
    set Ed($e,procEnter) EdErodeEnter

    # Required
    set Ed($e,scope) Multi 
    set Ed($e,input) Working

    set Ed($e,multi) Native
    set Ed($e,fill) 0
    set Ed($e,iterations) 1
    set Ed($e,neighbors) 4
}

#-------------------------------------------------------------------------------
# .PROC EdErodeBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdErodeBuildGUI {} {
    global Ed Gui Label

    set e EdErode
    #-------------------------------------------
    # Erode frame
    #-------------------------------------------
    set f $Ed(EdErode,frame)

    frame $f.fInput   -bg $Gui(activeWorkspace)
    frame $f.fScope   -bg $Gui(activeWorkspace)
    frame $f.fMulti   -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fInput $f.fScope $f.fMulti $f.fApply \
        -side top -pady $Gui(pad) -fill x

    EdBuildInputGUI $Ed($e,frame).fInput Ed($e,input)
    EdBuildScopeGUI $Ed($e,frame).fScope Ed($e,scope) 
    EdBuildMultiGUI $Ed($e,frame).fMulti Ed($e,multi) 

    #-------------------------------------------
    # Erode->Grid frame
    #-------------------------------------------
    set f $Ed(EdErode,frame).fGrid

    # Fields for background, foreground pixel values
    eval {button $f.bBack -text "Value to Erode:" \
        -command "ShowLabels"} $Gui(WBA)
    eval {entry $f.eBack -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eBack <Return>   "LabelsFindLabel"
    bind $f.eBack <FocusOut> "LabelsFindLabel"
    eval {entry $f.eName -width 6 \
        -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    eval {label $f.lFore -text "Fill value: "} $Gui(WLA)
    eval {entry $f.eFore -width 6 \
        -textvariable Ed(EdErode,fill)} $Gui(WEA)
    eval {label $f.lIter -text "Iterations: "} $Gui(WLA)
    eval {entry $f.eIter -width 6 \
        -textvariable Ed(EdErode,iterations)} $Gui(WEA)
    grid $f.bBack $f.eBack $f.eName -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.lFore $f.eFore -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.lIter $f.eIter -padx $Gui(pad) -pady $Gui(pad) -sticky e

    lappend Label(colorWidgetList) $f.eName

    # Neighborhood Size
    eval {label $f.lNeighbor -text "Neighborhood Size: "} $Gui(WLA)
    frame $f.fNeighbor -bg $Gui(activeWorkspace)
    foreach mode "4 8" {
        eval {radiobutton $f.fNeighbor.r$mode \
            -text "$mode" -variable Ed(EdErode,neighbors) -value $mode -width 2 \
            -indicatoron 0} $Gui(WCA)
        pack $f.fNeighbor.r$mode -side left -padx 0
    }
    grid $f.lNeighbor $f.fNeighbor -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.fNeighbor -sticky w


    #-------------------------------------------
    # Erode->Apply frame
    #-------------------------------------------
    set f $Ed(EdErode,frame).fApply

    eval {button $f.bErode -text "Erode" \
        -command "EdErodeApply Erode"} $Gui(WBA)
    eval {button $f.bDilate -text "Dilate" \
        -command "EdErodeApply Dilate"} $Gui(WBA)
    eval {button $f.bED -text "Erode & Dilate" \
        -command "EdErodeApply ErodeDilate"} $Gui(WBA)
    eval {button $f.bDE -text "Dilate & Erode" \
        -command "EdErodeApply DilateErode"} $Gui(WBA)
    grid $f.bErode  $f.bED -padx $Gui(pad) -pady $Gui(pad)
    grid $f.bDilate $f.bDE -padx $Gui(pad) -pady $Gui(pad)

}

#-------------------------------------------------------------------------------
# .PROC EdErodeEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdErodeEnter {} {
    global Ed

    LabelsColorWidgets
}

#-------------------------------------------------------------------------------
# .PROC EdErodeApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdErodeApply {effect} {
    global Ed Volume Label Gui

    set e EdErode
    set v [EditorGetInputID $Ed($e,input)]

    # Validate input
    if {[ValidateInt $Ed($e,fill)] == 0} {
        DevErrorWindow "Fill value is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,iterations)] == 0} {
        DevErrorWindow "Iterations is not an integer."
        return
    }
    if {[ValidateInt $Label(label)] == 0} {
        DevErrorWindow "Value To Erode is not an integer."
        return
    }
    if { $Ed($e,iterations) > 1 && $Ed($e,scope) == "3D" } {
        DevErrorWindow "Multiple iterations in 3D scope not supported"
        set Ed($e,iterations) 1
    }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) $Ed($e,multi)

    set Gui(progressText) "$effect [Volume($v,node) GetName]"
    
    set fg         $Label(label)
    set bg         $Ed($e,fill)
    set neighbors  $Ed($e,neighbors)     
    set iterations $Ed($e,iterations)
    Ed(editor)     $effect $fg $bg $neighbors $iterations
    Ed(editor)     SetInput ""
    Ed(editor)     UseInputOff

    EdUpdateAfterApplyEffect $v
}

