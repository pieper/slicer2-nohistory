/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageResize.h,v $
  Date:      $Date: 2006/02/27 19:21:51 $
  Version:   $Revision: 1.24 $

=========================================================================auto=*/
// .NAME vtkImageResize - resize (scale) the input image
// .SECTION Description
// Currently just used in vtkMrmlVolume for the histogram, which
// died with the advent of vtk3.1.  The histogram needs to be 
// fixed.
// Kilian: Just workes if the input image is of larger extent the the output image !
//         otherwise use vtkImageResample !!!

#ifndef __vtkImageResize_h
#define __vtkImageResize_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageResize : public vtkImageToImageFilter
{
public:
  static vtkImageResize *New();
  vtkTypeMacro(vtkImageResize,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // The whole extent of the output has to be set explicitely.
  void SetOutputWholeExtent(int extent[6]);
  void SetOutputWholeExtent(int minX, int maxX, int minY, int maxY, 
                int minZ, int maxZ);
  void GetOutputWholeExtent(int extent[6]);
  int *GetOutputWholeExtent() {return this->OutputWholeExtent;}

  // Description:
  // The whole extent of the input has to be set explicitely.
  void SetInputClipExtent(int extent[6]);
  void SetInputClipExtent(int minX, int maxX, int minY, int maxY, 
                int minZ, int maxZ);
  void GetInputClipExtent(int extent[6]);
  int *GetInputClipExtent() {return this->InputClipExtent;}

protected:
  vtkImageResize();
  ~vtkImageResize() {};

  int OutputWholeExtent[6];
  int InputClipExtent[6];

  int Initialized;
  
  void ComputeInputUpdateExtent(int inExt[6], int outExt[6]);
  void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);
  void ExecuteInformation(){this->Superclass::ExecuteInformation();};
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
    int outExt[6], int id);

private:
  vtkImageResize(const vtkImageResize&);
  void operator=(const vtkImageResize&);
};

#endif
