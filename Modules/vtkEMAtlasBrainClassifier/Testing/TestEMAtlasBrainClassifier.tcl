package require vtkSlicerBase
package require vtkITK

#for the NRRD Reader to load Reference Volume
package require vtkTeem 

#for EMAtlasBrainClassifier: Init
package require vtkEMLocalSegment

#ctest: test fails -> result is 1
#       test succeeds -> result is 0
set exitCode 5

source [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/tcl/EMAtlasBrainClassifier.tcl]
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
source [file join $::env(SLICER_HOME) Modules/vtkEMLocalSegment/tcl/EMLocalSegment.tcl]
source [file join $::env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]
source [file join $::env(SLICER_HOME) Modules/vtkTeem/tcl/VolNrrd.tcl]
source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainHelp.tcl]
#./slicer2-linux-x86_64 ~/schiz/slicer_auto_testing/xml-files/test/test/EMAtlasBrainClassifier.xml --no-tkcon --exec "EMAtlasBrainClassifier_BatchMode"
         
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

vtkMrmlSlicer Slicer   
proc MainSlicesSetVolumeAll {Layer v} {}
set Slice(idList) ""

# proc GuiInit {} {}
        
   set Gui(title) "Test"
 #  set Module(mainList) ""
 #  set Module(sharedList) ""
 #  MainInit

# stubs
proc MainShowProgress {filter} {}
proc MainEndProgress {} {}
proc SplashKill {} {}
# MainMrmlRead [file join $::env(SLICER_HOME) Modules/vtkAG/Testing/TestInput/AGRigid.xml]
MainMrmlRead [file join $::env(SLICER_HOME) Modules/vtkEMAtlasBrainClassifier/Testing/EMAtlasBrainClassifier2.xml]
MainUpdateMRML
 

EMAtlasBrainClassifierInit

if {0} {
#set EMAtlasBrainClassifier(BatchMode) 1
#set EMSegment(MrmlNode,TypeList) "Segmenter EndSegmenter SegmenterGraph SegmenterInput SegmenterSuperClass EndSegmenterSuperClass"
#set EMSegment(MrmlNode,TypeList) "$EMSegment(MrmlNode,TypeList) SegmenterClass EndSegmenterClass SegmenterCIM SegmenterPCAEigen"
#EMAtlasBrainClassifierInit

set Gui(activeWorkspace)  "#e2cdba"
EMSegmentInit
 
set EMAtlasBrainClassifier(WorkingDirectory) "/projects/schiz/guest/kquintus/slicer_auto_testing/EMAtlasBrainClassifier/test"
set EMAtlasBrainClassifier(Volume,SPGR) 1
set EMAtlasBrainClassifier(Volume,T2W) 2

# If you set EMAtlasBrainClassifier(BatchMode) to 1 also 
# set EMAtlasBrainClassifier(Save,*) otherwise when saving xml file 
# warning window comes up 
set EMAtlasBrainClassifier(Save,SPGR) 1
set EMAtlasBrainClassifier(Save,T2W)  1
set EMAtlasBrainClassifier(BatchMode) 1
set EMAtlasBrainClassifier(NumInputChannel) 1

set EMAtlasBrainClassifier(AlgorithmVersion) "Standard"
EMAtlasBrainClassifierChangeAlgorithm 
#set SucessFlag [EMAtlasBrainClassifierStartSegmentation]
}
if {0} {

    # Set Parameters for EMAtlasBrainClassifier
    ###########################################
   
EMSegmentUseSamples
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

#puts "Result: $exitCode"
#exit $exitCode
