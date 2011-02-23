/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlEndSegmenterSuperClassNode.h,v $
  Date:      $Date: 2006/02/14 21:24:27 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkMrmlEndSegmenterSuperClassNode - represents the end of a vtkMrmlPathNode.
// .SECTION Description
// Just a place holder in a vtkMrmlTree

#ifndef __vtkMrmlEndSegmenterSuperClassNode_h
#define __vtkMrmlEndSegmenterSuperClassNode_h

#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMLocalSegmentConfigure.h>

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlEndSegmenterSuperClassNode : public vtkMrmlNode
{
public:
  static vtkMrmlEndSegmenterSuperClassNode *New();
  vtkTypeMacro(vtkMrmlEndSegmenterSuperClassNode,vtkMrmlNode);
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
  vtkMrmlEndSegmenterSuperClassNode();
  ~vtkMrmlEndSegmenterSuperClassNode();
private:
  vtkMrmlEndSegmenterSuperClassNode(const vtkMrmlEndSegmenterSuperClassNode&);
  void operator=(const vtkMrmlEndSegmenterSuperClassNode&);
};

#endif

