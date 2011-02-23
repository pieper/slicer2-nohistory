
#
#
# startup.tcl
#
# This is used by the main slicer launch script to set environment
# variables needed to load all the slicer modules
#

# 
# you can use the SLICER_BUILD variable if you have multiple 
# versions for the same os (e.g. different compilers or 
# different versions of vtk)
#

set os [string lower $env(os)]

if { ![info exists env(SLICER_BUILD)] } {
    set env(SLICER_BUILD) $os
}

set build_dir $env(SLICER_HOME)/Base/builds/$os

# do some error checking...
if { ![file exists $build_dir/CMakeCache.txt] } {
    puts stderr "No CMakeCache.txt in $build_dir"
    puts exit
}

if { ![file readable $build_dir/CMakeCache.txt] } {
    puts stderr "Can't read CMakeCache.txt in $build_dir"
    puts exit
}


# read the cmake cache into one string
set fp [open $build_dir/CMakeCache.txt "r"]
set cache [read $fp]
close $fp

# helper proc to pull values from the cache
proc cachevalue {key} {
    global cache
    set i [lsearch -glob $cache "${key}*"]
    set v [lindex $cache $i]
    set afterequals [expr 1 + [string first "=" $v]]
    return [string range $v $afterequals end]
}

set vtk_binary_dir [cachevalue VTK_BINARY_DIR]
set vtk_source_dir [cachevalue VTK_BINARY_DIR]
set vtk_tcl_lib_dir [file dirname [cachevalue TCL_LIBRARY]
set vtk_tk_lib_dir [file dirname [cachevalue TK_LIBRARY]


if { [string match "windows*" $os] } {
    # write out a tmp batch file
    # for the calling bat file to call

} else {
    # print the environment variables to stdout
    # and they will be interpreted by the calling script

}



exit
