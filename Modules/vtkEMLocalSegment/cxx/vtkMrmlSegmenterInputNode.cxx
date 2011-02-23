/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterInputNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:33 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
//#include <stdio.h>
//#include <ctype.h>
//#include <string.h>
//#include <math.h>
#include "vtkMrmlSegmenterInputNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterInputNode* vtkMrmlSegmenterInputNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterInputNode");
  if(ret)
  {
    return (vtkMrmlSegmenterInputNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterInputNode;
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterInputNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<SegmenterInput";
  this->vtkMrmlSegmenterAtlasInputNode::Write(of);
  of << "></SegmenterInput>\n";;
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterInputNode::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkMrmlNode::PrintSelf(os,indent);
  this->vtkMrmlSegmenterAtlasInputNode::PrintSelf(os,indent);
}
