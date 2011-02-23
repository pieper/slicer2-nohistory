#=auto==========================================================================
# (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors.
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for  
# research purposes only, provided that (1) the above copyright notice and 
# the following four paragraphs appear on all copies of this software, and 
# (2) that source code to any modifications to this software be made 
# publicly available under terms no more restrictive than those in this 
# License Agreement. Use of this software constitutes acceptance of these 
# terms and conditions.
# 
# 3D Slicer Software has not been reviewed or approved by the Food and 
# Drug Administration, and is for non-clinical, IRB-approved Research Use 
# Only.  In no event shall data or images generated through the use of 3D 
# Slicer Software be used in the provision of patient care.
# 
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
# ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
# DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
# EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
# OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
# NON-INFRINGEMENT.
# 
# THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
# 
# 
#===============================================================================
# FILE:        IbrowserMotionCorrect.tcl
# PROCEDURES:  
#   IbrowserBuildMotionCorrectGUI
#   IbrowserUpdateMotionCorrectGUI
#   IbrowserUpdateMotionCorrectReference
#   IbrowserMotionCorrectStop
#   IbrowserSetCoarseParam
#   IbrowserSetFairParam
#   IbrowserSetGoodParam
#   IbrowserSetBestParam
#   IbrowserMotionCorrectGo
#   IbrowserHardenTransforms
#   IbrowserHelpMotionCorrection
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildMotionCorrectGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildMotionCorrectGUI { f master } {
    global Gui

    #--- set global variables for frame so we can raise it,
    #--- and specification params
    set ::Ibrowser(fProcessMotionCorrect) $f
    set ::Ibrowser(Process,MotionCorrectQuality) 1
    set ::Ibrowser(Process,MotionCorrect,Hardened) 0
    set ::Ibrowser(Process,MotionCorrectIterate) 0
    set ::Ibrowser(Process,InternalReference) $::Volume(idNone)
    set ::Ibrowser(Process,ExternalReference) $::Volume(idNone)

    frame $f.fOverview -bg $Gui(activeWorkspace) -bd 2 
    frame $f.fInput -bg $Gui(activeWorkspace) -bd 2 
    frame $f.fModel -bg $Gui(activeWorkspace) -bd 2 -relief groove
    frame $f.fResample -bg $Gui(activeWorkspace) -bd 2 -relief groove

    #---------------------------------------------------------------------------
    #---CHOOSE VOLUMES FRAME

    #--- create menu buttons and associated menus...
    set ff $f.fOverview
    DevAddButton $ff.bHelp "?" "IbrowserHelpMotionCorrection" 2 
    eval { label $ff.lOverview -text \
               "Register interval's volumes to reference." } $Gui(WLA)
    grid $ff.bHelp $ff.lOverview -pady 1 -padx 1 -sticky w
    
    set ff $f.fInput
    eval { label $ff.lChooseProcInterval -text "interval:" } $Gui(WLA)
    eval { menubutton $ff.mbIntervals -text "none" \
               -relief raised -bd 2 -width 18 \
               -menu $ff.mbIntervals.m -indicatoron 1 } $::Gui(WMBA)
    eval { menu $ff.mbIntervals.m } $::Gui(WMA)
    foreach i $::Ibrowser(idList) {
        $ff.mbIntervals.m add command -label $::Ibrowser($i,name) \
        -command "IbrowserSetActiveInterval $i"
    }
    set ::Ibrowser(Process,MotionCorrect,mbIntervals) $ff.mbIntervals
    bind $::Ibrowser(Process,MotionCorrect,mbIntervals) <ButtonPress-1> "IbrowserUpdateMotionCorrectGUI"
    set ::Ibrowser(Process,MotionCorrect,mIntervals) $ff.mbIntervals.m
    grid $ff.lChooseProcInterval $ff.mbIntervals -pady 1 -padx $::Gui(pad) -sticky e
    grid $ff.mbIntervals -sticky e
    
    eval { label $ff.lReference -text "reference:" } $Gui(WLA)
    eval { menubutton $ff.mbReference -text "none" \
               -relief raised -bd 2 -width 18 -indicatoron 1 \
               -menu $ff.mbReference.m } $::Gui(WMBA)
    eval { menu $ff.mbReference.m } $::Gui(WMA)
    foreach i $::Ibrowser(idList) {
        $ff.mbReference.m add command -label $::Ibrowser($i,name) \
            -command ""
    }
    set ::Ibrowser(Process,MotionCorrect,mbReference) $ff.mbReference
    bind $::Ibrowser(Process,MotionCorrect,mbReference) <ButtonPress-1> "IbrowserUpdateMotionCorrectReference"
    set ::Ibrowser(Process,MotionCorrect,mReference) $ff.mbReference.m
    grid $ff.lReference $ff.mbReference -pady 1 -padx $::Gui(pad) -sticky e
    grid $ff.mbReference -sticky e
    
    #---------------------------------------------------------------------------
    #---QUALITY AND ITERATION FRAME
    set ff $f.fModel
    eval { label $ff.lQuality -text "quality:" } $Gui(WLA)
    eval { label $ff.lBlank -text "" } $Gui(WLA)
    eval { radiobutton $ff.rQualityCoarse -indicatoron 1\
               -text "coarse" -value "Coarse" -variable ::VersorMattesMIRegistration(Objective) \
               -command "IbrowserSetCoarseParam"
           } $Gui(WCA)
    grid $ff.lQuality $ff.rQualityCoarse -padx $Gui(pad) -sticky w
    
    eval { radiobutton $ff.rQualityFair -indicatoron 1\
               -text "fair" -value "Fine" -variable ::VersorMattesMIRegistration(Objective) \
               -command "IbrowserSetFairParam"
           } $Gui(WCA)
    grid $ff.lBlank $ff.rQualityFair -padx $Gui(pad) -sticky w
    
    eval { radiobutton $ff.rQualityGood -indicatoron 1\
               -text "good (slow)" -value "Slow" -variable ::VersorMattesMIRegistration(Objective) \
               -command "IbrowserSetGoodParam"
           } $Gui(WCA)
    grid $ff.lBlank $ff.rQualityGood -padx $Gui(pad) -sticky w
    
    eval { radiobutton $ff.rQualityBest -indicatoron 1\
               -text "best (very slow)" -value "VerySlow" -variable ::VersorMattesMIRegistration(Objective) \
               -command "IbrowserSetBestParam"
           } $Gui(WCA)
    grid $ff.lBlank $ff.rQualityBest -padx $Gui(pad) -sticky w

    DevAddButton $ff.bGo "Run" "IbrowserMotionCorrectGo $ff.bGo" 8
    grid $ff.lBlank $ff.bGo -padx $Gui(pad) -pady $Gui(pad) -sticky w
    set ::Ibrowser(Process,MotionCorrect,Go) $ff.bGo
    
    #---------------------------------------------------------------------------
    #---HARDEN TRANSFORMS FRAME
    set ff $f.fResample
    DevAddButton $ff.bCancel "Cancel" "IbrowserRemoveNonReferenceTransforms" 8
    DevAddButton $ff.bApply "Apply transforms" "IbrowserHardenTransforms" 8
    pack $ff.bCancel $ff.bApply -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    

    pack $f.fOverview $f.fInput $f.fModel $f.fResample -side top -pady $Gui(pad) -padx $Gui(pad) -fill both

    #--- Place the whole collection of widgets in the
    #--- process-specific raised GUI panel.
    place $f -in $master -relheight 1.0 -relwidth 1.0
}





#-------------------------------------------------------------------------------
# .PROC IbrowserSetCoarseParam
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetCoarseParam { } {
    VersorMattesMIRegistrationCoarseParam
    set ::RigidIntensityRegistration(Repeat) 0
    set ::VersorMattesMIRegistration(UpdateIterations) "100"
    set ::VersorMattesMIRegistration(MinimumStepLength) ".001"
    set ::VersorMattesMIRegistration(MaximumStepLength) "2.0"
}




#-------------------------------------------------------------------------------
# .PROC IbrowserSetFairParam
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetFairParam { } {
    VersorMattesMIRegistrationFineParam
    set ::RigidIntensityRegistration(Repeat) 0
    set ::VersorMattesMIRegistration(UpdateIterations) "100 200"
    set ::VersorMattesMIRegistration(MinimumStepLength) ".001 .01"
    set ::VersorMattesMIRegistration(MaximumStepLength) "2.0 1.0"
}



#-------------------------------------------------------------------------------
# .PROC IbrowserSetGoodParam
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetGoodParam { } {
    VersorMattesMIRegistrationGSlowParam
    set ::RigidIntensityRegistration(Repeat) 0
    set ::VersorMattesMIRegistration(UpdateIterations) "500 1000 100" 
    set ::VersorMattesMIRegistration(MinimumStepLength) ".02 .01 .001"
    set ::VersorMattesMIRegistration(MaximumStepLength) "4.0 1.0 0.75"
}



#-------------------------------------------------------------------------------
# .PROC IbrowserSetBestParam
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetBestParam { } {
    VersorMattesMIRegistrationVerySlowParam
    set ::RigidIntensityRegistration(Repeat) 0
    set ::VersorMattesMIRegistration(UpdateIterations) "1000 1000 1000"
    set ::VersorMattesMIRegistration(MinimumStepLength) ".01 .001 .005"
    set ::VersorMattesMIRegistration(MaximumStepLength) "4.0 1.0 0.5"
}




#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateMotionCorrectGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateMotionCorrectGUI { } {

    if { [info exists ::Ibrowser(Process,MotionCorrect,mIntervals) ] } {
        #--- configure interval selection menu
        set m $::Ibrowser(Process,MotionCorrect,mIntervals)
        set mb $::Ibrowser(Process,MotionCorrect,mbIntervals)
        set mbR $::Ibrowser(Process,MotionCorrect,mbReference)
        $m delete 0 end
        foreach id $::Ibrowser(idList) {
            $m add command -label $::Ibrowser($id,name)  \
                -command "IbrowserSetActiveInterval $id;
                     IbrowserProcessingSelectInternalReference none $::Volume(idNone);
                     $mbR config -text none"
        }
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateMotionCorrectReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateMotionCorrectReference { } {
    
    if { [info exists ::Ibrowser(Process,MotionCorrect,mReference) ] } {    
        #--- configure reference selection menu and menubutton
        set m $::Ibrowser(Process,MotionCorrect,mReference)
        $m delete 0 end
        set id $::Ibrowser(activeInterval)
        if { $id == $::Ibrowser(idNone) } {
            set mb $::Ibrowser(Process,MotionCorrect,mbReference)
            $mb configure -text $::Ibrowser(${::Ibrowser(idNone)},name)
        } else {
            set mb $::Ibrowser(Process,MotionCorrect,mbReference)
            set start $::Ibrowser($::Ibrowser(activeInterval),firstMRMLid)
            set stop $::Ibrowser($::Ibrowser(activeInterval),lastMRMLid)
            set count 0
            #---build selections; all volumes in an interval
            set vname "none"
            $m add command -label $vname \
                -command "IbrowserProcessingSelectInternalReference $vname $::Volume(idNone)"
            for { set i $start } { $i <= $stop } { incr i } {
                set vname [ ::Volume($i,node) GetName ]
                $m add command -label $vname \
                    -command "IbrowserProcessingSelectInternalReference $vname $i;
                                         $mb configure -text $vname"
                incr count
            }
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserMotionCorrectStop
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMotionCorrectStop { stopbutton } {

    set ::Ibrowser(Process,MotionCorrectAbort) 1
    VersorMattesMIRegistrationStop
    $stopbutton configure -command "IbrowserMotionCorrectGo $stopbutton"
    #$stopbutton configure -text "Run"
    $stopbutton configure -state normal
}


#-------------------------------------------------------------------------------
# .PROC IbrowserMotionCorrectGo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMotionCorrectGo { stopbutton } {



    #--- catch any events to stop motion correction
    set ::Ibrowser(Process,MotionCorrectAbort) 0
    #$stopbutton configure -text "Stop"
    #$stopbutton configure -command "IbrowserMotionCorrectStop $stopbutton"
    $stopbutton configure -state disabled
    
    if { $::Ibrowser(Process,MotionCorrectAbort) == 0 } {
        #--- it's go
        if { [lsearch $::Ibrowser(idList) $::Ibrowser(activeInterval) ] == -1 } {
            DevErrorWindow "First select a valid sequence to motion correct."
            $stopbutton configure -state normal
            $stopbutton configure -text "Run"
            return
        } elseif { $::Ibrowser(activeInterval) == $::Ibrowser(idNone) } {
            DevErrorWindow "First select a valid sequence to motion correct."
            $stopbutton configure -state normal
            $stopbutton configure -text "Run"
            return
        }
        
        if { [lsearch $::Volume(idList) $::Ibrowser(Process,InternalReference) ] == -1 } {
            DevErrorWindow "First select a valid reference volume."
            $stopbutton configure -state normal
            $stopbutton configure -text "Run"
            return
        } elseif { $::Ibrowser(Process,InternalReference) == $::Volume(idNone) } {
            DevErrorWindow "First select a valid reference volume."
            $stopbutton configure -state normal
            $stopbutton configure -text "Run"
            return
        }    

        set tvid $::Ibrowser(Process,InternalReference)
        set iid $::Ibrowser(activeInterval)
        set start $::Ibrowser($iid,firstMRMLid)
        set stop $::Ibrowser($iid,lastMRMLid)
        set numdrops $::Ibrowser($iid,numDrops)
        
        #--- now register each volume in the selected interval to reference...
        IbrowserRaiseProgressBar
        set progcount 0
        #--- test to see if user interrupted registration for any of the volumes.
        set drop 0
        for { set vid $start } { $vid <= $stop } { incr vid } {
            if { $numdrops != 0} {
                #--- draw the ibrowser's progress bar
                set progress [ expr double ($progcount) / double ($numdrops) ]
                IbrowserUpdateProgressBar $progress "::"
                IbrowserPrintProgressFeedback
            }
            #--- don't try to register a volume to itself...
            if { $vid != $tvid } {
                #--- check to see if transforms exist; if not add 
                if { ! [info exists ::Ibrowser($iid,$drop,transformID) ] } {
                    IbrowserAddSingleTransform $iid $vid $drop       
                } 
                #--- set targets and sources
                set ::RigidIntensityRegistration(sourceID) $vid
                set ::RigidIntensityRegistration(targetID) $tvid
                IbrowserSlicesSetVolumeAll Fore $vid
                IbrowserSlicesSetVolumeAll Back $tvid
                set ::VersorMattesMIRegistration(Repeat) $::Ibrowser(Process,MotionCorrectIterate)
                set ::Matrix(activeID) $::Ibrowser($iid,$drop,transformID)
                set ::Matrix(volume) $vid
                set ::Matrix(refVolume) $tvid
                #--- register 
                IbrowserSayThis "starting motion correction." 0
                set ::Ibrowser(Process,MotionCorrectAbort) [ VersorMattesMIRegistrationAutoRun ]
                #--- listen for events until the current registration
                #--- is finished or stopped by user.
                while { $::VersorMattesMIRegistration(isdone) == 0 } {
                    update
                }
                #--- drop out of loop entirely if user stopped registration
                if { $::Ibrowser(Process,MotionCorrectAbort) == 1 } {
                    puts "stopping motion correction."
                    break
                }
                puts "Registered volume $drop of [expr $numdrops - 1] volumes to reference..."
            }
            incr progcount
            incr drop
        }
    }

    #--- clean up and send message.
    set ::Ibrowser(Process,MotionCorrect,Hardened) 0
    IbrowserLowerProgressBar
    if { $::Ibrowser(Process,MotionCorrectAbort) == 1 } {
        IbrowserSayThis "motion correction stopped by user, removing transforms..." 0
    } else {
        IbrowserSayThis "motion correction complete." 0
    }

    #--- leave the button ready to run again.
    $stopbutton configure -state normal
    $stopbutton configure -text "Run"

}


#-------------------------------------------------------------------------------
# .PROC IbrowserHardenTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserHardenTransforms { } {
    global Volume Transform
    
    #--- get the motion correction reference
    set RefID $::Ibrowser(Process,InternalReference)
    set rnode Volume($RefID,node)

    #--- get the interval's id and volume info
    set sIID $::Ibrowser(activeInterval)
    set start $::Ibrowser($sIID,firstMRMLid)
    set stop $::Ibrowser($sIID,lastMRMLid)
    set numDrops $::Ibrowser($sIID,numDrops)
    
    #--- find out which volume is the reference volume
    set insertRefHere -1
    for { set i 0 } { $i < $numDrops } { incr i } {
        if { $RefID == $::Ibrowser($sIID,$i,MRMLid) } {
            set insertRefHere $i
            break
        }
    }

    #--- error catching if can't find the reference
    if { $insertRefHere < 0 } {
        DevErrorWindow "Reference volume is not inside selected interval $::Ibrowser($sIID,name)"
        return
    }

    #--- set up new interval name in multivolumereader convention
    if { [info exists ::MultiVolumeReader(defaultSequenceName)] } {
        incr ::MultiVolumeReader(defaultSequenceName)
    } else {
        set ::MultiVolumeReader(defaultSequenceName) 1
    }
    set mmID $::MultiVolumeReader(defaultSequenceName)
    set iname [format "multiVol%d" $mmID]

    #--- init interval and get new id
    set newIID [ IbrowserInitNewInterval $iname ]
    
    #--- create new volumes; copy reference directly and xform the rest.
    IbrowserRaiseProgressBar
    set top [ expr $numDrops - 1]
    for { set i 0 } { $i < $numDrops } { incr i } {

        #--- feed ibrowser's progress bar
        if { $top != 0 } {
            set progress [ expr double ($i) / double ($top) ]
            IbrowserUpdateProgressBar $progress "::"
        }

        if { $i == $insertRefHere } {
            #--- copy the reference volume into the new interval
            set newnode [ MainMrmlAddNode Volume ]
            set vid [ $newnode GetID]
            set rname [ $rnode GetName ]
            MainVolumesCreate $vid
            $newnode Copy Volume($RefID,node)
            $newnode SetName ${iname}_mc_${i}_$rname
            MainVolumesCopyData $vid $RefID Off
            set ::Ibrowser($newIID,$i,MRMLid) $vid
        } else {
            #--- transform the volume and insert into new interval
            set tid  $::Ibrowser($sIID,$i,transformID)
            #--- find it in the TransformVolume menu and select:
            #--- have to go thru TransformVolume's widget for this.
            set tname [ Transform($tid,node) GetName ]
            set lastTran [$::TransformVolume(transform) get end]
            set gottran ""
            set tindx 0
            set nope 1
            while { $gottran != $lastTran } {
                set gottran [$::TransformVolume(transform) get $tindx ]                
                if {$gottran == $tname} {
                    set nope 0
                    break
                }
                incr tindx
            }
            if { $nope } {
                DevErrorWindow "Can't find the transform for volume $i in interval $::Ibrowser(IID,name)."
                return
            }

            #--- Configure TransformVolume module stuff and doit.
            $::TransformVolume(transform) select $tindx
            set ::TransformVolume(DispVolume) 0
            set ::TransformVolume(ResamplingMode) 0
            set ::TransformVolume(InterpolationMode) "Cubic"
            set ::TransformVolume(ResultPrefix) "${iname}_mc_${i}"
            set vid [ TransformVolumeRun ]
            set ::Ibrowser($newIID,$i,MRMLid) $vid
            
            #--- copy parameters from old node into this node.
            set oldID $::TransformVolume(VolIDs)
            set newnode Volume($vid,node)
            $newnode Copy Volume($oldID,node)
        }

        if { $i == 0 } {
            set ::Ibrowser($newIID,firstMRMLid) $vid
        } elseif { $i == $top } {
            set ::Ibrowser($newIID,lastMRMLid) $vid
        }
    }

    #--- create interval
    IbrowserMakeNewInterval $iname \
        $::IbrowserController(Info,Ival,imageIvalType) \
        0.0 [expr $numDrops-1] $numDrops

    #--- update multivolumereader to reflect this new sequence
    IbrowserUpdateMultiVolumeReader $iname $newIID
    
    #--- report in ibrowser's message panel
    IbrowserLowerProgressBar
    IbrowserSayThis "motion correction transforms committed in new interval $iname." 0
    set ::Ibrowser(Process,MotionCorrect,Hardened) 1
}


#-------------------------------------------------------------------------------
# .PROC IbrowserHelpMotionCorrection
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserHelpMotionCorrection { } {

    set i [ IbrowserGetHelpWinID ]
    set txt "<H3>Motion correction</H3>
 <P> This tool lets you select an interval to motion correct (a source interval), to select a reference volume from within the source interval, and to register all of the other volumes in the source interval to the reference. Currently, the only kind of registration available for motion correction in the ibrowser module is rigid registration by Mutual Information.
<P> Motion correction adds a transform to each non-reference volume in the interval, and may not work properly if the reference or target volume nodes already have transforms applied to them. It is recommended that an interval be motion corrected first, using any of its volumes as the reference, and if subsequent transforms are necessary, that those operations be carried out in a second step after transforms have been applied.
<P> To abort motion correction: stop the registration of an individual volume by clicking the <I>Stop</I> button on the popup window and wait a short time for the registration to stop. Any registration transforms that were added to the scene will not be deleted, and can be used for subsequent registration attempts. They can be deleted using the <I>Cancel</I> button.
<P> Important note: until the <I>Apply transforms</I> option is completed, these volumes will not be suitable for collective statistical processing (such as in the fMRIEngine module). If you'd like to keep image data in its original space, and use the transforms for visualization only, <B>don't</B> use the <I>Apply</I> button. If you'd like to perform additional processing on the motion corrected data, then <B>do</B> use the <I>Apply</I> button to transform the image data. Applying transforms will create a new interval containing transformed motion corrected data from teh original interval. (You may also want to delete the original interval to save memory).
<P> <B>Quality settings (from vtkRigidIntensityRegistration):</B>
<P><B>Coarse:</B> The coarse method will generally do a good job on all images. It requires no user intervention; though it updates regularly so that the user can stop the algorithm if she is satisfied with the result.
<P> <B>Fair:</B> The fine method can be run after the coarse method to fine-tune the result. You can expect it to take longer than the coarse method.
<P> <B>Good:</B> This method is designed for the user to be able to walk away, and to come back to find a good registration later. It does not update the alignment in Slicer's main viewer until finished.
<P><B>Best:</B> This method is certainly designed to be left unattended and running for some time. It generally works very well. It does not update the alignment in Slicer's main viewer until finished."
    DevCreateTextPopup infowin$i "Ibrowser information" 100 100 18 $txt
}

