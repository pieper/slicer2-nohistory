/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDisplacementPValue.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkDisplacementPValue.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkMath.h"

#include <gsl/gsl_sf.h>

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

vtkDisplacementPValue* vtkDisplacementPValue::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDisplacementPValue");
  if(ret)
    {
    return (vtkDisplacementPValue*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkDisplacementPValue;
}

vtkDisplacementPValue::vtkDisplacementPValue()
{
  this->NumberOfRequiredInputs = 3;
  this->NumberOfSamples=0;
}

vtkDisplacementPValue::~vtkDisplacementPValue()
{
}

void vtkDisplacementPValue::ExecuteInformation(vtkImageData **inDatas, 
                                               vtkImageData *outData)
{
  vtkDebugMacro("ExecuteInformation");
  vtkImageMultipleInputFilter::ExecuteInformation(inDatas,outData);
  
  outData->SetNumberOfScalarComponents(1);
}

vtkImageData* vtkDisplacementPValue::GetMean()
{
  if (this->NumberOfInputs < 1)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Target of "
        << this->Inputs[0]);
  return (vtkImageData *)(this->Inputs[0]);
}

vtkImageData* vtkDisplacementPValue::GetSigma()
{
  if (this->NumberOfInputs < 2)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[1]);
  return (vtkImageData *)(this->Inputs[1]);
}

vtkImageData* vtkDisplacementPValue::GetDisplacement()
{
  if (this->NumberOfInputs < 3)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Mask of "
        << this->Inputs[2]);
  return (vtkImageData *)(this->Inputs[2]);
}

static void vtkDisplacementPValueExecute(vtkDisplacementPValue *self,
                                         vtkImageData *in1Data, float *in1Ptr,
                                         vtkImageData *in2Data, float *in2Ptr,
                                         vtkImageData *in3Data, float *in3Ptr,
                                         vtkImageData *outData, float *outPtr,
                                         int outExt[6])
{
  int in1IncX, in1IncY, in1IncZ;
  int in2IncX, in2IncY, in2IncZ;
  int in3IncX, in3IncY, in3IncZ;
  int outIncX, outIncY, outIncZ;

  // Get increments to march through data 
  in1Data->GetContinuousIncrements(outExt, in1IncX, in1IncY, in1IncZ);
  in2Data->GetContinuousIncrements(outExt, in2IncX, in2IncY, in2IncZ);
  in3Data->GetContinuousIncrements(outExt, in3IncX, in3IncY, in3IncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  // Loop through ouput pixels
  float S[3][3];
  float SI[3][3];
  float V[3];
  float SIV[3];
  float T2;
  float F;
  int N=self->GetNumberOfSamples();
  for(int z = outExt[4]; z <= outExt[5]; ++z)
    {
    for(int y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
      {
      for(int x = outExt[0]; x <= outExt[1] ; ++x)
    {
        V[0]=*in1Ptr++ - *in3Ptr++;
        V[1]=*in1Ptr++ - *in3Ptr++;
        V[2]=*in1Ptr++ - *in3Ptr++;
        
        S[0][0]=        *in2Ptr++;
        S[0][1]=S[1][0]=*in2Ptr++;
        S[0][2]=S[2][0]=*in2Ptr++;
        S[1][1]=        *in2Ptr++;
        S[1][2]=S[2][1]=*in2Ptr++;
        S[2][2]=        *in2Ptr++;

        vtkMath::Invert3x3(S,SI);
        vtkMath::Multiply3x3(SI,V,SIV);

        // like comparing 2 populations, with 1
        T2=(N/(N+1))*vtkMath::Dot(V,SIV);
        F=T2*(N-3)/((N-1)*3.);

        // we want fprob(3,N-3,F)
        // which is equivalent to
        // betai((N-3)/2.,3/2.,(N-3)/(N-3+3*F))
        *outPtr++=gsl_sf_beta_inc((N-3)/2.,3/2.,(N-3)/(N-3+3*F));
    }
      outPtr += outIncY;
      in1Ptr += in1IncY;
      in2Ptr += in2IncY;
      in3Ptr += in3IncY;
      }
    outPtr += outIncZ;
    in1Ptr += in1IncZ;
    in2Ptr += in2IncZ;
    in3Ptr += in3IncZ;
    }
  outData->Modified();
}

void vtkDisplacementPValue::ThreadedExecute(vtkImageData **inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  float *inPtr1;
  float *inPtr2;
  float *inPtr3;
  float *outPtr;

  vtkDebugMacro(<< "ThreadedExecute: inData = " << inData 
  << ", outData = " << outData);
  

  if (inData[0] == 0)
    {
    vtkErrorMacro(<< "Input 1 must be specified.");
    return;
    }
   
  if (inData[1] == 0)
    {
    vtkErrorMacro(<< "Input 2 must be specified.");
    return;
    }
   
  if (inData[2] == 0)
    {
    vtkErrorMacro(<< "Input 3 must be specified.");
    return;
    }
   
  if (outData == 0)
    {
    vtkErrorMacro(<< "Output must be specified.");
    return;
    }
   
  inPtr1 = (float*)inData[0]->GetScalarPointerForExtent(outExt);
  inPtr2 = (float*)inData[1]->GetScalarPointerForExtent(outExt);
  inPtr3 = (float*)inData[2]->GetScalarPointerForExtent(outExt);
  outPtr = (float*)outData->GetScalarPointerForExtent(outExt);
  
  if (inData[0]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input0 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 3");
    return;
    }

  if (inData[1]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input1 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 6");
    return;
    }

  if (inData[2]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input2 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 3");
    return;
    }

  if (inData[0]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input1 ScalarType, "
                  <<  inData[0]->GetScalarType()
                  << ", must be float");
    return;
    }
  
  if (inData[1]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input2 ScalarType, "
                  <<  inData[0]->GetScalarType()
                  << ", must be float");
    return;
    }

  if (inData[2]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input3 ScalarType, "
                  <<  inData[0]->GetScalarType()
                  << ", must be float");
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
  if (outData->GetNumberOfScalarComponents() != 1)
    {
    vtkErrorMacro(<< "Execute: output NumberOfScalarComponents, "
                  << outData->GetNumberOfScalarComponents()
                  << ", must be 3");
    return;
    }
    
  vtkDisplacementPValueExecute(this,
                               inData[0],inPtr1, 
                               inData[1],inPtr2,
                               inData[2],inPtr3, 
                               outData, outPtr,
                               outExt);
}

void vtkDisplacementPValue::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "NumberOfSamples: " << this->GetNumberOfSamples() << "\n";
}
