/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMathUtils.h,v $
  Date:      $Date: 2006/04/19 18:57:21 $
  Version:   $Revision: 1.17 $

=========================================================================auto=*/
#ifndef __vtkMathUtils_h
#define __vtkMathUtils_h

#include "vtkObject.h"
#include "vtkPoints.h"
#include "vtkMatrix4x4.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMathUtils : public vtkObject
{
  public:
  static vtkMathUtils *New() {return new vtkMathUtils;};

  static int PrincipalMomentsAndAxes( vtkPoints *Points, vtkDataArray *Weights,
                                      vtkDataArray *Values, vtkDataArray *Vectors );
  static int AlignPoints( vtkPoints *Data, vtkPoints *Ref,
                          vtkMatrix4x4 *Xform );
  static void SVD3x3( vtkFloatingPointType A[][3], vtkFloatingPointType U[][3], vtkFloatingPointType W[], vtkFloatingPointType V[][3] );
  
  // Description:
  // Outer product of two 3-vectors.
  // VTK has a vtkMath::Outer
  static void Outer3(vtkFloatingPointType x[3], vtkFloatingPointType y[3], vtkFloatingPointType A[3][3]);

  // Description:
  // Outer product of two 2-vectors.
  // VTK has a vtkMath::Outer2D
  static void Outer2(vtkFloatingPointType x[2], vtkFloatingPointType y[2], vtkFloatingPointType A[2][2]);

  // Description:
  // General matrix multiplication.  You must allocate
  // output storage.
  // See also: vtkMath::MatrixMultiply
  static void MatrixMultiply(double **A, double **B, double **C, int rowA, 
                 int colA, int rowB, int colB);
  // Description:
  // Dump matrix contents to cout
  static void PrintMatrix(double **A, int rowA, int colA);
  // Description:
  // For use in PrintSelf Methods 
  static void PrintMatrix(double **A, int rowA, int colA, ostream& os, 
                          vtkIndent indent);
};

#endif
