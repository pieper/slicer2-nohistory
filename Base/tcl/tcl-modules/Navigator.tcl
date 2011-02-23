#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Navigator.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:00 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        Navigator.tcl
# PROCEDURES:  
#   NavigatorInit
#   NavigatorEnter
#   NavigatorExit
#   NavigatorBuildGUI
#   NavigatorSetFlatFileName
#   NavigatorCancelFlatFile
#   NavigatorDisplayFlatView .tFlat$name.fView$name $f.flatRenderWidget$name Navigator($name,Renderer) Navigator($name,Actor)
#   NavigatorSetEventBindings widget
#   NavigatorStartPan
#   NavigatorEndPan
#   NavigatorStartZoom
#   NavigatorEndZoom
#   NavigatorPickFlatPoint widget the float float
#   NavigatorPick3DPoint widget float float float
#   NavigatorPickSlicePoint
#   NavigatorMakeFlatPoint widget x PointActor$count
#   NavigatorMake3DPoint widget x PointActor$count
#   NavigatorMakeSlicePoint
#   NavigatorDisplayPoints
#   NavigatorRemoveFlattenedView
#   NavigatorMatchFlat
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC NavigatorInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorInit {} {
    global Navigator Module Volume Model

    # Initialize module-level variables

    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.

    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #

    # size of correlating spheres layed over models
    set Navigator(NavSphereScale) 5
    # select every nth point on the models
    # will be obsolete once spheres appear by clicking
    set Navigator(NavSphereSkip) 500

    # names of the views/models selected
    set Navigator(ModelSelect) $Model(idNone)
    set Navigator(FlatSelect) ""             

    # cameras
    set Navigator(FlatRenderWindow) ""
    set Navigator(FlatRenderers) ""

    set Navigator(FlatPolyData) ""

    set Navigator(FlatWindows) ""

    set Navigator(default,pointCount) 0

    set Navigator(RemoveFlat) 0
    set Navigator(RemoveEndo) 0

    set Flat(mbActiveList) ""
    set Flat(mActiveList) ""

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
    set m Navigator
    set Module($m,row1List) "Help Navigate Options"
    set Module($m,row1Name) "{Help} {Navigate} {Options}"
    set Module($m,row1,tab) Navigate

    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Point correspondences between 3D model, endoscopic view, and flattened image."
    set Module($m,author) "Mary Lederer, SPL, surreal@bwh.harvard.edu"
    set Module($m,category) "Application"

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
    #   set Module($m,procVTK) NavigatorBuildVTK
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
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               

    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) NavigatorBuildGUI
    set Module($m,procEnter) NavigatorEnter
    set Module($m,procExit) NavigatorExit

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) "Data Endoscopic Fiducials Models TetraMesh View"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.6 $} {$Date: 2006/01/06 17:57:00 $}]



}

#-------------------------------------------------------------------------------
# .PROC NavigatorEnter
# Called when the module is entered.  Sets up an endoscopic view.
#
# Possible updates: set up flattened view upon entry.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorEnter {} {
    global Endoscopic Ev Model

    EndoscopicAddEndoscopicView
    # EvActivateBindingSet bindTkModularEvents
}

#-------------------------------------------------------------------------------
# .PROC NavigatorExit
# Called when the module is exited.  Removes endoscopic view and flattened 
# view if the user has selected that option.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorExit {} {
    global Endoscopic Navigator

    if {$Navigator(RemoveFlat) == 1} {
    NavigatorRemoveFlattenedView
    }
    if {$Navigator(RemoveEndo) == 1} {
    EndoscopicRemoveEndoscopicView
    }
}


###############
## GUI PROCS ##
###############

# NAMING CONVENTION:
#----------------------------------------------------------------------------
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
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# .PROC NavigatorBuildGUI
# Create the Graphical User Interface.
# .END
#----------------------------------------------------------------------------
proc NavigatorBuildGUI {} {
    global Flat Gui Model Module Navigator Volume 

    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------

    # Help
    # Navigate
    #   Model3D
    #   Flat
    #   Choose
    #   Run
    # Options
    #   Exit
    #   Vertices
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    

    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The Navigator module allows the user to navigate on all three views
    of a model, the 3D model, the endoscopic view, and the flattened image.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags Navigator $help
    MainHelpBuildGUI Navigator
    
    #-------------------------------------------
    # Navigate frame
    #-------------------------------------------
    set fNavigate $Module(Navigator,fNavigate)
    set f $fNavigate

    # need to somehow ensure that only models get picked for model,
    # endos for endo, and flats for flat.  won't be necessary once all
    # are incorporated as functions.

    foreach frame "Label Model3D Flat FlatFileLabel FlatFile ChooseFile Run" {
    frame $f.f$frame -bg $Gui(activeWorkspace)

    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    

    #-------------------------------------------
    # Navigate->Label frame
    #-------------------------------------------
    set f $fNavigate.fLabel

    DevAddLabel $f.l "Choose the active 3D Model"
    DevAddLabel $f.l2 "and Flattened View"
    pack $f.l $f.l2

    #-------------------------------------------
    # Navigate->Model3D frame
    #-------------------------------------------
    set f $fNavigate.fModel3D
    
    DevAddSelectButton Navigator $f ModelSelect "3D Model:" pack
    
    lappend Model(mbActiveList) $f.mbModelSelect
    lappend Model(mActiveList) $f.mbModelSelect.m

    #-------------------------------------------
    # Navigate->Flat frame
    #-------------------------------------------
    set f $fNavigate.fFlat

    DevAddSelectButton Navigator $f FlatSelect "Flattened View:" pack
    
    lappend Flat(mbActiveList) $f.mbFlatSelect
    lappend Flat(mActiveList) $f.mbFlatSelect.m

    #-------------------------------------------
    # Navigate->FlatFileLabel frame
    #-------------------------------------------
    set f $fNavigate.fFlatFileLabel
    
    DevAddLabel $f.l "Choose a Flattened View File (.vtk)"

    pack $f.l

    #-------------------------------------------
    # Navigate->FlatFile frame
    #-------------------------------------------
    set f $fNavigate.fFlatFile
    
    # sets Navigator(FlatSelect) to selected filename
    DevAddFileBrowse $f Navigator FlatSelect "" "NavigatorSetFlatFileName" "vtk"
    
    #-------------------------------------------
    # Navigate->ChooseFile frame
    #-------------------------------------------
    set f $fNavigate.fChooseFile
    

    DevAddButton $f.bChoose "Choose" "NavigatorDisplayFlatView"
    DevAddButton $f.bCancel "Cancel" "NavigatorCancelFlatFile"
    grid $f.bChoose $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Navigate->Run frame
    #-------------------------------------------
    set f $fNavigate.fRun

    # Run button -- should eventually be obsolete
    DevAddButton $f.bRun \
    "Run" \
    NavigatorNavigateSurfaces
    pack $f.bRun

    #-------------------------------------------
    # Options frame
    #-------------------------------------------
    set fOptions $Module(Navigator,fOptions)
    set f $fOptions

    foreach frame "FlatExit EndoExit" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Options->FlatExit frame
    #-------------------------------------------
    set f $fOptions.fFlatExit

    DevAddLabel $f.lFlatDel "Remove Flattened View Upon Exit?"
    checkbutton $f.cFlatExit -variable Navigator(RemoveFlat)
    grid $f.lFlatDel $f.cFlatExit 

    #-------------------------------------------
    # Options->EndoExit
    #-------------------------------------------
    set f $fOptions.fEndoExit

    DevAddLabel $f.lEndoDel "Remove Endoscopic View Upon Exit?"
    checkbutton $f.cEndoExit -variable Navigator(RemoveEndo)
    grid $f.lEndoDel $f.cEndoExit

    #-------------------------------------------
    # Options->Vertices frame
    #-------------------------------------------
    # set f $fOptions.fVertices

    # DevAddLabel $f.lSphereSkip "Keep Every Nth Node:"
    # DevAddEntry Navigator NavSphereSkip $f.eSphereSkip

}

##################################
## PROCS THAT ACTUALLY DO STUFF ##
##################################

#-------------------------------------------------------------------------------
# .PROC NavigatorSetFlatFileName
#
# Called when the user enters a filename for a flattened view.  Sets
# $Navigator(FlatSelect)
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorSetFlatFileName {} {
    global Navigator

    # Do nothing if the user cancelled in the browse box
    if {$Navigator(FlatSelect) == ""} {
    set Navigator(name) ""
    set Navigator(FlatSelect) ""

    return
    }

    # Name the flattened view based on the entered file.  
    set Navigator(name) [ file root [file tail $Navigator(FlatSelect)]]

}
    


#-------------------------------------------------------------------------------
# .PROC NavigatorCancelFlatFile
# 
# Called when the user cancels a selection of a flattened view.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorCancelFlatFile {} {
    global Navigator

    set Navigator(FlatSelect) ""
    set Navigator(name) ""
}

#-------------------------------------------------------------------------------
# .PROC NavigatorDisplayFlatView
# 
# Called after a user selects a flattened image file.  Creates new
# toplevel and vtkTkRenderWidget to display flattened image.  Calls
# NavigatorSetEventBindings.  
#
# .ARGS 
#
# CREATES
#   toplevel           .tFlat$name.fView$name
#   vtkTkRenderWidget  $f.flatRenderWidget$name
#   vtkRenderer        Navigator($name,Renderer)
#   vtkActor           Navigator($name,Actor)
#
# .END
#-------------------------------------------------------------------------------
proc NavigatorDisplayFlatView {} {
    global Mrml Navigator View viewWin

    # deny if user clicks choose when the selection box is empty
    if {$Navigator(FlatSelect) == ""} {
    DevWarningWindow "Please select a file to display."
    return
    }

    set name $Navigator(name)

    # deny if user tries to display an already displayed file
    if {[lsearch -exact $Navigator(FlatWindows) $name] != -1} {
    DevWarningWindow "Please select a file that is not already displayed."
    return
    }
    
    # add the new window to the list of open windows
    lappend Navigator(FlatWindows) $name

    # create new toplevel for the flattened image
    toplevel .t$name -visual best
    frame .t$name.fView
    set f .t$name.fView
    wm title .t$name $name
    wm geometry .t$name +1030-50
    
    # create a vtkTkRenderWidget to draw the flattened image into
    # vtkTkRenderWidget $f.flatRenderWidget$name
    vtkTkRenderWidget $f.flatRenderWidget$name -width 200 -height 950 
    set Navigator($f.flatRenderWidget$name,name) $name

    # quit button
    button .t$name.bExit -text Quit -command "NavigatorRemoveFlattenedView $name"
    pack $f.flatRenderWidget$name -side left -padx 3 -pady 3 -fill both \
    -expand t
    pack $f -fill both -expand t
    pack .t$name.bExit -fill x
    
    # add a vtkRenderer to the vtkRenderWindow
    vtkRenderer Navigator($name,renderer)
    [$f.flatRenderWidget$name GetRenderWindow] AddRenderer Navigator($name,renderer)
    lappend $Navigator(FlatRenderers) Navigator($name,renderer)

    # create a vtkPolyDataReader and read the vtk file 
    vtkPolyDataReader TempPolyReader
    TempPolyReader SetFileName $Navigator(FlatSelect)

    # FIXME: debugging code
    # vtkSphereSource TempSphere

    # create a vtkPolyDataMapper to map the data from the vtk file
    vtkPolyDataMapper TempMapper
    TempMapper SetInput [TempPolyReader GetOutput]
    # TempMapper SetInput [TempSphere GetOutput]
    TempMapper ScalarVisibilityOff
    # TempSphere Delete

    # save the polydata where we can find it later
    set Navigator($name,polyData) [TempPolyReader GetOutput]

    # create a vtkActor for the vtkMapper to map to
    vtkActor Navigator($name,actor)
    Navigator($name,actor) SetMapper TempMapper
    Navigator($name,actor) RotateZ 90.

    # add the vtkActor
    Navigator($name,renderer) AddActor Navigator($name,actor)    

    # set event bindings for widget
    NavigatorSetEventBindings $f.flatRenderWidget$name 

    set Navigator($name,camera) [Navigator($name,renderer) GetActiveCamera]
    # $Navigator($name,camera) SetViewAngle 0
    $Navigator($name,camera) Zoom 1.5
    
    # initialize and reinitialize
    set Navigator($name,pointCount) 0
    set Navigator(FlatSelect) ""
    set Navigator(name) ""

    # twice for luck
    [$f.flatRenderWidget$name GetRenderWindow] Render    
    [$f.flatRenderWidget$name GetRenderWindow] Render    

    TempPolyReader Delete
    TempMapper Delete

}

#-------------------------------------------------------------------------------
# .PROC NavigatorSetEventBindings
# 
# Called from NavigatorDisplayFlatView.  Sets the event
# bindings/interactions with the vtk objects.  Calls
# NavigatorFlatExpose, NavigatorPickFlatPoint, and NavigatorGiveCoords
#
# .ARGS
#   widget widget  The widget in which the event bindings will be set.
# .END
#-------------------------------------------------------------------------------
proc NavigatorSetEventBindings {widget} {
    global Navigator

    set name $Navigator(name)
   
    # set interactions
    bind $widget <Expose> {%W Render}
    bind $widget <ButtonRelease-1> {NavigatorPickFlatPoint %W %x %y} 
    bind $widget <ButtonPress-2> {NavigatorStartPan %W %x %y}
    bind $widget <ButtonRelease-2> {NavigatorEndPan %W %x %y}
    bind $widget <ButtonPress-3> {NavigatorStartZoom %W %y}
    bind $widget <ButtonRelease-3> {NavigatorEndZoom %W %y}
    # bind $widget <B3-Motion> {NavigatorZoom %W %x %y}
}

#-------------------------------------------------------------------------------
# .PROC NavigatorStartPan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorStartPan {widget xcoord ycoord} {
    global Navigator

    set name $Navigator($widget,name)

    set Navigator($name,pan,xstart) $xcoord
    set Navigator($name,pan,ystart) $ycoord
}

#-------------------------------------------------------------------------------
# .PROC NavigatorEndPan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorEndPan {widget xcoord ycoord} {
    global Navigator

    set name $Navigator($widget,name)

    set xstart $Navigator($name,pan,xstart)
    set ystart $Navigator($name,pan,ystart)

    set dx [expr $xcoord - $xstart]
    set dy [expr $ycoord - $ystart]

    set xyz [$Navigator($name,camera) GetPosition]
    set x1 [lindex $xyz 0]
    set y1 [lindex $xyz 1]
    set z1 [lindex $xyz 2]

    set x2 [expr $x1 - [expr $dx * .1]]
    set y2 [expr $y1 + [expr $dy * .1]]

    $Navigator($name,camera) SetFocalPoint $x2 $y2 0
    $Navigator($name,camera) SetPosition $x2 $y2 $z1

    [$widget GetRenderWindow] Render
}

#-------------------------------------------------------------------------------
# .PROC NavigatorStartZoom
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorStartZoom {widget ycoord} {
    global Navigator
    
    set name $Navigator($widget,name)
    set Navigator($name,zoom,ystart) $ycoord
}

#-------------------------------------------------------------------------------
# .PROC NavigatorEndZoom
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorEndZoom {widget ycoord} {
    global Navigator

    set name $Navigator($widget,name)

    set ystart $Navigator($name,zoom,ystart)
    set dy [expr $ycoord - $ystart]

    set zoom 1

    if {$dy > 0} {
    set zoom [expr $dy / 10]
    } else {
    set zoom [expr 10. / [expr 0. - $dy]]
    }
    puts $zoom
    
    $Navigator($name,camera) Zoom $zoom
    [$widget GetRenderWindow] Render
}
    
#-------------------------------------------------------------------------------
# .PROC NavigatorPickFlatPoint
#
# Called when the user left-clicks a point on the flattened view.
# Calls NavigatorMakeFlatPoint and NavigatorMake3DPoint.
# 
# .ARGS
#   widget widget  The widget in which the user clicked and in which
#                  the the point will eventually appear.
#   xcoord float  The window x coordinate that the user clicked.
#   ycoord float  The window y coordinate that the user clicked.  
# .END
#-------------------------------------------------------------------------------
proc NavigatorPickFlatPoint {widget xcoord ycoord} {
    global Select Navigator Model

    set name $Navigator($widget,name)

    vtkCellPicker TempCellPicker

    # set Select(xyz), Select(actor), and Select(cellId)
    if {[SelectPick TempCellPicker $widget $xcoord $ycoord]} {
    
    # get Flat coords from Select(xyz)
    set fx [lindex $Select(xyz) 0]
    set fy [lindex $Select(xyz) 1]
    set fz [lindex $Select(xyz) 2]

    # get Model coords from Select(cellId)
    set model $Model(activeID)
    if {$model != ""} {
        set polyData $Model($model,polyData)
        set cell [$polyData GetCell $Select(cellId)]
        set bounds [$cell GetBounds]

        # get the approximate center from the bounds
        set mx [expr [expr [lindex $bounds 0] + [lindex $bounds 1]] / 2]
        set my [expr [expr [lindex $bounds 2] + [lindex $bounds 3]] / 2]
        set mz [expr [expr [lindex $bounds 4] + [lindex $bounds 5]] / 2]

        NavigatorMake3DPoint $mx $my $mz $name
        MainSlicesAllOffsetToPoint $mx $my $mz
        puts "World Point: [Slicer GetWldPoint]"
        puts "IJK Point: [Slicer GetIjkPoint]"
    }

    # call procs to make vtk stuff
    NavigatorMakeFlatPoint $widget $fx $fy $fz
    incr Navigator($name,pointCount)

    # FIXME: would be nice to be able to nav with flat and slices,
    # but perhaps useless
    }
    
    TempCellPicker Delete
}

#-------------------------------------------------------------------------------
# .PROC NavigatorPick3DPoint
#
# Called when the user presses "n" on a 3D model whose flattened view
# is displayed.  Calls NavigatorMakeFlatPoint and
# NavigatorMake3DPoint.
# 
# .ARGS
#   widget widget  The main viewer.  The widget in which the user presses "n"
#   xcoord float  The window x coordinate of the point that the user selected.
#   ycoord float  The window y coordinate of the point that the user selected.
#   zcoord float
# .END
#-------------------------------------------------------------------------------
proc NavigatorPick3DPoint {widget xcoord ycoord zcoord} {
    global Select Navigator Model Slice
    
    set model $Model(activeID)
    set mpolyData $Model($model,polyData)
    set mpoints [$mpolyData GetNumberOfPoints]
    
    MainSlicesAllOffsetToPoint $xcoord $ycoord $zcoord

    # FIXME: kludges kludges everywhere
    # puts "World Point: [Slicer GetWldPoint]"
    # puts "IJK Point: [Slicer GetIjkPoint]"
    # set ijkpoint [Slicer GetIjkPoint]
    # set i [string index $ijkpoint 0]
    # set j [string index $ijkpoint 1]
    # set k [string index $ijkpoint 2]
    # Slicer SetCursorPosition 0 [expr {round($i)}] [expr {round($j)}]
    # Slicer SetCursorPosition 1 [expr {round($j)}] [expr {round($k)}]
    # Slicer SetCursorPosition 2 [expr {round($i)}] [expr {round($k)}]
    # RenderSlices
    
    if { [info exists Select(actor)] == 0 } {
    # make sure an actor in the 3D scene is selected
    return 0
    }
    
    if { $Select(cellId) == 0 } {
    # make sure it's not selecting cell with cellId 0 as
    # default
    # FIXME: cannot pick cell with cellId 0
    return 0
    }
    
    set mcell [$mpolyData GetCell $Select(cellId)]
    set mbounds [$mcell GetBounds]
        
    # get the approximate center from the bounds
    set mx [expr [expr [lindex $mbounds 0] + [lindex $mbounds 1]] / 2]
    set my [expr [expr [lindex $mbounds 2] + [lindex $mbounds 3]] / 2]
    set mz [expr [expr [lindex $mbounds 4] + [lindex $mbounds 5]] / 2]
    
    if {$Navigator(FlatWindows) == ""} {
    NavigatorMake3DPoint $mx $my $mz "default"
    incr Navigator(default,pointCount)
    }
    
    foreach name $Navigator(FlatWindows) {
    # adds to all flat views
    # FIXME: tries to add selected point to all flattened views.
    # need a Flat(activeID).
    
        set fwidget .t$name.fView.flatRenderWidget$name
    set fpolyData $Navigator($name,polyData)
    set fpoints [$fpolyData GetNumberOfPoints]
    
    
    if {$fpoints != $mpoints} {
        # make sure that flat has same num points as model
        DevWarningWindow "Number of points in active flattened view, $name , does not match number of points in active model, $Model(name)."
        continue
    }
    
    set fcell [$fpolyData GetCell $Select(cellId)]
    set fbounds [$fcell GetBounds]
    
    # get the approximate center from the bounds
    set fx [expr 0 - [expr [expr [lindex $fbounds 2] + [lindex $fbounds 3]] / 2]]
    set fy [expr [expr [lindex $fbounds 0] + [lindex $fbounds 1]] / 2]
    set fz [expr [expr [lindex $fbounds 4] + [lindex $fbounds 5]] / 2]
    
    NavigatorMake3DPoint $mx $my $mz $name
    NavigatorMakeFlatPoint $fwidget $fx $fy $fz
    incr Navigator($name,pointCount)
    puts $Navigator($name,pointCount)
    }
}


#-------------------------------------------------------------------------------
# .PROC NavigatorPickSlicePoint
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorPickSlicePoint {widget x y z} {
    global Module Navigator

    # move slices around
    MainSlicesSetOffset 0 $z
    MainSlicesSetOffset 1 $x
    MainSlicesSetOffset 2 $y

    puts "World Point: [Slicer GetWldPoint]"
    puts "IJK Point: [Slicer GetIjkPoint]"

    set scellId -1

    # major major KLUDGE!!!
    # FIXME: using viewRen there seems like a bad thing . . .
    vtkCellPicker TempPicker
    TempPicker SetTolerance 0.5
    TempPicker Pick $x $y $z viewRen
    set scellId [TempPicker GetCellId]
    TempPicker Delete

    if {$scellId == -1} {
    return 0 
    }

    foreach name $Navigator(FlatWindows) {
    set w .t$name.fView.flatRenderWidget$name
    set fcell [$Navigator($name,polyData) GetCell $scellId]
    incr Navigator($name,pointCount)

    set fbounds [$fcell GetBounds]
    set fx [expr 0 - [expr [expr [lindex $fbounds 2] + [lindex $fbounds 3]] / 2]]
    set fy [expr [expr [lindex $fbounds 0] + [lindex $fbounds 1]] / 2]
    set fz [expr [expr [lindex $fbounds 4] + [lindex $fbounds 5]] / 2]
    
    NavigatorMakeFlatPoint $w $fx $fy $fz
    NavigatorMake3DPoint $x $y $z $name
    }
}
#-------------------------------------------------------------------------------
# .PROC NavigatorMakeFlatPoint
#
# Called by NavigatorPickFlatPoint and NavigatorPick3DPoint.  Creates
# the vtk for the selected point in the flat view.
# 
# .ARGS
#   widget widget  The widget into which the point will be drawn
#   float x  The world x coordinate where the point will go.
# 
# CREATES
#   vtkActor PointActor$count
# .END
#-------------------------------------------------------------------------------
proc NavigatorMakeFlatPoint {widget x y z} {
    global Navigator Select

    set name $Navigator($widget,name)
    set count $Navigator($name,pointCount)
    set renderer [[[$widget GetRenderWindow] GetRenderers] GetItemAsObject 0]
    
    # create source for the point
    vtkSphereSource TempSphere
    
    # create a mapper for the sphere
    vtkPolyDataMapper TempMapper
    TempMapper SetInput [TempSphere GetOutput]
    
    # create an actor
    vtkActor Navigator($name,flat,pointActor,$count)
    Navigator($name,flat,pointActor,$count) SetMapper TempMapper
    Navigator($name,flat,pointActor,$count) SetPosition $x $y 0
    Navigator($name,flat,pointActor,$count) SetPickable 0
    eval [Navigator($name,flat,pointActor,$count) GetProperty] SetColor "1 0 0"
    
    # add the actor to the renderer
    $renderer AddActor Navigator($name,flat,pointActor,$count)

    # create text for selected point
    vtkVectorText TempText
    TempText SetText "$name $count"
    
    # new mapper for the text 
    vtkPolyDataMapper TempMapper2
    TempMapper2 SetInput [TempText GetOutput]
    
    # new actor for the text
    vtkActor Navigator($name,flat,textActor,$count)
    Navigator($name,flat,textActor,$count) SetMapper TempMapper2
    # switch x and y because actor is rotated
    Navigator($name,flat,textActor,$count) SetPosition $x $y 0
    eval [Navigator($name,flat,textActor,$count) GetProperty] SetColor "1 0 0"
    
    vtkTransform Navigator($name,flat,textTransform,$count)
    Navigator($name,flat,textTransform,$count) Translate 0.05 0.05 0
    Navigator($name,flat,textTransform,$count) Scale 1.5 1.5 1
    # [Navigator($name,flat,textTransform,$count) GetMatrix] SetElement 0 1 .333

    #Navigator($name,flat,textActor,$count) SetUserMatrix [Navigator($name,flat,textTransform,$count) GetMatrix]

    $renderer AddActor Navigator($name,flat,textActor,$count)

    set camxyz [[$renderer GetActiveCamera] GetPosition]
    set cz [lindex $camxyz 2]
    [$renderer GetActiveCamera] SetFocalPoint $x $y $z
    [$renderer GetActiveCamera] SetPosition $x $y $cz

    [$widget GetRenderWindow] Render

    TempSphere Delete
    TempText Delete
    TempMapper Delete
    TempMapper2 Delete
}

#-------------------------------------------------------------------------------
# .PROC NavigatorMake3DPoint
# 
# Called by NavigatorPickFlatPoint and NavigatorPick3DPoint.  Creates vtk
# for selected point on 3D model.
#
# .ARGS
#   widget widget  The widget in which the point was clicked
#   float x  The world x coordinate of the point to be rendered.
#
# CREATES
#   vtkActor PointActor$count
# .END
#-------------------------------------------------------------------------------
proc NavigatorMake3DPoint {x y z name} {
    global Model Module Navigator
    
    set model $Model(activeID)
    set count $Navigator($name,pointCount)
   
    # create a source for the spheres
    vtkSphereSource TempSphere
    TempSphere SetRadius 5
       
    vtkVectorText TempText
    TempText SetText "$name $count"

    # create a mapper
    vtkPolyDataMapper TempMapper
    TempMapper SetInput [TempText GetOutput]
    
    vtkPolyDataMapper TempMapper2
    TempMapper2 SetInput [TempSphere GetOutput]

    vtkActor Navigator($name,model,pointActor,$count)
    Navigator($name,model,pointActor,$count) SetMapper TempMapper2
    Navigator($name,model,pointActor,$count) SetPosition $x $y $z
    eval [Navigator($name,model,pointActor,$count) GetProperty] SetColor "1 0 0"

    vtkTransform Navigator($name,model,textTransform,$count)
    Navigator($name,model,textTransform,$count) Translate 0 0 10
    [Navigator($name,model,textTransform,$count) GetMatrix] SetElement 0 1 .333
    Navigator($name,model,textTransform,$count) Scale 4 4 1

    # PointFollower$count SetUserMatrix [Navigator($name,flat,textTransform,$count) GetMatrix]

    # create an actor
    foreach r $Module(Renderers) {
    vtkFollower Navigator($name,model,textActor,$count,$r)
    Navigator($name,model,textActor,$count,$r) SetMapper TempMapper
    Navigator($name,model,textActor,$count,$r) SetPosition $x $y $z
    Navigator($name,model,textActor,$count,$r) SetCamera [$r GetActiveCamera]
    Navigator($name,model,textActor,$count,$r) SetScale 4 4 1
    Navigator($name,model,textActor,$count,$r) SetUserMatrix [Navigator($name,model,textTransform,$count) GetMatrix]
    eval [Navigator($name,model,textActor,$count,$r) GetProperty] SetColor "1 0 0"

    $r AddActor Navigator($name,model,textActor,$count,$r)
    }
    # add the actor to the main renderers
    MainAddActor Navigator($name,model,pointActor,$count)
    Render3D
    
    TempSphere Delete
    TempText Delete
    TempMapper Delete
    TempMapper2 Delete
}

#-------------------------------------------------------------------------------
# .PROC NavigatorMakeSlicePoint
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorMakeSlicePoint {widget x y z} {
    global Navigator Slice

    set name $Navigator($widget,name)
    set slice $Slice(activeID)
    puts $slice
    set count $Navigator($name,pointCount)

    vtkSphereSource TempPoint
    TempPoint SetRadius 10
    
    vtkPolyDataMapper2D TempMapper
    TempMapper SetInput [TempPoint GetOutput]

    vtkActor2D Navigator($name,slice,pointActor,$count)
    Navigator($name,slice,pointActor,$count) SetMapper TempMapper
    Navigator($name,slice,pointActor,$count) SetPosition $x $y 
    puts "$x $y"
    eval [Navigator($name,slice,pointActor,$count) GetProperty] SetColor "1 0 0"

    sl${slice}Imager AddActor2D Navigator($name,slice,pointActor,$count)
    RenderActive

    TempPoint Delete
    TempMapper Delete
}

#-------------------------------------------------------------------------------
# .PROC NavigatorDisplayPoints

# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorDisplayPoints {polyData name} {
    global Navigator

    vtkPolyDataMapper TempMapper
    TempMapper SetInput $polyData
    TempMapper SetColorModeToMapScalars
    
    vtkActor Navigator($name,pointsActor)
    Navigator($name,pointsActor) SetMapper TempMapper
    
    set frw [.t$name.fView.flatRenderWidget$name GetRenderWindow]
 
    Navigator($name,renderer) AddActor Navigator($name,pointsActor)

    $frw Render
    TempMapper Delete
}

    

#-------------------------------------------------------------------------------
# .PROC NavigatorRemoveFlattenedView
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorRemoveFlattenedView {{name ""}} {
    global Module Navigator View

    # if clicked 'Quit' button
    if {$name != ""} {
    # destroy all parts of the flat view
    destroy .t$name
    
    Navigator($name,renderer) Delete
    Navigator($name,actor) Delete    ;# actor for flattened image

    catch {Navigator($name,pointsActor) Delete} ;# actor for random points
    
    # destroy all the points
    set pointcount 0
    while {$pointcount < $Navigator($name,pointCount)} {
        # remove pointactors from 3D if they were added to a 3D model
        MainRemoveActor Navigator($name,model,pointActor,$pointcount)
        Navigator($name,model,pointActor,$pointcount) Delete
        Navigator($name,model,textTransform,$pointcount) Delete
        # remove the followers and destroy
        foreach r $Module(Renderers) {
        $r RemoveActor Navigator($name,model,textActor,$pointcount,$r)
        Navigator($name,model,textActor,$pointcount,$r) Delete
        }
        
        
        # destroy on flat
        Navigator($name,flat,pointActor,$pointcount) Delete
        Navigator($name,flat,textActor,$pointcount) Delete
        Navigator($name,flat,textTransform,$pointcount) Delete
        incr pointcount
    }
    Render3D
    set $Navigator($name,pointCount) 0
    
    # FIXME: not actually removing $name from $Navigator(FlatWindows)
    # for some unknown reason
    set index [lsearch -exact $Navigator(FlatWindows) $name]
    if {[llength $Navigator(FlatWindows)] > 1} {
        lreplace $Navigator(FlatWindows) $index $index
        lreplace $Navigator(FlatRenderers) $index $index
    } else {
        set Navigator(FlatWindows) ""
        set Navigator(FlatRenderers) ""
    }
    
    } else {
    # if ending all

    foreach frame $Navigator(FlatWindows) {
        destroy .t$frame
        
        Navigator($frame,renderer) Delete
        Navigator($frame,actor) Delete
        
        catch {Navigator($frame,pointsActor) Delete}
        
        # destroy all the points
        set pointcount 0
        while {$pointcount < $Navigator($frame,pointCount)} {
        
        # remove pointactors from 3D if they were added to a 3D model
        MainRemoveActor Navigator($frame,model,pointActor,$pointcount)
        Navigator($frame,model,pointActor,$pointcount) Delete
        # remove the followers and destroy
        foreach r $Module(Renderers) {
            $r RemoveActor Navigator($frame,model,textActor,$pointcount,$r)
            Navigator($frame,model,textActor,$pointcount,$r) Delete
        }
        
        Navigator($frame,model,textTransform,$pointcount) Delete
        Navigator($frame,flat,pointActor,$pointcount) Delete
        Navigator($frame,flat,textActor,$pointcount) Delete
        Navigator($frame,flat,textTransform,$pointcount) Delete
        incr pointcount
        }
        Render3D
        set $Navigator($frame,pointCount) 0
    }
    
    set Navigator(FlatWindows) ""
    set Navigator(FlatRenderers) ""
    }
    
}
    

#-------------------------------------------------------------------------------
# .PROC NavigatorMatchFlat
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NavigatorMatchFlat {} {
    global Flat Navigator Module

    foreach name $Navigator(FlatWindows) {
    
    set PD $Navigator($name,polyData)
    set NumNode [$PD GetNumberOfPoints]
    
    vtkMaskPoints FlatPoints
    FlatPoints SetInput $PD
    FlatPoints SetOnRatio $Navigator(NavSphereSkip)
    FlatPoints RandomModeOff
    FlatPoints Update

    set FlatPointData [FlatPoints GetOutput]
    
    set NumSelectNode [$FlatPointData GetNumberOfPoints]
    set Increment [expr $NumSelectNode / 2]
    
    
    catch {tempPolyData Delete}
    vtkPolyData tempPolyData

    tempPolyData ShallowCopy [FlatPoints GetOutput]
    tempPolyData Print

    vtkIntArray seen
    seen SetNumberOfValues $NumSelectNode
    for {set i 0} { $i < $NumSelectNode } {incr i 1} {
        seen SetValue $i 0
    }
    
    vtkScalars Scalars
    set p 0
    for {set i 0} { $i < $NumSelectNode } {incr i 1} {
        set p [expr $p + $Increment]
        if {$p >= $NumSelectNode} {set p [expr $p - $NumSelectNode] }
        while { [seen GetValue $p] == 1 } { 
        incr p  
        if {$p >= $NumSelectNode} {set p [expr $p - $NumSelectNode] }
        }
        Scalars InsertScalar $i [expr $i * $Increment]
        seen SetValue $p 1
        puts "$i $p"
    }
    
    seen Delete
    
    [tempPolyData GetPointData] SetScalars Scalars
    
    vtkSphereSource ASphere
    ASphere SetPhiResolution 5
    ASphere SetThetaResolution 5
    ASphere SetRadius [ expr 0.15 * $Navigator(NavSphereScale)]
    vtkGlyph3D ScalarGlyph
    ScalarGlyph SetInput  tempPolyData
    ScalarGlyph SetSource [ASphere GetOutput]
    ScalarGlyph SetScaleModeToDataScalingOff
    ScalarGlyph SetColorModeToColorByScalar
    ScalarGlyph Update
    
    NavigatorDisplayPoints [ScalarGlyph GetOutput] $name
    
    tempPolyData Delete    
    FlatPoints Delete
    ASphere Delete
    ScalarGlyph Delete
    Scalars Delete
    }
}
