/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageZoom2D.h,v $
  Date:      $Date: 2006/02/27 19:21:51 $
  Version:   $Revision: 1.20 $

=========================================================================auto=*/
// .NAME vtkImageZoom2D -  zooms (magnifies) a 2D image
// .SECTION Description
// vtkImageZoom2D 
//

#ifndef __vtkImageZoom2D_h
#define __vtkImageZoom2D_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageZoom2D : public vtkImageToImageFilter
{
public:
  static vtkImageZoom2D *New();
  vtkTypeMacro(vtkImageZoom2D,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Get/Set the Magnification
  vtkSetMacro(Magnification, vtkFloatingPointType);
  vtkGetMacro(Magnification, vtkFloatingPointType);

  // Description:
  // If AutoCenter is turned on,
  // Zoom in on the Center of the input image
  vtkGetMacro(AutoCenter, int);
  vtkSetMacro(AutoCenter, int);
  vtkBooleanMacro(AutoCenter, int);

  // Description:
  // Set the Zoom Point to be some point
  // Once you do that, OrigPoint should be the original point in the image.
  // It looks to me like this function does the calculation wrong.
  void SetZoomPoint(int x, int y);
  vtkGetVector2Macro(ZoomPoint, int);
  vtkGetVector2Macro(OrigPoint, int);

  // Description:
  // Set Center of the region on which we zoom in.
  vtkSetVector2Macro(Center, vtkFloatingPointType);
  vtkGetVector2Macro(Center, vtkFloatingPointType);

  // Description:
  // Set to be 1/magnification in each direction.
  // NEVER USE THIS.
  vtkSetVector2Macro(Step, vtkFloatingPointType);
  vtkGetVector2Macro(Step, vtkFloatingPointType);

  // Description:
  // Set/Get Upper Left hand corner of zoom window.
  // NEVER USE THIS.
  vtkSetVector2Macro(Origin, vtkFloatingPointType);
  vtkGetVector2Macro(Origin, vtkFloatingPointType);

protected:
  vtkImageZoom2D();
  ~vtkImageZoom2D(){};

  // Length of 1 Pixel in Zoom Window in the Original Image
  vtkFloatingPointType Step[2];
  // Upper Left hand corner of Zoom Window
  vtkFloatingPointType Origin[2];

  vtkFloatingPointType Magnification;
  int AutoCenter;
  vtkFloatingPointType Center[2];
  int OrigPoint[2];
  int ZoomPoint[2];

  void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
    int extent[6], int id);

private:
  vtkImageZoom2D(const vtkImageZoom2D&);
  void operator=(const vtkImageZoom2D&);
};

#endif



