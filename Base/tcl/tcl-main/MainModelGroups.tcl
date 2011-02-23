#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainModelGroups.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:54 $
#   Version:   $Revision: 1.15 $
# 
#===============================================================================
# FILE:        MainModelGroups.tcl
# PROCEDURES:  
#   MainModelGroupsCreateGUI f m hlevel
#   MainModelGroupsRefreshGUI mg c
#   MainModelGroupsPopupCallback
#   MainModelGroupsSetActive m
#   MainModelGroupsSetVisibility modelgroup value
#   MainModelGroupsSetOpacityInit m widget grouponly value
#   MainModelGroupsSetOpacity modelgroup grouponly
#   MainModelGroupsSetExpansion frame widget mg nochange recursionlevel
#   MainModelGroupsDeleteGUI f mg
#   MainModelGroupsDelete f mg
#   MainModelGroupsUpdateMRML mg
#   MainModelGroupsRestoreOldColors
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainModelGroupsCreateGUI
# Makes the popup menu that comes up when you right-click a model group.
# This is made for each new model group.
# .ARGS
# windowpath f where to create the gui elements
# int m model group id
# int hlevel hierarchy level
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsCreateGUI {f m {hlevel 0}} {
    global Gui ModelGroup Color

    set ModelGroup(frame) $f
    
    # sanity check
    if {[info command ModelGroup($m,node)] == ""} {
        puts "ERROR: MainModelGroupsCreateGUI: model group node $m does not exist, returning."
        return
    }

    # If the GUI already exists, then just change name.
    if {[info command $f.cg$m] != ""} {
        $f.cg$m config -text "[ModelGroup($m,node) GetName]"
        return 0
    }

    # Name / Visible
        
    eval {checkbutton $f.cg$m \
        -text [ModelGroup($m,node) GetName] -variable ModelGroup($m,visibility) \
        -width 17 -indicatoron 0 \
        -command "MainModelGroupsSetVisibility $m; Render3D"} $Gui(WCA)

    if {[info exist ModelGroup($m,colorID)] != 0} {
        $f.cg$m configure -bg [MakeColorNormalized \
                                   [Color($ModelGroup($m,colorID),node) GetDiffuseColor]]
        $f.cg$m configure -selectcolor [MakeColorNormalized \
                                            [Color($ModelGroup($m,colorID),node) GetDiffuseColor]]
    } else {
        puts "WARNING: no colour id exists for model group $m"
    }

    # Add a tool tip if the string is too long for the button
    if {[string length [ModelGroup($m,node) GetName]] > [$f.cg$m cget -width]} {
        TooltipAdd $f.cg$m "[ModelGroup($m,node) GetName]"
    }

    eval {checkbutton $f.hcg$m \
        -text "-" -variable ModelGroup($m,expansion) \
        -width 1 -indicatoron 0 \
        -command "MainModelGroupsSetExpansion $f $f.hcg$m $m; Render3D"} $Gui(WCA)
    
    eval {label $f.lg1_$m -text "" -width 1} $Gui(WLA)
    
    # menu
    eval {menu $f.cg$m.men} $Gui(WMA)
    set men $f.cg$m.men
    $men add command -label "Change Color..." -command \
        "MainModelGroupsSetActive $m; ShowColors MainModelGroupsPopupCallback"
    $men add command -label "-- Close Menu --" -command "$men unpost"
    bind $f.cg$m <Button-3> "$men post %X %Y"
    
    # Opacity
    eval {entry $f.eg${m} -textvariable ModelGroup($m,opacity) -width 3} $Gui(WEA)
    bind $f.eg${m} <Return> "MainModelGroupsSetOpacity $m 2; Render3D"
    bind $f.eg${m} <FocusOut> "MainModelGroupsSetOpacity $m 2; Render3D"
    eval {scale $f.sg${m} -from 0.0 -to 1.0 -length 40 \
        -variable ModelGroup($m,opacity) \
        -command "MainModelGroupsSetOpacityInit $m $f.sg$m 2" \
              -resolution 0.1} $Gui(WSA) {-sliderlength 14}
    if {[info exist ModelGroup($m,colorID)] != 0} {
        $f.sg${m} configure \
            -troughcolor [MakeColorNormalized \
                              [Color($ModelGroup($m,colorID),node) GetDiffuseColor]]
    }

    set l1_command $f.lg1_${m}
    set c_command $f.cg${m}

    for {set i 0} {$i<$hlevel} {incr i} {
        lappend l1_command "-"
    }
    
    for {set i 5} {$i>$hlevel} {incr i -1} {
        lappend c_command "-"
    }
    
    eval grid $l1_command $f.hcg${m} $c_command $f.eg${m} $f.sg${m} -pady 2 -padx 2 -sticky we
    if {$ModelGroup($m,expansion) == 1} {
        grid remove $f.eg${m} $f.sg${m}
    }
    
    foreach column {0 1 2 3 4 5} {
        # define a minimum size for each column, because otherwise
        # the empty columns used for building the tree would not
        # be drawn
        # maybe this should be moved some time to another procedure... (TODO)
        grid columnconfigure $f $column -minsize 8
    }

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsRefreshGUI
# Find the colour for the model group and configure the buttons and slider
# .ARGS
# int mg model group id
# int c colour node id
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsRefreshGUI {mg c} {
    global Model
    
    # Find the GUI components
    set f $Model(fScrolledGUI)
    set slider $f.sg$mg
    set button $f.cg$mg

    # Find the color for this model group
    if {$c != "" && [info command Color($c,node)] != ""} {
        set rgb [Color($c,node) GetDiffuseColor]
    } else {
        set rgb "1 1 1"
        if {$::Module(verbose)} { puts "MainModelGroupsRefreshGUI: setting rgb to 1 1 1" }
    }
    set color [MakeColorNormalized $rgb]

    # Color slider and colored checkbuttons
    # catch is important here, because the GUI variables for
    # model groups may have not been initialized yet
    ColorSlider $slider $rgb
    catch {$button configure -bg $color}
    catch {$button configure -selectcolor $color}

}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsPopupCallback
# Set the colours and expansions for the groups.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsPopupCallback {} {
    global Label ActiveModelGroup ModelGroup Color Model

    set mg $ActiveModelGroup
    if {$mg == ""} {return}

    ModelGroup($mg,node) SetColor $Label(name)
    
    set ModelGroup($mg,colorID) [lindex $Color(idList) 1]
    foreach c $Color(idList) {
        if {[Color($c,node) GetName] == $Label(name)} {
            set colorid $c
            set ModelGroup($mg,colorID) $c
        }
    }
    
    if {$ModelGroup($mg,expansion) == 0} {        
        # if the model group is collapsed, change the colors for all
        # dependent models
        SharedGetModelsInGroup $mg models
        foreach m $models {
            MainModelsSetColor $m $Label(name)
        }
    }
    
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsSetActive
# Set the active model group to the given id
# .ARGS
# int m model group id
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsSetActive {m} {
    global ActiveModelGroup
    
    set ActiveModelGroup $m
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsSetVisibility
# Set the visibility for all nodes in a group.
# .ARGS
# int modelgroup the model group id
# string value defaults to empty string, if set, is used as the visibility value
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsSetVisibility {modelgroup {value ""}} {
    global Model Module
    global Mrml(dataTree) ModelGroup

    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    set traversingModelGroup 0
    
    while {$node != ""} {

        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup
                set ModelGroup([$node GetID],visibility) $ModelGroup($modelgroup,visibility)
                $node SetVisibility $ModelGroup($modelgroup,visibility)
            }
            if {[$node GetID] == $modelgroup} {
                incr traversingModelGroup
                $node SetVisibility $ModelGroup($modelgroup,visibility)
            }
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup -1
            }
        }
        
        if {([string compare -length 8 $node "ModelRef"] == 0) && ($traversingModelGroup > 0)} {
            set m [SharedModelLookup [$node GetModelRefID]]
            if { $m == -1 } {
                puts "can't find model id for [$node GetModelRefID]"
                set node [Mrml(dataTree) GetNextItem]
                break
            }
            
            if {$value != ""} {
                set ModelGroup($modelgroup,visibility) $value
            }
            Model($m,node)  SetVisibility $ModelGroup($modelgroup,visibility)
            set Model($m,visibility) $ModelGroup($modelgroup,visibility)
            foreach r $Module(Renderers) {
                Model($m,actor,$r) SetVisibility [Model($m,node) GetVisibility] 
            }
            # If this is the active model, update GUI
            if {$m == $Model(activeID)} {
                set Model(visibility) [Model($m,node) GetVisibility]
            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsSetOpacityInit
# Sets the arguments to the MainModelGroupsSetOpacity command.
# .ARGS
# int m model group id
# windowpath widget the widget to configure
# boolean grouponly defaults to 0, argument to the command
# string value  defaults to empty string, not used
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsSetOpacityInit {m widget {grouponly 0} {value ""}} {

    $widget config -command "MainModelGroupsSetOpacity $m $grouponly; Render3D"
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsSetOpacity
# Set the opacity of the models in a model group
# .ARGS
# int modelgroup the id of the model group
# boolean grouponly flags diffferent setting behaviours 
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsSetOpacity {modelgroup {grouponly 0}} {
    global Model ModelGroup
    global Mrml(dataTree)

    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    set traversingModelGroup 0
    
    if {$grouponly == 2} {
        # special case: change opacity for the group only, if the group
        # is expanded; otherwise change it for each model in the group
        if {$ModelGroup($modelgroup,expansion) == 1} {
            set grouponly 1
        } else {
            set grouponly 0
        }
    }
    
    while {$node != ""} {

        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup
                if {$grouponly != 1} {
                    set ModelGroup([$node GetID],opacity) [format %#.1f $ModelGroup($modelgroup,opacity)]
                    $node SetOpacity $ModelGroup($modelgroup,opacity)
                }
            }
            if {[$node GetID] == $modelgroup} {
                incr traversingModelGroup
                $node SetOpacity $ModelGroup($modelgroup,opacity)
            }
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            if {$traversingModelGroup > 0} {
                incr traversingModelGroup -1
            }
        }
        
        if {([string compare -length 8 $node "ModelRef"] == 0) && ($traversingModelGroup > 0)} {
            if {$grouponly != 1} {
                set m [SharedModelLookup [$node GetModelRefID]]
                Model($m,node) SetOpacity $ModelGroup($modelgroup,opacity)
                $Model($m,prop,viewRen) SetOpacity [Model($m,node) GetOpacity]
                set Model($m,opacity) [format %#.1f $ModelGroup($modelgroup,opacity)]
                # If this is the active model, update GUI
                if {$m == $Model(activeID)} {
                    set Model(opacity) [Model($m,node) GetOpacity]
                }
            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsSetExpansion
# Expand model groups in the gui.
# .ARGS
# windowpath frame the base gui frame 
# windowpath widget the widget that we're configuring
# int mg model group id
# int nochange defaults to 0
# int recursionlevel starts at zero, increment with each call 
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsSetExpansion {frame widget mg {nochange 0} {recursionlevel 0}} {
    global ModelGroup Model OldColors OldOpacities RemovedModels

    if {$::Module(verbose)} {
        puts "MainModelGroupsSetExpansion start: mg = $mg"
    }
    if {$ModelGroup($mg,expansion) == 0} {
        ModelGroup($mg,node) SetExpansion 0
        # catch is necessary, because sometimes the widget parameter is empty
        # (especially when this procedure is called during a recursion)        
        catch {$widget config -text "+"}
        grid $frame.eg$mg $frame.sg$mg
        set models {}
        set modelgroups {}
        if {!$nochange} {
            SharedGetModelsInGroup $mg models 0
        } else {
            SharedGetModelsInGroup $mg models
        }
        SharedGetModelGroupsInGroup $mg modelgroups
        foreach m $models {
            if {$RemovedModels($m) == 0} {
                grid remove $frame.l1_$m $frame.c$m $frame.e$m $frame.s$m
                set OldColors($m) [Model($m,node) GetColor]
                set OldOpacities($m) [Model($m,node) GetOpacity]
                set RemovedModels($m) 1
            }
            MainModelsSetColor $m [ModelGroup($mg,node) GetColor]
            MainModelsSetOpacity $m [ModelGroup($mg,node) GetOpacity]
        }
        foreach m $modelgroups {
            grid remove $frame.lg1_$m $frame.hcg$m $frame.cg$m $frame.eg$m $frame.sg$m
        }
    } else {
        ModelGroup($mg,node) SetExpansion 1
        # catch is necessary, because sometimes the widget parameter is empty
        # (especially when this procedure is called during a recursion)
        catch {$widget config -text "-"}
        grid remove $frame.eg$mg $frame.sg$mg
        set models {}
        set modelgroups {}
        if {!$nochange} {
            SharedGetModelsInGroup $mg models 1
        } else {
            SharedGetModelsInGroup $mg models
        }
        SharedGetModelGroupsInGroup $mg modelgroups
        if {$::Module(verbose)} {
            puts "MainModelGroupsSetExpansion: models in group $mg = $models, groups in this group = $modelgroups"
        }
        foreach m $models {
            if {($Model($m,expansion) == 1) && ($RemovedModels($m) == 1)} {
                # only show the models of expanded groups
                MainModelsSetColor $m $OldColors($m)
                MainModelsSetOpacity $m [format %#.1f $OldOpacities($m)]
                grid $frame.l1_$m $frame.c$m $frame.e$m $frame.s$m
                set RemovedModels($m) 0
            }
        }
        foreach m $modelgroups {
            if {$::Module(verbose)} { 
                puts "MainModelGroupsSetExpansion: recursing down for model group $m, current level = $recursionlevel"
            }
            grid $frame.lg1_$m $frame.hcg$m $frame.cg$m $frame.eg$m $frame.sg$m
            MainModelGroupsSetExpansion $frame "" $m 1 [expr $recursionlevel + 1]
        }
        
        # MainUpdateMRML
        # should be able to get away with only calling MainModeslUpdateMRML here    
            if {$recursionlevel == 0} {
                if {$::Module(verbose)} { 
                    puts "MainModelGroupsSetExpansion: about to call main models update mrml, expansion is 1" 
                }
                MainModelsUpdateMRML
            } else {
                if {$::Module(verbose)} {
                    puts "MainModelGroupsSetExpansion: skipping update mrml, recursion level = $recursionlevel"
                }
            }
    }
        
    Render3D
    ModelsConfigScrolledGUI $Model(canvasScrolledGUI) \
            $Model(fScrolledGUI)
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsDeleteGUI
# Destroy the tk widgets for this group
# .ARGS
# windowpath f the path to the group's widgets
# int mg the model group id
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsDeleteGUI {f mg} {

    # If the GUI is already deleted, return
    if {[info command $f.cg$mg] == ""} {
        return 0
    }

    # Destroy TK widgets
    destroy $f.cg$mg
    destroy $f.hcg$mg
    destroy $f.eg$mg
    destroy $f.sg$mg
    destroy $f.lg1_$mg

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsDelete
# Delete the tcl vars for this model group, and then call to delete the gui for it.
# .ARGS
# windowpath f the path to the group's widgets
# int mg the model group id
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsDelete {f mg} {
    global ModelGroup Gui

    foreach name [array names ModelGroup] {
        if {[string first "$mg," $name] == 0} {
            unset ModelGroup($name)
        }
    }

    MainModelGroupsDeleteGUI $f $mg
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsUpdateMRML
# Update model group mrml elements: delete groups in the 
# ModelGroup(idListDelete list) and set the opacity for each model group.
# .ARGS 
# int mg optional argument, if set, only update this group
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsUpdateMRML { { mg "-1" } } {
    global Model ModelGroup

    set f $Model(fScrolledGUI)

    if {$::Module(verbose)} {
        puts "MainModelGroupsUpdateMRML: mg = $mg"
    }

    
    # Delete any old model groups
    #--------------------------------------------------------
    foreach mgID $ModelGroup(idListDelete) {
        MainModelGroupsDelete $f $mgID
    }

    # Set the opacity for each model group
    #--------------------------------------------------------
    if {$mg != -1} {
        catch {MainModelGroupsSetOpacity $mg 1}
    } else {
        foreach mgID $ModelGroup(idList) {
            if {$::Module(verbose)} { 
                puts "MainModelGroupsUpdatemMRML: set group opacity for group $mgID" 
            }
            # second parameter "1" means: this group only, doesn't affect
            # anything that is below in the hierarchy
            catch {MainModelGroupsSetOpacity $mgID 1}
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelGroupsRestoreOldColors
# Goes through the list of models and makes sure that each one has its colour set
# to the OldColor($modelID) value, where it was saved when any model groups were 
# collapsed.<br>
# Called when saving a scene in MainMrmlWriteProceed, so that the model nodes 
# have the correct colours before they are written out. <br>
# Restore the colours via a call to MainModelGroupsSetExpansion if necessary.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelGroupsRestoreOldColors {} {
    global ModelGroup Model OldColors

    if {[llength $ModelGroup(idList)] > 0} {
        if {$::Module(verbose)} {
            puts "MainModelGroupsRestoreOldColors: Warning: some models may go back to original colours."
        }
    }
    foreach mg $ModelGroup(idList) {
        if {$ModelGroup($mg,expansion) == 0} {
            if {$::Module(verbose)} {
                puts "MainModelGroupsRestoreOldColors: found a collapsed model group $mg"
            }
            SharedGetModelsInGroup $mg modelList
            if {$::Module(verbose)} {
                puts "MainModelGroupsRestoreOldColors: models in group $mg = $modelList"
            }
            foreach m $modelList {
                if {[info exist OldColors($m)]} {
                    if {$::Module(verbose)} {
                        puts "MainModelGroupsRestoreOldColors: restoring colour for model mode $m: $OldColors($m)"
                    }
                    Model($m,node) SetColor $OldColors($m)
                } else {
                    if {$::Module(verbose)} {
                        puts "MainModelGroupsRestoreOldColors: WARNING: no saved old colour for model $m in group $mg"
                    }
                }
            }
        }
    }
}
