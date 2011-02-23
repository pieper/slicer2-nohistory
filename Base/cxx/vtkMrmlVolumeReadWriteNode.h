/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlVolumeReadWriteNode.h,v $
  Date:      $Date: 2006/02/14 20:40:16 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkMrmlVolumeReadWriteNode - 
// .SECTION Description
// This sub-node should contain information specific to each
// type of volume that needs to be read in.  This can be used
// to clean up the special cases in this file which handle
// volumes of various types, such as dicom, header, etc.  In
// future these things can be moved to the sub-node specific for that
// type of volume.  The sub-nodes here that describe specific volume
// types each correspond to an implementation of the reader/writer,
// which can be found in a vtkMrmlDataVolumeReadWrite subclass.

#ifndef __vtkMrmlVolumeReadWriteNode_h
#define __vtkMrmlVolumeReadWriteNode_h

#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlVolumeReadWriteNode : public vtkMrmlNode
{
  public:
  static vtkMrmlVolumeReadWriteNode *New();
  vtkTypeMacro(vtkMrmlVolumeReadWriteNode,vtkMrmlNode);
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

  // Type of vtkMrmlVolumeReadWriteNode we are.  This must be written to 
  // the MRML file so when it is read back in, a node of this type
  // can be created.
  vtkGetStringMacro(ReaderType);

  // Subclasses will add more here to handle their types of volume

protected:
  vtkMrmlVolumeReadWriteNode();
  ~vtkMrmlVolumeReadWriteNode();
  vtkMrmlVolumeReadWriteNode(const vtkMrmlVolumeReadWriteNode&);
  void operator=(const vtkMrmlVolumeReadWriteNode&);

  vtkSetStringMacro(ReaderType);
  char *ReaderType;
};

#endif
