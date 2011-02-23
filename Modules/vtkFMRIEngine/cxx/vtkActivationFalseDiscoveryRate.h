/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationFalseDiscoveryRate.h,v $
  Date:      $Date: 2006/01/06 17:57:35 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

#ifndef __vtkActivationFalseDiscoveryRate_h
#define __vtkActivationFalseDiscoveryRate_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkSimpleImageToImageFilter.h"

class  VTK_FMRIENGINE_EXPORT vtkActivationFalseDiscoveryRate : public vtkSimpleImageToImageFilter
{
public:
    static vtkActivationFalseDiscoveryRate *New();
    vtkTypeMacro(vtkActivationFalseDiscoveryRate, vtkSimpleImageToImageFilter);

    // Description:
    // Gets/Sets the FDR threshold 
    vtkGetMacro(FDRThreshold, float);
    // vtkSetMacro(FDRThreshold, float);
    
    // Description:
    // Gets/Sets the dof 
    vtkGetMacro(DOF, int);
    vtkSetMacro(DOF, int);
    
    // Description:
    // Gets/Sets the option 
    vtkGetMacro(Option, int);
    vtkSetMacro(Option, int);

    // Description:
    // Gets/Sets the Q 
    vtkGetMacro(Q, float);
    vtkSetMacro(Q, float);

protected:
    vtkActivationFalseDiscoveryRate();
    ~vtkActivationFalseDiscoveryRate();

    void SimpleExecute(vtkImageData *input,vtkImageData *output);

private:
    // computed threshold (t statistic)
    float FDRThreshold;

    // degree of freedom
    int DOF; 

    // user specified Q value
    float Q; 

    // cind = 1 or cdep = 2
    // cind: assuming p values are independent across voxels
    // cdep: applying for an arbitrary distribution of p values
    int Option; 

};

#endif
