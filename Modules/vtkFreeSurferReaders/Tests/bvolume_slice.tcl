#! /usr/local/bin/vtk

package require vtk
package require vtkinteraction

load ../bin/libvtkFreeSurferReadersTCL.so

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
    global reslice
    global viewer
    global gPlane

    switch $axis {
    x { $reslice($axis) SetResliceAxesOrigin $gPlane($axis) 0 0 }
    y { $reslice($axis) SetResliceAxesOrigin 0 $gPlane($axis) 0 }
    z { $reslice($axis) SetResliceAxesOrigin 0 0 $gPlane($axis) }
    }
    $viewer($axis) Render
}


# ============================================================= Volume reader


# Load the binary volume.
set reader [vtkBVolumeReader _reader]
$reader SetFilePrefix /home/kteich/test_data/functional/overlay-bfloat/fsig
#set reader [vtkCORReader _reader]
#$reader SetFilePrefix /home/kteich/freesurfer/subjects/bert/mri/T1
$reader Update

set dimensions [$reader GetDataDimensions]
set lVolume(x) [lindex $dimensions 0]
set lVolume(y) [lindex $dimensions 1]
set lVolume(z) [lindex $dimensions 2]

set spacing [$reader GetDataSpacing]
set lSpacing(x) [lindex $spacing 0]
set lSpacing(y) [lindex $spacing 1]
set lSpacing(z) [lindex $spacing 2]

foreach axis {x y z} {
    set gPlane($axis) [expr $lVolume($axis) / 2]
}

# ================================================================== Controls

# Make three sliders
foreach axis {x y z} {
    
    set swSlider($axis) $fwControl($axis).sw$axis
    scale $swSlider($axis) \
    -from 0 -to [expr $lVolume($axis) * $lSpacing($axis)] \
    -orient horizontal -variable gPlane($axis)

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
    $reslice($axis) SetInput [$reader GetOutput]
    $reslice($axis) SetOutputExtent 0 255 0 255 0 1
    $reslice($axis) SetOutputSpacing 1 1 1
    $reslice($axis) SetOutputDimensionality 2

    switch $axis {
    x { $reslice($axis) SetResliceAxesDirectionCosines \
        0 0 1 \
        0 1 0 \
        1 0 0 }
    y { $reslice($axis) SetResliceAxesDirectionCosines \
        1 0 0 \
        0 0 1 \
        0 1 0 }
    z { $reslice($axis) SetResliceAxesDirectionCosines \
        1 0 0 \
        0 1 0 \
        0 0 1 }
    }

}

# ================================================================== Viewer
    
foreach axis {x y z} {

    set rwRender($axis) $fwRender($axis).rwRender
    vtkTkImageViewerWidget $rwRender($axis) \
    -height 256 -width 256
    pack $rwRender($axis) -fill both -expand yes

    set viewer($axis) [$rwRender($axis) GetImageViewer]
    $viewer($axis) SetInput [$reslice($axis) GetOutput]
    $viewer($axis) SetColorWindow 3
    $viewer($axis) SetColorLevel 1

    ::vtk::bind_tk_imageviewer_widget $rwRender($axis)
}

# ====================================================================== Main

wm withdraw .

UpdateSlice x
UpdateSlice y
UpdateSlice z

