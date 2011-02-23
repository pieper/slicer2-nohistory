#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareMosaik.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:23 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareMosaik.tcl
# PROCEDURES:  
#   CompareMosaikInit
#   CompareMosaikUpdateMRML
#   CompareMosaikSetActive
#   CompareMosaikSetVolume string int
#   CompareMosaikSetOffsetInit
#   CompareMosaikSetOffset float
#   CompareMosaikSetSliderRange
#   CompareMosaikSetOffsetIncrement float
#   CompareMosaikSetOrient string
#   CompareMosaikSetAnno
#   CompareMosaikCenterCursor
#   CompareMosaikSetZoom float
#   CompareMosaikResetZoom
#   CompareMosaikSetOpacity int
#   CompareMosaikSetOpacityToggle int
#   CompareMosaikSetDivision
#   CompareMosaikConfigGui string string
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC CompareMosaikInit
# Set CompareMosaik array to the proper initial values.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikInit {} {
    global CompareMosaik Module

    set CompareMosaik(mosaikIndex) 9

    set CompareMosaik(offset) 0
    set CompareMosaik(offsetIncrement) 1
    set CompareMosaik(orient) Axial
    set CompareMosaik(zoom) 1
    set CompareMosaik(opacity) 1
    set CompareMosaik(widthDivision) 128
    set CompareMosaik(heightDivision) 128

    set CompareMosaik(backVolID) 0
    set CompareMosaik(foreVolID) 0

    lappend Module(procMRML) CompareMosaikUpdateMRML
}

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
# CompareMosaik(mosaikIndex)         : id of the mosaik in MultiSlicer object
# CompareMosaik(opacity)             : opacity for faded subdivisions
# CompareMosaik(widthDivision)       : mosaik subdivision width
# CompareMosaik(heightDivision)      : mosaik subdivision height
# CompareMosaik(zoom)                : zoom factor
# CompareMosaik(orient)              : the mosaik orientation
# CompareMosaik(offset)              : The value on the offset slider
# CompareMosaik(offsetIncrement)     : in mm, the amount the offset slider moves by
# CompareMosaik(backVolID)           : id of the Volume in the background.
# CompareMosaik(foreVolID)           : id of the Volume in the foreground


#-------------------------------------------------------------------------------
# .PROC CompareMosaikUpdateMRML
# Update volume display and slice controls GUIs when MRML updates.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikUpdateMRML {} {
    global CompareMosaik Volume Module MultiSlicer

    # See if the volume for each layer actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    foreach layer "back fore" {
       if {[lsearch $Volume(idList) $CompareMosaik(${layer}VolID)] == -1} {
                CompareMosaikSetVolume [Cap $layer] $n
       }
    }

    # Volumes on mosaik
    #----------------------------
    foreach layer "Back Fore" {
        set m $Module(CompareModule,fMosaik).fVolume.f${layer}Volume.mb${layer}Volume.m
        $m delete 0 end
        foreach v $Volume(idList) {
           set colbreak [MainVolumesBreakVolumeMenu $m]

           $m add command -label [Volume($v,node) GetName] \
           -command "CompareMosaikSetVolume ${layer} $v; \
           CompareRenderMosaik" -columnbreak $colbreak
        }
    }

    MultiSlicer Update
    CompareRenderMosaik
}



#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetActive
# Set the mosaik to be the active slice. This is called when the user clicks
# on the mosaik window.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetActive {} {
    global CompareMosaik MultiSlicer

    MultiSlicer SetActiveSlice $CompareMosaik(mosaikIndex)
    MultiSlicer Update

    CompareRenderMosaik
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetVolume
# Set the volume to be displayed in the specified layer of the mosaik.
# Layer can be Back or Fore
# .ARGS
# Layer string one of the two mosaik image layers
# v int the id of the volume to display
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetVolume {Layer v} {
    global CompareMosaik Volume MultiSlicer

    # Check if volume exists and use the None if not
    if {[lsearch $Volume(idList) $v] == -1} {
        set v $Volume(idNone)
    }

    # Fields in the CompareMosaik array are uncapitalized
    set layer [Uncap $Layer]

    # If no change, return
    if {$v == $CompareMosaik(${layer}VolID)} {return}
    set CompareMosaik(${layer}VolID) $v

    # Change button text
    CompareMosaikConfigGui fVolume.f${Layer}Volume.mb${Layer}Volume \
            "-text \"[Volume($v,node) GetName]\""

    # Set the volume in the Slicer
    MultiSlicer Set${Layer}Volume $CompareMosaik(mosaikIndex) Volume($v,vol)
    MultiSlicer Update

    # Always update Slider Range when change volume or orient
    CompareMosaikSetSliderRange
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetOffsetInit
# wrapper around CompareMosaikSetOffset. Also calls CompareRenderMosaik
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetOffsetInit {widget} {

    # This prevents Tk from calling RenderBoth when it first creates
    $widget config -command "CompareMosaikSetOffset; CompareRenderMosaik"
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetOffset
# Set the offset.
# Mosaik plane normal is already defined by the reformat matrix set in the
# vtrkMrmlMultiSlicer object.  This matrix changes when the Orient menu is used.
# .ARGS
# value float offset from center of vol (proc is called from GUI with no value)
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetOffset {{value ""}} {
    global CompareMosaik MultiSlicer


    # figure out what offset to use
    if {$value == ""} {
        # this means we were called directly from the slider w/ no value param
        # and the variable Slice($s,offset) has already been set by user
        set value $CompareMosaik(offset)
    } elseif {$value == "Prev"} {
        set value [expr $CompareMosaik(offset) - $CompareMosaik(offsetIncrement)]
    } elseif {$value == "Next"} {
        set value [expr $CompareMosaik(offset) + $CompareMosaik(offsetIncrement)]
    }

    if {$::Module(verbose)} {
        puts "Compare Mosaik Set Offset value = $value"
    }

    # validate value
    if {[ValidateFloat $value] == 0}  {
        # don't change slice offset if value is bad
        # Set slider to the last used offset for this orient
        set value [MultiSlicer GetOffset $CompareMosaik(mosaikIndex)]
    }

    set CompareMosaik(offset) $value
    MultiSlicer SetOffset $CompareMosaik(mosaikIndex) $value
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetSliderRange
# Set the max and min values reachable with the mosaik selection slider.
# Called when the volume in the background changes
# (in case num slices, resolution have changed)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetSliderRange {} {
    global CompareMosaik MultiSlicer

    set lo [MultiSlicer GetOffsetRangeLow  $CompareMosaik(mosaikIndex)]
    set hi [MultiSlicer GetOffsetRangeHigh $CompareMosaik(mosaikIndex)]

    CompareMosaikConfigGui fOffsetOrientation.fOffset.fSlider.sOffset "-from $lo -to $hi"

    # Update Offset
    set CompareMosaik(offset) [MultiSlicer GetOffset $CompareMosaik(mosaikIndex)]
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetOffsetIncrement
# Set the increment by which the mosaik slider should move.
# The default in the slicer is 1, which is 1 mm.
# Note this procedure will force increment to 1 if in any
# of the Slices orientations which just grab original data from the array.
# In this case the increment would mean 1 slice instead of 1 mm.
# .ARGS
# incr float increment slider should move by. is empty str if called from GUI
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetOffsetIncrement {{incr ""}} {
    global CompareMosaik MultiSlicer

    # set slider increments to 1 if in original orientation
    set orient [MultiSlicer GetOrientString $CompareMosaik(mosaikIndex)]
    if {$orient == "AxiSlice" || $orient == "CorSlice" \
        || $orient == "SagSlice" || $orient == "OrigSlice" } {
        set incr 1
    }

    # if called without an incr arg it's from user entry
    if {$incr == ""} {
        if {[ValidateFloat $CompareMosaik(offsetIncrement)] == 0} {
            tk_messageBox -message "The increment must be a number."

            # reset the incr
            set CompareMosaik(offsetIncrement) 1
            return
        }
        # if user-entered incr is okay then do the rest of the procedure
        set incr $CompareMosaik(offsetIncrement)
    }

    # Change Mosaik's offset increment variable
    set CompareMosaik(offsetIncrement) $incr

    # Make the slider allow this resolution
    CompareMosaikConfigGui fOffsetOrientation.fOffset.fSlider.sOffset "-resolution $incr"
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetOrient
# Set the mosaik window to have some orientation (i.e. Axial, etc)
#
# .ARGS
# orient string one of Axial AxiSlice Sagittal SagSlice, etc. from menu
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetOrient {orient} {
    global CompareMosaik View MultiSlicer

    MultiSlicer ComputeNTPFromCamera $View(viewCam)

    MultiSlicer SetOrientString $CompareMosaik(mosaikIndex) $orient
    set CompareMosaik(orient) [MultiSlicer GetOrientString $CompareMosaik(mosaikIndex)]

    # Always update Slider Range when change Back volume or orient
    CompareMosaikSetSliderRange

    # Set slider increments
    CompareMosaikSetOffsetIncrement

    # Set slider to the last used offset for this orient
    set CompareSlice(offset) [MultiSlicer GetOffset $CompareMosaik(mosaikIndex)]

    # Change text on menu button
    CompareMosaikConfigGui fOffsetOrientation.fOrientation.fChooseOrient.mbOrient "-text \"$orient\""

    # Anno
    CompareMosaikSetAnno $orient
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetAnno
# Set orientation annotations for mosaik window
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetAnno {orient} {
    global View CompareAnno CompareMosaik

    switch $orient {
        "Axial" {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput A
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput P
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput R
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput L
        }
        "AxiSlice" {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput A
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput P
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput R
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput L
        }
        "Sagittal" {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput S
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput I
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput A
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput P
        }
        "SagSlice" {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput S
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput I
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput A
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput P
        }
        "Coronal" {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput S
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput I
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput R
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput L
        }
        "CorSlice" {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput S
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput I
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput R
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput L
        }
        default {
            CompareAnno($CompareMosaik(mosaikIndex),top,mapper)   SetInput " "
            CompareAnno($CompareMosaik(mosaikIndex),bot,mapper)   SetInput " "
            CompareAnno($CompareMosaik(mosaikIndex),left,mapper)  SetInput " "
            CompareAnno($CompareMosaik(mosaikIndex),right,mapper) SetInput " "
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikCenterCursor
#
# Puts cursor (crosshair) in the center of the mosaik window.
# Called when the mouse exits a window.
# Usage: CompareMosaikCenterCursor
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikCenterCursor {} {
    global CompareAnno MultiSlicer CompareMosaik

    MultiSlicer SetCursorPosition $CompareMosaik(mosaikIndex) 256 256
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetZoom
#
# Sets the zoom on the mosaik and displays the result
# Usage: CompareMosaikSetZoom zoom
# .ARGS
# zoom float the zoom factor
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetZoom {{zoom ""}} {
    global CompareMosaik MultiSlicer

    # if called without a zoom arg it's from user entry
    if {$zoom == ""} {
    if {[ValidateFloat $CompareMosaik(,zoom)] == 0} {
        tk_messageBox -message "The zoom must be a number."

        # reset the zoom
        set CompareMosaik(zoom) [MultiSlicer GetZoom $CompareMosaik(mosaikIndex)]
        return
    }
    # if user-entered zoom is okay then do the rest of the procedure
    set zoom $CompareMosaik(zoom)
    }

    # Change Slice's Zoom variable
    set CompareMosaik(zoom) $zoom
    MultiSlicer SetZoom $CompareMosaik(mosaikIndex) $zoom
    MultiSlicer Update
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikResetZoom
# Set zoom in mosaik window to 1
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikResetZoom {} {
    global CompareMosaik MultiSlicer

    CompareMosaikSetZoom 1
    MultiSlicer SetZoomAutoCenter $CompareMosaik(mosaikIndex) 1
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetOpacity
# Set opacity of Fore layer to value
# This means the opacity used when overlaying the mosaik in
# the vtkMrmlMultiSlicer object (in its vtkImageMosaik member object).
# This is used to fade from fore to back layer.
# .ARGS
# value int opacity value
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetOpacity {{value ""}} {
    global CompareMosaik MultiSlicer

    if {$value == ""} {
        set value $CompareMosaik(opacity)
    } else {
        set CompareMosaik(opacity) $value
    }
    MultiSlicer SetMosaikOpacity $value
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetOpacityToggle
# toggle the opacity setting between left and righ
# eg if it was .75,.25 it becomes .25,.75
# .ARGS
# value int opacity value
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetOpacityToggle {} {
    CompareMosaikSetOpacity [expr 1.0 - $::CompareMosaik(opacity)]
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikSetDivision
# Set the mosaik rectangular subdivisions size.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikSetDivision {} {
    global CompareMosaik MultiSlicer

    MultiSlicer SetMosaikDivision $CompareMosaik(widthDivision) $CompareMosaik(heightDivision)
}

#-------------------------------------------------------------------------------
# .PROC CompareMosaikConfigGui
# Configure any gui widget for mosaik. Example of usage is:
# Change text on menu button by doing
# CompareMosaikConfigGui fOrient.mbOrient$s "-text $orient"
#
# .ARGS
# gui string widget to configure
# config string tk configure line to use
# .END
#-------------------------------------------------------------------------------
proc CompareMosaikConfigGui {gui config} {
    global Module

    set f $Module(CompareModule,fMosaik)

    eval $f.$gui config $config
}
