

#-------------------------------------------------------------------------------
# .PROC ModelInteractionInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelInteractionInit {} {
    global ModelInteraction Module Volume Model Gui
    
    set m ModelInteraction

    # Module Summary Info
    #------------------------------------
    # Description:
    set Module($m,overview) "Tools to interact with models (lines,surfaces) in 3d."
    set Module($m,author) "Lauren O'Donnell MIT lauren@csail.mit.edu"

    #  Set the level of development that this module falls under.
    #  This is included in the Help->Module Categories menu item
    #------------------------------------
    set Module($m,category) "Interaction"

    # Define Tabs
    #------------------------------------

    set Module($m,row1List) "Help Select Paint"
    set Module($m,row1Name) "{Help} {Select} {Paint}"
    set Module($m,row1,tab) Select

    # Define Procedures
    #------------------------------------
    set Module($m,procGUI) ModelInteractionBuildGUI
    set Module($m,procVTK) ModelInteractionBuildVTK
    set Module($m,procEnter) ModelInteractionEnter
    set Module($m,procExit) ModelInteractionExit
    set Module($m,procMRML) ModelInteractionUpdateMRML

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
        {$Revision: 1.2 $} {$Date: 2009/02/05 20:58:02 $}]

    # Initialize module-level (global) variables
    #------------------------------------


    # bindings for mouse/keyboard picking interaction
    #------------------------------------

    EvDeclareEventHandler ModelInteractionEvents <KeyPress-s> \
        {if { [SelectPick ModelInteraction(vtk,cellPicker) %W %x %y] != 0 } \
             { 
                 set m [ModelInteractionIdentifySelectedModel]
                 if {$m != ""} {
                     ModelInteractionSelectModel $m
                 }
             }
        }
    
    EvDeclareEventHandler ModelInteractionEvents <KeyPress-d> \
        {if { [SelectPick ModelInteraction(vtk,cellPicker) %W %x %y] != 0 } \
             { 
                 set m [ModelInteractionIdentifySelectedModel]
                 if {$m != ""} {
                     ModelInteractionDeSelectModel $m
                 }
             }
        }
    
    # bindings for keyboard interaction with 3D model display
    #------------------------------------
    EvDeclareEventHandler ModelInteractionEvents <KeyPress-c> \
        {
            ModelInteractionClearClipboard
        }
    EvDeclareEventHandler ModelInteractionEvents <KeyPress-e> \
        {
            ModelInteractionToggleClipboardVisibility
        }
    EvDeclareEventHandler ModelInteractionEvents <KeyPress-f> \
        {
            ModelInteractionToggleClipboardHighlight
        }
    EvDeclareEventHandler ModelInteractionEvents <KeyPress-a> \
        {
            ModelInteractionToggleAllVisibility
        }



    EvAddWidgetToBindingSet ModelInteractionEvents $Gui(fViewWin) {{ModelInteractionEvents} {tkMouseClickEvents} {tkMotionEvents} {tkRegularEvents}}


    foreach submodule {Help Clipboards Paint} {
    source "$::env(SLICER_HOME)/Modules/vtkModelInteraction/Tcl/ModelInteraction$submodule.tcl"
    }

    ModelInteractionClipboardsInit
    ModelInteractionPaintInit

}


proc ModelInteractionBuildGUI {} {
    global Gui ModelInteraction Module Volume Model



    ModelInteractionHelpBuildGUI

    ModelInteractionClipboardsBuildGUI

    ModelInteractionPaintBuildGUI

}

#-------------------------------------------------------------------------------
# .PROC ModelInteractionBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelInteractionBuildVTK {} {

    vtkCellPicker ModelInteraction(vtk,cellPicker)
    ModelInteraction(vtk,cellPicker) SetTolerance 0.005

}

#-------------------------------------------------------------------------------
# .PROC ModelInteractionEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------

proc ModelInteractionEnter {} {
    global ModelInteraction
    
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.

    # add event handling for 3D
    EvActivateBindingSet ModelInteractionEvents

    set ModelInteraction(allVisibility) 0
    set ModelInteraction(clipboardVisibility) 0
    set ModelInteraction(clipboardHighlight) 0


}


#-------------------------------------------------------------------------------
# .PROC ModelInteractionExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelInteractionExit {} {

    global ModelInteraction

    # remove event handling for 3D
    EvDeactivateBindingSet ModelInteractionEvents

}


proc ModelInteractionUpdateMRML {} {


    if {$::Module(verbose)} {
        puts "ModelInteractionUpdateMRML: calling ModelInteractionPaintUpdateMRML"
    } 

    ModelInteractionPaintUpdateMRML
}



proc ModelInteractionIdentifySelectedModel {} {
    global Module Model Select

    set renderer [lindex $Module(Renderers) 0]
    foreach m $Model(idList) {
        if { $Select(actor) == "Model($m,actor,$renderer)" } {
            return $m
        }
    }

    return ""

}

proc ModelInteractionSelectModel {m} {

    ModelInteractionHighlightOn $m
    ModelInteractionAddModelToClipboard $m
    Render3D
}

proc ModelInteractionDeSelectModel {m} {

    ModelInteractionHighlightOff $m
    ModelInteractionRemoveModelFromClipboard $m
    Render3D
}


proc ModelInteractionSelectAll {} {
    global Model

    foreach m $Model(idList) {

        ModelInteractionSelectModel $m
    }
}


proc ModelInteractionHighlightOn {m} {
    global Module Model

    set renderer [lindex $Module(Renderers) 0]

    # highlight the chosen model
    eval $Model($m,prop,$renderer) \
        SetColor 1 0 0
}


proc ModelInteractionHighlightOff {m} {
    global Module Model Color

    set renderer [lindex $Module(Renderers) 0]
    
    # unhighlight the chosen model
    set cName [Model($m,node) GetColor]
    foreach c $Color(idList) {
        if {[Color($c,node) GetName] == $cName} {
            break
        }
    }
    
    # put back the original color
    eval $Model($m,prop,$renderer) \
        SetColor [Color($c,node) GetDiffuseColor]
}

proc ModelInteractionClipboardHighlightOn {} {
    global ModelInteraction Module Color Model

    set id [ModelInteractionGetCurrentClipboardID]

    foreach m $ModelInteraction(clipboard,$id) {
        ModelInteractionHighlightOn $m
    }

    set ModelInteraction(clipboardHighlight) 1

    Render3D
}

proc ModelInteractionClipboardHighlightOff {} {
    global ModelInteraction Module Color Model

    set id [ModelInteractionGetCurrentClipboardID]

    foreach m $ModelInteraction(clipboard,$id) {
        ModelInteractionHighlightOff $m
    }

    set ModelInteraction(clipboardHighlight) 0

    Render3D
}


proc ModelInteractionClipboardVisible {} {
    global ModelInteraction

    set id [ModelInteractionGetCurrentClipboardID]

    foreach m $ModelInteraction(clipboard,$id) {
        MainModelsSetVisibility $m 1
    }

    set ModelInteraction(clipboardVisibility) 1

    Render3D
}


proc ModelInteractionClipboardInVisible {} {
    global ModelInteraction

    set id [ModelInteractionGetCurrentClipboardID]

    foreach m $ModelInteraction(clipboard,$id) {
        MainModelsSetVisibility $m 0
    }

    set ModelInteraction(clipboardVisibility) 0

    Render3D
}

proc ModelInteractionAllClipboardsInVisible {} {
    global Model ModelInteraction

    foreach id $ModelInteraction(clipboardIDList) {
        foreach m $ModelInteraction(clipboard,$id) {
            MainModelsSetVisibility $m 0
        }
    }
    set ModelInteraction(allVisibility) 1
    set ModelInteraction(clipboardVisibility) 0
    Render3D
}

proc ModelInteractionAllInVisible {} {
    global Model ModelInteraction

    foreach m $Model(idList) {
        MainModelsSetVisibility $m 0
    }

    set ModelInteraction(allVisibility) 0
    set ModelInteraction(clipboardVisibility) 0
    Render3D
}

proc ModelInteractionAllVisible {} {
    global Model ModelInteraction

    foreach m $Model(idList) {
        MainModelsSetVisibility $m 1
    }

    set ModelInteraction(allVisibility) 2
    set ModelInteraction(clipboardVisibility) 1

    Render3D
}

proc ModelInteractionToggleClipboardHighlight {} {
    global ModelInteraction

    switch $ModelInteraction(clipboardHighlight) {

        "1" {
            ModelInteractionClipboardHighlightOff
        }
        "0" {
            ModelInteractionClipboardHighlightOn
        }
    }
}

proc ModelInteractionToggleClipboardVisibility {} {
    global ModelInteraction

    switch $ModelInteraction(clipboardVisibility) {

        "1" {
            ModelInteractionClipboardInVisible
        }
        "0" {
            ModelInteractionClipboardVisible
        }
    }
}

proc ModelInteractionToggleAllVisibility {} {
    global ModelInteraction
    
    switch $ModelInteraction(allVisibility) {
        "1" {
            ModelInteractionAllInVisible
        }
        "2" {
            ModelInteractionAllClipboardsInVisible
        }
        "0" {
            ModelInteractionAllVisible
        }
    }
}

