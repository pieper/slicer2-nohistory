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

vtkImageThreshold th
  th SetReplaceIn 1
  th SetReplaceOut 0
  th SetInValue 4000
  th ThresholdBetween 1000 2000

vtkImageEditor edit 
  edit SetInput [mag GetOutput]
  edit UseInputOn
  edit SetDimensionTo3D
#  edit SetDimensionToSingle
  edit SetSlice 22 
  edit SetInputSliceOrder SI
  edit SetFirstFilter th
  edit SetLastFilter th
  edit Apply
  edit Undo
  edit Apply
 
vtkImageViewer viewer
viewer SetInput [edit GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 2000
viewer SetColorLevel 1000

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]







