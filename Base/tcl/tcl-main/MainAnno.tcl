#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainAnno.tcl,v $
#   Date:      $Date: 2006/05/03 20:39:20 $
#   Version:   $Revision: 1.28 $
# 
#===============================================================================
# FILE:        MainAnno.tcl
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
proc MainAnnoInit {} {
    global Module Anno Gui

    # Define Procedures
    lappend Module(procStorePresets) MainAnnoStorePresets
    lappend Module(procRecallPresets) MainAnnoRecallPresets

        # Set version info
        lappend Module(versions) [ParseCVSInfo MainAnno \
        {$Revision: 1.28 $} {$Date: 2006/05/03 20:39:20 $}]

    # Preset Defaults
    set Module(Anno,presets) "box='1' axes='0' outline='0' letters='1' cross='0'\
hashes='1' mouse='1'"

    set Anno(box) 1
    set Anno(axes) 0
    set Anno(outline) 0
    set Anno(letters) 1
    set Anno(cross) 0
    set Anno(crossIntersect) 0
    set Anno(hashes) 1
    set Anno(mouse) 1

    set Anno(color) "1 1 0.5"
    set Anno(mmHashGap) 5
    set Anno(mmHashDist) 10
    set Anno(numHashes) 5
    set Anno(boxFollowFocalPoint) 1
    set Anno(axesFollowFocalPoint) 0
    set Anno(useCubeAxes) 0
    set Anno(cubeAxesRadius) 0.01
    set Anno(letterSize) 0.05
    set Anno(cursorMode) RAS
    set Anno(cursorModePrev) RAS
    # default display of floating point pixel values
    set Anno(pixelDispFormat) %.f

    # The display format of pixel for background and foreground 
    # could be different.
    set Anno(backPixelDispFormat) $Anno(pixelDispFormat) 
    set Anno(forePixelDispFormat) $Anno(pixelDispFormat)

    if {$Gui(smallFont) == 0} {
        set Anno(fontSize) 16
    } else {
        set Anno(fontSize) 14
    }

    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    set Anno(mouseList) "cur1 cur2 cur3 msg curBack curFore"
    set Anno(y256) "237 219 201 40 22 4"
    set Anno(y512) "492 474 456 40 22 4"
    # for MRT size
    set Anno(y160) "140 123 105 40 22 4"
    set Anno(y480) "460 443 423 40 22 4"

    # Orient anno: top bot left right
    #---------------------------------------------
    set Anno(orientList) "top bot right left"
    set Anno(orient,x256) "130 130 240 1"
    set Anno(orient,x512) "258 258 496 1"
    set Anno(orient,y256) "240 4 131 131"
    set Anno(orient,y512) "495 4 259 259"
    # for MRT
    set Anno(orient,x160) "78 78 144 1"
    set Anno(orient,y160) "144 4 82 82"
    set Anno(orient,x480) "241 241 464 1"
    set Anno(orient,y480) "464 4 242 242"
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoBuildVTK {} {
    global Gui Anno View Slice 

  
    #---------------------------------------------
    # 3D VIEW ANNO
    #---------------------------------------------

    set fov2 [expr $View(fov) / 2]

    #---------------------#
    # Bounding Box
    #---------------------#
    MakeVTKObject Outline box
    boxActor SetScale $fov2 $fov2 $fov2
    boxActor SetPickable 0
     [boxActor GetProperty] SetColor 1.0 0.0 1.0

    #---------------------#
    # Axes
    #---------------------#
    foreach axis "x y z" {
        if {$Anno(useCubeAxes) == 0} {
            vtkLineSource ${axis}Axis
            ${axis}Axis SetResolution 10
        } else {
            vtkCubeSource ${axis}Axis
        }

        vtkPolyDataMapper ${axis}AxisMapper
            ${axis}AxisMapper SetInput [${axis}Axis GetOutput]
        vtkActor ${axis}AxisActor
            ${axis}AxisActor SetMapper ${axis}AxisMapper
            ${axis}AxisActor SetScale $fov2 $fov2 $fov2
            ${axis}AxisActor SetPickable 0
            [${axis}AxisActor GetProperty] SetColor 1.0 0.0 1.0
            if {$Anno(useCubeAxes)} { [${axis}AxisActor GetProperty] SetOpacity 0.5 }
        MainAddActor ${axis}AxisActor
    }
    set pos  1.2
    set neg -1.2
    if {$Anno(useCubeAxes) == 0} {
        xAxis SetPoint1 $neg 0    0
        xAxis SetPoint2 $pos 0    0
        yAxis SetPoint1 0    $neg 0
        yAxis SetPoint2 0    $pos 0
        zAxis SetPoint1 0    0    $neg
        zAxis SetPoint2 0    0    $pos
    } else {
        xAxis SetBounds $neg $pos -$Anno(cubeAxesRadius) $Anno(cubeAxesRadius) -$Anno(cubeAxesRadius) $Anno(cubeAxesRadius)
        yAxis SetBounds -$Anno(cubeAxesRadius) $Anno(cubeAxesRadius) $neg $pos -$Anno(cubeAxesRadius) $Anno(cubeAxesRadius)
        zAxis SetBounds -$Anno(cubeAxesRadius) $Anno(cubeAxesRadius) -$Anno(cubeAxesRadius) $Anno(cubeAxesRadius) $neg $pos
    }

    #---------------------#
    # RAS axis labels
    #---------------------#    
    set scale [expr $View(fov) * $Anno(letterSize) ]

    foreach axis "R A S L P I" {
        vtkVectorText ${axis}Text
            ${axis}Text SetText "${axis}"
        vtkPolyDataMapper  ${axis}Mapper
            ${axis}Mapper SetInput [${axis}Text GetOutput]
        vtkFollower ${axis}Actor
            ${axis}Actor SetMapper ${axis}Mapper
            ${axis}Actor SetScale  $scale $scale $scale 
            ${axis}Actor SetPickable 0
            if {$View(bgName)=="White"} {
                [${axis}Actor GetProperty] SetColor 0 0 1
            } else {
                [${axis}Actor GetProperty] SetColor 1 1 1
            }
        [${axis}Actor GetProperty] SetDiffuse 0.0
        [${axis}Actor GetProperty] SetAmbient 1.0
        [${axis}Actor GetProperty] SetSpecular 0.0
        # add only to the Main View window
        viewRen AddActor ${axis}Actor

    }
    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActor SetPosition $pos 0.0  0.0
    AActor SetPosition 0.0  $pos 0.0
    SActor SetPosition 0.0  0.0  $pos 
    LActor SetPosition $neg 0.0  0.0
    PActor SetPosition 0.0  $neg 0.0
    IActor SetPosition 0.0  0.0  $neg 

    
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoBuildGUI {} {
    global Gui Anno View Slice
    
    #---------------------------------------------
    # SLICE ANNO
    #---------------------------------------------
    
    set Anno(actorList) ""
    
    # Line along distance being measured, and radii for arcs
    #---------------------------------------------
    foreach name "r1 r2" {
        foreach s $Slice(idList) {
            vtkLineSource Anno($s,$name,source)
            vtkPolyDataMapper2D Anno($s,$name,mapper)
                Anno($s,$name,mapper) SetInput \
                    [Anno($s,$name,source) GetOutput]
            vtkActor2D Anno($s,$name,actor)
                Anno($s,$name,actor) SetMapper \
                    Anno($s,$name,mapper)
                Anno($s,$name,actor) SetLayerNumber 1
                eval [Anno($s,$name,actor) GetProperty] \
                    SetColor $Anno(color)
                Anno($s,$name,actor) SetVisibility 0
            sl${s}Imager AddActor2D Anno($s,$name,actor)
        }
    }

    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    foreach name $Anno(mouseList) y256 $Anno(y256) y512 $Anno(y512) {    
        foreach s $Slice(idList) {
            vtkTextMapper Anno($s,$name,mapper)
                Anno($s,$name,mapper) SetInput ""
            if {[info commands vtkTextProperty] != ""} {
               [Anno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
               [Anno($s,$name,mapper) GetTextProperty] SetFontSize $Anno(fontSize)
               [Anno($s,$name,mapper) GetTextProperty] BoldOn
               [Anno($s,$name,mapper) GetTextProperty] ShadowOn
            } else {
                Anno($s,$name,mapper) SetFontFamilyToTimes
                Anno($s,$name,mapper) SetFontSize $Anno(fontSize)
                Anno($s,$name,mapper) BoldOn
                Anno($s,$name,mapper) ShadowOn
            }
            vtkActor2D Anno($s,$name,actor)
                Anno($s,$name,actor) SetMapper \
                    Anno($s,$name,mapper)
                Anno($s,$name,actor) SetLayerNumber 1
                eval [Anno($s,$name,actor) GetProperty] \
                    SetColor $Anno(color)
                Anno($s,$name,actor) SetVisibility 0
            sl${s}Imager AddActor2D Anno($s,$name,actor)
            [Anno($s,$name,actor) GetPositionCoordinate] \
                SetValue 1 $y256
        }
        set Anno($name,rect256) "1 $y256 40 [expr $y256+18]"
        set Anno($name,rect512) "1 $y512 40 [expr $y512+18]"
    }

    # Orient anno: top bot left right
    #---------------------------------------------
    foreach name $Anno(orientList) \
        x256 $Anno(orient,x256) x512 "$Anno(orient,x512)" y256 "$Anno(orient,y256)" y512 $Anno(orient,y512) {
            
        foreach s $Slice(idList) {
            vtkTextMapper Anno($s,$name,mapper)
                Anno($s,$name,mapper) SetInput ""
            if {[info commands vtkTextProperty] != ""} {
               [Anno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
               [Anno($s,$name,mapper) GetTextProperty] SetFontSize $Anno(fontSize)
               [Anno($s,$name,mapper) GetTextProperty] BoldOn
               [Anno($s,$name,mapper) GetTextProperty] ShadowOn
            } else {
                Anno($s,$name,mapper) SetFontFamilyToTimes
                Anno($s,$name,mapper) SetFontSize $Anno(fontSize)
                Anno($s,$name,mapper) BoldOn
                Anno($s,$name,mapper) ShadowOn
            }
            vtkActor2D Anno($s,$name,actor)
                Anno($s,$name,actor) SetMapper \
                    Anno($s,$name,mapper)
                Anno($s,$name,actor) SetLayerNumber 1
                eval [Anno($s,$name,actor) GetProperty] \
                    SetColor $Anno(color)
                Anno($s,$name,actor) SetVisibility 1 
            sl${s}Imager AddActor2D Anno($s,$name,actor)
            [Anno($s,$name,actor) GetPositionCoordinate] \
                SetValue $x256 $y256
        }
    }


    #---------------------#
    # Cameras 
    #---------------------#    

    # Make anno letters follow camera
    foreach axis "R A S L P I" {
        ${axis}Actor SetCamera $View(viewCam)
    }

}

#-------------------------------------------------------------------------------
# .PROC MainAnnoUpdateFocalPoint
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoUpdateFocalPoint {{xFP ""} {yFP ""} {zFP ""}} {
    global Anno View

    if {$xFP == ""} {
        set fp [$View(viewCam) GetFocalPoint]
        set xFP [lindex $fp 0]
        set yFP [lindex $fp 1]
        set zFP [lindex $fp 2]
    }

    if {$Anno(boxFollowFocalPoint) == 0} {
        boxActor SetPosition 0 0 0
    } else {
        boxActor SetPosition $xFP $yFP $zFP
    }

    if {$Anno(axesFollowFocalPoint) == 0} {
        set xFP 0
        set yFP 0
        set zFP 0
    }
    xAxisActor SetPosition $xFP $yFP $zFP
    yAxisActor SetPosition $xFP $yFP $zFP
    zAxisActor SetPosition $xFP $yFP $zFP

    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActor SetPosition [expr $pos+$xFP] $yFP  $zFP
    AActor SetPosition $xFP  [expr $pos+$yFP] $zFP
    SActor SetPosition $xFP  $yFP  [expr $pos+$zFP] 
    LActor SetPosition [expr $neg+$xFP] $yFP  $zFP
    PActor SetPosition $xFP  [expr $neg+$yFP] $zFP
    IActor SetPosition $xFP  $yFP  [expr $neg+$zFP] 
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetFov
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetFov {} {
    global Anno View

    set fov2 [expr $View(fov) / 2]
    foreach axis "x y z" {
        ${axis}AxisActor SetScale $fov2 $fov2 $fov2
    }
    boxActor SetScale $fov2 $fov2 $fov2

    set scale [expr $View(fov) * $Anno(letterSize) ]
    foreach axis "R A S L P I" {
        ${axis}Actor SetScale  $scale $scale $scale 
    }
    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActor SetPosition $pos 0.0  0.0
    AActor SetPosition 0.0  $pos 0.0
    SActor SetPosition 0.0  0.0  $pos 
    LActor SetPosition $neg 0.0  0.0
    PActor SetPosition 0.0  $neg 0.0
    IActor SetPosition 0.0  0.0  $neg 
}

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
proc MainAnnoSetVisibility {} {
    global Slice Anno AnnoEdit Anno

    boxActor SetVisibility $Anno(box)
    
    foreach u "x y z" {
        ${u}AxisActor  SetVisibility $Anno(axes)
    }
    foreach u "R A S L P I" {
        ${u}Actor      SetVisibility $Anno(letters)
    }

    # disable the cross intersection button if the cross hairs are not visible
    if {!$Anno(cross)} {
        $::Module(Anno,fVisibility).fVis.cCrossIntersect configure -state disabled
    } else {
        $::Module(Anno,fVisibility).fVis.cCrossIntersect configure -state active
    }

    MainAnnoSetCrossVisibility  slices $Anno(cross)
    MainAnnoSetHashesVisibility slices $Anno(hashes)
    MainAnnoSetCrossVisibility  mag    $Anno(cross)
    MainAnnoSetHashesVisibility mag    $Anno(hashes)

    foreach s $Slice(idList) {
        if {$Anno(outline) == 1} {
            Slice($s,outlineActor) SetVisibility $Slice($s,visibility)
        } else {
            Slice($s,outlineActor) SetVisibility 0
        } 
        foreach name "$Anno(orientList)" {
            Anno($s,$name,actor) SetVisibility $Anno(mouse) 
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetCrossVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetCrossVisibility {win vis} {
    global Slice

    Slicer SetShowCursor $vis
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetCrossIntersect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetCrossIntersect {} {
    global Anno
    Slicer SetCursorIntersect $Anno(crossIntersect)
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetHashesVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetHashesVisibility {win vis} {
    global Slice

    if {$vis == 1} {
        set vis 5
    }
    Slicer SetNumHashes $vis
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetColor
# SLICER DAVE not called
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetColor {color} {
    global Slice

    eval Slicer SetCursorColor $color
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoStorePresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoStorePresets {p} {
    global Preset Anno

    foreach key $Preset(Anno,keys) {
        set Preset(Anno,$p,$key) $Anno($key)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoRecallPresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoRecallPresets {p} {
    global Preset Anno

    foreach key $Preset(Anno,keys) {
        set Anno($key) $Preset(Anno,$p,$key)
    }
    MainAnnoSetVisibility
}


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
proc MainAnnoSetPixelDisplayFormat {mode} {
    global Anno

    switch $mode {
    "default" {
        set Anno(pixelDispFormat) %.f
    } 
    "decimal" {
        set Anno(pixelDispFormat) %6.2f
    } 
    "full" {        
        set Anno(pixelDispFormat) %f
    } 
    }
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoUpdateAxesPosition
# Updates the axes actor position from the current slicer RAS position.
# If inputs are not set, get the world point from the active slicer.
# .ARGS
# float rRas optional world coordinate
# float aRas optional world coordinate
# float sRas optional world coordinate
# .END
#-------------------------------------------------------------------------------
proc MainAnnoUpdateAxesPosition { {rRas ""} {aRas ""} {sRas ""} } {
    global Anno Interactor
    if {$Anno(axesFollowCrossHairs)} {
        if {$rRas == "" || $aRas == "" ||  $sRas == ""} {
            scan [$Interactor(activeSlicer) GetWldPoint] "%g %g %g" rRas aRas sRas 
        }
        xAxisActor SetPosition $rRas $aRas $sRas
        yAxisActor SetPosition $rRas $aRas $sRas
        zAxisActor SetPosition $rRas $aRas $sRas
    } else {
        MainAnnoUpdateFocalPoint
    }
}
