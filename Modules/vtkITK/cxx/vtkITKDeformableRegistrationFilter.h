/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKDeformableRegistrationFilter.h,v $
  Date:      $Date: 2006/05/26 19:52:12 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKDeformableRegistrationFilter_h
#define __vtkITKDeformableRegistrationFilter_h


#include "vtkITKRegistrationFilter.h"
#include "vtkImageFlip.h"


// vtkITKDeformableRegistrationFilter Class

class VTK_EXPORT vtkITKDeformableRegistrationFilter : public vtkITKRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKDeformableRegistrationFilter,vtkITKImageToImageFilter);

  static vtkITKDeformableRegistrationFilter* New(){return 0;};

  // Description:
  // Get the Output, 0-transformed image, 1-dispacement image
  virtual vtkImageData *GetOutput(int idx)
  {
    if (idx == 0) {
      return (vtkImageData *) this->vtkImporter->GetOutput();
    }
    else if (idx == 1) {
      // NO FLIP version
      return (vtkImageData *) this->vtkImporterDisplacement->GetOutput();
      // END NO FLIP version

      //this->vtkFlipDisplacement->Update();
      //return (vtkImageData *) this->vtkFlipDisplacement->GetOutput();
    }
    else {
      return NULL;
    }
  };
  
  // Description:
  // Get dispacement image
  virtual vtkImageData *GetOutputDisplacement()
  {
    return GetOutput(1);
  };

  void Update();

protected:

  //BTX

  typedef itk::Vector<float, 3>    VectorPixelType;
  typedef itk::Image<VectorPixelType, 3> DeformationFieldType;
  typedef itk::VTKImageExport<DeformationFieldType> DeformationExportType;

  DeformationExportType::Pointer itkExporterDisplacement;

  // vtk import for output vtk displacement image
  vtkImageImport *vtkImporterDisplacement;

  vtkImageFlip* vtkFlipDisplacement;

  // default constructor
  vtkITKDeformableRegistrationFilter () {}; // This is called from New() by vtkStandardNewMacro

  virtual vtkITKDeformableRegistrationFilter::DeformationFieldType::Pointer GetDisplacementOutput() = 0;

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput() = 0;

  virtual void UpdateRegistrationParameters() = 0;

  virtual void CreateRegistrationPipeline(){};

  virtual void ConnectOutputPipelines();

  virtual void AbortIterations() = 0;

  virtual ~vtkITKDeformableRegistrationFilter();
  //ETX


private:
  vtkITKDeformableRegistrationFilter(const vtkITKDeformableRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKDeformableRegistrationFilter&);  // Not implemented.
};

#endif




