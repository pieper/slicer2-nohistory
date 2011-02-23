/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlFiducialsNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:46 $
  Version:   $Revision: 1.16 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlFiducialsNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlFiducialsNode* vtkMrmlFiducialsNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlFiducialsNode");
  if(ret)
  {
    return (vtkMrmlFiducialsNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlFiducialsNode;
}

//----------------------------------------------------------------------------
vtkMrmlFiducialsNode::vtkMrmlFiducialsNode()
{
  // vtkMrmlNode's attributes
  this->Indent = 1;
  this->SymbolSize = 6.0;
  this->TextSize = 4.5;
  this->Visibility = 1;
  this->Color[0]=0.4; this->Color[1]=1.0; this->Color[2]=1.0;
  this->Type = NULL;
  this->SetType("default");
}

//----------------------------------------------------------------------------
vtkMrmlFiducialsNode::~vtkMrmlFiducialsNode()
{
  if (this->Type) {
    delete [] this->Type;
    this->Type = NULL;
  }

}

//----------------------------------------------------------------------------
void vtkMrmlFiducialsNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Fiducials";
  // Strings
  if (this->Name && strcmp(this->Name, "")) 
    {
      of << " name='" << this->Name << "'";
    }
  if (this->Description && strcmp(this->Description, "")) 
    {
      of << " description='" << this->Description << "'";
    }
     of << " type='" << this->Type << "'";
     of << " symbolSize='" << this->SymbolSize << "'";
     of << " textSize='" << this->TextSize << "'";
     of << " visibility='" << this->Visibility << "'";
     of << " color='" << this->Color[0] << " " << this->Color[1] << " " <<
                    this->Color[2] << "'";
  
   of << ">\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlFiducialsNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlFiducialsNode *node = (vtkMrmlFiducialsNode *) anode;

  this->SymbolSize = node->SymbolSize;
  this->TextSize = node->TextSize;
  this->Visibility = node->Visibility;
  this->Type = node->Type;
}

//----------------------------------------------------------------------------
void vtkMrmlFiducialsNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);
    os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
  
  os << indent << "Type: ";
  os << indent << this->Type << " \n ";
  
  os << indent << "Symbol size: (";
  os << indent << this->SymbolSize << ") \n ";

  os << indent << "Text size: (";
  os << indent << this->TextSize << ") \n ";

}

void vtkMrmlFiducialsNode::SetTypeToEndoscopic() {

  this->SetType("endoscopic");

}

void vtkMrmlFiducialsNode::SetTypeToMeasurement(){

  this->SetType("measurement");

}

void vtkMrmlFiducialsNode::SetTypeToDefault(){

  this->SetType("default");

}


