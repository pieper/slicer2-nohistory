/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMeanPValue.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkMeanPValue.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkMath.h"

#include <gsl/gsl_sf.h>
#ifdef WIN32
#include <float.h>
#endif

// isnan() is broken in /usr/include/gcc/darwin/3.3/c++/cmath
#if defined(__APPLE__) && defined(__MACH__)
extern "C" int isnan (double);
#endif

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

vtkMeanPValue* vtkMeanPValue::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMeanPValue");
  if(ret)
    {
    return (vtkMeanPValue*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkMeanPValue;
}

vtkMeanPValue::vtkMeanPValue()
{
  this->NumberOfRequiredInputs = 3;
  this->NumberOfSamples1=0;
  this->NumberOfSamples2=0;
}

vtkMeanPValue::~vtkMeanPValue()
{
}

void vtkMeanPValue::ExecuteInformation(vtkImageData **inDatas, 
                                       vtkImageData *outData)
{
  vtkDebugMacro("ExecuteInformation");
  vtkImageMultipleInputFilter::ExecuteInformation(inDatas,outData);
  
  outData->SetNumberOfScalarComponents(1);
}

vtkImageData* vtkMeanPValue::GetMean1()
{
  if (this->NumberOfInputs < 1)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Target of "
        << this->Inputs[0]);
  return (vtkImageData *)(this->Inputs[0]);
}

vtkImageData* vtkMeanPValue::GetSigma1()
{
  if (this->NumberOfInputs < 2)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[1]);
  return (vtkImageData *)(this->Inputs[1]);
}

vtkImageData* vtkMeanPValue::GetMean2()
{
  if (this->NumberOfInputs < 3)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Target of "
        << this->Inputs[2]);
  return (vtkImageData *)(this->Inputs[2]);
}

vtkImageData* vtkMeanPValue::GetSigma2()
{
  if (this->NumberOfInputs < 4)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[3]);
  return (vtkImageData *)(this->Inputs[3]);
}

static void vtkMeanPValueExecute(vtkMeanPValue *self,
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
  if(in4Data)
    {
    in4Data->GetContinuousIncrements(outExt, in4IncX, in4IncY, in4IncZ);
    }
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  // Loop through ouput pixels
  float S[3][3];
  float SI[3][3];
  float V[3];
  float SIV[3];
  float T2;
  float F;
  int N1=self->GetNumberOfSamples1();
  int N2=self->GetNumberOfSamples2();
  int p=3;
  for(int z = outExt[4]; z <= outExt[5]; ++z)
    {
    for(int y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
      {
      for(int x = outExt[0]; x <= outExt[1] ; ++x)
    {
        V[0]=*in1Ptr++ - *in3Ptr++;
        V[1]=*in1Ptr++ - *in3Ptr++;
        V[2]=*in1Ptr++ - *in3Ptr++;
 
        S[0][0]=        (N1 * *in2Ptr++)/(N1+N2-2);
        S[0][1]=S[1][0]=(N1 * *in2Ptr++)/(N1+N2-2);
        S[0][2]=S[2][0]=(N1 * *in2Ptr++)/(N1+N2-2);
        S[1][1]=        (N1 * *in2Ptr++)/(N1+N2-2);
        S[1][2]=S[2][1]=(N1 * *in2Ptr++)/(N1+N2-2);
        S[2][2]=        (N1 * *in2Ptr++)/(N1+N2-2);

        if(in4Ptr)
          {
          S[0][0]+=         (N2 * *in4Ptr++)/(N1+N2-2);
          S[0][1]= S[1][0]+=(N2 * *in4Ptr++)/(N1+N2-2);
          S[0][2]= S[2][0]+=(N2 * *in4Ptr++)/(N1+N2-2);
          S[1][1]+=         (N2 * *in4Ptr++)/(N1+N2-2);
          S[1][2]= S[2][1]+=(N2 * *in4Ptr++)/(N1+N2-2);
          S[2][2]+=         (N2 * *in4Ptr++)/(N1+N2-2);
          }
        
        vtkMath::Invert3x3(S,SI);
        vtkMath::Multiply3x3(SI,V,SIV);

        if(in4Ptr)
          { // Sigma1==Sigma2
          T2=(N1*N2)/float(N1+N2) * vtkMath::Dot(V,SIV);
          }
        else
          { // Sigma1!=Sigma2 (Sigma2 not provided)
          T2=N1 * vtkMath::Dot(V,SIV);
          }
        
        F=T2*(N1+N2-p-1)/float((N1+N2-2)*p);
        
        // we want 1 - F-cdf(a,b,F) = 1 - F-cdf(p,N1+N2-p-1,F)
        // which is equivalent to
        // 1 - (1 - BetaI(b/2.,a/2.,b/(b+a*F)))
        double val=(N1+N2-p-1)/(N1+N2-p-1+p*F);

        //Modified by Liu
#ifdef WIN32
        if(_isnan(val))
#else
        if(isnan(val))
#endif          
        {
            *outPtr++=0;
          }
        else
          {
          if(val<0)
            {
            val = 0;
            }
          *outPtr++=gsl_sf_beta_inc((N1+N2-p-1)/2.,p/2.,val);
//           printf("%f %f %f %f %f %f\n",T2,F,(N1+N2-p-1)/2.,p/2.,val,*(outPtr-1));
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

void vtkMeanPValue::ThreadedExecute(vtkImageData **inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  float *inPtr1=0;
  float *inPtr2=0;
  float *inPtr3=0;
  float *inPtr4=0;
  float *outPtr=0;

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
   
//   if (inData[3] == 0)
//     {
//     vtkErrorMacro(<< "Input 4 must be specified.");
//     return;
//     }
   
  if (outData == 0)
    {
    vtkErrorMacro(<< "Output must be specified.");
    return;
    }
   
  inPtr1 = (float*)inData[0]->GetScalarPointerForExtent(outExt);
  inPtr2 = (float*)inData[1]->GetScalarPointerForExtent(outExt);
  inPtr3 = (float*)inData[2]->GetScalarPointerForExtent(outExt);
  if(this->NumberOfInputs==4)
    {
    inPtr4 = (float*)inData[3]->GetScalarPointerForExtent(outExt);
    }
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
                  << inData[1]->GetNumberOfScalarComponents()
                  << ", must be 6");
    return;
    }

  if (inData[2]->GetNumberOfScalarComponents() != 3)
    {
    vtkErrorMacro(<< "Execute: input3 NumberOfScalarComponents, "
                  << inData[2]->GetNumberOfScalarComponents()
                  << ", must be 3");
    return;
    }

  if (inPtr4 && inData[3]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input4 NumberOfScalarComponents, "
                  << inData[3]->GetNumberOfScalarComponents()
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
                  <<  inData[1]->GetScalarType()
                  << ", must be float");
    return;
    }

  if (inData[2]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input3 ScalarType, "
                  <<  inData[2]->GetScalarType()
                  << ", must be float");
    return;
    }

  if (inPtr4 && inData[3]->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro(<< "Execute: input4 ScalarType, "
                  <<  inData[3]->GetScalarType()
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
    
  vtkMeanPValueExecute(this,
                       inData[0],inPtr1, 
                       inData[1],inPtr2,
                       inData[2],inPtr3, 
                       inPtr4 ? inData[3] : 0,inPtr4, 
                       outData, outPtr,
                       outExt);
}

void vtkMeanPValue::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "NumberOfSamples1: " << this->GetNumberOfSamples1() << "\n";
  os << indent << "NumberOfSamples2: " << this->GetNumberOfSamples2() << "\n";
}
