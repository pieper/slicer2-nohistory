/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntensityTransform.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#include "vtkIntensityTransform.h"

vtkIntensityTransform::vtkIntensityTransform() 
{
  this->Target=0;
  this->Source=0;
  this->Mask=0;
  this->UpdateMutex = vtkSimpleMutexLock::New();
}

vtkIntensityTransform::~vtkIntensityTransform()
{
  if(this->Target)
    {
    this->Target->Delete();
    }
  if(this->Source)
    {
    this->Source->Delete();
    }
  if(this->Mask)
    {
    this->Mask->Delete();
    }
  if (this->UpdateMutex)
    {
    this->UpdateMutex->Delete();
    }
}

void vtkIntensityTransform::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkFunctionSet::PrintSelf(os,indent);

  os << indent << "Target: " << this->Target << "\n";
  if(this->Target)
    {
    this->Target->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "Source: " << this->Source << "\n";
  if(this->Source)
    {
    this->Source->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "Mask: " << this->Mask << "\n";
  if(this->Mask)
    {
    this->Mask->PrintSelf(os,indent.GetNextIndent());
    }
}

void vtkIntensityTransform::Update()
{
  // locking is require to ensure that the class is thread-safe
  this->UpdateMutex->Lock();

  // update inputs
  if(this->Target)
    {
    this->Target->Update();
    }
  if(this->Source)
    {
    this->Source->Update();
    }
  if(this->Mask)
    {
    this->Mask->Update();
    }
  
  if (this->GetMTime() >= this->UpdateTime.GetMTime() ||
      (this->Target &&
       this->Target->GetMTime() >= this->UpdateTime.GetMTime()) ||
      (this->Source &&
       this->Source->GetMTime() >= this->UpdateTime.GetMTime()) ||
      (this->Mask &&
       this->Mask->GetMTime() >= this->UpdateTime.GetMTime()))
    {
    // do internal update for subclass
    vtkDebugMacro("Calling InternalUpdate on the transformation");
    this->InternalUpdate();
    }

  this->UpdateTime.Modified();
  this->UpdateMutex->Unlock();
}
