# test tractography in example DTI data
# this script outputs one fiber with one/two lines and tensors/none

package require vtkDTMRI

# read tensors
vtkStructuredPointsReader reader
reader SetFileName exampleDiffusionTensors.vtk
reader Update
set tensors [reader GetOutput]

#puts [$tensors Print]

# set up seed points
#-----------------------------------
#Bounds:
#    Xmin,Xmax: (108, 144)
#    Ymin,Ymax: (101, 145)
#    Zmin,Zmax: (96.2, 119.6)
# The seed points must be within bounds of the input data
# and this input was clipped out from center of a larger
# dataset.
#set seedPoints {{120 123 105} {120 131 110}}
set seedPoints {{120 123 105}}

set fiber 0

vtkPolyDataWriter w

foreach seed $seedPoints {

    set i [lindex $seed 0]
    set j [lindex $seed 1]
    set k [lindex $seed 2]

    vtkHyperStreamlineDTMRI s$fiber
    #vtkHyperStreamline s$fiber

    s$fiber SetStartPosition  $i $j $k
    s$fiber SetInput $tensors

    #s$fiber DebugOn


    # test combinations of parameters ...............


    # default
    # --------------------------
    s$fiber OutputTensorsOff
    s$fiber OneTrajectoryPerSeedPointOff
    s$fiber Update
    w SetInput [s$fiber GetOutput]
    w SetFileName "tractographyTwoLines.vtk"
    w Write


    # 2 lines, save tensors
    # --------------------------
    s$fiber OutputTensorsOn
    s$fiber OneTrajectoryPerSeedPointOff
    s$fiber Update
    w SetInput [s$fiber GetOutput]
    w SetFileName "tractographyTwoLinesAndTensors.vtk"
    w Write


    # 1 line
    # --------------------------
    s$fiber OutputTensorsOff
    s$fiber OneTrajectoryPerSeedPointOn
    s$fiber Update
    w SetInput [s$fiber GetOutput]
    w SetFileName "tractographyOneLine.vtk"
    w Write

    # 1 line, save tensors
    # --------------------------
    s$fiber OutputTensorsOn
    s$fiber OneTrajectoryPerSeedPointOn
    s$fiber Update
    w SetInput [s$fiber GetOutput]
    w SetFileName "tractographyOneLineAndTensors.vtk"
    w Write

    
    incr fiber
}



puts "Deleting objects"
w Delete
reader Delete


set count 0
while { $count < $fiber } {
  s$count Delete
  incr count
}  

exit
