/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlWindowLevelNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:50 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlWindowLevelNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlWindowLevelNode* vtkMrmlWindowLevelNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlWindowLevelNode");
  if(ret)
  {
    return (vtkMrmlWindowLevelNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlWindowLevelNode;
}

//----------------------------------------------------------------------------
vtkMrmlWindowLevelNode::vtkMrmlWindowLevelNode()
{
  // Numbers
  this->AutoWindowLevel = 1;
  this->Window = 256;
  this->Level = 128;
  this->ApplyThreshold = 0;
  this->AutoThreshold = 0;
  this->LowerThreshold = -32768;
  this->UpperThreshold = 32767;
}

//----------------------------------------------------------------------------
vtkMrmlWindowLevelNode::~vtkMrmlWindowLevelNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlWindowLevelNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<WindowLevel";
  
  // Numbers
  if (this->AutoWindowLevel != 1)
  {
    of << " autoWindowLevel='" << (this->AutoWindowLevel ? "true":"false") << "'";
  }
  if (this->Window != 256)
  {
    of << " window='" << this->Window << "'";
  }
  if (this->Level != 128)
  {
    of << " level='" << this->Level << "'";
  }
  if (this->ApplyThreshold != 0)
  {
    of << " applyThreshold='" << (this->ApplyThreshold ? "true":"false") << "'";
  }
  if (this->AutoThreshold != 0)
  {
    of << " autoThreshold='" << (this->AutoThreshold ? "true":"false") << "'";
  }
  if (this->LowerThreshold != -32768)
  {
    of << " lowerThreshold='" << this->LowerThreshold << "'";
  }
  if (this->UpperThreshold != 32767)
  {
    of << " upperThreshold='" << this->UpperThreshold << "'";
  }
  
  of << "></WindowLevel>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
void vtkMrmlWindowLevelNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlWindowLevelNode *node = (vtkMrmlWindowLevelNode *) anode;

  // Numbers
  this->SetWindow(node->Window);
  this->SetLevel(node->Level);
  this->SetLowerThreshold(node->LowerThreshold);
  this->SetUpperThreshold(node->UpperThreshold);
  this->SetAutoWindowLevel(node->AutoWindowLevel);
  this->SetApplyThreshold(node->ApplyThreshold);
  this->SetAutoThreshold(node->AutoThreshold);
}

//----------------------------------------------------------------------------
void vtkMrmlWindowLevelNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "AutoWindowLevel: " << this->AutoWindowLevel << "\n";
  os << indent << "Window: " << this->Window << "\n";
  os << indent << "Level: " << this->Level << "\n";
  os << indent << "ApplyThreshold: " << this->ApplyThreshold << "\n";
  os << indent << "AutoThreshold: " << this->AutoThreshold << "\n";
  os << indent << "Lower threshold: " << this->LowerThreshold << "\n";
  os << indent << "Upper threshold: " << this->UpperThreshold << "\n";
}
