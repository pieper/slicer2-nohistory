
if {$argc != 2} {
    puts "UNIX Usage: vtk GoMrmlize.tcl <img1> <num2>"
    puts "Windows Usage: wish82.exe GoMrmlize.tcl <img1> <num2>"
    puts "where: <img1> = full pathname of the first image in the volume."
    puts "       <num2> = just the number of the last image"
    puts "Example: vtk GoMrmlize.tcl /data/mr/I.001 124"
    puts "Output: output.mrml is written in the current directory."
    exit
}

# Load vtktcl.dll on PCs
catch {load vtktcl}
wm withdraw .

# Determine Slicer's home directory from the SLICER_HOME environment 
# variable, or the root directory of this script ($argv0).
if {[info exists env(SLICER_HOME)] == 0 || $env(SLICER_HOME) == ""} {
    set prog [file dirname $argv0]
    # temporary fix for print_header call to use in GetHeaderInfo
    set Gui(pc) 1
} else {
    set prog [file join $env(SLICER_HOME) Base/tcl]
    # temporary fix for print_header call to use in GetHeaderInfo
    set Gui(pc) 0
}

# need to source vtk stuff here
#
# set statup options - convert backslashes from windows
# version of SLICER_HOME var into to regular slashes
#
regsub -all {\\} $env(SLICER_HOME) / slicer_home
regsub -all {\\} $env(VTK_SRC_DIR) / vtk_src_dir
set auto_path "$slicer_home/Base/tcl $slicer_home/Base/Wrapping/Tcl/vtkSlicerBase $vtk_src_dir/Wrapping/Tcl $auto_path"

package require vtkSlicerBase

# Read source files
set Mrml(dir) [file dirname [lindex $argv 0]]
source [file join $prog [file join tcl-main MainFile.tcl]]
source [file join $prog [file join tcl-main MainHeader.tcl]]

# Find print_header
if {$tcl_platform(platform) == "windows"} {
    set Path(printHeader) [file join $prog [file join bin print_header_NT]]
} else {
    set Path(printHeader) [file join $prog [file join bin print_header]]
}

# Read headers
set img1 [lindex $argv 0]
set num2 [lindex $argv 1]
vtkMrmlVolumeNode node
GetHeaderInfo $img1 $num2 node 0
node SetName [file tail [file root $img1]]

# Write MRML
vtkMrmlTree tree
tree AddItem node
tree Write "output.xml"
exit
