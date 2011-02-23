/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_predicate__h
#define __vtk_predicate__h
#include <vtkMorphometricsConfigure.h>
#include <vtkObject.h>
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// An object of type vtkPredicate represents a predicate P 
// for points in R^3. Two function have to be implemented:
//  - InitP : Called to give the predicate the opportunity to
//            update itself prior to calling P a lot of times.
//  -     P : returns true for a Point x iff P holds for x.
//            This function gets called quite often.
class VTK_MORPHOMETRICS_EXPORT vtkPredicate : public vtkObject
{
 public:
  static vtkPredicate* New();
  void Delete();
  vtkTypeMacro(vtkPredicate,vtkObject);
  void PrintSelf();
  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkPredicate();
  ~vtkPredicate();

  void Execute();
 private:
  vtkPredicate(vtkPredicate&);
  void operator=(const vtkPredicate);
};

#endif
