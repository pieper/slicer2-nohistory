# Visualization Toolkit (VTK) Tcl package configuration.

#
# SLICER NOTE: 
# This is a modified version to allow location of the vtk tcl directories
# to be controlled by the VTK_SRC_DIR and VTK_DIR environment 
# variables rather than being hard coded to the build directory
#

package ifneeded vtkinit {4.4} {
  namespace eval ::vtk::init {
    proc load_library_package {libName libPath {libPrefix {}}} {
      set libExt [info sharedlibextension]
      set currentDirectory [pwd]
      set libFile [file join $libPath "$libPrefix$libName$libExt"]
      if {[catch "cd {$libPath}; load {$libFile}" errorMessage]} {
        puts $errorMessage
      }
      cd $currentDirectory
    }
    proc require_package {name {version {4.4}}} {
      if {[catch "package require -exact $name $version" errorMessage]} {
        puts $errorMessage
        return 0
      } else {
        return 1
      }
    }
    set version {4.4}
    set kits {}
    foreach kit { base Common Filtering IO Imaging Graphics
                  Rendering Hybrid 
                  Patented  } {
      lappend kits [string tolower "${kit}"]
    }
  }
  package provide vtkinit {4.4}
}

foreach kit { Common Filtering IO Imaging Graphics
              Rendering Hybrid 
              Patented  } {
    if { $::tcl_platform(platform) == "windows" } {
      package ifneeded "vtk${kit}TCL" {4.4} "
        package require -exact vtkinit {4.4}
        ::vtk::init::load_library_package {vtk${kit}TCL} {$::env(VTK_DIR)/bin/$::env(VTK_BUILD_TYPE)}
      "
  } else {
      package ifneeded "vtk${kit}TCL" {4.4} "
        package require -exact vtkinit {4.4}
        ::vtk::init::load_library_package {vtk${kit}TCL} {$::env(VTK_DIR)/bin} lib
      "
  }
  package ifneeded "vtk[string tolower ${kit}]" {4.4} "
    package require -exact vtkinit {4.4}
    if {\[catch {source \[file join {$::env(VTK_SRC_DIR)/Wrapping/Tcl} {vtk[string tolower ${kit}]} {vtk[string tolower ${kit}].tcl}\]} errorMessage\]} {
      puts \$errorMessage
    }
  "
}

foreach src {vtk vtkbase vtkinteraction vtktesting} {
  package ifneeded ${src} {4.4} "
    package require -exact vtkinit {4.4}
    if {\[catch {source \[file join {$::env(VTK_SRC_DIR)/Wrapping/Tcl} {$src} {$src.tcl}\]} errorMessage\]} {
      puts \$errorMessage
    }
  "
}
