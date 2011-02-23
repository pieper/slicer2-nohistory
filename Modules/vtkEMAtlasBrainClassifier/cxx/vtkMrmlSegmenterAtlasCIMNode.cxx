/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasCIMNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:30 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterAtlasCIMNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterAtlasCIMNode* vtkMrmlSegmenterAtlasCIMNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterAtlasCIMNode");
  if(ret)
  {
    return (vtkMrmlSegmenterAtlasCIMNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterAtlasCIMNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasCIMNode::vtkMrmlSegmenterAtlasCIMNode()
{
  this->CIMMatrix = NULL; 
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasCIMNode::~vtkMrmlSegmenterAtlasCIMNode()
{
  if (this->CIMMatrix)
  {
    delete [] this->CIMMatrix;
    this->CIMMatrix = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasCIMNode::Write(ofstream& of)
{
  // Write all attributes not equal to their defaults

  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name ='" << this->Name << "'";
  }
  if (this->CIMMatrix && strcmp(this->CIMMatrix, "")) 
  {
    of << " CIMMatrix='" << this->CIMMatrix << "'";
  }
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterAtlasCIMNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlSegmenterAtlasCIMNode *node = (vtkMrmlSegmenterAtlasCIMNode *) anode;

  this->SetCIMMatrix(node->CIMMatrix); 
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasCIMNode::PrintSelf(ostream& os, vtkIndent indent)
{
   os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
   os << indent << "CIMMatrix: " <<
    (this->CIMMatrix ? this->CIMMatrix : "(none)") << "\n";
   os << ")\n";
}

