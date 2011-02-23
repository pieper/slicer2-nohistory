# load in a surface file (created from an ascii file)

package require vtkFreeSurferReaders

# load up the surface
catch "sReader Delete"
vtkFSSurfaceReader sReader
sReader SetFileName [file join [file dirname [info script]] .. Data lh.dart.orig]

catch "normals Delete"
vtkPolyDataNormals normals
normals SetSplitting 0
normals SetInput [sReader GetOutput]

catch "stripper Delete"
vtkStripper stripper
stripper SetInput [normals GetOutput]

set pdata [stripper GetOutput]
$pdata Update

catch "mapper Delete"
vtkPolyDataMapper mapper
mapper SetInput $pdata

catch "actor Delete"
vtkActor actor 
actor SetMapper mapper

set prop [actor GetProperty]
# actor SetBackFaceProperty $prop

# Create the RenderWindow, Renderer and interactive renderer
#
catch "ren1 Delete"
vtkRenderer ren1
catch "renWin Delete"
vtkRenderWindow renWin
renWin AddRenderer ren1
ren1 SetBackground 1.0 1.0 1.0
catch "iren Delete"
vtkRenderWindowInteractor iren
iren SetRenderWindow renWin


ren1 AddActor actor

renWin Render

iren AddObserver UserEvent {wm deiconify .vtkInteract}

# prevent the tk window from showing up then start the event loop
wm withdraw .

proc WritePNG { {filename ""} } {

    if {$filename == ""} {
        set filename  [file join [file dirname [info script]] .. Baseline testOrig.tcl.png]
    }
    puts "Writing file $filename"

    catch "w2if Delete"
    vtkWindowToImageFilter w2if
    w2if SetInput renWin
    catch "pngWriter Delete"
    vtkPNGWriter pngWriter
    pngWriter SetInput [w2if GetOutput]
    pngWriter SetFileName $filename

    renWin Render
    w2if Modified
    pngWriter Write
    
}
