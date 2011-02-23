package require vtkDTMRI
package require vtkSlicerBase

# create the object and test setting parameters
vtkMrmlTractGroupNode node

node SetTractGroupID 1
node AddTractToGroup 2
node AddTractToGroup 3

# output object's info
puts [node Print]

# write a MRML file with a TractGroup
vtkMrmlTree tree
tree AddItem node
tree Write "test.mrml"

# return success code for nightly testing
exit 0




