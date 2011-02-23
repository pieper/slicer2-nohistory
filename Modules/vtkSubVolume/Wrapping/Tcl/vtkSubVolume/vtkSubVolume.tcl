package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

#if {[info commands vtkSubVolume] != "" ||
#    [::vtk::load_component vtkSubVolumeTCL] == "" } {

#    global PACKAGE_DIR_VTKSubVolume
#    package provide vtkSubVolume 1.0

    # source the Module's tcl file that contains it's init procedure
#    source [file join $PACKAGE_DIR_VTKSubVolume/../../../tcl/SubVolume.tcl]
    # add this module's name to the list of custom modules in order 
    # to have it's init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
#    global Module
#    lappend Module(customModules) SubVolume
#}

    global PACKAGE_DIR_VTKSubVolume
    package provide vtkSubVolume 1.0
    source [file join $PACKAGE_DIR_VTKSubVolume/../../../tcl/SubVolume.tcl]
    # add this module's name to the list of custom modules in order 
    # to have it's init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) SubVolume
