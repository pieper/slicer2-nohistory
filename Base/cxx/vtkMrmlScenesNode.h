/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlScenesNode.h,v $
  Date:      $Date: 2006/02/14 20:47:10 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlScenesNode - MRML node to represent a saved scene
// .SECTION Description
// Scenes contain a bunch of MRML nodes that describe a specific view saved
// by the user. The Scenes node itself only contains a scene language (for
// future use) and the name of the scene.

#ifndef __vtkMrmlScenesNode_h
#define __vtkMrmlScenesNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"


class VTK_SLICER_BASE_EXPORT vtkMrmlScenesNode : public vtkMrmlNode
{
public:
  static vtkMrmlScenesNode *New();
  vtkTypeMacro(vtkMrmlScenesNode,vtkMrmlNode);
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
  // Scene language
  vtkSetStringMacro(Lang);
  vtkGetStringMacro(Lang);
 
protected:
  vtkMrmlScenesNode();
  ~vtkMrmlScenesNode();
  vtkMrmlScenesNode(const vtkMrmlScenesNode&);
  void operator=(const vtkMrmlScenesNode&);

  // Strings
  char *Lang;

};

#endif
