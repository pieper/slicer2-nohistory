/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPolynomialIT.cxx,v $
  Date:      $Date: 2006/01/06 17:57:12 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkPolynomialIT.h"
#include "vtkObjectFactory.h"

#include <algorithm>

vtkPolynomialIT* vtkPolynomialIT::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPolynomialIT");
  if(ret)
    {
    return (vtkPolynomialIT*)ret;
    }
  // If the factory was unable to create the object, then create it here.
    return new vtkPolynomialIT;
}

vtkPolynomialIT::vtkPolynomialIT()
{
  this->NumIndepVars = 1;
  this->Degree=1;
  this->Alphas=0;
}

vtkPolynomialIT::~vtkPolynomialIT()
{
  if (this->Alphas!=0)
    {
    this->DeleteAlphas();
    }
}

void vtkPolynomialIT::DeleteAlphas()
{
  for(int i=0;i<this->NumFuncs;++i)
    {
    delete [] this->Alphas[i];
    }
  delete [] this->Alphas;
  this->Alphas=0;
}

void vtkPolynomialIT::BuildAlphas()
{
  this->Alphas=new float*[this->NumFuncs];
  for(int i=0;i<this->NumFuncs;++i)
    {
    this->Alphas[i]=new float[this->Degree+1];
    std::fill_n(this->Alphas[i],this->Degree+1,0);
    }
}

void vtkPolynomialIT::SetNumberOfFunctions(int n)
{
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): setting NumFuncs to " << n); 
  if(this->NumFuncs!=n)
    {
    this->DeleteAlphas();
    this->NumFuncs=n;
    this->BuildAlphas();
    this->Modified();
    }
}

void vtkPolynomialIT::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkIntensityTransform::PrintSelf(os, indent);
  os << indent << "Degree: " << this->GetDegree() << "\n";

  os << indent << "Alphas: " << this->Alphas << "\n";
  for(int i=0;i<this->NumFuncs;++i)
    {
    os << indent << "Alphas[" << i << "]: " << this->Alphas[i]<<" = ";
    for(int j=0;j<=this->Degree;++j)
      {
      os << indent << this->Alphas[i][j] << " ";
      }
    os << "\n";
    }
}

void vtkPolynomialIT::SetAlpha(int i, int j, float v)
{
  if(i>=this->NumFuncs)
    {
    vtkErrorMacro(<<"i larger than number of functions: "<<i);
    }
  if(j>this->Degree)
    {
    vtkErrorMacro(<<"j larger than number of degrees: "<<j);
    }
  if (this->Alphas[i][j] == v)
    {
    return;
    }
  this->Alphas[i][j]=v;
  this->Modified(); 
} 

float vtkPolynomialIT::GetAlpha(int i, int j)
{
  if(i>=this->NumFuncs)
    {
    vtkErrorMacro(<<"i larger than number of functions: "<<i);
    }
  if(j>this->Degree)
    {
    vtkErrorMacro(<<"j larger than number of degrees: "<<j);
    }
  return this->Alphas[i][j];
}

void vtkPolynomialIT::SetDegree(int d)
{
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): setting Degree to " << d); 
  if (this->Degree != d) 
    {
    this->DeleteAlphas();
    this->Degree = d;
    this->BuildAlphas();
    this->Modified(); 
    } 
} 

int vtkPolynomialIT::FunctionValues(vtkFloatingPointType* x,vtkFloatingPointType* f)
{
  for(int i=0;i<this->NumFuncs;++i)
    {
    float const xx=*x++;
    float xxx=xx;
    float res=this->Alphas[i][0];
    for(int j=1;j<=this->Degree;++j)
      {
      res += this->Alphas[i][j]*xxx;
      xxx *= xx;
      }
    *f++=res;
    }
  return 1;
}
