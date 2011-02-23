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
th SetInValue 1000 
th SetOutValue 2000 
th ThresholdBetween 1000 2000

vtkImageConnectivity cca
cca SetInput [th GetOutput]
cca SetSeed 100 100 100
cca SetOutputLabel 100
cca SetBackground 155
#cca SetMinSize
#cca SetMinForeground
#cca SetMaxForeground 
cca SetLargestIslandSize 15000
cca Update

vtkImageViewer viewer
viewer SetInput [cca GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 2000
viewer SetColorLevel 1000

#make interface
#source [file join [file dirname [info script]] WindowLevelInterface.tcl]







