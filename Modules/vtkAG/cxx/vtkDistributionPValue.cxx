/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistributionPValue.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkDistributionPValue.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkMath.h"

#include <gsl/gsl_randist.h>
#include <gsl/gsl_integration.h>

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

vtkDistributionPValue* vtkDistributionPValue::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDistributionPValue");
  if(ret)
    {
    return (vtkDistributionPValue*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkDistributionPValue;
}

vtkDistributionPValue::vtkDistributionPValue()
{
  this->NumberOfRequiredInputs = 4;
  this->NumberOfSamples1=0;
  this->NumberOfSamples2=0;
}

vtkDistributionPValue::~vtkDistributionPValue()
{
}

void vtkDistributionPValue::ExecuteInformation(vtkImageData **inDatas, 
                                               vtkImageData *outData)
{
  vtkDebugMacro("ExecuteInformation");
  vtkImageMultipleInputFilter::ExecuteInformation(inDatas,outData);
  
  outData->SetNumberOfScalarComponents(1);
}

vtkImageData* vtkDistributionPValue::GetMean1()
{
  if (this->NumberOfInputs < 1)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Target of "
        << this->Inputs[0]);
  return (vtkImageData *)(this->Inputs[0]);
}

vtkImageData* vtkDistributionPValue::GetSigma1()
{
  if (this->NumberOfInputs < 2)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[1]);
  return (vtkImageData *)(this->Inputs[1]);
}

vtkImageData* vtkDistributionPValue::GetMean2()
{
  if (this->NumberOfInputs < 3)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Target of "
        << this->Inputs[2]);
  return (vtkImageData *)(this->Inputs[2]);
}

vtkImageData* vtkDistributionPValue::GetSigma2()
{
  if (this->NumberOfInputs < 4)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[3]);
  return (vtkImageData *)(this->Inputs[3]);
}

struct my_f_params
{
  int N1;
  int N2;
};

static double f(double x, void* params)
{
  my_f_params *p=(my_f_params*)params;
  int N1=p->N1;
  int N2=p->N2;
  int N=N1+N2;
  int n1=N1-1;
  int n2=N2-1;
  int n=N-2;
  double X12=gsl_ran_beta_pdf(x,n1/2.,n2/2.);
  double X22=gsl_ran_beta_pdf(x,(n1-1)/2.,(n2-1)/2.);
  double X32=gsl_ran_beta_pdf(x,(n1-2)/2.,(n2-2)/2.);
  double Y22=gsl_ran_beta_pdf(x,n/2.-1,1/2.);
  double Y32=gsl_ran_beta_pdf(x,n/2.-2,1.);
  double Z1=gsl_ran_beta_pdf(x,n/2.,1/2.);
  double Z2=gsl_ran_beta_pdf(x,(n-1)/2.,1/2.);
  double Z3=gsl_ran_beta_pdf(x,(n-2)/2.,1/2.);
  return
    pow(X12,N1/2.)*(1-pow(X12,N2/2.))*
    pow(X22,N1/2.)*(1-pow(X22,N2/2.))*
    pow(X32,N1/2.)*(1-pow(X32,N2/2.))*
    pow(Y22,N/2.)*
    pow(Y32,N/2.)*
    pow(Z1,N/2.)*
    pow(Z2,N/2.)*
    pow(Z3,N/2.);
}

static void vtkDistributionPValueExecute(vtkDistributionPValue *self,
                                         vtkImageData *in1Data, float *in1Ptr,
                                         vtkImageData *in2Data, float *in2Ptr,
                                         vtkImageData *in3Data, float *in3Ptr,
                                         vtkImageData *in4Data, float *in4Ptr,
                                         vtkImageData *outData, float *outPtr,
                                         int outExt[6])
{
  int in1IncX, in1IncY, in1IncZ;
  int in2IncX, in2IncY, in2IncZ;
  int in3IncX, in3IncY, in3IncZ;
  int in4IncX, in4IncY, in4IncZ;
  int outIncX, outIncY, outIncZ;

  // Get increments to march through data 
  in1Data->GetContinuousIncrements(outExt, in1IncX, in1IncY, in1IncZ);
  in2Data->GetContinuousIncrements(outExt, in2IncX, in2IncY, in2IncZ);
  in3Data->GetContinuousIncrements(outExt, in3IncX, in3IncY, in3IncZ);
  in4Data->GetContinuousIncrements(outExt, in4IncX, in4IncY, in4IncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  // Loop through ouput pixels
  float A1[3][3];
  float A2[3][3];
  float V1[3];
  float V2[3];
  float V[3];
  float B[3][3];
  int N1=self->GetNumberOfSamples1();
  int N2=self->GetNumberOfSamples2();
  int N=N1+N2;
  float N1f=float(N1)/N;
  float N2f=float(N2)/N;
  float l;
  float d;
  float v;
  
  gsl_integration_workspace* w=gsl_integration_workspace_alloc(1000);
  double result, error;
  struct my_f_params params={N1,N2};
  gsl_function F;
  F.function=&f;
  F.params=&params;
  for(int z = outExt[4]; z <= outExt[5]; ++z)
    {
    for(int y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
      {
      for(int x = outExt[0]; x <= outExt[1] ; ++x)
    {
        printf("\r%d %d %d      ",z,y,x);
        fflush(stdout);
        
        A1[0][0]=         N1 * *in2Ptr++;
        A1[0][1]=A1[1][0]=N1 * *in2Ptr++;
        A1[0][2]=A1[2][0]=N1 * *in2Ptr++;
        A1[1][1]=         N1 * *in2Ptr++;
        A1[1][2]=A1[2][1]=N1 * *in2Ptr++;
        A1[2][2]=         N1 * *in2Ptr++;

        A2[0][0]=         N2 * *in4Ptr++;
        A2[0][1]=A2[1][0]=N2 * *in4Ptr++;
        A2[0][2]=A2[2][0]=N2 * *in4Ptr++;
        A2[1][1]=         N2 * *in4Ptr++;
        A2[1][2]=A2[2][1]=N2 * *in4Ptr++;
        A2[2][2]=         N2 * *in4Ptr++;

        V1[0]=*in1Ptr++;
        V1[1]=*in1Ptr++;
        V1[2]=*in1Ptr++;
        
        V2[0]=*in3Ptr++;
        V2[1]=*in3Ptr++;
        V2[2]=*in3Ptr++;

        V[0]=N1f*V1[0]+N2f*V2[0];
        V[1]=N1f*V1[1]+N2f*V2[1];
        V[2]=N1f*V1[2]+N2f*V2[2];

        V1[0]-=V[0];
        V1[1]-=V[1];
        V1[2]-=V[2];
        
        V2[0]-=V[0];
        V2[1]-=V[1];
        V2[2]-=V[2];

        B[0][0]        =N1*V1[0]*V1[0] + N2*V2[0]*V2[0] + A1[0][0] + A2[0][0]; 
        B[0][1]=B[1][0]=N1*V1[0]*V1[1] + N2*V2[0]*V2[1] + A1[0][1] + A2[0][1]; 
        B[0][2]=B[2][0]=N1*V1[0]*V1[2] + N2*V2[0]*V2[2] + A1[0][2] + A2[0][2]; 
        B[1][1]        =N1*V1[1]*V1[1] + N2*V2[1]*V2[1] + A1[1][1] + A2[1][1]; 
        B[1][2]=B[2][1]=N1*V1[1]*V1[2] + N2*V2[1]*V2[2] + A1[1][2] + A2[1][2]; 
        B[2][2]        =N1*V1[2]*V1[2] + N2*V2[2]*V2[2] + A1[2][2] + A2[2][2]; 

        d=vtkMath::Determinant3x3(B);
        if(d!=0)
          {
            v=pow((double)vtkMath::Determinant3x3(A1),(double)(N1/2.))/pow((double)N1,(double)(N1*3/2.))
            *
            pow((double)vtkMath::Determinant3x3(A2),(double)(N2/2.))/pow((double)N2,(double)(N2*3/2.))
            *
            pow((double)N,(double)(N*3/2.))/pow((double)d,(double)(N/2.));

          gsl_integration_qags(&F,0,v,0,1e-7,1000,w,&result,&error);
          l=result;
          }
        else
          {
          l=1;
          }
        *outPtr++=l;
    }
      outPtr += outIncY;
      in1Ptr += in1IncY;
      in2Ptr += in2IncY;
      in3Ptr += in3IncY;
      in4Ptr += in4IncY;
      }
    outPtr += outIncZ;
    in1Ptr += in1IncZ;
    in2Ptr += in2IncZ;
    in3Ptr += in3IncZ;
    in4Ptr += in4IncZ;
    }
  outData->Modified();
}

void vtkDistributionPValue::ThreadedExecute(vtkImageData **inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  float *inPtr1;
  float *inPtr2;
  float *inPtr3;
  float *inPtr4;
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
   
  if (inData[3] == 0)
    {
    vtkErrorMacro(<< "Input 4 must be specified.");
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
  inPtr4 = (float*)inData[3]->GetScalarPointerForExtent(outExt);
  outPtr = (float*)outData->GetScalarPointerForExtent(outExt);
  
  if (inData[0]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input1 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 3");
    return;
    }

  if (inData[1]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input2 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 6");
    return;
    }

  if (inData[2]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input3 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 3");
    return;
    }

  if (inData[3]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input4 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 6");
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

  if (inData[3]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input4 ScalarType, "
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
    
  vtkDistributionPValueExecute(this,
                               inData[0],inPtr1, 
                               inData[1],inPtr2,
                               inData[2],inPtr3, 
                               inData[3],inPtr4, 
                               outData, outPtr,
                               outExt);
}

void vtkDistributionPValue::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "NumberOfSamples1: " << this->GetNumberOfSamples1() << "\n";
  os << indent << "NumberOfSamples2: " << this->GetNumberOfSamples2() << "\n";
}
