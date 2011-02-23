/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlColorNode.h,v $
  Date:      $Date: 2006/02/14 20:40:13 $
  Version:   $Revision: 1.20 $

=========================================================================auto=*/
// .NAME vtkMrmlColorNode - MRML node for representing colors.
// .SECTION Description
// Color nodes define colors by describing not only the actual color 
// value, but also its name and a list of label values.  One attribute of 
// model nodes is the name of its color.  When the 3D Slicer displays 
// label maps, it colors each voxel by looking up the color associated 
// with that label value. Thus, when label maps are displayed on 
// reformatted slices, their colors automatically match the corresponding 
// surface models in the 3D view.
 

#ifndef __vtkMrmlColorNode_h
#define __vtkMrmlColorNode_h

#include "vtkMrmlNode.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlColorNode : public vtkMrmlNode
{
public:
  static vtkMrmlColorNode *New();
  vtkTypeMacro(vtkMrmlColorNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Write the node's attributes
  void Write(ofstream& of, int indent);

  // Description:
  // Copy the nodes attributes to this object to a MRML file in XML format
  void Copy(vtkMrmlNode *node);

  //--------------------------------------------------------------------------
  // Get and Set Functions
  //--------------------------------------------------------------------------

  // Description:
  // Get/Set for DiffuseColor
  vtkGetVector3Macro(DiffuseColor, vtkFloatingPointType);
  vtkSetVector3Macro(DiffuseColor, vtkFloatingPointType);

  // Description:
  // Factor of the affect of ambient light from 0 to 1
  vtkGetMacro(Ambient, vtkFloatingPointType);
  vtkSetMacro(Ambient, vtkFloatingPointType);

  // Description:
  // Factor of the affect of diffuse reflection from 0 to 1
  vtkGetMacro(Diffuse, vtkFloatingPointType);
  vtkSetMacro(Diffuse, vtkFloatingPointType);

  // Description:
  // Factor of the affect of specular reflection from 0 to 1
  vtkGetMacro(Specular, vtkFloatingPointType);
  vtkSetMacro(Specular, vtkFloatingPointType);

  // Description:
  // Specular power in the range of 1 to 100
  vtkGetMacro(Power, int);
  vtkSetMacro(Power, int);

  // Description:
  // List of label values associated with this color
  vtkGetStringMacro(Labels);
  vtkSetStringMacro(Labels);

protected:
  vtkMrmlColorNode();
  ~vtkMrmlColorNode();
  vtkMrmlColorNode(const vtkMrmlColorNode&);
  void operator=(const vtkMrmlColorNode&);

  // Strings
  char *Labels;

  // Numbers
  vtkFloatingPointType Ambient;
  vtkFloatingPointType Diffuse;
  vtkFloatingPointType Specular;
  int Power;

  // Arrays
  vtkFloatingPointType DiffuseColor[3];
};

#endif









