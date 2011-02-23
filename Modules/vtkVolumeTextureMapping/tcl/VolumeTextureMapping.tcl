#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolumeTextureMapping.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:08 $
#   Version:   $Revision: 1.8 $
# 
#===============================================================================
# FILE:        VolumeTextureMapping.tcl
# PROCEDURES:  
#   VolumeTextureMappingInit
#   VolumeTextureMappingBuildGUI
#   changeDim f dir dim
#   getColor f
#   gradImage w
#   ClipVolumes
#   CheckLines
#   ChangeRotDir f
#   RotateClipPlanePlane f angle
#   DistanceClipPlanePlane f distance
#   SetClipPlaneType
#   SpacingClipPlane f spacing
#   ChangeVolumeDim f
#   NumberOfPlanes planes
#   defaultPoints f
#   getPointX
#   getPointY
#   ChangeVolume f
#   TFPoints f
#   TFInteractions f
#   menuPopLine f x y x2 y2
#   menuPopPoint f x y x2 y2
#   holdOverLine f x y
#   leaveLine f
#   createHistLine f
#   createTFLine f
#   holdOverPoint f x y
#   leavePoint f
#   setValues f x y
#   addPoint f
#   removePoint f
#   clickOnPoint volume f x y
#   releasePoint volume f x y
#   movePoint f x y
#   ChangeTransformMatrix
#   VolumeTextureMappingBuildVTK
#   VolumeTextureMappingRefresh
#   VolumeTextureMappingCameraMotion
#   VolumeTextureMappingEnter
#   VolumeTextureMappingExit
#   VolumeTextureMappingUpdateMRML
#   VolumeTextureMappingSetOriginal1 v
#   VolumeTextureMappingSetOriginal2 v
#   VolumeTextureMappingSetOriginal3 v
#   VolumeTextureMappingStorePresets p
#   VolumeTextureMappingRecallPresets p
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
#
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are (some of) the variables defined by this module.
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingInit {} {
    global VolumeTextureMapping Module Volume Model prog 
    
    set m VolumeTextureMapping


    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "3D Texture Mapping, volume rendering."
    set Module($m,author) "Frida Hernell, Link÷ping University"
#    set Module($m,category) "Visualisation"
    set Module($m,category) "Alpha"
    set Module($m,row1List) "Help Settings Transfer Clip"
    set Module($m,row1Name) "{Help} {Settings} {Transfer Functions} {Clip}"
    set Module($m,row1,tab) Settings
    set Module($m,procGUI) VolumeTextureMappingBuildGUI
    set Module($m,procEnter) VolumeTextureMappingEnter
    set Module($m,procExit) VolumeTextureMappingExit
    set Module($m,procVTK) VolumeTextureMappingBuildVTK
    set Module($m,procMRML) VolumeTextureMappingUpdateMRML
    set Module($m,procCameraMotion) VolumeTextureMappingCameraMotion

    lappend Module(procStorePresets) VolumeTextureMappingStorePresets
    lappend Module(procRecallPresets) VolumeTextureMappingRecallPresets
    set Module(VolumeTextureMapping,presets) "idOriginal1='0' idOriginal2='0' idOriginal3='0' hideOnExit='1' " 
    set Module($m,depend) ""

    set VolumeTextureMapping(idOriginal1)  $Volume(idNone)
    set VolumeTextureMapping(idOriginal2)  $Volume(idNone)
    set VolumeTextureMapping(idOriginal3)  $Volume(idNone)

    set VolumeTextureMapping(transferFunctionSaveFileName) "$prog/cttrffunc.xml"
    set VolumeTextureMapping(transferFunctionReadFileName) "$prog/cttrffunc.xml"
    set VolumeTextureMapping(hideOnExit) "1"
    set VolumeTextureMapping(volumeVisible) "0"
    set VolumeTextureMapping(currentVolume) "volume1"

    set VolumeTextureMapping(contents) "VolumeTextureMappingTransferFunctions"
    set VolumeTextureMapping(eventManager)  {  }


}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingBuildGUI
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingBuildGUI {} {
    global Gui VolumeTextureMapping Module Volume Model env
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    #    set help "
    #    The VolumeTextureMapping module is under heavy development."

    set help "
Volume rendering developed by Frida Hernell, CMIV (Link÷ping university).
<P>
Description by tabs:
<P><B>Settings:</B><BR>
<UL>
<LI>Set which volumes to use in volume 1, volume 2 and volume 3. 
<LI>Set the texture dimension if other than default is wanted. If a texture dimension is set to a higher value then the data dimension then it will automatically be decreased. Choose which volume to affect with the radio buttons.
<LI>Press Refresh View to render the volumes in the viewport.
<LI>Change the amount of planes with the slider. Many planes give a detailed rendering but can become slow to interact with.
</UL>
<P><B>Transfer functions:</B><BR>
<UL>
<LI>Set a color palette in Volumes -> Display  
            <LI> Change the opacity function in the graph moving the points.  
</UL>
<P><B>Clip:</B><BR>
<UL>
<LI>Choose which volumes to clip with the check boxes.
<LI>Choose which typ of clipping to use. Single uses one plane, double uses two planes and cube uses six planes in order to form a cube.
<LI>The check box Lines can be choosen in order to se the clip planes.
<LI>Choose which axis to rotate arround.
<LI>Choose how much to rotate with the slider.
<LI>Choose how far from origo the clip plane will be placed with the slider Distance from origin
<LI>If the clip types double or cube are choosen than the slider Spacing between planes can be used. 
</UL>
"


    regsub -all "\n" $help {} help
    MainHelpApplyTags VolumeTextureMapping $help
    MainHelpBuildGUI VolumeTextureMapping
    
    #-------------------------------------------
    # Settings frame
    #-------------------------------------------
    set fSettings $Module(VolumeTextureMapping,fSettings)
    set f $fSettings

    foreach frame "RefreshSettings Planes " {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad)
    }
    foreach frame "Volume Dimension Buttons" {
    frame $f.fRefreshSettings.f$frame -bg $Gui(activeWorkspace)
    pack $f.fRefreshSettings.f$frame -side top -padx 0 -pady $Gui(pad)
    }
    

    #-------------------------------------------
    # Settings->RefreshSettings
    #-------------------------------------------
    set f $fSettings.fRefreshSettings
    $f config -relief groove -bd 3 -width 500


    #-------------------------------------------
    # Settings->Volume frame
    #-------------------------------------------
    set f $fSettings.fRefreshSettings.fVolume
    
    # Add menus that list models and volumes
    DevAddSelectButton VolumeTextureMapping $f Original1 "Volume1" Grid

    # Add menus that list models and volumes
    DevAddSelectButton VolumeTextureMapping $f Original2 "Volume2" Grid

    # Add menus that list models and volumes
    DevAddSelectButton VolumeTextureMapping $f Original3 "Volume3" Grid


    #-------------------------------------------
    # Settings->Dimension frame
    #-------------------------------------------
    set f $fSettings.fRefreshSettings.fDimension
    
    frame $f.fChooseVol -bg $Gui(activeWorkspace)
    foreach i {volume1 volume2 volume3} {
        eval {radiobutton $f.fChooseVol.$i -text $i -value $i -variable VolumeTextureMapping(currentVolume) -relief flat -value $i -bg $Gui(activeWorkspace) -command "ChangeVolumeDim $f" } $Gui(WCA)
        pack $f.fChooseVol.$i -side left -padx 2 
     }
     pack $f.fChooseVol -side top -padx 0 -pady $Gui(pad)
    
    label $f.dims -justify left -text "Texture dimension" -bg $Gui(activeWorkspace)
    pack $f.dims -side top -pady 2
    set lab "L"
    foreach dir "x y z" {
        label $f.dim$dir$lab -justify left -text "$dir:" -bg $Gui(activeWorkspace)
        pack $f.dim$dir$lab -side left
        menubutton $f.dim$dir -text "--" -menu $f.dim$dir.$dir -bg $Gui(activeWorkspace)
        $f.dim$dir config -relief groove -bd 3 
        menu $f.dim$dir.$dir 
        foreach dims "16 32 64 128 256" {
            $f.dim$dir.$dir add command -label "$dims" -underline 0 -command "changeDim $f.dim$dir $dir $dims"
        }
        pack $f.dim$dir -side left -padx 4
    }
    
    
    #-------------------------------------------
    # Settings->Buttons frame
    #-------------------------------------------
    set f $fSettings.fRefreshSettings.fButtons

    DevAddButton $f.bRefresh {Refresh View} VolumeTextureMappingRefresh
    DevAddLabel $f.lWarning {(Not working with all video cards.)} 
    pack $f.bRefresh -side top
    pack $f.lWarning
  


    #-------------------------------------------
    # Settings->Planes frame
    #-------------------------------------------
    set f $fSettings.fPlanes

    label $f.lplanes -justify left -text "Amount of planes" -bg $Gui(activeWorkspace)
    pack $f.lplanes -side top

    scale $f.sscalePlanes -orient horizontal -from 0 -to 1500 -tickinterval 0 -length 200 -showvalue true -bg $Gui(activeWorkspace) -command NumberOfPlanes 
    pack $f.sscalePlanes -side top
    $f.sscalePlanes set 700
    
    #-------------------------------------------
    # Transfer frame
    #-------------------------------------------
    set fTransfer $Module(VolumeTextureMapping,fTransfer)
    set f $fTransfer
    
    VolumeTextureMapping(texturevolumeMapper) IniatializeColors
    foreach frame "TFVolume TFVolume1" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    foreach frame "Buttons IO" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad)
    }

    #-------------------------------------------
    # Transfer->TFVolume frame
    #-------------------------------------------
    set f $fTransfer.fTFVolume
    $f config -relief groove -bd 3 

    foreach i {volume1 volume2 volume3} {
    radiobutton $f.b$i -text $i -variable VolumeTextureMapping(currentVolume) -relief flat -value $i -bg $Gui(activeWorkspace) -command "ChangeVolume f" 
    pack $f.b$i -side left -padx 2 
    }

    #-------------------------------------------
    # Transfer->TFVolume1 frame
    #-------------------------------------------
    set f $fTransfer.fTFVolume1
    
    frame $f.graph -bg $Gui(activeWorkspace)
            
    canvas $f.graph.canvas1 -relief raised -width 216 -height 106 -bg $Gui(activeWorkspace)
    $f.graph.canvas1 create polygon 2 2 216 2 216 106 2 106 -fill white -outline black -width 1
    pack $f.graph.canvas1 -side top -pady 2

    set grad1 [gradImage 10]
    canvas $f.graph.gradient1 -bd 0 -highlightthickness 0 -height 10 -width 216 
    $f.graph.gradient1 create image 0 0 -anchor nw -image $grad1 -tag grad1 
    pack $f.graph.gradient1 -side top -pady 2

    pack $f.graph -side top



    global .menuPoint .menuLine
    menu .menuPoint
    menu .menuLine
    defaultPoints $f.graph.canvas1
        

    #-------------------------------------------
    # Clip frame
    #-------------------------------------------
    set fClip $Module(VolumeTextureMapping,fClip)
    set f $fClip
    global lastDir
    global lastAngle
    set lastDir -1
    set lastAngle 0
    VolumeTextureMapping(texturevolumeMapper) InitializeClipPlanes

    foreach frame "Volumes Type Rotation Distance Planes" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad)
    }
    
    #-------------------------------------------
    # Clip->Volumes
    #-------------------------------------------
    set f $fClip.fVolumes
    $f config -relief groove -bd 3 
    
    frame $f.cvolumes -bg $Gui(activeWorkspace)
    foreach i {"volume1" "volume2" "volume3"} {
    checkbutton $f.cvolumes.p$i -relief flat -variable $i -bg $Gui(activeWorkspace) -command ClipVolumes
    pack $f.cvolumes.p$i -side left -padx 2
    label $f.cvolumes.l$i -justify left -text $i -bg $Gui(activeWorkspace)
    pack $f.cvolumes.l$i -side left -padx 2
    }
    pack $f.cvolumes -side top

    
    #-------------------------------------------
    # Clip->Type
    #-------------------------------------------
    set f $fClip.fType

    frame $f.type -bg $Gui(activeWorkspace)
    foreach i {single double cube} {
    radiobutton $f.type.b$i -text $i -variable planetype -relief flat -value $i -bg $Gui(activeWorkspace) -command SetClipPlaneType
    pack $f.type.b$i -side left -padx 2 
    }
    pack $f.type -side top
    
    frame $f.lines -bg $Gui(activeWorkspace)
    checkbutton $f.lines.clines -text "Lines" -variable "lines" -command CheckLines -bg $Gui(activeWorkspace)
    pack $f.lines.clines -side left -padx 2
    pack $f.lines -side top



    #-------------------------------------------
    # Clip->Rotation
    #-------------------------------------------
    set f $fClip.fRotation
    $f config -relief groove -bd 3
    
    label $f.lrotate -justify left -text "Rotation" -bg $Gui(activeWorkspace)
    pack $f.lrotate -side top
    
    global rotDir

    frame $f.rot -borderwidth 10 -bg $Gui(activeWorkspace)
    image create photo rX -file [file join $env(SLICER_HOME) Modules vtkVolumeTextureMapping images rX.gif]
    radiobutton $f.rot.c1 -image rX -selectimage rX    -indicatoron 0 -bg $Gui(activeWorkspace) -variable rotDir -value "x" -command "ChangeRotDir $f"
    pack $f.rot.c1 -side left

    image create photo rY -file [file join $env(SLICER_HOME) Modules vtkVolumeTextureMapping images rY.gif] 
    radiobutton $f.rot.c2 -image rY -selectimage rY    -indicatoron 0 -bg $Gui(activeWorkspace) -variable rotDir -value "y" -command "ChangeRotDir $f"
    pack $f.rot.c2 -side left

    image create photo rZ -file [file join $env(SLICER_HOME) Modules vtkVolumeTextureMapping images rZ.gif] 
    radiobutton $f.rot.c3 -image rZ -selectimage rZ    -indicatoron 0 -bg $Gui(activeWorkspace) -variable rotDir -value "z" -command "ChangeRotDir $f"
    pack $f.rot.c3 -side left

    pack $f.rot -side top

    scale $f.sscale -orient horizontal -from -180 -to 180 -tickinterval 0 -length 200 -showvalue true -bg $Gui(activeWorkspace) -command "RotateClipPlanePlane $f"
    pack $f.sscale -side top
    $f.sscale set 0
    
    #-------------------------------------------
    # Clip->Distance
    #-------------------------------------------
    set f $fClip.fDistance
    $f config -relief groove -bd 3

    label $f.ldist -justify left -text "Distance from origin" -bg $Gui(activeWorkspace)
    pack $f.ldist -side top

    scale $f.sdist -orient horizontal -from -128 -to 128 -tickinterval 0 -length 200 -showvalue true -bg $Gui(activeWorkspace) -command "DistanceClipPlanePlane $f"
    pack $f.sdist -side top
    $f.sdist set 0

    label $f.lspace -justify left -text "Spacing between planes" -bg $Gui(activeWorkspace)
    pack $f.lspace -side top
    
    global xangle yangle zangle
    set xangle 0
    set yangle 0
    set zangle 0
    
    scale $f.sspace -orient horizontal -from 0 -to 256 -length 200 -tickinterval 0 -showvalue true -bg $Gui(activeWorkspace) -command "SpacingClipPlane $f"
    pack $f.sspace -side top
    $f.sspace set 64
}

#-------------------------------------------------------------------------------
# .PROC changeDim
# 
# .ARGS
# windowpath f
# path dir
# string dim
# .END
#-------------------------------------------------------------------------------
proc changeDim {f dir dim} {
    global VolumeTextureMapping
    $f configure -text $dim
    if {[string compare $dir "x"] == 0} {
        set d 0
    } elseif {[string compare $dir "y"] == 0} {
        set d 1
    } elseif {[string compare $dir "z"] == 0} {
        set d 2
    }
    if {[string compare $VolumeTextureMapping(currentVolume) "volume1"] == 0} {
        set thisVol 0
    } elseif {[string compare $VolumeTextureMapping(currentVolume) "volume2"] == 0} {
        set thisVol 1
    } elseif {[string compare $VolumeTextureMapping(currentVolume) "volume3"] == 0} {
        set thisVol 2
    }
    VolumeTextureMapping(texturevolumeMapper) SetDimension $thisVol $d $dim
}



#-------------------------------------------------------------------------------
# .PROC getColor
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc getColor {f} {

    set grad1 [gradImage 10]
    $f.graph.gradient1 delete all
    $f.graph.gradient1 create image 0 0 -anchor nw -image $grad1 -tag grad1
    
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC gradImage
# 
# .ARGS
# int w optional
# .END
#-------------------------------------------------------------------------------
proc gradImage {{w}} {
 global currentVolume Volume VolumeTextureMapping

 set im [image create photo -width 216 -height $w]
    
    if {[info exists currentVolume] == 1 && $VolumeTextureMapping(idOriginal[expr $currentVolume+1]) != $Volume(idNone)} {
        set lutName [Volume($VolumeTextureMapping(idOriginal[expr $currentVolume+1]),node) GetLUTName]    
    } else {
        set lutName 0
    }

    for {set i 0; set j 1} {$i < 216} {incr i; incr j} {
        
        set rgba [Lut($lutName,lut) GetTableValue [expr $i*256/216]]
        set r [expr {round ([expr [lindex $rgba 0] * 255])}]
        set g [expr {round ([expr [lindex $rgba 1] * 255])}]
        set b [expr {round ([expr [lindex $rgba 2] * 255])}]

        set x [format %2.2x $r]
        set y [format %2.2x $g]
        set z [format %2.2x $b]
        $im put "#${x}${y}${z}" -to $i 0 $j $w    
    }
    return $im
}

#-------------------------------------------------------------------------------
# .PROC ClipVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ClipVolumes {} {
    global volume1 volume2 volume3
    if {$volume1} {
    set num 0
    VolumeTextureMapping(texturevolumeMapper) VolumesToClip $num 1
    } else {
    set num 0
    VolumeTextureMapping(texturevolumeMapper) VolumesToClip $num 0
    } 
    if {$volume2} {
    set num 1
    VolumeTextureMapping(texturevolumeMapper) VolumesToClip $num 1
    } else {
    set num 1
    VolumeTextureMapping(texturevolumeMapper) VolumesToClip $num 0
    }
    
    if {$volume3} {
    set num 2
    VolumeTextureMapping(texturevolumeMapper) VolumesToClip $num 1
    } else {
    set num 2
    VolumeTextureMapping(texturevolumeMapper) VolumesToClip $num 0
    }
    
    
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
    
    
}

#-------------------------------------------------------------------------------
# .PROC CheckLines
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CheckLines {} {
    global lines
    if {$lines} {
    VolumeTextureMapping(texturevolumeMapper) EnableClipLines 1    
    } else {
    VolumeTextureMapping(texturevolumeMapper) EnableClipLines 0    
    }
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC ChangeRotDir
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc ChangeRotDir {f} {
    global xangle yangle zangle rotDir lastDir lastAngle
    
    
    
    if {[string compare $rotDir "x"] == 0} {
     set dir 0
    } elseif {[string compare $rotDir "y"] == 0} {
     set dir 1
    } elseif {[string compare $rotDir "z"] == 0} {
     set dir 2
    }
    
    if {$lastDir != $dir} {    
    if {$lastDir == 0} {
        set xangle $lastAngle
        
    } elseif {$lastDir == 1} {
        set yangle $lastAngle
        
    } else {
        set zangle $lastAngle    
    }
    
    if {$dir == 0} {
        $f.sscale set $xangle
    } elseif {$dir == 1} {
        $f.sscale set $yangle
    } else {
        $f.sscale set $zangle
    }
    }
}

#-------------------------------------------------------------------------------
# .PROC RotateClipPlanePlane
# 
# .ARGS
# windowpath f
# float angle
# .END
#-------------------------------------------------------------------------------
proc RotateClipPlanePlane {f angle} {
    global lastDir lastAngle rotDir
    
    set dir 0
    if {[string compare $rotDir "x"] == 0} {
    set dir 0
    } elseif {[string compare $rotDir "y"] == 0} {
    set dir 1
    } elseif {[string compare $rotDir "z"] == 0} {
    set dir 2
    }    
    
    VolumeTextureMapping(texturevolumeMapper) ChangeClipPlaneDir 0 $dir $angle
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
    
    set lastDir $dir
    set lastAngle $angle
    
}

#-------------------------------------------------------------------------------
# .PROC DistanceClipPlanePlane
# 
# .ARGS
# windowpath f
# float distance
# .END
#-------------------------------------------------------------------------------
proc DistanceClipPlanePlane {f distance} {
    VolumeTextureMapping(texturevolumeMapper) ChangeDist 0 $distance
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC SetClipPlaneType
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SetClipPlaneType {} {
    global planetype Module
    if {[string compare $planetype "single"] == 0} {
    set currentType 0
     } elseif {[string compare $planetype "double"] == 0} {
    set currentType 1
    } elseif {[string compare $planetype "cube"] == 0} {
    set currentType 2
    }
    VolumeTextureMapping(texturevolumeMapper) ChangeType $currentType
    for {set num 0} {$num < 3} {incr num} {
    VolumeTextureMapping(texturevolumeMapper) ChangeClipPlaneDir 0 $num 0
    }
    set fClip $Module(VolumeTextureMapping,fClip)
    set f $fClip.fRotation
    $f.sscale set 0
    
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC SpacingClipPlane
# 
# .ARGS
# windowpath f
# float spacing
# .END
#-------------------------------------------------------------------------------
proc SpacingClipPlane {f spacing} {
    VolumeTextureMapping(texturevolumeMapper) ChangeSpacing $spacing
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC ChangeVolumeDim
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc ChangeVolumeDim {f} {
    global VolumeTextureMapping Module 
    if {[string compare $VolumeTextureMapping(currentVolume) "volume1"] == 0} {
    set thisVolume 0
    } elseif {[string compare $VolumeTextureMapping(currentVolume) "volume2"] == 0} {
    set thisVolume 1
    } elseif {[string compare $VolumeTextureMapping(currentVolume) "volume3"] == 0} {
    set thisVolume 2
    }
    #get volumedimensions for a specific dataset
    $f.dimx configure -text [VolumeTextureMapping(texturevolumeMapper) GetTextureDimension $thisVolume 0]
    $f.dimy configure -text [VolumeTextureMapping(texturevolumeMapper) GetTextureDimension $thisVolume 1]
    $f.dimz configure -text [VolumeTextureMapping(texturevolumeMapper) GetTextureDimension $thisVolume 2]
}

#-------------------------------------------------------------------------------
# .PROC NumberOfPlanes
# 
# .ARGS
# int planes
# .END
#-------------------------------------------------------------------------------
proc NumberOfPlanes {planes} {
    VolumeTextureMapping(texturevolumeMapper) SetNumberOfPlanes $planes
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
}



#-------------------------------------------------------------------------------
# .PROC defaultPoints
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc defaultPoints {f} {
    global currentVolume newVolume colorLine opacityLine histLine .menuPoint .menuLine 
    set currentVolume 0 
    set newVolume 0
    
    set colorLine [$f create line 0 0 0 0 -width 2 -fill red]
    set opacityLine [$f create line 0 0 0 0 -width 2 -fill red]
    set histLine [$f create line 0 0 0 0 -width 2 -fill red]
    
    
    .menuPoint add command -label "Delete Point" -command "removePoint $f"
    
    .menuLine add command -label "Add Point" -command "addPoint $f"
    
    createHistLine $f
    VolumeTextureMapping(texturevolumeMapper) ClearTF
    for {set addAxis 0} {$addAxis < 3} {incr addAxis} {
        
        VolumeTextureMapping(texturevolumeMapper) AddTFPoint $addAxis 0 0
        VolumeTextureMapping(texturevolumeMapper) AddTFPoint $addAxis 30 0
        VolumeTextureMapping(texturevolumeMapper) AddTFPoint $addAxis 110 200
        VolumeTextureMapping(texturevolumeMapper) AddTFPoint $addAxis 230 200
        VolumeTextureMapping(texturevolumeMapper) AddTFPoint $addAxis 255 255
    }
    TFPoints $f 
    TFInteractions $f  
}

#-------------------------------------------------------------------------------
# .PROC getPointX
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc getPointX {} {
    global currentVolume pointx numPoints
    set numPoints [VolumeTextureMapping(texturevolumeMapper) GetNumPoint $currentVolume]
    
    for {set num 0} {$num <= [expr $numPoints]} {incr num} {
    set pointx($num) [VolumeTextureMapping(texturevolumeMapper) GetPoint $currentVolume $num 0] 
    }
}

#-------------------------------------------------------------------------------
# .PROC getPointY
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc getPointY {} {
    global currentVolume pointy numPoints
    for {set num 0} {$num <= [expr $numPoints]} {incr num} {
    set pointy($num) [VolumeTextureMapping(texturevolumeMapper) GetPoint $currentVolume $num 1] 
    }
}

#-------------------------------------------------------------------------------
# .PROC ChangeVolume
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc ChangeVolume {f} {
  
     global currentVolume VolumeTextureMapping Module
    if {[string compare $VolumeTextureMapping(currentVolume) "volume1"] == 0} {
    set currentVolume 0
    } elseif {[string compare $VolumeTextureMapping(currentVolume) "volume2"] == 0} {
    set currentVolume 1
    } elseif {[string compare $VolumeTextureMapping(currentVolume) "volume3"] == 0} {
    set currentVolume 2
    }
    
    set fTransfer $Module(VolumeTextureMapping,fTransfer)
    set f $fTransfer.fTFVolume1
    getColor $f
    set fTransfer $Module(VolumeTextureMapping,fTransfer)
    set f $fTransfer.fTFVolume1.graph.canvas1
    createHistLine $f
    TFInteractions $f    
}


#-------------------------------------------------------------------------------
# .PROC TFPoints
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc TFPoints {f} {
    global currentVolume 
    global pointx pointy numPoints point
    getPointX 
    getPointY 
    
    set color "black"

    for {set i 0} {$i <= [expr $numPoints]} {incr i} {
    set x [expr {$pointx($i)*210/255+4}]
       set y [expr {(100+4) - $pointy($i)*100/255}]
        set item [$f create oval [expr {$x-3}] [expr {$y-3}] \
              [expr {$x+3}] [expr {$y+3}] -width 1 -outline black \
              -fill $color]
    $f addtag point withtag $item        
    }
}

#-------------------------------------------------------------------------------
# .PROC TFInteractions
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc TFInteractions {f} {
     global colorLine point currentVolume .menuPoint .menuLine opacityLine
    
    $f delete point
    createTFLine $f
    
    TFPoints $f    
    
    $f bind point <3> "menuPopPoint $f %x %y %X %Y"
    $f bind myLine <3> "menuPopLine $f %x %y %X %Y"
    $f bind point <Any-Enter> "holdOverPoint $f %x %y"
    $f bind myLine <Any-Enter> "holdOverLine $f %x %y"
    $f bind point <Any-Leave> "leavePoint $f"
    $f bind myLine <Any-Leave> "leaveLine $f"
    $f bind point <ButtonRelease-1> "releasePoint $currentVolume $f %x %y"
    $f bind point <1> "clickOnPoint $currentVolume $f %x %y"
    bind $f <B1-Motion> "movePoint  $f %x %y"
    
}

#-------------------------------------------------------------------------------
# .PROC menuPopLine
# 
# .ARGS
# windowpath f
# int x
# int y
# int x2
# int y2
# .END
#-------------------------------------------------------------------------------
proc menuPopLine {f x y x2 y2} {
    global newPointPosX newPointPosY 
    set vx [expr $x*255/210+4]
    set vy [expr ((100+4)-$y)*255/100]
    set newPointPosX $vx
    set newPointPosY $vy
    tk_popup .menuLine $x2 $y2
}

#-------------------------------------------------------------------------------
# .PROC menuPopPoint
# 
# .ARGS
# windowpath f
# int x
# int y
# int x2
# int y2
# .END
#-------------------------------------------------------------------------------
proc menuPopPoint {f x y x2 y2} {
  global newPointPosX newPointPosY 
    set vx [expr $x*255/210+4]
    set vy [expr ((100+4)-$y)*255/100]
    set newPointPosX $vx
    set newPointPosY $vy
    tk_popup .menuPoint $x2 $y2
}

#-------------------------------------------------------------------------------
# .PROC holdOverLine
# 
# .ARGS
# windowpath f
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc holdOverLine {f x y} {
   global lineColor
    set lineColor [$f itemcget current -fill]
    $f itemconfig current -fill yellow
    
}

#-------------------------------------------------------------------------------
# .PROC leaveLine
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc leaveLine {f} {
    global lineColor
    $f itemconfig current -fill $lineColor
}

#-------------------------------------------------------------------------------
# .PROC createHistLine
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc createHistLine {f} {
   global histLine coords currentVolume Module
    set fTransfer $Module(VolumeTextureMapping,fTransfer)
    set f $fTransfer.fTFVolume1.graph.canvas1
    $f delete $histLine
    lappend coords 0
    unset coords
   for {set i 0} {$i < 255} {incr i} {
    lappend coords [expr {$i*210/255+4}]
    lappend coords [expr {(100+4)-0*100/255}]
    lappend coords [expr {$i*210/255+4}]
    lappend coords [expr {(100+4)-[VolumeTextureMapping(texturevolumeMapper) GetHistValue $currentVolume $i]*100/255}]
    lappend coords [expr {$i*210/255+4}]
    lappend coords [expr {(100+4)-0*100/255}]
    }
    set histLine [$f create line $coords -width 3 -fill "red"]
}

#-------------------------------------------------------------------------------
# .PROC createTFLine
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc createTFLine {f} {
    global colorLine numPoints pointx pointy coords point opacityLine
      
    getPointX 
    getPointY 
    $f delete $opacityLine
      
    lappend coords 0
    unset coords

    for {set i 0} {$i <= [expr $numPoints]} {incr i} {
        lappend coords [expr {$pointx($i)*210/255+4}]
        lappend coords [expr {(100+4) - $pointy($i)*100/255}]     
    }
        
    set opacityLine [$f create line $coords -width 3 -fill "black"]
    $f addtag myLine withtag $opacityLine 
    $f raise point 
}

#-------------------------------------------------------------------------------
# .PROC holdOverPoint
# 
# .ARGS
# windowpath f
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc holdOverPoint {f x y} {
    global pointColor pointPos plot currentVolume
    set pointColor [$f itemcget current -fill]
    $f itemconfig current -fill yellow    
   
    set plot(lastX) $x
    set plot(lastY) $y
    set vx [expr ($x-4)*255/210]
    set vy [expr (100+4)*255/100]
    #inside a bounding box
    set boundX [expr 8*255/210]
    set boundY [expr 8*255/100]
    set pointPos [VolumeTextureMapping(texturevolumeMapper) GetArrayPos $currentVolume $vx $vy $boundX $boundY]
}

#-------------------------------------------------------------------------------
# .PROC leavePoint
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc leavePoint {f} {
    global pointColor
    $f itemconfig current -fill $pointColor
}

#-------------------------------------------------------------------------------
# .PROC setValues
# 
# .ARGS
# windowpath f
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc setValues {f x y} {
    global thisx thisy .menuLine
    set thisx $x
    set thisy $y
    tk_popup .menuLine $x $y
}


#-------------------------------------------------------------------------------
# .PROC addPoint
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc addPoint {f} {
    global currentVolume newPointPosX newPointPosY 
    
    set vx [expr $newPointPosX*255/210+4]
    set vy [expr ((100+4)-$newPointPosY)*255/100]
    
    VolumeTextureMapping(texturevolumeMapper) AddTFPoint $currentVolume $newPointPosX $newPointPosY
    TFInteractions $f
}


#-------------------------------------------------------------------------------
# .PROC removePoint
# 
# .ARGS
# windowpath f
# .END
#-------------------------------------------------------------------------------
proc removePoint {f} {
   global pointPos currentVolume newPointPosX newPointPosY numPoints
   set boundX [expr 10*255/210]
   set boundY [expr 10*255/100]
   set pointPos [VolumeTextureMapping(texturevolumeMapper) GetArrayPos $currentVolume $newPointPosX $newPointPosY $boundX $boundY]
   if {($pointPos != -1) && ($pointPos != 0) && ($pointPos != $numPoints)} {
        VolumeTextureMapping(texturevolumeMapper) RemoveTFPoint $currentVolume $pointPos
        TFInteractions $f
   }
}


#-------------------------------------------------------------------------------
# .PROC clickOnPoint
# 
# .ARGS
# int volume
# windowpath f
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc clickOnPoint {volume f x y} {
   global plot pointPos pointColor currentVolume
   $f dtag selected
   $f addtag selected withtag current
   $f raise current 
   #raise- change stack order #current -whatever object is over the mouse
   set plot(lastX) $x
   set plot(lastY) $y
   set vx [expr ($x-4)*255/210]
   set vy [expr ((100+4)-$y)*255/100]
   #inside the bounding box
   set boundX [expr 8*255/210]
   set boundY [expr 8*255/100]
   set pointPos [VolumeTextureMapping(texturevolumeMapper) GetArrayPos $currentVolume $vx $vy $boundX $boundY]
}

#-------------------------------------------------------------------------------
# .PROC releasePoint
# 
# .ARGS
# int volume
# windowpath f
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc releasePoint {volume f x y} {
    global pointPos currentVolume plot numPoints
    $f dtag selected
    
    if { [expr ($x-4)*255/210] < 0} {
    set x [expr {0*210/255+4}]
    } elseif {[expr ($x-4)*255/210] > 255} {
    set x [expr {255*210/255+4}]
    }
    if { [expr ((100+4)-$y)*255/100] < 0} {
    set y [expr {(100+4) - 0*100/255}]
    } elseif {[expr ((100+4)-$y)*255/100] > 255} {
    set y [expr {(100+4) - 255*100/255}]
    }
    if {$pointPos == 0}    {
    set x [expr {0*210/255+4}]
    
    } elseif {$pointPos == $numPoints} {
    set x [expr {255*210/255+4}]
    
    }
    set vx [expr ($x-4)*255/210]
    set vy [expr ((100+4)-$y)*255/100]
    VolumeTextureMapping(texturevolumeMapper) ChangeTFPoint $volume $pointPos $vx $vy        
    
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
    set pointPos -1
    TFInteractions $f
}

#-------------------------------------------------------------------------------
# .PROC movePoint
# 
# .ARGS
# windowpath f
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc movePoint {f x y} {
    global currentVolume pointPos numPoints
    global plot pointPos colorLine
    if {$pointPos != -1} {
    
    if { [expr ($x-4)*255/210] < 0} {
        set x [expr {0*210/255+4}]
    } elseif {[expr ($x-4)*255/210] > 255} {
        set x [expr {255*210/255+4}]
    }
    if { [expr ((100+4)-$y)*255/100] < 0} {
        set y [expr {(100+4) - 0*100/255}]
    } elseif {[expr ((100+4)-$y)*255/100] > 255} {
        set y [expr {(100+4) - 255*100/255}]
    }
    
    if {$pointPos == 0} {
        set x [expr {0*210/255+4}]            
    } elseif {$pointPos == $numPoints} {
        set x [expr {255*210/255+4}]                
    }
    $f move selected [expr {$x-$plot(lastX)}] [expr {$y-$plot(lastY)}]
    set plot(lastX) $x
    set plot(lastY) $y    
    set vx [expr ($x-4)*255/210]
    set vy [expr ((100+4)-$y)*255/100]
    
    VolumeTextureMapping(texturevolumeMapper) ChangeTFPoint $currentVolume $pointPos $vx $vy
    
    createTFLine $f 
    
    }
}

#-------------------------------------------------------------------------------
# .PROC ChangeTransformMatrix
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc ChangeTransformMatrix {} {
#    global t00 t01 t02 t03 t10 t11 t12 t13 t20 t21 t22 t23 t30 t31 t32 t33 currentVolume
#    VolumeTextureMapping(texturevolumeMapper) UpdateTransformMatrix $currentVolume $t00 $t01 $t02 $t03 $t10 $t11 $t12 $t13 $t20 $t21 $t22 $t23 $t30 $t31 $t32 $t33 
#    VolumeTextureMapping(texturevolumeMapper) Update
#    RenderAll
#}


#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingBuildVTK {} {
    global VolumeTextureMapping Volume
    
    vtkVolumeTextureMapper3D VolumeTextureMapping(texturevolumeMapper)
    global numVolumes
    set numVolumes 0
    
    
    VolumeTextureMapping(texturevolumeMapper) SetNumberOfPlanes 128
    vtkVolume VolumeTextureMapping(volume)
    
    
    #vtkImageCast filter casts the input type to match the output type in the image processing pipeline
    vtkImageCast VolumeTextureMapping(imageCast1)
    vtkImageCast VolumeTextureMapping(imageCast2)
    vtkImageCast VolumeTextureMapping(imageCast3)
    

}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingRefresh
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingRefresh {} {
    global VolumeTextureMapping Slice Volume Module currentVolume
    global numVolumes View
    
    set boxSize 128
    VolumeTextureMapping(texturevolumeMapper) SetCounter 0
    set boxSize [expr $View(fov)]
    VolumeTextureMapping(texturevolumeMapper) SetBoxSize $boxSize
    
    VolumeTextureMapping(texturevolumeMapper) SetEnableVolume 0 0
    VolumeTextureMapping(texturevolumeMapper) SetEnableVolume 1 0
    VolumeTextureMapping(texturevolumeMapper) SetEnableVolume 2 0
    
     for {set v 0} {$v < 3} {incr v} {
        if {$VolumeTextureMapping(idOriginal[expr $v + 1]) != $Volume(idNone)} {
            set numVolumes [expr $numVolumes+1]
            VolumeTextureMapping(texturevolumeMapper) SetEnableVolume $v 1
        } 
    }  
    
    VolumeTextureMapping(texturevolumeMapper) SetNumberOfVolumes $numVolumes
    set numVolumes 0
    

   for {set volLoad 0} {$volLoad < 3} {incr volLoad} {
        if {$VolumeTextureMapping(idOriginal1) != $Volume(idNone)} {
    
            set currentVolume 0
            VolumeTextureMapping(imageCast[expr $volLoad +1]) SetInput [Volume($VolumeTextureMapping(idOriginal[expr $volLoad +1]),vol) GetOutput]
            VolumeTextureMapping(imageCast[expr $volLoad +1]) SetOutputScalarTypeToUnsignedShort    

            VolumeTextureMapping(volume) SetMapper VolumeTextureMapping(texturevolumeMapper)

            scan [Volume($VolumeTextureMapping(idOriginal[expr $volLoad +1]),node) GetSpacing] "%g %g %g" res_x res_y res_z
            VolumeTextureMapping(texturevolumeMapper) SetInput [VolumeTextureMapping(imageCast[expr $volLoad +1]) GetOutput]
 
            if {[info commands t1] == ""} {
                 vtkTransform t1
            }
            t1 Identity
            t1 PreMultiply
            t1 SetMatrix [Volume($VolumeTextureMapping(idOriginal[expr $volLoad +1]),node) GetWldToIjk]
            t1 Inverse
      
            t1 PreMultiply
            t1 Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] [expr 1.0 / $res_z]
    
            VolumeTextureMapping(volume) SetUserMatrix [t1 GetMatrix]
            t1 Delete
        }
        

        set VolumeTextureMapping(colorTable$volLoad) [ Volume($VolumeTextureMapping(idOriginal[expr $volLoad +1]),node) GetLUTName]
          VolumeTextureMapping(texturevolumeMapper) SetColorTable Lut($VolumeTextureMapping(colorTable$volLoad),lut) $volLoad
    
        VolumeTextureMapping(texturevolumeMapper) Update
        RenderAll
   } 
    
    VolumeTextureMappingCameraMotion
    set fTransfer $Module(VolumeTextureMapping,fTransfer)
    set f $fTransfer.fTFVolume1.graph.canvas1
    createHistLine $f
    TFInteractions $f
    VolumeTextureMapping(texturevolumeMapper) Update
    RenderAll
    
    set fSettings $Module(VolumeTextureMapping,fSettings)
    set f $fSettings.fRefreshSettings.fDimension

    $f.dimx configure -text [VolumeTextureMapping(texturevolumeMapper) GetTextureDimension $currentVolume 0]
    $f.dimy configure -text [VolumeTextureMapping(texturevolumeMapper) GetTextureDimension $currentVolume 1]
    $f.dimz configure -text [VolumeTextureMapping(texturevolumeMapper) GetTextureDimension $currentVolume 2]
  
}


#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingCameraMotion
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingCameraMotion {} {
global View VolumeTextureMapping Volume  Module

 for {set i 0} {$i < 3} {incr i} {

   if {$VolumeTextureMapping(idOriginal[expr $i+1]) != $Volume(idNone)} {
        set id $VolumeTextureMapping(idOriginal[expr $i+1])

        if { ![info exists VolumeTextureMapping(colorTable$i)] } {
            break
        }

        if {$VolumeTextureMapping(colorTable$i) != [Volume($id,node) GetLUTName]} {
            set VolumeTextureMapping(colorTable$i) [ Volume($id,node) GetLUTName]
            VolumeTextureMapping(texturevolumeMapper) SetColorTable Lut($VolumeTextureMapping(colorTable$i),lut) $i
        }

        set extent [[Volume($id,vol) GetOutput] GetExtent]
        set x2 [expr [lindex $extent 1] + 1] 
        set x4 [expr [lindex $extent 3] + 1] 
        set x6 [expr [lindex $extent 5] + 1] 

        vtkMatrix4x4 resultMatrix
        vtkMatrix4x4 DisplaceMatrix
        vtkMatrix4x4 IjkToWld

        resultMatrix Identity
        DisplaceMatrix Identity
 
        #get the local and global transformation (instead of geting IJK->RAS and RAS->WLD)
        IjkToWld DeepCopy [Volume($id,node) GetWldToIjk]
        #invert since we want to go from IJK->WLD instead of WLD->IJK
        IjkToWld Invert

        #displace since the coordinates in the volume renderer goes from -extent/2 -> extent/2 instead of 0 -> extent
        DisplaceMatrix  DeepCopy \
        1  0  0  [expr $x2/2] \
        0  1  0  [expr $x4/2] \
        0  0  1  [expr $x6/2] \
        0  0  0  1    
  
        resultMatrix Multiply4x4 DisplaceMatrix resultMatrix resultMatrix
        resultMatrix Multiply4x4 IjkToWld resultMatrix resultMatrix
    
        #update the transformmatrix in the volume renerer
        VolumeTextureMapping(texturevolumeMapper) UpdateTransformMatrix $i resultMatrix

        DisplaceMatrix Delete
        IjkToWld Delete
        resultMatrix Delete
    }
 }
 
 VolumeTextureMapping(texturevolumeMapper) Update
 RenderAll

 set fTransfer $Module(VolumeTextureMapping,fTransfer)
 set f $fTransfer.fTFVolume
 ChangeVolume $f
}



#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingEnter {} {
    global VolumeTextureMapping Volume Slice Module
    
    # If the Original is None, then select what's being displayed,
    # otherwise the first volume in the mrml tree.
    
    if {$VolumeTextureMapping(idOriginal1) == $Volume(idNone)} {
        set v [[[Slicer GetBackVolume $Slice(activeID)] GetMrmlNode] GetID]
        if {$v == $Volume(idNone)} {
            set v [lindex $Volume(idList) 0]
        }
        if {$v != $Volume(idNone)} {
            VolumeTextureMappingSetOriginal1 $v
        }
    }
    
    pushEventManager $VolumeTextureMapping(eventManager)
    
    
    
    if {$VolumeTextureMapping(volumeVisible) == "0"} {
    
    foreach r $Module(Renderers) {
        $r AddVolume VolumeTextureMapping(volume)
        
    }
    }
    set VolumeTextureMapping(volumeVisible) "1"
    
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingExit
# Called when this module is exitedVolume($VolumeTextureMapping(idOriginal),node) GetPosition by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingExit {} {
    
}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingUpdateMRML {} {
    global Volume VolumeTextureMapping
    
    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $VolumeTextureMapping(idOriginal1)] == -1} {
        VolumeTextureMappingSetOriginal1 $n
        VolumeTextureMappingSetOriginal2 $n
        VolumeTextureMappingSetOriginal3 $n
    }
    
    # Original1 Volume menu
    #---------------------------------------------------------------------------
    set m $VolumeTextureMapping(mOriginal1)
    $m delete 0 end
    foreach v $Volume(idList) {
        $m add command -label [Volume($v,node) GetName] -command \
            "VolumeTextureMappingSetOriginal1 $v; RenderAll"
    }
    # Original2 Volume menu
    #---------------------------------------------------------------------------
    set m $VolumeTextureMapping(mOriginal2)
    $m delete 0 end
    foreach v $Volume(idList) {
        $m add command -label [Volume($v,node) GetName] -command \
            "VolumeTextureMappingSetOriginal2 $v; RenderAll"
    }
    # Original3 Volume menu
    #---------------------------------------------------------------------------
    set m $VolumeTextureMapping(mOriginal3)
    $m delete 0 end
    foreach v $Volume(idList) {
        $m add command -label [Volume($v,node) GetName] -command \
            "VolumeTextureMappingSetOriginal3 $v; RenderAll"
    }
    
    
}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingSetOriginal1
#   Sets which volume is used in this module.
#   Called from VolumeTextureMappingUpdateMRML and VolumeTextureMappingEnter.
# .ARGS
#  int  v Volume ID
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingSetOriginal1 {v} {
    global VolumeTextureMapping Volume
    
    set VolumeTextureMapping(idOriginal1) $v
    
    # Change button text
    $VolumeTextureMapping(mbOriginal1) config -text [Volume($v,node) GetName]
    
}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingSetOriginal2
#   Sets which volume is used in this module.
#   Called from VolumeTextureMappingUpdateMRML and VolumeTextureMappingEnter.
# .ARGS
# int  v    Volume ID
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingSetOriginal2 {v} {
    global VolumeTextureMapping Volume
    
    set VolumeTextureMapping(idOriginal2) $v
    
    # Change button text
    $VolumeTextureMapping(mbOriginal2) config -text [Volume($v,node) GetName]
    
}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingSetOriginal3
#   Sets which volume is used in this module.
#   Called from VolumeTextureMappingUpdateMRML and VolumeTextureMappingEnter.
# .ARGS
# int  v    Volume ID
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingSetOriginal3 {v} {
    global VolumeTextureMapping Volume
    
    set VolumeTextureMapping(idOriginal3) $v
    
    
    # Change button text
    $VolumeTextureMapping(mbOriginal3) config -text [Volume($v,node) GetName]
}




#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingStorePresets
# 
# .ARGS
# int p
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingStorePresets {p} {
    global Preset VolumeTextureMapping Volume
    
    set Preset(VolumeTextureMapping,$p,idOriginal1) $VolumeTextureMapping(idOriginal1)
    set Preset(VolumeTextureMapping,$p,idOriginal2) $VolumeTextureMapping(idOriginal2)
    set Preset(VolumeTextureMapping,$p,idOriginal3) $VolumeTextureMapping(idOriginal3)
    set Preset(VolumeTextureMapping,$p,hideOnExit) $VolumeTextureMapping(hideOnExit)
    
}

#-------------------------------------------------------------------------------
# .PROC VolumeTextureMappingRecallPresets
# 
# .ARGS
# int p
# .END
#-------------------------------------------------------------------------------
proc VolumeTextureMappingRecallPresets {p} {
    global Preset VolumeTextureMapping
    
    set VolumeTextureMapping(idOriginal1) $Preset(VolumeTextureMapping,$p,idOriginal1)
    set VolumeTextureMapping(idOriginal2) $Preset(VolumeTextureMapping,$p,idOriginal2)
    set VolumeTextureMapping(idOriginal3) $Preset(VolumeTextureMapping,$p,idOriginal3)
    set VolumeTextureMapping(hideOnExit) $Preset(VolumeTextureMapping,$p,hideOnExit)

}


