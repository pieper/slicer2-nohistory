/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkConvexHullInexact.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtk_convex_hull_inexact_h
#define __vtk_convex_hull_inexact_h
#include <vtkMorphometricsConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkPoints.h>
#include <vtkSetGet.h>
#include <vtkHull.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// This class implements a fast approximation of the convex hull of
// its input as well as a function for deciding whether a point is 
// inside the convex hull and a function for computing the distance
// of a point to the convex hull.

class VTK_MORPHOMETRICS_EXPORT vtkConvexHullInexact : public vtkPolyDataToPolyDataFilter
{
  public:
  static vtkConvexHullInexact* New();
  void Delete();
  vtkTypeMacro(vtkConvexHullInexact,vtkPolyDataToPolyDataFilter);
  void PrintSelf();
 
  bool Inside(vtkFloatingPointType* x);

  // When a point is inside the hull, the exact distance to the surface of the hull is returned.
  // When a point is outside of the hull, this function may return
  // FLT_MAX when it couldn't find the projection point of x onto the hull.
  // In that case an error message is printed.
  vtkFloatingPointType DistanceFromConvexHull(vtkFloatingPointType* x);
  vtkFloatingPointType DistanceFromConvexHull(vtkFloatingPointType x,vtkFloatingPointType y,vtkFloatingPointType z);
  void SetGranularity(int newGranularity);
 protected:
  vtkConvexHullInexact();
  ~vtkConvexHullInexact();

  void Execute();
 private:
  vtkConvexHullInexact(vtkConvexHullInexact&);
  void operator=(const vtkConvexHullInexact);

  //dimension of input points. The implementation assumes 
  // at several locations that Dimension == 3. I've left
  // this as a member to ensure readability of the algorithms.
  int Dimension; 
  
  // A positive number. The higher Granularity is, the exacter the approximation is.
  // Warning: This number has great impact on the efficiency of all other functions.
  // A value of 1 yields a coarse approximation, setting it to 2 yields a good 
  // approximation/efficiency tradeoff, 3 a slightly better approximation, for anything
  // higher the efficiency goes to hell.
  // In a nutshell: If you want something really fast, use 1, otherwise start with 2 and
  // try whether your code in overall goes faster with larger values of Granularity.
  int Granularity;

  // a value derived from Granularity and Dimension.
  int NumberNormals;

  // the _real_ internal representation of the convex hull.
  // its size is 3*((2*Granularity +1)^Dimension - (2*Granularity-1)^Dimension)
  vtkFloatingPointType*** ConvexHull;

  //  Compute ConvexHull for the given set of points
  void UpdateConvexHull(vtkPoints*);

  // Convenience function. Returns true iff
  // at least one entry of n equals Granularity or -Granularity
  bool AtLeastOneNeighbourDistEntry(vtkFloatingPointType* n);

  // Convenience function. Returns true iff
  // n is strictly positive regarding lexicographic order.
  bool LexPositive(vtkFloatingPointType* n);

  // Convenience function. Updates n to the next
  // larger vector fulfilling AtLeastOneNeighbourDistEntry
  // and LexPositive
  void NextNormal(vtkFloatingPointType* n);

  // Visualization of convex hull
  vtkHull* GeometricRepresentation;
};

#endif
