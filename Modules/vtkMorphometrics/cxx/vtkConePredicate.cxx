/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkConePredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkConePredicate.h"
#include <vtkObjectFactory.h>
#include <vtkCellArray.h>
#include <vtkPolyData.h>
#include <vtkMath.h>
#include <iostream>


unsigned long vtkConePredicate::GetMTime()
{
  unsigned long mTime=this->vtkPredicate::GetMTime();
  unsigned long OtherMTime;

  if ( this->Axis != NULL )
    {
    OtherMTime = this->Axis->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  return mTime;
}

bool vtkConePredicate::P(vtkFloatingPointType* x) 
{ 
  for(int i =0;i<3;i++)
    {
      DiffVector[i] = x[i] - Axis->GetCenter()[i];
    }
  
  vtkFloatingPointType Angle = Axis->Angle(DiffVector);

  return Angle <= MaximalAngle;
}

void vtkConePredicate::InitP()
{
}

vtkConePredicate* vtkConePredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkConePredicate")
;
  if(ret)
    {
    return (vtkConePredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkConePredicate;
}

void vtkConePredicate::Delete()
{
  delete this;

}
void vtkConePredicate::PrintSelf()
{

}

vtkConePredicate::vtkConePredicate()
{
  Axis = NULL;
  MaximalAngle=45;
  DiffVector = (vtkFloatingPointType*)malloc(3*sizeof(vtkFloatingPointType));
}

vtkConePredicate::~vtkConePredicate()
{
  free(DiffVector);
}
