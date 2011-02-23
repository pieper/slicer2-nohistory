/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPWConstantIT.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkPWConstantIT.h"
#include "vtkObjectFactory.h"

#include <algorithm>

vtkPWConstantIT* vtkPWConstantIT::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPWConstantIT");
  if(ret)
    {
    return (vtkPWConstantIT*)ret;
    }
  // If the factory was unable to create the object, then create it here.
    return new vtkPWConstantIT;
}

vtkPWConstantIT::vtkPWConstantIT()
{
  this->NumIndepVars = 1;
  this->NumberOfPieces=0;
  this->Boundaries=0;
  this->Values=0;
}

vtkPWConstantIT::~vtkPWConstantIT()
{
  if(this->NumberOfPieces)
    {
    delete [] this->NumberOfPieces;
    }
  if (this->Boundaries!=0)
    {
    this->DeleteFunctions();
    }
}

void vtkPWConstantIT::SetNumberOfFunctions(int n)
{
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): setting NumFuncs to " << n); 
  if(this->NumFuncs!=n)
    {
    this->DeleteFunctions();

    if (this->NumberOfPieces)
      {
      delete [] this->NumberOfPieces;
      }
    this->NumFuncs=n;
    this->NumberOfPieces=new int[n];
    std::fill_n(this->NumberOfPieces,n,0);
    
    this->BuildFunctions();
    this->Modified();
    }
}

void vtkPWConstantIT::SetNumberOfPieces(int i, int p)
{
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): setting pieces for function " << i << " to " << p); 
  this->DeleteFunction(i);
  this->NumberOfPieces[i]=p;
  this->BuildFunction(i);
  this->Modified();
}

int vtkPWConstantIT::GetNumberOfPieces(int i)
{
  return this->NumberOfPieces[i];
}

void vtkPWConstantIT::SetBoundary(int i,int j,int p)
{
  this->Boundaries[i][j]=p;
}

int vtkPWConstantIT::GetBoundary(int i,int j)
{
  return this->Boundaries[i][j];
}

void vtkPWConstantIT::SetValue(int i,int j,int p)
{
  this->Values[i][j]=p;
}

int vtkPWConstantIT::GetValue(int i,int j)
{
  return this->Values[i][j];
}

void vtkPWConstantIT::DeleteFunction(int i)
{
  if(this->Boundaries && this->Boundaries[i])
    {
    delete [] this->Boundaries[i];
    this->Boundaries[i]=0;
    }

  if(this->Values && this->Values[i])
    {
    delete [] this->Values[i];
    this->Values[i]=0;
    }
}

void vtkPWConstantIT::DeleteFunctions()
{
  for(int i=0;i<this->NumFuncs;++i)
    {
    this->DeleteFunction(i);
    }
  if(this->Boundaries)
    {
    delete [] this->Boundaries;
    }
  if(this->Values)
    {
    delete [] this->Values;
    }

  this->Boundaries=0;
  this->Values=0;
}

void vtkPWConstantIT::BuildFunction(int i)
{
  if(this->NumberOfPieces[i]>0)
    {
    this->Boundaries[i]=new int[this->NumberOfPieces[i]-1];
    this->Values[i]=new int[this->NumberOfPieces[i]];
    std::fill_n(this->Boundaries[i],this->NumberOfPieces[i]-1,0);
    std::fill_n(this->Values[i],this->NumberOfPieces[i],0);
    }
}

void vtkPWConstantIT::BuildFunctions()
{
  this->Boundaries=new int*[this->NumFuncs];
  std::fill_n(this->Boundaries,this->NumFuncs,(int*)0);

  this->Values=new int*[this->NumFuncs];
  std::fill_n(this->Values,this->NumFuncs,(int*)0);

  for(int i=0;i<this->NumFuncs;++i)
    {
    this->BuildFunction(i);
    }
}

void vtkPWConstantIT::PrintSelf(ostream& os, vtkIndent indent)
{
  //Modified by Liu
    int i;

  vtkIntensityTransform::PrintSelf(os, indent);
  os << indent << "NumberOfPieces: " << this->NumberOfPieces << " = ";

  //Modified by Liu
  //for(int i=0;i<this->NumFuncs;++i)
  for( i=0;i<this->NumFuncs;++i)
    {
    os << indent << this->NumberOfPieces[i] << " ";
    }
  os << "\n";
//Modified by Liu
  //for(int i=0;i<this->NumFuncs;++i)  
  for( i=0;i<this->NumFuncs;++i)
    {
    os << indent << "Boundaries[" << i << "]: " << this->Boundaries[i] << " = ";
    // Modified by Liu
    int j;
    //for(int j=0;j<this->NumberOfPieces[i]-1;++j)
    for( j=0;j<this->NumberOfPieces[i]-1;++j)
      {
      os << indent << this->Boundaries[i][j] << " ";
      }
    os << "\n";

    os << indent << "Values[" << i << "]: " << this->Values[i]<<" = ";
    //Modified by Liu
    //for(int j=0;j<this->NumberOfPieces[i];++j)
    for( j=0;j<this->NumberOfPieces[i];++j)
      {
      os << indent << this->Values[i][j] << " ";
      }
    os << "\n";
    }
}

int vtkPWConstantIT::FunctionValues(vtkFloatingPointType* x,vtkFloatingPointType* f)
{
  for(int i=0;i<this->NumFuncs;++i)
    {
    int const xx=int(*x++ + 0.5);
    int j;
    for(j=0;j<this->NumberOfPieces[i]-1;++j)
      {
      if(xx<this->Boundaries[i][j])
    {
    break;
    }
      }
    *f++=this->Values[i][j];
    }
  return 1;
}
