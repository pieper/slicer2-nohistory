/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistanceSpherePredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkDistanceSpherePredicate.h"
#include <vtkObjectFactory.h>

unsigned long vtkDistanceSpherePredicate::GetMTime()
{
  unsigned long mTime=this->vtkPredicate::GetMTime();
  unsigned long OtherMTime;

  if ( this->Sphere != NULL )
    {
    OtherMTime = this->Sphere->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  return mTime;
}


bool vtkDistanceSpherePredicate::P(vtkFloatingPointType* x) 
{ 
  vtkFloatingPointType d = 0;
  for(int i =0;i<3;i++)
    d += (x[i] - Sphere->GetCenter()[i])*(x[i] - Sphere->GetCenter()[i]);
  d = sqrt(d);

  if(!OnlyInside || d < Sphere->GetRadius())
    {
      return fabs(d - Sphere->GetRadius()) <= MaximalDistance;
    }
  return false;
}

void vtkDistanceSpherePredicate::InitP()
{
}

vtkDistanceSpherePredicate* vtkDistanceSpherePredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDistanceSpherePredicate")
;
  if(ret)
    {
    return (vtkDistanceSpherePredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkDistanceSpherePredicate;
}

void vtkDistanceSpherePredicate::Delete()
{
  delete this;

}
void vtkDistanceSpherePredicate::PrintSelf()
{

}

vtkDistanceSpherePredicate::vtkDistanceSpherePredicate()
{
  Sphere = NULL;
  OnlyInside=true;
  MaximalDistance=1;
}

vtkDistanceSpherePredicate::~vtkDistanceSpherePredicate()
{
}

