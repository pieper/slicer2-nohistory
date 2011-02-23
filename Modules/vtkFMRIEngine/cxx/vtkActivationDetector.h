/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationDetector.h,v $
  Date:      $Date: 2006/01/06 17:57:35 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/


// .NAME vtkActivationDetector - Computes voxel activation   
// .SECTION Description
// vtkActivationDetector is used to compute voxel activation based on
// paradigm and detection method (GLM or MI).


#ifndef __vtkActivationDetector_h
#define __vtkActivationDetector_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkObject.h"

class VTK_FMRIENGINE_EXPORT vtkActivationDetector : public vtkObject
{
public:
    vtkTypeMacro(vtkActivationDetector, vtkObject);

    vtkActivationDetector();
    ~vtkActivationDetector();

    // Description:
    // Gets/Sets the activation detection method (GLM = 1; MI = 2).
    vtkGetMacro(DetectionMethod, int);
    vtkSetMacro(DetectionMethod, int);

protected:
    int DetectionMethod;  // 1 - GLM; 2 - MI
};


#endif
