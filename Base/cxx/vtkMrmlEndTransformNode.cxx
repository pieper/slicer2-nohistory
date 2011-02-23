/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndTransformNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:46 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlEndTransformNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndTransformNode* vtkMrmlEndTransformNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndTransformNode");
  if(ret)
  {
    return (vtkMrmlEndTransformNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndTransformNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndTransformNode::vtkMrmlEndTransformNode()
{
  // vtkMrmlNode's attributes
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndTransformNode::~vtkMrmlEndTransformNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndTransformNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</Transform>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlEndTransformNode::Copy(vtkMrmlNode *node)
{
  vtkMrmlNode::MrmlNodeCopy(node);
}

//----------------------------------------------------------------------------
void vtkMrmlEndTransformNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
