/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGLMEstimator.h,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

#ifndef __vtkGLMEstimator_h
#define __vtkGLMEstimator_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkActivationEstimator.h"
#include "vtkFloatArray.h"
#include "vtkShortArray.h"
#include "vtkDataObject.h"

class  VTK_FMRIENGINE_EXPORT vtkGLMEstimator : public vtkActivationEstimator
{
    public:
    static vtkGLMEstimator *New();
    vtkTypeMacro(vtkGLMEstimator, vtkActivationEstimator);

    vtkGetMacro(PreWhitening, int);
    vtkSetMacro(PreWhitening, int);
    
    // Description:
    // Returns the time course of a specified voxel (i, j, k).
    vtkFloatArray *GetTimeCourse(int i, int j, int k);
    
    // Description:
    // Returns the time course of the defined ROI. 
    vtkFloatArray *GetRegionTimeCourse();
    
    // Description:
    // Sets the lower threshold.
    void SetLowerThreshold(float low) {this->LowerThreshold = low;}

    // Description:
    // Sets the cutoff frequency.
    void SetCutoff(float c) {this->Cutoff = c;}

    // Description:
    // Sets the indices of all voxels in the defined ROI.
    void SetRegionVoxels(vtkFloatArray *voxels) {this->RegionVoxels = voxels;}

    // Description:
    // Enables or disables high-pass filtering. 
    void EnableHighPassFiltering(int yes) {
        this->HighPassFiltering = yes;}

    // Description:
    // Gets HighPassFiltering.
    vtkGetMacro(HighPassFiltering, int);

    // Description:
    // Sets/Gets global effect.
    vtkSetMacro(GlobalEffect, int);
    vtkGetMacro(GlobalEffect, int);

    protected:
    vtkGLMEstimator();
    ~vtkGLMEstimator();

    void SimpleExecute(vtkImageData* input,vtkImageData* output);
    void PerformHighPassFiltering();
    // computes global mean for each volume and 
    // the grand mean for the entire sequence.
    void ComputeMeans();

    int PreWhitening;
    int HighPassFiltering;
    float LowerThreshold;
    float Cutoff;
    // one mean from each volume
    float *GlobalMeans;
    // mean of all volumes
    float GrandMean;
    // mean scaling:
    // 1 - grand mean 
    // 2 - global mean
    // 3 - both
    int GlobalEffect;

    vtkFloatArray *TimeCourse;
    vtkFloatArray *RegionTimeCourse;
    vtkFloatArray *RegionVoxels;
};


#endif
