/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKGradientMagnitudeImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:46 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKGradientMagnitudeImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:46 $
  Version:   $Revision: 1.4 $
*/
// .NAME vtkITKGradientMagnitudeImageFilter - Wrapper class around itk::GradientMagnitudeImageFilterImageFilter
// .SECTION Description
// vtkITKGradientMagnitudeImageFilter


#ifndef __vtkITKGradientMagnitudeImageFilter_h
#define __vtkITKGradientMagnitudeImageFilter_h


#include "vtkITKImageToImageFilterFF.h"
#include "itkGradientMagnitudeImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKGradientMagnitudeImageFilter : public vtkITKImageToImageFilterFF
{
 public:
  static vtkITKGradientMagnitudeImageFilter *New();
  vtkTypeRevisionMacro(vtkITKGradientMagnitudeImageFilter, vtkITKImageToImageFilterFF);

protected:
  //BTX
  typedef itk::GradientMagnitudeImageFilter<Superclass::InputImageType,Superclass::InputImageType> ImageFilterType;
  vtkITKGradientMagnitudeImageFilter() : Superclass ( ImageFilterType::New() ){};
  ~vtkITKGradientMagnitudeImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }

  //ETX
  
private:
  vtkITKGradientMagnitudeImageFilter(const vtkITKGradientMagnitudeImageFilter&);  // Not implemented.
  void operator=(const vtkITKGradientMagnitudeImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKGradientMagnitudeImageFilter, "$Revision: 1.4 $");
vtkStandardNewMacro(vtkITKGradientMagnitudeImageFilter);

#endif




