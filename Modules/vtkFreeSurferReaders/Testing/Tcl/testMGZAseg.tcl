# load in mgz file

package require vtkFreeSurferReaders

# load up the volume
vtkMGHReader mghReaderAseg
mghReaderAseg SetFileName [file join [file dirname [info script]] .. Data bert mri aseg.mgz]
mghReaderAseg SetFilePrefix [file dirname [mghReaderAseg GetFileName]]
mghReaderAseg ReadVolumeHeader
mghReaderAseg Update


scan [[mghReaderAseg GetOutput] GetWholeExtent] "%d %d %d %d %d %d" \
        xMin xMax yMin yMax zMin zMax


# Create the RenderWindow, Renderer and interactive renderer
#
vtkRenderer ren1
vtkRenderWindow renWin
renWin AddRenderer ren1
ren1 SetBackground 1.0 1.0 1.0
vtkRenderWindowInteractor iren
iren SetRenderWindow renWin

vtkImageReslice resliceAseg
resliceAseg SetInput [mghReaderAseg GetOutput]
resliceAseg SetInterpolationModeToCubic
resliceAseg SetOutputSpacing 1 1 1
resliceAseg SetOutputOrigin 0 0 0
resliceAseg SetOutputExtent $xMin $xMax $yMin $yMax $zMin $zMax

vtkImageMapper mapperAseg
mapperAseg SetInput [resliceAseg GetOutput]
mapperAseg SetColorWindow 2000
mapperAseg SetColorLevel 1000
mapperAseg SetZSlice [expr ($zMax - $zMin) / 2 + $zMin]

vtkActor2D actorAseg
actorAseg SetMapper mapperAseg

ren1 AddActor2D actorAseg

renWin SetSize [expr $xMax - $xMin] [expr $yMax - $yMin]
renWin Render
iren AddObserver UserEvent {wm deiconify .vtkInteract}

# prevent the tk window from showing up then start the event loop
wm withdraw .

proc WriteMGZAsegPNG { {filename ""} } {

    if {$filename == ""} {
        set filename  [file join [file dirname [info script]] .. Baseline testMGZAseg.tcl.png]
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
