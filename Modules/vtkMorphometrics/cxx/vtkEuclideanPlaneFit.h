/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEuclideanPlaneFit.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtk_euclidean_plane_fit_h
#define __vtk_euclidean_plane_fit_h
#include <vtkMorphometricsConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkPlaneSource.h>
#include "vtkPrincipalAxes.h"
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// Plane fitting by using the principal axes of the input

class VTK_MORPHOMETRICS_EXPORT vtkEuclideanPlaneFit : public vtkPolyDataToPolyDataFilter
{
 public:
  static vtkEuclideanPlaneFit* New();
  void Delete();
  vtkTypeMacro(vtkEuclideanPlaneFit,vtkPolyDataToPolyDataFilter);

  vtkGetVector3Macro(Center,vtkFloatingPointType);
  vtkGetVector3Macro(Normal,vtkFloatingPointType);

  void PrintSelf();
 protected:
  vtkEuclideanPlaneFit();
  ~vtkEuclideanPlaneFit();

  void Execute();
 private:
  vtkEuclideanPlaneFit(vtkEuclideanPlaneFit&);
  void operator=(const vtkEuclideanPlaneFit);

  vtkFloatingPointType* Center;
  vtkFloatingPointType* Normal;

  vtkPrincipalAxes* CoordinateSystem;
  vtkPlaneSource* FittingPlane;
};

#endif
