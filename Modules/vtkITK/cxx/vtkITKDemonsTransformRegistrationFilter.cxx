/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKDemonsTransformRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:45 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include "vtkITKDemonsTransformRegistrationFilter.h" // This class

typedef itk::Array<unsigned int> UnsignedIntArray;
typedef itk::Array<double> DoubleArray;

vtkITKDemonsTransformRegistrationFilter::vtkITKDemonsTransformRegistrationFilter()
{
  this->MaxNumberOfIterations = vtkUnsignedIntArray::New();
  this->SetNextMaxNumberOfIterations(100);
  this->StandardDeviations = 1.0;
  this-> UpdateFieldStandardDeviations = 0;;

  this->NumberOfHistogramLevels = 20;
  this->ThresholdAtMeanIntensity = true;

  CurrentIteration = 0;
  
  m_ITKFilter = itk::itkDemonsTransformRegistrationFilterFF::New();
  LinkITKProgressToVTKProgress(m_ITKFilter);

  // set identity transform by default
  m_Matrix = vtkMatrix4x4::New();
  m_Matrix->Identity();
  this->SetTransformationMatrix(m_Matrix);

}

vtkITKDemonsTransformRegistrationFilter::~vtkITKDemonsTransformRegistrationFilter()
{
  m_Matrix->Delete();
}

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKDemonsTransformRegistrationFilter::GetTransformedOutput()
{
  return m_ITKFilter->GetOutput();
}

vtkITKDeformableRegistrationFilter::DeformationFieldType::Pointer vtkITKDemonsTransformRegistrationFilter::GetDisplacementOutput()
{
  return m_ITKFilter->GetDeformationField();
}

void vtkITKDemonsTransformRegistrationFilter::CreateRegistrationPipeline()
{
  DemonsTransformRegistrationFilterCommand::Pointer observer = DemonsTransformRegistrationFilterCommand::New();
  observer->SetDemonsRegistrationFilter(this);
  m_ITKFilter->AddIterationObserver(observer );
  m_ITKFilter->SetInput(itkImporterFixed->GetOutput());
  m_ITKFilter->SetInput(1, itkImporterMoving->GetOutput());
}

void vtkITKDemonsTransformRegistrationFilter::UpdateRegistrationParameters()
{
  UnsignedIntArray NumIterations(this->GetMaxNumberOfIterations()->GetNumberOfTuples());
  for(int i=0; i< this->GetMaxNumberOfIterations()->GetNumberOfTuples();i++) {
    NumIterations[i] = this->GetMaxNumberOfIterations()->GetValue(i);
  }
  m_ITKFilter->SetNumberOfLevels(this->GetMaxNumberOfIterations()->GetNumberOfTuples());
  m_ITKFilter->SetNumberOfIterations(NumIterations);

  m_ITKFilter->SetNumberOfHistogramLevels(NumberOfHistogramLevels);
  m_ITKFilter->SetThresholdAtMeanIntensity(ThresholdAtMeanIntensity);

  m_ITKFilter->SetStandardDeviations(StandardDeviations);
  m_ITKFilter->SetUpdateFieldStandardDeviations(UpdateFieldStandardDeviations);
  //m_ITKFilter->Update();
}

void
vtkITKDemonsTransformRegistrationFilter::GetTransformationMatrix(vtkMatrix4x4* matrix)
{
  TransformType::Pointer transform 
    = TransformType::New();

  m_ITKFilter->GetTransform(transform);

  TransformType::ParametersType params = transform->GetParameters();
  
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

  matrix->Invert();
}
  
  
void 
vtkITKDemonsTransformRegistrationFilter::SetTransformationMatrix(vtkMatrix4x4 *matrix)
{
  TransformType::ParametersType  initialParameters = TransformType::ParametersType(12);

  vtkMatrix4x4* matrixInv = vtkMatrix4x4::New();

  vtkMatrix4x4::Invert(matrix, matrixInv);

  int count=0;
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      initialParameters[count++] = matrixInv->Element[i][j];
    }
  }
  
  initialParameters[9] = matrixInv->Element[0][3];
  initialParameters[10] = matrixInv->Element[1][3];
  initialParameters[11] = matrixInv->Element[2][3];

  TransformType::Pointer transform = TransformType::New();
  transform->SetParameters(initialParameters);
  m_ITKFilter->SetTransform(transform);

  matrixInv->Delete();
}

