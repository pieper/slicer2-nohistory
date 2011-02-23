/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageAutoCorrelation.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkImageAutoCorrelation.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"

vtkImageAutoCorrelation* vtkImageAutoCorrelation::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageAutoCorrelation");
  if(ret)
    {
    return (vtkImageAutoCorrelation*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageAutoCorrelation;
}

vtkImageAutoCorrelation::vtkImageAutoCorrelation()
{
}

vtkImageAutoCorrelation::~vtkImageAutoCorrelation()
{
}

void vtkImageAutoCorrelation::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os, indent);
}

void vtkImageAutoCorrelation::ExecuteInformation(vtkImageData *inData,
                         vtkImageData *outData)
{
  outData->SetNumberOfScalarComponents(6);
}

template <class T>
void vtkImageAutoCorrelationExecute(vtkImageAutoCorrelation *self,
                    vtkImageData *inData, T *inPtr,
                    vtkImageData *outData, T *outPtr,
                    int extent[6], int id)
{
  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;
  inData->GetContinuousIncrements(extent, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(extent, outIncX, outIncY, outIncZ);

  T x,y,z;
  for (int idxZ = extent[4]; idxZ <= extent[5]; ++idxZ)
    {
    for (int idxY = extent[2]; !self->AbortExecute && idxY <= extent[3]; ++idxY)
      {
      for (int idxX = extent[0]; idxX <= extent[1] ; ++idxX)
    {
    x=*inPtr++;
    y=*inPtr++;
    z=*inPtr++;
    
    *outPtr++=x*x;
    *outPtr++=x*y;
    *outPtr++=x*z;
    *outPtr++=y*y;
    *outPtr++=y*z;
    *outPtr++=z*z;
    }
      inPtr += inIncY;
      outPtr += outIncY;
      }
    inPtr += inIncZ;
    outPtr += outIncZ;
    }
}

void vtkImageAutoCorrelation::ThreadedExecute(vtkImageData *inData,
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

  if (inData->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input NumberOfScalarComponents, "
    << inData->GetNumberOfScalarComponents()
    << ", must be 3");
    return;
    }

  if (outData->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: output NumberOfScalarComponents, "
    << outData->GetNumberOfScalarComponents()
    << ", must be 6");
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
    vtkTemplateMacro7(vtkImageAutoCorrelationExecute,this,
              inData, (VTK_TT *)(inPtr), 
              outData, (VTK_TT *)(outPtr),
              extent,id);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}
