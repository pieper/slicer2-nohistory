/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistancePredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkDistancePredicate.h"
#include <vtkObjectFactory.h>
#include <vtkCellArray.h>
#include <vtkPolyData.h>
#include <iostream>
#include <assert.h>

unsigned long vtkDistancePredicate::GetMTime()
{
  unsigned long mTime=this->vtkPredicate::GetMTime();
  unsigned long OtherMTime;

  if ( this->Hull != NULL )
    {
    OtherMTime = this->Hull->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  return mTime;
}


bool vtkDistancePredicate::P(vtkFloatingPointType* x) 
{ 
  if(!OnlyInside || Hull->Inside(x))
    {
      return Hull->DistanceFromConvexHull(x) <= MaximalDistance;
    }
  return false;
}

void vtkDistancePredicate::InitP()
{
}

vtkDistancePredicate* vtkDistancePredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDistancePredicate")
;
  if(ret)
    {
    return (vtkDistancePredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkDistancePredicate;
}

void vtkDistancePredicate::Delete()
{
  delete this;

}

vtkDistancePredicate::vtkDistancePredicate()
{
  Hull = NULL;
  OnlyInside=true;
  MaximalDistance=1;
}

vtkDistancePredicate::~vtkDistancePredicate()
{
}

vtkDistancePredicate::vtkDistancePredicate(vtkDistancePredicate&)
{

}

void vtkDistancePredicate::operator=(const vtkDistancePredicate)
{

}
