package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

# We have no C++ classes
#if {[info commands vtkModelInteraction] != "" ||
#    [::vtk::load_component vtkModelInteractionTCL] == ""} {

# Source tcl initialization code for this module:
if {[info commands ModelInteractionInit] == ""} {
    global PACKAGE_DIR_VTKModelInteraction
    package provide vtkModelInteraction 1.0

    # source the Module's tcl file that contains its init procedure
    source [file join $PACKAGE_DIR_VTKModelInteraction/../../../Tcl/ModelInteraction.tcl]
    # add this module's name to the list of custom modules in order 
    # to have its init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) ModelInteraction
}
