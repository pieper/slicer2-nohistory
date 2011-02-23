package require vtkSlicerBase
package require vtkITK
package require vtkTeem 
#for the NRRD Reader to load Reference Volume
package require iSlicer

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
source [file join $::env(SLICER_HOME) Base/tcl/tcl-modules/Alignments.tcl]
source [file join $::env(SLICER_HOME) Modules/vtkAG/tcl/AG.tcl]
source [file join $::env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]
source [file join $::env(SLICER_HOME) Modules/vtkTeem/tcl/VolNrrd.tcl]
source [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/tcl/TransformVolume.tcl]
source [file join $::env(SLICER_HOME) Base/tcl/tcl-modules/Data.tcl]
source [file join $::env(SLICER_HOME) Modules/iSlicer/tcl/isvolumeoption.tcl]

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
proc MainSlicesSetVolumeAll {Layer v} {
}
set Slice(idList) ""
AlignmentsInit

# stubs
proc MainShowProgress {filter} {}
proc MainEndProgress {} {}

#Read the xml file
MainMrmlRead [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestInput/TransformVolume.xml]
MainUpdateMRML

DataInit

# Transform Volume 
TransformVolumeInit

set TransformVolume(OutputDimensionI) 256
set TransformVolume(OutputDimensionIS) 256
set TransformVolume(OutputDimensionJ) 256
set TransformVolume(OutputDimensionK) 124
set TransformVolume(OutputDimensionLR) 256
set TransformVolume(OutputDimensionPA) 269
set TransformVolume(OutputOrientation) "PA"
set TransformVolume(OutputSpacingI) 0.9375
set TransformVolume(OutputSpacingIS) 0.9375
set TransformVolume(OutputSpacingJ) 0.9375
set TransformVolume(OutputSpacingK) 1.5
set TransformVolume(OutputSpacingLR) 0.9375
set TransformVolume(OutputSpacingPA) 0.9375
set TransformVolume(RefVolume) 1
set TransformVolume(ResamplingMode) 2

set TransformVolume(VolIDs) 1
istransformoption .matopt
set TransformVolume(transform) .matopt
isvolumeoption  .volopt
set TransformVolume(displacementVol) .volopt
$TransformVolume(displacementVol) numScalars 3
$TransformVolume(displacementVol) allowNone 1
$TransformVolume(displacementVol) initSelection

proc ScrolledListbox {f xAlways yAlways {args ""}} {
    listbox .list 
    return .list
}
set Data(fNodeList) [ScrolledListbox $f.list 0 0 -height 16 -selectmode extended]

proc RenderAll {} {}

iwidgets::pushbutton  .brun
set TransformVolume(brun) .brun

TransformVolumeRun

# Save Volume

set Volume(activeID) 2
set Volume(UseCompression) 1
set Volumes(extentionGenericSave) "nhdr"
set Volumes(prefixGenericSave) [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestOutput/nightly_Result.nhdr]
VolumesGenericExport

# Subtract nightly result from the baseline

#stub: needed so that VolNrrdApply can be called without sourcing all the View and GUI stuff  
proc MainViewSetFov {s1 s2} { }

vtkNRRDReader nr
nr SetFileName [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestInput/baselineTransformVolume.nhdr]
#nr SetFileName [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestInput/test.nhdr]

nr Update

# Prepare a Volume for the subtraction result like it has
# been done in VolumeMathPrepareResultVolume
set difference [DevCreateNewCopiedVolume 2 "" "Difference"]
set node [Volume($difference,vol) GetMrmlNode]
Mrml(dataTree) RemoveItem $node 
set nodeBefore [Volume(2,vol) GetMrmlNode]
Mrml(dataTree) InsertAfterItem $nodeBefore $node
MainUpdateMRML

set subtrahend 2

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

set Volume(activeID) 3
set Volume(UseCompression) 1
set Volumes(extentionGenericSave) "nhdr"
set Volumes(prefixGenericSave) [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestOutput/difference.nhdr]
VolumesGenericExport

#ctest: test fails -> exitCode is 1
#       test succeeds -> exitCode is 0
set exitCode 5


#Now do the statistics

vtkImageStatistics stat
stat SetInput [Volume($difference,vol) GetOutput]
stat Update
set min [stat GetMin] 
set max [stat GetMax]
set mean [stat GetAverage]
set std [stat GetStdev]
stat Delete
puts "CTEST_FULL_OUTPUT"
puts "The nightly transformation result has been saved in [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestOutput/nightlyTransformResult.nhdr]."
puts "Difference between baseline and nightly transformation Result has been saved in [file join $::env(SLICER_HOME) Modules/vtkTransformVolume/Testing/TestOutput/difference.nhdr]."
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

TransformVolumeExit
  
if {$exitCode == 0} {
    puts "Test passed."
} else {
    puts "Test failed."
}
exit $exitCode
