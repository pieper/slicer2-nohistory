package require vtk

#
# rely on the fact that a class loaded from the shared
# library is uniquely available through this module
#

if {[::vtk::load_component vtkRigidIntensityRegistrationTCL] == "" } {

    global PACKAGE_DIR_VTKRigidIntensityRegistration
    package provide vtkRigidIntensityRegistration 1.0

    # source all the files
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/ItkToSlicerTransform.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/RigidIntensityRegistration.tcl]
    #source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/MutualInformationRegistration.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/AffineMattesMIRegistration.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/VersorMattesMIRegistration.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/TranslationMattesMIRegistration.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/TranslationMIGradientDescentRegistration.tcl]
    #source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/KullbackLeiblerRegistration.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/DeformableDemonsRegistration.tcl]
    source [file join $PACKAGE_DIR_VTKRigidIntensityRegistration/../../../tcl/DeformableBSplineRegistration.tcl]

    # add this module's name to the list of custom modules in order 
    # to have it's init procedure get called, @ModuleName@Init will be 
    # called by the Slicer Base code
    global Module
    lappend Module(customModules) RigidIntensityRegistration
    lappend Module(customModules) MutualInformationRegistration
    lappend Module(customModules) AffineMattesMIRegistration
    lappend Module(customModules) VersorMattesMIRegistration
    lappend Module(customModules) TranslationMattesMIRegistration
    lappend Module(customModules) TranslationMIGradientDescentRegistration
    lappend Module(customModules) KullbackLeiblerRegistration
    lappend Module(customModules) DeformableDemonsRegistration
    lappend Module(customModules) DeformableBSplineRegistration
}
