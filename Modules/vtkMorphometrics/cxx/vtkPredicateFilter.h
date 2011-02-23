/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPredicateFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_predicate_filter_h
#define __vtk_predicate_filter_h
#include <vtkMorphometricsConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkPoints.h>
#include <vtkCellArray.h>
#include <vtkPredicate.h>
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// Given a predicate P, filter the input polydata to only those
// points in input_polydata->GetPoints() which fulfill P. Furthermore
// keep only those polys,strips for which every point fulfills P.
// This may split strips into parts if a point inside the strip
// doesn't fulfill P. Which predicate is used is set by SetPredicate.
// This is useful if you want to experiment with different point-wise predicates
class VTK_MORPHOMETRICS_EXPORT vtkPredicateFilter : public vtkPolyDataToPolyDataFilter
{
  public:
  static vtkPredicateFilter* New();
  void Delete();
  vtkTypeMacro(vtkPredicateFilter,vtkPolyDataToPolyDataFilter);

  vtkSetObjectMacro(Predicate,vtkPredicate);
  void PrintSelf();

  // overriding superclass implementation in order to
  // reflect changes in the Predicate member
  unsigned long int GetMTime();

 protected:
  vtkPredicateFilter();
  ~vtkPredicateFilter();

  void Execute();
  // Filter to those strips where every point x of the strip
  // fulfills Predicate->P(x).
  void ExecuteUpdateStrips(vtkPolyData* in,vtkPolyData* out);

  // Filter to those polys where every point x of the poly
  // fulfills Predicate->P(x).
  void ExecuteUpdatePolys(vtkPolyData* in,vtkPolyData* out);
 private:
  vtkPredicateFilter(vtkPredicateFilter&);
  void operator=(const vtkPredicateFilter);
  vtkPredicate* Predicate;
};
#endif
