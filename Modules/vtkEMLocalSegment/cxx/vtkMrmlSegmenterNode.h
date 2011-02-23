/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterNode.h,v $
  Date:      $Date: 2006/02/14 21:24:27 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterNode_h
#define __vtkMrmlSegmenterNode_h

#include <vtkEMLocalSegmentConfigure.h>
#include "vtkMrmlSegmenterAtlasNode.h"

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterNode : public vtkMrmlSegmenterAtlasNode
{
public:
  static vtkMrmlSegmenterNode *New();
  vtkTypeMacro(vtkMrmlSegmenterNode,vtkMrmlNode);

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

  // Should be deleted - from Samson
  // Description:
  // Get/Set for Segmenter
  // vtkSetMacro(EMShapeIter, int);
  // vtkGetMacro(EMShapeIter, int);
 
  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(DisplayProb, int);
  vtkGetMacro(DisplayProb, int);

  // Description:
  // Define what kind of interpolation you want for the registration function - 
  // 1 = Linear Affine Registration 
  // 2 = Nearest Neighbour Affine Registration
   vtkSetMacro(RegistrationInterpolationType, int);
   vtkGetMacro(RegistrationInterpolationType, int);

  // Description:
  // Multi Thread Functionality (Diabled = 1 / Enabled = 0) 
  vtkSetMacro(DisableMultiThreading, int);
  vtkGetMacro(DisableMultiThreading, int);


protected:
  vtkMrmlSegmenterNode();
  ~vtkMrmlSegmenterNode(){};

  int    DisplayProb;  // Should the probability displayed in the graph - left it in bc it is more work to take it out - should not be defined here but in GraphNode 
  int    RegistrationInterpolationType;
  int    DisableMultiThreading;

private:
  vtkMrmlSegmenterNode(const vtkMrmlSegmenterNode&);
  void operator=(const vtkMrmlSegmenterNode&);
};

#endif

