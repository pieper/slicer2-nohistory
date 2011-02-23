/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPrincipalAxes.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#ifndef __vtk_principal_axes_h
#define __vtk_principal_axes_h
#include <vtkMorphometricsConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkSetGet.h>
// ---------------------------------------------------------
// Author: Axel Krauth
//
// This class computes the principal axes of the input.
// The direction of the eigenvector for the largest eigenvalue is the XAxis,
// the direction of the eigenvector for the smallest eigenvalue is the ZAxis,
// and the YAxis the the eigenvector for the remaining eigenvalue.

class VTK_MORPHOMETRICS_EXPORT vtkPrincipalAxes : public vtkPolyDataToPolyDataFilter
{
 public:
  static vtkPrincipalAxes* New();
  void Delete();
  vtkTypeMacro(vtkPrincipalAxes,vtkPolyDataToPolyDataFilter);

  vtkGetVector3Macro(Center,vtkFloatingPointType);
  vtkGetVector3Macro(XAxis,vtkFloatingPointType);
  vtkGetVector3Macro(YAxis,vtkFloatingPointType);
  vtkGetVector3Macro(ZAxis,vtkFloatingPointType);
  void Execute();
  void PrintSelf();
 protected:
  vtkPrincipalAxes();
  ~vtkPrincipalAxes();

 private:
  vtkPrincipalAxes(vtkPrincipalAxes&);
  void operator=(const vtkPrincipalAxes);

  vtkFloatingPointType* Center;
  vtkFloatingPointType* XAxis;
  vtkFloatingPointType* YAxis;
  vtkFloatingPointType* ZAxis;

  // a matrix of the eigenvalue problem
  double** eigenvalueProblem;
  // for efficiency reasons parts of the eigenvalue problem are computed separately
  double** eigenvalueProblemDiag;
  double** eigenvectors;
  double* eigenvalues;
};

#endif
