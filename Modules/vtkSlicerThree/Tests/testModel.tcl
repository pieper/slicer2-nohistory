catch "sc Delete"
vtkMRMLScene sc

catch "mn Delete"
vtkMRMLModelNode mn

sc RegisterNodeClass mn
sc SetURL Modules/vtkSlicerThree/Tests/sceneModel.xml
sc Connect

puts "GetNumberOfNodesByClass [sc GetNumberOfNodesByClass vtkMRMLModelNode]"
puts "GetNodeClasses [sc GetNodeClasses]"
puts "GetNthNode"

set v0 [sc GetNthNode 0]
puts "Print node 0"
puts "[$v0 Print]"



