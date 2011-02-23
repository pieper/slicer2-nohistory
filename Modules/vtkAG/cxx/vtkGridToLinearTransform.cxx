/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGridToLinearTransform.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkGridToLinearTransform.h"
#include "vtkLandmarkTransform.h"
#include "vtkObjectFactory.h"
#include "vtkMatrix4x4.h"
#include "vtkPoints.h"

vtkGridToLinearTransform* vtkGridToLinearTransform::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkGridToLinearTransform");
  if(ret)
    {
    return (vtkGridToLinearTransform*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkGridToLinearTransform;
}

vtkGridToLinearTransform::vtkGridToLinearTransform()
{
  this->GridTransform=0;
  this->Mask=0;
  this->Mode=12;
}

vtkGridToLinearTransform::~vtkGridToLinearTransform()
{
  this->SetGridTransform(0);
}

void vtkGridToLinearTransform::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkLinearTransform::PrintSelf(os,indent);

  os << indent << "Mode: " << this->GetModeAsString() << "\n";
  os << indent << "GridTransform: " << this->GridTransform << "\n";
  if(this->GridTransform) 
    {
    this->GridTransform->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "Mask: " << this->Mask << "\n";
  if(this->Mask) 
    {
    this->Mask->PrintSelf(os,indent.GetNextIndent());
    }
}

void vtkGridToLinearTransform::Inverse()
{
  this->SetInverseFlag(!this->GetInverseFlag());
}

vtkAbstractTransform *vtkGridToLinearTransform::MakeTransform()
{
  return vtkGridToLinearTransform::New();
}

void vtkGridToLinearTransform::InternalUpdate()
{
  vtkGridTransform* grid=this->GetGridTransform();
  if(grid==0)
    {
    vtkErrorMacro("No grid transform provided!");
    return;
    }
  
  grid->Update();

  vtkImageData* disp=grid->GetDisplacementGrid();

  if(disp==0)
    {
    this->Matrix->Identity();
    return;
    }
  
  vtkImageData* mask=this->GetMask();
  
  vtkDebugMacro(<< "ExecuteData grid = " << grid 
  << ", mask = " << mask);

  int* ext = disp->GetExtent();
  int gincX,gincY,gincZ;
  disp->GetContinuousIncrements(ext,gincX,gincY,gincZ);
  float* gptr = static_cast<float*>(disp->GetScalarPointerForExtent(ext));

  int mincX,mincY,mincZ;
  unsigned char* mptr = 0;
  if(mask)
    {
    mask->GetContinuousIncrements(ext,mincX,mincY,mincZ);
    mptr = static_cast<unsigned char*>(mask->GetScalarPointerForExtent(ext));
    }

  int maxsize = 0;

  if(mptr)
    {
    unsigned char* tmp=mptr;
    for(int z=ext[4];z<=ext[5];++z)
      {
      for(int y=ext[2];y<=ext[3];++y)
    {
    for(int x=ext[0];x<=ext[1];++x)
      {
      if(*tmp++)
        {
        ++maxsize;
        }
      }
    tmp += mincY;
    }
      tmp += mincZ;
      }
    }
  else
    {
    int* dims = disp->GetDimensions();
    maxsize=dims[0]*dims[1]*dims[2];
    }

  vtkDebugMacro(<< "Using " << maxsize << " points.");

  vtkPoints* target=vtkPoints::New();
  vtkPoints* source=vtkPoints::New();

  target->SetNumberOfPoints(maxsize);
  source->SetNumberOfPoints(maxsize);

  vtkFloatingPointType* spa=disp->GetSpacing();
  vtkFloatingPointType* ori=disp->GetOrigin();
  float scale=grid->GetDisplacementScale();
  float shift=grid->GetDisplacementShift();
  int p=0;
  for(int z=ext[4];z<=ext[5];++z)
    {
    for(int y=ext[2];y<=ext[3];++y)
      {
      for(int x=ext[0];x<=ext[1];++x)
    {
    if(!mptr || *mptr)
      {
      float xx=x*spa[0]+ori[0];
      float yy=y*spa[1]+ori[1];
      float zz=z*spa[2]+ori[2];
      
      target->SetPoint(p,xx,yy,zz);
      
      float dx=*gptr++ * scale + shift;
      float dy=*gptr++ * scale + shift;
      float dz=*gptr++ * scale + shift;

      source->SetPoint(p,xx+dx,yy+dy,zz+dz);
      //      printf("%d %d %d -> %f %f %f\n",x,y,z,x+dx,y+dy,z+dz);
      ++p;
      }
    else
      {
      gptr+=3;
      }

    if(mptr)
      {
      ++mptr;
      }
    }
      gptr += gincY;
      if(mptr)
    {
    mptr += mincY;
    }
      }
    gptr += gincZ;
    if(mptr)
      {
      mptr += mincZ;
      }
    }

  //  target->Print(cout);
  //  source->Print(cout);
  
  vtkLandmarkTransform* trans=vtkLandmarkTransform::New();
  trans->SetMode(this->Mode);
  if(this->InverseFlag==0)
    {
    trans->SetTargetLandmarks(target);
    trans->SetSourceLandmarks(source);
    }
  else
    {
     trans->SetTargetLandmarks(source);
     trans->SetSourceLandmarks(target);
    }
  trans->Update();

  this->Matrix->DeepCopy(trans->GetMatrix());
  trans->Delete();
}
