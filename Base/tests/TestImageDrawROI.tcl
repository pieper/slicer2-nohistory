package require vtk
package require vtkSlicerBase

# Image pipeline

vtkImageReader reader
reader ReleaseDataFlagOff
reader SetDataByteOrderToLittleEndian
reader SetDataExtent 0 63 0 63 1 1
reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
reader SetDataMask 0x7fff

vtkImageMagnify mag
  mag SetInput [reader GetOutput]
  mag SetMagnificationFactors 4 4 1

vtkImageCast ImCast
  ImCast SetOutputScalarTypeToUnsignedChar
  ImCast SetInput [mag GetOutput] 

vtkImageAppendComponents AppCom
  AppCom SetInput 0 [ ImCast GetOutput]
  AppCom SetInput 1 [ ImCast GetOutput]

vtkImageAppendComponents AppCom2
  AppCom2 SetInput 0 [ ImCast GetOutput]
  AppCom2 SetInput 1 [ AppCom GetOutput]

vtkImageDrawROI drroi
drroi SetInput [AppCom2 GetOutput]
drroi SetPointColor 0 1 1
drroi SetLineColor 0 1 1
drroi SelectPoint 0 0 
drroi SelectPoint 100 100
drroi SelectPoint 100 40
drroi SelectPoint 20 20

vtkImageViewer viewer
viewer SetInput [drroi GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 2000
viewer SetColorLevel 1000

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]







