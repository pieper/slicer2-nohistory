/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWarpForce.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkImageWarpForce.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"

vtkImageWarpForce* vtkImageWarpForce::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageWarpForce");
  if(ret)
    {
    return (vtkImageWarpForce*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageWarpForce;
}

vtkImageWarpForce::vtkImageWarpForce()
{
  this->NumberOfRequiredInputs = 2;
}

vtkImageWarpForce::~vtkImageWarpForce()
{
}

//----------------------------------------------------------------------------
// The output extent is the intersection.
void vtkImageWarpForce::ExecuteInformation(vtkImageData **inDatas, 
                       vtkImageData *outData)
{
  vtkDebugMacro("ExecuteInformation");
  vtkImageMultipleInputFilter::ExecuteInformation(inDatas,outData);

  outData->SetScalarType(VTK_FLOAT);
  outData->SetNumberOfScalarComponents(3);
}

vtkImageData* vtkImageWarpForce::GetTarget()
{
  if (this->NumberOfInputs < 1)
    {
    return 0;
    }

  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Target of "
        << this->Inputs[0]);
  return (vtkImageData *)(this->Inputs[0]);
}

vtkImageData* vtkImageWarpForce::GetSource()
{
  if (this->NumberOfInputs < 2)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Source of "
        << this->Inputs[1]);
  return (vtkImageData *)(this->Inputs[1]);
}

vtkImageData* vtkImageWarpForce::GetDisplacement()
{
  if (this->NumberOfInputs < 3)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Displacement of "
        << this->Inputs[2]);
  return (vtkImageData *)(this->Inputs[2]);
}

vtkImageData* vtkImageWarpForce::GetMask()
{
  if (this->NumberOfInputs < 4)
    {
    return 0;
    }
  
  vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning Mask of "
        << this->Inputs[3]);
  return (vtkImageData *)(this->Inputs[3]);
}

void vtkImageWarpForce::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkImageMultipleInputFilter::PrintSelf(os,indent);
}
