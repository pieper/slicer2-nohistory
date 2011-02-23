/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkHalfspacePredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_halfspace_predicate_h
#define __vtk_halfspace_predicate_h
#include <vtkMorphometricsConfigure.h>
#include "vtkPredicate.h"
#include <vtkPlaneSource.h>
#include <vtkSetGet.h>
#include <vtkMath.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// This predicate this class represents yields true for all points x for which
// vtkMath::Dot(n,x0) =< vtkMath::Dot(n,x) , which is a halfspace
// represented with the hessian normal form of a plane
// where n is the normal of the plane (Halfspace->GetNormal())
//  and x0 is the center of the plane (Halfspace->GetCenter())
// 
class VTK_MORPHOMETRICS_EXPORT vtkHalfspacePredicate : public vtkPredicate
{
  public:
  static vtkHalfspacePredicate* New();
  void Delete();
  vtkTypeMacro(vtkHalfspacePredicate,vtkPredicate);
  void PrintSelf();
  void SetPlane(vtkPlaneSource*);
  
  // override in order to reflect changes in Halfspace
  unsigned long int GetMTime();

  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkHalfspacePredicate();
  ~vtkHalfspacePredicate();

 private:
  vtkHalfspacePredicate(vtkHalfspacePredicate&);
  void operator=(const vtkHalfspacePredicate);

  vtkPlaneSource* Halfspace;
  vtkFloatingPointType* Normal;
  vtkFloatingPointType* Origin;

  // p = vtkMath::Dot(Normal,Origin)
  vtkFloatingPointType p;
};

#endif
