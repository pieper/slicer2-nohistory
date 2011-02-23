#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdChangeLabel.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.16 $
# 
#===============================================================================
# FILE:        EdChangeLabel.tcl
# PROCEDURES:  
#   EdChangeLabelInit
#   EdChangeLabelBuildGUI
#   EdChangeLabelEnter
#   EdChangeLabelApply
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC EdChangeLabelInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdChangeLabelInit {} {
    global Ed

    set e EdChangeLabel
    set Ed($e,name)      "Change Label"
    set Ed($e,initials)  "CL"
    set Ed($e,desc)      "Change Label: re-label all similar pixels."
    set Ed($e,rank)      3
    set Ed($e,procGUI)   EdChangeLabelBuildGUI
    set Ed($e,procEnter) EdChangeLabelEnter

    # Required
    set Ed($e,scope) 3D 
    set Ed($e,input) Working

    set Ed($e,inputLabel) 0
}

#-------------------------------------------------------------------------------
# .PROC EdChangeLabelBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdChangeLabelBuildGUI {} {
    global Ed Gui Label

    #-------------------------------------------
    # ChangeLabel frame
    #-------------------------------------------
    set f $Ed(EdChangeLabel,frame)

    frame $f.fInput   -bg $Gui(activeWorkspace)
    frame $f.fScope   -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fInput $f.fScope $f.fApply \
        -side top -pady $Gui(pad) -fill x

    EdBuildScopeGUI $Ed(EdChangeLabel,frame).fScope Ed(EdChangeLabel,scope) Multi
    EdBuildInputGUI $Ed(EdChangeLabel,frame).fInput Ed(EdChangeLabel,input)

    #-------------------------------------------
    # ChangeLabel->Grid frame
    #-------------------------------------------
    set f $Ed(EdChangeLabel,frame).fGrid

    # Input label
    set Ed(fOpChangeLabelGrid) $f
    eval {label $f.lInput -text "Value to change:"} $Gui(WLA)
    eval {entry $f.eInput -width 6 \
        -textvariable Ed(EdChangeLabel,inputLabel)} $Gui(WEA)

    # Output label
    eval {button $f.bOutput -text "Output:" -command "ShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "LabelsFindLabel"
    bind $f.eOutput <FocusOut> "LabelsFindLabel"
    eval {entry $f.eName -width 14 \
        -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}

    lappend Label(colorWidgetList) $f.eName

    grid $f.lInput $f.eInput -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f.bOutput $f.eOutput $f.eName -padx $Gui(pad) -pady $Gui(pad) -sticky e

    #-------------------------------------------
    # ChangeLabel->Apply frame
    #-------------------------------------------
    set f $Ed(EdChangeLabel,frame).fApply

    eval {button $f.bApply -text "Apply" \
        -command "EdChangeLabelApply"} $Gui(WBA) {-width 8}
    eval {label $f.lApply -text "Also apply by clicking on a label."} $Gui(WLA)
    pack $f.bApply $f.lApply -side top -padx $Gui(pad) -pady 2

}

#-------------------------------------------------------------------------------
# .PROC EdChangeLabelEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdChangeLabelEnter {} {
    global Ed

    LabelsColorWidgets
}

#-------------------------------------------------------------------------------
# .PROC EdChangeLabelApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdChangeLabelApply {} {
    global Ed Volume Label Gui

    set e EdChangeLabel
    set v [EditorGetInputID $Ed($e,input)]

    # Validate input
    if {[ValidateInt $Ed($e,inputLabel)] == 0} {
        tk_messageBox -message "Value To Change is not an integer."
        return
    }
    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Output label is not an integer."
        return
    }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native

    set Gui(progressText) "Change Label in [Volume($v,node) GetName]"
    
    set fg       $Ed($e,inputLabel)
    set fgNew    $Label(label)
    Ed(editor)   ChangeLabel $fg $fgNew
    Ed(editor)   SetInput ""
    Ed(editor)   UseInputOff

    EdUpdateAfterApplyEffect $v
}

