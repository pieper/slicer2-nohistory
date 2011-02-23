#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRIVoxelizeTracts.tcl,v $
#   Date:      $Date: 2006/03/06 21:07:30 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        DTMRIVoxelizeTracts.tcl
# PROCEDURES:  
#   DTMRIVoxelizeTractsBuildGUI
#   DTMRIVoxelizeTractsColorROIFromTracts
#==========================================================================auto=

proc DTMRIVoxelizeTractsInit {} {

    global DTMRI Volume

    # Version info for files within DTMRI module
    #------------------------------------
    set m "VoxelizeTracts"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.4 $} {$Date: 2006/03/06 21:07:30 $}]

    set DTMRI(VoxTractsROILabelmap) $Volume(idNone)
}



#-------------------------------------------------------------------------------
# .PROC DTMRIVoxelizeTractsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIVoxelizeTractsBuildGUI {} {

    global DTMRI Tensor Module Gui Volume

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Vox
    #-------------------------------------------

    #-------------------------------------------
    # Vox frame
    #-------------------------------------------
    set fVox $Module(DTMRI,fVox)
    set f $fVox
    
    foreach frame "Top Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    $f.fBottom configure  -relief groove -bd 3 


    #-------------------------------------------
    # Vox->Top frame
    #-------------------------------------------
    set f $fVox.fTop

    frame $f.fLabel -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fLabel -side top -padx $Gui(pad) -pady $Gui(pad) -fill x


    #-------------------------------------------
    # Vox->Top->Label frame
    #-------------------------------------------
    set f $fVox.fTop.fLabel

    DevAddLabel $f.lInfo "Color Voxels from Tracts"
    eval {$f.lInfo configure} $Gui(BLA)
    pack $f.lInfo -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Vox->Bottom frame
    #-------------------------------------------
    set f $fVox.fBottom

    foreach frame "ROI Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Vox->Bottom->ROI frame
    #-------------------------------------------
    set f $fVox.fBottom.fROI
    
    # menu to select a volume: will set DTMRI(VoxTractsROILabelmap)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name VoxTractsROILabelmap
    DevAddSelectButton  DTMRI $f $name "ROI to color:" Pack \
        "The region of interest in which to label voxels according to tract count."\
        13

    #-------------------------------------------
    # Vox->Bottom->Apply frame
    #-------------------------------------------
    set f $fVox.fBottom.fApply
    DevAddButton $f.bApply "Color ROI from tracts" \
        {puts "Coloring ROI"; DTMRIVoxelizeTractsColorROIFromTracts}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "First count the times each tract path passes through each voxel. Then color the ROI according to the tract which has the most paths traversing the voxel."




}

#-------------------------------------------------------------------------------
# .PROC DTMRIVoxelizeTractsColorROIFromTracts
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIVoxelizeTractsColorROIFromTracts {} {
    global DTMRI Label Volume

    set v $DTMRI(VoxTractsROILabelmap)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }
    # cast to short (as these are labelmaps the values are really integers
    # so this prevents errors with float labelmaps which come from editing
    # scalar volumes derived from the tensors).
    catch "castVSeedROI Delete"
    vtkImageCast castVSeedROI
    castVSeedROI SetOutputScalarTypeToShort
    castVSeedROI SetInput [Volume($v,vol) GetOutput] 
    castVSeedROI Update

    # set up the input segmented volume
    set ColorROIFromTracts [DTMRI(vtk,streamlineControl) GetColorROIFromTracts]

    $ColorROIFromTracts SetInputROIForColoring [castVSeedROI GetOutput] 
    castVSeedROI Delete
    #$ColorROIFromTracts SetInputROIValue $DTMRI(ROILabel)

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($v,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    $ColorROIFromTracts SetROIToWorld transform
    transform Delete

    $ColorROIFromTracts ColorROIFromStreamlines

    set output [$ColorROIFromTracts GetOutputROIForColoring]

    # export output to the slicer environment:
    # slicer MRML volume creation and display
    set v2 [DevCreateNewCopiedVolume $v "Color back from clusters" "TractColors_$v"]
    Volume($v2,vol) SetImageData $output
    MainVolumesUpdate $v2
    # tell the node what type of data so MRML file will be okay
    Volume($v2,node) SetScalarType [$output GetScalarType]
    # display this volume so the user knows something happened
    MainSlicesSetVolumeAll Fore $v2
    RenderAll
}

