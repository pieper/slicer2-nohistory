#for the NRRD Reader to load Reference Volume
package require vtkTeem
package require vtkSlicerBase
package require vtkITK

source [file join $::env(SLICER_HOME) Modules/vtkTeem/tcl/VolNrrd.tcl]

set errorCode -1
puts "CTEST_FULL_OUTPUT"
 
set baseline_path [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/Baseline/EMSegmentation_aug162006_linux_single_thread/EMResult.nhdr]
#set baseline_path [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/Baseline/EMSegmentation_aug162006_linux_multi_thread/EMResult.nhdr]
if {[file exists $baseline_path]} {
    catch "vtkNRRDReader nr_base"
    nr_base SetFileName $baseline_path
    nr_base Update
    
    set nightly_path [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult.nhdr]
    if {[file exists $nightly_path]} {
    puts "Comparing basline EMResult in $baseline_path to nightly EMResult in $nightly_path ."
    catch "vtkNRRDReader nr_nightly"
    nr_nightly SetFileName $nightly_path
    nr_nightly Update
    
    # Set up the VolumeMath Subtract
    
    catch "vtkImageMathematics SubMath"
    SubMath SetInput1 [nr_base GetOutput]
    SubMath SetInput2 [nr_nightly GetOutput]
    SubMath SetOperationToSubtract
    
    #Now do the statistics
    
    catch "vtkImageStatistics stat"
    stat SetInput [SubMath GetOutput]
    stat Update
    set min [stat GetMin] 
    set max [stat GetMax]
    set mean [stat GetAverage]
    set std [stat GetStdev]


    ############################
    #[SubMath GetOutput] -> vtkImageData
    #[[SubMath GetOutput] GetPointData] -> vtkPointData 
    #[[SubMath GetOutput] GetPointData] GetScalars] Print : vtkShortArray

    set numberOfPoints [[SubMath GetOutput] GetNumberOfPoints]
    set countNonZero 0
    for {set i 0} {$i < $numberOfPoints} {incr i} {
        set value [[[[SubMath GetOutput] GetPointData] GetScalars] GetValue $i]
        if {$value != 0} {
        #puts "ID: $i, Value: $value"
        incr countNonZero
        }
    }

    nr_base Delete
    nr_nightly Delete
    
    set somethingIswrong 0
    #rename to make sure that next time not the old files are used.
    if {[catch "file rename -force [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult.nhdr] [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult_old.nhdr]"] == 1} { 
        puts "Could not rename [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult.nhdr] "
        set somethingIswrong 1
    }
    
    
    if {[catch "file rename -force [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult.raw.gz] [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult_old.raw.gz]"] == 1} {
        puts "Could not rename [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/EMSegmentation/EMResult.raw.gz]"
        set somethingIswrong 1
    }
    
    if {[catch "file rename -force [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/atlas] [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/atlas_old]"] == 1} {
        puts "Could not rename [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/atlas]"
        set somethingIswrong 1
    }
    
    if {[catch "file rename -force [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/spgr] [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/spgr_old]"] == 1} {
        puts "Could not rename [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/spgr]"
        set somethingIswrong 1
    }
    
    
    if {[catch "file rename -force [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/t2w] [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/t2w_old]"] == 1} {
        puts "Could not rename [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/TestOutAndInput/t2w]"
        set somethingIswrong 1
    }
    if {$somethingIswrong !=1} {
        set percents [expr { $countNonZero/($numberOfPoints + 0.0) }]
        
        #puts "Difference between baseline and nightly EMAtlasBrainClassifier-Result has been saved in [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestOutput/difference.nhdr]."
        puts "======================================================================== "
        puts "Difference between baseline and nightly EMAtlasBrainClassifier-Result:"
        #puts "min: $min"
        #puts "max: $max"
        #    puts "mean: $mean"
        #    puts "std: $std"
        puts [format "Difference as percentage: %.6f%%" $percents]
        puts "That is $countNonZero out of $numberOfPoints voxel differ in their label."
        puts "======================================================================== "
        if {$min == 0 && $max == 0} {
        set errorCode 0
        } else {
        set errorCode 1
        }
    } else {
        puts "Files or directories could not be found, please check!"
        set errorCode 1
    }
    } else {
    puts "Segmentation result in $nightly_path could not be opened."
    set errorCode 1
    }
} else {
    puts "Baseline Volume in $baseline_path could not be opened."
    set errorCode 1
}

puts "ErrorCode: $errorCode"
if {$errorCode == 0} {
    puts "Test passed."
} else {
    puts "Test failed."
}

exit $errorCode


