package require vtk
package require vtkSlicerBase

# Image pipeline

if { [catch {set VTK_TCL $env(VTK_TCL)}] != 0} { set VTK_TCL "../../examplesTcl" }
if { [catch {set VTK_DATA $env(VTK_DATA)}] != 0} { set VTK_DATA "../../../vtkdata" }
source ../../imaging/examplesTcl/TkImageViewerInteractor.tcl

# This script tests the livewire stuff...

# Image pipeline

vtkImageReader reader
  reader ReleaseDataFlagOff
  reader SetDataByteOrderToLittleEndian
  reader SetDataExtent 0 63 0 63 1 93
  reader SetFilePrefix ${VTK_DATA_ROOT}/Data/headsq/quarter
  reader SetDataMask 0x7fff

vtkImageLiveWireEdgeWeights lwedge
lwedge SetInput 0 [reader GetOutput]
lwedge SetInput 1 [reader GetOutput]
lwedge SetInput 2 [reader GetOutput]

#lwedge TrainingModeOn

#lwedge SetEdgeDirection 2

# viewer
vtkImageViewer viewer
viewer SetInput [lwedge GetOutput]
viewer SetZSlice 15

# test writing to a file
#lwedge SetTrainingFileName testfile.txt
#lwedge WriteTrainedFeatureSettings

# Gui
toplevel .top
frame .top.f
vtkTkImageViewerWidget .top.f.v -width 256 -height 256 -iv viewer
pack .top.f.v
pack .top.f -fill both -expand t
BindTkImageViewer .top.f.v

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]









