#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainView.tcl,v $
#   Date:      $Date: 2006/07/27 18:27:05 $
#   Version:   $Revision: 1.56 $
# 
#===============================================================================
# FILE:        MainView.tcl
# PROCEDURES:  
#   MainViewInit
#   MainViewBuildVTK
#   MainViewBuildGUI
#   MainViewSelectView p
#   MainViewSetBackgroundColor col
#   MainViewSetTextureResolution res
#   MainViewSetTextureInterpolation interpolationFlag
#   MainViewSetFov sceneNum
#   MainViewSetParallelProjection
#   MainViewSetTexture
#   MainViewLightFollowCamera
#   MainViewNavReset x y cmd
#   MainViewRotate dir deg
#   MainViewNavRotate W x y cmd
#   MainViewSetStereo
#   MainViewSpin
#   MainViewRock
#   MainViewSetWelcome win
#   MainViewResetFocalPoint
#   MainViewSetFocalPoint x y z
#   MainViewStorePresets p
#   MainViewRecallPresets p
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC MainViewInit
# Initialise global variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewInit {} {
    global Module View Gui Path Preset Volume

    # set global flag (used to avoid possible render loop)
    set View(resetCameraClippingRange) 1

    if {$::Module(verbose)} { puts "Starting MainViewInit"}
    lappend Module(procStorePresets) MainViewStorePresets
    lappend Module(procRecallPresets) MainViewRecallPresets
    set Module(View,presets) "viewUp='0 0 1' position='0 750 0' \
focalPoint='0 0 0' clippingRange='21 2001' \
viewMode='Normal' viewBgColor='Blue' \
textureInterpolation='On' textureResolution='512' fov='240.0'"

    # The MainViewBuildGUI proc is called specifically
    lappend Module(procVTK)  MainViewBuildVTK

    set m MainView
    lappend Module(versions) [ParseCVSInfo $m \
    {$Revision: 1.56 $} {$Date: 2006/07/27 18:27:05 $}]

    set View(viewerHeightNormal) 656
    set View(viewerWidth)  956 
    set View(viewerHeight) 956 
    if {$Gui(pc) == 1} {
        set View(viewerHeightNormal) 400
        set View(viewerWidth)  700 
        set View(viewerHeight) 700 
    }

    # Configurable
    set View(mode) Normal
    set View(viewerWidth)  768 
    set View(viewerHeight) 700 
    set View(toolbarPosition) Top
    set View(bgColor) ".7 .7 .9"
    set View(bgName) Blue
    set View(fov) 240.0
    set View(spin) 0
    set View(rock) 0
    set View(rockLength) 200
    set View(rockCount) 0
    set View(spinDir) Right
    set View(spinMs) 5 
    set View(spinDegrees) 2 
    set View(stereo) 0
    set View(stereoType) RedBlue
    set View(closeupVisibility) On
    set View(createMagWin) Yes
    set View(textureResolution) 512
    set View(textureInterpolation) "On"
    set View(slice3DOpacity) 1

    # sp-2002-02-22: removed for 1.3; seems to work on modern Windows
    if {0} {
        # Bug in OpenGL on Windows98 version II ??
        if {$Gui(pc) == 1} {
            set View(createMagWin) No
            set View(closeupVisibility) Off
        }
    }

    # Lauren bugfix (temporary?) due to core dumps 
    # with vtk3.2 under Solaris.
    #set View(createMagWin) No
    #set View(closeupVisibility) Off

    # Init
    set View(rotateDegrees) 15
    set View(magWin) Welcome
    set View(inWin) none
    set View(viewPrefix) view
    set View(ext) .tif
}

#-------------------------------------------------------------------------------
# .PROC MainViewBuildVTK
# Build the vtk elements for this module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewBuildVTK {} {
    global View Slice

    # Set background color

        eval viewRen SetBackground $View(bgColor)

    # Closeup magnification of the slice with the cursor over it
    #--------------------------------------------
    
    #  [ActiveOutput] -----> mag -> magCursor -> magMapper

    # Create closeup magnification
    vtkImageCloseUp2D View(mag)
    View(mag) SetInput [Slicer GetOutput 0]
    View(mag) SetRadius 12
    View(mag) SetMagnification 7
    set View(closeupMag) 7

    # Closeup Cursor
    vtkImageCrossHair2D View(magCursor)
    View(magCursor) SetInput [View(mag) GetOutput]
    View(magCursor) SetCursor 87 87
    View(magCursor) BullsEyeOn
    View(magCursor) SetBullsEyeWidth 7
    View(magCursor) ShowCursorOn 
    View(magCursor) IntersectCrossOff
    View(magCursor) SetCursorColor 1 1 .5 
    View(magCursor) SetNumHashes 0 
    View(magCursor) SetHashLength 6
    View(magCursor) SetHashGap 10 
    View(magCursor) SetMagnification 1 
}

#-------------------------------------------------------------------------------
# .PROC MainViewBuildGUI
# Build the GUI
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewBuildGUI {} {
    global Gui View Slice viewWin

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Nav
    #    Top
    #      Dir
    #     Move
    #       Rotate
    #       FOV
    #   Bot
    #     Preset
    #     Center
    #     Parallel
    #-------------------------------------------

    #-------------------------------------------
    # View->Nav Frame
    #-------------------------------------------
    set f $Gui(fNav)
    
    frame $f.fTop -bg $Gui(activeWorkspace)
    frame $f.fBot -bg $Gui(activeWorkspace)
    pack $f.fTop -side top -padx 0 -pady 0 -fill both -expand true
    pack $f.fBot -side top -padx 0 -pady 0 -fill both -expand true

    #-------------------------------------------
    # View->Nav->Top Frame
    #-------------------------------------------
    set f $Gui(fNav).fTop
    
    frame $f.fDir     -bg $Gui(activeWorkspace) -bd $Gui(borderWidth) -relief sunken
#    frame $f.fPreset  -bg $Gui(activeWorkspace)
    frame $f.fMove    -bg $Gui(activeWorkspace)
    
#    pack $f.fDir $f.fPreset $f.fMove -side left -padx 3 -pady 0
    pack $f.fDir $f.fMove -side left -padx 3 -pady 0

    #-------------------------------------------
    # View->Nav->Top->Dir Frame
    #-------------------------------------------
    set f $Gui(fNav).fTop.fDir
    
    # Create control for setting view Direction
    foreach pict "N R L A P S I" {
        image create photo iDir$pict \
            -file [ExpandPath [file join gui "dir$pict.ppm"]]
    }        
    eval {label $f.lDir -image iDirN -width 74 -height 74 -anchor w} $Gui(WLA)
    bind $f.lDir <1>      {if {[MainViewNavReset %x %y click] == 1} {Render3D}}
    bind $f.lDir <Enter>  {MainViewNavReset %x %y      }
    bind $f.lDir <Leave>  {MainViewNavReset %x %y leave}
    bind $f.lDir <Motion> {MainViewNavReset %x %y      }
    pack $f.lDir
    set Gui(fDir) $f.lDir


    #-------------------------------------------
    # View->Nav->Top->Move Frame
    #-------------------------------------------
    set f $Gui(fNav).fTop.fMove
    
    frame $f.fRotate  -bg $Gui(activeWorkspace)
    frame $f.fFov  -bg $Gui(activeWorkspace)

    pack $f.fRotate $f.fFov -side top -pady 2 
    
    #-------------------------------------------
    # View->Nav->Top->Move->Rotate Frame
    #-------------------------------------------
    set f $Gui(fNav).fTop.fMove.fRotate
    
    # Create control for Rotating the view
    foreach pict "None Left Right Down Up" {
        image create photo iRotate${pict} \
            -file [ExpandPath [file join gui "rotate$pict.gif"]]            
    }
    label $f.lRotate -image iRotateNone -relief sunken -bd $Gui(borderWidth)
    bind $f.lRotate <1>      {MainViewNavRotate %W %x %y click}
    bind $f.lRotate <Enter>  {MainViewNavRotate %W %x %y      }
    bind $f.lRotate <Leave>  {MainViewNavRotate %W %x %y leave}
    bind $f.lRotate <Motion> {MainViewNavRotate %W %x %y      }

    pack $f.lRotate -side top -padx 0 -pady 0 

    #-------------------------------------------
    # View->Nav->Top->Move->Fov Frame
    #-------------------------------------------
    set f $Gui(fNav).fTop.fMove.fFov

    eval {label $f.lFov -text "FOV:"} $Gui(WLA)
    eval {entry $f.eFov -textvariable View(fov) -width 7} $Gui(WEA)
    bind $f.eFov <Return> {MainViewSetFov; RenderAll}
        TooltipAdd $f.eFov "field of view"
    pack $f.lFov $f.eFov -side left -padx 2 -pady 0

    #-------------------------------------------
    # View->Nav->Bot Frame
    #-------------------------------------------
    set f $Gui(fNav).fBot

    frame $f.fPreset  -bg $Gui(activeWorkspace)
    frame $f.fCenter  -bg $Gui(activeWorkspace)
    frame $f.fParallel  -bg $Gui(activeWorkspace)

    pack $f.fPreset $f.fCenter $f.fParallel -side top -pady 2 -fill x

    #-------------------------------------------
    # View->Nav->Bot->Preset Frame
    #-------------------------------------------
    set f $Gui(fNav).fBot.fPreset
    set View(fPreset) $f

    eval {label $f.lPreset -text "Views:"} $Gui(WLA)
    pack $f.lPreset -side left -padx 5 -pady 0

    # Preset Button
    
    eval {menubutton $f.cm -text "Select" -width 6 -menu $f.cm.m} $Gui(WBA)
    pack $f.cm -side left -padx 2
    
    # Store the widget path for later access
    set Gui(ViewMenuButton) $f.cm
    
    eval {menu $f.cm.m} $Gui(WMA)
    $f.cm.m add command -label "(none)"
    TooltipAdd $f.cm "Recall a previously saved view, right-click to save current view, shift-right-click to delete current view"
    bind $f.cm <ButtonRelease-3> "MainOptionsPresetSaveCreateDialog $f.cm"
    bind $f.cm <Shift-ButtonRelease-3> "MainOptionsPresetDeleteDialog $f.cm"

    #foreach p "1 2 3" {
    #    eval {button $f.c$p -text $p -width 2} $Gui(WBA)
    #    bind $f.c$p <ButtonPress>   "MainOptionsPreset $p Press"
    #    bind $f.c$p <ButtonRelease> "MainOptionsPreset $p Release"
    #    TooltipAdd $f.c$p "Saved view number $p: click to recall, hold down to save."
    #    pack $f.c$p -side left -padx 2 
    #}
    
    # MainViewSpin button
    eval {checkbutton $f.cMainViewSpin \
        -text "Spin" -variable View(spin) -width 4 \
        -indicatoron 0 -command "MainViewSpin"} $Gui(WCA)
    pack $f.cMainViewSpin -side left -padx 2 
    TooltipAdd $f.cMainViewSpin "Spin view: continuously rotate the 3D scene."

    # MainViewRock button
    eval {checkbutton $f.cMainViewRock \
        -text "Rock" -variable View(rock) -width 4 \
        -indicatoron 0 -command "MainViewRock"} $Gui(WCA)
    pack $f.cMainViewRock -side left -padx 2 
    TooltipAdd $f.cMainViewRock "Rock view: continuously rotate smoothly back and forth."

    #-------------------------------------------
    # View->Nav->Bot->Center Frame
    #-------------------------------------------
    set f $Gui(fNav).fBot.fCenter

    # Focalpoint button
    eval {button $f.bFocus -text "Move Focal Point to Center" -width 26 \
        -command "MainViewResetFocalPoint; RenderAll"} $Gui(WBA)
 
    pack $f.bFocus -side left -padx 3 -pady 0

    #-------------------------------------------
    # View->Nav->Bot->Parallel Frame
    #-------------------------------------------
    set f $Gui(fNav).fBot.fParallel

    # Parallel button
    eval {checkbutton $f.cParallel \
        -text "Parallel" -variable View(parallelProjection) -width 7 \
        -indicatoron 0 -command "MainViewSetParallelProjection"} $Gui(WCA)
        TooltipAdd $f.cParallel "Toggle parallel/perspective projection. No zooming in parallel projection mode."

     # Opacity Label
     eval {label $f.lSlice3DOpacity -text "Slice Opacity:"} $Gui(WLA)

     #  Opacity entry box
     eval {entry $f.eSlice3DOpacity  -textvariable View(slice3DOpacity)} $Gui(WEA)
     TooltipAdd $f.eSlice3DOpacity  "Opacity of slices in 3D scene. (Between 0 and 1)"
     bind $f.eSlice3DOpacity  <Return> {MainSlicesSet3DOpacityAll $View(slice3DOpacity)}

     pack $f.cParallel $f.lSlice3DOpacity $f.eSlice3DOpacity \
         -side left -padx 3
}

#-------------------------------------------------------------------------------
# .PROC MainViewSelectView
# Select a saved view.
# .ARGS
# int p view id
# .END
#-------------------------------------------------------------------------------
proc MainViewSelectView {p} {
    global Gui
    
    MainOptionsPreset $p Press
    MainOptionsPreset $p Release
    $Gui(ViewMenuButton) config -text "$p"
}

#-----------------------------------------------------------------------------
# .PROC MainViewSetBackgroundColor
#  Change the background color of all the renderers in Module(Renderers)
#  The background color is stored in View(bgName) and it should match \"Blue\",
#  \"Midnight\",\"Black\" or \"White\"
#
# .ARGS
# string col value of the color, optional, use View(bgName) if not set
# .END
#-----------------------------------------------------------------------------
proc MainViewSetBackgroundColor {{col ""}} {
    global View Module
    
    
    # set View(bgName) if called with an argument
    if {$col != ""} {
        if {$col == "Blue" || $col == "Black" || $col == "Midnight" || $col == "White"} {
            set View(bgName) $col
        } else {
            if {$::Module(verbose)} {
                DevInfoWindow "MainViewSetBackgroundColor:\nInvalid background colour selected, $col.\nValid colours are Blue, Black, Midnight, White"
            }
            return
        }   
    }    
    
    switch $View(bgName) {
        "Blue" {
            set View(bgColor) "0.7 0.7 0.9"
        }
        "Black" {
            set View(bgColor) "0 0 0"
        }
        "Midnight" {
            set View(bgColor) "0 0 0.3"
        }
        "White" {
            set View(bgColor) "1 1 1"
        }
    }

    # make sure color of axis letters contrasts with background
    foreach axis "R A S L P I" {
        if {$View(bgName)=="White"} {
            [${axis}Actor GetProperty] SetColor 0 0 1
        } else {
            [${axis}Actor GetProperty] SetColor 1 1 1
        }   
    }
    
    foreach m $Module(Renderers) {
        eval $m SetBackground $View(bgColor)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetTextureResolution
# sets the texture resolution
# .ARGS
# int res resolution to set it to
# .END
#-------------------------------------------------------------------------------
proc MainViewSetTextureResolution { {res 512}} {
    global View

    if {$::Module(verbose)} { puts "MainViewSetTextureResolution $res"}
    set View(textureResolution) $res
    # MainViewSetTexture
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetTextureInterpolation
# sets the texture interpolation to On or Off
# .ARGS
# boolean interpolationFlag value to set interpolation flag to, defaults to On
# .END
#-------------------------------------------------------------------------------
proc MainViewSetTextureInterpolation { {interpolationFlag "On"}} {
    global View

    if {$::Module(verbose)} { puts  "MainViewSetTextureInterpolation $interpolationFlag" }
    set View(textureInterpolation) $interpolationFlag
    # MainViewSetTexture
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetFov
# Set the field of view for Slicer object, Anno and Slices.
# If a new field of view is passed in, only use it if the fov hasn't been changed
# yet away from the default, or if it has, use it if the new number is greater than the old
# .ARGS
# int sceneNum if default, reset the main view's camera, otherwise leave it alone
# float fov if not changed from default, use View(fov), otherwise use it
# .END
#-------------------------------------------------------------------------------
proc MainViewSetFov { {sceneNum "default"} {fov -1.0} } {
    global View Gui Slice

    if {$fov != -1.0} {
         if {$View(fov) == $::Preset(View,default,fov) ||
             ($View(fov) != $::Preset(View,default,fov) && $fov > $View(fov))} {
             set View(fov) $fov
         } else {
            puts "MainViewSetFov: Not decreasing fov from $View(fov) to $fov"
         }
    }

    if {$::Module(verbose)} {
        puts "MainViewSetFov View(fov) = $View(fov), current fov = [Slicer GetFieldOfView], sceneNum = $sceneNum, viewcam position = [$View(viewCam) GetPosition]"
    }
    Slicer SetFieldOfView $View(fov)
    if {$sceneNum == "default"} {
        MainViewNavReset 55 42 click
        MainViewNavReset 0 0 leave
    }

    # Update slice offset, registration annotation
    MainAnnoSetFov
    MainSlicesSetFov

}

#-------------------------------------------------------------------------------
# .PROC MainViewSetParallelProjection
# Turn on/off parallel projection for the camera.
# Uses View(parallelProjection) to get the flag value.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetParallelProjection {} {
    global View Gui Slice

    if {$View(parallelProjection) == 1} {
        $View(viewCam) ParallelProjectionOn
        $View(viewCam) SetParallelScale $View(fov)
    } else {
        $View(viewCam) ParallelProjectionOff
    }    

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetTexture
# Applies current texture settings to the vtk pipeline
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetTexture {} {
    global View 

    if {$::Module(verbose)} { puts "Starting MainViewSetTexture" }
    for {set s 0} {$s < 3} {incr s} {
        Slice($s,texture) Interpolate$View(textureInterpolation)
        [Slicer GetBackReformat3DView $s] SetResolution $View(textureResolution)
        [Slicer GetForeReformat3DView $s] SetResolution $View(textureResolution)
        [Slicer GetLabelReformat3DView $s] SetResolution $View(textureResolution)
        if { [info command MatSlicer] != "" } {
            [MatSlicer GetBackReformat3DView $s] SetResolution $View(textureResolution)
            [MatSlicer GetForeReformat3DView $s] SetResolution $View(textureResolution)
            [MatSlicer GetLabelReformat3DView $s] SetResolution $View(textureResolution)
        }
    }
    Render3D
    if {$::Module(verbose)} { puts "Done MainViewSetTexture" }

}

#-------------------------------------------------------------------------------
# .PROC MainViewLightFollowCamera
# Reset the position and focal point of all lights to the View(viewCam) position and focal point.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewLightFollowCamera {} {
    global View
    
    # 3D Viewer

    set lights [viewRen GetLights]

    $lights InitTraversal
    set currentLight [$lights GetNextItem]
    if {$currentLight != ""} {
        eval $currentLight SetPosition   [$View(viewCam) GetPosition]
        eval $currentLight SetFocalPoint [$View(viewCam) GetFocalPoint]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainViewNavReset
#
# Returns 1 if window should be rendered
# .ARGS
# int x
# int y
# string cmd defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc MainViewNavReset {x y {cmd ""}} {
    global dirWin View Target Gui

    if {$cmd == "leave"} {
        $Gui(fDir) config -cursor top_left_arrow -image iDirN
        return 0
    }
    set directions "R L A P S I"
    set xList  "10 65 55 17 40 40"
    set yList  "36 23 42 13 10 65"

    set fp [$View(viewCam) GetFocalPoint]
    set r [lindex $fp 0]
    set a [lindex $fp 1]
    set s [lindex $fp 2]

    foreach dir $directions {
        set i [lsearch $directions $dir]
        set X [lindex  $xList  $i]
        set Y [lindex  $yList  $i]

        if {$x > [expr $X - 10] && $x < [expr $X + 10] && \
            $y > [expr $Y - 10] && $y < [expr $Y + 10]} {
            
            $Gui(fDir) config -cursor hand2 -image iDir$dir

            if {$cmd == "click"} {
                set d [expr $View(fov) * 3]

                switch $dir {
                    R {
                        $View(viewCam) SetPosition   [expr $r+$d] $a   $s
                        $View(viewCam) SetViewUp     0   0   1
                    }
                    A {
                        $View(viewCam) SetPosition   $r   [expr $a+$d] $s
                        $View(viewCam) SetViewUp     0   0   1
                    }
                    S {
                        $View(viewCam) SetPosition    $r   $a    [expr $s+$d]
                        $View(viewCam) SetViewUp     0   1   0
                    }
                    L {
                        $View(viewCam) SetPosition   [expr $r-$d] $a   $s
                        $View(viewCam) SetViewUp     0   0   1
                    }
                    P {
                        $View(viewCam) SetPosition    $r   [expr $a-$d] $s
                        $View(viewCam) SetViewUp     0   0   1
                    }
                    I {
                        $View(viewCam) SetPosition    $r   $a    [expr $s-$d]
                        $View(viewCam) SetViewUp     0   1   0
                    }
                }
                viewRen ResetCameraClippingRange
                $View(viewCam) ComputeViewPlaneNormal
                $View(viewCam) OrthogonalizeViewUp

                MainViewLightFollowCamera
                return 1
            }
            return 0
        }
    }
    $Gui(fDir) config -cursor top_left_arrow -image iDirN
}

#-------------------------------------------------------------------------------
# .PROC MainViewRotate
# 
# .ARGS
# str dir is Up Down Left Right
# float deg is the number of degrees to rotate, default \$View(rotateDegrees)
# .END
#-------------------------------------------------------------------------------
proc MainViewRotate {dir {deg rotate}} {
    global View

    if {$deg == "rotate"} {
        set p $View(rotateDegrees)
    } else {
        set p $deg
    }            
    set n [expr -$p]
    
    switch $dir {
        Down  {$View(viewCam) Elevation $p }
        Up    {$View(viewCam) Elevation $n }
        Left  {$View(viewCam) Azimuth $p }
        Right {$View(viewCam) Azimuth $n }
    }
    $View(viewCam) OrthogonalizeViewUp

    MainViewLightFollowCamera
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MainViewNavRotate
# 
# .ARGS
# windowpath W 
# int x
# int y
# string cmd defaults to empty string 
# .END
#-------------------------------------------------------------------------------
proc MainViewNavRotate {W x y {cmd ""}} {

    set directions "Up Down Left Right"
    set xList      "28 28 9 47"
    set yList      " 9 47 28 28"

    if {$cmd == "leave"} {
        $W config -cursor top_left_arrow -image iRotateNone
        return
    }
    foreach dir $directions {
        set i [lsearch $directions $dir]
        set X [lindex  $xList  $i]
        set Y [lindex  $yList  $i]

        if {$x > [expr $X - 10] && $x < [expr $X + 10] && \
            $y > [expr $Y - 10] && $y < [expr $Y + 10]} {
            $W config -cursor hand2 -image iRotate${dir}
            if {$cmd == "click"} {
                MainViewRotate $dir
            }
            return
        }
    }
    $W config -cursor top_left_arrow -image iRotateNone
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetStereo
# Checks the View(stereo) flag, and resets the view window.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetStereo {} {
    global viewWin View

    if {$View(stereo) == "1"} {
        $viewWin SetStereoTypeTo$View(stereoType)
        $viewWin StereoRenderOn
    } else {
        $viewWin StereoRenderOff
    }
}

#-------------------------------------------------------------------------------
# .PROC MainViewSpin
#
# To spin, set View(spinDir) = 1;
# Then call MainViewSpin. 
# To stop spinning, set View(spinDir) = 0;
# <br>
# Note that this calls MainViewRotate, which calls Render3D
# so that saving a spinning movie is easy, simply turn on View(movie).
# <br>
# Rotates the 3D Window in the direction View(spinDir).
# Rotates View(spinDegrees) degrees.
# Waits some amount of time given by View(spinMs).
# Then repeats.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSpin {} {
    global View

    if {$View(spin) == "1"} {

        set View(rock) 0

        MainViewRotate $View(spinDir) $View(spinDegrees)
        update idletasks
        after $View(spinMs) MainViewSpin
    }
}

#-------------------------------------------------------------------------------
# .PROC MainViewRock
#
# Shares a lot with MainviewSpin above, but gently rocks back and forth
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewRock {} {
    global View

    if {$View(rock) == "1"} {

        set View(spin) 0

        set cam [viewRen GetActiveCamera]
        set p [expr (1.0 * $View(rockCount)) / $View(rockLength)]
        set amt [expr 1.5 * cos ( 2.0 * 3.1415926 * ($p - floor($p)) ) ]
        incr View(rockCount)

        $cam Azimuth $amt
        Render3D

        update idletasks
        after $View(spinMs) MainViewRock
    }
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetWelcome
# Switch between the controls and the logo window.
# .ARGS
# string win name of the current window that's on top
# .END
#-------------------------------------------------------------------------------
proc MainViewSetWelcome {win} {
    global Edit Gui Slice View

    # Do nothing if no change
    if {$win == $View(magWin)} {return}

    if {$win == "Controls"} {
        # The gui may not be created yet
        if {[info exists Gui(fNav)] == 1} {
            raise $Gui(fNav)
        }
    } elseif {$win == "Welcome"} {
        if {[info exists Gui(fWelcome)] == 1} {
            raise $Gui(fWelcome)
        }
    } else {
        if {$View(createMagWin) == "Yes" && $View(closeupVisibility) == "On"} {
            if {[info exists Gui(fMagBorder)] == 1} {
                raise $Gui(fMagBorder)
                set s [string index $win 2]
                View(mag) SetInput [Slicer GetActiveOutput $s]
                magMapper SetInput [View(magCursor) GetOutput]
                magWin Render
            }
        }
    }
    
    set View(magWin) $win
}
        
#-------------------------------------------------------------------------------
# .PROC MainViewResetFocalPoint
# Calls MainViewSetFocalPoint with the origin.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewResetFocalPoint {} {
    global View Slice
                
    MainViewSetFocalPoint 0 0 0
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetFocalPoint
# Set the view camera's focal point and the slices focal point, update the anno focal point
# .ARGS
# float x x coordinate of new focal point
# float y y coordinate of new focal point
# float z z coordinate of new focal point
# .END
#-------------------------------------------------------------------------------
proc MainViewSetFocalPoint {x y z} {
    global Slice View

    set View(focalPoint) "$x $y $z"
    eval $View(viewCam) SetFocalPoint $View(focalPoint)
    $View(viewCam) ComputeViewPlaneNormal
    $View(viewCam) OrthogonalizeViewUp

    MainViewLightFollowCamera

    #SLICES
    Slicer ComputeNTPFromCamera $View(viewCam)

# BUG: This causes slice offset to not work with presets
#    foreach s $Slice(idList) {
#        if {[lsearch "Axial Sagittal Coronal Perp InPlane0 InPlane90 \
#            InPlaneNeg90" [Slicer GetOrientString $s]] != -1} {
#            MainSlicesSetOffset $s 0
#        }
#    }

    MainAnnoUpdateFocalPoint $x $y $z
}

#-------------------------------------------------------------------------------
# .PROC MainViewStorePresets
# store the presets for this view id. camera values, texture resolution, mode, 
# background colour.
# .ARGS
# int p view id
# .END
#-------------------------------------------------------------------------------
proc MainViewStorePresets {p} {
    global Preset View

    if {$::Module(verbose)} { puts "Starting MainViewSTOREPresets" }

    set Preset(View,$p,position)      [$View(viewCam) GetPosition]
    set Preset(View,$p,viewUp)        [$View(viewCam) GetViewUp]
    set Preset(View,$p,focalPoint)    [$View(viewCam) GetFocalPoint]
    set Preset(View,$p,clippingRange) [$View(viewCam) GetClippingRange]
    set Preset(View,$p,viewMode)      $View(mode)
    set Preset(View,$p,viewBgColor)   $View(bgName)

    set Preset(View,$p,textureResolution) $View(textureResolution)
    set Preset(View,$p,textureInterpolation) $View(textureInterpolation)

    set Preset(View,$p,fov) $View(fov)

    if {$::Module(verbose)} { puts "Done MainViewStorePresets" }

}

#-------------------------------------------------------------------------------
# .PROC MainViewRecallPresets
# Set the view camera, textures, etc. from the saved values to restore a view.
# .ARGS
# int p id of the saved view
# .END
#-------------------------------------------------------------------------------
proc MainViewRecallPresets {p} {
    global Preset View

    if {$::Module(verbose)} { 
        puts "Starting MainViewRecallPresets" 
        puts "\tUsing position $Preset(View,$p,position)\n\tviewUp $Preset(View,$p,viewUp)\n\t(current pos = [$View(viewCam) GetPosition], viewUp = [$View(viewCam) GetViewUp]"
    
        puts "Setting the view mode first"
    }
    eval MainViewerSetMode $Preset(View,$p,viewMode)

    eval $View(viewCam) SetPosition      $Preset(View,$p,position)
    eval $View(viewCam) SetViewUp        $Preset(View,$p,viewUp)
    eval $View(viewCam) SetClippingRange $Preset(View,$p,clippingRange)

    eval MainViewSetFocalPoint $Preset(View,$p,focalPoint)
    eval MainViewSetBackgroundColor $Preset(View,$p,viewBgColor)

    if {$::Module(verbose)} { 
        puts "\tMainViewRecallPresets $p, after set focal point, about to call texture res View(viewCam) position = [$View(viewCam) GetPosition]"
    }

    eval MainViewSetTextureResolution $Preset(View,$p,textureResolution)
    eval MainViewSetTextureInterpolation $Preset(View,$p,textureInterpolation)
    # this call sets it for the slices
    MainViewSetTexture 

    if {$::Module(verbose)} {
        puts "\tMainViewRecallPresets: getting fov preset for $p and setting fov $Preset(View,$p,fov)"
    }
    set View(fov) $Preset(View,$p,fov)
    # pass in the scene id so that MainViewNavReset doesn't get called
    MainViewSetFov $p
}
