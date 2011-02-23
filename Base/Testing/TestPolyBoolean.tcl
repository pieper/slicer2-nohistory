package require vtk
package require vtkSlicerBase

catch "s1 Delete"
catch "s2 Delete"
catch "s3 Delete"

vtkSphereSource s1
vtkSphereSource s2
vtkSphereSource s3

catch "s1m Delete"
catch "s2m Delete"
catch "s3m Delete"

vtkPolyDataMapper s1m
vtkPolyDataMapper s2m
vtkPolyDataMapper s3m
s1m SetInput [s1 GetOutput]
s2m SetInput [s2 GetOutput]
s3m SetInput [s3 GetOutput]

catch "s1a Delete"
catch "s2a Delete"
catch "s3a Delete"

vtkActor s1a
vtkActor s2a
vtkActor s3a
s1a SetMapper s1m
s2a SetMapper s2m
s3a SetMapper s3m

vtkRenderer viewRen
catch "viewRen RemoveActor s1a"
catch "viewRen RemoveActor s2a"
catch "viewRen RemoveActor s3a"
viewRen AddActor s1a
viewRen AddActor s2a
viewRen AddActor s3a

s1a SetScale 75 75 75
s2a SetScale 75 75 75
s3a SetScale 75 75 75

s1a SetPosition 30 0 -50
s2a SetPosition -30 0 -50
s3a SetPosition 0 0 50


#Render3D

catch "pb Delete"
vtkPolyBoolean pb
pb SetOperation 0

pb SetInput [s1 GetOutput]
#pb Update
pb SetPolyDataB [s2 GetOutput]
pb Update
##pb UpdateCutter
#s3m SetInput [pb GetOutput]
#
#
