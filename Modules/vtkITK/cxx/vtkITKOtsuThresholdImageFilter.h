/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKOtsuThresholdImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKOtsuThresholdImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.3 $
*/
// .NAME vtkITKOtsuThresholdImageFilter - Wrapper class around itk::OtsuThresholdImageFilter
// .SECTION Description
// vtkITKOtsuThresholdImageFilter


#ifndef __vtkITKOtsuThresholdImageFilter_h
#define __vtkITKOtsuThresholdImageFilter_h


#include "vtkITKImageToImageFilterSS.h"
#include "itkOtsuThresholdImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKOtsuThresholdImageFilter : public vtkITKImageToImageFilterSS
{
 public:
  static vtkITKOtsuThresholdImageFilter *New();
  vtkTypeRevisionMacro(vtkITKOtsuThresholdImageFilter, vtkITKImageToImageFilterSS);
  
  void SetNumberOfHistogramBins( unsigned long value) 
  {
    DelegateITKInputMacro ( SetNumberOfHistogramBins, value );
  };
  unsigned long GetNumberOfHistogramBins ()
  { DelegateITKOutputMacro ( GetNumberOfHistogramBins ); };
  
  void SetInsideValue (short value)
  { 
    OutputImagePixelType d = static_cast<OutputImagePixelType> ( value );
    DelegateITKInputMacro (SetInsideValue,d);
  }
  
  void SetOutsideValue (short value)
  { 
    OutputImagePixelType d = static_cast<OutputImagePixelType> ( value );
    DelegateITKInputMacro (SetOutsideValue,d);
  }
  
  short GetInsideValue ()
  { DelegateITKOutputMacro ( GetInsideValue ); };
  
  short GetOutsideValue ()
  { DelegateITKOutputMacro ( GetOutsideValue ); };
 
  short GetThreshold()
  { DelegateITKOutputMacro ( GetThreshold ); };

protected:
  //BTX
  typedef itk::OtsuThresholdImageFilter<Superclass::InputImageType, Superclass::OutputImageType> ImageFilterType;
  vtkITKOtsuThresholdImageFilter() : Superclass ( ImageFilterType::New() ){};
  ~vtkITKOtsuThresholdImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }
  //ETX
  
private:
  vtkITKOtsuThresholdImageFilter(const vtkITKOtsuThresholdImageFilter&);  // Not implemented.
  void operator=(const vtkITKOtsuThresholdImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKOtsuThresholdImageFilter, "$Revision: 1.3 $");
vtkStandardNewMacro(vtkITKOtsuThresholdImageFilter);

#endif




