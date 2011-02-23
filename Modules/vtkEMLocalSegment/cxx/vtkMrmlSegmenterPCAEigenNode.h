/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterPCAEigenNode.h,v $
  Date:      $Date: 2006/02/14 21:24:27 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterPCAEigenNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterPCAEigenNode_h
#define __vtkMrmlSegmenterPCAEigenNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMLocalSegmentConfigure.h>

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterPCAEigenNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterPCAEigenNode *New();
  vtkTypeMacro(vtkMrmlSegmenterPCAEigenNode,vtkMrmlNode);
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
  // Get/Set for SegmenterPCAEigen
  vtkGetMacro(Number, int);
  void SetNumber(int init) { 
    this->Number = init; 
    char *NameInit = new char[10];
    sprintf(NameInit,"%d",init);
    // So Name shows up in Data Window 
    this->SetName(NameInit);
    delete []NameInit;
  }

  // Description:
  // Get/Set for SegmenterPCAEigen
  vtkGetMacro(EigenValue, double);
  vtkSetMacro(EigenValue, double);

  // Description:
  // Get/Set for SegmenterPCAEigen
  vtkSetStringMacro(EigenVectorName);
  vtkGetStringMacro(EigenVectorName);
protected:
  vtkMrmlSegmenterPCAEigenNode();
  ~vtkMrmlSegmenterPCAEigenNode();

  int    Number;
  double EigenValue;  
  char   *EigenVectorName;
 
private:
  vtkMrmlSegmenterPCAEigenNode(const vtkMrmlSegmenterPCAEigenNode&);
  void operator=(const vtkMrmlSegmenterPCAEigenNode&);
};

#endif

