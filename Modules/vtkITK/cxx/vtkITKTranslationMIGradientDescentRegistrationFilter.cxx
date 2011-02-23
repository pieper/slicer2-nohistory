/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKTranslationMIGradientDescentRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
#include "vtkITKTranslationMIGradientDescentRegistrationFilter.h"

typedef itk::Array<unsigned int> UnsignedIntArray;
typedef itk::Array<double> DoubleArray;

vtkITKTranslationMIGradientDescentRegistrationFilter::vtkITKTranslationMIGradientDescentRegistrationFilter()
{
  m_ITKFilter = itk::itkTranslationMIGradientDescentRegistrationFilter::New();
  LinkITKProgressToVTKProgress(m_ITKFilter);
  this->SetSourceShrinkFactors(1,1,1);
  this->SetTargetShrinkFactors(1,1,1);

  this->LearningRate = vtkDoubleArray::New();
  this->MaxNumberOfIterations = vtkUnsignedIntArray::New();

  // Default Number of MultiResolutionLevels is 1
  this->SetNextMaxNumberOfIterations(100);
  this->SetNextLearningRate(0.0001);
  this->SetNumberOfSamples(100);
  this->SetStandardDeviation(0.4);
}

void vtkITKTranslationMIGradientDescentRegistrationFilter::CreateRegistrationPipeline()
{
  m_ITKFilter->SetInput(itkImporterFixed->GetOutput());
  m_ITKFilter->SetInput(1, itkImporterMoving->GetOutput());

  vtkITKTransformRegistrationCommand::Pointer observer = vtkITKTransformRegistrationCommand::New();
  observer->SetRegistrationFilter(this);
  m_ITKFilter->AddIterationObserver(observer );
}

void 
vtkITKTranslationMIGradientDescentRegistrationFilter::UpdateRegistrationParameters()
{
  itk::itkTranslationMIGradientDescentRegistrationFilter* filter = static_cast<itk::itkTranslationMIGradientDescentRegistrationFilter *> (m_ITKFilter);

  filter->SetMovingImageShrinkFactors(this->SourceShrink);
  filter->SetFixedImageShrinkFactors(this->TargetShrink);

  DoubleArray      LearningRate(this->GetLearningRate()->GetNumberOfTuples());
  UnsignedIntArray NumIterations(this->GetMaxNumberOfIterations()->GetNumberOfTuples());


  for(int i=0; i< this->GetMaxNumberOfIterations()->GetNumberOfTuples();i++) {
    LearningRate[i]    = this->GetLearningRate()->GetValue(i);
    NumIterations[i] = this->GetMaxNumberOfIterations()->GetValue(i);
  }
  filter->SetNumberOfLevels(this->GetMaxNumberOfIterations()->GetNumberOfTuples());
  filter->SetLearningRate(LearningRate);
  filter->SetNumberOfIterations(NumIterations);
  filter->SetNumberOfSpatialSamples(NumberOfSamples);
  filter->SetStandardDeviation(StandardDeviation);
}

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKTranslationMIGradientDescentRegistrationFilter::GetTransformedOutput()
{
   return m_ITKFilter->GetOutput();
}

void
vtkITKTranslationMIGradientDescentRegistrationFilter::GetTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::Pointer transform 
    = itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::New();

  m_ITKFilter->GetTransform(transform);

  itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::ParametersType params = transform->GetParameters();
 
  matrix->Identity();
  matrix->Element[0][3] = params[0];
  matrix->Element[1][3] = params[1];
  matrix->Element[2][3] = params[2];

}
  
void
vtkITKTranslationMIGradientDescentRegistrationFilter::GetCurrentTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::Pointer transform 
    = itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::New();
  
  m_ITKFilter->GetCurrentTransform(transform);
  
  itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::ParametersType params = transform->GetParameters();
 
 
  matrix->Identity();
  matrix->Element[0][3] = params[0];
  matrix->Element[1][3] = params[1];
  matrix->Element[2][3] = params[2];

}
  
void 
vtkITKTranslationMIGradientDescentRegistrationFilter::SetTransformationMatrix(vtkMatrix4x4 *matrix)
{
  itk::itkTranslationMIGradientDescentRegistrationFilter::ParametersType  initialParameters = itk::itkTranslationMIGradientDescentRegistrationFilter::ParametersType(3);

  initialParameters[0] = matrix->Element[0][3];
  initialParameters[1] = matrix->Element[1][3];
  initialParameters[2] = matrix->Element[2][3];

  itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::Pointer transform = itk::itkTranslationMIGradientDescentRegistrationFilter::TransformType::New();
  transform->SetParameters(initialParameters);

  m_ITKFilter->SetTransform(transform);
}


void 
vtkITKTranslationMIGradientDescentRegistrationFilter::SetSourceShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  SourceShrink[0] = i;
  SourceShrink[1] = j;
  SourceShrink[2] = k;
} //vtkITKTranslationMIGradientDescentRegistrationFilter

void 
vtkITKTranslationMIGradientDescentRegistrationFilter::SetTargetShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  TargetShrink[0] = i;
  TargetShrink[1] = j;
  TargetShrink[2] = k;
} //vtkITKTranslationMIGradientDescentRegistrationFilter
