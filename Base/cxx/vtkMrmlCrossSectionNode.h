/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlCrossSectionNode.h,v $
  Date:      $Date: 2006/02/14 20:40:13 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/
// .NAME vtkMrmlCrossSectionNode - MRML node to represent the properties of a cross section
// .SECTION Description
// CrossSection node describe the properties of the three slices that are
// displayed on the screen. Therefore, the position of a cross section must
// currently be 0, 1 or 2.

#ifndef __vtkMrmlCrossSectionNode_h
#define __vtkMrmlCrossSectionNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"


class VTK_SLICER_BASE_EXPORT vtkMrmlCrossSectionNode : public vtkMrmlNode
{
public:
  static vtkMrmlCrossSectionNode *New();
  vtkTypeMacro(vtkMrmlCrossSectionNode,vtkMrmlNode);
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

  // Description:
  // Which cross section is referenced?
  vtkSetMacro(Position,int);
  vtkGetMacro(Position,int);
  
  // Description:
  // Direction
  vtkSetStringMacro(Direction);
  vtkGetStringMacro(Direction);
  
  // Description:
  // Position of the slider
  vtkSetMacro(SliceSlider,int);
  vtkGetMacro(SliceSlider,int);
  
  // Description:
  // Rotation X
  // (not used in Slicer, only for SPLViz compatibility)
  vtkSetMacro(RotatorX,int);
  vtkGetMacro(RotatorX,int);
  
  // Description:
  // Rotation Y
  // (not used in Slicer, only for SPLViz compatibility)
  vtkSetMacro(RotatorY,int);
  vtkGetMacro(RotatorY,int);
  
  // Description:
  // Zoom
  vtkSetMacro(Zoom,float);
  vtkGetMacro(Zoom,float);
  
  // Description:
  // Visibility in 3D view
  vtkBooleanMacro(InModel,int);
  vtkSetMacro(InModel,int);
  vtkGetMacro(InModel,int);
  
  // Description:
  // Background volume
  vtkSetStringMacro(BackVolRefID);
  vtkGetStringMacro(BackVolRefID);
  
  // Description:
  // Foreground volume
  vtkSetStringMacro(ForeVolRefID);
  vtkGetStringMacro(ForeVolRefID);
  
  // Description:
  // Label volume
  vtkSetStringMacro(LabelVolRefID);
  vtkGetStringMacro(LabelVolRefID);
  
  // Description:
  // Clip Type Union or Intersection
  vtkSetStringMacro(ClipType);
  vtkGetStringMacro(ClipType);

  // Description:
  // Clipping state
  //vtkBooleanMacro(ClipState,int);
  vtkSetMacro(ClipState,int);
  vtkGetMacro(ClipState,int);
 
protected:
  vtkMrmlCrossSectionNode();
  ~vtkMrmlCrossSectionNode();
  vtkMrmlCrossSectionNode(const vtkMrmlCrossSectionNode&);
  void operator=(const vtkMrmlCrossSectionNode&);

  // Strings
  char *Direction;
  char *BackVolRefID;
  char *ForeVolRefID;
  char *LabelVolRefID;
  char *ClipType; // Union or Intersection
  
  // Numbers
  int Position;
  int SliceSlider;
  int RotatorX;
  int RotatorY;
  float Zoom;
  
  // Booleans
  int InModel;

  // int flag - 0, 1, 2
  int ClipState;

};

#endif
