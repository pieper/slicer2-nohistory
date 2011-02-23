/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPWConstantIT.h,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkPWConstantIT_h
#define __vtkPWConstantIT_h

#include <vtkAGConfigure.h>

#include <vtkIntensityTransform.h>

class VTK_AG_EXPORT vtkPWConstantIT : public vtkIntensityTransform
{
public:
  static vtkPWConstantIT* New();
  vtkTypeMacro(vtkPWConstantIT,vtkIntensityTransform);
  void PrintSelf(ostream& os, vtkIndent indent);
      
  void SetNumberOfFunctions(int n);
  int FunctionValues(vtkFloatingPointType* x, vtkFloatingPointType* f);

  void SetNumberOfPieces(int i, int p);
  int GetNumberOfPieces(int i);
  
  void SetBoundary(int i, int j, int p);
  int GetBoundary(int i,int j);
  
  void SetValue(int i,int j,int v);
  int GetValue(int i,int j);
  
protected:
  vtkPWConstantIT();
  ~vtkPWConstantIT();
  vtkPWConstantIT(const vtkPWConstantIT&);
  void operator=(const vtkPWConstantIT&);

  void DeleteFunction(int i);
  void DeleteFunctions();
  void BuildFunction(int i);
  void BuildFunctions();

  int* NumberOfPieces;
  int** Boundaries;
  int** Values;
};

#endif


