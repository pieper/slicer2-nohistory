/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterGraphNode.h,v $
  Date:      $Date: 2006/02/14 21:24:27 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterGraphNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterGraphNode_h
#define __vtkMrmlSegmenterGraphNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMLocalSegmentConfigure.h>

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterGraphNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterGraphNode *New();
  vtkTypeMacro(vtkMrmlSegmenterGraphNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // Variable Set/Get Functions - Name has to be first to properly work with GUI   
  // Description:
  // Just is listed here so that it properly works with automatic GUI - nothing really is changed 
  vtkSetStringMacro(Name);
  vtkGetStringMacro(Name);
 
  // Any Variables afterwards 
  // Description:
  // Get/Set for SegmenterGraph
  vtkSetMacro(Xmin, int);
  vtkGetMacro(Xmin, int);

  // Description:
  // Get/Set for SegmenterGraph
  vtkSetMacro(Xmax, int);
  vtkGetMacro(Xmax, int);

  // Description:
  // Get/Set for SegmenterGraph
  vtkSetMacro(Xsca, int);
  vtkGetMacro(Xsca, int);

protected:
  vtkMrmlSegmenterGraphNode();
  ~vtkMrmlSegmenterGraphNode();

  int Xmin;
  int Xmax;
  int Xsca;
private:
  vtkMrmlSegmenterGraphNode(const vtkMrmlSegmenterGraphNode&);
  void operator=(const vtkMrmlSegmenterGraphNode&);

};

#endif

