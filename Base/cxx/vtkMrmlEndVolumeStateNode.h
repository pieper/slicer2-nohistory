/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndVolumeStateNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlEndVolumeStateNode - represents the end of a vtkMrmlVolumeStateNode.
// .SECTION Description
// Just a place holder in a vtkMrmlTree

#ifndef __vtkMrmlEndVolumeStateNode_h
#define __vtkMrmlEndVolumeStateNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlEndVolumeStateNode : public vtkMrmlNode
{
public:
  static vtkMrmlEndVolumeStateNode *New();
  vtkTypeMacro(vtkMrmlEndVolumeStateNode,vtkMrmlNode);
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
  vtkMrmlEndVolumeStateNode();
  ~vtkMrmlEndVolumeStateNode();
  vtkMrmlEndVolumeStateNode(const vtkMrmlEndVolumeStateNode&);
  void operator=(const vtkMrmlEndVolumeStateNode&);

};

#endif

