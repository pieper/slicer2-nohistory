package require vtkSlicerBase
package require vtkAG
package require vtkITK

#for the NRRD Reader to load Reference Volume
package require vtkTeem 

#ctest: test fails -> exitCode is 1
#       test succeeds -> exitCode is 0
set exitCode 5

proc RunTest {{init 0}} {
    global Path Volume Lut Module Model Volumes AG Slicer Slice exitCode

    if {$init==1} {
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainFile.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainMrml.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/Gui.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MRMLapi.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/Main.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-modules/Volumes.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainVolumes.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainColors.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainLuts.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainModels.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainModelGroups.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainTetraMesh.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainAlignments.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/Parse.tcl]
        source [file join $::env(SLICER_HOME) Modules/vtkAG/tcl/AG.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]
        source [file join $::env(SLICER_HOME) Modules/vtkTeem/tcl/VolNrrd.tcl]
                
        # all these Initialisations to use the MRML-tree and to be able to run the RunAG proc
 
    set Module(procMRML) ""
        set Path(program) [file join $::env(SLICER_HOME) Base/tcl]

        MainMrmlInit

        MainVolumesInit
        set Module(verbose) 0

        MainColorsInit
        MainLutsInit
        MainLutsBuildVTK

        # Make the None Volume, which can never be deleted
        #---------------------------------------------------

        set v $Volume(idNone)

        vtkMrmlVolumeNode Volume($v,node)
        set n Volume($v,node)
        $n SetID $v
        $n SetName "None"
        $n SetDescription "NoneVolume=$v"
        $n SetLUTName 0

        vtkMrmlDataVolume Volume($v,vol)
        Volume($v,vol) SetMrmlNode         Volume($v,node)

        #could not find a more pretty solution for now:
        set Module(idList) Data

        MainModelsInit

        #just to have a volume
        set Model(fScrolledGUI) dummy 

        MainTetraMeshInit

        MainAlignmentsInit
        MainAlignmentsBuildVTK
        
        AGInit
        vtkMrmlSlicer Slicer   
        proc MainSlicesSetVolumeAll {Layer v} {
        }
        set Slice(idList) ""
        
    }

    # stubs
    proc MainShowProgress {filter} {}
    proc MainEndProgress {} {}

    MainMrmlRead [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestInput/AGRigid.xml]
    MainUpdateMRML

    # Set Parameters for AG
    set AG(InputVolSource) 1
    set AG(InputVolTarget) 2
    set AG(ResultVol) -5
    set AG(Gcr_criterion) 4
    set AG(LRName) "rigid group"
    set AG(IntensityTFMName) "no intensity transform"
    set AG(CriterionName) "mutual information"
    
    # Method: Non-linear
    set AG(Warp) 0
    set AG(Intensity_tfm) "none"
    set AG(Linear_group) 0
    set AG(WarpName) "demons"

    RunAG

    # Save Volume
    set Volume(activeID) 3
    set Volume(UseCompression) 1
    set Volumes(extentionGenericSave) "nhdr"
    set Volumes(prefixGenericSave) [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestOutput/nightly_AG_Result.nhdr]
    VolumesGenericExport

    # Subtract AG Result from the Reference Volume

    #stub: needed so that VolNrrdApply can be called without sourcing all the View and GUI stuff  
    proc MainViewSetFov {s1 s2} {
    }
    
    vtkNRRDReader nr
    nr SetFileName [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestInput/Baseline/AG_Reference_Result.nhdr]
    nr Update

    # Prepare a Volume for the subtraction result like it has
    # been done in VolumeMathPrepareResultVolume
    set difference [DevCreateNewCopiedVolume 3 "" "Difference"]
    set node [Volume($difference,vol) GetMrmlNode]
    Mrml(dataTree) RemoveItem $node 
    set nodeBefore [Volume(3,vol) GetMrmlNode]
    Mrml(dataTree) InsertAfterItem $nodeBefore $node
    MainUpdateMRML
    
    # hard coded numbers, not pretty

    set subtrahend 3
    set minuend 4

    # Set up the VolumeMath Subtract

    vtkImageMathematics SubMath
    SubMath SetInput1 [nr GetOutput]
    SubMath SetInput2 [Volume($subtrahend,vol) GetOutput]
    SubMath SetOperationToSubtract
    Volume($difference,vol) SetImageData [SubMath GetOutput]
    MainVolumesUpdate $difference
    SubMath Delete
    nr Delete
    
    # Save Difference Volume
    
    set Volume(activeID) 4
    set Volume(UseCompression) 1
    set Volumes(extentionGenericSave) "nhdr"
    set Volumes(prefixGenericSave) [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestOutput/difference.nhdr]
    VolumesGenericExport

    #Now do the statistics

    vtkImageStatistics stat
    stat SetInput [Volume($difference,vol) GetOutput]
    stat Update
    set min [stat GetMin] 
    set max [stat GetMax]
    set mean [stat GetAverage]
    set std [stat GetStdev]
    puts "The nightly AG-Result has been saved in [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestOutput/nightly_AG_Result.nhdr]."
    puts "Difference between baseline and nightly AG-Result has been saved in [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestOutput/difference.nhdr]."
    puts ""
    puts "Statistics of the difference image:"
    puts "min: $min"
    puts "max: $max"
    puts "mean: $mean"
    puts "std: $std"
    if {$min == 0 && $max == 0} {
        set exitCode 0
    } else {
        set exitCode 1
    }
}

puts "CTEST_FULL_OUTPUT"
RunTest 1

puts ""
if {$exitCode == 0} {
    puts "ExitCode: $exitCode"
    puts "Test passed"
} else {
    puts "Result: $exitCode"
    puts "Test failed"
}

exit $exitCode
