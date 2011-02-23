package require vtkTensorUtil

vtkImageData img
  img SetScalarTypeToUnsignedChar
  img SetDimensions 10 10 10
  img AllocateScalars
set tensors [[img GetPointData] GetTensors]
puts [$tensors Print]
[[img GetPointData] GetTensors] SetName "TestTensors"

set numTens [expr 10*10*10]
for {set i 0} {$i<$numTens} {incr i} {
   $tensors SetTuple9 $i 1 2 3 4 5 6 7 8 9
}

vtkImageGetTensorComponents getTens
  getTens SetInput img
  getTens Update

puts [[getTens GetOutput] Print]


