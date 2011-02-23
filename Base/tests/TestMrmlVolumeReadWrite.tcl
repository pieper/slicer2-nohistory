package require vtk
package require vtkSlicerBase

# Image pipeline

#### TEST WRITING
vtkImageReader reader
  reader ReleaseDataFlagOff
#  reader SetDataByteOrderToLittleEndian
#  reader SetDataExtent 0 63 0 63 1 93
#  reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
#  reader SetDataMask 0x7fff
  reader SetFilePrefix /projects/lmi/people/odonnell/data/florin_gradient5
  reader SetFilePattern "%s.%03d"
  reader SetDataExtent 0 255 0 255 1 6
  reader Update

vtkMrmlVolumeNode node
node SetDescription "hi"
node SetName "baby"
# these are not needed, using sub-node
#node SetFilePrefix test
## the full prefix is used by the reader, not the file prefix.
#node SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
#node SetFilePattern "%s.%d"
node SetImageRange 1 6
node SetDimensions 256 256

vtkMrmlDataVolume vol
vol SetMrmlNode node
vol SetImageData [reader GetOutput]
vol Update
#puts [node GetFilePrefix]
#vol Read

vtkMrmlDataVolumeReadWriteStructuredPoints dvrw
vol SetReadWrite dvrw 
puts "set read write"
dvrw SetFileName test.vtk
dvrw SetFileName /projects/lmi/people/odonnell/src4.0/slicer2/Base/tests/test.vtk
vol Write
puts "wrote test.vtk"

#### TEST READING
node Delete
vol Delete
dvrw Delete

vtkMrmlVolumeNode node
node SetDescription "hi"
node SetName "baby"

vtkMrmlDataVolume vol
vol SetMrmlNode node

vtkMrmlDataVolumeReadWriteStructuredPoints dvrw
vol SetReadWrite dvrw 
puts "set read write"
dvrw SetFileName test.vtk
dvrw SetFileName /projects/lmi/people/odonnell/src4.0/slicer2/Base/tests/test.vtk
vol Read
puts "wrote test.vtk"

puts [ [vol GetOutput] Print]
exit

