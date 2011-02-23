#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdIdentifyIslands.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.17 $
# 
#===============================================================================
# FILE:        EdIdentifyIslands.tcl
# PROCEDURES:  
#   EdIdentifyIslandsInit
#   EdIdentifyIslandsBuildGUI
#   EdIdentifyIslandsEnter
#   EdIdentifyIslandsNoThreshold
#   EdIdentifyIslandsApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdIdentifyIslandsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdIdentifyIslandsInit {} {
    global Ed Gui

    set e EdIdentifyIslands
    set Ed($e,name)      "Identify Islands"
    set Ed($e,initials)  "II"
    set Ed($e,desc)      "Identify Islands: label islands uniquely."
    set Ed($e,rank)      5
    set Ed($e,procGUI)   EdIdentifyIslandsBuildGUI
    set Ed($e,procEnter) EdIdentifyIslandsEnter

    # Required
    set Ed($e,scope) Single 
    set Ed($e,input) Working

    set Ed($e,fgMin)   $Gui(minShort)
    set Ed($e,fgMax)   $Gui(maxShort)
    set Ed($e,inputLabel) 0
}

#-------------------------------------------------------------------------------
# .PROC EdIdentifyIslandsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdIdentifyIslandsBuildGUI {} {
    global Ed Gui Label

    #-------------------------------------------
    # IdentifyIslands frame
    #-------------------------------------------
    set f $Ed(EdIdentifyIslands,frame)

    frame $f.fInput   -bg $Gui(activeWorkspace)
    frame $f.fScope   -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fInput $f.fScope $f.fApply \
        -side top -pady $Gui(pad) -fill x

    EdBuildScopeGUI $Ed(EdIdentifyIslands,frame).fScope Ed(EdIdentifyIslands,scope) Multi
    EdBuildInputGUI $Ed(EdIdentifyIslands,frame).fInput Ed(EdIdentifyIslands,input)

    #-------------------------------------------
    # IdentifyIslands->Grid frame
    #-------------------------------------------
    set f $Ed(EdIdentifyIslands,frame).fGrid

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
        -command "EdIdentifyIslandsNoThreshold"} $Gui(WBA)

    # Min Threshold
    eval {label $f.lMinFore -text "Min Threshold: "} $Gui(WLA)
    eval {entry $f.eMinFore -width 6 \
        -textvariable Ed(EdIdentifyIslands,fgMin)} $Gui(WEA)
    grid $f.lMinFore $f.eMinFore $f.bNo -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.eMinFore $f.bNo -sticky w
    grid $f.bNo -rowspan 2

    # Max Threshold
    eval {label $f.lMaxFore -text "Max Threshold: "} $Gui(WLA)
    eval {entry $f.eMaxFore -width 6 \
        -textvariable Ed(EdIdentifyIslands,fgMax)} $Gui(WEA)
    grid $f.lMaxFore $f.eMaxFore -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.eMaxFore -sticky w

    #-------------------------------------------
    # IdentifyIslands->Apply frame
    #-------------------------------------------
    set f $Ed(EdIdentifyIslands,frame).fApply

#    eval {button $f.bApply -text "Apply" \
#        -command "EdIdentifyIslandsApply"} $Gui(WBA) {-width 8}
#    pack $f.bApply -side top -padx $Gui(pad) -pady 2

    eval {label $f.lApply1 -text "Apply by clicking on the"} $Gui(WLA)
    eval {label $f.lApply2 -text "'sea' which contains the 'islands'."} $Gui(WLA)
    pack $f.lApply1 $f.lApply2 -side top -pady 0 -padx 0

}

#-------------------------------------------------------------------------------
# .PROC EdIdentifyIslandsEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdIdentifyIslandsEnter {} {
    global Ed

    # Color the label value 
    LabelsColorWidgets
}

#-------------------------------------------------------------------------------
# .PROC EdIdentifyIslandsNoThreshold
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdIdentifyIslandsNoThreshold {} {
    global Ed Gui
    
    set Ed(EdIdentifyIslands,fgMin)  $Gui(minShort)
    set Ed(EdIdentifyIslands,fgMax)  $Gui(maxShort)
}

#-------------------------------------------------------------------------------
# .PROC EdIdentifyIslandsApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdIdentifyIslandsApply {} {
    global Ed Volume Label Gui

    set e EdIdentifyIslands
    set v [EditorGetInputID $Ed($e,input)]

    # Validate input
    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Label Of The Sea is not an integer."
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

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native

    set Gui(progressText) "IdentifyIslands in [Volume($v,node) GetName]"
    
    # Determine the input label
    set Label(label) $Ed($e,inputLabel)
    LabelsFindLabel
    
    set bg        $Label(label)
    set fgMin     $Ed($e,fgMin)
    set fgMax     $Ed($e,fgMax)
    Ed(editor)    IdentifyIslands $bg $fgMin $fgMax
    Ed(editor)    SetInput ""
    Ed(editor)    UseInputOff

    EdUpdateAfterApplyEffect $v
}

