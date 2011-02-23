/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlLandmarkNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/
// .NAME vtkMrmlLandmarkNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Landmark nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlLandmarkNode_h
#define __vtkMrmlLandmarkNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlLandmarkNode : public vtkMrmlNode
{
public:
  static vtkMrmlLandmarkNode *New();
  vtkTypeMacro(vtkMrmlLandmarkNode,vtkMrmlNode);
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

  // Description:
  // Get/Set for Landmark
  vtkSetVector3Macro(XYZ,float);
  vtkGetVectorMacro(XYZ,float,3);

  // Description:
  // Get/Set for Landmark
  vtkSetVector3Macro(FXYZ,float);
  vtkGetVectorMacro(FXYZ,float,3);

  // Description:
  // Position of the landmark along the path
  vtkSetMacro(PathPosition, int);
  vtkGetMacro(PathPosition, int);

protected:
  vtkMrmlLandmarkNode();
  ~vtkMrmlLandmarkNode();
  vtkMrmlLandmarkNode(const vtkMrmlLandmarkNode&);
  void operator=(const vtkMrmlLandmarkNode&);

  float XYZ[3];
  float FXYZ[3];
  int PathPosition;
};

#endif

