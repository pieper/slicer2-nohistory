/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkVectorToOuterProductDualBasis.h,v $
  Date:      $Date: 2006/02/14 20:54:15 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkVectorToOuterProductDualBasis 
// .SECTION Description
//  Implementation in VTK of C-F Westin's method 
//  for calculating a dual basis.

#ifndef __vtkVectorToOuterProductDualBasis_h
#define __vtkVectorToOuterProductDualBasis_h

#include "vtkTensorUtilConfigure.h"
#include "vtkObject.h"

class VTK_TENSORUTIL_EXPORT vtkVectorToOuterProductDualBasis : public vtkObject
{
public:
  static vtkVectorToOuterProductDualBasis *New();
  vtkTypeMacro(vtkVectorToOuterProductDualBasis,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // The number of input vectors to use when creating the
  // outer products.  Call this before setting input
  // vectors since it does the allocation.
  void SetNumberOfInputVectors(int num);
  vtkGetMacro(NumberOfInputVectors,int);

  // Description:
  // Set number "num" input vector.
  void SetInputVector(int num, vtkFloatingPointType vector[3]);
  void SetInputVector(int num, vtkFloatingPointType v0, vtkFloatingPointType v1, vtkFloatingPointType v2);
  
  // Description:
  // Get number "num" input vector.
  vtkFloatingPointType *GetInputVector(int num)
    {
      return this->V[num];
    };

  // Description:
  // Calculate output based on input vectors.
  void CalculateDualBasis();

  // Description:
  // Access the output of this class (after calling
  // CalculateDualBasis to calculate this from input vectors).
  // The matrix dimensions are NumberOfInputVectorsx9.
  double **GetPseudoInverse() {return this->PInv;}

  // Description:
  // Print the PseudoInverse matrix, this->Pinv
  void PrintPseudoInverse(ostream &os);
  // for access from tcl, just dumps to stdout for now
  void PrintPseudoInverse();

   // Description:
   // Singular value decomposition of a mxn matrix.
  // SVD is given by: A = U W V^T;
  // The input arguments are: mxn matrix a, m  and n.
  // The outpur arguments are: w diagonal of matrix W, v matrix and
  // U replaces a on output.
  static int SVD(float **a, int m,int n, float *w, float **v);
  static int SVD(double **a, int m,int n, double *w, double **v);

  // Description:
  // PseudoInverse of a mxn matrix.
  static int PseudoInverse(double **A, double **AI, int m, int n);

protected:
  vtkVectorToOuterProductDualBasis();
  ~vtkVectorToOuterProductDualBasis();
  vtkVectorToOuterProductDualBasis(const vtkVectorToOuterProductDualBasis&);
  void operator=(const vtkVectorToOuterProductDualBasis&);

  int NumberOfInputVectors;

  vtkFloatingPointType **V;
  double **VV;
  double **VVT;

  double **VVTVV;
  double **VVTVVI;
  double **PInv;

  void AllocateInternals();
  void DeallocateInternals();

};

#endif
