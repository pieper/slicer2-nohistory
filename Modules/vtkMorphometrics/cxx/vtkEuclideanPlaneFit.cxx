/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEuclideanPlaneFit.cxx,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkEuclideanPlaneFit.h"
#include <vtkObjectFactory.h>
#include <vtkPolyData.h>
#include <vtkMath.h>
#include <iostream>
#include <assert.h>

void vtkEuclideanPlaneFit::Execute()
{
  vtkPolyData *input = (vtkPolyData *)this->Inputs[0];
  vtkPolyData *output = this->GetOutput();

  CoordinateSystem->SetInput(input);
  CoordinateSystem->Update();
  
  Center[0] = CoordinateSystem->GetCenter()[0];
  Center[1] = CoordinateSystem->GetCenter()[1];
  Center[2] = CoordinateSystem->GetCenter()[2];
  
  Normal[0] = CoordinateSystem->GetZAxis()[0];
  Normal[1] = CoordinateSystem->GetZAxis()[1];
  Normal[2] = CoordinateSystem->GetZAxis()[2];

  FittingPlane->SetCenter(Center);
  FittingPlane->SetNormal(Normal);

  FittingPlane->Update();
  output->SetPoints(FittingPlane->GetOutput()->GetPoints());
  output->SetStrips(((vtkPolyData*)FittingPlane->GetOutput())->GetStrips());
  output->SetLines(((vtkPolyData*)FittingPlane->GetOutput())->GetLines());
  output->SetVerts(((vtkPolyData*)FittingPlane->GetOutput())->GetVerts());
  output->SetPolys(((vtkPolyData*)FittingPlane->GetOutput())->GetPolys());
}

vtkEuclideanPlaneFit* vtkEuclideanPlaneFit::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkEuclideanPlaneFit")
;
  if(ret)
    {
    return (vtkEuclideanPlaneFit*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkEuclideanPlaneFit;
}

void vtkEuclideanPlaneFit::Delete()
{
  delete this;
}
void vtkEuclideanPlaneFit::PrintSelf()
{

}

vtkEuclideanPlaneFit::vtkEuclideanPlaneFit()
{
  Center = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
  Center[0] = 0;
  Center[1] = 0;
  Center[2] = 0;

  Normal = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
  Normal[0] = 0;
  Normal[1] = 0;
  Normal[2] = 1;

  CoordinateSystem = vtkPrincipalAxes::New();
  FittingPlane = vtkPlaneSource::New();

  FittingPlane->SetOrigin(0,0,0);
  FittingPlane->SetPoint1(100,0,0);
  FittingPlane->SetPoint2(0,100,0);
}

vtkEuclideanPlaneFit::~vtkEuclideanPlaneFit()
{
  free(Center);
  free(Normal);
  CoordinateSystem->Delete();
  FittingPlane->Delete();
}

vtkEuclideanPlaneFit::vtkEuclideanPlaneFit(vtkEuclideanPlaneFit&)
{

}

void vtkEuclideanPlaneFit::operator=(const vtkEuclideanPlaneFit)
{

}
