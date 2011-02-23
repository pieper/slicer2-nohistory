#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRISave.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:28 $
#   Version:   $Revision: 1.12 $
# 
#===============================================================================
# FILE:        DTMRISave.tcl
# PROCEDURES:  
#   DTMRISaveInit
#   DTMRISaveBuildGUI
#   DTMRISaveStreamlinesAsModel verbose
#   DTMRIWriteStructuredPoints filename
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC DTMRISaveInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveInit {} {

    global DTMRI

    # Version info for files within DTMRI module
    #------------------------------------
    set m "Save"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.12 $} {$Date: 2006/01/06 17:57:28 $}]

    set DTMRI(Save,type) visualization
    set DTMRI(Save,coords) World
}



#-------------------------------------------------------------------------------
# .PROC DTMRISaveBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveBuildGUI {} {

    global DTMRI Tensor Module Gui Volume

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Save
    #-------------------------------------------

    #-------------------------------------------
    # Save frame
    #-------------------------------------------
    set fSave $Module(DTMRI,fSave)
    set f $fSave
    
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    foreach frame "Top Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    $f.fTop configure  -relief groove -bd 3 
    $f.fBottom configure  -relief groove -bd 3 

    #-------------------------------------------
    # Save->Active frame
    #-------------------------------------------
    set f $fSave.fActive

    # menu to select active DTMRI
    DevAddSelectButton  DTMRI $f ActiveSave "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActiveSave
    lappend Tensor(mActiveList) $f.mbActiveSave.m


    #-------------------------------------------
    # Save->Top frame
    #-------------------------------------------
    set f $fSave.fTop

    foreach frame "Type Coords Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Save->Top->Type frame
    #-------------------------------------------
    set f $fSave.fTop.fType

    DevAddLabel $f.l "Save tracts for:"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    foreach frame "Buttons" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad)
    }

    #-------------------------------------------
    # Save->Top->Type->Buttons frame
    #-------------------------------------------
    set f $fSave.fTop.fType.fButtons

    foreach text {visualization analysis} tip {"Save slicer models (tubes)." "Save tract paths (lines) and tensors."} {
        eval {radiobutton $f.rType$text -text $text -variable DTMRI(Save,type) \
                  -value $text -indicatoron 0 } $Gui(WCA)
        TooltipAdd $f.rType$text $tip
        pack $f.rType$text -side left -padx 0 -pady $Gui(pad)
    }



    #-------------------------------------------
    # Save->Top->Coords frame
    #-------------------------------------------
    set f $fSave.fTop.fCoords

    DevAddLabel $f.l "Coordinate System:"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    foreach frame "Buttons" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) 
    }

    #-------------------------------------------
    # Save->Top->Coords->Buttons frame
    #-------------------------------------------
    set f $fSave.fTop.fCoords.fButtons

    foreach text {Default ScaledIJK CenteredScaledIJK} value {World ScaledIJK CenteredScaledIJK} tip {"What you see in the viewer (World coordinates) is the default.\nChoose this unless you have a specific reason to need another coordinate system." "Coordinates of tensor volume (advanced)." "Centered coordinates (origin in center) of tensor volume (advanced)."} {
        eval {radiobutton $f.rCoords$text -text $text -variable DTMRI(Save,coords) \
                  -value $value -indicatoron 0} $Gui(WCA)
        TooltipAdd $f.rCoords$text $tip
        pack $f.rCoords$text -side left -padx 0 -pady $Gui(pad)
    }

    #-------------------------------------------
    # Save->Top->Apply frame
    #-------------------------------------------
    set f $fSave.fTop.fApply
    DevAddButton $f.bApply "Save Tracts" \
        {puts "Saving streamlines"; DTMRISaveStreamlinesAsModel}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Save tracts to vtk file(s).\nEach color of tract will become a separate model.\n Choose the initial part of the filename, and models\nwill be saved as filename_0.vtk, filename_1.vtk, etc."


    #-------------------------------------------
    # Save->Bottom frame
    #-------------------------------------------
    set f $fSave.fBottom

    DevAddButton $f.bSave "Save Tensors" {DTMRIWriteStructuredPoints $DTMRI(devel,fileName)}
    pack $f.bSave -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bSave "Save tensor data (Active DTMRI) to vtk structured points file format."


}


#-------------------------------------------------------------------------------
# .PROC DTMRISaveStreamlinesAsModel
# Save all streamlines as a vtk model(s).
# Each color is written as a separate model.
# .ARGS
# int verbose default is 1
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveStreamlinesAsModel {{verbose "1"}} {
    global DTMRI Tensor

    # check we have streamlines
    if {[DTMRI(vtk,streamlineControl) GetNumberOfStreamlines] < 1} {
        set msg "There are no tracts to save. Please create tracts first."
        tk_messageBox -message $msg
        return
    }

    # set base filename for all stored files
    set filename [tk_getSaveFile  -title "Save Tracts: Choose Initial Filename"]
    if { $filename == "" } {
        return
    }

    # set name for models in slicer interface
    set modelname [file root [file tail $filename]]

    # get the object that performs saving
    set saveTracts [DTMRI(vtk,streamlineControl) GetSaveTracts]

    # Set whether to save polylines and tensors or just tubes
    if {$DTMRI(Save,type) == "analysis"} {
        $saveTracts SaveForAnalysisOn
    } else {
        $saveTracts SaveForAnalysisOff
    }

    # Set up the coordinate system in which to save
    # World ScaledIJK CenteredScaledIJK
    switch $DTMRI(Save,coords) {
        "World" {
            $saveTracts SetOutputCoordinateSystemToWorld
        }
        "ScaledIJK" {
            $saveTracts SetOutputCoordinateSystemToScaledIJK
        }
        "CenteredScaledIJK" {
            $saveTracts SetOutputCoordinateSystemToCenteredScaledIJK
            set t $Tensor(activeID)
            if {$t != ""} {
                eval {$saveTracts SetExtentForCenteredScaledIJK} \
                    [[Tensor($t,data) GetOutput] GetWholeExtent]
                eval {$saveTracts SetScalingForCenteredScaledIJK} \
                    [[Tensor($t,data) GetOutput] GetSpacing]
            }
        }

    }

    # save the models as well as a MRML file with their colors
    $saveTracts SaveStreamlinesAsPolyData $filename $modelname Mrml(colorTree)

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts and scene file. The filename is: $filename.xml"
        tk_messageBox -message $msg
    }

}

#-------------------------------------------------------------------------------
# .PROC DTMRIWriteStructuredPoints
# Dump DTMRIs to structured points file.  this ignores
# world to RAS, DTMRIs are just written in scaled ijk coordinate system.
# .ARGS
# path filename
# .END
#-------------------------------------------------------------------------------
proc DTMRIWriteStructuredPoints {filename} {
    global DTMRI Tensor

    set t $Tensor(activeID)

    # check we have tensors
    if {$t =="" } {
        set msg "There are no tensors to save."
        tk_messageBox -message $msg
        return
    }

    set filename [tk_getSaveFile -defaultextension ".vtk" -title "Save tensor as vtkStructuredPoints"]
    if { $filename == "" } {
        return
    }

    vtkStructuredPointsWriter writer
    writer SetInput [Tensor($t,data) GetOutput]
    writer SetFileName $filename
    writer SetFileTypeToBinary
    puts "Writing $filename..."
    writer Write
    writer Delete
    puts "Wrote DTMRI data, id $t, as $filename"
}


