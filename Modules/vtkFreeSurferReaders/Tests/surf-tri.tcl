#! /usr/local/bin/vtk

# first we load in the standard vtk packages into tcl
package require vtk
package require vtkinteraction

load ../builds/bin/libvtkFreeSurferReadersTCL.so

# This loads the surface file.
set mris [vtkFSSurfaceReader _mris]
$mris SetFileName "/home/kteich/subjects/anders/surf/nicole.orig"

# Add a normals object to computer normals from the output of the
# surface.
set normals [vtkPolyDataNormals _normals]
$normals SetInput [$mris GetOutput]

set mapper [vtkPolyDataMapper _mapper]
$mapper SetInput [$normals GetOutput]

set actor [vtkActor _actor]
$actor SetMapper $mapper

[$actor GetProperty] SetColor 1 .9 .9

set renderer [vtkRenderer _renderer]

set renderWindow [vtkRenderWindow _render-window]
$renderWindow AddRenderer $renderer

set interactor [vtkRenderWindowInteractor _interactor]
$interactor SetRenderWindow $renderWindow

$renderer AddActor $actor
$renderer SetBackground 0 0 0

$interactor Initialize

$renderer Render

wm withdraw .


