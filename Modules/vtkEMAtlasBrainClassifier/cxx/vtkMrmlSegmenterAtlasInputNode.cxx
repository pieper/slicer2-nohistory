/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasInputNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:30 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterAtlasInputNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterAtlasInputNode* vtkMrmlSegmenterAtlasInputNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterAtlasInputNode");
  if(ret)
  {
    return (vtkMrmlSegmenterAtlasInputNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterAtlasInputNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasInputNode::vtkMrmlSegmenterAtlasInputNode()
{
  this->FileName = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasInputNode::~vtkMrmlSegmenterAtlasInputNode()
{
  if (this->FileName)
  {
    delete [] this->FileName;
    this->FileName = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasInputNode::Write(ofstream& of)
{
  // Write all attributes not equal to their defaults
  
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name ='" << this->Name << "'";
  }
  if (this->FileName && strcmp(this->FileName, "")) 
  {
    of << " FileName='" << this->FileName << "'";
  }
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterAtlasInputNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlSegmenterAtlasInputNode *node = (vtkMrmlSegmenterAtlasInputNode *) anode;
  this->SetFileName(node->FileName); 
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasInputNode::PrintSelf(ostream& os, vtkIndent indent)
{
   os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
   os << indent << "FileName: " <<
    (this->FileName ? this->FileName : "(none)") << "\n";
}

/* 
  this->IntensityAvgValuePreDef = 0;

  vtkIndent i1(nIndent);
  of << i1 << "<SegmenterInput";
  of << " IntensityAvgValuePreDef ='"    << this->IntensityAvgValuePreDef << "'";
  of << "></SegmenterInput>\n";

  vtkMrmlNode::MrmlNodeCopy(anode);
  this->IntensityAvgValuePreDef = node->IntensityAvgValuePreDef;


  vtkMrmlNode::PrintSelf(os,indent);
  os << indent << "IntensityAvgValuePreDef:"          << this->IntensityAvgValuePreDef << "\n";
*/
