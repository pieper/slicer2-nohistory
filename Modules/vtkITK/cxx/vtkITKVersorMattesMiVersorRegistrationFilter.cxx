/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKVersorMattesMiVersorRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/
#include "vtkITKVersorMattesMiVersorRegistrationFilter.h"
typedef itk::Array<unsigned int> UnsignedIntArray;
typedef itk::Array<double> DoubleArray;

vtkITKVersorMattesMiVersorRegistrationFilter::vtkITKVersorMattesMiVersorRegistrationFilter()
{
  m_ITKFilter = itk::itkVersorMattesMiVersorRegistrationFilter::New();
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

void vtkITKVersorMattesMiVersorRegistrationFilter::CreateRegistrationPipeline()
{
  m_ITKFilter->SetInput(itkImporterFixed->GetOutput());
  m_ITKFilter->SetInput(1, itkImporterMoving->GetOutput());

  vtkITKTransformRegistrationCommand::Pointer observer = vtkITKTransformRegistrationCommand::New();
  observer->SetRegistrationFilter(this);
  m_ITKFilter->AddIterationObserver(observer );
}

void 
vtkITKVersorMattesMiVersorRegistrationFilter::UpdateRegistrationParameters()
{
  itk::itkVersorMattesMiVersorRegistrationFilter* filter = static_cast<itk::itkVersorMattesMiVersorRegistrationFilter *> (m_ITKFilter);

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

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKVersorMattesMiVersorRegistrationFilter::GetTransformedOutput()
{
   return m_ITKFilter->GetOutput();
}

void
vtkITKVersorMattesMiVersorRegistrationFilter::GetTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::Pointer transform 
    = itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::New();

  m_ITKFilter->GetTransform(transform);

  transform->GetRotationMatrix();

  const itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::MatrixType ResMat   =transform->GetRotationMatrix();
  const itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::OffsetType ResOffset=transform->GetOffset();

  matrix->Identity();
  
  // Create Rotation Matrix
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      matrix->Element[i][j] = ResMat[i][j];
    }
  }

  // Add translation 
  matrix->Element[0][3] = ResOffset[0];
  matrix->Element[1][3] = ResOffset[1];
  matrix->Element[2][3] = ResOffset[2];

}
  
void
vtkITKVersorMattesMiVersorRegistrationFilter::GetCurrentTransformationMatrix(vtkMatrix4x4* matrix)
{
  itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::Pointer transform 
    = itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::New();
  
  m_ITKFilter->GetCurrentTransform(transform);
  
  transform->GetRotationMatrix();
  
  const itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::MatrixType ResMat   =transform->GetRotationMatrix();
  const itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::OffsetType ResOffset=transform->GetOffset();
  
  matrix->Identity();

  // Create Rotation Matrix
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      matrix->Element[i][j] = ResMat[i][j];
    }
  }

  // Add translation 
  matrix->Element[0][3] = ResOffset[0];
  matrix->Element[1][3] = ResOffset[1];
  matrix->Element[2][3] = ResOffset[2];

}
  
void 
vtkITKVersorMattesMiVersorRegistrationFilter::SetTransformationMatrix(vtkMatrix4x4 *matrix)
{
  itk::itkVersorMattesMiVersorRegistrationFilter::ParametersType  initialParameters = itk::itkVersorMattesMiVersorRegistrationFilter::ParametersType(7);

  vtkMatrix4x4 *matrixITK =  vtkMatrix4x4::New();
  matrixITK->DeepCopy(matrix);

  initialParameters[3] = matrixITK->Element[0][3];
  initialParameters[4] = matrixITK->Element[1][3];
  initialParameters[5] = matrixITK->Element[2][3];

  matrixITK->Element[0][3] = 0;
  matrixITK->Element[1][3] = 0;
  matrixITK->Element[2][3] = 0;

  vnl_matrix<double> matrix3x4(3,4);

  for(int i=0;i<3;i++)
    for(int j=0;j<4;j++)
      matrix3x4[i][j] = matrixITK->Element[i][j];
  
  vnl_quaternion<double> matrixAsQuaternion(matrix3x4);

  //initialParameters[0] = matrixAsQuaternion.x();
  //initialParameters[1] = matrixAsQuaternion.y();
  //initialParameters[2] = matrixAsQuaternion.z();

  //There is a transpose between the vnl quaternion and itk quaternion.
  vnl_quaternion<double> conjugated = matrixAsQuaternion.conjugate();

  // This command automatically does the conjugate.
  // But, it does not calculate the paramaters
  // m_Transform->SetRotation(matrixAsQuaternion);

  // Versor have 6 parameters. The first three  represents the
  // quaternion and the last three represents the offset. 
  initialParameters[0] = conjugated.x();
  initialParameters[1] = conjugated.y();
  initialParameters[2] = conjugated.z();

  itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::Pointer transform = itk::itkVersorMattesMiVersorRegistrationFilter::TransformType::New();
  transform->SetParameters(initialParameters);
  // The guess is: a quaternion followed by a translation
  m_ITKFilter->SetTransform(transform);
}


void 
vtkITKVersorMattesMiVersorRegistrationFilter::SetSourceShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  SourceShrink[0] = i;
  SourceShrink[1] = j;
  SourceShrink[2] = k;
} //vtkITKVersorMattesMiVersorRegistrationFilter

void 
vtkITKVersorMattesMiVersorRegistrationFilter::SetTargetShrinkFactors(unsigned int i,
                                                                     unsigned int j, 
                                                                     unsigned int k)
{
  TargetShrink[0] = i;
  TargetShrink[1] = j;
  TargetShrink[2] = k;
} //vtkITKVersorMattesMiVersorRegistrationFilter
