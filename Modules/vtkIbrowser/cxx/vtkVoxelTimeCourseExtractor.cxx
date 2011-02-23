/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkVoxelTimeCourseExtractor.cxx,v $
  Date:      $Date: 2006/01/20 21:11:09 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkVoxelTimeCourseExtractor.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkCommand.h"

#include <stdio.h>

vtkStandardNewMacro(vtkVoxelTimeCourseExtractor);


vtkVoxelTimeCourseExtractor::vtkVoxelTimeCourseExtractor()
{
    this->outputMax = 0.0;
    this->outputMin = 10000000.0;
    this->outputRange = this->outputMin - this->outputMax;
    this->numInputs = 0;
}



vtkVoxelTimeCourseExtractor::~vtkVoxelTimeCourseExtractor()
{
}



vtkImageData *vtkVoxelTimeCourseExtractor::GetInput (int volNum)
{
    if (this->numInputs <= volNum)
        {
            return NULL;
        }
#if (VTK_MAJOR_VERSION >= 5)
    return (vtkImageData*)(this->GetInput(volNum));
#else
    return (vtkImageData*)(this->Inputs[volNum]);
#endif
}



vtkFloatArray *vtkVoxelTimeCourseExtractor::GetTimeCourse(int i, int j, int k)
{
    int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
    numberOfInputs = this->GetNumberOfInputConnections(0);
#else
    numberOfInputs = this->NumberOfInputs;
#endif
    if (numberOfInputs == 0 || this->GetInput(0) == NULL)
    {
        vtkErrorMacro( <<"No input image data; no timecourse can be extracted.");
        return NULL;
    }

    vtkFloatArray *timeCourse = vtkFloatArray::New();
    timeCourse->SetNumberOfTuples(numberOfInputs);
    timeCourse->SetNumberOfComponents(1);
    for (int ii = 0; ii < numberOfInputs; ii++)
    {
        short *val = (short *)this->GetInput(ii)->GetScalarPointer(i, j, k); 
        timeCourse->SetComponent(ii, 0, *val); 
    }

    return timeCourse;
}



vtkFloatArray *vtkVoxelTimeCourseExtractor::GetFloatTimeCourse(int i, int j, int k)
{
    int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
    numberOfInputs = this->GetNumberOfInputConnections(0);
#else
    numberOfInputs = this->NumberOfInputs;
#endif
    if (numberOfInputs == 0 || this->GetInput(0) == NULL)
    {
        vtkErrorMacro( <<"No input image data; no timecourse can be extracted.");
        return NULL;
    }

    vtkFloatArray *timeCourse = vtkFloatArray::New();
    timeCourse->SetNumberOfTuples(numberOfInputs);
    timeCourse->SetNumberOfComponents(1);
    for (int ii = 0; ii < numberOfInputs; ii++)
    {
        float *val = (float *)this->GetInput(ii)->GetScalarPointer(i, j, k); 
        timeCourse->SetComponent(ii, 0, *val); 
    }

    return timeCourse;
}




void vtkVoxelTimeCourseExtractor::AddInput(vtkImageData *input)
{
#if (VTK_MAJOR_VERSION >= 5)
    this->vtkImageAlgorithm::AddInput(input);
#else
    this->vtkProcessObject::AddInput(input);
#endif
    this->numInputs = this->numInputs + 1;
}




void vtkVoxelTimeCourseExtractor::SimpleExecute ( vtkImageData* input, vtkImageData* output)
{
    // this doesn't need to do anything.
    return;
}
