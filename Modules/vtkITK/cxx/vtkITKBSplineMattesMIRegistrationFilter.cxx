/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKBSplineMattesMIRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#include "vtkITKBSplineMattesMIRegistrationFilter.h" // This class

vtkITKBSplineMattesMIRegistrationFilter::vtkITKBSplineMattesMIRegistrationFilter()
{

  GridSize = 8;
  CostFunctionConvergenceFactor = 1e+7;
  ProjectedGradientTolerance = 1e-4;
  MaximumNumberOfIterations = 500;
  MaximumNumberOfEvaluations = 500;
  MaximumNumberOfCorrections = 12;
  NumberOfHistogramBins = 50;
  NumberOfSpatialSamples = 100000;

  ResampleMovingImage = false;
  ReinitializeSeed = false;

  m_ITKFilter = itk::itkBSplineMattesMIRegistrationFilterFF::New();
  LinkITKProgressToVTKProgress(m_ITKFilter);

  // set identity transform by default
  m_Matrix = vtkMatrix4x4::New();
  m_Matrix->Identity();
  this->SetTransformationMatrix(m_Matrix);

}

vtkITKBSplineMattesMIRegistrationFilter::~vtkITKBSplineMattesMIRegistrationFilter()
{
  m_Matrix->Delete();
}

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKBSplineMattesMIRegistrationFilter::GetTransformedOutput()
{
  return m_ITKFilter->GetOutput();
}

vtkITKDeformableRegistrationFilter::DeformationFieldType::Pointer vtkITKBSplineMattesMIRegistrationFilter::GetDisplacementOutput()
{
  //m_ITKFilter->GetOutput(1);
  return m_ITKFilter->GetDeformationField();
}

void vtkITKBSplineMattesMIRegistrationFilter::CreateRegistrationPipeline()
{
  BSplineMattesMIRegistrationFilterCommand::Pointer observer = BSplineMattesMIRegistrationFilterCommand::New();
  observer->SeRegistrationFilter(this);
  m_ITKFilter->AddIterationObserver(observer );
  m_ITKFilter->SetInput(itkImporterFixed->GetOutput());
  m_ITKFilter->SetInput(1, itkImporterMoving->GetOutput());
}

void vtkITKBSplineMattesMIRegistrationFilter::UpdateRegistrationParameters()
{
  m_ITKFilter->SetGridSize(GridSize);
  m_ITKFilter->SetCostFunctionConvergenceFactor(CostFunctionConvergenceFactor);
  m_ITKFilter->SetProjectedGradientTolerance(ProjectedGradientTolerance);
  m_ITKFilter->SetMaximumNumberOfIterations(MaximumNumberOfIterations);
  m_ITKFilter->SetMaximumNumberOfEvaluations(MaximumNumberOfEvaluations);
  m_ITKFilter->SetMaximumNumberOfCorrections(MaximumNumberOfCorrections);
  m_ITKFilter->SetNumberOfHistogramBins(NumberOfHistogramBins);
  m_ITKFilter->SetNumberOfSpatialSamples(NumberOfSpatialSamples);
  m_ITKFilter->SetResampleMovingImage(ResampleMovingImage);
  m_ITKFilter->SetReinitializeSeed(ReinitializeSeed);
  //m_ITKFilter->Update();
}

void
vtkITKBSplineMattesMIRegistrationFilter::GetTransformationMatrix(vtkMatrix4x4* matrix)
{
  TransformType::Pointer transform 
    = TransformType::New();

  m_ITKFilter->GetInputTransform(transform);

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
}
  
  
void 
vtkITKBSplineMattesMIRegistrationFilter::SetTransformationMatrix(vtkMatrix4x4 *matrix)
{
  TransformType::ParametersType  initialParameters = TransformType::ParametersType(12);

  int count=0;
  for(int i=0;i<3;i++) {
    for(int j=0;j<3;j++) {
      initialParameters[count++] = matrix->Element[i][j];
    }
  }
  
  initialParameters[9] = matrix->Element[0][3];
  initialParameters[10] = matrix->Element[1][3];
  initialParameters[11] = matrix->Element[2][3];

  TransformType::Pointer transform = TransformType::New();
  transform->SetParameters(initialParameters);
  m_ITKFilter->SetInputTransform(transform);
}

