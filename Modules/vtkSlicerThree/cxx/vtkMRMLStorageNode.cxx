/*=auto=========================================================================

Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

See Doc/copyright/copyright.txt
or http://www.slicer.org/copyright/copyright.txt for details.

Program:   3D Slicer
Module:    $RCSfile: vtkMRMLStorageNode.cxx,v $
Date:      $Date: 2006/03/17 15:10:10 $
Version:   $Revision: 1.2 $

=========================================================================auto=*/

#include <string>
#include <ostream>
#include <sstream>

#include "vtkObjectFactory.h"
#include "vtkMRMLStorageNode.h"
#include "vtkMRMLScene.h"

// Initialize static member that controls resampling -- 
// old comment: "This offset will be changed to 0.5 from 0.0 per 2/8/2002 Slicer 
// development meeting, to move ijk coordinates to voxel centers."


//----------------------------------------------------------------------------
vtkMRMLStorageNode::vtkMRMLStorageNode()
{
}

//----------------------------------------------------------------------------
vtkMRMLStorageNode::~vtkMRMLStorageNode()
{
}

void vtkMRMLStorageNode::WriteXML(ostream& of, int nIndent)
{
  Superclass::WriteXML(of, nIndent);
}

//----------------------------------------------------------------------------
void vtkMRMLStorageNode::ReadXMLAttributes(const char** atts)
{
  vtkMRMLNode::ReadXMLAttributes(atts);
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name, StorageID
void vtkMRMLStorageNode::Copy(vtkMRMLNode *node)
{
  Superclass::Copy(node);
}

//----------------------------------------------------------------------------
void vtkMRMLStorageNode::PrintSelf(ostream& os, vtkIndent indent)
{  
  vtkMRMLNode::PrintSelf(os,indent);
}

