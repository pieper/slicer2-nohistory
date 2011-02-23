package require vtk
package require vtkSlicerBase

# Image pipeline

vtkImageReader reader
  reader ReleaseDataFlagOff
  reader SetDataByteOrderToLittleEndian
  reader SetDataExtent 0 63 0 63 1 93
  reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
  reader SetDataMask 0x7fff

vtkImageMagnify mag
  mag SetInput [reader GetOutput]
  mag SetMagnificationFactors 4 4 1

vtkImageCopy copy
  copy SetInput [mag GetOutput]
  copy ClearOff

vtkImageCopy copy1
  copy1 SetInput [mag GetOutput]
  copy1 ClearOn

vtkImageMathematics sub
 sub SetOperationToSubtract
 sub SetInput 0 [copy GetOutput]
 sub SetInput 1 [copy1 GetOutput]
 sub Update

vtkImageViewer viewer
  viewer SetInput [sub GetOutput]
  viewer SetZSlice 22
  viewer SetColorWindow 2000
  viewer SetColorLevel 1000

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]





