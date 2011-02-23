#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRICalculateScalars.tcl,v $
#   Date:      $Date: 2007/10/18 20:19:35 $
#   Version:   $Revision: 1.29 $
# 
#===============================================================================
# FILE:        DTMRICalculateScalars.tcl
# PROCEDURES:  
#   DTMRICalculateScalarsInit
#   DTMRICalculateScalarsBuildGUI
#   DTMRISetOperation math
#   DTMRIUpdateMathParams
#   DTMRICreateEmptyVolume OrigId Description VolName
#   DTMRIDoMath operation
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC DTMRICalculateScalarsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateScalarsInit {} {

    global DTMRI

    # Version info for files within DTMRI module
    #------------------------------------
    set m "CalculateScalars"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                         {$Revision: 1.29 $} {$Date: 2007/10/18 20:19:35 $}]


    #------------------------------------
    # Variables for producing scalar volumes
    #------------------------------------

    # math op to produce scalars from DTMRIs
    set DTMRI(scalars,operation) Trace
    set DTMRI(scalars,operationList) [list Trace Determinant \
                      RelativeAnisotropy FractionalAnisotropy Mode LinearMeasure \
                      PlanarMeasure SphericalMeasure MaxEigenvalue \
                      MiddleEigenvalue MinEigenvalue ColorByOrientation \
                      ColorByMode  MaxEigenvalueProjectionX \
                      MaxEigenvalueProjectionY MaxEigenvalueProjectionZ \
                      IsotropicP AnisotropicQ \
              RAIMaxEigenvecX RAIMaxEigenvecY RAIMaxEigenvecZ D11 D22 D33 \
              ParallelDiffusivity PerpendicularDiffusivity]

    set DTMRI(scalars,operationList,tooltip) "Produce a scalar volume from DTMRI data.\nTrace, Determinant, Anisotropy, and Eigenvalues produce grayscale volumes,\nwhile Orientation produces a 3-component (Color) volume that is best viewed in the 3D window."

    # how much to scale the output floats by
    set DTMRI(scalars,scaleFactor) 1000
    set DTMRI(scalars,scaleFactor,tooltip) \
    "Multiplicative factor applied to output images for better viewing.\nColor image scale is divided by 1000 before being applied."
    
    # whether to compute vol from ROI or whole DTMRI volume
    set DTMRI(scalars,ROI) None
    set DTMRI(scalars,ROIList) {None Mask}
    set DTMRI(scalars,ROIList,tooltips) {"No ROI: derive the scalar volume from the entire DTMRI volume." "Use the mask labelmap volume defined in the ROI tab to mask the DTMRI volume before scalar volume creation."}




}


#-------------------------------------------------------------------------------
# .PROC DTMRICalculateScalarsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateScalarsBuildGUI {} {

    global DTMRI Tensor Module Gui

    #-------------------------------------------
    # Scalars frame
    #-------------------------------------------
    set fScalars $Module(DTMRI,fScalars)
    set f $fScalars
    
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    foreach frame "Top" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
        $f.f$frame config -relief groove -bd 3
    }

    #-------------------------------------------
    # Scalars->Active frame
    #-------------------------------------------
    set f $fScalars.fActive

    # menu to select active DTMRI
    DevAddSelectButton  DTMRI $f ActiveScalars "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActiveScalars
    lappend Tensor(mActiveList) $f.mbActiveScalars.m
    
    #-------------------------------------------
    # Scalars->Top frame
    #-------------------------------------------
    set f $fScalars.fTop
    
    foreach frame "ChooseOutput UseROI ScaleFactor Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Scalars->Top->ChooseOutput frame
    #-------------------------------------------
    set f $fScalars.fTop.fChooseOutput

    eval {label $f.lMath -text "Create Volume: "} $Gui(WLA)
    eval {menubutton $f.mbMath -text $DTMRI(scalars,operation) \
          -relief raised -bd 2 -width 20 \
          -menu $f.mbMath.m} $Gui(WMBA)

    eval {menu $f.mbMath.m} $Gui(WMA)
    pack $f.lMath $f.mbMath -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach math $DTMRI(scalars,operationList) {
        $f.mbMath.m add command -label $math \
        -command "DTMRISetOperation $math"
    }
    # save menubutton for config
    set DTMRI(gui,mbMath) $f.mbMath
    # Add a tooltip
    TooltipAdd $f.mbMath $DTMRI(scalars,operationList,tooltip)

    #-------------------------------------------
    # Scalars->Top->UseROI frame
    #-------------------------------------------
    set f $fScalars.fTop.fUseROI

    DevAddLabel $f.l "ROI:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach vis $DTMRI(scalars,ROIList) tip $DTMRI(scalars,ROIList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(scalars,ROI) \
          -command DTMRIUpdateMathParams \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }    

    #-------------------------------------------
    # Scalars->Top->ScaleFactor frame
    #-------------------------------------------
    set f $fScalars.fTop.fScaleFactor
    DevAddLabel $f.l "Scale Factor:"
    eval {entry $f.e -width 14 \
          -textvariable DTMRI(scalars,scaleFactor)} $Gui(WEA)
    TooltipAdd $f.e $DTMRI(scalars,scaleFactor,tooltip) 
    pack $f.l $f.e -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # Scalars->Top->Apply frame
    #-------------------------------------------
    set f $fScalars.fTop.fApply

    DevAddButton $f.bApply "Apply" "DTMRIDoMath"    
    pack $f.bApply -side top -padx 0 -pady 0

}


################################################################
#  Procedures used to derive scalar volumes from DTMRI data
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRISetOperation
# Set the mathematical operation we should do to produce
# a scalar volume from the DTMRIs
# .ARGS
# str math the name of the operation from list $DTMRI(scalars,operationList)
# .END
#-------------------------------------------------------------------------------
proc DTMRISetOperation {math} {
    global DTMRI

    set DTMRI(scalars,operation) $math
    
    # config menubutton
    $DTMRI(gui,mbMath) config -text $math
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMathParams
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMathParams {} {
    global DTMRI


    # Just check that if they requested a 
    # preprocessing step, that we are already
    # doing that step
    
    set mode $DTMRI(scalars,ROI)

    set err "The $mode ROI is not currently being computed.  Please turn this feature on in the ROI tab before creating the volume."

    switch $mode {
        "None" {
        }
        "Mask" {
            if {$DTMRI(mode,mask)    == "None"} {
                set DTMRI(scalars,ROI) None
                tk_messageBox -message $err
            }
        }
    }    

}

#-------------------------------------------------------------------------------
# .PROC DTMRICreateEmptyVolume
# Just like DevCreateNewCopiedVolume, but uses a Tensor node
# to copy parameters from instead of a volume node
# Used for scalar output from DTMRI math calculations.
# .ARGS
# int OrigId
# string Description Defaults to empty string
# string VolName Defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc DTMRICreateEmptyVolume {OrigId {Description ""} { VolName ""}} {
    global Volume Tensor

    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume]
    $newvol Copy Tensor($OrigId,node)
    
    # Set the Description and Name
    if {$Description != ""} {
        $newvol SetDescription $Description 
    }
    if {$VolName != ""} {
        $newvol SetName $VolName
    }

    # Create the volume (vtkMrmlDataVolume class)
    set n [$newvol GetID]
    MainVolumesCreate $n
   
    #Set up Node matrices from tensor volume
    set ext [[Tensor($OrigId,data) GetOutput] GetWholeExtent]
    DTMRIComputeRasToIjkFromCorners Tensor($OrigId,node) Volume($n,node) $ext
   
    # This updates all the buttons to say that the
    # Volume List has changed.
    MainUpdateMRML

    return $n
}

#-------------------------------------------------------------------------------
# .PROC DTMRIDoMath
# Called to compute a scalar vol from DTMRIs
# .ARGS
# string operation Defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc DTMRIDoMath {{operation ""}} {
    global DTMRI Gui Tensor


    # if this was called from user input GUI menu
    if {$operation == ""} {
        set operation $DTMRI(scalars,operation) 
    }

    # validate user input
    if {[ValidateFloat $DTMRI(scalars,scaleFactor)] != "1"} {
        DevErrorWindow \
            "Please enter a number for the scale factor."
        # reset default
        set DTMRI(scalars,scaleFactor) 1000
        return
    }

    # should use DevCreateNewCopiedVolume if have a vol node
    # to copy...
    set t $Tensor(activeID) 
    if {$t == "" || $t == $Tensor(idNone)} {
        DevErrorWindow \
            "Please select an input DTMRI volume (Active DTMRI)"
        return
    }
    set name [Tensor($t,node) GetName]
    set name ${operation}_$name
    set description "$operation volume derived from DTMRI volume $name"
    set v [DTMRICreateEmptyVolume $t $description $name]

    # find input
    set mode $DTMRI(scalars,ROI)
    
    switch $mode {
        "None" {
            set input [Tensor($t,data) GetOutput]
        }
        "Mask" {
            DTMRI(vtk,mask,mask) Update
            set input [DTMRI(vtk,mask,mask) GetOutput]
        }
    }

    #Set up proper scale factor
    #Map result between 1 - 1000
    
    puts "Running oper: $operation"
    
    # removed this hard-coded reset of the user's selected scale value after reviewing with LMI folks (sp - for slicer 2.6
    if { 0 } { 
        switch -regexp -- $operation {
        {^(Trace|Determinant|D11|D22|D33|MaxEigenvalue|MiddleEigenvalue|MinEigenvalue)$} {
                set DTMRI(scalars,scaleFactor) 1000
        }
        {^(RelativeAnisotropy|FractionalAnisotropy|Mode|LinearMeasure|PlanarMeasure|SphericalMeasure|ColorByOrientation|ColorByMode|IsotropicP|AnisotropicQ)$} {
                set DTMRI(scalars,scaleFactor) 1000
        }
        }
    }
    
    puts "DTMRI: scale factor $DTMRI(scalars,scaleFactor)"

    # create vtk object to do the operation
    catch "math Delete"
    vtkTensorMathematics math
    math SetScaleFactor $DTMRI(scalars,scaleFactor)
    math SetInput 0 $input
    math SetInput 1 $input
    math SetOperationTo$operation
    # color by RAS orientation, not IJK
    if {$operation == "ColorByOrientation"} {
        vtkTransform transform
        DTMRICalculateIJKtoRASRotationMatrix transform $Tensor(activeID)
        math SetTensorRotationMatrix [transform GetMatrix]
        transform Delete
    }
    math AddObserver StartEvent MainStartProgress
    math AddObserver ProgressEvent "MainShowProgress math"
    math AddObserver EndEvent MainEndProgress
    set Gui(progressText) "Creating Volume $operation"

    # put the filter output into a slicer volume
    math Update
    #puts [[math GetOutput] Print]
    Volume($v,vol) SetImageData [math GetOutput]
    MainVolumesUpdate $v
    # tell the node what type of data so MRML file will be okay
    Volume($v,node) SetScalarType [[math GetOutput] GetScalarType]

    # color operations generate 4 component volumes, so let the node know
    Volume($v,node) SetNumScalars [[math GetOutput] GetNumberOfScalarComponents]
    
    math SetInput 0 ""    
    math SetInput 1 ""
    # this is to disconnect the pipeline
    # this object hangs around, so try this trick from Editor.tcl:
    math SetOutput ""
    math Delete
    
    # reset blue bar text
    set Gui(progressText) ""
  
    # Registration
    # put the new volume inside the same transform as the original tensor
    # by inserting it right after that volume in the mrml file
    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set widx 0} {$widx < $nitems} {incr widx} {
        if { [Mrml(dataTree) GetNthItem $widx] == "Volume($v,node)" } {
            break
        }
    }
    if { $widx < $nitems } {
        Mrml(dataTree) RemoveItem $widx
        Mrml(dataTree) InsertAfterItem Tensor($t,node) Volume($v,node)
        MainUpdateMRML
    }
    
    # display this volume so the user knows something happened
    MainSlicesSetVolumeAll Back $v
    RenderAll
}


