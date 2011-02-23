/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDeformTensors.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkDeformTensors.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkMath.h"

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

vtkDeformTensors* vtkDeformTensors::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDeformTensors");
  if(ret)
    {
    return (vtkDeformTensors*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkDeformTensors;
}

vtkDeformTensors::vtkDeformTensors()
{
  this->NumberOfRequiredInputs = 2;
  this->Mode=VTK_DEFORMTENSOR_RIGID;
}

vtkDeformTensors::~vtkDeformTensors()
{
}

//----------------------------------------------------------------------------
// The output extent is the intersection.
void vtkDeformTensors::ExecuteInformation(vtkImageData **inDatas, 
                       vtkImageData *outData)
{
  vtkDebugMacro("ExecuteInformation");
  vtkImageMultipleInputFilter::ExecuteInformation(inDatas,outData);
}

vtkImageData* vtkDeformTensors::GetTensors()
{
  if (this->NumberOfInputs < 1)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning input of "
        << this->Inputs[0]);
  return (vtkImageData *)(this->Inputs[0]);
}

vtkImageData* vtkDeformTensors::GetDisplacements()
{
  if (this->NumberOfInputs < 2)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning input of "
        << this->Inputs[1]);
  return (vtkImageData *)(this->Inputs[1]);
}

static void vtkDeformTensorsExecute(vtkDeformTensors *self,
                     vtkImageData *in1Data, float *in1Ptr,
                     vtkImageData *in2Data, float *in2Ptr,
                     vtkImageData *outData, float *outPtr,
                     int outExt[6])
{
//   Write(in1Data,"/tmp/1.vtk");
//   Write(in2Data,"/tmp/2.vtk");
//   exit(0);
  int in1IncX, in1IncY, in1IncZ;
  int in2IncX, in2IncY, in2IncZ;
  int outIncX, outIncY, outIncZ;

  // Get increments to march through data 
  in1Data->GetContinuousIncrements(outExt, in1IncX, in1IncY, in1IncZ);
  in2Data->GetContinuousIncrements(outExt, in2IncX, in2IncY, in2IncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  int* in2Incs = in2Data->GetIncrements(); 

  vtkFloatingPointType* spa=in2Data->GetSpacing();
  float F[3][3];
  float Ft[3][3];
  float A[3][3];
  float U[3][3];
  float s[3];
  float Vt[3][3];
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

        // Pixel operation
        // Get tensor
        A[0][0]        =*in1Ptr++;
        A[1][0]=A[0][1]=*in1Ptr++;
        A[2][0]=A[0][2]=*in1Ptr++;
        A[1][1]        =*in1Ptr++;
        A[2][1]=A[1][2]=*in1Ptr++;
        A[2][2]=A[2][2]=*in1Ptr++;
        
    // Get Jacobian
    for(int c = 0; c < 3; ++c)
      {
      F[c][0] = (float(in2Ptr[xa]) - float(in2Ptr[xp])) / (2*spa[0]);
      F[c][1] = (float(in2Ptr[ya]) - float(in2Ptr[yp])) / (2*spa[1]);
      F[c][2] = (float(in2Ptr[za]) - float(in2Ptr[zp])) / (2*spa[2]);
      F[c][c] += 1;
      ++in2Ptr;
      }

        if(self->GetMode()==VTK_DEFORMTENSOR_SCALE)
          {
          }
        else if(self->GetMode()==VTK_DEFORMTENSOR_NO_SCALE)
          {
          float det=pow(vtkMath::Determinant3x3(F),1./3);
          for(int i=0;i<3;++i)
            {
            A[0][i]/=det;
            A[1][i]/=det;
            A[2][i]/=det;
            }
          }
        else if(self->GetMode()==VTK_DEFORMTENSOR_RIGID)
          {
          vtkMath::SingularValueDecomposition3x3(A,U,s,Vt);
          vtkMath::Multiply3x3(U,Vt,A);
          }

        vtkMath::Transpose3x3(F,Ft);
    vtkMath::Multiply3x3(Ft,A,A);
    vtkMath::Multiply3x3(A,F,A);
        
    *outPtr++=A[0][0];
    *outPtr++=A[0][1];
    *outPtr++=A[0][2];
    *outPtr++=A[1][1];
    *outPtr++=A[1][2];
    *outPtr++=A[2][2];
    }
      outPtr += outIncY;
      in1Ptr += in1IncY;
      in2Ptr += in2IncY;
      }
    outPtr += outIncZ;
    in1Ptr += in1IncZ;
    in2Ptr += in2IncZ;
    }

  outData->Modified();
}

void vtkDeformTensors::ThreadedExecute(vtkImageData **inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  void *inPtr1;
  void *inPtr2;
  void *outPtr;

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
   
  if (outData == 0)
    {
    vtkErrorMacro(<< "Output must be specified.");
    return;
    }
   
  inPtr1 = inData[0]->GetScalarPointerForExtent(outExt);
  inPtr2 = inData[1]->GetScalarPointerForExtent(outExt);
  outPtr = outData->GetScalarPointerForExtent(outExt);
  
  if (inData[0]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input0 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 6");
    return;
    }

  if (inData[1]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input1 NumberOfScalarComponents, "
                  << inData[1]->GetNumberOfScalarComponents()
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

  // expect inputs of the same type.
  if (inData[0]->GetScalarType() != inData[1]->GetScalarType())
    {
    vtkErrorMacro(<< "Execute: input1 ScalarType, "
                  <<  inData[0]->GetScalarType()
                  << ", must match input2 ScalarType "
                  << inData[1]->GetScalarType());
    return;
    }

  // expect inputs of the same type.
  if (inData[0]->GetScalarType() != outData->GetScalarType())
    {
    vtkErrorMacro(<< "Execute: input1 ScalarType, "
                  <<  inData[0]->GetScalarType()
                  << ", must match output ScalarType "
                  << outData->GetScalarType());
    return;
    }

  // expect inputs of the same type.
  if (inData[0]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input1 ScalarType, "
                  <<  inData[0]->GetScalarType()
                  << ", must be VTK_FLOAT (10)");
    return;
    }
  
  vtkDeformTensorsExecute(this,inData[0], (float *)(inPtr1), 
                          inData[1], (float *)(inPtr2), 
                          outData, (float *)(outPtr),
                          outExt);
}

void vtkDeformTensors::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageMultipleInputFilter::PrintSelf(os,indent);
}
