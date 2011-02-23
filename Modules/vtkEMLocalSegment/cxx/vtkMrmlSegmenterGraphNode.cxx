/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterGraphNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:33 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterGraphNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterGraphNode* vtkMrmlSegmenterGraphNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterGraphNode");
  if(ret)
  {
    return (vtkMrmlSegmenterGraphNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterGraphNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterGraphNode::vtkMrmlSegmenterGraphNode()
{
  this->Indent = 0;
  this->Xmin   = 0;
  this->Xmax   = 0; 
  this->Xsca   = 1;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterGraphNode::~vtkMrmlSegmenterGraphNode()
{

}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterGraphNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<SegmenterGraph";
  
  if (this->Name && strcmp(this->Name, ""))  {
    of << " name ='" << this->Name << "'";
  }
  of << " Xmin ='" << this->Xmin << "'";
  of << " Xmax ='" << this->Xmax << "'";
  of << " Xsca ='" << this->Xsca << "'";
  of << "></SegmenterGraph>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterGraphNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlSegmenterGraphNode *node = (vtkMrmlSegmenterGraphNode *) anode;

  this->Xmin   = node->Xmin;
  this->Xmax   = node->Xmax; 
  this->Xsca   = node->Xsca;
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterGraphNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);
  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
  os << indent << " Xmin: " << this->Xmin << "\n"; 
  os << indent << " Xmax: " << this->Xmax << "\n"; 
  os << indent << " Xsca: " << this->Xsca << "\n"; 
}


