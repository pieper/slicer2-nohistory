/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlColorNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:45 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlColorNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlColorNode* vtkMrmlColorNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlColorNode");
  if(ret)
  {
    return (vtkMrmlColorNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlColorNode;
}

//----------------------------------------------------------------------------
vtkMrmlColorNode::vtkMrmlColorNode()
{
  // Strings
  this->Labels = NULL;

  // Numbers
  this->Ambient = 0.0;
  this->Diffuse = 1.0;
  this->Specular = 0.0;
  this->Power = 1;
  
  // Arrays
  this->DiffuseColor[0] = 1.0;
  this->DiffuseColor[1] = 1.0;
  this->DiffuseColor[2] = 1.0;
}

//----------------------------------------------------------------------------
vtkMrmlColorNode::~vtkMrmlColorNode()
{
  if (this->Labels)
  {
    delete [] this->Labels;
    this->Labels = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlColorNode::Write(ofstream& of, int nIndent)
{
  vtkIndent i1(nIndent);

  // Write all attributes not equal to their defaults
  
  of << i1 << "<Color";
  
  // Strings
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->Labels && strcmp(this->Labels, "")) 
  {
    of << " labels='" << this->Labels << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }

  // Numbers
  if (this->Ambient != 0)
  {
    of << " ambient='" << this->Ambient << "'";
  }
  if (this->Diffuse != 1.0)
  {
    of << " diffuse='" << this->Diffuse << "'";
  }
  if (this->Specular != 0)
  {
    of << " specular='" << this->Specular << "'";
  }
  if (this->Power != 1)
  {
    of << " power='" << this->Power << "'";
  }

  // Arrays
  if (this->DiffuseColor[0] != 1.0 || this->DiffuseColor[1] != 1.0 ||
      this->DiffuseColor[2] != 1.0)
  {
    of << " diffuseColor='" << this->DiffuseColor[0] << " "
       << this->DiffuseColor[1] << " " << this->DiffuseColor[2] << "'";
  }

  of << "></Color>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlColorNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlColorNode *node = (vtkMrmlColorNode *) anode;

  // Strings
  this->SetLabels(node->Labels);

  // Vectors
  this->SetDiffuseColor(node->DiffuseColor);
  
  // Numbers
  this->SetAmbient(node->Ambient);
  this->SetDiffuse(node->Diffuse);
  this->SetSpecular(node->Specular);
  this->SetPower(node->Power);
}


//----------------------------------------------------------------------------
void vtkMrmlColorNode::PrintSelf(ostream& os, vtkIndent indent)
{
  int idx;
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
  os << indent << "Labels: " <<
    (this->Labels ? this->Labels : "(none)") << "\n";

  os << indent << "Ambient:           " << this->Ambient << "\n";
  os << indent << "Diffuse:           " << this->Diffuse << "\n";
  os << indent << "Specular:          " << this->Specular << "\n";
  os << indent << "Power:             " << this->Power << "\n";

  os << "DiffuseColor:\n";
  for (idx = 0; idx < 3; ++idx)
  {
    os << indent << ", " << this->DiffuseColor[idx];
  }
  os << ")\n";
}
