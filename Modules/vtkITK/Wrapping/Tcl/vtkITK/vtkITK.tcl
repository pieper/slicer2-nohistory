package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[info commands vtkITK] != "" ||
    [::vtk::load_component vtkITKTCL] == ""} {
    global PACKAGE_DIR_VTKITK
    source  [file join $PACKAGE_DIR_VTKITK/../../../tcl/EdWatershed.tcl]
    source  [file join $PACKAGE_DIR_VTKITK/../../../tcl/EdConfidenceConnected.tcl]
    source  [file join $PACKAGE_DIR_VTKITK/../../../tcl/ITKFilters.tcl]
    source  [file join $PACKAGE_DIR_VTKITK/../../../tcl/VolGeneric.tcl]
    global Module
    lappend Module(customModules) ITKFilters
    package provide vtkITK 1.0
}
