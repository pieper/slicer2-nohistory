/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPredicate.cxx,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkPredicate.h"
#include <vtkObjectFactory.h>
#include <iostream>
#include <assert.h>

bool vtkPredicate::P(vtkFloatingPointType* x)
{
  return true;
}

void vtkPredicate::InitP()
{
  cerr<<"vtkPredicate::InitP"<<endl;
}

vtkPredicate* vtkPredicate::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPredicate")
;
  if(ret)
    {
    return (vtkPredicate*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkPredicate;
}

void vtkPredicate::Delete()
{
  delete this;

}
void vtkPredicate::PrintSelf()
{

}

vtkPredicate::vtkPredicate()
{
}

vtkPredicate::~vtkPredicate()
{
}

vtkPredicate::vtkPredicate(vtkPredicate&)
{

}

void vtkPredicate::operator=(const vtkPredicate)
{

}
