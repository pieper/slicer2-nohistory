#! /usr/local/bin/vtk

package require vtk
package require vtkinteraction

load ../builds/bin/libvtkFreeSurferReadersTCL.so

set wwTop          .wwTop
set fwMain         $wwTop.fwMain

toplevel $wwTop
wm geometry $wwTop

frame $fwMain

foreach axis {x y z} {
    set fwView($axis) $fwMain.fwView-$axis
    frame $fwView($axis)

    set fwRender($axis)  $fwView($axis).fwRender-$axis
    frame $fwRender($axis) -height 256 -width 256 -relief raised -border 2

    set fwControl($axis) $fwView($axis).fwControl-$axis
    frame $fwControl($axis)

    pack $fwRender($axis) $fwControl($axis) -side top \
    -fill both -expand yes
}

pack $fwView(x) $fwView(y) $fwView(z) -side left \
    -fill both -expand yes
pack $fwMain -expand yes -fill both

# ================================================================= Callbacks

proc UpdateSlice { axis } {
    global viewer
    global gPlane

    $viewer($axis) SetZSlice $gPlane($axis)
    $viewer($axis) Render
}


# ============================================================= Volume reader

# Load the COR volume.
set mri [vtkCORReader _mri]
$mri SetFilePrefix "/home/kteich/subjects/grace/mri/T1"
$mri Update

set lVolume(x) 256
set lVolume(y) 256
set lVolume(z) 256

foreach axis {x y z} {
    set gPlane($axis) [expr $lVolume($axis) / 2]
}

set minValue 0
set maxValue 255

# Compute some color ramp values
set lRamp 4
for { set i 0 } { $i < $lRamp } { incr i } {
    set ramp($i) [expr $minValue + [expr [expr $maxValue / $lRamp] * $i]]
}

# ================================================================== Controls

# Make three sliders
foreach axis {x y z} {
    
    set swSlider($axis) $fwControl($axis).sw$axis
    scale $swSlider($axis) \
    -from 0 -to $lVolume($axis) -orient horizontal -variable gPlane($axis)

    pack $swSlider($axis) -expand yes -fill x

}

bind $swSlider(x) <ButtonRelease> { UpdateSlice x }
bind $swSlider(x) <B1-Motion> { UpdateSlice x }
bind $swSlider(y) <ButtonRelease> { UpdateSlice y }
bind $swSlider(y) <B1-Motion> { UpdateSlice y }
bind $swSlider(z) <ButtonRelease> { UpdateSlice z }
bind $swSlider(z) <B1-Motion> { UpdateSlice z }

# ================================================================ Reslicer

foreach axis {x y z} {

    set reslice($axis) [vtkImageReslice _reslice-$axis]
    $reslice($axis) SetInput [$mri GetOutput]
    $reslice($axis) SetOutputOrigin 0 0 0
    $reslice($axis) SetOutputSpacing 1 1 1
    $reslice($axis) SetOutputExtent 0 $lVolume(x) 0 $lVolume(y) 0 $lVolume(z)
    $reslice($axis) SetOutputDimensionality 3

    switch $axis {
    x { $reslice($axis) SetResliceAxesDirectionCosines 0 0 1 0 1 0 1 0 0 }
    y { $reslice($axis) SetResliceAxesDirectionCosines 1 0 0 0 0 1 0 1 0 }
    z { $reslice($axis) SetResliceAxesDirectionCosines 1 0 0 0 1 0 0 0 1 }
    }
}

# ================================================================== Viewer
    
foreach axis {x y z} {

    set lut [vtkLookupTable _lut-$axis]
    $lut SetTableRange $minValue $maxValue
    $lut SetNumberOfColors [expr $maxValue + 1]
    for { set i $minValue } { $i <= $maxValue } { incr i } {
    set f [expr $i / $maxValue.0]
    $lut SetTableValue $i $f $f $f 1.0
    }
    
    set mapper [vtkImageMapToColors _mapper-$axis]
    $mapper SetInput [$reslice($axis) GetOutput]
    $mapper SetOutputFormatToRGBA
    $mapper SetLookupTable $lut

    set rwRender($axis) $fwRender($axis).rwRender
    vtkTkImageViewerWidget $rwRender($axis) \
    -height 256 -width 256
    pack $rwRender($axis) -fill both -expand yes

    set viewer($axis) [$rwRender($axis) GetImageViewer]
    $viewer($axis) SetInput [$reslice($axis) GetOutput]
    $viewer($axis) SetColorWindow 127
    $viewer($axis) SetColorLevel 127
    $viewer($axis) SetZSlice 128

    BindTkImageViewer $rwRender($axis)
}

# ====================================================================== Main

wm withdraw .

UpdateSlice x
UpdateSlice y
UpdateSlice z

