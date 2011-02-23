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
# FILE:        IbrowserPlot.tcl
# PROCEDURES:  
#   IbrowserPopUpPlot
#   IbrowserDrawPlotAllSamples x y z
#   IbrowserClosePlotWindow
#   IbrowserCheckDataVolumeDimensions
#   IbrowserGetVoxelFromSelection x y
#   IbrowserCheckSelectionAgainstVolumeLimits argstr
#   IbrowserBuildReferenceVector
#   IbrowserMakeBoxcarKernel
#   IbrowserMakeImpulseKernel
#   IbrowserMakeHalfsineKernel
#   IbrowserMakeCanonicalHRFKernel
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC IbrowserPopUpPlot
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPopUpPlot {x y} {

    # error if no private segment
    if { [ catch "package require BLT" ] } {
        DevErrorWindow "Must have the BLT extension for the Tk toolkit installed to support plotting."
        return
    }

    #--- are there any volumes in this interval?
    set id $::Ibrowser(activeInterval)
    if { $::Ibrowser($id,numDrops) < 1 } {
        return
    }
    
    #--- for now, include only one kind of plot.
    #--- checks the current plotting option and sets vars.
    switch $::Ibrowser(plot,PlotType) {
        "" {
            return
        }
        "$::Ibrowser(plot,TypeVvvn)" {
            set ::Ibrowser(plot,plotTitle) "voxel intensity vs. volume number"
            set ::Ibrowser(plot,plotGeometry) "+335+200"
            set ::Ibrowser(plot,plotHeight) 250 
            
            #--- a rough way to guage how big to draw the plot window
            if {$MultiVolumeReader(noOfVolumes) > 150} { 
                set ::Ibrowser(plot,plotWidth) 700
                set graphWidth 700
            } else {
                set ::Ibrowser(plot,plotWidth) 500
                set graphWidth 500
            }
        }
        "$::Ibrowser(plot,TypeHistogram)" {
            set ::Ibrowser(plot,plotTitle) "voxel timecourse intensity histogram"
            puts "Histogram plotting not yet available."
            return
        }
        "$::Ibrowser(plot,TypeROIAvg)" {
            set ::Ibrowser(plot,plotTitle) "voxel intensity averaged over ROI versus volume number"
            puts "ROI plotting not yet available."
            return
        }
    }

    #--- Get the indices of selected voxel. Then, check
    #--- these indices against the dimensions of the volume.
    #--- If they're good values, assemble the selected voxel's
    #--- time-course and plot.
    scan [IbrowserGetVoxelFromSelection $x $y] "%d %d %d" i j k
    if {$i == -1} {
        return
    }
    
    #--- do all volumes in the interval have the same dimensions?
    #--- if not, return.
    scan [IbrowserCheckDataVolumeDimensions] "%d %d %d %d %d %d" \
        xmin ymin zmin xmax ymax zmax
    if { ($xmax == 0) && ($ymax == 0) && ($zmax == 0) } {
        DevErrorWindow "All volumes in the selected interval must have the same dimension."
        return
    }

    #--- Check to make sure that the selected voxel is within the data
    #--- volume. If not, return.
    set argstr "$i $j $k $xmin $ymin $zmin $xmax $ymax $zmax"
    if {[ IbrowserCheckSelectionAgainstVolumeLimits $argstr] == 0} {
        DevErrorWindow "Selected voxel is not in volume."
        return 
    }
    
    if { ( [ info exists ::Ibrowser(intervalPlotToplevel) ] ) && ( $::Ibrowser(curPlotting) != $::Ibrowser(plot,PlotType) ) } {
        IbrowserClosePlotWindow
    }

    #--- Plot the time course -- manage the popup
    if {[info exists ::Ibrowser(intervalPlotToplevel)] == 0 } {
        set w .ibtc
        toplevel $w -bg white
        wm title $w $::Ibrowser(plot,plotTitle)
        wm minsize $w $::Ibrowser(plot,plotWidth) $::Ibrowser(plot,plotHeight)
        wm geometry $w $::Ibrowser(plot,plotGeometry)

        blt::graph $w.graph -plotbackground white -background white -title "voxel intensity vs. volume number" \
            -font $::IbrowserController(UI,Bigfont)
        pack $w.graph 
        $w.graph legend configure -position bottom -anchor w -relief flat \
            -font $::IbrowserController(UI,Medfont) -fg black -background white
        $w.graph axis configure y -title "scalar intensity" 

        #--- grid the background
        $w.graph grid on
        $w.graph grid configure -color "#a7a7a7"
        $w.graph grid configure -linewidth 1

        wm protocol $w WM_DELETE_WINDOW "IbrowserClosePlotWindow" 

        set ::Ibrowser(intervalPlotToplevel) $w
        set ::Ibrowser(plot,intervalPlot) $w.graph
    }

    #--- configure the xaxis.
    if {$::Ibrowser(plot,PlotType) == "$::Ibrowser(plot,TypeHistogram)"} {
        $::Ibrowser(plot,intervalPlot) axis configure x -title "voxel timecourse intensity" 
    } else {
        $::Ibrowser(plot,intervalPlot) axis configure x -title "volume number" 
    }
    
    IbrowserPlotAllSamples $i $j $k 

    set ::Ibrowser(x,voxelIndex) $i
    set ::Ibrowser(y,voxelIndex) $j
    set ::Ibrowser(z,voxelIndex) $k
}



#-------------------------------------------------------------------------------
# .PROC IbrowserDrawPlotAllSamples
# Plots the voxel intensity as function of the interval variable (e.g. time).
# .ARGS
# int x the x index of selected voxel 
# int y the y index of selected voxel 
# int z the z index of selected voxel 
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotAllSamples {x y z} {
    global Ibrowser 

    #--- create a time course extractor
    vtkVoxelTimeCourseExtractor ::Ibrowser(plot,TimeCourseExtractor)

    #--- set up the vtkVoxelTimeCourseExtractor
    set id $::Ibrowser(activeInterval)
    set first $::Ibrowser($id,firstMRMLid)
    set last $::Ibrowser($id,lastMRMLid)
    for { set id $first } { $id <= $last } { incr id } {
        ::Volume($id,vol) Update
        ::Ibrowser(plot,TimeCourseExtractor) AddInput [ ::Volume($id,vol) GetOutput ]
    }

    #--- signal (response) time course and its plotting dimensions
    set timeCourse [ ::Ibrowser(plot,TimeCourseExtractor) GetTimeCourse $x $y $z]

    set myRange [ $timeCourse GetRange]
    set sigmin [lindex $myRange 0]
    set max [lindex $myRange 1]
    set sigmax [expr {$max == 0 ? 1 : $max}]
    set totalVolumes [ $timeCourse GetNumberOfTuples]

    #--- unset any existing plot globals from last time.
    if { [info exists ::Ibrowser(plot,Signal) ] } {
        unset ::Ibrowser(plot,Signal)
    }
    set j 0
    while { $j < $::Ibrowser(plot,NumReferences) } {
        if { [info exists ::Ibrowser(plot,Ref$j) ] } {
            unset ::Ibrowser(plot,Ref$j)
        }
        incr j
    }

    #--- build signal Ibrowser(plot,Signal) and fill axis vector with ticks
    set i 0
    while {$i < $totalVolumes} {
        lappend xAxis [expr $i ]
        lappend ::Ibrowser(plot,Signal) [ $timeCourse GetComponent $i 0]
        incr i
    }
    #--- fill reference's axis vector with more finely sampled ticks
    set ::Ibrowser(plot,RefIncrement) 0.1
    set i 0
    while { $i < $totalVolumes} {
        lappend x2Axis [ expr $i ]
        set i [ expr $i + $::Ibrowser(plot,RefIncrement) ]
    }
    
    #--- associate signal axis vector and signal vector
    blt::vector xVecSig yVecSig
    xVecSig set $xAxis
    yVecSig set $::Ibrowser(plot,Signal)
    
    #--- build reference vectors Ibrowser(plot,Ref$j)
    set j 0
    set rmax -100000
    set rmin 100000
    while {$j < $::Ibrowser(plot,NumReferences)} {
        IbrowserBuildReferenceVector $j $max
        blt::vector xVecRef$j yVecRef$j
        #--- associate reference axis vector and signal vector
        xVecRef$j set $x2Axis
        yVecRef$j set $::Ibrowser(plot,Ref$j)
        #--- get max and min of all ref waveforms
        set i 0
        set len [ llength $::Ibrowser(plot,Ref$j) ]
        while { $i < $len } {
            set v [ lindex $::Ibrowser(plot,Ref$j) $i ]
            if { $v > $rmax } {
                set rmax $v }
            if { $v < $rmin } {
                set rmin $v }
            incr i
        }
        incr j
    }
    
    
    set xaxisMax [ expr $totalVolumes - 1 ]
    $::Ibrowser(plot,intervalPlot) axis configure x -min 0 -max $xaxisMax
    $::Ibrowser(plot,intervalPlot) axis configure y -min $sigmin \
        -max $sigmax

    #--- delete existing signal curves
    if {[info exists Ibrowser(plot,signalCurve)] &&
        [$::Ibrowser(plot,intervalPlot) element exists $::Ibrowser(plot,signalCurve)]} {
        $::Ibrowser(plot,intervalPlot) element delete $::Ibrowser(plot,signalCurve)
    }

    #--- delete existing ref curves
    set j 0
    while { $j < $::Ibrowser(plot,NumReferences) } {
        if { [info exists Ibrowser(plot,ref{$j}Curve) ] &&
            [$::Ibrowser(plot,intervalPlot) element exists $::Ibrowser(plot,ref{$j}Curve)]} {
            $::Ibrowser(plot,intervalPlot) element delete $::Ibrowser(plot,ref{$j}Curve)
        }
        incr j
    }

    #--- delete existing plot markers
    if {[info exists Ibrowser(voxelIndices)] &&
        [$::Ibrowser(plot,intervalPlot) marker exists $::Ibrowser(voxelIndices)]} {
        $::Ibrowser(plot,intervalPlot) marker delete $::Ibrowser(voxelIndices)
    }


    #--- create plot curve and marker elements
    #--- signal
    set Ibrowser(plot,signalCurve) signalCurve 
    $::Ibrowser(plot,intervalPlot) element create $::Ibrowser(plot,signalCurve) \
        -label "response" -xdata xVecSig -ydata yVecSig
    $::Ibrowser(plot,intervalPlot) element configure $::Ibrowser(plot,signalCurve) \
        -symbol none -color blue -linewidth 1 

    #--- make second set of axes visible if there is a ref signal
    if { $::Ibrowser(plot,NumReferences) != 0 } {
        $::Ibrowser(plot,intervalPlot) axis configure y2 -hide no
        $::Ibrowser(plot,intervalPlot) axis configure y2 -title "reference" 
        $::Ibrowser(plot,intervalPlot) axis configure y2 -color "#a7a7a7"
        $::Ibrowser(plot,intervalPlot) axis configure x2 -color "#a7a7a7"
    } else {
        $::Ibrowser(plot,intervalPlot) axis configure x2 y2 -hide yes
    }

    #--- all references
    set j 0
    while { $j < $::Ibrowser(plot,NumReferences) } {   
        set Ibrowser(plot,ref{$j}Curve) ref{$j}Curve
        set rname [ lindex $::Ibrowser(plot,RefNameList) $j ]
        set col [ lindex $::Ibrowser(plot,RefColorList) $j ]
        #--- create and configure the reference wave's curve.
        $::Ibrowser(plot,intervalPlot) element create $::Ibrowser(plot,ref{$j}Curve) \
            -label $rname -xdata xVecRef$j -ydata yVecRef$j
        $::Ibrowser(plot,intervalPlot) element configure $::Ibrowser(plot,ref{$j}Curve) \
            -symbol none -color $col -linewidth 1
        #--- now map it to the other axis since it's max and min will be different
        $::Ibrowser(plot,intervalPlot) element configure $::Ibrowser(plot,ref{$j}Curve) -mapx x2 -mapy y2
        $::Ibrowser(plot,intervalPlot) grid configure -mapx x2 -mapy y2
        #--- configure other axis limits
        set lx [ $::Ibrowser(plot,intervalPlot) axis limits x ]
        set ly [ $::Ibrowser(plot,intervalPlot) axis limits y ]
        $::Ibrowser(plot,intervalPlot) axis configure x2 -min [ lindex $lx 0] -max [lindex $lx 1]
        $::Ibrowser(plot,intervalPlot) axis configure y2 -min $rmin -max $rmax
        incr j
    }

    # mark voxel  indices
    set mx [ expr $totalVolumes - 1 ]
    set Ibrowser(voxelIndices) voxelIndices
    $::Ibrowser(plot,intervalPlot) marker create text -text "voxel: ($x,$y,$z)" \
        -coords {$mx $sigmax} \
        -yoffset 5 -xoffset -70 -name $::Ibrowser(voxelIndices) -under yes -bg white \
        -font $::IbrowserController(UI,Medfont)

    set Ibrowser(curPlotting) $::Ibrowser(plot,TypeVvvn)
    ::Ibrowser(plot,TimeCourseExtractor) Delete
}




#-------------------------------------------------------------------------------
# .PROC IbrowserClosePlotWindow
# Cleans up if the plotting window is closed 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserClosePlotWindow {} {

    #--- destroy windows and close them up.
    destroy $::Ibrowser(plot,intervalPlot)
    if { [info exists ::Ibrowser(plot,intervalPlot) ] } {
        unset -nocomplain ::Ibrowser(plot,intervalPlot)
    }
    if { [ info exists ::Ibrowser(plot,signalCurve)] } {
        unset -nocomplain ::Ibrowser(plot,signalCurve)
    }
    set i 0
    while { $i < $::Ibrowser(plot,NumReferences) } {
        if { [info exists ::Ibrowser(plot,ref{$i}Curve) ] } {
            unset -nocomplain ::Ibrowser(plot,ref{$i}Curve)
        }
        incr i
    }
    destroy $::Ibrowser(intervalPlotToplevel)
    if { [info exists ::Ibrowser(intervalPlotToplevel) ] } {
        unset ::Ibrowser(intervalPlotToplevel)
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserCheckDataVolumeDimensions
# Checks volume dimensions in the interval.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCheckDataVolumeDimensions {} {
    global Volume Ibrowser

    #--- for each volume in the selected (active) interval,
    #--- check to see what its dimensions are.
    #--- if dimensions differ among volumes, plotting won't
    #--- work, so pop up an error window for now and
    #--- return all zeros.

    set id $::Ibrowser(activeInterval)
    set first $::Ibrowser($id,firstMRMLid)
    set last $::Ibrowser($id,lastMRMLid)

    #--- set initial values for reference
    set xmin 0
    set ymin 0
    set zmin 0
    set DimList [ [ ::Volume($first,vol) GetOutput ] GetDimensions ]
    set refx [ expr [ lindex $DimList 0 ] - 1]
    set refy [ expr [ lindex $DimList 1 ] - 1]
    set refz [ expr [ lindex $DimList 2 ] - 1]        
    set error 0

    #--- now compare each volume in interval to reference dimensions
    for { set v $first } { $v <= $last } { incr v } {
        set DimList [ [ ::Volume($v,vol) GetOutput ] GetDimensions ]
        set x [ expr [ lindex $DimList 0 ] - 1]
        set y [ expr [ lindex $DimList 1 ] - 1]
        set z [ expr [ lindex $DimList 2 ] - 1]        
        #--- if dimensions don't match, flag an error
        if { ($x != $refx) || ($y != $refy) || ($z != $refz) } {
            set error 1
        }
    }

    if { $error == 0 } {
        return "$xmin $ymin $zmin $x $y $z"
    } else {
        return " 0 0 0 0 0 0"
    }

}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetVoxelFromSelection
# Gets a selected voxel's index 
# .ARGS
# int x the selected point's x index
# int y the selected point's y index
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetVoxelFromSelection {x y} {
    global Ibrowser Interactor Gui
    
    # Which slice was picked?
    set s $Interactor(s)
    if {$s == ""} {
        DevErrorWindow "No slice was picked."
        return "-1 -1 -1"
    }

    set xs $x
    set ys $y

    # Which xy coordinates were picked?
    scan [MainInteractorXY $s $xs $ys] "%d %d %d %d" xs ys x y

    #--- from which interval and which (FG or BG) slice should we take selection?
    set ai $::Ibrowser(activeInterval)
    if { $ai == $::Ibrowser(FGInterval) } {
        set fVol [$Interactor(activeSlicer) GetForeVolume $s]
        set fRef [$Interactor(activeSlicer) GetForeReformat $s]
    } elseif { $ai == $::Ibrowser(BGInterval) } {
        set fVol [$Interactor(activeSlicer) GetBackVolume $s]
        set fRef [$Interactor(activeSlicer) GetBackReformat $s]
    } else {
        DevErrorWindow "Put active interval into the foreground or background."
        return
    }

    $Interactor(activeSlicer) SetReformatPoint $fVol $fRef $s $x $y
    # Which voxel index (ijk) were picked?
    scan [$Interactor(activeSlicer) GetIjkPoint]  "%g %g %g" i j k

    # Let's snap to the nearest voxel
    set i [expr round ($i)]
    set j [expr round ($j)]    
    set k [expr round ($k)]
    
    return "$i $j $k"
}


#-------------------------------------------------------------------------------
# .PROC IbrowserCheckSelectionAgainstVolumeLimits
# Checks index of selected voxel against volume limits 
# .ARGS
# string argstr the data string
# .END
#-------------------------------------------------------------------------------
proc IbrowserCheckSelectionAgainstVolumeLimits {argstr} {

    scan $argstr "%d %d %d %d %d %d %d %d %d" i j k xmin ymin zmin xmax ymax zmax
    if {$i < $xmin || $j < $ymin || $k < $zmin} {
        return 0 
    }
    if {$i > $xmax || $j > $ymax || $k > $zmax} {
        return 0 
    }

    return 1 
}



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildReferenceVector
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildReferenceVector { refIndex sigMax } {
    #--- Builds the reference vector and stores in global

    #--- Get information on this reference
    set type [ lindex $::Ibrowser(plot,RefTypeList) $refIndex ]
    set height [ lindex $::Ibrowser(plot,RefHeightList) $refIndex ]
    #--- height represents a percentage of the signal maximum,
    #--- so convert this into a value.
    set height [ expr $sigMax * $height / 100.0 ]
    set kernelSamples [ lindex $::Ibrowser(plot,RefSpanList) $refIndex ]
    set kernelSamples [ expr $kernelSamples / $::Ibrowser(plot,RefIncrement) ]
    set onsets [ lindex $::Ibrowser(plot,RefOnsetList) $refIndex ]
    set numOnsets [ llength $onsets ]
    set id $::Ibrowser(activeInterval)
    set totalSamples [ expr $::Ibrowser($id,numDrops) / $::Ibrowser(plot,RefIncrement) ]

    #--- compute reference kernel
    switch $type {
        "" {
            return
        }
        "boxcar" {
            set kernel [ IbrowserMakeBoxcarKernel $kernelSamples $height ]
        }
        "impulse" {
            set kernel [ IbrowserMakeImpulseKernel $kernelSamples $height ]
        }
        "halfsine" {
            set kernel [ IbrowserMakeHalfsineKernel $kernelSamples $height ]
        }
        "HRF" {
            set kernel [ IbrowserMakeCanonicalHRFKernel $kernelSamples $height ]
        }
    }
    
    #--- zero out the reference vector
    set j 0
    while { $j < $totalSamples } {
        lappend ::Ibrowser(plot,Ref$refIndex) 0.0
        incr j
    }

    #--- assemble the reference vector from kernel
    set i 0
    while { $i < $numOnsets } {
        #--- which onset
        set indx [ lindex $onsets $i ]
        #--- which sample
        set indx [ expr round ($indx / $::Ibrowser(plot,RefIncrement)) ]
        set j 0
        while { $j < $kernelSamples } {
            #--- insert an instance of the kernel at each onset
            set val [ lindex $kernel $j ]
            set ::Ibrowser(plot,Ref$refIndex) [lreplace $::Ibrowser(plot,Ref$refIndex) $indx $indx $val]
            incr indx
            incr j
        }
        incr i
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserMakeBoxcarKernel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeBoxcarKernel { samps height } {
    #--- builds a list that defines a boxcar function
    #--- for the number of samples and max height requested
    set i 0
    while { $i < $samps } {
        lappend kernel $height
        incr i
    }
    return $kernel
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeImpulseKernel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeImpulseKernel { samps height } {
    set i 0
    while { $i < $samps } {
        lappend kernel $height
        incr i
    }
    return $kernel
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeHalfsineKernel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeHalfsineKernel { samps height } {
    set PI 3.14159265
    set period [ expr 2 * $samps ]
    set m [ expr 2 * $PI / $period ]
    #--- halfsine signal:
    set t 0
    while { $t < $samps } {
        set v [ expr sin($m * $t) ]
        set v [ expr $height * $v ]
        lappend kernel $v
        incr t
    }
    return $kernel
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeCanonicalHRFKernel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeCanonicalHRFKernel { samps height } {
    #--- computes a single hemodynamic response function
    #--- as difference of two gamma functions recommended in
    #--- G.H. Glover, "Deconvolution of impulse response in
    #--- event-related BOLD fMRI", Neuroimage 9, 416-29.
    #--- In t = 30 seconds, the HRF peaks, dips below zero and
    #--- comes back to baseline. So we squeeze 30 seconds into
    #--- the user-specified span.

    set HRFsamps $samps
    set tinc [ expr 30.0 / $HRFsamps ]
    set a1 6
    set a2 12
    set b1 0.9
    set b2 0.9
    set c 0.35
    set d1 [ expr $a1 * $b1 ]
    set d2 [ expr $a2 * $b2 ]

    #--- compute first gamma function g1
    set t 0
    for { set x 0 } { $x < $HRFsamps } { incr x } {
        set v [ expr pow ( ($t / $d1), $d1) * exp( -($t-$d1) / $b1) ]
        lappend g1 $v
        set t [ expr $t + $tinc ]
    }

    #--- compute second gamma function g2
    set t 0
    for { set x 0 } { $x < $HRFsamps } { incr x } {
        set v [ expr pow ( ($t / $d2), $d2) * exp( -($t-$d2) / $b2) ]
        lappend g2 $v
        set t [ expr $t + $tinc ]
    }

    #--- set kernel as difference of g1 and g2
    set max -100000.0
    set min 100000.0
    for { set x 0} { $x < $HRFsamps } { incr x } {
        set v1 [lindex $g1 $x ]
        set v2 [lindex $g2 $x ]
        set v [ expr $v1 - ($c * $v2) ]
        if { $v > $max } {
            set max $v
        }
        if { $v < $min } {
            set min $v
        }
        lappend kernel $v
    }
    unset g1
    unset g2

    #--- normalize to correct height
    if { $max != 0.0 } {
        set normHeight [ expr $height / $max ]
    } else {
        set normHeight 0.0
    }
    set i 0
    while { $i < $HRFsamps } {
        set v [ lindex $kernel $i ]
        set v [ expr $v * $normHeight ]
        set kernel [ lreplace $kernel $i $i $v ]
        incr i
    }
    return $kernel
}




