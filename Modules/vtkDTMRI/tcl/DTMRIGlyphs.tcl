#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRIGlyphs.tcl,v $
#   Date:      $Date: 2006/04/01 13:35:50 $
#   Version:   $Revision: 1.22 $
# 
#===============================================================================
# FILE:        DTMRIGlyphs.tcl
# PROCEDURES:  
#   DTMRIGlyphsInit
#   DTMRIGlyphsBuildGUI
#   DTMRIUpdateReformatType
#   DTMRIUpdateScalarBar
#   DTMRIShowScalarBar
#   DTMRIHideScalarBar
#   DTMRIUpdateGlyphResolution value
#   DTMRIUpdateGlyphEigenvector
#   DTMRIUpdateGlyphColor
#   DTMRIUpdateGlyphScalarRange not_used
#   DTMRIUpdate
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC DTMRIGlyphsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIGlyphsInit {} {

    global DTMRI

    # Version info for files within DTMRI module
    #------------------------------------
    set m "Glyphs"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.22 $} {$Date: 2006/04/01 13:35:50 $}]

    # type of reformatting
    set DTMRI(mode,reformatType) 0
    #set DTMRI(mode,reformatTypeList) {None 0 1 2}
    #set DTMRI(mode,reformatTypeList) {0 1 2}
    set DTMRI(mode,reformatTypeList) {0 1 2 {0 1 2} None}
    set DTMRI(mode,reformatTypeList,text) {"" "" "" All Vol}
    set DTMRI(mode,reformatTypeList,tooltips) [list \
                           "Display DTMRIs as glyphs (ex. lines) in the location of the leftmost slice."  \
                           "Display DTMRIs as glyphs (ex. lines) in the location of the middle slice."  \
                           "Display DTMRIs as glyphs (ex. lines) in the location of the rightmost slice."  \
                           "Display DTMRIS as glyphs in all the slice views (axial, sagittal and coronal)." \
               "Display all DTMRIs in the volume.  Please use an ROI." \
                          ]
    #set DTMRI(mode,reformatTypeList,tooltips) [list \
    #        "No reformatting: display all DTMRIs." \
    #       "Reformat DTMRIs along with slice 0."  \
    #      "Reformat DTMRIs along with slice 1."  \
    #     "Reformat DTMRIs along with slice 2."  \
    #]

    # whether we are currently displaying glyphs
    set DTMRI(mode,visualizationType,glyphsOn) 0ff
    set DTMRI(mode,visualizationType,glyphsOnList) {On Off}
    set DTMRI(mode,visualizationType,glyphsOnList,tooltip) [list \
                                "Display each DTMRI as a glyph\n(for example a line or ellipsoid)" \
                                "Do not display glyphs" ]

    # type of glyph to display (default to lines since fastest)
    set DTMRI(mode,glyphType) Lines
    set DTMRI(mode,glyphTypeList) {Axes Lines Tubes Ellipsoids Boxes Superquadric}
    set DTMRI(mode,glyphTypeList,tooltips) {{Display DTMRIs as 3 axes aligned with eigenvectors and scaled by eigenvalues.} {Display DTMRIs as lines aligned with one eigenvector and scaled by its eigenvalue.} {Display DTMRIs as ellipses aligned with eigenvectors and scaled by eigenvalues.} {Display DTMRIs as scaled oriented cubes.}}
    
    #name of glyph object
    foreach plane "0 1 2" {
      set DTMRI(mode,glyphsObject$plane) DTMRI(vtk,glyphs$plane)
    }

    # type of eigenvector to draw glyph lines for
    set DTMRI(mode,glyphEigenvector) Max
    set DTMRI(mode,glyphEigenvectorList) {Max Middle Min}
    set DTMRI(mode,glyphEigenvectorList,tooltips) {{When displaying DTMRIs as Lines, use the eigenvector corresponding to the largest eigenvalue.} {When displaying DTMRIs as Lines, use the eigenvector corresponding to the middle eigenvalue.} {When displaying DTMRIs as Lines, use the eigenvector corresponding to the smallest eigenvalue.}}

    # type of glyph coloring
    set DTMRI(mode,glyphColor) Direction; # default must match the vtk class
    set DTMRI(mode,glyphColorList) {Linear Planar Spherical Max Middle Min MaxMinusMiddle RA FA Direction}
    set DTMRI(mode,glyphColorList,tooltip) "Color DTMRIs according to\nLinear, Planar, or Spherical measures,\nwith the Max, Middle, or Min eigenvalue,\nwith relative or fractional anisotropy (RA or FA),\nor by direction of major eigenvector."
   
    # glyhs visualization resolution
    set DTMRI(mode,glyphResolution) 3
    set DTMRI(mode,glyphResolution,min) 1
    set DTMRI(mode,glyphResolution,max) 5


    # How to handle display of colors: like W/L but scalar range
    set DTMRI(mode,glyphScalarRange) Auto
    set DTMRI(mode,glyphScalarRangeList) {Auto Manual}
    set DTMRI(mode,glyphScalarRangeList,tooltips) [list \
                               "Scalar range will be set to max and min scalar in the data." \
                               "User-adjustable scalar range to highlight areas of interest (like window/level does)."]
    # slider min/max values
    set DTMRI(mode,glyphScalarRange,min) 0
    set DTMRI(mode,glyphScalarRange,max) 10
    # slider current settings
    set DTMRI(mode,glyphScalarRange,low) 0
    set DTMRI(mode,glyphScalarRange,hi) 1

    # whether to reformat DTMRIs along with slices
    set DTMRI(mode,reformat) 0

    # Whether the glyph actors are currently present in the scene
    set DTMRI(glyphs,actorsAdded) 0

    # scalar bar
    set DTMRI(mode,scalarBar) Off
    set DTMRI(mode,scalarBarList) {On Off}
    set DTMRI(mode,scalarBarList,tooltips) [list \
                        "Display a scalar bar to show correspondence between numbers and colors." \
                        "Do not display the scalar bar."]


}


#-------------------------------------------------------------------------------
# .PROC DTMRIGlyphsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIGlyphsBuildGUI {} {

    global DTMRI Tensor Module Gui

    #-------------------------------------------
    # Glyph frame
    #-------------------------------------------
    set fGlyph $Module(DTMRI,fGlyph)
    set f $fGlyph

    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $f.fReformat  -bg $Gui(activeWorkspace)
    pack $f.fReformat -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $f.fGlyphsMode  -bg $Gui(activeWorkspace)
    pack $f.fGlyphsMode -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $f.fVisMethods  -bg $Gui(activeWorkspace) -relief sunken -bd 2
    pack $f.fVisMethods -side top -padx $Gui(pad) -pady $Gui(pad) -fill both -expand true

    #-------------------------------------------
    # Glyph->Active frame
    #-------------------------------------------
    set f $fGlyph.fActive

    # menu to select active DTMRI
    DevAddSelectButton DTMRI $f ActiveGlyph "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActiveGlyph
    lappend Tensor(mActiveList) $f.mbActiveGlyph.m

    #-------------------------------------------
    # Display->Notebook -> Glyph frame -> Reformat
    #-------------------------------------------
    set f $fGlyph.fReformat

    DevAddLabel $f.l "Glyphs on Slice:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    set colors [list  $Gui(slice0) $Gui(slice1) $Gui(slice2) $Gui(activeWorkspace) $Gui(activeWorkspace)]
    set widths [list  2 2 2 4 4]

    foreach vis $DTMRI(mode,reformatTypeList) \
    tip $DTMRI(mode,reformatTypeList,tooltips) \
    text $DTMRI(mode,reformatTypeList,text) \
    color $colors \
    width $widths {
        regsub -all " " $vis "_" winname  ;# remove spaces from value
        eval {radiobutton $f.rMode$winname \
              -text "$text" -value "$vis" \
              -variable DTMRI(mode,reformatType) \
              -command {DTMRIUpdateReformatType} \
              -indicatoron 0 } $Gui(WCA) \
        {-bg $color -selectcolor $color -width $width}
        pack $f.rMode$winname -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$winname $tip
    }
    
    #-------------------------------------------
    # Display -> Notebook -> Glyph frame ->->GlyphsMode frame
    #-------------------------------------------
    set f $fGlyph.fGlyphsMode

    eval {label $f.lVis -text "Display Glyphs: "} $Gui(WLA)
    pack $f.lVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationType,glyphsOnList) \
    tip $DTMRI(mode,visualizationType,glyphsOnList,tooltip) {
        eval {radiobutton $f.r$vis \
              -text $vis \
              -command "DTMRIUpdate" \
              -value $vis \
              -variable DTMRI(mode,visualizationType,glyphsOn) \
              -indicatoron 0} $Gui(WCA)

        pack $f.r$vis -side left -fill x
        TooltipAdd $f.r$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs frame
    #-------------------------------------------
    frame $fGlyph.fVisMethods.fGlyphs -bg $Gui(activeWorkspace)
    pack $fGlyph.fVisMethods.fGlyphs -side top -padx 0 -pady $Gui(pad) -fill x

    set f $fGlyph.fVisMethods.fGlyphs

    foreach frame "Resolution GlyphType Lines Colors ScalarBar GlyphScalarRange Slider" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Resolution frame
    #-------------------------------------------
    set f $fGlyph.fVisMethods.fGlyphs.fResolution
    
    eval {label $f.l -text "Density(H<->L):"\
          -width 12 -justify right } $Gui(WLA)

    eval {scale $f.s -from $DTMRI(mode,glyphResolution,min) \
                          -to $DTMRI(mode,glyphResolution,max)    \
          -variable  DTMRI(mode,glyphResolution)\
      -command DTMRIUpdateGlyphResolution \
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)

      pack $f.l $f.s -side left -padx $Gui(pad) -pady 0


    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->GlyphType frame
    #-------------------------------------------
    set f $fGlyph.fVisMethods.fGlyphs.fGlyphType

    DevAddLabel $f.l "Glyph Type:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    eval {menubutton $f.mbVis -text $DTMRI(mode,glyphType) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack  $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,glyphTypeList) {
        $f.mbVis.m add command -label $vis \
        -command "$f.mbVis config -text $vis; set DTMRI(mode,glyphType) $vis; DTMRIUpdate"
    }
    # save menubutton for config
    set DTMRI(gui,mbGlyphType) $f.mbVis
    # Add a tooltip
    #TooltipAdd $f.mbVis $DTMRI(mode,glyphColorList,tooltip)

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Lines frame
    #-------------------------------------------

    set f $fGlyph.fVisMethods.fGlyphs.fLines

    DevAddLabel $f.l "Line Type:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    foreach vis $DTMRI(mode,glyphEigenvectorList) tip $DTMRI(mode,glyphEigenvectorList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,glyphEigenvector) \
          -command DTMRIUpdateGlyphEigenvector \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 1
        TooltipAdd $f.rMode$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Colors frame
    #-------------------------------------------
    set f $fGlyph.fVisMethods.fGlyphs.fColors

    eval {label $f.lVis -text "Color by: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(mode,glyphColor) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,glyphColorList) {
        $f.mbVis.m add command -label $vis \
        -command "set DTMRI(mode,glyphColor) $vis; DTMRIUpdateGlyphColor"
    }
    # save menubutton for config
    set DTMRI(gui,mbGlyphColor) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(mode,glyphColorList,tooltip)

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->ScalarBar frame
    #-------------------------------------------
    set f $fGlyph.fVisMethods.fGlyphs.fScalarBar

    DevAddLabel $f.l "Scalar Bar:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    foreach vis $DTMRI(mode,scalarBarList) tip $DTMRI(mode,scalarBarList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,scalarBar) \
          -command {DTMRIUpdateScalarBar} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 1
        TooltipAdd  $f.rMode$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->GlyphScalarRange frame
    #-------------------------------------------
    set f $fGlyph.fVisMethods.fGlyphs.fGlyphScalarRange

    DevAddLabel $f.l "Scalar Range:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    foreach vis $DTMRI(mode,glyphScalarRangeList) tip $DTMRI(mode,glyphScalarRangeList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,glyphScalarRange) \
          -command {DTMRIUpdateGlyphScalarRange; Render3D} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 1
        TooltipAdd  $f.rMode$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Slider frame
    #-------------------------------------------
    foreach slider "Low Hi" text "Lo Hi" {

        set f $fGlyph.fVisMethods.fGlyphs.fSlider

        frame $f.f$slider -bg $Gui(activeWorkspace)
        pack $f.f$slider -side top -padx $Gui(pad) -pady 1
        set f $f.f$slider

        eval {label $f.l$slider -text "$text:"} $Gui(WLA)
        eval {entry $f.e$slider -width 10 \
          -textvariable DTMRI(mode,glyphScalarRange,[Uncap $slider])} \
        $Gui(WEA)
        eval {scale $f.s$slider -from $DTMRI(mode,glyphScalarRange,min) \
          -to $DTMRI(mode,glyphScalarRange,max) \
          -length 90 \
          -variable DTMRI(mode,glyphScalarRange,[Uncap $slider]) \
          -resolution 0.001 \
          -command {DTMRIUpdateGlyphScalarRange; Render3D}} \
        $Gui(WSA) {-sliderlength 15}
        pack $f.l$slider $f.e$slider $f.s$slider -side left  -padx $Gui(pad)
        set DTMRI(gui,slider,$slider) $f.s$slider
        bind $f.e${slider} <Return>   \
        "DTMRIUpdateGlyphScalarRange ${slider}; Render3D"

    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateReformatType
#  Reformat the requested slice (from GUI input) or all.  Then call
#  pipeline update proc (DTMRIUpdate) to make this happen.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateReformatType {} {
    global DTMRI

    set mode $DTMRI(mode,reformatType)

    set result ok

    # make sure we don't display all DTMRIs by accident
    switch $mode {
        "None" {
            set message "This will display ALL DTMRIs.  If the volume is not masked using a labelmap ROI, this may take a long time or not work on your machine.  Proceed?"
            set result [tk_messageBox -type okcancel -message $message]
        }
    }

    # display what was requested
    if {$result == "ok"} {
        DTMRIUpdate
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateScalarBar
# Display scalar bar for glyph coloring
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateScalarBar {} {
    global DTMRI

    set mode $DTMRI(mode,scalarBar)

    switch $mode {
        "On" {
            DTMRIShowScalarBar
        }
        "Off" {
            DTMRIHideScalarBar
        }
    }

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIShowScalarBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIShowScalarBar {} {
    DTMRIUpdateGlyphScalarRange
    DTMRI(vtk,scalarBar,actor) VisibilityOn
    #viewRen AddProp DTMRI(vtk,scalarBar,actor)
}

#-------------------------------------------------------------------------------
# .PROC DTMRIHideScalarBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIHideScalarBar {} {
    DTMRI(vtk,scalarBar,actor) VisibilityOff
    #viewRen RemoveActor DTMRI(vtk,scalarBar,actor)
}

################################################################
#  visualization procedures that deal with glyphs
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphResolution
# choose the resolution of the glyphs
# .ARGS
# int value not used
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphResolution { value } {
    global DTMRI

    foreach plane "0 1 2" {
      DTMRI(vtk,glyphs$plane) SetResolution $DTMRI(mode,glyphResolution)
    }
    #update 3D window (causes pipeline update)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphEigenvector
# choose max middle or min for display
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphEigenvector {} {
    global DTMRI

    set mode $DTMRI(mode,glyphEigenvector)

    # Scaling along x-axis corresponds to major 
    # eigenvector, etc.  So move the line to 
    # point along the proper axis for scaling
    switch $mode {
        "Max" {
            DTMRI(vtk,glyphs,line) SetPoint1 -1 0 0
            DTMRI(vtk,glyphs,line) SetPoint2 1 0 0    
        }
        "Middle" {
            DTMRI(vtk,glyphs,line) SetPoint1 0 -1 0
            DTMRI(vtk,glyphs,line) SetPoint2 0 1 0    
        }
        "Min" {
            DTMRI(vtk,glyphs,line) SetPoint1 0 0 -1
            DTMRI(vtk,glyphs,line) SetPoint2 0 0 1    
        }
    }
    # Update pipelines
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphColor
# switch between various color options the user can select for glyphs
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphColor {} {
    global DTMRI
    
    set mode $DTMRI(mode,glyphColor)
    
    # display new mode while we are working...
    $DTMRI(gui,mbGlyphColor)    config -text $mode
    
    # default lookup table colormap (changes for color by direction)
    DTMRI(vtk,glyphs,lut) SetHueRange .6667 0.0
    set DTMRI(vtk,glyphs,lut,HueRange) ".6667 0.0"

    foreach plane {0 1 2} {
    switch $mode {
        "Linear" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithLinearMeasure
        }
        "Planar" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithPlanarMeasure
        }
        "Spherical" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithSphericalMeasure
        }
        "Max" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithMaxEigenvalue
        }
        "Middle" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithMiddleEigenvalue
        }
        "Min" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithMinEigenvalue
        }
        "MaxMinusMiddle" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithMaxMinusMidEigenvalue
        }
        "RA" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithRelativeAnisotropy
        }
        "FA" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithFractionalAnisotropy
        }
        "Direction" {
            $DTMRI(mode,glyphsObject$plane) ColorGlyphsWithDirection
            # lookup table colormap changes for color by direction
            DTMRI(vtk,glyphs,lut) SetHueRange 0 1
            set DTMRI(vtk,glyphs,lut,HueRange) "0 1"
        }
        
    }
    
    }
    # Tell actor where to get scalar range
    set DTMRI(mode,glyphScalarRange) Auto
    DTMRIUpdateGlyphScalarRange

    # Update pipelines
    Render3D

}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphScalarRange
# Called to reset the scalar range displayed to correspond to the 
# numbers output by the current coloring method
# .ARGS
# string not_used Not used
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphScalarRange {{not_used ""}} {
    global DTMRI Tensor

    # make sure we have a DTMRI displayed now
    set t $Tensor(activeID)
    if {$t == "" || $t == $Tensor(idNone)} {
        return
    }

    # make sure the pipeline is up-to-date so we get the right
    # scalar range.  Otherwise the first render will not have
    # the right glyph colors.
    DTMRI(vtk,glyphs,append) Update

    set mode $DTMRI(mode,glyphScalarRange)

    # find scalar range if not set by user
    switch $mode {
        "Auto" {
            scan [[DTMRI(vtk,glyphs,append) GetOutput] GetScalarRange] \
        "%f %f" s1 s2
        }
        "Manual" {
            set s1 $DTMRI(mode,glyphScalarRange,low) 
            set s2 $DTMRI(mode,glyphScalarRange,hi) 
        }
    }

    # make sure that the scalars hi and low are not equal since
    # this causes an error from the mapper
    if {$s2 == $s1} {
        set s1 0
        set s2 1
    }    
    # set this scalar range for glyph display
    DTMRI(vtk,glyphs,mapper) SetScalarRange $s1 $s2

    # Round the scalar range numbers to requested precision
    # This way -4e-12 will not look like a negative eigenvalue in
    # the GUI
    set DTMRI(mode,glyphScalarRange,low) \
    [format "%0.5f" $s1]
    set DTMRI(mode,glyphScalarRange,hi) \
    [format "%0.5f" $s2]

    # This causes multiple renders since for some reason
    # the scalar bar does not update on the first one
    Render3D
}



################################################################
#  MAIN visualization procedure: pipeline control is here
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdate
# The whole enchilada (if this were a vtk filter, this would be
# the Execute function...)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdate {} {
    global DTMRI Slice Volume Label Gui Tensor

    set t $Tensor(activeID)
    if {$t == "" || $t == $Tensor(idNone)} {
        puts "DTMRIUpdate: Can't visualize Nothing"
        return
    }

    # reset progress text for any filter that uses the blue bar
    set Gui(progressText) "Working..."

    #------------------------------------
    # preprocessing pipeline
    #------------------------------------


    set dataSource [Tensor($t,data) GetOutput]

    # mask DTMRIs if required
    #------------------------------------
    set mode $DTMRI(mode,mask)
    if {$mode != "None" && $DTMRI(MaskLabelmap) != ""} {
        
        puts "masking by $DTMRI(mode,mask)"

        #Create pipeline
        set thresh DTMRI(vtk,mask,threshold)
        $thresh SetInValue       1
        $thresh SetOutValue      0
        $thresh SetReplaceIn     1
        $thresh SetReplaceOut    1
        $thresh SetOutputScalarTypeToUnsignedChar    
        
        $thresh ThresholdBetween $DTMRI(MaskLabel) $DTMRI(MaskLabel)
        set v $DTMRI(MaskLabelmap)
        $thresh SetInput [Volume($v,vol) GetOutput]

        set mask DTMRI(vtk,mask,mask)
        $mask SetMaskInput [$thresh GetOutput]
        # use output from above thresholding pipeline as input
        $mask SetImageInput $dataSource

        # set the dataSource to point to our output 
        # for the following pipelines
        set preprocessedSource [$mask GetOutput]
    
    # active mask mode in Scalar computation
    set DTMRI(scalars,ROI) "Mask"
    
    } else {
        set preprocessedSource $dataSource
    
    #deactive mask mode in Scalar computation
    set DTMRI(scalars,ROI) "None"
    }

    #------------------------------------
    # visualization pipeline
    #------------------------------------
    #set mode $DTMRI(mode,visualizationType)
    set mode $DTMRI(mode,visualizationType,glyphsOn)
    puts "Setting glyph mode $mode for DTMRI $t"
    
    foreach plane "0 1 2" {
      if {$DTMRI(mode,glyphType) == "Superquadric"} {
         set DTMRI(mode,glyphsObject$plane) DTMRI(vtk,glyphsSQ$plane)
      } else {
         set DTMRI(mode,glyphsObject$plane) DTMRI(vtk,glyphs$plane)     
      }
    }
      
     
        
    switch $mode {
        "On" {
            puts "glyphs! $DTMRI(mode,glyphType)"
            
            # Find input to pipeline
            #------------------------------------
            set slice $DTMRI(mode,reformatType)

        # find ijk->ras rotation to apply to each DTMRI
        #vtkTransform t2 
        #DTMRICalculateIJKtoRASRotationMatrix t2 $t
        #puts "Lauren testing rm -y"
        #t2 Scale 1 -1 1
        #puts [[t2 GetMatrix] Print]
        #DTMRI(vtk,glyphs) SetTensorRotationMatrix [t2 GetMatrix]
        #t2 Delete
        DTMRICalculateIJKtoRASRotationMatrix DTMRI(vtk,glyphs,trans) $t
        foreach plane {0 1 2} {
          $DTMRI(mode,glyphsObject$plane) SetTensorRotationMatrix [DTMRI(vtk,glyphs,trans) GetMatrix]
        }
            if {$slice != "None"} {
              foreach plane $slice {
                # We are reformatting a slice of glyphs
                DTMRI(vtk,reformat$plane) SetInput $preprocessedSource

                # set fov same as volume we are overlaying
                DTMRI(vtk,reformat$plane) SetFieldOfView [Slicer GetFieldOfView]

                # tell reformatter to obey the node
                set node Tensor($Tensor(activeID),node)
                DTMRI(vtk,reformat$plane) SetInterpolate [$node GetInterpolate]
                DTMRI(vtk,reformat$plane) SetWldToIjkMatrix [$node GetWldToIjk]
                
                #  reformat resolution should match the DTMRI resolution.
                # Use the extents to figure this out.
                set ext [[Tensor($Tensor(activeID),data) GetOutput] GetExtent]
                set resx [expr [lindex $ext 1] - [lindex $ext 0] + 1]
                set resy [expr [lindex $ext 3] - [lindex $ext 2] + 1]
                if {$resx > $resy} {
                    set res $resx
                } else {
                    set res $resy
                }

                DTMRI(vtk,reformat$plane) SetResolution $res

                set m [Slicer GetReformatMatrix $plane]
                DTMRI(vtk,reformat$plane) SetReformatMatrix $m
                set visSource [DTMRI(vtk,reformat$plane) GetOutput]
                
                # Position glyphs with the slice.
                # The glyph filter will transform output points by this 
                # matrix.  We can't just move the actor in space
                # since this will rotate the DTMRIs, so this is wrong:
                # DTMRI(vtk,glyphs,actor) SetUserMatrix $m
                $DTMRI(mode,glyphsObject$plane) SetVolumePositionMatrix $m
                $DTMRI(mode,glyphsObject$plane) SetInput $visSource
          }    

            } else {
                # We are displaying the whole volume of glyphs!
                set visSource $preprocessedSource
                
                # Want actor to be positioned in center with slices
                vtkTransform t1
                # special trick to avoid obnoxious windows warnings about legacy hack
                # for vtkTransform
                t1 AddObserver WarningEvent ""
                DTMRICalculateActorMatrix t1 $Tensor(activeID)
                
                # Position glyphs in the volume.
                # The glyph filter will transform output points by this 
                # matrix.  We can't just move the actor in space
                # since this will rotate the DTMRIs, so this is wrong:
                #DTMRI(vtk,glyphs,actor) SetUserMatrix [t1 GetMatrix]
                $DTMRI(mode,glyphsObject0) SetVolumePositionMatrix [t1 GetMatrix]
                t1 Delete
        
                $DTMRI(mode,glyphsObject0) SetInput $visSource
            }


            # Append glyphs
            #------------------------------------
        #Disconnect previous glyphs
        set prevnumInputs [DTMRI(vtk,glyphs,append) GetNumberOfInputs]
          for {set i 0} {$i < $prevnumInputs} {incr i} {
            DTMRI(vtk,glyphs,append) SetInputByNumber $i ""
          }     
            if {$slice != "None"} {
          set numInputs [llength $slice]
          DTMRI(vtk,glyphs,append) SetNumberOfInputs $numInputs
              foreach plane $slice {
            DTMRI(vtk,glyphs,append) SetInputByNumber [expr $plane%$numInputs] [$DTMRI(mode,glyphsObject$plane) GetOutput]
          }
        } else {
          set numInputs 1
          DTMRI(vtk,glyphs,append) SetNumberOfInputs $numInputs
          DTMRI(vtk,glyphs,append) SetInputByNumber 0 [$DTMRI(mode,glyphsObject0) GetOutput]
        }    
              
            # for lines don't use normals filter before mapper
        
         DTMRI(vtk,glyphs,mapper) SetInput \
         [DTMRI(vtk,glyphs,append) GetOutput]

            # Use axes or ellipsoids
            #------------------------------------
      set type stripper            
      foreach plane "0 1 2" {  
            switch $DTMRI(mode,glyphType) {
                "Axes" {
                    DTMRI(vtk,glyphs,$type) SetInput \
            [DTMRI(vtk,glyphs,axes) GetOutput]
                    #$DTMRI(mode,glyphsObject$plane) SetSource \
            #[DTMRI(vtk,glyphs,axes) GetOutput]
            
                    # this is too slow, but might make nice pictures
                    #[DTMRI(vtk,glyphs,tubeAxes) GetOutput]

                }
                "Lines" {
                    DTMRI(vtk,glyphs,$type) SetInput \
            [DTMRI(vtk,glyphs,line) GetOutput]
            #        $DTMRI(mode,glyphsObject$plane) SetSource \
            #[DTMRI(vtk,glyphs,line) GetOutput]

                }
                "Tubes" {
                    DTMRI(vtk,glyphs,$type) SetInput \
            [DTMRI(vtk,glyphs,tube) GetOutput]
                }
                "Ellipsoids" {            
                    DTMRI(vtk,glyphs,$type) SetInput \
            [DTMRI(vtk,glyphs,sphere) GetOutput]
                    #$DTMRI(mode,glyphsObject$plane) SetSource \
            #[DTMRI(vtk,glyphs,sphere) GetOutput]

                    # this normal filter improves display but is slow.
                    #DTMRI(vtk,glyphs,mapper) SetInput \
                    #    [DTMRI(vtk,glyphs,normals) GetOutput]
                    
                }
                "Boxes" {
                    DTMRI(vtk,glyphs,$type) SetInput \
            [DTMRI(vtk,glyphs,box) GetOutput]
                    #$DTMRI(mode,glyphsObject$plane) SetSource \
            #[DTMRI(vtk,glyphs,box) GetOutput]

                    # this normal filter improves display but is slow.
                    #DTMRI(vtk,glyphs,mapper) SetInput \
                    #    [DTMRI(vtk,glyphs,normals) GetOutput]
                }
        
           "Superquadric" {
                $DTMRI(mode,glyphsObject$plane) SetSource \
                 [DTMRI(vtk,glyphs,line) GetOutput]
                #DTMRI(vtk,glyphs,mapper) SetInput \
                #        [DTMRI(vtk,glyphs,normals) GetOutput] 
            }    
         }
         $DTMRI(mode,glyphsObject$plane) SetSource \
         [DTMRI(vtk,glyphs,stripper) GetOutput]
 
      }

            # in case this is the first time we load a tensor volume, 
            # place the actors in the scene now. (Now that there is input
            # to the pipeline this will not cause errors.)
            if {$DTMRI(glyphs,actorsAdded) == 0} {
                DTMRIAddAllActors
            }

            # Make actor visible
            #------------------------------------
            DTMRI(vtk,glyphs,actor) VisibilityOn

        }
        "Off" {
            puts "Turning off DTMRI visualization"

            # make invisible so output
            # not requested from pipeline anymore
            #------------------------------------
            DTMRI(vtk,glyphs,actor) VisibilityOff
        }
    }

    # make sure the scalars are updated (if we have anything displayed)
    if {$mode != "None" && $DTMRI(glyphs,actorsAdded)==1} {
        DTMRIUpdateGlyphScalarRange
    }
    # update 3D window (causes pipeline update)
    Render3D
}




