#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ModelHierarchy.tcl,v $
#   Date:      $Date: 2006/08/08 18:32:44 $
#   Version:   $Revision: 1.23 $
# 
#===============================================================================
# FILE:        ModelHierarchy.tcl
# PROCEDURES:  
#   ModelHierarchyInit
#   ModelHierarchyBuildGUI
#   ModelHierarchyRootEntry f
#   ModelHierarchyEnter
#   ModelHierarchyExit param
#   ModelHierarchyRedrawFrame
#   ModelHierarchyDeleteNode nodeType id
#   ModelHierarchyCreate
#   ModelHierarchyDeleteAsk widget
#   ModelHierarchyDelete
#   ModelHierarchyCreateGroup widget
#   ModelHierarchyCreateGroupOk name
#   ModelHierarchyDeleteModelGroup modelgroup
#   ModelHierarchyMoveModel id targetGroup modelgroup trg_modelgroup
#   ModelHierarchyDrag command args
#   ModelHierarchyAddModel modelID
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
#  This module enables the user to change the hierarchy of models.
#  If no hierarchy exists, a new one can be created.
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC ModelHierarchyInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyInit {} {
    global ModelHierarchy Module Volume Model
    
    # Define Tabs
    #------------------------------------
    # Description:
    #   Each module is given a button on the Slicer's main menu.
    #   When that button is pressed a row of tabs appear, and there is a panel
    #   on the user interface for each tab.  If all the tabs do not fit on one
    #   row, then the last tab is automatically created to say "More", and 
    #   clicking it reveals a second row of tabs.
    #
    #   Define your tabs here as shown below.  The options are:
    #   
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #
    set m ModelHierarchy
    set Module($m,row1List) "Help HDisplay"
    set Module($m,row1Name) "{Help} {Hierarchy}"
    set Module($m,row1,tab) HDisplay


    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Group models to create atlases."
    set Module($m,author) "Arne Hans, SPL, ahans@bwh.harvard.edu"
    set Module($m,category) "Visualisation"

    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources all *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #
    #   set Module($m,procVTK) ModelHierarchyBuildVTK
    #
    #   All the options are:
    #
    #   procGUI   = Build the graphical user interface
    #   procVTK   = Construct VTK objects
    #   procMRML  = Update after the MRML tree changes due to the creation
    #               of deletion of nodes.
    #   procEnter = Called when the user enters this module by clicking
    #               its button on the main menu
    #   procExit  = Called when the user leaves this module by clicking
    #               another modules button
    #   procCameraMotion = Called right before the camera of the active 
    #                      renderer is about to move 
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) ModelHierarchyBuildGUI
    set Module($m,procEnter) ModelHierarchyEnter
    set Module($m,procExit) ModelHierarchyExit
    set Module($m,procMainFileCloseUpdateEntered) ModelHierarchyMainFileClose

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) ""

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.23 $} {$Date: 2006/08/08 18:32:44 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #

    set ModelHierarchy(selectedModels) ""
    set ModelHierarchy(selectedGroups) ""
    set ModelHierarchy(moduleActive) 0
}


# NAMING CONVENTION:
#-------------------------------------------------------------------------------
#
# Use the following starting letters for names:
# t  = toplevel
# f  = frame
# mb = menubutton
# m  = menu
# b  = button
# l  = label
# s  = slider
# i  = image
# c  = checkbox
# r  = radiobutton
# e  = entry
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyBuildGUI {} {
    global Gui ModelHierarchy Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(ModelHierarchy,fStuff)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame ModelHierarchy:
    #-------------------------------------------
    # Help
    # HDisplay
    #   cEditor
    #     fModels
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The ModelHierarchy module displays the hierarchy of your models.  It also allows you to change the hierarchy, to delete it or to create a new one.<BR>
    To move a model to another model group, simply use drag and drop. You can also drop models on other models. In this case they will be inserted directly before the model on which they were dropped. Doing this, you can reorganize the order of your models in any way you like.<BR>
    You can also move whole model groups, but only to other model groups.<BR>
    If you would like to create a new group, click the respective button and enter the desired name.<BR>
    The buttons 'Create' and 'Delete' affect the whole hierarchy.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags ModelHierarchy $help
    MainHelpBuildGUI ModelHierarchy
    
    #-------------------------------------------
    # Hierarchy frame
    #-------------------------------------------
    set fHierarchy $Module(ModelHierarchy,fHDisplay)
    set f $fHierarchy
    pack configure $f -expand true -fill both

    # make canvas inside the Hierarchy frame
    canvas $f.cEditor -bg $Gui(activeWorkspace) -yscrollcommand "$f.sScrollBar set" -bd 0 -relief flat
    frame $f.fButtons -bg $Gui(activeWorkspace)
    eval "scrollbar $f.sScrollBar -orient vertical -command \"$f.cEditor yview\" $Gui(WSBA)"
    pack $f.fButtons -side bottom -fill x
    pack $f.sScrollBar -side right -fill y
    pack $f.cEditor -side top -fill both -expand true -padx 0 -pady $Gui(pad)
    $f.cEditor config -relief flat -bd 0

    #-------------------------------------------
    # Hierarchy->Editor canvas
    #-------------------------------------------
    set ModelHierarchy(ModelCanvas) $fHierarchy.cEditor
    set ModelHierarchy(ModelFrame) $ModelHierarchy(ModelCanvas).fModels
    set f $ModelHierarchy(ModelCanvas)
    
    frame $f.fModels -bg $Gui(activeWorkspace)
    $f create window 0 0 -anchor nw -window $f.fModels
    
    #-------------------------------------------
    # Hierarchy->Buttons frame
    #-------------------------------------------
    set f $fHierarchy.fButtons
    eval {button $f.bCreate -text "Create" -command "ModelHierarchyCreate"} $Gui(WBA)
    eval {button $f.bDelete -text "Delete" -command "ModelHierarchyDeleteAsk $f.bDelete"} $Gui(WBA)
    eval {button $f.bCreateGroup -text "Create group" -command "ModelHierarchyCreateGroup $f.bCreateGroup"} $Gui(WBA)
    eval {label $f.lTrash -text "T"} $Gui(WLA)
    grid $f.bCreate $f.bDelete $f.bCreateGroup $f.lTrash -padx $Gui(pad)
    #grid $f.bCreate $f.bDelete $f.bCreateGroup -padx $Gui(pad)
    TooltipAdd $f.bCreate "Create a new hierarchy"
    TooltipAdd $f.bDelete "Delete the hierarchy"
    TooltipAdd $f.bCreateGroup "Create a new model group"
    bindtags $f.lTrash [list DragDrop $f.lTrash Label . all]
}


#-------------------------------------------------------------------------------
# .PROC ModelHierarchyRootEntry
# Creates the entry for the root level of the hierarchy display.
# .ARGS
# windowpath f frame where the entry is created
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyCreateRootEntry {f} {
    global Gui
    
    frame $f.froot -bg $Gui(activeWorkspace)
    pack $f.froot -side top -fill x -expand true
    eval {label $f.lgroot -text "<root>"} $Gui(WLA)
    pack $f.lgroot -side left -in $f.froot
    bindtags $f.lgroot [list DragDrop $f.lroot Label . all]
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyEnter
# Called when this module is entered by the user. Creates the hierarchy display
# for the models.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyEnter {} {
    global ModelHierarchy Gui Module
    global ModelGroup
    global Mrml(dataTree)
        
    set HierarchyLevel 0
    set numModelLines 0
    set modelLineHeight 0
    set numGroupLines 0
    set groupLineHeight 0

    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    set f $ModelHierarchy(ModelFrame)
    
    set success 0
    
    # Drag and Drop bindings
    ModelHierarchyDrag init 0
    bind DragDrop {}
    bind DragDrop <ButtonPress-1>     [list ModelHierarchyDrag start %W]
    bind DragDrop <Motion>         [list ModelHierarchyDrag motion %X %Y]
    bind DragDrop <ButtonRelease-1>    [list ModelHierarchyDrag stop %X %Y]
    bind DragDrop <<DragOver>>    [list ModelHierarchyDrag over %W]
    bind DragDrop <<DragLeave>>    [list ModelHierarchyDrag leave %W]
    bind DragDrop <<DragDrop>>    [list ModelHierarchyDrag drop %W %X %Y]
        
    # search for collapsed model groups and expand them first
    while {$node != ""} {
        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            set mg [$node GetID]
            if {$ModelGroup($mg,expansion) == 0} {
                set ModelGroup($mg,expansion) 1
                MainModelGroupsSetExpansion $ModelGroup(frame) $ModelGroup(frame).hcg$mg $mg
            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }
    Render3D
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    while {$node != ""} {
        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            if {$success==0} {
                set success 1
                ModelHierarchyCreateRootEntry $f
            }
            incr HierarchyLevel
            switch $HierarchyLevel {
                1 {set color red}
                2 {set color brown}
                3 {set color purple}
                4 {set color yellow}
                default {set color red}
            }
            label $f.lg[$node GetID] -fg $color\
                -text "[$node GetName]" -font {-family helvetica -size 10 -weight bold}\
                        -bg $Gui(activeWorkspace)\
                        -bd 0 -padx 1 -pady 1 -relief flat 
            bindtags $f.lg[$node GetID] [list DragDrop $f.lg[$node GetID] Label . all]
            
            eval {label $f.l1g_[$node GetID] -text "" -width [expr ($HierarchyLevel-1)*2]} $Gui(WLA)
            frame $f.f1g_[$node GetID] -bg $Gui(activeWorkspace)
            set l1_command $f.l1g_[$node GetID]
            
            pack $f.f1g_[$node GetID] -side top -expand true -fill x
            pack $l1_command $f.lg[$node GetID] -in $f.f1g_[$node GetID] -side left
            lower $f.f1g_[$node GetID]
            incr numGroupLines
            if {$groupLineHeight == 0} {
                set groupLineHeight [expr {[winfo reqheight $f.lg[$node GetID]]}]
                if {$::Module(verbose)} {
                    puts "ModelHierarchyEnter: calculated height for group labels: $groupLineHeight"
                }
            }
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            incr HierarchyLevel -1
        }
        if {[string compare -length 8 $node "ModelRef"] == 0} {
            if {$success==0} {
                set success 1
                ModelHierarchyCreateRootEntry $f
                # add a line for the root entry
                incr numModelLines
                
            }
            set CurrentModelID [SharedModelLookup [$node GetModelRefID]]
            if {$CurrentModelID != -1} {
                if {[winfo exist $f.l$CurrentModelID] == 0} {
                    eval {label $f.l$CurrentModelID -text "[Model($CurrentModelID,node) GetName]"} $Gui(WLA)
                    bindtags $f.l$CurrentModelID [list DragDrop $f.l$CurrentModelID Label . all]
                    
                    frame $f.f1_$CurrentModelID -bg $Gui(activeWorkspace)
                    eval {label $f.l1_$CurrentModelID -text "" -width [expr ($HierarchyLevel)*2]} $Gui(WLA)
                    set l1_command $f.l1_$CurrentModelID
                    
                    pack $f.f1_$CurrentModelID -side top -expand true -fill x
                    pack $l1_command $f.l$CurrentModelID -in $f.f1_$CurrentModelID -side left
                    lower $f.f1_$CurrentModelID
                    incr numModelLines
                    if {$modelLineHeight == 0} {
                        # calc the label height
                        set modelLineHeight [expr {[winfo reqheight  $f.l$CurrentModelID]}]
                        if {$::Module(verbose)} {
                            puts "ModelHierarchyEnter: calculated height for model labels: $modelLineHeight"
                        }
                    }
                } else {
                    DevErrorWindow "Duplicate model reference number [$node GetModelRefID], cannot create interface"
                }
            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }
    
    set fb $Module(ModelHierarchy,fHDisplay).fButtons
    
    if {$success > 0} {
        # Find the height of a single label
        #set lastLabel $f.l$CurrentModelID
        # Find the height of a line
        #set incr [expr {[winfo reqheight $lastLabel]}]
        # Find the total height that should scroll and add some "safety space"
        # set height [expr {$numLines * $incr + 10}]
        set height [expr {$numGroupLines * $groupLineHeight + $numModelLines * $modelLineHeight + 10}]
        if {$::Module(verbose)} {
            puts "ModelHierarchyEnter: $numGroupLines * $groupLineHeight + $numModelLines * $modelLineHeight + 10 = $height"
        }
        $ModelHierarchy(ModelCanvas) config -scrollregion "0 0 1 $height"
        $ModelHierarchy(ModelCanvas) config -yscrollincrement $groupLineHeight -confine true
        $fb.bCreate config -state disabled
        $fb.bDelete config -state normal
        $fb.bCreateGroup config -state normal
    } else {
        # no hierarchy found
        $ModelHierarchy(ModelCanvas) config -scrollregion "0 0 0 0"
        eval {label $f.l -text "No hierarchy found."} $Gui(WLA)
        grid $f.l
        $fb.bCreate config -state normal
        $fb.bDelete config -state disabled
        $fb.bCreateGroup config -state disabled
    }

    set ModelHierarchy(moduleActive) 1
}


#-------------------------------------------------------------------------------
# .PROC ModelHierarchyExit
# Called when this module is exited by the user.
# .ARGS
# int param defaults to 1, if 1, destroy the models gui and then call models update
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyExit {{param 1}} {
    global ModelHierarchy Gui
    
    # destroy frame and create it again to delete all labels and buttons

    set f $ModelHierarchy(ModelCanvas)

    destroy $f.fModels
    frame $f.fModels -bd 0 -bg $Gui(activeWorkspace)
    $f create window 0 0 -anchor nw -window $f.fModels

    # update the hierarchy in the models tab

    if {$param == 1} {
        MainModelsDestroyGUI
        ModelsUpdateMRML
    }
    
    set ModelHierarchy(moduleActive) 0
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyRedrawFrame
# Redraws the model hierarchy view.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyRedrawFrame {} {
    ModelHierarchyExit 0
    ModelHierarchyEnter
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyDeleteNode
# A downsized copy of MainMrmlDeleteNode. Removes only the node's ID from idList and
# the node itself from the tree, doesn't call MainMrmlUpdate.
# .ARGS
# string nodeType 
# int id
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyDeleteNode {nodeType id} {
    global Mrml ModelRef ModelGroup EndModelGroup Hierarchy EndHierarchy

    upvar \#0 $nodeType Array

    MainMrmlClearList
    set Array(idListDelete) $id

    # Remove node's ID from idList
    set i [lsearch $Array(idList) $id]
    if {$i == -1} {return}
    set Array(idList) [lreplace $Array(idList) $i $i]

    # Remove node from tree, and delete it
    Mrml(dataTree) RemoveItem ${nodeType}($id,node)
    ${nodeType}($id,node) Delete
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyCreate
# Creates a new hierarchy
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyCreate {} {
    global Model ModelRef Hierarchy EndHierarchy ModelHierarchy
    
    if {[llength $Model(idList)] == 0} {
        DevErrorWindow "Cannot create a hierarchy without any models."
        return
    }
    set newHierarchyNode [MainMrmlAddNode "Hierarchy"]
    # set default values
    $newHierarchyNode SetType "MEDICAL"
    $newHierarchyNode SetHierarchyID "H1"
    
    # add all existing models to hierarchy
    foreach m $Model(idList) {
        set newModelRefNode [MainMrmlAddNode "ModelRef"]
        if {[Model($m,node) GetModelID] != ""} {
            $newModelRefNode SetModelRefID [Model($m,node) GetModelID]
        } else {
            # no model IDs yet, so create them
            $newModelRefNode SetModelRefID "M$m"
            Model($m,node) SetModelID "M$m"
        }
    }
    
    MainMrmlAddNode "EndHierarchy"
    
    if {$ModelHierarchy(moduleActive)==1} {
        ModelHierarchyRedrawFrame
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyDeleteAsk
# Asks for a confirmation of deleting the entire hierarchy
# .ARGS
# windowpath widget the parent to this popup
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyDeleteAsk {widget} {
    
    YesNoPopup important_question\
        [winfo rootx $widget]\
        [winfo rooty $widget]\
        "Do you really want to delete the hierarchy?" ModelHierarchyDelete
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyDelete
# Deletes the existing hierarchy
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyDelete {} {
    global ModelRef Hierarchy EndHierarchy ModelGroup EndModelGroup ModelHierarchy
    global Mrml(dataTree)
    
    MainModelsDestroyGUI
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    while {$node != ""} {
        if {[string compare -length 8 $node "ModelRef"] == 0} {
            ModelHierarchyDeleteNode "ModelRef" [$node GetID]
        }
        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            ModelHierarchyDeleteNode "ModelGroup" [$node GetID]
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            ModelHierarchyDeleteNode "EndModelGroup" [$node GetID]
        }
        if {[string compare -length 9 $node "Hierarchy"] == 0} {
            ModelHierarchyDeleteNode "Hierarchy" [$node GetID]
        }
        if {[string compare -length 12 $node "EndHierarchy"] == 0} {
            ModelHierarchyDeleteNode "EndHierarchy" [$node GetID]
        }
        
        set node [Mrml(dataTree) GetNextItem]
    }
    
    if {$ModelHierarchy(moduleActive)==1} {
        ModelHierarchyRedrawFrame
    }
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyCreateGroup
# Shows a dialog to ask for the name of a new model group.
# .ARGS
# windowpath widget the parent of this dialog
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyCreateGroup {widget} {
    global Gui

    if {[winfo exists .askforname] == 0} {
        set x [winfo rootx $widget]
        set y [winfo rooty $widget]
        toplevel .askforname -class Dialog -bg $Gui(activeWorkspace)
        wm title .askforname "New model group"
        wm geometry .askforname +$x+$y
        focus .askforname
        eval {label .askforname.l1 -text "Enter the name of the new group:"} $Gui(WLA)
        eval {entry .askforname.e1} $Gui(WEA)
        eval {button .askforname.bOk -text "Ok" -width 8 -command "ModelHierarchyCreateGroupOk"} $Gui(WBA)
        eval {button .askforname.bCancel -text "Cancel" -width 8 -command "destroy .askforname"} $Gui(WBA)
        grid .askforname.l1
        grid .askforname.e1
        grid .askforname.bOk .askforname.bCancel -padx 5 -pady 3
        focus .askforname.e1
        
        # make the dialog modal
        update idle
        grab set .askforname
        tkwait window .askforname
        grab release .askforname
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyCreateGroupOk
# Creates a new model group.
# .ARGS
# string name defaults to empty string, the name of the new group.
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyCreateGroupOk {{name ""}} {
    global Mrml ModelGroup Color ModelHierarchy
    
    
    Mrml(dataTree) InitTraversal
    set tmpnode [Mrml(dataTree) GetNextItem]
    
    while {$tmpnode != ""} {
        if {[string compare -length 12 $tmpnode "EndHierarchy"] == 0} {
            break
        }
        set tmpnode [Mrml(dataTree) GetNextItem]
    }
    
    set node [MainMrmlInsertBeforeNode $tmpnode "ModelGroup"]
    set newID [$node GetID]
    $node SetModelGroupID G$newID

    # Set some ModelGroup properties
    set ModelGroup($newID,visibility) [$node GetVisibility]
    set ModelGroup($newID,opacity) [format %#.1f [$node GetOpacity]]
    set ModelGroup($newID,expansion) [$node GetExpansion]

                                    
    # Need to find the first existing colour node, that's not named black.
    # There might not be a colour node with the id 0, and a black 
    # background makes the text unreadable.
    set nodenum 0
    while {[info command Color($nodenum,node)] == "" ||
           [Color($nodenum,node) GetName] == "Black"} { 
        incr nodenum 
        if {$nodenum > 1024} {
            DevErrorWindow "ModelHierarchyCreateGroupOk:\nCan't find a colour node after testing 1k nodes.\nLoad some colours via the Colors module."
            return
        }
    }
    if {$::Module(verbose)} {
        puts "first valid colour node number = $nodenum, named [Color($nodenum,node) GetName]"
    }
    $node SetColor [Color($nodenum,node) GetName]
    set ModelGroup($newID,colorID) $nodenum


    if {$name==""} {
        $node SetName [.askforname.e1 get]
    } else {
        $node SetName $name
    }
    
    MainMrmlInsertBeforeNode $tmpnode "EndModelGroup"

    if {($name=="") && ($ModelHierarchy(moduleActive)==1)} {
    # only update GUI if called from ModelHierarchyCreateGroup without a name parameter
        destroy .askforname
        ModelHierarchyRedrawFrame

        $ModelHierarchy(ModelCanvas) yview moveto 1.0
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyDeleteModelGroup
# Deletes a model group.
# .ARGS
# int modelgroup the id of the model group that is to be deleted
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyDeleteModelGroup {modelgroup} {
    global Mrml ModelGroup EndModelGroup Model ModelHierarchy
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    set depth -1
    
    while {$node != ""} {
        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            if {([$node GetID] == $modelgroup) && ($depth == -1)} {
                # the model group is found
                set depth 0
                MainModelGroupsDeleteGUI $Model(fScrolledGUI) [$node GetID]
                ModelHierarchyDeleteNode ModelGroup [$node GetID]
            } else {
                if {$depth > -1} {incr depth}
            }
        }
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            if {$depth == 0} {
                # found the right EndModelGroup node
                ModelHierarchyDeleteNode EndModelGroup [$node GetID]
                set depth -1
            } else {
                if {$depth>-1} {incr depth -1}
            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }
    
    if {$ModelHierarchy(moduleActive)==1} {
        ModelHierarchyRedrawFrame
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyMoveModel
# Moves a model (group) from one model group to another
# .ARGS
# int id id of the model
# string targetGroup name of the target model group
# int modelgroup is different from 0 if a modelgroup is moved
# int trg_modelgroup defaults to 1, the target model group id
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyMoveModel {id targetGroup src_modelgroup {trg_modelgroup 1}} {
    global Mrml ModelRef Model ModelGroup EndModelGroup Color ModelHierarchy
    
    # destroy the whole models gui before doing any changes, because model id's
    # and model group id's won't remain the same and MainModelsDestroyGUI depends
    # on these id's
    
    MainModelsDestroyGUI
    
    # are we moving only one model or a whole group?
    if {$src_modelgroup == 0} {
        # move a single model only
        
        Mrml(dataTree) InitTraversal
        set node [Mrml(dataTree) GetNextItem]
        set depth -1
        
        set sourceModelID [Model($id,node) GetModelID]
                
        while {$node != ""} {
            if {[string compare -length 10 $node "ModelGroup"] == 0} {
                # are we moving to a model group?
                if {$trg_modelgroup == 1} {
                    # if we are moving the model to root, insert it
                    # before the first model group
                    if {$targetGroup == "<root>"} {
                        set newModelRefNode [MainMrmlInsertBeforeNode $node ModelRef]
                        $newModelRefNode SetModelRefID [Model($id,node) GetModelID]
                        set targetGroup ""
                    }
                    if {$depth < 0} {
                        if {[$node GetName] == $targetGroup} {
                            set depth 0
                        }
                    } else {
                        incr depth
                    }
                }
                # else don't care about modelgroups
            }
            if {[string compare -length 13 $node "EndModelGroup"] == 0} {
                if {$trg_modelgroup == 1} {
                    if {$depth == 0} {
                        set newModelRefNode [MainMrmlInsertBeforeNode $node "ModelRef"]
                        $newModelRefNode SetModelRefID [Model($id,node) GetModelID]
                    }
                    incr depth -1
                }
            }
            if {[string compare -length 8 $node "ModelRef"] == 0} {
                if {[$node GetModelRefID] == $sourceModelID} {
                    # remove this node
                    ModelHierarchyDeleteNode ModelRef [$node GetID]
                } else {
                    if {[Model([SharedModelLookup [$node GetModelRefID]],node) GetName] == $targetGroup} {
                        # insert new node here
                        set newModelRefNode [MainMrmlInsertBeforeNode $node ModelRef]
                        $newModelRefNode SetModelRefID $sourceModelID
                    }
                }
            }
            
            set node [Mrml(dataTree) GetNextItem]
        }
        
        if {$ModelHierarchy(moduleActive)==1} {
            ModelHierarchyRedrawFrame
    }
    } else {
        # move a complete model group
        
        # first step: copy the entire model group to a temporary mrml tree
        # and delete it from the original tree
        
        catch "tempTree Delete"
        vtkMrmlTree tempTree
        
        Mrml(dataTree) InitTraversal
        set node [Mrml(dataTree) GetNextItem]
        set depth -1
        set i 0
        
        while {$node != ""} {
            incr i
            if {[string compare -length 10 $node "ModelGroup"] == 0} {
                if {[$node GetID] == $id} {
                    # this is the model group to be moved
                    set depth 0
                }
                if {$depth >= 0} {
                    incr depth
                    set n ModelGroupTemp($i,node)
                    vtkMrmlModelGroupNode $n
                    $n SetModelGroupID [$node GetModelGroupID]
                    $n SetName [$node GetName]
                    $n SetDescription [$node GetDescription]
                    $n SetColor [$node GetColor]
                    $n SetVisibility [$node GetVisibility]
                    $n SetOpacity [$node GetOpacity]
                    tempTree AddItem $n
                    ModelHierarchyDeleteNode ModelGroup [$node GetID]
                }
            }
            if {[string compare -length 8 $node "ModelRef"] == 0} {
                if {$depth > 0} {
                    set n ModelRefTemp($i,node)
                    vtkMrmlModelRefNode $n
                    $n SetModelRefID [$node GetModelRefID]
                    tempTree AddItem $n
                    ModelHierarchyDeleteNode ModelRef [$node GetID]
                }
            }
            if {[string compare -length 13 $node "EndModelGroup"] == 0} {
                if {$depth > 0} {
                    incr depth -1
                    if {$depth == 0} {
                        set depth -1
                    }
                    set n EndModelGroupNodeTemp($i,node)
                    vtkMrmlEndModelGroupNode $n
                    tempTree AddItem $n
                    ModelHierarchyDeleteNode EndModelGroup [$node GetID]
                }
            }
            
            set node [Mrml(dataTree) GetNextItem]
        }
        
        # second step: find the target position in the actual mrml tree
        
        Mrml(dataTree) InitTraversal
        set node [Mrml(dataTree) GetNextItem]
        set success 0
        
        while {($node != "") && ($success == 0)} {
            if {([string compare -length 10 $node "ModelGroup"] == 0) && ($trg_modelgroup == 1)} {
                # if we are moving the group to root, insert it
                # before the first model group
                
                if {$targetGroup == "<root>"} {
                    set targetNode $node
                    set targetGroup ""
                    set success 1
                }
                if {[$node GetName] == $targetGroup} {
                    set targetNode [Mrml(dataTree) GetNextItem]
                    set success 1
                }
            }
            if {([string compare -length 8 $node "ModelRef"] == 0) && ($trg_modelgroup == 0)} {
                set modelid [SharedModelLookup [$node GetModelRefID]]
                if {[Model($modelid,node) GetName] == $targetGroup} {
                    set targetNode $node
                    set success 1
                }
            }
            set node [Mrml(dataTree) GetNextItem]
        }
        if {!$success} {
            DevWarningWindow "Can't move node here"
            return
        }
        # third step: insert the contents of the temporary tree at
        # the desired location of the actual mrml tree
        
        tempTree InitTraversal
        set node [tempTree GetNextItem]
        
        while {$node != ""} {
            if {[string compare -length 10 $node "ModelGroup"] == 0} {
                set newNode [MainMrmlInsertBeforeNode $targetNode ModelGroup]
                $newNode SetModelGroupID [$node GetModelGroupID]
                $newNode SetName [$node GetName]
                $newNode SetDescription [$node GetDescription]
                $newNode SetColor [$node GetColor]
                $newNode SetVisibility [$node GetVisibility]
                $newNode SetOpacity [$node GetOpacity]
                set newID [$newNode GetID]
                
                # Set some ModelGroup properties
                set ModelGroup($newID,visibility) [$newNode GetVisibility]
                set ModelGroup($newID,opacity) [format %#.1f [$newNode GetOpacity]]
                set ModelGroup($newID,expansion) [$newNode GetExpansion]
                set colorname [$newNode GetColor]
                set ModelGroup($newID,colorID) 0
                foreach c $Color(idList) {
                    if {[Color($c,node) GetName] == $colorname} {
                        set ModelGroup($newID,colorID) $c
                    }
                }
            }
            if {[string compare -length 13 $node "EndModelGroup"] == 0} {
                MainMrmlInsertBeforeNode $targetNode EndModelGroup
            }
            if {[string compare -length 8 $node "ModelRef"] == 0} {
                set newNode [MainMrmlInsertBeforeNode $targetNode ModelRef]
                $newNode SetModelRefID [$node GetModelRefID]
            }
            
            set node [tempTree GetNextItem]
        }
        
        # fourth step: remove all temporary nodes
        
        tempTree InitTraversal
        set node [tempTree GetNextItem]
        
        while {$node != ""} {
            $node Delete
            set node [tempTree GetNextItem]
        }
        
        if {$ModelHierarchy(moduleActive)==1} {
            ModelHierarchyRedrawFrame
    }
        #MainUpdateMRML
        
        tempTree RemoveAllItems
        tempTree Delete
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyDrag
# Handles the Drag and Drop functions
# .ARGS
# string command drag-and-drop command: init, start, motion, start, over, leave, drop
# list args arguments to the command
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyDrag {command args} {
    global _dragging
    global _lastwidget
    global _dragwidget
    global _dragcursor
    global ModelHierarchy
    
    switch $command {
        init {
            set _lastwidget 0
            set _dragging 0
        }
        
        start {
            set w [lindex $args 0]
            set _dragging 1
            set _lastwidget $w
            set _dragwidget $w
            set _dragcursor [$w cget -cursor]
            $w config -cursor target
            set ModelHierarchy(DragOriginalColor) [$w cget -fg]
            set ModelHierarchy(DragOverOriginalColor) 0
            $w config -fg blue
        }
        
        motion {
            if {!$_dragging} {return}
            
            set x [lindex $args 0]
            set y [lindex $args 1]
            set w [winfo containing $x $y]
            if {[info exists ModelHierarchy(ModelCanvasY)] == 0} {
                set ModelHierarchy(ModelCanvasYTop) [winfo rooty $ModelHierarchy(ModelCanvas)]
                set ModelHierarchy(ModelCanvasYBottom) [expr [winfo rooty $ModelHierarchy(ModelCanvas)]+[winfo height $ModelHierarchy(ModelCanvas)]]
            }
            # check if the canvas has to be scrolled
            if {$y<[expr $ModelHierarchy(ModelCanvasYTop)+10]} {
                if {[lindex [$ModelHierarchy(ModelCanvas) yview] 0] > 0} {
                    # scroll if there is something hidden at the top
                    # of the canvas
                    $ModelHierarchy(ModelCanvas) yview scroll -1 units
                }
            }
            if {$y>[expr $ModelHierarchy(ModelCanvasYBottom)-10]} {
                if {[lindex [$ModelHierarchy(ModelCanvas) yview] 1] < 1} {
                    # scroll if there is something hidden at the bottom
                    # of the canvas
                    $ModelHierarchy(ModelCanvas) yview scroll 1 units
                }
            }
            if {$w != $_lastwidget && [winfo exists $_lastwidget]} {
                event generate $_lastwidget <<DragLeave>>
            }
            set _lastwidget $w
            if {[winfo exists $w]} {
                event generate $w <<DragOver>>
            }
        }
        
        stop {
            if {!$_dragging} {return}
            set x [lindex $args 0]
            set y [lindex $args 1]
            set w [winfo containing $x $y]
            if {[winfo exists $w]} {
                $_dragwidget configure -fg $ModelHierarchy(DragOriginalColor)
                event generate $w <<DragLeave>>
                event generate $w <<DragDrop>> -rootx $x -rooty $y
            }
            set _dragging 0
        }
        
        over {
            if {!$_dragging} {return}
            set w [lindex $args 0]
            $w configure -relief raised
            if {$ModelHierarchy(DragOverOriginalColor) == 0} {
                set ModelHierarchy(DragOverOriginalColor) [$w cget -fg]
            }
            $w configure -fg green
        }
        
        leave {
            if {!$_dragging} {return}
            set w [lindex $args 0]
            $w configure -relief groove
            if {($ModelHierarchy(DragOverOriginalColor) != 0) && ($_dragwidget != $w)} {
                $w configure -fg $ModelHierarchy(DragOverOriginalColor)
            }
            set ModelHierarchy(DragOverOriginalColor) 0
        }
        
        drop {
            set w [lindex $args 0]
            set x [lindex $args 1]
            set y [lindex $args 2]
            $_dragwidget config -cursor $_dragcursor
            if {[string match {*lTrash} $_dragwidget]} {
                DevErrorWindow "You really can't move the trash!"
                return
            }
            if {[string match {*lTrash} $w]} {
                regexp {.*\.l(.+)$} $_dragwidget match SourceID
                if {![string match {g*} $SourceID]} {
                    DevErrorWindow "Models can't be deleted from the hierarchy."
                    return
                } else {
                    regexp {g(.+)} $SourceID match SourceGroupID
                    ModelHierarchyDeleteModelGroup $SourceGroupID
                }
                return
            }
            # don't move if source and target are equal
            if {$_dragwidget != $w} {
                # strip off the first part of the widget name
                regexp {.*\.l(.+)$} $_dragwidget match SourceID
                regexp {.*\.l(.+)$} $w match TargetGroupID
                
                # check if the target is a group or a model
                # and set the TargetGroup variable
                if {![string match {g*} $TargetGroupID]} {
                    regexp {(.+)} $TargetGroupID match TargetID
                    set TargetGroup [Model($TargetID,node) GetName]
                    set target_is_modelgroup 0
                } else {
                    regexp {g(.+)} $TargetGroupID match TargetID
                    set target_is_modelgroup 1
                    if {$TargetID == "root"} {
                        set TargetGroup "<root>"
                    } else {
                        set TargetGroup [ModelGroup($TargetID,node) GetName]
                    }
                }
                # check if we are moving a model group or just a single model
                set match ""
                regexp {g.+} $SourceID match
                if {$match == ""} {
                    # move a single model
                    # --> add it to the list of selected models
                    lappend ModelHierarchy(selectedModels) $SourceID
                } else {
                    # move a model group
                    # --> add it to the list of selected groups
                    regexp {g(.+)} $SourceID match SourceGroupID
                    if {$SourceGroupID == "root"} {
                        DevErrorWindow "Can't move root!"
                        return
                    }
                    lappend ModelHierarchy(selectedGroups) $SourceGroupID
                }
                
                # move all the selected models and groups
                
                foreach m $ModelHierarchy(selectedModels) {
                    ModelHierarchyMoveModel $m "$TargetGroup" 0
                }
                
                foreach mg $ModelHierarchy(selectedGroups) {
                    ModelHierarchyMoveModel $mg "$TargetGroup" 1 $target_is_modelgroup
                }
                
                # empty the list of selected groups and models
                set ModelHierarchy(selectedModels) ""
                set ModelHierarchy(selectedGroups) ""
            } else {
                # source and target are equal, so it's a single click on one model
                # --> select that model (or that model group)
                
                regexp {.*\.l(.+)$} $_dragwidget match SourceID
                
                if {[string match {g*} $SourceID]} {
                    # if it's a group, check for the id in ModelHierarchy(selectedGroups)
                    # and add it or delete it from the list
                    
                    regexp {g(.+)} $SourceID match SourceID
                    set index [lsearch -exact $ModelHierarchy(selectedGroups) $SourceID]
                    if {$index >= 0} {
                        set ModelHierarchy(selectedGroups) [lreplace $ModelHierarchy(selectedGroups) $index $index]
                        $w configure -font {-family helvetica -slant roman -weight bold}
                    } else {
                        lappend ModelHierarchy(selectedGroups) $SourceID
                        $w configure -font {-family helvetica -slant italic -weight bold}
                    }
                } else {
                    # if it's a model, check for the id in ModelHierarchy(selectedModels)
                    # and add it or delete it from the list
                    
                    set index [lsearch -exact $ModelHierarchy(selectedModels) $SourceID]
                    if {$index >= 0} {
                        set ModelHierarchy(selectedModels) [lreplace $ModelHierarchy(selectedModels) $index $index]
                        $w configure -font {-family helvetica -slant roman -weight bold}
                    } else {
                        lappend ModelHierarchy(selectedModels) $SourceID
                        $w configure -font {-family helvetica -slant italic -weight bold}
                    }
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyAddModel
# Adds a model to the hierarchy
# .ARGS
# int modelID ID of the model to be added
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyAddModel {modelID} {
    global Mrml ModelRef
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    
    while {$node != ""} {
        if {[string compare -length 12 $node "EndHierarchy"] == 0} {
            # insert the new model here
            set newNode [MainMrmlInsertBeforeNode $node "ModelRef"]
            $newNode SetModelRefID $modelID
        }
        set node [Mrml(dataTree) GetNextItem]
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelHierarchyMainFileClose
# clean up the hierarchy frame when the scene is closed
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelHierarchyMainFileClose {} {
    puts "ModelHierarchyMainFileClose"
    
    ModelHierarchyExit 1
}
