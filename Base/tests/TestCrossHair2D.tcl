package require vtk
package require vtkSlicerBase

# Image pipeline

vtkImageReader reader
  reader ReleaseDataFlagOff
  reader SetDataByteOrderToLittleEndian
  reader SetDataExtent 0 63 0 63 22 22
  reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
  reader SetDataMask 0x7fff
  set a [ reader GetDataSpacing]
  reader SetDataSpacing 1 2 0
  set b [lindex $a 0]
  set c [lindex $a 1]
  set b "$b [ expr 2 * $c ]"
  set b "$b  0"
  puts $b

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

vtkImageCrossHair2D CrossH
  CrossH SetInput [AppCom2 GetOutput]
  CrossH SetCursor 50 50 
  CrossH ShowCursorOn
  CrossH IntersectCrossOff
  CrossH SetMagnification 2
  CrossH BullsEyeOn
  CrossH SetBullsEyeWidth 2
  CrossH SetCursorColor 0.3 1 1
#  CrossH SetCursorColor 0 0 0 

vtkImageViewer viewer
  viewer SetInput [CrossH GetOutput]
  viewer SetZSlice 22
  viewer SetColorWindow 2000
  viewer SetColorLevel 1000

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]
