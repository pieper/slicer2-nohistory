#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainSlices.tcl,v $
#   Date:      $Date: 2006/10/26 17:48:10 $
#   Version:   $Revision: 1.67 $
# 
#===============================================================================
# FILE:        MainSlices.tcl
# PROCEDURES:  
#   MainSlicesInit
#   MainSlicesBuildVTK
#   MainSlicesBuildVTKForSlice
#   MainSlicesBuildControlsForVolume widget int str str
#   MainSlicesBuildControls s F
#   MainSlicesBuildAdvancedControlsPopup
#   MainSlicesUpdateMRML
#   MainSlicesVolumeParam int str str
#   MainSlicesSetClipState int int
#   MainSlicesRefreshClip int
#   MainSlicesSetFov
#   MainSlicesCenterCursor int
#   MainSlicesKeyPress str
#   MainSlicesSetActive
#   MainSlicesSetVolumeAll
#   MainSlicesSetVolume string int int
#   MainSlicesSetOffsetInit
#   MainSlicesSetOffset int float
#   MainSlicesSetSliderRange int
#   MainSlicesSetAnno
#   MainSlicesSetOrientAll
#   MainSlicesSetOrient int string
#   MainSlicesResetZoomAll
#   MainSlicesSetZoomAll
#   MainSlicesConfigGui int string string
#   MainSlicesSetZoom
#   MainSlicesSetVisibilityAll
#   MainSlicesSetVisibility
#   MainSlicesUserReformat id
#   MainSlicesSetOpacityAll int
#   MainSlicesSetOpacityToggle int
#   MainSlicesSetFadeAll bool
#   MainSlicesSetClipType or
#   MainSlicesSave
#   MainSlicesSavePopup
#   MainSlicesWrite
#   MainSlicesStorePresets
#   MainSlicesRecallPresets
#   MainSlicesOffsetToPoint
#   MainSlicesAllOffsetToPoint
#   MainSlicesAdvancedControlsPopup
#   MainSlicesSetOffsetIncrement int float
#   MainSlicesSet3DOpacity s opacity
#   MainSlicesReset3DOpacityAll
#   MainSlicesSet3DOpacityAll opacity
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainSlicesInit
# Init proc called by slicer at startup
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesInit {} {
    global Slice Module

    # Define Procedures
    lappend Module(procVTK)  MainSlicesBuildVTK
    lappend Module(procMRML) MainSlicesUpdateMRML
    lappend Module(procStorePresets) MainSlicesStorePresets
    lappend Module(procRecallPresets) MainSlicesRecallPresets

    # Preset Defaults
    set Module(Slices,presets) "opacity='1.0' fade='0' clipType='Intersection' \
0,visibility='0' 0,backVolID='0' 0,foreVolID='0' 0,labelVolID='0' \
0,orient='Axial' 0,offset='0' 0,zoom='1.0' 0,clipState='0'\
1,visibility='0' 1,backVolID='0' 1,foreVolID='0' 1,labelVolID='0' \
1,orient='Sagittal' 1,offset='0' 1,zoom='1.0' 1,clipState='0' \
2,visibility='0' 2,backVolID='0' 2,foreVolID='0' 2,labelVolID='0' \
2,orient='Coronal' 2,offset='0' 2,zoom='1.0' 2,clipState='0'"

        # Set version info
        lappend Module(versions) [ParseCVSInfo MainSlices \
        {$Revision: 1.67 $} {$Date: 2006/10/26 17:48:10 $}]

    # Initialize Variables
    set Slice(idList) "0 1 2"

    set Slice(opacity) 0.5
    set Slice(clipType) Intersection
    set Slice(visibilityAll) 0
    set Slice(activeID) 0 
    set Slice(0,controls) ""
    set Slice(1,controls) ""
    set Slice(2,controls) ""
    set Slice(0,offset) 0
    set Slice(1,offset) 0
    set Slice(2,offset) 0

    set Slice(0,addedFunction) 0
    set Slice(1,addedFunction) 0
    set Slice(2,addedFunction) 0

    set Slice(xAnno) 0  
    set Slice(yAnno) 0 
    set Slice(xScrAnno) 0 
    set Slice(yScrAnno) 0

    foreach s $Slice(idList) {
        set Slice($s,id) 0
        set Slice($s,visibility) 0
        set Slice($s,clipState) 1
        set Slice($s,zoom) 1 
        set Slice($s,driver) User
        set Slice($s,orient) Axial
        set Slice($s,offsetAxia) 0
        set Slice($s,offsetSagittal) 0
        set Slice($s,offsetCoronal) 0
        set Slice($s,offsetInPlane) 0
        set Slice($s,offsetInPlane90) 0
        set Slice($s,offsetInPlaneNeg90) 0
        set Slice($s,offsetPerp) 0
        set Slice($s,offsetUser) 0
        set Slice($s,offsetOrigSlice) Auto
        set Slice($s,offsetAxiSlice) Auto
        set Slice($s,offsetCorSlice) Auto
        set Slice($s,offsetSagSlice) Auto
        set Slice($s,backVolID) 0
        set Slice($s,foreVolID) 0
        set Slice($s,labelVolID) 0
        set Slice($s,offsetIncrement) 1
    }
}

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
#
# Slice(activeID)               :
# Slice(idList)                 : Usually 0 1 2: the 3 slice showing windows.
# Slice(num)                    : # of slices in idList.
# Slice(visibilityAll)          : 1 = AllSlices Visible in 3D. 0 = Not.
# Slice(xAnno)                  :  Not Sure, Used in SlicesEvents.tcl
# Slice(xScrAnno)               : 
# Slice(yAnno)                  : 
# Slice(yScrAnno)               : 
# Slice(clipPlanes)             : instance of vtkImplicitBoolean, used to
#                                 determine clip regions
# Slice(clipType)               : "Intersection" or "Union", deals with the
#                                 way to deal with clipping from many slices
#
#  id is a number in Slice(idList)
#                               
# Slice(id,addedFunction)       : 1 = Addedfunction for clipping. 0 = None.
# Slice(id,backVolID)           : id of the Volume in the background.
# Slice(id,clipState)           : 1 and 2 use clipping. 0 is no clipping.
# Slice(id,clipPlane)           : instance of vtkPlane, used for clipping.
# Slice(id,driver)              : Set to "User" in slicer.config. Never Used.
# Slice(id,foreVolID)           : id of the Volume in the foreground
# Slice(id,labelVolID)          : id of the Label Volume 
# Slice(id,offset)              : The value on the offset slider
# Slice(id,offsetAxiSlice)      : 
# Slice(id,offsetAxial)         : No Idea
# Slice(id,offsetCorSlice)      :
# Slice(id,offsetCoronal)       :
# Slice(id,offsetInPlane)       :
# Slice(id,offsetInPlane90)     :
# Slice(id,offsetInPlaneNeg90)  :
# Slice(id,offsetOrigSlice)     :
# Slice(id,offsetPerp)          :
# Slice(id,offsetUser)          :
# Slice(id,offsetSagSlice)      :
# Slice(id,offsetSagittal)      :
# Slice(id,orient)              : 
# Slice(id,visibility)          : Is the plane visible in the 3D viewer?
# Slice(id,zoom)                : 1,2 4 or 8 : The Zoom on the slice.
# Slice(id,offsetIncrement)     : in mm, the amount the offset slider moves by
#

#-------------------------------------------------------------------------------
# .PROC MainSlicesBuildVTK
# Build VTK objects.  slice actors, clipping planes, textures, etc for
# all display in the 3D Viewer window.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesBuildVTK {} {
    global View Volume Slice Model Gui View

    # Clipping
    vtkImplicitBoolean Slice(clipPlanes)
        Slice(clipPlanes) SetOperationTypeToIntersection

        set Slice(clipType) "Intersection"

    foreach s $Slice(idList) {
        vtkPlane Slice($s,clipPlane)
        Slice(clipPlanes) AddFunction Slice($s,clipPlane)
        MainSlicesRefreshClip $s
    }

    foreach s $Slice(idList) {
        #Build VTK objects
        MainSlicesBuildVTKForSliceActor $s
  
        #Set input from vtkMrmlSlicer Slicer object
        Slice($s,texture) SetInput [Slicer GetOutput $s]
        Slice($s,outlineActor) SetUserMatrix [Slicer GetReformatMatrix $s]
        Slice($s,planeActor) SetUserMatrix [Slicer GetReformatMatrix $s]
    
        # add to the scene
        MainAddActor Slice($s,outlineActor)
        MainAddActor Slice($s,planeActor)

        # Clip
        MainSlicesSetClipState $s
    }

    # Color of slice outline
    [Slice(0,outlineActor) GetProperty] SetColor 0.9 0.1 0.1
    [Slice(1,outlineActor) GetProperty] SetColor 0.9 0.9 0.1
    [Slice(2,outlineActor) GetProperty] SetColor 0.1 0.9 0.1
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesBuildVTKForSlice
# Build VTK objects for slice actors that are displayed in the 3D Viewer window.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesBuildVTKForSliceActor {s} {
    global Slice View

    vtkTexture Slice($s,texture)
    Slice($s,texture) SetQualityTo32Bit
    
    vtkPlaneSource Slice($s,planeSource)
    
    vtkPolyDataMapper Slice($s,planeMapper)
    Slice($s,planeMapper) SetInput [Slice($s,planeSource) GetOutput]
    
    vtkActor Slice($s,planeActor)
    Slice($s,planeActor) SetScale      $View(fov) $View(fov) 1.0
    Slice($s,planeActor) SetPickable   1
    Slice($s,planeActor) SetTexture    Slice($s,texture)
    Slice($s,planeActor) SetMapper     Slice($s,planeMapper)
    Slice($s,planeActor) SetVisibility $Slice($s,visibility) 
    [Slice($s,planeActor) GetProperty] SetAmbient 1
    [Slice($s,planeActor) GetProperty] SetDiffuse 0
    [Slice($s,planeActor) GetProperty] SetSpecular 0
    
    vtkOutlineSource Slice($s,outlineSource)
    Slice($s,outlineSource) SetBounds -0.5 0.5 -0.5 0.5 0.0 0.0
    
    vtkPolyDataMapper Slice($s,outlineMapper)
    Slice($s,outlineMapper) SetInput [Slice($s,outlineSource) GetOutput]
    Slice($s,outlineMapper) ImmediateModeRenderingOn
    
    vtkActor Slice($s,outlineActor)
    Slice($s,outlineActor) SetMapper     Slice($s,outlineMapper)
    Slice($s,outlineActor) SetScale      $View(fov) $View(fov) 1.0
    Slice($s,outlineActor) SetPickable   0
    Slice($s,outlineActor) SetVisibility $Slice($s,visibility) 
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesBuildControlsForVolume
# Build volume selection controls for a slice in frame f.
# .ARGS
# f widget frame to place controls in
# s int slice (0,1,2)
# layer str one of Fors, Back, Label
# text str initial text for menubutton over menu (None for example)
# .END
#-------------------------------------------------------------------------------
proc MainSlicesBuildControlsForVolume {f s layer text} {
    global Gui

    # All Slices
    eval {menubutton $f.mb${layer}Volume -text "${text}:" -width 3 \
        -menu $f.mb${layer}Volume.m} $Gui(WMBA)
    eval {menu $f.mb${layer}Volume.m} $Gui(WMA)
    bind $f.mb${layer}Volume <Button-3> "MainVolumesPopupGo $layer $s %X %Y"
    # tooltip for slices in this layer
    TooltipAdd $f.mb${layer}Volume "Volume selection: choose a volume \
        to appear\nin the $layer layer in all three slice windows.\n\
        Right-click for volume display menu."

    # This Slice
    eval {menubutton $f.mb${layer}Volume${s} -text None -width 13 \
        -menu $f.mb${layer}Volume${s}.m} $Gui(WMBA) {-bg $Gui(slice$s)}
    eval {menu $f.mb${layer}Volume${s}.m} $Gui(WMA)
    bind $f.mb${layer}Volume$s <Button-3> "MainVolumesPopupGo $layer $s %X %Y"            
    # tooltip for this slice in this layer
    TooltipAdd $f.mb${layer}Volume${s} "Volume Selection: choose a volume\
        to appear\nin the $layer layer in just this slice window.\n\
        Right-click for volume display menu."    
    pack $f.mb${layer}Volume $f.mb${layer}Volume${s} \
        -pady 0 -padx 2 -side left -fill x
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesBuildControls
# 
# Called from MainViewer.tcl in MainViewerBuildGUI.
# Builds all controls above a slice window.  Also called to
# build the same controls for the Slices module.
# .ARGS
#  int s the id of the Slice
#  str F the name of the Slice Window
# .END
#-------------------------------------------------------------------------------
proc MainSlicesBuildControls {s F} {
    global Gui View Slice

    lappend Slice($s,controls) $F

    frame $F.fOffset -bg $Gui(activeWorkspace)
    frame $F.fOrient -bg $Gui(activeWorkspace)
    frame $F.fVolume -bg $Gui(activeWorkspace)

    pack $F.fOffset $F.fOrient $F.fVolume \
        -fill x -side top -padx 0 -pady 3

    # Offset
    #-------------------------------------------
    set f $F.fOffset
    set fov2 [expr $View(fov) / 2]

    eval {entry $f.eOffset -width 4 -textvariable Slice($s,offset)} $Gui(WEA)
        bind $f.eOffset <Return>   "MainSlicesSetOffset $s; RenderBoth $s"
        bind $f.eOffset <FocusOut> "MainSlicesSetOffset $s; RenderBoth $s"

    # tooltip for entry box
    set tip "Current slice: in mm or slice increments,\n \
        depending on the slice orientation you have chosen.\n \
        The default (AxiSagCor orientation) is in mm. \n \
        When editing (Slices orientation), slice numbers are shown.\n\
        To change the distance between slices from the default\n\
        1 mm, right-click on the V button."

    TooltipAdd $f.eOffset $tip

    eval {scale $f.sOffset -from -$fov2 -to $fov2 \
        -variable Slice($s,offset) -length 160 -resolution 1.0 -command \
        "MainSlicesSetOffsetInit $s $f.sOffset"} $Gui(WSA) \
        {-troughcolor $Gui(slice$s)}


    pack $f.sOffset $f.eOffset -side left -anchor w -padx 2 -pady 0

    # Visibility
    #-------------------------------------------

    # This Slice
    eval {checkbutton $f.cVisibility${s} \
        -variable Slice($s,visibility) -indicatoron 0 -text "V" -width 2 \
        -command "MainSlicesSetVisibility ${s}; \
        MainViewerHideSliceControls; Render3D"} $Gui(WCA) \
        {-selectcolor $Gui(slice$s)}
    # tooltip for Visibility checkbutton
    TooltipAdd $f.cVisibility${s} "Click to make this slice visible.\n \
        Right-click for menu: \nzoom, slice increments, \
        volume display."

    pack $f.cVisibility${s} -side left -padx 2


    # Menu on the Visibility checkbutton
    eval {menu $f.cVisibility${s}.men} $Gui(WMA)
    set men $f.cVisibility${s}.men
    $men add command -label "All Visible" \
        -command "MainSlicesSetVisibilityAll 1; MainViewerHideSliceControls; Render3D"
    $men add command -label "All Invisible" \
        -command "MainSlicesSetVisibilityAll 0; MainViewerHideSliceControls; Render3D"
    $men add command -label "Reset zoom" -command \
        "MainSlicesResetZoomAll; MainViewerHideSliceControls; RenderSlices"
    $men add command -label "Zoom all x2" -command \
        "MainSlicesSetZoomAll 2; MainViewerHideSliceControls; RenderSlices"
    $men add command -label "Zoom all x3" -command \
        "MainSlicesSetZoomAll 3; MainViewerHideSliceControls; RenderSlices"
    $men add command -label "Auto Window/Level" -command \
        "MainSlicesVolumeParam $s AutoWindowLevel 1"
    $men add command -label "No Threshold" -command \
        "MainSlicesVolumeParam $s AutoThreshold -1"
    $men add command -label "Set Zoom" -command \
        "MainSlicesAdvancedControlsPopup $s"
    $men add command -label "Set Slice Increment" -command \
        "MainSlicesAdvancedControlsPopup $s"
    $men add command -label "-- Close Menu --" -command "$men unpost"
    bind $f.cVisibility${s} <Button-3> "$men post %X %Y"

    # Orientation
    #-------------------------------------------
    set f $F.fOrient

    # All Slices
    eval {menubutton $f.mbOrient -text "Or:" -width 3 -menu $f.mbOrient.m} \
        $Gui(WMBA) {-anchor e}
    pack $f.mbOrient -side left -pady 0 -padx 2 -fill x
    # tooltip for orientation menu
    TooltipAdd $f.mbOrient "Set Orientation of all slices."

    eval {menu $f.mbOrient.m} $Gui(WMA)
    foreach item "AxiSagCor Orthogonal Slices ReformatAxiSagCor" {
        $f.mbOrient.m add command -label $item -command \
            "MainSlicesSetOrientAll $item; MainViewerHideSliceControls; RenderAll"
    }

    # This slice
    eval {menubutton $f.mbOrient${s} -text INIT -menu $f.mbOrient${s}.m \
        -width 13} $Gui(WMBA) {-bg $Gui(slice$s)}
    pack $f.mbOrient${s} -side left -pady 0 -padx 2 -fill x

    # tooltip for orientation menu for slice
    TooltipAdd $f.mbOrient${s} "Set Orientation of just this slice."

    eval {menu $f.mbOrient${s}.m} $Gui(WMA)
    set Slice($s,menu) $f.mbOrient${s}.m
    foreach item "[Slicer GetOrientList]" {
        $f.mbOrient${s}.m add command -label $item -command \
            "MainSlicesSetOrient ${s} $item; MainViewerHideSliceControls; RenderBoth $s"
    }
    #$f.mbOrient${s}.m add command -label "Arbitrary" -command \
        #    "MainSlicesSetOrient Arbitrary $item; MainViewerHideSliceControls; RenderBoth $s"
    
    
    # Background Volume
    #-------------------------------------------
    MainSlicesBuildControlsForVolume $f $s Back Bg

    # Foreground/Label Volumes row
    #-------------------------------------------
    set f $F.fVolume

    MainSlicesBuildControlsForVolume $f $s Label Lb
    MainSlicesBuildControlsForVolume $f $s Fore  Fg

    MainSlicesBuildAdvancedControlsPopup $s

}


#-------------------------------------------------------------------------------
# .PROC MainSlicesBuildAdvancedControlsPopup
# Build the advanced slice controls window for one slice.  Pop it up 
# by calling proc MainSlicesAdvancedControlsPopup.
# Currently the window supports manual zoom entry and also
# setting of the slice slider increment value.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesBuildAdvancedControlsPopup {s} {
    global Gui

    # This is since the slice GUIs get built twice,
    # once on the Viewer and once in the module panel.
    # So build the popup only once
    if {[info exists Gui(wSlicesAdv$s)] == 1} {
        if {[winfo exists $Gui(wSlicesAdv$s)] == 1} {
            return
        }
    }

    #-------------------------------------------
    # Slices Advanced Controls Popup Window
    #-------------------------------------------
    set w .wSlicesAdv$s
    set Gui(wSlicesAdv$s) $w
    toplevel $w -bg $Gui(activeWorkspace) -class Dialog
    wm title $w "Advanced Slice Controls"
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW "wm withdraw $w"
    if {$Gui(pc) == "0"} {
        wm transient $w .
    }
    wm withdraw $w
    set f $w
    
    # Close button
    eval {button $f.bClose -text "Close" \
        -command "wm withdraw $w"} $Gui(WBA)

    # Frames
    frame $f.fTop -bg $Gui(activeWorkspace)
    frame $f.fZoom -bg $Gui(activeWorkspace)
    frame $f.fIncrement -bg $Gui(activeWorkspace)
    pack $f.fTop $f.fZoom $f.fIncrement -side top \
        -pady $Gui(pad) -padx $Gui(pad) -fill x -expand true

    pack $f.bClose -side top -pady $Gui(pad)
    
    #-------------------------------------------
    # Popup->Top frame
    #-------------------------------------------
    set f $w.fTop
    
    eval {label $f.lTop -text "Controls for Slice $s"} \
        $Gui(WLA) {-bg $Gui(slice$s)}
    pack $f.lTop

    #-------------------------------------------
    # Popup->Zoom frame
    #-------------------------------------------
    set f $w.fZoom
    
    eval {label $f.lZoom -text "Zoom: "} $Gui(WLA)

    eval {entry $f.eZoom -width 7 \
        -textvariable Slice($s,zoom)} $Gui(WEA)
    bind $f.eZoom <Return>   \
        "MainSlicesSetZoom $s; RenderSlices"
    TooltipAdd $f.eZoom "Manually enter zoom value for slice\n\
        and hit Enter."

    grid $f.lZoom $f.eZoom \
        -pady $Gui(pad) -padx $Gui(pad)
    grid $f.lZoom -sticky e
    grid $f.eZoom -sticky e

    #-------------------------------------------
    # Popup->Increment frame
    #-------------------------------------------
    set f $w.fIncrement
    
    eval {label $f.lIncrement -text "Slice Increment: "} $Gui(WLA)

    eval {entry $f.eIncrement -width 7 \
        -textvariable Slice($s,offsetIncrement)} $Gui(WEA)
    bind $f.eIncrement <Return>   \
        "MainSlicesSetOffsetIncrement $s"
    bind $f.eIncrement <FocusOut>   \
        "MainSlicesSetOffsetIncrement $s"

    grid $f.lIncrement $f.eIncrement \
        -pady $Gui(pad) -padx $Gui(pad)
    grid $f.lIncrement -sticky e
    grid $f.eIncrement -sticky e

    TooltipAdd $f.eIncrement "Enter increment between reformatted\n\
        slices in mm, and hit Enter.\nThe slider will morve by this amount."
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesUpdateMRML
# Update volume display and slice controls GUIs when MRML updates.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesUpdateMRML {} {
    global Gui Slice Volume Module

    # See if the volume for each layer actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    foreach s $Slice(idList) {
         foreach layer "back fore label" {
            if {[lsearch $Volume(idList) $Slice($s,${layer}VolID)] == -1} {
                MainSlicesSetVolume [Cap $layer] $s $n
            }
        }
    }

    foreach s $Slice(idList) {
        
        # Volumes on slice
        #----------------------------
        foreach layer "Back Fore Label" baseSuffix "Orient Volume Volume" {
    
            # All Slices
            set suffix "f${baseSuffix}.mb${layer}Volume.m"
            
            foreach pre "$Slice($s,controls)" {
                set m $pre.$suffix
                $m delete 0 end
                foreach v $Volume(idList) {
                    set colbreak [MainVolumesBreakVolumeMenu $m] 
                    $m add command -label [Volume($v,node) GetName] \
                        -command "MainSlicesSetVolumeAll $layer $v; \
                        MainViewerHideSliceControls; RenderAll" \
                        -columnbreak $colbreak 
                }
            }

            # Current Slice
            set suffix "f${baseSuffix}.mb${layer}Volume${s}.m"

            foreach pre "$Slice($s,controls)" {
                set m $pre.$suffix
                $m delete 0 end
                foreach v $Volume(idList) {
                    set colbreak [MainVolumesBreakVolumeMenu $m] 
                    $m add command -label [Volume($v,node) GetName] \
                        -command "MainSlicesSetVolume ${layer} ${s} $v; \
                        MainViewerHideSliceControls; RenderBoth $s" \
                        -columnbreak $colbreak 
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesVolumeParam
#  Set a parameter for a slicer volume.  Also make that one
# the active volume.  Calls MainVolumesSetParam 
# .ARGS
# s int slice (0,1,2)
# param str name of parameter
# value str value to set
# .END
#-------------------------------------------------------------------------------
proc MainSlicesVolumeParam {s param value} {

    set v [[[Slicer GetBackVolume $s] GetMrmlNode] GetID]
    MainVolumesSetActive $v
    MainVolumesSetParam $param $value
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetClipState
#
#  Uses Slice(id,clipState) if state is empty str.
#  Makes appropriate changes to Slice(clipPlanes) 
#  states 1 and 2 use clipping (is there a difference btwn these?).
#  state 0 is no clipping.
# Usage: MainSlicesSetClipState id
# .ARGS
# s int slice id (0,1,2)
# state int clip state to use (1,2 or empty string)
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetClipState {s {state ""}} {
    global Gui Slice

    if {$state != ""} {
        set Slice($s,clipState) $state
    }
    set state $Slice($s,clipState)

    if {$state == "1"} {
        MainSlicesRefreshClip $s
        if {$Slice($s,addedFunction) == 0} {
            Slice(clipPlanes) AddFunction Slice($s,clipPlane)
            set Slice($s,addedFunction) 1
        }
    } elseif {$state == "2"} {
        MainSlicesRefreshClip $s
        if {$Slice($s,addedFunction) == 0} {
            Slice(clipPlanes) AddFunction Slice($s,clipPlane)
            set Slice($s,addedFunction) 1
        }
    } else {
        Slice(clipPlanes) RemoveFunction Slice($s,clipPlane)
        set Slice($s,addedFunction) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesRefreshClip
# Update clipping.
# Set normal and origin of clip plane using current
# info from vtkMrmlSlicer's reformat matrix.
# .ARGS
# s int slice id (0,1,2)
# .END
#-------------------------------------------------------------------------------
proc MainSlicesRefreshClip {s} {
    global Slice
    
    # Set normal and orient of slice
    if {$Slice($s,clipState) == "1"} {
        set sign 1
    } elseif {$Slice($s,clipState) == "2"} {
        set sign -1
    } else {
        return
    }
    set mat [Slicer GetReformatMatrix $s]

    set origin "[$mat GetElement 0 3] \
        [$mat GetElement 1 3] [$mat GetElement 2 3]"

    set normal "[expr $sign*[$mat GetElement 0 2]] \
        [expr $sign*[$mat GetElement 1 2]] \
        [expr $sign*[$mat GetElement 2 2]]"

    # WARNING: objects may not exist yet!
    if {[info command Slice($s,clipPlane)] != ""} {
        eval Slice($s,clipPlane) SetOrigin  $origin     
        eval Slice($s,clipPlane) SetNormal $normal
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetFov
#  For all slices, resets the slider range and tells actors their scale.
#  Called from MainViewSetFov
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetFov {} {
    global Slice View

    foreach s $Slice(idList) {
        MainSlicesSetSliderRange $s
        Slice($s,planeActor)   SetScale $View(fov) $View(fov) 1.0
        Slice($s,outlineActor) SetScale $View(fov) $View(fov) 1.0
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesCenterCursor
#
# Puts cursor (crosshair) in the center of the slice window. 
# Called when the mouse exits a window.
# Usage: CenterCursor sliceid
# .ARGS
# s int slice id
# .END
#-------------------------------------------------------------------------------
proc MainSlicesCenterCursor {s} {
    global View

    if {$View(mode) == "Quad512"} {
        Slicer SetCursorPosition $s 256 256
    } else {
        Slicer SetCursorPosition $s 128 128
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesKeyPress
#
# Called when a key is pressed in the 2D window.
# Deals with Up, Down, Left and Right.
#
#  Up and Down moves the slice offset.
#  Left and Right calles EditApplyFilter from Edit.tcl
# .ARGS
# key str the key that was pressed with mouse over the slice window
# .END
#-------------------------------------------------------------------------------
proc MainSlicesKeyPress {key} {
    global View Slice Toolbar Edit

    # Determine which slice this is
    set win $View(inWin)
    if {$win == "none"} {return}
    set s [string index $win 2]
    switch $key {
      "Up" {
        MainSlicesSetOffset $s Next; SliceMouseAnno;
        MainSlicesRefreshClip $s
        # I could Render3D here, but I'd prefer speed.
      }
      "Down" {
        MainSlicesSetOffset $s Prev; SliceMouseAnno;
        MainSlicesRefreshClip $s
      }
      "Left" {
        if {[IsModule Edit] == 1} {
            if {$Toolbar(mode) == "Edit" && $Edit(op) == "Draw"} {
                EditApplyFilter Draw
            }
        }
      }
      "Right" {
        if {[IsModule Edit] == 1} {
            if {$Toolbar(mode) == "Edit" && $Edit(op) == "Draw"} {
                EditApplyFilter Draw
            }
        }
      }
    }
}

 
#-------------------------------------------------------------------------------
# .PROC MainSlicesSetActive
# Set the active slice. This is called when the user clicks
# on a slice.  The active slice is the one that is updated interactively 
# when the user is changing the threshold or window/level, for
# example.  It's also the one that the user is currently editing, etc.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetActive {{s ""}} {
    global Edit Slice View Gui

    if {$s == $Slice(activeID)} {return}
    
    if {$s == ""} {
        set s $Slice(activeID)
    } else {
        set Slice(activeID) $s
    }
    
    Slicer SetActiveSlice $s
    Slicer Update

    # Redraw mag with polygon drawing
    RenderSlices
    MainViewSetWelcome sl$s
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetVolumeAll
#
#
# Sets all the layers to be the same volume.
# Layer is Fore,Back,Label
#
# Usage: MainSlicesSetVolumeAll Layer id
# .ARGS
# str Layer Back, Fore, or Label
# int id volume id
# bool setOffSetFlag defaults to 1, if call MainSlicesSetSliderRange without resetting the slice offset
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetVolumeAll {Layer v {setOffSetFlag 1}} {
    global Slice Volume

    # Check if volume exists and use the None if not
    if {[lsearch $Volume(idList) $v] == -1} {
        set v $Volume(idNone)
    }
    
    # Fields in the Slice array are uncapitalized
    set layer [Uncap $Layer]

    # Set the volume in the Slicer
    Slicer Set${Layer}Volume Volume($v,vol)
    Slicer Update

    foreach s $Slice(idList) {
        set Slice($s,${layer}VolID) $v

        # Change button text
        if {$Layer == "Back"} {
            MainSlicesConfigGui $s fOrient.mb${Layer}Volume$s \
                "-text \"[Volume($v,node) GetName]\""
        } else {
            MainSlicesConfigGui $s fVolume.mb${Layer}Volume$s \
                "-text \"[Volume($v,node) GetName]\""
        }

        # Always update Slider Range when change volume or orient
        if {$s == 2 && $::Module(verbose)} {
            puts "\tMainSlicesSetVolumeAll: calling MainSlicesSetSliderRange $s (setOffsetFlag = $setOffSetFlag)"
        }
        if {$setOffSetFlag == 0} {
            # trick it into thinking that we're updating options
            set savedPresets $::Options(recallingPresets)
            set ::Options(recallingPresets) 1
        }
        MainSlicesSetSliderRange $s
        if {$setOffSetFlag == 0} {
            # trick it into thinking that we're done updating options
            set ::Options(recallingPresets) $savedPresets
        }

        #--- Remove Ibrowser's control of viewer if Ibrowser is present
        #--- and update the Ibrowser's icons to reflect the change

        if { [catch "package require vtkIbrowser"] == 0 } {
            if { $Layer == "fore" || $Layer == "Fore" } {
                if { [info exists ::IbrowserController(Icanvas)] } {
                    IbrowserDeselectFGIcon $::IbrowserController(Icanvas)
                }
                if { [info exists ::Ibrowser(NoInterval)] } {
                    set ::Ibrowser(FGInterval) $::Ibrowser(NoInterval)
                }
            } elseif { $Layer == "back" || $Layer == "Back" } {
                if { [info exists ::IbrowserController(Icanvas)] } {
                    IbrowserDeselectBGIcon $::IbrowserController(Icanvas)
                }
                if { [info exists ::Ibrowser(NoInterval)] } {
                    set ::Ibrowser(BGInterval) $::Ibrowser(NoInterval)
                }
            }
        } 
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetVolume
# Set the volume to be displayed in this layer and this slice window.
# Layer can be Back, Fore,Label
# .ARGS 
# Layer string one of the three composited slice image layers
# s int 0,1,or 2 the slice image window
# v int the id of the volume to display
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetVolume {Layer s v} {
    global Slice Volume Model Lut

    # Check if volume exists and use the None if not
    if {[lsearch $Volume(idList) $v] == -1} {
        set v $Volume(idNone)
    }
    
    # Fields in the Slice array are uncapitalized
    set layer [Uncap $Layer]
    
    # If no change, return
    if {$v == $Slice($s,${layer}VolID)} {return}
    set Slice($s,${layer}VolID) $v

    # Change button text
    if {$Layer == "Back"} {
        MainSlicesConfigGui $s fOrient.mb${Layer}Volume$s \
            "-text \"[Volume($v,node) GetName]\""
    } else {
        MainSlicesConfigGui $s fVolume.mb${Layer}Volume$s \
            "-text \"[Volume($v,node) GetName]\""
    }
    if {$::Module(verbose)} { puts "\tMainSlicesSetVolume layer = $Layer, calling Slicer Set Layer Volume fo slice $s, volume id $v" }
    # Set the volume in the Slicer
    Slicer Set${Layer}Volume $s Volume($v,vol)
    Slicer Update

    # Always update Slider Range when change volume or orient
    if {$::Module(verbose)} { puts "\tMainSlicesSetVolume layer = $Layer, calling set slider range on $s (recalling presets =  $::Options(recallingPresets))"}
    MainSlicesSetSliderRange $s

    #--- Remove Ibrowser's control of viewer if Ibrowser is present
    #--- and update the Ibrowser's icons to reflect the change
    if { [catch "package require vtkIbrowser"] == 0 } {        
        if { $Layer == "fore" || $Layer == "Fore" } {
            if { [info exists ::IbrowserController(Icanvas)] } {
                IbrowserDeselectFGIcon $::IbrowserController(Icanvas)
            }
            if { [info exists ::Ibrowser(NoInterval) ] } {
                set ::Ibrowser(FGInterval) $::Ibrowser(NoInterval)
            }
        } elseif { $Layer == "back" || $Layer == "Back" } {
            if { [info exists ::IbrowserController(Icanvas)] } {
                IbrowserDeselectBGIcon $::IbrowserController(Icanvas)
            }
            if { [info exists ::Ibrowser(NoInterval) ] } {
                set ::Ibrowser(BGInterval) $::Ibrowser(NoInterval)
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOffsetInit
# wrapper around MainSlicesSetOffset. Also calls RenderBoth
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOffsetInit {s widget {value ""}} {

    # This prevents Tk from calling RenderBoth when it first creates
    # the slider, but before a user uses it.

    $widget config -command "MainSlicesSetOffset $s; RenderBoth $s"
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOffset
# Set the offset from volume center at which slice should be reformatted.
# Slice plane normal is already defined by the reformat matrix set in the
# vtrkMrmlSlicer object for slice s.  This matrix changes when the 
# Orient menu is used.
# .ARGS
# s int slice window (0,1,or 2)
# value float offset from center of vol (proc is called from GUI with no value) 
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOffset {s {value ""}} {
    global Slice Fiducials
    
    # are we already at the right offset?
    if {$Slice($s,offset) == $value} {
        return
    }
   
    set setSliderFlag 0
    # figure out what offset to use
    if {$value == ""} {
        # this means we were called directly from the slider w/ no value param
        # and the variable Slice($s,offset) has already been set by user
        set value $Slice($s,offset)
    } elseif {$value == "Prev"} {
        set value [expr $Slice($s,offset) - $Slice($s,offsetIncrement)]
        set Slice($s,offset) $value
    } elseif {$value == "Next"} {
        set value [expr $Slice($s,offset) + $Slice($s,offsetIncrement)]
        set Slice($s,offset) $value
    } else {
        # the value was passed in, we should save it in Slice(s,offset) so the slider is right
        set setSliderFlag 1
    }
   
    if {$::Module(verbose)} {
        puts "Main Slices Set Offset s = $s, value = $value (set slider = $setSliderFlag)"
    }

    # validate value
    if {[ValidateFloat $value] == 0}  {
        # don't change slice offset if value is bad
        # Set slider to the last used offset for this orient
        set value [Slicer GetOffset $s]
    }

    Slicer SetOffset $s $value

    # check for fiducials, should they be visible on this new slice? 
    # update the points for each fiducials list passing in this slice renderer
    set r [FiducialsSliceNumberToRendererName $s]
    # for each list of fiducials
    foreach id $::Fiducials(idList) {
        FiducialsVTKUpdatePoints2D $id $r
    }
    
    MainSlicesRefreshClip $s

    if {$setSliderFlag} {
        # update the slice offset in the gui
        if {$s == 2 && $::Module(verbose)} {
            puts "\tMainSlicesSetOffest: setting offset from Slicer, s = $s, old offest = $Slice($s,offset), Slicer offset = [Slicer GetOffset $s]"
        }
        set Slice($s,offset) [Slicer GetOffset $s]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetSliderRange
# Set the max and min values reachable with the slice selection slider.
# Called when the volume in the background changes 
# (in case num slices, resolution have changed)
# .ARGS
# s int slice window (0,1,2)
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetSliderRange {s} {
    global Slice 


    set lo [Slicer GetOffsetRangeLow  $s]
    set hi [Slicer GetOffsetRangeHigh $s]

    MainSlicesConfigGui $s fOffset.sOffset "-from $lo -to $hi"

    # Update Offset 
    
    if {$::Options(recallingPresets) == 0} {
        set Slice($s,offset) [Slicer GetOffset $s]
    } else {
        if {$s == 2 && $::Module(verbose)} { puts "\tSKIPPING setting the offset for slice $s" }
    }

    # adjust hidden scale widgets in Alignments if module is loaded
    if { [info command AlignmentsSlicesSetSliderRange] != "" } {
        catch "AlignmentsSlicesSetSliderRange $s"
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetAnno
# Set Anno for slice windows 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetAnno {s orient} {
    global View

    switch $orient {
        "Axial" {
            Anno($s,top,mapper)   SetInput A
            Anno($s,bot,mapper)   SetInput P
            Anno($s,left,mapper)  SetInput R
            Anno($s,right,mapper) SetInput L
        }
        "AxiSlice" {
            Anno($s,top,mapper)   SetInput A
            Anno($s,bot,mapper)   SetInput P
            Anno($s,left,mapper)  SetInput R
            Anno($s,right,mapper) SetInput L
        }
        "Sagittal" {
            Anno($s,top,mapper)   SetInput S
            Anno($s,bot,mapper)   SetInput I
            Anno($s,left,mapper)  SetInput A 
            Anno($s,right,mapper) SetInput P 
        }
        "SagSlice" {
            Anno($s,top,mapper)   SetInput S
            Anno($s,bot,mapper)   SetInput I
            Anno($s,left,mapper)  SetInput A 
            Anno($s,right,mapper) SetInput P 
        }
        "Coronal" {
            Anno($s,top,mapper)   SetInput S
            Anno($s,bot,mapper)   SetInput I
            Anno($s,left,mapper)  SetInput R
            Anno($s,right,mapper) SetInput L
        }
        "CorSlice" {
            Anno($s,top,mapper)   SetInput S
            Anno($s,bot,mapper)   SetInput I
            Anno($s,left,mapper)  SetInput R
            Anno($s,right,mapper) SetInput L
        }
        default {
            Anno($s,top,mapper)   SetInput " " 
            Anno($s,bot,mapper)   SetInput " " 
            Anno($s,left,mapper)  SetInput " " 
            Anno($s,right,mapper) SetInput " " 
        }
    }
}  


#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOrientAll
# Set all slice windows to have some orientation (i.e. Axial, etc)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOrientAll {orient} {
    global Slice View

    
    Slicer ComputeNTPFromCamera $View(viewCam)

    Slicer SetOrientString $orient

    foreach s $Slice(idList) {
        set orient [Slicer GetOrientString $s]
        set Slice($s,orient) $orient

        # Always update Slider Range when change Back volume or orient
        MainSlicesSetSliderRange $s

        # Set slider increments
        MainSlicesSetOffsetIncrement $s

        # Set slider to the last used offset for this orient
        set Slice($s,offset) [Slicer GetOffset $s]

        # Change text on menu button
        MainSlicesConfigGui $s fOrient.mbOrient$s "-text \"$orient\""
        $Slice($s,lOrient) config -text $orient

        # Anno
        MainSlicesSetAnno $s $Slice($s,orient)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOrient
# Set one slice window to have some orientation (i.e. Axial, etc)
# 
# .ARGS
# s int slice window (0,1,2)
# orient string one of Axial AxiSlice Sagittal SagSlice, etc. from menu
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOrient {s orient} {
    global Slice Volume View Module

    Slicer ComputeNTPFromCamera $View(viewCam)

    Slicer SetOrientString $s $orient
    set Slice($s,orient) [Slicer GetOrientString $s]

    # Always update Slider Range when change Back volume or orient
    MainSlicesSetSliderRange $s

    # Set slider increments
    MainSlicesSetOffsetIncrement $s
    
    # Set slider to the last used offset for this orient
    set Slice($s,offset) [Slicer GetOffset $s]
    

    # Change text on menu button
    MainSlicesConfigGui $s fOrient.mbOrient$s "-text \"$orient\""
    $Slice($s,lOrient) config -text $orient

    # Anno
    MainSlicesSetAnno $s $orient    
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesResetZoomAll
# Set zoom in all slice windows to 1
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesResetZoomAll {} {
    global Slice

    foreach s $Slice(idList) {
        MainSlicesSetZoom $s 1
        Slicer SetZoomAutoCenter $s 1
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetZoomAll
#
# Sets the zoom on all slices
# and displays the result
#
# Usage: MainSlicesSetZoomAll zoom
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetZoomAll {zoom} {
    global Slice

    # Change Slice's Zoom variable
    foreach s $Slice(idList) {
        set Slice($s,zoom) $zoom
#>> Bouix 4/23/03 put the old version of zoom to solve the drawing problem    
        # Attila's new zooming function
        if {[Slicer GetDisplayMethod] ==2} {
            Slicer SetZoomNew $s $zoom
        }
    }
    Slicer SetZoom $zoom
#<< Bouix
    Slicer Update
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesConfigGui
# Configure any gui widget for slice s.  The GUI is duplicated
# once above the slice and once in the Slices module, so always
# call this procedure to configure them both.  Example of usage is:
# Change text on menu button by doing
# MainSlicesConfigGui $s fOrient.mbOrient$s "-text $orient"
#
# .ARGS
# s int slice (0,1,2)
# gui string widget to configure (look in proc MainSlicesBuildControls)
# config string tk configure line to use
# .END
#-------------------------------------------------------------------------------
proc MainSlicesConfigGui {s gui config} {
    global Gui Module Slice

    foreach f $Slice($s,controls) {
        eval $f.$gui config $config
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetZoom
#
# Sets the zoom on a Slice id
# and displays the result
#
# Usage: MainSlicesSetZoom id zoom
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetZoom {s {zoom ""}} {
    global Slice
    
    # if called without a zoom arg it's from user entry
    if {$zoom == ""} {
        if {[ValidateFloat $Slice($s,zoom)] == 0} {
            tk_messageBox -message "The zoom must be a number."
            
            # reset the zoom
            set Slice($s,zoom) [Slicer GetZoom $s]
            return
        }
        # if user-entered zoom is okay then do the rest of the procedure
        set zoom $Slice($s,zoom)
    }

    # Change Slice's Zoom variable
    set Slice($s,zoom) $zoom
#>> Bouix 4/23/03 Back to old zoom
    # Use Attila's new zooming code
    
    if {[Slicer GetDisplayMethod] ==2} {
        # Use Attila's new zooming code
        Slicer SetZoomNew $s $zoom
    }

    if {[Slicer GetDisplayMethod] ==1 || [Slicer GetDisplayMethod] ==3} {
        Slicer SetZoom $s $zoom
    }
#<< Bouix 
    Slicer Update

    # update 2d Fiducials to take into account the new zoom
    FiducialsUpdateZoom2D $s $zoom
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetVisibilityAll
#
# Set the visibility of all the slices on the 3D viewer
# to be visibilityAll. Called when the cVisibility button is clicked on."
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetVisibilityAll {{value ""}} {
    global Slice Anno

    if {$value != ""} {
        set Slice(visibilityAll) $value
    }

    foreach s $Slice(idList) {
        set Slice($s,visibility) $Slice(visibilityAll)

        Slice($s,planeActor) SetVisibility $Slice($s,visibility) 

        if {$Anno(outline) == 1} {
            Slice($s,outlineActor) SetVisibility $Slice($s,visibility)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetVisibility
#
# Set the visibility of a slice on the 3D viewer
# to be it's visibility.  
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetVisibility {s} {
    global Slice Anno

    Slice($s,planeActor)   SetVisibility $Slice($s,visibility) 

    if {$Anno(outline) == 1} {
        Slice($s,outlineActor) SetVisibility $Slice($s,visibility)
    } 
    
    # If any slice is invisible, then Slice(visibilityAll) should be 0
    set Slice(visibilityAll) 1
    foreach s $Slice(idList) {
        if {$Slice($s,visibility) == 0} {
            set Slice(visibilityAll) 0
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesUserReformat
# Make the selected slice active and visible
# Tab to Volumes -> Reformat
# .ARGS
#  s id of selected slice
# .END
#-------------------------------------------------------------------------------
proc MainSlicesUserReformat {s} {
    global Slice Anno Module

    set Slice($s,visibility) 1
    MainSlicesSetVisibility $s
    MainSlicesSetActive $s
    Render3D
    if {[info exists Module(Volumes,fReformat)] == 1} {   
    Tab Volumes row1 Reformat
    }
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOpacityAll
#  Set opacity of all Fore layers to value
# This means the opacity used when overlaying the slices in
# the vtkMrmlSlicer object (in its vtkImageOverlay member object).
# This is used to fade from fore to back layers (image overlay).
# This does not affect the transparency of the slice actor
# in the 3D window.
# .ARGS
# value int opacity value
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOpacityAll {{value ""}} {
    global Slice
    
    if {$value == ""} {
        set value $Slice(opacity)
    } else {
        set Slice(opacity) $value
    }
    Slicer SetForeOpacity $value
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOpacityToggle
# toggle the opacity setting between top and bottom
# eg if it was .75,.25 it becomes .25,.75
# .ARGS
# value int opacity value
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOpacityToggle {} {
    MainSlicesSetOpacityAll [expr 1.0 - $::Slice(opacity)]
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesSetFadeAll
# Set fade of all slices to value.  
# This controls the behavior of the display when using the opacity slider
# to blend from foreground to background slice (image overlay).
# Ron says this doesn't actually work...
# .ARGS
# fade bool whether to fade.
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetFadeAll {{value ""}} {
    global Slice
    
    if {$value == ""} {
        set value $Slice(fade)
    } else {
        set Slice(fade) $value
    }
    Slicer SetForeFade $value
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetClipType
# Set the type of clippint to apply to models
# .ARGS
# Union or Intersection
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetClipType {{value ""}} {
    global Slice
    
    if {$value == ""} {
        set value $Slice(clipType)
    } else {
        set Slice(clipType) $value
    }
    Slice(clipPlanes) SetOperationTypeTo$Slice(clipType);
    MainModelsRefreshClipping 
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSave
# Save a slice window into an image file.
# Calls MainSlicesWrite.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSave {} {
    global Mrml Slice

    # Prefix cannot be blank
    if {$Slice(prefix) == ""} {
        tk_messageBox -message "Please specify a file name."
        return
    }

    # Get a unique filename by appending a number to the prefix
    set filename [MainFileFindUniqueName $Mrml(dir) $Slice(prefix) $Slice(ext)]

    MainSlicesWrite $filename
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSavePopup
# Pop up a save dialog box to write the slice image.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSavePopup {} {
    global Slice Mrml Gui

    # Cannot have blank prefix
    if {$Slice(prefix) == ""} {
        set Slice(prefix) view
    }

     # Show popup initialized to the last file saved
    set filename [file join $Mrml(dir) $Slice(prefix)]
    set dir [file dirname $filename]
    set typelist {
        {"TIFF File" {".tif"}}
        {"PPM File" {".ppm"}}
        {"BMP File" {".bmp"}}
        {"All Files" {*}}
    }
    set filename [tk_getSaveFile -title "Save Slice" -defaultextension $Slice(ext)\
        -filetypes $typelist -initialdir "$dir" -initialfile $filename]

    # Do nothing if the user cancelled
    if {$filename == ""} {return}

    MainSlicesWrite $filename
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesWrite
# Write the active slice's image into a file.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesWrite {filename} {
    global viewWin Mrml Slice Gui

    MainFileCreateDirectory $filename
    
    # Write it
    set s $Slice(activeID)
    set ext [file extension $filename]
    set success 0
    switch $ext {
    ".tif" {
        set success 1
        vtkWindowToImageFilter filter
        filter SetInput sl${s}Win

        vtkTIFFWriter writer
        writer SetInput [filter GetOutput]
        writer SetFileName $filename
        writer Write
        filter Delete
        writer Delete
    }
    ".bmp" {
        set success 1
        vtkWindowToImageFilter filter
        filter SetInput sl${s}Win

        vtkBMPWriter writer
        writer SetInput [filter GetOutput]
        writer SetFileName $filename
        writer Write
        filter Delete
        writer Delete
    }
    ".ppm" {
        set success 1
        vtkWindowToImageFilter filter
        filter SetInput sl${s}Win

        vtkPNMWriter writer
        writer SetInput [filter GetOutput]
        writer SetFileName $filename
        writer Write
        filter Delete
        writer Delete
    }
    }
    if {$success == "0"} {
        puts "Unable to save view.  Did you choose a filename extension?"
        return
    }
    puts "Saved view: $filename"

    # Store the new prefix and extension for next time
    set root $Mrml(dir)
    set absPrefix [file rootname $filename]
    if {$Gui(pc) == 1} {
        set absPrefix [string tolower $absPrefix]
        set root [string tolower $Mrml(dir)]
    }
    if {[regexp "^$root/(\[^0-9\]*)(\[0-9\]*)" $absPrefix match relPrefix num] == 1} {
        set Slice(prefix) $relPrefix
    } else {
        set Slice(prefix) [file rootname $absPrefix]
    }
    set Slice(ext) [file extension $filename]
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesStorePresets
# Store current settings into preset global variables
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesStorePresets {p} {
    global Preset Slice

    foreach s $Slice(idList) {
        set Preset(Slices,$p,$s,visibility) $Slice($s,visibility)
        set Preset(Slices,$p,$s,orient)     $Slice($s,orient)
        set Preset(Slices,$p,$s,offset)     $Slice($s,offset)
        set Preset(Slices,$p,$s,zoom)       $Slice($s,zoom)
        set Preset(Slices,$p,$s,clipState)  $Slice($s,clipState)
        set Preset(Slices,$p,$s,backVolID)  $Slice($s,backVolID)
        set Preset(Slices,$p,$s,foreVolID)  $Slice($s,foreVolID)
        set Preset(Slices,$p,$s,labelVolID) $Slice($s,labelVolID)
    }
    set Preset(Slices,$p,opacity) $Slice(opacity)
    set Preset(Slices,$p,fade) $Slice(fade)
    set Preset(Slices,$p,clipType) $Slice(clipType)
}



#-------------------------------------------------------------------------------
# .PROC MainSlicesRecallPresets
# Set current settings from preset global variables
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesRecallPresets {p} {
    global Preset Slice

    foreach s $Slice(idList) {
        set Slice($s,visibility) $Preset(Slices,$p,$s,visibility)
        MainSlicesSetVisibility $s
        if {$s == 2 && $::Module(verbose)} {
            puts "\tMainSlicesRecallPresets: setting volume layers for slice $s to preset id: back = $Preset(Slices,$p,$s,backVolID), fore = $Preset(Slices,$p,$s,foreVolID), label = $Preset(Slices,$p,$s,labelVolID)"
        }
        MainSlicesSetVolume Back $s $Preset(Slices,$p,$s,backVolID)
        MainSlicesSetVolume Fore $s $Preset(Slices,$p,$s,foreVolID)
        MainSlicesSetVolume Label $s $Preset(Slices,$p,$s,labelVolID)
        MainSlicesSetOrient $s $Preset(Slices,$p,$s,orient)
        if {$s == 2 && $::Module(verbose)} {
            puts "\tMainSlicesRecallPresets: setting slice $s to preset offset $Preset(Slices,$p,$s,offset)"
        }
        MainSlicesSetOffset    $s $Preset(Slices,$p,$s,offset)
        MainSlicesSetZoom $s $Preset(Slices,$p,$s,zoom)
        MainSlicesSetClipState $s $Preset(Slices,$p,$s,clipState)
    }
    MainSlicesSetOpacityAll $Preset(Slices,$p,opacity)
    MainSlicesSetFadeAll $Preset(Slices,$p,fade)
    MainSlicesSetClipType $Preset(Slices,$p,clipType)
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesOffsetToPoint
# Implemented by Peter Everett.
# Reformat a slice at point  x y z
# 
# NOTICE: THIS CODE SHOULD BE REMOVED THE INSTANT
# THAT vtkMrmlSlicer SUPPORTS IT. The internallogic
# of the reformatter should not be duplicated here.
# YOU HAVE BEEN WARNED. Here is the replacement code:    
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesOffsetToPoint { s x y z } {
    #
    # NOTICE: THIS CODE SHOULD BE REMOVED THE INSTANT
    # THAT vtkMrmlSlicer SUPPORTS IT. The internallogic
    # of the reformatter should not be duplicated here.
    # YOU HAVE BEEN WARNED. Here is the replacement code:
    #
    # set offset [Slicer GetOffsetFromPoint $s $x $y $z]
    # MainSlicesSetOffset $s $offset
    #
    if { [lsearch [Slicer ListMethods] "GetOffsetFromPoint"] != -1 } {
        puts "Warning: Read comment in tcl-main/MainSlicesOffsetToPoint"
    }

    set drive [Slicer GetDriver $s]
    if { $drive == 0 } {
        set fp [Slicer GetCamP]
    } else {
        set fp [Slicer GetDirP]
    }
    set mat [Slicer GetReformatMatrix $s]
    set vecx [$mat GetElement 0 2]
    set vecy [$mat GetElement 1 2]
    set vecz [$mat GetElement 2 2]
    set difx [expr $x - [lindex $fp 0]]
    set dify [expr $y - [lindex $fp 1]]
    set difz [expr $z - [lindex $fp 2]]
    set offset [expr $vecx * $difx + $vecy * $dify + $vecz * $difz]
    # Weird kludge for axial & sagittal. For explanation,
    # see vtkMrmlSlicer:GetOffsetForComputation
    set orient [Slicer GetOrientString $s]
    if { $orient == "Axial" || $orient == "Sagittal" } {
        set offset [expr -1.0 * $offset]
    }
    MainSlicesSetOffset $s $offset
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesAllOffsetToPoint
# All slices reformatted at a point
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesAllOffsetToPoint { x y z } {
    global Slice

    foreach s $Slice(idList) {
        MainSlicesOffsetToPoint $s $x $y $z
    }
    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesAdvancedControlsPopup
# Pop up the advanced slice controls window.  Called from
# the menu under the V for visibility button.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesAdvancedControlsPopup {s} {
    global Gui
    
    # Recreate window if user killed it
    if {[winfo exists $Gui(wSlicesAdv$s)] == 0} {
        MainSlicesBuildAdvancedControlsPopup $s
    }
    
    ShowPopup $Gui(wSlicesAdv$s) 0 0
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesSetOffsetIncrement
# Set the increment by which the slice slider should move.
# The default in the slicer is 1, which is 1 mm.
# Note this procedure will force increment to 1 if in any
# of the Slices orientations which just grab original data from the array.
# In this case the increment would mean 1 slice instead of 1 mm.
# .ARGS
# s int slice number (0,1,2)
# incr float increment slider should move by. is empty str if called from GUI
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSetOffsetIncrement {s {incr ""}} {
    global Slice

    # set slider increments to 1 if in original orientation
    set orient [Slicer GetOrientString $s]
    if {$orient == "AxiSlice" || $orient == "CorSlice" \
        || $orient == "SagSlice" || $orient == "OrigSlice" } {
        set incr 1    
    }
    
    # if called without an incr arg it's from user entry
    if {$incr == ""} {
        if {[ValidateFloat $Slice($s,offsetIncrement)] == 0} {
            tk_messageBox -message "The increment must be a number."
            
            # reset the incr
            set Slice($s,offsetIncrement) 1
            return
        }
        # if user-entered incr is okay then do the rest of the procedure
        set incr $Slice($s,offsetIncrement)
    }

    # Change Slice's offset increment variable
    set Slice($s,offsetIncrement) $incr

    # Make the slider allow this resolution
    MainSlicesConfigGui $s fOffset.sOffset "-resolution $incr"    
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesSet3DOpacity
# This actually sets the opacity of the slice's plane actor
# in the 3D scene.  This has nothing to do with the opacity
# of fore/back layers.  This only affects the 3D display.
# .ARGS
# int s slice number
# float opacity a number between 0 and 1
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSet3DOpacity  {s opacity} {
    global Slice

    [Slice($s,planeActor) GetProperty] SetOpacity $opacity
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MainSlicesReset3DOpacityAll
# Reset opacity of all slice actors in 3D window to 1
# (completely opaque, this is the default).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainSlicesReset3DOpacityAll  {} {
    global Slice

    MainSlicesSet3DOpacityAll  1
}


#-------------------------------------------------------------------------------
# .PROC MainSlicesSet3DOpacityAll
# This actually sets the opacity of all slices' plane actors
# in the 3D scene.  This has nothing to do with the opacity
# of fore/back layers.  This only affects the 3D display.
# 
# .ARGS
# float opacity a number between 0 and 1
# .END
#-------------------------------------------------------------------------------
proc MainSlicesSet3DOpacityAll  {opacity} {
    global Slice

    foreach s $Slice(idList) {
    [Slice($s,planeActor) GetProperty] SetOpacity $opacity
    }
    Render3D
}
