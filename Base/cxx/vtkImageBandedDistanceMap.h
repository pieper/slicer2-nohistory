/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageBandedDistanceMap.h,v $
  Date:      $Date: 2006/01/06 17:56:38 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
// .NAME vtkImageBandedDistanceMap -  Does a quick partial distance map
// .SECTION Description
// Will compute distances from an input region, up to the user-specified
// MaximumDistanceToCompute.  The output is a distance map in 
// a band around the input region of interest, and pixels
// are set to the max distance outside of this band.  The point of this
// filter is to quickly compute a good enough distance map for applications
// that don't care about "really distant" pixels.
//

#ifndef __vtkImageBandedDistanceMap_h
#define __vtkImageBandedDistanceMap_h

#include "vtkImageNeighborhoodFilter.h"

class VTK_SLICER_BASE_EXPORT vtkImageBandedDistanceMap : public vtkImageNeighborhoodFilter
{
public:
  static vtkImageBandedDistanceMap *New();
  vtkTypeMacro(vtkImageBandedDistanceMap,vtkImageNeighborhoodFilter);
    
  // Description: 
  // Background and foreground pixel values in the image.
  // Usually 0 and some label value, respectively.
  vtkSetMacro(Background, float);
  vtkGetMacro(Background, float);
  vtkSetMacro(Foreground, float);
  vtkGetMacro(Foreground, float);

  // Description: 
  // Defines size of neighborhood around contour where 
  // distances will be computed.
  vtkGetMacro(MaximumDistanceToCompute, int);
  void SetMaximumDistanceToCompute(int distance);

  // Description: 
  // Set to 3 for a 3-D kernel.  Else will use a 2D kernel
  // to save time.
  vtkSetMacro(Dimensionality, int);
  vtkGetMacro(Dimensionality, int);

protected:
  vtkImageBandedDistanceMap();
  ~vtkImageBandedDistanceMap();

  float Background;
  float Foreground;

  int MaximumDistanceToCompute;
  int Dimensionality;

  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
    int extent[6], int id);
};

#endif

