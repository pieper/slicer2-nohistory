/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationRegionStats.h,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

#ifndef __vtkActivationRegionStats_h
#define __vtkActivationRegionStats_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkShortArray.h"
#include "vtkFloatArray.h"
#include "vtkDataObject.h"
#include "vtkMultipleInputsImageFilter.h"

class  VTK_FMRIENGINE_EXPORT vtkActivationRegionStats : public vtkMultipleInputsImageFilter
{
public:
    static vtkActivationRegionStats *New();
    vtkTypeMacro(vtkActivationRegionStats, vtkMultipleInputsImageFilter);

    // Description:
    // Returns the indices and intensities of all voxels in the defined ROI, 
    // in the labelmap volumes
    vtkFloatArray *GetRegionVoxels() {return this->RegionVoxels;};

    // Description:
    // Returns the average percent signal changes in the defined ROI 
    vtkFloatArray *GetPercentSignalChanges() {return this->SignalChanges;};

    // Description:
    // Sets/gets label
    vtkSetMacro(Label, int);
    vtkGetMacro(Label, int);

    // Description:
    // Sets/gets voxel count 
    vtkSetMacro(Count, int);
    vtkGetMacro(Count, int);

protected:
    vtkActivationRegionStats();
    ~vtkActivationRegionStats();

    void SimpleExecute(vtkImageData *input, vtkImageData *output);
    void ExecuteInformation(vtkImageData *input, vtkImageData *output);

    // the indices (i, j, k) and their intensities of all voxels in the defined ROI, 
    // in the labelmap volume.
    vtkFloatArray *RegionVoxels;  

    int Label;
    int Count;

    vtkFloatArray *SignalChanges;
};

#endif
