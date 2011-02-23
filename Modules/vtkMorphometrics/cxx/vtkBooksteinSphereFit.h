/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBooksteinSphereFit.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtk_bookstein_sphere_fit_h
#define __vtk_bookstein_sphere_fit_h
#include <vtkMorphometricsConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkSphereSource.h>
#include <vtkPoints.h>
#include <vtkSetGet.h>
#include "vtkLargeLeastSquaresProblem.h"
//---------------------------------------------------------
// Author: Axel Krauth
//
// This class implements sphere fitting with the Bookstein
// algorithm. 
//
// The result isn't the best fitting sphere for euclidean distance
// but a very good approximation of it. The main advantage of this
// algorithm lies in the fast computation of the sphere.
class VTK_MORPHOMETRICS_EXPORT vtkBooksteinSphereFit : public vtkPolyDataToPolyDataFilter
{
  public:
  static vtkBooksteinSphereFit* New();
  void Delete();
  vtkTypeMacro(vtkBooksteinSphereFit,vtkPolyDataToPolyDataFilter);
  
  vtkGetVector3Macro(Center,vtkFloatingPointType);
  vtkGetMacro(Radius,vtkFloatingPointType);
  
  void PrintSelf();
  protected:
  vtkBooksteinSphereFit();
  ~vtkBooksteinSphereFit();
  
  void Execute();
  private:
  vtkBooksteinSphereFit(vtkBooksteinSphereFit&);
  void operator=(const vtkBooksteinSphereFit);
  
  // used for visualizing the result of the sphere fit
  vtkSphereSource* Base;
  vtkFloatingPointType* Center;
  vtkFloatingPointType  Radius;
  
  // Sphere fitting with the Bookstein algorithm is
  // a least squares problem whose matrix has
  // input->GetNumberPoints() many rows.
  vtkLargeLeastSquaresProblem* Solver;

  // Derive from the solution of the least squares problem 
  // the geometrical solution.
  void GeometricalSolution(vtkFloatingPointType alpha,vtkFloatingPointType beta,vtkFloatingPointType gamma,vtkFloatingPointType delta);

  // the quality of the radius can be improved by using
  // the radius a euclidean best fitting sphere would have
  void BestEuclideanFitRadius(vtkPoints* points);
};

#endif
