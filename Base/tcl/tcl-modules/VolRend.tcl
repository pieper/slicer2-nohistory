#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolRend.tcl,v $
#   Date:      $Date: 2006/09/11 14:34:22 $
#   Version:   $Revision: 1.16 $
# 
#===============================================================================
# FILE:        VolRend.tcl
# PROCEDURES:  
#   VolRendInit
#   VolRendBuildGUI
#   VolRendBuildVTK
#   VolRendRefresh
#   VolRendEnter
#   VolRendExit
#   VolRendUpdateMRML
#   VolRendSetOriginal Volume
#   VolRendSaveTransferFunctions
#   VolRendReadTransferFunctions
#   VolRendSelectRenderMethod
#   VolRendStorePresets
#   VolRendRecallPresets
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
# .PROC VolRendInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendInit {} {
    global VolRend Module Volume Model prog
    
    set m VolRend

    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Volume rendering."
    set Module($m,author) "Attila Tanacs, Johns Hopkins University, tanacs@cs.jhu.edu"
    set Module($m,category) "Visualisation"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.16 $} {$Date: 2006/09/11 14:34:22 $}]

    set Module($m,row1List) "Help Settings Transfer"
    set Module($m,row1Name) "{Help} {Settings} {Transfer Functions}"
    set Module($m,row1,tab) Settings

    set Module($m,procGUI) VolRendBuildGUI
    set Module($m,procEnter) VolRendEnter
    set Module($m,procExit) VolRendExit
    set Module($m,procVTK) VolRendBuildVTK
    set Module($m,procMRML) VolRendUpdateMRML

    lappend Module(procStorePresets) VolRendStorePresets
    lappend Module(procRecallPresets) VolRendRecallPresets
    set Module(VolRend,presets) "idOriginal='0' sampleDistance='1.0' hideOnExit='1' \
interpolationMethod='Nearest' renderMethod='composite' compositeMethod='classify' \
mipMaxMethod='ScalarValue' isoValue='512' \
opacityTransferFunction='0 0.0 399 0.0 400 0.0 1199 0.2 1200 0.8 4095 0.8 4096 0.0' \
colorTransferFunction='0 0.0 0.0 0.0 399 0.0 0.0 0.0 400 0.1 0.1 0.1 1199 0.5 0.5 0.5 1200 0.8 0.8 0.8 4095 1.0 1.0 1.0' \
gradientOpacityTransferFunction='0 0.0 30 0.0 150 1.0 4095 1.0' \
renderType='raycast'"

    set Module($m,depend) ""

    set VolRend(idOriginal)  $Volume(idNone)
    set VolRend(renderType) "raycast"
    set VolRend(sampleDistance) "1.0"
    set VolRend(transferFunctionSaveFileName) "$prog/cttrffunc.xml"
    set VolRend(transferFunctionReadFileName) "$prog/cttrffunc.xml"
    set VolRend(hideOnExit) "1"
    set VolRend(volumeVisible) "0"
    set VolRend(interpolationMethod) "Nearest"
    set VolRend(renderMethod) "composite"
    set VolRend(compositeMethod) "classify"
    set VolRend(mipMaxMethod) "ScalarValue"
    set VolRend(isoValue) "512"

    set VolRend(contents) "VolRendTransferFunctions"

    set VolRend(eventManager)  {  }
}

#-------------------------------------------------------------------------------
# .PROC VolRendBuildGUI
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc VolRendBuildGUI {} {
    global Gui VolRend Module Volume Model
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
#    set help "
#    The VolRend module is under heavy development."

    set help "
Volume rendering using available VTK classes.
<P>
Description by tabs:
  <P><B>Settings:</B>
  <UL>
    <LI>Ref Volume: the volume used for rendering
    <LI>Sample distance: sample distance along the ray. The smaller, the result looks
 better, but the calculation takes much more time.
    <LI>Hide Volume on Module Exit: since volume rendering is a very time consuming
 process, the volume should be rendered only if it is really necessary.
    <LI>Interpolation: nearest neighbor or linear
    <LI>Volume rendering methods: Composite, MIP (maximum intensity projection),
 Isosurface.
  </UL>
  <P><B>Transfer functions:</B><BR>
 Transfer functions play a crucial role in the rendering process. Along the ray,
 at every position, the given voxel value will be turned into a color and opacity
 value according to these. These functions are defined by the values at given
 positions and linear interpolation is used between them.<BR>
  <UL>
    <LI>Scalar Opacity Box: defines the function which assigns the opacity value
 for a given voxel value
    <LI>Color Transfer Box: defines the function which assigns the color value
 for a given voxel value
    <LI>Gradient Opacity Box: at every position, the gradient is calculated, and the
 value of this function is multiplied by the Scalar Opacity value to get the
 final opacity value.
  </UL>
"


    regsub -all "\n" $help {} help
    MainHelpApplyTags VolRend $help
    MainHelpBuildGUI VolRend
    
    #-------------------------------------------
    # Settings frame
    #-------------------------------------------
    set fSettings $Module(VolRend,fSettings)
    set f $fSettings

    foreach frame "Top HideOnExit Interpolation RenderMethod Texture Buttons" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
#    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad)
    }
    
    #-------------------------------------------
    # Settings->Top frame
    #-------------------------------------------
    set f $fSettings.fTop
    
    # Add menus that list models and volumes
    DevAddSelectButton VolRend $f Original "Ref Volume" Grid
    lappend Volume(mbActiveList) $f.mbOriginal
    lappend Volume(mActiveList)  $f.mbOriginal.m

    #-------------------------------------------
    # Settings->HideOnExit frame
    #-------------------------------------------
    set f $fSettings.fHideOnExit

    eval {checkbutton $f.rHideOnExit \
          -text "Hide Volume on Module Exit" -command "" \
          -variable VolRend(hideOnExit) \
          -indicatoron 1} $Gui(WCA)
    pack $f.rHideOnExit -side top -padx $Gui(pad)

    #-------------------------------------------
    # Settings->Interpolation frame
    #-------------------------------------------
    set f $fSettings.fInterpolation

    foreach value "Nearest Linear" text "{Nearest Neighbor} {Linear Interpolation}" width "15 15" {
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(interpolationMethod) \
          -command ""} $Gui(WCA)
    pack $f.r$value -side left -fill x
    }
    
    #-------------------------------------------
    # Settings->RenderMethod frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod

    $f config -relief groove -bd 3 

    frame $f.fRenderType -bg $Gui(activeWorkspace)
    pack $f.fRenderType -side top -padx 2 -pady 2

    frame $f.fSampleDist -bg $Gui(activeWorkspace)
    pack $f.fSampleDist -side top -padx 2 -pady 2

    frame $f.fTop -bg $Gui(backdrop)
    pack $f.fTop -side top -padx 2 -pady 2

    frame $f.fBottom -bg $Gui(activeWorkspace)
    pack $f.fBottom -side top -padx 2 -pady 2 -fill both -expand true

    #-------------------------------------------
    # Settings->RenderMethod->RenderType frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod.fRenderType

    set value "raycast"
    set text "Ray Casting"
    set width 25
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(renderType) \
          -command ""} $Gui(WCA)
    pack $f.r$value -side top

    #-------------------------------------------
    # Settings->RenderMethod->SampleDist frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod.fSampleDist

    eval {label $f.lSampleDist -text "Sample Distance:"} $Gui(WLA)
    eval {entry $f.eSampleDist -width 6 \
          -textvariable VolRend(sampleDistance)} $Gui(WEA)

    pack $f.lSampleDist $f.eSampleDist -side left -fill x

    #-------------------------------------------
    # Settings->RenderMethod->Top frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod.fTop
    set fBottom $fSettings.fRenderMethod.fBottom

    set value "composite"
    set text "Composite"
    set width 10
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(renderMethod) \
          -command "VolRendSelectRenderMethod"} $Gui(WCA)
    pack $f.r$value -side left -fill x
    
    frame $fBottom.f$value -bg $Gui(activeWorkspace)
#    place $fBottom.f${value} -in $fBottom -relheight 1.0 -relwidth 1.0
    pack $fBottom.f$value -side top -padx 0 -pady 0
    #    place $fBottom.f${value} -in $fBottom -height 300 -relwidth 1.0
    set VolRend(f${value}) $fBottom.f${value}
    
    foreach value "mip isosurface" text "MIP Isosurface" width "5 10" {
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(renderMethod) \
          -command "VolRendSelectRenderMethod"} $Gui(WCA)
    pack $f.r$value -side left -fill x

    frame $fBottom.f$value -bg $Gui(activeWorkspace)
    place $fBottom.f${value} -in $fBottom -relheight 1.0 -relwidth 1.0
    set VolRend(f${value}) $fBottom.f${value}
    }
    raise $VolRend(f$VolRend(renderMethod))

    #-------------------------------------------
    # Settings->RenderMethod->Bottom->fcomposite frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod.fBottom.fcomposite

    foreach value "interpolate classify" text "{Interpolate First} {Classify First}" width "15 15" {
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(compositeMethod) \
          -command ""} $Gui(WCA)
    pack $f.r$value -side left -fill x
    }

    #-------------------------------------------
    # Settings->RenderMethod->Bottom->fmip frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod.fBottom.fmip

    foreach value "ScalarValue Opacity" text "{Max. Scalar Value} {Max. Opacity}" width "15 15" {
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(mipMaxMethod) \
          -command ""} $Gui(WCA)
    pack $f.r$value -side left -fill x
    }

    #-------------------------------------------
    # Settings->RenderMethod->Bottom->fisosurface frame
    #-------------------------------------------
    set f $fSettings.fRenderMethod.fBottom.fisosurface

    eval {label $f.lIsoValue -text "    Iso Value:" -width 15} $Gui(WLA)
    eval {entry $f.eIsoValue -width 6 \
          -textvariable VolRend(isoValue)} $Gui(WEA)

    pack $f.lIsoValue $f.eIsoValue -side left -fill x

    #-------------------------------------------
    # Settings->Texture frame
    #-------------------------------------------
    set f $fSettings.fTexture

    $f config -relief groove -bd 3

    frame $f.fRenderType -bg $Gui(activeWorkspace)
    pack $f.fRenderType -side top -padx 2 -pady 2

    frame $f.fParams -bg $Gui(activeWorkspace)
    pack $f.fParams -side top -padx 2 -pady 2

    #-------------------------------------------
    # Settings->Texture->RenderType frame
    #-------------------------------------------
    set f $fSettings.fTexture.fRenderType

    set value "texture"
    set text "2D Texture Mapping"
    set width 25
    eval {radiobutton $f.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable VolRend(renderType) \
          -command ""} $Gui(WCA)
    pack $f.r$value -side top

    #-------------------------------------------
    # Settings->Texture->Params frame
    #-------------------------------------------
    set f $fSettings.fTexture.fParams

    eval {label $f.lParams -text "No parameters to set." -width 34} $Gui(WLA)
    pack $f.lParams -side top

    #-------------------------------------------
    # Settings->Buttons frame
    #-------------------------------------------
    set f $fSettings.fButtons

    DevAddButton $f.bRefresh {Refresh View} VolRendRefresh
    pack $f.bRefresh -side top

    #-------------------------------------------
    # Transfer frame
    #-------------------------------------------
    set fTransfer $Module(VolRend,fTransfer)
    set f $fTransfer

    foreach frame "ScalarOpacity ColorTransfer GradientOpacity MessageBox" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    foreach frame "Buttons IO" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad)
    }

    #-------------------------------------------
    # Transfer->ScalarOpacity frame
    #-------------------------------------------
    set f $fTransfer.fScalarOpacity
    
    set VolRend(ScalarOpacityBox) [ScrolledText $f.fListbox -height 5]
    $VolRend(ScalarOpacityBox) configure -height 5 -width 10
    pack $f.fListbox -side top -pady 0 -padx 0 -fill both -expand true
    $VolRend(ScalarOpacityBox) configure -state normal

    #-------------------------------------------
    # Transfer->ColorTransfer frame
    #-------------------------------------------
    set f $fTransfer.fColorTransfer
    
    set VolRend(ColorTransferBox) [ScrolledText $f.fListbox -height 5]
    $VolRend(ColorTransferBox) configure -height 5 -width 10
    pack $f.fListbox -side top -pady 0 -padx 0 -fill both -expand true
    $VolRend(ColorTransferBox) configure -state normal

    #-------------------------------------------
    # Transfer->GradientOpacity frame
    #-------------------------------------------
    set f $fTransfer.fGradientOpacity
    
    set VolRend(GradientOpacityBox) [ScrolledText $f.fListbox -height 5]
    $VolRend(GradientOpacityBox) configure -height 5 -width 10
    pack $f.fListbox -side top -pady 0 -padx 0 -fill both -expand true
    $VolRend(GradientOpacityBox) configure -state normal

    #-------------------------------------------
    # Transfer->MessageBox frame
    #-------------------------------------------
#     set f $fSettings.fMessageBox
    
#     set VolRend(MessageBox) [ScrolledText $f.fListbox -height 5]
#     $VolRend(MessageBox) configure -height 5 -width 10
#     pack $f.fListbox -side top -pady 0 -padx 0 -fill both -expand true
#     $VolRend(MessageBox) configure -state normal
#     $VolRend(MessageBox) insert insert "MessageBox\n"

    #-------------------------------------------
    # Transfer->Buttons frame
    #-------------------------------------------
    set f $fTransfer.fButtons

    DevAddButton $f.bRefresh {Refresh View} VolRendRefresh
    pack $f.bRefresh -side top

    #-------------------------------------------
    # Transfer->IO frame
    #-------------------------------------------
    set f $fTransfer.fIO

    DevAddButton $f.bRead {Read} VolRendReadTransferFunctions
    pack $f.bRead -side left

    DevAddButton $f.bSave {Save} VolRendSaveTransferFunctions
    pack $f.bSave -side left
}

#-------------------------------------------------------------------------------
# .PROC VolRendBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendBuildVTK {} {
    global VolRend

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    # Create transfer functions for opacity and color
    vtkPiecewiseFunction VolRend(opacityTransferFunction)
    vtkColorTransferFunction VolRend(colorTransferFunction)
    vtkPiecewiseFunction VolRend(GradientOpacityTRansferFunction)

    # Create properties, mappers, volume actors, and ray cast function
    vtkVolumeProperty VolRend(volumeProperty)
    VolRend(volumeProperty) SetColor VolRend(colorTransferFunction)
    VolRend(volumeProperty) SetScalarOpacity VolRend(opacityTransferFunction)
    VolRend(volumeProperty) SetGradientOpacity VolRend(GradientOpacityTRansferFunction)

    vtkVolumeRayCastCompositeFunction  VolRend(compositeFunction)
    vtkVolumeRayCastMIPFunction VolRend(mipFunction)
    vtkVolumeRayCastIsosurfaceFunction VolRend(isosurfaceFunction)

    vtkVolumeRayCastMapper VolRend(raycastvolumeMapper)
    vtkVolumeTextureMapper2D VolRend(texturevolumeMapper)
#    VolRend(volumeMapper) SetInput [reader GetOutput]
    VolRend(raycastvolumeMapper) SetVolumeRayCastFunction VolRend(compositeFunction)

    vtkVolume VolRend(volume)
#    VolRend(volume) SetMapper VolRend(volumeMapper)
    VolRend(volume) SetProperty VolRend(volumeProperty)

    vtkImageCast VolRend(imageCast)

#     vtkOutlineFilter VolRend(outline)
# #    VolRend(outline) SetInput [reader GetOutput]

#     vtkPolyDataMapper VolRend(outlineMapper)
#     VolRend(outlineMapper) SetInput [VolRend(outline) GetOutput]

#     vtkActor VolRend(outlineActor)
#     VolRend(outlineActor) SetMapper VolRend(outlineMapper)
#     eval [VolRend(outlineActor) GetProperty] SetColor 1 1 1
}

#-------------------------------------------------------------------------------
# .PROC VolRendRefresh
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendRefresh {} {
    global VolRend Slice Volume

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    if {$VolRend(idOriginal) == $Volume(idNone)} {
     return
    }

    VolRend(opacityTransferFunction) RemoveAllPoints
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(ScalarOpacityBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        eval VolRend(opacityTransferFunction) AddPoint $line
    }
    }

    VolRend(colorTransferFunction) RemoveAllPoints
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(ColorTransferBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        eval VolRend(colorTransferFunction) AddRGBPoint $line
    }
    }

    VolRend(GradientOpacityTRansferFunction) RemoveAllPoints
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(GradientOpacityBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        eval VolRend(GradientOpacityTRansferFunction) AddPoint $line
    }
    }

    VolRend(imageCast) SetInput [Volume($VolRend(idOriginal),vol) GetOutput]
    VolRend(imageCast) SetOutputScalarTypeToUnsignedShort

#    VolRend(volume) SetMapper VolRend(${VolRend(renderType)}volumeMapper)

    if {$VolRend(renderType) == "raycast"} {
    VolRend(volume) SetMapper VolRend(raycastvolumeMapper)
    [VolRend(volume) GetProperty] SetInterpolationTypeTo$VolRend(interpolationMethod)
    VolRend(raycastvolumeMapper) SetSampleDistance $VolRend(sampleDistance)
    VolRend(raycastvolumeMapper) SetInput [VolRend(imageCast) GetOutput]

    switch $VolRend(renderMethod) {
        "composite" {
        if {$VolRend(compositeMethod) == "interpolate"} {
            VolRend(compositeFunction) SetCompositeMethodToInterpolateFirst
        } else {
            VolRend(compositeFunction) SetCompositeMethodToClassifyFirst
        }
        VolRend(raycastvolumeMapper) SetVolumeRayCastFunction VolRend(compositeFunction)
        }
        
        "mip" {
        VolRend(mipFunction) SetMaximizeMethodTo$VolRend(mipMaxMethod)
        VolRend(raycastvolumeMapper) SetVolumeRayCastFunction VolRend(mipFunction)
        }
        
        "isosurface" {
        VolRend(isosurfaceFunction) SetIsoValue $VolRend(isoValue)
        VolRend(raycastvolumeMapper) SetVolumeRayCastFunction VolRend(isosurfaceFunction)
        }
    }

    if {[info commands t1] == ""} {
        vtkTransform t1
    }
    t1 Identity
    t1 PreMultiply
    t1 SetMatrix [Volume($VolRend(idOriginal),node) GetWldToIjk]
    t1 Inverse
    scan [Volume($VolRend(idOriginal),node) GetSpacing] "%g %g %g" res_x res_y res_z
    t1 PostMultiply
    t1 Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] [expr 1.0 / $res_z]
    }

    if {$VolRend(renderType) == "texture"} {
    VolRend(volume) SetMapper VolRend(texturevolumeMapper)
    [VolRend(volume) GetProperty] SetInterpolationTypeTo$VolRend(interpolationMethod)
#    VolRend(texturevolumeMapper) SetSampleDistance $VolRend(sampleDistance)
    VolRend(texturevolumeMapper) SetInput [VolRend(imageCast) GetOutput]

    if {[info commands t1] == ""} {
        vtkTransform t1
    }
    t1 Identity
    t1 PreMultiply
    t1 SetMatrix [Volume($VolRend(idOriginal),node) GetWldToIjk]
    t1 Inverse
    scan [Volume($VolRend(idOriginal),node) GetSpacing] "%g %g %g" res_x res_y res_z
    t1 PreMultiply
    t1 Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] [expr 1.0 / $res_z]
    }

    VolRend(volume) SetUserMatrix [t1 GetMatrix]

#    VolRend(outline) SetInput [Volume($VolRend(idOriginal),vol) GetOutput]
#    VolRend(outlineActor) SetUserMatrix [Volume($VolRend(idOriginal),node) GetPosition]

    VolRend(${VolRend(renderType)}volumeMapper) Update
    t1 Delete
    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC VolRendEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendEnter {} {
    global VolRend Volume Slice Module


    if { ![VTK_AT_LEAST 4.5] } {
        return
    }
    # If the Original is None, then select what's being displayed,
    # otherwise the first volume in the mrml tree.

    if {$VolRend(idOriginal) == $Volume(idNone)} {
        set v [[[Slicer GetBackVolume $Slice(activeID)] GetMrmlNode] GetID]
        if {$v == $Volume(idNone)} {
            set v [lindex $Volume(idList) 0]
        }
        if {$v != $Volume(idNone)} {
            VolRendSetOriginal $v
        }
    }

    pushEventManager $VolRend(eventManager)

#     if {$VolRend(idOriginal) != $Volume(idNone)} {
#     VolRend(volumeMapper) SetInput [Volume($VolRend(idOriginal),vol) GetOutput]
#     VolRend(volumeMapper) Update
#     }

    if {$VolRend(volumeVisible) == "0"} {
    #    MainAddActor VolRend(volume)
    foreach r $Module(Renderers) {
        $r AddVolume VolRend(volume)
        #    $r AddActor VolRend(outlineActor)
    }
    }
    set VolRend(volumeVisible) "1"

    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC VolRendExit
# Called when this module is exitedVolume($VolRend(idOriginal),node) GetPosition by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendExit {} {
     global VolRend Module Volume


    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    if {$VolRend(hideOnExit)} {
    #    MainRemoveActor VolRend(volume)
    foreach r $Module(Renderers) {
        $r RemoveVolume VolRend(volume)
        #    $r RemoveActor VolRend(outlineActor)
    }   
    VolRend(imageCast) SetInput [Volume($Volume(idNone),vol) GetOutput]
    set VolRend(volumeVisible) "0"

    RenderAll
    }

    popEventManager
}

#-------------------------------------------------------------------------------
# .PROC VolRendUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendUpdateMRML {} {
    global Volume VolRend

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $VolRend(idOriginal)] == -1} {
        VolRendSetOriginal $n
    }

    # Original Volume menu
    #---------------------------------------------------------------------------
    set m $VolRend(mOriginal)
    $m delete 0 end
    foreach v $Volume(idList) {
        $m add command -label [Volume($v,node) GetName] -command \
            "VolRendSetOriginal $v; RenderAll"
    }
}

#-------------------------------------------------------------------------------
# .PROC VolRendSetOriginal
#   Sets which volume is used in this module.
#   Called from VolRendUpdateMRML and VolRendEnter.
# .ARGS
#   v    Volume ID
# .END
#-------------------------------------------------------------------------------
proc VolRendSetOriginal {v} {
    global VolRend Volume

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }
    
    set VolRend(idOriginal) $v
    
    # Change button text
    $VolRend(mbOriginal) config -text [Volume($v,node) GetName]
}

#-------------------------------------------------------------------------------
# .PROC VolRendSaveTransferFunctions
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendSaveTransferFunctions {} {
    global VolRend Options

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    set VolRend(transferFunctionReadFileName) [tk_getSaveFile -title "Save file" -filetypes "{{XML} {.xml}} {{All files} {*}}" -initialdir [file dirname $VolRend(transferFunctionSaveFileName)] -initialfile $VolRend(transferFunctionSaveFileName)]

    if {$VolRend(transferFunctionSaveFileName) == ""} {
    return
    }

    vtkMrmlOptionsNode node
    node SetProgram $Options(program)
    node SetContents "VolRendTransferFunctions"

    set settings ""

    set settings "OpacityTransferFunction='\n"
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(ScalarOpacityBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        set settings "${settings}${line}\n"
    }
    }
    set settings "$settings'\n"

    set settings "${settings}ColorTransferFunction='\n"
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(ColorTransferBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        set settings "${settings}${line}\n"
    }
    }
    set settings "$settings'\n"

    set settings "${settings}GradientOpacityTransferFunction='\n"
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(GradientOpacityBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        set settings "${settings}${line}\n"
    }
    }
    set settings "$settings'\n"

    # fill in the options info
    node SetOptions $settings

    # temp tree for writing
    vtkMrmlTree tempTree
    tempTree AddItem node

    # tell the tree to write
    tempTree Write $VolRend(transferFunctionSaveFileName)
    if {[tempTree GetErrorCode] != 0} {
        puts "ERROR: VolRendSaveTransferFunctions: Unable to write file $VolRend(transferFunctionSaveFileName)"
    }

    tempTree RemoveAllItems

    tempTree Delete
    node Delete
}

#-------------------------------------------------------------------------------
# .PROC VolRendReadTransferFunctions
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendReadTransferFunctions {} {
    global VolRend

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    set VolRend(transferFunctionReadFileName) [tk_getOpenFile -title "Input file" -filetypes "{{XML} {.xml}} {{All files} {*}}" -initialdir [file dirname $VolRend(transferFunctionReadFileName)] -initialfile $VolRend(transferFunctionReadFileName)]

    if {$VolRend(transferFunctionReadFileName) == ""} {
    return
    }
    
    # read in the settings
    set tags [MainMrmlReadVersion2.0 $VolRend(transferFunctionReadFileName)]
    set node(program) ""
    set node(contents) ""

    foreach pair $tags {
    set tag  [lindex $pair 0]
    set attr [lreplace $pair 0 0]
    
    switch $tag {
        "Options" {
        foreach a $attr {
            set key [lindex $a 0]
            set val [lreplace $a 0 0]
            set node($key) $val
        }
        }    
    }
    }
    
    # check program and contents
    if {$node(program) != "slicer"} {
    set msg "This is not a Slicer file. It is from $node(program)."
    puts $msg
    tk_messageBox -message "$msg"
    }
    if {$node(contents) != $VolRend(contents)} {
    set msg "This is not a VolRend settings file. It is $node(contents)."
    puts $msg
    tk_messageBox -message "$msg"
    }

    $VolRend(ScalarOpacityBox) delete 1.0 end
    $VolRend(ScalarOpacityBox) insert insert "ScalarOpacityBox\n"
    if {[info exists node(OpacityTransferFunction)] == "1"} {
    foreach {scalar opacity} $node(OpacityTransferFunction) {
        $VolRend(ScalarOpacityBox) insert insert "$scalar $opacity\n"
    }
    }
    $VolRend(ScalarOpacityBox) insert insert "end"

    $VolRend(ColorTransferBox) delete 1.0 end
    $VolRend(ColorTransferBox) insert insert "ColorTransferBox\n"
    if {[info exists node(ColorTransferFunction)] == "1"} {
    foreach {scalar R G B} $node(ColorTransferFunction) {
        $VolRend(ColorTransferBox) insert insert "$scalar $R $G $B\n"
    }
    }
    $VolRend(ColorTransferBox) insert insert "end"

    $VolRend(GradientOpacityBox) delete 1.0 end
    $VolRend(GradientOpacityBox) insert insert "GradientOpacityBox\n"
    if {[info exists node(GradientOpacityTransferFunction)] == "1"} {
    foreach {gradient value} $node(GradientOpacityTransferFunction) {
        $VolRend(GradientOpacityBox) insert insert "$gradient $value\n"
    }
    }
    $VolRend(GradientOpacityBox) insert insert "end"
}

#-------------------------------------------------------------------------------
# .PROC VolRendSelectRenderMethod
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendSelectRenderMethod {} {
    global VolRend

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }
    
    raise $VolRend(f$VolRend(renderMethod))
    focus $VolRend(f$VolRend(renderMethod))
}

# >> Presets

#-------------------------------------------------------------------------------
# .PROC VolRendStorePresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendStorePresets {p} {
    global Preset VolRend Volume

    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    set Preset(VolRend,$p,idOriginal) $VolRend(idOriginal)
    set Preset(VolRend,$p,renderType) $VolRend(renderType)
    set Preset(VolRend,$p,sampleDistance) $VolRend(sampleDistance)
    set Preset(VolRend,$p,hideOnExit) $VolRend(hideOnExit)
    set Preset(VolRend,$p,interpolationMethod) $VolRend(interpolationMethod)
    set Preset(VolRend,$p,renderMethod) $VolRend(renderMethod)
    set Preset(VolRend,$p,compositeMethod) $VolRend(compositeMethod)
    set Preset(VolRend,$p,mipMaxMethod) $VolRend(mipMaxMethod)
    set Preset(VolRend,$p,isoValue) $VolRend(isoValue)

    set settings ""
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(ScalarOpacityBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        set settings "${settings}${line} "
    }
    }
    regsub -all "\n" $settings {} Preset(VolRend,$p,opacityTransferFunction)

    set settings ""
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(ColorTransferBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        set settings "${settings}${line} "
    }
    }
    regsub -all "\n" $settings {} Preset(VolRend,$p,colorTransferFunction)

    set settings ""
    set go 1
    for {set i 2} {$go == 1} {incr i} {
    set line [$VolRend(GradientOpacityBox) get $i.0 $i.end]
    if {$line == "end"} {
        set go 0
    } else {
        set settings "${settings}${line} "
    }
    }
    regsub -all "\n" $settings {} Preset(VolRend,$p,gradientOpacityTransferFunction)
}

#-------------------------------------------------------------------------------
# .PROC VolRendRecallPresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolRendRecallPresets {p} {
    global Preset VolRend
    
    if { ![VTK_AT_LEAST 4.5] } {
        return
    }

    set VolRend(idOriginal) $Preset(VolRend,$p,idOriginal)
    set VolRend(renderType) $Preset(VolRend,$p,renderType)
    set VolRend(sampleDistance) $Preset(VolRend,$p,sampleDistance)
    set VolRend(hideOnExit) $Preset(VolRend,$p,hideOnExit)
    set VolRend(interpolationMethod) $Preset(VolRend,$p,interpolationMethod)
    set VolRend(renderMethod) $Preset(VolRend,$p,renderMethod)
    set VolRend(compositeMethod) $Preset(VolRend,$p,compositeMethod)
    set VolRend(mipMaxMethod) $Preset(VolRend,$p,mipMaxMethod)
    set VolRend(isoValue) $Preset(VolRend,$p,isoValue)

    $VolRend(ScalarOpacityBox) delete 1.0 end
    $VolRend(ScalarOpacityBox) insert insert "ScalarOpacityBox\n"
    if {[info exists Preset(VolRend,$p,opacityTransferFunction)] == "1"} {
    foreach {scalar opacity} $Preset(VolRend,$p,opacityTransferFunction) {
        $VolRend(ScalarOpacityBox) insert insert "$scalar $opacity\n"
    }
    }
    $VolRend(ScalarOpacityBox) insert insert "end"

    $VolRend(ColorTransferBox) delete 1.0 end
    $VolRend(ColorTransferBox) insert insert "ColorTransferBox\n"
    if {[info exists Preset(VolRend,$p,colorTransferFunction)] == "1"} {
    foreach {scalar R G B} $Preset(VolRend,$p,colorTransferFunction) {
        $VolRend(ColorTransferBox) insert insert "$scalar $R $G $B\n"
    }
    }
    $VolRend(ColorTransferBox) insert insert "end"

    $VolRend(GradientOpacityBox) delete 1.0 end
    $VolRend(GradientOpacityBox) insert insert "GradientOpacityBox\n"
    if {[info exists Preset(VolRend,$p,gradientOpacityTransferFunction)] == "1"} {
    foreach {gradient value} $Preset(VolRend,$p,gradientOpacityTransferFunction) {
        $VolRend(GradientOpacityBox) insert insert "$gradient $value\n"
    }
    }
    $VolRend(GradientOpacityBox) insert insert "end"
}

# << Presets
