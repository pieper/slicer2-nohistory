package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[info commands vtkQueryAtlas] != "" ||
    [::vtk::load_component vtkQueryAtlasTCL] == ""} {
    global PACKAGE_DIR_VTKQueryAtlas
    package provide vtkQueryAtlas 1.0

    # source the Module's tcl file that contains it's init procedure
    source [file join $PACKAGE_DIR_VTKQueryAtlas/../../../tcl/QueryAtlas.tcl]
    source [file join $PACKAGE_DIR_VTKQueryAtlas/../../../tcl/slicerd.tcl]
    # add this module's name to the list of custom modules in order 
    # to have it's init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) QueryAtlas
}
