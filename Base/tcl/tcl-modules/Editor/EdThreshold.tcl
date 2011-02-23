#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdThreshold.tcl,v $
#   Date:      $Date: 2008/01/31 22:03:46 $
#   Version:   $Revision: 1.25 $
# 
#===============================================================================
# FILE:        EdThreshold.tcl
# PROCEDURES:  
#   EdThresholdInit
#   EdThresholdBuildVTK
#   EdThresholdBuildGUI
#   EdThresholdEnter
#   EdThresholdExit
#   EdThresholdUpdateSliderRange
#   EdThresholdUpdateInteractive
#   EdThresholdSetInput
#   EdThresholdSetInteract
#   EdThresholdUpdateInit
#   EdThresholdUpdate
#   EdThresholdRenderInteractive
#   EdThresholdLabel
#   EdThresholdApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdThresholdInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdInit {} {
    global Ed Gui

    set e EdThreshold
    set Ed($e,name)      "Threshold"
    set Ed($e,initials)  "Th"
    set Ed($e,desc)      "Threshold: assign a label to a pixel range."
    set Ed($e,rank)      1
    set Ed($e,procGUI)   EdThresholdBuildGUI
    set Ed($e,procVTK)   EdThresholdBuildVTK
    set Ed($e,procEnter) EdThresholdEnter
    set Ed($e,procExit)  EdThresholdExit

    # Required
    set Ed($e,scope)  3D 
    set Ed($e,input)  Original

    # Windows98 Version II can't render histograms
    # the histogram is broken
    set Ed($e,histogram) Off
    #set Ed($e,histogram) On
    if {$Gui(pc) == 1} {
        set Ed($e,histogram) Off
    }

    set Ed($e,interact) Active

    set Ed($e,lower) 50
    set Ed($e,upper) 150
    set Ed($e,replaceIn) 1
    set Ed($e,replaceOut) 1
    set Ed($e,bg) 0
    set Ed($e,rangeLow) 0
    set Ed($e,rangeHigh) 500
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdBuildVTK {} {
    global Ed Label Slice

    foreach s $Slice(idList) {
        vtkImageThreshold Ed(EdThreshold,thresh$s)
        # set the values first, as setting them automatically sets the replace flag to 1
        Ed(EdThreshold,thresh$s) SetInValue    0
        Ed(EdThreshold,thresh$s) SetOutValue   $Ed(EdThreshold,bg)
        Ed(EdThreshold,thresh$s) SetReplaceIn  $Ed(EdThreshold,replaceIn)
        Ed(EdThreshold,thresh$s) SetReplaceOut $Ed(EdThreshold,replaceOut)
        Ed(EdThreshold,thresh$s) SetOutputScalarTypeToShort
    }
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdBuildGUI {} {
    global Ed Gui Label Volume

    #-------------------------------------------
    # Threshold frame
    #-------------------------------------------
    set f $Ed(EdThreshold,frame)

    frame $f.fInput     -bg $Gui(activeWorkspace)
    frame $f.fScope     -bg $Gui(activeWorkspace)
    frame $f.fInteract  -bg $Gui(activeWorkspace)
    frame $f.fHistogram -bg $Gui(activeWorkspace)
    frame $f.fGrid      -bg $Gui(activeWorkspace)
    frame $f.fSliders   -bg $Gui(activeWorkspace)
    frame $f.fApply     -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fSliders $f.fHistogram $f.fInput $f.fScope \
        $f.fInteract $f.fApply \
        -side top -pady $Gui(pad) -fill x

    EdBuildScopeGUI $Ed(EdThreshold,frame).fScope Ed(EdThreshold,scope) Multi

    EdBuildInputGUI $Ed(EdThreshold,frame).fInput Ed(EdThreshold,input) \
        "-command EdThresholdSetInput"

    EdBuildInteractGUI $Ed(EdThreshold,frame).fInteract Ed(EdThreshold,interact) \
        "-command EdThresholdSetInteract"

    #-------------------------------------------
    # Threshold->Histogram frame
    #-------------------------------------------
    set f $Ed(EdThreshold,frame).fHistogram

    if {$Ed(EdThreshold,histogram) == "On"} {
        eval {label $f.l -text "Histogram:"} $Gui(WLA)
        frame $f.fHistBorder -bg $Gui(activeWorkspace) -relief sunken -bd 2
        pack $f.l $f.fHistBorder -side left -padx $Gui(pad) -pady $Gui(pad)

        #-------------------------------------------
        # Threshold->Histogram->HistBorder frame
        #-------------------------------------------
        set f $Ed(EdThreshold,frame).fHistogram.fHistBorder

        MakeVTKImageWindow editThreshHist
        editThreshHistMapper SetInput [Volume(0,vol) GetHistogramPlot]

        vtkTkRenderWidget $f.fHist -rw editThreshHistWin \
            -width $Volume(histWidth) -height $Volume(histHeight)  
        bind $f.fHist <Expose> {ExposeTkImageViewer %W %x %y %w %h}
        pack $f.fHist
    }

    #-------------------------------------------
    # Threshold->Grid frame
    #-------------------------------------------
    set f $Ed(EdThreshold,frame).fGrid

    # Output label
    eval {button $f.bOutput -text "Output:" \
        -command "ShowLabels EdThresholdLabel"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdThresholdLabel"
    bind $f.eOutput <FocusOut> "EdThresholdLabel"
    eval {entry $f.eName -width 14 -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w

    lappend Label(colorWidgetList) $f.eName

    # Whether to Replace the output
    eval {checkbutton $f.cReplaceOutput \
        -text "Replace Output" -width 14 -variable Ed(EdThreshold,replaceOut) \
       -indicatoron 0} $Gui(WCA) {-command "EdThresholdUpdate; RenderAll"}
    TooltipAdd $f.cReplaceOutput "Determines whether to replace the pixel out of range with 0"
    grid $f.cReplaceOutput -columnspan 2 -pady $Gui(pad) -sticky e

    # Whether to Replace the input
    eval {checkbutton $f.cReplaceInput \
        -text "Replace Input" -width 14 -variable Ed(EdThreshold,replaceIn) \
       -indicatoron 0} $Gui(WCA) {-command "EdThresholdUpdate; RenderAll"}
    TooltipAdd $f.cReplaceInput "Determines whether to replace the pixel in range with the label in the Output entry box"
    grid $f.cReplaceInput -columnspan 2 -pady $Gui(pad) -sticky e

    #-------------------------------------------
    # Threshold->Sliders frame
    #-------------------------------------------
    set f $Ed(EdThreshold,frame).fSliders

    foreach slider "Lower Upper" text "Lo Hi" {
        eval {label $f.l$slider -text "$text:"} $Gui(WLA)
        eval {entry $f.e$slider -width 6 \
            -textvariable Ed(EdThreshold,[Uncap $slider])} $Gui(WEA)
        bind $f.e$slider <Return>   "EdThresholdUpdate; RenderActive;"
        bind $f.e$slider <FocusOut> "EdThresholdUpdate; RenderActive;"
        eval {scale $f.s$slider -from $Ed(EdThreshold,rangeLow) -to $Ed(EdThreshold,rangeHigh)\
            -length 220 -variable Ed(EdThreshold,[Uncap $slider])  -resolution 1 \
            -command "EdThresholdUpdateInit $f.s$slider"} \
            $Gui(WSA) {-sliderlength 22}
        grid $f.l$slider $f.e$slider -padx 2 -pady 2 -sticky w
        grid $f.l$slider -sticky e
        grid $f.s$slider -columnspan 2 -pady 2 

        set Ed(EdThreshold,slider$slider) $f.s$slider
    }

    #-------------------------------------------
    # Threshold->Apply frame
    #-------------------------------------------
    set f $Ed(EdThreshold,frame).fApply

    eval {button $f.bApply -text "Apply" \
        -command "EdThresholdApply"} $Gui(WBA) {-width 8}
    pack $f.bApply

}

#-------------------------------------------------------------------------------
# .PROC EdThresholdEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdEnter {} {
    global Ed Label

    # Make sure we're colored
    LabelsColorWidgets

    EdThresholdUpdateSliderRange
    EdThresholdUpdateInteractive
    EdThresholdUpdate
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdExit {} {
    global Ed

    Slicer BackFilterOff
    Slicer ForeFilterOff
    Slicer ReformatModified
    Slicer Update
    EdThresholdRenderInteractive
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdUpdateSliderRange
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdUpdateSliderRange {} {
    global Volume Ed

    set v [EditorGetInputID $Ed(EdThreshold,input)]

    set lo [Volume($v,vol) GetRangeLow]
    set hi [Volume($v,vol) GetRangeHigh]
    set th [Volume($v,vol) GetBimodalThreshold]

    $Ed(EdThreshold,sliderLower) config -from $lo -to $hi
    $Ed(EdThreshold,sliderUpper) config -from $lo -to $hi

    # Auto EdThresholdold
    set Ed(EdThreshold,lower) $th
    set Ed(EdThreshold,upper) $hi

    # Refresh Histogram
    if {$Ed(EdThreshold,histogram) == "On"} {
        editThreshHistMapper SetInput [Volume($v,vol) GetHistogramPlot]
        editThreshHistWin Render
    }
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdUpdateInteractive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdUpdateInteractive {} {
    global Ed Slice
    
    foreach s $Slice(idList) {
        Slicer SetFirstFilter $s Ed(EdThreshold,thresh$s)
        Slicer SetLastFilter  $s Ed(EdThreshold,thresh$s)
    }

    # Layers: Back=Original, Fore=Working
    if {$Ed(EdThreshold,input) == "Original"} {
        Slicer BackFilterOn
        Slicer ForeFilterOff
    } else {
        Slicer BackFilterOff
        Slicer ForeFilterOn
    }

    # Just active slice?
    if {$Ed(EdThreshold,interact) == "Active"} {
        Slicer FilterActiveOn
    } else {
        Slicer FilterActiveOff
    }

    Slicer ReformatModified
    Slicer Update
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdSetInput
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdSetInput {} {
    global Ed Label

    EdThresholdUpdateSliderRange
    EdThresholdUpdateInteractive
    EdThresholdUpdate
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdSetInteract
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdSetInteract {} {
    global Ed Label

    EdThresholdUpdateInteractive
    EdThresholdUpdate
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdUpdateInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdUpdateInit {widget {value ""}} {

    $widget config -command "EdThresholdUpdate; RenderActive"
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdUpdate {{value ""}} {
    global Ed Label Slice

    # Validate input
    if {[ValidateInt $Ed(EdThreshold,lower)] == 0} {
        tk_messageBox -message "Lo threshold is not an integer."
        return
    }
    if {[ValidateInt $Ed(EdThreshold,upper)] == 0} {
        tk_messageBox -message "Hi threshold is not an integer."
        return
    }
    if {$Label(label) == ""} {
        return
    }
   
    foreach s $Slice(idList) {
        # set the values first, as setting them automatically sets the replace flag to 1
        Ed(EdThreshold,thresh$s) SetInValue       $Label(label)
        Ed(EdThreshold,thresh$s) SetOutValue      $Ed(EdThreshold,bg)
        Ed(EdThreshold,thresh$s) SetReplaceIn     $Ed(EdThreshold,replaceIn)
        Ed(EdThreshold,thresh$s) SetReplaceOut    $Ed(EdThreshold,replaceOut)
        Ed(EdThreshold,thresh$s) ThresholdBetween $Ed(EdThreshold,lower) $Ed(EdThreshold,upper)
    }
    EdThresholdRenderInteractive
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdRenderInteractive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdRenderInteractive {} {
    global Ed

    Render$Ed(EdThreshold,interact)
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdLabel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdLabel {} {
    global Ed

    LabelsFindLabel
    EdThresholdUpdate
}

#-------------------------------------------------------------------------------
# .PROC EdThresholdApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdThresholdApply {} {
    global Ed Volume Label Gui

    set e EdThreshold
    set v [EditorGetInputID $Ed($e,input)]

    # Validate input
    if {[ValidateInt $Ed($e,lower)] == 0} {
        tk_messageBox -message "Lo threshold is not an integer."
        return
    }
    if {[ValidateInt $Ed($e,upper)] == 0} {
        tk_messageBox -message "Hi threshold is not an integer."
        return
    }
    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Output label is not an integer."
        return
    }

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native

    set Gui(progressText) "Threshold [Volume($v,node) GetName]"    

    set min        $Ed($e,lower)
    set max        $Ed($e,upper)
    set in         $Label(label)
    set out        $Ed($e,bg)
    set replaceIn  $Ed($e,replaceIn)
    set replaceOut $Ed($e,replaceOut)
    Ed(editor)     Threshold $min $max $in $out $replaceIn $replaceOut
    Ed(editor)     SetInput ""
    Ed(editor)     UseInputOff

    EdUpdateAfterApplyEffect $v

    # Reset sliders if the input was working, because that means
    # it changed.
    if {$v == [EditorGetWorkingID]} {
        EdThresholdSetInput
    }
}

