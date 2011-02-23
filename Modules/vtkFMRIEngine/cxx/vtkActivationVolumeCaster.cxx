/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationVolumeCaster.cxx,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/

#include "vtkObjectFactory.h"
#include "vtkActivationVolumeCaster.h"
#include "vtkSource.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkDataArray.h"


vtkStandardNewMacro(vtkActivationVolumeCaster);

vtkActivationVolumeCaster::vtkActivationVolumeCaster()
{
}

void vtkActivationVolumeCaster::SimpleExecute(vtkImageData *input, vtkImageData* output)
{
    if (this->GetInput() == NULL)
    {
        vtkErrorMacro( << "No input image data in this filter.");
        return;
    }

    // Sets up properties for output vtkImageData
    int imgDim[3];  
    input->GetDimensions(imgDim);
    output->SetScalarType(VTK_SHORT);
    output->SetOrigin(input->GetOrigin());
    output->SetSpacing(input->GetSpacing());
    output->SetNumberOfScalarComponents(1);
    output->SetDimensions(imgDim[0], imgDim[1], imgDim[2]);
    output->AllocateScalars();
 
    int indx = 0;
    vtkDataArray *scalarsOutput = output->GetPointData()->GetScalars();
    vtkDataArray *scalarsInput = input->GetPointData()->GetScalars();

    float low = fabs(this->LowerThreshold);
    float high = fabs(this->UpperThreshold);

    // Apply threshold if desired
    if (low <= high) 
    {
        // Voxel iteration through the entire image volume
        for (int kk = 0; kk < imgDim[2]; kk++)
        {
            for (int jj = 0; jj < imgDim[1]; jj++)
            {
                for (int ii = 0; ii < imgDim[0]; ii++)
                {
                    short val = 0;
                    float v = (float) scalarsInput->GetComponent(indx, 0);

                    // Zero out values according to the FMRI mapping:
                    //
                    // |-------|-------|------|------|--------|-------|
                    // Min    -h      -l      0      +l      +h       Max
                    // show values between -h and -l, and
                    //      values between +l and +h
                    // zero out values less than -h, and
                    //      values between -l and +l, and
                    //      values above +h
                    if ((v < low && v > (-low))  ||
                            (v > high)               ||
                            (v < (-high)))           
                    {
                        val = 0;
                    }
                    else
                    {
                        // 9 = t positive voxels; 3 = negative voxels
                        // A volume may appear differently in slicer if we 
                        // turn on/off the interpolation.
                        val = (v >= 0 ? 9 : 3);
                    }
                    scalarsOutput->SetComponent(indx++, 0, val);
                }
            }
        }
    }    
    // Zero out everything
    else
    {
        short *ptr = (short *) output->GetScalarPointer();
        memset(ptr, 0, imgDim[0]*imgDim[1]*imgDim[2]*sizeof(short));
    }

    double range[2];
    output->GetScalarRange(range);
    this->LowRange = (short)range[0];
    this->HighRange = (short)range[1];
}

