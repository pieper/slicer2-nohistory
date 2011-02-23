/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAndPredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkAndPredicate.h"
#include <vtkObjectFactory.h>
#include <vtkCellArray.h>
#include <vtkPolyData.h>
#include <iostream>
#include <assert.h>

bool vtkAndPredicate::P(vtkFloatingPointType* x) 
{ 
  if(!LeftOperand->P(x)) 
    return false;
  else
    return RightOperand->P(x);
}

void vtkAndPredicate::InitP()
{
  if(LeftOperand==NULL || RightOperand==NULL) 
    return;
  LeftOperand->InitP();
  RightOperand->InitP();
}

// Description:
// Overload standard modified time function. If and is modified
// then this object is modified as well.
unsigned long vtkAndPredicate::GetMTime()
{
  unsigned long mTime=this->vtkPredicate::GetMTime();
  unsigned long OtherMTime;

  if ( this->LeftOperand != NULL )
    {
    OtherMTime = this->LeftOperand->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  if ( this->RightOperand != NULL )
    {
    OtherMTime = this->RightOperand->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  return mTime;
}


vtkAndPredicate* vtkAndPredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkAndPredicate")
;
  if(ret)
    {
    return (vtkAndPredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkAndPredicate;
}

void vtkAndPredicate::Delete()
{
  delete this;

}
void vtkAndPredicate::PrintSelf()
{

}

vtkAndPredicate::vtkAndPredicate()
{
  LeftOperand  = NULL;
  RightOperand = NULL;
}

vtkAndPredicate::~vtkAndPredicate()
{
  LeftOperand->Delete();
  RightOperand->Delete();
}

vtkAndPredicate::vtkAndPredicate(vtkAndPredicate&)
{

}

void vtkAndPredicate::operator=(const vtkAndPredicate)
{

}
