#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Workflow.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:06 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        Workflow.tcl
# PROCEDURES:  
#   WorkflowInit
#   WorkflowAddStep workflowName callOnEnterStep this callOnExitStep step. buildStepInterface this name name well
#   WorkflowStart workflowName
#   WorkflowInitWorkflow workflowName module, workflowFrame
#   WorkflowInitGUI workflowFrame workflowName
#   WorkflowDecrStepCounter workflowName
#   WorkflowIncrStepCounter workflowName
#   WorkflowCleanUI workflowName
#   WorkflowCreateUI workflowName
#   WorkflowCurrentStep workflowName
#   WorkflowCurrentOnEnter workflowName
#   WorkflowCurrentOnExit workflowName
#   WorkflowCurrentBuildUI workflowName
#   WorkflowCurrentName workflowName
#   WorkflowUpdatePreviousStepButton workflowName
#   WorkflowUpdateNextStepButton workflowName
#==========================================================================auto=
# A description how the workflow system works internally is given in the "private"
# section of this module. Users should only call functions prior to the "End of public"
# comment.
######
# Overall Description:
# This module provides a framework which other modules can use to employ a graphical workflow.
# A workflow consists of several steps, this modules takes care of the storage and traversal 
# of those steps.
# The user interface roughly looks like this:
# ----------------------------------------
# <name of the step> (<index of step in the list of steps> /<#steps>)
# 
#
#      <frame into which each step can deploy an own user interface>
#
#
# 
#
# <go_to_previous_step_button> <go_to_next_step_button>
######
# This module provides:
# - a static workflow, you can't delete/exchange steps in your workflow
# - a linear workflow, the user traverses the workflow in the order you added steps and can't jump
#    to steps other than the previous and next
# - no means of constructing hierarchies of workflows
######
# Usage instructions:
# 1.) In the Init function of your module, add "Workflow" to the list of modules your module depends on:
#      set Module(Morphometrics,depend) "Workflow"
# 
# 2.) Call WorkflowInitWorkflow with the name of your workflow and the name of a frame where the
#     workflow user interface should be contained. To avoid nameclashes, prefix your workflow always
#     with the name of your module:
#         WorkflowInitWorkflow Morphometrics $fWorkflow
#
# 3.) Add each step in the order you want the user to traverse the workflow. A step consists of:
#     - a name, which get's displayed on the top of the workflow frame as well as on the previous
#       and next button
#     - the name of the function to call when the workflow leaves the step
#     - the name of the function to call when the workflow enters a step
#     - the name of the function which builds the specific user interface
#      
#    The first two functions are called without any arguments whereas the last is called with the 
#    name of a frame where the specific user interface should be drawn.
#    Be aware of the fact that the frame in which each step draws the interface will be destroyed
#    if the user enters the previous or next step. 
#    
#    When the user enters the previous or next step, the order of function calls is as follows:
#     1.) the on-exit function of the current step is called 
#     2.) the frame for the user interface of each step is emptied
#     3.) the user interface build function of the new current step is called
#     4.) the on-entry function of the new current step is called
#
# 4.) Invoke WorkflowStart <your_workflow>. This starts the workflow and the user interface is drawn
#     for the first time.
#-------------------------------------------------------------------------------
# .PROC WorkflowInit
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc WorkflowInit {} {
}


#-------------------------------------------------------------------------------
# .PROC WorkflowAddStep
# Append a step to the workflow of the module.   
# .ARGS
# str workflowName name of the workflow to which the steps is added
# str callOnEnterStep function name which gets called each time the workflow comes
#                   into this step. The function is called without any arguments.
# str callOnExitStep function name which gets called each time the workflow leaves
#                   this step. The function is called without any arguments
# str buildStepInterface function name which builds the user interface of the step. Sole argument
#                   for this function is the name of the frame to draw the interface into
# str name a concise and descriptive name of what the user does/achieves in this step.
#     This name will be displayed on the top of the workflow interface if this step is the current step
#     as well as the label of the "previous step" and "next step" button.
# .END
#-------------------------------------------------------------------------------
proc WorkflowAddStep {workflowName callOnEnterStep callOnExitStep buildStepInterface name} {
    global Workflow
    lappend Workflow($workflowName,steps) [concat "$callOnEnterStep" "$callOnExitStep" "$buildStepInterface" [list $name]]
    set Workflow($workflowName,nr_steps) [expr $Workflow($workflowName,nr_steps) + 1]
}


#-------------------------------------------------------------------------------
# .PROC WorkflowStart
# Transfer the flow of control to the workflow system. The workflow system draws
# the user interface for the first step in the frame specified in the call to
# WorkflowInit
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowStart {workflowName} {
    global Workflow
    WorkflowInitGUI $Workflow($workflowName,ui) $workflowName
    WorkflowCreateUI $workflowName
}

#-------------------------------------------------------------------------------
# .PROC WorkflowInitWorkflow
# Tells the Workflow system that there is a new workflow with the specified name.
# As expected, the inital workflow has no steps.
# .ARGS
# str workflowName name of the workflow. In order to avoid name clashes use the name of
#            your module, or at least prefix the actual name with the module name.
# str workflowFrame name of a frame where the workflow interface should be located.
# .END
#-------------------------------------------------------------------------------
proc WorkflowInitWorkflow { workflowName workflowFrame} {
    global Workflow
    set Workflow($workflowName,nr_steps) 0
    set Workflow($workflowName,ui) $workflowFrame
    set Workflow($workflowName,steps) {}
    set Workflow($workflowName,current_step) 0
}

##### End Of "Public" Functions Section
##################################
# Description of the architecture of the Workflow module
# 1.) What is the internal representation of a workflow?
#    A workflow is a list of steps together with the information
#    where its user interface is as well as the current state information
# 2.) What is the structure of the user interface?
#    For every workflow the workflowFrame is divided into three subframes. 
#    The first subframe displays the name of the step as well as a counter of
#    steps already done and how many steps totally are in the workflow. The second subframe is the frame
#    where each step of the workflow displays its own user interface. The third subframe
#    consists merely of two buttons which enable the user to reach the previous and next step
#    of the workflow.
# 3.) What happens if the user presses one of the buttons?
#    Pressing the button results in calling the exit-function of the current step,
#    increasing/decreasing the step counter, calling the user interface of the new current step and calling
#    its enter-function.
# 
# The functions actually implementing this are straight forward.
#-------------------------------------------------------------------------------
# .PROC WorkflowInitGUI
# Initialize the frame where the workflow is displayed.
# .ARGS
# str workflowFrame name of frame where the workflow is displayed
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowInitGUI {workflowFrame workflowName} {
    global Gui

    foreach subFrame "Top Middle Bottom" {
    frame $workflowFrame.f$subFrame -bg $Gui(activeWorkspace)
    pack $workflowFrame.f$subFrame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    set buttonFrame $workflowFrame.fBottom

    DevAddButton $buttonFrame.bPrev "Previous Step"  [subst -nocommand {eval {eval [WorkflowCurrentOnExit $workflowName];WorkflowDecrStepCounter $workflowName;WorkflowCreateUI $workflowName;eval [WorkflowCurrentOnEnter $workflowName]}}]
    $buttonFrame.bPrev configure -state disabled
    DevAddButton $buttonFrame.bNext "Next Step    "  [subst -nocommand {eval {eval [WorkflowCurrentOnExit $workflowName];WorkflowIncrStepCounter $workflowName; WorkflowCreateUI $workflowName;eval [WorkflowCurrentOnEnter $workflowName]}}]

    pack $buttonFrame.bPrev -side left -padx $Gui(pad) -pady $Gui(pad)
    pack $buttonFrame.bNext -side right -padx $Gui(pad) -pady $Gui(pad)
}

#-------------------------------------------------------------------------------
# .PROC WorkflowDecrStepCounter
# Convenience function to decrease the internal counter in which step the workflow
# currently is
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowDecrStepCounter {workflowName} {
    global Workflow
    set Workflow($workflowName,current_step) [expr $Workflow($workflowName,current_step) - 1 ]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowIncrStepCounter
# Convenience function to decrease the internal counter in which step the workflow
# currently is
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowIncrStepCounter {workflowName} {
    global Workflow
    set Workflow($workflowName,current_step) [expr $Workflow($workflowName,current_step) + 1 ]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCleanUI
# Convenience function to empty the workflowframe. Only the top and middle frame
# get emptied, since they need to be rebuild.
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCleanUI {workflowName} {
    global Workflow
    set workflowFrame $Workflow($workflowName,ui)
    set allSlaves [concat [pack slaves $workflowFrame.fTop] [pack slaves $workflowFrame.fMiddle]]
    foreach iter $allSlaves { destroy $iter}
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCreateUI
# Build the interface for the current step. Invoke every time the current step
# switches in order to update the user interface.
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCreateUI {workflowName} {
    global Workflow Gui

    WorkflowCleanUI $workflowName
    
    set workflowFrame $Workflow($workflowName,ui)
    # Add the current step counter
    DevAddLabel $workflowFrame.fTop.lsteps "[WorkflowCurrentName $workflowName] ([expr 1 + $Workflow($workflowName,current_step)] / $Workflow($workflowName,nr_steps))"
    pack $workflowFrame.fTop.lsteps -side top -padx $Gui(pad) -pady $Gui(pad) -fill x


    # Let the step draw its user interface
    eval [WorkflowCurrentBuildUI $workflowName] $workflowFrame.fMiddle
    
    # update the buttons
    WorkflowUpdatePreviousStepButton $workflowName
    WorkflowUpdateNextStepButton $workflowName
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCurrentStep
# Convenience function, returns all known information about the current step as
# were added during WorkflowAddStep
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCurrentStep {workflowName} {
    global Workflow 
    return [lindex $Workflow($workflowName,steps) $Workflow($workflowName,current_step)]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCurrentOnEnter
# Convenience function, returns the function the user specified to be called every
# time the workflow enters the step
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCurrentOnEnter {workflowName} {
    global Workflow
    return [lindex [WorkflowCurrentStep $workflowName] 0]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCurrentOnExit
# Convenience function, returns the function the user specified to be called every
# time the workflow exits the step
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCurrentOnExit {workflowName} {
    global Workflow
    return [lindex [WorkflowCurrentStep $workflowName] 1]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCurrentBuildUI
# Convenience function, calls the function the user specified for building the
# user interface of the current step
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCurrentBuildUI {workflowName} {
    global Workflow
    return [lindex [WorkflowCurrentStep $workflowName] 2]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowCurrentName
# Convenience function, returns the name of the current step
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowCurrentName {workflowName} {
    global Workflow
    return [lindex [WorkflowCurrentStep $workflowName] 3]
}

#-------------------------------------------------------------------------------
# .PROC WorkflowUpdatePreviousStepButton
# The buttons on the bottom of the workflowframe have to be updated each time 
# the step currently displayed changes. This function updates the "previous step" 
# button, specifically it updates the name as well as ensures that if the current
#  step is the first in the workflow, the button is disabled.
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowUpdatePreviousStepButton {workflowName} {
    global Workflow
    set prev_step_nr  [expr $Workflow($workflowName,current_step) - 1]
    set workflowFrame $Workflow($workflowName,ui)

    if {[expr $prev_step_nr +1 ] == 0} { 
    $workflowFrame.fBottom.bPrev configure -state disabled
    $workflowFrame.fBottom.bPrev configure -text "-----"  
    } else {
    $workflowFrame.fBottom.bPrev configure -state normal
    set steps $Workflow($workflowName,steps) 
    set prev_step [lindex $steps $prev_step_nr]
    set name [lindex $prev_step 3]
    $workflowFrame.fBottom.bPrev configure -text "$name"
    }
}

#-------------------------------------------------------------------------------
# .PROC WorkflowUpdateNextStepButton
# The buttons on the bottom of the workflowframe have to be updated each time 
# the step currently displayed changes. This function updates the "next step" 
# button, specifically it updates the name as well as ensures that if the current
#  step is the last in the workflow, the button is disabled.
# .ARGS
# str workflowName name of the workflow
# .END
#-------------------------------------------------------------------------------
proc WorkflowUpdateNextStepButton {workflowName} {
    global Workflow
    set next_step_nr  [expr $Workflow($workflowName,current_step) + 1]
    set workflowFrame $Workflow($workflowName,ui)

    if {$next_step_nr == $Workflow($workflowName,nr_steps)} { 
    $workflowFrame.fBottom.bNext configure -state disabled
    $workflowFrame.fBottom.bNext configure -text "-----"  
    } else {
    $workflowFrame.fBottom.bNext configure -state normal
    set steps $Workflow($workflowName,steps) 
    set next_step [lindex $steps $next_step_nr]
    set name [lindex $next_step 3]
    $workflowFrame.fBottom.bNext configure -text "$name"
    }
}

##########################################################################

