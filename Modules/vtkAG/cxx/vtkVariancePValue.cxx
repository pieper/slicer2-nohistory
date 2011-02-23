/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkVariancePValue.cxx,v $
  Date:      $Date: 2006/01/06 17:57:12 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkVariancePValue.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkMath.h"
//Modified by Liu
#ifdef WIN32
#include <float.h>
#endif 

// isnan() is broken in /usr/include/gcc/darwin/3.3/c++/cmath
#if defined(__APPLE__) && defined(__MACH__)
extern "C" int isnan (double);
#endif

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

vtkVariancePValue* vtkVariancePValue::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkVariancePValue");
  if(ret)
    {
    return (vtkVariancePValue*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkVariancePValue;
}

vtkVariancePValue::vtkVariancePValue()
{
  this->NumberOfRequiredInputs = 2;
  this->NumberOfSamples1=0;
  this->NumberOfSamples2=0;
}

vtkVariancePValue::~vtkVariancePValue()
{
}

void vtkVariancePValue::ExecuteInformation(vtkImageData **inDatas, 
                                           vtkImageData *outData)
{
  vtkDebugMacro("ExecuteInformation");
  vtkImageMultipleInputFilter::ExecuteInformation(inDatas,outData);
  
  outData->SetNumberOfScalarComponents(1);
}

vtkImageData* vtkVariancePValue::GetSigma1()
{
  if (this->NumberOfInputs < 1)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[0]);
  return (vtkImageData *)(this->Inputs[0]);
}

vtkImageData* vtkVariancePValue::GetSigma2()
{
  if (this->NumberOfInputs < 2)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[1]);
  return (vtkImageData *)(this->Inputs[1]);
}

static void vtkVariancePValueExecute(vtkVariancePValue *self,
                                     vtkImageData *in1Data, float *in1Ptr,
                                     vtkImageData *in2Data, float *in2Ptr,
                                     vtkImageData *outData, float *outPtr,
                                     int outExt[6])
{
  int in1IncX, in1IncY, in1IncZ;
  int in2IncX, in2IncY, in2IncZ;
  int outIncX, outIncY, outIncZ;

  //Modifiefd by Liu
  int i,x,y,z;

  // Get increments to march through data 
  in1Data->GetContinuousIncrements(outExt, in1IncX, in1IncY, in1IncZ);
  in2Data->GetContinuousIncrements(outExt, in2IncX, in2IncY, in2IncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  // Loop through ouput pixels
  double A1[3][3];
  double A2[3][3];
  double A[3][3];
  double dA;
  double V[3][3];
  double Vt[3][3];
  double w[3];
  double W[3][3];
  int N1=self->GetNumberOfSamples1();
  int N2=self->GetNumberOfSamples2();
  int n1=N1-1;
  int n2=N2-1;
  int n=n1+n2;
  float k1=float(n1)/n;
  float k2=float(n2)/n;
  double V1;
  double l1s;
  int p=3;
  int q=2;
  double r;
  double o2;
  int f=(q-1)*p*(p+1)/2;
  double c;

  //for(int i=0;i<3;++i)
  // Modified by Liu
  for( i=0;i<3;++i)
    {
    W[i][0]=0;
    W[i][1]=0;
    W[i][2]=0;
    }
//Modified by Liu  
//  for(int z = outExt[4]; z <= outExt[5]; ++z)
//   {
//    for(int y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
//      {
//      for(int x = outExt[0]; x <= outExt[1] ; ++x)
  
  for( z = outExt[4]; z <= outExt[5]; ++z)
    {
    for( y = outExt[2]; !self->AbortExecute && y <= outExt[3]; ++y)
      {
      for( x = outExt[0]; x <= outExt[1] ; ++x)

      
      {
        A1[0][0]=         N1 * *in1Ptr++;
        A1[0][1]=A1[1][0]=N1 * *in1Ptr++;
        A1[0][2]=A1[2][0]=N1 * *in1Ptr++;
        A1[1][1]=         N1 * *in1Ptr++;
        A1[1][2]=A1[2][1]=N1 * *in1Ptr++;
        A1[2][2]=         N1 * *in1Ptr++;

        A2[0][0]=         N2 * *in2Ptr++;
        A2[0][1]=A2[1][0]=N2 * *in2Ptr++;
        A2[0][2]=A2[2][0]=N2 * *in2Ptr++;
        A2[1][1]=         N2 * *in2Ptr++;
        A2[1][2]=A2[2][1]=N2 * *in2Ptr++;
        A2[2][2]=         N2 * *in2Ptr++;

//         A1[0][0]=         N1 * 1;
//         A1[0][1]=A1[1][0]=N1 * 0;
//         A1[0][2]=A1[2][0]=N1 * 0;
//         A1[1][1]=         N1 * 1;
//         A1[1][2]=A1[2][1]=N1 * 0;
//         A1[2][2]=         N1 * 1;

//         A2[0][0]=         N2 * 1.1;
//         A2[0][1]=A2[1][0]=N2 * 0;
//         A2[0][2]=A2[2][0]=N2 * 0;
//         A2[1][1]=         N2 * 1.1;
//         A2[1][2]=A2[2][1]=N2 * 0;
//         A2[2][2]=         N2 * 1.1;

        // Modified by Liu
        //for(int i=0;i<3;++i)
        for( i=0;i<3;++i)
          {
          A[i][0]=A1[i][0]+A2[i][0];
          A[i][1]=A1[i][1]+A2[i][1];
          A[i][2]=A1[i][2]+A2[i][2];
          }

//         for(int i=0;i<3;++i)
//           {
//           printf("A1 %lg %lg %lg\n",A1[i][0],A1[i][1],A1[i][2]);
//           }
//         printf("\n");
//         for(int i=0;i<3;++i)
//           {
//           printf("A2 %lg %lg %lg\n",A2[i][0],A2[i][1],A2[i][2]);
//           }
//         printf("\n");
        
        // lets whiten everything to stay within double limits.
        vtkMath::Diagonalize3x3(A,w,V);

        //         printf("w %lg %lg %lg\n",w[0],w[1],w[2]);
//         for(int i=0;i<3;++i)
//           {
//           printf("V %lg %lg %lg\n",V[i][0],V[i][1],V[i][2]);
//           }
//         printf("\n");

        dA=1;
        // Modified by Liu
        //for(int i=0;i<3;++i)
        for(i=0;i<3;++i)  
        {
          if(w[i]<0)
            {
            dA=0;
            break;
            }
          W[i][i]=1/sqrt(w[i]);
          }

//         for(int i=0;i<3;++i)
//           {
//           printf("W %lg %lg %lg\n",W[i][0],W[i][1],W[i][2]);
//           }
//         printf("\n");

        vtkMath::Multiply3x3(V,W,V);
        vtkMath::Transpose3x3(V,Vt);

        vtkMath::Multiply3x3(Vt,A1,A1);
        vtkMath::Multiply3x3(A1,V,A1);

        vtkMath::Multiply3x3(Vt,A2,A2);
        vtkMath::Multiply3x3(A2,V,A2);
        
        vtkMath::Multiply3x3(Vt,A,A);
        vtkMath::Multiply3x3(A,V,A);

//         dA=vtkMath::Determinant3x3(A);
        
//         for(int i=0;i<3;++i)
//           {
//           printf("%lg %lg %lg\n",A1[i][0],A1[i][1],A1[i][2]);
//           }
//         printf("\n");
        
//         for(int i=0;i<3;++i)
//           {
//           printf("%lg %lg %lg\n",A2[i][0],A2[i][1],A2[i][2]);
//           }
//         printf("\n");
      
//         for(int i=0;i<3;++i)
//           {
//           printf("%lg %lg %lg\n",A[i][0],A[i][1],A[i][2]);
//           }
//         printf("\n");

//         printf("%lg %lg\n",dA,vtkMath::Determinant3x3(A));
        if(dA!=0)
          {
          V1=pow(vtkMath::Determinant3x3(A1),n1/2.) *
            pow(vtkMath::Determinant3x3(A2),n2/2.) /
            pow(dA,n/2.);
//           printf("v1 %lg \n",V1);
//Modified by Liu
#ifdef WIN32
          if (_isnan(V1))
#else

          if(isnan(V1))
#endif 
            {
//             printf("problem for pixel %d %d %d\n",x,y,z);
//             printf("%lg %lg %lg\n",vtkMath::Determinant3x3(A1),n1/2.,pow(vtkMath::Determinant3x3(A1),n1/2.));
//             printf("%lg %lg %lg\n",vtkMath::Determinant3x3(A2),n2/2.,pow(vtkMath::Determinant3x3(A2),n2/2.));
//             printf("%lg %lg %lg\n",dA,n/2.,pow(dA,n/2.));

//             for(int i=0;i<3;++i)
//               {
//               printf("A1 %lg %lg %lg\n",A1[i][0],A1[i][1],A1[i][2]);
//               }
//             printf("\n");
//             for(int i=0;i<3;++i)
//               {
//               printf("A2 %lg %lg %lg\n",A2[i][0],A2[i][1],A2[i][2]);
//               }
//             printf("\n");
            
//             exit(0);
            *outPtr=0;
            }
          else if(V1==0)
        {
//             printf("%lg\n",V1);
//             printf("%lg %lg %lg\n",vtkMath::Determinant3x3(A1),n1/2.,pow(vtkMath::Determinant3x3(A1),n1/2.));
//             printf("%lg %lg %lg\n",vtkMath::Determinant3x3(A2),n2/2.,pow(vtkMath::Determinant3x3(A2),n2/2.));
//             printf("%lg %lg %lg\n",dA,n/2.,pow(dA,n/2.));
//             exit(0);
            *outPtr=0;
        }
          else
            {
            //l1s=V1*pow(n,p*n/2.)/(pow(n1,p*n1/2.)*pow(n2,p*n2/2.));
            l1s=V1*pow((double)(pow((double)(1/k1),(double)k1)*pow((double)(1/k2),(double)k2)),(double)(p*n/2.));
            r=1-(1./n1+1./n2-1./n)*(2*p*p+3*p-1)/(6*(p+1)*(q-1));
            o2=p*(p+1)*((p-1)*(p+2)*(1./(n1*n1)+1./(n2*n2)-1./(n*n))-
                        6*(q-1)*pow(1-r,2))/(48*r*r);
            c=-2*r*log(l1s);

            // we want chi2(c,f) == gammp(f/2.,c/2)
            *outPtr=1-gsl_sf_gamma_inc_P(f/2.,c/2.)+
              o2*(gsl_sf_gamma_inc_P((f+4)/2.,c/2.)-
                  gsl_sf_gamma_inc_P(f/2.,c/2.));
//             printf("%lg %lg %lg %lg %lg %i %g %g\n",V1,l1s,r,o2,c,f,*outPtr,gsl_sf_gamma_inc_P(f/2.,c/2.));
//             exit(0);
            }
          
      outPtr++;
          }
        else
          {
//           printf("something's wrong, dA==0\n");
//           exit(0);
          *outPtr++=0;
          }
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

void vtkVariancePValue::ThreadedExecute(vtkImageData **inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  float *inPtr1;
  float *inPtr2;
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
   
  if (outData == 0)
    {
    vtkErrorMacro(<< "Output must be specified.");
    return;
    }
   
  inPtr1 = (float*)inData[0]->GetScalarPointerForExtent(outExt);
  inPtr2 = (float*)inData[1]->GetScalarPointerForExtent(outExt);
  outPtr = (float*)outData->GetScalarPointerForExtent(outExt);
  
  if (inData[0]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input0 NumberOfScalarComponents, "
                  << inData[0]->GetNumberOfScalarComponents()
                  << ", must be 6");
    return;
    }

  if (inData[1]->GetNumberOfScalarComponents() != 6)
    {
    vtkErrorMacro(<< "Execute: input2 NumberOfScalarComponents, "
                  << inData[1]->GetNumberOfScalarComponents()
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
                  << ", must be 1");
    return;
    }
    
  vtkVariancePValueExecute(this,
                           inData[0],inPtr1, 
                           inData[1],inPtr2,
                           outData, outPtr,
                           outExt);
}

void vtkVariancePValue::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "NumberOfSamples1: " << this->GetNumberOfSamples1() << "\n";
  os << indent << "NumberOfSamples2: " << this->GetNumberOfSamples2() << "\n";
}
