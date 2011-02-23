/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKRegistrationFilter.h,v $
  Date:      $Date: 2006/05/26 19:52:12 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKRegistrationFilter_h
#define __vtkITKRegistrationFilter_h


#include "vtkITKImageToImageFilter.h"
#include "vtkImageToImageFilter.h"
#include "itkImageToImageFilter.h"
#include "itkVTKImageExport.h"
#include "itkVTKImageImport.h"
#include "vtkITKUtility.h"
#include "vtkImageFlip.h"

#include "itkImageRegionIterator.h"
#include "itkCastImageFilter.h"

#include "itkImageFileWriter.h"

#include "vtkImageData.h"


#include <fstream>
#include <string>

#define vtkRegistrationNewMacro(thisClass) \
  thisClass* thisClass::New() \
  { \
    vtkObject* ret = vtkObjectFactory::CreateInstance(#thisClass); \
    if(ret) \
      { \
          thisClass* c = static_cast<thisClass*>(ret); \
          c->InitializePipeline(); \
      return (c); \
      } \
    thisClass* c = new thisClass; \
    c->InitializePipeline(); \
    return c; \
  } \
  vtkInstantiatorNewMacro(thisClass)

// vtkITKRegistrationFilter Class

class VTK_EXPORT vtkITKRegistrationFilter : public vtkITKImageToImageFilter
{
public:
  vtkTypeMacro(vtkITKRegistrationFilter,vtkITKImageToImageFilter);

  static vtkITKRegistrationFilter* New(){return 0;};

  void PrintSelf(ostream& os, vtkIndent indent)
  {
    Superclass::PrintSelf ( os, indent );
  };

  void SetCurrentIteration (int iter) {
    CurrentIteration = iter;
  };
  int GetCurrentIteration() {
    return CurrentIteration;
  };

  void Update();

  // Description:
  // Set the Input, 0-fixed image, 1-moving image
  virtual void SetInput(vtkImageData *Input, int idx)
  {
    if (idx == 0) {
      this->vtkCast->SetInput(Input);
    }
    else if (idx == 1) {
      this->vtkCastMoving->SetInput(Input);
    }
    else {
      // report error
    }
  };
  virtual vtkImageData* GetInput(int idx)
  {
    if (idx == 0) {
#if (VTK_MAJOR_VERSION >= 5)
      return this->vtkCast->GetImageDataInput(0);
#else
      return this->vtkCast->GetInput();
#endif
    }
    else if (idx == 1) {
#if (VTK_MAJOR_VERSION >= 5)
      return this->vtkCastMoving->GetImageDataInput(0);
#else
      return this->vtkCastMoving->GetInput();
#endif
    }
    else {
      // report error
    }
    return NULL;
  };

  // Description:
  // Set Fixed Input
  void SetFixedInput(vtkImageData *Input)
  {
    this->SetInput(Input, 0);
  };

  virtual vtkImageData* GetFixedInput()
  {
    return this->GetInput(0);
  }

  // Description:
  // Set Moving Input
  void SetMovingInput(vtkImageData *Input)
  {
    this->SetInput(Input, 1);
  };

  virtual vtkImageData* GetMovingInput()
  {
    return this->GetInput(1);
  }


  void WriteFixedImage(char* filename);

  void WriteMovingImage(char* filename);

  void WriteFixedImageInfo(char* filename);

  void WriteMovingImageInfo(char* filename);

  void WriteVtkFixedImageInfo(char* filename);

  void WriteVtkMovingImageInfo(char* filename);

protected:
  int    CurrentIteration;
  //BTX
  
  // To/from ITK

  typedef float InputImagePixelType;
  typedef float OutputImagePixelType;
  typedef float InternalPixelType;

  typedef itk::Image<InputImagePixelType, 3> InputImageType;
  typedef itk::Image<OutputImagePixelType, 3> OutputImageType;
  typedef itk::Image<InternalPixelType, 3 >  InternalImageType;

  typedef itk::VTKImageImport<InputImageType> ImageImportType;
  typedef itk::VTKImageExport<OutputImageType> ImageExportType;

  typedef itk::ImageFileWriter< InputImageType  >    FixedWriterType;      
  typedef itk::ImageFileWriter< InputImageType >     MovingWriterType;      

  // itk import for input itk images
  ImageImportType::Pointer itkImporterFixed;
  ImageImportType::Pointer itkImporterMoving;

  // itk export for output itk images
  ImageExportType::Pointer itkExporterTransformed;

  // vtk export for moving vtk image
  vtkImageCast* vtkCastMoving;
  vtkImageExport* vtkExporterMoving;  
  vtkImageFlip* vtkFlipMoving;
  vtkImageFlip* vtkFlipFixed;

  FixedWriterType::Pointer   itkFixedImageWriter;
  MovingWriterType::Pointer  itkMovingImageWriter;

  void InitializePipeline();

  virtual OutputImageType::Pointer GetTransformedOutput() = 0;

  virtual void UpdateRegistrationParameters() = 0;

  virtual void ConnectInputPipelines();

  virtual void CreateRegistrationPipeline(){};

  virtual void ConnectOutputPipelines();

  virtual void AbortIterations() = 0;

  // default constructor
  vtkITKRegistrationFilter (){}; 

  virtual ~vtkITKRegistrationFilter();
  //ETX
  
private:
  vtkITKRegistrationFilter(const vtkITKRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKRegistrationFilter&);  // Not implemented.
};

#endif




