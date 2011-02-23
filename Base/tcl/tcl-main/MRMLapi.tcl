#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MRMLapi.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:52 $
#   Version:   $Revision: 1.16 $
# 
#===============================================================================
# FILE:        MRMLapi.tcl
# PROCEDURES:  
#   MRMLInit
#   MRMLReadDefaults
#   MRMLGetDefault
#   MRMLRead
#   MRMLExpandUrls
#   MRMLComputeRelationships
#   MRMLParseDagIntoArray
#   MRMLWrite
#   MRMLCheckFileExists
#   MRMLCreateDag
#   MRMLClearDag
#   MRMLAppendDag
#   MRMLInsertDag
#   MRMLCreateNode
#   MRMLAppendNode
#   MRMLInsertNode
#   MRMLDeleteNode
#   MRMLSetNode
#   MRMLGetNode
#   MRMLGetNumNodes
#   MRMLCountTypeOfNode
#   MRMLGetIndexOfNodeInDag
#   MRMLGetIndexOfAttributeInNode
#   MRMLGetNodeType
#   MRMLGetValue
#   MRMLSetValue
#   MRMLAddAttribute
#   MRMLGetNumAttributes
#   MRMLGetAttribute
#   MRMLGetAttributeKey
#   MRMLGetAttributeValue
#==========================================================================auto=

# This file contains an application programming interface (API) for programmers
# who read and write files for the Medical Reality Modeling Language (MRML).
#
# WHAT IS MRML
# ------------
# MRML was inspired by the Virtual Reality Modeling Language (VRML) used to
# construct 3-D scenes.
# A MRML file represents a directed acyclical graph (DAG) that is a tree-like
# structure of leaves referred to here as nodes.  Example nodes are Volumes
# (raster data) and Models (polygon data).  Nodes have attributes expressed
# as "key value" pairs.  For example the file name of a model may be stored as
# "fileName /data/skin.vtk" where "fileName" is the key and "/data/skin.vtk"
# is the value.  Default attributes must be read in using MRMLReadDefaults
# before calling some of the other procedures.
# Geometrical relationships are maintained among some types of nodes
# (Volume, Model) by concatenating nested transformations in the file.
#
# FILE FORMAT
# -----------
# The first line of a MRML file must be:
# MRML V<version number>
# The first line may be followed by any number of comment lines starting with
# the '#' sign.  Comments may not appear anywhere else in the file.
# No blank lines may appear in the file.
#
# DAG FORMAT
# ----------
# A dag consists of a TCL list of nodes.
# A node consist of a TCL list where the first item in the list is the name
# of the type of node, and the remaining items are attributes (key-value pairs).
# An example dag is:
#   {Model {name tumor} {fileName tumor.vtk}} {Volume {name mr} {filePrefix I}}
# This structure is actually abstracted from the programmer through the use
# of the procedures in this file.  That allows the structure to change.
#
# PROCEDURES (in order of appearance)
# -----------------------------------
# Procedure Name:                   Procedure Arguments:
# =============================     ===============================
# MRMLReadDefaults                  filename 
# MRMLGetDefault                    nodeType key
# MRMLRead                          filename ...
# MRMLExpandUrls                    dag dirname
# MRMLComputeRelationships          dag
# MRMLParseDagIntoArray             dag typeArray type programName
# MRMLWrite                         dag filename
# MRMLCheckFileExists               filename
# MRMLCreateDag                     
# MRMLClearDag                      dag
# MRMLAppendDag                     dag newDag
# MRMLCreateNode                    dag type
# MRMLInsertDag                     dag newDag i
# MRMLAppendNode                    dag node
# MRMLInsertNode                    dag node i
# MRMLDeleteNode                    dag i
# MRMLSetNode                       dag i node
# MRMLGetNode                       dag i
# MRMLGetNumNodes                   dag
# MRMLCountTypeOfNode               dag type
# MRMLGetIndexOfNodeInDag           dag i type
# MRMLGetIndexOfAttributeInNode     dag key
# MRMLGetNodeType                   node
# MRMLGetValue                      node key
# MRMLSetValue                      node key value
# MRMLAddAttribute                  node key value
# MRMLGetNumAttributes              node
# MRMLGetAttribute                  node i
# MRMLGetAttributeKey               attribute
# MRMLGetAttributeValue             attribute

# EXAMPLES
# --------
# Read a MRML file, add a new model called skin, and write the file:
#
# MRMLReadDefaults "Defaults.mrml"
# set dag    [MRMLRead "data.mrml"]
# if {$dag == "-1"} {puts error}
# set node   [MRMLCreateNode "Model"]
# set node   [MRMLSetValue $node "name" "Skin"]
# set dag    [MRMLAppendNode $dag $node]
# MRMLWrite $dag "data.mrml"
#
# Print the name of all the models:
#
# set filename "data.mrml"
# MRMLReadDefaults "Defaults.mrml"
# set dag [MRMLRead $filename]
# set dag [MRMLExpandUrls $dag [file dirname $filename]]
# set dag [MRMLComputeRelationships $dag]
# set models(idList) ""
# MRMLParseDagIntoArray $dag models "Model" "smg" "value 3 smooth 50"
# foreach id $models(idList) {
#    puts $models($id,name)
# }
#

#-------------------------------------------------------------------------------
# .PROC MRMLInit
#
# This function serves no purpose yet, but it may in the future.
# .END
#-------------------------------------------------------------------------------
proc MRMLInit {} {
}

#-------------------------------------------------------------------------------
# .PROC MRMLReadDefaults
#
# Reads file 'filename' to create array 'MRMLDefaults' which contains default
# key-value pairs.  For example, print the default name for models as:
#   MRMLReadDefaults 'Defaults.mrml'
#    puts name=[MRMLGetDefault Model name]
# Returns the MRML version on success, or '' on error.
# .END
#-------------------------------------------------------------------------------
proc MRMLReadDefaults {filename} { 
    global MRMLDefaults

    # Init
    set MRMLDefaults(nodeList) ""
    set debug 0
    set nLine 0
    
    # Open file and check that is a MRML file
    if {[MRMLCheckFileExists $filename] == 0} {
        return ""
    }
    set fid [open $filename r]
    gets $fid line; incr nLine
        if {[lindex $line 0] != "MRML"} {
        puts "Not a MRML file: '$filename'"
        if {[catch {close $fid} errorMessage]} {
            tk_messageBox -type ok -message "The following error occurred saving a file named ${filename} : ${errorMessage}"
            puts "Aborting due to : ${errorMessage}"
            exit 1
        }
        return ""
    }
    # Store version number for checking other files read
    set MRMLDefaults(version) [lindex $line 1]
    gets $fid line; incr nLine

    # Skip comments
    while {[eof $fid] == 0 && [string range $line 0 0] == "#"} {
        gets $fid line; incr nLine
    }

    # Read Nodes
    while {[eof $fid] == 0} {

        # Read node type
        set node [lindex $line 0]

        # Check for open brace
        if {[lindex $line 1] != "("} {
            puts "Error: missing open brace on line $nLine."
            if {[catch {close $fid} errorMessage]} {
                            tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                            puts "Aborting due to : ${errorMessage}"
                                   exit 1
                    }
            return ""
        }
        # Record node type
        lappend MRMLDefaults(nodeList) $node
        gets $fid line; incr nLine

        # Read attributes until closing brace
        set MRMLDefaults($node,keyList) ""
        while {[eof $fid] == 0 && [lindex $line 0] != ")" } {

            # Read attribute
            set key   [lindex   $line 0]
            set value [lreplace $line 0 0]
            lappend MRMLDefaults($node,keyList) $key
            set MRMLDefaults($node,$key) $value
            if {$debug == "1"} {puts "$node: $key=$value"}

            # Read next line
            gets $fid line; incr nLine
        }

        # Read next node
        gets $fid line; incr nLine
    }

    # Cleanup
    if {[catch {close $fid} errorMessage]} {
            tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
            puts "Aborting due to : ${errorMessage}"
            exit 1
        }
    return $MRMLDefaults(version)
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetDefault
#
# Returns the default value of 'key' in node of type 'nodeType'.
# The value of key may be 'keyList' to return a list of all valid keys.
# The value of nodeType may be 'version' to return the MRML file version number.
# The value of nodeType may be 'nodeList' to return a list of valid node types.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetDefault {nodeType {key ""}} {
    global MRMLDefaults

    if {$key == ""} {
        return $MRMLDefaults($nodeType)
    } else {
        return $MRMLDefaults($nodeType,$key)
    }
}

#-------------------------------------------------------------------------------
# .PROC MRMLRead
#
# Reads file 'filename' and returns the dag or '' on failure.
# 'MRMLDefaults' is the global array of default values read by MRMLReadDefaults.
#
# Returns the dag on success, or -1 on error.
# .END
#-------------------------------------------------------------------------------
proc MRMLRead {filename} {
    global MRMLDefaults
    
    # Init
    set dag ""
    set depth 0
    set nLine 0
    
    # Open file and check that is a MRML file
    if {[MRMLCheckFileExists $filename] == 0} {
        return -1 
    }
    set fid [open $filename r]
    gets $fid line; incr nLine
    if {[lindex $line 0] != "MRML"} {
        puts "Not a MRML file: '$filename'"
        if {[catch {close $fid} errorMessage]} {
                        tk_messageBox -type ok -message "The following error occurred saving a file named ${filename} : ${errorMessage}"
                        puts "Aborting due to : ${errorMessage}"
                        exit 1
                }
        return -1 
    }
    # Check MRML version
    set version [lindex $line 1]
    if {$version != [MRMLGetDefault version]} {
        puts "MRML file '$filename' is version '$version' instead of \
        '[MRMLGetDefault version]'."
        if {[catch {close $fid} errorMessage]} {
                        tk_messageBox -type ok -message "The following error occurred saving a file named ${filename} : ${errorMessage}"
                        puts "Aborting due to : ${errorMessage}"
                        exit 1
                }
        return -1 
    }
    gets $fid line; incr nLine

    # Skip comments
    while {[eof $fid] == 0 && [string range $line 0 0] == "#"} {
        gets $fid line; incr nLine
    }

    # Read Nodes
    while {[eof $fid] == 0} {

        # Read node type
        set type [lindex $line 0]

        if {$type != ")"} {
            # Check for open brace
            if {[lindex $line 1] != "("} {
                puts "Error: missing open brace on line $nLine."
                if {[catch {close $fid} errorMessage]} {
                                tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                   puts "Aborting due to : ${errorMessage}"
                                       exit 1
                        }
                return -1 
            }

            # Validate node type
            if {[lsearch [MRMLGetDefault nodeList] $type] == -1} {
                puts "Error: unknown node type: $type."
                if {[catch {close $fid} errorMessage]} {
                                tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                   puts "Aborting due to : ${errorMessage}"
                                       exit 1
                        }
                return -1 
            }
        }

        # Process node

        # Separator
        if {$type == "Separator"} {
            set node "Separator"
            incr depth

        # End of Separator
        } elseif {$type == ")"} {
            set node "End"
            set depth [expr $depth - 1]
            if {$depth < 0} {
                puts "Error: Extra separator end on line $nLine."
                if {[catch {close $fid} errorMessage]} {
                                tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                   puts "Aborting due to : ${errorMessage}"
                                       exit 1
                        }
                return -1 
            }

        # Transform
        } elseif {$type == "Transform"} {
            # Concatenate operations onto the current transform
        
            set node [MRMLCreateNode $type]
            gets $fid line; incr nLine

            # Read attributes until closing brace
            while {[eof $fid] == 0 && [lindex $line 0] != ")" } {
        
                # Read attribute's key
                set key [lindex $line 0]
                
                # Validate key
                if {[lsearch [MRMLGetDefault $type keyList] $key] == "-1"} {
                    puts "Error: invalid key '$key' for node '$type' on \
                        line $nLine"
                    if {[catch {close $fid} errorMessage]} {
                                    tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                       puts "Aborting due to : ${errorMessage}"
                                           exit 1
                            }
                    return -1 
                }

                # Read Attribute's value
                set value [lreplace $line 0 0]
                set node [MRMLSetValue $node $key $value]

                # Validate value
                set lenRequired [llength $value]
                switch $key {
                    matrix    {set len 16}
                    translate {set len 3}
                    scale     {set len 3}
                    rotateX   {set len 1}
                    rotateY   {set len 1}
                    rotateZ   {set len 1}
                    default   {set len -1}
                }
                if {$len != -1} {
                    if {$len != $lenRequired} {
                        puts "The '$key' attribute requires $lenRequired \
                            numbers, but $len were given."
                        if {[catch {close $fid} errorMessage]} {
                                        tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                           puts "Aborting due to : ${errorMessage}"
                                               exit 1
                                }
                        return -1 
                    }
                }    
                # Read next line
                gets $fid line; incr nLine
            }

            # Check for close brace
            if {[lindex $line 0] != ")"} {
                puts "Error: missing close brace on line $nLine."
                if {[catch {close $fid} errorMessage]} {
                                tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                   puts "Aborting due to : ${errorMessage}"
                                          exit 1
                        }
                return -1 
            }

        # Url
        } elseif {$type == "Url"} {
        
            set node [MRMLCreateNode $type]
            gets $fid line; incr nLine

            # Read attributes until closing brace
            while {[eof $fid] == 0 && [lindex $line 0] != ")" } {
        
                # Read attribute's key
                set key [lindex $line 0]
                
                # Validate key
                if {[lsearch [MRMLGetDefault $type keyList] $key] == "-1"} {
                    puts "Error: invalid key '$key' for node '$type' on \
                        line $nLine"
                    if {[catch {close $fid} errorMessage]} {
                                     tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                       puts "Aborting due to : ${errorMessage}"
                                              exit 1
                            }
                    return -1 
                }

                # Read Attribute's value
                set value [lreplace $line 0 0]
                set node [MRMLSetValue $node $key $value]

                # Read next line
                gets $fid line; incr nLine
            }

            # Check for close brace
            if {[lindex $line 0] != ")"} {
                puts "Error: missing close brace on line $nLine."
                if {[catch {close $fid} errorMessage]} {
                                 tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                  puts "Aborting due to : ${errorMessage}"
                                          exit 1
                        }
                return -1 
            }

        # Volume, Model, Color, Config
        } else {

            set node [MRMLCreateNode $type]
            gets $fid line; incr nLine

            # Read attributes until closing brace
            while {[eof $fid] == 0 && [lindex $line 0] != ")" } {
    
                # Read attribute's key
                set key [lindex $line 0]

                # Validate key
                if {[lsearch [MRMLGetDefault $type keyList] $key] == "-1"} {
                    puts "Error: invalid key '$key' for node '$type' on \
                        line $nLine"
                    if {[catch {close $fid} errorMessage]} {
                                     tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                      puts "Aborting due to : ${errorMessage}"
                                              exit 1
                            }
                    return -1 
                }

                # Read attribute's value
                set value [lreplace $line 0 0]
                set node [MRMLSetValue $node $key $value]
    
                # Read next line
                gets $fid line; incr nLine
            }

            # Check for close brace
            if {[lindex $line 0] != ")"} {
                puts "Error: missing close brace on line $nLine."
                if {[catch {close $fid} errorMessage]} {
                                 tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                  puts "Aborting due to : ${errorMessage}"
                                          exit 1
                        }
                return -1 
            }

        }

        # Append a Volume or Model to DAG if we're not ignoring it
        if {[lsearch "Volume Model" $type] != "-1"} {
            if {[MRMLGetValue $node "ignore"] == 0} {
                set dag [MRMLAppendNode $dag $node]
            }
        } else {
            set dag [MRMLAppendNode $dag $node]
        }

        # Read next node
        gets $fid line; incr nLine
    }

    if {$depth > 0} {
        puts "Error: extra separator."
        if {[catch {close $fid} errorMessage]} {
                           tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                       puts "Aborting due to : ${errorMessage}"
                           exit 1
                   }
        return -1 
    }
    if {$depth < 0} {
        puts "Error: extra close brace."
        if {[catch {close $fid} errorMessage]} {
                           tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                       puts "Aborting due to : ${errorMessage}"
                           exit 1
                   }
        return -1 
    }

    # Cleanup
    if {[catch {close $fid} errorMessage]} {
                   tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
               puts "Aborting due to : ${errorMessage}"
                      exit 1
        }
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLExpandUrls
#
# 'fileDir' is the directory name of the MRML file.
#
# Concatenates relative URLs with root URLs.
# Expands (reads in) all the URLs in 'dag' that aren't 'root' URLs.
#
# 'depth' should not be used.  The procedure uses it when calling itself
# recursively.
#
# Returns the new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLExpandUrls {dag fileDir {depth 0}} {

    set numNodes [MRMLGetNumNodes $dag]
    set UrlRoot(0) "$fileDir"
    set n 0
    while {$n < $numNodes} {

        # Get node
        set node [MRMLGetNode $dag $n]
        set type [MRMLGetNodeType $node]

        # Separator
        if {$type == "Separator"} {
            incr depth
            set UrlRoot($depth) $UrlRoot([expr $depth-1])

        # End of Separator
        } elseif {$type == "End"} {
            set depth [expr $depth - 1]

        # Url
        } elseif {$type == "Url"} {
        
            # Get this Url's attributes
            foreach key "url link" {
                set $key [MRMLGetValue $node $key]
            }

            # If this Url is relative, then concatenate it with the root Url
            set url [file join $UrlRoot($depth) $url]
            set node [MRMLSetValue $node "url" $url]

            # If this is not a link Url, then store it as the root Url
            if {$link == 0} {
                set UrlRoot($depth) $url
            } else {
                # Else, expand this Url (read it in)

                set urlDag [MRMLRead $url]
                if {$urlDag != "-1"} {
                    set urlDag [MRMLExpandUrls $urlDag $fileDir $depth]

                    set dag [MRMLDeleteNode $dag $n]
                    set dag [MRMLInsertDag $dag $urlDag $n]

                    set urlNumNodes [expr [MRMLGetNumNodes $urlDag] - 1]
                    set n           [expr $n + $urlNumNodes]
                    set numNodes    [expr $numNodes + $urlNumNodes]
                }
            }

        # Model, Volume
        } elseif {$type == "Model" || $type == "Volume"} {

            # Apply root url to Volumes and Models
            foreach nodeType "Volume Model" urlName "filePrefix fileName" {
                if {$nodeType == $type} {
                    set url [file join $UrlRoot($depth) \
                        [MRMLGetValue $node $urlName]]
                    set node [MRMLSetValue $node $urlName $url]
                    set dag  [MRMLSetNode $dag $n $node]
                }
            }
        }

        incr n
    }
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLComputeRelationships
#
# Computes the geometric relationships between volumes and models.
# This function must be called before MRMLParseDagIntoArray.
#
# Attributes with key name 'id' are added to some nodes to assign them unique 
# identifiers for easier referencing.  One may optionally set the first id.
# For example, to number 2 volumes as 3 and 4, set 'nextVolumeID' to 3.
# See the MRMLParseDagIntoArray procedure for an example of how to use id's.
# Transforms are concatenated to form matrices 'rasToRefStr'.
#
# Returns the new dag or '' on error.
# .END
#-------------------------------------------------------------------------------
proc MRMLComputeRelationships {dag \
    {nextVolumeID 1} {nextModelID 0} {nextColorID 0} {nextConfigID 0}} {

    # Init
    set depth 0
    set volumeID($depth) "-1"
    set labelID($depth) "-1"
    
    # Initialize transform stack
    vtkTransform trans
    trans Identity
    vtkMatrix4x4 mat
  
    # Set the vtkTransform to PostMultiply so a concatenated matrix, C,
    # is multiplied by the existing matrix, M: C*M (not M*C)
    trans PostMultiply

    set numNodes [MRMLGetNumNodes $dag]
    set n 0
    while {$n < $numNodes} {

        # Get node
        set node [MRMLGetNode $dag $n]
        set type [MRMLGetNodeType $node]

        # Separator
        if {$type == "Separator"} {

            # Push the current transform
            trans Push
            incr depth
            set volumeID($depth) "-1"
            set labelID($depth) "-1"

        # End of Separator
        } elseif {$type == "End"} {

            # Pop transform
            trans Pop
            set depth [expr $depth - 1]

        # Transform
        } elseif {$type == "Transform"} {

            # Process each attribute to concatenate operations onto the
            # current transform
            set numAttr [MRMLGetNumAttributes $node]
            for {set i 0} {$i < $numAttr} {incr i} {
        
                # Get attribute
                set attr  [MRMLGetAttribute $node $i]
                set key   [MRMLGetAttributeKey $attr]
                set value [MRMLGetAttributeValue $attr]

                # Concatenate the operation to the current transformation
                set defaultValue [MRMLGetDefault $type $key]
                if {$defaultValue != $value} {
                    switch $key {
                        matrix {
                            for {set i 0} {$i < 4} {incr i} {
                                for {set j 0} {$j < 4} {incr j} {
                                    mat SetElement $i $j \
                                        [lindex $value [expr $i*4+$j]]
                                }
                            }
                            trans Concatenate mat 
                        }
                        scale {
                            eval trans Scale $value
                        }
                        rotateX {
                            trans RotateX $value
                        }
                        rotateY {
                            trans RotateY $value
                        }
                        rotateZ {
                            trans RotateZ $value
                        }
                        translate {
                            eval trans Translate $value
                        }
                    }
                }
            }

        # Url
        } elseif {$type == "Url"} {
            # Nichts

        # Volume, Model, Color, Config
        } else {

            # Set ID to the next one available
            switch $type {
                Volume  {set id $nextVolumeID}
                Model   {set id $nextModelID}
                Color   {set id $nextColorID}
                Config  {set id $nextConfigID}
                default {
                    puts "Error: invalid node type: '$type' on line $nLine"
                    if {[catch {close $fid} errorMessage]} {
                                    tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                       puts "Aborting due to : ${errorMessage}"
                                           exit 1
                            }
                    trans Delete
                    mat Delete
                    return ""
                }
            }
            incr next${type}ID

            # Add the ID to the node
            set node [MRMLAddAttribute $node "id" $id]

            # Update the volumeID
            if {$type == "Volume"} {
                if {[MRMLGetValue $node labelMap] != "1"} {
                    set volumeID($depth) $id
                }
            }

            # Update the labelID
            if {$type == "Volume"} {
                if {[MRMLGetValue $node labelMap] == "1"} {
                    set labelID($depth) $id
                }
            }

            # Attach a Model or Label to a Volume
            if {$type == "Model"} {
                set node [MRMLAddAttribute $node "volumeID" $volumeID($depth)]
            }
            if {$type == "Volume"} {
                if {[MRMLGetValue $node labelMap] == "1"} {
                    set node [MRMLAddAttribute $node "volumeID" \
                        $volumeID($depth)]
                } else {
                    set node [MRMLAddAttribute $node "volumeID" "-1"]
                }
            }

            # Attach a Model to a Label
            if {$type == "Model"} {
                set node [MRMLAddAttribute $node "labelID" $labelID($depth)]
            }
 
            # If type is a Volume or Model
            # then store the ras-to-reference 
            # matrix that positions the node within the reference  space
            #
            if {[lsearch "Volume Model" $type] != "-1"} {
                set matrix [trans GetMatrix]
                set rasToRefStr ""
                for {set i 0} {$i < 4} {incr i} {
                    for {set j 0} {$j < 4} {incr j} {
                        lappend rasToRefStr [$matrix GetElement $i $j]
                    }
                }
                set node [MRMLAddAttribute $node "rasToRefMatrix" $rasToRefStr]
            }
        }

        # Save changes to this node
        set dag [MRMLSetNode $dag $n $node]

        incr n
    }

    trans Delete
    mat Delete
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLParseDagIntoArray
#
# MRMLComputeRelationships must be called first!
# Parses 'dag' to form 'typeArray' containing info for all nodes of type 'type'.
# Caller must first initialize the idList to empty with a command like:
#   set typeArray(idList) '' 
# (Don't do this if you want to add additional info to an existing array).
#
# Program-specific options can be optionally specified using the 'options'
# key.  To enable this, include the 'programName' and 'defaultOptions'
# which is a list of key-value pairs like: 'interpolate 1 lutID 0'.
# Options may then be referenced from the output array just like any other
# key-value pair.  A list of options is placed in $array(optionsList).
#
# After calling this procedure, attributes can then be referenced as shown 
# in the following example:
#   MRMLParseDagIntoArray $dag models 'Model'
#   foreach id $models(idList) {
#     puts $models($id,name)
#   }
# .END
#-------------------------------------------------------------------------------
proc MRMLParseDagIntoArray {dag typeArray type {programName ""} \
    {defaultOptions ""}} { 

    # Init
    upvar $typeArray array
    set debug 0
    set numNodes [llength $dag]

    if {$programName != ""} {
        set array(optionsList) ""
        foreach {key value} $defaultOptions {
            set array(optionsList) "$array(optionsList) $key"
        }
    }

    # Read Nodes
    for {set n 0} {$n < $numNodes} {incr n} {

        # Read node name
        set node     [MRMLGetNode $dag $n]
        set nodeType [MRMLGetNodeType $node]
        
        if {$type == $nodeType} {

            # Append ID to idList if its not already there.
            #
            set id [MRMLGetValue $node id]
            if {$id == ""} {
                puts "MRMLComputeRelationships must be called before \
                    MRMLParseDagIntoArray!"
                return ""
            }
            if {[lsearch $array(idList) $id] == -1} {
                lappend array(idList) $id
            }

            # Set (key,value) pairs for each attribute
            #
            set numAttr [MRMLGetNumAttributes $node]
            for {set i 0} {$i < $numAttr} {incr i} {
                set attr  [MRMLGetAttribute $node $i]
                set key   [MRMLGetAttributeKey $attr]
                set value [MRMLGetAttributeValue $attr]
                if {$debug == "1"} {puts "$type: $key=$value"}
                set array($id,$key) $value
            }

            # Assign options their default values (if not set already).
            #
            foreach {key value} $defaultOptions {
                set array($id,$key) $value
            }

            # Optionally parse options (ignore options for other programs)
            #
            if {$programName != ""} {
                set program [lindex $array($id,options) 0]
                set options [lrange $array($id,options) 1 end]
                if {$program == $programName} {
                    # Parse options in format: key1 value1 key2 value2 ...
                    # Verify that options exist in the list of defaults.
                    foreach {key value} $options {
                        if {[lsearch $array(optionsList) $key] == "-1"} {
                            puts "Unknown option: '$key' for node '$type'."
                        } else {
                            set array($id,$key) $value
                        }
                    }
                }
            }
        }
    }

    # Store number of IDs in array
    set array(num) [llength $array(idList)]

    # Determine next ID
    set maxId -1
    for {set i 0} {$i < $array(num)} {incr i} {
        set id [lindex $array(idList) $i]
        if {$id > $maxId} {
            set maxId $id
        }
    }
    set array(nextID) [expr $maxId + 1]
}

#-------------------------------------------------------------------------------
# These utility routines are used by the MRMLWrite procedure
#-------------------------------------------------------------------------------
proc MRMLIndent {fid text indents} {
    set tabs ""
    for {set i 0} {$i < $indents} {incr i} {
        set tabs "${tabs}\t"
    }
    puts $fid "${tabs}${text}"
}
proc MRMLWriteAttribute {fid key value depth} {
    MRMLIndent $fid "$key $value" [expr $depth + 1]
}
proc MRMLStartNode {fid name depth} {
    MRMLIndent $fid "$name (" $depth
}
proc MRMLEndNode {fid depth} {
    MRMLIndent $fid ")" $depth
}
proc MRMLWriteNode {fid type depth node} {

    # There are extra keys created by the MRMLRead procedure
    # so I don't want to have to write these out.
    set extraKeys "volumeID labelID id rasToRefMatrix"
    
    MRMLStartNode $fid $type $depth
    set numAttr [MRMLGetNumAttributes $node]
    for {set i 0} {$i < $numAttr} {incr i} {
        set attr  [MRMLGetAttribute $node $i]
        set key   [MRMLGetAttributeKey $attr]
        set value [MRMLGetAttributeValue $attr]

        # Validate key
        if {[lsearch [MRMLGetDefault $type keyList] $key] == "-1"} {
            if {[lsearch $extraKeys $key] == "-1"} {
                if {[catch {close $fid} errorMessage]} {
                                tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                                   puts "Aborting due to : ${errorMessage}"
                                       exit 1
                        }
                puts "Invalid key: '$key' for node type: '$type'"
                return "$type $key"
            }
        }

        # Write value if it differs from the default
        if {[lsearch $extraKeys $key] == "-1"} {        
            if {$value != [MRMLGetDefault $type $key]} {
                MRMLWriteAttribute $fid $key $value $depth
            }
        }
    }
    MRMLEndNode $fid $depth
}

#-------------------------------------------------------------------------------
# .PROC MRMLWrite
#
# Writes the 'dag' to the file 'filename'.
# Returns '' on success, and the name of an invalid node type (or invalid key
# type in the form 'node key') if any exist.
# .END
#-------------------------------------------------------------------------------
proc MRMLWrite {dag filename} {

    # Init
    set depth 0
    set numNodes [MRMLGetNumNodes $dag]
    set fid [open $filename w]
    puts $fid "MRML [MRMLGetDefault version]"

    # Read Nodes
    for {set n 0} {$n < $numNodes} {incr n} {

        # Validate node type
        set node [MRMLGetNode $dag $n]
        set type [MRMLGetNodeType $node]
        if {[lsearch [MRMLGetDefault nodeList] $type] == -1 && $type != "End"} {
            if {[catch {close $fid} errorMessage]} {
                            tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
                               puts "Aborting due to : ${errorMessage}"
                                      exit 1
                    }
            puts "Invalid node type: '$type'"
            return $type
        }
        
        if {$type == "Separator"} {

            MRMLStartNode $fid $type $depth
            incr depth

        } elseif {$type == "End"} {

            set depth [expr $depth - 1]
            MRMLEndNode $fid $depth

        } else {

            MRMLWriteNode $fid $type $depth $node
        }
    }
    if {[catch {close $fid} errorMessage]} {
                 tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}"
             puts "Aborting due to : ${errorMessage}"
                    exit 1
        }
    return ""
}

#-------------------------------------------------------------------------------
# .PROC MRMLCheckFileExists
#
# Checks if a file exists, is not a directory, and is readable.
# Returns 1 on success, else 0.
# .END
#-------------------------------------------------------------------------------
proc MRMLCheckFileExists {filename} {

    if {[file exists $filename] == 0} {
        puts "File '$filename' does not exist."
        return 0
    }
    if {[file isdirectory $filename] == 1} {
        puts "'$filename' is a directory, not a file."
        return 0
    }
    if {[file readable $filename] == 0} {
        puts "'$filename' exists, but is unreadable."
        return 0
    }
    return 1
}

#-------------------------------------------------------------------------------
# .PROC MRMLCreateDag
#
# Returns a new, empty dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLCreateDag {} {
    return ""
}

#-------------------------------------------------------------------------------
# .PROC MRMLClearDag
#
# Deletes all nodes in 'dag'.
# Returns the new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLClearDag {dag} {
    return ""
}

#-------------------------------------------------------------------------------
# .PROC MRMLAppendDag
#
# Appends 'newDag' to 'dag'.
# Returns new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLAppendDag {dag newDag} {
    return [concat $dag $newDag]
}

#-------------------------------------------------------------------------------
# .PROC MRMLInsertDag
#
# Inserts 'newDag' into 'dag' at index 'i' (0-based).
# Appends 'newDag' if 'i' is out of range, '', 'end', or unspecified.
# Returns the new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLInsertDag {dag newDag {i ""}} {
    if {$i < 0 || $i >= [llength $dag] || $i == "" || $i == "end"} {
        set dag [MRMLAppendDag $dag $newDag]
    } else {
        set numNodes [llength $newDag]
        for {set n 0} {$n < $numNodes} {incr n} {
            set node [lindex $newDag $n]
            set dag [linsert $dag $i $node]
            incr i
        }
    }
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLCreateNode
#
# Creates a node of type 'type' and sets all its attributes to defaults.
# Returns the new node or '' if the 'type' is invalid.
# Example of correct usage:
#    MRMLReadDefaults defaults 'Defaults.mrml'
#    set node [MRMLCreateNode 'Model' defaults]
# Example of incorrect usage:
#    set node [MRMLCreateNode 'Model' $defaults]
# .END
#-------------------------------------------------------------------------------
proc MRMLCreateNode {type} {

    # Separator Ends are a special case because they aren't in the Defaults.
    if {$type == "End"} {
        return "End"
    }
    
    if {[lsearch [MRMLGetDefault nodeList] $type] == "-1"} {
        puts "Error: '$type' is an invalid node type"
        return ""
    }
    # Set all the node's unspecified attributes to defaults
    set node $type
    foreach key [MRMLGetDefault $type keyList] {
        if {[MRMLGetIndexOfAttributeInNode $node $key] == ""} {
            lappend node [concat $key [MRMLGetDefault $type $key]]
        }
    }
    return $node
}

#-------------------------------------------------------------------------------
# .PROC MRMLAppendNode
#
# Appends 'node' to 'dag'.
# When appending a Separator, remember to append an End too.
# Returns new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLAppendNode {dag node } {
    lappend dag $node
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLInsertNode
#
# Insert node before iTH (0 is first) node in dag.
# The node is appended to the dag if 'i' is out of range, '', 'end', left off.
# When inserting a Separator, remember to insert an End too.
# Returns new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLInsertNode {dag node {i ""}} {
    if {$i < 0 || $i >= [llength $dag] || $i == "" || $i == "end"} {
        set dag [MRMLAppendNode $dag $node]
    } else {
        set dag [linsert $dag $i $node]
    }
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLDeleteNode
#
# Deletes the 'i'TH (0-based) node from 'dag'.
# If the node is a Separator, then its matching End is deleted as well.
# Returns the new dag
# .END
#-------------------------------------------------------------------------------
proc MRMLDeleteNode {dag i} {
    # Validate i
    if {$i < 0 || $i > [llength $dag]} {return $dag}

    # See if this is an end node, which can't be deleted
    set type [MRMLGetNodeType [MRMLGetNode $dag $i]]
    if {$type == "End"} {return $dag}

    # Delete matching end too (get the one at this depth, dude)
    if {$type == "Separator"} {
        set depth 1
        set numNodes [llength $dag]
        for {set n [expr $i + 1]} {$n < $numNodes} {incr n} {
            set type [MRMLGetNodeType [MRMLGetNode $dag $n]]
            if {$type == "End"} {
                set depth [expr $depth - 1]
                if {$depth == 0} {
                    set dag [lreplace $dag $n $n]
                }
            } elseif {$type == "Separator"} {
                incr depth
            }
        }
    }

    set cutNode [lindex $dag $i]
    set dag [lreplace $dag $i $i]
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLSetNode
#
# Replaces 'i'TH (0-based) node in 'dag' to be 'node'.
# Returns the new dag.
# .END
#-------------------------------------------------------------------------------
proc MRMLSetNode {dag i node} {
    if {$i < 0 || $i >= [llength $dag]} {return $dag}

    set dag [lreplace $dag $i $i $node]
    return $dag
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetNode
#
# Returns the 'i'TH (0-based) node from 'dag'.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetNode {dag i} {
    if {$i < 0 || $i >= [llength $dag]} {
        return ""
    }
    set node [lindex $dag $i]
    return $node
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetNumNodes
#
# Returns the number of nodes in 'dag'.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetNumNodes {dag} {
    return [llength $dag]
}

#-------------------------------------------------------------------------------
# .PROC MRMLCountTypeOfNode
#
# Returns the number of nodes in 'dag' of type 'type'. (ie: number of Models)
# .END
#-------------------------------------------------------------------------------
proc MRMLCountTypeOfNode {dag type} {

    set numNodes [llength $dag]
    set cnt 0
    for {set n 0} {$n < $numNodes} {incr n} {
        set node [lindex $dag $n]
        set name [lindex $node 0]
        if {$name == $type} {
            incr cnt
        }
    }
    return $cnt
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetIndexOfNodeInDag
#
# Returns the index of the 'i'TH (0-based) node of type 'type' in 'dag'.
# For example, to get the index of the 3RD Model, use:
#    set index [MRMLGetIndexOfNodeInDag $dag 2 Model]
# Returns '' if 'i' is out of range.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetIndexOfNodeInDag {dag i type} {
    set index -1
    set numNodes [llength $dag]
    for {set n 0} {$n < $numNodes} {incr n} {
        set node [lindex $dag $n]
        set nodeType [lindex $node 0]
        if {$type == $nodeType} {
            incr index
        }
        if {$i == $index} {
            return $n
        }
    }
    return ""
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetIndexOfAttributeInNode
#
# Returns the index of the 'i'TH (0-based) attribute of with 'key' in 'node'.
# Returns '' if 'key' is invalid.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetIndexOfAttributeInNode {node key} {
    # Find all attributes where key appears somewhere and see if key is right.
    set index ""
    set done 0
    set falseAlarms 0
    set n $node
    while {$done == 0} {
        set i [lsearch -regexp $n $key]
        if {$i == "-1"} {
            set done 1
        } else {
            set attr [lindex $n $i]
            set n [lreplace $n $i $i]
            if {[lindex $attr 0] == $key} {
                set index $i
                set done 1
            } else {
                incr falseAlarms
            }
        }
    }
    if {$index != ""} {
        set index [expr $index + $falseAlarms]
    }
    return $index
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetNodeType
#
# Returns the type of 'node'. (ie: 'Model')
# .END
#-------------------------------------------------------------------------------
proc MRMLGetNodeType {node} {
    return [lindex $node 0]
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetValue
#
# Returns the value of the attribute 'key' in 'node'.
# Returns '' if 'key' is invalid.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetValue {node key} {
    set i [MRMLGetIndexOfAttributeInNode $node $key]
    if {$i == ""} {return ""}

    return [lreplace [lindex $node $i] 0 0]
}

#-------------------------------------------------------------------------------
# .PROC MRMLSetValue
#
# Sets the value of 'key' in 'node' to 'value'.
# Returns the new node, or '' if the 'key' is invalid.
# .END
#-------------------------------------------------------------------------------
proc MRMLSetValue {node key value} {
    set i [MRMLGetIndexOfAttributeInNode $node $key]
    if {$i == ""} {return ""}

    set node [lreplace $node $i $i "$key $value"]
    return $node
}

#-------------------------------------------------------------------------------
# .PROC MRMLAddAttribute
#
# Adds the attribute with 'key' and 'value' to 'node'.
# Returns the new node.
# NOTE:
# All nodes possess all default attributes.  So the only reason to add
# attributes are for your own creative uses.
# .END
#-------------------------------------------------------------------------------
proc MRMLAddAttribute {node key value} {
    lappend node [concat $key $value]
    return $node
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetNumAttributes
#
# Returns the number of attributes (key-value pairs) in 'node'.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetNumAttributes {node} {
    return [expr [llength $node] - 1]
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetAttribute
#
# Returns the 'i'TH (0-based) attribute (key-value pair) in 'node'.
# .END
#-------------------------------------------------------------------------------
proc MRMLGetAttribute {node i} {
    return [lindex $node [expr $i + 1]]
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetAttributeKey
#
# Returns the key of the 'attribute' (key-value pair).
# .END
#-------------------------------------------------------------------------------
proc MRMLGetAttributeKey {attribute} {
    return [lindex $attribute 0]
}

#-------------------------------------------------------------------------------
# .PROC MRMLGetAttributeValue
#
# Returns the value of the 'attribute' (key-value pair).
# .END
#-------------------------------------------------------------------------------
proc MRMLGetAttributeValue {attribute} {
    return [lreplace $attribute 0 0]
}
