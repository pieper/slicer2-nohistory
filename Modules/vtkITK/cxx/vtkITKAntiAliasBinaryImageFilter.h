/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKAntiAliasBinaryImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKAntiAliasBinaryImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.4 $
*/
// .NAME vtkITKAntiAliasBinaryImageFilter - Wrapper class around itk::AntiAliasBinaryImageFilterImageFilter
// .SECTION Description
// vtkITKAntiAliasBinaryImageFilter


#ifndef __vtkITKAntiAliasBinaryImageFilter_h
#define __vtkITKAntiAliasBinaryImageFilter_h


#include "vtkITKImageToImageFilterFF.h"
#include "itkAntiAliasBinaryImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKAntiAliasBinaryImageFilter : public vtkITKImageToImageFilterFF
{
 public:
  static vtkITKAntiAliasBinaryImageFilter *New();
  vtkTypeRevisionMacro(vtkITKAntiAliasBinaryImageFilter, vtkITKImageToImageFilterFF);

  float GetUpperBinaryValue ()
  {
    DelegateITKOutputMacro(GetUpperBinaryValue) ;
  };

  float GetLowerBinaryValue ()
  {
    DelegateITKOutputMacro(GetLowerBinaryValue) ;
  };

  float GetIsoSurfaceValue ()
  {
    DelegateITKOutputMacro(GetIsoSurfaceValue) ;
  };

  void SetMaximumIterations ( int value )
  {
    DelegateITKInputMacro ( SetMaximumIterations, value );
  };

  void SetMaximumRMSError ( float value )
  {
    DelegateITKInputMacro ( SetMaximumRMSError, value );
  };

protected:
  //BTX
  typedef itk::AntiAliasBinaryImageFilter<Superclass::InputImageType,Superclass::InputImageType> ImageFilterType;
  vtkITKAntiAliasBinaryImageFilter() : Superclass ( ImageFilterType::New() ){};
  ~vtkITKAntiAliasBinaryImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }

  //ETX
  
private:
  vtkITKAntiAliasBinaryImageFilter(const vtkITKAntiAliasBinaryImageFilter&);  // Not implemented.
  void operator=(const vtkITKAntiAliasBinaryImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKAntiAliasBinaryImageFilter, "$Revision: 1.4 $");
vtkStandardNewMacro(vtkITKAntiAliasBinaryImageFilter);

#endif




