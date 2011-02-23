package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[info commands vtkCompareModule] != "" ||
    [::vtk::load_component vtkCompareModuleTCL] == ""} {
    global PACKAGE_DIR_VTKCompareModule
    package provide vtkCompareModule 1.0

    # source the Module's tcl file that contains it's init procedure
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareModule.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareAnno.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareInteractor.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareSlices.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareMosaik.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareViewer.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareRender.tcl]
    source [file join $PACKAGE_DIR_VTKCompareModule/../../../tcl/CompareFlip.tcl]
    # add this module's name to the list of custom modules in order
    # to have it's init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) CompareModule
}

