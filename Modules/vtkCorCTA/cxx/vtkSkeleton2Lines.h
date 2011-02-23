/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSkeleton2Lines.h,v $
  Date:      $Date: 2006/01/06 17:57:24 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

// .NAME vtkSkeleton2Lines - Creates lines from a skeleton
// .SECTION Description
// .SECTION see also

#ifndef __vtkSkeleton2Lines_h
#define __vtkSkeleton2Lines_h

// Authors: Karl Krissian, Arne Hans
// Brigham and Women's Hospital

#include <vtkCorCTAConfigure.h>
#include "vtkStructuredPointsToPolyDataFilter.h"
#include "vtkImageData.h"


//BTX
//----------------------------------------------------------------------
class extremity {
//    ---------
public:
  int x,y,z;

  extremity()
    {
      x=y=z= 0;
    }

  extremity(int x0, int y0, int z0)
    {
      x  = x0;
      y  = y0;
      z  = z0;
    }
};
//ETX


//----------------------------------------------------------------------
class VTK_CORCTA_EXPORT vtkSkeleton2Lines : public vtkStructuredPointsToPolyDataFilter
//               -----------------
{
public:
  vtkTypeMacro(vtkSkeleton2Lines,vtkStructuredPointsToPolyDataFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Construct instance of vtkSkeleton2Lines 
  static vtkSkeleton2Lines *New();
  
  // Minimum number of points per line
  vtkSetMacro(MinPoints,int);
  vtkGetMacro(MinPoints,int);

protected:
  vtkSkeleton2Lines();
  ~vtkSkeleton2Lines();
  vtkSkeleton2Lines(const vtkSkeleton2Lines&) {};

  void Init();
  void Init_Pos();

  unsigned char CoordOK(vtkImageData* im,int x,int y,int z);

  void ExecuteData(vtkDataObject* output);

//BTX
  int pos[3][3][3];
  int neighbors_pos  [27];
  int neighbors_place[27][3];

  int tx,ty,tz,txy;

  vtkImageData* InputImage; 
  vtkPolyData* OutputPoly;
  
  int MinPoints;
//ETX
};

#endif
