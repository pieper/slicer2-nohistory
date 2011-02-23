#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareSlices.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:23 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareSlices.tcl
# PROCEDURES:  
#   CompareSlicesInit
#   CompareSlicesBuildControlsForVolume widget int str str
#   CompareSlicesBuildControls s F
#   CompareSlicesEnableControls
#   CompareSlicesUpdateMRML
#   CompareSlicesSetActive int
#   CompareSlicesSetVolume string int int
#   CompareSlicesSetOffsetInit
#   CompareSlicesSetOffset int float
#   CompareSlicesSetOffsetAll float
#   CompareSlicesSetSliderRange int
#   CompareSlicesSetOffsetIncrement int float
#   CompareSlicesSetOffsetIncrementAll float
#   CompareSlicesSetOrient int string
#   CompareSlicesSetOrientAll
#   CompareSlicesSetZoom int float
#   CompareSlicesSetZoomAll float
#   CompareSlicesResetZoomAll
#   CompareSlicesCenterCursor int
#   CompareSlicesSetAnno int string
#   CompareSlicesSetOpacityAll int
#   CompareSlicesSetOpacityToggle int
#   CompareSlicesConfigGui int string string
#==========================================================================auto=

# TODO : - add an outline actor to represent the plane in linked mode
#        - manage presets


#-------------------------------------------------------------------------------
# .PROC CompareSlicesInit
# Set CompareSlice array to the proper initial values.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesInit {} {
    global CompareSlice Module

    set CompareSlice(idList) "0 1 2 3 4 5 6 7 8"

    set CompareSlice(opacity) 0.5
    set CompareSlice(activeID) 0

    set CompareSlice(offset) 0
    set CompareSlice(offsetIncrement) 1

    foreach s $CompareSlice(idList) {
        set CompareSlice($s,controls) ""

        set CompareSlice($s,orient) Axial
    set CompareSlice($s,offset) 0
        set CompareSlice($s,offsetIncrement) 1
    set CompareSlice($s,zoom) 1

        set CompareSlice($s,backVolID) 0
        set CompareSlice($s,foreVolID) 0
        set CompareSlice($s,labelVolID) 0

    }

    lappend Module(procMRML) CompareSlicesUpdateMRML
}

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
#
# CompareSlice(idList)                 : 0 to 8: the up to 9 slices id shown in
#   multi-slices window.
# CompareSlice(opacity)                : the opacity when displaying background
#   and foreground
# CompareSlice(activeID)               : active slice id
# CompareSlice(offset)                 : offset used in linked mode
# CompareSlice(offsetIncrement)        : offset increment used in linked mode
#
# In the following, s is a number in CompareSlice(idList) :
#   CompareSlice(s,controls)            : slice controls (GUI)
#   CompareSlice(s,orient)              : slice orientation
#   CompareSlice(s,offset)              : The value on the slice offset slider
#   CompareSlice(s,offsetIncrement)     : in mm, the amount the slice offset slider moves by
#   CompareSlice(s,zoom)                : The Zoom on the slice.
#   CompareSlice(s,backVolID)           : slice background volume id
#   CompareSlice(s,foreVolID)           : slice foreground volume id
#   CompareSlice(s,labelVolID)          : slice label volume id
#-------------------------------------------------------------------------------


# .PROC CompareSlicesBuildControlsForVolume
# Build volume selection controls for a slice in frame f.
#
# .ARGS
# f widget frame to place controls in
# s int slice (0 to 8)
# layer str one of Fore, Back, Label
# text str initial text for menubutton over menu (None for example)
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesBuildControlsForVolume {f s layer text} {
    global Gui

    DevAddLabel $f.l${layer}Volume "${text}:"

    # This Slice
    eval {menubutton $f.mb${layer}Volume${s} -text None -width 13 \
        -menu $f.mb${layer}Volume${s}.m} $Gui(WMBA) {-bg $Gui(slice0)}

    eval {menu $f.mb${layer}Volume${s}.m} $Gui(WMA)

    # tooltip for this slice in this layer
    TooltipAdd $f.mb${layer}Volume${s} "Volume Selection: choose a volume\
        to appear\nin the $layer layer in this slice window."

    pack $f.l${layer}Volume $f.mb${layer}Volume${s} \
        -pady 0 -padx 2 -side left -fill x
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesBuildControls
#
# Called from CompareViewer.tcl in CompareViewerBuildGUI.
# Builds all controls in the north east corner of a slice window.
# .ARGS
#  int s the id of the CompareSlice
#  str F the name of the CompareSlice Window
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesBuildControls {s F} {
    global Gui View CompareSlice MultiSlicer

    lappend CompareSlice($s,controls) $F

    frame $F.fOffset -bg $Gui(activeWorkspace)
    frame $F.fOrient -bg $Gui(activeWorkspace)
    frame $F.fVolume -bg $Gui(activeWorkspace)

    pack $F.fOffset $F.fOrient $F.fVolume \
        -fill x -side top -padx 0 -pady 3

    # Offset
    #-------------------------------------------
    set f $F.fOffset
    set fov2 [expr $View(fov) / 2]
    eval {entry $f.eOffset -width 4 -textvariable CompareSlice($s,offset)} $Gui(WEA)
    bind $f.eOffset <Return>   "CompareSlicesSetOffset $s; CompareRenderSlice $s"
    bind $f.eOffset <FocusOut> "CompareSlicesSetOffset $s; CompareRenderSlice $s"

    # tooltip for entry box
    set tip "Current slice: in mm or slice increments,\n \
        depending on the slice orientation you have chosen.\n \
        The default (AxiSagCor orientation) is in mm. \n \
        When editing (Slices orientation), slice numbers are shown.\n\
        To change the distance between slices from the default\n\
        1 mm, right-click on the V button."

    TooltipAdd $f.eOffset $tip

    eval {scale $f.sOffset -from -$fov2 -to $fov2 \
        -variable CompareSlice($s,offset) -length 160 -resolution 1.0 -command \
        "CompareSlicesSetOffsetInit $s $f.sOffset"} $Gui(WSA) \
        {-troughcolor $Gui(slice0)}

    pack $f.sOffset $f.eOffset -side left -anchor w -padx 2 -pady 0


    # Orientation
    #-------------------------------------------
    set f $F.fOrient

    DevAddLabel $f.lOrient "Or:"
    pack $f.lOrient -side left -pady 0 -padx 2 -fill x

    # This slice
    eval {menubutton $f.mbOrient${s} -text INIT -menu $f.mbOrient${s}.m \
        -width 13} $Gui(WMBA) {-bg $Gui(slice0)}

    pack $f.mbOrient${s} -side left -pady 0 -padx 2 -fill x

    # tooltip for orientation menu for slice
    TooltipAdd $f.mbOrient${s} "Set Orientation of this slice."

    eval {menu $f.mbOrient${s}.m} $Gui(WMA)
    set CompareSlice($s,menu) $f.mbOrient${s}.m

    foreach item "[MultiSlicer GetOrientList]" {
        $f.mbOrient${s}.m add command -label $item -command \
            "CompareSlicesSetOrient ${s} $item; CompareViewerHideSliceControls; CompareRenderSlice $s"
    }

    # Background Volume
    #-------------------------------------------
    CompareSlicesBuildControlsForVolume $f $s Back Bg

    # Foreground/Label Volumes row
    #-------------------------------------------
    set f $F.fVolume

    CompareSlicesBuildControlsForVolume $f $s Label Lb
    CompareSlicesBuildControlsForVolume $f $s Fore  Fg
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesEnableControls
# Called to enable/disable offset and orient controls, depending on display
# linking. When linking is activated, those controls are disabled for each
# slice, as general controls (in module GUI) are used to set offset and orientation.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesEnableControls {} {
   global CompareViewer CompareSlice

   if {$CompareViewer(linked) == "on"} {
      foreach s $CompareSlice(idList) {
         set control $CompareSlice($s,controls)
         $control.fOffset.sOffset configure -state disable
         $control.fOffset.eOffset configure -state disable
         $control.fOrient.mbOrient${s} configure -state disable
   }
   } else {
      foreach s $CompareSlice(idList) {
         set control $CompareSlice($s,controls)
         $control.fOffset.sOffset configure -state active
         $control.fOffset.eOffset configure -state normal
         $control.fOrient.mbOrient${s} configure -state normal
      }
   }
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesUpdateMRML
# Update volume display and slice controls GUIs when MRML updates.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesUpdateMRML {} {
    global CompareSlice Volume Module MultiSlicer

    # See if the volume for each layer actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    foreach s $CompareSlice(idList) {
         foreach layer "back fore label" {
            if {[lsearch $Volume(idList) $CompareSlice($s,${layer}VolID)] == -1} {
                CompareSlicesSetVolume [Cap $layer] $s $n
            }
        }
    }

    foreach s $CompareSlice(idList) {

        # Volumes on slice
        #----------------------------
        foreach layer "Back Fore Label" baseSuffix "Orient Volume Volume" {

            # Current Slice
            set suffix "f${baseSuffix}.mb${layer}Volume${s}.m"

            foreach pre "$CompareSlice($s,controls)" {
                set m $pre.$suffix
                $m delete 0 end
                foreach v $Volume(idList) {
                    set colbreak [MainVolumesBreakVolumeMenu $m]

            $m add command -label [Volume($v,node) GetName] \
                        -command "CompareSlicesSetVolume ${layer} ${s} $v; \
                        CompareViewerHideSliceControls; CompareRenderSlice $s" \
                        -columnbreak $colbreak
                }
            }
        }
    }
    MultiSlicer Update
    CompareRenderSlices
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetActive
# Set the active slice. This is called when the user clicks
# on a slice.
# .ARGS
# s int id of the slice set as active
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetActive {{s ""}} {
    global CompareSlice MultiSlicer

    if {$s == $CompareSlice(activeID)} {return}

    if {$s == ""} {
        set s $CompareSlice(activeID)
    } else {
        set CompareSlice(activeID) $s
    }

    MultiSlicer SetActiveSlice $s
    MultiSlicer Update

    CompareRenderSlices
}


#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetVolume
# Set the volume to be displayed in this layer and this slice window.
# Layer can be Back, Fore,Label
# .ARGS
# Layer string one of the three composited slice image layers
# s int 0 to 8, the considered slice id
# v int the id of the volume to display
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetVolume {Layer s v} {
    global CompareSlice Volume MultiSlicer

    # Check if volume exists and use the None if not
    if {[lsearch $Volume(idList) $v] == -1} {
        set v $Volume(idNone)
    }

    # Fields in the Slice array are uncapitalized
    set layer [Uncap $Layer]

    # If no change, return
    if {$v == $CompareSlice($s,${layer}VolID)} {return}
    set CompareSlice($s,${layer}VolID) $v

    # Change button text
    if {$Layer == "Back"} {
        CompareSlicesConfigGui $s fOrient.mb${Layer}Volume$s \
            "-text \"[Volume($v,node) GetName]\""
    } else {
        CompareSlicesConfigGui $s fVolume.mb${Layer}Volume$s \
            "-text \"[Volume($v,node) GetName]\""
    }

    # Set the volume in the Slicer
    MultiSlicer Set${Layer}Volume $s Volume($v,vol)
    MultiSlicer Update

    # Always update Slider Range when change volume or orient
    CompareSlicesSetSliderRange $s

}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOffsetInit
# wrapper around CompareSlicesSetOffset. Also calls CompareRenderSlice
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOffsetInit {s widget {value ""}} {

    # This prevents Tk from calling RenderBoth when it first creates
    # the slider, but before a user uses it.
    $widget config -command "CompareSlicesSetOffset $s; CompareRenderSlice $s"
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOffset
# Set the offset from volume center at which slice should be reformatted.
# Slice plane normal is already defined by the reformat matrix set in the
# vtrkMrmlSlicer object for slice s.  This matrix changes when the
# Orient menu is used.
# .ARGS
# s int slice id (0 to 8)
# value float offset from center of vol (proc is called from GUI with no value)
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOffset {s {value ""}} {
    global CompareSlice MultiSlicer


    # figure out what offset to use
    if {$value == ""} {
        # this means we were called directly from the slider w/ no value param
        # and the variable Slice($s,offset) has already been set by user
        set value $CompareSlice($s,offset)
    } elseif {$value == "Prev"} {
        set value [expr $CompareSlice($s,offset) - $CompareSlice($s,offsetIncrement)]
    } elseif {$value == "Next"} {
        set value [expr $CompareSlice($s,offset) + $CompareSlice($s,offsetIncrement)]
    }

    if {$::Module(verbose)} {
        puts "Compare Slices Set Offset s = $s, value = $value"
    }

    # validate value
    if {[ValidateFloat $value] == 0}  {
        # don't change slice offset if value is bad
        # Set slider to the last used offset for this orient
        set value [MultiSlicer GetOffset $s]
    }

    set CompareSlice($s,offset) $value
    MultiSlicer SetOffset $s $value
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOffsetAll
# Set the offset for all slices (used in linked mode).
# .ARGS
# value float offset from center of vol (proc is called from GUI with no value)
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOffsetAll {{value ""}} {
   global CompareSlice MultiSlicer

   # figure out what offset to use
    if {$value == ""} {
        # this means we were called directly from the slider w/ no value param
        # and the variable Slice($s,offset) has already been set by user
        set value $CompareSlice(offset)
    } elseif {$value == "Prev"} {
        set value [expr $CompareSlice(offset) - $CompareSlice(offsetIncrement)]
    } elseif {$value == "Next"} {
        set value [expr $CompareSlice(offset) + $CompareSlice(offsetIncrement)]
    }
    if {$::Module(verbose)} {
        puts "Compare Slices Set Offset All : value = $value"
    }

    # validate value
    if {[ValidateFloat $value] == 0}  {
        # don't change slice offset if value is bad
        # Set slider to the last used offset for this orient
    foreach s $CompareSlice(idList) {
           set value [MultiSlicer GetOffset $s]
    }
    }
    set CompareSlice(offset) $value
    foreach s $CompareSlice(idList) {
       set CompareSlice($s,offset) $value
       MultiSlicer SetOffset $s $value
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetSliderRange
# Set the max and min values reachable with the slice selection slider.
# Called when the volume in the background changes
# (in case num slices, resolution have changed)
# .ARGS
# s int slice id (0 to 8)
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetSliderRange {s} {
    global CompareSlice MultiSlicer

    set lo [MultiSlicer GetOffsetRangeLow  $s]
    set hi [MultiSlicer GetOffsetRangeHigh $s]

    CompareSlicesConfigGui $s fOffset.sOffset "-from $lo -to $hi"

    # Update Offset
    set CompareSlice($s,offset) [MultiSlicer GetOffset $s]
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOffsetIncrement
# Set the increment by which the slice slider should move.
# The default in the slicer is 1, which is 1 mm.
# Note this procedure will force increment to 1 if in any
# of the Slices orientations which just grab original data from the array.
# In this case the increment would mean 1 slice instead of 1 mm.
# .ARGS
# s int slice id
# incr float increment slider should move by. is empty str if called from GUI
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOffsetIncrement {s {incr ""}} {
    global CompareSlice MultiSlicer

    # set slider increments to 1 if in original orientation
    set orient [MultiSlicer GetOrientString $s]
    if {$orient == "AxiSlice" || $orient == "CorSlice" \
        || $orient == "SagSlice" || $orient == "OrigSlice" } {
        set incr 1
    }

    # if called without an incr arg it's from user entry
    if {$incr == ""} {
        if {[ValidateFloat $CompareSlice($s,offsetIncrement)] == 0} {
            tk_messageBox -message "The increment must be a number."

            # reset the incr
            set CompareSlice($s,offsetIncrement) 1
            return
        }
        # if user-entered incr is okay then do the rest of the procedure
        set incr $CompareSlice($s,offsetIncrement)
    }

    # Change Slice's offset increment variable
    set CompareSlice($s,offsetIncrement) $incr

    # Make the slider allow this resolution
    CompareSlicesConfigGui $s fOffset.sOffset "-resolution $incr"
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOffsetIncrementAll
# Set the increment by which every slice slider should move.
# The default in the slicer is 1, which is 1 mm.
# Note this procedure will force increment to 1 if in any
# of the Slices orientations which just grab original data from the array.
# In this case the increment would mean 1 slice instead of 1 mm.
# .ARGS
# incr float increment slider should move by. is empty str if called from GUI
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOffsetIncrementAll {{incr ""}} {
    global CompareSlice MultiSlicer Module

    # set slider increments to 1 if in original orientation
    set mOrient ${Module(CompareModule,fDisplay)}.fLinking.fOrientation.fChooseOrient.mbOrient
    set cget  "-text"
    set orient [eval $mOrient cget $cget]
    # set orient [MultiSlicer GetOrientString $s]
    if {$orient == "AxiSlice" || $orient == "CorSlice" \
        || $orient == "SagSlice" || $orient == "OrigSlice" } {
        set incr 1
    }

    # if called without an incr arg it's from user entry
    if {$incr == ""} {
        if {[ValidateFloat $CompareSlice(offsetIncrement)] == 0} {
            tk_messageBox -message "The increment must be a number."

            # reset the incr
            set CompareSlice(offsetIncrement) 1
            return
        }
        # if user-entered incr is okay then do the rest of the procedure
        set incr $CompareSlice(offsetIncrement)
    }

    # Change Slice's offset increment variable
    set CompareSlice(offsetIncrement) $incr

    # FIXME : update increment for every slice
    foreach s $CompareSlice(idList) {
    set temp CompareSlice($s,offsetIncrement)
    set $temp $incr
    # Make the slider allow this resolution
    CompareSlicesConfigGui $s fOffset.sOffset "-resolution $incr"
    }

    # Make the general slider allow this resolution
    #CompareSlicesConfigGui $s fOffset.sOffset "-resolution $incr"
    set sO ${Module(CompareModule,fDisplay)}.fLinking.fOffset.fSlider.sOffset
    set config "-resolution $incr"
    eval $sO config $config
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOrient
# Set one slice window to have some orientation (i.e. Axial, etc)
#
# .ARGS
# s int slice window (0,1,2)
# orient string one of Axial AxiSlice Sagittal SagSlice, etc. from menu
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOrient {s orient} {
    global CompareSlice View MultiSlicer

    # WARNING : don't know what's happening on this call...
    # Keep it right now, but may be deleted if related with 3D display
    MultiSlicer ComputeNTPFromCamera $View(viewCam)

    MultiSlicer SetOrientString $s $orient
    set CompareSlice($s,orient) [MultiSlicer GetOrientString $s]

    # Always update Slider Range when change Back volume or orient
    CompareSlicesSetSliderRange $s

    # Set slider increments
    CompareSlicesSetOffsetIncrement $s

    # Set slider to the last used offset for this orient
    set CompareSlice($s,offset) [MultiSlicer GetOffset $s]


    # Change text on menu button
    CompareSlicesConfigGui $s fOrient.mbOrient$s "-text \"$orient\""
    $CompareSlice($s,lOrient) config -text $orient

    # Anno
    CompareSlicesSetAnno $s $orient
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOrientAll
# Set all slice windows to have the same orientation (i.e. Axial, etc)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOrientAll {orient} {
    global CompareSlice MultiSlicer View Module

    # don't know if really useful but keep it as not source of issues
    MultiSlicer ComputeNTPFromCamera $View(viewCam)

    # resets zoom and pan
    CompareSlicesResetZoomAll

    #CompareModuleResetOffsets
    #set CompareSlice(offset) 0

    foreach s $CompareSlice(idList) {
        MultiSlicer SetOrientString $s $orient
        set CompareSlice($s,orient) [MultiSlicer GetOrientString $s]

        # Always update Slider Range when change Back volume or orient
        CompareSlicesSetSliderRange $s

        # Set slider increments
        CompareSlicesSetOffsetIncrement $s

        # FIXME : done in CompareSlicesSetSliderRange
    # Set slider to the last used offset for this orient
        set CompareSlice($s,offset) [MultiSlicer GetOffset 0]
    MultiSlicer SetOffset $s $CompareSlice($s,offset)

        # Change text on menu button
        CompareSlicesConfigGui $s fOrient.mbOrient$s "-text \"$orient\""
        $CompareSlice($s,lOrient) config -text $orient

        # update menu value
    set mOrient ${Module(CompareModule,fDisplay)}.fLinking.fOrientation.fChooseOrient.mbOrient
        set config  "-text \"$orient\""
        eval $mOrient config $config

        # Anno
        CompareSlicesSetAnno $s $CompareSlice($s,orient)
    }

    # Updates linking slidebar range
    set CompareSlice(offset) [MultiSlicer GetOffset 0]
    set lo [MultiSlicer GetOffsetRangeLow  0]
    set hi [MultiSlicer GetOffsetRangeHigh 0]

    set sO ${Module(CompareModule,fDisplay)}.fLinking.fOffset.fSlider.sOffset
    set config "-from $lo -to $hi"
    eval $sO config $config
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetZoom
# Sets the zoom on a Slice id
# and displays the result
#
# Usage: CompareSlicesSetZoom id zoom
# .ARGS
# s int slice id
# zoom float the zoom factor
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetZoom {s {zoom ""}} {
    global CompareSlice MultiSlicer

    # if called without a zoom arg it's from user entry
    if {$zoom == ""} {
    if {[ValidateFloat $CompareSlice($s,zoom)] == 0} {
        tk_messageBox -message "The zoom must be a number."

        # reset the zoom
        set CompareSlice($s,zoom) [MultiSlicer GetZoom $s]
        return
    }
    # if user-entered zoom is okay then do the rest of the procedure
    set zoom $CompareSlice($s,zoom)
    }

    # Change Slice's Zoom variable
    set CompareSlice($s,zoom) $zoom

    MultiSlicer SetZoom $s $zoom

    MultiSlicer Update
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetZoomAll
#
# Sets the zoom on all slices
# and displays the result
#
# Usage: CompareSlicesSetZoomAll zoom
# .ARGS
# zoom float the zoom factor
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetZoomAll {zoom} {
    global CompareSlice MultiSlicer

    # Change Slice's Zoom variable
    foreach s $CompareSlice(idList) {
        set CompareSlice($s,zoom) $zoom
    }
    MultiSlicer SetZoom $zoom

    MultiSlicer Update
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesResetZoomAll
# Set zoom in all slice windows to 1
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesResetZoomAll {} {
    global CompareSlice MultiSlicer

    foreach s $CompareSlice(idList) {
        CompareSlicesSetZoom $s 1
        MultiSlicer SetZoomAutoCenter $s 1
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesCenterCursor
#
# Puts cursor (crosshair) in the center of the slice window.
# Called when the mouse exits a window.
# Usage: CenterCursor sliceid
# .ARGS
# s int slice id
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesCenterCursor {s} {
    global CompareViewer MultiSlicer

    if {$CompareViewer(mode) == "2" || $CompareViewer(mode) == "3" || $CompareViewer(mode) == "4"} {
        MultiSlicer SetCursorPosition $s 256 256
    } else {
        MultiSlicer SetCursorPosition $s 128 128
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetAnno
# Set orientation annotations for slice windows
# .ARGS
# s int slice id
# orient string the slice orientation
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetAnno {s orient} {
    global CompareAnno

    switch $orient {
        "Axial" {
            CompareAnno($s,top,mapper)   SetInput A
            CompareAnno($s,bot,mapper)   SetInput P
            CompareAnno($s,left,mapper)  SetInput R
            CompareAnno($s,right,mapper) SetInput L
        }
        "AxiSlice" {
            CompareAnno($s,top,mapper)   SetInput A
            CompareAnno($s,bot,mapper)   SetInput P
            CompareAnno($s,left,mapper)  SetInput R
            CompareAnno($s,right,mapper) SetInput L
        }
        "Sagittal" {
            CompareAnno($s,top,mapper)   SetInput S
            CompareAnno($s,bot,mapper)   SetInput I
            CompareAnno($s,left,mapper)  SetInput A
            CompareAnno($s,right,mapper) SetInput P
        }
        "SagSlice" {
            CompareAnno($s,top,mapper)   SetInput S
            CompareAnno($s,bot,mapper)   SetInput I
            CompareAnno($s,left,mapper)  SetInput A
            CompareAnno($s,right,mapper) SetInput P
        }
        "Coronal" {
            CompareAnno($s,top,mapper)   SetInput S
            CompareAnno($s,bot,mapper)   SetInput I
            CompareAnno($s,left,mapper)  SetInput R
            CompareAnno($s,right,mapper) SetInput L
        }
        "CorSlice" {
            CompareAnno($s,top,mapper)   SetInput S
            CompareAnno($s,bot,mapper)   SetInput I
            CompareAnno($s,left,mapper)  SetInput R
            CompareAnno($s,right,mapper) SetInput L
        }
        default {
            CompareAnno($s,top,mapper)   SetInput " "
            CompareAnno($s,bot,mapper)   SetInput " "
            CompareAnno($s,left,mapper)  SetInput " "
            CompareAnno($s,right,mapper) SetInput " "
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOpacityAll
# Set opacity of all Fore layers to value
# This means the opacity used when overlaying the slices in
# the vtkMrmlMultiSlicer object (in its vtkImageOverlay member object).
# This is used to fade from fore to back layers (image overlay).
# .ARGS
# value int opacity value
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOpacityAll {{value ""}} {
    global CompareSlice MultiSlicer

    if {$value == ""} {
        set value $CompareSlice(opacity)
    } else {
        set CompareSlice(opacity) $value
    }
    MultiSlicer SetForeOpacity $value
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesSetOpacityToggle
# toggle the opacity setting between left and right
# eg if it was .75,.25 it becomes .25,.75
# .ARGS
# value int opacity value
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesSetOpacityToggle {} {
    CompareSlicesSetOpacityAll [expr 1.0 - $::CompareSlice(opacity)]
}

#-------------------------------------------------------------------------------
# .PROC CompareSlicesConfigGui
# Configure any gui widget for slice s. Example of usage is:
# Change text on menu button by doing
# CompareSlicesConfigGui $s fOrient.mbOrient$s "-text $orient"
#
# .ARGS
# s int slice id (0 to 8)
# gui string widget to configure (look in proc CompareSlicesBuildControls)
# config string tk configure line to use
# .END
#-------------------------------------------------------------------------------
proc CompareSlicesConfigGui {s gui config} {
    global CompareSlice

    foreach f $CompareSlice($s,controls) {
        eval $f.$gui config $config
    }
}

