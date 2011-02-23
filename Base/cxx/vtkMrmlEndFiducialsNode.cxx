/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndFiducialsNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:46 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlEndFiducialsNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndFiducialsNode* vtkMrmlEndFiducialsNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndFiducialsNode");
  if(ret)
  {
    return (vtkMrmlEndFiducialsNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndFiducialsNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndFiducialsNode::vtkMrmlEndFiducialsNode()
{
  // vtkMrmlNode's attributes
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndFiducialsNode::~vtkMrmlEndFiducialsNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndFiducialsNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</Fiducials>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlEndFiducialsNode::Copy(vtkMrmlNode *node)
{
  vtkMrmlNode::MrmlNodeCopy(node);
}

//----------------------------------------------------------------------------
void vtkMrmlEndFiducialsNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
