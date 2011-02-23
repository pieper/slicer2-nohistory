/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlWindowLevelNode.h,v $
  Date:      $Date: 2006/02/14 20:40:16 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlWindowLevelNode - MRML node to represent the properties of 
// the window levels
// .SECTION Description

#ifndef __vtkMrmlWindowLevelNode_h
#define __vtkMrmlWindowLevelNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"


class VTK_SLICER_BASE_EXPORT vtkMrmlWindowLevelNode : public vtkMrmlNode
{
public:
  static vtkMrmlWindowLevelNode *New();
  vtkTypeMacro(vtkMrmlWindowLevelNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  vtkSetMacro(Window,int);
  vtkGetMacro(Window,int);
  
  vtkSetMacro(Level,int);
  vtkGetMacro(Level,int);

  // Description:
  // Lower threshold of windowing function
  vtkSetMacro(LowerThreshold,int);
  vtkGetMacro(LowerThreshold,int);

  // Description:
  // Upper threshold of windowing function
  vtkSetMacro(UpperThreshold,int);
  vtkGetMacro(UpperThreshold,int);
  
  // Description:
  // Does Slicer determine the window level automatically?
  vtkBooleanMacro(AutoWindowLevel,int);
  vtkSetMacro(AutoWindowLevel,int);
  vtkGetMacro(AutoWindowLevel,int);
  
  // Description:
  // Apply threshold?
  vtkBooleanMacro(ApplyThreshold,int);
  vtkSetMacro(ApplyThreshold,int);
  vtkGetMacro(ApplyThreshold,int);
  
  // Description:
  // Does Slicer determine the threshold automatically?
  vtkBooleanMacro(AutoThreshold,int);
  vtkSetMacro(AutoThreshold,int);
  vtkGetMacro(AutoThreshold,int);

  
 
protected:
  vtkMrmlWindowLevelNode();
  ~vtkMrmlWindowLevelNode();
  vtkMrmlWindowLevelNode(const vtkMrmlWindowLevelNode&);
  void operator=(const vtkMrmlWindowLevelNode&);

  // Numbers
  int Window;
  int Level;
  int LowerThreshold;
  int UpperThreshold;
  
  // Booleans
  int AutoWindowLevel;
  int ApplyThreshold;
  int AutoThreshold;
  
};

#endif
