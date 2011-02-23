package require vtk
package require vtkDTMRI

set TEST_TYPE "Slice" 
#Types are: Slice, Volume, Mosaic

#Base Classess
vtkImageNoiseSource _sr
_sr SetMinimum 0
_sr SetMaximum 256
_sr SetWholeExtent 0 31 0 31 0 31
_sr Update

vtkImageCast _c
_c SetInput [_sr GetOutput]
_c SetOutputScalarTypeToShort
_c Update

vtkImageExtractSlices s 

switch -glob -- $TEST_TYPE {

  "Slice" {
  
  #Read Data
  #r SetFileName DTMRI-InterSlice.vtk
  #r Update
  
  #Replicate repetitions
  vtkImageAppend ap
  ap SetInput 0 [_c GetOutput]
  ap SetInput 1 [_c GetOutput]
  ap SetAppendAxis 2
  ap Update
  
  s SetInput [ap GetOutput]
  s SetNumberOfRepetitions 2
  s AverageRepetitionsOn
  s SetSlicePeriod 4
  s SetSliceOffset 3
  s SetModeToSLICE
  s SetNumberOfThreads 6
  #s InterleaveRepetitionsOff
  s Update
  
  }
  
  "Volume" {
  #Read Data
  #r SetFileName DTMRI-InterVolume.vtk
  #r Update
  
  #Replicate repetitions
  vtkImageAppend ap
  ap SetInput 0 [_c GetOutput]
  ap SetInput 1 [_c GetOutput]
  ap SetAppendAxis 2
  ap Update
  
  s SetInput [ap GetOutput]
  s SetNumberOfRepetitions 2
  s AverageRepetitionsOn
  s SetSlicePeriod 4
  s SetSliceOffset 3
  s SetModeToVOLUME
  s SetNumberOfThreads 2
  s Update
  
  }
  
  "Mosaic" {
  
  #Read Data

  #r SetFileName TestMosaic.vtk
  #r Update
  
    #Replicate repetitions
   vtkImageAppend ap
   ap SetInput 0 [_c GetOutput]
   ap SetInput 1 [_c GetOutput]
   ap SetAppendAxis 2
   ap Update
  

  s SetInput [ap GetOutput]
  s SetMosaicSlices 32
  s SetMosaicTiles 2
  s SetSliceOffset 1
  s SetSlicePeriod 0
  s SetNumberOfRepetitions 2
  s AverageRepetitionsOff
  s SetModeToMOSAIC
  s DebugOn
  s SetNumberOfThreads 1
  s Update
  }
  
}  

 set dims [[s GetOutput] GetDimensions]
 set inExt [[s GetOutput] GetExtent]
 set dimz [lindex $dims 2]
 set range [[s GetOutput] GetScalarRange]
 return 0


#vtkImageAppend a
#for {set k 0} {k < $dimz} {incr k} {
#
#vtkImageClip c$k
#c$k SetInput [s GetOutput]
#c$k SetOutputExtent [lindex $inExt 0] [lindex $inExt 1] [lindex $inExt 2] /
#                    [lindex $inExt 3] $k $k
#c$k Update

#}

#vtkImageViewer viewer
#viewer SetInput [s GetOutput]
#viewer SetColorLevel [expr [lindex $range 1] / 2]
#viewer SetColorWindow [expr [viewer GetColorLevel] / 2]
#viewer SetZSlice [expr $dimz/2]

#source [file join [file dirname [info script]] WindowLevelInterface.tcl]
