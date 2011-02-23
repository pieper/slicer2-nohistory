/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndModelGroupNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:46 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlEndModelGroupNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndModelGroupNode* vtkMrmlEndModelGroupNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndModelGroupNode");
  if(ret)
  {
    return (vtkMrmlEndModelGroupNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndModelGroupNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndModelGroupNode::vtkMrmlEndModelGroupNode()
{
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndModelGroupNode::~vtkMrmlEndModelGroupNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndModelGroupNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</ModelGroup>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlEndModelGroupNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlEndModelGroupNode *node = (vtkMrmlEndModelGroupNode *) anode;
}

//----------------------------------------------------------------------------
void vtkMrmlEndModelGroupNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
