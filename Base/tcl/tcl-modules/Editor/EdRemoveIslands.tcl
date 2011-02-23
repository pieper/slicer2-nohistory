#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdRemoveIslands.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.17 $
# 
#===============================================================================
# FILE:        EdRemoveIslands.tcl
# PROCEDURES:  
#   EdRemoveIslandsInit
#   EdRemoveIslandsBuildGUI
#   EdRemoveIslandsEnter
#   EdRemoveIslandsNoThreshold
#   EdRemoveIslandsApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdRemoveIslandsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdRemoveIslandsInit {} {
    global Ed Gui

    set e EdRemoveIslands
    set Ed($e,name)      "Remove Islands"
    set Ed($e,initials)  "RI"
    set Ed($e,desc)      "Remove Islands smaller than an area."
    set Ed($e,rank)      5
    set Ed($e,procGUI)   EdRemoveIslandsBuildGUI
    set Ed($e,procEnter) EdRemoveIslandsEnter

    # Required
    set Ed($e,scope) Multi 
    set Ed($e,input) Working

    set Ed($e,multi) Native
    set Ed($e,minSize) 10000
    set Ed($e,fgMin)   $Gui(minShort)
    set Ed($e,fgMax)   $Gui(maxShort)
    set Ed($e,inputLabel) 0
}

#-------------------------------------------------------------------------------
# .PROC EdRemoveIslandsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdRemoveIslandsBuildGUI {} {
    global Ed Gui Label

    set e EdRemoveIslands
    #-------------------------------------------
    # RemoveIslands frame
    #-------------------------------------------
    set f $Ed($e,frame)

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
    # RemoveIslands->Grid frame
    #-------------------------------------------
    set f $Ed(EdRemoveIslands,frame).fGrid

    # Island Size
    eval {label $f.lMinIsland -text "Min Island Area: "} $Gui(WLA)
    eval {entry $f.eMinIsland -width 6 \
        -textvariable Ed(EdRemoveIslands,minSize)} $Gui(WEA)
    grid $f.lMinIsland $f.eMinIsland -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.eMinIsland -sticky w

    # Label of Sea
    eval {button $f.bOutput -text "Label of the sea:" -command "ShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "LabelsFindLabel"
    bind $f.eOutput <FocusOut> "LabelsFindLabel"
    eval {entry $f.eName -width 14 -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w

    lappend Label(colorWidgetList) $f.eName

    # No Threshold
    eval {button $f.bNo -text "No Threshold" \
        -command "EdRemoveIslandsNoThreshold"} $Gui(WBA)

    # Min Threshold
    eval {label $f.lMinFore -text "Min Threshold: "} $Gui(WLA)
    eval {entry $f.eMinFore -width 6 \
        -textvariable Ed(EdRemoveIslands,fgMin)} $Gui(WEA)
    grid $f.lMinFore $f.eMinFore $f.bNo -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.eMinFore $f.bNo -sticky w
    grid $f.bNo -rowspan 2

    # Max Threshold
    eval {label $f.lMaxFore -text "Max Threshold: "} $Gui(WLA)
    eval {entry $f.eMaxFore -width 6 \
        -textvariable Ed(EdRemoveIslands,fgMax)} $Gui(WEA)
    grid $f.lMaxFore $f.eMaxFore -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.eMaxFore -sticky w

    #-------------------------------------------
    # RemoveIslands->Apply frame
    #-------------------------------------------
    set f $Ed(EdRemoveIslands,frame).fApply

#    eval {button $f.bApply -text "Apply" \
#        -command "EdRemoveIslandsApply"} $Gui(WBA) {-width 8}
#    pack $f.bApply -side top -padx $Gui(pad) -pady 2

    eval {label $f.lApply1 -text "Apply by clicking on the"} $Gui(WLA)
    eval {label $f.lApply2 -text "'sea' which contains the 'islands'."} $Gui(WLA)
    pack $f.lApply1 $f.lApply2 -side top -pady 0 -padx 0

}

#-------------------------------------------------------------------------------
# .PROC EdRemoveIslandsEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdRemoveIslandsEnter {} {
    global Ed

    # Color the label value 
    LabelsColorWidgets
}

#-------------------------------------------------------------------------------
# .PROC EdRemoveIslandsNoThreshold
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdRemoveIslandsNoThreshold {} {
    global Ed Gui
    
    set Ed(EdRemoveIslands,fgMin)  $Gui(minShort)
    set Ed(EdRemoveIslands,fgMax)  $Gui(maxShort)
}

#-------------------------------------------------------------------------------
# .PROC EdRemoveIslandsApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdRemoveIslandsApply {} {
    global Ed Volume Label Gui

    set e EdRemoveIslands
    set v [EditorGetInputID $Ed($e,input)]

    # Validate input
    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Label Of The Sea is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,minSize)] == 0} {
        tk_messageBox -message "Min Island Area is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,fgMin)] == 0} {
        tk_messageBox -message "Min Threshold is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,fgMax)] == 0} {
        tk_messageBox -message "Max Threshold is not an integer."
        return
    }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) $Ed($e,multi)

    # Only apply to native slices
    if {[set native [EdIsNativeSlice]] != ""} {
        # TODO - remove comment if this works
        puts "Warning: check results - now allowed, but fromerly failed with:"
        puts " Please click on the slice with orient = $native."
        puts "-sp 2002-09-30"
        #tk_messageBox -message "Please click on the slice with orient = $native."
        #return
    }

    set Gui(progressText) "RemoveIslands in [Volume($v,node) GetName]"
    
    # Determine the input label
    set Label(label) $Ed($e,inputLabel)
    LabelsFindLabel
    
    set bg        $Label(label)
    set minSize   $Ed($e,minSize)
    set fgMin     $Ed($e,fgMin)
    set fgMax     $Ed($e,fgMax)
    Ed(editor)  RemoveIslands $bg $fgMin $fgMax $minSize
    Ed(editor)  SetInput ""
    Ed(editor)  UseInputOff

    EdUpdateAfterApplyEffect $v
}

