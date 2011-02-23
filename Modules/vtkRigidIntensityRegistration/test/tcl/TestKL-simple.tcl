package require vtk;
package require vtkRigidIntensityRegistration;# this pulls in the package

    catch { __gs1              Delete   }
    catch { __ns1              Delete   }
    catch { __imadd1           Delete   }
    catch { __gs2              Delete   }
    catch { __ns2              Delete   }
    catch { __imadd2           Delete   }
    catch { __KL               Delete   }
    catch { __TrainingTrans       Delete   }
    catch { __TestTrans        Delete   }

  vtkImageGaussianSource __gs1
     __gs1 SetWholeExtent 1 64 1 64 1 64
     __gs1 SetCenter 32 32 32
     __gs1 SetMaximum 250
     __gs1 SetStandardDeviation 20

  vtkImageNoiseSource __ns1
     __ns1 SetWholeExtent 1 64 1 64 1 64
     __ns1 SetMinimum 0
     __ns1 SetMaximum 10

  vtkImageMathematics __imadd1
     __imadd1 SetOperationToAdd
     __imadd1 SetInput1 [__ns1 GetOutput]
     __imadd1 SetInput2 [__gs1 GetOutput]

  vtkImageGaussianSource __gs2
     __gs2 SetWholeExtent 1 64 1 64 1 64
     __gs2 SetCenter 32 32 32
     __gs2 SetMaximum 250
     __gs2 SetStandardDeviation 20

  vtkImageNoiseSource __ns2
     __ns2 SetWholeExtent 1 64 1 64 1 64
     __ns2 SetMinimum 0
     __ns2 SetMaximum 10

  vtkImageMathematics __imadd2
     __imadd2 SetOperationToAdd
     __imadd2 SetInput1 [__ns2 GetOutput]
     __imadd2 SetInput2 [__gs2 GetOutput]

  vtkMatrix4x4 __TrainingTrans
     __TrainingTrans Identity

  vtkMatrix4x4 __TestTrans
     __TestTrans Identity
    
  vtkITKKullbackLeiblerTransform __KL
     __KL SetTrainingSourceImage [__imadd1 GetOutput]
     __KL SetTrainingTargetImage [__imadd2 GetOutput]
     __KL SetTrainingTransform   __TrainingTrans
     __KL SetSourceImage      [__gs1 GetOutput]
     __KL SetTargetImage      [__gs2 GetOutput]
     __KL SetHistSizeSource   64
     __KL SetHistSizeTarget   64
     __KL SetHistEpsilon      1e-12
     __KL Initialize          __TestTrans

     __KL    SetSourceShrinkFactors 1 1 1
     __KL    SetTargetShrinkFactors 1 1 1
     __KL    SetNumberOfSamples 50

     __KL ResetMultiResolutionSettings 
    foreach iter  "1" {
    __KL SetNextMaxNumberOfIterations $iter
    }
    foreach rate  "1e-4" {
    __KL SetNextLearningRate  $rate
    }

    ## Not really needed for KL
    #  __KL InitRandomSeed 8775070
  
    __KL Update
    set results [__KL  GetMetricValue]

    if {[expr abs($results+22.5418)] < 0.1} {
      puts "SUCCESS"
    }  else {
     puts "ERROR. Should have gotten -22.5418, Got $results"
     puts "There is no way to seed VTK noise source, so maybe this is due to that problem"
     exit
    }
