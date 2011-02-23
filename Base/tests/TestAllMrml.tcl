package require vtk
package require vtkSlicerBase

# This file tests creation of a MRML tree containing all node types

# Please add all nodes to the list (not vtkMrmlNode)
set nodeTypeList "vtkMrmlColorNode vtkMrmlCrossSectionNode vtkMrmlEndFiducialsNode vtkMrmlEndHierarchyNode vtkMrmlEndModelGroupNode vtkMrmlEndPathNode vtkMrmlEndScenesNode vtkMrmlEndTransformNode vtkMrmlEndVolumeStateNode vtkMrmlFiducialsNode vtkMrmlHierarchyNode vtkMrmlLandmarkNode vtkMrmlLocatorNode vtkMrmlMatrixNode vtkMrmlModelGroupNode vtkMrmlModelNode vtkMrmlModelRefNode vtkMrmlModelStateNode vtkMrmlOptionsNode vtkMrmlPathNode vtkMrmlPointNode vtkMrmlSceneOptionsNode vtkMrmlScenesNode vtkMrmlTetraMeshNode vtkMrmlTransformNode vtkMrmlVolumeNode vtkMrmlVolumeStateNode vtkMrmlWindowLevelNode"

# Create a tree with all nodes
vtkMrmlTree tree

foreach node $nodeTypeList {

    # unique name
    set name example$node
    puts $node
    # Create the node
    $node $name

    # Note the tree may not have proper syntax, this is just a test
    # Put item on the tree
    tree AddItem $name
}

# Now we can test individual things about the nodes
examplevtkMrmlVolumeNode SetDescription "hello!!!!!!!"


# Now write the file
set filename "test.xml"
tree Write $filename
puts "MRML file saved as $filename"
exit







