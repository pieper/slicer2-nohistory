package require vtk
package require vtkSlicerBase

# Image pipeline

vtkPNGReader reader
reader SetFileName $VTK_DATA_ROOT/Data/fullhead15.png

vtkImageStatistics stats
  stats SetInput [reader GetOutput]
  stats IgnoreZeroOff
  stats Update

vtkImageViewer viewer
viewer SetInput [stats GetOutput]
viewer SetColorWindow 163
viewer SetColorLevel 360

#make interface
source [file join [file dirname [info script]] WindowLevelInterface.tcl]

#puts [stats GetQuartile1]
#puts [stats GetMedian   ]
#puts [stats GetQuartile3]
#puts [stats GetQuintile1]
#puts [stats GetQuintile2]
#puts [stats GetQuintile3]
#puts [stats GetQuintile4]
#puts [stats GetAverage  ]
#puts [stats GetStdev    ]
#puts [stats GetMax      ]
#puts [stats GetMin      ]


if {[stats GetQuartile1] != 96  } {error "Didn't get right answer:Quartile1" }
if {[stats GetMedian   ] != 191 } {error "Didn't get right answer:Median   " }
if {[stats GetQuartile3] != 1079} {error "Didn't get right answer:Quartile3" }
if {[stats GetQuintile1] != 82  } {error "Didn't get right answer:Quintile1" }
if {[stats GetQuintile2] != 135 } {error "Didn't get right answer:Quintile2" }
if {[stats GetQuintile3] != 1011} {error "Didn't get right answer:Quintile3" }
if {[stats GetQuintile4] != 1091} {error "Didn't get right answer:Quintile4" }
if {[stats GetMax      ] != 3714} {error "Didn't get right answer:Max      " }
if {[stats GetMin      ] != 0} {error "Didn't get right answer:Min      " }

if { [ expr abs([ expr [stats GetAverage ] - 635.807]) ]  > "0.001" } {
   error "Didn't get right answer:Average  "
}

if { [ expr abs([expr [stats GetStdev ] - 660.913]) ] > "0.001" } {
   error "Didn't get right answer:Average  "
}


