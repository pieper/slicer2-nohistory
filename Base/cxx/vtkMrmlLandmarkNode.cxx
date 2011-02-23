/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlLandmarkNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:47 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlLandmarkNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlLandmarkNode* vtkMrmlLandmarkNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlLandmarkNode");
  if(ret)
  {
    return (vtkMrmlLandmarkNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlLandmarkNode;
}

//----------------------------------------------------------------------------
vtkMrmlLandmarkNode::vtkMrmlLandmarkNode()
{
  this->XYZ[0] = this->XYZ[1] = this->XYZ[2] = 0.0;
  this->FXYZ[0] = this->FXYZ[1] = this->FXYZ[2] = 0.0;
  this->PathPosition = 0;
}

//----------------------------------------------------------------------------
vtkMrmlLandmarkNode::~vtkMrmlLandmarkNode()
{

}

//----------------------------------------------------------------------------
void vtkMrmlLandmarkNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Landmark";

  // Strings
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }

  // Landmark
  of << " xyz='" << this->XYZ[0] << " " << this->XYZ[1] << " " <<
                    this->XYZ[2] << "'";

  // Landmark
  of << " focalxyz='" << this->FXYZ[0] << " " << this->FXYZ[1] << " " <<
                    this->FXYZ[2] << "'";

  of << " pathPosition='" << this->PathPosition << "'";

  of << "></Landmark>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlLandmarkNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlLandmarkNode *node = (vtkMrmlLandmarkNode *) anode;

  this->XYZ[0] = node->XYZ[0];
  this->XYZ[1] = node->XYZ[1];
  this->XYZ[2] = node->XYZ[2];
  this->PathPosition = node ->PathPosition;
}

//----------------------------------------------------------------------------
void vtkMrmlLandmarkNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";

  // XYZ
  os << indent << "XYZ: (";
  os << indent << this->XYZ[0] << ", " << this->XYZ[1] << ", " << this->XYZ[2]
                  << ")" << "\n";
  // FXYZ
  os << indent << "FXYZ: (";
  os << indent << this->FXYZ[0] << ", " << this->FXYZ[1] << ", " << this->FXYZ[2]
                  << ")" << "\n";
  os << indent << "pathPosition: ";
  os << indent << this->PathPosition;
}


