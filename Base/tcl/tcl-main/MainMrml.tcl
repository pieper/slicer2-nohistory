#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainMrml.tcl,v $
#   Date:      $Date: 2006/07/27 18:21:39 $
#   Version:   $Revision: 1.116 $
# 
#===============================================================================
# FILE:        MainMrml.tcl
# PROCEDURES:  
#   MainMrmlInit
#   MainMrmlInitIdLists
#   MainMrmlUpdateIdLists nodeTypeList
#   MainMrmlAppendnodeTypeList  MRMLnodeTypeList
#   MainMrmlUpdateMRML
#   MainMrmlDumpTree type
#   MainMrmlPrint tags
#   MainMrmlClearList
#   MainMrmlAddNode nodeType globalArray
#   MainMrmlInsertBeforeNode nodeBefore nodeType
#   MainMrmlInsertAfterNode nodeBefore nodeType
#   MainMrmlUndoAddNode nodeType n
#   MainMrmlDeleteNodeDuringUpdate nodeType id
#   MainMrmlDeleteNode nodeType id
#   MainMrmlDeleteNodeNoUpdate nodeType id
#   MainMrmlDeleteAll
#   MainMrmlSetFile filename
#   MainMrmlRead mrmlFile
#   MainMrmlImport  filename
#   MainMrmlBuildTreesVersion2.0 tags
#   MainMrmlReadVersion1.0 filename
#   MainMrmlBuildTreesVersion1.0
#   MainMrmlDeleteColors
#   MainMrmlAddColorsFromFile fileName
#   MainMrmlAddColors tags
#   MainMrmlCheckColors
#   MainMrmlRelativity oldRoot
#   MainMrmlWrite filename
#   MainMrmlWriteProceed filename
#   MainMrmlCheckVolumes filename
#   MainMrmlAbsolutivity
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC MainMrmlInit
# Set global variables for this module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlInit {} {
    global Mrml

    # List of all types of MRML nodes understood by slicer
    set Mrml(nodeTypeList) "Model Volume Color Transform \
        EndTransform Matrix TransferFunction WindowLevel \
        TFPoint ColorLUT Options Fiducials EndFiducials \
        Point Path EndPath Landmark \
        Hierarchy EndHierarchy ModelGroup EndModelGroup ModelRef \
        Scenes EndScenes VolumeState EndVolumeState CrossSection SceneOptions ModelState \
        Locator TetraMesh Tensor"
 
    MainMrmlInitIdLists

    # Read MRML defaults file for version 1.0
    set fileName [ExpandPath "Defaults.mrml"]
    if {[CheckFileExists $fileName] == "0"} {
        set msg "Unable to read file MRML defaults file '$fileName'"
        puts $msg
        tk_messageBox -message $msg
        exit    
    }
    MRMLReadDefaults $fileName

    # Set version info
    lappend Module(versions) [ParseCVSInfo MainMrml \
    {$Revision: 1.116 $} {$Date: 2006/07/27 18:21:39 $}]

    set Mrml(colorsUnsaved) 0
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlInitIdLists
# 
# Init the Id list for each data type
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlInitIdLists {} {
    global Mrml Volume
    MainMrmlUpdateIdLists "$Mrml(nodeTypeList)"
    # Volumes are a special case because the "None" always exists    
    set Volume(idList) 0
    set Volume(nextID) 1
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlUpdateIdLists
# 
# Updates the Id list for each data type
#
# .ARGS
# list nodeTypeList the list of nodes for this type
# .END
#-------------------------------------------------------------------------------
proc MainMrmlUpdateIdLists {nodeTypeList} {
    global Mrml 
    eval {global} $nodeTypeList
     
    foreach node $nodeTypeList {
        set ${node}(nextID) 0
        set ${node}(idList) ""
        set ${node}(idListDelete) ""
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlAppendnodeTypeList 
#  Call this function in your init function if your module addds new nodes 
#  to the Mrml Tree. Makes sure that no duplicates are added.
#  Example: vtkEMLocalSegment/tcl/EMLocalSegment 
# .ARGS
# list MRMLnodeTypeList new type list
# .END
#-------------------------------------------------------------------------------
proc MainMrmlAppendnodeTypeList {MRMLnodeTypeList} {
    global Mrml

    foreach node $MRMLnodeTypeList {
        if {[lsearch $Mrml(nodeTypeList) $node] == -1} {
            set Mrml(nodeTypeList) "$Mrml(nodeTypeList) $node"
        } else {
            if {$::Module(verbose)} {
                puts "MainMrmlAppendnodeTypeList: Found $node in the list, skipping"
            }
        }
    }

    MainMrmlUpdateIdLists "$MRMLnodeTypeList"
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlUpdateMRML
# Compute transforms for every node in the mrml data tree.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlUpdateMRML {} {
    global Mrml

    # Compute geometric relationships
    if {[info command Mrml(dataTree)] != ""} {
        Mrml(dataTree) ComputeTransforms
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlDumpTree
# Print out all the nodes in the tree (not their contents)
# .ARGS
# string type which tree to dump 
# .END
#-------------------------------------------------------------------------------
proc MainMrmlDumpTree {type} {
    global Mrml

    set tree Mrml(${type}Tree)
    $tree InitTraversal
    set node [$tree GetNextItem]
    while {$node != ""} {
        puts "dump='$node'"
        set node [$tree GetNextItem]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlPrint
# Print out the contents of the mrml tree.
# .ARGS
# list tags the pairs that make up the mrml tree information
# .END
#-------------------------------------------------------------------------------
proc MainMrmlPrint {tags} {

    set level 0
    foreach pair $tags {
        set tag  [lindex $pair 0]
        set attr [lreplace $pair 0 0]

        # Process EndTransform & EndFiducials & EndPath & EndModelGroup & EndHierarchy
        if {$tag == "EndTransform" || $tag == "EndFiducials" || $tag == "EndPath" || $tag == "EndModelGroup" || $tag == "EndHierarchy" || $tag == "EndSegmenter" || $tag == "EndSegmenterSuperClass" | $tag == "EndSegmenterClass" } {
            set level [expr $level - 1]
        }
        set indent ""
        for {set i 0} {$i < $level} {incr i} {
            set indent "$indent  "
        }

        puts "${indent}$tag"

        # Process Transform & Fiducials & Path & ModelGroup & Hierarchy
        if {$tag == "Transform" || $tag == "Fiducials" || $tag == "Path" || $tag == "ModelGroup" || $tag == "Hierarchy" || $tag == "Segmenter" || $tag == "SegmenterSuperClass" || $tag == "SegmenterClass"} {
            incr level
        }
        set indent ""
        for {set i 0} {$i < $level} {incr i} {
            set indent "$indent  "
        }

        foreach a $attr {
            set key   [lindex $a 0]
            set value [lreplace $a 0 0]
            puts "${indent}  $key=$value"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlClearList
# 
# Delete the entries in the list of Ids to delete for the data type in Mrml(nodeTypeList)
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlClearList {} {
    global Mrml 
    eval {global} $Mrml(nodeTypeList)
    
    foreach node $Mrml(nodeTypeList) {
        set ${node}(idListDelete) ""
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlAddNode
#
#  Adds a node to the data tree.
#  Returns the MrmlMode
# 
# .ARGS
# str nodeType the type of node, \"Volume\", \"Color\", etc.
# list globalArray defaults to empty list, optional, if empty is set to node type and upvar'd
# .END
#-------------------------------------------------------------------------------
proc MainMrmlAddNode {nodeType  {globalArray ""}} {
    global Mrml

    if {$globalArray == ""} {
        set globalArray $nodeType
    }

    # the #0 puts the array in global scope
    upvar #0 $globalArray Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    # Add ID to idList
    set i $Array(nextID)
    incr Array(nextID)
    lappend Array(idList) $i

    # Put the None volume at the end
    if {$globalArray == "Volume"} {
        set j [lsearch $Array(idList) $Array(idNone)]
        set Array(idList) "[lreplace $Array(idList) $j $j] $Array(idNone)"
    }

    
    # Create vtkMrmlNode
    set n ${globalArray}($i,node)
    vtkMrml${nodeType}Node $n
    $n SetID $i

    # if it's a Fiducial, create the selected point id list?
    if {$globalArray == "Fiducials"} {
        if {$::Module(verbose)} {
            puts "Does a selected point id list exist yet for list $i? [info exist ::Fiducials($i,selectedPointIdList)] (if 0, creating it)"
        }
        if {[info exist ::Fiducials($i,selectedPointIdList)] == 0} {
            set ::Fiducials($i,selectedPointIdList) ""
        }
    }

    # Add node to tree
    Mrml($tree) AddItem $n

    # Return node
    return ${globalArray}($i,node)
}


#-------------------------------------------------------------------------------
# .PROC MainMrmlInsertBeforeNode
#
#  Adds a node to the data tree right after NodeBefore.
#  Returns the MrmlMode
# 
# .ARGS
# str nodeBefore the node to insert after
# str nodeType the type of node, \"Volume\", \"Color\", etc.
# .END
#-------------------------------------------------------------------------------
proc MainMrmlInsertBeforeNode {nodeBefore nodeType} {
    global Mrml

    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    # Add ID to idList
    set i $Array(nextID)
    incr Array(nextID)
    lappend Array(idList) $i

    # Put the None volume at the end
    if {$nodeType == "Volume"} {
        set j [lsearch $Array(idList) $Array(idNone)]
        set Array(idList) "[lreplace $Array(idList) $j $j] $Array(idNone)"
    }

    # Create vtkMrmlNode
    set n ${nodeType}($i,node)

    vtkMrml${nodeType}Node $n
    $n SetID $i

    # Add node to tree
    Mrml($tree) InsertBeforeItem $nodeBefore $n

    # Return node
    return ${nodeType}($i,node)
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlInsertAfterNode
#
#  Adds a node to the data tree right after NodeBefore.
#  Returns the MrmlNode
# 
# .ARGS
# str nodeBefore the node to insert after
# str nodeType the type of node, \"Volume\", \"Color\", etc.
# .END
#-------------------------------------------------------------------------------
proc MainMrmlInsertAfterNode {nodeBefore nodeType} {
    global Mrml

    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    # Add ID to idList
    set i $Array(nextID)
    incr Array(nextID)
    lappend Array(idList) $i

    # Put the None volume at the end
    if {$nodeType == "Volume"} {
        set j [lsearch $Volume(idList) $Volume(idNone)]
        set Volume(idList) "[lreplace $Volume(idList) $j $j] $Volume(idNone)"
    }

    # Create vtkMrmlNode
    set n ${nodeType}($i,node)

    vtkMrml${nodeType}Node $n
    $n SetID $i

    # Add node to tree
    Mrml($tree) InsertAfterItem $nodeBefore $n

    # Return node
    return ${nodeType}($i,node)
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlUndoAddNode
# 
# Use this routine to remove a node that was accidentally added.
#
# Don't call this routine to delete a node, it should only
# happen if adding one fails (i.e reading a volume from disk fails).
#
# .ARGS
# string nodeType the type of node, \"Volume\", \"Color\", etc.
# int n the node to undo the add of
# .END
#-------------------------------------------------------------------------------
proc MainMrmlUndoAddNode {nodeType n} {
    global Mrml

    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    # Remove node's ID from idList
    set id [$n GetID]
    set i [lsearch $Array(idList) $id]
    if {$i == -1} {return}
    set Array(idList) [lreplace $Array(idList) $i $i]
    set Array(nextID) [expr $Array(nextID) - 1]

    # Remove node from tree, and delete it
    Mrml($tree) RemoveItem $n
    $n Delete
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlDeleteNodeDuringUpdate
# Call this routine to delete a node during MainUpdateMRML
# .ARGS
# string nodeType the type of node, \"Volume\", \"Color\", etc.
# int id the node id 
# .END
#-------------------------------------------------------------------------------
proc MainMrmlDeleteNodeDuringUpdate {nodeType id} {
    global Mrml

    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    lappend Array(idListDelete) $id

    # Remove node's ID from idList
    set i [lsearch $Array(idList) $id]
    if {$i == -1} {return}
    set Array(idList) [lreplace $Array(idList) $i $i]

    # Remove node from tree, and delete it
    Mrml($tree) RemoveItem ${nodeType}($id,node)
    ${nodeType}($id,node) Delete
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlDeleteNode
# Call this routine to delete a node.
# .ARGS
# string nodeType the type of node, \"Volume\", \"Color\", etc.
# int id the node id 
# .END
#-------------------------------------------------------------------------------
proc MainMrmlDeleteNode {nodeType id} {
    global Mrml 
    
    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    MainMrmlClearList
    set Array(idListDelete) $id

    # Remove node's ID from idList
    set i [lsearch $Array(idList) $id]
    if {$i == -1} {return}
    set Array(idList) [lreplace $Array(idList) $i $i]

    # Remove node from tree, and delete it
    Mrml($tree) RemoveItem ${nodeType}($id,node)
    ${nodeType}($id,node) Delete

    MainUpdateMRML

    MainMrmlClearList
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlDeleteNodeNoUpdate
#  Same as MainMrmlDeleteNode, but does not call UpdateMRML 
# .ARGS
# string nodeType the type of node, \"Volume\", \"Color\", etc.
# int id the node id 
# .END
#-------------------------------------------------------------------------------
proc MainMrmlDeleteNodeNoUpdate {nodeType id} {
    global Mrml 
    
    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    set tree "dataTree"
    if {$nodeType == "Color"} {
        set tree "colorTree"
    }

    MainMrmlClearList
    set Array(idListDelete) $id

    # Remove node's ID from idList
    set i [lsearch $Array(idList) $id]
    if {$i == -1} {return}
    set Array(idList) [lreplace $Array(idList) $i $i]

    # Remove node from tree, and delete it
    Mrml($tree) RemoveItem ${nodeType}($id,node)
    ${nodeType}($id,node) Delete

    MainMrmlClearList
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlDeleteAll
# 
#  Delete all volumes, models and transforms.
#
# .END
#-------------------------------------------------------------------------------
proc MainMrmlDeleteAll {} {
    global Mrml 
    eval {global} $Mrml(nodeTypeList)    

    # Volumes are a special case because the "None" always exists
    foreach id $Volume(idList) {
        if {$id != $Volume(idNone)} {

            # Add to the deleteList
            lappend Volume(idListDelete) $id

            # Remove from the idList
            set i [lsearch $Volume(idList) $id]
            set Volume(idList) [lreplace $Volume(idList) $i $i]

            # Remove node from tree, and delete it
            Mrml(dataTree) RemoveItem Volume($id,node)
            Volume($id,node) Delete
        }
    }

    # dataTree
    foreach node $Mrml(nodeTypeList) {
        if {$node != "Volume" && $node != "Color"} {
            upvar #0 $node Array
            
            foreach id $Array(idList) {

                # Add to the deleteList
                lappend Array(idListDelete) $id

                # Remove from the idList
                set i [lsearch $Array(idList) $id]
                set Array(idList) [lreplace $Array(idList) $i $i]

                # Remove node from tree, and delete it
                Mrml(dataTree) RemoveItem ${node}($id,node)
                ${node}($id,node) Delete

            }
        }
    }

    # colorTree
    foreach node "Color" {
        upvar #0 $node Array

        foreach id $Array(idList) {

            # Add to the deleteList
            lappend Array(idListDelete) $id

            # Remove from the idList
            set i [lsearch $Array(idList) $id]
            set Array(idList) [lreplace $Array(idList) $i $i]

            # Remove node from tree, and delete it
            Mrml(colorTree) RemoveItem ${node}($id,node)
            ${node}($id,node) Delete
        }
    }

    MainUpdateMRML

    MainMrmlClearList

    MainMrmlInitIdLists
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlSetFile
# Store the directory of the MRML file as the Mrml(dir) and store the new
# relative prefix.
# .ARGS
# path filename the name of the mrml file
# .END
#-------------------------------------------------------------------------------
proc MainMrmlSetFile {filename} {
    global Mrml File

    # Store the directory of the MRML file as the Mrml(dir)
    set dir [file dirname $filename]
    if {$dir == "" || $dir == "."} {
        set dir [pwd]
    }
    set Mrml(dir) $dir

    # Store the new relative prefix
    set File(filePrefix) [MainFileGetRelativePrefix $filename]

}

#-------------------------------------------------------------------------------
# .PROC MainMrmlRead
#
#  Delete the loaded Mrml data from memory.  Replace with a new Mrml file.
#  Append \".xml\" or \".mrml\" an necessary to the file name as necessary.
# .ARGS
# str mrmlFile name of a MRML file to load
# .END
#-------------------------------------------------------------------------------
proc MainMrmlRead {mrmlFile} {
    global Path Mrml Volume

    # Open the file 'mrmlFile' to determine which MRML version it is,
    # and then call the appropriate routine to handle it.

    # Determine name of MRML input file.
    # Append ".mrml" or ".xml" if necessary.
    set fileName $mrmlFile
    if {[file extension $fileName] != ".mrml" && [file extension $fileName] != ".xml"} {
        if {[file exists $fileName.xml] == 1} {
            set fileName $fileName.xml
        } elseif {[file exists $fileName.mrml] == 1} {
            set fileName "$fileName.mrml"
        }
    }

    # Build a MRML Tree for data, and another for colors and LUTs
    if {[info command Mrml(dataTree)] == ""} {
        vtkMrmlTree Mrml(dataTree)
    }
    if {[info command Mrml(colorTree)] == ""} {
        vtkMrmlTree Mrml(colorTree)
    }

    # Check the file exists
    if {$fileName != "" && [CheckFileExists $fileName 0] == "0"} {
        set errmsg "Unable to read input MRML file '$fileName'"
        puts $errmsg
        tk_messageBox -message $errmsg

        # At least read colors
        set tags [MainMrmlAddColors ""]
        MainMrmlBuildTreesVersion2.0 $tags
        return    
    }

    # no file?
    if {$fileName == ""} {
        # At least read colors
        set tags [MainMrmlAddColors ""]
        MainMrmlBuildTreesVersion2.0 $tags
        return    
    }

    MainMrmlDeleteAll

    # Store file and directory name
    MainMrmlSetFile $fileName

    # Colors don't need saving now
    set Mrml(colorsUnsaved) 0

    # Open the file to determine its type
    set version 2
    if {$fileName == ""} {
        set version 1
    } else {
        set fid [open $fileName r]
        gets $fid line
         close $fid
        if {[lindex $line 0] == "MRML"} {
            set version 1
        }
    }
    if {$version == 1} {
        puts "Reading MRML V1.0: $fileName"
        MainMrmlReadVersion1.0 $fileName
        MainMrmlBuildTreesVersion1.0

        # Always add Colors.xml
        set tags [MainMrmlAddColors ""]
        MainMrmlBuildTreesVersion2.0 $tags
    } else {
        puts "Reading MRML V2.0: $fileName"
        set tags [MainMrmlReadVersion2.x $fileName]

        # Only add colors if none exist
        set tags [MainMrmlAddColors $tags]

        MainMrmlBuildTreesVersion2.0 $tags
    }    

    # Put the None volume at the end
    set i [lsearch $Volume(idList) $Volume(idNone)]
    set Volume(idList) "[lreplace $Volume(idList) $i $i] $Volume(idNone)"

    # if there were scene options in the file, set one to be active now
    set sceneOptions [vtkMrmlSceneOptionsNode ListInstances]
    if {$::Module(verbose)} {
        if {$sceneOptions != ""} {
            puts "MainMrmlRead: found [llength $sceneOptions] scene options: $sceneOptions"
            
        } else {
            puts "MainMrmlRead: no scenes in mrml file"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlImport 
# Bring nodes from a mrml file into the current tree
# .ARGS 
# path filename the mrml file to import
# .END
#-------------------------------------------------------------------------------
proc MainMrmlImport {filename} {
    global Mrml

    set tags [MainMrmlReadVersion2.0 $filename]

    set outtags ""
    foreach pair $tags {
        set tag  [lindex $pair 0]
        set attr [lreplace $pair 0 0]
        if {$::Module(verbose)} { 
            puts "MainMrlmImport: attr = $attr"
        }
        set outattr ""

        switch $tag {
            "Volume" {
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    if {$::Module(verbose)} {
                        puts "\tkey = $key\n\tval = $val"
                    }
                    switch [string tolower $key] {
                        "fileprefix"      {
                            set mrmlpath [file split $Mrml(dir)]
                            set filepath [lrange [file split [file dir $filename]] 1 end]
                            set dots ""
                            for {set dotscount 0} {$dotscount < [expr [llength $mrmlpath] - 1]} {incr dotscount} {
                                lappend dots ".."
                            }
                            # set prefixlist [file split $val]
                            # when the tags are read in, the file prefix (val) is set wrong, just use the filename
                            # lappend outattr [list $key [eval file join $dots $filepath $prefixlist]]
                            lappend outattr [list $key [eval file join $dots $filepath $val]]
                            if {$::Module(verbose)} {
                                puts "\tsetting file prefix: Mrml(dir) = $Mrml(dir), filename = $filename, fileprefix = [eval file join $dots $filepath $val]"
                            }
                        }
                        "options" {
                            # do nothing
                        }
                        default {
                            lappend outattr [eval list $key $val]
                        }
                    }
                }
            }
            default {
            # TODO - fix paths on different Node types (Models, etc)
                lappend outattr $attr
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    if {$::Module(verbose)} {
                        puts "\tkey = $key\n\tval = $val"
                    }
                    switch [string tolower $key] {
                        "options" {
                            # do nothing
                        }
                        default {
                            lappend outattr [eval list $key $val]
                        }
                    }
                }
            }
        }
        MainMrmlBuildTreesVersion2.0 [list [eval list $tag $outattr]]
        MainUpdateMRML
    }
}


#-------------------------------------------------------------------------------
# .PROC MainMrmlBuildTreesVersion2.0
# Build a mrml tree by adding nodes of the correct types, and filling in information
# from the tags
# .ARGS
# list tags the pairs of tags to build the tree from
# .END
#-------------------------------------------------------------------------------
proc MainMrmlBuildTreesVersion2.0 {tags} {
    global Mrml 
    eval {global} $Mrml(nodeTypeList)

    set sceneName ""

    if {$::Module(verbose)} { 
        puts "\n\n*********\nMainMrmlBuildTreesVersion2.0 tags = $tags\n*************\n\n"
    }
    foreach pair $tags {
        set tag  [lindex $pair 0]
        set attr [lreplace $pair 0 0]
        switch $tag {
            
            "Transform" {
                set n [MainMrmlAddNode Transform]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "desc"   {$n SetDescription $val}
                        "name"   {$n SetName        $val}
                    }
                }
            }
            
            "EndTransform" {
                set n [MainMrmlAddNode EndTransform]
            }
            
            "Matrix" {
                set n [MainMrmlAddNode Matrix]
                # special trick to avoid vtk 4.2 legacy hack message 
                # (adds a concatenated identity transform to the transform)
                if { [info commands __dummy_transform] == "" } {
                    vtkTransform __dummy_transform
                }
                [$n GetTransform] SetInput __dummy_transform
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "desc"   {$n SetDescription $val}
                        "name"   {$n SetName        $val}
                        "matrix" {eval [$n GetTransform] SetMatrix $val}
                    }
                }
            }

            "Color" {
                set n [MainMrmlAddNode Color]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "desc"         {$n SetDescription  $val}
                        "name"         {$n SetName         $val}
                        "ambient"      {$n SetAmbient      $val}
                        "diffuse"      {$n SetDiffuse      $val}
                        "specular"     {$n SetSpecular     $val}
                        "power"        {$n SetPower        $val}
                        "labels"       {$n SetLabels       $val}
                        "diffusecolor" {eval $n SetDiffuseColor $val}
                    }
                }
            }
            
            "Model" {
                set n [MainMrmlAddNode Model]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "id"               {$n SetModelID      $val}
                        "desc"             {$n SetDescription  $val}
                        "name"             {$n SetName         $val}
                        "filename"         {$n SetFileName     $val}
                        "color"            {$n SetColor        $val}
                        "opacity"          {$n SetOpacity      $val}
                        "scalarrange"      {eval $n SetScalarRange $val}
                        "visibility" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetVisibility 1
                            } else {
                                $n SetVisibility 0
                            }
                        }
                        "clipping" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetClipping 1
                            } else {
                                $n SetClipping 0
                            }
                        }
                        "backfaceculling" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetBackfaceCulling 1
                            } else {
                                $n SetBackfaceCulling 0
                            }
                        }
                        "scalarvisibility" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetScalarVisibility 1
                            } else {
                                $n SetScalarVisibility 0
                            }
                        }
                        "scalarfiles" {
                            if {$::Module(verbose)} {
                                puts "MainMrmlBuildTreesVersion2.0: dealing with the list of scalar files:"
                                puts $val
                            }
                            set filelist {}
                            eval {lappend filelist} $val
                            foreach file $filelist {
                                # deal with relative paths...
                                set fname $file
                                if {$::Module(verbose)} { 
                                    puts "checking $fname"
                                }
                                if {[file exists $fname] == 0} {
                                    DevErrorWindow "Scalar file $fname does not exist"
                                } else {
                                    # add it
                                    $n AddScalarFileName $fname
                                }
                            }
                        }
                    }
                }

                # Compute full path name relative to the MRML file
                $n SetFullFileName [file join $Mrml(dir) [$n GetFileName]]
                if {$::Module(verbose)} { 
                    puts "MainMrmlBuildTreesVersion2.0: Model FullFileName set to [$n GetFullFileName], from mrml dir ($Mrml(dir)) and file name ([$n GetFileName])"
                }
                # Generate model ID if necessary
               if {[$n GetModelID] == ""} {
                   $n SetModelID "M[$n GetID]"
               }
            }
            
            "Volume" {
                if {$::Module(verbose)} {
                    puts "Volume:"
                    puts "attr: $attr"
                }
                set n [MainMrmlAddNode Volume]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    if {$::Module(verbose)} {
                        puts "attr = $a"
                        puts "\tkey = $key\n\tval = $val"
                    }
                    switch [string tolower $key] {
                        "id"              {$n SetVolumeID       $val}
                        "desc"            {$n SetDescription    $val}
                        "name"            {$n SetName           $val}
                        "filetype"        {$n SetFileType       $val}
                        "filepattern"     {$n SetFilePattern    $val}
                        "fileprefix"      {$n SetFilePrefix     $val}
                        "imagerange"      {eval $n SetImageRange $val}
                        "spacing"         {eval $n SetSpacing   $val}
                        "dimensions"      {eval $n SetDimensions $val}
                        "scalartype"      {$n SetScalarTypeTo$val}
                        "numscalars"      {$n SetNumScalars     $val}
                        "rastoijkmatrix"  {$n SetRasToIjkMatrix $val}
                        "rastovtkmatrix"  {$n SetRasToVtkMatrix $val}
                        "positionmatrix"  {$n SetPositionMatrix $val}
                        "scanorder"       {$n SetScanOrder $val}
                        "colorlut"        {$n SetLUTName        $val}
                        "window"          {$n SetWindow         $val}
                        "level"           {$n SetLevel          $val}
                        "lowerthreshold"  {$n SetLowerThreshold $val}
                        "upperthreshold"  {$n SetUpperThreshold $val}
                        "autowindowlevel" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetAutoWindowLevel 1
                            } else {
                                $n SetAutoWindowLevel 0
                            }
                        }
                        "autothreshold" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetAutoThreshold 1
                            } else {
                                $n SetAutoThreshold 0
                            }
                        }
                        "applythreshold" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetApplyThreshold 1
                            } else {
                                $n SetApplyThreshold 0
                            }
                        }
                        "interpolate" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetInterpolate 1
                            } else {
                                $n SetInterpolate 0
                            }
                        }
                        "labelmap" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetLabelMap 1
                            } else {
                                $n SetLabelMap 0
                            }
                        }
                        "littleendian" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetLittleEndian 1
                            } else {
                                $n SetLittleEndian 0
                            }
                        }
                        "dicomfilenamelist" {
                            set filelist {}
                            eval {lappend filelist} $val
                            foreach file $filelist {
                                set DICOMName [file join $Mrml(dir) $file]
                                if {$::Module(verbose) } {
                                    puts "MainMrmlBuildTreesVersion2.0: Added mrml dir to file $file, dicomname = $DICOMName (prefix = [$n GetFilePrefix])"
                                }
                                if {[file exists $DICOMName] == 0} {
                                    set DICOMName [file join [$n GetFilePrefix] $file]
                                    if {$::Module(verbose) } {
                                        puts "MainMrmlBuildTreesVersion2.0: Reset dicomname to $DICOMName, because first try didn't exist: [file join $Mrml(dir) $file]"
                                    }
                                }
                                $n AddDICOMFileName $DICOMName
                            }
                        }
                        "dicommultiframeoffsetlist" {
                            set offsetlist {}
                            eval {lappend offsetlist} $val
                            foreach offset $offsetlist {
                                $n AddDICOMMultiFrameOffset $offset
                            }
                        }
                        "frequencyphaseswap" {
                            # added by odonnell for DTI data: will move 
                            # to submodule of Volumes.tcl
                            if {$val == "yes" || $val == "true"} {
                                $n SetFrequencyPhaseSwap 1
                            }
                        }
                    }
                }

                # Compute full path name relative to the MRML file
                $n SetFullPrefix [file join $Mrml(dir) [$n GetFilePrefix]]
                # if it's an absolute path, it may have ..'s in it, so normalize it
                if {([file pathtype [$n GetFullPrefix]] == "absolute") 
                        && ([string first ".." [$n GetFullPrefix]] != -1)} {
                    $n SetFullPrefix [file normalize [$n GetFullPrefix]]
                    if  {$::Module(verbose)} { 
                        puts "MainMrmlBuildTreesVersion2.0: Volume [$n GetVolumeID] normalised full prefix: [$n GetFullPrefix]"
                    }
                }
                # Set volume ID if necessary
                if {[$n GetVolumeID] == ""} {
                    $n SetVolumeID "V[$n GetID]"
                }

                if {$::Module(verbose)} { 
                    puts "MainMrmlBuildTreesVersion2.0: Volume [$n GetVolumeID] FullPrefix set to [$n GetFullPrefix]" 
                }
                # Compute the absolute directory that the volume lives in
                # puts "MainMrmlBuildTreesVersion2.0: [file dirname [$n GetFullPrefix]]"
                # set Volume([$n GetVolumeID],absDir) [file dirname [$n GetFullPrefix]]
                # puts "Set Volume([$n GetVolumeID],absDir) to $Volume([$n GetVolumeID],absDir)"

                $n UseRasToVtkMatrixOn
            }

            "TetraMesh" {
                MainTetraMeshProcessMrml "$attr"
            }

            "Options" {
                # Legacy: options shouldn't be stored in an options tag,
                # use the fancy XML tags instead

                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "options"      {set options $val}
                        "program"      {set program $val}
                        "contents"     {set contents $val}
                    }
                }
                # I don't want any of gimpy's stinkin' modules in my tree!
                if {$contents != "modules"} {
                    set n [MainMrmlAddNode Options]
                    $n SetOptions $options
                    $n SetProgram $program
                    $n SetContents $contents
                }

                # Check that this is a slicer options node.
                if {[$n GetProgram] != "slicer"} {
                    return
                }

                # If these are presets, then do preset stuff on stuffing, not attr
                if {[$n GetContents] == "presets"} {
                    # Since presets aren't written to the MRML file when different
                    # from their default values, I must first reset them to their defaults.
                    MainOptionsUseDefaultPresets
                    MainOptionsParsePresets $attr
                }
            }

            "Fiducials" {
                set n [MainMrmlAddNode Fiducials]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "description"             {$n SetDescription  $val}
                        "name"             {
                            # check to make sure there are no spaces in the name
                            if {[string first " " $val] != -1} {
                                if {$::Module(verbose)} {
                                    puts "MainMrmlBuildTreesVersion2.0: changing spaces to underscores in Fiducial name $val"
                                }
                                $n SetName [regsub -all " " $val "_"]
                            } else {
                                $n SetName         $val
                            }
                        }
                        "type"              {eval $n SetType     $val}
                        "visibility"        {eval $n SetVisibility $val}
                        "symbolsize"         {eval $n SetSymbolSize    $val}
                        "textsize"         {eval $n SetTextSize    $val}
                        "color"            {eval $n SetColor     $val}
                    }
                }
            }
            "EndFiducials" {
                set n [MainMrmlAddNode EndFiducials]
            }
            "Point" {
                set n [MainMrmlAddNode Point]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "description"             {$n SetDescription  $val}
                        "name"             {
                            if {[string first " " $val] != -1} {
                                if {$::Module(verbose)} {
                                    puts "MainMrmlBuildTreesVersion2.0: changing spaces to underscores in Point name $val"
                                }
                                $n SetName [regsub -all " " $val "_"]
                            } else {
                                $n SetName         $val
                            }
                        }
                        "index"            {eval $n SetIndex        $val}
                        "xyz"              {eval $n SetXYZ     $val}
                        "focalxyz"         {eval $n SetFXYZ     $val}
                        "orientationwxyz"  {eval $n SetOrientationWXYZ     $val}
                    }

                }
            }
            ####### The next 3 nodes are only here for backward compatibility
            ####### Endoscopic paths are now defined with Fiducials/Point nodes
            "Path" {
                set n [MainMrmlAddNode Path]
            }
            
            "EndPath" {
                set n [MainMrmlAddNode EndPath]
            }
            "Landmark" {
                set n [MainMrmlAddNode Landmark]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        
                        "desc"             {$n SetDescription  $val}
                        "name"             {
                            # check to make sure there are no spaces in the name
                            if {[string first " " $val] != -1} {
                                if {$::Module(verbose)} {
                                    puts "MainMrmlBuildTreesVersion2.0: changing spaces to underscores in Landmark name $val"
                                }
                                $n SetName [regsub -all " " $val "_"]
                            } else {
                                $n SetName         $val
                            }
                        }
                        "xyz"              {eval $n SetXYZ     $val}
                        "focalxyz"              {eval $n SetFXYZ     $val}
                        "pathposition"    {$n SetPathPosition  $val}
                    }
                }
            }

            "Hierarchy" {
                set n [MainMrmlAddNode Hierarchy]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "id" {$n SetHierarchyID $val}
                        "type" {$n SetType $val}
                    }
                }
            }
            "EndHierarchy" {
                set n [MainMrmlAddNode EndHierarchy]
            }
            "ModelGroup" {
                set n [MainMrmlAddNode ModelGroup]
                $n SetExpansion 1; #always show groups expanded
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "id" {$n SetModelGroupID $val}
                        "name" {$n SetName $val}
                        "color" {$n SetColor $val}
                        "opacity" {$n SetOpacity $val}
                        "visibility" {
                            if {$val == "yes" || $val == "true"} {
                                $n SetVisibility 1
                            } else {
                                $n SetVisibility 0
                            }
                        }
                    }
                }        
            }
            "EndModelGroup" {
                set n [MainMrmlAddNode EndModelGroup]
            }
            "ModelRef" {
                set n [MainMrmlAddNode ModelRef]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "modelrefid" {$n SetModelRefID $val}
                    }
                }
            }
            "Scenes" {
                set n [MainMrmlAddNode Scenes]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "lang" {$n SetLang $val}
                        "name" {
                            $n SetName $val
                            # save the scene name, so that we can associate the scene options with it
                            set sceneName $val
                        }
                        "description" {$n SetDescription $val}
                    }
                }
            }
            "EndScenes" {
                set n [MainMrmlAddNode EndScenes]
            }
            "VolumeState" {
                set n [MainMrmlAddNode VolumeState]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "volumerefid" {$n SetVolumeRefID $val}
                        "colorlut" {$n SetColorLUT $val}
                        "foreground" {
                            if {$val == "true"} {
                                $n SetForeground 1
                            } else {
                                $n SetForeground 0
                            }
                        }
                        "background" {
                            if {$val == "true"} {
                                $n SetForeground 1
                            } else {
                                $n SetForeground 0
                            }
                        }
                        "label" {
                            if {$val == "true"} {
                                $n SetLabel 1
                            } else {
                                $n SetLabel 0
                            }
                        }
                        "fade" {
                            if {$val == "true"} {
                                $n SetFade 1
                            } else {
                                $n SetFade 0
                            }
                        }
                        "opacity" {
                            $n SetOpacity $val
                        }
                    }
                }
            }
            "EndVolumeState" {
                set n [MainMrmlAddNode EndVolumeState]
            }
            "CrossSection" {
                set n [MainMrmlAddNode CrossSection]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "position" {$n SetPosition $val}
                        "direction" {$n SetDirection $val}
                        "sliceslider" {$n SetSliceSlider $val}
                        "rotatorx" {$n SetRotatorX $val}
                        "rotatory" {$n SetRotatorY $val}
                        "inmodel" {
                            if {$val == "true"} {
                                $n SetInModel 1
                            } else {
                                $n SetInModel 0
                            }
                        }
                        "clipstate" { 
                            switch $val {
                                "true" { set val 1 }
                                "false" { set val 0 }
                            }
                            $n SetClipState $val
                        }
                        "cliptype" { $n SetClipType $val}
                        "zoom" {$n SetZoom $val}
                        "backvolrefid" {$n SetBackVolRefID $val}
                        "forevolrefid" {$n SetForeVolRefID $val}
                        "labelvolrefid" {$n SetLabelVolRefID $val}
                    }
                }
            }
            "SceneOptions" {
                set n [MainMrmlAddNode SceneOptions]
                if {$::Module(verbose)} {
                    puts "Node $n for Scene Options, part of scene $sceneName"
                }
                if {$sceneName != ""} {
                    $n SetName $sceneName                    
                }
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "viewup" {$n SetViewUp $val}
                        "position" {$n SetPosition $val}
                        "focalpoint" {$n SetFocalPoint $val}
                        "clippingrange" {$n SetClippingRange $val}
                        "viewmode" {$n SetViewMode $val}
                        "viewbgcolor" {$n SetViewBgColor $val}
                        "textureresolution" {$n SetViewTextureResolution $val}
                        "textureinterpolation" {$n SetViewTextureInterpolation $val}
                        "showaxes" {
                            if {$val == "true"} {
                                $n SetShowAxes 1
                            } else {
                                $n SetShowAxes 0
                            }
                        }
                        "showbox" {
                            if {$val == "true"} {
                                $n SetShowBox 1
                            } else {
                                $n SetShowBox 0
                            }
                        }
                        "showannotations" {
                            if {$val == "true"} {
                                $n SetShowAnnotations 1
                            } else {
                                $n SetShowAnnotations 0
                            }
                        }
                        "showslicebounds" {
                            if {$val == "true"} {
                                $n SetShowSliceBounds 1
                            } else {
                                $n SetShowSliceBounds 0
                            }
                        }
                        "showletters" {
                            if {$val == "true"} {
                                $n SetShowLetters 1
                            } else {
                                $n SetShowLetters 0
                            }
                        }
                        "showcross" {
                            if {$val == "true"} {
                                $n SetShowCross 1
                            } else {
                                $n SetShowCross 0
                            }
                        }
                        "showhashes" {
                            if {$val == "true"} {
                                $n SetShowHashes 1
                            } else {
                                $n SetShowHashes 0
                            }
                        }
                        "showmouse" {
                            if {$val == "true"} {
                                $n SetShowMouse 1
                            } else {
                                $n SetShowMouse 0
                            }
                        }
                        "dicomstartdir" {$n SetDICOMStartDir $val}
                        "filenamesortparam" {$n SetFileNameSortParam $val}
                        "dicomdatadictfile" {$n SetDICOMDataDictFile $val}
                        "dicompreviewwidth" {$n SetDICOMPreviewWidth $val}
                        "dicompreviewheight" {$n SetDICOMPreviewHeight $val}
                        "dicompreviewhighestvalue" {$n SetDICOMPreviewHighestValue $val}
                        "fov" {$n SetFOV $val}
                    }
                }
            }
            "ModelState" {
                set n [MainMrmlAddNode ModelState]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "modelrefid" {$n SetModelRefID $val}
                        "opacity" {$n SetOpacity $val}
                        "visible" {
                            if {$val == "true"} {
                                $n SetVisible 1
                            } else {
                                $n SetVisible 0
                            }
                        }
                        "slidervisible" {
                            if {$val == "true"} {
                                $n SetSliderVisible 1
                            } else {
                                $n SetSliderVisible 0
                            }
                        }
                        "sonsvisible" {
                            if {$val == "true"} {
                                $n SetSonsVisible 1
                            } else {
                                $n SetSonsVisible 0
                            }
                        }
                        "clipping" {
                            if {$val == "true"} {
                                $n SetClipping 1
                            } else {
                                $n SetClipping 0
                            }
                        }
                    }
                }
            }
            "WindowLevel" {
                set n [MainMrmlAddNode WindowLevel]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "window" {$n SetWindow $val}
                        "level" {$n SetLevel $val}
                        "lowerthreshold" {$n SetLowerThreshold $val}
                        "upperthreshold" {$n SetUpperThreshold $val}
                        "autowindowlevel" {
                            if {$val == "true"} {
                                $n SetAutoWindowLevel 1
                            } else {
                                $n SetAutoWindowLevel 0
                            }
                        }
                        "applythreshold" {
                            if {$val == "true"} {
                                $n SetApplyThreshold 1
                            } else {
                                $n SetApplyThreshold 0
                            }
                        }
                        "autothreshold" {
                            if {$val == "true"} {
                                $n SetAutoThreshold 1
                            } else {
                                $n SetAutoThreshold 0
                            }
                        }
                    }
                }
            }
            "Locator" {
                set n [MainMrmlAddNode Locator]
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "driver" {$n SetDriver $val}
                        "diffusecolor" {$n SetDiffuseColor $val}
                        "visibility" {
                            if {$val == "true"} {
                                $n SetVisibility 1
                            } else {
                                $n SetVisibility 0
                            }
                        }
                        "transversevisibility" {
                            if {$val == "true"} {
                                $n SetTransverseVisibility 1
                            } else {
                                $n SetTransverseVisibility 0
                            }
                        }
                        "normallen" {$n SetNormalLen $val}
                        "transverselen" {$n SetTransverseLen $val}
                        "radius" {$n SetRadius $val}
                    }
                }
            }
            default {
                foreach m $::Module(idList) {
                    
                    if { [info exists ::Module(${m},procMRMLLoad)] } {
                        global $m
                        set loadproc [set ::Module(${m},procMRMLLoad)]
                        $loadproc $tag $attr
                        
                    }
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlReadVersion1.0
# Calls MRMLRead on the filename. Deprecated.
# .ARGS
# path filename file containing mrml to be read in
# .END
#-------------------------------------------------------------------------------
proc MainMrmlReadVersion1.0 {fileName} {
    global Lut Dag Volume Model Config Color Gui Mrml env Transform
    global Fiducials EndFiducials Point
        global Path EndPath Landmark

    # Read file
    if {$fileName == ""} {
        set Dag(read) [MRMLCreateDag]
    } else {
        set Dag(read) [MRMLRead $fileName]
        if {$Dag(read) == "-1"} {
            tk_messageBox -message "Error reading MRML file: '$fileName'\n\
                See message written in console." 
            return
        }
    }

    # Expand URLs
    set Dag(expanded) [MRMLExpandUrls $Dag(read) $Mrml(dir)]
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlBuildTreesVersion1.0
# Add nodes to the mrml tree. Deprecated.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlBuildTreesVersion1.0 {} {
    global Dag Color Model Volume Transform EndTransform Matrix Path
    global Fiducials EndFiducials Point
    global Path EndPath Landmark

    set level 0
    set transformCount($level) 0
    set dag $Dag(expanded)
    set num [MRMLGetNumNodes $dag]

    for {set j 0} {$j < $num} {incr j} {
        set node [MRMLGetNode $dag $j]
        set type [MRMLGetNodeType $node]
        switch $type {
        
        "Separator" {
            # Increment the separator level.
            # Initialize the counter of transforms inside this separator.
            # Add a Transform node.
            
            incr level
            set transformCount($level) 0

            set n [MainMrmlAddNode Transform]
        }
        
        "End" {
            # For each transform inside this separator, add an EndTransform node.
            # Also add an EndTransform node for this separator itself.

            for {set c 0} {$c < $transformCount($level)} {incr c} {
                set n [MainMrmlAddNode EndTransform]
            }
            set level [expr $level - 1]

            set n [MainMrmlAddNode EndTransform]
        }
        
        "Transform" {
            # Increment the count of transforms inside the current separator.
            # Add a Transform node and a Matrix node.
            
            incr transformCount($level)

            set n [MainMrmlAddNode Transform]

            set n [MainMrmlAddNode Matrix]
            $n SetDescription  [MRMLGetValue $node desc]
            $n SetName         [MRMLGetValue $node name]
            $n SetMatrix       [MRMLGetValue $node matrix]
            eval $n Scale      [MRMLGetValue $node scale]
            $n RotateX         [MRMLGetValue $node rotateX]
            $n RotateY         [MRMLGetValue $node rotateY]
            $n RotateZ         [MRMLGetValue $node rotateZ]
            eval $n Translate  [MRMLGetValue $node translate]
        }

        "Color" {
            set n [MainMrmlAddNode Color]
            $n SetDescription  ""
            $n SetName         [MRMLGetValue $node name]
            $n SetAmbient      [MRMLGetValue $node ambient]
            $n SetDiffuse      [MRMLGetValue $node diffuse]
            $n SetSpecular     [MRMLGetValue $node specular]
            $n SetPower        [MRMLGetValue $node power]
            $n SetLabels       [MRMLGetValue $node labels]
            eval $n SetDiffuseColor [MRMLGetValue $node diffuseColor]
        }
        
        "Model" {
            set n [MainMrmlAddNode Model]
            $n SetDescription      [MRMLGetValue $node desc]
            $n SetName             [MRMLGetValue $node name]
            $n SetFileName         [MRMLGetValue $node fileName]
            $n SetFullFileName     [MRMLGetValue $node fileName]
            $n SetColor            [MRMLGetValue $node colorName]
            $n SetOpacity          [MRMLGetValue $node opacity]
            $n SetVisibility       [MRMLGetValue $node visibility]
            $n SetClipping         [MRMLGetValue $node clipping]
            $n SetBackfaceCulling  [MRMLGetValue $node backfaceCulling]
            $n SetScalarVisibility [MRMLGetValue $node scalarVisibility]
            eval $n SetScalarRange [MRMLGetValue $node scalarRange]
            # get any scalar file names
        }
        
        "Volume" {
            set n [MainMrmlAddNode Volume]
            $n SetDescription      [MRMLGetValue $node desc]
            $n SetName             [MRMLGetValue $node name]
            eval $n SetImageRange  [MRMLGetValue $node imageRange]
            eval $n SetDimensions  [MRMLGetValue $node dimensions]
            eval $n SetSpacing     [MRMLGetValue $node spacing]
            $n SetScalarTypeTo[MRMLGetValue $node scalarType]
            $n SetNumScalars       [MRMLGetValue $node numScalars]
            $n SetLittleEndian     [MRMLGetValue $node littleEndian]
            $n SetTilt             [MRMLGetValue $node tilt]
            $n SetRasToIjkMatrix   [MRMLGetValue $node rasToIjkMatrix]
            $n SetRasToVtkMatrix   [MRMLGetValue $node rasToVtkMatrix]
            $n UseRasToVtkMatrixOn
            $n SetFilePattern      [MRMLGetValue $node filePattern]
            $n SetFilePrefix       [MRMLGetValue $node filePrefix]
            $n SetFullPrefix       [MRMLGetValue $node filePrefix]
            $n SetWindow           [MRMLGetValue $node window]
            $n SetLevel            [MRMLGetValue $node level]
            $n SetAutoWindowLevel  [MRMLGetValue $node autoWindowLevel]
            if {$::Module(verbose)} {
                puts "auto=[$n GetAutoWindowLevel]"
            }
            $n SetLabelMap         [MRMLGetValue $node labelMap]
            $n SetScanOrder        [MRMLGetValue $node scanOrder]

            # Don't interpolate label maps
            if {[MRMLGetValue $node labelMap] == 1} {
                $n SetInterpolate 0
            }
        }
        }
    }

    # Add EndTransforms for each transform at the base level
    # (outside all separators)
    for {set c 0} {$c < $transformCount($level)} {incr c} {
        set n [MainMrmlAddNode EndTransform]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlDeleteColors
# Deletes all the color nodes.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlDeleteColors {} {
    global Module Mrml Color

    if {$Module(verbose) == 1} {
        puts "MainMrmlDeleteColors"
    }
    set tree "colorTree"
    set nodeType Color

    # the #0 puts the nodeType in global scope
    upvar #0 $nodeType Array

    MainMrmlClearList
    
    foreach id $Color(idList) {
        set Array(idListDelete) $id
        # Remove node's ID from idList
        set i [lsearch $Array(idList) $id]
        set Array(idList) [lreplace $Array(idList) $i $i]

        # remove the item
        Mrml($tree) RemoveItem Color($id,node)
        # delete the node
        Color($id,node) Delete
    }
    MainUpdateMRML
    MainColorsUpdateMRML 

    MainMrmlClearList
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlAddColorsFromFile
# Reads in colour information from a given xml file, adding to the mrml tree.
# Returns -1 if it cannot read the file, 1 on success.
# .ARGS
# string fileName the name of the xml file to open and search for colours
# .END
#-------------------------------------------------------------------------------
proc MainMrmlAddColorsFromFile {fileName} {
    global Module

    if {$Module(verbose) == 1} {
        puts "MainMrmlAddColorsFromFile: reading colours from file \'$fileName\'"
    }
    set tagsColors [MainMrmlReadVersion2.x $fileName]
    if {$tagsColors == 0} {
        set msg "Unable to read file MRML color file '$fileName'"
        puts $msg
        tk_messageBox -message $msg
        return -1
    }
    # build the new nodes
    MainMrmlBuildTreesVersion2.0 $tagsColors
    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlAddColors
# If there are no Color nodes, then read, and append default colors.
# Return a new list of tags, possibly including default colors.
# .ARGS
# list tags information about the color nodes
# .END
#-------------------------------------------------------------------------------
proc MainMrmlAddColors {tags} {
    global Module

    set colors 0
    foreach pair $tags {
        set tag  [lindex $pair 0]
        if {$tag == "Color"} {
            set colors 1
        }
    }
    if {$colors == 1} {return $tags}
    
    if {[info exists ::Color(defaultColorFileName)] == 1} {
        set fileName $::Color(defaultColorFileName)
        if {$::Module(verbose)} {
            puts "MainMrmlAddColors: using Color(defaultColorFileName)"
        }
    } else {
        set fileName [ExpandPath Colors.xml]
    }
    
    set tagsColors [MainMrmlReadVersion2.x $fileName]
    if {$tagsColors == 0} {
        set msg "Unable to read file default MRML color file '$fileName'"
        puts $msg
        tk_messageBox -message $msg
        return $tags
    }

    if {0} {
    # check to see if any sub modules have defined an AddColors routine
    set tagsModuleColors ""
    foreach m $Module(idList) {
        if {[info exists Module($m,procColor)] == 1} {
            if {$Module(verbose) == 1} {
                puts "mainmrml.tcl: found a colour proc for $m = $Module($m,procColor)"
            }
            # this deals with the case such as if the Volumes module has sub 
            # modules that each registered a color procedure
            foreach p $Module($m,procColor) {
                set tagsModuleColors [$p $tagsModuleColors]
            }
        }
    }
    return "$tags $tagsColors $tagsModuleColors"
}
    return "$tags $tagsColors"
}


#-------------------------------------------------------------------------------
# .PROC MainMrmlCheckColors
# Check to see if the colors have been saved.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlCheckColors {} {
    global Mrml
    
    if {[info exists ::Color(defaultColorFileName)] == 1} {
        set fileName $::Color(defaultColorFileName)
    } else {
        set fileName [ExpandPath Colors.xml]
    }
    
    set tags [MainMrmlReadVersion2.x $fileName]

    if {$tags != 0} {
        vtkMrmlColorNode default
        set n default

        Mrml(colorTree) InitTraversal
        set node [Mrml(colorTree) GetNextItem]

        foreach pair $tags {
            set tag  [lindex $pair 0]
            set attr [lreplace $pair 0 0]

            # Are we out of nodes?
            if {$node == ""} {
                set Mrml(colorsUnsaved) 1
            } else {
                if {$tag == "Color"} {
                    foreach a $attr {
                        set key [lindex $a 0]
                        set val [lreplace $a 0 0]
                        switch $key {
                        "desc"         {$n SetDescription  $val}
                        "name"         {$n SetName         $val}
                        "ambient"      {$n SetAmbient      $val}
                        "diffuse"      {$n SetDiffuse      $val}
                        "specular"     {$n SetSpecular     $val}
                        "power"        {$n SetPower        $val}
                        "labels"       {$n SetLabels       $val}
                        "diffuseColor" {eval $n SetDiffuseColor $val}
                        }
                    }
                    if {[$node GetDescription] != [$n GetDescription]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetName] != [$n GetName]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetAmbient] != [$n GetAmbient]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetDiffuse] != [$n GetDiffuse]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetSpecular] != [$n GetSpecular]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetPower] != [$n GetPower]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetLabels] != [$n GetLabels]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    if {[$node GetDiffuseColor] != [$n GetDiffuseColor]} {
                        set Mrml(colorsUnsaved) 1
                    }
                    set node [Mrml(colorTree) GetNextItem]
                }
            }
        }
        default Delete

        # Out of tags
        if {$node != ""} {
            set Mrml(colorsUnsaved) 1
        }
    }

}

#-------------------------------------------------------------------------------
# .PROC MainMrmlRelativity
# Traverses the mrml tree and sets the file prefix or full prefix for
# volume and model nodes to a relative path from Mrml(dir), so that
# when the mrml file is saved in Mrml(dir) it will contain relative
# paths to the model and volume files if they are in directories below the mrml
# save directory.
# .ARGS
# str oldRoot The path to the old directory in which the mrml file was saved. Ignored.
# .END
#-------------------------------------------------------------------------------
proc MainMrmlRelativity {oldRoot} {
    global Mrml Module

    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        set class [$node GetClassName]

        if {$class == "vtkMrmlVolumeNode"} {

            if {$Module(verbose) == 1} {
                puts "MainMrmlRelativity: volume node has file prefix [$node GetFilePrefix], oldroot = $oldRoot, full prefix [$node GetFullPrefix], Mrml(dir) = $Mrml(dir)"
            }
            # this proc will calculate the relative path between the file passed in and 
            # Mrml(dir) which was set before this proc was called, to the new mrml file 
            # save location, and return a true relative prefix
            $node SetFilePrefix [MainFileGetRelativePrefixNew [$node GetFullPrefix]]
            # Do I need to set the Full Prefix as well???? No.

            if {$Module(verbose) == 1} {
                puts "MainMrml.tcl MainMrmlRelativity: set file prefix to [$node GetFilePrefix] (full prefix is now [$node GetFullPrefix])"
            }
            # Kilian 02/03 I do not know what old root is good for but I will just leave it here

            # leave the full prefix alone, it's an absolute path
            if {0} {
                if {$oldRoot == $Mrml(dir)} { 
                    $node SetFullPrefix [file join $Mrml(dir) [$node GetFilePrefix]]
                } else { 
              $node SetFullPrefix [file join $Mrml(dir) \
                                       [file join $oldRoot [$node GetFilePrefix]]]
                }
            }
            # >> AT 7/6/01, sp 2002-08-20

            set num [$node GetNumberOfDICOMFiles]
            for {set i 0} {$i < $num} {incr i} {
                set filename [$node GetDICOMFileName $i]
                
                #set dir [file dirname $filename]
                #set name [file tail $filename]
                #set reldir [MainFileGetRelativePrefix $dir]
                # set relname [lindex [MainFileGetRelativeDirPrefix $filename] 1]
                set relname [MainFileGetRelativePrefixNew $filename]
                if {$::Module(verbose)} {
                    puts "MainMrmlRelativity: got dicom filename $filename, with new relative name $relname"
                }
                $node SetDICOMFileName $i $relname
            }

            # << AT 7/6/01, sp 2002-08-20
            # Kilian : Check if path exists 02/03
              
            } elseif {$class == "vtkMrmlModelNode"} {

            set ext [file extension [$node GetFileName]]
            $node SetFileName [MainFileGetRelativePrefix \
                                   [file join $oldRoot [$node GetFileName]]]$ext
            $node SetFullFileName [file join $Mrml(dir) \
                                       [file join $oldRoot [$node GetFileName]]]$ext
            
            # use the new version with real relative paths - doesn't work 
            # $node SetFileName [MainFileGetRelativePrefixNew [$node GetFileName]]
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlWrite
# Sets up for writing, called before MainMrmlWriteProceed.
# .ARGS
# filepath filename where to write the mrml file
# .END
#-------------------------------------------------------------------------------
proc MainMrmlWrite {filename} {
    global Mrml

    if { ![file writable [file dirname $filename]] } {
        DevErrorWindow "Can't write to $filename"
        return
    }
    # Store the new root and filePrefix
    # NA - try not resetting it here, MainMrmlRelativity needs to know where it was opened originally in order to calculate the paths to the volumes when save it in a new place.
    if {$::Module(verbose)} {
        puts "MainMrmlWrite: setting oldRoot to mrml dir ($Mrml(dir)) and mrml dir to $filename.\nThen calling MainMrmlRelativity and then MainMrmlCheckVolumes."
    }
    set oldRoot $Mrml(dir)
    # maybe we shouldn't set the filename yet...
    MainMrmlSetFile $filename
    # Rename all file with relative path names
    MainMrmlRelativity $oldRoot
    
    # Check if all the volumes also have relative path names 
    MainMrmlCheckVolumes $filename
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlWriteProceed
# Write out the mrml tree to file
# .ARGS
# filepath filename where to write the mrml file to
# .END
#-------------------------------------------------------------------------------
proc MainMrmlWriteProceed {filename} {
    global Mrml

    # set the model hierarchy model node colours back to normal if they're collapsed
    MainModelGroupsRestoreOldColors

    # See if colors are different than the defaults
    MainMrmlCheckColors

    # If colors have changed since last save, then save colors too
    if {$Mrml(colorsUnsaved) == 1} {
        if {$::Module(verbose)} {
            puts SaveColors
        }

        # Combine trees
        vtkMrmlTree tree

        # Data tree
        Mrml(dataTree) InitTraversal
        set node [Mrml(dataTree) GetNextItem]
        while {$node != ""} {
            tree AddItem $node
            set node [Mrml(dataTree) GetNextItem]
        }

        # Color tree
        Mrml(colorTree) InitTraversal
        set node [Mrml(colorTree) GetNextItem]
        while {$node != ""} {
            tree AddItem $node
            set node [Mrml(colorTree) GetNextItem]
        }

        # TODO: check that nodes can actually be written, files exist
        tree Write $filename
        if {[tree GetErrorCode] != 0} {
            #puts "ERROR: MainMrmlWriteProceed: unable to write mrml file with colours: $filename"
            #DevErrorWindow "ERROR: MainMrmlWriteProceed: unable to write mrml file with colours: $filename"
        }
        tree RemoveAllItems
        tree Delete
    } else {
        if {$::Module(verbose)} { 
            puts "MainMrmlWriteProceed: calling Write in the Mrml(dataTree) to file $filename" 
        }
        
        Mrml(dataTree) Write $filename
        
        if {[Mrml(dataTree) GetErrorCode] != 0} {
            #puts "ERROR: MainMrmlWriteProceed: unable to write mrml data file $filename"
            #DevErrorWindow "ERROR: MainMrmlWriteProceed: unable to write mrml data file $filename"
        }
    }
    # Colors don't need saving now
    set Mrml(colorsUnsaved) 0

    # restore the model hierarchy model node colours for collapsed model groups?
    # doesn't seem necessary, as ModelHierarchyEnter and expanding the groups will reset
    # the colours automatically
    
    
}

#-------------------------------------------------------------------------------
# .PROC MainMrmlCheckVolumes
# Make sure that the volumes have the first file present.
# If the check succeeds, call MainMrmlWriteProceed with the filename.
# .ARGS
# filepath filename mrml file name
# .END
#-------------------------------------------------------------------------------
proc MainMrmlCheckVolumes {filename} {
   global Mrml

    if {$::Module(verbose)} { puts "Starting MainMrmlCheckVolumes with filename $filename" }
   Mrml(dataTree) InitTraversal
   set node [Mrml(dataTree) GetNextItem]
   set volumelist ""
   while {$node != ""} {
       set class [$node GetClassName]
       if {($class == "vtkMrmlVolumeNode")} {
           if {[$node GetNumberOfDICOMFiles] == 0} {
               # test the first non dicom volume file
               if {$::Module(verbose)} {
                   puts "MainMrmlCheckVolumes: non dicom file:\n\tfile pattern  [$node GetFilePattern] \n\tfull prefix [$node GetFullPrefix]\n\t file prefix [$node GetFilePrefix]"
               }
               set fname [format [$node GetFilePattern] [$node GetFullPrefix] [lindex [$node GetImageRange] 0]]
               if {$::Module(verbose)} {
                   puts "MainMrmlCheckVolumes: non dicom file, set this node's file name to $fname"
               }
           } else {
               # test the first dicom volume file
               set fname [$node GetDICOMFileName 0]
               if {$::Module(verbose)} {
                   puts "MainMrmlCheckVolumes: dicom file, first name is $fname"
               }
               # if it's a relative file name, convert to abs to test it
               if {[file pathtype $fname] == "relative"} {
                   set fname2 [file join ${Mrml(dir)} ${fname}]
                   if {$::Module(verbose)} {
                       puts "MainMrmlCheckVolumes: filename is relative $fname.\n\t Prepended mrml dir to filename: $fname2.\n\tSetting dicom filename to normalised name [file normalize $fname2]"
                   }
                   set fname [file normalize $fname2]
               }
           }
           if {([file exist $fname] == 0)} {
               set volumelist "$volumelist {[$node GetName]: $fname}\n"
           }
       }
       set node [Mrml(dataTree) GetNextItem]
  }
  if {[string length $volumelist]} {
      YesNoPopup MrmlCheckVolumes 20 50 "The following volumes will not be saved in the XML-file,\n because the first volume file does not exist:\n $volumelist\nWrite XML-file anyway?\n(press No to save volumes)" "MainMrmlWriteProceed \{$filename\} ; MainMrmlAbsolutivity"  "Tab Editor row1 Volumes ; TabbedFrameInvoke $::Module(Editor,fVolumes) File"
  } else {
      MainMrmlWriteProceed $filename
      
      # then reset the mrml tree to have absolute filenames
      MainMrmlAbsolutivity 
  }
} 

#-------------------------------------------------------------------------------
# .PROC MainMrmlAbsolutivity
# Traverses the mrml tree and sets the file prefix or full prefix for
# volume and model nodes to an absolute path, starting any relative paths from Mrml(dir).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainMrmlAbsolutivity {} {
    global Mrml Module

    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        set class [$node GetClassName]

        if {$class == "vtkMrmlVolumeNode"} {

            if {$Module(verbose) == 1} {
                puts "MainMrmlAbsolutivity: volume node has file prefix [$node GetFilePrefix], full prefix [$node GetFullPrefix], Mrml(dir) = $Mrml(dir)"
            }
             
            set oldPrefix [$node GetFullPrefix]
            if {[file pathtype $oldPrefix] == "relative"} {
                set fname [file join ${Mrml(dir)} ${oldPrefix}]
                if {$::Module(verbose)} { 
                    puts "MainMrmlAbsolutivity: non dicom file \n\trelative old prefix $oldPrefix\n\tnew one wrt mrml dir $fname\n\tnormalized = [file normalize $fname]"
                }
                $node SetFilePrefix [file normalize $fname]
            } else {
                # just normalize it if there are ..'s in the middle of the path
                if {[string first ".." $oldPrefix] != -1} {
                    if {$::Module(verbose)} {
                        puts "MainMrmlAbsolutivity: non dicome file \n\t old prefix with ..'s: $oldPrefix\n\t new one normalized = [file normalize $oldPrefix]"
                    }
                    $node SetFilePrefix [file normalize $oldPrefix]
                }
            }
            set num [$node GetNumberOfDICOMFiles]
            for {set i 0} {$i < $num} {incr i} {
                set filename [$node GetDICOMFileName $i]
                if {$::Module(verbose)} {
                    puts "MainMrmlAbsolutivity: got dicom filename $filename"
                }
                if {[file pathtype $filename] == "relative"} {
                    set absname [file join ${Mrml(dir)} ${filename}]
                    if {$::Module(verbose)} {
                        puts "MainMrmlAbsolutivity: dicom file \n\trelative old filename $filename\n\tnew one wrt mrml dir $absname\n\tnormalized = [file normalize $absname]"
                    }
                    $node SetDICOMFileName $i [file normalize $absname]
                }
            }
              
        } elseif {$class == "vtkMrmlModelNode"} {
            # ignore these for now as they're not touched
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}
