#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainColors.tcl,v $
#   Date:      $Date: 2006/05/26 18:54:46 $
#   Version:   $Revision: 1.23 $
# 
#===============================================================================
# FILE:        MainColors.tcl
# PROCEDURES:  
#   MainColorsInit
#   MainColorsUpdateMRML
#   MainColorsSetActive c
#   MainColorsAddLabel c newLabel
#   MainColorsAddColor name diffuseColor ambient diffuse specular power
#   MainColorsDeleteLabel c delLabel
#   MainColorsGetColorFromLabel label
#   MainColorsGetColorIDFromName name
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainColorsInit
# Set up the global variables for this module
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainColorsInit {} {
    global Color Gui

        # Set version info
        lappend Module(versions) [ParseCVSInfo MainColors \
        {$Revision: 1.23 $} {$Date: 2006/05/26 18:54:46 $}]

    set Color(activeID) ""
    set Color(name) ""
    set Color(label) ""
    set Color(ambient) 0
    set Color(diffuse) 1
    set Color(specular) 0
    set Color(power) 1
    set Color(labels) ""
    set Color(diffuseColor) "1 1 1"
}

#-------------------------------------------------------------------------------
# .PROC MainColorsUpdateMRML
# Called to update the mrml elements created in the Colors module.
#
# .END
#-------------------------------------------------------------------------------
proc MainColorsUpdateMRML {} {
    global Lut Color Mrml

    # Build any new colors
    #--------------------------------------------------------
    # (nothing to be done)

    # Delete any old colors
    #--------------------------------------------------------
    # (nothing to be done)

    # Did we delete the active color?
    if {[lsearch $Color(idList) $Color(activeID)] == -1} {
        MainColorsSetActive [lindex $Color(idList) 1]
    }

    # Refresh GUI 
    #--------------------------------------------------------
    set lut  Lut($Lut(idLabel),lut)
    set iLut Lut($Lut(idLabel),indirectLUT)

    # Set default color to white, and thresholded color to clear black.
    set num [llength $Color(idList)]
    $lut SetNumberOfTableValues [expr $num + 2]
    $lut SetTableValue 0 0.0 0.0 0.0 0.0
    $lut SetTableValue 1 1.0 1.0 1.0 1.0

    # Set colors for each label value
    $iLut InitDirect
    set tree Mrml(colorTree) 
    set node [$tree InitColorTraversal]
    set n 0
    while {$node != ""} {
        set diffuseColor [$node GetDiffuseColor]
        eval $lut SetTableValue [expr $n+2] $diffuseColor 1.0

        set values [$node GetLabels]
        foreach v $values {
            $iLut MapDirect $v [expr $n+2]
        }
        set node [$tree GetNextColor]
        incr n
    }
    $iLut Build
}
 
#-------------------------------------------------------------------------------
# .PROC MainColorsSetActive
# Set Color(activeID) and the color's name.
# .ARGS 
# int c id of the color node
# .END
#-------------------------------------------------------------------------------
proc MainColorsSetActive {c} {
    global Color

    set Color(activeID) $c

    if {$c == ""} {return}

    # Update GUI
    set Color(name) [Color($c,node) GetName]
    scan [Color($c,node) GetDiffuseColor] "%g %g %g" \
        Color(red) Color(green) Color(blue)
    foreach param "Ambient Diffuse Specular Power" {
        set Color([Uncap $param]) [Color($c,node) Get$param]
    }
    
}

#-------------------------------------------------------------------------------
# .PROC MainColorsAddLabel
#
# Creates a new label "newLabel" to the color with ID c.
# Returns 1 on success, else 0
# .ARGS
# int c id of the color node
# int newLabel value of the new label
# .END
#-------------------------------------------------------------------------------
proc MainColorsAddLabel {c newLabel} {
    global Color Gui Mrml

    if {$c == ""} {return} 

    # Convert to integer
    if {$newLabel >= -32768 && $newLabel <= 32767} {
    } else {
        tk_messageBox -icon error -title $Gui(title) \
            -message "Label '$newLabel' must be a short integer."
        return 0
    }

    # Don't allow duplicate labels
    set labels [Color($c,node) GetLabels]
    if {[lsearch $labels $newLabel] != "-1"} {
        tk_messageBox -icon error -title $Gui(title) \
            -message "Label '$newLabel' already exists."
        return 0
    }

    # Append the new label and sort the list of labels
    lappend labels $newLabel
    set labels [lsort -increasing $labels]
    set index  [lsearch $labels $newLabel]

    # Update the node
    Color($c,node) SetLabels $labels

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainColorsAddColor
#
# Creates a new color named "name".<br>
# Returns the new color's ID on success, else empty string.
# .ARGS
# str name name of the new color
# array diffuseColor rgb value to use
# array ambient optional, if not empty string, use set the node's ambient value
# array diffuse optional, if not empty string, use set the node's diffuse
# array specular optional, if not empty string, use set the node's specular value
# array power optional, if not empty string, use set the node's  power value
# .END
#-------------------------------------------------------------------------------
proc MainColorsAddColor {name diffuseColor \
    {ambient ""} {diffuse ""} {specular ""} {power ""}} {
    global Color Mrml Gui

    # Don't allow duplicate colors
    set colors ""
    set tree Mrml(colorTree) 
    set node [$tree InitColorTraversal]
    while {$node != ""} {
        set colors "$colors [$node GetName]"
        set node [$tree GetNextColor]
    }
    if {[lsearch $colors $name] != "-1"} {
        tk_messageBox -icon error -title $Gui(title) \
            -message "Color '$name' already exists."
        return ""
    }

    # Create new node
    set c $Color(nextID)
    incr Color(nextID)
    lappend Color(idList) $c
    vtkMrmlColorNode Color($c,node)
    set n Color($c,node)
    $n SetID           $c
    $n SetDescription  ""
    $n SetName         $name
    eval $n SetDiffuseColor $diffuseColor
    if {$ambient != ""} {
        $n SetAmbient      $ambient
    }
    if {$diffuse != ""} {
        $n SetDiffuse      $diffuse
    }
    if {$specular != ""} {
        $n SetSpecular     $specular
    }
    if {$power != ""} {
        $n SetPower        $power
    }

    Mrml(colorTree) AddItem $n

    return $c
}

#-------------------------------------------------------------------------------
# .PROC MainColorsDeleteLabel
#
# Deletes "delLabel" from Color node with id "c"
# .ARGS
# int c id of the color node
# int delLabel the color label to delete 
# .END
#-------------------------------------------------------------------------------
proc MainColorsDeleteLabel {c delLabel} {
    global Color

    if {$c == ""} {return}
    
    set labels [Color($c,node) GetLabels]

    set i  [lsearch $labels $delLabel]
    set labels [lreplace $labels $i $i]
    Color($c,node) SetLabels $labels
}

#-------------------------------------------------------------------------------
# .PROC MainColorsGetColorFromLabel
# Returns the color ID of a label value, or "" if unsuccessful.
# .ARGS
# int label the label being queried
# .END
#-------------------------------------------------------------------------------
proc MainColorsGetColorFromLabel {label} {
    global Color Mrml

    set tree Mrml(colorTree) 
    set node [$tree InitColorTraversal]
    while {$node != ""} {
        set labels [$node GetLabels]
        foreach l $labels {
            if {$l == $label} {
                return [$node GetID]
            }
        }
        set node [$tree GetNextColor]
    }
    return ""
}

#-------------------------------------------------------------------------------
# .PROC MainColorsGetColorIDFromName
# Returns the colour node id with this name, or -1 if not found
# .ARGS
# str name the name of the colour
# .END
#-------------------------------------------------------------------------------
proc MainColorsGetColorIDFromName {name} {
    global Color Mrml

    set tree Mrml(colorTree) 
    set node [$tree InitColorTraversal]
    while {$node != ""} {
        if {$name == [$node GetName]} {
            return [$node GetID]
        }
        set node [$tree GetNextColor]
    }
    return -1
}
