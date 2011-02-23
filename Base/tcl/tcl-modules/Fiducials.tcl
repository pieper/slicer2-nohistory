#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Fiducials.tcl,v $
#   Date:      $Date: 2006/07/27 18:40:57 $
#   Version:   $Revision: 1.69 $
# 
#===============================================================================
# FILE:        Fiducials.tcl
# PROCEDURES:  
#   FiducialsInit
#   FiducialsDisplayDescriptionActive
#   FiducialsDescriptionActiveUpdated
#   FiducialsEnter
#   FiducialsExit
#   FiducialsBuildGUI
#   FiducialsCreateGUI f id
#   FiducialsDeleteGUI f m
#   FiducialsConfigScrolledGUI canvasScrolledGUI fScrolledGUI
#   FiducialsBuildVTK
#   FiducialsVTKCreateFiducialsList id type scale textScale visibility
#   FiducialsVTKCreatePoint fid pid
#   FiducialsVTKUpdatePoints fid symbolSize textSize
#   FiducialsVTKUpdatePoints2D fid renList
#   FiducialsSetTxtScale id val
#   FiducialsSetScale id val
#   FiducialsSetSymbol2D symbol
#   FiducialsUpdateMRML
#   FiducialsResetVariables deleteFlag
#   FiducialsCheckListExistence name argfid
#   FiducialsCreateFiducialsList type name textSize symbolSize
#   FiducialsCreatePointFromWorldXYZ type x y z listName name selected
#   FiducialsInsertPointFromWorldXYZ type previousPid x y z listName name
#   FiducialsDeletePoint fid pid noUpdate
#   FiducialsDeleteFromPicker actor cellId
#   FiducialsActiveDeleteList
#   FiducialsDeleteList name
#   FiducialsSetFiducialsVisibility name visibility rendererName
#   FiducialsSetActiveList name menu cb
#   FiducialsSelectionUpdate fid pid on
#   FiducialsSelectionFromPicker actor cellId
#   FiducialsSelectionFromCheckbox menu cb focusOnActiveFiducial pid
#   FiducialsSelectionFromScroll menu cb focusOnActiveFiducial pid
#   FiducialsUpdateSelectionForActor fid pid
#   FiducialsPointIdFromGlyphCellId fid cid
#   FiducialsScalarIdFromPointId fid pid
#   FiducialsScalarIdFromPointId2D fid pid r
#   FiducialsGetAllNodesFromList name
#   FiducialsAddActiveListFrame frame scrollHeight scrollWidth defaultNames
#   FiducialsInteractActiveCB args
#   FiducialsInteractActiveStart mode
#   FiducialsInteractActiveEnd
#   FiducialsGetPointCoordinates pid
#   FiducialsWorldPointXYZ fid pid
#   FiducialsGetPointIdListFromName name
#   FiducialsGetSelectedPointIdListFromName name
#   FiducialsGetAllSelectedPointIdList
#   FiducialsGetActiveSelectedPointIdList
#   FiducialsToTextCards modelid
#   FiducialsPrint2DPoints id
#   FiducialsSliceNumberToRendererName s
#   FiducialsMainFileClose
#   FiducialsUpdateZoom2D s zoom
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC FiducialsInit
# The init procedure that creates tcl variables for that module
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsInit {} {
    global Fiducials Module Volume Model Point
    
    set m Fiducials
    set Module($m,row1List) "Help Display Edit"
    set Module($m,row1Name) "{Help} {Display} {Edit}"
    set Module($m,row1,tab) Edit
    set Module($m,procVTK) FiducialsBuildVTK
    set Module($m,procEnter) FiducialsEnter
    set Module($m,procExit) FiducialsExit
    set Module($m,procMRML) FiducialsUpdateMRML
    set Module($m,procMainFileCloseUpdateEntered) FiducialsMainFileClose
    
    set Module($m,procGUI) FiducialsBuildGUI

    set Module($m,overview) "Create and manage fiducial points, in 2D and 3D"
    set Module($m,author) "Delphine, Nain, SlicerHaker, delfin@mit.edu"
    set Module($m,category) "Registration"

    # Set Dependencies
    set Module($m,depend) ""

    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.69 $} {$Date: 2006/07/27 18:40:57 $}]
    

    # Save some presets and handle them properly
    lappend Module(procStorePresets) FiducialsStorePresets
    lappend Module(procRecallPresets) FiducialsRecallPresets
    # default values for the default list... 
    set Module($m,presets) "name='default' visibility='1' selected=''"
    set Module($m,procMRMLLoad) FiducialsLoadMRML
    MainMrmlAppendnodeTypeList "FiducialsState"
    set Module($m,procRetrievePresets) FiducialsRetrievePresetValues
    set Module($m,procUnparsePresets) FiducialsUnparsePresets

    # Initialize module-level variables
    set Fiducials(renList) "viewRen matRen"
    set Fiducials(renList2D) "sl0Imager sl1Imager sl2Imager"
    set Fiducials(scale) 6
    set Fiducials(minScale) 0
    set Fiducials(maxScale) 40
    set Fiducials(textScale) 4.5
    set Fiducials(textSlant) .333
    set Fiducials(textPush) 10

    set Fiducials(activeListID)  None
    set Fiducials(activePointID) None
    set Fiducials(activeName) "(no point selected)"
    set Fiducials(activeXYZ) ""
    set Fiducials(activeXY) ""
    set Fiducials(activeDescription) ""

    set Fiducials(textSelColor) "1.0 0.5 0.5"
    
    # Append widgets to list that gets refreshed during UpdateMRML
    set Fiducials(mbActiveList) ""
    set Fiducials(mActiveList)  ""
    set Fiducials(scrollActiveList) ""

    set Fiducials(activeList) None
    set Fiducials(defaultNames) ""
    # List of Fiducials node names
    set Fiducials(listOfNames) ""
    set Fiducials(listOfIds) ""
    
    set Fiducials(displayList) ""

    set Fiducials(glyphTypes) {None Vertex Dash Cross ThickCross Triangle Square Circle Diamond Arrow ThickArrow HookedArrow}
    set Fiducials(defaultGlyphType) "None"

    # set this to one when delete a point so that the vtk vars will get reset properly
    set Fiducials(deleteFlag) 0

    # use this as a flag to try and avoid looping too often when called from slices update
    set Fiducials(updating2D) 0
    set Fiducials(updating2DZoom) 0

    set Fiducials(howto) "
You can add Fiducial points in the volume using the 2D slice windows or on any models in the 3D View.

Fiducial points are grouped in lists. Each Fiducial list has a name. You have to select a list before creating a Fiducial point. 
If you want to create a new list, go to the Fiducials module.

To create a Fiducial point: point to the location with the mouse and press 'p' on the keyboard.
To select/unselect a Fiducial point: point to the Fiducial that you want to select/unselect with the mouse and press 'q' on the keyboard.
To delete a Fiducial: point to the Fiducial that you want to delete with the mouse and press 'd' on the keyboard. 
NOTE: it is important to press 'p' and not 'P', 'd' and not 'D' and 'q' and not 'Q'. "

set Fiducials(help) "
Short cuts: <B>p</B> to create, <B>q</B> to select, <B>d</B> to delete. 
<BR>
<BR> Fiducial points can be added by the user on any models or any actor in the 2D slice screens or the 3D screens. Fiducial points are useful for measuring distances and angles, as well as for other modules (i.e slice reformatting)
<BR>
<BR> Fiducial points are grouped in lists. Each Fiducial list has a name. You have to select a list before creating a Fiducial. 
If you want to create a new list, go to the Fiducials module.
<BR>
<BR> You can add Fiducial points on the volume in the 2D slice windows or on any models in the 3D View. Here is how to do it:
<BR> <LI><B>To create a Fiducial point </B>: point to the location with the mouse and press 'p' on the keyboard
<BR> <LI><B> To select/unselect a Fiducial </B>: point to the Fiducial that you want to select/unselect with the mouse and press 'q' on the keyboard. You can also select/unselect Fiducials points in the scrolled textbox.
<BR> <LI> <B> To delete a Fiducial </B>: point to the Fiducial that you want to delete with the mouse and press 'd' on the keyboard. "

}

#-------------------------------------------------------------------------------
# .PROC FiducialsDisplayDescriptionActive
# Formats the active point's location into strings for the Display tab
# .ARGS 
# .END
#-------------------------------------------------------------------------------
proc FiducialsDisplayDescriptionActive {} {
    global Fiducials Point

    if {$::Module(verbose)} {
        puts "FiducialsDisplayDescriptionActive: active list id  $Fiducials(activeListID), active point id = $Fiducials(activePointID), updating name etc"
    }
    set listExists [array names Fiducials $Fiducials(activeListID),pointIdList]
    if { $listExists=="" } { return }

    # change : update even if it's not selected (taking it out for retesting)
    if {[lsearch $Fiducials($Fiducials(activeListID),pointIdList) $Fiducials(activePointID)] != -1} { 
        if { [info command Point($Fiducials(activePointID),node)] != "" } {
            set Fiducials(activeName) [Point($Fiducials(activePointID),node) GetName]
            if {$::Module(verbose)} {
                puts "FiducialsDisplayDescriptionActive:  setting the name $Fiducials(activeName)"
            }
            foreach {x y z} [Point($Fiducials(activePointID),node) GetXYZ] { break }
            set Fiducials(activeXYZ) [format "(%.2f, %.2f, %.2f)" $x $y $z]
            
            foreach {x y s o} [Point($Fiducials(activePointID),node) GetXYSO] { break }
            set Fiducials(activeXY) [format "(%d, %d, win %d, offset %d)" $x $y $s $o]
            
            set Fiducials(activeDescription) [Point($Fiducials(activePointID),node) GetDescription]
        } else {
            if {$::Module(verbose)} {
            puts "FiducialsDisplayDescriptionActive: Point node for pid $Fiducials(activePointID) doesn't exist, didn't update the active description"
            }
        }
    } else {
        if {$::Module(verbose)} {
            puts "FiducialsDisplayDescriptionActive: active point $Fiducials(activePointID) not on active list $Fiducials(activeListID) point list"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsDescriptionActiveUpdated
# Check for an active updated fiducial and set the Point name and description.
# .ARGS 
# .END
#------------------------------------------------------------------------------
proc FiducialsDescriptionActiveUpdated {} {
    global Fiducials Point


    set listExists [array names Fiducials $Fiducials(activeListID),pointIdList]

    if {$::Module(verbose)} {
        puts "FiducialsDescriptionActiveUpdated: active list id = $Fiducials(activeListID), active point id = $Fiducials(activePointID)"
        puts "FiducialsDescriptionActiveUpdated: list exists = $listExists"
    }

    if { $listExists == "" } { 
        if {$::Module(verbose)} {
            puts "FiducialsDescriptionActiveUpdated: list exists is empty, returning"
        }
        return 
    }

    # does the point node exist?
    if {[info command Point($Fiducials(activePointID),node)] == ""} {
        puts "Warning: tried to update a point that doesn't exist, id = $Fiducials(activePointID)"
        return
    }

    # is this name already in use in this list?
    foreach checkPID $Fiducials($Fiducials(activeListID),pointIdList) {
        if {[Point($checkPID,node) GetName] == $Fiducials(activeName)} {
            DevErrorWindow "Cannot use the name $Fiducials(activeName) as it is already in use"
            return
        }
    }

    if {$::Module(verbose)} {
        puts "FiducialsDescriptionActiveUpdated: changing name in the node to $Fiducials(activeName), description to $Fiducials(activeDescription)"
    }
    # find and rename the entries for this fiducial
    set counter 0
    foreach cb  $Fiducials(scrollActiveList) {
        # get the current name to use
        set menu [lindex $Fiducials(mbActiveList) $counter]    
        set name [$menu cget -text]
        # if the name is valid
        if {[lsearch $Fiducials(listOfNames) $name] != -1} {
            # find the old named one and rename it
            set cbindex [$cb index "[Point($Fiducials(activePointID),node) GetName]"]
            if {$cbindex != -1} {
                if {$::Module(verbose) && [regexp ".*Fiducials.*" $cb] != 0} {
                    puts "Found point $Fiducials(activePointID) in the menu $cb at index $cbindex, renaming"
                }
                $cb buttonrename $cbindex $Fiducials(activeName)
            } else {
                puts "FiducialsDescriptionActiveUpdated: didn't find point $Fiducials(activePointID) in the menu $cb"
            } 
       
        }
    }
    
    # now change the node name and description
    Point($Fiducials(activePointID),node) SetName $Fiducials(activeName)
    Point($Fiducials(activePointID),node) SetDescription $Fiducials(activeDescription)
 
    FiducialsUpdateMRML
    # now call this to update the list of fiducials in the data module so the name change propagates
    DataUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC FiducialsEnter
# The Fiducials event manager has bindings for the keys 'p'(create a Fiducial point), 'q'(select/unselect a Fiducial Point), and 'd' (delete a Fiducial Point) - these are defined in TkInteractor.tcl
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsEnter {} {
    global Fiducials Events
 
    # not calling Render3D upon enter
#    Render3D 
}

#-------------------------------------------------------------------------------
# .PROC FiducialsExit
# Stops the interactive fiducials mode, and renders. Called when leaving this module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsExit {} {
    global Events
    
    FiducialsInteractActiveEnd
    # render is called in the proc above
    # Render3D
}


#-------------------------------------------------------------------------------
# .PROC FiducialsBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc FiducialsBuildGUI {} {
    global Gui Fiducials Module Volume Model

    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(Fiducials,fStuff)

    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Display
    # Edit
    #   Top
    #   Bottom
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------

    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help $Fiducials(help)

    regsub -all "\n" $help {} help
    MainHelpApplyTags Fiducials $help
    MainHelpBuildGUI Fiducials

    #-------------------------------------------
    # Display frame
    #-------------------------------------------
    set fDisplay $Module(Fiducials,fDisplay)
    set f $fDisplay

    foreach frame "buttons list scroll options2d" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Display->Buttons frame
    #-------------------------------------------
    set f $fDisplay.fbuttons

    DevAddButton $f.bAll "Show All" \
            "FiducialsSetFiducialsVisibility ALL; Render3D" 10 
    DevAddButton $f.bNone "Show None" \
            "FiducialsSetFiducialsVisibility None; Render3D" 10 
    pack $f.bAll $f.bNone -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # fDisplay->Grid frame
    #-------------------------------------------
    set f $fDisplay.flist
    eval {label $f.lV -text "Visibility"} $Gui(WLA)
    eval {label $f.lO -text "Symbol Size" } $Gui(WLA)
    eval {label $f.tO -text "Text Size"} $Gui(WLA) 
    grid $f.lV $f.lO $f.tO  -pady 0 -padx 5
    

    set f $fDisplay.fscroll
    
    DevCreateScrollList $Module(Fiducials,fDisplay).fscroll \
        FiducialsCreateGUI \
        FiducialsConfigScrolledGUI \
        "$Fiducials(idList)"

    set Fiducials(canvasScrolledGUI)  $Module(Fiducials,fDisplay).fscroll.cGrid
    set Fiducials(fScrolledGUI)       $Fiducials(canvasScrolledGUI).fListItems

    # Done in MainModelsCreateGUI

    #-------------------------------------------
    # Display->options2d frame
    #-------------------------------------------
    set f $fDisplay.foptions2d

    # menu to select the 2d glyph symbols - one source, so affects all fid lists
    eval {label $f.lSymbols -text "2D Fiducial Symbol: "} $Gui(WLA) \
        {-bg $Gui(activeWorkspace)}
    eval {menubutton $f.mbSymbols -text $Fiducials(defaultGlyphType) -relief raised -bd 2 -width 15 \
              -menu $f.mbSymbols.m} $Gui(WMBA)
    eval {menu $f.mbSymbols.m} $Gui(WMA)
    pack $f.lSymbols $f.mbSymbols -side left -padx $Gui(pad) -pady 0 
    foreach s $Fiducials(glyphTypes) {
        $f.mbSymbols.m add command -label $s \
            -command "FiducialsSetSymbol2D $s"
    }
    #-------------------------------------------
    # Edit frame
    #-------------------------------------------
    set fEdit $Module(Fiducials,fEdit)
    set f $fEdit

    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Edit->Top frame
    #-------------------------------------------
    set f $fEdit.fTop
        
    eval {label $f.lCreateList -text "Create a Fiducials List:"} $Gui(WLA)
    eval {entry $f.eCreateList -width 15 -textvariable Fiducials(newListName) } \
                $Gui(WEA)
    bind $f.eCreateList <Return> {FiducialsCreateFiducialsList "default" $Fiducials(newListName)}

    pack $f.lCreateList $f.eCreateList -side left -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Edit->Middle frame
    #-------------------------------------------
    set f $fEdit.fMiddle

    FiducialsAddActiveListFrame $f 275 10 
}

#-------------------------------------------------------------------------------
# .PROC FiducialsCreateGUI
# Makes the GUI for each model on the Fiducials->Display panel.<br>
# This is called for each new model.<br>
# Also makes the popup menu that comes up when you right-click a model.
#
# .ARGS
# widget f the frame to create the GUI in
# int id the id of the model
# .END
#-------------------------------------------------------------------------------
proc FiducialsCreateGUI {f id} {
    global Gui Model Color Fiducials

    lappend Fiducials(displayList) $id

    # puts "Creating GUI for model $m"        
    # If the GUI already exists, then just change name.
    if {[info command $f.c$id] != ""} {
        $f.c$id config -text "[Fiducials($id,node) GetName]"
        return 0
    }
    
    # Name / Visible
    set name [Fiducials($id,node) GetName]
    eval {checkbutton $f.c$id \
        -text [Fiducials($id,node) GetName] -variable Fiducials($id,visibility)        -width 17 -indicatoron 0 \
        -command "FiducialsSetFiducialsVisibility [Fiducials($id,node) GetName]; Render3D"} $Gui(WCA)
    
    # menu
    eval {menu $f.c$id.men} $Gui(WMA)
    set men $f.c$id.men
   
    $men add command -label "Delete" -command "FiducialsDeleteList $name; Render3D"
    $men add command -label "-- Close Menu --" -command "$men unpost"
    bind $f.c$id <Button-3> "$men post %X %Y"
    
    # Scale
    #eval {entry $f.e${id} -textvariable Fiducials($id,scale) -width 3} $Gui(WEA)
    #bind $f.e${id} <Return> "FiducialsSetScale $id; Render3D"
    #bind $f.e${id} <FocusOut> "FiducialsSetScale $id; Render3D"
    eval {scale $f.s${id} -from 0.0 -to 80.0 -length 40 \
        -variable Fiducials($id,scale) \
        -command "FiducialsSetScale $id" \
        -resolution 1} $Gui(WSA) {-sliderlength 10 }

    # text Scale
    #eval {entry $f.et${id} -textvariable Fiducials($id,textScale) -width 3} $Gui(WEA)
    #bind $f.et${id} <Return> "FiducialsSetTxtScale $id; Render3D"
    #bind $f.et${id} <FocusOut> "FiducialsSetTxtScale $id; Render3D"
    eval {scale $f.st${id} -from 0.0 -to 20.0 -length 40 \
        -variable Fiducials($id,textScale) \
        -command "FiducialsSetTxtScale $id" \
        -resolution 0.2} $Gui(WSA) {-sliderlength 10 }
        

    # 2d symbols
    
    eval grid $f.c${id}  $f.s${id}  $f.st${id} -pady 2 -padx 2 -sticky we

    return 1

}

#-------------------------------------------------------------------------------
# .PROC FiducialsDeleteGUI
# Delete the gui elements for this model id.
# .ARGS
# windowpath f the path to the frame containing elements for this model
# int m model id
# .END
#-------------------------------------------------------------------------------
proc FiducialsDeleteGUI {f m} {
    global Gui Model Color Fiducials


    # If the GUI is already deleted, return
    if {[info command $f.c$m] == ""} {
        return 0
    }

    set index [lsearch $Fiducials(displayList) $m]
    set Fiducials(displayList) [lreplace $Fiducials(displayList) $index $index]

    # Destroy TK widgets
    destroy $f.c$m
    destroy $f.e$m
    destroy $f.st$m
    destroy $f.s$m

    return 1
}

#-------------------------------------------------------------------------------
# .PROC FiducialsConfigScrolledGUI
# 
# Set the dimensions of the scrolledGUI
#
# .ARGS
# frame  canvasScrolledGUI  The canvas around the scrolled frame
# frame  fScrolledGUI       The frame with the item list of models
# .END   
#-------------------------------------------------------------------------------
proc FiducialsConfigScrolledGUI {canvasScrolledGUI fScrolledGUI} {
    global Fiducials

    set f      $fScrolledGUI
    set canvas $canvasScrolledGUI
    set m [lindex $Fiducials(idList) 0]
    # y spacing important for calculation of frame height for scrolling
    set pady 2

    if {$m != ""} {
        # Find the height of a single button
        # Must use $f.s$m since the scrollbar ("s") fields are tallest
        set lastButton $f.c$m
        # Find how many modules (lines) in the frame
        set numLines 0
        foreach m $Fiducials(idList) {
            incr numLines
        }

        # Find the height of a line
        set incr [expr {[winfo reqheight $lastButton] + 2*$pady}]
        # Find the total height that should scroll
        set height [expr {$numLines * $incr}]
        # Find the width of the scrolling region
        update;     # wait for some stuff to be done before requesting
        # window positions
        set last_x [winfo x $lastButton]
        set width [expr $last_x + [winfo reqwidth $lastButton]]
        $canvas config -scrollregion "0 0 $width $height"
        $canvas config -yscrollincrement $incr -confine true
        $canvas config -xscrollincrement 1 -confine true
    }
#        $canvas config -scrollregion "0 0 100 300"
#        $canvas config -yscrollincrement 1 -confine true
#        $canvas config -xscrollincrement 1 -confine true

}

#-------------------------------------------------------------------------------
# .PROC FiducialsBuildVTK
#
# Create the VTK structures used for displaying Fiducials.
# .END
#-------------------------------------------------------------------------------
proc FiducialsBuildVTK {} {
    global Fiducials Point

    # create the picker
    vtkCellPicker Fiducials(picker)
    Fiducials(picker) SetTolerance 0.001

    ########################################################
    #
    #       CREATE THE VTK SOURCE FOR THE DIAMOND FIDUCIALS
    #
    ########################################################
    vtkPoints Fiducials(symbolPoints)
    Fiducials(symbolPoints) SetNumberOfPoints 6
      Fiducials(symbolPoints) InsertPoint 0 1 0 0
      Fiducials(symbolPoints) InsertPoint 1 0 1 0
      Fiducials(symbolPoints) InsertPoint 2 0 0 1
      Fiducials(symbolPoints) InsertPoint 3 -1 0 0
      Fiducials(symbolPoints) InsertPoint 4 0 -1 0
      Fiducials(symbolPoints) InsertPoint 5 0 0 -1
    vtkCellArray Fiducials(symbolPolys)
      Fiducials(symbolPolys) InsertNextCell 4
        Fiducials(symbolPolys) InsertCellPoint 0
        Fiducials(symbolPolys) InsertCellPoint 1
        Fiducials(symbolPolys) InsertCellPoint 3
        Fiducials(symbolPolys) InsertCellPoint 4
      Fiducials(symbolPolys) InsertNextCell 4
        Fiducials(symbolPolys) InsertCellPoint 1
        Fiducials(symbolPolys) InsertCellPoint 2
        Fiducials(symbolPolys) InsertCellPoint 4
        Fiducials(symbolPolys) InsertCellPoint 5
      Fiducials(symbolPolys) InsertNextCell 4
        Fiducials(symbolPolys) InsertCellPoint 2
        Fiducials(symbolPolys) InsertCellPoint 0
        Fiducials(symbolPolys) InsertCellPoint 5
        Fiducials(symbolPolys) InsertCellPoint 3
    vtkCellArray Fiducials(symbolLines)
      Fiducials(symbolLines) InsertNextCell 2
        Fiducials(symbolLines) InsertCellPoint 0
        Fiducials(symbolLines) InsertCellPoint 3
      Fiducials(symbolLines) InsertNextCell 2
        Fiducials(symbolLines) InsertCellPoint 1
        Fiducials(symbolLines) InsertCellPoint 4
      Fiducials(symbolLines) InsertNextCell 2
        Fiducials(symbolLines) InsertCellPoint 2
        Fiducials(symbolLines) InsertCellPoint 5

    vtkPolyData Fiducials(symbolPD)
    Fiducials(symbolPD) SetPoints Fiducials(symbolPoints)
    Fiducials(symbolPoints) Delete
    Fiducials(symbolPD) SetPolys Fiducials(symbolPolys)
    Fiducials(symbolPD) SetLines Fiducials(symbolLines)
    Fiducials(symbolPolys) Delete
    Fiducials(symbolLines) Delete

    vtkTransform Fiducials(tmpXform)
      Fiducials(tmpXform) PostMultiply
      Fiducials(tmpXform) AddObserver WarningEvent ""

    ########################################################
    #
    #       CREATE THE VTK SOURCE FOR THE DIAMOND FIDUCIALS
    #
    ########################################################

    vtkSphereSource   Fiducials(sphereSource)     
    Fiducials(sphereSource) SetRadius 0.3
    Fiducials(sphereSource)     SetPhiResolution 10
    Fiducials(sphereSource)     SetThetaResolution 10
    
    ########################################################
    #
    #       CREATE THE VTK SOURCE FOR THE 2D CROSS FIDUCIALS
    #
    ########################################################
    vtkGlyphSource2D Fiducials(2DSource)
      Fiducials(2DSource) SetGlyphTypeTo${Fiducials(defaultGlyphType)}
      # Fiducials(2DSource) SetScale 4
      Fiducials(2DSource) FilledOff
     # Fiducials(2DSource) SetRotationAngle 45

    #vtkGlyph2D Fiducials(2DGlyph)
    #Fiducials(2DGlyph) SetInput [Fiducials(2DSource) GetOutput]
}

#-------------------------------------------------------------------------------
# .PROC FiducialsVTKCreateFiducialsList
#
# Create a new set of fiducials vtk variables/actors corresponding to that list
# id, if they don't exist yet.
# .ARGS 
# int id the mrml id of the Fiducials list
# str type the type of the fiducial, if endoscopic or sphereSource, use a sphere, else use the standard glyph
# float scale optional scale of the 3d symbol, uses Fiducials(scale) if default of empty string
# float textScale optional scale of the fiducial's text, uses Fiducials(textScale) if default of empty string
# int visibility optional, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc FiducialsVTKCreateFiducialsList { id type {scale ""} {textScale ""} {visibility ""}} {
    global Fiducials Mrml Module
    
    if {$::Module(verbose)} {
        puts "FiducialsVTKCreateFiducialsList id = $id"
    }
    if {$scale == "" } {
        set scale $Fiducials(scale)
    }
    if {$textScale == "" } {
        set textScale $Fiducials(textScale)
    }

    set Fiducials($id,scale) $scale
    set Fiducials($id,textScale) $textScale
    
    set Fiducials($id,scale) [Fiducials($id,node) GetSymbolSize]
    set Fiducials($id,textScale) $textScale

    if {[info command Fiducials($id,points)] == ""} {
        vtkPoints Fiducials($id,points)
    } else {
    #    Fiducials($id,points) Initialize
    }
    
    if {[info command Fiducials($id,scalars)] == ""} {
        vtkFloatArray Fiducials($id,scalars)
    } else {
    #    Fiducials($id,scalars) Initialize
    } 
    
    if {[info command Fiducials($id,pointsPD)] == ""} {
        vtkPolyData Fiducials($id,pointsPD)
    } else {
        # Fiducials($id,pointsPD) Initialize
    }
    Fiducials($id,pointsPD) SetPoints Fiducials($id,points)
    [Fiducials($id,pointsPD) GetPointData] SetScalars Fiducials($id,scalars)

    if {[info command  Fiducials($id,glyphs)] == ""} {
        vtkGlyph3D Fiducials($id,glyphs)
    }
    
    # set the default size for text 
    if {[info command Point($id,textXform)] == ""} {
        vtkTransform Point($id,textXform)
        Point($id,textXform) AddObserver WarningEvent ""
    } else {
         Point($id,textXform) Identity
    }
    Point($id,textXform) Translate 0 0 $Fiducials(textPush)
    [Point($id,textXform) GetMatrix] SetElement 0 1 .333
    Point($id,textXform) Scale $textScale $textScale 1

    # set the default size for symbols
    if {[info command Fiducials($id,symbolXform)] == ""} {
        vtkTransform Fiducials($id,symbolXform)
        Fiducials($id,symbolXform) AddObserver WarningEvent ""
    } else {
        Fiducials($id,symbolXform) Identity
    }
    Fiducials($id,symbolXform) Scale $scale $scale $scale
    

    if {[info command Fiducials($id,XformFilter)] == ""} {
        vtkTransformPolyDataFilter Fiducials($id,XformFilter)
    }
    if { ($type == "endoscopic") || ($type == "sphereSymbol") } {
        Fiducials($id,XformFilter) SetInput [Fiducials(sphereSource) GetOutput]
    } else {
        Fiducials($id,XformFilter) SetInput Fiducials(symbolPD)
    }
    Fiducials($id,XformFilter) SetTransform Fiducials($id,symbolXform)
    
    Fiducials($id,glyphs) SetSource \
        [Fiducials($id,XformFilter) GetOutput]
    
    Fiducials($id,glyphs) SetInput Fiducials($id,pointsPD)
    Fiducials($id,glyphs) SetScaleFactor 1.0
    Fiducials($id,glyphs) ClampingOn
    Fiducials($id,glyphs) ScalingOff
    Fiducials($id,glyphs) SetRange 0 1
    
    if {[info command Fiducials($id,mapper)] == ""} {
        vtkPolyDataMapper Fiducials($id,mapper)
    }
    Fiducials($id,mapper) SetInput [Fiducials($id,glyphs) GetOutput]
    
    [Fiducials($id,mapper) GetLookupTable] SetNumberOfTableValues 2

    foreach {r1 g1 b1} [Fiducials($id,node) GetColor] { break }
    foreach {r2 g2 b2} $Fiducials(textSelColor) { break }

    [Fiducials($id,mapper) GetLookupTable] SetTableValue 0 $r1 $g1 $b1 1.0
    [Fiducials($id,mapper) GetLookupTable] SetTableValue 1 $r2 $g2 $b2 1.0

    if {[info command Fiducials($id,xform)] == ""} {
        vtkMatrix4x4 Fiducials($id,xform)
    }
    Mrml(dataTree) ComputeNodeTransform Fiducials($id,node) \
        Fiducials($id,xform)

    # create a different actor for each renderer
    foreach r $Fiducials(renList) {
        if {[info command Fiducials($id,actor,$r)] == ""} {
            vtkActor Fiducials($id,actor,$r)
        }
        Fiducials($id,actor,$r) SetMapper Fiducials($id,mapper)
        [Fiducials($id,actor,$r) GetProperty] SetColor 1 0 0
        [Fiducials($id,actor,$r) GetProperty] SetInterpolationToFlat
        Fiducials($id,actor,$r) SetUserMatrix Fiducials($id,xform)
        # can re-add an actor w/o error 
        $r AddActor Fiducials($id,actor,$r)
    }  
   
    # ---------
    # 2D glyphs
    # ---------
    if {$::Module(verbose)} {
        puts "Creating a 2d glyph for id = $id"
    }

    # create different points, sclars, polydata, glyph, mapper and actor for each slice window
    foreach r $Fiducials(renList2D) {
        if {[info command Fiducials($id,points2D,$r)] == ""} {
            vtkPoints Fiducials($id,points2D,$r)
        }
    

        if {[info command Fiducials($id,scalars2D,$r)] == ""} {
            vtkFloatArray Fiducials($id,scalars2D,$r)
        }
        if {[info command Fiducials($id,pointsPD2D,$r)] == ""} {
            vtkPolyData Fiducials($id,pointsPD2D,$r)
        }

        Fiducials($id,pointsPD2D,$r) SetPoints  Fiducials($id,points2D,$r)
        [Fiducials($id,pointsPD2D,$r) GetPointData] SetScalars Fiducials($id,scalars2D,$r)

    
        if {[info command Fiducials($id,glyphs2D,$r)] == ""} {
            vtkGlyph2D Fiducials($id,glyphs2D,$r)
        }
        Fiducials($id,glyphs2D,$r) SetSource [Fiducials(2DSource) GetOutput]

        # Fiducials($id,glyphs2D,$r) SetInput [Fiducials(2DSource) GetOutput]
        Fiducials($id,glyphs2D,$r) SetInput Fiducials($id,pointsPD2D,$r)
        Fiducials($id,glyphs2D,$r) SetScaleFactor 1.0
        Fiducials($id,glyphs2D,$r) ClampingOn
        Fiducials($id,glyphs2D,$r) ScalingOff
        Fiducials($id,glyphs2D,$r) SetRange 0 1
        
   
        if {[info command Fiducials($id,mapper2D,$r)] == ""} {
            vtkPolyDataMapper2D Fiducials($id,mapper2D,$r)
        }
        Fiducials($id,mapper2D,$r) SetInput [Fiducials($id,glyphs2D,$r) GetOutput]
        [Fiducials($id,mapper2D,$r) GetLookupTable] SetNumberOfTableValues 2

        # use colours from 3d glyph
        [Fiducials($id,mapper2D,$r) GetLookupTable] SetTableValue 0 $r1 $g1 $b1 1.0
        [Fiducials($id,mapper2D,$r) GetLookupTable] SetTableValue 1 $r2 $g2 $b2 1.0

        # create an actor for the right 2D renderer
        if {0} {
            # need the pid
            set xyso [Point($pid,node) GetXYSO]
            set ren2d [format "sl%dImager" [lindex $xyso 2]]
            if {$::Module(verbose)} {
                puts "Point($pid,node) XYSO = $xyso, slice num = [lindex $xyso 2], renderer = $ren2d"
            }
        }
        # create an actor for the 2d renderer
        if {[info command Fiducials($id,actor2D,$r)] == ""} {
            vtkActor2D Fiducials($id,actor2D,$r)
        }
        Fiducials($id,actor2D,$r) SetMapper Fiducials($id,mapper2D,$r)
        [Fiducials($id,actor2D,$r) GetProperty] SetColor 1 0 0
        $r AddActor2D Fiducials($id,actor2D,$r)
    
    }

    # now set the visibility
    FiducialsSetFiducialsVisibility $Fiducials($id,name) $visibility
}

#-------------------------------------------------------------------------------
# .PROC FiducialsVTKCreatePoint
#
# Create a point follower (vtk actor). Will only declare vtk variables if they don't exist yet.
# .ARGS 
# int fid Mrml id of the list that contains the new Point
# int pid Mrml id of the Point
# .END
#-------------------------------------------------------------------------------
proc FiducialsVTKCreatePoint { fid pid visibility} {
    global Fiducials Point Mrml Module
    
    if { [FiducialsUseTextureText] } {   
        if {[info command Point($pid,text)] == ""} {
            # create it
            vtkTextureText Point($pid,text)
        }
        set Fiducials(FontManager) [Point($pid,text) GetFontParameters]
        [Point($pid,text) GetFontParameters] SetFontFileName "ARIAL.TTF"
        [Point($pid,text) GetFontParameters] SetBlur 2
        [Point($pid,text) GetFontParameters] SetStyle 2
        Point($pid,text) SetText "   [Point($pid,node) GetName]"
        Point($pid,text) CreateTextureText
    } else {
        if {[info command Point($pid,text)] == ""} {
            # create it
            vtkVectorText Point($pid,text)
        }
        Point($pid,text) SetText "   [Point($pid,node) GetName]"
        if {[info command Point($pid,mapper)] == ""} {
            vtkPolyDataMapper Point($pid,mapper)
        }
        Point($pid,mapper) SetInput [Point($pid,text) GetOutput]
    }
    # mikey - wasn't this redundant??
    #Point($pid,text) SetText "   [Point($pid,node) GetName]"

    foreach r $Fiducials(renList) {
        if {[info command Point($pid,follower,$r)] == ""} {
            vtkFollower Point($pid,follower,$r)
        }
        if { [FiducialsUseTextureText] } {
            Point($pid,follower,$r) SetMapper [[Point($pid,text) GetFollower] GetMapper]
            Point($pid,follower,$r) SetTexture [Point($pid,text) GetTexture]
        } else {
            Point($pid,follower,$r) SetMapper Point($pid,mapper)
        }
        Point($pid,follower,$r) SetCamera [$r GetActiveCamera]

        # user matrix was making text disappear - changed to scale -sp 2002-12-15
        #Point($pid,follower,$r) SetUserMatrix [Point($fid,textXform) GetMatrix]
        Point($pid,follower,$r) SetScale $Fiducials($fid,textScale)

        Point($pid,follower,$r) SetPickable 0
             eval [Point($pid,follower,$r) GetProperty] SetColor [Fiducials($fid,node) GetColor]

        # check if it was already added
        $r AddActor Point($pid,follower,$r)
        Point($pid,follower,$r) SetVisibility $visibility
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsVTKUpdatePoints
#
# Update the points contained within all Fiducials/EndFiducials node after 
# the UpdateMRML.
# .ARGS
# int fid the id of the fiducials list
# int symbolSize used to scale the fiducial glyph
# int textSize used to scale the glyph's associated text
# .END
#-------------------------------------------------------------------------------
proc FiducialsVTKUpdatePoints {fid symbolSize textSize} {
    global Fiducials Point Mrml Module
    
    if {$::Module(verbose)} {
        puts "FiducialsVTKUpdatePoints: fid $fid. Point id list = $Fiducials($fid,pointIdList)"
    }
    Mrml(dataTree) ComputeNodeTransform Fiducials($fid,node) \
        Fiducials($fid,xform)
    Fiducials(tmpXform) SetMatrix Fiducials($fid,xform)
    Fiducials($fid,points) SetNumberOfPoints 0
    Fiducials($fid,scalars) SetNumberOfTuples 0

    foreach pid $Fiducials($fid,pointIdList) {
        set xyz [Point($pid,node) GetXYZ]
        eval Fiducials($fid,points) InsertNextPoint $xyz
        Fiducials($fid,scalars) InsertNextTuple1 0        
        #eval Fiducials(tmpXform) SetPoint $xyz 1
        #set xyz [Fiducials(tmpXform) GetPoint]
        eval Fiducials(tmpXform) TransformPoint $xyz
        foreach r $Fiducials(renList) {
            eval Point($pid,follower,$r) SetPosition $xyz
        }
        Point($pid,text) SetText "   [Point($pid,node) GetName]"
    }

    # color the selected glyphs (by setting their scalar to 1)
    if {[info exists Fiducials($fid,oldSelectedPointIdList)]} {
        foreach pid $Fiducials($fid,pointIdList) {
            # see if that point was previously selected
            if {[lsearch $Fiducials($fid,oldSelectedPointIdList) $pid] != -1} { 
                if {$::Module(verbose)} { 
                    puts "FiducialsVTKUpdatePoints: pid $pid was selected"
                }

                set Fiducials(activeListID)  $fid
                #set Fiducials(activePointID) $pid

                # color the point
                Fiducials($fid,scalars) SetTuple1 [FiducialsScalarIdFromPointId $fid $pid] 1
                # color the text
                foreach r $Fiducials(renList) {
                    eval [Point($pid,follower,$r) GetProperty] SetColor $Fiducials(textSelColor)
                }
                
                # add it to the current list of selected items if it's not there already
                if {[lsearch $Fiducials($fid,selectedPointIdList) $pid] == -1} {
                    lappend Fiducials($fid,selectedPointIdList) $pid
                }
            }
        }
    }
    # now do it for the 2d points
    FiducialsVTKUpdatePoints2D $fid

    if {$::Module(verbose)} {
        puts "FiducialsVTKUpdatePoints: calling FiducialsDisplayDescriptionActive for list $fid, active point = $Fiducials(activePointID)"
    }
    FiducialsDisplayDescriptionActive

    Fiducials($fid,pointsPD) Modified
}

#-------------------------------------------------------------------------------
# .PROC FiducialsVTKUpdatePoints2D
#
# Update the 2d points contained within all Fiducials/EndFiducials node after 
# the UpdateMRML. Can be called from MainSlicesSetOffset to update which 2d
# fiducials are visible on a given slice. Relies on Fiducials($fid,selectedPointIdList)
# having been set properly via a call to FiducialsVTKUpdatePoints
# .ARGS
# int fid the fiducial list id
# string renList optional renderer(s) to update, defaults to all of them
# .END
#-------------------------------------------------------------------------------
proc FiducialsVTKUpdatePoints2D { fid {renList ""} } {
    global Fiducials Point Module
    
    # check to see that we're not already updating, can get into inf loop 
    # when moving sliders sometimes
    if {$Fiducials(updating2D) == 1} {
        if {$::Module(verbose)} {
            puts "FiducialsVTKUpdatePoints2D: already updating, returning"
        }
        return
    } 
    set Fiducials(updating2D) 1

    if {$renList == ""} {
        set renList $Fiducials(renList2D)
    }

    if {$::Module(verbose)} {
        puts "FiducialsVTKUpdatePoints2D updating fid list $fid for renderers $renList"
    }

    foreach r $renList {
        if {[info command Fiducials($fid,points2D,$r)] == ""} {
            if {$::Module(verbose)} { puts  "FiducialsVTKUpdatePoints2D: Points list for fiducials list $fid and renderer $r does not exist, returning (could be first call when create start/end list nodes)"}
           return
        }
        Fiducials($fid,points2D,$r) SetNumberOfPoints 0
        Fiducials($fid,scalars2D,$r) SetNumberOfTuples 0


        foreach pid $Fiducials($fid,pointIdList,$r) {
            if {[info command Point($pid,node)] == ""} {
                puts "No point node for $pid"
                break
            }
            set xyso [Point($pid,node) GetXYSO]
            if {$::Module(verbose)} {
                puts "FiducialsVTKUpdatePoints: creating 2d points list: fid $fid pid $pid xyso $xyso r $r"
            }
            
            # get the slice number
            set s [lindex $xyso 2]
            # get the slice offset
            set o [lindex $xyso 3]
            # set the point to x,y and the slice offset
            set xy "[lrange $xyso 0 1] $o"

            if {$::Module(verbose)} {
                puts "xyso = $xyso, s = $s, r = $r, o = $o"
            }

            # only add the point to the list if the current slice being displayed 
            # matches the slice number of the point
            if {$o == $::Slice($s,offset)} {
                eval Fiducials($fid,points2D,$r) InsertNextPoint $xy
                # 1 = selected, 0 == not selected, so set them all not, and redo it in next loop
                Fiducials($fid,scalars2D,$r) InsertNextTuple1 0
            } else {
                if {$::Module(verbose)} {
                    puts "(not adding point $pid, since offset $o != offset $::Slice($s,offset))"
                }
            }
        }
    
    }
    # the colour the selected glpyhs by setting their scalar to 1
    # only check the selected point list, as it should have been updated in the 3D call
    if {[info exists Fiducials($fid,selectedPointIdList)]} {
        foreach pid $Fiducials($fid,pointIdList) {
            if {[lsearch $Fiducials($fid,selectedPointIdList) $pid] != -1} { 
                if {[info command Point($pid,node)] != ""} {
                    set xyso [Point($pid,node) GetXYSO]
                    set s [lindex $xyso 2]
                    set r [FiducialsSliceNumberToRendererName $s]
                    # get the slice offset
                    set o [lindex $xyso 3]
                    # only do this if the point is visible on this slice
                    if {$o == $::Slice($s,offset)} {
                        if {$::Module(verbose)} {
                            puts "FiducialsVTKUpdatePoints2D: setting $fid scalars2D $r tuple 1 for pid $pid"
                        }
                        set scalarIndex [FiducialsScalarIdFromPointId2D $fid $pid $r]
                        if {$scalarIndex != -1} {
                            if {$::Module(verbose)} {
                                puts "\tgot scalar index $scalarIndex from fid list $fid pid $pid r $r"
                            }
                            Fiducials($fid,scalars2D,$r) SetTuple1 $scalarIndex 1
                        } else { 
                            # it's not on this slice offset
                            if {$::Module(verbose)} { 
                                puts "\tnot setting tuple1 for pid $pid $r, scalar index == -1" 
                            } 
                        }
                    } else {
                        if {$::Module(verbose)} { 
                            puts "FiducialsVTKUpdatePoints: NOT setting $fid scalars2D $r tuple 1 for pid $pid, since offset $o != $::Slice($s,offset)"
                        }
                    }
                }
            }
        }
    }
    foreach r $renList {
        if {[info command Fiducials($fid,pointsPD2D,$r)] != ""} {
            Fiducials($fid,pointsPD2D,$r) Modified
        } else {
            DevErrorWindow "Fiducials($fid,pointsPD2D,$r) does not exist"
        }
    }
    
    # release the flag    
    set Fiducials(updating2D) 0
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSetTxtScale
#
# Set the scale of the Fiducials text.
# .ARGS
# int id the id of the fiducials list.
# float val optional, otherwise use Fiducial(id,textScale). Defaults to empty string. 
# .END
#-------------------------------------------------------------------------------
proc FiducialsSetTxtScale { id {val ""} } {
    global Fiducials Point

    if { $val == ""} {
        set val $Fiducials($id,textScale)
    }

    foreach pid $Fiducials($id,pointIdList) {
        foreach r $Fiducials(renList) {
            if {[info command Point($pid,follower,$r)] == ""} {
                puts "ERROR: FiducialsSetTxtScale: no follower for point $pid in renderer $r"
            } else {
                Point($pid,follower,$r) SetScale $val
            }
        }
    }
    Fiducials($id,node) SetTextSize $val

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSetScale
#
# Set the scale of the Fiducials symbol.
# .ARGS
# int id the id of the fiducials list.
# float val optional, otherwise use Fiducial(id,scale). Defaults to empty string. 
# .END
#-------------------------------------------------------------------------------
proc FiducialsSetScale { id {val ""}} {
    global Fiducials
    
    if { $val == ""} {
        set val $Fiducials($id,scale)
    }
    
    Fiducials($id,node) SetSymbolSize $val
    if {[info command Fiducials($id,symbolXform)] != ""} {
        Fiducials($id,symbolXform) Identity
        Fiducials($id,symbolXform) Scale $val $val $val
    }

    # 2d symbols
    if {[info command Fiducials(2DSource)] != ""} {
        Fiducials(2DSource) SetScale $val
        RenderSlices
    }

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSetSymbol2D
# Set the glyph type of the Fiducials(2DSource)
# .ARGS
# string symbol defaults to Cross, valid values found in $Fiducials(glyphTypes)
# .END
#-------------------------------------------------------------------------------
proc FiducialsSetSymbol2D { {symbol Cross} } {
    global Fiducials

    if {[lsearch $Fiducials(glyphTypes) $symbol] != -1} {
        # valid type
        $::Module(Fiducials,fDisplay).foptions2d.mbSymbols configure -text $symbol
        Fiducials(2DSource) SetGlyphTypeTo${symbol}
        # reset the default scale as well
        # Fiducials(2DSource) SetScale $Fiducials(0,scale)
        RenderAll
    } else {
        puts "ERROR: invalid glyph type $symbol, must be in list:\n$Fiducials(glyphTypes)"
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsUpdateMRML
#
# Update the Fiducials actors and scroll textboxes based on the current Mrml Tree.
# Also update presets.
# .END
#-------------------------------------------------------------------------------
proc FiducialsUpdateMRML {} {
    global Fiducials Mrml Module Models Model Landmark Path EndPath

    if {$::Module(verbose)} {
        puts "FiducialsUpdateMRML: start."
    }

    # start callback in case any module wants to know that Fiducials are 
    # about to be updated
    foreach m $Module(idList) {
        if {[info exists Module($m,fiducialsStartUpdateMRMLCallback)] == 1} {
            if {$Module(verbose) == 1} {puts "\n\nFiducials Start Callback: $m = $Module($m,fiducialsStartUpdateMRMLCallback)"}
            $Module($m,fiducialsStartUpdateMRMLCallback)  
        }
    }
       
    ############################################################
    # Read through the Mrml tree and create all the variables 
    # and vtk entities for the fiducial/points nodes
    ############################################################
    
    Mrml(dataTree) ComputeTransforms
    Mrml(dataTree) InitTraversal
    set item [Mrml(dataTree) GetNextItem]
 
    #reset all data
    if {$::Module(verbose)} {
        puts "FidUpdateMrml: delete flag = $Fiducials(deleteFlag)"
    }
    FiducialsResetVariables $Fiducials(deleteFlag)
    set readOldNodesForCompatibility 0
    set gui 0

    # the next line is for the Fiducials->Display panel where all lists have a 
    # corresponding button with attributes when you right click
    
    # the "removeFromDisplayList" variable holds all the names of 
    # the lists that have a button on the Fiducials-> Display panel 
    # before the Mrml update
    # Since we are reading through the new updated Mrml tree, 
    # we will delete from the "removeFromDisplayList" all the lists that
    # still exist and therefore keep their button
    # The remaining lists in the "removeFromDisplayList" will be deleted from
    # the display

    set Fiducials(removeDisplayList) $Fiducials(displayList)
    
    # keep track of which scene we're in 
    set sceneName ""

    while { $item != "" } {
        
        if { [$item GetClassName] == "vtkMrmlFiducialsNode"} {
            set fid [$item GetID]
            # get its name
            # if there is no name, give it one
            if {[$item GetName] == ""} {
                $item SetName "Fiducials$fid"
            }
            set name [$item GetName]

            lappend Fiducials(listOfNames) $name
            lappend Fiducials(listOfIds) $fid
            # reset/create variables for that list
            set Fiducials($fid,name) $name
            set Fiducials($name,fid) $fid
            set Fiducials($fid,pointIdList) ""
            foreach r $Fiducials(renList2D) {
                set Fiducials($fid,pointIdList,$r) ""
            }
            # puts "FidUpdateMrml: clearing out $fid selectedPointIdList"
            # set Fiducials($fid,selectedPointIdList) ""
            if {[info exists Fiducials($fid,oldSelectedPointIdList)] == 0 } {
                set Fiducials($fid,oldSelectedPointIdList) ""
            }
            set Fiducials($fid,pointsExist) 0

            # get type and options to create the right type of list
            set type [$item GetType]
            set symbolSize [$item GetSymbolSize]
            set Fiducials($fid,scale) $symbolSize
            if {$type == "endoscopic"} {
                $item SetTextSize 0
            }
            set textSize [$item GetTextSize]
            set Fiducials($fid,textScale) $textSize
            set visibility [$item GetVisibility]
            set Fiducials($fid,visibility) $visibility

            FiducialsVTKCreateFiducialsList $fid $type $symbolSize $textSize $visibility
        }

        if { [$item GetClassName] == "vtkMrmlPointNode" } {
            set pid [$item GetID]

            if {[info exist fid] == 1} {
                lappend Fiducials($fid,pointIdList) $pid
                if {$::Module(verbose)} {
                    puts "FidUpdateMrml: added $pid to $fid's point list: $Fiducials($fid,pointIdList) "
                }
                #set its index based on its position in the list
                Point($pid,node) SetIndex [lsearch $Fiducials($fid,pointIdList) $pid]

                # also add it to the right id list depending on which slice it's showing on
                if {$::Module(verbose)} {
                    puts "Adding pid $pid to point ID list for renderer [lindex [Point($pid,node) GetXYSO] 2]"
                }
                lappend Fiducials($fid,pointIdList,[FiducialsSliceNumberToRendererName [lindex [Point($pid,node) GetXYSO] 2]]) $pid

                FiducialsVTKCreatePoint $fid $pid $visibility
                set Fiducials($fid,pointsExist) 1
            } else {
               # DevErrorWindow "No fiducials list exists to add this point to!\n(no vtkMrmlFiducialsNode found before this point)"
                if {$::Module(verbose)} {
                    puts "No fiducials list exists to add this point to!\n(no vtkMrmlFiducialsNode found before this point)"
                }
            }
        }
        if { [$item GetClassName] == "vtkMrmlEndFiducialsNode" } {
            set efid [$item GetID]
            # if the Mrml ID is not in the list already, then this
            # a new Fiducials Node/EndNode pair
            # there could be an end node w/o a starting node, so make sure that fid has been set
            if { [info exists fid] == 0 } {
                puts "FiducialsUpdateMRML:\nWarning: an EndFiducialsNode of id $efid has been found w/o the id of the starting node being found previously."
                break
            } 

            # update the modified point List for all the existing Fiducials Node
            if { $Fiducials($fid,pointsExist) ==  1} { 
                FiducialsVTKUpdatePoints $fid $symbolSize $textSize
            }
            # if this is a new list and it doesn't exist in Fiducials->Display, then
            # create its button and attributes
            if { [lsearch $Fiducials(displayList) $fid] == -1 } { 
                set gui [expr $gui + [FiducialsCreateGUI $Fiducials(fScrolledGUI) $fid]]
            } else {
                # otherwise the button for that list exists already so remove it 
                # from the "to be deleted list"
                set index [lsearch $Fiducials(removeDisplayList) $fid]
                if {$index != -1} {
                    set Fiducials(removeDisplayList) [lreplace $Fiducials(removeDisplayList) $index $index]
                }
            }
            # callback in case any module wants to know what list of fiducials 
            # (and its type) was just read in the MRML tree
            # see the endoscopic module for examples

            foreach m $Module(idList) {
                if {[info exists Module($m,fiducialsCallback)] == 1} {
                    if {$Module(verbose) == 1} {
                        puts "Fiducials Callback: $m"
                    }
                    $Module($m,fiducialsCallback) $type $fid $Fiducials($fid,pointIdList)
                }
            }   
        }

        # BACKWARD COMPATIBILITY for old files that still use the 
        # Path/Landmark Mrml nodes (the new ones use the Fiducials/Point nodes)

        if { [$item GetClassName] == "vtkMrmlPathNode"} {
            set fid [[MainMrmlAddNode Fiducials] GetID] 
            set efid [[MainMrmlAddNode EndFiducials] GetID] 
            Fiducials($fid,node) SetName "savedPath"
            Fiducials($fid,node) SetType "endoscopic"
            MainMrmlDeleteNodeDuringUpdate Path [$item GetID]
        } elseif { [$item GetClassName] == "vtkMrmlLandmarkNode"} {
            set pid [[MainMrmlInsertBeforeNode EndFiducials($efid,node) Point] GetID]
            # set its world coordinates    
            eval Point($pid,node) SetXYZ [$item GetXYZ]
            eval Point($pid,node) SetFXYZ [$item GetFXYZ]
            Point($pid,node) SetIndex [$item GetPathPosition]
            # Point($pid,node) SetName [concat "savedPath" [$item GetPathPosition]]
            Point($pid,node) SetName "savedPath[$item GetPathPosition]"
            MainMrmlDeleteNodeDuringUpdate Landmark [$item GetID]
        } elseif { [$item GetClassName] == "vtkMrmlEndPathNode" } {
            MainMrmlDeleteNodeDuringUpdate EndPath [$item GetID]
            set readOldNodesForCompatibility 1
        }
        
        # deal with the fiducials list information saved in the scene
        if {[$item GetClassName] == "vtkMrmlScenesNode"} {
            # get the scene name
            set sceneName [$item GetName]
        }
        # is it a module node for this module?
        if {[$item GetClassName] == "vtkMrmlModuleNode" &&
            [$item GetModuleRefID] == "Fiducials"} {
            # get the list name
            set name [$item GetName]
            if {$::Module(verbose)} {
                puts "Updating Presets for module Fiducials, scene $sceneName, list $name"
            }
            set Preset(Fiducials,$sceneName,$name,visibility) [$item GetValue visibility]
            set Preset(Fiducials,$sceneName,$name,selected) [FiducialsGetPointIdsFromNames [$item GetValue selected]]
            
            
        }
 
        set item [Mrml(dataTree) GetNextItem]
        
    }

    Render3D
    RenderSlices

    ##################################################
    # UPDATE ACTIVE LISTS
    # Check to see if the active list still exists
    # and tell other modules what list is active
    ##################################################

    # if the list is in the listOfNames, then the active list before the
    # UpdateMRML still exists, and it stays active

    if { [lsearch $Fiducials(listOfNames) $Fiducials(activeList) ] > -1 } {
        set name $Fiducials(activeList)
        set id $Fiducials($name,fid)
        if {[info command Fiducials($id,node)] != ""} {
            set type [Fiducials($id,node) GetType]
            
            # callback in case any module wants to know the name of the active list    
            foreach m $Module(idList) {
                if {[info exists Module($m,fiducialsActivatedListCallback)] == 1} {
                    if {$Module(verbose) == 1} {puts "Fiducials Activated List Callback: $m"}
                    $Module($m,fiducialsActivatedListCallback)  $type $name $id
                }
            }
        } else {
            DevErrorWindow "No fiducials node found for id $id"
        }
       
    } else {
        # if the list that was active before the UpdateMRML does not exist anymore, 
        # then make the active list the "None" list
        FiducialsSetActiveList "None"
         # callback in case any module wants that the None list is active
        foreach m $Module(idList) {
            if {[info exists Module($m,fiducialsActivatedListCallback)] == 1} {
                if {$Module(verbose) == 1} {puts "Fiducials Activated List Callback: $m"}
                $Module($m,fiducialsActivatedListCallback)  "default" "None" ""
            }
        }
    }

    ##################################################
    # Update the Fiducials->Display panel
    ##################################################

    # Remove the buttons on the Fiducials->Display panel
    # for the fiducials not on the list
    foreach i $Fiducials(removeDisplayList) {
        FiducialsDeleteGUI $Fiducials(fScrolledGUI) $i
    }

    # Tell the Fiducials->Display scrollbar to update if the gui height changed
    if {$gui > 0} {
        FiducialsConfigScrolledGUI $Fiducials(canvasScrolledGUI) $Fiducials(fScrolledGUI)
    }
        
    ##################################################
    # Update all the Fiducials menus 
    ##################################################

    # Form the menus with all mrml fiducials plus the defaults that are not saved in mrml
    #--------------------------------------------------------
   
    set index 0
    foreach m $Fiducials(mActiveList) {
        # get the corresponding scroll
        set cb [lindex $Fiducials(scrollActiveList) $index]
        set mb [lindex $Fiducials(mbActiveList) $index]
        $m delete 0 end
        foreach v $Fiducials(idList) {
            $m add command -label [Fiducials($v,node) GetName] -command "FiducialsSetActiveList [Fiducials($v,node) GetName]"
               # -command "FiducialsSetActiveList [Fiducials($v,node) GetName] $mb $cb"
        }
        foreach d $Fiducials(defaultNames) {
            # if this default name doesn't exist in the list of fiducials in the mrml tree
            if {[lsearch $Fiducials(listOfNames) $d] == -1} {
                $m add command -label $d -command "FiducialsSetActiveList $d"
                #    -command "FiducialsSetActiveList $d $mb $cb"
            }
        }
        incr index
    }

    # re-write the scrolls
    set counter 0
    foreach cb $Fiducials(scrollActiveList) {
        if {0} {
#skip deleting
        if {[$cb getnumbuttons] == 0} { 
            if {$::Module(verbose)} { 
                puts "FiducialsUpdateMRML: no elements, not deleting anything"
            }
        } else {
            # ischeckbox supports full delete
            if {$::Module(verbose)} { 
                puts "FiducialsUpdateMRML: deleting everything from $cb"
            }
            $cb delete
        }
    }
        # get the current name to use 
        set menu [lindex $Fiducials(mbActiveList) $counter]    
        set name [$menu cget -text]
        # if the name is valid
        if {[lsearch $Fiducials(listOfNames) $name] != -1} {
            # rewrite the list of points
            if {$::Module(verbose)} {
                puts "FidUpdateMRML, looking in selectedPointIdList to select stuff: $Fiducials($Fiducials($name,fid),selectedPointIdList)"
            }
            foreach pid $Fiducials($Fiducials($name,fid),pointIdList) {
                if {[$cb index "[Point($pid,node) GetName]"] == -1} {
                    # add it
                    $cb add "[Point($pid,node) GetName]" -text "[Point($pid,node) GetName]" \
                        -command "FiducialsSelectionFromCheckbox $menu $cb no $pid"
                    if {$::Module(verbose)} {
                        puts "FiducialsUpdateMrml: didn't find [Point($pid,node) GetName] via cb index,\n\tadded command for point $pid:\n\tFiducialsSelectionFromCheckbox menu = $menu, cb = $cb no , pid = $pid"
                    }
                } else { 
                }
                # if it is selected, tell the scroll
                set fid $Fiducials($name,fid)
                set index [lsearch $Fiducials($fid,pointIdList) $pid]
                if {[info exists Fiducials($fid,selectedPointIdList)] == 0} {
                    # it didn't get created yet (may have been read from mrml, set it to an empty list
                    set Fiducials($fid,selectedPointIdList) ""
                }
                if {[lsearch $Fiducials($fid,selectedPointIdList) $pid] != -1} {
                    if {$::Module(verbose)} { puts "FiducialsUpdateMRML: $cb selecting index $index" }
                    if {[lsearch [$cb getselind] $index] == -1} {
                        if {$::Module(verbose)} { 
                            puts "FiducialsUpdateMRML: really $cb selecting index $index"
                        }
                        # last arg determines if invoke 1 or select 0
                        $cb select $index 0
                    } else {
                        if {$::Module(verbose)} { 
                            puts "FiducialsUpdateMRML: it was already selected, not doing anything"
                        }
                    }
                } else {
                    # deselect it
                    if {[lsearch [$cb getselind] $index] != -1} {
                        $cb deselect $index
                    } else { 
                        if {$::Module(verbose)} {  
                            puts "FiducialsUpdateMRML: pid $pid was already deselected." 
                        }
                    }
                }
            }
            if {$::Module(verbose)} {
                puts "FidUpdateMRML: Fids should be selected now? are they?"
            }

        } else {
            # if the name is not valid, just set the text to None
            $menu configure -text "None"
        }
        incr counter
    }

    #################################################################
    # Tell the user if their file still has old nodes and give them 
    # the option to update their files
    #################################################################
    if {$readOldNodesForCompatibility == 1} {

        # tell the user to save the file
        puts "The file read uses a deprecated version of the endoscopic path.\nThe current data was updated to use the new version.\nPlease save the scene and use that new file instead to not get this message again.\n"
        MainUpdateMRML
    }

    # end callback in case any module wants to know that Fiducials 
    # are done being updated 
    foreach m $Module(idList) {
        if {[info exists Module($m,fiducialsEndUpdateMRMLCallback)] == 1} {
            if {$Module(verbose) == 1} {puts "Fiducials End Callback: $m"}
            $Module($m,fiducialsEndUpdateMRMLCallback)  
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsResetVariables
# Reset all the tcl and vtk variables, delete vtk objects only if the deleteFlag is 1.
# .ARGS
# int deleteFlag Set this to 1 if you wish to delete vtk objects, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc FiducialsResetVariables { {deleteFlag "0"} } {

    global Fiducials Module

    if {!$deleteFlag} {
        # check to see if a point node was deleted, if so, we need to delete our vars
        set nodeDeleted 0
        foreach id $Fiducials(listOfIds) {
            if {$::Module(verbose)} { puts "FiducialsResetVariables: checking list $id for deleted nodes, deleteFlag == $deleteFlag, point id list = $Fiducials($id,pointIdList)" }
            if {$deleteFlag == 0} {
                foreach pid $Fiducials($id,pointIdList) {
                    if {$::Module(verbose)} { puts "FiducialsResetVariables: checking Point $pid: [info command Point($pid,node)]"}
                    if {[info command Point($pid,node)] == ""} {
                        if {$::Module(verbose)} {
                            puts "****FiducialsResetVariables: didn't find Point($pid,node), setting deleteFlag to 1"
                        }
                        set deleteFlag 1
                    }
                }
            }
        }
    }

    if {$deleteFlag} {
        if {$::Module(verbose)} {
            puts "FiducialsResetVariables: delete Flag is one, deleting everything from lists $Fiducials(listOfIds)"
        }
        # go through the list of existing fiducial list and clear them
        foreach id $Fiducials(listOfIds) {
            if {$::Module(verbose)} {
                puts "FiducialsResetVariables: deleting everything from list $id, points = $Fiducials($id,pointIdList)"
            }
            foreach pid $Fiducials($id,pointIdList) {
                foreach r $Fiducials(renList) {
                    if {[info command Point($pid,follower,$r)] != ""} {
                        $r RemoveActor Point($pid,follower,$r)
                        Point($pid,follower,$r) Delete
                    }
                }
                if { [FiducialsUseTextureText] &&
                     [info command Point($pid,mapper)] != ""} {
                    Point($pid,mapper) Delete
                }
                catch "Point($pid,text) Delete"
            }
            
            foreach r $Fiducials(renList) {
                if {[info command Fiducials($id,actor,$r)] != ""} {
                    $r RemoveActor Fiducials($id,actor,$r)
                    Fiducials($id,actor,$r) Delete 
                }
            }
            foreach r $Fiducials(renList2D) {
                if {[info command Fiducials($id,actor2D,$r)] != ""} {
                    Fiducials($id,actor2D,$r) Delete
                }
            }
            catch "Fiducials($id,mapper) Delete"
            catch "Fiducials($id,glyphs) Delete"
            catch "Fiducials($id,symbolXform) Delete"
            catch "Fiducials($id,XformFilter) Delete"
            catch "Fiducials($id,points) Delete"
            catch "Fiducials($id,scalars) Delete" 
            catch "Fiducials($id,xform) Delete" 
            catch "Fiducials($id,pointsPD) Delete" 
            catch "Point($id,textXform) Delete"
            set Fiducials($id,pointIdList) ""
            if {[info exist Fiducials($id,selectedPointIdList)] != 0} {
                set Fiducials($id,oldSelectedPointIdList) $Fiducials($id,selectedPointIdList) 
            } else {
                set Fiducials($id,oldSelectedPointIdList) ""
            }
            set Fiducials($id,selectedPointIdList) ""
            
            # delete the 2d glyph variables
            foreach r $Fiducials(renList2D) {
                set Fiducials($id,pointIdList,$r) ""
                catch "Fiducials($id,glyphs2D,$r) Delete"
                catch "Fiducials($id,mapper2D,$r) Delete"
                catch "Fiducials($id,scalars2D,$r) Delete"
                catch "Fiducials($id,pointsPD2D,$r) Delete" 
                catch "Fiducials($id,points2D,$r) Delete"
            }
            # delete the checkboxes
            foreach cb $Fiducials(scrollActiveList) {
                if {$::Module(verbose)} {
                    puts "Deleting all from checkbox $cb"
                }
                $cb delete
            }
        }
        set Fiducials(listOfIds) ""
        set Fiducials(listOfNames) ""
        
    } else {
        # these are operations that take place that don't involve deleting vtk variables
        foreach id $Fiducials(listOfIds) {
            set Fiducials($id,pointIdList) ""
            if {$::Module(verbose) && [info exist Fiducials($id,selectedPointIdList)] != 0} {
                puts "ResetVars: clearing out selected point id list for $id, saving it in old if there was one: $Fiducials($id,selectedPointIdList)"
            }
            if {[info exist Fiducials($id,selectedPointIdList)] != 0} {
                set Fiducials($id,oldSelectedPointIdList) $Fiducials($id,selectedPointIdList) 
            } else {
                set Fiducials($id,oldSelectedPointIdList) ""
            }
            set Fiducials($id,selectedPointIdList) ""
            foreach r $Fiducials(renList2D) {
                set Fiducials($id,pointIdList,$r) ""
            }
        }
        set Fiducials(listOfIds) ""
        set Fiducials(listOfNames) ""
    }
    set Fiducials(newListName) ""
}



####################################################################
#
#
#        USER OPERATIONS THAT CHANGES THE STATE OF
#        FIDUCIALS IN MRML
#
#
####################################################################



##################### CREATION ####################################

#-------------------------------------------------------------------------------
# .PROC FiducialsCheckListExistence
# Checks the Mrml tree to see if any lists with that name already exist.<br>
# Return fid value if requested. <br>
# Return 1 if a list with that name exists, 0 otherwise.<br>
# .ARGS 
# string name name of the list to check
# string argfid optional, defaults to empty string, get it via upvar
# .END
#-------------------------------------------------------------------------------
proc FiducialsCheckListExistence {name {argfid ""}} {

    global Fiducials
    
    if { $argfid != "" } {
        upvar $argfid fid
    }
    set existingLists $Fiducials(idList)
    foreach fid $existingLists {
        if { [Fiducials($fid,node) GetName] == $name & [lsearch $Fiducials(listOfNames) $name] != -1} {
            return 1
        } 
    } 
    # if no list with that name is found, return 0
    return 0
}

#-------------------------------------------------------------------------------
# .PROC FiducialsCreateFiducialsList
# Create a new Fiducials/EndFiducials nodes with that name that will hold a set of points.<br>
# If a list with that name exists already, or there is a space in the name, return -1.<br>
# If the new Fiducials/EndFiducials pair is created, return its id .
# .ARGS 
# str type the type of the fiducial node
# str name the name of the new List
# int textSize size to draw the fiducial text, defaults to 6
# int symbolSize size to draw the fiducial symbol, defaults to 6
# .END
#-------------------------------------------------------------------------------
proc FiducialsCreateFiducialsList {type name {textSize "6"} {symbolSize "6"}} {
    global Fiducials Point
    
    # check to see if there's a space in the name
    if {[string first " " $name] != -1} {
        DevErrorWindow "Invalid fiducial list name:\n\"$name\"\nNo spaces allowed."
        return -1
    }

    # search in the existing lists to see if one already exists with that name
    if { [FiducialsCheckListExistence $name] == 0 } {
    
        set fid [[MainMrmlAddNode Fiducials] GetID] 
        
        Fiducials($fid,node) SetName $name
        Fiducials($fid,node) SetType $type
        Fiducials($fid,node) SetTextSize $textSize
        Fiducials($fid,node) SetSymbolSize $symbolSize
        MainMrmlAddNode EndFiducials

        if {$::Module(verbose)} {
            puts "FiducialsCreateFiducialsList: Calling MainUpdateMRML and then Render3D since added new Fiducials/EndFiducials node"
        }
        MainUpdateMRML
        # set that list active
        FiducialsSetActiveList $name
        # only call render if it didn't get called in MainUpdateMRML
        if {$::Module(RenderFlagForMainUpdateMRML) == 0} {
            Render3D
        } else {
            if {$::Module(verbose)} {
                puts "FiducialsCreateFiducialsList: Skipped call to render3d done in main update mrml"
            }
        }
        
        return $fid
    } else {
        return -1
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsCreatePointFromWorldXYZ
#  Create a Point at the xyz location for the Fiducials list that is currently active 
# and add it to the MRML tree (but does not call UpdateMRML)
#
# .ARGS
# string type the type of the fiducial node
# float x the x world coordinate of the new point
# float y the y world coordinate of the new point
# float z the z world coordinate of the new point
# str listName (optional) the name of the Fiducials list you want to add this point to. If a list with that name doesn't exist, it is created automatically.
# str name (optional) name of that new point
# int selected (optional) is the point selected? defaults to 1
# .END
#-------------------------------------------------------------------------------
proc FiducialsCreatePointFromWorldXYZ { type x y z  {listName ""} {name ""} {selected 1} } {

    global Fiducials Point Module Select
    if {$::Module(verbose)} {
        puts "FiducialsCreatePointFromWorldXYZ x $x, y $y, z $z"
    }

    # if the user specified a list, use that name
    # otherwise, if the user specified a default list for their module/tab, 
    # use that name
    # otherwise, use the active list

    
    if {[info exists Select(actor)] != 0} {
        set actor $Select(actor)
        set cellId $Select(cellId)
    } else {
        set actor ""
        set cellId ""
    }

    # make sure that there's a list to add the new point into
    if {$listName != ""} {
        # check that the name exists, if not, create new list
        if { [lsearch $Fiducials(listOfNames) $listName] == -1 } {
            FiducialsCreateFiducialsList $type $listName
            FiducialsSetActiveList $listName
        }
    } else {
    
        set module $Module(activeID) 
        set row $Module($module,row) 
        set tab $Module($module,$row,tab) 
        
        if { [info exists Fiducials($module,$tab,defaultList)] == 1 } {
            set listName $Fiducials($module,$tab,defaultList)
            # check that the name exists, if not, create new list
            if { [lsearch $Fiducials(listOfNames) $listName] == -1 } {
                FiducialsCreateFiducialsList $type $listName
            }
            FiducialsSetActiveList $listName
            
        }  else {
            if { $Fiducials(activeList) == "None" } {
                FiducialsCreateFiducialsList $type "default"
                FiducialsSetActiveList "default"
            } else {
                # if the active list string is not empty, but it doesn't exist, create it (in Mrml)
                if {[lsearch $Fiducials(listOfNames) $Fiducials(activeList)] == -1} {
                    FiducialsCreateFiducialsList $type $Fiducials(activeList)
                }
            }
        }
    }
    
    # now use the id of the active list 
    set fid $Fiducials($Fiducials(activeList),fid)

    # find out its position in the list
    set index [llength $Fiducials($fid,pointIdList)]
    
    set pid [[MainMrmlInsertBeforeNode EndFiducials($fid,node) Point] GetID]
    # set its world coordinates

    Point($pid,node) SetXYZ $x $y $z
    Point($pid,node) SetIndex $index
    # this won't work correctly if points were deleted from the list (will reuse names)
    # Point($pid,node) SetName "$Fiducials($fid,name)$index"
    Point($pid,node) SetName [FiducialsNewPointName $fid]

    # save actor and cell - TODO: this isn't saved in MRML
    set Point($pid,actor) $actor
    set Point($pid,cellId) $cellId
    
    # calculate FXYZ
    # if the actor and cell Id is not empty, get the normal of that cell
    if {$actor != "" && $cellId != ""} {
       set normals [[[[$actor GetMapper] GetInput] GetPointData] GetNormals]
       if {$normals != ""} {
           set cell [[[$actor GetMapper] GetInput] GetCell $cellId]
           set pointIds [$cell GetPointIds]
           
           # average the normals
           set count 0
           set sumX 0
           set sumY 0
           set sumZ 0
           set num [$pointIds GetNumberOfIds]
           while {$num > 0} {
               set num [expr $num - 1]
               incr count
               set id [$pointIds GetId $num]
               set normal [$normals GetTuple3 $id]

   
               set sumX [expr $sumX + [lindex $normal 0]]
               set sumY [expr $sumY + [lindex $normal 1]]
               set sumZ [expr $sumZ + [lindex $normal 2]]
               
           }
           # now average
           set avSumX [expr $sumX/$count]
           set avSumY [expr $sumY/$count]
           set avSumZ [expr $sumZ/$count]
           
           # set the camera position to be a distance of 10 units in the direction of the normal from the picked point
           
           set fx [expr $x + 30 * $avSumX]
           set fy [expr $y + 30 * $avSumY]
           set fz [expr $z + (30 * $avSumZ)]
           Point($pid,node) SetFXYZ $fx $fy $fz
       }
   }


    #
    # support automatically setting anatomical label description 
    # for fiducials created on the 2D slice windows
    #
    if { [info exists ::Fiducial(Pick2D)] } {
        if {$::Module(verbose)} {
            puts "Fiducial(Pick2D) = $::Fiducial(Pick2D), select xy = $::Select(xy)"
            # get the slice window from the widget
            if {[scan [lindex $::Select(xy) 0] ".tViewer.fSlice%d" slicenum] == 1} {
                puts "\tSlice num = $slicenum, offset = $::Slice($slicenum,offset)"
            }
        }
        if { $::Fiducial(Pick2D) == 1 } {
            Point($pid,node) SetDescription $::Anno(curFore,label)
            scan [lindex $::Select(xy) 0] ".tViewer.fSlice%d" slicenum
            set x2d [lindex $::Select(xy) 1] 
            set y2d [lindex $::Select(xy) 2] 
            if {$::Module(verbose)} {
                puts "\tSlice num = $slicenum, x2d = $x2d, y2d = $y2d, offset = $::Slice($slicenum,offset)"
            }
            Point($pid,node) SetXYSO $x2d $y2d $slicenum $::Slice($slicenum,offset)
        }
    }

    # select fiducial after creation
    if {$::Module(verbose)} {
        puts "FiducialsCreatePointFromWorldXYZ: calling FiducialsSelectionUpdate $fid $pid $selected"
    }
    FiducialsSelectionUpdate $fid $pid $selected

    if {0} {
        # set the active point id now so that it's active once all updates are done
        if {$::Module(verbose)} {
            puts "FiducialsCreatePointFromWorldXYZ: setting the active point now to $pid"
        }
        set Fiducials(activePointID) $pid
    }

   # callback for modules who wish to know a point was created
   foreach m $Module(idList) {
       if {[info exists Module($m,fiducialsPointCreatedCallback)] == 1} {
           if {$Module(verbose) == 1} {puts "Fiducials Point Created Callback: $m"}
               $Module($m,fiducialsPointCreatedCallback) $type $fid $pid
           }
   }
   return $pid
}

#-------------------------------------------------------------------------------
# .PROC FiducialsInsertPointFromWorldXYZ
# Create a Point at the xyz location for the Fiducials list that is currently active 
# and add it to the MRML tree (but does not call UpdateMRML) and insert it after the 
# point with the id previousPid
#
# .ARGS
# string type the type of the fiducial node
# int previousPid the id of the previous point, insert after this one
# float x the x world coordinate of the new point
# float y the y world coordinate of the new point
# float z the z world coordinate of the new point
# str listName (optional) the name of the Fiducials list you want to add this point to. If a list with that name doesn't exist, it is created automatically.
# str name (optional) name of that new point
# .END
#-------------------------------------------------------------------------------
proc FiducialsInsertPointFromWorldXYZ {type previousPid x y z  {listName ""} {name ""} } {

    global Fiducials Point Module Select

    # if the user specified a list, use that name
    # otherwise, if the user specified a default list for their module/tab, 
    # use that name
    # otherwise, use the active list

    
    if {[info exists Select(actor)] != 0} {
        set actor $Select(actor)
        set cellId $Select(cellId)
    } else {
        set actor ""
        set cellId ""
    }

    if {$listName != ""} {
        # check that the name exists, if not, create new list
        if { [lsearch $Fiducials(listOfNames) $listName] == -1 } {
            FiducialsCreateFiducialsList $type $listName
            FiducialsSetActiveList $listName
        }
    } else {
    
        set module $Module(activeID) 
        set row $Module($module,row) 
        set tab $Module($module,$row,tab) 
        
        if { [info exists Fiducials($module,$tab,defaultList)] == 1 } {
            set listName $Fiducials($module,$tab,defaultList)
            # check that the name exists, if not, create new list
            if { [lsearch $Fiducials(listOfNames) $listName] == -1 } {
                FiducialsCreateFiducialsList $type $listName
            }
            FiducialsSetActiveList $listName
            
        }  else {
            if { $Fiducials(activeList) == "None" } {
                FiducialsCreateFiducialsList $type "default"
                FiducialsSetActiveList "default"
            } else {
                # if the active list string is not empty, but it doesn't exist, create it (in Mrml)
                if {[lsearch $Fiducials(listOfNames) $Fiducials(activeList)] == -1} {
                    FiducialsCreateFiducialsList $type $Fiducials(activeList)
                }
            }
        }
    }
    
    # now use the id of the active list 
    set fid $Fiducials($Fiducials(activeList),fid)

    # find out its position in the list
    set index [llength $Fiducials($fid,pointIdList)]
    
    set pid [[MainMrmlInsertAfterNode Point($previousPid,node) Point] GetID]
    # set its world coordinates

    Point($pid,node) SetXYZ $x $y $z
    Point($pid,node) SetIndex $index
    #Point($pid,node) SetName [concat $Fiducials($fid,name) $index]
    # this won't work if points were deleted from the list
    # Point($pid,node) SetName "$Fiducials($fid,name)${index}"
    Point($pid,node) SetName [FiducialsNewPointName $fid]

    # calculate FXYZ
    # if the actor and cell Id is not empty, get the normal of that cell
    if {$actor != ""} {
       set normals [[[[$actor GetMapper] GetInput] GetPointData] GetNormals]
       if {$normals != ""} {
           set cell [[[$actor GetMapper] GetInput] GetCell $cellId]
           set pointIds [$cell GetPointIds]
           
           # average the normals
           set count 0
           set sumX 0
           set sumY 0
           set sumZ 0
           set num [$pointIds GetNumberOfIds]
           while {$num > 0} {
               set num [expr $num - 1]
               incr count
               set id [$pointIds GetId $num]
              # set normal [$normals GetNormal $id]
               set normal [$normals GetTuple3 $id]

               set sumX [expr $sumX + [lindex $normal 0]]
               set sumY [expr $sumY + [lindex $normal 1]]
               set sumZ [expr $sumZ + [lindex $normal 2]]
               
           }
           # now average
           set avSumX [expr $sumX/$count]
           set avSumY [expr $sumY/$count]
           set avSumZ [expr $sumZ/$count]
           
           # set the camera position to be a distance of 10 units in the direction of the normal from the picked point
           
           set fx [expr $x + 30 * $avSumX]
           set fy [expr $y + 30 * $avSumY]
           set fz [expr $z + (30 * $avSumZ)]
           Point($pid,node) SetFXYZ $fx $fy $fz
       }
   }
   
   
   # callback for modules who wish to know a point was created
   foreach m $Module(idList) {
       if {[info exists Module($m,fiducialsPointCreatedCallback)] == 1} {
           if {$Module(verbose) == 1} {puts "Fiducials Point Created Callback: $m"}
               $Module($m,fiducialsPointCreatedCallback) $type $fid $pid
           }
   }
   return $pid
}

############################## DELETION ################################

#-------------------------------------------------------------------------------
# .PROC FiducialsDeleteActivePoint
# Delete the active point on the active list, calls FiducialsDeletePoint
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsDeleteActivePoint {} {
    global Fiducials

    if {$::Module(verbose)} {
        puts "FiducialsDeleteActivePoint active list = $Fiducials(activeListID), active point = $Fiducials(activePointID).\n\tcalling FiducialsDeletePoint and then FiducialsDisplayDescriptionActive"
    }
    FiducialsDeletePoint $Fiducials(activeListID) $Fiducials(activePointID)
}

#-------------------------------------------------------------------------------
# .PROC FiducialsDeletePoint
# Delete from Mrml/vtk the selected Point
# .ARGS 
# int fid the Mrml id of the Fiducial list that contains the point
# int pid the Mrml id of the Point
# int noUpdate if the flag is 1, do a full mrml update. Optional, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc FiducialsDeletePoint {fid pid {noUpdate 0}} {
     
    global Fiducials Point
    if {$::Module(verbose)} {
        puts "FiducialsDeletePoint: fid = $fid, pid = $pid, noUpdate = $noUpdate"
    }

    if {$fid == "None" || $pid == "None"} {
        puts "Select a fiducial to delete, first."
        return
    }

    # first check if the ID of the Point to be deleted is in the selected 
    # list and if so, delete it
    if {[info exist Fiducials($fid,selectedPointIdList)]} {
        set index [lsearch $Fiducials($fid,selectedPointIdList) $pid]
        if { $index != -1 } {
            # remove the id from the list
            set Fiducials($fid,selectedPointIdList) [lreplace $Fiducials($fid,selectedPointIdList) $index $index]
        }
    }

    # delete the checkbox if this is the active list (it won't get added if it's not there now)
    # do this before losing it's place on the pointIdList
    if {$Fiducials(activeList) != "None" &&
        $fid == $Fiducials($Fiducials(activeList),fid)} {
        set index [lsearch $Fiducials($fid,pointIdList) $pid]
        if {$::Module(verbose)} {
            puts "FiducialsDeletePoint: deleting checkbox for $fid $pid, index $index"
        }
        foreach cb $Fiducials(scrollActiveList) {
            $cb delete "$index"
        }
    }


    # remove the id from the fiducials list it belongs to
    set index [lsearch $Fiducials($fid,pointIdList) $pid]
    if { $index != -1 } {
        # remove the id from the list
        set Fiducials($fid,pointIdList) [lreplace $Fiducials($fid,pointIdList) $index $index]
    }

    
    # remove the id from the 2d fiducials list it belongs to
    foreach r $Fiducials(renList2D) {
        set index [lsearch $Fiducials($fid,pointIdList,$r) $pid]
        if { $index != -1 } {
            # remove the id from the list
            set Fiducials($fid,pointIdList) [lreplace $Fiducials($fid,pointIdList,$r) $index $index]

            # remove the point/scalar for this 2d fid so that no glyph will be displayed at that point
            set sid [FiducialsScalarIdFromPointId2D $fid $pid $r]
            if {$sid != -1} {
                if {$::Module(verbose)} {
                    puts "FiducialsDeletePoint: TODO: removing point $pid from points2D and scalars2D for renderer $r"
                } 
                if {0} {
                    # not quite right, probably need to move things down one by one
                    Fiducials($fid,points2D,$r) RemovePoint $sid
                    Fiducials($fid,scalars2D,$r) SetTuple1 $sid
                }
            }
        }
    }
    

    foreach r $Fiducials(renList) {
        if {[info command Point($pid,follower,$r)] != ""} {
            $r RemoveActor Point($pid,follower,$r)
            Point($pid,follower,$r) Delete
            if {$::Module(verbose)} {
                puts "FiducialsDeletePoint: removed actor Point($pid,follower,$r) and deleted it"
            }
        }
    }
    if { [FiducialsUseTextureText] } {
        catch "Point($pid,mapper) Delete"
    }
    catch "Point($pid,text) Delete"

    catch "unset Point($pid,actor)"
    catch "unset Point($pid,cellId)"

    # check to see if this was the last point on the list
    if {[llength $Fiducials($fid,pointIdList)] == 0} {
        if {$::Module(verbose)} {
            puts "FiducialsDeletePoint: last point on list:"
        }
        set Fiducials(deleteFlag) 1
    }

    # delete from Mrml
    if {!$noUpdate} {
        MainMrmlDeleteNode Point $pid
        # don't need this call, it's called last in MainMrmlDeleteNode
        # MainUpdateMRML
        if {$::Module(RenderFlagForMainUpdateMRML) == 0} {
            # render was not called yet
            Render3D
        }
    } else {
        MainMrmlDeleteNodeNoUpdate Point $pid
    }
    if {$::Module(verbose)} {
        puts "FiducialsDeletePoint: Point $pid node = [info command Point($pid,node)]"
    }
    # reset the delete flag, it triggered deleting the vtk vars in FiducialsResetVariables
    # from the call in FiducialsUpdateMrml if this was the last point on the list 
    set Fiducials(deleteFlag) 0

    # if it was the active point, pick a new one
    if {$pid == $Fiducials(activePointID)} {
        # set a new active point, last on the active list
        if {[llength $Fiducials($Fiducials(activeListID),pointIdList)] > 0} {
            set Fiducials(activePointID) [lindex $Fiducials($Fiducials(activeListID),pointIdList) end]
            if {$::Module(verbose)} {
                puts "FiducialsDeletePoint: resetting active point to $Fiducials(activePointID)"
            }
        }
        # now update the description of the active point because it's out of date now
        FiducialsDisplayDescriptionActive
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsDeleteFromPicker
# If an existing Fiducial point matches the actor and cellId, then it is deleted 
# and the Mrml Tree is updated  
#
# .ARGS 
#       str actor a vtkActor
#       int cellId ID of the selected cell in the actor
# .END
#-------------------------------------------------------------------------------
proc FiducialsDeleteFromPicker {actor cellId} {
    global Fiducials Point Module
    
    foreach fid $Fiducials(idList) {
        foreach r $Fiducials(renList) {
            if { $actor == "Fiducials($fid,actor,$r)" } {
                
                set pid [FiducialsPointIdFromGlyphCellId $fid $cellId]
                FiducialsDeletePoint $fid $pid
                return 1
            }
        }
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC FiducialsActiveDeleteList
# Delete from Mrml/vtk the whole active list
# .ARGS       
# .END
#-------------------------------------------------------------------------------
proc FiducialsDeleteActiveList {} {
    global Fiducials

    if {$Fiducials(activeList) == "None"} {
        # do nothing 
        puts "No active fiducials list"
        return
    } else {
        FiducialsDeleteList $Fiducials(activeList)
    }
    
}

#-------------------------------------------------------------------------------
# .PROC FiducialsDeleteList
# Delete from Mrml/vtk the whole list
# .ARGS 
# string name the name of the list to delete   
# .END
#-------------------------------------------------------------------------------
proc FiducialsDeleteList {name} {
    
    global Fiducials Point
    
    if {$name == "None"} {
        # do nothing 
        return
    }
    if { $Fiducials(activeList) == $name } {
        set Fiducials(activeList) "None"
    }
    
    if {$::Module(verbose)} {
        puts "FiducialsDeleteList $name"
    }
    set fid $Fiducials($name,fid)

    set noUpdate 1

    foreach pid $Fiducials($fid,pointIdList) {
        # delete from Mrml
        # MainMrmlDeleteNodeNoUpdate Point $pid
        FiducialsDeletePoint $fid $pid $noUpdate
    }
    
    MainMrmlDeleteNodeNoUpdate EndFiducials $fid
    MainMrmlDeleteNodeNoUpdate Fiducials $fid
    
    MainUpdateMRML
    if {$::Module(RenderFlagForMainUpdateMRML) == 0} {
        # render wasn't called yet
        Render3D
    }
}

########################### VISIBILITY #####################################

#-------------------------------------------------------------------------------
# .PROC FiducialsSetFiducialsVisibility
# This procedure sets the visibility on the given screen for a set of fiducials 
# .ARGS 
#       str name  name of the list to set visible/invisible
#       int visibility 1 makes it visible 0 makes it invisible
#       str rendererName the name of the renderer to update, optional, defaults to empty string which will cause viewRen to be updated.
# .END
#-------------------------------------------------------------------------------
proc FiducialsSetFiducialsVisibility {name {visibility ""} {rendererName ""}} {
    global Fiducials Module

    if {$rendererName == ""} {
        set rendererName "viewRen"
    }
   
    if {$name == "ALL"} {
        set visibility 1 
        set name $Fiducials(listOfNames)
    } elseif {$name == "None"} {
        set visibility 0 
        set name $Fiducials(listOfNames)
    } else {
        set fid $Fiducials($name,fid)
        if {$visibility == ""} {
            set visibility $Fiducials($fid,visibility)
        }
    }
     
    foreach l $name {
        if {[lsearch $Fiducials(listOfNames) $l] != -1} {
            foreach ren $rendererName {
                if {$::Module(verbose)} {
                    puts "Setting fid list $l visibility: for renderer $ren"
                }
                set fid $Fiducials($l,fid)
                Fiducials($fid,actor,$ren) SetVisibility $visibility
                Fiducials($fid,node) SetVisibility $visibility
                # go through the list of followers as well
                foreach pid $Fiducials($fid,pointIdList) {
                    Point($pid,follower,$ren) SetVisibility $visibility
                }
                
                
            }
        }
        # for the 2d glyphs, but use the 2d renderers
        if {[lsearch $Fiducials(listOfNames) $l] != -1} {
            set fid $Fiducials($l,fid)
            if {$::Module(verbose)} {
                puts "Setting 2D fid visibility: for list $fid"
                # puts "\tPoint list = $Fiducials($fid,pointIdList)"
            }
            foreach ren $Fiducials(renList2D) {
                if {$::Module(verbose)} {
                    puts "Setting fid visibility: for renderer $ren"
                }
                Fiducials($fid,actor2D,$ren) SetVisibility $visibility
            }
        }
    }
    RenderSlices
    Render3D
    
}

############################# SELECTION ##############################3

#-------------------------------------------------------------------------------
# .PROC FiducialsSetActiveList
# Set the active list of that widget to be the list of Fiducials with the name 
# given as an argument and update the display of the scroll and menu given as 
# argument (that active list doesn't necessarily have to exist in Mrml already,
# it will be created if it is not in the Mrml tree next time a point gets added
# to the list). If no menu or scroll are specified, then all fiducial scrolls 
# that exist are updated.
# .ARGS 
#      str name name of the list that becomes active
#      str menu (optional) the menu that needs to be updated to show the new name
#      str cb (optional) the checkbox that needs to be updated to show the points of the new list
# .END
#-------------------------------------------------------------------------------
proc FiducialsSetActiveList {name {menu ""} {cb ""}} {
    
    global Fiducials Point Module

    if {$::Module(verbose)} {
        puts "FiducialsSetActiveList:\nname = $name\nmenu = $menu\ncb = $cb"
    }

    if { [FiducialsCheckListExistence $name] == 1} {
        set Fiducials(activeList) $name
        if { $menu == "" } {
            foreach m $Fiducials(mbActiveList) {
                $m config -text $name
            } 
        } else {
            $menu config -text $name
        }

        # change the content of the selection box to display only the points
        # that belong to that list

        # clear the text text

        if {$cb == ""} {
            set cblist $Fiducials(scrollActiveList)
        } else {
            set cblist $cb
        }
        if {$menu == ""} {
            set menulist $Fiducials(mbActiveList)
        } else {
            set menulist $menu
        }
        set menuindex 0
        foreach s $cblist {
            # clear out the checkboxes
            if {[$s getnumbuttons] != 0} {
                if {$::Module(verbose)} { puts "SetActiveList: there are some buttons on $s, deleting"}
                $s delete
            }
            if {[info exists Fiducials($name,fid)] == 1} {
                set fid $Fiducials($name,fid)
            }

            if {$::Module(verbose)} {
                puts "SetActiveList: name = $name, list = [FiducialsGetPointIdListFromName $name]"
            }

            foreach pid [FiducialsGetPointIdListFromName $name] {
                set pidsList $name
                if {[$s index "[Point($pid,node) GetName]"] == -1} {
                    # add it
                    if {$::Module(verbose)} { puts "SetActiveList: Adding a fid $pid, selected id list = $Fiducials($fid,selectedPointIdList)\n\tmenu = $menu\n\ts = $s"}                        
                    if {$menu == ""} {
                        # set thismenu [lindex $menulist $menuindex] 
                        foreach thismenu $menulist {
                            $s add "[Point($pid,node) GetName]" -text "[Point($pid,node) GetName]" \
                                -command "FiducialsSelectionFromCheckbox $thismenu $s no $pid"
                            if {$::Module(verbose)} {
                                puts "SetActiveList: adding command for menu $thismenu"
                            }
                        }
                        incr menuindex
                        if {$::Module(verbose)} {
                            puts "\t menu was empty, used $menulist, s = $s, pid = $pid"
                        }
                    } else {
                        $s add "[Point($pid,node) GetName]" -text "[Point($pid,node) GetName]" \
                            -command "FiducialsSelectionFromCheckbox $menu $s no $pid"
                    }
                }
                if {[info exists Fiducials($name,fid)] == 1} {
                    set fid $Fiducials($name,fid)
                    set index [lsearch $Fiducials($fid,pointIdList) $pid]
                    # is there a selected point id list?
                    if {[info exists Fiducials($fid,selectedPointIdList)] == 1} {
                        # if it is selected, tell the scroll
                        if {[lsearch $Fiducials($fid,selectedPointIdList) $pid] != -1} {
                            if {[lsearch [$s getselind] $index] == -1} {
                                if {$::Module(verbose)} { puts "FiducialsSetActiveList: $s selecting index \"$index\"" }
                                $s select "$index"
                            } else {
                                if {$::Module(verbose)} { puts "FiducialsSetActiveList $index already selected" }
                            }
                        } else { 
                            # deselect it
                            if {[lsearch [$s getselind] $index] != -1} {
                                if {$::Module(verbose)} { puts "FiducialsSetActiveList: $s deselecting $index"}
                                $s deselect "$index"
                            }
                        }
                    } else {
                        if {$::Module(verbose)} {
                            puts "FiducialsSetActiveList: no selectedPointIdList ofr fid $fid"
                        }
                    }
                }    
            }
        }
        if {![info exist pid]} {
            # could be the first call when the list is created
            if {$::Module(verbose)} {
                puts "FiducialsSetActiveList: No points found on menu:\n\t$menu"
            }
        }
        # if this point is on a new list, can't make it active just yet
        # as the active list id hasn't been updated yet, so FiducialsDisplayDescriptionActive won't do anything
        # puts "SetActiveList, current active list = $Fiducials(activeListID), passed in list id = $fid, this point $pid is on list $pidsList [lindex $Fiducials(listOfIds) [lsearch $Fiducials(listOfNames) $pidsList]] - don't change it here, as "
        if {0 && $Fiducials(activeListID) != $pidsList} {
            if {$::Module(verbose)} {
                puts "FiducialsSetActiveList setting last point on newly active list (pid = $pid, [Point($pid,node) GetName]) to be active"
            }
            set Fiducials(activePointID) $pid
            FiducialsDisplayDescriptionActive
        }

        # callback in case any module wants to know the name of the active list    
        if {$name == "None"} {
            foreach m $Module(idList) {
                if {[info exists Module($m,fiducialsActivatedListCallback)] == 1} {
                    if {$Module(verbose) == 1} {puts "Fiducials Activated List Callback: $m"}
                    $Module($m,fiducialsActivatedListCallback)  "default" $name ""
                }
            }
        } else {
            set id $Fiducials($name,fid)
            set type [Fiducials($id,node) GetType]
            foreach m $Module(idList) {
                if {[info exists Module($m,fiducialsActivatedListCallback)] == 1} {
                    if {$Module(verbose) == 1} {
                        puts "Fiducials Activated List Callback: $m"
                    }
                    $Module($m,fiducialsActivatedListCallback)  $type $name $id
                }
            }
        }
    } else {
        if {$::Module(verbose)} {
            puts "FidSetActiveList: didn't do anything because the list $name doesn't exist"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSelectionUpdate
# Update the selection of this point.
# .ARGS
# int fid id of the fiducials list
# int pid id of the point
# bool on is the point selected now?
# .END
#-------------------------------------------------------------------------------
proc FiducialsSelectionUpdate {fid pid on} {
    
    global Fiducials Module

    if {$::Module(verbose)} {
        puts "\n\nFiducialsSelectionUpdate: fid = $fid (active list = $Fiducials($Fiducials(activeList),fid)) pid = $pid, on = $on."
        if {[info exists Fiducials($fid,selectedPointIdList)]} {
            puts "\tselected point id list = $Fiducials($fid,selectedPointIdList)"
        }
    }

    # if the selected point id list doesn't exist, create an empty list
    if {[info exist Fiducials($fid,selectedPointIdList)] == 0} {
        set Fiducials($fid,selectedPointIdList) ""
    }

    # only do stuff with the checkbox list if it's the active list

    ### ON CASE #####
    if {$on } {
        set index [lsearch $Fiducials($fid,selectedPointIdList) $pid]
        if { $index == -1} {
            lappend Fiducials($fid,selectedPointIdList) $pid
            if {$::Module(verbose)} {
                puts "added $pid to selected point id list $Fiducials($fid,selectedPointIdList), point id list = $Fiducials($fid,pointIdList)"
            }
            # tell procedure who want to know about it
            # callback 
            foreach m $Module(idList) {
                if {[info exists Module($m,fiducialsPointSelectedCallback)] == 1} {
                    if {$Module(verbose) == 1} {
                        puts "FiducialsSelectionUpdate: Fiducials Point Selected Callback: $m"
                    }
                    $Module($m,fiducialsPointSelectedCallback) $fid $pid
                }
            }
            
        } else {
            # if it is already selected, do nothing
            if {$::Module(verbose)} {
                puts "FiducialsSelectionUpdate: already selected, returning"
            }
            return
        }
    }
    
    if {!$on} {
    
        ### OFF CASE ###
        set index [lsearch $Fiducials($fid,selectedPointIdList) $pid]
        if { $index != -1} {
            # remove the id from the list
            set Fiducials($fid,selectedPointIdList) [lreplace $Fiducials($fid,selectedPointIdList) $index $index]
        } else {
            # if it is already deselected, do nothing
            if {$::Module(verbose)} {
                puts "FiducialsSelectionUpdate: already deselected, returning"
            }
            return 
        }
    }
    FiducialsUpdateAllCheckBoxes $fid $pid $on
    if {$::Module(verbose)} {
        puts "SelectionUpdate: calling FiducialsUpdateSelectionForActor on fid list $fid (pt list = $Fiducials($fid,pointIdList))"
        puts "FiducialsSelectionUpdate: calling FiducialsUpdateSelectionForActor with a pid $pid"
    }
    FiducialsUpdateSelectionForActor $fid $pid
}

#-------------------------------------------------------------------------------
# .PROC FiducialsUpdateAllCheckBoxes
# encapsulate going through all the active checkboxes and updating selections
# .ARGS
# int fid fiducials list id
# int pid point id - not used
# bool on is the point selected or no? - not used
# .END
#-------------------------------------------------------------------------------
proc FiducialsUpdateAllCheckBoxes {fid {pid -1} {on 1}} {
    global Fiducials

    # update all the scrollboxes if this is the active list
    if {$Fiducials(activeList) != "None" &&
        $fid == $Fiducials($Fiducials(activeList),fid)} {
    
        set counter 0
        foreach menu $Fiducials(mbActiveList) {
            # get the corresponding scrollbox
            set cb [lindex $Fiducials(scrollActiveList) $counter]
            if { $cb == "" } { continue }
            if {[$menu cget -text] == $Fiducials($fid,name)} {
                if {$::Module(verbose)} {
                    if {[string first "FiducialsEdit" $menu] != -1} { 
                        # puts "FiducialsUpdateAllCheckBoxes:\n\tmenu = $menu\n\tcb = $cb\n\tmenu text = [$menu cget -text]\n\tfid = $fid\n\tfid name = $Fiducials($fid,name)"
                    }
                }
                # clear everything
                # $scroll selection clear 0 end
                if {[$cb getnumbuttons] == 0} {
                    if {$::Module(verbose)} { 
                        # puts "FiducialsUpdateAllCheckBoxes: no elements, not deselecting"
                    }
                } else {
                    if {$::Module(verbose)} {
#                        puts "FiducialsUpdateAllCheckBoxes: selected list = $Fiducials($fid,selectedPointIdList), deselecting everything and then reselected (right now cb sel = [$cb getselind])"
                    }
                    $cb deselect
                    
                    #re-color the entries
                    foreach pid $Fiducials($fid,selectedPointIdList) {
                        set sid [lsearch $Fiducials($fid,pointIdList) $pid]
                        # last arg determines if invoke 1 or select 0
                        $cb select $sid 0
                        if {$::Module(verbose)} {
                            if {[string first "FiducialsEdit" $menu] != -1} {
                                # puts "FiducialsUpdateAllCheckBoxes: pid = $pid, selected sid = $sid for cb $cb"
                            }
                        }
                    }
                }
                incr counter
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSelectionFromPicker
#  If an existing Fiducial point matches the actor and cellId, then it selects it 
# or unselects it, depending on its current state
#  
# .ARGS 
#       str actor a vtkActor
#       int cellId ID of the selected cell in the actor
# .END
#-------------------------------------------------------------------------------
proc FiducialsSelectionFromPicker {actor cellId} {
    global Fiducials Point Module
    
    foreach fid $Fiducials(idList) {
        foreach r $Fiducials(renList) {
            if { $actor == "Fiducials($fid,actor,$r)" } {
                set pid [FiducialsPointIdFromGlyphCellId $fid $cellId]
                if {[info exist Fiducials($fid,selectedPointIdList)]} {
                    set index [lsearch $Fiducials($fid,selectedPointIdList) $pid]
                } else {
                    set index -1
                }
                if {$::Module(verbose)} {
                    puts "FiducialsSelectionFromPicker: pid $pid in selected point list = $index"
                }
                if { $index != -1} {
                    # if it is already selected, it needs to unselected
                    FiducialsSelectionUpdate $fid $pid 0
                } else {
                    FiducialsSelectionUpdate $fid $pid 1
                }
                return 1
            }
        }
    }
    puts "Unable to determine which fiducial was selected, please try again."
    return 0
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSelectionFromCheckbox
# Call back from the checkboxes, make sure the id is either in the selected list or not
# and then call FiducialsSelectionFromScroll, and update the other active checkbox lists
# via a call to FiducialsUpdateAllCheckBoxes.
# .ARGS 
# widget menu the menu with the selected list name as the current text
# widget cb the checkbox containing the fiducials list
# int focusOnActiveFiducial if true, set the main view window's focus on the active fiducial
# int pid  point id for the one fiducial to update
# .END
#-------------------------------------------------------------------------------
proc FiducialsSelectionFromCheckbox {menu cb focusOnActiveFiducial pid} {
    global Fiducials Module

    if {$::Module(verbose)} {
        puts "FiducialsSelectionFromCheckbox for menu $menu, cb $cb, pid = $pid."
    }

    # get the active list from the menu
    set name [$menu cget -text]

    if {$::Module(verbose)} {
        puts "FiducialsSelectionFromCheckbox: name = $name"
    }

    if { $name != "None" } {
        # get the id of the active list for that menu
        set fid $Fiducials($name,fid)
        # is point that changed sel or unsel?
        set selind [$cb getselind]
        if {$::Module(verbose)} {
            puts "FiducialsSelectionFromCheckbox: selected = $selind, pid = $pid"
        }
        if {[info exists Fiducials($fid,selectedPointIdList)] == 0} {
            set Fiducials($fid,selectedPointIdList) ""
        }
        set selpind [lsearch $Fiducials($fid,selectedPointIdList) $pid]
        set checkboxInd [lsearch $Fiducials($fid,pointIdList) $pid]
        if {[lsearch $selind $checkboxInd] == -1} {
            set on 0
            # it's not selected, make sure it's not on the selected fids list
            if {$selpind != -1} {
                # remove it from the list
                if {$::Module(verbose)} {
                    puts "Removing pid $pid from selected list at index $selpind"
                }
                set Fiducials($fid,selectedPointIdList) [lreplace $Fiducials($fid,selectedPointIdList) $selpind $selpind]
                if {$::Module(verbose)} {
                    puts "\t new list = $Fiducials($fid,selectedPointIdList)"
                }
            } else { 
                if {$::Module(verbose)} {
                    puts "it's not on the list" 
                }
            }
        } else {
            set on 1
            # make sure it's on the selected fids list
            if {$selpind == -1} {
                # add it
                lappend Fiducials($fid,selectedPointIdList) $pid
                set on 1
                if {$::Module(verbose)} {
                    puts "Added pid $pid to the selected list: $Fiducials($fid,selectedPointIdList)"
                }
            } else { 
                if {$::Module(verbose)} {
                    puts "Pid $pid already on the list at $selpind: $Fiducials($fid,selectedPointIdList)"
                }
            }
        }
        # and now update the scroll selection
        if {$::Module(verbose)} {
            puts "\t\t**FiducialsSelectionFromCheckbox calling FiducialsSelectionFromScroll"
        }
        FiducialsSelectionFromScroll $menu $cb $focusOnActiveFiducial $pid

        if {$::Module(verbose)} {
            puts "calling FiducialsUpdateAllCheckBoxes... on = $on"
        }
        # don't need these in the call $pid $on
        FiducialsUpdateAllCheckBoxes $fid $pid $on
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSelectionFromScroll
# 
# Given a check box and a menu with a selected Fiducials list, update the list 
# of selected/unselected Points to match the selected fiducials list.
#
# .ARGS 
# widget menu the menu with the selected list name as the current text
# widget cb the checkbox containing the fiducials list
# int focusOnActiveFiducial if true, set the main view window's focus on the active fiducial
# int pid optional point id, if just updating one fiducial
# .END
#-------------------------------------------------------------------------------
proc FiducialsSelectionFromScroll {menu cb focusOnActiveFiducial {pid -1}} {
    global Fiducials Module

    if {$::Module(verbose)} {
        puts "FiducialsSelectionFromScroll for menu $menu, cb $cb, pid = $pid."
    }
    
    # get the active list from the menu
    set name [$menu cget -text]

    if {$::Module(verbose)} {
        puts "FiducialsSelectionFromScroll: name = $name"
    }

    if { $name != "None" } {
        # get the id of the active list for that menu
        set fid $Fiducials($name,fid)
        
        # tell procedures who want to know about it
        # callback 
        foreach m $Module(idList) {
            if {[info exists Module($m,fiducialsPointSelectedCallback)] == 1} {
                if {$Module(verbose) == 1} {puts "Fiducials Start Callback: $m"}
                $Module($m,fiducialsPointSelectedCallback) $fid $pid
            }
        }
        if {$::Module(verbose)} { puts "FiducialsSelectionFromScroll: after call backs: $Fiducials($fid,selectedPointIdList)"}

        # now update the actors
        if {$::Module(verbose)} {
            puts "FiducialsSelectionFromScroll: updating the actor from fid list $fid for $pid"
        }
        FiducialsUpdateSelectionForActor $fid $pid
        
        if { $focusOnActiveFiducial=="yes" } {
            foreach {x y z} [Point($Fiducials(activePointID),node) GetXYZ] { break }
            MainViewSetFocalPoint $x $y $z
            RenderAll
        }

        # turn off editing in case we had been editing the previously selected fiducial
        FiducialsInteractActiveEnd

    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsUpdateSelectionForActor
# 
# Update the color of the glyphs (points) for a given Fiducials actor, based
# on the current selection list  
#
# .ARGS 
#       int fid Mrml id of the Fiducial list to be updated
# int pid optional point id 
# .END
#-------------------------------------------------------------------------------
proc FiducialsUpdateSelectionForActor {fid {pid -1}} {
    global Fiducials Module
    
    if {$::Module(verbose)} {
        puts "FiducialsUpdateSelectionForActor: fid = $fid, point id list = $Fiducials($fid,pointIdList), pid = $pid"
    }

    if {$pid == -1} {
        set pidList $Fiducials($fid,pointIdList) 
    } else {
        set pidList $pid
    }
    foreach pid $pidList {
        # if the point is selected
        if {[info exists Fiducials($fid,selectedPointIdList)] == 0} {
            set Fiducials($fid,selectedPointIdList) ""
        }

        # change 2006-05-04: even when deselecting, make it the active point, if it's on the active list
        # puts "FiducialsUpdateSelectionForActor: active list id = $Fiducials(activeListID), this list id = $fid (pid = $pid)"
        if {0 && $Fiducials(activeListID) == $fid} {
            if {$::Module(verbose)} {
                puts "FiducialsUpdateSelectionForActor: setting active list id to $fid, active point id to $pid"
            }
#            set Fiducials(activeListID)  $fid
            set Fiducials(activePointID) $pid
        }

        # if {$::Module(verbose)} { puts "\tis the pt $pid in $Fiducials($fid,selectedPointIdList)?" }
        if {[lsearch $Fiducials($fid,selectedPointIdList) $pid] != -1} { 
            # if {$::Module(verbose)} { puts "\t\tyes (scalar id from point id = [FiducialsScalarIdFromPointId $fid $pid] )" }
            set Fiducials(activeListID)  $fid
            set Fiducials(activePointID) $pid


            # color the point to show it is selected
            set scalarIndex [FiducialsScalarIdFromPointId $fid $pid]
            if {$scalarIndex >= 0 && $scalarIndex < [Fiducials($fid,scalars) GetNumberOfTuples]} {
                Fiducials($fid,scalars) SetTuple1 $scalarIndex 1
            }
            # color the text
            foreach r $Fiducials(renList) {
                if {[info command Point($pid,follower,$r)] != ""} {
                    eval [Point($pid,follower,$r) GetProperty] SetColor $Fiducials(textSelColor)
                }
            }

            # do the same for 2d point
            set s [lindex [Point($pid,node) GetXYSO] 2]
            set r [FiducialsSliceNumberToRendererName $s]
            if {$::Module(verbose)} { 
              #  puts "FiducialsUpdateSelectionForActor: Setting selected for slice $s, renderer $r for pid $pid"
            }
            set scalarIndex [FiducialsScalarIdFromPointId2D $fid $pid $r]
            if {$scalarIndex != -1} {
                Fiducials($fid,scalars2D,$r) SetTuple1 $scalarIndex 1
            } else { 
                if {$::Module(verbose)} {
               #     puts "FiducialsUpdateSelectionForActor: not setting tuple1 for pid $pid $r, scalar index == -1" 
                } 
            }
            # if it is not selected
        } else {
            # if {$::Module(verbose)} { puts "\t\tno" } 
            # color the point the default color
            Fiducials($fid,scalars) SetTuple1 [FiducialsScalarIdFromPointId $fid $pid] 0
            # uncolor the text
            foreach r $Fiducials(renList) {
              eval [Point($pid,follower,$r) GetProperty] SetColor [Fiducials($fid,node) GetColor]
            }

            
            # for 2d case
            set s [lindex [Point($pid,node) GetXYSO] 2]
            set r [FiducialsSliceNumberToRendererName $s]
            set scalarIndex [FiducialsScalarIdFromPointId2D $fid $pid $r]
            if {$scalarIndex != -1} {
                Fiducials($fid,scalars2D,$r) SetTuple1 $scalarIndex 0
            } else { 
                if {$::Module(verbose)} { 
                  #  puts "FiducialsUpdateSelectionForActor: not setting scalars 2D tuple1 for pid $pid $r, scalar index == -1" 
                } 
            }
        }
    }
    
    if {$::Module(verbose)} {
        # puts "FiducialsUpdateSelectionForActor: calling FiducialsDisplayDescriptionActive fid = $fid, pid = $pid"
    }
    FiducialsDisplayDescriptionActive

    Fiducials($fid,pointsPD) Modified
    foreach r $Fiducials(renList2D) {
        Fiducials($fid,pointsPD2D,$r) Modified
    }
    
    Render3D
    RenderSlices
}

###############################################################################
#
#
#                   HELPER METHODS
#
#
##############################################################################

#-------------------------------------------------------------------------------
# .PROC FiducialsPointIdFromGlyphCellId
#
# Returns the Point Id that corresponds to the cell id of a picked Fiducials vtk actor. 
# This is a convenient way to know which glyph (point) was picked since a Fiducials actor 
# can have many glyphs (points).
#
# .ARGS 
#       int fid the Mrml id of the Fiducial list that contains the point
#       int cid the vtk cell Id
# .END
#-------------------------------------------------------------------------------
proc FiducialsPointIdFromGlyphCellId { fid cid } {
    global Fiducials Point
    
    # it's either a symbol or a sphere
    set num [ [Fiducials($fid,glyphs) GetSource 0]  GetNumberOfCells]
    
    set vtkId [expr $cid/$num]
    return [lindex $Fiducials($fid,pointIdList) $vtkId]
}

#-------------------------------------------------------------------------------
# .PROC FiducialsScalarIdFromPointId
#
#  Return the vtk scalar ID that corresponds to that point ID
# .ARGS 
#       int fid the Mrml id of the Fiducial list that contains the point
#       int pid Point ID
# .END
#-------------------------------------------------------------------------------
proc FiducialsScalarIdFromPointId {fid pid } {
    global Fiducials Point

    # returns the index of the Point with the corresponding pid 
    # (its position in the list of pointIdList)
    # This works because scalars are organized like the list of pointIdList
    # so if Point with id 4 is in 2nd position in the list, the corresponding 
    # scalar for that point is also in 2nd position in the list of scalars 
    return [lsearch $Fiducials($fid,pointIdList) $pid]
}

#-------------------------------------------------------------------------------
# .PROC FiducialsScalarIdFromPointId2D
#
#  Return the vtk scalar ID that corresponds to that 2D point ID.<br>
# Takes into account that the 2d fiducials are in separate lists for each imager,
# and that each imager (2d render window) only has points defined for the fiducials
# visible on the currently displayed slice.
# .ARGS 
# int fid the fiducial list id
# int pid Point ID
# string r the renderer
# .END
#-------------------------------------------------------------------------------
proc FiducialsScalarIdFromPointId2D {fid pid r } {
    global Fiducials Point

    # returns the index of the Point with the corresponding pid 
    # (its position in the list of pointIdList)
    # This works because scalars for each renderer are organized like the list of pointIdList for each renderer
    # so if Point with id 4 is in 2nd position in the list, the corresponding 
    # scalar for that point is also in 2nd position in the list of scalars 

    set pointListIndex [lsearch $Fiducials($fid,pointIdList,$r) $pid]

    # if it's not in this renderer's point list, return -1
    if {$pointListIndex == -1} {
        if {$::Module(verbose)} { 
            puts "FiducialsScalarIdFromPointId2D: point $pid not on renderer's $r id list, returning -1"
        }
        return -1
    }

    # otherwise, need to take a look at the points that are visible on this slice 
    # and see if pid is one of them
    set xyso [Point($pid,node) GetXYSO]
    for {set i 0} { $i < [Fiducials($fid,points2D,$r) GetNumberOfPoints]} { incr i} { 
        set xyo [Fiducials($fid,points2D,$r) GetPoint $i]
        if {$::Module(verbose)} {
           # puts "Testing point $i of the points2D array for renderer $r: $xyo"
        }
        # test if the x, y, offset are same
        if {[lindex $xyo 0] == [lindex $xyso 0] &&
            [lindex $xyo 1] == [lindex $xyso 1] &&
            [lindex $xyo 2] == [lindex $xyso 3]} {
            if {$::Module(verbose)} {
                # puts "xyo $xyo and xyso $xyso match, returning scalar id $i"
            }
            return $i
        }
    }


    # this is complicated by the fact that only the points that are visible on the current slice are added to the scalar list, so this may return -1 if the point hasn't been added.

    return -1
}

#############################################################################
#
#
#
#                   USEFUL GETTER PROCEDURES FOR OTHER MODULES              #
#
#
#
#############################################################################

#-------------------------------------------------------------------------------
# .PROC FiducialsGetAllNodesFromList
# Return the mrml Point and EndFiducials nodes belonging to that Fiducials list
# (used in DataCutNode->DataGetChildrenSelectedNode).
# .ARGS 
# str name the name of the Fiducial list 
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetAllNodesFromList {name} {
    
    global Fiducials Point Mrml
    
    if {$name == "None"} {
        # do nothing 
        return
    }
    if { $Fiducials(activeList) == $name } {
        set Fiducials(activeList) "None"
    }
    
    set fid $Fiducials($name,fid)
    
    set list ""
    foreach pid $Fiducials($fid,pointIdList) {
        lappend list Point($pid,node)
    }

    lappend list EndFiducials($fid,node)
    return $list 
}

#-------------------------------------------------------------------------------
# .PROC FiducialsAddActiveListFrame
#  Given a frame, this procedure packs into it an fiducials list drop down menu
#  and a checkbox list that contains all the fiducial points of the active list. 
#  These are updated automatically when a new list/point are created/selected.
# .ARGS
#      str frame tk frame in which to pack the Fiducials panel
#      int scrollHeight height of the scrollbar, a good range is 200<->300, if not in that range 275 is used.
#      int scrollWidth width if the scrollbar, a good range is 5<->15, if not in that range, 10 is used
#      list defaultNames (optional) the name of the Fiducial lists you would like to add to the drop down menu 
# .END
#-------------------------------------------------------------------------------
proc FiducialsAddActiveListFrame {frame scrollHeight scrollWidth {defaultNames ""}} {
    global Fiducials Gui
    
    # put a scrolled frame around it all, with a good height
    if {$scrollHeight < 200 || $scrollHeight > 300} {
        set height 275
    } else {
        set height $scrollHeight
    }
    if {$scrollWidth < 5 || $scrollWidth > 15} {
        set sbWidth 10
    } else {
        set sbWidth $scrollWidth
    }
    set sf [iwidgets::scrolledframe $frame.sf -height $height -width 20  -sbwidth $sbWidth \
                -vscrollmode dynamic -hscrollmode dynamic -borderwidth 1 \
               -troughcolor $Gui(activeWorkspace) -background $Gui(activeWorkspace)]
    pack $frame.sf -expand yes -fill both
    set frame [$sf childsite]

    foreach subframe "how menu scroll" {
        frame $frame.f$subframe -bg $Gui(activeWorkspace)
        pack $frame.f$subframe -side top -padx 0 -pady $Gui(pad) -fill x -expand true
    }

    #-------------------------------------------
    # frame->How frame
    #-------------------------------------------
    set f $frame.fhow
    
    
    eval {button $f.bhow -text "How do I create Fiducials?"} $Gui(WBA)
    TooltipAdd $f.bhow "$Fiducials(howto)"
    
    eval {button $f.bdel -text "Delete Active List" -command "FiducialsDeleteActiveList"} $Gui(WBA)
    pack $f.bhow $f.bdel -side top
    TooltipAdd $f.bdel "Deletes all the points of the active list"
    
    #-------------------------------------------
    # frame->Menu frame
    #-------------------------------------------
    set f $frame.fmenu
    
    eval {label $f.lActive -text "Fiducials Lists: "} $Gui(WLA)\
        {-bg $Gui(inactiveWorkspace)}
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) -pady 0 
    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Fiducials(mbActiveList) $f.mbActive
    lappend Fiducials(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # frame->ScrollBox frame
    #-------------------------------------------
    set f $frame.fscroll
    
    # Create and Append widgets to list that gets refreshed during UpdateMRML
    # set scroll [ScrolledListbox $f.list 1 1 -height $scrollHeight -width $scrollWidth -selectforeground red -selectmode multiple]
    
    set cs $f
    
    # now put in a checkbox

    if {[catch "package require iSlicer" errmsg] == 1} {
        puts "Ooops, can't use the ischeckbox"
        set cb [checkbox  $cs.cb]
    } else {
        set cb [iwidgets::ischeckbox $cs.cb -relief sunken -labeltext "Fiducials" -borderwidth 2 -labelmargin 10 -background $Gui(activeWorkspace) -labelfont {helvetica 8}]
        if {$::Module(verbose)} {
            puts "added checkbox $cb"
        }
    }


    bind $cb <Control-ButtonRelease-1> "FiducialsSelectionFromScroll $frame.fmenu.mbActive $cb yes" 
    bind $cb <ButtonRelease-1> "FiducialsSelectionFromScroll $frame.fmenu.mbActive $cb no" 

    frame $f.fName -bg $Gui(activeWorkspace)
   
    eval {label $f.fName.lName -text "Rename:"} $Gui(WLA)
    eval {entry $f.fName.nameEntry -width 15 -textvariable Fiducials(activeName) } $Gui(WEA)
    bind $f.fName.nameEntry <Return> {FiducialsDescriptionActiveUpdated}
    eval {button $f.fName.bDelete -text "Delete" -command "FiducialsDeleteActivePoint"} $Gui(WBA)
    
    TooltipAdd $f.fName.bDelete "Delete the active point"

    eval {label $f.xyzLabel -textvariable Fiducials(activeXYZ) } $Gui(WLA) 
    eval {label $f.xyLabel -textvariable Fiducials(activeXY) } $Gui(WLA)

    eval {button $f.xyzEditButton -text "Edit..." -command FiducialsInteractActiveStart} $Gui(WBA) 
    eval {button $f.xyzEditButtonSlices -text "Edit w/Slices..." -command "FiducialsInteractActiveStart Slices"} $Gui(WBA) 

    eval {entry $f.descriptionEntry -width 25 -textvariable Fiducials(activeDescription) } $Gui(WEA)
    bind $f.descriptionEntry <Return> {FiducialsDescriptionActiveUpdated}

    # lappend Fiducials(scrollActiveList) $scroll
    lappend Fiducials(scrollActiveList) $cb

#    pack $f.list $f.nameEntry $f.xyzLabel $f.xyLabel $f.xyzEditButton $f.xyzEditButtonSlices $f.descriptionEntry -side top
    pack $cb  \
        -side top -expand true -fill both
#    pack $f.lName $f.nameEntry -side top
    pack $f.fName -side top
    pack $f.fName.lName $f.fName.nameEntry $f.fName.bDelete -side left

    pack $f.xyzLabel $f.xyLabel $f.xyzEditButton $f.xyzEditButtonSlices $f.descriptionEntry \
        -side top

    # if there any default names specified, add them to the list
    foreach d $defaultNames {
        $frame.fmenu.mbActive.m add command -label $d -command "FiducialsSetActiveList $d"
            # -command "FiducialsSetActiveList $d $frame.fmenu.mbActive $cb"
        lappend Fiducials(defaultNames) $d
    }
} 

#-------------------------------------------------------------------------------
# .PROC FiducialsInteractActiveCB
#  Handle interaction events from the PointWidget
# .ARGS
# list args not used
# .END
#-------------------------------------------------------------------------------
proc FiducialsInteractActiveCB {args} {
    global Fiducials


    if { $Fiducials(activePointID) == "None" } {
        return
    }

    if { [info command Fiducials(csys,actor)] == "" } { 
        return
    }

    foreach var "x y z" val [Fiducials(csys,actor) GetPosition] {
        set $var $val
    }  

    # update fiducial
    Point($Fiducials(activePointID),node) SetXYZ $x $y $z
    eval "Point($Fiducials(activePointID),node) SetOrientationWXYZ [Fiducials(csys,actor) GetOrientationWXYZ]"
    FiducialsUpdateMRML

    # update slice location
    if { $Fiducials(csys,SlicesMode) == "Slices" } {
        for {set slice 0} {$slice < 3} {incr slice} {
            switch [$::Interactor(activeSlicer) GetOrientString $slice] {
                "Axial" { MainSlicesSetOffset $slice $z}
                "Sagittal" { MainSlicesSetOffset $slice $x}
                "Coronal" { MainSlicesSetOffset $slice $y}
            }
            RenderSlice $slice
        }
    }

    # move callback in case any module wants to know that Fiducials have been updated 
    foreach m $::Module(idList) {
        if {[info exists ::Module($m,fiducialsMoveCallback)] == 1} {
            if {$::Module(verbose) == 1} {puts "Fiducials Move Callback: $m"}
            $::Module($m,fiducialsMoveCallback)  
        }
    }

    set $::View(render_on) 1
    Render3D

}

#-------------------------------------------------------------------------------
# .PROC FiducialsInteractActiveStart
#  Use a vtkPointWidget to set the fiducial location
# .ARGS
# string mode the coordinate system actor's slices mode. Optional, defaults to NoSlices. 
# .END
#-------------------------------------------------------------------------------
proc FiducialsInteractActiveStart { {mode "NoSlices"} } {
    global Fiducials Csys

    if { $Fiducials(activePointID) == "None" } {
        return
    }
    set Fiducials(csys,SlicesMode) $mode

    #
    # reset the interactors first then create the pipeline
    #
    FiducialsInteractActiveEnd

    if { [info command Fiducials(csys,actor)] == "" } { 
        #CsysCreate Fiducials csys -1 -1 -1
        CsysCreate Fiducials csys 150 1 5
        set ::Module(Fiducials,procXformMotion) FiducialsInteractActiveCB 
    }
    Fiducials(csys,actor) SetOrientation 0 0 0
    eval "Fiducials(csys,actor) RotateWXYZ [Point($Fiducials(activePointID),node) GetOrientationWXYZ]"
    eval "Fiducials(csys,actor) SetPosition [Point($Fiducials(activePointID),node) GetXYZ]"

    set Csys(active) 1
    MainAddActor Fiducials(csys,actor)
    FiducialsInteractActiveCB 
}

#-------------------------------------------------------------------------------
# .PROC FiducialsInteractActiveEnd
#  Kill out the current interactive session
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsInteractActiveEnd {} {
    global Fiducials

    if { [info command Fiducials(csys,actor)] == "" } { 
        return
    }

    set Csys(active) 0
    MainRemoveActor Fiducials(csys,actor)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC FiducialsGetPointCoordinates
#  This procedure returns the xyz coordinates of the Point with Mrml id pid
# .ARGS
# int pid the mrml id of the point
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetPointCoordinates { pid } {
    global Fiducials Point
    
    return [Point($pid,node) GetXYZ]
}

#-------------------------------------------------------------------------------
# .PROC FiducialsWorldPointXYZ
#
#  Created by Peter Everett. <br>
# Returns the xyz coordinates for the point with id pid in the list with id fid and 
# deals with transformations. We don't support transformations of Fiducials, so use 
# FiducialsGetPointCoordinates instead. When we support transformations of Fiducials, 
# FiducialsGetPointCoordinates should probably be changed to take the transformations 
# into account, and we should get rid of this method.
#   
# .ARGS
# int fid the id of the fiducials list
# int pid the point id
# .END
#-------------------------------------------------------------------------------
proc FiducialsWorldPointXYZ { fid pid } {
    global Fiducials Point

    Fiducials(tmpXform) SetMatrix Fiducials($fid,xform)
    #eval Fiducials(tmpXform) SetPoint [Point($pid,node) GetXYZ] 1
    #set xyz [Fiducials(tmpXform) GetPoint]
    eval Fiducials(tmpXform) TransformPoint $xyz
    return $xyz
}

#-------------------------------------------------------------------------------
# .PROC FiducialsGetPointIdListFromName
# Return the MRML ID of the Fiducials Points in the list with that name. If the 
# name is not found, return an empty string.
# .ARGS
# str name the name of the fiducials list.
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetPointIdListFromName { name } {
    global Fiducials Point
    if { [lsearch $Fiducials(listOfNames) $name] != -1 } {
        set fid $Fiducials($name,fid)
        return $Fiducials($fid,pointIdList) 
    } else {
        return ""
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsGetSelectedPointIdListFromName
# Return the MRML ID of the selected Fiducials Points in the list with that name
# .ARGS
# string name the name of the fiducials list
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetSelectedPointIdListFromName { name } {
    global Fiducials Point
    if { [lsearch $Fiducials(listOfNames) $name] != -1 } {
        set fid $Fiducials($name,fid)
        if {[info exists Fiducials($fid,selectedPointIdList)]} {
            return $Fiducials($fid,selectedPointIdList) 
        } else { return "" } 
    } else {
        return ""
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsGetAllSelectedPointIdList
# Return the Id List of all the selected Points, regardless what list they belong to.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetAllSelectedPointIdList {} {
    global Fiducials Point
    set list ""
    foreach name $Fiducials(listOfNames) {
        set fid $Fiducials($name,fid)
        if {[info exist Fiducials($fid,selectedPointIdList)]} {
            set list [concat $list $Fiducials($fid,selectedPointIdList)] 
        }
    }
    return $list
}

#-------------------------------------------------------------------------------
# .PROC FiducialsGetActiveSelectedPointIdList
# Return the Id List of all of the selected points in the Active list.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetActiveSelectedPointIdList {} {
    global Fiducials

    return [FiducialsGetSelectedPointIdListFromName $Fiducials(activeList)]
}

#-------------------------------------------------------------------------------
# .PROC FiducialsToTextCards
# Convert the Fiducials to Text Cards relative to a given model
# .ARGS
# int modelid the id of the model
# .END
#-------------------------------------------------------------------------------
proc FiducialsToTextCards {modelid} {

    if { $modelid != "" && [FiducialsUseTextureText] } {
        catch {[Fiducials_sch GetTextCards] RemoveAllItems}
        catch "Fiducials_sch Delete"
        vtkSorter Fiducials_sorter 
        Fiducials_sch SetRenderer viewRen

        foreach tc [vtkTextCard ListInstances] {
            if { [string match Fiducials-tc* $tc] } {
                $tc RemoveActors viewRen
                $tc Delete
            }
        }
        foreach tt [vtkTextureText ListInstances] {
            if { [string match Fiducials-tt* $tt] } {
                $tt Delete
            }
        }

        foreach id $::Point(idList) {
            vtkTextureText Fiducials-tt-$id
            Fiducials-tt-$id SetText [Point($id,node) GetName]
            [Fiducials-tt-$id GetFontParameters] SetBlur 3
            Point($id,node) SetName "."
            [[Fiducials-tt-$id GetFollower] GetProperty] SetColor 0 0 0
            vtkTextCard Fiducials-tc-$id
            [Fiducials_sch GetTextCards] AddItem Fiducials-tc-$id
            Fiducials-tc-$id SetMainText Fiducials-tt-$id
            Fiducials-tc-$id SetCamera [viewRen GetActiveCamera]
            Fiducials-tc-$id CreateLine 0 0 0
            Fiducials-tc-$id SetLinePoint1Local 0 0 0
            Fiducials-tc-$id SetScale 7 
            Fiducials-tc-$id SetBoxEdgeColor 0 0 0
            Fiducials-tc-$id SetOpacityBase 0.7
            Fiducials-tc-$id SetBoxEdgeWidth 1.0
            eval Fiducials-tc-$id SetOffsetActorAndMarker Model($modelid,actor,viewRen) [Point($id,node) GetXYZ] 0 0 -10
            Fiducials-tc-$id AddActors viewRen
        }
    }
    FiducialsUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC FiducialsPrint2DPoints
# Prints out information about the 2D fiducials
# .ARGS
# int id the fiducials list id, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc FiducialsPrint2DPoints { {id 0} } {
    global Fiducials
    puts "Fiducials list id = $id, points ids = $Fiducials(0,pointIdList)"
    foreach r $Fiducials(renList2D) {
        puts "\nRenderer $r:"
        for {set i 0} { $i < [Fiducials($id,points2D,$r) GetNumberOfPoints]} { incr i} { 
            puts "Fiducials($id,points2D,$r) GetPoint $i = [Fiducials($id,points2D,$r) GetPoint $i]"
        }
        
        puts "From the point ID list for this fiducials list (r=$r) (list = $Fiducials($id,pointIdList,$r)):"
        foreach pid $Fiducials($id,pointIdList,$r) {
            puts "Point $pid XYSO = [Point($pid,node) GetXYSO]"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsSliceNumberToRendererName
# Returns the renderer name that corresponds to this slice window, assumes that 
# Fiducials(renList2D) has been built up so indexing into it via the slice window 
# number will return the proper renderer.
# .ARGS
# int s the slice window to return the renderer name for
# .END
#-------------------------------------------------------------------------------
proc FiducialsSliceNumberToRendererName { s } {
    global Fiducials

    if {$s == ""} { 
        puts "FiducialsSliceNumberToRendererName ERROR: empty input slice"
        return
    }

    if {$s < 0 || $s >= [llength $Fiducials(renList2D)]} {
        puts "FiducialsSliceNumberToRendererName ERROR: slice number $s not in range 0 to [expr [llength $Fiducials(renList2D)] - 1]"
        return
    }

    return [lindex $Fiducials(renList2D) $s]
}

#-------------------------------------------------------------------------------
# .PROC FiducialsMainFileClose
# Called when the scene is closed, to remove all actors that this module added to
# the scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsMainFileClose {} {
    global Fiducials

    # set the delete flag to be 1 and clear out everything
    FiducialsResetVariables 1
}

#-------------------------------------------------------------------------------
# .PROC FiducialsUpdateZoom2D
# Adjust the location of the 2d fids to match the zoom for this slice.
# Adjust all of them, so that if the slices are scrolled, they're all correct w/o another call
# .ARGS
# int s the slice number
# float zoom the zoom value
# .END
#-------------------------------------------------------------------------------
proc FiducialsUpdateZoom2D { s zoom } {
    global Fiducials 
# global Module

    # not quite right yet
    return

    set Module(verbose) 1

    if {$Fiducials(updating2DZoom) == 1} {
        if {$Module(verbose)} {
            puts "FiducialsUpdateZoom2D: already updating, returning"
        }
        return
    } 
    set Fiducials(updating2DZoom) 1

    if {$Module(verbose)} {
        puts "FiducialsUpdateZoom2D s= $s, zoom = $zoom, updating flag = $Fiducials(updating2DZoom)"
    }

    # try and find fids on this slice
    # foreach fiducials list
    set updateNeeded 0
    foreach fid $Fiducials(listOfIds) {
        foreach pid $Fiducials($fid,pointIdList) {
            foreach {x y pointSlice pointOffset} [Point($pid,node) GetXYSO] { break }
            if {$pointSlice == $s} {
                if {$Module(verbose)} {
                    puts "List $fid: Point $pid is on slice ${s}: x $x, y $y, o $pointOffset (slice offset = $::Slice($s,offset))"
                    puts "\txyz = [Point($pid,node) GetXYZ]"
                }
                $::Interactor(activeSlicer) SetScreenPoint $s $x $y
                set refPoint [$::Interactor(activeSlicer) GetReformatPoint]
                scan $refPoint "%d %d" zx zy
                if {$Module(verbose)} {
                    puts "\treformatpoint = $zx $zy (raw = $refPoint)"
                }
                # reset the point's xyso and flag to call FiducialsVTKUpdatePoints2D
                if {[info command Point($pid,node)] != ""} {
                    Point($pid,node) SetXYSO $zx $zy $pointSlice $pointOffset
                    set updateNeeded 1
                } else {
                    puts "FiducialsUpdateZoom2D: No point node for $pid!"
                }
            } else {
                if {$Module(verbose)} {
                    puts "List $fid: Point $pid is on slice $pointSlice, not the currently changing slice $s"
                }
            }
        }

        if {$updateNeeded} {
            if {$Module(verbose)} {
                puts "Need to update 2d fid locations for list $fid"
            }
            FiducialsVTKUpdatePoints2D $fid
            set updateNeeded 0
        }
    }
    set Fiducials(updating2DZoom) 0
}

#-------------------------------------------------------------------------------
# .PROC FiducialsUseTextureText
# Return 1 if the texture text classes are available on this platform
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FiducialsUseTextureText {} {

    if { $::tcl_platform(machine) == "x86_64" } {
        # don't use the freetype fonts on 64 bit machines for now...
        return 0
    }
    if { [info command vtkTextureText] != "" } {   
        return 1
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC FiducialsNewPointName
# Generates a new point name, for use in the fiducial list box and 3d glyph. Works
# correctly even if points have been deleted from the fiducial list.
# Returns the list name concatenated with a number larger than the integers at the end
# of all the other names on the list.
# .ARGS
# int fid the id of the fiducials list for which a new name is to be generated
# .END
#-------------------------------------------------------------------------------
proc FiducialsNewPointName { fid } {
    global Fiducials

    set listLength [llength $Fiducials($fid,pointIdList)]
    if {$::Module(verbose)} {
        puts "FiducialsNewPointName: fid = $fid, length of the fid list = $listLength"
    }

    set listName $Fiducials($fid,name)
    if {$listLength == 0} {
        return "${listName}0"
    }
    set highest 0
    foreach pid $Fiducials($fid,pointIdList) {
        set name [Point($pid,node) GetName]
        # deals with the case of a number at the end of the list name
        if {[regexp "${listName}(\[0-9\]\+)\$" $name matchVar thisNum] == 1} {
            if {$thisNum > $highest} {
                set highest $thisNum
            }
        }
    }
    # highest currently holds the largest number at the end of a point name, increment it by one and use it
    set highest [incr highest]
    if {$::Module(verbose)} {
        puts "FiducialsNewPointName: returning $highest"
    }

    return "$Fiducials($fid,name)$highest"
}

#-------------------------------------------------------------------------------
# .PROC FiducialsStorePresets
#  Save current settings to preset global variables.
# .ARGS
# int p the scene id
# .END
#-------------------------------------------------------------------------------
proc FiducialsStorePresets {p} {
    global Fiducials Preset

    if {$::Module(verbose)} {
        puts "FiducialsStorePresets p = $p"
    }
    foreach name $Fiducials(listOfNames) {
        set id $Fiducials($name,fid)
        if {$::Module(verbose)} { puts "\tname = $name, id = $id" }
        set Preset(Fiducials,$p,$name,visibility) $Fiducials($id,visibility)
        set Preset(Fiducials,$p,$name,selected) $Fiducials($id,selectedPointIdList)
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsRecallPresets
# Set current settings from preset global variables
# .ARGS
# int p the scene id
# .END
#-------------------------------------------------------------------------------
proc FiducialsRecallPresets {p} {
    global Fiducials Preset

    if {$::Module(verbose)} {
        puts "FiducialsRecallPresets p = $p"
    }
    foreach name $Fiducials(listOfNames) {
        set id $Fiducials($name,fid)
        if {$::Module(verbose)} {
            puts "\tname = $name, id = $id"
        }
        if {[info exist Preset(Fiducials,$p,$name,visibility)] == 0} {
            puts "WARNING: FiducialsRecallPresets no preset for visibility, scene $p, fiducials list $name (id = $id).\n\tUsing default: $Preset(Fiducials,$p,visibility)"
            set Preset(Fiducials,$p,$name,visibility) $Preset(Fiducials,$p,visibility)
        }
        set Fiducials($id,visibility) $Preset(Fiducials,$p,$name,visibility)
        set nodeName [Fiducials($id,node) GetName]
        FiducialsSetFiducialsVisibility $nodeName $Fiducials($id,visibility)
        if {[info exists Preset(Fiducials,$p,$name,selected)] == 0} {
            # use the default
            set Preset(Fiducials,$p,$name,selected) $Preset(Fiducials,$p,selected)
            puts "WARNING: FiducialsRecallPresets no preset for selected, scene $p, fiducials list $name (id = $id).\n\tUsing default: $Preset(Fiducials,$p,$name,selected)"
        }
        set Fiducials($id,selectedPointIdList) $Preset(Fiducials,$p,$name,selected)
        # update the GUI selections for the points on the list
        FiducialsUpdateAllCheckBoxes $id 
        FiducialsUpdateSelectionForActor $id 
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsLoadMRML
# Whenever the MRML Tree is loaded this function is called to update all
# Fiducials scene related information.
# .ARGS
# string tag
# string attr
# .END
#-------------------------------------------------------------------------------
proc FiducialsLoadMRML {tag attr} {
    global Mrml Fiducials

    if {$::Module(verbose)} {
        puts "FiducialsLoadMRML: tag = $tag, attr = $attr"
    }

    # get the module ref id element in the attr list to check it's a Fiducials state node
    set attrIndex 0
    set moduleRefIDPair [lindex $attr $attrIndex]
    while {[lindex $moduleRefIDPair 0] != "moduleRefID" && $attrIndex < [llength $attr]} {
        incr attrIndex
        set moduleRefIDPair [lindex $attr $attrIndex]
    }
    if {$tag == "Module" && ([lindex $moduleRefIDPair 1] == "Fiducials")} {
        set node [MainMrmlAddNode Module FiducialsState]
        foreach a $attr {
            set key [lindex $a 0]
            set val [lreplace $a 0 0]
            switch $key {
                "moduleRefID" {
                    # puts "\tHave the ref id $val"
                    $node SetModuleRefID $val
                }
                "name" {
                    # puts "\tHave the name $val"
                    $node SetName $val
                }
                "options" {
                    # puts "\tNOT USING options"
                }
                "default" {
                    # puts "\tHave one of the string options key = $key, val = $val"
                    $node SetValue $key $val
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC Fiducials RetrievePresetValues
# Called from MainOptionsRetrievePresetValues to save the values from a mrml node
# into the Presets array
# .ARGS
# vtkMrmlModuleNode node the node to grab values from
# str p the scene ID
# .END
#-------------------------------------------------------------------------------
proc FiducialsRetrievePresetValues {node p} {
    global Preset Module Fiducials

     # check to see that it's a Fiducials state node
    set ClassName [$node GetClassName]
    if {$ClassName == "vtkMrmlModuleNode" &&
        [$node GetModuleRefID] == "Fiducials"} {
        if {$::Module(verbose)} {
            puts "\tGetting presets from node $node"
        }
        set name [$node GetName]
        set id $name
        set Preset(Fiducials,$p,$id,visibility) [$node GetValue visibility]
        # use the names of the points, and get their ids
        set Preset(Fiducials,$p,$id,selected) [FiducialsGetPointIdsFromNames [$node GetValue selected]]
    } else {
        if {$::Module(verbose)} {
            puts "FiducialsRetrievePresetValues: wrong kind of node $node, class = $ClassName, module = [$node GetModuleRefID]"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsUnparsePresets
# Makes a mrml node out of the presets.
# Makes a Module node and adds it to the data tree.
# .ARGS
# int presetNum optional, defaults to empty string - currently not used
# .END
#-------------------------------------------------------------------------------
proc FiducialsUnparsePresets {{presetNum ""}} {
    global Preset Fiducials

    if {$presetNum != ""} {
        set p $presetNum
    } else {
        set p "default"
    }
    if {$::Module(verbose)} {
       puts "----> Unparsing Fiducials Presets for scene $p"
    }

    foreach name $Fiducials(listOfNames) {
        set node [MainMrmlAddNode "Module" "FiducialsState"]
        $node SetModuleRefID "Fiducials"
        $node SetName $name
        # check to see that the list presets were created
        if {[info exist Preset(Fiducials,$p,$name,visibility)]} {
            $node SetValue visibility $Preset(Fiducials,$p,$name,visibility)
        } else {
            if {$::Module(verbose)} {
                puts "WARNING: preset visibility missing for list $name, using default of $Preset(Fiducials,$p,visibility)"
            }
            $node SetValue visibility $Preset(Fiducials,$p,visibility)
        }
        if {[info exist Preset(Fiducials,$p,$name,selected)]} {
            # get the point names of the selected points and save those to the nodes
            set nameList ""
            foreach pointId $Preset(Fiducials,$p,$name,selected) {
                lappend nameList [Point($pointId,node) GetName]
            }
            $node SetValue selected $nameList
        } else {
            $node SetValue selected $Preset(Fiducials,$p,selected)
        }
        if {$::Module(verbose)} { puts "\tAdded node for list $name: $node"} 
    }
}

#-------------------------------------------------------------------------------
# .PROC FiducialsGetPointIdsFromNames
# Goes through the list of point names and returns a list of the point ids
# that are associated with them. Uses Point(id,node) GetName to find names.
# This is clunky because we don't save a mapping between point ids and names.
# .ARGS
# list pointNames a list of names associated with fiducial points
# .END
#-------------------------------------------------------------------------------
proc FiducialsGetPointIdsFromNames {pointNames} {
    global Point
    set pointIds ""
    foreach pointId $::Point(idList) {
        if {[lsearch $pointNames [Point($pointId,node) GetName]] != -1} {
            # this node's name is on the selected list, add it's id to the id list
            lappend pointIds $pointId
        }
    }
    return $pointIds
}
