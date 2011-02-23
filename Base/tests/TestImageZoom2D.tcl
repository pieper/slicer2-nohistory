package require vtk
package require vtkSlicerBase

# this script tests vtkImageZoom2D

# Image pipeline

vtkPNGReader reader
reader SetFileName $VTK_DATA_ROOT/Data/fullhead15.png

vtkImageZoom2D CloseUp
  CloseUp SetInput [reader GetOutput]
  CloseUp SetMagnification 2

vtkImageViewer viewer
viewer SetInput [CloseUp GetOutput]
viewer SetColorWindow 163
viewer SetColorLevel 360

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]







