/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterInputNode.h,v $
  Date:      $Date: 2006/02/14 21:24:27 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterInputNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterInputNode_h
#define __vtkMrmlSegmenterInputNode_h

//#include <iostream.h>
//#include <fstream.h>

#include <vtkEMLocalSegmentConfigure.h>
#include "vtkMrmlSegmenterAtlasInputNode.h"

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterInputNode : public vtkMrmlSegmenterAtlasInputNode 
{
public:
  static vtkMrmlSegmenterInputNode *New();
  vtkTypeMacro(vtkMrmlSegmenterInputNode,vtkMrmlNode);

  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node) {this->vtkMrmlSegmenterAtlasInputNode::Copy(node);}

  // Description: - not used anymore
  // Get/Set for SegmenterInput
  // vtkGetMacro(IntensityAvgValuePreDef, double);
  // vtkSetMacro(IntensityAvgValuePreDef, double);

protected:
  vtkMrmlSegmenterInputNode(){};
  ~vtkMrmlSegmenterInputNode(){};
private:
  vtkMrmlSegmenterInputNode(const vtkMrmlSegmenterInputNode&);
  void operator=(const vtkMrmlSegmenterInputNode&);
};

#endif

