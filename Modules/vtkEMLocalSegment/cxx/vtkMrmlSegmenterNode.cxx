/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterNode.cxx,v $
  Date:      $Date: 2006/01/13 16:36:46 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
//#include <stdio.h>
//#include <ctype.h>
//#include <string.h>
//#include <math.h>
#include "vtkMrmlSegmenterNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterNode* vtkMrmlSegmenterNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterNode");
  if(ret)
  {
    return (vtkMrmlSegmenterNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterNode::vtkMrmlSegmenterNode()
{
  this->Indent                        = 1;
  this->DisplayProb                   = 0;
  this->RegistrationInterpolationType = 0;
  this->DisableMultiThreading         = 0;
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);
  of << i1 << "<Segmenter";
  this->vtkMrmlSegmenterAtlasNode::Write(of);
  of << " DisplayProb  ='"               << this->DisplayProb  << "'";
  if (this->RegistrationInterpolationType) of << " RegistrationInterpolationType ='"<< this->RegistrationInterpolationType << "'";
  if (this->DisableMultiThreading)   of << " DisableMultiThreading ='" << this->DisableMultiThreading << "'";
  of << ">\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name and PrintDir
void vtkMrmlSegmenterNode::Copy(vtkMrmlNode *anode)
{
  this->vtkMrmlSegmenterAtlasNode::Copy(anode);
  vtkMrmlSegmenterNode *node          = (vtkMrmlSegmenterNode *) anode;
  this->DisplayProb                   = node->DisplayProb;
  this->RegistrationInterpolationType = node->RegistrationInterpolationType;
  this->DisableMultiThreading         = node->DisableMultiThreading; 
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterNode::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkMrmlSegmenterAtlasNode::PrintSelf(os, indent);
  os << indent << "DisplayProb: "               << this->DisplayProb <<  "\n"; 
  os << indent << "RegistrationInterpolationType: " << this->RegistrationInterpolationType << "\n"; 
  os << indent << "DisableMultiThreading: "; 
  if (this->DisableMultiThreading) cout << "Yes\n"; 
  else cout << "No\n"; 
  os << "\n";
}
