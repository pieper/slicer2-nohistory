/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKWatershedImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:49 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKWatershedImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:49 $
  Version:   $Revision: 1.4 $
*/
// .NAME vtkITKWatershedImageFilter - Wrapper class around itk::WatershedImageFilterImageFilter
// .SECTION Description
// vtkITKWatershedImageFilter


#ifndef __vtkITKWatershedImageFilter_h
#define __vtkITKWatershedImageFilter_h


#include "vtkITKImageToImageFilterFUL.h"
#include "itkWatershedImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKWatershedImageFilter : public vtkITKImageToImageFilterFUL
{
 public:
  static vtkITKWatershedImageFilter *New();
  vtkTypeRevisionMacro(vtkITKWatershedImageFilter, vtkITKImageToImageFilterFUL);

  void SetThreshold ( double d ) { DelegateSetMacro ( Threshold, d ); };
  double GetThreshold () { DelegateGetMacro ( Threshold ); };
  void SetLevel ( double d ) { DelegateSetMacro ( Level, d ); };
  double GetLevel () { DelegateGetMacro ( Level ); };

protected:
  //BTX
  typedef itk::WatershedImageFilter<Superclass::InputImageType> ImageFilterType;
  vtkITKWatershedImageFilter() : Superclass ( ImageFilterType::New() ){};
  ~vtkITKWatershedImageFilter() {};

  //ETX
  
private:
  vtkITKWatershedImageFilter(const vtkITKWatershedImageFilter&);  // Not implemented.
  void operator=(const vtkITKWatershedImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKWatershedImageFilter, "$Revision: 1.4 $");
vtkStandardNewMacro(vtkITKWatershedImageFilter);

#endif




