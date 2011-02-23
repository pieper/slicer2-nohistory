
proc ModelInteractionClipboardsInit {} {
    global ModelInteraction 

    set ModelInteraction(clipboardLastID) -1

    set ModelInteraction(gui,textBox,mode) ModelIDs

    set ModelInteraction(clipboardCurrentID) ""

    set ModelInteraction(clipboardIDList) ""

    set ModelInteraction(nameFromGUI) ""

}


proc ModelInteractionClipboardsBuildGUI {} {
    global Gui ModelInteraction Module Volume Model
    
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # 
    # Clipboards
    # 
    #-------------------------------------------

    #-------------------------------------------
    # Select frame
    #-------------------------------------------
    set fSelect $Module(ModelInteraction,fSelect)
    set f $fSelect
    
    foreach frame "Top Top1 Middle Middle2 Bottom1 Bottom2" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # Select->Top frame
    #-------------------------------------------
    set f $fSelect.fTop
    eval {label $f.lHelp -text "Hit \'s'\ to select, 'd' to deselect"} $Gui(WLA)
    pack $f.lHelp -side top


    #-------------------------------------------
    # Select->Top1 frame
    #-------------------------------------------
    set f $fSelect.fTop1
    DevAddButton $f.bClearSelected "Clear" ModelInteractionClearClipboard
    TooltipAdd $f.bClearSelected "Clear group."
    pack $f.bClearSelected -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $f.bHideSelected "Show/Hide" ModelInteractionToggleClipboardVisibility
    TooltipAdd $f.bHideSelected "Show or hide current group."
    pack $f.bHideSelected -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $f.bHighlightSelected "Highlight On/Off" ModelInteractionToggleClipboardHighlight
    TooltipAdd $f.bHighlightSelected "Display selected group with highlight or regular color."
    pack $f.bHighlightSelected -side left -padx $Gui(pad) -pady $Gui(pad)

    
    #-------------------------------------------
    # Select->Middle frame
    #-------------------------------------------
    set f $fSelect.fMiddle
    DevAddButton $f.bShowSelected "Show/Hide All" ModelInteractionToggleAllVisibility
    TooltipAdd $f.bShowSelected "Show or hide all models."
    pack $f.bShowSelected -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $f.bName "Name" ModelInteractionNameClipboard
    TooltipAdd $f.bName "Name current group."
    pack $f.bName -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $f.bNew "New" ModelInteractionAddClipboard
    TooltipAdd $f.bNew "Create a new group."
    pack $f.bNew -side left -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Select->Middle2 frame
    #-------------------------------------------
    set f $fSelect.fMiddle2

    DevAddButton $f.bExport "Export to Scene" ModelInteractionExportClipboardsToModelGroups
    TooltipAdd $f.bExport "Export all groups to ModelGroups MRML scene format. Then do File->Save Scene."
    pack $f.bExport -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $f.bImport "Import from Scene" ModelInteractionImportModelGroupsToClipboards
    TooltipAdd $f.bImport "Import groups from ModelGroups in MRML scene that you have loaded."
    pack $f.bImport -side left -padx $Gui(pad) -pady $Gui(pad)



    #-------------------------------------------
    # Select->Bottom1 frame
    #-------------------------------------------
    set f $fSelect.fBottom1
    
    eval {label $f.lClipboard -text "Group: "} $Gui(WLA)
    eval {menubutton $f.mbClipboard  \
              -relief raised -bd 2 -width 30 \
              -menu $f.mbClipboard.m} $Gui(WMBA)
    eval {menu $f.mbClipboard.m} $Gui(WMA)
    pack $f.lClipboard -side left -pady 1 -padx $Gui(pad)
    pack $f.mbClipboard -side right -pady 1 -padx $Gui(pad)

    # save menu to configure later
    set ModelInteraction(clipboardMenuButton) $f.mbClipboard
    set ModelInteraction(clipboardMenu) $f.mbClipboard.m

    # Add a tooltip
    TooltipAdd $f.mbClipboard "Groups of models you have selected"

    #-------------------------------------------
    # Select->Bottom2 frame
    #-------------------------------------------
    set f $fSelect.fBottom2
    
    # here's the text box widget from tcl-shared/Widgets.tcl
    set ModelInteraction(gui,textBox) [ScrolledText $f.tText]
    pack $f.tText -side top -pady $Gui(pad) -padx $Gui(pad) \
        -fill x -expand true


}

proc ModelInteractionGetCurrentClipboardID {} {

    global ModelInteraction

    set id $ModelInteraction(clipboardCurrentID)

    # in case we have no clipboard (it was deleted or 
    # does not exist yet), then add one.
    if {$id == ""} {
        ModelInteractionAddClipboard
        set id $ModelInteraction(clipboardCurrentID)

        # make sure the GUI is up to date
        ModelInteractionUpdateClipboardGui
        
    }

    return $id
}

proc ModelInteractionAddModelToClipboard {m} {
    global ModelInteraction
    
    set id [ModelInteractionGetCurrentClipboardID]

    if {$id == -1} {
        # make the first clipboard
        ModelInteractionAddClipboard
    }


    # Check if this model is already on the clipboard
    if {[lsearch -inline -sorted -integer $ModelInteraction(clipboard,$id) $m] != ""} {
        return
    }

    # If this is the first model, make it the default highlight color
    if {$ModelInteraction(clipboard,$id) == ""} {
        set ModelInteraction(clipboard,$id,clipboardColor) [Model($m,node) GetColor]
    } 

    lappend ModelInteraction(clipboard,$id) $m

    set ModelInteraction(clipboard,$id) \
        [lsort -integer $ModelInteraction(clipboard,$id)]

    ModelInteractionUpdateClipboardGui
    
}

proc ModelInteractionRemoveModelFromClipboard {m} {
    global ModelInteraction

    set id [ModelInteractionGetCurrentClipboardID]

    set ModelInteraction(clipboard,$id) \
        [lsearch -all -inline -sorted -integer -not -exact $ModelInteraction(clipboard,$id) $m]

    ModelInteractionUpdateClipboardGui
}

proc ModelInteractionUpdateClipboardGui {} {
    global ModelInteraction
    
    # clear the text box and put current list there
    $ModelInteraction(gui,textBox) delete 1.0 end

    # Find the current clipboard we are using
    set id [ModelInteractionGetCurrentClipboardID]

    # Either put numbers or model names, depending on
    # the mode
    set guiList ""
    switch $ModelInteraction(gui,textBox,mode) {
        "ModelIDs" {
            #$ModelInteraction(gui,textBox) insert end $ModelInteraction(clipboard,$id)
            # fix off by one error with regards to slicer internal IDs vs. model numbers
            # and model IDs in MRML file
            foreach m $ModelInteraction(clipboard,$id) {
                lappend guiList [Model($m,node) GetModelID]
            }
            $ModelInteraction(gui,textBox) insert end $guiList
        }
        "ModelNames" {
            foreach m $ModelInteraction(clipboard,$id) {
                lappend guiList [Model($m,node) GetName]
            }
            $ModelInteraction(gui,textBox) insert end $guiList
        }
    }

    # make sure the menu of clipboards is up to date
    $ModelInteraction(clipboardMenuButton) config -text \
        $ModelInteraction(clipboard,$id,name)

    set menu $ModelInteraction(clipboardMenu)
    $menu delete 0 end

    foreach id $ModelInteraction(clipboardIDList) {
        
        $menu add command -label $ModelInteraction(clipboard,$id,name) \
            -command "ModelInteractionSetActiveClipboard $id"
        
    }

}

proc ModelInteractionClearClipboard {} {

    global ModelInteraction Color Model Module

    ModelInteractionClipboardHighlightOff
    
    # remove all from clipboard
    set id [ModelInteractionGetCurrentClipboardID]
    set ModelInteraction(clipboard,$id) ""

    ModelInteractionUpdateClipboardGui

    Render3D
}


proc ModelInteractionDeleteEmptyClipboards {} {

    global ModelInteraction

    foreach id $ModelInteraction(clipboardIDList) {
        
        if {$ModelInteraction(clipboard,$id) == ""} {

            ModelInteractionSetActiveClipboard $id
            
            ModelInteractionDeleteClipboard
        }
    }
}

proc ModelInteractionDeleteClipboard {} {
    
    global ModelInteraction

    ModelInteractionClipboardHighlightOff
    
    # remove all from clipboard
    set id [ModelInteractionGetCurrentClipboardID]
    set ModelInteraction(clipboard,$id) ""
    
    set ModelInteraction(clipboard,$id,name) ""

    # remove from clipboard id list
    set ModelInteraction(clipboardIDList) \
        [lsearch -all -inline -integer -not -exact \
             $ModelInteraction(clipboardIDList) $id]

    # this removes clipboard pulldown menu contents
    ModelInteractionUpdateClipboardGui
}

proc ModelInteractionDeleteAllClipboards {} {

    global ModelInteraction Color Model Module

    foreach id $ModelInteraction(clipboardIDList) {
        
        ModelInteractionSetActiveClipboard $id

        ModelInteractionClipboardHighlightOff
        
        # remove all from clipboard
        set id [ModelInteractionGetCurrentClipboardID]
        set ModelInteraction(clipboard,$id) ""

        set ModelInteraction(clipboard,$id,name) ""
        
    }

    # clear list of clipboards
    set ModelInteraction(clipboardIDList) ""
    set ModelInteraction(clipboardCurrentID) ""
    set ModelInteraction(clipboardLastID) -1

    # this removes clipboard pulldown menu contents
    ModelInteractionUpdateClipboardGui

    Render3D
}

proc ModelInteractionAddModelGroup {groupName} {
    ModelHierarchyCreateGroupOk "$groupName"
}

proc ModelInteractionAddClipboard {} {

    global ModelInteraction

    incr ModelInteraction(clipboardLastID)
    
    set id $ModelInteraction(clipboardLastID)

    set ModelInteraction(clipboardCurrentID) $id

    lappend ModelInteraction(clipboardIDList) $id

    set ModelInteraction(clipboard,$id) ""
    set ModelInteraction(clipboard,$id,name) "Selection $id"

    # display this new clipboard
    ModelInteractionSetActiveClipboard $id

}


proc ModelInteractionBuildNameGui {} {

    global ModelInteraction

    catch {destroy .modelInteractionNameGUI}
    toplevel .modelInteractionNameGUI

    # put it somewhere near the mouse...
    wm geometry .modelInteractionNameGUI +20+200

    # clear the entry box
    set ModelInteraction(nameFromGUI) ""

    set f .modelInteractionNameGUI.name
    frame $f
    pack $f 
    label $f.label -text "Name:"
    pack $f.label -side left
    entry $f.name -textvariable ModelInteraction(nameFromGUI)
    pack $f.name -side left
    
    set f .modelInteractionNameGUI.apply
    frame $f
    pack $f 
    DevAddButton $f.bApply "Apply" \
        ModelInteractionNameClipboard
    pack $f.bApply 

}

proc ModelInteractionNameClipboard {{name ""}} {

    global ModelInteraction

    # if no name, pop up GUI, then call 
    # this procedure with the chosen name
    if {$name == ""} {

        # if the GUI was just used to select a name
        if {$ModelInteraction(nameFromGUI) != ""} {
            ModelInteractionNameClipboard $ModelInteraction(nameFromGUI) 
            set ModelInteraction(nameFromGUI) ""
            catch {destroy .modelInteractionNameGUI}
        } else {

            # else create the GUI to select a name
            ModelInteractionBuildNameGui

        }


    } else {

        # here we were called with an argument
        set id [ModelInteractionGetCurrentClipboardID]
        
        set ModelInteraction(clipboard,$id,name) $name
        
        ModelInteractionUpdateClipboardGui
    }

}



proc ModelInteractionSetActiveClipboard {id} {

    global ModelInteraction

    # turn off highlight of previous clipboard
    ModelInteractionClipboardHighlightOff

    set ModelInteraction(clipboardCurrentID) $id

    # turn on highlight of new clipboard
    ModelInteractionClipboardHighlightOn

    # display entries for this clipboard
    ModelInteractionUpdateClipboardGui

    # make these models visible
    ModelInteractionClipboardVisible
}



proc ModelInteractionAddClipboardToModelGroup {groupName} {

    global ModelInteraction

    set id [ModelInteractionGetCurrentClipboardID]

    foreach m $ModelInteraction(clipboard,$id) {
        ModelHierarchyMoveModel $m "$groupName" 0
    }
}

proc ModelInteractionExportClipboardsToModelGroups {} {

    global ModelInteraction

    puts "Deleting empty clipboards."

    ModelInteractionDeleteEmptyClipboards


    # check for duplicates.
    puts "Checking for models in more than one clipboard."
    set doneList ""
    set duplicateList ""

    foreach id $ModelInteraction(clipboardIDList) {
        foreach m $ModelInteraction(clipboard,$id) {
            
            # Have we seen this one already?
            # if so turn it red
            if {[lsearch -inline -integer $doneList $m] != ""} {
                lappend duplicateList $m
            } else {
                lappend doneList $m
            }
        }
    }
    
    if {$duplicateList != ""} {

        # make all invisible so you only see the error models
        ModelInteractionAllInVisible
        
        foreach m $duplicateList {
            set clipList ""
            foreach id $ModelInteraction(clipboardIDList) {
                if {[lsearch -inline -integer $ModelInteraction(clipboard,$id) $m] != ""} {
                    lappend clipList $ModelInteraction(clipboard,$id,name)
                }
            }
            puts "ERROR: Model $m is more than one clipboard: $clipList"
            puts "Repeated models will be displayed in a moment."
            MainModelsSetVisibility $m 1
            Render3D
        }

        return
    }


    # this function in ModelHierarchy.tcl deletes any existing model hierarchy
    # it is very slow since it deletes part of the GUI
    puts "Deleting any old model hierarchy."
    ModelHierarchyDelete
    
    # this function in ModelHierarchy.tcl creates a new model hierarchy
    #ModelHierarchyCreate

    puts "Creating new hierarchy."
    set newHierarchyNode [MainMrmlAddNode "Hierarchy"]
    # set default values
    $newHierarchyNode SetType "MEDICAL"
    $newHierarchyNode SetHierarchyID "H1"
    
    # add all existing models to hierarchy
    #foreach m $Model(idList) {
    #    set newModelRefNode [MainMrmlAddNode "ModelRef"]
    #
    #}
    
    # Now we add nodes to the hierarchy
    foreach id $ModelInteraction(clipboardIDList) {

        set node [MainMrmlAddNode "ModelGroup"]
        set newID [$node GetID]
        $node SetModelGroupID G$newID

        $node SetColor $ModelInteraction(clipboard,$id,clipboardColor)

        $node SetName $ModelInteraction(clipboard,$id,name)
        
        foreach m $ModelInteraction(clipboard,$id) {

            set newModelRefNode [MainMrmlAddNode "ModelRef"]

            if {[Model($m,node) GetModelID] != ""} {
                $newModelRefNode SetModelRefID [Model($m,node) GetModelID]
            } else {
                # no model IDs yet, so create them
                $newModelRefNode SetModelRefID "M$m"
                Model($m,node) SetModelID "M$m"
            }
            #$newModelRefNode SetModelRefID [Model($m,node) GetModelID]

        }

         MainMrmlAddNode "EndModelGroup"
    }

    
    MainMrmlAddNode "EndHierarchy"

    MainUpdateMRML

    # Now here we make sure the models GUI is in sync.
    MainModelsDestroyGUI
    ModelsUpdateMRML

}


proc ModelInteractionImportModelGroupsToClipboards {} {

    global ModelInteraction Model

    # find the beginning of the hierarchy on the tree
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    set found 0

    while {$node != ""} {
        if {[string compare -length 9 $node "Hierarchy"] == 0} {
            set found 1
            break
        }
        set node [Mrml(dataTree) GetNextItem]
    }

    if {$found == 0} {
        puts "No model hierarchy found."
        return
    } else {
        puts "Found a hierarchy"
    }
    
    # Find out the model ref ID for each model (in case
    # these don't match slicer model IDs)
    foreach m $Model(idList) {
        lappend ModelRefIDList [Model($m,node) GetModelID]
    }
    

    # Now we have found one, make clipboards from it.
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        if {[string compare -length 12 $node "EndHierarchy"] == 0} {
            puts "Reached end of hierarchy"
            break
        }

        # this is a group in the hierarchy
        if {[string compare -length 10 $node "ModelGroup"] == 0} {

            # create new clipboard
            ModelInteractionAddClipboard
            ModelInteractionNameClipboard [$node GetName]

            # get all nodes in the group and put on a new clipboard

            set node [Mrml(dataTree) GetNextItem]
            while {$node != ""} {
                if {[string compare -length 13 $node "EndModelGroup"] == 0} {
                    puts "Reached end of group"
                    break
                }
                
                # put model onto clipboard.
                # this uses slicer model id #s so convert from model refs
                set mRef [$node GetModelRefID]
                set m [lsearch -exact $ModelRefIDList $mRef] 
                
                ModelInteractionAddModelToClipboard $m

                # get next node in this group or end of group node
                set node [Mrml(dataTree) GetNextItem]

            } ; # end loop over models in group

        } ; # end handling individual group

        # get next group node or end of hierarchy node

        set node [Mrml(dataTree) GetNextItem]
    }    ;# end looping over all groups in hierarchy
    

}


proc ModelInteractionExportClipboardsToTextFile {filename} {

    global ModelInteraction

    set fid [open $filename w]

    foreach id $ModelInteraction(clipboardIDList) {

        puts $fid "GROUP"
        puts $fid $ModelInteraction(clipboard,$id,name)
        
        foreach m $ModelInteraction(clipboard,$id) {

            puts $fid [Model($m,node) GetModelID]

        }


    }

    close $fid

}

