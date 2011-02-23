
set SLICER_MODULE_ARG "-DVTKITK_SOURCE_DIR:PATH=$SLICER_HOME/Modules/vtkITK"
lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_DIR:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)" 

switch $tcl_platform(os) {
    "SunOS" {
       lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/libvtkITK.so"
       lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/libvtkITKTCL.so" 
     }
    "Linux" {
       lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/libvtkITK.so"
       lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/libvtkITKTCL.so" 
    }
    "Darwin" {
       lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/libvtkITK.dylib"
       lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/libvtkITKTCL.dylib" 
    }
    default {
         lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_TYPE)/vtkITK.lib"
         lappend SLICER_MODULE_ARG "-DVTKITK_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkITK/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_TYPE)/vtkITKTCL.lib" 
    } 
}

puts "SLICER_MODULE_ARG"
puts "$SLICER_MODULE_ARG"
