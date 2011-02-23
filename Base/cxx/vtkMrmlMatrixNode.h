/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlMatrixNode.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkMrmlMatrixNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Matrix nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlMatrixNode_h
#define __vtkMrmlMatrixNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkMatrix4x4.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlMatrixNode : public vtkMrmlNode
{
public:
  static vtkMrmlMatrixNode *New();
  vtkTypeMacro(vtkMrmlMatrixNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  // Description:
  // 16 numbers that form a 4x4 matrix. The matrix is multiplied by a 
  // point (M*P) to compute the transformed point
  void SetMatrix(char *str);
  char *GetMatrix();

  // Description:
  // Rotate around each axis: x,y, and z in degrees
  void Scale(float x, float y, float z) {
    this->Transform->Scale(x, y, z);};

  // Description:
  // Rotate around each axis: x,y, and z in degrees
  void RotateX(float d) {
    this->Transform->RotateX(d);};
  void RotateY(float d) {
    this->Transform->RotateY(d);};
  void RotateZ(float d) {
    this->Transform->RotateZ(d);};

  // Description:
  // Rotate around each axis: x,y, and z in degrees
  void Translate(float x, float y, float z) {
    this->Transform->Translate(x, y, z);};

  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // Description:
  // Get/Set for Matrix
  vtkGetObjectMacro(Transform, vtkTransform);
  vtkSetObjectMacro(Transform, vtkTransform);

protected:
  vtkMrmlMatrixNode();
  ~vtkMrmlMatrixNode();
  vtkMrmlMatrixNode(const vtkMrmlMatrixNode&);
  void operator=(const vtkMrmlMatrixNode&);

  vtkTransform *Transform;
};

#endif

