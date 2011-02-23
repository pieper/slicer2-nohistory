#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRI.tcl,v $
#   Date:      $Date: 2007/02/21 18:38:19 $
#   Version:   $Revision: 1.133 $
# 
#===============================================================================
# FILE:        DTMRI.tcl
# PROCEDURES:  
#   TensorInit
#   TensorCreateNew t
#   TensorUpdateMRML
#   TensorCreate
#   TensorRead
#   TensorDelete
#   TensorSetActive
#   MainTensorSetActive
#   DTMRIInit
#   DTMRIUpdateMRML
#   DTMRIEnter
#   DTMRIExit
#   DTMRIBuildGUI
#   DTMRICreateBindings
#   DTMRIRemoveAllActors
#   DTMRIAddAllActors
#   DTMRIDeleteVTKObject object
#   DTMRIMakeVTKObject object
#   DTMRIAddObjectProperty object parameter value type desc
#   DTMRIBuildVTK
#   DTMRIGetScaledIjkCoordinatesFromWorldCoordinates x y z
#   DTMRICalculateActorMatrix transform t
#   DTMRICalculateIJKtoRASRotationMatrix transform t
#   DTMRISetTensor
#   DTMRISetActive n
#   DTMRIUpdateLabelWidgetFromShowLabels
#   DTMRIUpdateLabelWidget
#   DTMRIGetVersionInfo
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC TensorInit
# Sets up global array "Tensor" which holds IDs of tensor volumes.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TensorInit {} {

    global Tensor

    # ID indicating no data object selected
    set Tensor(idNone) -1
    # ID indicating currently selected data object
    set Tensor(activeID) ""
    # The ID number of the next object we add
    set Tensor(nextID) 0
    # List of all the data objects in the slicer currently
    set Tensor(idList) ""
    # List of the data objects to delete next time we update mrml
    set Tensor(idListDelete) ""

    # Append widgets to list that gets refreshed during UpdateMRML
    set Tensor(mbActiveList) ""
    set Tensor(mActiveList) ""

    # Initialize menus to None
    TensorSetActive ""
}


#-------------------------------------------------------------------------------
# .PROC TensorCreateNew
# Contains some code that is used when creating a new tensor volume.
# .ARGS
# int t ID of the volume
# .END
#-------------------------------------------------------------------------------
proc TensorCreateNew {t} {
    
    global Tensor

    set data "Tensor($t,data)"

    # See if this data object already exists
    #--------------------------------------------------------
    if {[info command $data] != ""} {
        puts "Tensor $t data exists"
        return 0
    }

    # Create vtkMrmlData object 
    #--------------------------------------------------------
    vtkMrmlDataVolume $data

    # Connect data object with the MRML node
    #--------------------------------------------------------
    $data SetMrmlNode Tensor($t,node)

    # Progress methods
    #--------------------------------------------------------
    $data AddObserver StartEvent       MainStartProgress
    $data AddObserver ProgressEvent   "MainShowProgress $data"
    $data AddObserver EndEvent         MainEndProgress

    
}

#-------------------------------------------------------------------------------
# .PROC TensorUpdateMRML
#  General UpdateMRML procedure useable by all datatypes in the slicer.
#  This procedure will create any new data objects and delete any old ones.
#  If your datatype needs to handle datatype-specific things when
#  there is a change in MRML, write a wrapper proc for this procedure.
# .ARGS
# 
# .END
#-------------------------------------------------------------------------------
proc TensorUpdateMRML {ModuleArray} {

    #puts "Lauren in TensorUpdateMRML $ModuleArray "

    # If the module is not loaded in the Slicer, do nothing.
    #--------------------------------------------------------
    if {[IsModule $ModuleArray] == "0"} {
        ## not all data types are module names, so don't return - steve & raul 2004-02-24
        #return
    }

    # Get access to the global module array
    #--------------------------------------------------------
    upvar #0 $ModuleArray Array

    # Build any new data objects
    #--------------------------------------------------------
    foreach d $Array(idList) {
        if {[TensorCreate $ModuleArray $d] > 0} {

            # Lauren improve this on the fly thing using MRML DATA object
            # Mark it as not being created on the fly 
            # since it was added from the Data module or read in from MRML
            set Array($d,fly) 0
            
            # Read
            if {[TensorRead $ModuleArray $d] < 0} {
                # Let the user know about the error
                # Lauren general filename we can print from node/data object?
                tk_messageBox -message "Could not read [$Array($d,node) GetTitle]"
                # Remove the objects we have created
                MainMrmlDeleteNodeDuringUpdate $ModuleArray $d
            }
        }
    }
    
    # Delete any old data objects
    #--------------------------------------------------------
    foreach d $Array(idListDelete) {
        TensorDelete $ModuleArray $d
    }
    # Did we delete the active data?
    if {[lsearch $Array(idList) $Array(activeID)] == -1} {
        TensorSetActive [lindex $Array(idList) 0]
    }
    
    # Update any menus that list all data objects 
    #--------------------------------------------------------
    if {[info exists Array(mActiveList)] == "1"} {
    foreach menu $Array(mActiveList) {
        # clear out menu
        $menu delete 0 end
        # add all current data objects to menu
        foreach d $Array(idList) {
            set node ${ModuleArray}($d,node)
            $menu add command -label [$node GetName] \
                -command "Main${ModuleArray}SetActive $ModuleArray $d"
        }
    }
    } else {
        if {$::Module(verbose)} {
            puts "Developer: you have not put menus on ModuleArray(mActiveList),\
            which is a convenience for updating menus listing all \
            $ModuleArray objects.  See Tensor.tcl, proc TensorUpdateMRML \
            for information on how to stop this message from appearing."
        }
    }

    # In case we changed the name of the active data object
    TensorSetActive $Array(activeID)
}


#-------------------------------------------------------------------------------
# .PROC TensorCreate
#  Actually create a data object.  Called from TensorUpdateMRML.
#  Each module must add its own actor to the scene after
#  using this procedure to create a vtkMrmlData* object for it.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TensorCreate {ModuleArray d {objectType ""}} {

    # If the module is not loaded in the Slicer, do nothing.
    #--------------------------------------------------------
    if {[IsModule $ModuleArray] == "0"} {
        ## not all data types are module names, so don't return - steve & raul 2004-02-24
        #return
    }

    # Default value of vtkMrmlData subclass to create
    #--------------------------------------------------------
    if {$objectType == ""} {
        set objectType $ModuleArray
    }

    # Get access to the global module array
    #--------------------------------------------------------
    upvar #0 $ModuleArray Array

    # Get MRML node
    #--------------------------------------------------------
    set node ${ModuleArray}($d,node)

    # Get MRML data
    #--------------------------------------------------------
    set data ${ModuleArray}($d,data)

    # See if this data object already exists
    #--------------------------------------------------------
    if {[info command $data] != ""} {
        #puts "TensorCreate: $ModuleArray $d data exists"
        return 0
    }

    # Create vtkMrmlData* object 
    #--------------------------------------------------------
    #vtkMrmlData${ModuleArray} $data
    vtkMrmlData${objectType} $data

    # Connect data object with the MRML node
    #--------------------------------------------------------
    $data SetMrmlNode $node

    # Progress methods
    #--------------------------------------------------------
    $data AddObserver StartEvent       MainStartProgress
    $data AddObserver ProgressEvent   "MainShowProgress $data"
    $data AddObserver EndEvent         MainEndProgress

    # Here the module can hook in to set the new Data
    # object's properties (as defined by user in GUI)
    #--------------------------------------------------------
    Main${ModuleArray}SetAllVariablesToData $d

    # Mark the object as unsaved and created on the fly.
    # If it actually isn't being created on the fly, I can't tell that from
    # inside this procedure, so the "fly" variable will be set to 0 in the
    # TensorUpdateMRML procedure.
    set Array($d,dirty) 1
    set Array($d,fly) 1
    
    return 1
}


#-------------------------------------------------------------------------------
# .PROC TensorRead
#  Read in a vtkMrmlData object.  Called from TensorUpdateMRML.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TensorRead {ModuleArray d} {

    # If the module is not loaded in the Slicer, do nothing.
    #--------------------------------------------------------
    if {[IsModule $ModuleArray] == "0"} {
        ## not all data types are module names, so don't return - steve & raul 2004-02-24
        #return
    }

    # Get access to the global module array
    #--------------------------------------------------------
    upvar #0 $ModuleArray Array

    # Get MRML node
    #--------------------------------------------------------
    set node ${ModuleArray}($d,node)

    # Get MRML data
    #--------------------------------------------------------
    set data ${ModuleArray}($d,data)

    # Check FileName
    #--------------------------------------------------------
    # this test works in simple case where node has 1 filename
    # for volumes this test can't work and should
    # be handled by data object instead
    set fileName ""
    catch {set fileName [$node GetFileName]}
    if {$fileName != ""} {
        if {[CheckFileExists $fileName] == 0} {
            return -1
        }
    }
    
    # Display appropriate text over progress bar while reading
    #--------------------------------------------------------
    set Gui(progressText) "Reading [$node GetName]"

    # Read using vtkMrmlData object
    #--------------------------------------------------------
    puts "Reading [$node GetTitle]..."
    $data Read
    $data Update
    puts "...finished reading [$node GetTitle]"

    set Gui(progressText) ""

    # Lauren: models did pipeline stuff here
    # Now we either do pipeline junk here,
    # or we write vtkMrmlSlicerTensors to handle it

    # Mark this tensor as saved already
    set Array($d,dirty) 0

    # Return success code 
    #--------------------------------------------------------
    return 1
}

#-------------------------------------------------------------------------------
# .PROC TensorDelete
#  Delete a vtkMrmlData object.  Called from TensorUpdateMRML.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TensorDelete {ModuleArray d} {

    # If the module is not loaded in the Slicer, do nothing.
    #--------------------------------------------------------
    if {[IsModule $ModuleArray] == "0"} {
        ## not all data types are module names, so don't return - steve & raul 2004-02-24
        #return
    }

    # Get access to the global module array
    #--------------------------------------------------------
    upvar #0 $ModuleArray Array  

    # Get MRML data
    #--------------------------------------------------------
    set data ${ModuleArray}($d,data)

    # Make sure we are not deleting the idNone
    #--------------------------------------------------------
    if {$d == $Array(idNone)} {
        puts "Warning: TensorDelete, trying to delete the none $moduleArray"
        return 0
    }

    # See if this data object exists
    #--------------------------------------------------------
    if {[info command $data] == ""} {
        return 0
    }

    # Remove actors from renderers
    #--------------------------------------------------------
    # Actor handling is not general and must be done by the module
    #MainRemoveActor $d
    
    # Delete VTK objects 
    #--------------------------------------------------------
    $data  Delete
    #puts "Lauren does deleting the volume really delete the node?"
    
    # Delete all TCL variables of the form: Array($d,<whatever>)
    #--------------------------------------------------------
    foreach name [array names Array] {
        if {[string first "$d," $name] == 0} {
            unset Array($name)
        }
    }
    
    return 1
}

#-------------------------------------------------------------------------------
# .PROC TensorSetActive
#  Select a data object as active, and update the GUI to 
#  display properties of this object.  This proc calls the
#  procedure Main${ModuleArray}GetAllVariablesFromNode,
#  which the developer should write.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TensorSetActive {t} {
    global Tensor

    # Update ID number of active object
    #--------------------------------------------------------
    set Tensor(activeID) $t

    # Decide which button text to use
    #--------------------------------------------------------
    if {$t == ""} {
        # Menu button text reads "None"
        set mbText "None"
    } else {
        # Get current MRML node
        set node Tensor($t,node)
        # Menu button text shows active object's name
        set mbText [$node GetName]
    }

    # Change menu button text
    #--------------------------------------------------------
    foreach mb $Tensor(mbActiveList) {
        $mb config -text $mbText
    }

    # Exit here if the ID was ""
    #--------------------------------------------------------
    if {$t == ""} {
        return
    }
    
}    


#-------------------------------------------------------------------------------
# .PROC MainTensorSetActive
# Wrapping method around TensorSetActive
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTensorSetActive {ModuleArray d} {
  TensorSetActive $d
  
}  

     
#-------------------------------------------------------------------------------
# .PROC DTMRIInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
#  In DTMRIInit a list of sub-modules is set up and their init procedures
#  are called.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIInit {} {
    global DTMRI Module Volume Tensor env
    
    # Initialize the Tensor array for holding info about tensor volumes
    #------------------------------------
    TensorInit

    # Source all appropriate tcl files here. 
    #------------------------------------
    source "$env(SLICER_HOME)/Modules/vtkDTMRI/tcl/VTKObjectInspection.tcl"
    
    # List of all submodules (most are tcl files for tabs within this module)
    #------------------------------------
    set DTMRI(submodulesList) "TensorRegistration ODF TractCluster Tractography Glyphs CalculateTensors CalculateScalars Mask Save VoxelizeTracts"
    
    # Module Summary Info
    #------------------------------------
    set m DTMRI
    set Module($m,overview) "Diffusion Tensor MRI visualization and more..."
    set Module($m,author) "Lauren O'Donnell"
    set Module($m,category) "Visualisation"

    # Version info (just of this file, not submodule files)
    #------------------------------------
    lappend Module(versions) [ParseCVSInfo $m \
                  {$Revision: 1.133 $} {$Date: 2007/02/21 18:38:19 $}]

    # Define Tabs
    # Many of these correspond to submodules.
    #------------------------------------
    set Module($m,row1List) "Help Conv Glyph Tract Regist"
    set Module($m,row1Name) "{Help} {Conv} {Glyph} {Tract} {Reg}"
    set Module($m,row1,tab) Conv
    # Use these lines to add a second row of tabs
    set Module($m,row2List) "Scalars ROI TC Save ODF Vox VTK"
    set Module($m,row2Name) "{Scalars} {ROI} {TC} {Save} {ODF} {Vox} {VTK}"
    set Module($m,row2,tab) Scalars
    
  
    # Define Procedures
    #------------------------------------
    set Module($m,procGUI) DTMRIBuildGUI
    set Module($m,procMRML) DTMRIUpdateMRML
    set Module($m,procVTK) DTMRIBuildVTK
    set Module($m,procEnter) DTMRIEnter
    set Module($m,procExit) DTMRIExit
    
    # Define Dependencies
    #------------------------------------
    set Module($m,depend) ""
    
    # Create any specific bindings for this module
    #------------------------------------
    DTMRICreateBindings


    # Developers panel variables (possibly unused)
    #------------------------------------
    set DTMRI(devel,subdir) ""
    set DTMRI(devel,fileNamePoints) ""
    set DTMRI(devel,fileName) "DTMRIs.vtk"
    set tmp "\
            {1 0 0 0}  \
            {0 1 0 0}  \
            {0 0 1 0}  \
            {0 0 0 1}  "
    set rows {0 1 2 3}
    set cols {0 1 2 3}    
    foreach row $rows {
        foreach col $cols {
            set DTMRI(recalculate,userMatrix,$row,$col) \
                [lindex [lindex $tmp $row] $col]
        } 
    }


    # Variables shared by submodules
    #------------------------------------

    # 3 is brain in the default colormap for labels in the slicer
    set DTMRI(defaultLabel) 3

    # Id of active Tensor volume (one active per tab)
    set DTMRI(Active) ""
    #List of active tensor volumes. This volumes are all sync to have the same id.
    set DTMRI(ActiveList) "ActiveGlyph ActiveTract ActiveMask ActiveScalars ActiveSave"
    foreach active $DTMRI(ActiveList) {
        set DTMRI($active) ""
    }       

    #------------------------------------
    # Source and Init all submodules
    #------------------------------------
    foreach mod $DTMRI(submodulesList) {
        catch {source [file join $env(SLICER_HOME)/Modules/vtkDTMRI/tcl DTMRI${mod}.tcl]}
        set name "DTMRI${mod}Init"
        # If the Init procedure exists, call it.
        if {[info proc $name] == $name} {
            $name
        }
    }
    

}

################################################################
#  Procedures called automatically by the slicer
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMRML
# Called automatically by the main slicer code whenever the 
# the MRML tree changes (transformation matrices, new volumes, etc.)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMRML {} {
    global Tensor DTMRI

    set t $Tensor(activeID)
    
    if {$t != "" } {
        # in case transformation matrices have moved around
        # our tensor data, set up the tractography matrix again.
        # transform from World coords to scaledIJK of the tensors
        catch "transform Delete"
        vtkTransform transform
        # special trick to avoid warnings about legacy hack
        # for vtkTransform
        transform AddObserver WarningEvent ""
        DTMRICalculateActorMatrix transform $t    
        transform Inverse
        DTMRI(vtk,streamlineControl) SetWorldToTensorScaledIJK transform
        transform Delete 

        # Set the matrix for rotating tensors into world space
        vtkTransform transform
        # special trick to avoid warnings about legacy hack
        # for vtkTransform
        transform AddObserver WarningEvent ""        
        DTMRICalculateIJKtoRASRotationMatrix transform $t
        DTMRI(vtk,streamlineControl) SetTensorRotationMatrix \
            [transform GetMatrix]
        transform Delete

    }
    
     # Do MRML update of Tensor nodes.
     TensorUpdateMRML Tensor

     DevUpdateNodeSelectButton Tensor DTMRI ActiveGlyph ActiveGlyph DevSelectNode 0 0 0 DTMRISetTensorGlyph
     DevUpdateNodeSelectButton Tensor DTMRI ActiveTract ActiveTract DevSelectNode 0 0 0 DTMRISetTensorTract
     DevUpdateNodeSelectButton Tensor DTMRI ActiveMask ActiveMask DevSelectNode 0 0 0 DTMRISetTensorMask
     DevUpdateNodeSelectButton Tensor DTMRI ActiveScalars ActiveScalars DevSelectNode 0 0 0 DTMRISetTensorScalars
     DevUpdateNodeSelectButton Tensor DTMRI ActiveSave ActiveSave DevSelectNode 0 0 0 DTMRISetTensorSave
     
     # Do MRML update for Tensor Registration tab. Necessary because
     # multiple lists are used.
     # If the tensor reg module file exists it has set this variable
     if {[info exist DTMRI(reg,AG)]} {
         # If it found all its libraries it set this to 1
         if {$DTMRI(reg,AG) == 1} {
             # This is needed to handle deletion of tensors.
             if {[catch "Tensor($DTMRI(InputTensorSource),node) GetName"]==1} {
                 set DTMRI(InputTensorSource) $Tensor(idNone)
                 $DTMRI(mbInputTensorSource) config -text None
             }
             if {[catch "Tensor($DTMRI(InputTensorTarget),node) GetName"]==1} {
                 set DTMRI(InputTensorTarget) $Tensor(idNone)
                 $DTMRI(mbInputTensorTarget) config -text None
             }
             if {[catch "Tensor($DTMRI(ResultTensor),node) GetName"]==1} {
                 set DTMRI(ResultTensor) -5
             }
             DevUpdateNodeSelectButton Tensor DTMRI InputTensorSource   InputTensorSource   DevSelectNode
             DevUpdateNodeSelectButton Tensor DTMRI InputTensorTarget   InputTensorTarget   DevSelectNode 0 0 0 
             DevUpdateNodeSelectButton Tensor DTMRI ResultTensor  ResultTensor  DevSelectNode  0 1 0
             DevSelectNode Tensor $DTMRI(ResultTensor) DTMRI ResultTensor ResultTensor
             DevUpdateNodeSelectButton Volume DTMRI InputCoregVol InputCoregVol DevSelectNode
             DevUpdateNodeSelectButton Volume DTMRI TargetMaskVol TargetMaskVol DevSelectNode
             DevUpdateNodeSelectButton Volume DTMRI SourceMaskVol SourceMaskVol DevSelectNode
         }
     }

          
    DevUpdateNodeSelectButton Volume DTMRI InputODF InputODF DevSelectNode
    
    DevUpdateNodeSelectButton Volume DTMRI MaskLabelmap MaskLabelmap DevSelectNode 0 0 1 DTMRIUpdate
    DevUpdateNodeSelectButton Volume DTMRI ROILabelmap ROILabelmap DevSelectNode 0 0 1
    DevUpdateNodeSelectButton Volume DTMRI ROI2Labelmap ROI2Labelmap DevSelectNode 1 0 1
    DevUpdateNodeSelectButton Volume DTMRI  ROISelection  ROISelection DevSelectNode 0 0 1
    DevUpdateNodeSelectButton Volume DTMRI VoxTractsROILabelmap VoxTractsROILabelmap DevSelectNode 0 0 1
    DevUpdateNodeSelectButton Volume DTMRI ColorByVolume ColorByVolume DevSelectNode 0 0 0 DTMRIUpdateTractColorToMulti
    DevUpdateNodeSelectButton Volume DTMRI convertID convertID DevSelectNode 0 0 1 DTMRIConvertUpdate

    # Update label widgets.  This is because if the colormap changes,
    # then the widget colors may have to change.
    DTMRIUpdateLabelWidget ROILabel
    DTMRIUpdateLabelWidget ROI2Label
    DTMRIUpdateLabelWidget TractLabel
    DTMRIUpdateLabelWidget MaskLabel

}

#-------------------------------------------------------------------------------
# .PROC DTMRIEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIEnter {} {
    global DTMRI Volume Slice View
    
    # set global flag to avoid possible render loop
    set View(resetCameraClippingRange) 0

    # add event handling for slices
    EvActivateBindingSet DTMRISlice0Events
    EvActivateBindingSet DTMRISlice1Events
    EvActivateBindingSet DTMRISlice2Events

    # add event handling for 3D
    EvActivateBindingSet DTMRI3DEvents

    # color label selection widgets
    LabelsColorWidgets

    # Default to reformatting along with the currently active slice
    set DTMRI(mode,reformatType) $Slice(activeID)

    Render3D

    #Update LMI logo
    set modulepath $::PACKAGE_DIR_VTKDTMRI/../../../images
    if {[file exist [ExpandPath [file join \
                     $modulepath "slicerLMIlogo.ppm"]]]} {
        image create photo iWelcome \
        -file [ExpandPath [file join $modulepath "slicerLMIlogo.ppm"]]
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIExit {} {
    global DTMRI View
    
    # unset global flag to avoid possible render loop
    set View(resetCameraClippingRange) 1

    # remove event handling for slices
    EvDeactivateBindingSet DTMRISlice0Events
    EvDeactivateBindingSet DTMRISlice1Events
    EvDeactivateBindingSet DTMRISlice2Events

    # remove event handling for 3D
    EvDeactivateBindingSet DTMRI3DEvents

    #Restore standar slicer logo
    image create photo iWelcome \
        -file [ExpandPath [file join gui "welcome.ppm"]]


}

################################################################
#  Procedures for building the GUI
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIBuildGUI
# Builds the GUI panel.  Calls any existing SubmoduleBuildGUI procedure in
# submodule tcl files. Builds the VTK GUI for user interaction with objects.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildGUI {} {
    global Module Gui DTMRI Label Volume Tensor


    # Build GUI for all submodules
    foreach mod $DTMRI(submodulesList) {
        set name "DTMRI${mod}BuildGUI"
        # If the Build GUI procedure exists, call it.
        if {[info proc $name] == $name} {
            $name
        }
    }

    # Build GUI for the VTK object inspection
    VTKOIBuildGUI DTMRI $Module(DTMRI,fVTK)


    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    This module allows visualization of DTMRI-valued data, 
especially Diffusion DTMRI MRI.
    <P>

    For <B>tractography</B>, point at the voxel of interest with the mouse and click\n the letter '<B>s</B>' (for start, or streamline). To <B>delete</B> a tract, point at it and click '<B>d</B>' (for delete).
<P><B>Warning</B>: It may not be possible to run this process to completion on Windows, due to memory allocation constraints.
    <P>
    Description by tab:
    <BR>
    <B>Disp (Visualization and Display Settings Tab)</B>
    <BR>
    <UL>
    <LI><B>3D View Settings:</B> click 'DTMRIs' view for transparent slices (this makes it easier to see 3D glyphs and tracts). 
    <LI><B>Display Glyphs:</B> turn glyphs on and off. Glyphs are little models for each DTMRI.  They display the eigensystem (principal directions of diffusion).
    <LI><B>Glyphs on Slice:</B> glyphs are displayed in the 3D view over this reformatted slice.  The slice-selection buttons are colored to match the colors of the three slice windows at the bottom of the Viewer window.
    <LI><B>Display Tracts:</B> turn display of tracts on and off, or delete all tracts.  Tracts are seeded when you point the mouse and hit the 's' key.  There are many more settings for tracts under the Visualization Menu below.
    <LI><B>Visualization Menu:</B> Settings for Tracts and Glyphs.
    </UL>


    <P>
    <B>Props Tab</B>
    <BR>
    <UL>
    <LI>This tab is for file reading/DTMRI conversion.
    </UL>
"
    regsub -all "\n" $help {} help
    MainHelpApplyTags DTMRI $help
    MainHelpBuildGUI DTMRI

}

################################################################
#  bindings for user interaction
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRICreateBindings
#  Makes bindings for the module.  These are in effect when module is entered
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICreateBindings {} {
    global Gui Ev; # CustomCsys Csys
    
    #EvDeclareEventHandler DTMRICsysEvents <KeyPress-c> {CustomCsysDoSomethingCool}

    # this seeds a stream when the l key is hit (use s instead, it's nicer)
    EvDeclareEventHandler DTMRISlicesStreamlineEvents <KeyPress-l> \
    { if { [SelectPick2D %W %x %y] != 0 } \
          {  eval DTMRISelectStartHyperStreamline $Select(xyz); Render3D } }
    # this seeds a stream when the s key is hit
    EvDeclareEventHandler DTMRISlicesStreamlineEvents <KeyPress-s> \
    { if { [SelectPick2D %W %x %y] != 0 } \
          {  eval DTMRISelectStartHyperStreamline $Select(xyz); Render3D } }
    
    EvAddWidgetToBindingSet DTMRISlice0Events $Gui(fSl0Win) {DTMRISlicesStreamlineEvents}
    EvAddWidgetToBindingSet DTMRISlice1Events $Gui(fSl1Win) {DTMRISlicesStreamlineEvents}
    EvAddWidgetToBindingSet DTMRISlice2Events $Gui(fSl2Win) {DTMRISlicesStreamlineEvents}

    # this seeds a stream when the l key is hit (use s instead, it's nicer)
    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-l> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectStartHyperStreamline $Select(xyz);Render3D } }
    # this seeds a stream when the s key is hit
    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-s> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectStartHyperStreamline $Select(xyz);Render3D } }
    # this deletes a stream when the d key is hit
    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-d> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectRemoveHyperStreamline $Select(xyz);Render3D } }
    # this chooses a streamline when c is hit
    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-c> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectChooseHyperStreamline $Select(xyz);Render3D } }

    # This contains all the regular events from tkInteractor.tcl, 
    # which will happen after ours.  For some reason we don't need 
    # this for the slice windows, apparently their original bindings
    # are not done using Ev.tcl and they stay even when we add ours.
    EvAddWidgetToBindingSet DTMRI3DEvents $Gui(fViewWin) {{DTMRI3DStreamlineEvents} {tkMouseClickEvents} {tkMotionEvents} {tkRegularEvents}}
}




################################################################
#  little procedures to handle display control, interaction with user
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRIRemoveAllActors
# Remove all actors (glyphs, tracts) from scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRemoveAllActors {} {
    global DTMRI
    
    # rm glyphs
    MainRemoveActor DTMRI(vtk,glyphs,actor)

    # rm streamlines
    DTMRIRemoveAllStreamlines

    Render3D

    set DTMRI(glyphs,actorsAdded) 0
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAddAllActors
# Add all actors (glyphs, tracts) to scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIAddAllActors {} {
    global DTMRI
    
    # rm glyphs
    MainAddActor DTMRI(vtk,glyphs,actor)

    # rm streamlines
    DTMRIAddAllStreamlines

    Render3D

    set DTMRI(glyphs,actorsAdded) 1
}



################################################################
#  Procedures to set up pipelines and create/modify vtk objects.
#  TODO: try to create objects only if needed!
################################################################



#-------------------------------------------------------------------------------
# .PROC DTMRIDeleteVTKObject
#  Wrapper around VTKOIDeleteVTKObject.
# .ARGS
# string object Name of object to delete
# .END
#-------------------------------------------------------------------------------
proc DTMRIDeleteVTKObject {object} {
    global DTMRI
    VTKOIDeleteVTKObject DTMRI $object
}

#-------------------------------------------------------------------------------
# .PROC DTMRIMakeVTKObject
# Wrapper around VTKOIMakeVTKObject.
# .ARGS
# string object  Name of object to create
# .END
#-------------------------------------------------------------------------------
proc DTMRIMakeVTKObject {class object} {
    global DTMRI
    VTKOIMakeVTKObject DTMRI $class $object
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAddObjectProperty
# Wrapper around VTKOIAddObjectProperty
# .ARGS
# string object name of vtk object (same as arg when creating it)
# string parameter name of variable in the object
# string value initial value
# string type data type
# string desc description for tooltip
# .END
#-------------------------------------------------------------------------------
proc DTMRIAddObjectProperty {object parameter value type desc} {
    global DTMRI
    VTKOIAddObjectProperty DTMRI $object $parameter $value $type $desc
}



#-------------------------------------------------------------------------------
# .PROC DTMRIBuildVTK
# Called automatically by the slicer program.
# builds pipelines.
# See also DTMRIUpdate for pipeline use.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildVTK {} {
    global DTMRI Module

    #---------------------------------------------------------------
    # Pipeline for display of DTMRIs over 2D slices
    #---------------------------------------------------------------
    
    foreach plane "0 1 2" {
    DTMRIMakeVTKObject vtkImageReformat reformat$plane
    }

    #------------------------------------
    # objects for masking before glyph display
    #------------------------------------

    # produce binary mask from the input mask labelmap
    set object mask,threshold
    DTMRIMakeVTKObject vtkImageThreshold $object
    DTMRI(vtk,$object) SetInValue       1
    DTMRI(vtk,$object) SetOutValue      0
    DTMRI(vtk,$object) SetReplaceIn     1
    DTMRI(vtk,$object) SetReplaceOut    1
    DTMRI(vtk,$object) SetOutputScalarTypeToShort

    # convert the mask to short
    # (use this most probable input type to try to avoid data copy)
    #set object mask,cast
    #DTMRIMakeVTKObject vtkImageCast $object
    #DTMRI(vtk,$object) SetOutputScalarTypeToShort    
    #DTMRI(vtk,$object) SetInput \
    #    [DTMRI(vtk,mask,threshold) GetOutput]

    # mask the DTMRIs 
    set object mask,mask
    DTMRIMakeVTKObject vtkTensorMask $object
    DTMRI(vtk,$object) SetMaskInput \
        [DTMRI(vtk,mask,threshold) GetOutput]

    #---------------------------------------------------------------
    # Pipeline for display of glyphs
    #---------------------------------------------------------------

    # User interaction objects
    #------------------------------------
    set object picker
    DTMRIMakeVTKObject vtkCellPicker $object
    # Making this change causes incorrect location to be 
    # chosen in 3D. Needs more investigation into SelectPick function
    # in Select.tcl, which we are using.  To be done later, in conjunction
    # with having fewer actors.
    #DTMRIMakeVTKObject vtkFastCellPicker $object
    DTMRIAddObjectProperty $object Tolerance 0.001 float {Pick Tolerance}

    # objects for creation of polydata glyphs
    #------------------------------------

    # Axes
    set object glyphs,axes
    DTMRIMakeVTKObject vtkAxes $object
    DTMRIAddObjectProperty $object ScaleFactor 1 float {Scale Factor}
    
    # too slow: maybe useful for nice photos
    #set object glyphs,tubeAxes
    #DTMRIMakeVTKObject vtkTubeFilter $object
    #DTMRI(vtk,$object) SetInput [DTMRI(vtk,glyphs,axes) GetOutput]
    #DTMRIAddObjectProperty $object Radius 0.1 float {Radius}
    #DTMRIAddObjectProperty $object NumberOfSides 6 int \
    #    {Number Of Sides}

    # One line
    set object glyphs,line
    DTMRIMakeVTKObject vtkLineSource $object
    DTMRIAddObjectProperty $object Resolution 10 int {Resolution}
    #DTMRI(vtk,$object) SetPoint1 0 0 0
    # use a stick that points both ways, not a vector from the origin!
    DTMRI(vtk,$object) SetPoint1 -1 0 0
    DTMRI(vtk,$object) SetPoint2 1 0 0
    
    set object glyphs,tube
    DTMRIMakeVTKObject vtkTubeFilter $object
    DTMRI(vtk,$object) SetInput [DTMRI(vtk,glyphs,line) GetOutput]
    DTMRIAddObjectProperty $object Radius 0.1 float {Radius}
    DTMRIAddObjectProperty $object NumberOfSides 6 int \
        {Number Of Sides}

    # Ellipsoids
    set object glyphs,sphere
    DTMRIMakeVTKObject vtkSphereSource  $object
    #DTMRIAddObjectProperty $object ThetaResolution 1 int ThetaResolution
    #DTMRIAddObjectProperty $object PhiResolution 1 int PhiResolution
    DTMRIAddObjectProperty $object ThetaResolution 12 int ThetaResolution
    DTMRIAddObjectProperty $object PhiResolution 12 int PhiResolution

    # Boxes
    set object glyphs,box
    DTMRIMakeVTKObject vtkCubeSource  $object

    # stripping
    set object glyphs,stripper
    DTMRIMakeVTKObject vtkStripper $object

    # objects for placement of Standard glyphs in dataset
    #------------------------------------
    set object glyphs
    foreach plane "0 1 2" {
    #DTMRIMakeVTKObject vtkDTMRIGlyph $object
    DTMRIMakeVTKObject vtkInteractiveTensorGlyph $object$plane
    DTMRI(vtk,$object$plane) SetInput ""
    #DTMRI(vtk,glyphs$plane) SetSource [DTMRI(vtk,glyphs,axes) GetOutput]
    #DTMRI(vtk,glyphs$plane) SetSource [DTMRI(vtk,glyphs,sphere) GetOutput]
    #DTMRIAddObjectProperty $object ScaleFactor 1 float {Scale Factor}
    DTMRIAddObjectProperty $object$plane ScaleFactor 1000 float {Scale Factor}
    DTMRIAddObjectProperty $object$plane ClampScaling 0 bool {Clamp Scaling}
    DTMRIAddObjectProperty $object$plane ExtractEigenvalues 1 bool {Extract Eigenvalues}
    DTMRI(vtk,$object$plane) AddObserver StartEvent MainStartProgress
    DTMRI(vtk,$object$plane) AddObserver ProgressEvent "MainShowProgress DTMRI(vtk,$object$plane)"
    DTMRI(vtk,$object$plane) AddObserver EndEvent MainEndProgress
    }
    
    # objects for placement of Superquadric glyphs in dataset
    #------------------------------------    
    set object glyphsSQ
    foreach plane "0 1 2" {
    DTMRIMakeVTKObject vtkSuperquadricTensorGlyph $object$plane
    DTMRI(vtk,$object$plane) SetInput ""
    DTMRIAddObjectProperty $object$plane ScaleFactor 1000 float {Scale Factor}
    DTMRIAddObjectProperty $object$plane ClampScaling 0 bool {Clamp Scaling}
    DTMRIAddObjectProperty $object$plane Gamma 1 float {Gamma}
    DTMRIAddObjectProperty $object$plane ThetaResolution 12 int {ThetaResolution}
    DTMRIAddObjectProperty $object$plane PhiResolution 12 int {PhiResolution}
    DTMRI(vtk,$object$plane) AddObserver StartEvent MainStartProgress
    DTMRI(vtk,$object$plane) AddObserver ProgressEvent "MainShowProgress DTMRI(vtk,$object$plane)"
    DTMRI(vtk,$object$plane) AddObserver EndEvent MainEndProgress
    }
    
    set object glyphs,trans
    DTMRIMakeVTKObject vtkTransform $object
    
    #poly data append to join glyphs from the 3 slice planes
    set object glyphs,append
    DTMRIMakeVTKObject vtkAppendPolyData $object
    DTMRI(vtk,$object) UserManagedInputsOn
    
    # poly data normals filter cleans up polydata for nice display
    # use this for ellipses/boxes only
    #------------------------------------
    # very slow
    set object glyphs,normals
    DTMRIMakeVTKObject vtkPolyDataNormals $object
    DTMRI(vtk,$object) SetInput [DTMRI(vtk,glyphs,append) GetOutput]

    # Display of DTMRI glyphs: LUT and Mapper
    #------------------------------------
    set object glyphs,lut
    #DTMRIMakeVTKObject vtkLogLookupTable $object
    DTMRIMakeVTKObject vtkLookupTable $object
    DTMRIAddObjectProperty $object HueRange \
        {0 1} float {Hue Range}

    # mapper
    set object glyphs,mapper
    DTMRIMakeVTKObject vtkPolyDataMapper $object
    #Raul
    DTMRI(vtk,glyphs,mapper) SetInput [DTMRI(vtk,glyphs,append) GetOutput]
    #DTMRI(vtk,glyphs,mapper) SetInput [DTMRI(vtk,glyphs,normals) GetOutput]
    DTMRI(vtk,glyphs,mapper) SetLookupTable DTMRI(vtk,glyphs,lut)
    DTMRIAddObjectProperty $object ImmediateModeRendering \
        1 bool {Immediate Mode Rendering}    

    # Display of DTMRI glyphs: Actor
    #------------------------------------
    set object glyphs,actor
    #DTMRIMakeVTKObject vtkActor $object
    DTMRIMakeVTKObject vtkLODActor $object
    DTMRI(vtk,glyphs,actor) SetMapper DTMRI(vtk,glyphs,mapper)
    # intermediate level of detail produces visible points with 10
    [DTMRI(vtk,glyphs,actor) GetProperty] SetPointSize 10
    
    [DTMRI(vtk,glyphs,actor) GetProperty] SetAmbient 1
    [DTMRI(vtk,glyphs,actor) GetProperty] SetDiffuse .2
    [DTMRI(vtk,glyphs,actor) GetProperty] SetSpecular .4

    # Scalar bar actor
    #------------------------------------
    set object scalarBar,actor
    DTMRIMakeVTKObject vtkScalarBarActor $object
    DTMRI(vtk,scalarBar,actor) SetLookupTable DTMRI(vtk,glyphs,lut)
    viewRen AddProp DTMRI(vtk,scalarBar,actor)
    DTMRI(vtk,scalarBar,actor) VisibilityOff

    #---------------------------------------------------------------
    # Pipeline for display of tractography
    #---------------------------------------------------------------
    vtkMultipleStreamlineController DTMRI(vtk,streamlineControl)
    #DTMRI(vtk,streamlineControl) DebugOn
    # give it the renderers in which we display streamlines
    vtkCollection DTMRI(vtk,renderers)
    foreach r $Module(Renderers) {
        DTMRI(vtk,renderers) AddItem $r
    }
    DTMRI(vtk,streamlineControl) SetInputRenderers DTMRI(vtk,renderers)
    # This will be the input to the streamline controller. It lets us merge 
    # scalars from various datasets with the input tensor field
    vtkMergeFilter DTMRI(vtk,streamline,merge)

    # these are example objects used in creation of hyperstreamlines
    set streamline "streamlineControl,vtkHyperStreamlinePoints"
    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    vtkHyperStreamlineDTMRI DTMRI(vtk,$streamline) 
    $seedTracts SetVtkHyperStreamlinePointsSettings \
        DTMRI(vtk,$streamline)
    set streamline "streamlineControl,vtkPreciseHyperStreamlinePoints"
    vtkPreciseHyperStreamlinePoints DTMRI(vtk,$streamline)
    $seedTracts SetVtkPreciseHyperStreamlinePointsSettings \
        DTMRI(vtk,$streamline)

    set streamline "streamlineControl,vtkHyperStreamlineTeem"
    vtkHyperStreamlineTeem DTMRI(vtk,$streamline)
    $seedTracts SetVtkHyperStreamlineTeemSettings \
        DTMRI(vtk,$streamline)
    


    #---------------------------------------------------------------
    # Pipeline for BSpline tractography (moved from proc DTMRIInit)
    #---------------------------------------------------------------

    DTMRIMakeVTKObject vtkTensorImplicitFunctionToFunctionSet itf
    set DTMRI(vtk,BSpline,init) 0
    set DTMRI(vtk,BSpline,data) 0
    
    if {[info command vtkITKBSplineImageFilter] == ""} {
        DevErrorWindow "DTMRI\nERROR: vtkITKBSplineImageFilter does not exist, cannot use bspline filter"
    }
    for {set i 0} {$i < 6} {incr i 1} {
        DTMRIMakeVTKObject vtkBSplineInterpolateImageFunction impComp($i)
        DTMRI(vtk,itf) AddImplicitFunction DTMRI(vtk,impComp($i)) $i
        if {[info command vtkITKBSplineImageFilter] != ""} {
            DTMRIMakeVTKObject vtkITKBSplineImageFilter bspline($i)
        } 
        DTMRIMakeVTKObject vtkExtractTensorComponents extractor($i)
        DTMRI(vtk,extractor($i)) PassTensorsToOutputOff
        DTMRI(vtk,extractor($i)) ExtractScalarsOn
        DTMRI(vtk,extractor($i)) ExtractVectorsOff
        DTMRI(vtk,extractor($i)) ExtractNormalsOff
        DTMRI(vtk,extractor($i)) ExtractTCoordsOff
        DTMRI(vtk,extractor($i)) ScalarIsComponent
    }
    
    DTMRI(vtk,extractor(0)) SetScalarComponents 0 0
    DTMRI(vtk,extractor(1)) SetScalarComponents 0 1
    DTMRI(vtk,extractor(2)) SetScalarComponents 0 2
    DTMRI(vtk,extractor(3)) SetScalarComponents 1 1
    DTMRI(vtk,extractor(4)) SetScalarComponents 1 2
    DTMRI(vtk,extractor(5)) SetScalarComponents 2 2
    
    DTMRIMakeVTKObject vtkRungeKutta45 rk45
    DTMRIMakeVTKObject vtkRungeKutta4 rk4
    DTMRIMakeVTKObject vtkRungeKutta2 rk2
    
    DTMRI(vtk,rk45) SetFunctionSet DTMRI(vtk,itf)
    DTMRI(vtk,rk4) SetFunctionSet DTMRI(vtk,itf)
    DTMRI(vtk,rk2) SetFunctionSet DTMRI(vtk,itf)
    
    set DTMRI(vtk,ivps) DTMRI(vtk,rk4)

    #Objects for finding streamlines through several ROIS
    vtkROISelectTracts DTMRI(vtk,ROISelectTracts)
    DTMRI(vtk,ROISelectTracts) SetStreamlineController DTMRI(vtk,streamlineControl)
    vtkShortArray DTMRI(vtk,ListANDLabels)
    vtkShortArray DTMRI(vtk,ListNOTLabels)
    vtkDoubleArray DTMRI(vtk,convKernel)    
    
    #Get Kernel 
    vtkStructuredPointsReader DTMRI(vtk,tmp1)
    global PACKAGE_DIR_VTKDTMRI
    DTMRI(vtk,tmp1) SetFileName $PACKAGE_DIR_VTKDTMRI/../../../data/GKernel.vtk
    DTMRI(vtk,tmp1) Update

    vtkImageCast DTMRI(vtk,tmp2)
    DTMRI(vtk,tmp2) SetInput [DTMRI(vtk,tmp1) GetOutput]
    DTMRI(vtk,tmp2) SetOutputScalarTypeToDouble
    DTMRI(vtk,tmp2) Update
    
    DTMRI(vtk,convKernel) DeepCopy [[[DTMRI(vtk,tmp2) GetOutput] GetPointData] GetScalars]

    DTMRI(vtk,tmp1) Delete
    DTMRI(vtk,tmp2) Delete
    

    DTMRIBuildVTKODF

}





################################################################
#  Procedures that deal with coordinate systems
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIGetScaledIjkCoordinatesFromWorldCoordinates
#
# Use our world to ijk matrix information to correct x,y,z.
# The streamline class doesn't know about the
# DTMRI actor's "UserMatrix" (actually implemented with two matrices
# in the glyph class).  We need to transform xyz by
# the inverse of this matrix (almost) so the streamline will start 
# from the right place in the DTMRIs.  The "almost" is because the 
# DTMRIs know about their spacing (vtkImageData) and so we must
# remove the spacing from this matrix.
#
#
# .ARGS
# int x x-coordinate of input world coordinates point 
# int y y-coord
# int z z-coord
# .END
#-------------------------------------------------------------------------------
proc DTMRIGetScaledIjkCoordinatesFromWorldCoordinates {x y z} {
    global DTMRI Tensor

    set t $Tensor(activeID)
    
    vtkTransform transform
    DTMRICalculateActorMatrix transform $t    
    transform Inverse
    set point [transform TransformPoint $x $y $z]
    transform Delete

    # check point is in bounds of the dataset
    set dims [[Tensor($t,data) GetOutput] GetDimensions]
    set space [[Tensor($t,data) GetOutput] GetSpacing]
    # return "-1 -1 -1" if out of bounds error 
    foreach d $dims s $space p $point {
        if {$p < 0} {
            set point "-1 -1 -1"
        } elseif {$p > [expr $d*$s]} {
            set point "-1 -1 -1"
        }
    }

    return $point
}

#-------------------------------------------------------------------------------
# .PROC DTMRICalculateActorMatrix
# Place the entire Tensor volume in world coordinates
# using this transform.  Uses world to IJK matrix but
# removes the spacing since the data/actor know about this.
# .ARGS
# vtkTransform transform the transform to modify
# int t the id of the DTMRI volume to calculate the matrix for
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateActorMatrix {transform t} {
    global Tensor
    # Grab the node whose data we want to position 
    set node Tensor($t,node)

    if { [info command $node] == "" } {
        # the node doesn't exist (probably being deleted)
        # so bail out here
        return
    }

    # the user matrix is either the reformat matrix
    # to place the slice, OR it needs to place the entire 
    # DTMRI volume.

    # In this procedure we calculate the second kind of matrix,
    # to place the whole volume.
    $transform Identity
    $transform PreMultiply

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    $transform SetMatrix [$node GetWldToIjk]

    # now it's ijk to world
    $transform Inverse

    # the data knows its spacing already so remove it
    # (otherwise the actor would be stretched, ouch)
    scan [$node GetSpacing] "%g %g %g" res_x res_y res_z

    $transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
        [expr 1.0 / $res_z]
}


#-------------------------------------------------------------------------------
# .PROC DTMRICalculateIJKtoRASRotationMatrix
# 
#  The IJK to RAS matrix has two actions on the DTMRIs.
#  <p>
#  1.  Each DTMRI glyph must be placed at the (x,y,z) location
#  determined by the matrix.  This is analogous to setting the
#  reformat matrix as the actor's user matrix when placing 
#  scalar data.  However, actor matrices do not work here because
#  of number 2, next.
#  <p>
#  2.  Each DTMRI itself must be rotated from ijk to ras.  This
#  uses the ijk to ras matrix, but without any scaling or translation.
#  The DTMRIs are created in the ijk coordinate system so that 
#  diffusion-simulation filters and hyperstreamlines, which do not 
#  know about RAS or actor placement, can correctly handle the data.
#
#
#  <p> This procedure removes translation and scaling 
#  from a volume's ijk to ras matrix, and it returns
#  a rotation matrix that can act on each DTMRI.
#
# .ARGS
# string transform
# int t
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateIJKtoRASRotationMatrix {transform t} {
    global Volume Tensor

    if { [info command Tensor($t,node)] == "" } {
        # the node doesn't exist (probably being deleted)
        # so bail out here
        return
    }


    # special trick to avoid warnings about legacy hack
    # for vtkTransform
    $transform AddObserver WarningEvent ""

    # --------------------------------------------------------
    # Rotate DTMRIs to RAS  (actually to World space)
    # --------------------------------------------------------
    # We want the DTMRIs to be displayed in the RAS coordinate system

    # The upper left 3x3 part of this matrix is the rotation.
    # (It also has voxel scaling which we will remove.)
    # -------------------------------------
    #$transform SetMatrix [Tensor($t,node)  GetRasToIjk]
    $transform SetMatrix [Tensor($t,node)  GetWldToIjk]
    # Now it's ijk to ras
    $transform Inverse

    # Remove the voxel scaling from the matrix.
    # -------------------------------------
    scan [Tensor($t,node) GetSpacing] "%g %g %g" res_x res_y res_z

    # We want -y since vtk flips the y axis
    #puts "Not flipping y"
    #set res_y [expr -$res_y]
    $transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
    [expr 1.0 / $res_z]

    # Remove the translation part from the last column.
    # (This was in there to center the volume in the cube.)
    # -------------------------------------
    [$transform GetMatrix] SetElement 0 3 0
    [$transform GetMatrix] SetElement 1 3 0
    [$transform GetMatrix] SetElement 2 3 0
    # Set element (4,4) to 1: homogeneous point
    [$transform GetMatrix] SetElement 3 3 1

    # Now this matrix JUST does the rotation needed for ijk->ras.
    # -------------------------------------
    #puts "-----------------------------------"
    #puts [$transform Print]
    #puts "-----------------------------------"

}

#-------------------------------------------------------------------------------
# .PROC DTMRISetTensor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISetTensor {} {
  global Tensor
  
  DTMRISetActive $Tensor(activeID)
  
}  

proc DTMRISetTensorGlyph {} {
  global DTMRI Tensor
  
  set Tensor(activeID) $DTMRI(ActiveGlyph)
  DTMRISetActive $Tensor(activeID)
  
}  

proc DTMRISetTensorTract {} {
  global DTMRI Tensor
  
  set Tensor(activeID) $DTMRI(ActiveTract)
  DTMRISetActive $Tensor(activeID)
  
}  

proc DTMRISetTensorMask {} {
  global DTMRI Tensor
  
  set Tensor(activeID) $DTMRI(ActiveMask)
  DTMRISetActive $Tensor(activeID)
  
}  

proc DTMRISetTensorSave {} {
  global DTMRI Tensor
  
  set Tensor(activeID) $DTMRI(ActiveSave)
  DTMRISetActive $Tensor(activeID)
  
}  

proc DTMRISetTensorScalars {} {
  global DTMRI Tensor
  
  set Tensor(activeID) $DTMRI(ActiveScalars)
  DTMRISetActive $Tensor(activeID)
  
}  

#-------------------------------------------------------------------------------
# .PROC DTMRISetActive
# Set the active tensor on the menus, and make it input to the 
# glyph and tractography pipelines. 
# .ARGS
# int n ID number of the DTMRI volume that will become active
# .END
#-------------------------------------------------------------------------------
proc DTMRISetActive {t} {
    global DTMRI

    set DTMRI(Active) $t
    
    #Sync the list of actives DTMRI
    foreach active $DTMRI(ActiveList) {
        set DTMRI($active) $t
       $DTMRI(mb$active) configure -text [Tensor($t,node) GetName]
    }       

    #set up the mask if exists
    if {[info exists DTMRI(maskTable,$t)] == 1} {
       
       #Check mask node exists
       set v $DTMRI(maskTable,$t)
       if {[catch "Volume($v,node) GetClassName"] == 0} {
           #Set up mask pipeline
           set DTMRI(MaskLabelmap) $v
           set DTMRI(MaskLabel) 1
           set DTMRI(mode,mask) MaskWithLabelmap
           #Set label of menu button to volume name.
           $DTMRI(mbMaskLabelmap) configure -text [Volume($v,node) GetName]
       } else {
           set DTMRI(mode,mask) None
       }   
    } else {
       set DTMRI(mode,mask) None
    }   

    # Make sure this tensor is the input to the glyph pipeline
    DTMRIUpdate

    # set up the tractography pipeline with both data and location
    # information from the active tensor dataset
    DTMRI(vtk,streamline,merge) SetTensors [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetGeometry [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetScalars [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetVectors [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetNormals [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetTCoords [Tensor($t,data) GetOutput]
    
    DTMRI(vtk,streamline,merge) Update
    DTMRI(vtk,streamlineControl) SetInputTensorField \
        [DTMRI(vtk,streamline,merge) GetOutput] 
    
    #DTMRI(vtk,streamlineControl) SetInputTensorField [Tensor($t,data) GetOutput]
    
    
    # set correct transformation from World coords to scaledIJK of the tensors
    vtkTransform transform
    # special trick to avoid warnings about legacy hack
    # for vtkTransform
    transform AddObserver WarningEvent ""
    DTMRICalculateActorMatrix transform $t    
    transform Inverse
    DTMRI(vtk,streamlineControl) SetWorldToTensorScaledIJK transform
    transform Delete    

    # start with solid colors since we can't be sure selected volume
    # is okay to color tracts with (i.e. may not have same size).
    # this also sets up the correct color for the first tract.
    DTMRIUpdateTractColorToSolid

    # initial setup of the streamline control object for the
    # type of streamline to create.
    DTMRIUpdateStreamlineSettings
    

#     # set up the BSpline tractography pipeline
#     set DTMRI(vtk,BSpline,data) 1
#     set DTMRI(vtk,BSpline,init) 1;
#     DTMRI(vtk,itf) SetDataBounds [Tensor($t,data) GetOutput]
#     #DTMRI(vtk,itf) SetDataBounds [DTMRI(vtk,streamline,merge) GetOutput]
#     for {set i 0} {$i < 6} {incr i} {
#         DTMRI(vtk,extractor($i)) SetInput [Tensor($t,data) GetOutput]
#         #DTMRI(vtk,extractor($i)) SetInput \
#         #    [DTMRI(vtk,streamline,merge) GetOutput]
#     }
#     for {set i 0} {$i < 6} {incr i} {
#         #DTMRI(vtk,extractor($i)) Update
#         DTMRI(vtk,bspline($i)) SetInput [DTMRI(vtk,extractor($i)) GetOutput]
#     }          
#     DTMRIUpdateBSplineOrder $DTMRI(stream,BSplineOrder)
#     for {set i 0} {$i < 6} {incr i} {
#         #DTMRI(vtk,bspline($i)) Update
#         DTMRI(vtk,impComp($i)) SetInput [DTMRI(vtk,bspline($i)) GetOutput]
#     }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateLabelWidgetFromShowLabels
# Callback after ShowLabels window receives a label selection
# from the user.  Calls DTMRIUpdateLabelWidget
# after getting the Label(label) value set by the user.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateLabelWidgetFromShowLabels {label} {

    global Label DTMRI

    # Get the output of the ShowLabels popup window.
    # Label(label) is set to the selected number.
    LabelsFindLabel

    # Now this sets our local variable to the same value
    set DTMRI($label) $Label(label)

    DTMRIUpdateLabelWidget $label

}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateLabelWidget
# Update the color and color name of a label selection widget,
# after receiving user input.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateLabelWidget {label} {

    global DTMRI

    # new label value to use when updating
    set labelValue $DTMRI($label)

    # widget to update (name and color)
    set widget $DTMRI(${label}Widget)
    # label name variable to update
    set labelName DTMRI(${label}Name)
    # color value variable to update
    set colorID DTMRI(${label}ColorID)

    # display the color name and background color the GUI
    set c [MainColorsGetColorFromLabel $labelValue]
    set $colorID $c
    if {$c == ""} {
        # we don't have this color in the colormap for labels...
    } else {
        $widget config -bg \
            [MakeColorNormalized [Color($c,node) GetDiffuseColor]] \
            -state normal
        set $labelName [Color($c,node) GetName]
    }


}


#-------------------------------------------------------------------------------
# .PROC DTMRIGetVersionInfo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIGetVersionInfo {} {

    global DTMRI

    set msg [FormatCVSInfo $DTMRI(versions)]
    tk_messageBox -message $msg -title "DTMRI Sub-Module Version Info"
}

