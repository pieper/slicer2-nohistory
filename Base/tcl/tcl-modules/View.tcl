#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: View.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:01 $
#   Version:   $Revision: 1.43 $
# 
#===============================================================================
# FILE:        View.tcl
# PROCEDURES:  
#   ViewInit
#   ViewBuildGUI
#   ViewBuildVTK
#   ViewBuildLightsVTK
#   ViewSaveHeadlight
#   ViewCreateLightKit
#   ViewSetLightIntensity value
#   ViewUpdateLightIntensity
#   ViewSwitchLightKit state
#   ViewLightsSetDefaults
#==========================================================================auto=
#
# Use this Module for Changing the Viewing Windows sizes
# and relative positions.
#
#
# KNOWN BUG: Turning off the Close-up window doesn't actually turn it off.
#            It prevents the window from updating, but the close-up window
#            Still gets initialized upon entering a slice.
#
#

#-------------------------------------------------------------------------------
# .PROC ViewInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewInit {} {

    global View Module

    # Define Tabs
    set m View
    set Module($m,row1List) "Help View Texture Fog Lights"
    set Module($m,row1Name) "Help View Texture Fog Lights"
    set Module($m,row1,tab) View

    # Module Summary Info
    set Module($m,overview) "Settings for 3D View, stereo, make movies."
    set Module($m,author) "Core"
    set Module($m,category) "Visualisation"

    # Define Procedures
    set Module($m,procGUI) ViewBuildGUI
    set Module($m,procVTK) ViewBuildVTK

    # Define Dependencies
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.43 $} {$Date: 2006/01/06 17:57:01 $}]

    # Default values
    set View(default,LightIntensity) 0.7
    set View(default,LightKeyToFillRatio) 2
    set View(default,LightKeyToHeadRatio) 1.75
    set View(default,LightKeyToBackRatio) 3.75


    set ::View(LightKit,updating) 0

}

#-------------------------------------------------------------------------------
# .PROC ViewBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewBuildGUI {} {

    global Gui View Module Fog

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # View
    #   Size     : Size of window in 3D mode
    #   Closeup  : Turns on/off Close-up Window
    #   Stereo   : Turns on/off Stereo 3D
    #
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
<UL>
<LI><B>Size</B> If you want to save the 3D view as an image on disk 
(using the <B>Save 3D</B> command from the <B>File</B> menu), first
set the size of the window to the desired size of the saved image.
<BR><LI><B>Closeup</B> The Closeup window magnifies the slice window
around the mouse cursor.  This option is not presently available on PCs.
<BR><LI><B>Stereo</B> The Stereo mode allows viewing the 3D window in
3D if you have Red/Blue glasses.  If you have crystal eyes glasses,
then select the CrystalEyes stereo mode.
<BR><LI><B>Background Color</B> When you threshold graylevel volumes,
the view will look better if the background is black.
<BR><LI><B>Record Movie</B>This functionality is now located in the
<I>File->Set Save 3D View Parameters...</I> menu option.
<BR><LI><B>Texture</B> The Texture panel controls the rendering of the slices
displayed in the 3D window.  <B>Resolution</B> controls the number of pixels
in the texture.  Choose higher values up to the resolution of your source
images for better quality.  Choose smaller values for faster rendering.
<B>Interpolation</B> controls whether pixel blocks are smoothed as they are
magnified.
<BR><LI><B>Fog</B> The fog allows to mix the  color of the 3D object
with the background depending on its distance to the camera.
The transformation is linear with two parameters <I>Start</I> and <I>End</I>.
The value 0 is the closest position of the bounding box and
the value 1 is the furthest position of the bounding box.
<BR><LI><B>Lights</B>The Lights panel lets you select between the default,
fairly ugly 'Blair Witch'-type headlight lighting and a more pleasing multiple
light arrangement using the vtkLightKit. The panel also allows some other 
light parameters (e.g., overall intensity) to be adjusted. 
You can return to the system defaults by hitting the 'Return to default values' button.
</UL>
"
    regsub -all "\n" $help { } help
    MainHelpApplyTags View $help
    MainHelpBuildGUI View

    #-------------------------------------------
    # View frame
    #-------------------------------------------
    set fView $Module(View,fView)
    set f $fView

    frame $f.fSize    -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fBg      -bg $Gui(activeWorkspace)
    frame $f.fStereo  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fCloseup -bg $Gui(activeWorkspace)
    frame $f.fMovie   -bg $Gui(activeWorkspace)
    pack $f.fSize $f.fBg $f.fCloseup $f.fStereo $f.fMovie \
        -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # View->Bg Frame
    #-------------------------------------------
    set f $fView.fBg
    
    eval {label $f.l -text "Background: "} $Gui(WLA)
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach value "Blue Black Midnight White" width "5 6 9 6" {
        eval {radiobutton $f.r$value -width $width \
            -text "$value" -value "$value" -variable View(bgName) \
            -indicatoron 0 -command "MainViewSetBackgroundColor; Render3D"} $Gui(WCA)
        pack $f.r$value -side left -padx 0 -pady 0
    }
    
    #-------------------------------------------
    # View->Closeup Frame
    #-------------------------------------------
    set f $fView.fCloseup
    
    eval {label $f.lCloseup -text "Closeup Window: "} $Gui(WLA)
    pack $f.lCloseup -side left -padx $Gui(pad) -pady 0

    foreach value "On Off" width "4 4" {
        eval {radiobutton $f.rCloseup$value -width $width \
            -text "$value" -value "$value" -variable View(closeupVisibility) \
            -indicatoron 0 -command "MainViewSetWelcome Welcome"} $Gui(WCA)
        pack $f.rCloseup$value -side left -padx 0 -pady 0
    }
    
    #-------------------------------------------
    # View->Size Frame
    #-------------------------------------------
    set f $fView.fSize
    
    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
       pack $f.fTitle $f.fBtns -side top -pady 5

    eval {label $f.fTitle.lTitle -text "Window Size in 3D Mode:"} $Gui(WLA)
    pack $f.fTitle.lTitle -side left -padx $Gui(pad) -pady 0

    eval {label $f.fBtns.lW -text "Width:"} $Gui(WLA)
    eval {label $f.fBtns.lH -text "Height:"} $Gui(WLA)
    eval {entry $f.fBtns.eWidth -width 5 -textvariable View(viewerWidth)} $Gui(WEA)
    eval {entry $f.fBtns.eHeight -width 5 -textvariable View(viewerHeight)} $Gui(WEA)
        bind $f.fBtns.eWidth  <Return> {MainViewerSetMode}
        bind $f.fBtns.eHeight <Return> {MainViewerSetMode}
    pack $f.fBtns.lW $f.fBtns.eWidth $f.fBtns.lH $f.fBtns.eHeight \
        -side left -padx $Gui(pad)

    #-------------------------------------------
    # View->Stereo Frame
    #-------------------------------------------
    set f $fView.fStereo

    frame $f.fStereoType -bg $Gui(activeWorkspace)
    frame $f.fStereoOn -bg $Gui(activeWorkspace)
    pack $f.fStereoType $f.fStereoOn -side top -pady 5

    #-------------------------------------------
    # View->Stereo->StereoType Frame
    #-------------------------------------------
    set f $fView.fStereo.fStereoType

    foreach value "RedBlue CrystalEyes Interlaced" {
        eval {radiobutton $f.r$value \
            -text "$value" -value "$value" \
            -variable View(stereoType) \
            -indicatoron 0 \
            -command "MainViewSetStereo; Render3D"} \
            $Gui(WCA)
        pack $f.r$value -side left -padx 0 -pady 0
    }

    #-------------------------------------------
    # View->Stereo->StereoOn Frame
    #-------------------------------------------
    set f $fView.fStereo.fStereoOn
    
    # Stereo button
    eval {checkbutton $f.cStereo \
        -text "Stereo" -variable View(stereo) -width 6 \
        -indicatoron 0 -command "MainViewSetStereo; Render3D"} $Gui(WCA)
 
    pack $f.cStereo -side top -padx 0 -pady 2

    #-------------------------------------------
    # View->Movie Frame
    #-------------------------------------------
    
    set f $fView.fMovie
 
    eval {label $f.cDeprecatedNote -text "Movie functionality is now in the\n\"File->Set Save 3D View Params...\"\nSlicer menu item."} $Gui(WLA) -justify left

    pack $f.cDeprecatedNote -expand true -fill both

    #-------------------------------------------
    # Fog frame
    #-------------------------------------------

    FogBuildGui $Module(View,fFog)

    #-------------------------------------------
    # Texture frame
    #-------------------------------------------

    set f $Module(View,fTexture)

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side top -pady 5

    eval {label $f.fTitle.lTitle -text "Texture Display:"} $Gui(WLA)
    pack $f.fTitle.lTitle -side left -padx $Gui(pad) -pady 0

    eval {label $f.fBtns.lR -text "Resolution:"} $Gui(WLA)
    eval {entry $f.fBtns.eRes -width 5 -textvariable View(textureResolution)} $Gui(WEA)
    bind $f.fBtns.eRes  <Return> {MainViewSetTexture}
    pack $f.fBtns.lR $f.fBtns.eRes \
        -side left -padx $Gui(pad)

    frame $f.fInterp -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack $f.fInterp -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    eval {label $f.fInterp.lInterp -text "Interpolate: "} $Gui(WLA)
    pack $f.fInterp.lInterp -side left -padx $Gui(pad) -pady 0

    foreach value "On Off" width "4 4" {
        eval {radiobutton $f.fInterp.rInterp$value -width $width \
            -text "$value" -value "$value" -variable View(textureInterpolation) \
            -indicatoron 0 -command "MainViewSetTexture"} $Gui(WCA)
        pack $f.fInterp.rInterp$value -side left -padx 0 -pady 0
    }

    #-------------------------------------------
    # Lights frame
    #-------------------------------------------
    set fLights $Module(View,fLights)
    
    set f $fLights

    frame $f.fLightMode -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fLightIntensity -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack $f.fLightMode $f.fLightIntensity -side top -pady 5 -fill x -padx 5

    set f $fLights.fLightMode
    eval {label $f.lLightMode -text "Light Mode"} $Gui(WLA)
    eval {radiobutton $f.rbLK -text "LightKit (better)" \
              -variable View(LightModeIndicator) -value "LightKit" \
              -command "ViewSwitchLightKit 1"} $Gui(WRA)
    TooltipAdd $f.rbLK "Light the model more naturally with three lights."

    eval {radiobutton $f.rbHL -text "Headlight (VTK default)" \
              -variable View(LightModeIndicator) -value "Headlight" \
              -command {ViewSwitchLightKit 0}} $Gui(WRA)
    TooltipAdd $f.rbHL "Light the model with a headlight (a light at the camera)."

    pack $f.lLightMode -side top -anchor w -padx $Gui(pad) -pady $Gui(pad)
    pack $f.rbLK -side top -anchor w -padx $Gui(pad) -pady $Gui(pad)
    pack $f.rbHL -side top -anchor w -padx $Gui(pad) -pady $Gui(pad)

    # main light
    set f $fLights.fLightIntensity
    eval {scale $f.sIntensity -from 0.0 -to 1.5 -showvalue true \
               -label "Main Light Intensity" -tickinterval 0.25 \
               -variable View(LightIntensity) -resolution 0.05 -orient horizontal \
               -command ViewUpdateLightIntensity} $Gui(WSA)

    TooltipAdd $f.sIntensity "Set the overall lighting intensity of the scene."
    pack $f.sIntensity -fill x -side top -padx $Gui(pad) -pady $Gui(pad) -expand true

    # fill light
    eval {scale $f.sFillRatio -from 0.5 -to 7.5 -showvalue true \
               -label "Fill Ratio" -tickinterval 2.0 \
               -variable View(LightKeyToFillRatio) -resolution 0.05 -orient horizontal \
               -command ViewUpdateLightIntensity} $Gui(WSA)

    set View(FillRatioScale) $f.sFillRatio

    TooltipAdd $f.sFillRatio "Set the ratio of the main light to fill light from below."
    pack $f.sFillRatio -fill x -side top -padx $Gui(pad) -pady $Gui(pad) -expand true

    # headlight
    eval {scale $f.sHeadRatio -from 0.5 -to 7.5 -showvalue true \
               -label "Headlight Ratio" -tickinterval 2.0 \
               -variable View(LightKeyToHeadRatio) -resolution 0.05 -orient horizontal \
               -command ViewUpdateLightIntensity} $Gui(WSA)

    set View(HeadRatioScale) $f.sHeadRatio    

    TooltipAdd $f.sHeadRatio "Set the ratio of the main light to the camera's headlight."
    pack $f.sHeadRatio -fill x -side top -padx $Gui(pad) -pady $Gui(pad) -expand true

    # back light
    if {$View(LightKitHasBackLights)} {
       eval {scale $f.sBackRatio -from 0.5 -to 7.5 -showvalue true \
                  -label "Back Light Ratio" -tickinterval 2.0 \
                  -variable View(LightKeyToBackRatio) -resolution 0.05 -orient horizontal \
                  -command ViewUpdateLightIntensity} $Gui(WSA)

       set View(BackRatioScale) $f.sBackRatio    

       TooltipAdd $f.sBackRatio "Set the ratio of the main light to the camera's back lights."
       pack $f.sBackRatio -fill x -side top -padx $Gui(pad) -pady $Gui(pad) -expand true
    }

    # button to return to default values
    DevAddButton $f.bSetDefaults "Return to default values" ViewLightsSetDefaults
    pack $f.bSetDefaults -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    
}

#-------------------------------------------------------------------------------
# .PROC ViewBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewBuildVTK {} {
    ViewBuildLightsVTK
}

#-------------------------------------------------------------------------------
# .PROC ViewBuildLightsVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewBuildLightsVTK {} {
    global View
    ViewCreateLightKit
    set View(LightIntensity) $View(default,LightIntensity)
    set View(LightKeyToFillRatio) $View(default,LightKeyToFillRatio)
    set View(LightKeyToHeadRatio) $View(default,LightKeyToHeadRatio)
    set View(LightKeyToBackRatio) $View(default,LightKeyToBackRatio) 

    ViewSwitchLightKit 1
    set View(LightModeIndicator) "LightKit"
}

#-------------------------------------------------------------------------------
# .PROC ViewSaveHeadlight
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewSaveHeadlight {} {
    global View

    set ren viewRen

    set lights [$ren GetLights]
    $lights InitTraversal
    set hl [$lights GetNextItem]
    set View(LightSavedHeadlight) $hl
    set View(LightMode) "Headlight"
    set View(LightModeIndicator) "Headlight"
}

#-------------------------------------------------------------------------------
# .PROC ViewCreateLightKit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewCreateLightKit {} {
    global View
    vtkLightKit ViewLightKit
    set View(LightKit) ViewLightKit
    set View(LightKitHasBackLights) [expr {! [catch {ViewLightKit cGetBackLightWarmth}]}]
}

#-------------------------------------------------------------------------------
# .PROC ViewSetLightIntensity
# 
# .ARGS
# float value Light intensity value
# .END
#-------------------------------------------------------------------------------
proc ViewSetLightIntensity {value} {
    global View
    set View(LightIntensity) $value
    ViewSwitchLightKit
}
#-------------------------------------------------------------------------------
# .PROC ViewUpdateLightIntensity
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewUpdateLightIntensity {args} {
    ViewSwitchLightKit
}

#-------------------------------------------------------------------------------
# .PROC ViewSwitchLightKit
# 
# .ARGS
# str state on or off
# .END
#-------------------------------------------------------------------------------
proc ViewSwitchLightKit {{state ""}} {
    global View

    if { $::View(LightKit,updating) } {
        return 
    }
    set ::View(LightKit,updating) 1
    


    set ren viewRen

    if {![info exists View(LightSavedHeadlight)]} {
        ViewSaveHeadlight
    }

    if {"$state" == ""} {
        if {$View(LightMode) == "Headlight"} {
            set state 0
        } else { set state 1 }
    }

    if {($state == 1 || "$state" == "on") && 
        $View(LightMode) == "Headlight"} {

        $View(LightKit) AddLightsToRenderer $ren
        $View(LightSavedHeadlight) SetIntensity 0.0

        set View(LightMode) "LightKit"

    } elseif {($state == 0 || "$state" == "off") && 
              $View(LightMode) == "LightKit"} {

        $View(LightKit) RemoveLightsFromRenderer $ren

        set View(LightMode) "Headlight"
    }

    if {$View(LightMode) == "Headlight"} {
        $View(LightSavedHeadlight) SetIntensity $View(LightIntensity)

        if { 0 } {
            catch {
                $View(HeadRatioScale) config -state disabled
                $View(FillRatioScale) config -state disabled
                if {$View(LightKitHasBackLights)} {
                    $View(BackRatioScale) config -state disabled
                }
            }
        }
    } else {
        if { 0 } {
            catch {
                $View(HeadRatioScale) config -state normal
                $View(FillRatioScale) config -state normal
                if {$View(LightKitHasBackLights)} {
                    $View(BackRatioScale) config -state normal              
                }
            }
        }
        $View(LightKit) SetKeyLightIntensity $View(LightIntensity)
        $View(LightKit) SetKeyToFillRatio $View(LightKeyToFillRatio)
        $View(LightKit) SetKeyToHeadRatio $View(LightKeyToHeadRatio)
        if {$View(LightKitHasBackLights)} {
            $View(LightKit) SetKeyToBackRatio $View(LightKeyToBackRatio)
        }

    }

    Render3D
    set ::View(LightKit,updating) 0
}

#-------------------------------------------------------------------------------
# .PROC ViewLightsSetDefaults
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ViewLightsSetDefaults {} {
    global View 
    
    set View(LightIntensity) $View(default,LightIntensity)
    set View(LightKeyToFillRatio) $View(default,LightKeyToFillRatio)
    set View(LightKeyToHeadRatio) $View(default,LightKeyToHeadRatio)
    set View(LightKeyToBackRatio) $View(default,LightKeyToBackRatio) 

    # update the 3d scene
    ViewSwitchLightKit
}


