#! /usr/local/bin/vtk

# first we load in the standard vtk packages into tcl
package require vtk
package require vtkinteraction

load ../bin/libvtkFreeSurferReadersTCL.so

# This loads the scalar file.
set scalars [vtkFloatArray _scalars]
set reader [vtkFSSurfaceScalarReader _reader]
$reader SetFileName "/home/kteich/subjects/anders/surf/lh.curv"
$reader SetOutput $scalars
$reader ReadFSScalars

# check some values
set lRange [$scalars GetRange]
puts "Range: [lindex $lRange 0] -> [lindex $lRange 1]"



exit

