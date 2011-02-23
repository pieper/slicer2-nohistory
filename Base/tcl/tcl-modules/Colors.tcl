#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Colors.tcl,v $
#   Date:      $Date: 2006/03/06 19:24:22 $
#   Version:   $Revision: 1.36 $
# 
#===============================================================================
# FILE:        Colors.tcl
# PROCEDURES:  
#   ColorsInit
#   ColorsBuildGUI
#   ColorsSetFileName
#   ColorsLoadApply deleteFlag
#   ColorsApply
#   ColorsUpdateMRML
#   ColorsDisplayColors
#   ColorsSelectColor i
#   ColorsSetColor value
#   ColorsAddColor
#   ColorsDeleteColor
#   ColorsColorSample
#   ColorsDisplayLabels
#   ColorsSelectLabel i
#   ColorsAddLabel
#   ColorsDeleteLabel
#   ColorsClose
#   ColorsPickLUT parrentButton
#   ColorsSetLUT id
#   ColorsLUTSetNumberOfColors val
#   ColorsLUTSetParam hilo Param val
#   ColorsLUTSetAnno col
#   ColorsLUTSetRamp
#   ColorsVerifyModelColorIDs
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC ColorsInit
#
# Initialize global variables.
# .END
#-------------------------------------------------------------------------------
proc ColorsInit {} {
    global Color Gui Module

    # Define Tabs
    set m Colors
    set Module($m,row1List) "Help Colors Scale Load"
    set Module($m,row1Name) "Help {Edit Colors} {Edit Color Scale} {Load Colors}"
    set Module($m,row1,tab) Colors

    # Module Summary Info
    set Module($m,overview) "Add new colors, view color lookup table."
    set Module($m,author) "Core"
    set Module($m,category) "Settings"

    # Define Procedures
    set Module($m,procGUI)  ColorsBuildGUI
    set Module($m,procMRML) ColorsUpdateMRML
    set Module($m,procMainFileCloseUpdateEntered) ColorsClose

    # Define Dependencies
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.36 $} {$Date: 2006/03/06 19:24:22 $}]

    # default color xml file
    set Color(defaultColorFileName) [ExpandPath Colors.xml]
    # init the color file to load from
    set Color(fileName) $Color(defaultColorFileName)

    # the LUT to affect by the colour scale editing
    set Color(LUT,currentID) -1
    # gui values for changing LUTs
    set Color(LUT,NumberOfColors) 0
    foreach rangeName {Hue Saturation Value Alpha} {
        set Color(LUT,lower${rangeName}) 0.0
    }
    foreach rangeName {Hue Saturation Value Alpha} {
        set Color(LUT,upper${rangeName}) 1.0
    }
    foreach col {r g b} {
        set Color(LUT,annoColor,$col) "0.0"
    }
    if {$::Module(verbose)} {
        puts "ColorsInit: Set Color(LUT,*) values"
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc ColorsBuildGUI {} {
    global Gui Module Color Colors

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Colors
    #   Top
    #     Colors
    #     Labels
    #   Bot
    #     Attr
    #     Apply
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
<UL>
<LI><B>Edit Colors:</B><BR>
Click on the name of a color in the <B>Color Name</B> listbox to view the <B>Label</B> values associated with this color.  Use the <B>Add</B> and <B>Delete</B> buttons to create/remove new colors or labels for colors. Make sure to add a new color name first, and then add labels for the new color, and edit the display color. <BR>
The color changes will take effect through all of Slicer when you hit the <B>Update</B> button, otherwise just the color node here will be changed.
<P>
The colors are saved in the MRML file when you select the <B>Save</B> option from the <B>File</B> menu if they differ from the default colors. <BR>
If you select the <B>Close</B> option from the <B>File</B> menu, all color changes will be backed out and the default slicer colors will be reloaded.
<BR><LI><B>Edit Color Scale:</B><BR>
Select a color look up table from the drop down menu and do real time adjustments. Not saved.
<BR><LI><B>Load Colors:</B><BR>
The Load Colors tab will allow you to open up mrml files with color nodes and use the new ones as your default colors.
</UL>"

    regsub -all "\n" $help { } help
    MainHelpApplyTags Colors $help
    MainHelpBuildGUI Colors

    #-------------------------------------------
    # Colors frame
    #-------------------------------------------
    set fColors $Module(Colors,fColors)
    set f $fColors

    frame $f.fTop -bg $Gui(activeWorkspace)
    frame $f.fBot -bg $Gui(activeWorkspace)
    pack $f.fTop $f.fBot -side top -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Colors->Top
    #-------------------------------------------
    set f $fColors.fTop

    frame $f.fColors -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fLabels -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fColors $f.fLabels -side left -padx 2 -pady 1 -fill x

    #-------------------------------------------
    # Colors->Top->Colors frame
    #-------------------------------------------
    set f $fColors.fTop.fColors

    eval {label $f.lTitle -text "Color Name"} $Gui(WTA)

    set Color(fColorList) [ScrolledListbox $f.list 1 1 -height 5 -width 15]
    bind $Color(fColorList) <ButtonRelease-1> {ColorsSelectColor}

    eval {entry $f.eName -textvariable Color(name) -width 18} $Gui(WEA)
    bind $f.eName <Return> "ColorsAddColor"
    
    frame $f.fBtns -bg $Gui(activeWorkspace)
    eval {button $f.fBtns.bAdd -text "Add" -width 4 \
        -command "ColorsAddColor"} $Gui(WBA)
    eval {button $f.fBtns.bDelete -text "Delete" -width 7 \
        -command "ColorsDeleteColor"} $Gui(WBA)
    pack $f.fBtns.bAdd $f.fBtns.bDelete -side left -padx $Gui(pad)

    pack $f.lTitle -side top -pady 2
    pack $f.list $f.eName $f.fBtns -side top -pady $Gui(pad)

    #-------------------------------------------
    # Colors->Top->Labels frame
    #-------------------------------------------
    set f $fColors.fTop.fLabels

    eval {label $f.lTitle -text "Label"} $Gui(WTA)

    set Color(fLabelList) [ScrolledListbox $f.list 1 1 -height 5 -width 6]
        bind $Color(fLabelList) <ButtonRelease-1> "ColorsSelectLabel"

    eval {entry $f.eName -textvariable Color(label) -width 9} $Gui(WEA)
    bind $f.eName <Return> "ColorsAddLabel"

    frame $f.fBtns -bg $Gui(activeWorkspace)
    eval {button $f.fBtns.bAdd -text "Add" -width 4 \
        -command "ColorsAddLabel"} $Gui(WBA)
    eval {button $f.fBtns.bDelete -text "Del" -width 4 \
        -command "ColorsDeleteLabel"} $Gui(WBA)
    pack $f.fBtns.bAdd $f.fBtns.bDelete -side left -padx $Gui(pad)

    pack $f.lTitle -side top -pady 2
    pack $f.list $f.eName $f.fBtns -side top -pady $Gui(pad) 

    #-------------------------------------------
    # Colors->Bot frame
    #-------------------------------------------
    set f $fColors.fBot

    frame $f.fAttr  -bg $Gui(activeWorkspace)
    frame $f.fApply -bg $Gui(activeWorkspace)
    pack $f.fAttr $f.fApply -side left -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Colors->Bot->Attr frame
    #-------------------------------------------
    set f $fColors.fBot.fAttr

    foreach slider "Red Green Blue Ambient Diffuse Specular Power" {

        eval {label $f.l${slider} -text "${slider}"} $Gui(WLA)

        eval {entry $f.e${slider} -textvariable Color([Uncap $slider]) \
            -width 3} $Gui(WEA)
            bind $f.e${slider} <Return>   "ColorsSetColor"
            bind $f.e${slider} <FocusOut> "ColorsSetColor"

        eval {scale $f.s${slider} -from 0.0 -to 1.0 -length 40 \
            -variable Color([Uncap $slider]) -command "ColorsSetColor" \
            -resolution 0.1} $Gui(WSA) {-sliderlength 15}
        set Color(s$slider) $f.s$slider

        grid $f.l${slider} $f.e${slider} $f.s${slider} \
            -pady 1 -padx 1 -sticky e
    }
    $f.sPower config -from 0 -to 100 -resolution 1 


    #-------------------------------------------
    # Colors->Bot->Apply frame
    #-------------------------------------------
    set f $fColors.fBot.fApply

    eval {button $f.bApply -text "Update" -width 7 \
        -command "ColorsApply; RenderAll"} $Gui(WBA)
    pack $f.bApply -side top -pady $Gui(pad) 



    #-------------------------------------------
    # Scale frame
    #-------------------------------------------
    set fScale $Module(Colors,fScale)
    set f $fScale

    frame $f.fPick -bg $Gui(backdrop)
    pack $f.fPick -side top -fill x -pady $Gui(pad) -padx $Gui(pad)

    foreach subf {NumColours Hue Saturation Value Alpha Ramp Anno} {
        frame $f.f${subf} -bg $Gui(activeWorkspace) -relief groove -bd 2
        pack $f.f${subf} -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Scale->Pick frame
    #-------------------------------------------
    set f $fScale.fPick

    DevAddButton $f.bPickLUT "Pick LUT" "ColorsPickLUT $f.bPickLUT" 12
    pack $f.bPickLUT -side top

    #-------------------------------------------
    # Scale->NumColours frame
    #-------------------------------------------
    set f $fScale.fNumColours

    eval {label $f.lNumberOfColors -text "Number of Colors: "} $Gui(WLA)
    eval {entry $f.eNumberOfColors -textvariable Color(LUT,NumberOfColors) -width 5} $Gui(WEA)
    bind $f.eNumberOfColors <Return> "ColorsLUTSetNumberOfColors [$f.eNumberOfColors get]"
    pack $f.lNumberOfColors $f.eNumberOfColors -padx $Gui(pad) -pady $Gui(pad) -expand 1 -fill x

    #-------------------------------------------
    # Scale->Hue, Saturation, Value, Alpha frames
    #-------------------------------------------
    foreach frameName {Hue Saturation Value Alpha} {
        set f $fScale.f${frameName}
        eval {label $f.l${frameName} -text "$frameName Range: "} $Gui(WLA)
        pack $f.l${frameName} -side top

        frame $f.fSliders -bg $Gui(activeWorkspace)
        pack $f.fSliders -side top  -fill x -expand 1
        set f $f.fSliders
        foreach slider "lower upper" text "Lo Hi" {
            DevAddLabel $f.l${slider} "$text:"
            eval {entry $f.e${slider} -width 6 \
                      -textvariable Color(LUT,${slider}${frameName})} $Gui(WEA)
            bind $f.e${slider} <Return> "ColorsLUTSetParam ${slider} ${frameName}"
            # bind $f.e${slider} <FocusOut> "ColorsLUTSetParam ${slider}${frameName}"
            eval {scale $f.s${slider} -from 0.0 -to 1.0 -length 50 \
                      -variable Color(LUT,${slider}${frameName}) -resolution 0.01 \
                      -command "ColorsLUTSetParam ${slider} ${frameName}"} \
                $Gui(WSA) {-sliderlength 14}
            grid  $f.l${slider} $f.e${slider} $f.s${slider} -padx 2 -pady $Gui(pad) \
                -sticky news
        }
    }

    #-------------------------------------------
    # Scale->Anno frame
    #-------------------------------------------
    set f $fScale.fAnno
    # r g b values
    DevAddLabel $f.lAnno "Annotation RGB"
    foreach col {r g b} {
        eval {label $f.l$col -text $col } $Gui(WLA)
        eval {entry $f.e$col -width 3 -textvariable Color(LUT,annoColor,$col)} $Gui(WEA) 
        bind $f.e$col <Return> "ColorsLUTSetAnno $col"
        
    }
    pack $f.lr $f.er $f.lg $f.eg $f.lb $f.eb -side left -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Scale->Ramp frame
    #-------------------------------------------
    set f $fScale.fRamp
    DevAddLabel $f.lRamp "Ramp: "
    eval {menubutton $f.mbRamp -text "default" -relief raised -bd 2 -width 20 \
            -menu $f.mbRamp.m} $Gui(WMBA)
    eval {menu $f.mbRamp.m} $Gui(WMA)
    foreach r {Linear SCurve SQRT} {
        $f.mbRamp.m insert end command -label $r -command "ColorsLUTSetRamp $r"
    }
    set Color(mbRamp) $f.mbRamp
    pack $f.lRamp $f.mbRamp -side left

    #-------------------------------------------
    # Load frame
    #-------------------------------------------
    set fLoad $Module(Colors,fLoad)
    set f $fLoad

    frame $f.fTop -bg $Gui(activeWorkspace)
    frame $f.fBot -bg $Gui(activeWorkspace)
    pack $f.fTop $f.fBot -side top -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Load->Top
    #-------------------------------------------
    set f $fLoad.fTop
    DevAddFileBrowse $f Color fileName "MRML color file:" "ColorsSetFileName" "xml" "" "Open" "Open a Color MRML file"
    eval {button $f.bLoad -text "Load" -width 7 \
              -command "ColorsLoadApply"} $Gui(WBA)
    TooltipAdd $f.bLoad "Deletes old colors - models using them will have unexpected colors"
    eval {button $f.bAppend -text "Append Colors" -width 14 \
              -command "ColorsLoadApply 0"} $Gui(WBA)
    TooltipAdd $f.bAppend "Appends to color list"
    pack $f.bLoad $f.bAppend -side top -pady $Gui(pad) 

    #-------------------------------------------
    # Load->Bot
    #-------------------------------------------

    set f $fLoad.fBot
    eval {label $f.lWarning -text "Appending colors will show the first color name\nfor that label on mouse roll over of label maps."} $Gui(WLA)
    pack $f.lWarning -side top -pady $Gui(pad)
                                                                                            
}

#-------------------------------------------------------------------------------
# .PROC ColorsSetFileName
# The Color(fileName) is set via the interface, and printed out here.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ColorsSetFileName {}  {
    global Color
    puts "Color filename = $Color(fileName)"
}

#-------------------------------------------------------------------------------
# .PROC ColorsLoadApply
# Load an xml file, Color(fileName), that contains colour node definitions.
# Deletes old colour nodes first.
# .ARGS
# int deleteFlag if 1, delete the old colours, else, don't, add to them. Defaults to 1
# .END
#-------------------------------------------------------------------------------
proc ColorsLoadApply { {deleteFlag 1}} {
    global Color

    if {$::Module(verbose)} {
        puts "ColorsLoadApply: load of a new xml file with colour nodes\n\t$Color(fileName)"
    }

    if {$deleteFlag == 1} {
        MainMrmlDeleteColors
    }
    MainMrmlAddColorsFromFile $Color(fileName)

    if {$deleteFlag == 1} {
        # check that all models have valid colour ids
        ColorsVerifyModelColorIDs
    }

    # update the gui's color list
    ColorsDisplayColors

    MainColorsUpdateMRML

    # this call forces a rebuilding of the canvas that displays the colours for label selection
    LabelsUpdateMRML

    RenderAll
}
#-------------------------------------------------------------------------------
# .PROC ColorsApply
#
# Update all uses of colors in the Slicer to show the current colors, 
# just calls MainUpdateMRML
# .END
#-------------------------------------------------------------------------------
proc ColorsApply {} {
    global Color

    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC ColorsUpdateMRML
#
# This routine is called when the MRML tree changes
# .END
#-------------------------------------------------------------------------------
proc ColorsUpdateMRML {} {
    global Color

    if {$Color(idList) == ""} {
        return
    }
    
    ColorsDisplayColors
    ColorsSelectColor $Color(activeID)
    ColorsSelectLabel 0
}

#-------------------------------------------------------------------------------
# .PROC ColorsDisplayColors
# Inserts colours from the Mrml color tree into the tk element Color(fColorList)
# .END
#-------------------------------------------------------------------------------
proc ColorsDisplayColors {} {
    global Color Mrml

    # Clear old
    $Color(fColorList) delete 0 end

    # Append new
    set tree Mrml(colorTree) 
    set node [$tree InitColorTraversal]
    while {$node != ""} {
        $Color(fColorList) insert end [$node GetName]
        set node [$tree GetNextColor]
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsSelectColor
# Select the colour clicked upon, and set the active color node, and redraw 
# gui elements.
# .ARGS
# int i optional color index in Color(idList), defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc ColorsSelectColor {{i ""}} {
    global Color Mrml

    if {$i == ""} {
        set i [$Color(fColorList) curselection]
    }
    if {$i == ""} {return}
    $Color(fColorList) selection set $i $i
    set c [lindex $Color(idList) $i]

    MainColorsSetActive $c

    ColorsColorSample
    ColorsDisplayLabels
}

#-------------------------------------------------------------------------------
# .PROC ColorsSetColor
# Used by the color sliders, sets the  color of the active color node from 
# the Color red, green, blue array vars, and draws the sample sliders.
# .ARGS
# list value optional, not used, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc ColorsSetColor {{value ""}} {
    global Color

    # Set the new color from the GUI into the node
    set c $Color(activeID)
    if {$c == ""} {return}

    Color($c,node) SetDiffuseColor $Color(red) $Color(green) $Color(blue)
    foreach param "Ambient Diffuse Specular Power" {
        Color($c,node) Set$param $Color([Uncap $param])
    }

    # Draw Sample
    ColorsColorSample
}

#-------------------------------------------------------------------------------
# .PROC ColorsAddColor
# Calls MainColorsAddColor with the values set from the gui.
# .END
#-------------------------------------------------------------------------------
proc ColorsAddColor {} {
    global Color Gui
    
    set c [MainColorsAddColor $Color(name) $Color(diffuseColor) \
        $Color(ambient) $Color(diffuse) $Color(specular) $Color(power)]
    
    if {$c != ""} {
        # make sure new color is selected on GUI
        MainColorsSetActive $c

        MainUpdateMRML
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsDeleteColor
# Delete the active color node, and re-render.
# .END
#-------------------------------------------------------------------------------
proc ColorsDeleteColor {} {
    global Color

    MainMrmlDeleteNode Color $Color(activeID)
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC ColorsColorSample
# Loop over the call to redraw the color sliders.
# .END
#-------------------------------------------------------------------------------
proc ColorsColorSample {} {
    global Color
    
    set color "$Color(red) $Color(green) $Color(blue)"
    foreach slider "Red Green Blue" {
        ColorSlider $Color(s$slider) $color
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsDisplayLabels
# Clear out the Color fLabelList and create it from scratch from the labels in 
# the active color node.
# .END
#-------------------------------------------------------------------------------
proc ColorsDisplayLabels {} {
    global Color

    # Clear old
    $Color(fLabelList) delete 0 end

    # Append new
    set c $Color(activeID)
    if {$c == ""} {return}

    set Color(label) ""
    foreach label [Color($c,node) GetLabels] {
        $Color(fLabelList) insert end $label
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsSelectLabel
# Update the gui after selection of a label.
# .ARGS
# int i defaults to empty string, otherwise set to current selection.
# .END
#-------------------------------------------------------------------------------
proc ColorsSelectLabel {{i ""}} {
    global Color

    if {$i == ""} {
        set i [$Color(fLabelList) curselection]
    }
    if {$i == ""} {return}
    $Color(fLabelList) selection set $i $i
    
    set c $Color(activeID)
    if {$c == ""} {
        set Color(label) ""
    } else {
        set labels [Color($c,node) GetLabels]
        set Color(label) [lindex $labels $i]
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsAddLabel
# Add a new label and redraw the gui.
# Returns 1 on success, else 0
# .END
#-------------------------------------------------------------------------------
proc ColorsAddLabel {} {
    global Color Color Gui

    # Convert to integer
    set index [MainColorsAddLabel $Color(activeID) $Color(label)]

    ColorsDisplayLabels
    ColorsSelectLabel $index
    return 1
}

#-------------------------------------------------------------------------------
# .PROC ColorsDeleteLabel
# Delete the label  and redraw the gui.
# .END
#-------------------------------------------------------------------------------
proc ColorsDeleteLabel {} {
    global Color Color

    MainColorsDeleteLabel $Color(activeID) $Color(label)

    ColorsDisplayLabels
    ColorsSelectLabel 0
}

#-------------------------------------------------------------------------------
# .PROC ColorsClose
# Called when the File Close option is selected, to clean up the colors module.
# Goes back to the default slicer colors.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ColorsClose {} {
    global Color

    if {$::Module(verbose)} {
        puts "ColorsClose, reloading default colors from $Color(defaultColorFileName) "
    }
    set Color(fileName) $Color(defaultColorFileName)
    ColorsLoadApply
}

#-------------------------------------------------------------------------------
# .PROC ColorsPickLUT
# Pick a look up table to work with. Sets Color(LUT,currentID). Will leave out luts
# from the pick list that are missing functions to set NumberOfColors, HueRange, SaturationRange, 
# ValueRange, AlphaRange.
# .ARGS
# button parrentButton button to hang the menu off of
# .END
#-------------------------------------------------------------------------------
proc ColorsPickLUT {parentButton} {
    global Color Gui

    catch "destroy .mcolorspicklut"
    eval menu .mcolorspicklut $Gui(WMA)

    set currid $::Color(LUT,currentID)

    foreach l $::Lut(idList) {
        if {$l >= 0} {
            # only use LUTs that support the Range values that the interface allows access to
            if {[catch "Lut($l,lut) GetHueRange" errMsg] == 0 &&
                [catch "Lut($l,lut) GetSaturationRange" errMsg] == 0 &&
                [catch "Lut($l,lut) GetValueRange" errMsg] == 0} {
                if {$l == $currid} {
                    set labeltext "* $l $::Lut($l,name) *"
                } else {
                    set labeltext "$l $::Lut($l,name)"
                }
                .mcolorspicklut insert end command -label $labeltext -command "ColorsSetLUT $l"
                if {$::Module(verbose)} {
                    puts "ColorsPickLUT: added command to set Color(LUT,currentID) to $l"
                }
            } else {
                if {$::Module(verbose)} {
                    puts "ColorsPickLUT: skipped lut $l, it doesn't support range commands"
                }
            }
        }
    }
    set x [expr [winfo rootx $parentButton] + 10]
    set y [expr [winfo rooty $parentButton] + 10]
    
    .mcolorspicklut post $x $y
}

#-------------------------------------------------------------------------------
# .PROC ColorsSetLUT
# Set the current LUT id for the Colors module, and set the global vars
# .ARGS 
# int id the ID of the look up table to use to set the Colors Module vars
# .END
#-------------------------------------------------------------------------------
proc ColorsSetLUT { id } {
    global Color Lut
    
    if {$id >= 0 && [lsearch $Lut(idList) $id] != -1} {
        set ::Color(LUT,currentID) $id
        # modify the button text
        $::Module(Colors,fScale).fPick.bPickLUT configure -text $Lut($Color(LUT,currentID),name)

        # now get the LUT values
        set Color(LUT,NumberOfColors) [Lut($id,lut) GetNumberOfColors]
        set Color(LUT,lowerHue) [lindex [Lut($id,lut) GetHueRange] 0]
        set Color(LUT,upperHue) [lindex [Lut($id,lut) GetHueRange] 1]
        set Color(LUT,lowerSaturation) [lindex [Lut($id,lut) GetSaturationRange] 0]
        set Color(LUT,upperSaturation)  [lindex [Lut($id,lut) GetSaturationRange] 1]
        set Color(LUT,lowerValue)  [lindex [Lut($id,lut) GetValueRange] 0]
        set Color(LUT,upperRange) [lindex [Lut($id,lut) GetValueRange] 1]
        set Color(LUT,lowerAlpha) [lindex [Lut($id,lut) GetAlphaRange] 0]
        set Color(LUT,upperAlpha) [lindex [Lut($id,lut) GetAlphaRange] 1]
        if {[info exist Lut($id,annoColor)]} {
            set Color(LUT,annoColor,r) [lindex $Lut($id,annoColor) 0]
            set Color(LUT,annoColor,g) [lindex $Lut($id,annoColor) 1]
            set Color(LUT,annoColor,b) [lindex $Lut($id,annoColor) 2]
        }
    } else {
        puts "ColorsSetLUT: lut id $id is out of range or invalid: $Lut(idList)"
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsLUTSetNumberOfColors
# Set the number of colours in the current Color module LUT
# .ARGS
# int val number greater than 0
# .END
#-------------------------------------------------------------------------------
proc ColorsLUTSetNumberOfColors { val } {
    global Color Lut

    set val $Color(LUT,NumberOfColors)
    if {$::Module(verbose)} { 
        puts "ColorsLUTSet: varName = NumberOfColors, val = $val, current Color(LUT,NumberOfColors) = $Color(LUT,NumberOfColors), lut id = $Color(LUT,currentID)"
    }

    set id $Color(LUT,currentID)
    if {[lsearch $Lut(idList) $id] != -1} {
        if {$::Module(verbose)} { 
            puts "ColorsLUTSetNumberOfColors: Setting value for colour table $Lut($id,name): set Lut($id,NumberOfColors) to $val, and set Lut($id,lut) SetNumberOfColors to $val"
        }
        # check if val is valid
        if {$val < 0} {
            puts "ColorsLUTSetNumberOfColors: Value $val out of range, must be greater than 0"
            return
        }
        set Lut($id,$Color(LUT,NumberOfColors)) $val
        eval Lut($id,lut) SetNumberOfColors $val
        
        Lut($id,lut) Build
        Render3D
    } else {
        if {$::Module(verbose)} {
            puts "ColorsLUTSetNumberOfColors: Warning: current id not a valid look up table ($id == -1 or not in \"$Lut(idList)\")"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsLUTSetParam
# Set the colour look up table parameter for the current Color module LUT. 
# The variable Color(LUT,$hilo$Param) has been set already.
# .ARGS
# string hilo one of lower or upper, which end of the range to set 
# string Param the name of the parameter to set, one of Hue Saturation Value Alpha
# float val value passed in from the slider, not used
# .END
#-------------------------------------------------------------------------------
proc ColorsLUTSetParam { hilo Param {val ""} } {
    global Color Lut

    set value $Color(LUT,${hilo}${Param})
    set id $Color(LUT,currentID)
    if {$::Module(verbose)} { 
        puts "ColorsLUTSetParam: hilo = $hilo, Param = $Param, value = $value, lut id = $id"
    }

   
    if {$id != -1 && [lsearch $Lut(idList) $id] != -1} {
        if {$::Module(verbose)} { 
            puts "ColorsLUTSetParam: Setting value for colour table $Lut($id,name)"
        }
        # check if val is valid
        if {$::Module(verbose)} {
            puts "ColorsLUTSet: value = $value"
        }
        if {($value< 0.0 || $value > 1.0)} {
            puts "ColorsLUTSet: Value $value out of range 0.0 to 1.0"
            return
        }
        if {$hilo == "upper"} {
            set rangeInd 1
        } else {
            set rangeInd 0
        }
        if {$::Module(verbose)} {
            puts "ColorsLUTSetParam: $hilo -> $rangeInd, setting Lut($id,[Uncap ${Param}Range])"
        }
        if {[info exist Lut($id,[Uncap ${Param}]Range)]} {
            lset Lut($id,[Uncap ${Param}]Range) $rangeInd $value
            if {$::Module(verbose)} {
                puts "\tto $Lut($id,[Uncap ${Param}]Range)"
                puts "Now calling Set${Param} for Lut($id,lut) with that value, and rebuilding the lut, and rendering"
            }
            eval Lut($id,lut) Set${Param}Range $Lut($id,[Uncap ${Param}]Range)

        
            Lut($id,lut) Build
            Render3D
        } else {
            puts "No [Uncap ${Param}Range] for lut id $id"
        }
    } else {
        if {$::Module(verbose)} {
            puts "Warning: current id not a valid look up table ($id == -1 or not in \"$Lut(idList)\""
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsLUTSetAnno
# Set the annotation colour in the current Color module LUT
# .ARGS
# char col r, g, or b to set the red, green, or blue
# .END
#-------------------------------------------------------------------------------
proc ColorsLUTSetAnno { col } {
    global Color Lut

    set val $Color(LUT,annoColor,$col)

    if {$::Module(verbose)} {
        puts "ColorsLUTSetAnno: $col $val"
    }
    set ind -1
    if {$col == "r"} { set ind 0 }
    if {$col == "g"} { set ind 1 }
    if {$col == "b"} { set ind 2 }

    if {$ind == -1} {
        DevErrorWindow "ColorsLUTSetAnno: Invalid colour $col, must be r, g, or b"
        return
    }

    if {$val < 0.0 || $val > 1.0} {
        DevErrorWindow "ColorsLUTSetAnno: Invalid colour value $val, just be 0.0-1.0.\nResetting to limit."
        if {$val < 0.0} {
            set Color(LUT,annoColor,$col) 0.0
        } else {
            set Color(LUT,annoColor,$col) 1.0
        }
        return
    }

    set id $Color(LUT,currentID)

    if {[lsearch $Lut(idList) $id] != -1} {
        if {$::Module(verbose)} { 
            puts "ColorsLUTSetAnno: Setting value for colour table $Lut($id,name)"
        }
        set Color(LUT,annoColor,$col) $val
        set Lut($id,annoColor) {$Color(LUT,annoColor,r) $Color(LUT,annoColor,g) $Color(LUT,annoColor,b)}
        # don't do anything else right now, it's for the histogram
    } else {
        puts "Warning: current id not a valid look up table ($id not in \"$Lut(idList)\""
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsLUTSetRamp
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ColorsLUTSetRamp { ramp } {
    global Color Lut

    set id $Color(LUT,currentID)

    if {[lsearch $Lut(idList) $id] != -1} {
        if {$::Module(verbose)} { 
            puts "ColorsLUTSetRamp: Setting ramp value for colour table $Lut($id,name) to $ramp"
        }
        $Color(mbRamp) configure -text $ramp
        eval Lut($id,lut) SetRampTo${ramp}
        Lut($id,lut) Build
        Render3D
    } else {
        puts "ColorsLUTSetRamp: colour table $id not in Lut(idList)"
    }
}

#-------------------------------------------------------------------------------
# .PROC ColorsVerifyModelColorIDs
# Called after deleting the colours, to make sure that any models that were
# assigned colour ids before they were deleted, now have a valid default colour id
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ColorsVerifyModelColorIDs {} {
    global Color Model

    set numChanges 0
    set changeList ""

    # find a default id
    set defaultNodeID 0
    while {[info command Color($defaultNodeID,node)] == "" ||
           [Color($defaultNodeID,node) GetName] == "Black"} { 
        incr defaultNodeID 
        if {$defaultNodeID > 1000} {
            puts "ColorsVerifyModelColorIDs: can't find a colour node!\nLoad some Colors!"
            return
        }
    }
    if {$::Module(verbose)} {
        puts "ColorsVerifyModelColorIDs: found a default node id $defaultNodeID, named [Color($defaultNodeID,node) GetName]"
    }

    # now check to see if I need to use it
    foreach m $Model(idList) {
        # get the colour id
        if {$Model($m,colorID) == ""} {
            set Model($m,colorID) $defaultNodeID
            incr numChanges
            lappend changeList [Model($m,node) GetName]
            if {$::Module(verbose)} {
                puts "ColorsVerifyModelColorIDs: reset model $m"
            }
        }
    }
    if {$numChanges > 0} {
        if {$::Module(verbose)} {
            puts "Loading colours left $numChanges models without a default colour id, reset their colours:\n$changeList"
        }
    }
}

