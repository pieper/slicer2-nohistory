/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlVolumeReadWriteNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:50 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkMrmlVolumeReadWriteNode.h"
#include "vtkObjectFactory.h"

  //------------------------------------------------------------------------------
  vtkMrmlVolumeReadWriteNode* vtkMrmlVolumeReadWriteNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlVolumeReadWriteNode");
  if(ret)
  {
    return (vtkMrmlVolumeReadWriteNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlVolumeReadWriteNode;
}

//----------------------------------------------------------------------------
vtkMrmlVolumeReadWriteNode::vtkMrmlVolumeReadWriteNode()
{
  // Strings
  this->ReaderType = NULL; // needed to use macro below
  this->SetReaderType("none");
}

//----------------------------------------------------------------------------
vtkMrmlVolumeReadWriteNode::~vtkMrmlVolumeReadWriteNode()
{
  if (this->ReaderType)
    {
      delete [] this->ReaderType;
      this->ReaderType = NULL;
    }

}


//----------------------------------------------------------------------------
void vtkMrmlVolumeReadWriteNode::Write(ofstream& of, int nIndent)
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
void vtkMrmlVolumeReadWriteNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlVolumeReadWriteNode *node = (vtkMrmlVolumeReadWriteNode *) anode;

  // Strings
  this->SetReaderType(node->ReaderType);
}


//----------------------------------------------------------------------------
void vtkMrmlVolumeReadWriteNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "ReaderType: " <<
    (this->ReaderType ? this->ReaderType : "(none)") << "\n";

}

