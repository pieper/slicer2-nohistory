/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlHierarchyNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:47 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlHierarchyNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlHierarchyNode* vtkMrmlHierarchyNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlHierarchyNode");
  if(ret)
  {
    return (vtkMrmlHierarchyNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlHierarchyNode;
}

//----------------------------------------------------------------------------
vtkMrmlHierarchyNode::vtkMrmlHierarchyNode()
{
  this->Indent = 1;
  
  // Strings
  this->HierarchyID = NULL;
  this->Type = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlHierarchyNode::~vtkMrmlHierarchyNode()
{
  if (this->HierarchyID)
  {
    delete [] this->HierarchyID;
    this->HierarchyID = NULL;
  }
  if (this->Type)
  {
    delete [] this->Type;
    this->Type = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlHierarchyNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Hierarchy";

  // Strings
  if (this->HierarchyID && strcmp(this->HierarchyID, ""))
  {
    of << " id='" << this->HierarchyID << "'";
  }
  if (this->Type && strcmp(this->Type, "")) 
  {
    of << " type='" << this->Type << "'";
  }
  
  of << ">\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlHierarchyNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlHierarchyNode *node = (vtkMrmlHierarchyNode *) anode;

  // Strings
  this->SetHierarchyID(node->HierarchyID);
  this->SetType(node->Type);
}

//----------------------------------------------------------------------------
void vtkMrmlHierarchyNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "HierarchyID: " << 
    (this->HierarchyID ? this->HierarchyID : "(node)") << "\n";
  os << indent << "Type: " <<
    (this->Type ? this->Type : "(none)") << "\n";  
}
