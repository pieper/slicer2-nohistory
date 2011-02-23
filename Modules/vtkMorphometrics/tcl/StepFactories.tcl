#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: StepFactories.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:59 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        StepFactories.tcl
# PROCEDURES:  
#   MorphometricsDoNothingOnEnterExit
#   MorphometricsNoUI frame
#   MorphometricsCreateVolumeChooserStep workflowName volumeNames volumeDistributor
#   MorphometricsCreateModelChooserStep workflowName modelNames modelDistributor
#   MorphometricsCreatePlanePlacementStep workflowName plane shortDescription instructions
#   MorphometricsCreateSpherePlacementStep workflowName sphere shortDescription instructions
#   MorphometricsCreateAxisPlacementStep workflowName axis shortDescription instructions
#   MorphometricsCreateCylinderPlacementStep workflowName cylinderSource cylinderSourceTransformFilter shortDescription instructions CustomUserInterface callOnEnter callOnExit
#   MorphometricsCreatePolyDataPlacementStep workflowName polyDataTransformFilter shortDescription instructions CustomUserInterface callOnEnter callOnExit
#   MorphometricsInitStepFactories
#   MorphometricsGenericPlaneDisplay plane
#   MorphometricsGenericPlaneUndisplay plane
#   MorphometricsGenericPlaneUI instructions frame
#   MorphometricsGenericCylinderUI cylinderSource customUI frame
#   MorphometricsGenericCylinderChangeRadius cylinderSource delta
#   MorphometricsGenericCylinderChangeHeight cylinderSource delta
#   MorphometricsGenericPolyDataDisplay polyDataTransformFilter userOnEnter
#   MorphometricsGenericPolyDataDisplay polyDataTransformFilter userOnExit
#   MorphometricsGenericPolyDataUI customUI instructions frame
#   MorphometricsModelChooserUI internalId frame
#   MorphometricsModelChooserOnEnter internalId
#   MorphometricsModelChooserOnExit internalId
#   MorphometricsVolumeChooserUI internalId frame
#   MorphometricsVolumeChooserOnEnter internalId
#   MorphometricsVolumeChooserOnExit internalId
#   MorphometricsGenericSphereDisplay sphere
#   MorphometricsGenericSphereUndisplay sphere
#   MorphometricsGenericSphereUI sphere instructions frame
#   MorphometricsGenericSphereChangeRadius sphere delta
#   MorphometricsGenericAxisDisplay axis
#   MorphometricsGenericAxisUndisplay axis
#   MorphometricsAlignPolydataWithCsys Polydata Center Orientation
#   MorphometricsUnAlignPolydataWithCsys
#   MorphometricsViewPolydata polydata
#   MorphometricsHidePolydata
#   MorphometricsViewPolydataWithCsys
#   MorphometricsHidePolydataWithCsys
#==========================================================================auto=

#=========================================================================
# Public Interface Description
# This file provides functions for generating some steps for the workflow
# module automatically. Specifically steps can be generated if
# - you want the user to specify a list of models 
# - you want the user to place a plane/sphere/cylinder/polydata in viewRen
#
# Generation of a step consists in the first case of specifying a list of model
# names as well as a function which gets called with the list of user choices for each model. 
# In the second case you have to specify the vtkObject, a short description
# of the step and a longer text where you can say how you want the user to place the vtkObject.


#-------------------------------------------------------------------------------
# .PROC MorphometricsDoNothingOnEnterExit
# Often enough, you don't want to do anything on enter/exit. Here is the 
# corresponding dummy function.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsDoNothingOnEnterExit {} {
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsNoUI
# A dummy user-interface build function. Either used as a default or when you're
# content with the generic user interface
# .ARGS
# str frame a user interface build function always accept a frame argument
# .END
#-------------------------------------------------------------------------------
proc MorphometricsNoUI {frame} {
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsCreateVolumeChooserStep
# Create a step in which the user can choose for a given list of names corresponding
# volumes. When the user goes to the next or previous step, a user specified function,
# namely the third argument, is called with a sole argument,a list of id's. 
# This id's are the ones the user has choosen for every entry in the name list. 
# The choice of the user for i-th element in $volumeNames is the i-th element in the 
# argument list for $volumeDistributor
# .ARGS
# str workflowName name of the workflow for which a volume choosing step should be added
# list volumeNames a list of names, for each element the user gets to choose a volume
# str volumeDistributor a function, called with a list of id's when the user leaves this step
# .END
#-------------------------------------------------------------------------------
proc MorphometricsCreateVolumeChooserStep {workflowName volumeNames volumeDistributor} {
    global Morphometrics Volume
    set nrChooser $Morphometrics(StepFactories,ModelChooser,Count)
    set Morphometrics(StepFactories,ModelChooser,Count) [expr 1 + $nrChooser]
    
    set Morphometrics(StepFactories,ModelChooser,$nrChooser,names) $volumeNames
    set Morphometrics(StepFactories,ModelChooser,$nrChooser,distributor) $volumeDistributor

    # preset to nothing choosen
    foreach iter $volumeNames {
    lappend Morphometrics(StepFactories,ModelChooser,$nrChooser,id) $Volume(idNone)
    }
    
    WorkflowAddStep $workflowName [list [subst -nocommand {MorphometricsVolumeChooserOnEnter $nrChooser}]] [list [subst -nocommand {MorphometricsVolumeChooserOnExit $nrChooser}]]  [list [subst -nocommand {MorphometricsVolumeChooserUI $nrChooser}]] "Choose Volume(s)"
}
#-------------------------------------------------------------------------------
# .PROC MorphometricsCreateModelChooserStep
# Create a step in which the user can choose for a given list of names corresponding
# models. When the user goes to the next or previous step, a user specified function,
# namely the third argument, is called with a sole argument,a list of id's. 
# This id's are the ones the user has choosen for every entry in the name list. 
# The choice of the user for i-th element in $modelNames is the i-th element in the 
# argument list for $modelDistributor
# .ARGS
# str workflowName name of the workflow for which a model choosing step should be added
# list modelNames a list of names, for each element the user gets to choose a model
# str modelDistributor a function, called with a list of id's when the user leaves this step
# .END
#-------------------------------------------------------------------------------
proc MorphometricsCreateModelChooserStep {workflowName modelNames modelDistributor} {
    global Morphometrics Model
    set nrChooser $Morphometrics(StepFactories,ModelChooser,Count)
    set Morphometrics(StepFactories,ModelChooser,Count) [expr 1 + $nrChooser]
    
    set Morphometrics(StepFactories,ModelChooser,$nrChooser,names) $modelNames
    set Morphometrics(StepFactories,ModelChooser,$nrChooser,distributor) $modelDistributor

    # preset to nothing choosen
    foreach iter $modelNames {
    lappend Morphometrics(StepFactories,ModelChooser,$nrChooser,id) $Model(idNone)
    }
    
    WorkflowAddStep $workflowName [list [subst -nocommand {MorphometricsModelChooserOnEnter $nrChooser}]] [list [subst -nocommand {MorphometricsModelChooserOnExit $nrChooser}]]  [list [subst -nocommand {MorphometricsModelChooserUI $nrChooser}]] "Choose Model(s)"
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsCreatePlanePlacementStep
# Given a vtkPlaneSource, this function creates the whole user interface in which
# the user can place the plane according to the provided instructions.
# This function updates the normal and the center of the plane when the user
# leaves the step.
# .ARGS
# str workflowName name of the workflow to which this function should add a step
# str plane object of type vtkPlaneSource
# str shortDescription A concise description where the user should place a plane.
# str instructions A longer text, explaining to the user how the plane should be placed.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsCreatePlanePlacementStep {workflowName plane shortDescription instructions} {
    WorkflowAddStep $workflowName [list [subst -nocommand {MorphometricsGenericPlaneDisplay $plane}]] [list [subst -nocommand {MorphometricsGenericPlaneUndisplay $plane}]] [list [subst -nocommand {MorphometricsGenericPlaneUI [list $instructions]}]] $shortDescription
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsCreateSpherePlacementStep
# Given a vtkSphereSource, this function creates the whole user interface in which
# the user can place the sphere according to the provided instructions.
# Furthermore an interface is provided for the user to adjust the radius of the
# sphere. The radius gets updated whenever the user adjusts the radius whereas
# the center of the sphere gets updated when the user leaves the step.
# .ARGS
# str workflowName name of the workflow to which this function should add a step
# str sphere object of type vtkSphereSource
# str shortDescription A concise description where the user should place the sphere
# str instructions A longer text, explaining to the user how the sphere should be placed.
# .END 
#-------------------------------------------------------------------------------
proc MorphometricsCreateSpherePlacementStep {workflowName sphere shortDescription instructions} {
    WorkflowAddStep $workflowName [list [subst -nocommand {MorphometricsGenericSphereDisplay $sphere}]] [list [subst -nocommand {MorphometricsGenericSphereUndisplay $sphere}]] [list [subst -nocommand {MorphometricsGenericSphereUI $sphere [list $instructions]}]] $shortDescription
}


#-------------------------------------------------------------------------------
# .PROC MorphometricsCreateAxisPlacementStep
# Given a vtkAxisSource, this function creates the whole user interface in which
# the user can place the axis according to the provided instructions.
# The axis itself gets updated when the user leaves the step, not when the user 
# places it
# .ARGS
# str workflowName name of the workflow to which this function should add a step
# str axis object of type vtkAxis
# str shortDescription A concise description where the user should place the axis
# str instructions A longer text, explaining to the user how the axis should be placed.
# .END 
#-------------------------------------------------------------------------------
proc MorphometricsCreateAxisPlacementStep {workflowName axis shortDescription instructions} {
    WorkflowAddStep $workflowName [list [subst -nocommand {MorphometricsGenericAxisDisplay $axis}]] [list [subst -nocommand {MorphometricsGenericAxisUndisplay $axis}]] [list [subst -nocommand {MorphometricsGenericPolyDataUI MorphometricsNoUI [list $instructions]}]] $shortDescription
}


#-------------------------------------------------------------------------------
# .PROC MorphometricsCreateCylinderPlacementStep
# Given a vtkCylinderSource, this function creates the whole user interface in which
# the user can place the cylinder according to the provided instructions.
# Furthermore an interface is provided for the user to adjust the radius as well as 
# the height of the cylinder.
# The radius and height gets updated whenever the user adjusts those values whereas
# the center and the orientation of the cylinder gets updated when the user leaves
# the step. The vtkTransformFilter, the third argument, is needed since one cannot
# translate or rotate  a vtkCylinderSource. Therefore the rotation and center of
# the user placed cylinder are found in the transform of the TransformFilter.
# .ARGS
# str workflowName name of the workflow to which this function should add a step
# str cylinderSource Object of type vtkCylinderSource
# str cylinderSourceTransformFilter Object of type vtkTransformFilter
# str shortDescription A concise description where the user should place the cylinder.
# str instructions A longer text, explaining to the user how the cylinder should be placed.
# str CustomUserInterface name of function for building an additional user interface. Defaults to a dummy function
# str callOnEnter name of function to call whenever the user enters the step. Defaults to a dummy function
# str callOnExit name of function to call whenever the user exits the step. Defaults to a dummy function
# .END 
#-------------------------------------------------------------------------------
proc MorphometricsCreateCylinderPlacementStep {workflowName cylinderSource cylinderSourceTransformFilter shortDescription instructions {CustomUserInterface MorphometricsNoUI} {callOnEnter MorphometricsDoNothingOnEnterExit} {callOnExit MorphometricsDoNothingOnEnterExit}} {
    MorphometricsCreatePolyDataPlacementStep $workflowName $cylinderSourceTransformFilter $shortDescription $instructions [list [subst -nocommand {MorphometricsGenericCylinderUI $cylinderSource $CustomUserInterface}]] $callOnEnter $callOnExit
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsCreatePolyDataPlacementStep
# This function creates a step enabling the user to place an arbitrary object of
# type vtkPolyData.
# The vtkPolyData to be placed is defined as [polyDataTransformFilter GetInput] and
# the initial placement is defined by the transformation the TransformFilter uses.
# .ARGS
# str workflowName name of the workflow to which this function should add a step
# str polyDataTransformFilter object of type vtkTransformFilter
# str shortDescription A concise description where the user should place the polydata.
# str instructions A longer text, explaining to the user how the polydata should be placed.
# str CustomUserInterface name of function for building an additional user interface. Defaults to a dummy function
# str callOnEnter name of function to call whenever the user enters the step. Defaults to a dummy function
# str callOnExit name of function to call whenever the user exits the step. Defaults to a dummy function
# .END
#-------------------------------------------------------------------------------
proc MorphometricsCreatePolyDataPlacementStep {workflowName polyDataTransformFilter shortDescription instructions {CustomUserInterface MorphometricNoUI} {callOnEnter MorphometricsDoNothingOnEnterExit} {callOnExit MorphometricsDoNothingOnEnterExit}} {
    WorkflowAddStep $workflowName [list [subst -nocommand {MorphometricsGenericPolyDataDisplay $polyDataTransformFilter $callOnEnter}]] [list [subst -nocommand {MorphometricsGenericPolyDataUndisplay $polyDataTransformFilter $callOnExit}]] [list [subst -nocommand {MorphometricsGenericPolyDataUI $CustomUserInterface [list $instructions]}]] $shortDescription
}

############# END OF PUBLIC SECTION
#=========================================================================
# Internal Structure
# The StepFactories divide at the moment in two groups: one which generates
# polydata-placement steps and one which generates a step for choosing models.
# For the first group a VTK pipeline is used for displaying the polydata and
# interacting with it. The layout of the pipeline starts with a vtkTransformFilter,
# namely Morphometrics(StepFactories,Filter), continues with a vtkPolyDataMapper,
# Morphometrics(StepFactories,Mapper) and finishes with a vtkActor,Morphometrics(StepFactories,Actor).
# The transform used by the transform filter is Morphometrics(StepFactories,FilterTransform).
# Creating a polydata-placement steps is done by adding a normal step to the
# workflow and using generic function calls, with the polydata as substituted argument,
# for the different functions needed for WorkflowAddStep.
# The first function, called when the user enters the step, sets the polydata as the input
# for the pipeline named above. Furthermore it adds the actor to the csys actor. Thereby
# the polydata is visible in viewRen and whenever the csys actor moves, the polydata moves
# as well. Normally the rotation and translation of an vtkPolyData object is described by
# an transformation. In this case we set the csys-actors transform matrix to this
# transformation and Morphometrics(StepFactories,FilterTransform) to the inverse of this
# transformation. By doing this the center and orientation of the csys actor is the same
# as that of the polydata. Furthermore the transformation of the polydata doesn't have to
# be set to identity. In case the translation and rotation of the polydata can be described
# within the polydata, ie a vtkSphereSource, FilterTransform is set to Identity. 
# When the user leaves the step, we remove the actor from the csys actor, thereby removing
# the polydata from viewRen, and set the transform of the polydata to that of the csys 
# actor, thus reflecting the new position/orientation.
#
# In the second case, generating a step for choosing models, bookkeeping has to be performed in order 
# mimic persistence of the user choices. Current user choices of the i-th constructed model-choosing step
# are found in $Morphometrics(StepFactories,ModelChooser,$i,id).
#-------------------------------------------------------------------------------
# .PROC MorphometricsInitStepFactories
# Initialize Variables needed for the different MorphometricsCreate* functions.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsInitStepFactories { } {
    global Morphometrics
    # initialize the internalID counter of the ModelChooserStepGenerator
    set Morphometrics(StepFactories,ModelChooser,Count) 0


    # set up the pipeline for displaying polydata
    vtkActor MorphometricsStepFactoriesActor
    vtkPolyDataMapper MorphometricsStepFactoriesPolyDataMapper
    vtkTransformFilter MorphometricsStepFactoriesTransformFilter
    vtkTransform MorphometricsStepFactoriesTransform

    MorphometricsStepFactoriesTransformFilter SetTransform MorphometricsStepFactoriesTransform

    MorphometricsStepFactoriesActor SetMapper MorphometricsStepFactoriesPolyDataMapper
    set Morphometrics(StepFactories,Mapper) MorphometricsStepFactoriesPolyDataMapper
    set Morphometrics(StepFactories,Actor) MorphometricsStepFactoriesActor
    set Morphometrics(StepFactories,Filter) MorphometricsStepFactoriesTransformFilter
    set Morphometrics(StepFactories,FilterTransform) MorphometricsStepFactoriesTransform
    $Morphometrics(StepFactories,FilterTransform) Identity

    #otherwise a warning is issued, to keep the filter quiet we give it a dummy input
    vtkPlaneSource dummy
    MorphometricsStepFactoriesTransformFilter SetInput [dummy GetOutput]

    $Morphometrics(StepFactories,Mapper) SetInput [MorphometricsStepFactoriesTransformFilter GetOutput]
}

## Plane specific stuff
#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericPlaneDisplay
# Display a plane in viewRen, center a csys actor at its center, direct the 
# x-axis of the actor into the direction of the planes normal and align the
# displayed plane to the actor.
# .ARGS
# str plane object of type vtkPlaneSource
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericPlaneDisplay {plane} {
    global Morphometrics
    $Morphometrics(StepFactories,Filter) SetInput [$plane GetOutput]

    $Morphometrics(StepFactories,FilterTransform) Identity

    MorphometricsPositionCsys  [$plane GetCenter] [$plane GetNormal]

    [$Morphometrics(StepFactories,FilterTransform) GetMatrix] Invert [$Morphometrics(csys,actor) GetMatrix] [$Morphometrics(StepFactories,FilterTransform) GetMatrix]

    MorphometricsViewPolydataWithCsys
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericPlaneUndisplay
# Remove the plane from viewRen as well as update the plane to represent where it
# was located when it was undisplayed.
# .ARGS
# str plane object of type vtkPlaneSource
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericPlaneUndisplay {plane} {
    global Morphometrics
    MorphometricsUnAlignPolydataWithCsys
    MorphometricsHidePolydataWithCsys

    set position [MorphometricsCsysCenter]
    $plane SetCenter [lindex $position 0] [lindex $position 1] [lindex $position 2]
    set normal [MorphometricsCsysDirectionX]
    $plane SetNormal [lindex $normal 0] [lindex $normal 1] [lindex $normal 2]
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericPlaneUI
# A generic user interface function: simply print the instructions for placement.
# .ARGS
# str instructions A text which is displayed in the user interface
# str frame Name of frame where the user interface should be constructed
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericPlaneUI {instructions frame} {
    global Gui Morphometrics
    text $frame.tInstructions -wrap word -bg $Gui(normalButton) -height 5
    $frame.tInstructions insert end $instructions
    pack $frame.tInstructions -side top -padx $Gui(pad) -pady $Gui(pad)
}

## Cylinder specific stuff


#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericCylinderUI
# Construct an interface for accessing the height as well as the radius parameters
# of the given cylinderSource.
# .ARGS
# str cylinderSource object of type vtkCylinderSource
# str customUI name of additional user interface function. Called after this function is finished
# str frame name of frame where the user interface should be created. 
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericCylinderUI {cylinderSource customUI frame} {
    global Gui Morphometrics
    # A subframe for modifying the radius of the cylinder
    frame $frame.fradius -bg $Gui(activeWorkspace)
    pack $frame.fradius -side top -padx 0 -pady $Gui(pad) -fill x

    DevAddButton $frame.fradius.bMakeCylinderThinner "Thinner" [list eval [subst -nocommands {MorphometricsGenericCylinderChangeRadius $cylinderSource -1; Render3D}]]
    pack $frame.fradius.bMakeCylinderThinner -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $frame.fradius.bMakeCylinderThicker "Thicker" [list eval [subst -nocommands {MorphometricsGenericCylinderChangeRadius $cylinderSource +1; Render3D}]]
    pack $frame.fradius.bMakeCylinderThicker -side left -padx $Gui(pad) -pady $Gui(pad) -fill x


    # A subframe for modifying the height of the cylinder
    frame $frame.fheight -bg $Gui(activeWorkspace)
    pack $frame.fheight -side top -padx 0 -pady $Gui(pad) -fill x

    DevAddButton $frame.fheight.bMakeCylinderTaller "Taller" [list eval [subst -nocommands {MorphometricsGenericCylinderChangeHeight $cylinderSource +1; Render3D}]]
    pack $frame.fheight.bMakeCylinderTaller -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $frame.fheight.bMakeCylinderSmaller "Smaller" [list eval [subst -nocommands {MorphometricsGenericCylinderChangeHeight $cylinderSource -1; Render3D}]]
    pack $frame.fheight.bMakeCylinderSmaller -side left -padx $Gui(pad) -pady $Gui(pad)

    frame $frame.fUser -bg $Gui(activeWorkspace)
    pack $frame.fUser -side top -padx 0 -pady $Gui(pad) -fill x
    eval $customUI $frame.fUser

}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericCylinderChangeRadius
# Convenience function to change the radius of a cylinder. Ensures non-negativity
# of the radius.
# .ARGS
# str cylinderSource object of type vtkCylinderSource
# float delta specifies how much to change the radius
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericCylinderChangeRadius {cylinderSource delta} {
    if {[expr $delta + [$cylinderSource GetRadius] >= 0]} { 
    $cylinderSource SetRadius [expr $delta + [$cylinderSource GetRadius]] 
    }
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericCylinderChangeHeight
# Convenience function to change the height of a cylinder. Ensures non-negativity
# of the height.
# .ARGS
# str cylinderSource object of type vtkCylinderSource
# float delta specifies how much to change the height
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericCylinderChangeHeight {cylinderSource delta} {
    if {[expr $delta + [$cylinderSource GetHeight] >= 0]} { 
    $cylinderSource SetHeight [expr $delta + [$cylinderSource GetHeight]] 
    }
}

## PolyData specific stuff
#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericPolyDataDisplay
# Display polydata in viewRen. Align a csys to the polydata, where the center
# of the csys is defined as the translation of the origin by the transform used
# by the specified TransformFilter. Similarly the x-axis of the csys is defined
# by the rotation of {1 0 0 0}.
# .ARGS
# str polyDataTransformFilter object of type vtkTransformFilter
# str userOnEnter user function to call prior to executing the function body itself
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericPolyDataDisplay {polyDataTransformFilter userOnEnter} {
    eval $userOnEnter
    set orientation [[$polyDataTransformFilter GetTransform] GetOrientationWXYZ]
    set center [[$polyDataTransformFilter GetTransform] GetPosition] 

    MorphometricsAlignPolydataWithCsys [$polyDataTransformFilter GetInput] $center $orientation
    MorphometricsViewPolydataWithCsys
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericPolyDataDisplay
# Unalign as well as undisplay the polydata. Furthermore update the transformFilter
# to use the matrix of the csys to reflect its current location and orientation.
# .ARGS
# str polyDataTransformFilter polyData to update and to not display anylonger
# str userOnExit user function to call after executing the function body
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericPolyDataUndisplay {polyDataTransformFilter userOnExit} {
    global Morphometrics
    MorphometricsUnAlignPolydataWithCsys
    MorphometricsHidePolydataWithCsys

    [$polyDataTransformFilter GetTransform] SetMatrix  [Morphometrics(csys,actor) GetMatrix]
    eval $userOnExit
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericPolyDataUI
# Displays the instructions in the specified frame.
# .ARGS
# str customUI user specified interface-build function. Called with a subframe of the specified frame
# str instructions text, telling the user where/how to place the polydata exactly
# str frame name of frame where the user interface should be located
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericPolyDataUI {customUI instructions frame} {
    global Gui Morphometrics

    text $frame.tInstructions -wrap word -bg $Gui(normalButton) -height 5
    $frame.tInstructions insert end $instructions
    pack $frame.tInstructions -side top -padx $Gui(pad) -pady $Gui(pad)

    frame $frame.fUser -bg $Gui(activeWorkspace)
    pack $frame.fUser -side top -padx 0 -pady $Gui(pad) -fill x
    eval $customUI $frame.fUser

    text $frame.tHowToCsys -wrap word -bg $Gui(normalButton) -height 5
    $frame.tHowToCsys insert end [MorphometricsHowToInteractWithCsys]
    pack $frame.tHowToCsys -side top -padx $Gui(pad) -pady $Gui(pad)
   
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsModelChooserUI
# Display an interface in the designated frame where the user can choose for each
# entry of a prior specified list which model of the currently available it is.
# .ARGS
# int internalId necessary since the step has to perform some bookkeeping.
# str frame name of the frame where the user interface should be constructed.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsModelChooserUI {internalId frame} {
    global Gui Model Morphometrics
                                                                                
    set neededSegs $Morphometrics(StepFactories,ModelChooser,$internalId,names)
    set counter 0
    foreach iter $neededSegs {
        frame $frame.f$counter -bg $Gui(activeWorkspace)
        pack $frame.f$counter -side top -padx 0 -pady $Gui(pad) -fill x
    
        DevAddSelectButton Morphometrics $frame.f$counter Model$counter  "$iter :" Pack
    lappend Model(mbActiveList) $frame.f$counter.mbModel$counter
    lappend Model(mActiveList) $frame.f$counter.mbModel$counter.m

    DevUpdateNodeSelectButton Model Morphometrics Model$counter mModel$counter DevSelectNode

    # text of the user-choosen entry
    # is the text of the i-th label of the menu where "i-th" is the entry in the corresponding internal list
    set usersChoiceId [lindex $Morphometrics(StepFactories,ModelChooser,$internalId,id) $counter]
    
    if {[expr $usersChoiceId != $Model(idNone)]} {
        $frame.f$counter.mbModel$counter.m invoke $usersChoiceId
    }

    set counter [expr 1 + $counter]
    }
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsModelChooserOnEnter
# dummy function. Its only purpose at the moment is to ensure extensibility.
# .ARGS
# int internalId internal counter which modelchoosing step is meant.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsModelChooserOnEnter {internalId} {
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsModelChooserOnExit
# Saves user choices and also calls the function specified during creation of this
# step. User choices are saved in order to be able to recreate user choices when he/she
# reenters this step.
# .ARGS
# int internalId internal counter which modelchoosing step is meant.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsModelChooserOnExit {internalId} {
    global Gui Model Morphometrics
    # save user choices into Morphometrics(StepFactories,ModelChooser,$internalId,id)
    # init to {}
    set counter 0
    set Morphometrics(StepFactories,ModelChooser,$internalId,id) {}
    # foreach length ..
    foreach iter $Morphometrics(StepFactories,ModelChooser,$internalId,names) {
    lappend Morphometrics(StepFactories,ModelChooser,$internalId,id) $Morphometrics(mModel$counter) 

    # find index for the menubutton
    set index [lsearch -exact $Model(mbActiveList) $Morphometrics(workflowFrame).fMiddle.f$counter.mbModel$counter]
    # remove the index
    set Model(mbActiveList) [lreplace $Model(mbActiveList) $index $index]


    # find index for the menu
    set index [lsearch -exact $Model(mActiveList) $Morphometrics(workflowFrame).fMiddle.f$counter.mbModel$counter.m]
    # remove the index
    set Model(mActiveList) [lreplace $Model(mActiveList) $index $index]


    set counter [expr $counter + 1]
    }

    # call user function with the list of choosen 
    $Morphometrics(StepFactories,ModelChooser,$internalId,distributor) $Morphometrics(StepFactories,ModelChooser,$internalId,id)

}

#-------------------------------------------------------------------------------
# .PROC MorphometricsVolumeChooserUI
# Display an interface in the designated frame where the user can choose for each
# entry of a prior specified list which volume of the currently available it is.
# .ARGS
# int internalId necessary since the step has to perform some bookkeeping.
# str frame name of the frame where the user interface should be constructed.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsVolumeChooserUI {internalId frame} {
    global Gui Volume Morphometrics
                                                                                
    set neededSegs $Morphometrics(StepFactories,ModelChooser,$internalId,names)
    set counter 0
    foreach iter $neededSegs {
        frame $frame.f$counter -bg $Gui(activeWorkspace)
        pack $frame.f$counter -side top -padx 0 -pady $Gui(pad) -fill x
    
        DevAddSelectButton Morphometrics $frame.f$counter Volume$counter  "$iter :" Pack
    lappend Volume(mbActiveList) $frame.f$counter.mbVolume$counter
    lappend Volume(mActiveList) $frame.f$counter.mbVolume$counter.m

    DevUpdateNodeSelectButton Volume Morphometrics Volume$counter mVolume$counter DevSelectNode

    # text of the user-choosen entry
    # is the text of the i-th label of the menu where "i-th" is the entry in the corresponding internal list
    set usersChoiceId [lindex $Morphometrics(StepFactories,ModelChooser,$internalId,id) $counter]
    
    if {[expr $usersChoiceId != $Volume(idNone)]} {
        $frame.f$counter.mbVolume$counter.m invoke $usersChoiceId
    }

    set counter [expr 1 + $counter]
    }
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsVolumeChooserOnEnter
# dummy function. Its only purpose at the moment is to ensure extensibility.
# .ARGS
# int internalId internal counter which volumechoosing step is meant.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsVolumeChooserOnEnter {internalId} {
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsVolumeChooserOnExit
# Saves user choices and also calls the function specified during creation of this
# step. User choices are saved in order to be able to recreate user choices when he/she
# reenters this step.
# .ARGS
# int internalId internal counter which volumechoosing step is meant.
# .END
#-------------------------------------------------------------------------------
proc MorphometricsVolumeChooserOnExit {internalId} {
    global Gui Volume Morphometrics
    # save user choices into Morphometrics(StepFactories,ModelChooser,$internalId,id)
    # init to {}
    set counter 0
    set Morphometrics(StepFactories,ModelChooser,$internalId,id) {}
    # foreach length ..
    foreach iter $Morphometrics(StepFactories,ModelChooser,$internalId,names) {
    lappend Morphometrics(StepFactories,ModelChooser,$internalId,id) $Morphometrics(mVolume$counter) 

    # find index for the menubutton
    set index [lsearch -exact $Volume(mbActiveList) $Morphometrics(workflowFrame).fMiddle.f$counter.mbVolume$counter]
    # remove the index
    set Volume(mbActiveList) [lreplace $Volume(mbActiveList) $index $index]


    # find index for the menu
    set index [lsearch -exact $Volume(mActiveList) $Morphometrics(workflowFrame).fMiddle.f$counter.mbVolume$counter.m]
    # remove the index
    set Volume(mActiveList) [lreplace $Volume(mActiveList) $index $index]


    set counter [expr $counter + 1]
    }

    # call user function with the list of choosen 
    $Morphometrics(StepFactories,ModelChooser,$internalId,distributor) $Morphometrics(StepFactories,ModelChooser,$internalId,id)

}

## Sphere specific stuff
#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericSphereDisplay
# Display a sphere in viewRen, center the csys actor at its center and align the
# sphere to the actor.
# .ARGS
# str sphere object of type vtkSphereSource
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericSphereDisplay {sphere} {
    global Morphometrics
    # the last argument to AlignPolydataWithCsys is a dummy argument.
    MorphometricsAlignPolydataWithCsys [$sphere GetOutput] [$sphere GetCenter] {180 1 0 0}
    $Morphometrics(StepFactories,FilterTransform) Translate [expr -1 * [lindex [$sphere GetCenter] 0]] [expr -1 * [lindex [$sphere GetCenter] 1]] [expr -1 * [lindex [$sphere GetCenter] 2]]
    MorphometricsViewPolydataWithCsys
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericSphereUndisplay
# Remove the sphere from viewRen as well as update the sphere to its new center.
# .ARGS
# str sphere object of type vtkSphereSource
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericSphereUndisplay {sphere} {
    global Morphometrics
    MorphometricsUnAlignPolydataWithCsys
    MorphometricsHidePolydataWithCsys

    set position [MorphometricsCsysCenter]
    $sphere SetCenter [lindex $position 0] [lindex $position 1] [lindex $position 2]
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericSphereUI
# A generic user interface function: simply print the instructions for placement
# and add two buttons in order to make it possible for the user to adjust the
# radius of the displayed sphere.
# .ARGS
# str sphere object of type vtkSphereSource
# str instructions A text which is displayed in the user interface
# str frame Name of frame where the user interface should be constructed
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericSphereUI {sphere instructions frame} {
    global Gui Morphometrics

    text $frame.tInstructions -wrap word -bg $Gui(normalButton) -height 5
    $frame.tInstructions insert end $instructions
    pack $frame.tInstructions -side top -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $frame.bMakeSphereLarger "Larger" [list eval [subst -nocommands {MorphometricsGenericSphereChangeRadius $sphere 1; Render3D}]]
    pack $frame.bMakeSphereLarger -side left -padx $Gui(pad) -pady $Gui(pad)

    DevAddButton $frame.bMakeSphereSmaller "Smaller" [list eval [subst -nocommands {MorphometricsGenericSphereChangeRadius $sphere -1; Render3D}]]
    pack $frame.bMakeSphereSmaller -side right -padx $Gui(pad) -pady $Gui(pad)
}


#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericSphereChangeRadius
# Convenience function to change the radius of the specified sphere. Ensures
# nonnegativeness of the radius.
# .ARGS
# str sphere object of type vtkSphereSource
# float delta specifies how much to change the height
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericSphereChangeRadius {sphere delta} {
    if {[expr $delta + [$sphere GetRadius] >= 0]} { 
    $sphere SetRadius [expr $delta + [$sphere GetRadius]]
    }
}


#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericAxisDisplay
# Display a axis in viewRen, center the csys actor at its center and align the
# axis to the actor.
# .ARGS
# str axis object of type vtkAxisSource
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericAxisDisplay {axis} {
    global Morphometrics

    $Morphometrics(StepFactories,Filter) SetInput [$axis GetOutput]

    $Morphometrics(StepFactories,FilterTransform) Identity

    MorphometricsPositionCsys  [$axis GetCenter] [$axis GetDirection]

    [$Morphometrics(StepFactories,FilterTransform) GetMatrix] Invert [$Morphometrics(csys,actor) GetMatrix] [$Morphometrics(StepFactories,FilterTransform) GetMatrix]

    MorphometricsViewPolydataWithCsys
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsGenericAxisUndisplay
# Remove the axis from viewRen as well as update the axis to its new center.
# .ARGS
# str axis object of type vtkAxisSource
# .END
#-------------------------------------------------------------------------------
proc MorphometricsGenericAxisUndisplay {axis} {
    global Morphometrics
    MorphometricsUnAlignPolydataWithCsys
    MorphometricsHidePolydataWithCsys

    set position [MorphometricsCsysCenter]
    set direction [MorphometricsCsysDirectionX]
    $axis SetCenter [lindex $position 0] [lindex $position 1] [lindex $position 2]
    $axis SetDirection [lindex $direction 0] [lindex $direction 1] [lindex $direction 2]
}


#-------------------------------------------------------------------------------
# .PROC MorphometricsAlignPolydataWithCsys
# Position the csys actor to the specified center and direction as well as make
# the location and orientation of the polydata dependend on the csys actor. Via
# this mechanism the user can orient the polydata with the csys actor and the
# transformation matrix of the actor holds the information about its new orientation
# and location after interaction by the user.
# .ARGS
# str Polydata object of type vtkPolydata
# list Center the center where the actor should be
# list Orientation the orientation of the actor
# .END
#-------------------------------------------------------------------------------
proc MorphometricsAlignPolydataWithCsys {Polydata Center Orientation} {
    global Morphometrics

    $Morphometrics(StepFactories,Filter) SetInput $Polydata

    $Morphometrics(StepFactories,FilterTransform) Identity

    $Morphometrics(csys,actor) SetPosition 0 0 0 
    $Morphometrics(csys,actor) SetOrientation 0 0 0
    $Morphometrics(csys,actor) RotateWXYZ [lindex $Orientation 0] [lindex $Orientation 1] [lindex $Orientation 2] [lindex $Orientation 3]
    $Morphometrics(csys,actor) SetPosition [lindex $Center 0] [lindex $Center 1] [lindex $Center 2]
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsUnAlignPolydataWithCsys
# Reposition the csys to the origin as well as align it to the "normal" axes
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsUnAlignPolydataWithCsys {} {
    global Morphometrics
    $Morphometrics(StepFactories,FilterTransform) Identity
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsViewPolydata
# Convenience function to display polydata. Only the polydata of the last call
# to this function is displayed.
# .ARGS
# str polydata object of type vtkPolyData
# .END
#-------------------------------------------------------------------------------
proc MorphometricsViewPolydata {polydata} {
    global Morphometrics
    $Morphometrics(StepFactories,Filter) SetInput $polydata
    viewRen AddActor $Morphometrics(StepFactories,Actor)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsHidePolydata
# Convenience function to undisplay polydata.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsHidePolydata {} {
    global Morphometrics
    viewRen RemoveActor $Morphometrics(StepFactories,Actor)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsViewPolydataWithCsys
# Convenience function to display the csys and its aligned data.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsViewPolydataWithCsys {} {
    global Morphometrics
    $Morphometrics(csys,actor) AddPart $Morphometrics(StepFactories,Actor)
    MorphometricsViewCsys
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MorphometricsHidePolydataWithCsys
# Convenience function to undisplay the csys and its aligned data.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MorphometricsHidePolydataWithCsys {} {
    global Morphometrics
    $Morphometrics(csys,actor) RemovePart $Morphometrics(StepFactories,Actor)
    MorphometricsHideCsys
    Render3D
}

