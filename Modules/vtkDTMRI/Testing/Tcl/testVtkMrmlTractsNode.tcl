package require vtkDTMRI
package require vtkSlicerBase

# create the object and test setting parameters
vtkMrmlTractsNode node

node SetFileName "test.vtk"

# output object's info
puts [node Print]

# write a MRML file with a TractGroup
vtkMrmlTree tree
tree AddItem node
tree Write "test.mrml"

# return success code for nightly testing
exit 0



