package require vtk
package require Iwidgets

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if { [info commands isvolume] == "" } {
    global PACKAGE_DIR_ISLICER
    package provide iSlicer 1.0

    # source the Module's tcl file that contains it's init procedure
    # (note imrml.tcl not included for default load)
    set files {
        collapsablewidget.itk ismodel.tcl isvolume.tcl isframes.tcl
        is3d.tcl isregistration.tcl evaluation-movies.tcl isbutton.tcl 
        istask.tcl isrange.tcl spinfloat.tcl 
        ismvolumeselector.tcl isvolumeoption.tcl 
        ismatrixoption.tcl istransformoption.tcl iscomm.tcl
        isprocess.tcl ischeckbox.tcl
    }
        
    foreach f $files {
        source $PACKAGE_DIR_ISLICER/../../../tcl/$f
    }
}
