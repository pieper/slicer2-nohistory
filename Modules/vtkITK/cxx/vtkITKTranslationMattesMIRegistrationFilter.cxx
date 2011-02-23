/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKTranslationMattesMIRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkITKTranslationMattesMIRegistrationFilter.h"
typedef itk::Array<unsigned int> UnsignedIntArray;
typedef itk::Array<double> DoubleArray;

vtkITKTranslationMattesMIRegistrationFilter::vtkITKTranslationMattesMIRegistrationFilter()
{
  m_ITKFilter = itk::itkTranslationMattesMIRegistrationFilter::New();
  LinkITKProgressToVTKProgress(m_ITKFilter);
  this->SetSourceShrinkFactors(1,1,1);
  this->SetTargetShrinkFactors(1,1,1);

  this->MinimumStepLength = vtkDoubleArray::New();
  this->MaximumStepLength = vtkDoubleArray::New();
  this->MaxNumberOfIterations = vtkUnsignedIntArray::New();

  // Default Number of MultiResolutionLevels is 1
  this->SetNextMaxNumberOfIterations(100);
  this->SetNextMinimumStepLength(0.0001);
  this->SetNextMaximumStepLength(0.2);
  this->SetNumberOfSamples(100);
  this->SetNumberOfHistogramBins(256);
}

void vtkITKTranslationMattesMIRegistrationFilter::CreateRegistrationPipeline()
{
  m_ITKFilter->SetInput(itkImporterFixed->GetOutput());
  m_ITKFilter->SetInput(1, itkImporterMoving->GetOutput());

  vtkITKTransformRegistrationCommand::Pointer observer = vtkITKTransformRegistrationCommand::New();

  observer->SetRegistrationFilter(this);
  m_ITKFilter->AddIterationObserver(observer );
}

void 
vtkITKTranslationMattesMIRegistrationFilter::UpdateRegistrationParameters()
{
  itk::itkTranslationMattesMIRegistrationFilter* filter = static_cast<itk::itkTranslationMattesMIRegistrationFilter *> (m_ITKFilter);

  filter->SetMovingImageShrinkFactors(this->SourceShrink);
  filter->SetFixedImageShrinkFactors(this->TargetShrink);

  DoubleArray      MinimumStepLength(this->GetMinimumStepLength()->GetNumberOfTuples());
  DoubleArray      MaximumStepLength(this->GetMaximumStepLength()->GetNumberOfTuples());
  UnsignedIntArray NumIterations(this->GetMaxNumberOfIterations()->GetNumberOfTuples());


  for(int i=0; i< this->GetMaxNumberOfIterations()->GetNumberOfTuples();i++) {
    MinimumStepLength[i]    = this->GetMinimumStepLength()->GetValue(i);
    MaximumStepLength[i]    = this->GetMaximumStepLength()->GetValue(i);
    NumIterations[i] = this->GetMaxNumberOfIterations()->GetValue(i);
  }
  filter->SetNumberOfLevels(this->GetMaxNumberOfIterations()->GetNumberOfTuples());
  filter->SetMinimumStepLength(MinimumStepLength);
  filter->SetMaximumStepLength(MaximumStepLength);
  filter->SetNumberOfIterations(NumIterations);
  filter->SetNumberOfSpatialSamples(NumberOfSamples);
  filter->SetNumberOfHistogramBins(NumberOfHistogramBins);
}

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKTranslationMattesMIRegistrationFilter::GetTransformedOutput()
{
   return m_ITKFilter->GetOutput();
}

void
vtkITKTranslationMattesMIRegistrationFilter::GetTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkTranslationMattesMIRegistrationFilter::TransformType::Pointer transform 
    = itk::itkTranslationMattesMIRegistrationFilter::TransformType::New();

  m_ITKFilter->GetTransform(transform);

  itk::itkTranslationMattesMIRegistrationFilter::TransformType::ParametersType params = transform->GetParameters();
  
  matrix->Identity();

  matrix->Element[0][3] = params[0];
  matrix->Element[1][3] = params[1];
  matrix->Element[2][3] = params[2];
}
  
void
vtkITKTranslationMattesMIRegistrationFilter::GetCurrentTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkTranslationMattesMIRegistrationFilter::TransformType::Pointer transform 
    = itk::itkTranslationMattesMIRegistrationFilter::TransformType::New();
  
  m_ITKFilter->GetCurrentTransform(transform);
  
  itk::itkTranslationMattesMIRegistrationFilter::TransformType::ParametersType params = transform->GetParameters();

  matrix->Identity();

  matrix->Element[0][3] = params[0];
  matrix->Element[1][3] = params[1];
  matrix->Element[2][3] = params[2];
}
  
void 
vtkITKTranslationMattesMIRegistrationFilter::SetTransformationMatrix(vtkMatrix4x4 *matrix)
{
  itk::itkTranslationMattesMIRegistrationFilter::ParametersType  initialParameters = itk::itkTranslationMattesMIRegistrationFilter::ParametersType(12);

  initialParameters[0] = matrix->Element[0][3];
  initialParameters[1] = matrix->Element[1][3];
  initialParameters[2] = matrix->Element[2][3];

  itk::itkTranslationMattesMIRegistrationFilter::TransformType::Pointer transform = itk::itkTranslationMattesMIRegistrationFilter::TransformType::New();
  transform->SetParameters(initialParameters);
  m_ITKFilter->SetTransform(transform);
}


void 
vtkITKTranslationMattesMIRegistrationFilter::SetSourceShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  SourceShrink[0] = i;
  SourceShrink[1] = j;
  SourceShrink[2] = k;
} //vtkITKTranslationMattesMIRegistrationFilter

void 
vtkITKTranslationMattesMIRegistrationFilter::SetTargetShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  TargetShrink[0] = i;
  TargetShrink[1] = j;
  TargetShrink[2] = k;
} //vtkITKTranslationMattesMIRegistrationFilter
