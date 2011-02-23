/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModelGroupNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:47 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlModelGroupNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlModelGroupNode* vtkMrmlModelGroupNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlModelGroupNode");
  if(ret)
  {
    return (vtkMrmlModelGroupNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlModelGroupNode;
}

//----------------------------------------------------------------------------
vtkMrmlModelGroupNode::vtkMrmlModelGroupNode()
{
  this->Indent = 1;
  
  // Strings
  this->ModelGroupID = NULL;
  this->Color = NULL;
  
  // Numbers
  this->Opacity = 1.0;
  this->Visibility = 1;
  this->Expansion = 1;
}

//----------------------------------------------------------------------------
vtkMrmlModelGroupNode::~vtkMrmlModelGroupNode()
{
  if (this->ModelGroupID)
  {
    delete [] this->ModelGroupID;
    this->ModelGroupID = NULL;
  }
  if (this->Color)
  {
    delete [] this->Color;
    this->Color = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlModelGroupNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<ModelGroup";

  // Strings
  if (this->ModelGroupID && strcmp(this->ModelGroupID,""))
  {
    of << " id='" << this->ModelGroupID << "'";
  }
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->Color && strcmp(this->Color, ""))
  {
    of << " color='" << this->Color << "'";
  }
  
  //Numbers
  if (this->Opacity != 1.0)
  {
    of << " opacity='" << this->Opacity << "'";
  }
  if (this->Visibility != 1)
  {
    of << " visibility='" << (this->Visibility ? "true":"false") << "'";
  }
  
  of << ">\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlModelGroupNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlModelGroupNode *node = (vtkMrmlModelGroupNode *) anode;

  // Strings
  this->SetModelGroupID(node->ModelGroupID);
  this->SetColor(node->Color);
  
  // Numbers
  this->SetOpacity(node->Opacity);
  this->SetVisibility(node->Visibility);
  this->SetExpansion(node->Expansion);
  
}

//----------------------------------------------------------------------------
void vtkMrmlModelGroupNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "ModelGroupID: " <<
    (this->ModelGroupID ? this->ModelGroupID : "(none)") << "\n";
  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";  
  os << indent << "Color: " <<
    (this->Color ? this->Color : "(none)") << "\n";
    
  os << indent << "Opacity:    " << this->Opacity << "\n";
  os << indent << "Visibility: " << this->Visibility << "\n";
}
