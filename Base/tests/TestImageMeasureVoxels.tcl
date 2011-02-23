package require vtk
package require vtkSlicerBase

# Image pipeline

vtkImageReader reader
  reader ReleaseDataFlagOff
  reader SetDataByteOrderToLittleEndian
  reader SetDataExtent 0 63 0 63 1 93
  reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
  reader SetDataMask 0x7fff

vtkImageThreshold thresh
  thresh SetInput [reader GetOutput]
  thresh SetReplaceIn 1
  thresh SetReplaceOut 1
  thresh SetInValue 4000
  thresh SetOutValue 0
  thresh ThresholdBetween 0 10

vtkImageMeasureVoxels measure
measure SetInput [thresh GetOutput]
measure SetFileName TestImageMeasureVoxels.txt
measure Update

puts "results are in the file TestImageMeasureVoxels.txt"
exit






