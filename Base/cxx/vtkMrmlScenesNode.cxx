/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlScenesNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:48 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlScenesNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlScenesNode* vtkMrmlScenesNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlScenesNode");
  if(ret)
  {
    return (vtkMrmlScenesNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlScenesNode;
}

//----------------------------------------------------------------------------
vtkMrmlScenesNode::vtkMrmlScenesNode()
{
  this->Indent = 1;
  
  // Strings
  this->Lang = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlScenesNode::~vtkMrmlScenesNode()
{
  if (this->Lang)
  {
    delete [] this->Lang;
    this->Lang = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlScenesNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Scenes";

  // Strings
  if (this->Lang && strcmp(this->Lang, ""))
  {
    of << " lang='" << this->Lang << "'";
  }
  if (this->Name && strcmp(this->Name, ""))
  {
    of << " name='" << this->Name << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }
  
  of << ">\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlScenesNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlScenesNode *node = (vtkMrmlScenesNode *) anode;

  // Strings
  this->SetDescription(node->Description);
  this->SetLang(node->Lang);
}

//----------------------------------------------------------------------------
void vtkMrmlScenesNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "Name: " << 
    (this->Name ? this->Name : "(none)") << "\n";
  os << indent << "Description: " <<
    (this->Description ? this->Description : "(none)") << "\n";  
  os << indent << "Lang: " <<
    (this->Lang ? this->Lang : "(none)") << "\n";
}
