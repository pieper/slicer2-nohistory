/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKBSplineImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKBSplineImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.3 $
*/
// .NAME vtkITKBSplineImageFilter - Wrapper class around itk::BSplineImageFilterImageFilter
// .SECTION Description
// vtkITKBSplineImageFilter


#ifndef __vtkITKBSplineImageFilter_h
#define __vtkITKBSplineImageFilter_h


#include "vtkITKImageToImageFilterFF.h"
#include "itkBSplineDecompositionImageFilter.h"

class VTK_EXPORT vtkITKBSplineImageFilter : public vtkITKImageToImageFilterFF
{
 public:
  static vtkITKBSplineImageFilter *New();
  vtkTypeRevisionMacro(vtkITKBSplineImageFilter, vtkITKImageToImageFilterFF);
  void SetSplineOrder ( unsigned int order ) { DelegateSetMacro ( SplineOrder, order ); };
  int GetSplineOrder () { DelegateGetMacro ( SplineOrder ); };
  
protected:
  //BTX
  typedef Superclass::InputImageType InputImageType;
  typedef Superclass::OutputImageType OutputImageType;

  typedef itk::BSplineDecompositionImageFilter<InputImageType,OutputImageType> ImageFilterType;

  vtkITKBSplineImageFilter() : Superclass ( ImageFilterType::New() ){}
  ~vtkITKBSplineImageFilter() {};

  //ETX
  
private:
  vtkITKBSplineImageFilter(const vtkITKBSplineImageFilter&);  // Not implemented.
  void operator=(const vtkITKBSplineImageFilter&);  // Not implemented.
};

#endif




