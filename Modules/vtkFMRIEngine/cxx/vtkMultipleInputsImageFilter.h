/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMultipleInputsImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:37 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

#ifndef __vtkMultipleInputsImageFilter_h
#define __vtkMultipleInputsImageFilter_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkSimpleImageToImageFilter.h"

class  VTK_FMRIENGINE_EXPORT vtkMultipleInputsImageFilter : public vtkSimpleImageToImageFilter
{
public:
    vtkTypeMacro(vtkMultipleInputsImageFilter, vtkSimpleImageToImageFilter);

    // Description:
    // Adds an input to the input list. Expands the list memory if necessary.
    void AddInput(vtkImageData *input);

    // Description:
    // Get one input whose index is "indx" on the input list.
    vtkImageData *GetInput(int indx);
};


#endif
