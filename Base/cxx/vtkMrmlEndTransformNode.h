/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndTransformNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.17 $

=========================================================================auto=*/
// .NAME vtkMrmlEndTransformNode - represents the end of a vtkMrmlTransformNode.
// .SECTION Description
// Just a place holder in a vtkMrmlTree

#ifndef __vtkMrmlEndTransformNode_h
#define __vtkMrmlEndTransformNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkMatrix4x4.h"
#include "vtkTransform.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlEndTransformNode : public vtkMrmlNode
{
public:
  static vtkMrmlEndTransformNode *New();
  vtkTypeMacro(vtkMrmlEndTransformNode,vtkMrmlNode);
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
  vtkMrmlEndTransformNode();
  ~vtkMrmlEndTransformNode();
  vtkMrmlEndTransformNode(const vtkMrmlEndTransformNode&);
  void operator=(const vtkMrmlEndTransformNode&);

};

#endif

