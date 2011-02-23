/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlPathNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:48 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlPathNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlPathNode* vtkMrmlPathNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlPathNode");
  if(ret)
  {
    return (vtkMrmlPathNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlPathNode;
}

//----------------------------------------------------------------------------
vtkMrmlPathNode::vtkMrmlPathNode()
{

  // vtkMrmlNode's attributes
  this->Indent = 1;

//  this->cPathColor = NULL;
//  this->cLandColor = NULL;
//  this->fPathColor = NULL;
//  this->fLandColor = NULL;

}

//----------------------------------------------------------------------------
vtkMrmlPathNode::~vtkMrmlPathNode()
{

//  if (this->cLandColor)
//    {
//      delete [] this->cLandColor;
//      this->cLandColor = NULL;
//    }
//  if (this->cPathColor)
//    {
//      delete [] this->cPathColor;
//      this->cPathColor = NULL;
//    }
//  if (this->fLandColor)
//    {
//      delete [] this->fLandColor;
//      this->fLandColor = NULL;
//    }
//  if (this->fPathColor)
//    {
//      delete [] this->fPathColor;
//      this->fPathColor = NULL;
//    }
}

//----------------------------------------------------------------------------
void vtkMrmlPathNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Path";

  // Strings
//  if (this->cLandColor && strcmp(this->cLandColor, "")) 
//    {
//      of << " cLandColor='" << this->cLandColor << "'";
//    }
//  if (this->cPathColor && strcmp(this->cPathColor, "")) 
//    {
//      of << " cPathColor='" << this->cPathColor << "'";
//    }
//  if (this->fLandColor && strcmp(this->fLandColor, "")) 
//    {
//      of << " fLandColor='" << this->fLandColor << "'";
//    }
//  if (this->fPathColor && strcmp(this->fPathColor, "")) 
//    {
//      of << " fPathColor='" << this->fPathColor << "'";
//    }
  of << "></Path>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlPathNode::Copy(vtkMrmlNode *node)
{
  vtkMrmlNode::MrmlNodeCopy(node);
  //Strings, how do we do with color?
}

//----------------------------------------------------------------------------
void vtkMrmlPathNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

//  os << indent << "cLandColor: " <<
//    (this->cLandColor ? this->cLandColor : "(none)") << "\n";
//  os << indent << "cPathColor: " <<
//    (this->cPathColor ? this->cPathColor : "(none)") << "\n";
//  os << indent << "fLandColor: " <<
//    (this->fLandColor ? this->fLandColor : "(none)") << "\n";
//  os << indent << "fPathColor: " <<
//    (this->fPathColor ? this->fPathColor : "(none)") << "\n";

}


