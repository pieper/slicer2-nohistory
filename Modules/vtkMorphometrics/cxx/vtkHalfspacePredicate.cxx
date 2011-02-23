/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkHalfspacePredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkHalfspacePredicate.h"
#include <vtkObjectFactory.h>
#include <vtkCellArray.h>
#include <vtkPolyData.h>
#include <iostream>
#include <assert.h>

bool vtkHalfspacePredicate::P(vtkFloatingPointType* x) 
{ 
  return p <= vtkMath::Dot(Normal,x);
}

void vtkHalfspacePredicate::InitP()
{
  Normal[0] = Halfspace->GetNormal()[0];
  Normal[1] = Halfspace->GetNormal()[1];
  Normal[2] = Halfspace->GetNormal()[2];

  Origin[0] = Halfspace->GetCenter()[0];
  Origin[1] = Halfspace->GetCenter()[1];
  Origin[2] = Halfspace->GetCenter()[2];
  
  p = vtkMath::Dot(Normal,Origin);
 
}

void vtkHalfspacePredicate::SetPlane(vtkPlaneSource* v)
{
  Halfspace = v;
  if(v!=NULL)
    Modified();
}

// Description:
// Overload standard modified time function. If Halfspace is modified
// then this object is modified as well.
unsigned long vtkHalfspacePredicate::GetMTime()
{
  unsigned long mTime=this->vtkPredicate::GetMTime();
  unsigned long OtherMTime;

  if ( this->Halfspace != NULL )
    {
    OtherMTime = this->Halfspace->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  return mTime;
}


vtkHalfspacePredicate* vtkHalfspacePredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkHalfspacePredicate")
;
  if(ret)
    {
    return (vtkHalfspacePredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkHalfspacePredicate;
}

void vtkHalfspacePredicate::Delete()
{
  delete this;

}

void vtkHalfspacePredicate::PrintSelf()
{

}

vtkHalfspacePredicate::vtkHalfspacePredicate()
{

  Halfspace = NULL;
  Normal = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
  Origin = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
}

vtkHalfspacePredicate::~vtkHalfspacePredicate()
{
  free(Normal);
  free(Origin);
}

vtkHalfspacePredicate::vtkHalfspacePredicate(vtkHalfspacePredicate&)
{

}

void vtkHalfspacePredicate::operator=(const vtkHalfspacePredicate)
{

}
