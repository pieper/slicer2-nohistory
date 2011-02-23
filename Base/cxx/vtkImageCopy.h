/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageCopy.h,v $
  Date:      $Date: 2006/02/27 19:21:49 $
  Version:   $Revision: 1.16 $

=========================================================================auto=*/
//.NAME vtkImageCopy copies an image
//.SECTION Description 
// vtkImageCopy takes an image as input and produces a copy of the image
// as output. By setting the clear variable, the output data can be all zeros.
// instead of a copy.

#ifndef __vtkImageCopy_h
#define __vtkImageCopy_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkImageData;
class VTK_SLICER_BASE_EXPORT vtkImageCopy : public vtkImageToImageFilter
{
public:
  static vtkImageCopy *New();
  vtkTypeMacro(vtkImageCopy,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // If Clear is set to 1, the output image is all zeros.
  // If Clear is set to 0, the output image is a copy of the input.
  vtkSetMacro(Clear, int);
  vtkGetMacro(Clear, int);
  vtkBooleanMacro(Clear, int);

protected:
  vtkImageCopy();
  ~vtkImageCopy() {};
  vtkImageCopy(const vtkImageCopy&);
  void operator=(const vtkImageCopy&);

  int Clear;
  
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
               int extent[6], int id);
};

#endif

