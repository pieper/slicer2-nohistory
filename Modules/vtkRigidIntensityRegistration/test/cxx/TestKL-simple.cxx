#include <fstream>

#include "SimpleApp.h"
#include "itkExceptionObject.h"

#include "vtkImageGaussianSource.h"
#include "vtkImageNoiseSource.h"
#include "vtkImageMathematics.h"
#include "vtkITKKullbackLeiblerTransform.h"
#include "vtkITKKullbackLeiblerTransform.cxx"

int main(int argc, char *argv[])
{
  vtkImageGaussianSource *gs1 = vtkImageGaussianSource::New();
     gs1->SetWholeExtent(1,64,1,64,1,64);
     gs1->SetCenter(32,32,32);
     gs1->SetMaximum(250);
     gs1->SetStandardDeviation(20);

  vtkImageNoiseSource *ns1 = vtkImageNoiseSource::New();
    ns1->SetWholeExtent(1,64,1,64,1,64);
    ns1->SetMinimum(0);
    ns1->SetMaximum(10);

  vtkImageMathematics *imadd1 = vtkImageMathematics::New();
    imadd1->SetOperationToAdd();
    imadd1->SetInput1(ns1->GetOutput());
    imadd1->SetInput2(gs1->GetOutput());
    imadd1->GetOutput()->Update();

  vtkImageGaussianSource *gs2 = vtkImageGaussianSource::New();
     gs2->SetWholeExtent(1,64,1,64,1,64);
     gs2->SetCenter(32,32,32);
     gs2->SetMaximum(250);
     gs2->SetStandardDeviation(20);

  vtkImageNoiseSource *ns2 = vtkImageNoiseSource::New();
    ns2->SetWholeExtent(1,64,1,64,1,64);
    ns2->SetMinimum(0);
    ns2->SetMaximum(10);

  vtkImageMathematics *imadd2 = vtkImageMathematics::New();
    imadd2->SetOperationToAdd();
    imadd2->SetInput1(ns2->GetOutput());
    imadd2->SetInput2(gs2->GetOutput());
    imadd2->GetOutput()->Update();

  vtkMatrix4x4 *TrainingTrans = vtkMatrix4x4::New();
     TrainingTrans->Identity();

  vtkMatrix4x4 *TestTrans = vtkMatrix4x4::New();
    TestTrans->Identity();
    
  vtkITKKullbackLeiblerTransform *KL = vtkITKKullbackLeiblerTransform::New();
    KL->SetTrainingSourceImage(imadd1->GetOutput());
    KL->SetTrainingTargetImage(imadd2->GetOutput());
    KL->SetTrainingTransform(TrainingTrans);
    KL->SetSourceImage(gs1->GetOutput());
    KL->SetTargetImage(gs2->GetOutput());
    KL->SetHistSizeSource(64);
    KL->SetHistSizeTarget(64);
    KL->SetHistEpsilon(1e-12);
    KL->Initialize(TestTrans);

    KL->SetSourceShrinkFactors(1,1,1);
    KL->SetTargetShrinkFactors(1,1,1);
    KL->SetNumberOfSamples(50);

    KL->ResetMultiResolutionSettings();
    KL->SetNextLearningRate(0.001);
    KL->SetNextMaxNumberOfIterations(1);

//    KL->ResetMultiResolutionSettings
//    foreach iter  "1" {
//       KL->SetNextMaxNumberOfIterations $iter
//    }
//    foreach rate  "1e-4" {
//       KL->SetNextLearningRate  $rate
//    }
  
    KL->Update();
    std::cout << "Metric: " << KL->GetMetricValue() << std::endl;

    KL->SetSourceImage(imadd1->GetOutput());
    KL->SetTargetImage(imadd2->GetOutput());

    KL->Update();
    std::cout << "Metric: (should be 0)" << KL->GetMetricValue() << std::endl;

}
