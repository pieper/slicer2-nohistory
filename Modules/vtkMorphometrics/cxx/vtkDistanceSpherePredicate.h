/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistanceSpherePredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_distance_sphere_predicate_h
#define __vtk_distance_sphere_predicate_h
#include <vtkMorphometricsConfigure.h>
#include "vtkPredicate.h"
#include <vtkSphereSource.h>
#include <vtkSetGet.h>
#include <float.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// This class filters points according to their distance from
// the surface of a sphere. Additionaly the flag OnlyInside can
// be set.
class VTK_MORPHOMETRICS_EXPORT vtkDistanceSpherePredicate : public vtkPredicate
{
  public:
  static vtkDistanceSpherePredicate* New();
  void Delete();
  vtkTypeMacro(vtkDistanceSpherePredicate,vtkPredicate);
  void PrintSelf();
  
  vtkSetObjectMacro(Sphere,vtkSphereSource);

  vtkSetMacro(OnlyInside,bool);
  vtkGetMacro(OnlyInside,bool);


  vtkSetClampMacro(MaximalDistance,vtkFloatingPointType,0,FLT_MAX);
  vtkGetMacro(MaximalDistance,vtkFloatingPointType);
  
  // override in order to reflect changes in Sphere
  unsigned long int GetMTime();


  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkDistanceSpherePredicate();
  ~vtkDistanceSpherePredicate();

 private:
  vtkDistanceSpherePredicate(vtkDistanceSpherePredicate&);
  void operator=(const vtkDistanceSpherePredicate);

  vtkSphereSource* Sphere;
  bool OnlyInside;
  vtkFloatingPointType MaximalDistance;
};

#endif
