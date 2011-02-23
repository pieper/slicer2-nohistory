/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkLabelMapWhitening.cxx,v $
  Date:      $Date: 2006/01/31 17:48:00 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/

#include "vtkLabelMapWhitening.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkCommand.h"


vtkStandardNewMacro(vtkLabelMapWhitening);


vtkLabelMapWhitening::vtkLabelMapWhitening()
{
}


vtkLabelMapWhitening::~vtkLabelMapWhitening()
{
}


void vtkLabelMapWhitening::SimpleExecute(vtkImageData *input, vtkImageData* output)
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

    // Sets up properties for output vtkImageData
    int imgDim[3];  
    input->GetDimensions(imgDim);
    output->SetScalarType(input->GetScalarType());
    output->SetOrigin(input->GetOrigin());
    output->SetSpacing(input->GetSpacing());
    output->SetNumberOfScalarComponents(1);
    output->SetDimensions(imgDim[0], imgDim[1], imgDim[2]);
    output->AllocateScalars();
 
    int indx = 0;
    vtkDataArray *scalarsOutput = output->GetPointData()->GetScalars();
    vtkDataArray *scalarsInput = input->GetPointData()->GetScalars();

    // Voxel iteration through the entire image volume
    for (int kk = 0; kk < imgDim[2]; kk++)
    {
        for (int jj = 0; jj < imgDim[1]; jj++)
        {
            for (int ii = 0; ii < imgDim[0]; ii++)
            {
                short l = (short) scalarsInput->GetComponent(indx, 0);
                short val = (l > 0 ? (500+l) : 0); 
                scalarsOutput->SetComponent(indx++, 0, val);
            }
        } 
    }
}

