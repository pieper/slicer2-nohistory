package require vtkSlicerBase
package require vtkITK


# open up a notes file for writing
set fname [file join $::env(SLICER_HOME) Base Testing Notes dp.txt]

if {[file exists [file dirname $fname]] == 0} {
    # make the directory
    file mkdir [file dirname $fname]
}
if {[catch "set fd [open $fname w]" errmsg] != 0} {
    puts "Error opening file $fname for writing, exit 1"
    exit 1
}

if {$fd == ""} {
    puts "Error opening file $fname for writing, exit 1"
    exit 1
}

vtkMrmlSlicer Slicer

# for ParseCVSInfo
source [file join $::env(SLICER_HOME) Base tcl tcl-main Main.tcl]

set execName ""
switch $tcl_platform(os) {
    "SunOS" {
        set execName "slicer2-solaris-sparc"
    }
    "Linux" {
        set execName "slicer2-linux-x86"
    }
    "Darwin" {
        set execName "slicer2-darwin-ppc"
    }
    default {
        set execName "slicer2-win32.exe"
    }
}

set compilerVersion [Slicer GetCompilerVersion]
set compilerName [Slicer GetCompilerName]
set vtkVersion [Slicer GetVTKVersion]
if {[info command vtkITKVersion] == ""} {
    set itkVersion "none"
} else {
    catch "vtkITKVersion vtkitkver"
    catch "set itkVersion [vtkitkver GetITKVersion]"
    catch "vtkitkver Delete"
}
if {[info exist ::env(USER)] == 1} {
    set userName $::env(USER)
} else {
    # user name may not be set when running a nightly test as a cron job
    set userName "NONE"
}
set dpString "ProgramName: $execName\nProgramArguments: $argv\nTimeStamp: [clock format [clock seconds] -format "%D-%T-%Z"]\nUser: ${userName}\nMachine: $tcl_platform(machine)\nPlatform: $tcl_platform(os) PlatformVersion: $tcl_platform(osVersion)"
set dpString "${dpString}\nVersion: [ParseCVSInfo "" {$Name:  $}]"
set dpString "${dpString}\nCVS: [ParseCVSInfo "" {$Id: testDataProvenance.tcl,v 1.3 2006/07/28 14:23:00 nicole Exp $}]"
set dpString "${dpString}\nCompilerName: ${compilerName} CompilerVersion: $compilerVersion"
set dpString "${dpString}\nLibName: VTK LibVersion: ${vtkVersion}\nLibName: TCL LibVersion: ${tcl_patchLevel}\nLibName: TK LibVersion: ${tk_patchLevel}\nLibName: ITK LibVersion: ${itkVersion}"

puts "$dpString"
puts $fd "$dpString"
close $fd


puts "0"
exit 0
