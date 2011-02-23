# load in mgz file

package require vtkFreeSurferReaders

# load up the volume
vtkMGHReader mghReaderBrain
mghReaderBrain SetFileName [file join [file dirname [info script]] .. Data bert mri brain.mgz]
mghReaderBrain SetFilePrefix [file dirname [mghReaderBrain GetFileName]]
mghReaderBrain ReadVolumeHeader
mghReaderBrain Update


scan [[mghReaderBrain GetOutput] GetWholeExtent] "%d %d %d %d %d %d" \
        xMin xMax yMin yMax zMin zMax

# Create the RenderWindow, Renderer and interactive renderer
#
vtkRenderer ren1
vtkRenderWindow renWin
renWin AddRenderer ren1
ren1 SetBackground 1.0 1.0 1.0
vtkRenderWindowInteractor iren
iren SetRenderWindow renWin


vtkImageReslice resliceBrain
resliceBrain SetInput [mghReaderBrain GetOutput]
resliceBrain SetInterpolationModeToCubic
resliceBrain SetOutputSpacing 1 1 1
resliceBrain SetOutputOrigin 0 0 0
resliceBrain SetOutputExtent $xMin $xMax $yMin $yMax $zMin $zMax

vtkImageMapper mapperBrain
mapperBrain SetInput [resliceBrain GetOutput]
mapperBrain SetColorWindow 2000
mapperBrain SetColorLevel 1000
mapperBrain SetZSlice [expr ($zMax - $zMin) / 2 + $zMin]

vtkActor2D actorBrain
actorBrain SetMapper mapperBrain

ren1 AddActor2D actorBrain

renWin Render

renWin SetSize [expr $xMax - $xMin] [expr $yMax - $yMin]
renWin Render
iren AddObserver UserEvent {wm deiconify .vtkInteract}

# prevent the tk window from showing up then start the event loop
wm withdraw .

proc WriteMGZBrainPNG { {filename ""} } {

    if {$filename == ""} {
        set filename  [file join [file dirname [info script]] .. Baseline testMGZBrain.tcl.png]
    }
    puts "Writing file $filename"

    vtkWindowToImageFilter w2if
    w2if SetInput renWin
    vtkPNGWriter pngWriter
    pngWriter SetInput [w2if GetOutput]
    pngWriter SetFileName $filename

    renWin Render
    w2if Modified
    pngWriter Write
    
}
