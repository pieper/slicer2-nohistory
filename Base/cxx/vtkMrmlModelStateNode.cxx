/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModelStateNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:48 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlModelStateNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlModelStateNode* vtkMrmlModelStateNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlModelStateNode");
  if(ret)
  {
    return (vtkMrmlModelStateNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlModelStateNode;
}

//----------------------------------------------------------------------------
vtkMrmlModelStateNode::vtkMrmlModelStateNode()
{
  // Strings
  this->ModelRefID = NULL;
  
  // Numbers
  this->Visible = 1;
  this->Opacity = 1.0;
  this->SliderVisible = 1;
  this->SonsVisible = 1;
  this->Clipping = 0;
  this->BackfaceCulling = 1;
}

//----------------------------------------------------------------------------
vtkMrmlModelStateNode::~vtkMrmlModelStateNode()
{
  if (this->ModelRefID)
  {
    delete [] this->ModelRefID;
    this->ModelRefID = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlModelStateNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<ModelState";

  // Strings
  if (this->ModelRefID && strcmp(this->ModelRefID, "")) 
  {
    of << " modelRefID='" << this->ModelRefID << "'";
  }
  
  // Numbers
  if (this->Visible != 1)
  {
    of << " visible='" << (this->Visible ? "true":"false") << "'";
  }
  if (this->Opacity != 1.0)
  {
    of << " opacity='" << this->Opacity << "'";
  }
  if (this->SliderVisible != 1)
  {
    of << " slidervisible='" << (this->SliderVisible ? "true":"false") << "'";
  }
  if (this->SonsVisible != 1)
  {
    of << " sonsvisible='" << (this->SonsVisible ? "true":"false") << "'";
  }
  if (this->Clipping != 0)
  {
    of << " clipping='" << (this->Clipping ? "true":"false") << "'";
  }
  if (this->BackfaceCulling != 1)
  {
    of << " backfaceCulling='" << (this->BackfaceCulling ? "true":"false") << "'";
  }
  
  of << "></ModelState>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlModelStateNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlModelStateNode *node = (vtkMrmlModelStateNode *) anode;

  // Strings
  this->SetModelRefID(node->ModelRefID);
  // Numbers
  this->SetVisible(node->Visible);
  this->SetOpacity(node->Opacity);
  this->SetSliderVisible(node->SliderVisible);
  this->SetSonsVisible(node->SonsVisible);
  this->SetClipping(node->Clipping);
  this->SetBackfaceCulling(node->BackfaceCulling);
}

//----------------------------------------------------------------------------
void vtkMrmlModelStateNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "ModelRefID: " <<
    (this->ModelRefID ? this->ModelRefID : "(none)") << "\n";
  os << indent << "Visible: " << this->Visible << "\n";
  os << indent << "Opacity: " << this->Opacity << "\n";
  os << indent << "SliderVisible: " << this->SliderVisible << "\n";
  os << indent << "SonsVisible: " << this->SonsVisible << "\n";
  os << indent << "Clipping: " << this->Clipping << "\n";
  os << indent << "BackfaceCulling: " << this->BackfaceCulling << "\n";
}
