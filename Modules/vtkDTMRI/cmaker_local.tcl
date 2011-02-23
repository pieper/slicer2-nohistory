
set SLICER_MODULE_ARG "-DVTKTENSORUTIL_SOURCE_DIR:PATH=$SLICER_HOME/Modules/vtkTensorUtil"
lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_DIR:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)" 

switch $tcl_platform(os) {
    "SunOS" {
       lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/libvtkTensorUtil.so"
       lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/libvtkTensorUtilTCL.so" 
     }
    "Linux" {
       lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/libvtkTensorUtil.so"
       lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/libvtkTensorUtilTCL.so" 
    }
    "Darwin" {
       lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/libvtkTensorUtil.dylib"
       lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/libvtkTensorUtilTCL.dylib" 
    }
    default {
         lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_TYPE)/vtkTensorUtil.lib"
         lappend SLICER_MODULE_ARG "-DVTKTENSORUTIL_BUILD_TCL_LIB:PATH=$SLICER_HOME/Modules/vtkTensorUtil/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_TYPE)/vtkTensorUtilTCL.lib" 
    } 
}

puts "SLICER_MODULE_ARG"
puts "$SLICER_MODULE_ARG"
