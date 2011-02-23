/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPWMedianIT.cxx,v $
  Date:      $Date: 2006/01/06 17:57:12 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkPWMedianIT.h"
#include "vtkObjectFactory.h"

#include "vtkImageAppendComponents.h"
#include "vtkImageAccumulate.h"
#include "vtkImageExtractComponents.h"

#include <algorithm>
#include <functional>

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

vtkPWMedianIT* vtkPWMedianIT::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPWMedianIT");
  if(ret)
    {
    return (vtkPWMedianIT*)ret;
    }
  // If the factory was unable to create the object, then create it here.
    return new vtkPWMedianIT;
}

vtkPWMedianIT::vtkPWMedianIT()
{
}

vtkPWMedianIT::~vtkPWMedianIT()
{
}

void vtkPWMedianIT::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkPWConstantIT::PrintSelf(os, indent);
}

template <class T>
static void vtkPWMedianITExecute(vtkPWMedianIT *self,
                 vtkImageData *in1Data,
                 vtkImageData *in2Data,
                 vtkImageData *in3Data, T *in3Ptr,
                 int comp)
{
  vtkFloatingPointType* range1=in1Data->GetScalarRange();
  vtkFloatingPointType* range2=in2Data->GetScalarRange();
  int maxj=int(range1[1]-range1[0]+0.5);
  int maxi=int(range2[1]-range2[0]+0.5);
    
  vtkImageAppendComponents* append=vtkImageAppendComponents::New();
  append->SetInput(0,in2Data);
  append->SetInput(1,in1Data);

  vtkImageAccumulate* accum=vtkImageAccumulate::New();
  accum->SetInput(append->GetOutput());
  accum->SetComponentExtent(0,maxi,0,maxj,0,0);
  accum->SetComponentOrigin(range2[0],range1[0],0);
  accum->SetComponentSpacing(1,1,1);
  
  vtkImageData* acres=accum->GetOutput();
  acres->Update();
  int* ptr=(int*)acres->GetScalarPointer();

  self->SetValue(comp,0,0);
  if(self->GetNumberOfPieces(comp)<=1)
    {
    vtkGenericWarningMacro(<<"Defining only one piece doesn't make sense."
               " It is set to 0.");
    }
  else
    {
    int low=int((self->GetBoundary(comp,0)-range2[0]+0.5)/1.0);
    int high;
    for(int f=1;f<self->GetNumberOfPieces(comp);++f)
      {
      // set high bound
      if(f==self->GetNumberOfPieces(comp)-1)
    {
    // if last piece, to more than max intensity (exclusive bounds)
    high=maxi+1;
    }
      else
    {
    high=int((self->GetBoundary(comp,f)-range2[0]+0.5)/1.0);
    }
      
      int diff=high-low;
      int* ptr1=ptr+low;
      
      int sum=0;
      
      // Modified by Liu
      //int partial[maxj];
      int* partial = NULL;
      if ( maxj > 0) 
          partial = new int[maxj];



      std::fill_n(partial,maxj,0);
      
      // compute sum and partial sums
      int ext=maxi-diff+1;
      for(int j=0;j<maxj;++j)
    {
    int sum2=0;
    for(int i=low;i<high;++i)
      {
      sum2+=*ptr1++;
      }
    sum+=sum2;
    partial[j]=sum;
    ptr1+=ext;
    }
      
      // find median
      int median=std::find_if(partial,partial+maxj,
                              std::bind2nd(std::greater<int>(),sum/2))-partial-1;
      self->SetValue(comp,f,median);
      
      low=high;
      // Modified by Liu
      //int partial[maxj];
      if ( partial != NULL)
          delete[] partial ;

      }
    }

  append->Delete();
  accum->Delete();
}

template <class T>
static void vtkPWMedianITExecute(vtkPWMedianIT *self,
                 vtkImageData *in1Data,
                 vtkImageData *in2Data,
                 vtkImageData *in3Data, T *in3Ptr)
{
  vtkImageExtractComponents* c1=vtkImageExtractComponents::New();
  vtkImageExtractComponents* c2=vtkImageExtractComponents::New();

  c1->SetInput(in1Data);
  c2->SetInput(in2Data);
  for(int c=0; c < self->GetNumberOfFunctions(); ++c)
    {
    c1->SetComponents(c);
    c2->SetComponents(c);
    c1->Update();
    c2->Update();
    vtkPWMedianITExecute(self,c1->GetOutput(),c2->GetOutput(),in3Data,in3Ptr,c);
    }
  c1->Delete();
  c2->Delete();
}

void vtkPWMedianIT::InternalUpdate()
{
  vtkDebugMacro("Main code for intensity matching");
   
  void *inPtr3=0;

  if (this->Target == NULL)
    {
    vtkErrorMacro(<< "Target must be specified.");
    return;
    }
   
  if (Source == NULL)
    {
    vtkErrorMacro(<< "Source must be specified.");
    return;
    }
   
  if(this->Mask)
    {
    inPtr3 = Mask->GetScalarPointer();
    }

  // expect all inputs of the same time.
  if (this->Target->GetScalarType() != Source->GetScalarType())
    {
    vtkErrorMacro(<< "Execute: Target ScalarType, "
          <<  this->Target->GetScalarType()
          << ", must match Source ScalarType "
          << Source->GetScalarType());
    return;
    }
      
  if (this->Target->GetNumberOfScalarComponents() !=
      this->Source->GetNumberOfScalarComponents())
    {
    vtkErrorMacro(<< "Execute: Target NumberOfScalarComponents, "
          << this->Target->GetNumberOfScalarComponents()
          << ", must be equal to Source NumberOfScalarComponents, "
          << this->Source->GetNumberOfScalarComponents());
    return;
    }
    
  if(this->GetNumberOfFunctions()>
     this->Target->GetNumberOfScalarComponents())
    {
    vtkErrorMacro(<< "Execute: Target NumberOfScalarComponents, "
          << this->Target->GetNumberOfScalarComponents()
          << ", must smaller or equal to number of functions, "
          << this->GetNumberOfFunctions());
    return;
    }

  switch (this->Target->GetScalarType())
    {
    vtkTemplateMacro5(vtkPWMedianITExecute,
              this,this->Target, this->Source,
              this->Mask, (VTK_TT *)(inPtr3));
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}
