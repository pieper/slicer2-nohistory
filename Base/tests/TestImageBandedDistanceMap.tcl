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

vtkImageThreshold thresh
thresh SetReplaceIn 1
thresh SetReplaceOut 1
# output 1's for the label we want
thresh SetInValue 1
thresh SetOutValue 0
thresh SetInput [mag GetOutput]
reader Delete
# values to grab:
thresh ThresholdBetween 750 920

vtkImageBandedDistanceMap distmap
distmap SetInput [thresh GetOutput]
thresh Delete
distmap SetBackground 0
distmap SetForeground 1

distmap SetMaximumDistanceToCompute 20

#exit

#distmap Update



vtkImageViewer viewer
viewer SetInput [distmap GetOutput]
#viewer SetInput [thresh GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 50
viewer SetColorLevel 0

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]
