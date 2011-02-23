/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkLargeLeastSquaresProblem.cxx,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include "vtkLargeLeastSquaresProblem.h"
#include <vtkObjectFactory.h>
#include <vtkMath.h>
#include <iostream>


#define EPSILON 0.0000001

void vtkLargeLeastSquaresProblem::Initialize(int NumberVariables)
{
  // free memory
  if(Ab!=NULL)
    {
      for(int i =0;i<NumberRows;i++)
    free(Ab[i]);
      free(Ab);
    }


  if(tempAb!=NULL)
    {
      for(int i =0;i<NumberRows;i++)
    free(tempAb[i]);
      free(tempAb);
    }

  if(Householder!=NULL)
    {
      for(int i =0;i<NumberRows;i++)
    free(Householder[i]);
      free(Householder);
    }

  if(omega!=NULL)
    free(omega);

  // update the internal variables;
  NumberColumns = NumberVariables + 1;
  NumberRows = NumberColumns + NumberIncreasement;
  
  // allocate new memory
  Ab = (double**)malloc(NumberRows * sizeof(double*));
  int i;
  for(i = 0;i<NumberRows;i++)
    Ab[i] = (double*)malloc(NumberColumns * sizeof(double));

  tempAb = (double**)malloc(NumberRows * sizeof(double*));
  for(i = 0;i<NumberRows;i++)
    tempAb[i] = (double*)malloc(NumberColumns * sizeof(double));

  Householder = (double**)malloc(NumberRows * sizeof(double*));
  for(i = 0;i<NumberRows;i++)
    Householder[i] = (double*)malloc(NumberRows * sizeof(double));

  omega = (double*)malloc(NumberRows*sizeof(double));


  // initialize
  for(i=0;i<NumberRows;i++)
    for(int j=0;j<NumberColumns;j++)
      Ab[i][j] = 0;

  for(i=0;i<NumberRows;i++)
    for(int j=0;j<NumberRows;j++)
      Householder[i][j] = 0;

  for(i=0;i<NumberRows;i++)
    omega[i] = 0;

  CurrentIndex = 0;
}

void vtkLargeLeastSquaresProblem::AddLine(double* Entries,double Beta)
{
  if(CurrentIndex==NumberRows) // Matrix is full -> reduce the problem
    {
      Reduce();
      CurrentIndex = NumberColumns;
    }
  
  for(int i =0;i<NumberColumns-1;i++)
    Ab[CurrentIndex][i] = Entries[i];
  Ab[CurrentIndex][NumberColumns-1] = - Beta;
  CurrentIndex++;
}
void vtkLargeLeastSquaresProblem::GenerateHouseholder(int i)
{
  int l;
  // Reset Householder[][] to identity
  for(l=0;l<NumberRows;l++)
    {
      for(int j=0;j<NumberRows;j++)
    Householder[l][j]=0;
      Householder[l][l] = 1;
    }
  
  // test whether we actually have to / can construct a householder matrix
  bool zeroBelowAii = true;
  for(l=i;l<NumberRows;l++)
    {
      if(fabs(Ab[l][i])>EPSILON)
    {
      zeroBelowAii = false;
      break;
    }
    }

  if(zeroBelowAii)
    return;

  // straight forward implementation for
  // generating the householder matrix
  double rho = 0;
  int j;
  for(j = i;j<NumberRows;j++)
    rho += Ab[j][i]*Ab[j][i];
  rho = sqrt(rho);
  if(Ab[i][i] <0)
    rho = -rho;

  int sizeOmega = NumberRows - i;

  omega[0] = Ab[i][i] + rho;
  for(j=1;j<sizeOmega;j++)
    omega[j] = Ab[i+j][i];

  double normOmega = 0;
  for(j=0;j<sizeOmega;j++)
    normOmega += omega[j]*omega[j];
  normOmega = sqrt(normOmega);
  for(j=0;j<sizeOmega;j++)
    omega[j] = omega[j]/normOmega;

  for(j=0;j<sizeOmega;j++)
    for(int k=0;k<sizeOmega;k++)
      {
    Householder[i+j][i+k] = Householder[i+j][i+k] - 2*omega[j]*omega[k];
      }
}

void vtkLargeLeastSquaresProblem::Reduce()
{
  for(int i =0;i<NumberColumns;i++)
    {
      GenerateHouseholder(i);

      // A := Householder*A
      
      // update tempA;
      int k;
      for(k=0;k<NumberRows;k++)
    for(int l=0;l<NumberColumns;l++)
      {
        tempAb[k][l] = Ab[k][l];
        Ab[k][l] = 0;
      }

      
      for(k=0;k<NumberRows;k++)
    for(int l=0;l<NumberColumns;l++)
      for(int m = 0;m<NumberRows;m++)
        Ab[k][l] += Householder[k][m]*tempAb[m][l];
      for(k=i+1;k<NumberRows;k++)
    Ab[k][i] = 0;


    }
}

void vtkLargeLeastSquaresProblem::Solve(double* FinalResult)
{
  // for vtk, we have to split Ab into a matrix A and a matrix b
  double** Result = (double**) malloc((NumberColumns -1)*sizeof(double*));
  int i;
  for(i =0;i<NumberColumns-1;i++)
    {
      Result[i] = (double*)malloc(1*sizeof(double));
      Result[i][0] = 0;
    }
  
  double** b = (double**)malloc(NumberRows*sizeof(double*));

  int k;
  for(k=0;k<NumberRows;k++)
    {
      b[k] = (double*)malloc(1*sizeof(double));
      b[k][0] = Ab[k][NumberColumns -1];
    }

  double** A = (double**)malloc(NumberRows*sizeof(double*));
  for(i=0;i<NumberRows;i++)
    {
      A[i] = (double*)malloc((NumberColumns-1)*sizeof(double));
      for(int j=0;j<NumberColumns-1;j++)
    A[i][j]=Ab[i][j];
    }
  
  vtkMath::SolveLeastSquares(NumberRows,A,NumberColumns-1,b,1,Result);

  for(i =0;i<NumberColumns -1;i++)
    {
      FinalResult[i] = Result[i][0];
      free(Result[i]);
    }

  for(k=0;k<NumberRows;k++)
    free(A[k]);
  free(A);
  free(Result);
  for(k=0;k<NumberRows;k++)
    {
      free(b[k]);
    }
  free(b);

}

vtkLargeLeastSquaresProblem* vtkLargeLeastSquaresProblem::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkLargeLeastSquaresProblem")
;
  if(ret)
    {
    return (vtkLargeLeastSquaresProblem*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkLargeLeastSquaresProblem;
}

void vtkLargeLeastSquaresProblem::Delete()
{
  delete this;

}
void vtkLargeLeastSquaresProblem::PrintSelf()
{

}

vtkLargeLeastSquaresProblem::vtkLargeLeastSquaresProblem()
{
  Ab = NULL;
  tempAb = NULL;
  Householder = NULL;
  omega = NULL;
  NumberColumns = 3;
  NumberIncreasement = 3;
  NumberRows = NumberColumns + NumberIncreasement;
  CurrentIndex = 0;
}

vtkLargeLeastSquaresProblem::~vtkLargeLeastSquaresProblem()
{
  if(Ab!=NULL)
    {
      for(int i =0;i<NumberRows;i++)
    free(Ab[i]);
      free(Ab);
    }

  if(tempAb!=NULL)
    {
      for(int i =0;i<NumberRows;i++)
    free(tempAb[i]);
      free(tempAb);
    }

  if(Householder!=NULL)
    {
      for(int i =0;i<NumberRows;i++)
    free(Householder[i]);
      free(Householder);
    }

  if(omega!=NULL)
    free(omega);
}

vtkLargeLeastSquaresProblem::vtkLargeLeastSquaresProblem(vtkLargeLeastSquaresProblem&)
{

}

void vtkLargeLeastSquaresProblem::operator=(const vtkLargeLeastSquaresProblem)
{

}
