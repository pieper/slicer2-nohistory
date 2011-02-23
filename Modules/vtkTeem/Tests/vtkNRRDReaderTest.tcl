
package require vtkITK 
package require vtkSlicerBase

catch "nr Delete"
vtkNRRDReader nr

nr SetFileName d:/data/namic/HUVA00024864/HUVA00024864_spgr.nhdr
nr SetFileName /home/rjosest/projects/data/nrrd/caseD20_DWI-masked.nhdr

nr UpdateInformation

puts "Num comp: [nr GetNumberOfComponents]"
puts "[[nr GetRasToIjkMatrix] Print]"
#nr Update
#puts [nr Print]
puts [[nr GetOutput] Print]

vtkImageReformat r
r SetInput [nr GetOutput]
r Update

puts "[[r GetOutput] Print]"

vtkImageExtractComponents e
e SetInput [nr GetOutput]
e SetComponents 0
e Update

#puts [[e GetOutput] Print]

catch "v Delete"
vtkImageViewer v
v SetInput [r GetOutput]
v SetColorWindow 500
v SetColorLevel 1000

set zdim [lindex [[nr GetOutput] GetDimensions] 0]
for {set z 0} {$z < $zdim} {incr z} {
    v SetZSlice $z
    v Render
    update
    gets stdin
}

