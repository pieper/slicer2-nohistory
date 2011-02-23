/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkJacobian.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkJacobian.h"
#include "vtkObjectFactory.h"
#include "vtkMath.h"
#include "vtkImageData.h"

vtkJacobian* vtkJacobian::New(){
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkJacobian");
  if(ret)
    {
    return (vtkJacobian*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkJacobian;
}

vtkJacobian::vtkJacobian()
{
}

vtkJacobian::~vtkJacobian()
{
}

void vtkJacobian::ExecuteInformation(vtkImageData *inData, vtkImageData *outData)
{
  outData->SetScalarType(VTK_FLOAT);
  outData->SetNumberOfScalarComponents(1);
}

void vtkJacobian::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os, indent);
}

template <class T>
static void vtkJacobianExecute(vtkJacobian *self,
                   vtkImageData *inData, T *inPtr,
                   vtkImageData *outData, float *outPtr,
                   int outExt[6], int id)
{
  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;
  vtkFloatingPointType* spa=outData->GetSpacing();

  // Get increments to march through data 
  inData->GetContinuousIncrements(outExt, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  int* inIncs = inData->GetIncrements(); 

  // Loop through ouput pixels
  for(int z = outExt[4]; z <= outExt[5]; ++z)
    {
    int zp = z == outExt[4] ? 0 : -inIncs[2];
    int za = z == outExt[5] ? 0 : inIncs[2];
    for(int y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
      {
      int yp = y == outExt[2] ? 0 : -inIncs[1];
      int ya = y == outExt[3] ? 0 : inIncs[1];
      for(int x = outExt[0]; x <= outExt[1] ; ++x)
    {
    float A[3][3];
    
    // Pixel operation
    // Get gradient
    int xp = x == outExt[0] ? 0 : -inIncs[0];
    int xa = x == outExt[1] ? 0 : inIncs[0];

    for(int c = 0; c < 3; ++c)
      {
      A[c][0] = (float(inPtr[xa]) - float(inPtr[xp])) / (2*spa[0]);
      A[c][1] = (float(inPtr[ya]) - float(inPtr[yp])) / (2*spa[1]);
      A[c][2] = (float(inPtr[za]) - float(inPtr[zp])) / (2*spa[2]);
      A[c][c] += 1;
      ++inPtr;
      }
    *outPtr=vtkMath::Determinant3x3(A);
    
    ++outPtr;
    }
      outPtr += outIncY;
      inPtr += inIncY;
      }
    outPtr += outIncZ;
    inPtr += inIncZ;
    }
}

void vtkJacobian::ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
                  int extent[6], int id)
{
  vtkDebugMacro(<< "ExecuteData: inData = " << inData 
  << ", outData = " << outData);

  if(inData->GetNumberOfScalarComponents()!=3)
    {
    vtkErrorMacro("inData should have 3 components.");
    return;
    }

//   if(outData->GetNumberOfScalarComponents()!=1)
//     {
//     vtkErrorMacro("outData should have 1 components.");
//     return;
//     }

//   if(outData->GetScalarType()!=VTK_FLOAT)
//     {
//     vtkErrorMacro(<< "Execute: input1 ScalarType, "
//     <<  inData->GetScalarType()
//     << ", must be " << VTK_FLOAT);
//     return;
//     }

  void *inPtr = inData->GetScalarPointerForExtent(extent);
  float *outPtr = (float*)outData->GetScalarPointerForExtent(extent);
  
  switch (inData->GetScalarType())
    {
    vtkTemplateMacro7(vtkJacobianExecute, this, inData, (VTK_TT *)(inPtr), 
                      outData, outPtr, extent, id);
    default:
      vtkErrorMacro(<< "Execute: Unknown input ScalarType");
      return;
    }
}

