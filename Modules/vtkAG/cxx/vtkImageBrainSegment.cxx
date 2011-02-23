/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageBrainSegment.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkImageBrainSegment.h"
#include "vtkImageHistogramNormalization.h"
#include "vtkImageThreshold.h"
#include "vtkImageContinuousErode3D.h"
#include "vtkImageSeedConnectivity.h"
#include "vtkImageContinuousDilate3D.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"

vtkImageBrainSegment* vtkImageBrainSegment::New(){
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageBrainSegment");
  if(ret)
    {
    return (vtkImageBrainSegment*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageBrainSegment;
}

vtkImageBrainSegment::vtkImageBrainSegment()
{
  ErodeKernelSize=3;
  DilateKernelSize=15;
}

vtkImageBrainSegment::~vtkImageBrainSegment()
{
}

void vtkImageBrainSegment::ExecuteInformation(vtkImageData *inData, vtkImageData *outData)
{
  outData->SetScalarType(3);
}

void vtkImageBrainSegment::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os, indent);
}

int vtkImageBrainSegment::Average(vtkImageData* img,int thesh)
{
  int* ext=img->GetWholeExtent();
  float s=0;
  int c=0;
  for(int z=ext[4];z<=ext[5];++z)
    {
    for(int y=ext[2];y<=ext[3];++y)
      {
      for(int x=ext[0];x<=ext[1];++x)
    {
#if !(VTK_MAJOR_VERSION ==4 && VTK_MINOR_VERSION > 2)
        float v=img->GetScalarComponentAsFloat(x,y,z,0);
#else
        double v=img->GetScalarComponentAsDouble(x,y,z,0);
#endif
    if(v>=thesh)
      {
      s+=v;
      ++c;
      }
    }
      }
    }

  vtkDebugMacro(<< "Average: " << s/c);
  return int(s/c);
}
 
void vtkImageBrainSegment::ExecuteData(vtkDataObject *out)
{
  vtkImageData* inData=this->GetInput();
  vtkImageData* outData = this->AllocateOutputData(out);
  
  vtkDebugMacro(<< "ExecuteData: inData = " << inData 
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

  int eks=this->GetErodeKernelSize();
  int dks=this->GetDilateKernelSize();
  
  vtkImageHistogramNormalization* n=vtkImageHistogramNormalization::New();
  n->SetInput(inData);
  n->SetOutputScalarTypeToUnsignedChar();
  n->Update();
  
  vtkImageThreshold* t=vtkImageThreshold::New();
  t->SetInput(n->GetOutput());
  //  t->SetOutputScalarTypeToUnsignedChar();
  t->ThresholdByUpper(this->Average(n->GetOutput(),15));
  t->ReplaceInOn();
  t->SetInValue(255);
  t->ReplaceOutOn();
    
  vtkImageContinuousErode3D* e=vtkImageContinuousErode3D::New();
  e->SetInput(t->GetOutput());
  e->SetKernelSize(eks,eks,eks);

  int* dims=inData->GetDimensions();
  vtkImageSeedConnectivity* c=vtkImageSeedConnectivity::New();
  c->SetInput(e->GetOutput());
  c->AddSeed(dims[0]/2,dims[1]/2,dims[2]/2);
  c->SetInputConnectValue(255);
  c->SetOutputConnectedValue(255);
  c->SetOutputUnconnectedValue(0);

  vtkImageContinuousDilate3D* d=vtkImageContinuousDilate3D::New();
  d->SetInput(c->GetOutput());
  d->SetKernelSize(dks,dks,dks);
  d->SetOutput(outData);
  d->Update();
  outData->SetSource(this);
  
  n->Delete();
  t->Delete();
  e->Delete();
  c->Delete();
  d->Delete();
}

