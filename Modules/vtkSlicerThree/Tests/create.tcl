vtkMRMLScene sc
vtkMRMLVolumeNode vn
sc RegisterNodeClass vn
sc SetURL Modules/vtkSlicerThree/Tests/scene1.xml
sc Connect
puts "GetNumberOfNodesByClass"
sc GetNumberOfNodesByClass vtkMRMLVolumeNode
puts "GetNodeClasses"
sc GetNodeClasses
puts "GetNthNode"
sc GetNthNode 0
set vn [sc GetNthNode 0]
puts "Print volume node"
$vn Print
