package require vtk
package require vtkinteraction

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if { [info commands MIRIADSegmentInit] == "" } {
    global PACKAGE_DIR_VTKMIRIADSEGMENT
    package provide vtkMIRIADSegment 1.0

    # source the Module's tcl file that contains it's init procedure
    set files {
        MIRIADSegment.tcl
        MIRIADParameters.tcl
        birnPipelineFunctions.tcl
        NormalizeImage.tcl
        birnPipelineMain.tcl
        EMSegmentXMLReaderWriter.tcl
    }
    #EMSegmentBatch.tcl
        
    foreach f $files {
        source $PACKAGE_DIR_VTKMIRIADSEGMENT/../../../tcl/$f
    }

    lappend ::Module(customModules) MIRIADSegment
}
