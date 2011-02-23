
# Don't use the improved MainColorsGetColorIDFromName.
# How annoying, this new function returns an ID rather than 
# the label value. So you *still* don't know what the voxel
# value is!!
proc LaurenThesisGetLabelValuesFromColorName {colorName} {
    
    global Color Mrml
    
    set tree Mrml(colorTree)
    set node [$tree InitColorTraversal]
    while {$node != ""} {
        set name [$node GetName]
        
        if {$name == $colorName} {
            
            # return list of labels that correspond to this color
            return [$node GetLabels]
            
        }
        
        set node [$tree GetNextColor]
    }
    return -1
}

proc LaurenThesisColorROIInit {} {

    global LaurenThesis Volume


    set LaurenThesis(vROI)  $Volume(idNone)

    set LaurenThesis(colorROI,colorBy) Model

}


proc LaurenThesisColorROIBuildGUI {} {

    global Gui LaurenThesis Module Volume Model

    #-------------------------------------------
    # ColorROI frame
    #-------------------------------------------
    set fColorROI $Module(LaurenThesis,fColorROI)
    set f $fColorROI
    
    foreach frame "Top Middle Bottom" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # ColorROI->Top frame
    #-------------------------------------------
    set f $fColorROI.fTop
    DevAddLabel $f.lHelp "Label voxels with tract clusters."
    pack $f.lHelp -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ColorROI->Middle frame
    #-------------------------------------------
    set f $fColorROI.fMiddle
    foreach frame "Volume ModelGroups ColorBy" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # ColorROI->Middle->Volume frame
    #-------------------------------------------
    set f $fColorROI.fMiddle.fVolume

    # menu to select a volume: will set LaurenThesis(vROI)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name vROI
    DevAddSelectButton  LaurenThesis $f $name "Region of interest:" Pack \
        "Volume in which to label voxels based on tract clusters."\
        25



    #-------------------------------------------
    # ColorROI->Middle->ModelGroups frame
    #-------------------------------------------
    set f $fColorROI.fMiddle.fModelGroups
    
    # menu to select a model group
    eval {label $f.lVis -text "Choose clusters:   "} $Gui(WLA)
    eval {menubutton $f.mbVis -text "All" \
              -relief raised -bd 2 -width 25 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis -side left -pady 1 -padx $Gui(pad)
    pack $f.mbVis -side right -pady 1 -padx $Gui(pad)

    # save menubutton for config
    set LaurenThesis(colorROI,modelGroupMenu) $f.mbVis

    # Add a tooltip
    TooltipAdd $f.mbVis "Color using all models or a model group"


    #-------------------------------------------
    # ColorROI->Middle->ColorBy frame
    #-------------------------------------------
    set f $fColorROI.fMiddle.fColorBy

    # menu defines whether we color by model group's color
    # or by the models' colors
    eval {label $f.lVis -text "Use colors from:   "} $Gui(WLA)
    eval {menubutton $f.mbVis -text "Each model" \
              -relief raised -bd 2 -width 25 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis -side left -pady 1 -padx $Gui(pad)
    pack $f.mbVis -side right -pady 1 -padx $Gui(pad)

    # save menubutton for config
    set LaurenThesis(colorROI,colorByMenu) $f.mbVis

    # Add a tooltip
    TooltipAdd $f.mbVis "Get voxel colors from each model, or from model group colors."

    # add menu
    set menu $LaurenThesis(colorROI,colorByMenu).m
    set menubutton $LaurenThesis(colorROI,colorByMenu)
    $menu add command  -label "Each model" -command \
        "set LaurenThesis(colorROI,colorBy) Model; $menubutton config -text {Each model}"
    $menu add command  -label "Model groups" -command \
        "set LaurenThesis(colorROI,colorBy) ModelGroups; $menubutton config -text {Model groups}"

    #-------------------------------------------
    # ColorROI->Bottom frame
    #-------------------------------------------
    set f $fColorROI.fBottom

    DevAddButton $f.bApply "Apply" \
        LaurenThesisColorROIValidateParametersAndApply
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Label voxels with cluster ID."

}



proc LaurenThesisColorROIEnter {} {

    global LaurenThesis Model

    # clear out old menu
    set menubutton $LaurenThesis(colorROI,modelGroupMenu)
    set LaurenThesis(colorROI,modelGroupName) All
    set LaurenThesis(colorROI,modelGroupIdx) -1
    $menubutton config -text "All"
    set menu $LaurenThesis(colorROI,modelGroupMenu).m
    $menu delete 0 end
    $menu add command -label "All" -command "set LaurenThesis(colorROI,modelGroupName) All; set LaurenThesis(colorROI,modelGroupIdx) -1; $menubutton config -text All"

    set LaurenThesis(colorROI,modelGroupNodes) ""

    # find all model groups in the hierarchy and put them on the menu
    
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

    #if {$found == 0} {
    #    puts "No model hierarchy found."
    #    return
    #} else {
    #    puts "Found a hierarchy"
    #}
    
    # Find out the model ref ID for each model (in case
    # these don't match slicer model IDs)
    foreach m $Model(idList) {
        lappend ModelRefIDList [Model($m,node) GetModelID]
    }
    

    
    # Now we have found a hierarchy, make menu items from it.
    set idx -1
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        if {[string compare -length 12 $node "EndHierarchy"] == 0} {
            #puts "Reached end of hierarchy"
            break
        }

        # this is a group in the hierarchy
        if {[string compare -length 10 $node "ModelGroup"] == 0} {

            # increment count of model groups
            incr idx 

            # save a pointer to this node
            lappend LaurenThesis(colorROI,modelGroupNodes) $node
            
            # put the node's name onto the menu
            set name [$node GetName]
            $menu add command -label $name -command "set LaurenThesis(colorROI,modelGroupName) \{$name\}; $menubutton config -text \{$name\}"

            # get all nodes in the group and record model IDs
            set LaurenThesis(colorROI,modelGroup,modelIDs,$name) ""

            set node [Mrml(dataTree) GetNextItem]
            while {$node != ""} {
                if {[string compare -length 13 $node "EndModelGroup"] == 0} {
                    #puts "Reached end of group"
                    break
                }
                
                # put model onto clipboard.
                # this uses slicer model id #s so convert from model refs
                set mRef [$node GetModelRefID]
                set m [lsearch -exact $ModelRefIDList $mRef] 
                
                # save the IDs of models in this group
                puts $m
                lappend LaurenThesis(colorROI,modelGroup,modelIDs,$name) $m

                # get next node in this group or end of group node
                set node [Mrml(dataTree) GetNextItem]

            } ; # end loop over models in group

        } ; # end handling individual group

        # get next group node or end of hierarchy node

        set node [Mrml(dataTree) GetNextItem]
    }    ;# end looping over all groups in hierarchy
    

}


proc LaurenThesisColorROIUpdateMRML {} {

    global LaurenThesis

    # Update volume selection widgets if the MRML tree has changed
    # the one at the end allows labelmaps too
    DevUpdateNodeSelectButton Volume LaurenThesis vROI vROI \
        DevSelectNode 0 0 1


}






proc LaurenThesisColorROIValidateParametersAndApply {} {
    global LaurenThesis Volume

    puts "----------------------------------------------"    

    puts "Validating parameters."

    puts "ROI volume ID: $LaurenThesis(vROI)"   

    if {$LaurenThesis(vROI) == $Volume(idNone) || $LaurenThesis(vROI) == ""} {
        puts "Please choose ROI volume to color."
        return
    }

    puts "Model group name (or ALL models):"
    set name $LaurenThesis(colorROI,modelGroupName)
    puts $name

    if {$name != "All"} {
        puts "Model group indices: $LaurenThesis(colorROI,modelGroup,modelIDs,$name)"
    }

    LaurenThesisColorROI $LaurenThesis(vROI) $LaurenThesis(colorROI,modelGroupName) $LaurenThesis(colorROI,colorBy)

}

proc LaurenThesisPrintModelGroups {} {

    global LaurenThesis
    
    foreach node $LaurenThesis(colorROI,modelGroupNodes) {
        set name [$node GetName]
        puts "$name: $LaurenThesis(colorROI,modelGroup,modelIDs,$name) "
    }

}


proc LaurenThesisColorROI {vROI modelGroupName colorBy} {

    global Model LaurenThesis

    # Cast ROI volume to short.
    # cast to short (as these are labelmaps the values are really integers
    # so this prevents errors with float labelmaps which come from editing
    # scalar volumes derived from the tensors).
    catch {vtkImageCast castVROI}
    castVROI SetOutputScalarTypeToShort
    castVROI SetInput [Volume($vROI,vol) GetOutput] 
    castVROI Update

    # The positioning is accounted for by the ROIToWorld so set
    # image origin to slicer convention. This fixes bugs
    # where origin was in the image data and in the transform, causing
    # misalignment with the fibers.
    [castVROI GetOutput] SetOrigin 0 0 0

    # create vtk object to do the coloring
    vtkColorROIFromPolyLines colorROI
    colorROI SetInputROIForColoring [castVROI GetOutput]
    
    # Loop through all models and put on a collection for input.
    # Also make a vtkIntArray with their label values in our
    # colormap.
    puts "Adding models to collection for input"
    vtkCollection modelCollection
    vtkIntArray modelLabels

    if {$modelGroupName == "All"} {
        set modelList $Model(idList)
    } else {
        set modelList $LaurenThesis(colorROI,modelGroup,modelIDs,$modelGroupName)
    }

    foreach m $modelList {
        puts $m
        modelCollection AddItem $Model($m,polyData)

        # Get labels for model or modelGroup color
        set labels [LaurenThesisGetLabelValuesFromColorName [Model($m,node) GetColor]]

        # Replace labels with model group color, if it's in a group
        # and the user wants to color by group.
        if {$colorBy  == "ModelGroups"} {

            # find the model group this one is in, if any
            foreach node $LaurenThesis(colorROI,modelGroupNodes) {

                set name [$node GetName]
                
                # get saved model IDs for this group
                set modelIDs $LaurenThesis(colorROI,modelGroup,modelIDs,$name)

                # if this model is on the list of IDs for this group
                if {[lsearch -inline -integer $modelIDs $m] != ""} {
                    # we have found the group.
                    # find its color now.
                    set labels [LaurenThesisGetLabelValuesFromColorName [$node GetColor]]
                }
            }
        }

        # use the first label as the array value
        modelLabels InsertNextValue [lindex $labels 0]
    }
    
    colorROI SetPolyLineClusters modelCollection
    colorROI SetLabels modelLabels

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($vROI,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    colorROI SetROIToWorld transform

    # The models are in world space so no need for another matrix

    # run the calculation
    puts "Calculating voxel labels from tract clusters."
    colorROI ColorROIFromStreamlines
    puts "Done calculating."
    puts "Exporting slicer volume to scene..."

    # export output to the slicer environment:
    # slicer MRML volume creation and display
    set output [colorROI GetOutputROIForColoring]
    set volumeName "TractColors_[Volume($vROI,node) GetName]"
    set v2 [DevCreateNewCopiedVolume $vROI "Color back from clusters" $volumeName]
    Volume($v2,vol) SetImageData $output
    # tell the node what type of data so MRML file will be okay
    Volume($v2,node) SetScalarType [$output GetScalarType]
    Volume($v2,node) SetLabelMap 1
    Volume($v2,node) InterpolateOff
    MainVolumesUpdate $v2


    # export output to the slicer environment:
    # slicer MRML volume creation and display
    set output2 [colorROI GetOutputMaxFiberCount]
    set volumeName "TractCount_[Volume($vROI,node) GetName]"
    set v3 [DevCreateNewCopiedVolume $vROI "Fiber count from clusters" $volumeName]
    Volume($v3,vol) SetImageData $output2
    # tell the node what type of data so MRML file will be okay
    Volume($v3,node) SetScalarType [$output2 GetScalarType]
    Volume($v3,node) SetLabelMap 0
    Volume($v3,node) InterpolateOn
    MainVolumesUpdate $v3

    # Registration
    # put the new volume inside the same transform as the original volume
    # by inserting it right after that volume in the mrml file
    # First remove it, then add it in the right place.
    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set widx 0} {$widx < $nitems} {incr widx} {
        if { [Mrml(dataTree) GetNthItem $widx] == "Volume($v2,node)" } {
            break
        }
    }
    if { $widx < $nitems } {
        Mrml(dataTree) RemoveItem $widx
        Mrml(dataTree) InsertAfterItem Volume($vROI,node) Volume($v2,node)
        MainUpdateMRML
    }

    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set widx 0} {$widx < $nitems} {incr widx} {
        if { [Mrml(dataTree) GetNthItem $widx] == "Volume($v3,node)" } {
            break
        }
    }
    if { $widx < $nitems } {
        Mrml(dataTree) RemoveItem $widx
        Mrml(dataTree) InsertAfterItem Volume($vROI,node) Volume($v3,node)
        MainUpdateMRML
    }

    # display this volume so the user knows something happened
    MainSlicesSetVolumeAll Fore $v2
    RenderAll

    # Clean up all objects
    castVROI Delete
    colorROI Delete
    modelCollection Delete
    modelLabels Delete
    catch {transform Delete}
    
    puts "Done labeling voxels from tracts. New volume name is $volumeName"
}





