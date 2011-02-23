package require vtk
package require vtkSlicerBase

# this script tests vtkImageCloseUp2D 

# Image pipeline

vtkPNGReader reader
reader SetFileName $VTK_DATA_ROOT/Data/fullhead15.png

vtkImageCloseUp2D CloseUp
  CloseUp SetInput [reader GetOutput]
  CloseUp SetMagnification 2
  CloseUp SetRadius 50
  CloseUp SetX 150
  CloseUp SetY 150

vtkImageViewer viewer
viewer SetInput [CloseUp GetOutput]
viewer SetColorWindow 163
viewer SetColorLevel 360

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]







