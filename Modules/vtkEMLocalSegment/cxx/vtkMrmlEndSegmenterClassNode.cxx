/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndSegmenterClassNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:32 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkMrmlEndSegmenterClassNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlEndSegmenterClassNode* vtkMrmlEndSegmenterClassNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlEndSegmenterClassNode");
  if(ret)
  {
    return (vtkMrmlEndSegmenterClassNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlEndSegmenterClassNode;
}

//----------------------------------------------------------------------------
vtkMrmlEndSegmenterClassNode::vtkMrmlEndSegmenterClassNode()
{
  // vtkMrmlNode's attributes
  this->Indent = -1;
}

//----------------------------------------------------------------------------
vtkMrmlEndSegmenterClassNode::~vtkMrmlEndSegmenterClassNode()
{
}

//----------------------------------------------------------------------------
void vtkMrmlEndSegmenterClassNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "</SegmenterClass>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlEndSegmenterClassNode::Copy(vtkMrmlNode *node)
{
  vtkMrmlNode::MrmlNodeCopy(node);
}

//----------------------------------------------------------------------------
void vtkMrmlEndSegmenterClassNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}
