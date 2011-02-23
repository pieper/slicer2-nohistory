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

vtkImageCast cast
cast SetInput [mag GetOutput]
cast SetOutputScalarTypeToFloat

vtkImageCast cast2
cast2 SetInput [th GetOutput]
cast2 SetOutputScalarTypeToFloat

vtkImageWeightedSum sum
sum SetInput 0 [cast GetOutput]
sum SetInput 1 [cast2 GetOutput]
sum SetWeightForInput 0 10
sum SetWeightForInput 1 4
puts "set inputs to sum"

vtkImageViewer viewer
viewer SetInput [sum GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 1819
viewer SetColorLevel 939

puts "grabbed sum's output"

sum SetWeightForInput 0 1
puts "---"
#sum SetWeightForInput 1 2

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]

