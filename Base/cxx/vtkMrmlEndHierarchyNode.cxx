/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndHierarchyNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:46 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlEndHierarchyNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndHierarchyNode* vtkMrmlEndHierarchyNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndHierarchyNode");
  if(ret)
  {
    return (vtkMrmlEndHierarchyNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndHierarchyNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndHierarchyNode::vtkMrmlEndHierarchyNode()
{
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndHierarchyNode::~vtkMrmlEndHierarchyNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndHierarchyNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</Hierarchy>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlEndHierarchyNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlEndHierarchyNode *node = (vtkMrmlEndHierarchyNode *) anode;

}

//----------------------------------------------------------------------------
void vtkMrmlEndHierarchyNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
