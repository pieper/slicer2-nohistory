/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterCIMNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:33 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkMrmlSegmenterCIMNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterCIMNode* vtkMrmlSegmenterCIMNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterCIMNode");
  if(ret)
  {
    return (vtkMrmlSegmenterCIMNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterCIMNode;
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterCIMNode::Write(ofstream& of, int nIndent)
{
  
  vtkIndent i1(nIndent);

  of << i1 << "<SegmenterCIM";
  this->vtkMrmlSegmenterAtlasCIMNode::Write(of);
  of << "></SegmenterCIM>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterCIMNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  this->vtkMrmlSegmenterAtlasCIMNode::Copy(anode);
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterCIMNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);
  vtkMrmlSegmenterAtlasCIMNode::PrintSelf(os,indent);
}


