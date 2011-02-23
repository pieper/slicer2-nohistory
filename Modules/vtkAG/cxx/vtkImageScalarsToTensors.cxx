/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageScalarsToTensors.cxx,v $
  Date:      $Date: 2006/01/06 17:57:10 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkImageScalarsToTensors.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkDataArray.h"
#include "vtkPointData.h"

vtkImageScalarsToTensors* vtkImageScalarsToTensors::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageScalarsToTensors");
  if(ret)
    {
    return (vtkImageScalarsToTensors*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageScalarsToTensors;
}

void vtkImageScalarsToTensors::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os, indent);
}

void vtkImageScalarsToTensors::ExecuteData(vtkDataObject *out)
{
  vtkImageData *res = vtkImageData::SafeDownCast(out);
  if (!res)
    {
    vtkWarningMacro("Call to ExecuteData with non vtkImageData output");
    return;
    }
  res->SetExtent(res->GetUpdateExtent());
  int* dims=res->GetDimensions();
  
  vtkDataArray* da=vtkDataArray::CreateDataArray(res->GetScalarType());
  da->SetNumberOfComponents(9);
  da->SetNumberOfTuples(dims[0]*dims[1]*dims[2]);

  res->GetPointData()->SetTensors(da);
  da->Delete();

  this->MultiThread(this->GetInput(),res);
}

template <class T>
static void vtkImageScalarsToTensorsExecute(vtkImageScalarsToTensors *self,
                        vtkImageData *inData, T *inPtr,
                        vtkImageData *outData, T *outPtr,
                        int extent[6], int id)
{
  int inIncX, inIncY, inIncZ;
  int outIncY, outIncZ;
  inData->GetContinuousIncrements(extent, inIncX, inIncY, inIncZ);
  int* dims=outData->GetDimensions();

  outIncY=(dims[0]-(extent[1]-extent[0]+1))*9;
  outIncZ=(dims[1]-(extent[3]-extent[2]+1))*dims[0]*9;

  for (int idxZ = extent[4]; idxZ <= extent[5]; ++idxZ)
    {
    for (int idxY = extent[2]; idxY <= extent[3]; ++idxY)
      {
      for (int idxX = extent[0]; idxX <= extent[1] ; ++idxX)
    {
    outPtr[0]=*inPtr++;
    outPtr[1]=outPtr[3]=*inPtr++;
    outPtr[2]=outPtr[6]=*inPtr++;
    outPtr[4]=*inPtr++;
    outPtr[5]=outPtr[7]=*inPtr++;
    outPtr[8]=*inPtr++;

    outPtr+=9;
    }
      inPtr += inIncY;
      outPtr += outIncY;
      }
    inPtr += inIncZ;
    outPtr += outIncZ;
    }
}

void vtkImageScalarsToTensors::ThreadedExecute(vtkImageData *inData,
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

  void* inPtr = inData->GetScalarPointerForExtent(extent);

  vtkDataArray* da=outData->GetPointData()->GetTensors();
  int* dims=outData->GetDimensions();
  void* outPtr=da->GetVoidPointer(((extent[4]*dims[1] + extent[2])*dims[0] + extent[0])*9);

  switch (inData->GetScalarType())
    {
    vtkTemplateMacro7(vtkImageScalarsToTensorsExecute,this,
              inData, (VTK_TT *)(inPtr), 
              outData, (VTK_TT *)(outPtr),
              extent,id);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}
