/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKDeformableRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:45 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include "vtkITKDeformableRegistrationFilter.h" // This class

void vtkITKDeformableRegistrationFilter::ConnectOutputPipelines()
{

  vtkITKRegistrationFilter::ConnectOutputPipelines();

  // Set pipline for output displacement image
  this->vtkImporterDisplacement = vtkImageImport::New();
  this->itkExporterDisplacement = DeformationExportType::New();
  ConnectPipelines(this->itkExporterDisplacement, this->vtkImporterDisplacement);

  this->itkExporterDisplacement->SetInput(GetDisplacementOutput());

  // flip displacement image
  this->vtkFlipDisplacement = vtkImageFlip::New();
  this->vtkFlipDisplacement->SetInput( this->vtkImporterDisplacement->GetOutput() );
  this->vtkFlipDisplacement->SetFilteredAxis(1);
  this->vtkFlipDisplacement->FlipAboutOriginOn();

};

vtkITKDeformableRegistrationFilter::~vtkITKDeformableRegistrationFilter()
{
  this->vtkImporterDisplacement->Delete();
};

void vtkITKDeformableRegistrationFilter::Update()
{
  vtkITKRegistrationFilter::Update();

  //vtkImporterDisplacement->Update();
}

