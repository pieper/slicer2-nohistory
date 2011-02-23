package require vtkSlicerBase


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
source [file join $::env(SLICER_HOME) Base/tcl/tcl-modules/VolumeMath.tcl]
source [file join $::env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]


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

#stubs
proc MainShowProgress {filter} {}
proc MainEndProgress {} {}

# in the test no message boxes should pop up since it runs as a batch process
proc tk_messageBox {{a 0} {b 0} {c 0} {d 0} {e 0} {f 0} {g 0} {h 0}} {}

MainMrmlRead [file join $::env(SLICER_HOME) Base/Testing/TestInput/MaskStat.xml]
MainUpdateMRML

VolumeMathInit

# set MaskStat input
# ------------------
set VolumeMath(fileName) [file join $::env(SLICER_HOME) Base/Testing/TestOutput/maskStat.hist.txt]
set VolumeMath(maskLabel) 4
set VolumeMath(MathType) "MaskStat"

# Label map/the mask
set VolumeMath(Volume1) 2

# Volume to mask: the spgr
set VolumeMath(Volume2) 1

# Masked output: create new
set VolumeMath(Volume3) -5

# Do the volume mask
# ------------------
VolumeMathDoMaskStat


#  Open the Baseline 
set fp [open [file join $::env(SLICER_HOME) Base/Testing/Baseline/maskStatBaseline.hist.txt] r]
set data [read $fp]
close $fp
set data [split $data "\n"]

#tell CTest that I require the full output of the test
puts "CTEST_FULL_OUTPUT"

puts "\nBaseline mask statistics:"
puts "----------------------------"

set new [split [regsub -all {[ \t\n]+} $data { }]]
set b_min [lindex $new 2]
set b_max [lindex $new 4]
set b_mean [lindex $new 6]
set b_std [lindex $new 8]
puts "Min: $b_min"
puts "Max: $b_max"
puts "Mean: $b_mean"
puts "Std: $b_std\n"

#  Open the nightly result
set fp [open [file join $::env(SLICER_HOME) Base/Testing/TestOutput/maskStat.hist.txt] r]
set data [read $fp]
close $fp
set data [split $data "\n"]
puts "Nightly mask statistics:"
puts "------------------------"
set new [split [regsub -all {[ \t\n]+} $data { }]]
set min [lindex $new 2]
set max [lindex $new 4]
set mean [lindex $new 6]
set std [lindex $new 8]
puts "Min: $min"
puts "Max: $max"
puts "Mean: $mean"
puts "Std: $std\n"
 
puts "Test result:"
puts "------------"

#ctest: test fails -> result is 1
#       test succeeds -> result is 0
set exitCode 0

set diff_min [expr {$b_min - $min}] 
if {$diff_min != 0} {
    puts "Min: found difference of $diff_min"  
    set exitCode 1
} else {
    puts "Min: no difference"  
}

set diff_max [expr {$b_max - $max}] 
if {$diff_max != 0} {
    puts "Max: found difference of $diff_max"  
    set exitCode 1
} else {
    puts "Max: no difference"  
}

set diff_mean [expr {$b_mean - $mean}] 
if {$diff_mean != 0} {
    puts "Mean: found difference of $diff_mean"  
    set exitCode 1
} else {
    puts "Mean: no difference"  
}

set diff_std [expr {$b_std - $std}] 
if {$diff_std != 0} {
    puts "Std: found difference of $diff_std"  
    set exitCode 1
} else {
    puts "Std: no difference"  
}


puts "Exit Code is $exitCode"
if {$exitCode == 0} {
    puts "Test passed."
} else {
    puts "Test failed."
}
exit $exitCode
