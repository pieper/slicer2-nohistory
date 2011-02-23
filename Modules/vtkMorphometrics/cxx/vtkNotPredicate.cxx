/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkNotPredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkNotPredicate.h"
#include <vtkObjectFactory.h>
#include <vtkCellArray.h>
#include <vtkPolyData.h>
#include <iostream>
#include <assert.h>

bool vtkNotPredicate::P(vtkFloatingPointType* x) 
{ 
  return !Operand->P(x);
}

void vtkNotPredicate::InitP()
{
  if(Operand==NULL)
    return;
  Operand->InitP();
}

// Description:
// Overload standard modified time function. If and is modified
// then this object is modified as well.
unsigned long vtkNotPredicate::GetMTime()
{
  unsigned long mTime=this->vtkPredicate::GetMTime();
  unsigned long OtherMTime;

  if ( this->Operand != NULL )
    {
    OtherMTime = this->Operand->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  return mTime;
}


vtkNotPredicate* vtkNotPredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkNotPredicate")
;
  if(ret)
    {
    return (vtkNotPredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkNotPredicate;
}

void vtkNotPredicate::Delete()
{
  delete this;

}
void vtkNotPredicate::PrintSelf()
{

}

vtkNotPredicate::vtkNotPredicate()
{
  Operand = NULL;
}

vtkNotPredicate::~vtkNotPredicate()
{
  if(Operand!=NULL)
    Operand->Delete();
}

vtkNotPredicate::vtkNotPredicate(vtkNotPredicate&)
{

}

void vtkNotPredicate::operator=(const vtkNotPredicate)
{

}
