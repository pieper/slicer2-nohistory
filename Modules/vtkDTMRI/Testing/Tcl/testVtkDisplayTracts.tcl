# Imitate the Hyper.tcl script from VTK, but use our 
# vtkSeedTracts and vtkDisplyTracts classes

package require vtkDTMRI

# Create the RenderWindow, Renderer and interactive renderer
#
vtkRenderer ren1
vtkRenderWindow renWin
renWin AddRenderer ren1
vtkRenderWindowInteractor iren
iren SetRenderWindow renWin

#
# generate tensors
vtkPointLoad ptLoad
ptLoad SetLoadValue 100.0
ptLoad SetSampleDimensions 20 20 20
ptLoad ComputeEffectiveStressOn
ptLoad SetModelBounds -10 10 -10 10 -10 10
set input [ptLoad GetOutput]

#######################  Seed tracts  #############################
# Our class for managing streamlines
vtkSeedTracts seedTracts
seedTracts DebugOn

# Type of streamlines to create
seedTracts UseVtkHyperStreamlinePoints
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
# Give the seedTracts this object to copy new ones from
seedTracts SetVtkHyperStreamlinePointsSettings exampleObject

# Set the tensors as input to the streamline controller
seedTracts SetInputTensorField $input

# this is needed so the seedTracts object can
# check whether the streamline start points are inside
# the data.  Otherwise the data bounds aren't correct yet.
ptLoad Update

seedTracts SeedStreamlineFromPoint 9 9 -9
seedTracts SeedStreamlineFromPoint -9 -9 -9
seedTracts SeedStreamlineFromPoint 9 -9 -9
seedTracts SeedStreamlineFromPoint -9 9 -9

# Also test seeding from a region of interest
vtkImageData roi
roi SetDimensions 20 20 20
roi SetExtent 0 20 0 20 0 20
roi SetWholeExtent 0 20 0 20 0 20
roi SetScalarTypeToShort
roi AllocateScalars
roi Update

#tk_messageBox -message [roi Print]
set inValue 1
set outValue 0
foreach x {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19} {
    foreach y {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19} {
        foreach z {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19} {
             roi SetScalarComponentFromFloat $x $y $z 0 $outValue
        }
    }
}
roi SetScalarComponentFromFloat 4 4 4 0 $inValue

#tk_messageBox -message [[roi GetPointData] Print]

seedTracts SetInputROI roi
seedTracts SetInputROIValue $inValue
seedTracts SeedStreamlinesInROI
#######################  END Seed tracts  #############################


#######################  Display tracts  #############################
# Renderers
vtkCollection renderers
renderers AddItem ren1

# Our class for streamline display
vtkDisplayTracts displayTracts

displayTracts DebugOn

displayTracts SetStreamlines [seedTracts GetStreamlines]
displayTracts SetRenderers renderers
displayTracts AddStreamlinesToScene
displayTracts ScalarVisibilityOn
#######################  END Display tracts  #############################



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


# test deletion
displayTracts DeleteStreamline 2

displayTracts DeleteStreamline [[displayTracts GetActors] GetItemAsObject 2]

