/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationEstimator.h,v $
  Date:      $Date: 2006/01/06 17:57:35 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/

#ifndef __vtkActivationEstimator_h
#define __vtkActivationEstimator_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkActivationDetector.h"
#include "vtkMultipleInputsImageFilter.h"

class  VTK_FMRIENGINE_EXPORT vtkActivationEstimator : public vtkMultipleInputsImageFilter
{
public:
    vtkTypeMacro(vtkActivationEstimator, vtkMultipleInputsImageFilter);

    // Description:
    // Sets the activation detector.
    void SetDetector(vtkActivationDetector *detector);

protected:
    vtkActivationEstimator();
    ~vtkActivationEstimator();

    vtkActivationDetector *Detector;
};


#endif
