/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkLargeLeastSquaresProblem.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_large_least_squares_problem_h
#define __vtk_large_least_squares_problem_h
#include <vtkMorphometricsConfigure.h>
#include <vtkObject.h>
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// A class for solving large least squares problem. It accomplishes this
// by reducing the problem each time it gets too large to an equivalent
// problem of smaller size.
//
// If you want to use this class, call Initialize first, then add each line
// of your least squares problem and finally call Solve.
//
// Furthermore you can set the member NumberIncreasement. Basically this is 
// a controller for the space/time tradeoff of the algorithm used for 
// reducing the problem. Decreasing the default value results in more 
// reductions but the matrix used for the reduction stays small, whereas
// increasing it results in less reductions but the matrix used for the 
// reduction enlarges. The size of that matrix depend quadratically on
// NumberIncreasement. In a nutshell: Start with the default and try
// whether increasements of NumberIncreasement speed up your program, they
// should speed up until NumberIncreasement is so large that the reduction
// algorithm starts generating cache misses.
//
// A least squares problem of the form A x - b= 0 can be reduced to a smaller
// problem if A has more rows than columns. In that case one can use QR factorization
// on Ab, a matrix composed of A and b, in order to get an upper triangular
// matrix R and an orthogonal Matrix Q. Then R is a least squares problem
// which is equivalent to the initial problem. Since R is upper triangular, the
// rows below the #columns - row are all zero, which have no influence on the result
// and can therefore be reused for inserting new lines of the linear problem.
// NumberIncreasement is the number of extra rows below the #columns-rows.
//
// For efficiency reasons some temporary variables needed for reducing the problem,
// namely Householder,tempAb and omega, are object members. The reason is that each 
// reduction would involve allocating those arrays.
class VTK_MORPHOMETRICS_EXPORT vtkLargeLeastSquaresProblem : public vtkObject
{
  public:
  static vtkLargeLeastSquaresProblem* New();
  void Delete();
  vtkTypeMacro(vtkLargeLeastSquaresProblem,vtkObject);
  
  // has to be set prior to calling Initialize
  vtkSetMacro(NumberIncreasement,int);
  vtkGetMacro(NumberIncreasement,int);

  void Initialize(int NumberVariables);
  void AddLine(double* Entries,double beta);
  void Solve(double* Result);

  void PrintSelf();
 protected:
  vtkLargeLeastSquaresProblem();
  ~vtkLargeLeastSquaresProblem();

  void Execute();
 private:
  vtkLargeLeastSquaresProblem(vtkLargeLeastSquaresProblem&);
  void operator=(const vtkLargeLeastSquaresProblem);

  // the current least squares problem in the form A x -b = 0
  // this is the required form for using the QR-Factorization
  // as a reduction algorithm for the problem.
  double** Ab;

  // Construction of the smaller problem requires multiplication
  // of Q with Ab and we want to use Ab as storage for the new
  // problem, we have to copy Ab temporarily.
  double** tempAb;

  // The algorithm used for QR-Factorization is iterative
  // generation of the corresponding householder matrix. 
  // Householder is the householder matrix
  // omega is a vector needed for constructing the householder matrix
  double** Householder;
  double*  omega;


  // NumberColumns = NumberVariables + 1
  // in the extra column b is stored.
  int NumberColumns;
  // NumberRows is a derived value. It's a member to ensure readability
  // NumberRows := NumberColumns + NumberIncreasement
  int NumberRows;

  // strictly positive
  int NumberIncreasement;

  // index which indicates the index of the next free line in Ab
  int CurrentIndex;

  // reduce Ab to an upper triangular matrix which
  // is equivalent to the problem Ab
  void Reduce();
  
  // Sets Householder to the householder matrix which 
  // multiplied with Ab results in a matrix where
  // the i-th column is upper triangular
  void GenerateHouseholder(int i);
};

#endif
