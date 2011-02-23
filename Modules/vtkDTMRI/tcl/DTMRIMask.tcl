#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRIMask.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:28 $
#   Version:   $Revision: 1.15 $
# 
#===============================================================================
# FILE:        DTMRIMask.tcl
# PROCEDURES:  
#   DTMRIMaskInit
#   DTMRIMaskBuildGUI
#   DTMRIUpdateMaskLabel
#   DTMRIUpdateMaskLabelFromShowLabels
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC DTMRIMaskInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIMaskInit {} {
    
    global DTMRI Volume Label

    # Version info for files within DTMRI module
    #------------------------------------
    set m "Mask"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.15 $} {$Date: 2006/01/06 17:57:28 $}]

    # type of masking to use to reduce volume of DTMRIs
    set DTMRI(mode,mask) None
    set DTMRI(mode,maskList) {None MaskWithLabelmap}
    set DTMRI(mode,maskList,tooltips) {{No masking.  Display all DTMRIs.} {Only display DTMRIs where the mask labelmap shows the chosen label value.}}
    set DTMRI(mode,maskLabel,tooltip) "The ROI colored with this label will be used to mask DTMRIs.  DTMRIs will be shown only inside the ROI."

    # labelmap to use as mask
    set DTMRI(MaskLabelmap) $Volume(idNone)
    # label value indicating mask voxels
    set DTMRI(MaskLabel) $DTMRI(defaultLabel)
    # Name of this label/color
    set DTMRI(MaskLabelName) ""
    # Color ID corresponding to the label
    set DTMRI(MaskLabelColorID) ""

}


#-------------------------------------------------------------------------------
# .PROC DTMRIMaskBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIMaskBuildGUI {} {

    global DTMRI Tensor Volume Module Gui Label

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # ROI
    #    Active
    #    Mask
    #       Label
    #       Mode
    #       Volume
    #       ChooseLabel
    #       Label
    #       Label
    #-------------------------------------------


    set fROI $Module(DTMRI,fROI)
    set f $fROI

    #-------------------------------------------
    # ROI frame
    #-------------------------------------------
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    foreach frame "Mask" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
        $f.f$frame config -relief groove -bd 3
    }

    #-------------------------------------------
    # ROI->Active frame
    #-------------------------------------------
    set f $fROI.fActive

    # menu to select active DTMRI
    DevAddSelectButton  DTMRI $f ActiveMask "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActiveMask
    lappend Tensor(mActiveList) $f.mbActiveMask.m

    #-------------------------------------------
    # ROI->Mask frame
    #-------------------------------------------
    set f $fROI.fMask

    foreach frame "Label Mode Volume ChooseLabel" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # ROI->Mask->Label frame
    #-------------------------------------------
    set f $fROI.fMask.fLabel

    DevAddLabel $f.l "DTMRI Mask Settings"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ROI->Mask->Mode frame
    #-------------------------------------------
    set f $fROI.fMask.fMode

    DevAddLabel $f.l "Mask:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach vis $DTMRI(mode,maskList) tip $DTMRI(mode,maskList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,mask) \
          -command {DTMRIUpdate} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }    

    #-------------------------------------------
    # ROI->Mask->Volume frame
    #-------------------------------------------
    set f $fROI.fMask.fVolume

    # menu to select a volume: will set DTMRI(MaskLabelmap)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name MaskLabelmap
    DevAddSelectButton  DTMRI $f $name "Mask Labelmap:" Pack \
        "Select a labelmap volume to use as a mask.\nDTMRIs will be displayed only where the label matches the label you select below." \
        13
    
    #-------------------------------------------
    # ROI->Mask->ChooseLabel frame
    #-------------------------------------------
    set f $fROI.fMask.fChooseLabel

    # mask label
    eval {button $f.bOutput -text "Label:" \
          -command "ShowLabels DTMRIUpdateMaskLabelFromShowLabels"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
          -textvariable DTMRI(MaskLabel)} $Gui(WEA)
    bind $f.eOutput <Return>   "DTMRIUpdateMaskLabel"
    eval {entry $f.eName -width 14 \
          -textvariable DTMRI(MaskLabelName)} $Gui(WEA) \
            {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    
    # save for changing color later
    set DTMRI(MaskLabelWidget) $f.eName
    
    TooltipAdd  $f.bOutput $DTMRI(mode,maskLabel,tooltip)
    TooltipAdd  $f.eOutput $DTMRI(mode,maskLabel,tooltip)
    TooltipAdd  $f.eName $DTMRI(mode,maskLabel,tooltip)

}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMaskLabel
# If we are masking the glyphs to display a subvolume and
# the user requests a new mask label value this is called. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMaskLabel {} {

    global DTMRI

    DTMRIUpdateLabelWidget MaskLabel

    # this label becomes 1 in the mask
    set thresh DTMRI(vtk,mask,threshold)
    $thresh ThresholdBetween $DTMRI(MaskLabel) $DTMRI(MaskLabel)

    # Update pipelines
    Render3D
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMaskLabelFromShowLabels
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMaskLabelFromShowLabels {} {

    global Label DTMRI

    LabelsFindLabel

    set DTMRI(MaskLabel) $Label(label)

    DTMRIUpdateMaskLabel
}
