package require vtkSlicerBase
package require vtkITK
package require vtkTeem 
#for the NRRD Reader to load Reference Volume


#ctest: test fails -> exitCode is 1
#       test succeeds -> exitCode is 0
set exitCode 0

proc RunTest {{init 0}} {
    global Path Volume Lut Module Model Volumes AG Slicer Slice exitCode MeasureVol

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
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-modules/MeasureVol.tcl]
        source [file join $::env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]
        source [file join $::env(SLICER_HOME) Modules/vtkTeem/tcl/VolNrrd.tcl]
        
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
        
    }
    
    
    #stubs
    proc MainShowProgress {filter} {}
    proc MainEndProgress {} {}
    
    MainMrmlRead [file join $::env(SLICER_HOME) Base/Testing/TestInput/MeasureVol.xml]
    MainUpdateMRML
    set Volume(activeID) 1
    
    #stub for the textBox: 
    #eval {text .test}
    text .test
    set MeasureVol(textBox) .test
    label .label
    set MeasureVol(lResultVol) .label
    proc YesNoPopup {win x y msg {yesCmd ""} {noCmd ""} \
                         {justify center} {title ""} {font ""}} {}
    
    MeasureVolInit
    MeasureVolSelectVol
    set MeasureVol(fileName) [file join  $::env(SLICER_HOME) Base/Testing/TestOutput/]/$MeasureVol(fileName)
    MeasureVolVolume

    #  Open the Baseline 
    set fp [open [file join $::env(SLICER_HOME) Base/Testing/Baseline/measureVol_caseR16_hist.txt] r]
    set data [read $fp]
    close $fp
    
    #  Create baseline list
    set data [split $data "\n"]
    
    #tell CTest that I require the full output of the test
    puts "CTEST_FULL_OUTPUT"

    puts "Baseline measurements in mL:"
    puts "----------------------------"
    foreach line $data {
    puts $line
        set new  [split [regsub -all {[ \t\n]+} $line { }]]
        set a [lindex $new 1]
        set b [lindex $new 2]
        lappend baseline_list "$a $b"
    }
    
    #  Open the nightly test result
    set p [open $MeasureVol(fileName) r]
    set l  [read $p]
    close $p
    
    #set baseline_list
    
    #  Process data file
    set l [split $l "\n"]
    set i 0
    puts "Result of nightly measurements in mL:"
    puts "-------------------------------------"
    foreach line $l {
        puts $line
    } 
    puts "Test result:"
    puts "------------"
    foreach line $l {
        set new  [split [regsub -all {[ \t\n]+} $line { }]]
        set c [lindex $new 2]
        #puts $c
        #puts $i
        if {$c!=""} {
            set orig [lindex $baseline_list "$i 1"]

        set diff [expr $orig -$c]
            if {$diff != 0} {
                set label [lindex $new 1]
                set dev [expr (abs($diff)/$orig)*100]
                puts [format "Deviation in label %s: %.2f %%" $label $dev]
                #puts "Deviation in label $label: $dev %"
                #puts "Baseline Volume: $orig Nightly Test: $c"
                set exitCode 1
            }
        }
        incr i;
    }
    
    
}
RunTest 1

if {$exitCode == 0} {
    puts "No differences between baseline measurements and nightly results."
    puts "Test passed."
} else {
    puts "There are differences between baseline measurements and nightly results."
    puts "Test failed."
}
exit $exitCode
