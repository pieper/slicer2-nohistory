/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataTetraMesh.h,v $
  Date:      $Date: 2006/02/14 20:40:13 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
// .NAME vtkMrmlDataTetraMesh - Object used in the slicer to perform
// everything related to the access and display of image data (volumes).
// .SECTION Description
// Used in conjunction with a vtkMrmlDataTetraMeshNode (which neatly describes
// display settings, file locations, etc.).  Essentially, the MRML 
// node gives the high level description of what this class should 
// actually do with the ImageData.
// 

#ifndef __vtkMrmlDataTetraMesh_h
#define __vtkMrmlDataTetraMesh_h

//#include <fstream.h>
#include <stdlib.h>
//#include <iostream.h>

#include "vtkMrmlData.h"

#include "vtkMrmlTetraMeshNode.h"
#include "vtkUnstructuredGrid.h"
#include "vtkSlicer.h"

//----------------------------------------------------------------------------
class VTK_SLICER_BASE_EXPORT vtkMrmlDataTetraMesh : public vtkMrmlData
{
public:
  static vtkMrmlDataTetraMesh *New();
  vtkTypeMacro(vtkMrmlDataTetraMesh,vtkMrmlData);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Provides opportunity to insure internal consistency before access. 
  // Transfers all ivars from MrmlNode to internal VTK objects
  void Update();
  unsigned long int GetMTime();

  // Description:
  // Set the image data
  // Use GetOutput to get the image data.
  vtkSetObjectMacro(TheMesh, vtkUnstructuredGrid);
  vtkUnstructuredGrid* GetOutput();

  // Description:
  // Read/Write image 
  int Read();
  int Write();

protected:
  vtkMrmlDataTetraMesh();
  ~vtkMrmlDataTetraMesh();
  vtkMrmlDataTetraMesh(const vtkMrmlDataTetraMesh&);
  void operator=(const vtkMrmlDataTetraMesh&);

  // Description: 
  // If Data has not be created, create it.
  void CheckMrmlNode();

  vtkUnstructuredGrid *TheMesh;
};

#endif
