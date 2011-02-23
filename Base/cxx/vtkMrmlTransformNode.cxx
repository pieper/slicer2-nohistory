/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlTransformNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:49 $
  Version:   $Revision: 1.17 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlTransformNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlTransformNode* vtkMrmlTransformNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlTransformNode");
  if(ret)
  {
    return (vtkMrmlTransformNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlTransformNode;
}

//----------------------------------------------------------------------------
vtkMrmlTransformNode::vtkMrmlTransformNode()
{
  // vtkMrmlNode's attributes
  this->Indent = 1;

}

//----------------------------------------------------------------------------
vtkMrmlTransformNode::~vtkMrmlTransformNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlTransformNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Transform";

  // Strings
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }
  of << ">\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlTransformNode::Copy(vtkMrmlNode *node)
{
  vtkMrmlNode::MrmlNodeCopy(node);
}

//----------------------------------------------------------------------------
void vtkMrmlTransformNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
