/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlData.cxx,v $
  Date:      $Date: 2006/03/06 19:02:26 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
#include <stdio.h>
#include "vtkVersion.h"
#include "vtkCommand.h"
#include "vtkMrmlData.h"
#include "vtkObjectFactory.h"
#include "vtkImageReader.h"
#include "vtkImageWriter.h"
#include <time.h>

//------------------------------------------------------------------------------
vtkMrmlData* vtkMrmlData::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlData");
  if(ret)
    {
    return (vtkMrmlData*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return NULL;
}

//----------------------------------------------------------------------------
vtkMrmlData::vtkMrmlData()
{
  // Objects that should be set by the user, but can be self-created
  this->MrmlNode = NULL;
  this->LabelIndirectLUT = NULL;
  this->IndirectLUT = vtkIndirectLookupTable::New();
  this->UseLabelIndirectLUT = 0;
  
  this->ProcessObject = NULL;
  this->NeedToWriteOff();
}

//----------------------------------------------------------------------------
vtkMrmlData::~vtkMrmlData()
{
  // Delete if self-created or if no one else is using it
  if (this->MrmlNode != NULL)
  {
    this->MrmlNode->UnRegister(this);
  }
  if (this->LabelIndirectLUT != NULL)
  {
    this->LabelIndirectLUT->UnRegister(this);
  }
  if (this->IndirectLUT != NULL)
    {
      this->IndirectLUT->Delete();
    }
}

//----------------------------------------------------------------------------
void vtkMrmlData::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkProcessObject::PrintSelf(os, indent);

  os << indent << "UseLabelIndirectLUT: " << this->UseLabelIndirectLUT << endl;
  os << indent << "MrmlNode: " << this->MrmlNode << "\n";

  if (this->MrmlNode)
  {
    this->MrmlNode->PrintSelf(os,indent.GetNextIndent());
  }

  os << indent << "LabelIndirectLUT: " << this->LabelIndirectLUT << "\n";
  if (this->LabelIndirectLUT)
  {
    this->LabelIndirectLUT->PrintSelf(os,indent.GetNextIndent());
  }
}

//----------------------------------------------------------------------------

void vtkMrmlData::CopyNode(vtkMrmlData *MrmlData)
{
  this->GetMrmlNode()->Copy(MrmlData->GetMrmlNode());
}

//----------------------------------------------------------------------------
// Determine the modified time of this object
unsigned long int vtkMrmlData::GetMTime()
{
  unsigned long result, t;

  result = vtkObject::GetMTime();
 
  // MrmlNode
  if (this->MrmlNode)
  {
    t = this->MrmlNode->GetMTime(); 
    result = (t > result) ? t : result;
  }

  // For whatever reason, we currently don't check 
  // If maby a lookup table was set directly. I don't know why...
 
  // LabelIndirectLUT 
  if (this->UseLabelIndirectLUT && this->LabelIndirectLUT)
  {
    t = this->LabelIndirectLUT->GetMTime(); 
    result = (t > result) ? t : result;
  }

  return result;
}

//----------------------------------------------------------------------------

int vtkMrmlData::Write() {
  vtkErrorMacro("The Programmer Did not Specify \"Write\" for this type of vtkMrmlData");
  return 0;
};
int vtkMrmlData::Read() {
  vtkErrorMacro("The Programmer Did not Specify \"Read\" for this type of vtkMrmlData");
  return 0;
};
vtkDataObject *vtkMrmlData::GetOutput() {
  vtkErrorMacro("The Programmer Did not Specify \"GetOutput\" for this type of vtkMrmlData");
  return NULL;
};


//----------------------------------------------------------------------------
// If the user has not set the Mrmlnode, then create one.
// This function should be implemented in the actual classes
void vtkMrmlData::CheckMrmlNode()
{
  vtkErrorMacro("The Programmer Did not Specify \"CheckMrmlNode\" for this type of vtkMrmlData");

//  Example of the type of thing that should appear here:
//  if (this->MrmlNode == NULL)
//  {
//    // This next line should be specific to the lower function.
//    this->MrmlNode = vtkMrmlNode::New();
//    this->MrmlNode->Register(this);
//    this->MrmlNode->Delete();
//  }
}

//----------------------------------------------------------------------------
void vtkMrmlData::CheckLabelIndirectLUT()
{
  if (this->LabelIndirectLUT == NULL)
  {
    this->LabelIndirectLUT = vtkIndirectLookupTable::New();
    this->LabelIndirectLUT->Register(this);
    this->LabelIndirectLUT->Delete();
  }
}

//----------------------------------------------------------------------------
void vtkMrmlData::Update()
{
  
  // We really should have an Update time that we compare with the
  // MTime, but since the other objects inside this class do this, 
  // its alright.

  // Create objects that the user hasn't already set
  this->CheckMrmlNode();
  this->CheckLabelIndirectLUT();
}

//----------------------------------------------------------------------------
void vtkMrmlData::ProgressCallbackFunction(vtkObject* caller,
                                              unsigned long,
                                              void* clientdata, void*)
{
  vtkMrmlData *self = (vtkMrmlData *)(clientdata);
#if (VTK_MAJOR_VERSION >= 5)
  vtkAlgorithm *obj = self->GetProcessObject();
#else
  vtkProcessObject *obj = self->GetProcessObject();
#endif

  if (obj)
  {
    self->UpdateProgress(obj->GetProgress());
  }
}

//----------------------------------------------------------------------------
vtkIndirectLookupTable* vtkMrmlData::GetIndirectLUT()
{
  if (this->UseLabelIndirectLUT) 
  {
    return this->LabelIndirectLUT;
  }
  return this->IndirectLUT;
}

