package require vtk
package require vtkinteraction

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if { [info commands LDMMViewerInit] == "" } {
    global PACKAGE_DIR_LDMMVIEWER
    package provide LDMMViewer 1.0

    # source the Module's tcl file that contains it's init procedure
    set files {
        LDMMViewer.tcl
        }
        
    foreach f $files {
        source $PACKAGE_DIR_LDMMVIEWER/../../../tcl/$f
    }

    lappend ::Module(customModules) LDMMViewer
}
