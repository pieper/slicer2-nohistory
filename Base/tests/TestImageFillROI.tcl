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

# get just one slice
vtkImageClip clip
  clip SetInput [mag GetOutput]
  clip SetOutputWholeExtent 0 255 0 255 10 10
  clip ClipDataOn
  clip ReleaseDataFlagOff

vtkPoints roiPoints
  roiPoints InsertNextPoint 2 2 0
  roiPoints InsertNextPoint 200 230 0
  roiPoints InsertNextPoint 220 50 0
  roiPoints InsertNextPoint 4 10 0

### This is not a good test.
### It does not test the different types of shapes
vtkImageFillROI flroi
#flroi SetInput [reader GetOutput]
flroi SetInput [clip GetOutput]
flroi SetValue 1000
flroi SetRadius 10

#flroi SetShapeString Polygon
flroi SetShapeString Lines
#flroi SetShapeString Points
flroi SetPoints roiPoints

vtkImageViewer viewer
viewer SetInput [flroi GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 1031
viewer SetColorLevel 818

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]
