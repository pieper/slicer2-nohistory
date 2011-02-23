#! /usr/local/bin/vtk

# first we load in the standard vtk packages into tcl
package require vtk
package require vtkinteraction

load ../builds/bin/libvtkFreeSurferReadersTCL.so

foreach hemi {lh rh} {

    # This loads the surface file.
    set mris($hemi) [vtkFSSurfaceReader _mris-$hemi]
    $mris($hemi) SetFileName "/home/kteich/subjects/anders/surf/${hemi}.plump"

    # Add a normals object to computer normals from the output of the
    # surface.
    set normals($hemi) [vtkPolyDataNormals _normals-$hemi]
    $normals($hemi) SetInput [$mris($hemi) GetOutput]
    
    set mapper($hemi) [vtkPolyDataMapper _mapper-$hemi]
    $mapper($hemi) SetInput [$normals($hemi) GetOutput]
    
    set actor($hemi) [vtkActor _actor-$hemi]
    $actor($hemi) SetMapper $mapper($hemi)

    [$actor($hemi) GetProperty] SetColor 1 .9 .9
}


set renderer [vtkRenderer _renderer]

set renderWindow [vtkRenderWindow _render-window]
$renderWindow AddRenderer $renderer

set interactor [vtkRenderWindowInteractor _interactor]
$interactor SetRenderWindow $renderWindow

foreach hemi {lh rh} {
    $renderer AddActor $actor($hemi)
}
$renderer SetBackground 0 0 0

$interactor Initialize

$renderer Render

wm withdraw .


