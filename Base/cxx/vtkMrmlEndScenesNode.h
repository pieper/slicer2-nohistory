/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndScenesNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlEndScenesNode - represents the end of a vtkMrmlScenesNode.
// .SECTION Description
// Just a place holder in a vtkMrmlTree

#ifndef __vtkMrmlEndScenesNode_h
#define __vtkMrmlEndScenesNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlEndScenesNode : public vtkMrmlNode
{
public:
  static vtkMrmlEndScenesNode *New();
  vtkTypeMacro(vtkMrmlEndScenesNode,vtkMrmlNode);
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
  vtkMrmlEndScenesNode();
  ~vtkMrmlEndScenesNode();
  vtkMrmlEndScenesNode(const vtkMrmlEndScenesNode&);
  void operator=(const vtkMrmlEndScenesNode&);

};

#endif

