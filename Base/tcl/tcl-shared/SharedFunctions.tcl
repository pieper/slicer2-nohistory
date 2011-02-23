#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: SharedFunctions.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:05 $
#   Version:   $Revision: 1.10 $
# 
#===============================================================================
# FILE:        SharedFunctions.tcl
# PROCEDURES:  
#   SharedModelLookup ModelRefID
#   SharedVolumeLookup VolumeRefID
#   SharedGetModelsInGroup modelgroup umodels changeExpansion
#   SharedGetModelsInGroupOnly modelgroup umodels
#   SharedGetModelGroupsInGroup modelgroup umodelgroups
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC SharedModelLookup
# Gets the internal model ID that belongs to a given alphanumerical model ID.
# .ARGS
# int ModelRefID the alphanumerical model ID
# .END
#-------------------------------------------------------------------------------
proc SharedModelLookup {ModelRefID} {
    global Model
    
    set ModelID -1
    
    foreach m $Model(idList) {
        if {[Model($m,node) GetModelID] == $ModelRefID} {
            set ModelID [Model($m,node) GetID]
        }
    }
    return $ModelID
}


#-------------------------------------------------------------------------------
# .PROC SharedVolumeLookup
# Gets the internal volume ID that belongs to a given alphanumerical volume ID.
# .ARGS
# int VolumeRefID alphanumerical volume ID
# .END
#-------------------------------------------------------------------------------
proc SharedVolumeLookup {VolumeRefID} {
    global Volume
    
    set VolumeID -1
    
    foreach v $Volume(idList) {
        if {[Volume($v,node) GetVolumeID] == $VolumeRefID} {
            set VolumeID [Volume($v,node) GetID]
        }
    }
    return $VolumeID
}


#-------------------------------------------------------------------------------
# .PROC SharedGetModelsInGroup
# Gets all the models in a model group (including all dependent model groups).
# .ARGS
# int modelgroup the group where to get the dependent models from
# list umodels a list where the models are stored
# int changeExpansion if >=0, change the variable Model(id,expansion) to this value, but only in the group $modelgroup. defaults to -1
# .END
#-------------------------------------------------------------------------------
proc SharedGetModelsInGroup {modelgroup umodels {changeExpansion -1}} {
    global Mrml(dataTree) Model
    
    upvar $umodels models
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    set traversingModelGroup 0
    set models {}
    
    while {$node != ""} {

        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup
            }
            if {[$node GetID] == $modelgroup} {
                incr traversingModelGroup
            }
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup -1
            }
        }
        
        if {([string compare -length 8 $node "ModelRef"] == 0) && ($traversingModelGroup > 0)} {
            set m [SharedModelLookup [$node GetModelRefID]]
            lappend models $m
            if {($traversingModelGroup == 1) && ($changeExpansion >= 0)} {
                set Model($m,expansion) $changeExpansion
            }            
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}


#-------------------------------------------------------------------------------
# .PROC SharedGetModelsInGroupOnly
# Gets all the models in a model group (without dependent model groups).
# .ARGS
# int modelgroup the group where to get the dependent models from
# list umodels a list where the models are stored
# .END
#-------------------------------------------------------------------------------
proc SharedGetModelsInGroupOnly {modelgroup umodels} {
    global Model
    
    upvar $umodels models
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    set traversingModelGroup 0
    set models ""
    
    while {$node != ""} {
        if {[string equal -length 10 $node "ModelGroup"] == 1} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup
            }
            if {[$node GetID] == $modelgroup} {
                incr traversingModelGroup
            }
        }
        if {[string equal -length 13 $node "EndModelGroup"] == 1} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup -1
            }
        }
        
        if {([string equal -length 8 $node "ModelRef"] == 1) && ($traversingModelGroup == 1)} {
            set m [SharedModelLookup [$node GetModelRefID]]
            lappend models $m
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}


#-------------------------------------------------------------------------------
# .PROC SharedGetModelGroupsInGroup
# Gets all model groups which depend of a given model group.
# .ARGS
# int modelgroup container group
# int umodelgroups sub groups
# .END
#-------------------------------------------------------------------------------
proc SharedGetModelGroupsInGroup {modelgroup umodelgroups} {
    global Mrml(dataTree)
    
    upvar $umodelgroups mgs
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    set traversingModelGroup 0
    set mgs {}
    
    while {$node != ""} {

        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup
                lappend mgs [$node GetID]
            }
            if {[$node GetID] == $modelgroup} {
                incr traversingModelGroup
            }
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup -1
            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}
