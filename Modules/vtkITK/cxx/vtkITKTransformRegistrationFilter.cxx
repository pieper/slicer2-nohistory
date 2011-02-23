/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKTransformRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkITKTransformRegistrationFilter.h" // This class

vtkITKTransformRegistrationFilter::vtkITKTransformRegistrationFilter()
{
  Error = 0;
  m_Matrix = vtkMatrix4x4::New();
}

vtkITKTransformRegistrationFilter::~vtkITKTransformRegistrationFilter()
{
  m_Matrix->Delete();
}

vtkITKRegistrationFilter::OutputImageType::Pointer vtkITKTransformRegistrationFilter::GetTransformedOutput()
{
  //return m_ITKFilter->GetOutput();
  return NULL;
}


void vtkITKTransformRegistrationFilter::CreateRegistrationPipeline()
{ 
}

void vtkITKTransformRegistrationFilter::vtkItkMatrixTransform (vtkMatrix4x4 *matIn, vtkMatrix4x4 *matOut)
{
  // itk to vtk flip matrix
  vtkMatrix4x4 *rot = vtkMatrix4x4::New();
  rot->Identity();
  rot->Element[1][1] = -1;
  rot->Element[2][2] = -1;

  vtkMatrix4x4 *matrix = vtkMatrix4x4::New();

  // vtk matrix
  //vtkMatrix4x4::Multiply4x4(rot, matIn, matrix);
  //vtkMatrix4x4::Multiply4x4(matrix, rot, matOut);
  vtkMatrix4x4::Multiply4x4(matIn, rot, matrix);
  vtkMatrix4x4::Multiply4x4(rot, matrix, matOut);

  rot->Delete();
  matrix->Delete();
}

