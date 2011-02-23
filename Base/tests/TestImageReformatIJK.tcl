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

# this script tests vtkImageReformatIJK.tcl

### Lousy Test! Doesn't test complicated matrix stuff

vtkImageReformatIJK ref
ref SetInput [reader GetOutput]
ref SetInputOrderString SI
ref SetOutputOrderString SI
ref SetSlice 22
ref ComputeTransform
ref ComputeOutputExtent
ref Update

#vtkImageViewer viewer
#viewer SetInput [ref GetOutput]
##viewer SetZSlice 0
#viewer SetColorWindow 2000
#viewer SetColorLevel 1000

set ijk "10 10 10"
puts "ijk = $ijk"
eval ref SetIJKPoint $ijk
set xy  [ref GetXYPoint]

if {[lindex $xy 0] != "11"} {
  error "Didn't get right answer for \"x\"!"
}

if {[lindex $xy 1] != "11"} {
  error "Didn't get right answer for \"y\"!"
}
