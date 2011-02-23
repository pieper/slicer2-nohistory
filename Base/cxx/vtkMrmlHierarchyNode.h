/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlHierarchyNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlHierarchyNode - MRML node to represent an anatomical hierarchy.
// .SECTION Description
// Hierarchy nodes begin the descriptions of anatomical model hierarchies.
// The hierarchy descriptions have to be followed by EndHierarchy nodes.

#ifndef __vtkMrmlHierarchyNode_h
#define __vtkMrmlHierarchyNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"


class VTK_SLICER_BASE_EXPORT vtkMrmlHierarchyNode : public vtkMrmlNode
{
public:
  static vtkMrmlHierarchyNode *New();
  vtkTypeMacro(vtkMrmlHierarchyNode,vtkMrmlNode);
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
  // Hierarchy ID
  vtkSetStringMacro(HierarchyID);
  vtkGetStringMacro(HierarchyID);

  // Description:
  // Hierarchy type
  vtkSetStringMacro(Type);
  vtkGetStringMacro(Type);

 
protected:
  vtkMrmlHierarchyNode();
  ~vtkMrmlHierarchyNode();
  vtkMrmlHierarchyNode(const vtkMrmlHierarchyNode&);
  void operator=(const vtkMrmlHierarchyNode&);

  // Strings
  char *HierarchyID;
  char *Type;

};

#endif
