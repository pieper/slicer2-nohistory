/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBooksteinSphereFit.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// The basic idea of the Bookstein sphere fitting 
// is not to minimize the euclidean distance, which is 
//   \sum_{i=1}^n (distance(x_i,sphere_center) - radius)^2 ,
// but to minimize 
//   \sum_{i=1}^n distance(x_i,sphere_center)^2 - radius^2 
// instead. 

// From a computational point of view, the first sum
// mainly is solving equations of the order 4 whereas 
// the second boils down to the least squares problem
// (x_i,y_i,z_i,1) * (alpha,beta,gamma,delta) = x_i^2 + y_i^2 + z_i^2.
//
// The center of the fitting sphere found is 
// (-alpha/2,-beta/2,-gamma/2)
// and the radius is sqrt(vtkMath::Dot(center,center) - delta)
//
// The quality of the sphere found via the Bookstein algorithm
// can be improved using as radius 
// (\sum_{i=1}^n Norm(x_i - center)) / n
// which is the radius an euclidean best fit sphere would have.

#include "vtkBooksteinSphereFit.h"
#include <vtkObjectFactory.h>
#include <vtkPolyData.h>
#include <vtkMath.h>
#include <iostream>
#include <assert.h>

void vtkBooksteinSphereFit::Execute()
{
  vtkPolyData *input = (vtkPolyData *)this->Inputs[0];
  vtkPolyData *output = this->GetOutput();
  vtkIdType nr_points = input->GetNumberOfPoints();
  vtkFloatingPointType* point;

  double* line = (double*)malloc(4*sizeof(double));
  line[3] = 1;

  Solver->Initialize(4);

  // add all points
  for(int i = 0;i<input->GetNumberOfPoints();i++)
    {
      point = input->GetPoint(i);
      line[0] = point[0];
      line[1] = point[1];
      line[2] = point[2];
      Solver->AddLine(line,vtkMath::Dot(point,point));
    }

  // solve the problem
  Solver->Solve(line);
  // compute the geometrical solution
  GeometricalSolution(line[0],line[1],line[2],line[3]);

  // recompute the radius
  BestEuclideanFitRadius(input->GetPoints());

  Base->SetRadius(Radius);
  Base->SetCenter(Center[0],Center[1],Center[2]);
  output->SetPoints(Base->GetOutput()->GetPoints());
  output->SetStrips(((vtkPolyData*)Base->GetOutput())->GetStrips());
  output->SetLines(((vtkPolyData*)Base->GetOutput())->GetLines());
  output->SetVerts(((vtkPolyData*)Base->GetOutput())->GetVerts());
  output->SetPolys(((vtkPolyData*)Base->GetOutput())->GetPolys());
}

void vtkBooksteinSphereFit::GeometricalSolution(vtkFloatingPointType alpha,vtkFloatingPointType beta,vtkFloatingPointType gamma,vtkFloatingPointType delta)
{
  Center[0] = - alpha/2;
  Center[1] = - beta/2;
  Center[2] = - gamma/2;
  
  Radius = sqrt (vtkMath::Dot(Center,Center)   - delta);
}

void vtkBooksteinSphereFit::BestEuclideanFitRadius(vtkPoints* points)
{
  vtkFloatingPointType newRadius = 0;
  vtkFloatingPointType norm;
  vtkFloatingPointType* point_i;
  for(vtkIdType i=0;i<points->GetNumberOfPoints();i++)
    {
      point_i = points->GetPoint(i);
      norm = 0;
      for(int j=0;j<3;j++)
    norm += (Center[j]-point_i[j])*(Center[j]-point_i[j]);
      newRadius += sqrt(norm);
    }
  Radius = newRadius/points->GetNumberOfPoints();
}

vtkBooksteinSphereFit* vtkBooksteinSphereFit::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkBooksteinSphereFit");
  if(ret)
    {
    return (vtkBooksteinSphereFit*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkBooksteinSphereFit;
}

void vtkBooksteinSphereFit::Delete()
{
  delete this;

}
void vtkBooksteinSphereFit::PrintSelf()
{

}

vtkBooksteinSphereFit::vtkBooksteinSphereFit()
{
  Center = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
  Center[0] = 0;
  Center[1] = 0;
  Center[2] = 0;

  Radius = 3;

  Base = vtkSphereSource::New();

  Base->SetThetaResolution(30);
  Base->SetPhiResolution(30);
  Base->SetRadius(Radius);

  Solver = vtkLargeLeastSquaresProblem::New();
  Solver->SetNumberIncreasement(5);
}

vtkBooksteinSphereFit::~vtkBooksteinSphereFit()
{
  free(Center);
  Base->Delete();
  Solver->Delete();
}

vtkBooksteinSphereFit::vtkBooksteinSphereFit(vtkBooksteinSphereFit&)
{

}

void vtkBooksteinSphereFit::operator=(const vtkBooksteinSphereFit)
{

}
