/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasInputNode.h,v $
  Date:      $Date: 2006/01/06 17:57:30 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterAtlasInputNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterAtlasInputNode_h
#define __vtkMrmlSegmenterAtlasInputNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMAtlasBrainClassifierConfigure.h>

class VTK_EMATLASBRAINCLASSIFIER_EXPORT vtkMrmlSegmenterAtlasInputNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterAtlasInputNode *New();
  vtkTypeMacro(vtkMrmlSegmenterAtlasInputNode,vtkMrmlNode);

  // Variable Set/Get Functions - Name has to be first to properly work with GUI   
  // Description:
  // Just is listed here so that it properly works with automatic GUI - nothing really is changed 
  vtkSetStringMacro(Name);
  vtkGetStringMacro(Name);
 
  // Description:
  // Get/Set for SegmenterInput
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

protected:
  vtkMrmlSegmenterAtlasInputNode();
  ~vtkMrmlSegmenterAtlasInputNode();
  vtkMrmlSegmenterAtlasInputNode(const vtkMrmlSegmenterAtlasInputNode&) {};
  void operator=(const vtkMrmlSegmenterAtlasInputNode&) {};

  void PrintSelf(ostream& os,vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // I do not know how to better Identify my Images
  char *FileName;
};

#endif

/*
  // Description:
  // Get/Set for SegmenterInput
  vtkGetMacro(IntensityAvgValuePreDef, double);
  vtkSetMacro(IntensityAvgValuePreDef, double);

  double IntensityAvgValuePreDef;

*/
