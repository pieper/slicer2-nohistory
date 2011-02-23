

vtkFSSurfaceReader sr
sr SetFileName c:/pieper/bwh/data/uci-picker15-sp/surf/rh.pial
sr Update
vtkPolyDataMapper pmap
pmap SetInput [sr GetOutput]
vtkActor a
a SetMapper pmap
viewRen AddActor a
Render3D


vtkFloatArray fa
vtkFSSurfaceScalarReader ssr
ssr SetFileName c:/pieper/bwh/data/uci-picker15-sp/surf/rh.thickness
ssr SetOutput fa
ssr ReadFSScalars
fa Print

[[ssr GetOutput] GetPointData] SetScalars fa
