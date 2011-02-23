/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlPathNode.h,v $
  Date:      $Date: 2006/02/14 20:47:10 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/
// .NAME vtkMrmlPathNode - MRML node to represent a path.
// .SECTION Description
//

#ifndef __vtkMrmlPathNode_h
#define __vtkMrmlPathNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlPathNode : public vtkMrmlNode
{
public:
  static vtkMrmlPathNode *New();
  vtkTypeMacro(vtkMrmlPathNode,vtkMrmlNode);
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
  // Name of the Camera Path (cPath) color, which is defined by a Color node in a MRML file
 //  vtkSetStringMacro(cPathColor);
 // vtkGetStringMacro(cPathColor);

  // Description:
  // Name of the Focal Point Path (fPath) color, which is defined by a Color node in a MRML file
  // vtkSetStringMacro(fPathColor);
  // vtkGetStringMacro(fPathColor);

  // Description:
  // Name of the Camera Landmarks (cLand) color, which is defined by a Color node in a MRML file
  // vtkSetStringMacro(cLandColor);
  // vtkGetStringMacro(cLandColor);

  // Description:
  // Name of the Focal Point Landmarks (fPath) color, which is defined by a Color node in a MRML file
  // vtkSetStringMacro(fLandColor);
  // vtkGetStringMacro(fLandColor);

protected:
  vtkMrmlPathNode();
  ~vtkMrmlPathNode();
  vtkMrmlPathNode(const vtkMrmlPathNode&);
  void operator=(const vtkMrmlPathNode&);

//  char *cPathColor;
//  char *fPathColor;
//  char *cLandColor;
//  char *fLandColor;

};

#endif

