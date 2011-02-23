# Imitate the Hyper.tcl script from VTK, but use our 
# vtkMultiStreamlineController class

package require vtkDTMRI

# generate input tensor data
catch "vtkPointLoad ptLoad"
    ptLoad SetLoadValue 100.0
    ptLoad SetSampleDimensions 20 20 20
    ptLoad ComputeEffectiveStressOn
    ptLoad SetModelBounds -10 10 -10 10 -10 10
set input [ptLoad GetOutput]

# this is needed so the streamControl object can
# check whether the streamline start points are inside
# the data.  Otherwise the data bounds aren't correct yet.
ptLoad Update

# Create the RenderWindow, Renderer and interactive renderer
#
catch "vtkRenderer ren1"
catch "vtkRenderWindow renWin"
    renWin AddRenderer ren1
catch "vtkRenderWindowInteractor iren"
    iren SetRenderWindow renWin



# Our class for managing streamlines
#-----------------------------------
catch "vtkMultipleStreamlineController streamControl"
#streamControl DebugOn

# Set input renderers for display
#-----------------------------------
catch "vtkCollection renderers"
renderers RemoveAllItems
renderers AddItem ren1
streamControl SetInputRenderers renderers

# Set type of streamlines to create
#-----------------------------------
set seedTracts [streamControl GetSeedTracts]
$seedTracts UseVtkHyperStreamlinePoints
catch "vtkHyperStreamlineDTMRI exampleObject"
exampleObject  IntegrateMinorEigenvector
exampleObject SetMaximumPropagationDistance 18.0
exampleObject SetIntegrationStepLength 0.1
exampleObject SetStepLength 0.01
exampleObject SetRadius 0.25
exampleObject SetNumberOfSides 18
# Less picky anisotropy and curvature settings than default.
# The defaults for brain will cut off these streamlines near the
# botttom of the cube.
exampleObject SetStoppingThreshold 0
exampleObject SetStoppingModeToLinearMeasure
exampleObject SetRadiusOfCurvature 10
# Give the $seedTracts this object to copy new ones from
$seedTracts SetVtkHyperStreamlinePointsSettings exampleObject


# Set the tensors as input to the streamline controller
#-----------------------------------
streamControl SetInputTensorField $input
[streamControl GetDisplayTracts] ScalarVisibilityOn

# Set seed points and display the result
#-----------------------------------
set count 1
set numberOfHyperStreamlines 1000

while { $count < $numberOfHyperStreamlines } {

    $seedTracts SeedStreamlineFromPoint 9 9 -9
    $seedTracts SeedStreamlineFromPoint -9 -9 -9
    $seedTracts SeedStreamlineFromPoint 9 -9 -9
    $seedTracts SeedStreamlineFromPoint -9 9 -9

    incr count
}

puts "Created $count hyperstreamlines."


# Display
#streamControl DebugOn
[streamControl GetDisplayTracts] AddStreamlinesToScene


puts "Now check memory use via top or similar program."
puts "You have 30 s. before execution resume"
after 30000 set timeout 1
vwait timeout

catch "vtkCamera camera"
    camera SetFocalPoint 0.113766 -1.13665 -1.01919
    camera SetPosition -29.4886 -63.1488 26.5807
    camera SetViewAngle 24.4617
    camera SetViewUp 0.17138 0.331163 0.927879
    camera SetClippingRange 1 100

ren1 SetBackground 1.0 1.0 1.0
ren1 SetActiveCamera camera

renWin SetSize 300 300
renWin Render
iren AddObserver UserEvent {wm deiconify .vtkInteract}

# prevent the tk window from showing up then start the event loop
wm withdraw .

puts [[[streamControl GetDisplayTracts] GetClippedStreamlines] Print]

# test deletion
streamControl DeleteStreamline \
    [[[streamControl GetDisplayTracts] GetActors] GetItemAsObject 2]

#streamControl DeleteStreamline 2

puts "Delete Streamlines"
streamControl DeleteAllStreamlines
 
