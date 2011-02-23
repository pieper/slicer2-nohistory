#=auto==========================================================================
#   Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: LaurenThesisSeedBrain.tcl,v $
#   Date:      $Date: 2008/07/03 18:16:10 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        LaurenThesisSeedBrain.tcl
# PROCEDURES:  
#   LaurenThesisRunWholeDataset
#   LaurenThesisCreateTensors
#   LaurenThesisFindMaskLabelValue
#   LaurenThesisCreateLMMask
#   LaurenThesisSeedEverywhere
#   LaurenThesisSeedAndSaveStreamlinesFromSegmentation verbose
#==========================================================================auto=

proc LaurenThesisSeedBrainInit {} {

    global LaurenThesis Volume


    set LaurenThesis(tTensor) -1
    set LaurenThesis(vMask)  $Volume(idNone)

    set LaurenThesis(subjectID) caseXXX

    set LaurenThesis(seedThreshold) 0.3
    set LaurenThesis(stopThreshold) 0.15

    set LaurenThesis(lengthThreshold) 20

    set LaurenThesis(seedResolution) 2

    set LaurenThesis(doErosion) Yes

    set LaurenThesis(savecL) 0
    set LaurenThesis(saveFA) 1
    set LaurenThesis(saveB0) 0

}


proc LaurenThesisSeedBrainBuildGUI {} {

    global Gui LaurenThesis Module Volume Model

    #-------------------------------------------
    # SeedBrain frame
    #-------------------------------------------
    set fSeedBrain $Module(LaurenThesis,fSeedBrain)
    set f $fSeedBrain
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # SeedBrain->Top frame
    #-------------------------------------------
    set f $fSeedBrain.fTop
    DevAddLabel $f.lHelp "Seed and save tract paths for matlab clustering."
    pack $f.lHelp -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # SeedBrain->Middle frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle
    foreach frame "Tensor Mask Name Seed Stop Isotropic Length Erode Scalars" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # SeedBrain->Middle->Tensor frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fTensor

    # menu to select a volume: will set LaurenThesis(tTensor)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name tTensor
    DevAddSelectButton  LaurenThesis $f $name "Tensor dataset:" Pack \
        "Tensor volume data in which to seed tractography."\
        25

    #-------------------------------------------
    # SeedBrain->Middle->Mask frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fMask

    # menu to select a volume: will set LaurenThesis(vMask)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name vMask
    DevAddSelectButton  LaurenThesis $f $name "Brain Mask:" Pack \
        "Brain or intercranial cavity mask."\
        25


    #-------------------------------------------
    # SeedBrain->Middle->Name frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fName

    # entry box for the name of the volume (i.e. caseD100)
    DevAddLabel $f.lName "Subject ID:"
    eval {entry $f.eName -width 10 \
              -textvariable LaurenThesis(subjectID)} $Gui(WEA)
    
    pack $f.lName $f.eName -side left \
        -padx $Gui(pad) -pady $Gui(pad)

    set tip "Subject identifier for output filenames (no spaces allowed).  Example: caseD102."
    TooltipAdd  $f.eName $tip
    TooltipAdd  $f.lName $tip

    #-------------------------------------------
    # SeedBrain->Middle->Seed frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fSeed

    DevAddLabel $f.lSeedThresh "Seed where cL >"
    eval {entry $f.eSeedThresh -width 4 \
              -textvariable LaurenThesis(seedThreshold)} $Gui(WEA)
    
    pack $f.lSeedThresh $f.eSeedThresh -side left \
        -padx $Gui(pad) -pady $Gui(pad)


    set tip "Linear measure threshold for seeding tractography."
    TooltipAdd  $f.eSeedThresh $tip
    TooltipAdd  $f.lSeedThresh $tip

    #-------------------------------------------
    # SeedBrain->Middle->Stop frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fStop

    DevAddLabel $f.lStopThresh "Stop where cL <"
    eval {entry $f.eStopThresh -width 4 \
              -textvariable LaurenThesis(stopThreshold)} $Gui(WEA)
    
    pack $f.lStopThresh $f.eStopThresh -side left \
        -padx $Gui(pad) -pady $Gui(pad)

    set tip "Linear measure threshold for stopping tractography."
    TooltipAdd  $f.eStopThresh $tip
    TooltipAdd  $f.lStopThresh $tip


    #-------------------------------------------
    # SeedBrain->Middle->Isotropic frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fIsotropic

    DevAddLabel $f.lSeedRes "Seeding Resolution (mm)"
    eval {entry $f.eSeedRes -width 4 \
              -textvariable LaurenThesis(seedResolution)} $Gui(WEA)
 
    eval {checkbutton $f.cJitter -text " Jitter " -variable LaurenThesis(seedJitter) -indicatoron 0 } $Gui(WCA)
 
    pack $f.lSeedRes $f.eSeedRes $f.cJitter -side left \
        -padx $Gui(pad) -pady $Gui(pad)

    set tip "No grid bias: Randomly jitter seed locations up to Seeding Resolution/2"
    TooltipAdd  $f.cJitter $tip

    #-------------------------------------------
    # SeedBrain->Middle->Length frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fLength

    DevAddLabel $f.lLengthThresh "Save if length >"
    eval {entry $f.eLengthThresh -width 4 \
              -textvariable LaurenThesis(lengthThreshold)} $Gui(WEA)
    
    pack $f.lLengthThresh $f.eLengthThresh -side left \
        -padx $Gui(pad) -pady $Gui(pad)

    set tip "Minimum length to save a tractographic path."
    TooltipAdd  $f.eLengthThresh $tip
    TooltipAdd  $f.lLengthThresh $tip


    #-------------------------------------------
    # SeedBrain->Middle->Erode frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fErode

    DevAddLabel $f.lErode "Erode Brain Mask 1x:"

    pack $f.lErode -side left \
        -padx $Gui(pad) -pady $Gui(pad)

    set tip "Use if mask is larger than white matter. Erodes mask once to remove gray/csf at boundary."
    TooltipAdd  $f.lErode $tip

    foreach text {Yes No} tip {"Use if mask is larger than white matter. Erodes mask once to remove gray/csf at boundary." "No erosion of mask."} {
        eval {radiobutton $f.r$text -text $text \
                  -variable LaurenThesis(doErosion) \
                  -value $text -indicatoron 0 } $Gui(WCA)
        TooltipAdd $f.r$text $tip
        pack $f.r$text -side left -padx $Gui(pad) -pady $Gui(pad)
    }
    
    #-------------------------------------------
    # SeedBrain->Middle->Scalars frame
    #-------------------------------------------
    set f $fSeedBrain.fMiddle.fScalars

    DevAddLabel $f.lHelp "Save images also:"

    pack $f.lHelp -side left \
        -padx $Gui(pad) -pady $Gui(pad)

    set tip "Output scalar invariant images as well as tractography."
    TooltipAdd  $f.lHelp $tip

    foreach volume {cL FA B0} {        
        DevAddLabel $f.l$volume "$volume"

        eval {checkbutton $f.c$volume \
                  -variable LaurenThesis(save$volume) -indicatoron 0} $Gui(WCA) \
            -height 1 -width 1

        pack $f.l$volume $f.c$volume -side left \
            -padx $Gui(pad) -pady $Gui(pad)

        TooltipAdd  $f.l$volume $tip
        TooltipAdd  $f.c$volume $tip

    }

    #-------------------------------------------
    # SeedBrain->Bottom frame
    #-------------------------------------------
    set f $fSeedBrain.fBottom

    DevAddButton $f.bApply "Seed Tracts" \
        LaurenThesisValidateParametersAndRunDataset
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Seed tracts in the mask, where thresholds are met."

}




proc LaurenThesisSeedBrainUpdateMRML {} {

    global LaurenThesis

    # Update volume selection widgets if the MRML tree has changed

    DevUpdateNodeSelectButton Tensor LaurenThesis tTensor tTensor \
        DevSelectNode 0 0 0 

    # the one allows labelmaps too
    DevUpdateNodeSelectButton Volume LaurenThesis vMask vMask DevSelectNode 0 0 1 

}






proc LaurenThesisValidateParametersAndRunDataset {} {
    global LaurenThesis Volume

    puts "----------------------------------------------"    

    puts "Validating parameters."

    puts "Tensor volume ID: $LaurenThesis(tTensor)"   

    if {$LaurenThesis(tTensor) == "-1" || $LaurenThesis(tTensor) == ""} {
        puts "Please choose tensor volume before seeding."
        return
    }


    puts "Mask volume ID: $LaurenThesis(vMask)"

    if {$LaurenThesis(vMask) == $Volume(idNone) || $LaurenThesis(vMask) == ""} {
        puts "Please choose mask volume before seeding."
        return
    }

    puts "Subject ID: $LaurenThesis(subjectID)"

    if {$LaurenThesis(subjectID) == "caseXXX"} {
        puts "Please set the subject ID before seeding."
        return
    }

    puts "Seed threshold: $LaurenThesis(seedThreshold)"


    if {[ValidateFloat $LaurenThesis(seedThreshold)] == 0} {
        puts "Seed threshold must be a number between 0 and 1."
        return
    }


    if {$LaurenThesis(seedThreshold) < 0  || $LaurenThesis(seedThreshold) > 1} {
        puts "Seed threshold must be between 0 and 1"
        return
    }

    puts "Stop threshold: $LaurenThesis(stopThreshold)"

    if {[ValidateFloat $LaurenThesis(stopThreshold)] == 0} {
        puts "Stop threshold must be a number between 0 and 1."
        return
    }

    if {$LaurenThesis(stopThreshold) < 0  || $LaurenThesis(stopThreshold) > 1} {
        puts "Stop threshold must be between 0 and 1"
        return
    }



    puts "Seed resolution: $LaurenThesis(seedResolution)"


    if {[ValidateFloat $LaurenThesis(seedResolution)] == 0} {
        puts "Seed resolution must be a floating point number between 0.5 and 5"
        return
    }


    if {$LaurenThesis(seedResolution) < 0.5  || $LaurenThesis(seedResolution) > 5} {
        puts "Seed resolution must be between 0.5 and 5"
        return
    }

    puts "Seed point random jitter: $LaurenThesis(seedJitter)"

    if { !( $LaurenThesis(seedJitter) == 1  || $LaurenThesis(seedJitter) == 0 ) } {
        puts "Seed random jitter must be 0 or 1"
        return
    }

    puts "Length threshold: $LaurenThesis(lengthThreshold)"

    if {[ValidateFloat $LaurenThesis(lengthThreshold)] == 0} {
        puts "Length threshold must be a number (in mm)."
        return
    }

    if {$LaurenThesis(lengthThreshold) < 0 } {
        puts "Length threshold must not be negative."
        return
    }

    if {$LaurenThesis(doErosion) == "Yes" } {
        set doErosion 1
    } else {
        set doErosion 0
    }

    puts "Running dataset $LaurenThesis(subjectID)."
    puts "----------------------------------------------"

    LaurenThesisRunWholeDatasetFromTensors \
        $LaurenThesis(tTensor) \
        $LaurenThesis(vMask) \
        $LaurenThesis(subjectID) \
        $LaurenThesis(seedThreshold) \
        $LaurenThesis(stopThreshold) \
        $LaurenThesis(seedResolution) \
        $LaurenThesis(seedJitter) \
        $LaurenThesis(lengthThreshold) \
        $doErosion \
        $LaurenThesis(savecL) \
        $LaurenThesis(saveFA) \
        $LaurenThesis(saveB0) \


}


proc LaurenThesisRunWholeDatasetFromTensors {tTensor vICCMask dataSetName seedThreshold stopThreshold seedResolution seedJitter lengthThreshold doErosion {savecL 0} {saveFA 0} {saveB0 0}} {

    # find the label for the intercranial cavity mask
    set maskLabel [LaurenThesisFindMaskLabelValue $vICCMask]

    # create linear measure mask in which to seed
    set vLMMask [LaurenThesisCreateLMMask $vICCMask $maskLabel $tTensor $seedThreshold $doErosion]


    # seed everywhere in this mask (second mask is for cL/FA volume creation)
    set directory [LaurenThesisSeedEverywhere $vLMMask $tTensor $dataSetName $stopThreshold $seedResolution $seedJitter $lengthThreshold $savecL $saveFA $vICCMask $saveB0 $doErosion]

    # Save our settings
    set fid [open [file join $directory "TractographySettings_$dataSetName.txt"] w]

    puts $fid "subjectID: $dataSetName"
    puts $fid "seedThreshold: $seedThreshold"
    puts $fid "stopThreshold: $stopThreshold"
    puts $fid "seedResolution: $seedResolution"
    puts $fid "seedJitter: $seedJitter"
    puts $fid "lengthThreshold: $lengthThreshold"

    close $fid

}


proc LaurenThesisRunWholeDatasetFromGradientVolume {vGradient vICCMask dataSetName seedThreshold stopThreshold lengthThreshold } {

    # convert volume to tensors
    set tTensor [LaurenThesisCreateTensors $vGradient]

    LaurenThesisRunWholeDatasetFromTensors $tTensor $vICCMask \
        $dataSetName $seedThreshold $stopThreshold $lengthThreshold

}


#-------------------------------------------------------------------------------
# .PROC LaurenThesisCreateTensors
# Convert volume vTensor to tensors. Assumes BWH data (BWH_6g.1bSlice).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisCreateTensors {vTensor} {
    
    global DTMRI Tensor

    # imitate the GUI
    set DTMRI(convertID) $vTensor
    set DTMRI(selectedpattern) BWH_6g.1bSlice

    # call the code
    ConvertVolumeToTensors

    # return the ID of the new tensors
    # assume it is at the end of the ID list
    return [lindex $Tensor(idList) end]
}

#-------------------------------------------------------------------------------
# .PROC LaurenThesisFindMaskLabelValue
# Find the highest value in the labelmap, assume this is the mask value.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisFindMaskLabelValue {vMask} {

    # assume just 2 values, 0 and label
    set values [[Volume($vMask,vol) GetOutput] GetScalarRange]
    set label [lindex $values 1]
    #puts $label
    return $label
}

#-------------------------------------------------------------------------------
# .PROC LaurenThesisCreateLMMask
# Take the mask (inter-cranial cavity), erode 1 time, calculate the 
# linear measure volume, then threshold it.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisCreateLMMask {vICCMask maskLabel tTensor seedThreshold doErosion {display 1}} {

    global Volume Tensor Lut

    set cLThreshold [expr $seedThreshold * 1000]

    # if we are requested to erode, do it 

    if {$doErosion == "1" } {
        # first we want to erode the ICC mask 
        foreach e { 0 } {
            catch {vtkImageErode _erode$e}
            _erode$e SetForeground $maskLabel
            _erode$e SetBackground "0"
            _erode$e SetNeighborTo8
        }
        
        _erode0 SetInput [Volume($vICCMask,vol) GetOutput]
        puts "Eroding..."
        _erode0 Update
    }

    # Now we use this as the mask for computing the linear measure
    vtkTensorMask _mask
    if {$doErosion == "1" } {
        _mask SetMaskInput [_erode0 GetOutput]
        _erode0 Delete        
    } else {
        _mask SetMaskInput [Volume($vICCMask,vol) GetOutput]
    }
    _mask SetImageInput [Tensor($tTensor,data) GetOutput]
    puts "Masking..."
    _mask Update

    vtkTensorMathematics _math
    _math SetScaleFactor 1000
    _math SetInput 0 [_mask GetOutput]
    _math SetInput 1 [_mask GetOutput]

    _math SetOperationToLinearMeasure
    puts "Calculating linear anisotropy measure..."    
    _math Update

    # Now we threshold this masked linear measure
    vtkImageThreshold _thresh
    _thresh ThresholdBetween $cLThreshold 1000
    _thresh SetReplaceIn 1
    _thresh SetReplaceOut 1
    # pick 10 so we can see it well in slicer, the number is not important
    _thresh SetInValue 10
    _thresh SetOutValue 0
    _thresh SetInput [_math GetOutput]

    puts "Thresholding..."
    _thresh Update


    puts "Exporting results to MRML tree..."
    # this is now the volume we want to use for seeding.
    # make it into a slicer volume so it is available
    set name [Tensor($tTensor,node) GetName]

    set name LinearMeasure_$name
    set description "Linear measure volume derived from DTMRI volume $name"
    set v [DTMRICreateEmptyVolume $tTensor $description $name]
    Volume($v,vol) SetImageData [_math GetOutput]
    MainVolumesUpdate $v
    # tell the node what type of data so MRML file will be okay
    Volume($v,node) SetScalarType [[_math GetOutput] GetScalarType]
    
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
        Mrml(dataTree) InsertAfterItem Tensor($tTensor,node) Volume($v,node)
        MainUpdateMRML
    }
    

    # display this volume so the user knows something happened
    # this is slow so make it optional
    if {$display == 1} {
        MainSlicesSetVolumeAll Back $v
    }



    set name Mask_${cLThreshold}_$name
    set description "Masked Linear measure ($cLThreshold) volume derived from DTMRI volume $name"
    set v [DTMRICreateEmptyVolume $tTensor $description $name]
    Volume($v,vol) SetImageData [_thresh GetOutput]
    MainVolumesUpdate $v
    # tell the node what type of data so MRML file will be okay
    Volume($v,node) SetScalarType [[_thresh GetOutput] GetScalarType]
    Volume($v,node) SetLabelMap 1
    Volume($v,node) InterpolateOff
    Volume($v,node) SetLUTName  $Lut(idLabel)

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
        Mrml(dataTree) InsertAfterItem Tensor($tTensor,node) Volume($v,node)
        MainUpdateMRML
    }

    # display this volume so the user knows something happened
    puts "Displaying volume"
    # this is slow so make it optional
    if {$display == 1} {
        MainSlicesSetVolumeAll Fore $v
        MainSlicesSetVolumeAll Label $v
        RenderAll
    }

    # Now delete temporary objects
    puts "Deleting temporary objects..."
    _math SetInput 0 ""    
    _math SetInput 1 ""
    _math SetOutput ""
    _math Delete

    #_erode1 Delete
    #_erode2 Delete
    _mask Delete
    _thresh Delete


    
    puts "Done."

    return $v
}


proc LaurenThesisSaveScalarVolume {volumeType tTensor vBrainMask directory {doErosion 0}} {
    global Volume Tensor


    # All volumes are saved to disk
    set filename [file join $directory $volumeType]
    catch {vtkImageWriter _writer}
    _writer SetFilePrefix $filename
    _writer SetFilePattern "%s.%04d"
    _writer SetFileDimensionality 2

    # If we have to calculate invariants from the tensors
    if {  $volumeType == "cL" ||  $volumeType == "FA" } {    
        
        # erode mask if requested
        if {$doErosion == "1" } {

            set values [[Volume($vBrainMask,vol) GetOutput] GetScalarRange]
            set maskLabel [lindex $values 1]

            catch {vtkImageErode _erode}
            _erode SetForeground $maskLabel
            _erode SetBackground "0"
            _erode SetNeighborTo4
            _erode SetInput [Volume($vBrainMask,vol) GetOutput]
            puts "Eroding..."
            _erode Update

        }

        # We mask all volumes before saving
        catch { vtkTensorMask _mask}
        if {$doErosion == "1" } {
            _mask SetMaskInput [_erode GetOutput]
        } else {
            _mask SetMaskInput [Volume($vBrainMask,vol) GetOutput]
        }
        _mask SetImageInput [Tensor($tTensor,data) GetOutput]
        puts "Masking..."
        _mask Update

        
        catch { vtkTensorMathematics _math}
        # The values are scaled by 1000
        # since we need to save as short data.
        _math SetScaleFactor 1000
        _math SetInput 0 [_mask GetOutput]
        _math SetInput 1 [_mask GetOutput]
        
        switch $volumeType {
            "cL" {
                _math SetOperationToLinearMeasure
                puts "Calculating linear anisotropy measure (cL)..."    
            }
            "FA" {
                _math SetOperationToFractionalAnisotropy
                puts "Calculating fractional anisotropy measure (FA)..."    
            }
        }
        
        _math Update


        # sadly we need to output to short for compatibility
        # with other programs (lilla registration, xv).
        catch {vtkImageCast _cast}
        _cast SetOutputScalarTypeToShort
        _cast SetInput [_math GetOutput] 
        _cast Update
        _writer SetInput [_cast GetOutput]

        puts "Saving anisotropy images..."
        _writer Write        
        puts "Done saving anisotropy images..."

        # Delete objects 
        # (they don't actually go away until writer is deleted)
        catch { _cast Delete }
        catch { _math Delete }
        catch { _mask Delete }

    } else {

        # we must be saving the B0 image
        
        # This assumes current image naming conventions in slicer.
        # (as of Feb, 2006)
        # Find the image based on the fact that its name
        # is the same as the tensor volume, with _Tensor removed
        # and _Baseline appended.
        # If we can't find it, just print an error.

        set name [Tensor($tTensor,node) GetName]

        # name we are looking for
        set B0Name [regsub "_Tensor" ${name} "_Baseline"]

        set found 0

        foreach  v $Volume(idList) {
            
            set node Volume($v,node)

            #puts "$v: [$node GetName]"
            
            if {[$node GetName] == $B0Name } {
                set found 1
                break
            }
            
        }

        if {$found == 0 } {
            puts "ERROR: Volume $B0Name not found, not saving B0 image"
            # now we will go to the end of this proc and delete
            # the objects
        } else {
            
            # We found it, so save it to disk


            # In case this has been averaged and is not short:
            # sadly we need to output to short for compatibility
            # with other programs (lilla registration, xv).
            catch { vtkImageCast _cast}
            _cast SetOutputScalarTypeToShort
            _cast SetInput [Volume($v,vol) GetOutput] 
            _cast Update

            # We mask all volumes before saving
            #catch { vtkImageMask _mask }
            #_mask SetMaskInput [Volume($vBrainMask,vol) GetOutput]
            ##_mask SetImageInput [_cast GetOutput] 
            #_mask SetImageInput [_cast GetOutput] 
            #puts "Masking..."
            #_mask Update

            _writer SetInput [_cast GetOutput]

            puts "Saving B0 images..."
            _writer Write        
            puts "Done saving B0 images..."            
            
            #catch { _mask Delete }
            catch { _cast Delete }

        }
        
    }



    # Delete objects we created before the if statements above
    catch { _writer Delete }

}




#-------------------------------------------------------------------------------
# .PROC LaurenThesisSeedEverywhere
# Seed everywhere in the mask.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisSeedEverywhere {vSeedMask tTensor dataSetName stopThreshold seedResolution seedJitter lengthThreshold {savecL 0} {saveFA 0} {vBrainMask -1} {saveB0 0} {doErosion 0}} {
    global DTMRI
    

    # assume the correct tensor ID is already active.

    # imitate the GUI
    # 10 was chosen for mask so we can see it well in slicer
    set DTMRI(ROILabel) 10

    # imitate the GUI
    # set up tractography parameters
    set DTMRI(stream,StoppingBy) LinearMeasure
    #set DTMRI(stream,StoppingThreshold) 0.25
    set DTMRI(stream,StoppingThreshold) $stopThreshold


    # Directly set the seeding resolution in the vtk object
    [DTMRI(vtk,streamlineControl) GetSeedTracts] IsotropicSeedingOn
    [DTMRI(vtk,streamlineControl) GetSeedTracts] SetIsotropicSeedingResolution \
        $seedResolution

    # Turn on jitter if requested
    if { $seedJitter == 1 } {
        [DTMRI(vtk,streamlineControl) GetSeedTracts] RandomGridOn
    }

    # Directly set the length threshold in the vtk object
    [DTMRI(vtk,streamlineControl) GetSeedTracts] SetMinimumPathLength \
        $lengthThreshold

    # call the code
    LaurenThesisSeedAndSaveStreamlinesFromSegmentation $tTensor $vSeedMask $dataSetName $savecL $saveFA $vBrainMask $saveB0 $doErosion
}


#-------------------------------------------------------------------------------
# .PROC LaurenThesisSeedAndSaveStreamlinesFromSegmentation
# Seeds streamlines at all points in a segmentation.
# This does not display anything, just one by one seeds
# the streamline and saves it to disk. So nothing is 
# visualized, this is for exporting files only.
# (Actually displaying all of the streamlines would be impossible
# with a whole brain ROI.)
# .ARGS
# int verbose Defaults to 1
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisSeedAndSaveStreamlinesFromSegmentation {t v {filename ""} {savecL 0} {saveFA 0} {vBrainMask -1} {saveB0 0} {doErosion 0} {verbose 0}} {
    global DTMRI Label Tensor Volume

    set returnValue ""

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return $returnValue
        }

    }

    if {$filename == ""} {
        # set base filename for all stored files
        set filename [tk_getSaveFile  -title "Save Tracts: Choose Initial Filename"]
        if { $filename == "" } {
            return $returnValue
        }
    }

    # cast to short (as these are labelmaps the values are really integers
    # so this prevents errors with float labelmaps which come from editing
    # scalar volumes derived from the tensors).
    catch {vtkImageCast castVSeedROI}
    castVSeedROI SetOutputScalarTypeToShort
    castVSeedROI SetInput [Volume($v,vol) GetOutput] 
    castVSeedROI Update

    # make a subdirectory for them, named the same as the files                            
    set name [file root [file tail $filename]]
    set dir [file dirname $filename]
    set newdir [file join $dir tract_files_$name]
    file mkdir $newdir
    set filename [file join $newdir $name]
    # make a subdirectory for the vtk models                                               
    set newdir2 [file join $newdir vtk_model_files]
    file mkdir $newdir2
    set filename2 [file join $newdir2 $name]

    # Return the directory we created
    set returnValue $newdir

    # ask for user confirmation first
    if {$verbose == "1"} {
        set name [Volume($v,node) GetName]
        set msg "About to seed streamlines in all labelled voxels of volume $name.  This may take a while, so make sure the Tracts settings are what you want first. Go ahead?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return $returnValue
        }
    }


    # save the cL and FA volumes if requested
    # make a subdirectory for them
    if {  $savecL == "1" ||  $saveFA == "1" ||  $saveB0 == "1" } {
        set newdir3 [file join $newdir anisotropyAndOrB0Images]
        file mkdir $newdir3
    }

    if {$savecL == 1} {
        LaurenThesisSaveScalarVolume cL $t $vBrainMask $newdir3 $doErosion
    }
    if {$saveFA == 1} {
        LaurenThesisSaveScalarVolume FA $t $vBrainMask $newdir3 $doErosion
    }
    if {$saveB0 == 1} {
        LaurenThesisSaveScalarVolume B0 $t $vBrainMask $newdir3 $doErosion
    }


    # make sure the settings are current for the models we save to disk              
    #DTMRIUpdateTractColor                                                          
    DTMRIUpdateStreamlineSettings

    # set up the input segmented volume
    set seedTracts [DTMRI(vtk,streamlineControl) GetSeedTracts]
    $seedTracts SetInputROI [castVSeedROI GetOutput] 
    $seedTracts SetInputROIValue $DTMRI(ROILabel)

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($v,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    $seedTracts SetROIToWorld transform
    transform Delete

    # create all streamlines
    puts "Starting to seed streamlines. Files will be $filename*.*"
    $seedTracts SeedAndSaveStreamlinesInROI \
        $filename  $filename2

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts. The filename is: $filename*.*"
        tk_messageBox -message $msg
    }

    castVSeedROI Delete

    # return directory name for saving settings file(s)
    return $returnValue
}


