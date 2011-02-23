package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[info commands vtkAnisoGaussSeidel] != "" ||
    [::vtk::load_component vtkFluxDiffusionTCL] == ""} {
    global PACKAGE_DIR_VTKFLUXDIFFUSION
    source  $PACKAGE_DIR_VTKFLUXDIFFUSION/../../../tcl/FluxDiffusion.tcl
    package provide vtkFluxDiffusion 1.0
    # add this module's name to the list of custom modules in order 
    # to have it's init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) FluxDiffusion
}
