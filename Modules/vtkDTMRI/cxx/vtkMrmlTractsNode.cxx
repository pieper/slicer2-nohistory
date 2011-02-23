/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlTractsNode.cxx,v $
  Date:      $Date: 2006/03/06 21:07:29 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

#include "vtkMrmlTractsNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlTractsNode* vtkMrmlTractsNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlTractsNode");
  if(ret)
  {
    return (vtkMrmlTractsNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlTractsNode;
}

//----------------------------------------------------------------------------
vtkMrmlTractsNode::vtkMrmlTractsNode()
{
  this->FileName = NULL;

}

//----------------------------------------------------------------------------
vtkMrmlTractsNode::~vtkMrmlTractsNode()
{
  
  if (this->FileName)
    {
      delete [] this->FileName;
      this->FileName = NULL;
    }
}

//----------------------------------------------------------------------------
void vtkMrmlTractsNode::Write(ofstream& of, int nIndent)
{
  vtkIndent i1(nIndent);

  // Write all attributes
  
  of << i1 << "<Tracts";

  if (this->FileName) 
    {
      of << " fileName='" << this->FileName << "'";
    }
  else
    {
      of << " fileName=''";
    }

  of << "></Tracts>\n";
}

//----------------------------------------------------------------------------
void vtkMrmlTractsNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

}

