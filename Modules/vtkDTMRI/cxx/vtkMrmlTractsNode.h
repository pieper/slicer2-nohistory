/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlTractsNode.h,v $
  Date:      $Date: 2006/02/14 20:57:41 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

#ifndef __vtkMrmlTractsNode_h
#define __vtkMrmlTractsNode_h

#include "vtkDTMRIConfigure.h"
#include "vtkMrmlNode.h"

class VTK_DTMRI_EXPORT vtkMrmlTractsNode : public vtkMrmlNode
{
 public:
  static vtkMrmlTractsNode *New();
  vtkTypeMacro(vtkMrmlTractsNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  // Description:
  // Copy to another node of the same type. Not implemented.
  void Copy(vtkMrmlNode *node) {};

  // Description:
  // Name of a file containing streamlines as vtkPolyLine data.
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

 protected:
  vtkMrmlTractsNode();
  ~vtkMrmlTractsNode();
  vtkMrmlTractsNode(const vtkMrmlTractsNode&);
  void operator=(const vtkMrmlTractsNode&);

  char *FileName;

};

#endif



