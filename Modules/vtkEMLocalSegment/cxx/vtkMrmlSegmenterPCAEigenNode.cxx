/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterPCAEigenNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:33 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkMrmlSegmenterPCAEigenNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterPCAEigenNode* vtkMrmlSegmenterPCAEigenNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterPCAEigenNode");
  if(ret)
  {
    return (vtkMrmlSegmenterPCAEigenNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterPCAEigenNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterPCAEigenNode::vtkMrmlSegmenterPCAEigenNode()
{
  this->Number          = -1;
  this->EigenVectorName = NULL; 
  this->EigenValue      = 0.0;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterPCAEigenNode::~vtkMrmlSegmenterPCAEigenNode()
{
  if (this->EigenVectorName)
  {
    delete [] this->EigenVectorName;
    this->EigenVectorName = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterPCAEigenNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);
  of << i1 << "<SegmenterPCAEigen";
  of << " Number='" << this->Number << "'";
  if (this->EigenVectorName && strcmp(this->EigenVectorName, "")) 
  {
    of << " EigenVectorName='" << this->EigenVectorName << "'";
  }
  of << " EigenValue='" << this->EigenValue << "'";
  of << "></SegmenterPCAEigen>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterPCAEigenNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlSegmenterPCAEigenNode *node = (vtkMrmlSegmenterPCAEigenNode *) anode;

  this->SetNumber(node->Number);
  this->SetEigenVectorName(node->EigenVectorName);
  this->SetEigenValue(node->EigenValue);
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterPCAEigenNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);
   os << indent << "Number: " << this->Number << "\n";
   os << indent << "EigenVectorName: " << (this->EigenVectorName ? this->EigenVectorName : "(none)") << "\n";
   os << indent << "EigenValue: " << this->EigenValue << "\n";
}


