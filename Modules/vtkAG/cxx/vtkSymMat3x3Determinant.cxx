/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSymMat3x3Determinant.cxx,v $
  Date:      $Date: 2006/01/06 17:57:12 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkSymMat3x3Determinant.h"
#include "vtkObjectFactory.h"
#include "vtkMath.h"
#include "vtkImageData.h"

vtkSymMat3x3Determinant* vtkSymMat3x3Determinant::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkSymMat3x3Determinant");
  if(ret)
    {
    return (vtkSymMat3x3Determinant*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkSymMat3x3Determinant;
}

vtkSymMat3x3Determinant::vtkSymMat3x3Determinant()
{
}

vtkSymMat3x3Determinant::~vtkSymMat3x3Determinant()
{
}

void vtkSymMat3x3Determinant::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os, indent);
}

void vtkSymMat3x3Determinant::ExecuteInformation(vtkImageData *inData,
                         vtkImageData *outData)
{
  outData->SetNumberOfScalarComponents(1);
}

template <class T>
void vtkSymMat3x3DeterminantExecute(vtkSymMat3x3Determinant *self,
                 vtkImageData *inData, T *inPtr,
                 vtkImageData *outData, T *outPtr,
                 int extent[6], int id)
{
  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;
  inData->GetContinuousIncrements(extent, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(extent, outIncX, outIncY, outIncZ);

  T v1,v2,v3,v4,v5,v6;
  for (int idxZ = extent[4]; idxZ <= extent[5]; ++idxZ)
    {
    for (int idxY = extent[2]; !self->AbortExecute && idxY <= extent[3]; ++idxY)
      {
      for (int idxX = extent[0]; idxX <= extent[1] ; ++idxX)
    {
    v1=*inPtr++;
    v2=*inPtr++;
    v3=*inPtr++;
    v4=*inPtr++;
    v5=*inPtr++;
    v6=*inPtr++;
    
    *outPtr++=T(vtkMath::Determinant3x3(v1,v2,v3,
                        v2,v4,v5,
                        v3,v5,v6));
    }
      inPtr += inIncY;
      outPtr += outIncY;
      }
    inPtr += inIncZ;
    outPtr += outIncZ;
    }
}

void vtkSymMat3x3Determinant::ThreadedExecute(vtkImageData *inData,
                                           vtkImageData *outData,
                                           int extent[6], int id)
{
  vtkDebugMacro(<< "ThreadedExecute: inData = " << inData 
  << ", outData = " << outData);
  
  if (inData == 0)
    {
    vtkErrorMacro(<< "Input must be specified.");
    return;
    }
   
  if (outData == 0)
    {
    vtkErrorMacro(<< "Output must be specified.");
    return;
    }

  if (inData->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input NumberOfScalarComponents, "
    << inData->GetNumberOfScalarComponents()
    << ", must be 6");
    return;
    }

  if (outData->GetNumberOfScalarComponents() != 1)
    {
    vtkErrorMacro(<< "Execute: output NumberOfScalarComponents, "
    << outData->GetNumberOfScalarComponents()
    << ", must be 1");
    return;
    }

  if (inData->GetScalarType() != outData->GetScalarType())
    {
    vtkErrorMacro(<< "Execute: input ScalarType, "
    << inData->GetScalarType()
    << ", must be the same as output ScalarType, "
    << outData->GetScalarType());
    return;
    }

  void* inPtr = inData->GetScalarPointerForExtent(extent);
  void* outPtr = outData->GetScalarPointerForExtent(extent);

  switch (inData->GetScalarType())
    {
    vtkTemplateMacro7(vtkSymMat3x3DeterminantExecute,this,
              inData, (VTK_TT *)(inPtr), 
              outData, (VTK_TT *)(outPtr),
              extent,id);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}
