/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlMatrixNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:47 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlMatrixNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlMatrixNode* vtkMrmlMatrixNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlMatrixNode");
  if(ret)
  {
    return (vtkMrmlMatrixNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlMatrixNode;
}

//----------------------------------------------------------------------------
vtkMrmlMatrixNode::vtkMrmlMatrixNode()
{
  this->Transform = vtkTransform::New();
}

//----------------------------------------------------------------------------
vtkMrmlMatrixNode::~vtkMrmlMatrixNode()
{
  this->Transform->Delete();
}

//----------------------------------------------------------------------------
void vtkMrmlMatrixNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults 
 
  vtkIndent i1(nIndent);

  of << i1 << "<Matrix";

  // Strings
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }

  // Matrix
  of << " matrix='" << 
    GetMatrixToString(this->Transform->GetMatrix()) << "'";

  of << "></Matrix>\n";;
}

//----------------------------------------------------------------------------

void vtkMrmlMatrixNode::SetMatrix(char *str) {
  // This line does not work.
  //    this->SetMatrixToString(this->Transform->GetMatrix(), str);};
  vtkMatrix4x4 *tmp = vtkMatrix4x4::New();
  this->SetMatrixToString(tmp,str);
  this->Transform->SetMatrix(tmp);
  tmp->Delete();
}

//----------------------------------------------------------------------------

char *vtkMrmlMatrixNode::GetMatrix() {
  return this->GetMatrixToString(this->Transform->GetMatrix());
};

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlMatrixNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlMatrixNode *node = (vtkMrmlMatrixNode *) anode;

  this->Transform->DeepCopy(node->Transform);
}

//----------------------------------------------------------------------------
void vtkMrmlMatrixNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";

  // Transform
  os << indent << "Transform:\n";
    this->Transform->PrintSelf(os, indent.GetNextIndent());  
}


