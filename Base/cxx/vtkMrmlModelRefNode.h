/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModelRefNode.h,v $
  Date:      $Date: 2006/02/14 20:40:15 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/
// .NAME vtkMrmlModelRefNode - MRML node to represent a reference to a model.
// .SECTION Description
// ModelRef nodes refer to model nodes. They define where a model should be
// placed in the hierarchy.

#ifndef __vtkMrmlModelRefNode_h
#define __vtkMrmlModelRefNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"


class VTK_SLICER_BASE_EXPORT vtkMrmlModelRefNode : public vtkMrmlNode
{
public:
  static vtkMrmlModelRefNode *New();
  vtkTypeMacro(vtkMrmlModelRefNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // Description:
  // ID of the referenced model
  vtkSetStringMacro(ModelRefID);
  vtkGetStringMacro(ModelRefID);

 
protected:
  vtkMrmlModelRefNode();
  ~vtkMrmlModelRefNode();
  vtkMrmlModelRefNode(const vtkMrmlModelRefNode&);
  void operator=(const vtkMrmlModelRefNode&);

  // Strings
  char *ModelRefID;

};

#endif
