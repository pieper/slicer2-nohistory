/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistancePredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_distance_predicate_h
#define __vtk_distance_predicate_h
#include <vtkMorphometricsConfigure.h>
#include "vtkPredicate.h"
#include "vtkConvexHullInexact.h"
#include <vtkSetGet.h>
#include <float.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// The predicate this class represents is true for a point x if
// its distance to the convex hull Hull is smaller or equal to
// MaximalDistance. If OnlyInside is set to true, x also has to 
// be inside Hull.
// Main use for this class is to find extremal points of polydata 
// by setting Hull to the convex hull of the polydata.
class VTK_MORPHOMETRICS_EXPORT vtkDistancePredicate : public vtkPredicate
{
  public:
  static vtkDistancePredicate* New();
  void Delete();
  vtkTypeMacro(vtkDistancePredicate,vtkPredicate);
  
  vtkSetObjectMacro(Hull,vtkConvexHullInexact);

  vtkSetMacro(OnlyInside,bool);
  vtkGetMacro(OnlyInside,bool);

  vtkSetClampMacro(MaximalDistance,vtkFloatingPointType,0,FLT_MAX);
  vtkGetMacro(MaximalDistance,vtkFloatingPointType);
  
  // override in order to reflect changes in Hull
  unsigned long int GetMTime();


  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkDistancePredicate();
  ~vtkDistancePredicate();

 private:
  vtkDistancePredicate(vtkDistancePredicate&);
  void operator=(const vtkDistancePredicate);
  vtkConvexHullInexact* Hull;
  bool OnlyInside;
  vtkFloatingPointType MaximalDistance;
};

#endif
