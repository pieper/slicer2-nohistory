/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageSmooth.h,v $
  Date:      $Date: 2006/01/06 17:57:54 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtkImageSmooth_h
#define __vtkImageSmooth_h 



#include <vtkImageToImageFilter.h>
#include "vtkImageSmoothConfigure.h"

class VTK_IMAGESMOOTH_EXPORT vtkImageSmooth : public vtkImageToImageFilter
{
 public:
  // -----------------------------------------------------
  // Genral Functions for the filter
  // -----------------------------------------------------
  static vtkImageSmooth *New();

  vtkTypeMacro(vtkImageSmooth,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Get/Set the number of iterations of smoothing that is to be done
  vtkSetMacro(NumberOfIterations,int);
  vtkGetMacro(NumberOfIterations,int);
  vtkSetMacro(Dimensions,int);
  vtkGetMacro(Dimensions,int);
  
 
  void ComputeInputUpdateExtent(int inExt[6], 
                int outExt[6]);

  
  void ExecuteInformation(vtkImageData *inData, 
                                     vtkImageData *outData);
  void ExecuteInformation() {this->vtkImageToImageFilter::ExecuteInformation();};

  float Init();
 
  //Data
  int NumberOfIterations;
  float dt;
  int Dimensions;

  protected:
  vtkImageSmooth();
  ~vtkImageSmooth();
  /*
  float Smooth2D(vtkImageData *inData, vtkImageData *outData,int inExt[6],
                int outExt[6]);
  float Smooth3D(vtkImageData *inData, vtkImageData *outData,int inExt[6],
                int outExt[6]);
*/

  void ThreadedExecute(vtkImageData *inData, 
                                  vtkImageData *outData,
                                  int outExt[6], int threadid);


  
  
};

#endif
