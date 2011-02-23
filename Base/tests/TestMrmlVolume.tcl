package require vtk
package require vtkSlicerBase

# Image pipeline

vtkMrmlVolumeNode node
node LittleEndianOn
node SetDescription "This code better work!"
node SetName "Dave"
node SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
# the full prefix is used by the reader, not the file prefix.
node SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
node SetFilePattern "%s.%d"
node SetImageRange 1 93
node SetDimensions 256 256

scan [node GetImageRange] "%d %d" lo hi
puts "lo $lo hi $hi"
puts "Pattern"
puts [node GetFilePattern ]
puts "Prefix"
puts [node GetFilePrefix  ]

vtkMrmlDataVolume vol
vol SetMrmlNode node
vol Update
puts [node GetFilePrefix]
vol Read

vtkImageViewer viewer
viewer SetInput [vol GetOutput]
viewer SetZSlice 0 
viewer SetColorWindow 2000
viewer SetColorLevel 1000

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]







