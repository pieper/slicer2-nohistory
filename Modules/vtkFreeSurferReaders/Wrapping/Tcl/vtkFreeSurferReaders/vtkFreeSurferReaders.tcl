package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[info commands vtkFreeSurferReaders] != "" ||
    [::vtk::load_component vtkFreeSurferReadersTCL] == ""} {
    global PACKAGE_DIR_VTKFREESURFERREADERS
#    source  [file join $PACKAGE_DIR_VTKFREESURFERREADERS/../../../tcl/VolFreeSurferReaders.tcl]
    source  [file join $PACKAGE_DIR_VTKFREESURFERREADERS/../../../tcl/vtkFreeSurferReaders.tcl]
    source  [file join $PACKAGE_DIR_VTKFREESURFERREADERS/../../../tcl/regions.tcl]
    package provide vtkFreeSurferReaders 1.0

    # add this module's name to the list of custom modules in order 
    # to have it's init procedure get called, vtkFreeSurferReadersInit will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) vtkFreeSurferReaders

}

