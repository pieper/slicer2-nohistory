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
# FILE:        IbrowserReassemble.tcl
# PROCEDURES:  
#   IbrowserBuildReassembleGUI
#   IbrowserUpdateReassembleGUI
#   IbrowserCancelReassembleSequence
#   IbrowserValidReassembleAxis
#   IbrowserReassembleSequence
#   IbrowserHelpReassemble
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildReassembleGUI
#  Builds the GUI in Slicer's GUI panel for creating a new set of volumes
#  from a selected set of volumes, by rearranging their slices.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildReassembleGUI { f master } {
global Gui

    #--- This GUI allows a new set of volumes to be created from
    #--- slices from volumes in the interval.
    #--- Set a global variable for frame so we can raise it.
    set ::Ibrowser(fProcessReassemble) $f
    
    frame $f.fOverview -bg $Gui(activeWorkspace) -bd 2 
    pack $f.fOverview -side top

    set ff $f.fOverview
    DevAddButton $ff.bHelp "?" "IbrowserHelpReassemble" 2 
    eval { label $ff.lOverview -text \
               "Reassemble slices along major axis." } $Gui(WLA)
    grid $ff.bHelp $ff.lOverview -pady 1 -padx 1 -sticky w

    frame $f.fSpace -bg $::Gui(activeWorkspace) -bd 2 
    eval { label $f.fSpace.lSpace -text "       " } $Gui(WLA)
    pack $f.fSpace -side top 
    pack $f.fSpace.lSpace -side top -pady 4 -padx 20 -anchor w -fill x

    #--- frame to specify the interval to be processed.
    frame $f.fSelectInterval -bg $::Gui(activeWorkspace) -bd 2
    pack $f.fSelectInterval -side top -anchor w -fill x
    eval { label $f.fSelectInterval.lText -text "interval to process:" } $Gui(WLA)    
    eval { menubutton $f.fSelectInterval.mbIntervals -text "none" -width 18 -relief raised \
               -height 1 -menu $f.fSelectInterval.mbIntervals.m -bg $::Gui(activeWorkspace) \
               -indicatoron 1 } $Gui(WBA)
    eval { menu $f.fSelectInterval.mbIntervals.m } $Gui(WMA)
    foreach i $::Ibrowser(idList) {
        puts "adding $::Ibrowser($i,name)"
        $f.mbVolumes.m add command -label $::Ibrowser($i,name) \
            -command "IbrowserSetActiveInterval $i"
    }

    set ::Ibrowser(Process,Reassemble,mbIntervals) $f.fSelectInterval.mbIntervals
    bind $::Ibrowser(Process,Reassemble,mbIntervals) <ButtonPress-1> "IbrowserUpdateReassembleGUI"
    set ::Ibrowser(Process,Reassemble,mIntervals) $f.fSelectInterval.mbIntervals.m
    pack $f.fSelectInterval.lText -pady 2 -padx 2 -anchor w
    pack $f.fSelectInterval.mbIntervals -pady 2 -padx 2 -anchor w

    frame $f.fConfiguration -bg $Gui(activeWorkspace) -bd 2 -relief groove
    pack $f.fConfiguration -side top -anchor w -padx 2 -pady 5 -fill x
    DevAddLabel $f.fConfiguration.lText "Select axis to vary along interval:"
    eval { radiobutton $f.fConfiguration.r1 -width 20 -text {R/L} \
               -variable ::Ibrowser(Process,reassembleAxis) -value "RL" \
               -relief flat -offrelief flat -overrelief raised \
               -command "" -selectcolor white } $Gui(WEA)
    eval { radiobutton $f.fConfiguration.r2 -width 20 -text {A/P} \
               -variable ::Ibrowser(Process,reassembleAxis) -value "AP" \
               -relief flat -offrelief flat -overrelief raised \
               -command "" -selectcolor white } $Gui(WEA)
    eval { radiobutton $f.fConfiguration.r3 -width 20 -text {S/I} \
               -variable ::Ibrowser(Process,reassembleAxis) -value "SI" \
               -relief flat -offrelief flat -overrelief raised \
               -command "" -selectcolor white } $Gui(WEA)
    
    pack $f.fConfiguration.lText -side top -pady 4 -padx 20 -anchor w
    pack $f.fConfiguration.r1 $f.fConfiguration.r2 $f.fConfiguration.r3 -side top -pady 5 -padx 20 -anchor w

    DevAddButton $f.fConfiguration.bApply "apply" "IbrowserReassembleSequence" 10
    TooltipAdd $f.fConfiguration.bApply "Reassembles volumes and populates a new interval with them."
    DevAddButton $f.fConfiguration.bCancel "cancel" "IbrowserCancelReassembleSequence" 10

    pack $f.fConfiguration.bApply $f.fConfiguration.bCancel -side top -anchor w -padx 20 -pady 5
    place $f -in $master -relwidth 1.0 -relheight 1.0 -y 0
    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateReassembleGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateReassembleGUI { } {

    if { [info exists ::Ibrowser(Process,Reassemble,mIntervals) ] } {
        set m $::Ibrowser(Process,Reassemble,mIntervals)
        $m delete 0 end
        foreach id $::Ibrowser(idList) {
            $m add command -label $::Ibrowser($id,name)  \
                -command "IbrowserSetActiveInterval $id"
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserCancelReassembleSequence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCancelReassembleSequence { } {
    set ::Ibrowser(Process,reassembleAxis) ""
}



#-------------------------------------------------------------------------------
# .PROC IbrowserValidReassembleAxis
# Checks to see if the selected axis is valid.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserValidReassembleAxis { } {
    
    set c $::Ibrowser(Process,reassembleAxis)
    if { $c == "RL" || $c == "AP" || $c == "SI" } {
        return 1
    } else {
        return 0
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserReassembleSequence
# Reassembles selected interval into a new set of volumes.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserReassembleSequence { } {
global Volume
#---
#--- Slices a volume along a selected axis
#--- and assembles new volumes from slices
#--- along interval axis.

    if { [ IbrowserValidReassembleAxis ] } {
        IbrowserRaiseProgressBar
        set pcount 0

        #--- get the destination interval started
        set dstID $::Ibrowser(uniqueNum)
        set ::Ibrowser(loadVol,name) [format "multiVol%d" $dstID]
        set dstName $::Ibrowser(loadVol,name)
        set ::Ibrowser($dstID,name) $dstName
        set ::Ibrowser($dstName,intervalID) $dstID
        
        #--- get info about the source interval
        set srcID $::Ibrowser(activeInterval)
        if { $srcID == $::Ibrowser(none,intervalID) } {
            DevErrorWindow "Please choose an interval to process."
            return
        }
        set firstVolID $::Ibrowser($srcID,firstMRMLid)
        set lastVolID $::Ibrowser($srcID,lastMRMLid)
        set srcName $::Ibrowser($srcID,name)

        #--- get the dimensions of the first image volume
        set DimList [ [ ::Volume($firstVolID,vol) GetOutput ] GetDimensions ]
        set xmin 0
        set ymin 0
        set zmin 0
        set xmax [expr [ lindex $DimList 0 ] - 1 ]
        set ymax [ expr [ lindex $DimList 1 ] - 1 ]
        set zmax [ expr [ lindex $DimList 2 ] - 1 ]

        #--- Error check: see if all volumes in the src interval
        #--- have the same dimension; otherwise this will fail.
        #--- Assuming dimensions are returned in vtk space.
        for { set vid $firstVolID } { $vid <= $lastVolID} { incr vid } {
            set VDimList [ [::Volume($vid,vol) GetOutput ] GetDimensions ]
            set Vi [ expr [ lindex $VDimList 0 ] - 1 ]
            set Vj [ expr [ lindex $VDimList 1 ] - 1 ]
            set Vk [ expr [lindex $VDimList 2 ] - 1 ]
            if { $Vi != $xmax ||  $Vj != $ymax || $Vk != $zmax } {
                DevErrorWindow "All volumes in selected interval must have the same dimension."
                return
            }
        }

        #--- User has selected the "reassembleAxis" -- which is
        #--- the axis (SI, RL, or AP) along which corresponding
        #--- slices will be collected and arrayed along the interval.
        #--- For instance: if reassembleAxis = RL, the rightmost
        #--- slice of each volume in the source interval will be
        #--- appended to a new volume, which will be placed first
        #--- in the destination interval, and so on.
        #--- Get the corresponding axis in Vtk space for this vol.
        set vid $firstVolID
        set newvec [ IbrowserGetRasToVtkAxis \
                         $::Ibrowser(Process,reassembleAxis) \
                         ::Volume($vid,node) ]
        #--- unpack the vector into x, y and z
        foreach { x y z } $newvec { }

        #--- set the appropriate append axis.
        if { ($x == 1) || ($x == -1) } {
            #---vary axis 0 along interval
            set appendAxis 0
            set numDestVols [ expr $xmax + 1 ]
        } elseif { ($y == 1) || ( $y == -1) } {
            #---vary axis 1 along interval
            set appendAxis 1
            set numDestVols [ expr $ymax + 1 ]
        } elseif { ($z == 1) || ($z == -1) } {
            #---vary axis 2 along interval
            set appendAxis 2
            set numDestVols [ expr $zmax + 1 ]
        }
        set numSrcVols $::Ibrowser($srcID,numDrops)

        #--- create all new Volume nodes and volumes.
        #--- and make a list of ptrs to nodes.
        for {set i 0} { $i < $numDestVols } { incr i } {
            set node [MainMrmlAddNode Volume ]
            set nodeID [$node GetID ]
            MainVolumesCreate $nodeID
            lappend newnodeList  $node 
        }

        #--- Now, here's how the reassemble will work:
        #--- for each [of n = 0 to (numDestVols-1)] destination volume,
        #--- extract  nth slices from all m src data vols,
        #--- and append them to create nth dest volume.

        #--- for each DESTINATION data volume
        for { set n 0 } { $n < $numDestVols } { incr n } {
            if { $numDestVols != 0 } {
                set progress [ expr double ($pcount) / double ($numDestVols) ]
                IbrowserUpdateProgressBar $progress "::"
                IbrowserPrintProgressFeedback
            }
            set dstnode [ lindex $newnodeList $n ]
            set dstnodeID [ $dstnode GetID ]

            #--- create the image appender
            vtkImageAppend appender
            appender SetAppendAxis $appendAxis

            #--- consider each of m volumes in the SRC sequence,
            #--- starting with the first.
            set vid $firstVolID
            for { set m 0 } { $m < $numSrcVols } { incr m } {
                #--- use each volume in the src sequence as input
                vtkExtractVOI extract$m
                extract$m SetInput  [ ::Volume($vid,vol) GetOutput ]
                extract$m SetSampleRate 1 1 1
                vtkImageChangeInformation putslice$m
                
                #--- extract the nth slice from the src volume
                if { $appendAxis == 0 } {
                    extract$m SetVOI $n $n $ymin $ymax $zmin $zmax
                    putslice$m SetOutputExtentStart $m 0 0  
                } elseif { $appendAxis == 1 } {
                    extract$m SetVOI $xmin $xmax $n $n $zmin $zmax
                    putslice$m SetOutputExtentStart 0 $m 0 
                } elseif { $appendAxis == 2 } {
                    extract$m SetVOI $xmin $xmax $ymin $ymax $n $n
                    putslice$m SetOutputExtentStart 0 0 $m
                } else {
                    DevErrorWindow "Invalid axis for reassembling volumes."
                    return
                }

                #--- append this slice to the new n^th destination volume.
                putslice$m SetInput [ extract$m GetOutput]
                appender AddInput [ putslice$m GetOutput]
                #--- look at next volume in the src interval
                incr vid
            }

            #--- grab the new image data (appended slices from src volumes)
            set imdata [ appender GetOutput ]
            $imdata Update

            #--- get info about new vtkImageData
            set dim [ $imdata GetDimensions ]
            set dimx [ lindex $dim 0 ]
            set dimy [ lindex $dim 1 ]
            set dimz [ lindex $dim 2 ]
            set spc [ $imdata GetSpacing ]
            set pixwid [ lindex $spc 0 ]
            set pixhit [ lindex $spc 1 ]
            set sliceThickness [ lindex $spc 2 ]
            set sliceSpacing 0
            set zSpacing [ expr $sliceThickness + $sliceSpacing ]
            set ext [ $imdata GetWholeExtent ]
            set xstart [expr 1 + [lindex $ext 0]]
            set xstop [expr 1 + [lindex $ext 1]]            
            set ystart [expr 1 + [lindex $ext 2]]
            set ystop [expr 1 + [lindex $ext 3]]            
            set zstart [expr 1 + [lindex $ext 4]]
            set zstop [expr 1 + [lindex $ext 5]] 
            
            #--- get info to configure destination MrmlVolumeNodes:
            $dstnode SetImageRange $zstart $zstop
            $dstnode SetDimensions $dimx $dimy
            $dstnode SetName ${dstName}_${n}
            $dstnode SetLabelMap [ ::Volume($firstVolID,node) GetLabelMap ]
            eval $dstnode SetSpacing $pixwid $pixhit $zSpacing
            $dstnode SetTilt 0
            $dstnode SetNumScalars [ $imdata GetNumberOfScalarComponents ]
            $dstnode SetScanOrder [ ::Volume($firstVolID,node) GetScanOrder ]
            $dstnode SetLittleEndian 1
            $dstnode ComputeRasToIjkFromScanOrder [ ::Volume($firstVolID,node) GetScanOrder ]
            $dstnode SetLUTName [ ::Volume($firstVolID,node) GetLUTName ]
            $dstnode SetAutoWindowLevel [ ::Volume($firstVolID,node) GetAutoWindowLevel ]
            $dstnode SetWindow [ ::Volume($firstVolID,node) GetWindow ]
            $dstnode SetLevel [ ::Volume($firstVolID,node) GetLevel ]
            $dstnode SetApplyThreshold [ ::Volume($firstVolID,node) GetApplyThreshold ]
            $dstnode SetAutoThreshold [ ::Volume($firstVolID,node) GetAutoThreshold ]
            $dstnode SetUpperThreshold [ ::Volume($firstVolID,node) GetUpperThreshold ]
            $dstnode SetLowerThreshold [ ::Volume($firstVolID,node) GetLowerThreshold ]
            $dstnode SetFrequencyPhaseSwap [ ::Volume($firstVolID,node) GetFrequencyPhaseSwap ]
            $dstnode SetRasToIjkMatrix [ ::Volume($firstVolID,node) GetRasToIjkMatrix ]
            $dstnode SetRasToVtkMatrix [ ::Volume($firstVolID,node) GetRasToVtkMatrix ]
            $dstnode SetPositionMatrix [ ::Volume($firstVolID,node) GetPositionMatrix]
            #--- if there's only one image plane in the destination volume and
            #--- interpolation is turned on, nothing shows up in Slicer's viewer!
            if { $numSrcVols < 2 } {
                $dstnode SetInterpolate 0
            } else {
                $dstnode SetInterpolate [ ::Volume($firstVolID,node) GetInterpolate ]
            }

            ::Volume($dstnodeID,vol) SetImageData  $imdata
            puts "New MrmlVolumeNode $dstnodeID:"
            puts "----------------------------------------"
            puts "new image data dimensions: $dim"
            puts "new image data spacing: $zSpacing"
            puts "new image data extent: $ext"
            puts ""

            set ::Ibrowser($dstID,$n,MRMLid) $dstnodeID

            #--- delete the slice appender and slice extractors for this destination volume
            appender Delete
            for { set m 0 } { $m < $::Ibrowser($srcID,numDrops) } { incr m } {
                extract$m Delete
                putslice$m Delete
            }
            #--- update Ibrowser's progress increment
            incr pcount
        }

        IbrowserEndProgressFeedback
        IbrowserLowerProgressBar    

        #--- set first and last MRML ids in the interval
        #--- and create a new interval to hold the volumes
        set ::Ibrowser($dstID,firstMRMLid) [ [ lindex $newnodeList 0 ] GetID ]
        set ::Ibrowser($dstID,lastMRMLid) [ [ lindex $newnodeList end ] GetID ]
        set spanmax [ expr $numDestVols - 1 ]
        IbrowserMakeNewInterval $dstName $::IbrowserController(Info,Ival,imageIvalType) \
            0.0 $spanmax $numDestVols

        #--- text the user
        set tt "Created new interval $dstName from volumes."
        IbrowserSayThis $tt 0

        IbrowserEndProgressFeedback
        set c $::Ibrowser(Process,reassembleAxis)
        set tt "New interval $dstName contains $srcName reassembled with $c axis along interval."
        IbrowserSayThis $tt 0
        set ::Ibrowser(Process,reassembleAxis) ""
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserHelpReassemble
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserHelpReassemble { } {

    set i [ IbrowserGetHelpWinID ]
    set txt "<H3>Reassemble volumes</H3>
 <P> This tool lets you generate a new interval whose volumes are reassembled versions of those in a selected interval. In the reassembly, an axis (either Right -> Left, Anterior -> Posterior, or Superior -> Inferior) is arrayed along the interval axis. If the selected interval contains a set of volumes that represent a timeseries, then each volume in the reassembled interval will contain the same slice for all timepoints.
<P> As an example, assume the selected axis is S->I. Then the first volume in the reassembled interval will be comprised of the S-most slice from each volume in the selected interval; the last volume in the reassembled interval will be comprised of the I-most slice from each volume in the selected interval.
<P> Or, if a selected interval contains a single volume containing the same slice sampled over time, then a reassembled interval can be created which arrays individual timepoints along the Ibrowser's interval axis."
    DevCreateTextPopup infowin$i "Ibrowser information" 100 100 18 $txt
}

