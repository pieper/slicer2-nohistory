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
th SetInput [mag GetOutput]
th SetReplaceIn 1
th SetReplaceOut 1
th ThresholdBetween -1000 1000
th SetOutValue 0
th SetInValue 2000

## Lousy test, doesn't test fade stuff!
vtkImageOverlay over
over SetInput 0 [th GetOutput]
over SetInput 1 [mag GetOutput]
over SetOpacity 1 0.5

vtkImageViewer viewer
viewer SetInput [over GetOutput]
viewer SetZSlice 52
viewer SetColorWindow 1879
viewer SetColorLevel 1242

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]

