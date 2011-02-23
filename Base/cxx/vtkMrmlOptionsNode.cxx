/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlOptionsNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:48 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "vtkMrmlOptionsNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlOptionsNode* vtkMrmlOptionsNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlOptionsNode");
  if(ret)
  {
    return (vtkMrmlOptionsNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlOptionsNode;
}

//----------------------------------------------------------------------------
vtkMrmlOptionsNode::vtkMrmlOptionsNode()
{
  // Strings
  this->Program = NULL;
  this->Contents = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlOptionsNode::~vtkMrmlOptionsNode()
{
  if (this->Program)
  {
    delete [] this->Program;
    this->Program = NULL;
  }
  if (this->Contents)
  {
    delete [] this->Contents;
    this->Contents = NULL;
  }
  if (this->Options)
  {
    delete [] this->Options;
    this->Options = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlOptionsNode::Write(ofstream& of, int nIndent)
{
  vtkIndent i1(nIndent);

  // Write all attributes not equal to their defaults
  
  of << i1 << "<Options";
  
  // Strings
  if (this->Program && strcmp(this->Program, "")) 
  {
    of << " program='" << this->Program << "'";
  }
  if (this->Contents && strcmp(this->Contents, "")) 
  {
    of << " contents='" << this->Contents << "'";
  }

  of << ">\n";

  if (this->Options && strcmp(this->Options, "")) 
  {
    of << this->Options;
  }

  of << "</Options>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlOptionsNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlOptionsNode *node = (vtkMrmlOptionsNode *) anode;

  // Strings
  this->SetOptions(node->Options);
}


//----------------------------------------------------------------------------
void vtkMrmlOptionsNode::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkObject::PrintSelf(os,indent);

  os << indent << "Name: " <<
    (this->Options ? this->Options : "(none)") << "\n";
}
