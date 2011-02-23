/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlVolumeReadWriteStructuredPointsNode.h,v $
  Date:      $Date: 2006/02/14 20:47:11 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkMrmlVolumeReadWriteStructuredPointsNode - 
// .SECTION Description
// This sub-node should contain information specific to each
// type of volume that needs to be read in.  This can be used
// to clean up the special cases in this file which handle
// volumes of various types, such as dicom, header, etc.  In
// future these things can be moved to the sub-node specific for that
// type of volume.  The sub-nodes here that describe specific volume
// types each correspond to an implementation of the reader/writer,
// which can be found in a vtkMrmlDataVolumeReadWrite subclass.

#ifndef __vtkMrmlVolumeReadWriteStructuredPointsNode_h
#define __vtkMrmlVolumeReadWriteStructuredPointsNode_h

#include "vtkMrmlVolumeReadWriteNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlVolumeReadWriteStructuredPointsNode : public vtkMrmlVolumeReadWriteNode
{
  public:
  static vtkMrmlVolumeReadWriteStructuredPointsNode *New();
  vtkTypeMacro(vtkMrmlVolumeReadWriteStructuredPointsNode,vtkMrmlVolumeReadWriteNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------
 
  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);
  
  //--------------------------------------------------------------------------
  // Specifics for each type of volume data
  //--------------------------------------------------------------------------

  // Subclasses will add more here to handle their types of volume

protected:
  vtkMrmlVolumeReadWriteStructuredPointsNode();
  ~vtkMrmlVolumeReadWriteStructuredPointsNode();
  vtkMrmlVolumeReadWriteStructuredPointsNode(const vtkMrmlVolumeReadWriteStructuredPointsNode&);
  void operator=(const vtkMrmlVolumeReadWriteStructuredPointsNode&);

};

#endif
