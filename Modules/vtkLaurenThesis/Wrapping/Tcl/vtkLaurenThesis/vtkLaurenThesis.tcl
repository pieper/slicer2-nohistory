package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

# There are no local vtk classes in this module
#if {[info commands vtkLaurenThesis] != "" ||
#    [::vtk::load_component vtkLaurenThesisTCL] == ""} {

if {[info commands LaurenThesisInit] == ""} {
    global PACKAGE_DIR_VTKLaurenThesis
    package provide vtkLaurenThesis 1.0

    # source the Module's tcl file that contains its init procedure
    source [file join $PACKAGE_DIR_VTKLaurenThesis/../../../Tcl/LaurenThesis.tcl]
    # add this module's name to the list of custom modules in order 
    # to have its init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    
    global Module
    lappend Module(customModules) LaurenThesis

}
