# Imitate the Hyper.tcl script from VTK, but use our 
# vtkMultiStreamlineController class
# Then run clustering.

package require vtkDTMRI

# Create the RenderWindow, Renderer and interactive renderer
#
vtkRenderer ren1
vtkRenderWindow renWin
    renWin AddRenderer ren1
vtkRenderWindowInteractor iren
    iren SetRenderWindow renWin


# Our class for managing streamlines
vtkMultipleStreamlineController streamControl
#streamControl DebugOn

# Renderers
vtkCollection renderers
renderers AddItem ren1
streamControl SetInputRenderers renderers

# Type of streamlines to create
[streamControl GetSeedTracts] UseVtkHyperStreamlinePoints
vtkHyperStreamlineDTMRI exampleObject
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
# Give the streamControl this object to copy new ones from
[streamControl GetSeedTracts] SetVtkHyperStreamlinePointsSettings exampleObject

#
# generate tensors
vtkPointLoad ptLoad
    ptLoad SetLoadValue 100.0
    ptLoad SetSampleDimensions 20 20 20
    ptLoad ComputeEffectiveStressOn
    ptLoad SetModelBounds -10 10 -10 10 -10 10
set input [ptLoad GetOutput]

# Set the tensors as input to the streamline controller
streamControl SetInputTensorField $input
[streamControl GetDisplayTracts] ScalarVisibilityOn

# this is needed so the streamControl object can
# check whether the streamline start points are inside
# the data.  Otherwise the data bounds aren't correct yet.
ptLoad Update


[streamControl GetSeedTracts] SeedStreamlineFromPoint 9 9 -9
[streamControl GetSeedTracts] SeedStreamlineFromPoint -9 -9 -9
[streamControl GetSeedTracts] SeedStreamlineFromPoint 9 -9 -9
[streamControl GetSeedTracts] SeedStreamlineFromPoint -9 9 -9
[streamControl GetSeedTracts] SeedStreamlineFromPoint 9 9 -9

[streamControl GetDisplayTracts] AddStreamlinesToScene


# plane for context
#
vtkImageDataGeometryFilter g
    g SetInput $input
    g SetExtent 0 100 0 100 0 0
    g Update;#for scalar range
vtkPolyDataMapper gm
    gm SetInput [g GetOutput]
    eval gm SetScalarRange [[g GetOutput] GetScalarRange]
vtkActor ga
    ga SetMapper gm

# Create outline around data
#
vtkOutlineFilter outline
    outline SetInput $input
vtkPolyDataMapper outlineMapper
    outlineMapper SetInput [outline GetOutput]
vtkActor outlineActor
    outlineActor SetMapper outlineMapper
    eval [outlineActor GetProperty] SetColor 0 0 0

# Create cone indicating application of load
#
vtkConeSource coneSrc
    coneSrc  SetRadius .5
    coneSrc  SetHeight 2
vtkPolyDataMapper coneMap
    coneMap SetInput [coneSrc GetOutput]
vtkActor coneActor
    coneActor SetMapper coneMap;    
    coneActor SetPosition 0 0 11
    coneActor RotateY 90
    eval [coneActor GetProperty] SetColor 1 0 0

vtkCamera camera
    camera SetFocalPoint 0.113766 -1.13665 -1.01919
    camera SetPosition -29.4886 -63.1488 26.5807
    camera SetViewAngle 24.4617
    camera SetViewUp 0.17138 0.331163 0.927879
    camera SetClippingRange 1 100

ren1 AddActor outlineActor
ren1 AddActor coneActor
ren1 AddActor ga
ren1 SetBackground 1.0 1.0 1.0
ren1 SetActiveCamera camera

renWin SetSize 300 300
renWin Render
iren AddObserver UserEvent {wm deiconify .vtkInteract}

# prevent the tk window from showing up then start the event loop
wm withdraw .


# Now test the clustering
set clusterer [streamControl GetTractClusterer]
set features [$clusterer GetTractAffinityCalculator]
#$features DebugOn

$clusterer SetNumberOfClusters 3
$clusterer SetNumberOfEigenvectors 1
#$clusterer DebugOn

puts "Testing endpoint clustering"
$features SetFeatureTypeToEndPoints
streamControl ClusterTracts 1
renWin Render

puts "Testing mean/cov clustering"
set clusterer [streamControl GetTractClusterer]
set features [$clusterer GetTractAffinityCalculator]
$features SetFeatureTypeToMeanAndCovariance
streamControl ClusterTracts 1
renWin Render

puts "Testing Hausdorff clustering"
set clusterer [streamControl GetTractClusterer]
set features [$clusterer GetTractAffinityCalculator]
$features SetFeatureTypeToHausdorff
streamControl ClusterTracts 1
renWin Render


# test with another streamline added
puts "Adding more streamlines, re-clustering"
#streamControl DebugOn
[streamControl GetSeedTracts] SeedStreamlineFromPoint 9 9 -9
[streamControl GetSeedTracts] SeedStreamlineFromPoint -9 9 -9
[streamControl GetSeedTracts] SeedStreamlineFromPoint -9 9 -9
[streamControl GetDisplayTracts] RemoveStreamlinesFromScene
[streamControl GetDisplayTracts] AddStreamlinesToScene
renWin Render
set clusterer [streamControl GetTractClusterer]
$clusterer SetNumberOfEigenvectors 2

streamControl ClusterTracts 1
renWin Render



