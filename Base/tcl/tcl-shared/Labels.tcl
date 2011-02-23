#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Labels.tcl,v $
#   Date:      $Date: 2006/03/06 19:24:26 $
#   Version:   $Revision: 1.29 $
# 
#===============================================================================
# FILE:        Labels.tcl
# PROCEDURES:  
#   LabelsInit
#   LabelsUpdateMRML
#   LabelsBuildGUI
#   LabelsHideLabels
#   LabelsUnHideLabels
#   LabelsColorSample scale
#   ShowLabels callback x y
#   ShowColors callback x y
#   LabelsDisplayColors
#   LabelsGetColorFromPosition x y
#   LabelsBrowseColor x y
#   LabelsSelectColor x y c
#   LabelsLeaveGrid
#   LabelsDisplayLabels
#   LabelsSelectLabelClick index
#   LabelsSelectLabel i
#   LabelsSetColor colorName
#   LabelsColorWidgets
#   LabelsFindLabel
#   LabelsSetOutputLabel p
#   LabelsCreateColor
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC LabelsInit
# Initialise global variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsInit {} {
    global Module Label 

    set m Labels

    # Define Procedures
    lappend Module(procGUI)  LabelsBuildGUI
    lappend Module(procMRML) LabelsUpdateMRML

    # Define Dependencies
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
                                  {$Revision: 1.29 $} {$Date: 2006/03/06 19:24:26 $}]


    # Props
    set Label(nameBrowse) ""
    set Label(activeID) ""
    set Label(label) ""
    set Label(name) ""
    # so other modules can have their own label names set
    set Label(nameList) {Label(name)}
    set Label(diffuse) "1 1 1"
    set Label(dim) 200
    set Label(gridDim) 8
    set Label(gridCellDim) 8
    set Label(nameNew) NewColor
    set Label(labelNew) 1
    set Label(diffuseNew) "1 1 1"
    set Label(callback) ""
    set Label(hideLabels) 0

    set Label(colorWidgetList) ""

    set Label(sample,red)      1.0
    set Label(sample,green)    1.0
    set Label(sample,blue)     1.0
}

#-------------------------------------------------------------------------------
# .PROC LabelsUpdateMRML
# Update the Label mrml elements and redraw the gui elements.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsUpdateMRML {} {
    global Label Color

    if {$Color(idList) == ""} {
        set Label(activeID) ""
        set Label(nameBrowse) ""
        foreach name $Label(nameList) {
            set $name ""
        }
        set Label(label) ""
        set Label(diffuse) "0 0 0"
        return
    }
    
    # If no active color, take the second one
    if {$Label(activeID) == "" || \
        [lsearch $Color(idList) $Label(activeID)] == -1} {
        LabelsSelectColor 0 0 [lindex $Color(idList) 1]
    }

    # If no label, take the first one for this color
    if {$Label(label) == ""} {
        set labels [Color($Label(activeID),node) GetLabels]
        set LabelsSelectLabel [lindex $labels 0]
    }

    LabelsDisplayColors
    LabelsDisplayLabels

    # Set Label(labelNew) to the next available label
    set highest 1
    foreach c $Color(idList) {
        set high [lindex [lsort -decreasing -integer [Color($c,node) GetLabels]] 0]
        if {$high > $highest} {
            set highest $high
        }    
    }
    # get the one behond the current highest
    incr highest
    if {$::Module(verbose)} {
        puts "Resetting labelNew to $highest, and diffuseNew to white, and nameNew to empty string"
    }
    set Label(labelNew) $highest
    # also reset the new diffuse value and the new label name
    set Label(diffuseNew) {1.0 1.0 1.0}
    # resets the sliders
    foreach slider "red green blue" {
        set Label(sample,$slider) 1.0
        ColorSlider $Label(s[Cap $slider]) $Label(diffuseNew)
    }

    set Label(nameNew) ""

}

#-------------------------------------------------------------------------------
# .PROC LabelsBuildGUI
# Build the labels popup window, .wLabels
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsBuildGUI {} {
    global Gui Label

    #-------------------------------------------
    # Labels Popup Window
    #-------------------------------------------
    set w .wLabels
    set Gui(wLabels) $w
    toplevel $w -class Dialog -bg $Gui(inactiveWorkspace)
    wm title $w "Select a Color"
     wm iconname $w Dialog
     wm protocol $w WM_DELETE_WINDOW "wm withdraw $w"
    if {$Gui(pc) == "0"} {
        wm transient $w .
    }
    wm withdraw $w

    # Frames
    frame $w.fTop -bg $Gui(activeWorkspace) -bd 2 -relief raised
    frame $w.fClose -bg $Gui(inactiveWorkspace)
    pack $w.fTop $w.fClose \
        -side top -pady $Gui(pad) -padx $Gui(pad)

    #-------------------------------------------
    # Labels->Close frame
    #-------------------------------------------
    set f $w.fClose

    eval {button $f.bCancel -text "Cancel" -width 6 \
        -command "wm withdraw $w"} $Gui(WBA)
        
    pack $f.bCancel -side left -padx $Gui(pad)

    #-------------------------------------------
    # Labels->Top frame
    #-------------------------------------------
    set f $w.fTop

    frame $f.fInfo -bg $Gui(activeWorkspace)
    frame $f.fData -bg $Gui(activeWorkspace)
    frame $f.fNew  -bg $Gui(activeWorkspace)
    pack $f.fInfo $f.fData $f.fNew -side top -pady 5

    #-------------------------------------------
    # Labels->Top->Info frame
    #-------------------------------------------
    set f $w.fTop.fInfo

    eval {label $f.lInfo -justify left  -text\
        "1.) Click on a color.\n2.) Click on a label value."} $Gui(WLA)
    pack $f.lInfo
    set Label(lInfo) $f.lInfo

    #-------------------------------------------
    # Labels->Top->Data frame
    #-------------------------------------------
    set f $w.fTop.fData

    frame $f.fCanvas -bg $Gui(activeWorkspace)
    frame $f.fList   -bg $Gui(activeWorkspace)
    set Label(fList) $f.fList
    pack $f.fCanvas $f.fList -side left -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Labels->Top->New frame
    #-------------------------------------------
    set f $w.fTop.fNew

    frame $f.fEntry -bg $Gui(activeWorkspace)
    frame $f.fWheel -bg $Gui(activeWorkspace)
    pack $f.fEntry $f.fWheel -side left -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Labels->Top->New->Entry frame
    #-------------------------------------------
    set f $w.fTop.fNew.fEntry

    eval {label $f.lTitle -text "Create New Color"} $Gui(WTA)
    eval {label $f.lName -text "Color:"} $Gui(WLA)
    eval {entry $f.eName -textvariable Label(nameNew) -width 15} $Gui(WEA)
    eval {label $f.lLabel -text "Label:"} $Gui(WLA) 
    eval {entry $f.eLabel -textvariable Label(labelNew) -width 15} $Gui(WEA)
    eval {button $f.bCreate -text Create -width 7 \
        -command LabelsCreateColor} $Gui(WBA)

    grid $f.lTitle -columnspan 2 -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lName $f.eName -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lLabel $f.eLabel -padx $Gui(pad) -pady $Gui(pad)
    grid $f.bCreate -column 1 -padx $Gui(pad) -pady $Gui(pad)
    
    #-------------------------------------------
    # Labels->Top->New->Wheel frame
    #-------------------------------------------
    set f $w.fTop.fNew.fWheel

    foreach slider "Red Green Blue" {

        eval {label $f.l${slider} -text "${slider}"} $Gui(WLA)
            

        eval {entry $f.e${slider} -textvariable Label(sample,[Uncap $slider]) \
            -width 3} $Gui(WEA)
        bind $f.e${slider} <Return>   "LabelsColorSample"
        bind $f.e${slider} <FocusOut> "LabelsColorSample"

        eval {scale $f.s${slider} -from 0.0 -to 1.0 -length 40 \
            -variable Label(sample,[Uncap $slider]) -command "LabelsColorSample" \
            -resolution 0.1} $Gui(WSA) {-sliderlength 15} 
            
        set Label(s$slider) $f.s$slider

        grid $f.l${slider} $f.e${slider} $f.s${slider} \
            -pady 1 -padx 1 -sticky e
    }

    #-------------------------------------------
    # Labels->Canvas frame
    #-------------------------------------------
    set f $w.fTop.fData.fCanvas

    set dim [expr $Label(dim) + 1]
    eval {canvas $f.canvas -width $dim -height $dim \
        -background $Gui(activeWorkspace) -highlightthickness 0 \
        -borderwidth 0}
    bind $f.canvas <Motion>   {LabelsBrowseColor %x %y}
    bind $f.canvas <Button-1> {LabelsSelectColor %x %y}
    bind $f.canvas <Leave>    {LabelsLeaveGrid}
    set Label(canvas) $f.canvas
    
    frame $f.fName -bg $Gui(activeWorkspace)
    eval {label $f.fName.lName -text "Color:"} $Gui(WTA)
    eval {entry $f.fName.eName -textvariable Label(nameBrowse) -width 35} \
        $Gui(WEA) {-state disabled}
    pack $f.fName.lName $f.fName.eName -side left -padx $Gui(pad) -pady 0

    pack $f.fName $f.canvas -side top -pady $Gui(pad)

    #-------------------------------------------
    # Labels->List frame
    #-------------------------------------------
    set f $w.fTop.fData.fList

    eval {label $f.lTitle -text "Labels"} $Gui(WTA)

    set Label(fLabelList) [ScrolledListbox $f.list 0 1 -height 11 -width 6]
    bind $Label(fLabelList) <ButtonRelease-1> "LabelsSelectLabelClick"

    pack $f.lTitle $f.list -side top -pady 2

}

#-------------------------------------------------------------------------------
# .PROC LabelsHideLabels
# Hide the label list Label(fList).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsHideLabels {} {
    global Label

    $Label(lInfo) config -text \
        "Click on a color."

    pack forget $Label(fList)

    set Label(hideLabels) 1
}

#-------------------------------------------------------------------------------
# .PROC LabelsUnHideLabels
# Show the label list.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsUnHideLabels {} {
    global Label

    $Label(lInfo) config -text \
        "1.) Click on a color.\n2.) Click on a label value."

    pack $Label(fList) -side left

    set Label(hideLabels) 0
}

#-------------------------------------------------------------------------------
# .PROC LabelsColorSample
# Set the Label(diffuseNew) list, loop through RGB to color the sliders, and 
# .ARGS
# int scale optional argument, not used
# .END
#-------------------------------------------------------------------------------
proc LabelsColorSample {{scale}} {
    global Label
    
    set Label(diffuseNew) \
        "$Label(sample,red) $Label(sample,green) $Label(sample,blue)"

    foreach slider "Red Green Blue" {
        ColorSlider $Label(s$slider) $Label(diffuseNew)
    }
}


#-------------------------------------------------------------------------------
# .PROC ShowLabels
# Shows the popup that allows you to pick labels.
# .ARGS
# string callback defaults to empty string, what to call when a selection is made
# int x defaults to 100, horizontal position of the popup window, passed to wm geometry as +x
# int y defaults to 100, vertical  position of the popup window, passed to wm geometry as +y
# .END
#-------------------------------------------------------------------------------
proc ShowLabels {{callback ""} {x 100} {y 100}} {
    global Gui Label

    # Recreate popup if user killed it
    if {[winfo exists $Gui(wLabels)] == 0} {
        LabelsBuildGUI
    }
    
    set Label(callback) $callback

    LabelsUnHideLabels

    ShowPopup $Gui(wLabels) $x $y
}

#-------------------------------------------------------------------------------
# .PROC ShowColors
# Display the pop up that allows you to select colors.
# .ARGS
# string callback defaults to empty string, what to call when a selection is made
# int x defaults to 100, horizontal position of the popup window, passed to wm geometry as +x
# int y defaults to 100, vertical  position of the popup window, passed to wm geometry as +y
# .END
#-------------------------------------------------------------------------------
proc ShowColors {{callback ""} {x 100} {y 100}} {
    global Gui Label

    # Recreate popup if user killed it
    if {[winfo exists $Gui(wLabels)] == 0} {
        LabelsBuildGUI
    }
    
    set Label(callback) $callback
    
    LabelsHideLabels

    ShowPopup $Gui(wLabels) $x $y
}
 
#-------------------------------------------------------------------------------
# .PROC LabelsDisplayColors
# Create the canvas colour grid showing sample squares of each node in the color tree.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsDisplayColors {} {
    global Color Label Gui Mrml

    # Determine size of color grid

    set tree Mrml(colorTree) 
    set numColors [$tree GetNumberOfColors]

    set p 2
    while {$numColors > [expr $p * $p]} {
        incr p
    }
    set n [expr $Label(dim) / $p]
    set Label(gridDim)     $p
    set Label(gridCellDim) $n

    # Start out all black
    set dim1 [expr $Label(dim) - 1]
    $Label(canvas) create rect 0 0 $dim1 $dim1 -fill black

    # Make color grid
    for {set y 0} {$y < $p} {incr y} {
        for {set x 0} {$x < $p} {incr x} {
            set i [expr $y*$p+$x]
            if {$i >= $numColors} {
                set color "0 0 0"
            } else {
                set node  [$tree GetNthColor $i]
                set color [$node GetDiffuseColor]
            }
            $Label(canvas) create rect \
                [expr $x*$n] [expr $y*$n] \
                [expr $x*$n+$n]  [expr $y*$n+$n]\
                -fill [MakeColorNormalized $color]
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC LabelsGetColorFromPosition
#
# x,y are positions in color canvas on [1, $Label(dim)].
# Returns color ID.
# .ARGS
# int x x position on the color canvas
# int y y position on the color canvas
# .END
#-------------------------------------------------------------------------------
proc LabelsGetColorFromPosition {x y} {
    global Label Mrml

    set xGrid [expr $x / $Label(gridCellDim)]
    set yGrid [expr $y / $Label(gridCellDim)]
    set i [expr $Label(gridDim) * $yGrid + $xGrid]
    set node [Mrml(colorTree) GetNthColor $i]
    if {$node == ""} {
        return ""
    }
    set id [$node GetID]
    return $id
}

#-------------------------------------------------------------------------------
# .PROC LabelsBrowseColor
#
# Show the name of the color the mouse is over
# .ARGS
# int x x position on the color canvas
# int y y position on the color canvas
# .END
#-------------------------------------------------------------------------------
proc LabelsBrowseColor {x y} {
    global Label Color

    set c [LabelsGetColorFromPosition $x $y]
    if {$c == ""} {
        set Label(nameBrowse) ""
    } else {
        set Label(nameBrowse) "[Color($c,node) GetName]=[Color($c,node) GetLabels]"
    }
}

#-------------------------------------------------------------------------------
# .PROC LabelsSelectColor
#
# Select the color the mouse is over
# .ARGS
# int x x position on the color canvas
# int y y position on the color canvas
# int c defaults to empty string, optional color id
# .END
#-------------------------------------------------------------------------------
proc LabelsSelectColor {x y {c ""}} {
    global Label Color

    if {$c == ""} {
        set c [LabelsGetColorFromPosition $x $y]
    }
    set Label(activeID) $c

    # Show the selection
    if {$c == ""} {
        set Label(nameBrowse) ""
        LabelsDisplayLabels        
        return
    }
    set Label(nameBrowse) [Color($c,node) GetName]
    set Label(diffuse)    [Color($c,node) GetDiffuseColor]
    LabelsDisplayLabels

    # If there's only one label, or labels or hidden, select it
    if {[llength [Color($c,node) GetLabels]] == 1 ||
        $Label(hideLabels) == 1} {
        LabelsSelectLabelClick 0
        return
    }
}

#-------------------------------------------------------------------------------
# .PROC LabelsLeaveGrid
# Reset Label(nameBrowse) when the mouse leaves the color grid.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsLeaveGrid {} {
    global Label
    
    set c $Label(activeID)
    if {$Label(activeID) != ""} {
        set Label(nameBrowse) [Color($c,node) GetName]
    } else {
        set Label(nameBrowse) ""
    }
}

#-------------------------------------------------------------------------------
# .PROC LabelsDisplayLabels
# Clear out the Label(fLabelList) and repopulate it from the list for the 
# active color node.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsDisplayLabels {} {
    global Label

    # Clear old
    $Label(fLabelList) delete 0 end

    # Append new
    set c $Label(activeID)
    if {$c == ""} {return}

    foreach label [Color($c,node) GetLabels] {
        $Label(fLabelList) insert end $label
    }
}

#-------------------------------------------------------------------------------
# .PROC LabelsSelectLabelClick
# Select the label, call the callback, and then close the popup.
# .ARGS
# int index defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc LabelsSelectLabelClick {{index ""}} {
    global Gui Label
    
    LabelsSelectLabel $index

    if {$Label(callback) != ""} {
        eval $Label(callback)
    }

    # close popup
    wm withdraw $Gui(wLabels)
}

#-------------------------------------------------------------------------------
# .PROC LabelsSelectLabel
# Set the active label, recolor gui elements when select a label.
# .ARGS
# int i label id, defaults to empty string to be reset from the currently selected label
# .END
#-------------------------------------------------------------------------------
proc LabelsSelectLabel {{i ""}} {
    global Label

    if {$::Module(verbose)} {
        puts "LabelsSelectLabel i = $i"
    }
    if {$i == ""} {
        set i [$Label(fLabelList) curselection]
    }
    if {$i == ""} {return}
    $Label(fLabelList) selection set $i $i
    
    set c $Label(activeID)
    if {$c == ""} {return}
    set labels [Color($c,node) GetLabels]
    set Label(label) [lindex $labels $i]

    if {$::Module(verbose)} {
        puts "LabelSelectLabel: set Label(label) to $Label(label)"
    }
    # Update GUI
    foreach name $Label(nameList) {
        set $name [Color($c,node) GetName]
    }
    set Label(diffuse) [Color($c,node) GetDiffuseColor]
    LabelsColorWidgets
}

#-------------------------------------------------------------------------------
# .PROC LabelsSetColor
# Update the gui when a label has been selected.
# .ARGS
# string colorName for testing against the color node names
# .END
#-------------------------------------------------------------------------------
proc LabelsSetColor {colorName} {
    global Label Color

    # Made for Models properties GUI

    set id ""
    foreach c $Color(idList) {
        if {[Color($c,node) GetName] == $colorName} {
            set id $c
        }
    }
    set c $id

    # The rest is stolen from LabelsFindLabel
    # DAVE clean this crap up, or just leave it. Ha!

    if {$c == ""} {
        set c [lindex $Color(idList) 1]
    }
    if {$c == ""} {
        # Update GUI
        foreach name $Label(nameList) {
            set $name ""
        }
        set Label(diffuse) "0 0 0"
        LabelsColorWidgets
        return
    }
    set i [lsearch [Color($c,node) GetLabels] $Label(label)]    
    set labels [Color($c,node) GetLabels]
    set Label(label) [lindex $labels $i]

    # Update GUI
    foreach name $Label(nameList) {
        set $name [Color($c,node) GetName]
    }
    set Label(diffuse) [Color($c,node) GetDiffuseColor]
    LabelsColorWidgets
}

#-------------------------------------------------------------------------------
# .PROC LabelsColorWidgets
# Loop through the Label(colorWidgetList) and recolor all of them.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsColorWidgets {} {
    global Label 
    if {$::Module(verbose)} {
        puts "LabelsColorWidgets"
    }
    foreach w $Label(colorWidgetList) {
        $w config -bg [MakeColorNormalized $Label(diffuse)] -state normal
    }
}

#-------------------------------------------------------------------------------
# .PROC LabelsFindLabel
#
# Find the color for the current label value, and select the color.
# .END
#-------------------------------------------------------------------------------
proc LabelsFindLabel { } {
    global Label Mrml

    
    set c [MainColorsGetColorFromLabel $Label(label)]

    if {$::Module(verbose)} {
        puts "LabelsFindLabel: Label(label) = $Label(label), c= $c"
    }
    if {$c == ""} {
        # Update GUI
        set Label(activeID) ""
        foreach name $Label(nameList) {
            set $name ""
        }
        set Label(diffuse) "0 0 0"
        LabelsColorWidgets
        return
    }
    set i [lsearch [Color($c,node) GetLabels] $Label(label)]

    if {$::Module(verbose)} { puts "LabelsFindLabel: i = $i, active id = $Label(activeID)" }

    if {$Label(activeID) != $c} {
        LabelsSelectColor 0 0 $c
        if {$i != -1} {
            LabelsSelectLabel $i
        }
    }
    if {$::Module(verbose)} { puts "LabelsFindLabel: done" }
}

#-------------------------------------------------------------------------------
# .PROC LabelsSetOutputLabel
#
# Update the label value in the interactive filters.
# .ARGS
# int p defaults to empty string, not used
# .END
#-------------------------------------------------------------------------------
proc LabelsSetOutputLabel {{p ""}} {

    LabelsFindLabel
}

#-------------------------------------------------------------------------------
# .PROC LabelsCreateColor
# Called to add a new color.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LabelsCreateColor {} {
    global Gui Volume Label Dag Color

    set newLabel $Label(labelNew)
    if {$newLabel >= -32768 && $newLabel <= 32767} {
    } else {
        tk_messageBox -icon error -title $Gui(title) -message \
            "Label '$newLabel' must be a number\nbetween -32768 and 32767."
        return 0
    }

    # Add color
    set c [MainColorsAddColor $Label(nameNew) $Label(diffuseNew)]
    if {$c == ""} {
        return
    }
    
    # Add label
    if {[MainColorsAddLabel $c $Label(labelNew)] == 0} {
        return
    }

    # Update MRML since we're adding a color
    MainUpdateMRML
    
    # Select it (since there's one label, close the popup)
    LabelsSelectColor 0 0 $c
}

