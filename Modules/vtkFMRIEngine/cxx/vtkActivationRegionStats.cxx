/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationRegionStats.cxx,v $
  Date:      $Date: 2006/01/31 17:47:59 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/

#include "vtkActivationRegionStats.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkCommand.h"


vtkStandardNewMacro(vtkActivationRegionStats);


vtkActivationRegionStats::vtkActivationRegionStats()
{
    this->RegionVoxels = NULL; 
    this->SignalChanges = NULL;

    this->Label = 0;
    this->Count = 0;
}


vtkActivationRegionStats::~vtkActivationRegionStats()
{
    if (this->RegionVoxels != NULL)
    {
        this->RegionVoxels->Delete();
    }

    if (this->SignalChanges != NULL)
    {
        this->SignalChanges->Delete();
    }
}


void vtkActivationRegionStats::SimpleExecute(vtkImageData *inputs, vtkImageData* output)
{
    int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
    numberOfInputs = this->GetNumberOfInputConnections(0);
#else
    numberOfInputs = this->NumberOfInputs;
#endif
    if (numberOfInputs != 3)
    {
        vtkErrorMacro( << "This filter can only accept three input images.");
        return;
    }
    // this->NumberOfInputs == 3 
    else
    {
        int dim[3];  
        this->GetInput(0)->GetDimensions(dim);
        int size = dim[0]*dim[1]*dim[2];

        // Array holding the intensities of all voxels in
        // the defined ROI.
        float *t = new float[size];

        // Arrays holding the coordinates of all voxels in
        // the defined ROI.
        int *x = new int[size];
        int *y = new int[size];
        int *z = new int[size];

        int len = (this->GetInput(2)->GetNumberOfScalarComponents() - 2) / 2;
        double *signalChanges = new double [len];
        for (int d = 0; d < len; d++) {
            signalChanges[d] = 0.0; // initialization 
        }

        // Number of inputs == 3 means we are going to compute stats 
        // for t volume: 
        // the first volume - the label map volume 
        // the second volume - the t volume
        // the third volume - the beta volume
        int indx = 0;
        int index2 = 0;
        vtkDataArray *betas = this->GetInput(2)->GetPointData()->GetScalars();

        // Voxel iteration through the entire image volume
        for (int kk = 0; kk < dim[2]; kk++)
        {
            for (int jj = 0; jj < dim[1]; jj++)
            {
                for (int ii = 0; ii < dim[0]; ii++)
                {
                    short *l = (short *)this->GetInput(0)->GetScalarPointer(ii, jj, kk);
                    if (*l == this->Label)
                    {
                        x[indx] = ii;
                        y[indx] = jj;
                        z[indx] = kk;

                        float *tv = (float *)this->GetInput(1)->GetScalarPointer(ii, jj, kk);
                        t[indx++] = *tv;

                        // get % signal changes
                        int yy = len + 2;
                        for (int d = 0; d < len; d++) {
                            signalChanges[d] += betas->GetComponent(index2, yy++);
                        }
                    }
                     
                    index2++;
                }
            } 
        }

        this->Count = indx;

        // Array holding all voxels in the defined ROI.
        if (this->RegionVoxels != NULL)
        {
            this->RegionVoxels->Delete();
            this->RegionVoxels = NULL;
        }

        if (indx > 0) 
        {
            this->RegionVoxels = vtkFloatArray::New();
            this->RegionVoxels->SetNumberOfTuples(indx);
            this->RegionVoxels->SetNumberOfComponents(4);

            // create the output image
            output->SetWholeExtent(0, this->Count-1, 0, 0, 0, 0);
            output->SetExtent(0, this->Count-1, 0, 0, 0, 0);
            output->SetScalarType(VTK_FLOAT);
            output->SetOrigin(this->GetInput(0)->GetOrigin());
            output->SetSpacing(this->GetInput(0)->GetSpacing());
            output->SetNumberOfScalarComponents(1);
            output->AllocateScalars();

            float *ptr = (float *) output->GetScalarPointer();
            for (int i = 0; i < indx; i++) 
            {
                *ptr++ = t[i];

                // always use InsertTuple4, instead of SetTuple4
                // since the former handles memory allocation if needed.
                this->RegionVoxels->InsertTuple4(i, x[i], y[i], z[i], t[i]);
            }

            // get average % signal changes
            this->SignalChanges = vtkFloatArray::New();
            this->SignalChanges->SetNumberOfTuples(len);
            this->SignalChanges->SetNumberOfComponents(1);
            for (int d = 0; d < len; d++) {
                signalChanges[d] /= indx; 
                this->SignalChanges->SetComponent(d, 0, signalChanges[d]);
            }
        }

        delete [] t;
        delete [] x;
        delete [] y;
        delete [] z;
        delete [] signalChanges;
    }
} 


// If the output image of a filter has different properties from the input image
// we need to explicitly define the ExecuteInformation() method
void vtkActivationRegionStats::ExecuteInformation(vtkImageData *input, vtkImageData *output)
{
    int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
    numberOfInputs = this->GetNumberOfInputConnections(0);
#else
    numberOfInputs = this->NumberOfInputs;
#endif

    if (numberOfInputs == 3 && this->Count > 0)
    {
        int dim[3];  
        dim[0] = this->Count;
        dim[1] = 1;
        dim[2] = 1;
        output->SetDimensions(dim);
        output->SetWholeExtent(0, this->Count-1, 0, 0, 0, 0);
        output->SetExtent(0, this->Count-1, 0, 0, 0, 0);
        output->SetScalarType(VTK_FLOAT);
        output->SetOrigin(this->GetInput(0)->GetOrigin());
        output->SetSpacing(this->GetInput(0)->GetSpacing());
        output->SetNumberOfScalarComponents(1);
    }
}

