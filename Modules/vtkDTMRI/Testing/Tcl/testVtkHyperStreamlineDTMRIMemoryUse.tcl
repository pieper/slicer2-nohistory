# Imitate the Hyper.tcl script from VTK, create a lot of 
# hyperstreamlines, and write to disk.
# The purpose of this script is to show how much memory is used.

package require vtkDTMRI

# generate tensors
vtkPointLoad ptLoad
ptLoad SetLoadValue 100.0
ptLoad SetSampleDimensions 20 20 20
ptLoad ComputeEffectiveStressOn
ptLoad SetModelBounds -10 10 -10 10 -10 10
set input [ptLoad GetOutput]

# make tensors
ptLoad Update

# for writing all hyperstreamlines to disk
vtkAppendPolyData app


# make many hyperstreamlines, each somewhere 
# within the dataset
set count 1
set numberOfHyperStreamlines 1000

while { $count < $numberOfHyperStreamlines } {

    vtkHyperStreamlineDTMRI s$count
    #s$count SetStartPosition  -9 -9 -9
    s$count SetStartPosition  -9 -9 [expr -9 + 19/$count]
    s$count SetInput $input
    s$count Update

    # add this one to the appender
    app AddInput [s$count GetOutput]

    #s$count Delete

    incr count
}

puts "Created $count hyperstreamlines."
puts "Now check memory use via top or similar program."
puts "You have 30 s. before execution resume"
after 30000 set timeout 1
vwait timeout


# Save the appended hyperstreamlines
vtkPolyDataWriter w
w SetInput [app GetOutput]
set fileName "test.vtk"
w SetFileName $fileName
w Write

#app Delete
#w Delete

puts "Wrote hyperstreamlines in file $fileName."


puts "Deleting objects"
ptLoad Delete
app Delete
w Delete

set count 1
while { $count < $numberOfHyperStreamlines } {
  s$count Delete
  incr count
}  
