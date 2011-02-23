
package require vtkITK 
package require vtkSlicerBase
package require vtkTeem

catch "nr Delete"
vtkNRRDReader nr


nr SetFileName /projects/schiz/diff/chronic/males/cases/caseD20/coronal_nhdr/caseD20_DWI.nhdr


nr UpdateInformation

puts "Num comp: [nr GetNumberOfComponents]"
puts "[[nr GetRasToIjkMatrix] Print]"
#nr Update
#puts [nr Print]
puts [[nr GetOutput] Print]


set keys [nr GetHeaderKeys]


vtkTeemEstimateDiffusionTensor tEst
tEst SetNumberOfThreads 1
tEst SetInput [nr GetOutput]
tEst SetEstimationMethodToLLS

set numgradients 0

foreach key $keys$ {

  switch -glob -- $key {
  
     "DWMRI_gradient*" {
        puts "$key [nr GetHeaderValue $key]"
        regexp {[0-9]+$} $key gradnum
        regexp {[ ]+([0-9\.-]+)[ ]+([0-9\.-]+)[ ]+([0-9\.-]+)} [nr GetHeaderValue $key] match g1 g2 g3
        #puts "$gradnum $g1 $g2 $g3"
        scan $gradnum %d gradnum
        set gradients($gradnum,val) "$g1 $g2 $g3"
        incr numgradients
     }
   }
}


tEst SetNumberOfGradients $numgradients
puts "Num gradients: $numgradients"
for {set i 0} {$i < $numgradients} {incr i} {
  tEst SetDiffusionGradient $i [lindex $gradients($i,val) 0] [lindex $gradients($i,val) 1] [lindex $gradients($i,val) 2] 
  tEst SetB $i 1000
}

tEst Update



