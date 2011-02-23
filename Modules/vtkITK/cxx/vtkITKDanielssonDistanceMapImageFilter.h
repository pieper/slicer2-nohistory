/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKDanielssonDistanceMapImageFilter.h,v $
  Date:      $Date: 2006/03/06 20:09:01 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKDanielssonDistanceMapImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/03/06 20:09:01 $
  Version:   $Revision: 1.6 $
*/
// .NAME vtkITKDanielssonDistanceMapImageFilter - Wrapper class around itk::DanielssonDistanceMapImageFilter
// .SECTION Description
// vtkITKDanielssonDistanceMapImageFilter


#ifndef __vtkITKDanielssonDistanceMapImageFilter_h
#define __vtkITKDanielssonDistanceMapImageFilter_h


#include "vtkITKImageToImageFilterFF.h"
#include "itkDanielssonDistanceMapImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKDanielssonDistanceMapImageFilter : public vtkITKImageToImageFilterFF
{
 public:
  static vtkITKDanielssonDistanceMapImageFilter *New();
  vtkTypeRevisionMacro(vtkITKDanielssonDistanceMapImageFilter, vtkITKImageToImageFilterFF);

  void SetSquaredDistance ( int value ) {
    DelegateITKInputMacro ( SetSquaredDistance, (bool) value );
  }
  int GetSquaredDistance() { 
    DelegateITKOutputMacro ( GetSquaredDistance ); 
  }
  void SquaredDistanceOn() {
    this->SetSquaredDistance (true);
  }
  void SquaredDistanceOff() {
    this->SetSquaredDistance (false);
  }
  int GetInputIsBinary() { 
    DelegateITKOutputMacro ( GetInputIsBinary ); 
  }
  void SetInputIsBinary ( int value ) {
    DelegateITKInputMacro ( SetInputIsBinary, (bool) value );
  }
  void InputIsBinaryOn() {
    this->SetInputIsBinary (true);
  }
  void InputIsBinaryOff() {
    this->SetInputIsBinary (false);
  }
  void SetUseImageSpacing ( int value ) {
    DelegateITKInputMacro ( SetUseImageSpacing, (bool) value );
  }
  int GetUseImageSpacing () {
    DelegateITKOutputMacro ( GetUseImageSpacing );
  } 
  void UseImageSpacingOn () {
    this->SetUseImageSpacing (true);
  }
  void UseImageSpacingOff () {
    this->SetUseImageSpacing (false);
  }
  vtkImageData *GetVoronoiMap() {
    this->vtkVoronoiMapImporter->Update(); 
    return this->vtkVoronoiMapImporter->GetOutput();
  } 
  vtkImageData *GetDistanceMap() {
    this->vtkDistanceMapImporter->Update();
    return this->vtkDistanceMapImporter->GetOutput();
  } 
protected:
  //BTX
  typedef itk::DanielssonDistanceMapImageFilter<Superclass::InputImageType, Superclass::OutputImageType> ImageFilterType;
  typedef itk::VTKImageExport<OutputImageType> VoronoiMapExportType;
  typedef itk::VTKImageExport<OutputImageType> DistanceMapExportType;

  VoronoiMapExportType::Pointer itkVoronoiMapExporter;
  DistanceMapExportType::Pointer itkDistanceMapExporter;  
  vtkImageImport *vtkVoronoiMapImporter;  
  vtkImageImport *vtkDistanceMapImporter; 
 
  vtkITKDanielssonDistanceMapImageFilter() : Superclass ( ImageFilterType::New() ) {
     //VoronoiMap 
    this->itkVoronoiMapExporter = VoronoiMapExportType::New();
    this->vtkVoronoiMapImporter = vtkImageImport::New();
    ConnectPipelines(this->itkVoronoiMapExporter,this->vtkVoronoiMapImporter);
    this->itkVoronoiMapExporter->SetInput((dynamic_cast<ImageFilterType*>(m_Filter.GetPointer()))->GetVoronoiMap());
 
    //DistanceMap
    this->itkDistanceMapExporter = DistanceMapExportType::New();
    this->vtkDistanceMapImporter = vtkImageImport::New();
    ConnectPipelines(this->itkDistanceMapExporter,this->vtkDistanceMapImporter);
    this->itkDistanceMapExporter->SetInput((dynamic_cast<ImageFilterType*>(m_Filter.GetPointer()))->GetDistanceMap());
  }
  ~vtkITKDanielssonDistanceMapImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }

 //ETX

 
private:
  vtkITKDanielssonDistanceMapImageFilter(const vtkITKDanielssonDistanceMapImageFilter&);  // Not implemented.
  void operator=(const vtkITKDanielssonDistanceMapImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKDanielssonDistanceMapImageFilter, "$Revision: 1.6 $");
vtkStandardNewMacro(vtkITKDanielssonDistanceMapImageFilter);

#endif




