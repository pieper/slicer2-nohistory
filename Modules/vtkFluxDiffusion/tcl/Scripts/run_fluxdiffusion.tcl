#
# run_fluxdiffusion.tcl
#

package require vtkFluxDiffusion

wm withdraw .
update

#
# read arguments
#

set numargs [llength $argv]
puts "number of arguments $numargs"

if { $numargs < 11 } {
  puts "Wrong number of arguments"
  puts "syntax:"
  puts "run_fluxdiffusion.tcl inputprefix outputprefix dim first last vx vy vz threshold iterations standarddeviation"
  exit
}

set input_name  [lindex $argv 0]
set output_name [lindex $argv 1]
set dim         [lindex $argv 2]
set first       [lindex $argv 3]
set last        [lindex $argv 4]
set vx          [lindex $argv 5]
set vy          [lindex $argv 6]
set vz          [lindex $argv 7]
set threshold   [lindex $argv 8]
set iterations  [lindex $argv 9]
set standarddev [lindex $argv 10]

#
# Default parameters
#
set FluxDiffusion(Dimension)      "3"
set FluxDiffusion(Threshold)      $threshold
set FluxDiffusion(Attachment)     "0.05"
set FluxDiffusion(Iterations)     $iterations
set FluxDiffusion(StandardDev)    $standarddev
set FluxDiffusion(IsoCoeff)       "0.2"
set FluxDiffusion(TruncNegValues) "1"
vtkMultiThreader v
set FluxDiffusion(NumberOfThreads) [v GetGlobalDefaultNumberOfThreads]
set FluxDiffusion(TangCoeff) "1"
set FluxDiffusion(MincurvCoeff)  "1"
set FluxDiffusion(MaxcurvCoeff)  "0.1"

puts "threads ${FluxDiffusion(NumberOfThreads)}"


#
# load input image
#

vtkImageReader r
#  r SetDataByteOrderToLittleEndian
  r SetDataExtent 0 [expr $dim-1] 0 [expr $dim-1] $first $last
  r SetFilePattern ${input_name}
  r Update

#vtkStructuredPointsReader r
#r SetFileName ${input_name}
#r Update

#
# process
#
vtkAnisoGaussSeidel aniso

aniso SetInput               [r GetOutput]

aniso Setmode                $FluxDiffusion(Dimension)
aniso Setsigma               $FluxDiffusion(StandardDev)
aniso Setk                   $FluxDiffusion(Threshold)
aniso Setbeta                $FluxDiffusion(Attachment)
aniso SetIsoCoeff            $FluxDiffusion(IsoCoeff)

aniso SetNumberOfIterations  $FluxDiffusion(Iterations)

aniso SetTangCoeff           $FluxDiffusion(TangCoeff)

aniso SetMincurvCoeff        $FluxDiffusion(MincurvCoeff)
aniso SetMaxcurvCoeff        $FluxDiffusion(MaxcurvCoeff)


aniso SetNumberOfThreads     $FluxDiffusion(NumberOfThreads)
aniso SetTruncNegValues      $FluxDiffusion(TruncNegValues)


vtkImageWriter w
#  w SetDataExtent 0 [expr $dim-1] 0 [expr $dim-1] $first $last
  w SetInput    [aniso GetOutput]
  w SetFilePattern  ${output_name}
  w Write

#vtkStructuredPointsWriter w
#w SetFileName ${output_name}
#w SetInput    [aniso GetOutput]
#w Update


#aniso UnRegisterAllOutputs
#aniso Delete
#r Delete
#w Delete

exit
