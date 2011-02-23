/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPolygonList.h,v $
  Date:      $Date: 2006/02/14 20:40:16 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

    vtkPolygonList
    Created by Chand T. John for Slicer/NMBL Pipeline

=========================================================================*/
// .NAME vtkPolygonList - represent and manipulate list of 3D polygons
// .SECTION Description
// vtkPolygonList represents a list of 3D polygons. The data model for
// vtkPolygonList is a linked list of polygons, each of which is an array
// of vx-vy-vz triplets accessible by (point or cell) id (see vtkPoints).

#ifndef __vtkPolygonList_h
#define __vtkPolygonList_h

#include "vtkObject.h"
#include "vtkPoints.h"
#include "point.h"
#include "vtkSlicer.h"

// If you change this number here, it will need to be changed in
// SLICER_HOME/Base/tcl/tcl-modules/Editor/EdDraw.tcl's EdDrawApply
// procedure in a for loop that contains "{$p < 20}".
#define NUM_POLYGONS 20

class VTK_SLICER_BASE_EXPORT vtkPolygonList : public vtkObject
{
public:
  static vtkPolygonList *New();
  vtkTypeMacro(vtkPolygonList,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Make polygon p look empty but do not delete memory.
  void Reset(int p);

  // Description:
  // Return number of points in polygon p.
  int GetNumberOfPoints(int p);

  // Description:
  // Return a pointer to an array of points for a specific id.
  vtkPoints *GetPolygon(int p);

  // Description:
  // Return a pointer to a sampling of polygon p.
  vtkPoints *GetSampledPolygon(int p);

  // Description:
  // Store ith point of polygon p into ctlpoint array.
  void GetPoint(int p, int i);

  // Description:
  // Returns lowest index in which there is an empty polygon.
  int GetInsertPosition();

  // Description:
  // Returns lowest index at or after p in which there is an empty polygon.
  int GetNextInsertPosition(int p);

  // Description:
  // Returns lowest index in which there is a nonempty polygon.
  int GetRetrievePosition();

  // Description:
  // Returns lowest index after p in which there is a nonempty polygon.
  int GetNextRetrievePosition(int p);

  // Description:
  // Insert point into next available slot. Returns id of slot.
  int InsertNextPoint (int p, double x, double y, double z);

  // Description:
  // Returns density of polygon p.
  int GetDensity (int p);

  // Description:
  // Returns closedness of polygon p.
  int GetClosed(int p);

  // Description:
  // Returns preshape (points/polygon) of polygon p.
  int GetPreshape(int p);

  // Description:
  // Returns label of polygon p.
  int GetLabel(int p);

  // Description:
  // Sets density of polygon p to d.
  void SetDensity (int p, int d);

  // Description:
  // Sets closedness of polygon p.
  void SetClosed (int p, int closed);

  // Description:
  // Sets preshape (points/polygon) of polygon p.
  void SetPreshape (int p, int preshape);

  // Description:
  // Sets label of polygon p.
  void SetLabel (int p, int label);

  // Description:
  // Updates order array for addition of polygon p.
  void UpdateApplyOrder (int p);

  // Description:
  // Updates order array for removal of polygon p.
  void RemoveApplyOrder (int p);

  // Description:
  // Returns number of polygons to apply next time Apply is clicked.
  int GetNumApplyable ();

  // Description:
  // Returns index of qth polygon to apply.
  int GetApplyable (int q);

  // Description:
  // Removes all polygons.
  void Clear ();

protected:
  vtkPolygonList();
  ~vtkPolygonList();
  vtkPolygonList(const vtkPolygonList&);  // Not implemented.
  void operator=(const vtkPolygonList&);  // Not implemented.

  vtkPoints *Polygons[NUM_POLYGONS];
  int densities[NUM_POLYGONS]; // Sampling densities
  int closed[NUM_POLYGONS]; // Whether each contour is closed or not
  int preshape[NUM_POLYGONS]; // Preshape (points/polygon) of each contour
  int label[NUM_POLYGONS]; // Labelmap number for each polygon
  int order[NUM_POLYGONS]; // Order in which to apply polygons (for overlap)
  int currentOrder; // Index of highest non-"-1" entry in order array
  Point ctlpoint; // Stores a point for GetFirstPoint and GetLastPoint
  vtkPoints            *Samples;
};

#endif

