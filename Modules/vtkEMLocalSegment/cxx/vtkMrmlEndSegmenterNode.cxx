/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndSegmenterNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:32 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlEndSegmenterNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndSegmenterNode* vtkMrmlEndSegmenterNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndSegmenterNode");
  if(ret)
  {
    return (vtkMrmlEndSegmenterNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndSegmenterNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndSegmenterNode::vtkMrmlEndSegmenterNode()
{
  // vtkMrmlNode's attributes
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndSegmenterNode::~vtkMrmlEndSegmenterNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndSegmenterNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</Segmenter>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlEndSegmenterNode::Copy(vtkMrmlNode *node)
{
  vtkMrmlNode::MrmlNodeCopy(node);
}

//----------------------------------------------------------------------------
void vtkMrmlEndSegmenterNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
