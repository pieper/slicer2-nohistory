/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEuclideanLineFit.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtk_euclidean_line_fit_h
#define __vtk_euclidean_line_fit_h
#include <vtkMorphometricsConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkCylinderSource.h>
#include <vtkTransformFilter.h>
#include <vtkTransform.h>
#include <vtkPrincipalAxes.h>
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// Line fitting by using the center and eigenvector of
// the largest eigenvalue of the principal axes of 
// the input.
class VTK_MORPHOMETRICS_EXPORT vtkEuclideanLineFit : public vtkPolyDataToPolyDataFilter
{
 public:
  static vtkEuclideanLineFit* New();
  void Delete();
  vtkTypeMacro(vtkEuclideanLineFit,vtkPolyDataToPolyDataFilter);

  vtkGetVector3Macro(Center,vtkFloatingPointType);
  vtkGetVector3Macro(Direction,vtkFloatingPointType);

  void PrintSelf();
 protected:
  vtkEuclideanLineFit();
  ~vtkEuclideanLineFit();

  void Execute();
 private:
  vtkEuclideanLineFit(vtkEuclideanLineFit&);
  void operator=(const vtkEuclideanLineFit);

  // result is visualized by an oriented long and thin cylinder
  vtkCylinderSource* Base;
  vtkTransformFilter* OrientationFilter;
  vtkTransform* Orientation;

  vtkFloatingPointType* Center;
  vtkFloatingPointType* Direction;

  vtkPrincipalAxes* CoordinateSystem;

  // changes the transform so that the
  // resulting cylinder axis equals Direction
  void UpdateDirection();
};

#endif
