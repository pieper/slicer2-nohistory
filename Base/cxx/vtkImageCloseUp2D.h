/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageCloseUp2D.h,v $
  Date:      $Date: 2006/02/27 19:21:49 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkImageCloseUp2D -  Creates a magnified 2D image
// .SECTION Description
// vtkImageCloseUp2D shows a magnified square portion of a 2D image.

#ifndef __vtkImageCloseUp2D_h
#define __vtkImageCloseUp2D_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkImageData;
class VTK_SLICER_BASE_EXPORT vtkImageCloseUp2D : public vtkImageToImageFilter
{
public:
  static vtkImageCloseUp2D *New();
  vtkTypeMacro(vtkImageCloseUp2D,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Set the Center of the window (X,Y) that we zoom in on.
  // Set the Magnification
  // Set the half-width of the region to zoom in on (radius)
  // The half-length is set to the same value.
  vtkSetMacro(X, int);
  vtkSetMacro(Y, int);
  vtkSetMacro(Radius, int);
  vtkSetMacro(Magnification, int);

  int Magnification;
  int Radius;
  int X;
  int Y;

protected:
  vtkImageCloseUp2D();
  ~vtkImageCloseUp2D() {};

  void ExecuteInformation(vtkImageData *inData, 
                          vtkImageData *outData);
  void ExecuteInformation(){this->Superclass::ExecuteInformation();};

  // Override this function since inExt != outExt
  void ComputeInputUpdateExtent(int inExt[6], int outExt[6]);
  
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
                       int extent[6], int id);
private:
  vtkImageCloseUp2D(const vtkImageCloseUp2D&);
  void operator=(const vtkImageCloseUp2D&);
};

#endif



