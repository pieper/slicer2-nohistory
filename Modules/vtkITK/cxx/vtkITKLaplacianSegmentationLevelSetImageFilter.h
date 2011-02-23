/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKLaplacianSegmentationLevelSetImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKLaplacianSegmentationLevelSetImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.4 $
*/
// .NAME vtkITKLaplacianSegmentationLevelSetImageFilter - Wrapper class around itk::LaplacianSegmentationLevelSetImageFilterImageFilter
// .SECTION Description
// vtkITKLaplacianSegmentationLevelSetImageFilter


#ifndef __vtkITKLaplacianSegmentationLevelSetImageFilter_h
#define __vtkITKLaplacianSegmentationLevelSetImageFilter_h


#include "vtkITKImageToImageFilterFF.h"
#include "itkLaplacianSegmentationLevelSetImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKLaplacianSegmentationLevelSetImageFilter : public vtkITKImageToImageFilterFF
{
 public:
  static vtkITKLaplacianSegmentationLevelSetImageFilter *New();
  vtkTypeRevisionMacro(vtkITKLaplacianSegmentationLevelSetImageFilter, vtkITKImageToImageFilterFF);

  float GetIsoSurfaceValue ()
  {
    DelegateITKOutputMacro(GetIsoSurfaceValue) ;
  };

  void SetIsoSurfaceValue ( float value )
  {
     DelegateITKInputMacro ( SetIsoSurfaceValue, value );
  };
  
  void SetMaximumIterations ( int value )
  {
    DelegateITKInputMacro ( SetMaximumIterations, value );
  };

  void SetMaximumRMSError ( float value )
  {
    DelegateITKInputMacro ( SetMaximumRMSError, value );
  };

  void SetUseNegativeFeatures (int value )
  {
    DelegateITKInputMacro( SetUseNegativeFeatures, value);
  };
  
  void SetFeatureImage ( vtkImageData *value)
  {
    this->vtkFeatureExporter->SetInput(value);
  };

  void SetFeatureScaling ( float value )
  {
    DelegateITKInputMacro ( SetFeatureScaling, value );
  };

  void SetCurvatureScaling ( float value )
  {
    DelegateITKInputMacro ( SetCurvatureScaling, value );
  };

  float GetCurvatureScaling ()
  {
    DelegateITKOutputMacro(GetCurvatureScaling) ;
  };
  
  vtkImageData *GetSpeedImage()
  {
    this->vtkSpeedImporter->Update();
    return this->vtkSpeedImporter->GetOutput();
  };

  float GetRMSChange ()
  {
    DelegateITKOutputMacro(GetRMSChange);
  };

  int GetElapsedIterations()
  {
    DelegateITKOutputMacro(GetElapsedIterations);
  };

  
  // Description: Override vtkSource's Update so that we can access this class's GetOutput(). vtkSource's GetOutput is not virtual.
  void Update()
  {
    if (this->vtkFeatureExporter->GetInput())
      {
        this->itkFeatureImporter->Update();
        
        if (this->GetOutput(0))
          {
            this->GetOutput(0)->Update();
            if ( this->GetOutput(0)->GetSource() )
              {
                //          this->SetErrorCode( this->GetOutput(0)->GetSource()->GetErrorCode() );
              }
          }
      }
  }
    
protected:
  //BTX
  typedef itk::LaplacianSegmentationLevelSetImageFilter<Superclass::InputImageType,Superclass::InputImageType> ImageFilterType;
  typedef itk::VTKImageImport<InputImageType> FeatureImageImportType;
  typedef itk::VTKImageExport<InputImageType> SpeedImageExportType;
  
  vtkITKLaplacianSegmentationLevelSetImageFilter() : Superclass ( ImageFilterType::New() )
  {
    this->vtkFeatureExporter = vtkImageExport::New();
    this->itkFeatureImporter = FeatureImageImportType::New();
    this->itkSpeedExporter = SpeedImageExportType::New();
    this->vtkSpeedImporter = vtkImageImport::New();
    ConnectPipelines(this->itkSpeedExporter, this->vtkSpeedImporter);
    ConnectPipelines(this->vtkFeatureExporter, this->itkFeatureImporter);
    (dynamic_cast<ImageFilterType*>(m_Filter.GetPointer()))->SetFeatureImage(this->itkFeatureImporter->GetOutput());
    this->itkSpeedExporter->SetInput((dynamic_cast<ImageFilterType*>(m_Filter.GetPointer()))->GetSpeedImage());
  };
  ~vtkITKLaplacianSegmentationLevelSetImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }
  
  FeatureImageImportType::Pointer itkFeatureImporter;
  SpeedImageExportType::Pointer itkSpeedExporter;
  //ETX

  vtkImageExport *vtkFeatureExporter;
  vtkImageImport *vtkSpeedImporter;
  
private:
  vtkITKLaplacianSegmentationLevelSetImageFilter(const vtkITKLaplacianSegmentationLevelSetImageFilter&);  // Not implemented.
  void operator=(const vtkITKLaplacianSegmentationLevelSetImageFilter&);  //
                                                                          // Not implemented
  
};

vtkCxxRevisionMacro(vtkITKLaplacianSegmentationLevelSetImageFilter, "$Revision: 1.4 $");
vtkStandardNewMacro(vtkITKLaplacianSegmentationLevelSetImageFilter);

#endif

