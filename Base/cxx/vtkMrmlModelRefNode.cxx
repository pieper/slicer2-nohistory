/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModelRefNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:47 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlModelRefNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlModelRefNode* vtkMrmlModelRefNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlModelRefNode");
  if(ret)
  {
    return (vtkMrmlModelRefNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlModelRefNode;
}

//----------------------------------------------------------------------------
vtkMrmlModelRefNode::vtkMrmlModelRefNode()
{
  // Strings
  this->ModelRefID = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlModelRefNode::~vtkMrmlModelRefNode()
{
  if (this->ModelRefID)
  {
    delete [] this->ModelRefID;
    this->ModelRefID = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlModelRefNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<ModelRef";

  // Strings
  if (this->ModelRefID && strcmp(this->ModelRefID, "")) 
  {
    of << " ModelRefID='" << this->ModelRefID << "'";
  }
  
  of << "></ModelRef>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlModelRefNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlModelRefNode *node = (vtkMrmlModelRefNode *) anode;

  // Strings
  this->SetModelRefID(node->ModelRefID);
  
}

//----------------------------------------------------------------------------
void vtkMrmlModelRefNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "ModelRefID: " <<
    (this->ModelRefID ? this->ModelRefID : "(none)") << "\n";  
}
