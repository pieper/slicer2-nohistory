#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: OsteoPlan.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:00 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        OsteoPlan.tcl
# PROCEDURES:  
#   OsteoPlanInit
#   OsteoPlanBuildGUI
#   OsteoPlanEnter
#   OsteoPlanExit
#   OsteoPlanUpdateGUI
#   ResetOsteo
#   OsteoApplyCut
#   OsteoUncut
#   ExtractComponent
#   OsteoCopyModel
#   OsteoWriteComponent
#==========================================================================auto=
# OsteoPlan.tcl
# 1998 Peter C. Everett peverett@bwh.harvard.edu: Created
# 02/02/02 Krishna C. Yeshwant kcy@bwh.harvard.edu: Edited


#--------------
# OsteoPlanInit
#--------------

#-------------------------------------------------------------------------------
# .PROC OsteoPlanInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoPlanInit {} {
    global Module OsteoPlan Osteo Gui

    # Definine Tabs
    set m OsteoPlan
    set Module($m,row1List) "Help Landmarks Cut Reorient Rx"
    set Module($m,row1Name) "{Help} {Landmarks} {Cut} {Reorient} {Rx}"
    set Module($m,row1,tab) Cut

    # Define Procedures
    set Module($m,procGUI) OsteoPlanBuildGUI
    set Module($m,procMRML) OsteoPlanUpdateGUI
    set Module($m,procVTK) OsteoPlanBuildVTK
    set Module($m,procEnter) OsteoPlanEnter
    set Module($m,procExit) OsteoPlanExit

    # Define Dependencies
    set Module($m,depend) ""

    set Module($m,overview) "Provides model cutting tools"
    set Module($m,author) "Krishna Yeshwant, SPL, kcy@bwh.harvard.edu"
    set Module($m,category) "Application"


    # Set Version Info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.9 $} {$Date: 2006/01/06 17:57:00 $}]

    # Initialize module-level variables
    set Osteo(pointlabels) 1
    set Osteo(gui) 0
    set Osteo(edit,id) -1
    set Osteo(midsaggitalPointIDs) ""
    set Osteo(horizontalPointIDs) ""
    set Osteo(cutModelID) -1
    set Osteo(toolModelID) -2
    set Osteo(componentName) ""

    set Osteo(moveModelID) -1
    set Osteo(relModelID) -2

    # create bindings
#    OsteoPlanCreateBindings
###    When I placed these bindings, all the standard bindings
###    stopped working.  e.g. Couldn't rotate 3d image.
###    Declaring global binding here for now.
###    bind $Gui(fViewWin) <KeyPress-e> { ExtractComponent %W %x %y  }
}


#-------------------------------------------------------------------------------
# OsteoPlanBuildVTK
#    Builds the CellPicker and the Glyph3D objects to support point creation.
#-------------------------------------------------------------------------------
proc OsteoPlanBuildVTK {} {
    global Osteo
    
    set Osteo(picker) [vtkCellPicker Osteo(picker)]
    Osteo(picker) SetTolerance 0.001

    set Osteo(cutter) [vtkPolyBoolean Osteo(cutter)]
    set Osteo(cutResult) [vtkPolyData Osteo(cutResult)]
    set Osteo(filterA) [vtkTriangleFilter Osteo(filterA)]
    set Osteo(filterB) [vtkTriangleFilter Osteo(filterB)]
##
    set Osteo(cleanA) [vtkCleanPolyData Osteo(cleanA)]
    set Osteo(cleanB) [vtkCleanPolyData Osteo(cleanB)]
##
#    set Osteo(connectivity) [vtkPolyDataConnectivityFilter Osteo(connectivity)]
    set Osteo(writer) [vtkPolyDataWriter Osteo(writer)]
    Osteo(writer) SetFileTypeToBinary
##
    Osteo(filterA) SetInput [Osteo(cleanA) GetOutput]
    Osteo(filterB) SetInput [Osteo(cleanB) GetOutput]
##
    Osteo(cutter) SetOperation 0
    Osteo(cutter) SetInput [Osteo(filterA) GetOutput]
    Osteo(cutter) SetPolyDataB [Osteo(filterB) GetOutput]
}


#-------------------------------------------------------------------------------
# .PROC OsteoPlanBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoPlanBuildGUI {} {
    global Gui Module OsteoPlan Osteo Volume Model


    #---------------
    # Help Frame
    #---------------
    set help "
    This module is used by the MGH OMFS department.
    "
    MainHelpApplyTags OsteoPlan $help
    MainHelpBuildGUI OsteoPlan
    
    #-----------------
    # Landmark Frame
    #   Points button
    #   textbox
    #   break
    #-----------------
    set fLandmarks $Module(OsteoPlan,fLandmarks)
    set f $fLandmarks
    
    # Points Frame
    set f1 $f.fPoints
    set height 200
    frame $f1 -bg $Gui(activeWorkspace) -height $height \
        -borderwidth 2 -relief sunken


    #    Points button
    set c { menubutton $f1.mbPoints -menu $f1.mbPoints.m \
        -text "Points" -relief raised -bd 2 -width 8 $Gui(WMBA) }
    eval [subst $c]
    set c { menu $f1.mbPoints.m -tearoff 0 $Gui(WMA) -postcommand \
        {} }
    eval [subst $c]
    # these commands don't exist
    # foreach item { Update Import Export } {
    # $f1.mbPoints.m add command -label $item -command OPPoints$item
    # }
    $f1.mbPoints.m add checkbutton -label "Show Labels" \
        -variable Osteo(pointlabels) -onvalue 1 -offvalue 0 \
        -command { PointLabelVisibility $Osteo(pointlabels) }
    ## need to set to 1 by default      $f1.mbPoints.m select      

    
    #    Points scrolled listbox
    set Osteo(points,list) \
        [ScrolledListbox $f1.list 0 0 -width 40 -height 10]
    $Osteo(points,list) configure -selectforeground #ff0000
    
    pack $f1.mbPoints $f1.list -in $f1 -side top \
        -padx $Gui(pad) -pady $Gui(pad)
    
    

    # Modify Frame
    set f2 $f.fModify
    frame $f2 -borderwidth 2 -bg $Gui(activeWorkspace) -width 236

    #    Name label/textbox  (fed by Osteo(edit,name))
    set c { label $f2.lName -text "Name: " $Gui(WTA)}
    eval [subst $c]
    set c { entry $f2.eName -width 16 -textvariable Osteo(edit,name) \
        $Gui(WEA)} ; eval [subst $c]
    #    XYZ label/textbox   (fed by Osteo(edit,xyz))
    set c { label $f2.lXYZ -text "XYZ: " $Gui(WTA)}
    eval [subst $c]
    set c { entry $f2.eXYZ -width 30 -textvariable Osteo(edit,xyz) \
        $Gui(WEA)} ; eval [subst $c]
    #    Model label/Menu    (fed by SelectModelMenu procedure)
    set c { label $f2.lModel -text "Model: " $Gui(WTA)}
    eval [subst $c]
##    set mb [SelectModelMenu $f2 $Model(activeID) 1]
    
    #    Modify Frame Grid Organization
    grid $f2.lName $f2.eName -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f2.eName -sticky w
    grid $f2.lXYZ $f2.eXYZ -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $f2.eXYZ -sticky w
##    grid $f2.lModel $mb -padx $Gui(pad) -pady $Gui(pad) -sticky e
##    grid $mb -sticky w
    
    #    Apply button
    set c { button $f2.bApply -text "Apply" -width 6 $Gui(WBA) -command \
        "OsteoEndPointModify 1" }
    eval [subst $c]
    $f2.bApply config -bd 4 -relief groove
    
    #    Cancel button
    set c { button $f2.bCancel -text "Cancel" -width 7 $Gui(WBA) -command \
        "OsteoEndPointModify 0" }
    eval [subst $c]
    
    #    Apply/Cancel Grid Organization
    grid $f2.bApply $f2.bCancel -padx $Gui(pad) -pady $Gui(pad) -sticky {}
    

    pack $f1 -side top -padx $Gui(pad) -pady $Gui(pad) -in $f
    pack $f2 -side top -padx $Gui(pad) -pady $Gui(pad) -in $f

    # PLANES
#    frame $f.fPlanes -bg $Gui(activeWorkspace) -height $height \
#        -borderwidth 2 -relief sunken
    # LINES
#    frame $f.fLines -bg $Gui(activeWorkspace) -height $height \
#        -borderwidth 2 -relief sunken
#    pack $f.fPoints $f.fPlanes $f.fLines -side top -pady 2 -padx 2 \
#        -fill both
    
    
    
    

    #-----------------
    # Cut Frame
    #-----------------
    set f $Module(OsteoPlan,fCut)

    set c {label $f.lCutModel -text "Cut Model: " $Gui(WLA)}
    eval [subst $c]
    set c {label $f.lToolModel -text "With Model: " $Gui(WLA)}
    eval [subst $c]
    set mb1 [SelectModelMenu $f Osteo(cutModelID) 1]
    set mb2 [SelectModelMenu $f Osteo(toolModelID) 1]
    set c {checkbutton $f.bWithTool -text "With Tool" -indicatoron 0 \
        -width 10 -variable Osteo(useTool) $Gui(WCA) \
        -state disabled -command "OsteoToolCut"} ; eval [subst $c]

    set c { checkbutton $f.bCsys -text "Csys" -variable Measure(Csys,visible) \
        -width 6 -indicatoron 0 -command "MeasureSetCsysVisibility" $Gui(WCA) } ;  eval [subst $c]

    grid $f.lCutModel $mb1 -sticky n -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lToolModel $mb2 -sticky n -padx $Gui(pad) -pady $Gui(pad)
    grid $f.bWithTool -padx $Gui(pad) -pady $Gui(pad)
    grid $f.bCsys -padx $Gui(pad) -pady $Gui(pad)
    
    set c {button $f.bApply -text "Apply Cut" -width 11 $Gui(WBA) \
        -command "OsteoApplyCut"} ; eval [subst $c]
    
    set c {button $f.bUncut -text "Uncut" -width 11 $Gui(WBA) \
        -command "OsteoUncut"} ; eval [subst $c]
    
    set c {label $f.lComponent -text \
        "Position mouse & press 'C' to\nextract cut component." \
        $Gui(WLA)} ; eval [subst $c]
    
    set c {button $f.bComponent -text "Write:" $Gui(WBA) \
        -command OsteoWriteComponent -state disabled }
    eval [subst $c]
    set c {entry $f.eComponent -width 20 $Gui(WEA) \
        -textvariable Osteo(componentName)}
    eval [subst $c]
    
    grid $f.bApply $f.bUncut
    grid $f.lComponent -columnspan 2 -padx $Gui(pad) -pady $Gui(pad)
    grid $f.bComponent $f.eComponent -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Reorient frame
    #-------------------------------------------
    if { [info exists Xform(center)] == 0 } {
    set Xform(center) "0 0 0"
    set Xform(dist) "0"
    set Xform(axis) "0 0 0"
    set Xform(angle) "0"
    }
    set fReorient $Module(OsteoPlan,fReorient)
    set f $fReorient
    
    set c {label $f.lModel -text "Model: " $Gui(WLA)}
    eval [subst $c]
    set mb1 [SelectModelMenu $f $Osteo(moveModelID) 1]
    set c {label $f.lModel2 -text "W.R.T.: " $Gui(WLA)}
    eval [subst $c]
    set mb2 [SelectModelMenu $f $Osteo(relModelID) 1]
    grid $f.lModel $mb1 -sticky n -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lModel2 $mb2 -sticky n -padx $Gui(pad) -pady $Gui(pad)
    
    set c { label $f.lCenter -text "Center: " $Gui(WTA)}
    eval [subst $c]
    set c { entry $f.eCenter -width 24 -textvariable Xform(center) \
        $Gui(WEA)} ; eval [subst $c]
    
    set c { label $f.lAxis -text "Axis: " $Gui(WTA)}
    eval [subst $c]
    set c { entry $f.eAxis -width 24 -textvariable Xform(axis) \
        $Gui(WEA)} ; eval [subst $c]
    
    set c { label $f.lAngle -text "Angle: " $Gui(WTA)}
    eval [subst $c]
    set c { entry $f.eAngle -width 24 -textvariable Xform(angle) \
        $Gui(WEA)} ; eval [subst $c]
    
    set c { label $f.lDist -text "Dist: " $Gui(WTA)}
    eval [subst $c]
    set c { entry $f.eDist -width 24 -textvariable Xform(dist) \
        $Gui(WEA)} ; eval [subst $c]
    
    grid $f.lCenter $f.eCenter -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lAxis $f.eAxis -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lAngle $f.eAngle -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lDist $f.eDist -padx $Gui(pad) -pady $Gui(pad)
    

    #-------------------------------------------
    # Rx frame
    #-------------------------------------------
    set fRx $Module(OsteoPlan,fRx)
    set f $fRx
    set c { label $f.lStart -text "Distractor Placement:" $Gui(WTA)}
    eval [subst $c]
    set c { entry $f.eStart -width 30 -textvariable Osteo(startDistractor) \
        $Gui(WEA) } ; eval [subst $c]
    pack $f.lStart $f.eStart -padx $Gui(pad) -pady $Gui(pad)
    
    set Osteo(gui) 1
}

#-------------------------------------------------------------------------------
# .PROC OsteoPlanEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoPlanEnter {} {
    global OsteoPlan Gui
#   OsteoPlanPushBindings 
    ## binding events for OsteoPlan by appending to tkRegularEvents
    EvDeclareEventHandler tkRegularEvents <KeyPress-c> {
    ExtractComponent %W %x %y
    }

    EvDeclareEventHandler tkRegularEvents <KeyPress-e> {
    puts "test"
    }
    #    pushEventManager $OsteoPlan(eventManager)
}



#-------------------------------------------------------------------------------
# .PROC OsteoPlanExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoPlanExit {} {
#    popEventManager
###    OsteoPlanPopBindings
}



#-------------------------------------------------------------------------------
# .PROC OsteoPlanUpdateGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoPlanUpdateGUI {} {
    global Module Osteo Point Model

    #-------------------------------------------
    # Refresh Cutter
    #-------------------------------------------
    set fCut $Module(OsteoPlan,fCut)
    SelectModelMenu $fCut Osteo(cutModelID) 0
    SelectModelMenu $fCut Osteo(toolModelID) 0
    
}

#-------------------------------------------------------------------------------
# .PROC ResetOsteo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ResetOsteo {} {
    global Osteo

    Osteo(picker) Delete
    Osteo(cutter) Delete
    Osteo(cutResult) Delete
    Osteo(filterA) Delete
    Osteo(filterB) Delete
    Osteo(cleanA) Delete
    Osteo(cleanB) Delete
    Osteo(writer) Delete

    OsteoPlanBuildVTK
}

#-------------------------------------------------------------------------------
# .PROC OsteoApplyCut
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoApplyCut {} {
    global Osteo Model

    ResetOsteo
    
    set idA $Osteo(cutModelID)
    set idB $Osteo(toolModelID)
    
    puts "Entered OsteoApplyCut"

    puts [concat "Cut " $idA " with " $idB]

    if { $idA > -1 && $idB > -1 && $idA != $idB } {
    puts "Setup"

    puts "  Set FilterA"
    # Model($idA,mapper,viewRen) ISA vtkPolyData
    Osteo(filterA) SetInput [Model($idA,mapper,viewRen) GetInput]
    puts [concat "Model:" $idA [Model($idA,mapper,viewRen) GetInput]]
    puts "Render3d"
    Render3D

    puts "  Set FilterB"
    # Model($idB,mapper,viewRen) ISA vtkPolyData ISA vtkPolyData
    Osteo(filterB) SetInput [Model($idB,mapper,viewRen) GetInput]
    Osteo(filterB) Update

    puts [concat "Model:" $idB [Model($idB,mapper,viewRen) GetInput]]
    puts "Render3d"
    Render3D
    
##    Osteo(cutter) SetPolyDataB [Osteo(filterB) GetOutput]
    
    puts "  Set Transform of A"
    Osteo(cutter) SetXformA [Model($idA,actor,viewRen) GetMatrix]
    puts "Render3d"
    Render3D

    puts "  Set Transform of B"
    Osteo(cutter) SetXformB [Model($idB,actor,viewRen) GetMatrix]
    puts "Render3d"
    Render3D

    puts "  Set Mapper"
    Osteo(cutter) Update
    Model($idA,mapper,viewRen) SetInput [Osteo(cutter) GetOutput]

    puts "Render3d"
    Render3D

    puts "Update"
    Osteo(cutter) UpdateCutter

    puts "Render3d"
    Render3D

    puts "Initialize Cut Result"
    Osteo(cutResult) Initialize

    puts "Render3d"
    Render3D

    puts "CopyStructure"
    Osteo(cutResult) CopyStructure [Osteo(cutter) GetOutput]

    puts "Render3d"
    Render3D

    puts "Squeeze"
    Osteo(cutResult) Squeeze

    puts "Modified"
    Osteo(cutResult) Modified
    
    puts "Redefine Mapper"
    Model($idA,mapper,viewRen) SetInput Osteo(cutResult)

    puts "Render3d"
###    Render3D
    } else {
    puts "Cutting not defined."
    }

    puts "Leaving OsteoApplyCut"
}

#-------------------------------------------------------------------------------
# .PROC OsteoUncut
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoUncut {} {
    global Osteo Model
    
    set idA $Osteo(cutModelID)
    set idB $Osteo(toolModelID)
    if { $idA > -1 && $idB > -1 && $idA != $idB } {
    Model($idA,mapper,viewRen) SetInput [Osteo(filterA) GetOutput]
    #Model($idA,reader)
    Render3D
    }
}


#-------------------------------------------------------------------------------
# .PROC ExtractComponent
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ExtractComponent { widget x y } {
    global viewRen Point Model Osteo Module
    
    puts "Entering ExtractComponent: $widget $x $y"

    set f $Module(OsteoPlan,fCut)

    MeasureSetModelsPickable 1
    MeasureSetCsysPickable 0
    
    # replace Point(picker) with Select(picker) ???

    if { [SelectPick Osteo(picker) $widget $x $y] != 0 } {
    puts "Selected Actor"
    set actor [Osteo(picker) GetActor]
    set cellId [Osteo(picker) GetCellId]
    set nextID $Model(nextID)
    foreach id $Model(idList) {
        foreach r $Module(Renderers) {
        if { $actor == "Model($id,actor,$r)" } {
            puts [concat "SelectPicked id=" $id]
            ## actor = model selected by c-button-1
            vtkPolyDataConnectivityFilter cfilt
            cfilt SetInput [[$actor GetMapper] GetInput]
            cfilt SetExtractionModeToCellSeededRegions
            cfilt InitializeSeedList
            cfilt AddSeed $cellId
            cfilt Update
            OsteoCopyModel $id [cfilt GetOutput]
            $f.bComponent configure -state normal
            Osteo(writer) SetInput [cfilt GetOutput]
            cfilt Delete
        }
        }
    }
    }   
}




#-------------------------------------------------------------------------------
# .PROC OsteoCopyModel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoCopyModel { id pd {name ""} } {
    global OsteoPlan Model Mrml Label
    ### See models.tcl:865
    ### See ModelMaker:549
    ### See ModelMaker::ModelMakerWrite (line 518)

    # Create the model's MRML node
    set n [MainMrmlAddNode Model]
    $n SetName "Extracted_Model_$Model(nextID)"
    $n SetColor $Label(name)

    # Create the model
    set m [$n GetID]
    $n SetModelID M$m
    MainModelsCreate $m

    set OsteoPlan(extractedModelID) $m
    set OsteoPlan(extractedModelPD) $pd
    
    # Registration
    #    Model($m,node) SetRasToWld [Mrml(dataTree) GetNthModel $id]


    # If errors, delete model
    # MainModelsDelete $m
    # return

    MainUpdateMRML

    MainModelsSetActive $m
    set name [Model($m,node) GetName]
    tk_messageBox -message "The model '$name' has been created."

    Model($m,mapper,viewRen) SetInput $pd
    MainUpdateMRML
}







#-------------------------------------------------------------------------------
# SelectModelMenu
# Create/Update a Menu of Models
# Return the name of the menubutton for packing (in create mode)
# Selected ModelID is stored in variable (or -1 if <None>)
#-------------------------------------------------------------------------------
# fRoot    - frame in which the model menu will be placed (if create = 1)
# variable - where the selected model's id will be stored (or -1 if <none>)
# create   - if 1 then create new menu, if 0 (default) then update list of models in menu
proc SelectModelMenu { fRoot variable {create 0}} {
    global Gui Model Selected
    global Mrml(dataTree)
    
    # Handle global arrays or regular global variables
    set paren [string first "(" $variable]
    if { $paren == -1 } {
        global $variable
    } else {
        incr paren -1
        global [string range $variable 0 $paren]
    }
    
    set none "<None>"
    set mb $fRoot.mb$variable

    if { $create == 1 } {
        set c { menubutton $mb -text "$none" -relief raised -bd 2 -width 20 -menu $mb.m $Gui(WMBA) }
        eval [subst $c]
        
        set c { menu $mb.m $Gui(WMA) }
        eval [subst $c]
    }
    
    set m $mb.m
    $m delete 0 end


    foreach id $Model(idList) {
        set currModel [Mrml(dataTree) GetNthModel $id]
        if {$currModel == ""} {
            # TODO - this is an error condition, but it comes up when cutting
            # and pasting models in the mrml tree (Data)
            return;
        }
        set name [$currModel GetName]
        
        $m add radiobutton -label $name -indicatoron 0 \
            -variable $variable -value $id -command \
            "$mb config -text \"$name\""
    }
    
    
    $m add radiobutton -label $none -variable $variable -indicatoron 0 \
        -value -1 -command "$mb config -text \"$none\""
    
    set varID [subst $$variable]
    
    if { [lsearch $Model(idList) $varID] != -1 } {
        set currModel [Mrml(dataTree) GetNthModel $varID]
        set name [$currModel GetName]
        
        $mb config -text "$name"
    } else {
        $mb config -text "$none"
    }
    

    if { $create != 0 } {
        return $fRoot.mb$variable
    }

}









#proc OsteoCopyModel { id pd {name ""} } {
#    global Model Point Osteo Gui Module
#    global Mrml(dataTree)
#    
#    puts $id
#
#    set newID $Model(nextID)
#    incr Model(nextID)
#
#    foreach foo [array names Model $id,*] {
#    set pos [string first , $foo]
#    incr pos
#    set item [string range $foo $pos end]
#    set Model($newID,$item) $Model($foo)
#    }
#
##    set nextidx 1
##
##    set currModel [Mrml(dataTree) GetNthModel $nextidx]
##    set currName [$currModel GetName]
##
##    set nextname $currName_$nextidx
##    set tryagain 1
##    while { $tryagain == 1 } {
##    set tryagain 0
##    foreach mid $Model(idList) {
##        if { $nextname == $Model($mid,name) } {
##        set currModel [Mrml(dataTree) GetNthModel mid]
##        set currName [$currModel GetName]
##
##        incr nextidx
##        set nextname $name_$nextidx
##        set tryagain 1
##        }
##    }
##    }
#    
#    lappend Model(idList) $newID
#    set currModel [Mrml(dataTree) GetNthModel $newID]
#    set currName [$currModel GetName]
#
#    if { $name != "" } {
##    set Model($newID,name) $name
#    $currModel SetName $name
#    } else {
##    set Model($newID,name) $nextname
#    $currModel SetName $nextname
#    }
###    set Osteo(componentName) $Model($newID,name)
#    set Osteo(componentName) [$currModel GetName]
#    
#    foreach pid $Point(idList) {
#    set Point(model) $Model($newID,name)
#    if { $Point($pid,model) == $Model($id,name) } {
#        eval PointsNew $Point($pid,xyz) \
#            [append $Point($pid,name) _1]
#    }
#    }
#    
#    vtkPolyDataNormals Model($newID,normals)
#    Model($newID,normals) SplittingOff
#    Model($newID,normals) ConsistencyOff
#    Model($newID,normals) SetFeatureAngle 179
#    vtkPolyDataMapper Model($newID,mapper)
#    vtkActor Model($newID,actor)
#    Model($newID,normals) SetInput $pd
#    Model($newID,mapper) SetInput [Model($newID,normals) GetOutput]
#    Model($newID,actor) SetMapper Model($newID,mapper)
#    vtkTransform Model($newID,rasToWldTransform)
#    Model($newID,rasToWldTransform) SetMatrix \
#        [Model($id,rasToWldTransform) GetMatrix]
#    Model($newID,actor) SetUserMatrix \
#        [Model($newID,rasToWldTransform) GetMatrix]
#    vtkMatrix4x4 Model($newID,rasToRef)
#    Model($newID,rasToRef) DeepCopy Model($id,rasToRef)
#    set Model($newID,prop) [Model($newID,actor) GetProperty]
#    eval $Model($newID,prop) SetColor [$Model($id,prop) GetColor]
#    viewRen AddActor Model($newID,actor)
#    
#    # Add to GUI
#    ModelsAddGUI $Gui(wModels).fGrid $newID
#    ModelsAddGUI $Tabs(Models,fVisibility).fGrid $newID
#}

#-------------------------------------------------------------------------------
# .PROC OsteoWriteComponent
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OsteoWriteComponent {} {
    global OsteoPlan Module Gui Mrml Model Osteo

    # Based on ModelMaker::ModelMakerWrite

    # File dialog box
#    set m $Model(activeID)
    set m $OsteoPlan(extractedModelID)
    ##    set file_prefix [MainFileSaveModel $m $Osteo(componentName)]
    ##    if {$file_prefix == ""} {return}
    
    # Write
    Osteo(writer) SetInput $OsteoPlan(extractedModelPD)
    Osteo(writer) SetFileName $Osteo(componentName)
    Osteo(writer) Write
    puts $Osteo(componentName)
    #    MainModelsWrite $m $file_prefix
    
    MainModelsSetActive $m
}



