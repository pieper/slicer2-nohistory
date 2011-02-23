package require vtkSlicerBase
package require vtkRealignResample 

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
source [file join $::env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]
source [file join $::env(SLICER_HOME) Modules/vtkTeem/tcl/VolNrrd.tcl]
source [file join $::env(SLICER_HOME) Modules/vtkRealignResample/tcl/RealignResample.tcl]               
source [file join $::env(SLICER_HOME) Base/tcl/tcl-modules/Fiducials.tcl]                
source [file join $::env(SLICER_HOME) Base/tcl/tcl-main/MainOptions.tcl]                

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
proc RenderAll { {scale ""}} {}

FiducialsInit
RealignResampleInit
set RealignResample(MidlineList) "midsag"
set RealignResample(ACPCList) "acpc"

MainMrmlRead [file join $::env(SLICER_HOME) Modules/vtkRealignResample/Testing/TestInput/RealignResample.xml]
MainUpdateMRML

proc FiducialsSliceNumberToRendererName { s } {}
FiducialsBuildVTK
set Fiducials(renList) ""
set Fiducials(renList2D) ""
proc Render3D {{scale ""}} {}
proc RenderSlices {{scale ""}} {}
set Fiducials(fScrolledGUI) ""
proc FiducialsCreateGUI {f id} {}
proc FiducialsSetFiducialsVisibility {name {visibility ""} {rendererName ""}} {}

proc FiducialsCreateGUI {f id} {return 1}
set Fiducials(canvasScrolledGUI) ""
proc FiducialsConfigScrolledGUI {canvasScrolledGUI fScrolledGUI} {}

FiducialsUpdateMRML
RealignCalculate

MainMrmlImport [file join $::env(SLICER_HOME) Modules/vtkRealignResample/Testing/TestInput/baseline_matrix.xml]
MainUpdateMRML

puts "CTEST_FULL_OUTPUT"
puts "\nBaseline matrix:"
puts "----------------------------"
set baseline [[Matrix(1,node) GetTransform] GetMatrix] 

for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            puts -nonewline "[$baseline GetElement $i $j] "
        }
    puts ""
}

puts "\nNightly realign result matrix:"
puts "-------------------------------------------------"
set nightly_matrix [[Matrix(0,node) GetTransform] GetMatrix] 

for {set i 0} {$i < 4} {incr i} {
    for {set j 0} {$j < 4} {incr j} {
        puts -nonewline "[$nightly_matrix GetElement $i $j] "
    }
    puts ""
}

puts "\nDifference between nightly result and baseline:"
puts "-----------------------------------------------------------"

#ctest: test fails -> result is 1
#       test succeeds -> result is 0
set exitCode 0

for {set i 0} {$i < 4} {incr i} {
    for {set j 0} {$j < 4} {incr j} {
        set diff [expr {[$baseline GetElement $i $j]-[$nightly_matrix GetElement $i $j]}] 
        puts -nonewline $diff
        if {$diff!=0} {
            set exitCode 1
        }
    }
    puts ""    
}
puts ""
puts "Exit code: $exitCode"
puts ""    
if {$exitCode == 0} {
    puts "Test passed."
} else {
    puts "Test failed."
}
exit $exitCode
