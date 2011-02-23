/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageTransformIntensity.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkImageTransformIntensity.h"
#include "vtkObjectFactory.h"

// #include <vtkStructuredPointsWriter.h>
// static void Write(vtkImageData* image,const char* filename)
// {
//   vtkStructuredPointsWriter* writer = vtkStructuredPointsWriter::New();
//   writer->SetFileTypeToBinary();
//   writer->SetInput(image);
//   writer->SetFileName(filename);
//   writer->Write();
//   writer->Delete();
// }

vtkImageTransformIntensity* vtkImageTransformIntensity::New(){
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageTransformIntensity");
  if(ret)
    {
    return (vtkImageTransformIntensity*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageTransformIntensity;
}

vtkImageTransformIntensity::vtkImageTransformIntensity()
{
  this->IntensityTransform=0;
}

vtkImageTransformIntensity::~vtkImageTransformIntensity()
{
  if(this->IntensityTransform)
    {
    this->IntensityTransform->Delete();
    }
}

void vtkImageTransformIntensity::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os, indent);
  os << indent << "IntensityTransform: " << this->GetIntensityTransform() << "\n";
  if(this->GetIntensityTransform())
    {
    this->GetIntensityTransform()->PrintSelf(os,indent.GetNextIndent());
    }
}

template <class T>
void vtkImageTransformIntensityExecute(vtkImageTransformIntensity *self,
                       vtkImageData *inData, T *inPtr,
                       vtkImageData *outData, T *outPtr,
                       int outExt[6], int id)
{
  vtkIntensityTransform* f = self->GetIntensityTransform();
  if(f)
    {
    f->Update();
    }
  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;
  inData->GetContinuousIncrements(outExt, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  int n=inData->GetNumberOfScalarComponents();
  // float buf[n];  Modified by Liu
  vtkFloatingPointType* buf = NULL;
  if (n > 0) 
      buf = new vtkFloatingPointType[n];


  for (int idxZ = outExt[4]; idxZ <= outExt[5]; ++idxZ)
    {
    for (int idxY = outExt[2]; idxY <= outExt[3]; ++idxY)
      {
      for (int idxX = outExt[0]; idxX <= outExt[1] ; ++idxX)
    {
    if(f)
      {
      vtkFloatingPointType* buff=buf;
      T* end=inPtr+n;
      while(inPtr!=end)
        {
        *buff++=vtkFloatingPointType(*inPtr++);
        }
      f->FunctionValues(buf,buf);
      buff=buf;
      end=outPtr+n;
      while(outPtr!=end)
        {
        *outPtr++=T(*buff++);
        }
      }
    else
      {
      T* end=outPtr+n;
      while(outPtr!=end)
        {
        *outPtr++=T(*inPtr++);
        }
      }
    }
      inPtr += inIncY;
      outPtr += outIncY;
      }
    inPtr += inIncZ;
    outPtr += outIncZ;
    }

  // Modified by Liu
  if (buf != NULL)
      delete[] buf;

}

void vtkImageTransformIntensity::ThreadedExecute(vtkImageData *inData,
                         vtkImageData *outData,
                         int extent[6], int id)
{
  void *inPtr;
  void *outPtr;
   
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

  inPtr = inData->GetScalarPointerForExtent(extent);
  outPtr = outData->GetScalarPointerForExtent(extent);
  
  if (outData->GetScalarType() != inData->GetScalarType())
    {
    vtkErrorMacro(<< "Execute: output ScalarType, "
    << outData->GetScalarType()
    << ", must match input2 ScalarType "
    << inData->GetScalarType());
    return;
    }
  
  if (inData->GetNumberOfScalarComponents() !=
      outData->GetNumberOfScalarComponents())
    {
    vtkErrorMacro(<< "Execute: input1 NumberOfScalarComponents, "
    << inData->GetNumberOfScalarComponents()
    << ", must be equal to output NumberOfScalarComponents, "
    << outData->GetNumberOfScalarComponents());
    return;
    }

  if(this->IntensityTransform &&
     (this->IntensityTransform->GetNumberOfFunctions() >
      inData->GetNumberOfScalarComponents()))
    {
    vtkErrorMacro(<< "Execute: input1 NumberOfScalarComponents, "
    << inData->GetNumberOfScalarComponents()
    << ", must be >= to NumberOfFunctions, "
    << this->IntensityTransform->GetNumberOfFunctions());
    return;
    }

  switch (inData->GetScalarType())
    {
    vtkTemplateMacro7(vtkImageTransformIntensityExecute,
              this,inData, (VTK_TT *)(inPtr), 
              outData, (VTK_TT *)(outPtr),
              extent,id);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}

