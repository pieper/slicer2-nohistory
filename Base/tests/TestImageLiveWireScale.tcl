package require vtk
package require vtkSlicerBase

# Image pipeline

vtkImageReader reader
  reader ReleaseDataFlagOff
  reader SetDataByteOrderToLittleEndian
  reader SetDataExtent 0 63 0 63 1 93
  reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
  reader SetDataMask 0x7fff

vtkImageLiveWireScale norm2
norm2 SetInput [reader GetOutput]
norm2 SetScaleFactor 255
#norm2 SetTransformationFunctionToInverseLinearRamp
norm2 SetTransformationFunctionToOneOverX

vtkImageLiveWireScale norm
#norm SetInput [reader GetOutput]
norm SetInput [norm2 GetOutput]

# test various normalization methods.

# max val filter will output
norm SetScaleFactor 255
# method:
#norm SetTransformationFunctionToInverseLinearRamp
#norm SetTransformationFunctionToOneOverX

vtkPoints points
set numPoints 30
points SetNumberOfPoints $numPoints

for {set i 0} {$i < $numPoints} {incr i} {
    #points SetPoint $i $i $i 0
    points SetPoint $i 100 $i 0
}

norm SetLookupPoints points
#norm SetUseLookupTable 1
norm SetUseGaussianLookup 1

vtkImageViewer viewer
viewer SetInput [norm GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 300
viewer SetColorLevel 100

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]









