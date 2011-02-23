/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkConePredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_cone_predicate_h
#define __vtk_cone_predicate_h
#include <vtkMorphometricsConfigure.h>
#include "vtkPredicate.h"
#include "vtkAxisSource.h"
#include <vtkSetGet.h>

//---------------------------------------------------------
// Author: Axel Krauth
//
// this class represents an implicitly given cone. The cone is specified 
// by the axis of the cone and an angle. The center of the axis is
// the basis of the cone. A point p is inside the cone iff the vector
// from the basis of the cone to p has an angle to the axis smaller
// than the specified angle.
class VTK_MORPHOMETRICS_EXPORT vtkConePredicate : public vtkPredicate
{
  public:
  static vtkConePredicate* New();
  void Delete();
  vtkTypeMacro(vtkConePredicate,vtkPredicate);
  void PrintSelf();
  
  vtkSetObjectMacro(Axis,vtkAxisSource);

  vtkSetMacro(MaximalAngle,vtkFloatingPointType);
  vtkGetMacro(MaximalAngle,vtkFloatingPointType);

  // override in order to reflect changes in Axis
  unsigned long int GetMTime();


  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkConePredicate();
  ~vtkConePredicate();

 private:
  vtkConePredicate(vtkConePredicate&);
  void operator=(const vtkConePredicate);

  vtkAxisSource* Axis;

  vtkFloatingPointType MaximalAngle;

  // for deciding P(x) I currently need a vector pointer
  // this is the temp variable for this
  vtkFloatingPointType* DiffVector;
};

#endif
