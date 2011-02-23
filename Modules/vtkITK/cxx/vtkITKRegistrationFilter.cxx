/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
#include "vtkITKRegistrationFilter.h" // This class
void vtkITKRegistrationFilter::InitializePipeline()
{
    CurrentIteration = 0;
    ConnectInputPipelines();
    CreateRegistrationPipeline();
    ConnectOutputPipelines();
}
void vtkITKRegistrationFilter::ConnectInputPipelines()
{
  // set pipeline for fixed image
  this->vtkCast = vtkImageCast::New();
  this->vtkExporter = vtkImageExport::New();
  this->vtkCast->SetOutputScalarTypeToFloat();

  this->vtkFlipFixed = vtkImageFlip::New();
  this->vtkFlipFixed->SetInput( this->vtkCast->GetOutput() );
  this->vtkFlipFixed->SetFilteredAxis(1);
  this->vtkFlipFixed->FlipAboutOriginOn();

  this->vtkExporter->SetInput ( this->vtkFlipFixed->GetOutput() );

  this->itkImporterFixed = ImageImportType::New();
  ConnectPipelines(this->vtkExporter, this->itkImporterFixed);

  // set pipeline for movin image
  this->vtkCastMoving = vtkImageCast::New();
  this->vtkExporterMoving = vtkImageExport::New();
  this->vtkCastMoving->SetOutputScalarTypeToFloat();

  this->vtkFlipMoving = vtkImageFlip::New();
  this->vtkFlipMoving->SetInput( this->vtkCastMoving->GetOutput() );
  this->vtkFlipMoving->SetFilteredAxis(1);
  this->vtkFlipMoving->FlipAboutOriginOn();

  this->vtkExporterMoving->SetInput ( this->vtkFlipMoving->GetOutput() );

  this->itkImporterMoving = ImageImportType::New();
  ConnectPipelines(this->vtkExporterMoving, this->itkImporterMoving);

  this->itkFixedImageWriter         = FixedWriterType::New();
  this->itkMovingImageWriter        = MovingWriterType::New();

}

void vtkITKRegistrationFilter::ConnectOutputPipelines()
{
  // Set pipline for output transformed image
  this->itkExporterTransformed = ImageExportType::New();
  ConnectPipelines(this->itkExporterTransformed, this->vtkImporter);
  this->itkExporterTransformed->SetInput ( GetTransformedOutput() );

};

vtkITKRegistrationFilter::~vtkITKRegistrationFilter()
{
  this->vtkExporterMoving->Delete();
  this->vtkCastMoving->Delete();
  this->vtkFlipFixed->Delete();
  this->vtkFlipMoving->Delete();
};

void vtkITKRegistrationFilter::Update()
{
  this->AbortExecuteOff();

  this->itkImporterMoving->Update();
  this->itkImporterFixed->Update();

  this->UpdateRegistrationParameters();

  this->SetCurrentIteration(0);
  //this->GetOutput(0)->SetExtent(0,0,0,0,0,0);
  vtkITKImageToImageFilter::Update();

  //vtkImporter->Update();
}

void vtkITKRegistrationFilter::WriteFixedImage(char* filename)
{
  this->itkFixedImageWriter->SetInput(this->itkImporterFixed->GetOutput());
  this->itkFixedImageWriter->SetFileName( filename );
  this->itkFixedImageWriter->Update();
}

void vtkITKRegistrationFilter::WriteMovingImage(char* filename)
{
  this->itkMovingImageWriter->SetInput(this->itkImporterMoving->GetOutput());
  this->itkMovingImageWriter->SetFileName( filename );
  this->itkMovingImageWriter->Update();
}

void vtkITKRegistrationFilter::WriteFixedImageInfo(char* filename)
{
  std::ofstream ofs(filename);
  InputImageType::SpacingType spacing = (this->itkImporterFixed->GetOutput()->GetSpacing());
  InputImageType::PointType origin = (this->itkImporterFixed->GetOutput()->GetOrigin());
  ofs << "Origin = " << origin << std::endl;
  ofs << "Spacing = " << spacing << std::endl;
  ofs.close();
}

void vtkITKRegistrationFilter::WriteMovingImageInfo(char* filename)
{
  std::ofstream ofs(filename);
  InputImageType::SpacingType spacing = (this->itkImporterFixed->GetOutput()->GetSpacing());
  InputImageType::PointType origin = (this->itkImporterFixed->GetOutput()->GetOrigin());
  ofs << "Origin = " << origin << std::endl;
  ofs << "Spacing = " << spacing << std::endl;
  ofs.close();
}

void vtkITKRegistrationFilter::WriteVtkFixedImageInfo(char* filename)
{
  std::ofstream ofs(filename);
  this->vtkExporter->GetInput()->PrintSelf(ofs, 0);
  ofs.close();
}

void vtkITKRegistrationFilter::WriteVtkMovingImageInfo(char* filename)
{
  std::ofstream ofs(filename);
  this->vtkExporterMoving->GetInput()->PrintSelf(ofs, 0);
  ofs.close();
}


