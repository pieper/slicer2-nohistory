#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareAnnoBug.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:23 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareAnnoBug.tcl
# PROCEDURES:  
#   MainAnnoInit
#   MainAnnoBuildVTK
#   MainAnnoBuildGUI
#   MainAnnoUpdateFocalPoint
#   MainAnnoSetFov
#   MainAnnoSetVisibility
#   MainAnnoSetCrossVisibility
#   MainAnnoSetCrossIntersect
#   MainAnnoSetHashesVisibility
#   MainAnnoSetColor
#   MainAnnoStorePresets
#   MainAnnoRecallPresets
#   MainAnnoSetPixelDisplayFormat mode
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainAnnoInit
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoInit {} {
    global Module CompareAnno Gui

    # Define Procedures
    # FIXME : removed but may be used in the future
    #lappend Module(procStorePresets) MainAnnoStorePresets
    #lappend Module(procRecallPresets) MainAnnoRecallPresets

        # Set version info
        #lappend Module(versions) [ParseCVSInfo MainAnno \
        #{$Revision: 1.2 $} {$Date: 2006/01/06 17:57:23 $}]

    # Preset Defaults

    # FIXME : removed all 3D related annotations

    set Module(CompareAnno,presets) "cross='0' hashes='1' mouse='1'"


    #set CompareAnno(mode) "2"
#    set CompareAnno(box) 1
#    set CompareAnno(axes) 0
#    set CompareAnno(outline) 0
#    set CompareAnno(letters) 1
    set CompareAnno(cross) 1
    set CompareAnno(crossIntersect) 0
    set CompareAnno(hashes) 1
    set CompareAnno(mouse) 1

    set CompareAnno(color) "1 1 0.5"
    set CompareAnno(mmHashGap) 5
    set CompareAnno(mmHashDist) 10
    set CompareAnno(numHashes) 5
#    set CompareAnno(boxFollowFocalPoint) 1
#    set CompareAnno(axesFollowFocalPoint) 0
    set CompareAnno(letterSize) 0.05
    set CompareAnno(cursorMode) RAS
    set CompareAnno(cursorModePrev) RAS
    # default display of floating point pixel values
    set CompareAnno(pixelDispFormat) %.f

    # The display format of pixel for background and foreground
    # could be different.
    set CompareAnno(backPixelDispFormat) $CompareAnno(pixelDispFormat)
    set CompareAnno(forePixelDispFormat) $CompareAnno(pixelDispFormat)

    if {$Gui(smallFont) == 0} {
        set CompareAnno(fontSize) 16
    } else {
        set CompareAnno(fontSize) 14
    }

    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    #set Anno(mouseList) "cur1 cur2 cur3 msg curBack curFore"
    # FIXME : changed the list to add other cursors, as I think curX is for
    # slice X
    # FIXME 2 : No! cur1, cur2 and cur3 are used to display RAS, IJK or XY coordinates!
    # -> removed other curX
    #set CompareAnno(mouseList) "cur1 cur2 cur3 cur4 cur5 cur6 cur7 cur8 cur9 msg curBack curFore"
    set CompareAnno(mouseList) "cur1 cur2 cur3 msg curBack curFore"
    # FIXME : the compare display assumes only 2 slices sizes. I think nothing is to be changed
    set CompareAnno(y256) "237 219 201 40 22 4"
    set CompareAnno(y512) "492 474 456 40 22 4"

    # Orient anno: top bot left right
    #---------------------------------------------
    set CompareAnno(orientList) "top bot right left"
    set CompareAnno(orient,x256) "130 130 240 1"
    set CompareAnno(orient,x512) "258 258 496 1"
    set CompareAnno(orient,y256) "240 4 131 131"
    set CompareAnno(orient,y512) "495 4 259 259"


}

#-------------------------------------------------------------------------------
# .PROC MainAnnoBuildVTK
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# FIXME : removed as create VTK objects related with 3D display
#proc MainAnnoBuildVTK {} {
#    global Gui Anno View Slice


    #---------------------------------------------
    # 3D VIEW ANNO
    #---------------------------------------------


#    set fov2 [expr $View(fov) / 2]

    #---------------------#
    # Bounding Box
    #---------------------#
#    MakeVTKObject Outline box
#    boxActor SetScale $fov2 $fov2 $fov2
#    boxActor SetPickable 0
#     [boxActor GetProperty] SetColor 1.0 0.0 1.0

    #---------------------#
    # Axes
    #---------------------#
#    foreach axis "x y z" {
#        vtkLineSource ${axis}Axis
#            ${axis}Axis SetResolution 10
#        vtkPolyDataMapper ${axis}AxisMapper
#            ${axis}AxisMapper SetInput [${axis}Axis GetOutput]
#        vtkActor ${axis}AxisActor
#            ${axis}AxisActor SetMapper ${axis}AxisMapper
#            ${axis}AxisActor SetScale $fov2 $fov2 $fov2
#            ${axis}AxisActor SetPickable 0
#            [${axis}AxisActor GetProperty] SetColor 1.0 0.0 1.0

#        MainAddActor ${axis}AxisActor
#    }
#    set pos  1.2
#    set neg -1.2
#    xAxis SetPoint1 $neg 0    0
#    xAxis SetPoint2 $pos 0    0
#    yAxis SetPoint1 0    $neg 0
#    yAxis SetPoint2 0    $pos 0
#    zAxis SetPoint1 0    0    $neg
#    zAxis SetPoint2 0    0    $pos

    #---------------------#
    # RAS axis labels
    #---------------------#
#    set scale [expr $View(fov) * $Anno(letterSize) ]

#    foreach axis "R A S L P I" {
#        vtkVectorText ${axis}Text
#            ${axis}Text SetText "${axis}"
#        vtkPolyDataMapper  ${axis}Mapper
#            ${axis}Mapper SetInput [${axis}Text GetOutput]
#        vtkFollower ${axis}Actor
#            ${axis}Actor SetMapper ${axis}Mapper
#            ${axis}Actor SetScale  $scale $scale $scale
#            ${axis}Actor SetPickable 0
#            if {$View(bgName)=="White"} {
#                [${axis}Actor GetProperty] SetColor 0 0 1
#            } else {
#                [${axis}Actor GetProperty] SetColor 1 1 1
#            }
#        [${axis}Actor GetProperty] SetDiffuse 0.0
#        [${axis}Actor GetProperty] SetAmbient 1.0
#        [${axis}Actor GetProperty] SetSpecular 0.0
        # add only to the Main View window
#        viewRen AddActor ${axis}Actor

#    }
#    set pos [expr   $View(fov) * 0.6]
#    set neg [expr - $View(fov) * 0.6]
#    RActor SetPosition $pos 0.0  0.0
#    AActor SetPosition 0.0  $pos 0.0
#    SActor SetPosition 0.0  0.0  $pos
#    LActor SetPosition $neg 0.0  0.0
#    PActor SetPosition 0.0  $neg 0.0
#    IActor SetPosition 0.0  0.0  $neg


#}

#-------------------------------------------------------------------------------
# .PROC MainAnnoBuildGUI
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc CompareAnnoBuildGUI {} {
#    global CompareAnno CompareSlice CompareMosaik
#
#    #---------------------------------------------
#    # SLICE ANNO
#    #---------------------------------------------
#
#    set CompareAnno(actorList) ""
#
#    # Line along distance being measured, and radii for arcs
#    #---------------------------------------------
#    set toUpdate [concat $CompareSlice(idList) $CompareMosaik(mosaikIndex)]
#
#    foreach name "r1 r2" {
#        #foreach s $CompareSlice(idList) {
#    foreach s $toUpdate {
#            vtkLineSource CompareAnno($s,$name,source)
#            vtkPolyDataMapper2D CompareAnno($s,$name,mapper)
#                CompareAnno($s,$name,mapper) SetInput \
#                    [CompareAnno($s,$name,source) GetOutput]
#            vtkActor2D CompareAnno($s,$name,actor)
#                CompareAnno($s,$name,actor) SetMapper \
#                    CompareAnno($s,$name,mapper)
#                CompareAnno($s,$name,actor) SetLayerNumber 1
#                eval [CompareAnno($s,$name,actor) GetProperty] \
#                    SetColor $CompareAnno(color)
#                CompareAnno($s,$name,actor) SetVisibility 0
#            slCompare${s}Imager AddActor2D CompareAnno($s,$name,actor)
#        }
#    }
#
#    # Cursor anno: RAS, Back & Fore pixels
#    #---------------------------------------------
#    foreach name $CompareAnno(mouseList) y256 $CompareAnno(y256) y512 $CompareAnno(y512) {
#
#    #foreach s $CompareSlice(idList) {
#    foreach s $toUpdate {
#            vtkTextMapper CompareAnno($s,$name,mapper)
#                CompareAnno($s,$name,mapper) SetInput ""
#            if {[info commands vtkTextProperty] != ""} {
#               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
#               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontSize $CompareAnno(fontSize)
#               [CompareAnno($s,$name,mapper) GetTextProperty] BoldOn
#               [CompareAnno($s,$name,mapper) GetTextProperty] ShadowOn
#            } else {
#                CompareAnno($s,$name,mapper) SetFontFamilyToTimes
#                CompareAnno($s,$name,mapper) SetFontSize $CompareAnno(fontSize)
#                CompareAnno($s,$name,mapper) BoldOn
#                CompareAnno($s,$name,mapper) ShadowOn
#            }
#            vtkActor2D CompareAnno($s,$name,actor)
#                CompareAnno($s,$name,actor) SetMapper \
#                    CompareAnno($s,$name,mapper)
#                CompareAnno($s,$name,actor) SetLayerNumber 1
#                eval [CompareAnno($s,$name,actor) GetProperty] \
#                    SetColor $CompareAnno(color)
#                CompareAnno($s,$name,actor) SetVisibility 0
#            slCompare${s}Imager AddActor2D CompareAnno($s,$name,actor)
#
#            [CompareAnno($s,$name,actor) GetPositionCoordinate] \
#                SetValue 1 $y256
#        }
#        set CompareAnno($name,rect256) "1 $y256 40 [expr $y256+18]"
#        set CompareAnno($name,rect512) "1 $y512 40 [expr $y512+18]"
#    }
#
#    # Orient anno: top bot left right
#    #---------------------------------------------
#    foreach name $CompareAnno(orientList) \
#        x256 $CompareAnno(orient,x256) x512 "$CompareAnno(orient,x512)" y256 \
#    "$CompareAnno(orient,y256)" y512 $CompareAnno(orient,y512) {
#
#        #foreach s $CompareSlice(idList) {
#    foreach s $toUpdate {
#            vtkTextMapper CompareAnno($s,$name,mapper)
#                CompareAnno($s,$name,mapper) SetInput ""
#            if {[info commands vtkTextProperty] != ""} {
#               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
#               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontSize $CompareAnno(fontSize)
#               [CompareAnno($s,$name,mapper) GetTextProperty] BoldOn
#               [CompareAnno($s,$name,mapper) GetTextProperty] ShadowOn
#            } else {
#                CompareAnno($s,$name,mapper) SetFontFamilyToTimes
#                CompareAnno($s,$name,mapper) SetFontSize $CompareAnno(fontSize)
#                CompareAnno($s,$name,mapper) BoldOn
#                CompareAnno($s,$name,mapper) ShadowOn
#            }
#            vtkActor2D CompareAnno($s,$name,actor)
#                CompareAnno($s,$name,actor) SetMapper \
#                    CompareAnno($s,$name,mapper)
#                CompareAnno($s,$name,actor) SetLayerNumber 1
#                eval [CompareAnno($s,$name,actor) GetProperty] \
#                    SetColor $CompareAnno(color)
#                CompareAnno($s,$name,actor) SetVisibility 1
#            slCompare${s}Imager AddActor2D CompareAnno($s,$name,actor)
#            [CompareAnno($s,$name,actor) GetPositionCoordinate] \
#                SetValue $x256 $y256
#        }
#    }
#}

#-------------------------------------------------------------------------------
# .PROC MainAnnoUpdateFocalPoint
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# FIXME : removed (3D)
#proc MainAnnoUpdateFocalPoint {{xFP ""} {yFP ""} {zFP ""}} {
#    global Anno View
#
#    if {$xFP == ""} {
#        set fp [$View(viewCam) GetFocalPoint]
#        set xFP [lindex $fp 0]
#        set yFP [lindex $fp 1]
#        set zFP [lindex $fp 2]
#    }
#
#    if {$Anno(boxFollowFocalPoint) == 0} {
#        boxActor SetPosition 0 0 0
#    } else {
#        boxActor SetPosition $xFP $yFP $zFP
#    }
#
#    if {$Anno(axesFollowFocalPoint) == 0} {
#        set xFP 0
#        set yFP 0
#        set zFP 0
#    }
#  xAxisActor SetPosition $xFP $yFP $zFP
#    yAxisActor SetPosition $xFP $yFP $zFP
#   zAxisActor SetPosition $xFP $yFP $zFP
#
#   set pos [expr   $View(fov) * 0.6]
#   set neg [expr - $View(fov) * 0.6]
#   RActor SetPosition [expr $pos+$xFP] $yFP  $zFP
#   AActor SetPosition $xFP  [expr $pos+$yFP] $zFP
#   SActor SetPosition $xFP  $yFP  [expr $pos+$zFP]
#  LActor SetPosition [expr $neg+$xFP] $yFP  $zFP
#   PActor SetPosition $xFP  [expr $neg+$yFP] $zFP
#   IActor SetPosition $xFP  $yFP  [expr $neg+$zFP]
#

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetFov
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# FIXME : removed (3D)
#proc MainAnnoSetFov {} {
#   global Anno View
#
#   set fov2 [expr $View(fov) / 2]
#   foreach axis "x y z" {
#       ${axis}AxisActor SetScale $fov2 $fov2 $fov2
#   }
#   boxActor SetScale $fov2 $fov2 $fov2
#
#  set scale [expr $View(fov) * $Anno(letterSize) ]
#   foreach axis "R A S L P I" {
#       ${axis}Actor SetScale  $scale $scale $scale
#   }
#   set pos [expr   $View(fov) * 0.6]
#   set neg [expr - $View(fov) * 0.6]
#   RActor SetPosition $pos 0.0  0.0
#   AActor SetPosition 0.0  $pos 0.0
#   SActor SetPosition 0.0  0.0  $pos
#   LActor SetPosition $neg 0.0  0.0
#   PActor SetPosition 0.0  $neg 0.0
#   IActor SetPosition 0.0  0.0  $neg
#}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetVisibility
#
# Checks the Anno Array and sets visibility of the following objects
#   The cube in the 3D scene
#   The Axes in the 3D scene
#   The letters in the 3D scene (RASLPI)
#   The outline around the slices in the 3D scene
#   The Cross Hairs in the 2D scene
#   The Hash Marks on the Cross Hairs in the 2D scene
#   The Letters in the 2D scene.
#   Everything in Slice(idlist)
#
# Visibility is set using the vtkActor Setvisibility command.
#
# usage: MainAnnoSetVisibility
# .END
#-------------------------------------------------------------------------------
# FIXME : removed 3D related calls and settings
proc CompareAnnoSetVisibility {} {
    # FIXME : changed ; don't want editing related calls and settings
    #global Slice Anno AnnoEdit Anno
    global CompareSlice CompareAnno CompareMosaik

    CompareAnnoSetCrossVisibility  slices $CompareAnno(cross)
    CompareAnnoSetHashesVisibility slices $CompareAnno(hashes)

    #set toUpdate [concat $CompareSlice(idList) $CompareMosaik(mosaikIndex)]

    foreach s $CompareSlice(idList) {
        #foreach s $toUpdate {
        # FIXME : removed (3D slice outlines)
        #if {$Anno(outline) == 1} {
        #    Slice($s,outlineActor) SetVisibility $Slice($s,visibility)
        #} else {
        #    Slice($s,outlineActor) SetVisibility 0
        #}
        foreach name "$CompareAnno(orientList)" {
            CompareAnno($s,$name,actor) SetVisibility $CompareAnno(mouse)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetCrossVisibility
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetCrossVisibility {win vis} {
    global SlicerLight

    SlicerLight SetShowCursor $vis
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetCrossIntersect
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetCrossIntersect {} {
    global SlicerLight CompareAnno

    SlicerLight SetCursorIntersect $CompareAnno(crossIntersect)
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetHashesVisibility
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetHashesVisibility {win vis} {
    global SlicerLight

    if {$vis == 1} {
        set vis 5
    }
    SlicerLight SetNumHashes $vis
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetColor
# SLICER DAVE not called
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetColor {color} {
    global SlicerLight

    eval SlicerLight SetCursorColor $color
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoStorePresets
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# TODO : manage presets in the future
#proc AnnoStorePresets {p} {
#    global Preset Anno
#
#    foreach key $Preset(Anno,keys) {
#        set Preset(Anno,$p,$key) $Anno($key)
#    }
#}

#-------------------------------------------------------------------------------
# .PROC MainAnnoRecallPresets
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# TODO : manage presets in the future
#proc MainAnnoRecallPresets {p} {
#    global Preset Anno
#
#    foreach key $Preset(Anno,keys) {
#        set Anno($key) $Preset(Anno,$p,$key)
#    }
#    MainAnnoSetVisibility
#}


#-------------------------------------------------------------------------------
# .PROC MainAnnoSetPixelDisplayFormat
#  Set the display formatting used when the pixel values
# are shown above the 2D slices.  Options are int display,
# two decimal points, or full floating-point display.
# This procedure is here in case a module in the slicer
# wants to set things up to view non-standard data, say floats.
#
# FUTURE IDEAS:
# It would be nice if this sort of setting could be pushed/
# popped like the bindings stack that Peter wrote (Events.tcl).
# This would allow modules to control the visualization
# but not interfere with other modules.
# .ARGS
# str mode can be default, decimal, or full
# .END
#-------------------------------------------------------------------------------
# TODO : manage display mode with buttons (like general annotations)
proc CompareAnnoSetPixelDisplayFormat {mode} {
    global CompareAnno

    switch $mode {
    "default" {
        set CompareAnno(pixelDispFormat) %.f
    }
    "decimal" {
        set CompareAnno(pixelDispFormat) %6.2f
    }
    "full" {
        set CompareAnno(pixelDispFormat) %f
    }
    }
}
