/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKAffineMattesMIRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkITKAffineMattesMIRegistrationFilter.h"
typedef itk::Array<unsigned int> UnsignedIntArray;
typedef itk::Array<double> DoubleArray;

vtkITKAffineMattesMIRegistrationFilter::vtkITKAffineMattesMIRegistrationFilter()
{
  m_ITKFilter = itk::itkAffineMattesMIRegistrationFilter::New();
  LinkITKProgressToVTKProgress(m_ITKFilter);
  this->SetSourceShrinkFactors(1,1,1);
  this->SetTargetShrinkFactors(1,1,1);
  this->SetTranslateScale(0.001);

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

void vtkITKAffineMattesMIRegistrationFilter::CreateRegistrationPipeline()
{

  m_ITKFilter->SetInput(itkImporterFixed->GetOutput());
  m_ITKFilter->SetInput(1, itkImporterMoving->GetOutput());

  vtkITKTransformRegistrationCommand::Pointer observer = vtkITKTransformRegistrationCommand::New();
  observer->SetRegistrationFilter(this);
  m_ITKFilter->AddIterationObserver(observer );
}

void 
vtkITKAffineMattesMIRegistrationFilter::UpdateRegistrationParameters()
{
  itk::itkAffineMattesMIRegistrationFilter* filter = static_cast<itk::itkAffineMattesMIRegistrationFilter *> (m_ITKFilter);

  filter->SetTranslationScale(this->GetTranslateScale());
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

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKAffineMattesMIRegistrationFilter::GetTransformedOutput()
{
   return m_ITKFilter->GetOutput();
}

void
vtkITKAffineMattesMIRegistrationFilter::GetTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkAffineMattesMIRegistrationFilter::TransformType::Pointer transform 
    = itk::itkAffineMattesMIRegistrationFilter::TransformType::New();

  m_ITKFilter->GetTransform(transform);

  itk::itkAffineMattesMIRegistrationFilter::TransformType::ParametersType params = transform->GetParameters();
  
  matrix->Identity();
  int count=0;
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      matrix->Element[i][j] = params[count++];
    }
  }

  // Add translation
  matrix->Element[0][3] = params[9];
  matrix->Element[1][3] = params[10];
  matrix->Element[2][3] = params[11];
}
  
void
vtkITKAffineMattesMIRegistrationFilter::GetCurrentTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkAffineMattesMIRegistrationFilter::TransformType::Pointer transform 
    = itk::itkAffineMattesMIRegistrationFilter::TransformType::New();
  
  m_ITKFilter->GetCurrentTransform(transform);
  
  itk::itkAffineMattesMIRegistrationFilter::TransformType::ParametersType params = transform->GetParameters();

  matrix->Identity();
  int count=0;
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      matrix->Element[i][j] = params[count++];
    }
  }

  // Add translation
  matrix->Element[0][3] = params[9];
  matrix->Element[1][3] = params[10];
  matrix->Element[2][3] = params[11];
}
  
void 
vtkITKAffineMattesMIRegistrationFilter::SetTransformationMatrix(vtkMatrix4x4 *matrix)
{
  itk::itkAffineMattesMIRegistrationFilter::ParametersType  initialParameters = itk::itkAffineMattesMIRegistrationFilter::ParametersType(12);

  int count=0;
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      initialParameters[count++] = matrix->Element[i][j];
    }
  }
  
  initialParameters[9] = matrix->Element[0][3];
  initialParameters[10] = matrix->Element[1][3];
  initialParameters[11] = matrix->Element[2][3];

  itk::itkAffineMattesMIRegistrationFilter::TransformType::Pointer transform = itk::itkAffineMattesMIRegistrationFilter::TransformType::New();
  transform->SetParameters(initialParameters);
  m_ITKFilter->SetTransform(transform);
}


void 
vtkITKAffineMattesMIRegistrationFilter::SetSourceShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  SourceShrink[0] = i;
  SourceShrink[1] = j;
  SourceShrink[2] = k;
} //vtkITKAffineMattesMIRegistrationFilter

void 
vtkITKAffineMattesMIRegistrationFilter::SetTargetShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  TargetShrink[0] = i;
  TargetShrink[1] = j;
  TargetShrink[2] = k;
} //vtkITKAffineMattesMIRegistrationFilter
