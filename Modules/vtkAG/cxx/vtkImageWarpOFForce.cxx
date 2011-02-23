/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWarpOFForce.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkImageWarpOFForce.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"

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

vtkImageWarpOFForce* vtkImageWarpOFForce::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageWarpOFForce");
  if(ret)
    {
    return (vtkImageWarpOFForce*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageWarpOFForce;
}

vtkImageWarpOFForce::vtkImageWarpOFForce()
{
  this->NumberOfRequiredInputs = 3;
}

vtkImageWarpOFForce::~vtkImageWarpOFForce()
{
}

template <class T1,class T2>
static void vtkImageWarpOFForceExecute2(vtkImageWarpOFForce *self,
                    vtkImageData *in1Data, T1 *in1Ptr,
                    vtkImageData *in2Data, T2 *in2Ptr,
                    vtkImageData** inData,
                    vtkImageData *outData, float *outPtr,
                    int outExt[6])
{
  //   Write(in1Data,"/tmp/1.vtk");
  //   Write(in2Data,"/tmp/2.vtk");
  //   exit(0);
  float *in3Ptr;
  unsigned char* in4Ptr=0;
  vtkImageData* in3Data=inData[2];
  vtkImageData* in4Data=0;

  in3Ptr = (float*) inData[2]->GetScalarPointerForExtent(outExt);
  if(self->GetNumberOfInputs()==4 && inData[3]!=0)
    {
    in4Ptr = (unsigned char*) inData[3]->GetScalarPointerForExtent(outExt);
    }

  int in1IncX, in1IncY, in1IncZ;
  int in2IncX, in2IncY, in2IncZ;
  int in3IncX, in3IncY, in3IncZ;
  int in4IncX, in4IncY, in4IncZ;
  int outIncX, outIncY, outIncZ;
  vtkFloatingPointType* spa=outData->GetSpacing();

  // Get increments to march through data 
  in1Data->GetContinuousIncrements(outExt, in1IncX, in1IncY, in1IncZ);
  in2Data->GetContinuousIncrements(outExt, in2IncX, in2IncY, in2IncZ);
  in3Data->GetContinuousIncrements(outExt, in3IncX, in3IncY, in3IncZ);
  if(in4Data)
    {
    in4Data->GetContinuousIncrements(outExt, in4IncX, in4IncY, in4IncZ);
    }
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  int* in2Incs = in2Data->GetIncrements(); 

  int comp=in1Data->GetNumberOfScalarComponents();
  // Loop through ouput pixels
  for(int z = outExt[4]; z <= outExt[5]; ++z)
    {
    int zp = z == outExt[4] ? 0 : -in2Incs[2];
    int za = z == outExt[5] ? 0 : in2Incs[2];
    for(int y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
      {
      int yp = y == outExt[2] ? 0 : -in2Incs[1];
      int ya = y == outExt[3] ? 0 : in2Incs[1];
      for(int x = outExt[0]; x <= outExt[1] ; ++x)
    {
        int xp = x == outExt[0] ? 0 : -in2Incs[0];
        int xa = x == outExt[1] ? 0 : in2Incs[0];

        *outPtr = 0;
    *(outPtr+1) = 0;
    *(outPtr+2) = 0;

    for(int c=0;c<comp;++c)
      {
      // Pixel operation
      // Get gradient
      float dx = (float(in2Ptr[xa]) - float(in2Ptr[xp])) / (2*spa[0]);
      float dy = (float(in2Ptr[ya]) - float(in2Ptr[yp])) / (2*spa[1]);
      float dz = (float(in2Ptr[za]) - float(in2Ptr[zp])) / (2*spa[2]);
      
      // |Grad(S)|^2
      float norm2=dx*dx+dy*dy+dz*dz;
      
      if(norm2>0)
        {
            // It
            float It = float(*in2Ptr) - float(*in1Ptr);

            // Grad(S(x)).h(x)
            float sp = dx*in3Ptr[0] + dy*in3Ptr[1] + dz*in3Ptr[2];

            // (T-S)^2
            float alpha2 = It*It;
          
            // |Grad(S)|^2 + (T-S)^2
            float denum = norm2 + alpha2;
            
            // [Grad(S(x)).h(x) + It] / (|Grad(S)|^2 + (T-S)^2)
            float scale = (sp+It) / denum;
            
            // OFForce = Grad(S(x)) * [Grad(S(x)).h(x) + It] /
            //                       (|Grad(S)|^2 + (T-S)^2)
            outPtr[0] -= dx * scale;
            outPtr[1] -= dy * scale;
            outPtr[2] -= dz * scale;
            }
      ++in1Ptr;
      ++in2Ptr;
          in3Ptr+=3;
      }

    float scale=1./comp;
    if(in4Ptr)
      {
      scale *= *in4Ptr/255.0;
      }
    
    *outPtr++*=scale;
    *outPtr++*=scale;
    *outPtr++*=scale;

    if(in4Ptr)
      {
      ++in4Ptr;
      }
    }
      outPtr += outIncY;
      in1Ptr += in1IncY;
      in2Ptr += in2IncY;
      in3Ptr += in3IncY;
      if(in4Ptr)
    {
    in4Ptr += in4IncY;
    }
      }
    outPtr += outIncZ;
    in1Ptr += in1IncZ;
    in2Ptr += in2IncZ;
    in3Ptr += in3IncZ;
    if(in4Ptr)
      {
      in4Ptr += in4IncZ;
      }
    }

  outData->Modified();
}

template <class T>
static void vtkImageWarpOFForceExecute1(vtkImageWarpOFForce *self,
                                      vtkImageData *in1Data, T *in1Ptr,
                                      vtkImageData *in2Data, void *in2Ptr,
                                      vtkImageData** inData,
                                      vtkImageData *outData, float *outPtr,
                                      int outExt[6])
{
  switch (in2Data->GetScalarType())
    {
    vtkTemplateMacro9(vtkImageWarpOFForceExecute2,
              self,in1Data, in1Ptr, 
              in2Data, (VTK_TT *)(in2Ptr),
              inData,
              outData,outPtr,
              outExt);
    default:
      vtkGenericWarningMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}

void vtkImageWarpOFForce::ThreadedExecute(vtkImageData **inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  void *inPtr1;
  void *inPtr2;
  float *inPtr3;
  unsigned char* inPtr4=0;
  void *outPtr;
  vtkImageData* inData4=0;

  vtkDebugMacro(<< "ThreadedExecute: inData = " << inData 
  << ", outData = " << outData);
  

  if (inData[0] == 0)
    {
    vtkErrorMacro(<< "Input " << 0 << " must be specified.");
    return;
    }
   
  if (inData[1] == 0)
    {
    vtkErrorMacro(<< "Input " << 1 << " must be specified.");
    return;
    }
   
  if (inData[2] == 0)
    {
    vtkErrorMacro(<< "Input " << 2 << " must be specified.");
    return;
    }
   
  if (outData == 0)
    {
    vtkErrorMacro(<< "Output must be specified.");
    return;
    }
   
  inPtr1 = inData[0]->GetScalarPointerForExtent(outExt);
  inPtr2 = inData[1]->GetScalarPointerForExtent(outExt);
  inPtr3 = (float*) inData[2]->GetScalarPointerForExtent(outExt);
  outPtr = outData->GetScalarPointerForExtent(outExt);
  if(this->NumberOfInputs==4 && inData[3]!=0)
    {
    inData4=inData[3];
    inPtr4 = (unsigned char*) inData4->GetScalarPointerForExtent(outExt);
    }

  if (inData[0]->GetNumberOfScalarComponents() !=
      inData[1]->GetNumberOfScalarComponents())
    {
    vtkErrorMacro(<< "Execute: input1 NumberOfScalarComponents, "
    << inData[0]->GetNumberOfScalarComponents()
    << ", must be equal to input2 NumberOfScalarComponents, "
    << inData[1]->GetNumberOfScalarComponents());
    return;
    }

  // expect output of type float.
  if (inData[2]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input3 ScalarType, "
          << inData[2]->GetScalarType()
          << ", must be "
          << VTK_FLOAT);
    return;
    }
  
  if (inData[2]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input3 NumberOfScalarComponents, "
          << inData[0]->GetNumberOfScalarComponents()
          << ", must be equal to 3");
    return;
    }

  // expect mask of type unsigned char.
  if (inData4 && (inData4->GetScalarType() != VTK_UNSIGNED_CHAR))
    {
    vtkErrorMacro(<< "Execute: mask ScalarType, "
          << inData4->GetScalarType()
          << ", must be "
          << VTK_UNSIGNED_CHAR);
    return;
    }
  
  // expect output of type float.
  if (outData->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: output ScalarType, "
          << outData->GetScalarType()
          << ", must be "
          << VTK_FLOAT);
    return;
    }
  
  // expect output 3d output vectors.
  if (outData->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: output NumberOfScalarComponents, "
          << outData->GetNumberOfScalarComponents()
          << ", must be 3");
    return;
    }
    
  switch (inData[0]->GetScalarType())
    {
    vtkTemplateMacro9(vtkImageWarpOFForceExecute1,
              this,inData[0], (VTK_TT *)(inPtr1), 
              inData[1],inPtr2, 
              inData,
              outData, static_cast<float*>(outPtr), outExt);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }

  vtkDebugMacro(<< "ThreadedExecute end");
}

void vtkImageWarpOFForce::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageWarpForce::PrintSelf(os,indent);
}
