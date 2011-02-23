/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.
  Program:   3D Slicer
  Module:    $RCSfile: vtkFastCellPicker.h,v $
  Date:      $Date: 2006/03/06 19:02:25 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkFastCellPicker - select a cell by shooting a ray into graphics window
// .SECTION Description
// vtkFastCellPicker is used to select a cell by shooting a ray into graphics
// window and intersecting with actor's defining geometry - specifically 
// its cells. Beside returning coordinates, actor and mapper, vtkCellPicker
// returns the id of the closest cell within the tolerance along the pick
// ray, and the dataset that was picked.
// .SECTION See Also
// vtkPicker vtkPointPicker

#ifndef __vtkFastCellPicker_h
#define __vtkFastCellPicker_h

#include "vtkVersion.h"
#include "vtkCollection.h"
#include "vtkAssemblyPath.h"
#include "vtkDataSet.h"
#include "vtkMapper.h"
#include "vtkActor.h"
#include "vtkPicker.h"
#include "vtkOBBTree.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkFastCellPicker : public vtkPicker
{
public:
  vtkFastCellPicker();
//  static vtkFastCellPicker *New() {return new vtkFastCellPicker;};
static vtkFastCellPicker *New();
//  const char *GetClassName() {return "vtkFastCellPicker";};
vtkTypeMacro(vtkFastCellPicker,vtkPicker);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Get the id of the picked cell. If CellId = -1, nothing was picked.
  vtkGetMacro(CellId,int);

  // Description:
  // Get the subId of the picked cell. If SubId = -1, nothing was picked.
  vtkGetMacro(SubId,int);

  // Description:
  // Get the parametric coordinates of the picked cell. Only valid if 
  // pick was made.
  vtkGetVectorMacro(PCoords,vtkFloatingPointType,3);

protected:
  int CellId; // picked cell
  int SubId; // picked cell subId
  vtkFloatingPointType PCoords[3]; // picked cell parametric coordinates

#if (VTK_MAJOR_VERSION == 3 && VTK_MINOR_VERSION == 2) || (VTK_MAJOR_VERSION >= 4)
  virtual vtkFloatingPointType IntersectWithLine(vtkFloatingPointType p1[3], vtkFloatingPointType p2[3], vtkFloatingPointType tol, 
                  vtkAssemblyPath *assem, vtkActor *a, vtkMapper *m);
#else
  virtual vtkFloatingPointType IntersectWithLine(vtkFloatingPointType p1[3], vtkFloatingPointType p2[3], vtkFloatingPointType tol, 
                  vtkActor *assem, vtkActor *a, vtkMapper *m);
#endif
  void Initialize();
  vtkCollection *OBBTrees;
};

#endif


