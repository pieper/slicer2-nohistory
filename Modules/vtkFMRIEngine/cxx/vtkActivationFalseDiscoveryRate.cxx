/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationFalseDiscoveryRate.cxx,v $
  Date:      $Date: 2006/01/31 17:47:59 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/

#include "vtkActivationFalseDiscoveryRate.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkFloatArray.h"
#include "vtkPointData.h"
#include "itkTDistribution.h"

#include <vtkstd/algorithm>

vtkStandardNewMacro(vtkActivationFalseDiscoveryRate);


vtkActivationFalseDiscoveryRate::vtkActivationFalseDiscoveryRate()
{
    this->FDRThreshold = 0; 
    this->DOF = 0;
    this->Option = 1;
}


vtkActivationFalseDiscoveryRate::~vtkActivationFalseDiscoveryRate()
{
}


void vtkActivationFalseDiscoveryRate::SimpleExecute(vtkImageData *input, vtkImageData* output)
{
    int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
    numberOfInputs = this->GetNumberOfInputConnections(0);
#else
    numberOfInputs = this->NumberOfInputs;
#endif
    if (numberOfInputs == 0)
    {
        vtkErrorMacro( << "This filter needs one input of image data.");
        return;
    }

    // we don't use output image
    output = NULL;

    // get the data array from input image (t map)
    vtkFloatArray *tArray = (vtkFloatArray *)input->GetPointData()->GetScalars();
    vtkFloatArray *tmp = vtkFloatArray::New();
    tmp->DeepCopy(tArray);

    // convert t -> p
    int size = tmp->GetNumberOfTuples();
    float *data = (float *)tmp->GetPointer(0);
    int count = 0;
    for (int i = 0; i < size; i++)
    {
        float t = data[i];
        if (t != 0)
        {
            float p = (float)itk::Statistics::TDistribution::CDF(t, this->DOF);
            // double sided tail probability for t-distribution
            p *= 2;

            data[count++] = p;
        }
    }

    // use vtkstd::sort sort p values from min to max
    float *ps = new float [count];
    memcpy(ps, data, count);
    vtkstd::sort(ps, ps + count);

    // compute c(N) according to option 
    float cn = 1.0;
    float l = 0.0;
    if (this->Option == 2)
    {
        for (int i = 0; i < count; i++)
        {
            l += 1.0 / (i+1); 
        }
        cn = l;
    }

    // get the max p(i), where
    // p(i) <= i * q / (N * c(N))
    float pc = 0.0;
    for (int i = 0; i < count; i++)
    {
        float v = (i+1) * this->Q / count / cn;
        if (ps[i] == v)
        {
            pc = ps[i];
            break;
        }
        else if (ps[i] > v)
        {
            pc = ps[i-1];
            break;
        }
    }

    // t threshold
    this->FDRThreshold = (float)(fabs(itk::Statistics::TDistribution::InverseCDF((pc / 2), this->DOF)));

    tmp->Delete();
    delete [] ps;
}

