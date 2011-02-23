/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMultipleInputsImageFilter.cxx,v $
  Date:      $Date: 2006/01/31 17:48:00 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/

#include "vtkMultipleInputsImageFilter.h"
#include "vtkSource.h"
#include "vtkImageData.h"
#include "vtkPointData.h"


void vtkMultipleInputsImageFilter::AddInput(vtkImageData *image)
{
#if (VTK_MAJOR_VERSION >= 5)
    this->vtkImageAlgorithm::AddInput(image);
#else
    this->vtkProcessObject::AddInput(image);
#endif
}


vtkImageData *vtkMultipleInputsImageFilter::GetInput(int index)
{
    int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
    numberOfInputs = this->GetNumberOfInputConnections(0);
#else
    numberOfInputs = this->NumberOfInputs;
#endif
    if (numberOfInputs <= index)
    {
        return NULL;
    }

#if (VTK_MAJOR_VERSION >= 5)
    return (vtkImageData*)(this->Superclass::GetInput(index));
#else
    return (vtkImageData*)(this->Inputs[index]);
#endif
}

