#=auto==========================================================================
# (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
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
# FILE:        FSLReaderPlot.tcl
# PROCEDURES:  
#   FSLReaderPopUpPlot x y
#   FSLReaderDrawPlotLong x y z
#   FSLReaderCloseTimeCourseWindow
#   FSLReaderGetDataVolumeDimensions
#   FSLReaderGetVoxelFromSelection x y
#   FSLReaderCheckSelectionAgainstVolumeLimits argstr
#   FSLReaderLoadModel
#   FSLReaderCloseTimeSeriesGraphWindow
#   FSLReaderSelectTimeSeriesGraph
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC FSLReaderPopUpPlot
# This routine pops up a plot of a selected voxel's response over
# time, overlayed onto a reference signal. This reference may be the
# experimental protocol, or the protocol convolved with a hemodynamic
# response function.
# .ARGS
# int x the selected point's x coord
# int y the selected point's y coord
# .END
#-------------------------------------------------------------------------------
proc FSLReaderPopUpPlot {x y} {
    global FSLReader Interactor Volume

    if {[$FSLReader(gui,voxelWiseButton) cget -state] == "disabled" ||
        $FSLReader(tcPlotOption) == "fsl"} {
        return
    }

    set id [MIRIADSegmentGetVolumeByName "example_func"] 
    set ext [[Volume($id,vol) GetOutput] GetWholeExtent]
    set FSLReader(volextent) $ext 

    # Get the indices of selected voxel. Then, check
    # these indices against the dimensions of the volume.
    # If they're good values, assemble the selected voxel's
    # time-course, the reference signal, and plot both.
    scan [FSLReaderGetVoxelFromSelection $x $y] "%d %d %d" i j k
    if {$i == -1} {
        return
    }

    scan [FSLReaderGetDataVolumeDimensions] "%d %d %d %d %d %d" \
        xmin ymin zmin xmax ymax zmax

    # Check to make sure that the selected voxel
    # is within the data volume. If not, return.
    set argstr "$i $j $k $xmin $ymin $zmin $xmax $ymax $zmax"
    if { [ FSLReaderCheckSelectionAgainstVolumeLimits $argstr] == 0 } {
        # DevErrorWindow "Selected voxel not in volume."
        return 
    }

    set s $Interactor(s)
    set fvName [[[Slicer GetForeVolume $s] GetMrmlNode] GetName]
    set overlay $FSLReader(currentOverlayVolumeName)
    if {$fvName != $overlay} {
        DevErrorWindow "The foreground volume displayed is different from the one selected."
        return
    }

    # voxel time course - a vtkFloatArray
    set timecourse [FSLReader(timecourseExtractor) GetTimeCourse $i $j $k]

    # model data
    set overlay $FSLReader(currentOverlayVolumeName)
    if {! [info exists FSLReader($overlay,model)]} {
        FSLReaderLoadModel $overlay
    }

    set plotTitle "Time Course ($overlay)"
    set plotHeight 250 
#    set plotGeometry "+335+200"
    set plotGeometry "+300+200"

    if {$FSLReader(noOfFuncVolumes) > 100} { 
        set plotWidth 850
        set graphWidth 850
    } else {
        set plotWidth 700
        set graphWidth 700
    }

    # Plot the time course
    if {! [info exists FSLReader(timeCourseToplevel)]} {
        set w .tcren
        toplevel $w
        wm title $w $plotTitle 
        wm minsize $w $plotWidth $plotHeight
        wm geometry $w $plotGeometry 

        blt::graph $w.graph -plotbackground white -width $graphWidth -height $plotHeight
        pack $w.graph 
        $w.graph legend configure -position bottom -relief raised \
            -font fixed -fg black 
        $w.graph axis configure y -title "Intensity"
        # $w.graph grid on
        # $w.graph grid configure -color black

        wm protocol $w WM_DELETE_WINDOW "FSLReaderCloseTimeCourseWindow" 

        set FSLReader(timeCourseToplevel) $w
        set FSLReader(timeCourseGraph) $w.graph
        $FSLReader(timeCourseGraph) axis configure x -title "Volume Number" 
    }

    # real plotting
    FSLReaderPlotTimecourse $i $j $k $timecourse $FSLReader($overlay,model) 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderDrawPlotLong
# Draws time course plot in long format 
# .ARGS
# int x the x index of voxel whose time course is to be plotted
# int y the y index of voxel whose time course is to be plotted
# int z the z index of voxel whose time course is to be plotted
# .END
#-------------------------------------------------------------------------------
proc FSLReaderPlotTimecourse {x y z data model} {
    global FSLReader

    # clean variables
    unset -nocomplain FSLReader(signalArray,plotting)
    unset -nocomplain FSLReader(modelArray,plotting)

    # signal (response) time course
    set myRange [$data GetRange]
    set timeCourseYMin [lindex $myRange 0]
    set max [lindex $myRange 1]
    set timeCourseYMax [expr {$max == 0 ? 1 : $max}] 

    # get min and max of this model 
    set modelMin 1000000 
    set modelMax -1000000
    foreach v $model { 
        if {$v > $modelMax} {
            set modelMax $v
        }
        if {$v < $modelMin} {
            set modelMin $v
        }
    }

    set modelMinToBe [expr {$timeCourseYMin + ($timeCourseYMax-$timeCourseYMin) / 4}]
    set modelMaxToBe [expr {$timeCourseYMax - ($timeCourseYMax-$timeCourseYMin) / 4}]
    set totalVolumes [$data GetNumberOfTuples]

    set i 0
    while {$i < $totalVolumes} {
        lappend xAxis [expr $i + 1]
        lappend FSLReader(signalArray,plotting) [$data GetComponent $i 0]

        set m [lindex $model $i]
        set nm [expr {(($modelMaxToBe-$modelMinToBe) * ($m-$modelMin) / ($modelMax-$modelMin)) + $modelMinToBe}]
        lappend FSLReader(modelArray,plotting) $nm 

        incr i
    }

    $FSLReader(timeCourseGraph) axis configure x -min 1 -max $totalVolumes 
    $FSLReader(timeCourseGraph) axis configure y \
        -min $timeCourseYMin -max $timeCourseYMax

    blt::vector xVecSig yVecSig xVecModel yVecModel
    xVecSig set $xAxis
    yVecSig set $FSLReader(signalArray,plotting)

    xVecModel set $xAxis
    yVecModel set $FSLReader(modelArray,plotting)
   
    if {[info exists FSLReader(signalCurve)] &&
        [$FSLReader(timeCourseGraph) element exists $FSLReader(signalCurve)]} {
        $FSLReader(timeCourseGraph) element delete $FSLReader(signalCurve)
    }
    if {[info exists FSLReader(modelCurve)] &&
        [$FSLReader(timeCourseGraph) element exists $FSLReader(modelCurve)]} {
        $FSLReader(timeCourseGraph) element delete $FSLReader(modelCurve)
    }
    if {[info exists FSLReader(voxelIndices)] &&
        [$FSLReader(timeCourseGraph) marker exists $FSLReader(voxelIndices)]} {
        $FSLReader(timeCourseGraph) marker delete $FSLReader(voxelIndices)
    }

    set FSLReader(signalCurve) signalCurve 
    set FSLReader(modelCurve) modelCurve 
    set FSLReader(voxelIndices) voxelIndices

    $FSLReader(timeCourseGraph) element create $FSLReader(signalCurve) \
        -label "response" -xdata xVecSig -ydata yVecSig
    $FSLReader(timeCourseGraph) element configure $FSLReader(signalCurve) \
        -symbol none -color red -linewidth 1 
    $FSLReader(timeCourseGraph) element create $FSLReader(modelCurve) \
        -label "Full model" -xdata xVecModel -ydata yVecModel
    $FSLReader(timeCourseGraph) element configure $FSLReader(modelCurve) \
        -symbol none -color blue -linewidth 1 

    # Voxel indices
    $FSLReader(timeCourseGraph) marker create text -text "Voxel: ($x,$y,$z)" \
        -coords {$totalVolumes $timeCourseYMax} \
        -yoffset 5 -xoffset -70 -name $FSLReader(voxelIndices) -under yes -bg white \
        -font fixed 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderCloseTimeCourseWindow
# Cleans up if the time course window is closed 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderCloseTimeCourseWindow {} {
    global FSLReader

    if {[info exists FSLReader(timeCourseToplevel)]} {
        destroy $FSLReader(timeCourseToplevel)
        
        unset -nocomplain FSLReader(timeCourseToplevel)
        unset -nocomplain FSLReader(timeCourseGraph)
        unset -nocomplain FSLReader(signalCurve)]
        unset -nocomplain FSLReader(modelCurve)]
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderGetDataVolumeDimensions
# Gets volume dimensions 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderGetDataVolumeDimensions {} {
    global Volume FSLReader

    set ext $FSLReader(volextent) 

    set xmin [lindex $ext 0]
    set xmax [lindex $ext 1]
    set ymin [lindex $ext 2]
    set ymax [lindex $ext 3]
    set zmin [lindex $ext 4]
    set zmax [lindex $ext 5]

    return "$xmin $ymin $zmin $xmax $ymax $zmax"
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderGetVoxelFromSelection
# Gets voxel index from the selection 
# .ARGS
# int x the selected point's x coord
# int y the selected point's y coord
# .END
#-------------------------------------------------------------------------------
proc FSLReaderGetVoxelFromSelection {x y} {
    global FSLReader Interactor Gui
    
    # Which slice was picked?
    set s $Interactor(s)
    if {$s == ""} {
        DevErrorWindow "No slice was picked."
        return "-1 -1 -1"
    }

if {0} {
    set fvName [[[Slicer GetForeVolume $s] GetMrmlNode] GetName]
    set start [string first "_" $fvName 0]
    set end [string first "-" $fvName 0]
    set name [string range $fvName [expr $start + 1] [expr $end - 1]]

    if {[info command FSLReader($name,model)] == ""} {
        DevErrorWindow "To view time series, you need to load an activation as your \
        foreground image."
        return "-1 -1 -1"
    }

    # Make sure back volume exists
    set bvName [[[Slicer GetBackVolume $s] GetMrmlNode] GetName]
    if {$bvName == "None"} {
        DevErrorWindow "Background volume is empty."
        return "-1 -1 -1"
    }

    if {$FSLReader(bgOption) == "Other-Volume" && 
        $FSLReader(bgVolName) != $bvName} {
        DevErrorWindow "Please load or select a right background volume."
        return "-1 -1 -1"
    }

    set b [string first "filtered_func_data" $bvName 0]
    if {$FSLReader(bgOption) == "Time-Series-Volume" && 
        $b == -1} {
        DevErrorWindow "Please select a time series volume as your background image."
        return "-1 -1 -1"
    }

    set FSLReader(currentModelName) $name
}

    set xs $x
    set ys $y

    # Which xy coordinates were picked?
    scan [MainInteractorXY $s $xs $ys] "%d %d %d %d" xs ys x y
    # puts "Click: $s $x $y"

    # Which voxel index (ijk) were picked?
    $Interactor(activeSlicer) SetReformatPoint $s $x $y
    scan [$Interactor(activeSlicer) GetIjkPoint]  "%g %g %g" i j k
    # puts "Voxel coords: $i $j $k"

    # Let's snap to the nearest voxel
    set i [expr round ($i) ]
    set j [expr round ($j) ]    
    set k [expr round ($k) ]
    # puts "Rounded voxel coords: $i $j $k"
    puts "Voxel coords: $i $j $k"
    
    return "$i $j $k"
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderCheckSelectionAgainstVolumeLimits
# Checks voxel selection against volume limits 
# .ARGS
# string argstr the data string
# .END
#-------------------------------------------------------------------------------
proc FSLReaderCheckSelectionAgainstVolumeLimits {argstr} {

    scan $argstr "%d %d %d %d %d %d %d %d %d" i j k xmin ymin zmin xmax ymax zmax
    # puts "argstr = $argstr"
    if {$i < $xmin || $j < $ymin || $k < $zmin} {
        return 0 
    }
    if {$i > $xmax || $j > $ymax || $k > $zmax} {
        return 0 
    }

    return 1 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderLoadModel
# Loads a model from tsplot directory 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderLoadModel {overlay} {
    global FSLReader 

    set i [string first "/" $overlay 0]
    set fName [string range $overlay [expr $i+1] end]
    set fileName [file join $FSLReader(featDir) tsplot tsplot_$fName.txt] 

    if {! [file exists $fileName]} {
        DevErrorWindow "File doesn't exist: $fileName."
        return
    }

    # Reads file
    set fp [open $fileName r]
    set data [string trim [read $fp]]
    set lines [split $data "\n"]
    close $fp

    if {! [info exists FSLReader($overlay,model)]} {
        unset -nocomplain FSLReader($overlay,model)
    }

    set count 0
    set i [string first "f" $overlay]
    set n [expr {$i == -1 ? 2 : 1}] 
    foreach l $lines {
        set tokens [split $l " "]
        set v [lindex $tokens $n]

        # convert string to float
        set index [string first "e" $v]
        if {$index != -1} {
            set f [string range $v 0 [expr $index-1]]
            set e [string range $v [expr $index+2] end]
        }
        set v [expr {$f * pow(10,$e)}]

        lappend FSLReader($overlay,model) $v 
        incr count
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderCloseTimeSeriesGraphWindow
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderCloseTimeSeriesGraphWindow {} {
    global FSLReader Gui

    if {[info exists FSLReader(timecourseGraphToplevel)]} {
        destroy $FSLReader(timecourseGraphToplevel)
        unset -nocomplain $FSLReader(timecourseGraphToplevel)
    }
}

#-------------------------------------------------------------------------------
# .PROC FSLReaderSelectTimeSeriesGraph
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderSelectTimeSeriesGraph {gif} {
    global FSLReader Gui

    # configure menubutton
    $FSLReader(gui,gifMenuButton) config -text $gif 
    set FSLReader(currentNativeTimeSeriesName) $gif 

    FSLReaderCloseTimeSeriesGraphWindow
 
    if {$gif != "none"} {
        set w .tcGraph
        toplevel $w
        wm title $w $gif
        set FSLReader(timecourseGraphToplevel) $w 

        set img [file join $FSLReader(featDir) tsplot $gif] 
        set uselogo [image create photo -file $img]
        set height [image height $uselogo]
        set width [image width $uselogo]
        wm minsize $w $width $height 
        wm geometry $w +315+300 
        wm protocol $w WM_DELETE_WINDOW "FSLReaderCloseTimeSeriesGraphWindow"

        eval {label $w.lLogoImages -width $width -height $height \
            -image $uselogo -justify center} $Gui(BLA)

        button $w.bClose -text "Close" -font fixed -command "FSLReaderCloseTimeSeriesGraphWindow"
        pack $w.lLogoImages $w.bClose -side top -padx 5 -pady 5 -expand 1 
    }
}
 

