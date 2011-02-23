#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ModelCompare.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:00 $
#   Version:   $Revision: 1.8 $
# 
#===============================================================================
# FILE:        ModelCompare.tcl
# PROCEDURES:  
#   ModelCompareInit
#   ModelCompareBuildGUI
#   ModelCompareCreateModelGUI widget int
#   ModelCompareConfigScrolledGUI canvasScrolledGUI fScrolledGUI
#   ModelCompareDeleteModelGUI widget int
#   ModelCompareUpdateGUI
#   ModelCompareCorrespondSurfaces
#   ModelCompareMatchSurface
#   ModelCompareFormArray
#   ModelCompareUndoArray
#   ModelCompareSetAll Setting
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC ModelCompareInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelCompareInit {} {
    global ModelCompare Module Volume Model

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
    set m ModelCompare
    set Module($m,row1List) "Help Correspond Array"
    set Module($m,row1Name) "{Help} {Correspond} {Array Display}"
    set Module($m,row1,tab) Correspond

#        set Module($m,row2List) "SField VField"
#        set Module($m,row2Name) "{Scalar Field} {Vector Field}"
#        set Module($m,row2,tab) SField

    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Comparing Lots of Models."
    set Module($m,author) "Samson Timoner, MIT AI Lab, samson@bwh.harvard.edu"
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
    #   set Module($m,procVTK) ModelCompareBuildVTK
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
    set Module($m,procGUI) ModelCompareBuildGUI
#    set Module($m,procEnter) ModelCompareEnter
#    set Module($m,procExit) ModelCompareExit
    set Module($m,procMRML) ModelCompareUpdateGUI

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) "Data Models TetraMesh"

        # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.8 $} {$Date: 2006/01/06 17:57:00 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
        set ModelCompare(Model1) ""
        set ModelCompare(Model2) ""
        set ModelCompare(CorSphereScale) 9.5
        set ModelCompare(CorSphereSkip) 20

        set ModelCompare(TransformName) "ArrayTrans";
        set ModelCompare(Rowsize)  10
        set ModelCompare(ColX) 5.0;
        set ModelCompare(ColY) 0.0;
        set ModelCompare(ColZ) 0.0;;

        set ModelCompare(RowX) 0.0;
        set ModelCompare(RowY) 5.0;
        set ModelCompare(RowZ) 0.0;;
        set ModelCompare(MatArray) " ";
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc ModelCompareBuildGUI {} {
    global Gui ModelCompare Module Volume Model View

    # A frame has already been constructed automatically for each tab.
    # A frame named "Props" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(ModelCompare,fProps)

    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
        # Correspond
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------

    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
The ModelCompare module allows a compare lots of models. There are two 
functions currently available: showing point correspondances and showing
models in a 2D array.

<UL>
<LI><B>Matching Surfaces:</B> The models are assumed to correspond on a point by point basis. That is point 33 in model 1 corresponds to point 33 in model 2.
</LI>
<LI><B>Known Problems:</B> It overwrites the scalar point data on the models.
</LI></UL>
<UL>
<LI><B>Array Display:</B> The models are assumed to roughly lie in the same spot in space. The models are then translated for easy visualization.
</LI>
<LI><B>Known Concerns:</B> Not exactly sure what happens if the model already has a transform around it.
</LI></UL>

"
    regsub -all "\n" $help {} help
    MainHelpApplyTags ModelCompare $help
    MainHelpBuildGUI ModelCompare


    #-------------------------------------------
    # Correspond frame
    #-------------------------------------------
    set fCorrespond $Module(ModelCompare,fCorrespond)
    set f $fCorrespond

    set FrameString  "";
    foreach Frame "Top Top2 Scroll Middle Bottom Run" {
        frame $f.f$Frame  -bg $Gui(activeWorkspace)
        set FrameString  "$FrameString $f.f$Frame"
    }

    eval pack $FrameString -side top -padx 0 -pady $Gui(pad)

        #-------------------------------------------
        # Correspond->Top frame
        #-------------------------------------------
        set f $fCorrespond.fTop
        DevAddLabel  $f.lCorrespond "Show correspondences between surfaces\n with identical numbers of nodes"

        pack $f.lCorrespond 

        #-------------------------------------------
        # Correspond->Top2 frame
        #-------------------------------------------

        set f $fCorrespond.fTop2

        DevAddLabel $f.lSelect "Select Models:"

        DevAddButton $f.bAll "All" \
                 "ModelCompareSetAll 1" 6 
        DevAddButton $f.bNone "None" \
                 "ModelCompareSetAll 0" 6 

        pack $f.lSelect $f.bAll $f.bNone -side left -padx $Gui(pad)

        #-------------------------------------------
        # Correspond->Scroll frame
        #-------------------------------------------

    
        set f $fCorrespond.fScroll

        set ModelCompare(canvasScrolledGUI1)  $f.cGrid
        set ModelCompare(fScrolledGUI1)   $f.cGrid.fListItems
        DevCreateScrollList $f \
                            ModelCompareCreateModelGUI \
                            ModelCompareConfigScrolledGUI \
                            "$Model(idList)"

         #-------------------------------------------
         # Correspond->Middle frame
         #-------------------------------------------
     
         set f $fCorrespond.fMiddle
     
             DevAddLabel  $f.lSphereScale "Sphere Scaling"
             eval {entry $f.eSphereScale -textvariable ModelCompare(CorSphereScale) -width 5} $Gui(WEA)
        
             pack $f.lSphereScale $f.eSphereScale -side left -padx $Gui(pad)
     
         #-------------------------------------------
         # Correspond->Bottom frame
         #-------------------------------------------
     
     
         set f $fCorrespond.fBottom
     
             DevAddLabel  $f.lSphereSkip "Keep Every Nth Node:"
             eval {entry $f.eSphereSkip -textvariable ModelCompare(CorSphereSkip) -width 5} $Gui(WEA)
        
             pack $f.lSphereSkip $f.eSphereSkip -side left -padx $Gui(pad)
     
         #-------------------------------------------
         # Correspond->Bottom frame
         #-------------------------------------------
     
         set f $fCorrespond.fRun
     
             DevAddButton $f.bRun "Run" "ModelCompareCorrespondSurfaces"
     
         pack $f.bRun
     
    #-------------------------------------------
    # Array frame
    #-------------------------------------------
    set fArray $Module(ModelCompare,fArray)
    set f $fArray

    set FrameString ""
    foreach Frame "Top Top2 Scroll Middle Bottom Mat1 Mat2 Run" {
        frame $f.f$Frame  -bg $Gui(activeWorkspace)
        set FrameString  "$FrameString $f.f$Frame"
    }

    eval pack $FrameString -side top -padx 0 -pady $Gui(pad)

        #-------------------------------------------
        # Array->Top frame
        #-------------------------------------------
        set f $fArray.fTop
        DevAddLabel  $f.lArray "Show Array of Models:"

        pack $f.lArray

        #-------------------------------------------
        # Array->Top2 frame
        #-------------------------------------------

        set f $fArray.fTop2

        DevAddLabel $f.lSelect "Select Models:"

        DevAddButton $f.bAll "All" \
                 "ModelCompareSetAll 1" 6 
        DevAddButton $f.bNone "None" \
                 "ModelCompareSetAll 0" 6 

        pack $f.lSelect $f.bAll $f.bNone -side left -padx $Gui(pad)

        #-------------------------------------------
        # Correspond->Scroll frame
        #-------------------------------------------

        set f $fArray.fScroll
  
        set ModelCompare(canvasScrolledGUI2)  $f.cGrid
        set ModelCompare(fScrolledGUI2)   $f.cGrid.fListItems
        DevCreateScrollList $f \
                            ModelCompareCreateModelGUI \
                            ModelCompareConfigScrolledGUI \
                            "$Model(idList)"

        #-------------------------------------------
        # Arry->Middle frame
        #-------------------------------------------
    
        set f $fArray.fMiddle
    
            DevAddLabel  $f.lTransformName "Transform Name:"
            eval {entry $f.eTransformName -textvariable ModelCompare(TransformName) -width 15} $Gui(WEA)
       
            pack $f.lTransformName $f.eTransformName -side left -padx $Gui(pad)
    
        #-------------------------------------------
        # Array->Bottom frame
        #-------------------------------------------
    
        set f $fArray.fBottom
    
            DevAddLabel  $f.lRow "Models Per Row:"
            eval {entry $f.eRow -textvariable ModelCompare(Rowsize) -width 5} $Gui(WEA)
    #        DevAddLabel  $f.lCol "Per Column:"
    #        eval {entry $f.eCol -textvariable ModelCompare(Columnsize) -width 5} $Gui(WEA)
    
    #        pack $f.lRow $f.eRow $f.lCol $f.eCol  -side left -padx $Gui(pad)
            pack $f.lRow $f.eRow  -side left -padx $Gui(pad)
    
        #-------------------------------------------
        # Array->Matrix Frame
        #-------------------------------------------
    
        set f $fArray.fMat1
    
        DevAddLabel  $f.lRowOff "Row Offset:"
        eval {entry $f.eRowX -textvariable ModelCompare(RowX) -width 5} $Gui(WEA)
        eval {entry $f.eRowY -textvariable ModelCompare(RowY) -width 5} $Gui(WEA)
        eval {entry $f.eRowZ -textvariable ModelCompare(RowZ) -width 5} $Gui(WEA)
        pack $f.lRowOff $f.eRowX $f.eRowY $f.eRowZ  -side left -padx $Gui(pad)
    
        set f $fArray.fMat2
    
        DevAddLabel  $f.lColOff "Column Offset:"
        eval {entry $f.eColX -textvariable ModelCompare(ColX) -width 5} $Gui(WEA)
        eval {entry $f.eColY -textvariable ModelCompare(ColY) -width 5} $Gui(WEA)
        eval {entry $f.eColZ -textvariable ModelCompare(ColZ) -width 5} $Gui(WEA)
    
        pack $f.lColOff $f.eColX $f.eColY $f.eColZ  -side left -padx $Gui(pad)
    
        #-------------------------------------------
        # Array->Run Frame
        #-------------------------------------------
    
        set f $fArray.fRun
  
         DevAddButton $f.bRun  "Run"  "ModelCompareFormArray"
         DevAddButton $f.bUndo "Undo" "ModelCompareUndoArray"
    
         pack $f.bRun $f.bUndo -side left -padx $Gui(pad)
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareCreateModelGUI
# Makes the GUI for each model on the Models->Display panel.
# This is called for each new model.
# Also makes the popup menu that comes up when you right-click a model.
#
# returns 1 if it did anything, 0 otherwise.
#
# .ARGS
# f widget the frame to create the GUI in
# m int the id of the model
# .END
#-------------------------------------------------------------------------------
proc ModelCompareCreateModelGUI {f m } {
    global Gui Model Color ModelCompare


        # puts "Creating GUI for model $m"        
    # If the GUI already exists, then just change name.
    if {[info command $f.c$m] != ""} {
        $f.c$m config -text "[Model($m,node) GetName]"
        return 0
    }

    # Name / Visible
    set ModelCompare($m,match) 0
    eval {checkbutton $f.c$m \
        -text [Model($m,node) GetName] -variable ModelCompare($m,match) \
        -width 17 -indicatoron 0} $Gui(WCA)
#        $f.c$m configure -bg [MakeColorNormalized \
#                        [Color($Model($m,colorID),node) GetDiffuseColor]]
#        $f.c$m configure -selectcolor [MakeColorNormalized \
#                        [Color($Model($m,colorID),node) GetDiffuseColor]]
            
    # Add a tool tip if the string is too long for the button
    if {[string length [Model($m,node) GetName]] > [$f.c$m cget -width]} {
        TooltipAdd $f.c$m [Model($m,node) GetName]
    }
    
#    eval grid $l1_command $c_command $f.e${m} $f.s${m} -pady 2 -padx 2 -sticky we

        eval grid $f.c$m -pady 2 -padx 2 -sticky we
    return 1
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareConfigScrolledGUI
# 
# Set the dimensions of the scrolledGUI
#
# .ARGS
#
# frame  canvasScrolledGUI  The canvas around the scrolled frame
# frame  fScrolledGUI       The frame with the item list of models
# .END   
#-------------------------------------------------------------------------------
proc ModelCompareConfigScrolledGUI {canvasScrolledGUI fScrolledGUI} {
    global Model ModelGroup RemovedModels

    set f      $fScrolledGUI
    set canvas $canvasScrolledGUI
    set m [lindex $Model(idList) 0]

        # y spacing important for calculation of frame height for scrolling
        set pady 2

    if {$m != ""} {
        # Find the height of a single button
        # Must use $f.s$m since the scrollbar ("s") fields are tallest
        set lastButton $f.c$m
        # Find how many modules (lines) in the frame
        set numLines 0
        foreach m $Model(idList) {
            if {$RemovedModels($m) == 0} {
                incr numLines
            }
        }
        incr numLines [llength $ModelGroup(idList)]
        #set numLines [expr [llength $Model(idList)] + [llength $ModelGroup(idList)]]
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
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareDeleteModelGUI
# 
# .ARGS
# f widget the frame to create the GUI in
# m int the id of the model
# .END
#-------------------------------------------------------------------------------
proc ModelCompareDeleteModelGUI {f m} {
    global ModelCompare

    # If the GUI is already deleted, return
    if {[info command $f.c$m] == ""} {
        return 0
    }

    # Destroy TK widgets
    destroy $f.c$m

    set ModelCompare($m,match) 0;

    return 1
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareUpdateGUI
# 
# This procedure is called to update the buttons
# due to such things as volumes or models being added or subtracted.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelCompareUpdateGUI {} {
    global Model ModelCompare

    set gui 0

    # Now build GUI for any models not in hierarchies
    foreach m $Model(idList) {
        set gui [expr $gui + [ModelCompareCreateModelGUI \
                               $ModelCompare(fScrolledGUI1) $m]]
        ModelCompareCreateModelGUI $ModelCompare(fScrolledGUI2) $m
    }

    # Delete the GUI for any old models
    foreach m $Model(idListDelete) {
        set gui [expr $gui + [ModelCompareDeleteModelGUI \
                  $ModelCompare(fScrolledGUI1) $m]]
        set gui [expr $gui + [ModelCompareDeleteModelGUI \
                  $ModelCompare(fScrolledGUI2) $m]]
    }

    # Tell the scrollbar to update if the gui height changed
    if {$gui > 0} {
        ModelCompareConfigScrolledGUI $ModelCompare(canvasScrolledGUI1) \
                $ModelCompare(fScrolledGUI1)
        ModelCompareConfigScrolledGUI $ModelCompare(canvasScrolledGUI2) \
                $ModelCompare(fScrolledGUI2)
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareCorrespondSurfaces
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelCompareCorrespondSurfaces {} {
    global ModelCompare Model Mrml

    ############################################################
    # First check for problems.
    # Make sure all surfaces have the same number of nodes.
    ############################################################

    set NumNode -1;

    foreach m $Model(idList) {
        if {$ModelCompare($m,match) == 1} {
            set ThisNumNode [$Model($m,polyData) GetNumberOfPoints]
            if {$NumNode == -1} { set NumNode $ThisNumNode }
            if {$ThisNumNode != $NumNode} {
                DevWarningWindow "Must have same number of nodes in each Model!"
                return 0
            }
          }
    }

    if {$NumNode == -1} {
        DevWarningWindow "No Models Selected!"
        return 0
    }

    ############################################################
    # First check for problems.
    # Make sure all surfaces have the same number of nodes.
    ############################################################

    foreach m $Model(idList) {
        if {$ModelCompare($m,match) == 1} {
            set p [ModelCompareMatchSurface $m]

            ## move the returning node to be after the polyData node
            Mrml(dataTree) RemoveItem Model($p,node)
            Mrml(dataTree) InsertAfterItem Model($m,node) Model($p,node)
        }
    }


  ############################################################
  # Update the displays
  ############################################################

  MainModelsUpdateMRML 
  MainUpdateMRML
  Render3D
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareMatchSurface
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelCompareMatchSurface {m} {
    global ModelCompare Model Volume Module

    set PD  $Model($m,polyData)
    set NumNode [$PD GetNumberOfPoints]

######################################################################
#################### Get the Points Set and put them together
######################################################################

vtkMaskPoints PointSelection
  PointSelection SetInput $PD
  PointSelection SetOnRatio $ModelCompare(CorSphereSkip)
  PointSelection RandomModeOff
  PointSelection Update

set PointData     [PointSelection GetOutput]

set NumSelectNode [$PointData GetNumberOfPoints]
set Increment [ expr $NumSelectNode / 2 ]

vtkPolyData tempPolyData
  tempPolyData ShallowCopy [PointSelection GetOutput]
  tempPolyData Print

vtkIntArray seen
  seen SetNumberOfValues $NumSelectNode
  for {set i 0} { $i < $NumSelectNode } {incr i 1} {
    seen SetValue $i 0
  }

puts "Increment: $Increment"
vtkFloatArray Scalars
set p 0
for {set i 0} { $i < $NumSelectNode } {incr i 1} {
    # increment $p
    set p [expr $p + $Increment]
    if {$p >= $NumSelectNode} {set p [expr $p - $NumSelectNode] }
    while { [seen GetValue $p] == 1 } { 
        incr p  
        if {$p >= $NumSelectNode} {set p [expr $p - $NumSelectNode] }
    }
    Scalars InsertTuple1 $i [expr $i * $Increment]
    seen SetValue $p 1
    puts "$i $p"
}

seen Delete

[tempPolyData GetPointData] SetScalars Scalars

#
#  PointSelection Update
#  [[PointSelection GetOutput] GetPointData] SetScalars Scalars

vtkSphereSource ASphere
  ASphere SetPhiResolution 5
  ASphere SetThetaResolution 5
  ASphere SetRadius [ expr 0.15 * $ModelCompare(CorSphereScale) ]
vtkGlyph3D ScalarGlyph
  ScalarGlyph SetInput  tempPolyData
  ScalarGlyph SetSource [ASphere GetOutput]
  ScalarGlyph SetScaleModeToDataScalingOff
  ScalarGlyph SetColorModeToColorByScalar
#  ScalarGlyph SetScaleModeToScaleByScalar
#  ScalarGlyph SetScaleFactor 
  ScalarGlyph Update

  ########################################
  ##### Form the Model
  ########################################

  set range [tempPolyData GetScalarRange]
  set LOWSCALAR  [ lindex $range 0 ]
  set HIGHSCALAR [ lindex $range 1 ]
  set name [Model($m,node) GetName]
  set name "${name}-correspond-points"

  ### Create the new Model
  set m [ TetraMeshCreateModel $name $LOWSCALAR $HIGHSCALAR ]
  TetraMeshCopyPolyData [ScalarGlyph GetOutput] $m

  PointSelection Delete
  ASphere Delete
  ScalarGlyph Delete
  Scalars Delete
  tempPolyData Delete

  return $m
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareFormArray
# 
# Put a transform around each model
# to form a 2D array
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelCompareFormArray {} {
    global ModelCompare Model Transform EndTransform

    set ModelCompare(MatArray) ""
    set ModelCompare(Transforms)   ""
    set ModelCompare(EndTransforms) ""
    set NumColumn $ModelCompare(Rowsize);
    set i 0
    set j 0;

    foreach m $Model(idList) {
        if {$ModelCompare($m,match) == 1} {
            ## Form the matrix
            ## Put the transform and matrix in the right place
            ## Keep track of the matrix
            
            ## add the matrix, don't redraw.
            set matrixnum [ DataAddTransform 0 Model($m,node) Model($m,node) 0 ]
            Matrix($matrixnum,node) SetName "ModelCompArrayTrans"
            lappend ModelCompare(MatArray) $matrixnum

            ### Also keep track of the transform
            lappend ModelCompare(Transforms)    [expr $Transform(nextID) - 1]
            lappend ModelCompare(EndTransforms) [expr $EndTransform(nextID) - 1]
            set mat [ [Matrix($matrixnum,node) GetTransform] GetMatrix ]
            $mat SetElement 0 3 [expr $i * $ModelCompare(ColX) + \
                                      $j * $ModelCompare(RowX) ]
            $mat SetElement 1 3 [expr $i * $ModelCompare(ColY) + \
                                      $j * $ModelCompare(RowY) ]
            $mat SetElement 2 3 [expr $i * $ModelCompare(ColZ) + \
                                      $j * $ModelCompare(RowZ) ]
            incr i
            if {$i == $NumColumn} {
              set i 0
              incr j
            }
        }
    }
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareUndoArray
# 
# Put a transform around each model
# to form a 2D array
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelCompareUndoArray {} {
    global ModelCompare Model

    foreach mat $ModelCompare(MatArray) \
            trans  $ModelCompare(Transforms) \
            etrans $ModelCompare(EndTransforms) {
        MainMrmlDeleteNodeDuringUpdate Transform $trans
        MainMrmlDeleteNodeDuringUpdate Matrix $mat
        MainMrmlDeleteNodeDuringUpdate EndTransform $etrans
    }
    MainUpdateMRML
    Render3D
    set ModelCompare(MatArray) ""
    set ModelCompare(Transforms)   ""
    set ModelCompare(EndTransforms) ""
}

#-------------------------------------------------------------------------------
# .PROC ModelCompareSetAll
# 
# Set all the models to the argument
#
# .ARGS
# int Setting either 1 or 0, to select or unselect all
# .END
#-------------------------------------------------------------------------------
proc ModelCompareSetAll {Setting} {
    global ModelCompare Model 

    foreach m $Model(idList) {
        set ModelCompare($m,match) $Setting
    }
}
