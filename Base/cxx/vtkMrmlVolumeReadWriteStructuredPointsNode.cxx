/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlVolumeReadWriteStructuredPointsNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:50 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkMrmlVolumeReadWriteStructuredPointsNode.h"
#include "vtkObjectFactory.h"

  //------------------------------------------------------------------------------
  vtkMrmlVolumeReadWriteStructuredPointsNode* vtkMrmlVolumeReadWriteStructuredPointsNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlVolumeReadWriteStructuredPointsNode");
  if(ret)
  {
    return (vtkMrmlVolumeReadWriteStructuredPointsNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlVolumeReadWriteStructuredPointsNode;
}

//----------------------------------------------------------------------------
vtkMrmlVolumeReadWriteStructuredPointsNode::vtkMrmlVolumeReadWriteStructuredPointsNode()
{
  // Strings
  this->ReaderType = NULL; // needed to use macro below
  this->SetReaderType("vtkStructuredPoints");
}

//----------------------------------------------------------------------------
vtkMrmlVolumeReadWriteStructuredPointsNode::~vtkMrmlVolumeReadWriteStructuredPointsNode()
{
  if (this->ReaderType)
    {
      delete [] this->ReaderType;
      this->ReaderType = NULL;
    }

}


//----------------------------------------------------------------------------
void vtkMrmlVolumeReadWriteStructuredPointsNode::Write(ofstream& of, int nIndent)
{
  
  vtkIndent i1(nIndent);

  of << i1 << "<VolumeReadWrite";

  // Write all attributes 
  // Strings
  if (this->ReaderType && strcmp(this->ReaderType,""))
    {
      of << " readerType='" << this->ReaderType << "'";
    }
  of << "></VolumeReadWrite>\n";;
}


//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name, VolumeID
void vtkMrmlVolumeReadWriteStructuredPointsNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlVolumeReadWriteStructuredPointsNode *node = (vtkMrmlVolumeReadWriteStructuredPointsNode *) anode;

  // Strings
  this->SetReaderType(node->ReaderType);
}


//----------------------------------------------------------------------------
void vtkMrmlVolumeReadWriteStructuredPointsNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "ReaderType: " <<
    (this->ReaderType ? this->ReaderType : "(none)") << "\n";

}

