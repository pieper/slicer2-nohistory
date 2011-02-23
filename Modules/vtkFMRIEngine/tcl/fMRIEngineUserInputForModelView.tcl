#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineUserInputForModelView.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:38 $
#   Version:   $Revision: 1.14 $
# 
#===============================================================================
# FILE:        fMRIEngineUserInputForModelView.tcl
# PROCEDURES:  
#==========================================================================auto=
proc fMRIModelViewSortUserInput { } {
    global fMRIEngine
    #---
    #--- numRuns should be set to 1 by default; changed only
    #--- when user wants to analyze several runs at once:
    #--- When numRuns > 1, we must determine whether
    #--- all runs have the same conditions or whether 
    #--- conditions vary in some way from run to run
    #--- (Maybe their onsets, durations or intensities differ...)
    #--- When conditions are identical across runs,
    #--- we set fMRIModelView(Design,identicalRuns) = 1;
    #--- otherwise zero.
    #---
    set ::fMRIModelView(Design,numRuns) $fMRIEngine(noOfSpecifiedRuns)
    set ::fMRIModelView(Design,identicalRuns) $fMRIEngine(checkbuttonRunIdentical)
    set ::fMRIModelView(Layout,NoDisplay) 0

    #--- this is the number of files read in, and their fake filenames
    set numFiles 0
    unset -nocomplain ::fMRIModelView(Design,fileNames)
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set ::fMRIModelView(Design,Run$r,numTimePoints) $::MultiVolumeReader(noOfVolumes)        
        for { set i 0 } { $i < $::fMRIModelView(Design,Run$r,numTimePoints) } { incr i } {
            fMRIModelViewAddFileName "Run$r-0$i.img"
            incr numFiles
        }
    }
    set ::fMRIModelView(Design,totalTimePoints) $numFiles

    
    #---
    #--- Design types supported: blocked, event-related, or mixed
    #--- default is 'blocked'
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set ::fMRIModelView(Design,Run$r,Type) $fMRIEngine($r,designType) 
    }
    #--- scan interval in seconds.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set ::fMRIModelView(Design,Run$r,TR) $fMRIEngine($r,tr) 
    }
    #--- fraction-of-second increment used in modeling
    #--- please keep ($::fMRIModelView(Design,Run$r,TR) *
    #--- 1.0/$::fMRIModelView(Design,Run$r,TimeIncrement) an integer value.
    #--- like TR=2, TimeIncrement=0.1, 2/0.1 = 20: good.
    #--- not TR=2, TimeIncrement=0.3, 2/0.3 = 6.666: bad.
    #--- otherwise, the subsampling routine will try to sample between
    #--- samples and will break or generated incorrect signals.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        #set ::fMRIModelView(Design,Run$r,TimeIncrement) 1.0
        set ::fMRIModelView(Design,Run$r,TimeIncrement) 0.1
    }

    #---
    #--- Specify these Onsets and Durations lists for each user-specified condition.
    #--- BLOCKED DESIGN requires both lists for each condition;
    #--- MIXED DESIGN Duration list sets duration=0 for event durations.
    #--- and purely EVENT-RELATED DESIGNS have no Duration lists.
    #--- Assumes onsets and durations are specified in numbers of scans:
    #--- an onset of 10 means 'onset at the 10th scan'
    #--- and a duration of 10 means 'lasting for 10 scans'.
    #--- **if onsets are typically specified in seconds, have to change this.
    #--- For parametric designs, specify Condition intensity too.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        if {[info exists fMRIEngine($r,conditionList)]} {  
            set len [llength $fMRIEngine($r,conditionList)]
            set ::fMRIModelView(Design,Run$r,numConditions) $len

            set i 0
            #--- Specify each condition inside each run...
            while {$i < $len} {
                set title [lindex $fMRIEngine($r,conditionList) $i]
                set indx [expr $i+1]

                # Intensities
                set onsetsStr $fMRIEngine($r,$title,onsets)
                # trim white spaces at beginning and end
                set onsetsStr [string trim $onsetsStr]
                # replace multiple spaces in the middle of the string by one space  
                regsub -all {( )+} $onsetsStr " " onsetsStr 

                set onsets [split $onsetsStr " "]     
                set l [llength $onsets]
                for {set j 0} {$j < $l} {incr j} {
                    lappend intensities
                } 
                fMRIModelViewSetConditionIntensities $r $indx $intensities 

                fMRIModelViewSetConditionOnsets $r $indx $onsets 

                set dursStr $fMRIEngine($r,$title,durations)
                # trim white spaces at beginning and end
                set dursStr [string trim $dursStr]
                # replace multiple spaces in the middle of the string by one space  
                regsub -all {( )+} $dursStr " " dursStr 

                set durs [split $dursStr " "]     
                fMRIModelViewSetConditionDurations $r $indx $durs 

                incr i 
            }
        }
    }

    #--- IMPORTANT. Let's count up the number of explanatory variables (EVs)
    #--- we'll use for the linear model. We'll represent different *kinds*
    #--- of EVs in different global variables. What we call 'conditionEVs' are
    #--- those derived from the conditions themselves: the stimulus signal
    #--- with signal modeling applied (i.e. boxcar, hrf convolution).
    #--- What we call 'additionalEVs' are things that model the 
    #--- derivative signals per condition, baseline and the nuissance signals per run.
    #--- THE REASON we keep these separate is so that we can arrange
    #--- signals in a coherent way within the visual representation of the
    #--- design matrix. For instance, we'd like stimulus signals and their derivatives
    #--- to be grouped together, and the per-run nuissance signal data, baseline,
    #--- etc. to appear at the end of the run.
    #--- So here, we start counting them up and assigning 'signal types' to each
    #--- so we know how to build them later.
    #--- numEVs derived from conditions.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set len [llength $fMRIEngine($r,conditionList)]
        set ::fMRIModelView(Design,Run$r,numConditionEVs) $len 
        set ::fMRIModelView(Design,Run$r,numAdditionalEVs) 0
    }

    #---
    #--- Additional EVs for detrending? User specifies:
    #--- by default, ev for baseline is off
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set ::fMRIModelView(Design,Run$r,UsePolyBasis) 0
        set ::fMRIModelView(Design,Run$r,UseSplineBasis) 0
        set ::fMRIModelView(Design,Run$r,UseExploratoryBasis) 0
        unset -nocomplain ::fMRIModelView(Design,evNames)
        unset -nocomplain ::fMRIModelView(Design,evs)
    }

    #---    
    #--- Regular signal types used for condition-derived EVs:
    #--- baseline,
    #--- boxcar,
    #--- boxcar_dt1,
    #--- boxcar_dt2,
    #--- boxcar_cHRF,
    #--- boxcar_cHRF_dt1,
    #--- boxcar_cHRF_dt2,
    #--- halfsine,
    #--- halfsine_dt1,
    #--- halfsine_dt2,
    #--- halfsine_cHRF,
    #--- halfsine_cHRF_dt1,
    #--- halfsine_cHRF_dt2,
    #--- These variables get generated during signal modeling
    #--- of conditions, and selection of additional EVs.
    #--- So here, ::fMRIModelView(Design,EV1,SignalType)
    #--- corresponds to condition1.
    #---
    #-------------------- IMPORTANT ---------------------------------------------------------
    #--- This proc formats the list of EVs in the following way,
    #--- which the rest of fMRIEngine conforms:
    #--- condition1, deriv1, deriv2, baseline, trendbasis1...trendbasisN,
    #--- condition2, deriv1, deriv2, baseline, trendbasis1...trendbasisN,...
    #--- conditionM, deriv1, deriv2, baseline, trendbasis1...trendbasisN.
    #--- Only derivatives used are included, and only trendbases used are included.
    #--------------------------------------------------------------------------------------------
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        #---wjp 09/19/05 adding this unset. ConditionNames keeps getting appended.
        #unset -nocomplain ::fMRIModelView(Design,Run$r,ConditionNames)
        set count 1 
        foreach title $fMRIEngine($r,namesOfEVs) {
            set wf $::fMRIEngine($r,$title,signalType)
            fMRIModelViewSetEVCondition $r $count $::fMRIEngine($r,$title,myCondition)
            fMRIModelViewSetEVSignalType $r $count $wf
            #--- WJP: moving the adding of ConditionName to fMRIEngineAddCondition 
            #fMRIModelViewAddConditionName $r $title 
            incr count
        }
    }

    
    #--- wjp 09/02/05
    #--- add to the count of additional EVs if temporal derivatives are used in
    #--- modeling, as these EVs have been automatically created above.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        foreach title $fMRIEngine($r,namesOfEVs) {
            set sig $::fMRIEngine($r,$title,signalType)
            set addEV [ string first "dt" $sig  ]
            if { $addEV >= 0 } {
                incr ::fMRIModelView(Design,Run$r,numAdditionalEVs)
            }
        }
    }


    #--- compute totalEVs across runs.
    set sum 0
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set sum [ expr $sum + $::fMRIModelView(Design,Run$r,numConditionEVs) \
                      + $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
    }
    set ::fMRIModelView(Design,totalEVs) $sum

    #---
    #--- Additional EV: use for modeling baseline
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        if { $::fMRIModelView(Design,Run$r,UseBaseline) } {
            set j [ expr \
                        $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                        $::fMRIModelView(Design,Run$r,numAdditionalEVs) + 1 ]
            #--- wjp added.
            fMRIModelViewSetEVCondition $r $j "none"
            fMRIModelViewSetEVSignalType $r $j "baseline"
            #--- have added another ev, so:
            #--- increment the number of additional EVs,
            incr ::fMRIModelView(Design,Run$r,numAdditionalEVs)
        }
    }

    
    #--- update totalEVs
    set sum 0
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set sum [ expr $sum + $::fMRIModelView(Design,Run$r,numConditionEVs) \
                      + $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
    }
    set ::fMRIModelView(Design,totalEVs) $sum

    #--- open: new DCbasis code wjp 11/03/05
    #--- compute how many cosines we'll need per each run.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        if { $::fMRIEngine(Design,Run$r,useCustomCutoff) == 0 } {
            fMRIEngineComputeDefaultHighpassTemporalCutoff  $r
        }
        fMRIModelViewFindNumCosineBasis $r
        #--- add the correct number of basis functions.
        set j [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                    $::fMRIModelView(Design,Run$r,numAdditionalEVs) + 1 ]
        if { $::fMRIModelView(Design,Run$r,UseDCBasis) } {
            set numDCbasis $::fMRIEngine(Design,Run$r,numCosines)
            for { set b 0 } { $b < $numDCbasis } { incr b } {
                fMRIModelViewSetEVCondition $r $j "none"
                fMRIModelViewSetEVSignalType $r $j "DCbasis$b"
                #--- have added another ev, so:
                #--- increment the number of additional EVs,
                incr ::fMRIModelView(Design,Run$r,numAdditionalEVs)            
                incr j
            }
        }
    }

    #--- close: new DCbasis code

    #--- update totalEVs
    set sum 0
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set sum [ expr $sum + $::fMRIModelView(Design,Run$r,numConditionEVs) \
                      + $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
    }
    set ::fMRIModelView(Design,totalEVs) $sum
    
    #---    
    #--- these auto-generated titles & labels of EVs derived from
    #--- user-specified conditions in each run, and the additional
    #--- requested regressors.
    #--- If temporal derivatives have been requested in modeling, additional
    #--- ev's are automatically created in GenerateEVName and GenerateEVLabel.
    #--- these will be added into the count below.
    if { $::fMRIModelView(Design,identicalRuns) } {
        #--- copy EVnames derived from user-specified conditions thru
        #--- signal modeling, and additional EVs too.
        for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
            set copyrun 1
            set k 1
            set numevs [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                            $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
            for { set i 1 } { $i <= $numevs } { incr i } {
                fMRIModelViewGenerateEVName $i $copyrun
                fMRIModelViewGenerateEVLabel $k
                incr k
            }
        }
    } else {
        #--- specify condition names for each run separately.
        #--- run 1
        for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
            set k 1
            set numevs [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                             $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
            for { set i 1 } { $i <= $numevs } { incr i } {
                fMRIModelViewGenerateEVName $i $r
                fMRIModelViewGenerateEVLabel $k
                incr k
            }
        }
    }


    #---
    #--- assume that t-contrasts will be available in vector form
    set size [$fMRIEngine(contrastsListBox) size]
    set ::fMRIModelView(Design,numTContrasts) $size 
    unset -nocomplain ::fMRIModelView(Design,TContrastNames)
    unset -nocomplain ::fMRIModelView(Design,TContrasts)
 
    set i 0
    while {$i < $size} {
        set name [$fMRIEngine(contrastsListBox) get $i]
        if {$name != ""} {
            set c $fMRIEngine($name,contrastVector)
            # trim white spaces at beginning and end
            set c [string trim $c]
            # replace multiple spaces in the middle of the string by one space  
            regsub -all {( )+} $c " " c 

            # reformat the contrast string
            set cl [split $c " "]
            set len [llength $cl]
            if {$len > $::fMRIModelView(Design,totalEVs)} {
                set cl [lrange $cl 0 [expr $::fMRIModelView(Design,totalEVs)-1]]
            } elseif {$len < $::fMRIModelView(Design,totalEVs)} {
                for {set j $len} {$j < $::fMRIModelView(Design,totalEVs)} {incr j} {
                    lappend cl 0
                }
            } else {
            }

            set index [expr $i+1]
            fMRIModelViewSetTContrast $index $cl
            fMRIModelViewSetTContrastName $index t-$name 
            fMRIModelViewSetTContrastLabel $index

            set str [join $cl " "]
            set fMRIEngine($name,contrastVector) $str
        }

        incr i
    }


}


