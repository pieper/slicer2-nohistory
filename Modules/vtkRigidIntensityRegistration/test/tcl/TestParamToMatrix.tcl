package require vtkRigidIntensityRegistration;# this pulls in the package

  vtkTransform TestTrans
     TestTrans RotateWXYZ 12 1 0.33 0.8
     TestTrans Translate 10.2 2.4 -3.3
     [TestTrans GetMatrix] Print

   vtkITKMutualInformationTransform __reg
    set results [ __reg TestMatrixInitialize [TestTrans GetMatrix] ]

   if {$results != 0 } {
     puts "TEST FAILED"
     exit
   } else {
     puts "SUCCESS"
   }

  __reg Delete
  TestTrans Delete
