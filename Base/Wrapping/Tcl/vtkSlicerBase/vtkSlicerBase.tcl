package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[info commands vtkMrmlSlicer] != "" ||
    [::vtk::load_component vtkSlicerBaseTCL] == ""} {
    package provide vtkSlicerBase 1.0
}
