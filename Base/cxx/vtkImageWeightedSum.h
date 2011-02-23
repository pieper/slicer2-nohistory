/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWeightedSum.h,v $
  Date:      $Date: 2006/04/25 16:49:20 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/
// .NAME vtkImageWeightedSum -  adds any number of images, weighting
// each according to the weight set using this->SetWeightForInput(i,w).
//
// .SECTION Description
// All weights are normalized so they will sum to 1.
// Images must have the same extents. Output is always type float.
//
//
#ifndef __vtkImageWeightedSum_h
#define __vtkImageWeightedSum_h

#include "vtkImageData.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkFloatArray.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageWeightedSum : public vtkImageMultipleInputFilter
{
public:
  static vtkImageWeightedSum *New();
  vtkTypeMacro(vtkImageWeightedSum,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // The weights control the contribution of each input to the sum.
  // They will be normalized to sum to 1 before filter execution.
  float GetWeightForInput(int i);
  float GetNormalizedWeightForInput(int i);
  void SetWeightForInput(int i, float w);

  // Description:
  // This function is called by vtkImageWeightedSumExecute.
  // It makes sure a weight exists for each input image
  // and normalizes the weights.
  void CheckWeights();

protected:

  vtkImageWeightedSum();
  ~vtkImageWeightedSum();

  vtkFloatArray * Weights;

  void NormalizeWeights();

  void ExecuteInformation(vtkImageData **inputs, vtkImageData *output);
  void ExecuteInformation(){this->vtkImageMultipleInputFilter::ExecuteInformation();};
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
               int extent[6], int id);
};

#endif

