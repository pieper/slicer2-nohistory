/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndScenesNode.cxx,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlEndScenesNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndScenesNode* vtkMrmlEndScenesNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndScenesNode");
  if(ret)
  {
    return (vtkMrmlEndScenesNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndScenesNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndScenesNode::vtkMrmlEndScenesNode()
{
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndScenesNode::~vtkMrmlEndScenesNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndScenesNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</Scenes>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlEndScenesNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);

}

//----------------------------------------------------------------------------
void vtkMrmlEndScenesNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
