/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndHierarchyNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlEndHierarchyNode - represents the end of a vtkMrmlHierarchyNode.
// .SECTION Description
// Just a place holder in a vtkMrmlTree

#ifndef __vtkMrmlEndHierarchyNode_h
#define __vtkMrmlEndHierarchyNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlEndHierarchyNode : public vtkMrmlNode
{
public:
  static vtkMrmlEndHierarchyNode *New();
  vtkTypeMacro(vtkMrmlEndHierarchyNode,vtkMrmlNode);
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

protected:
  vtkMrmlEndHierarchyNode();
  ~vtkMrmlEndHierarchyNode();
  vtkMrmlEndHierarchyNode(const vtkMrmlEndHierarchyNode&);
  void operator=(const vtkMrmlEndHierarchyNode&);

};

#endif

