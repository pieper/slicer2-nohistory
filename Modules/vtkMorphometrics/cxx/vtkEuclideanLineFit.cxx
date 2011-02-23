/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEuclideanLineFit.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include "vtkEuclideanLineFit.h"
#include <vtkObjectFactory.h>
#include <vtkPolyData.h>
#include <vtkMath.h>
#include <iostream>
#include <assert.h>

void vtkEuclideanLineFit::Execute()
{
  vtkPolyData *input = (vtkPolyData *)this->Inputs[0];
  vtkPolyData *output = this->GetOutput();

  CoordinateSystem->SetInput(input);
  CoordinateSystem->Update();

  Center[0] = CoordinateSystem->GetCenter()[0];
  Center[1] = CoordinateSystem->GetCenter()[1];
  Center[2] = CoordinateSystem->GetCenter()[2];

  Direction[0] = CoordinateSystem->GetXAxis()[0];
  Direction[1] = CoordinateSystem->GetXAxis()[1];
  Direction[2] = CoordinateSystem->GetXAxis()[2];

  // update Direction
  UpdateDirection();
  OrientationFilter->Update();
  
  output->SetPoints(OrientationFilter->GetOutput()->GetPoints());
  output->SetStrips(((vtkPolyData*)OrientationFilter->GetOutput())->GetStrips());
  output->SetLines(((vtkPolyData*)OrientationFilter->GetOutput())->GetLines());
  output->SetVerts(((vtkPolyData*)OrientationFilter->GetOutput())->GetVerts());
  output->SetPolys(((vtkPolyData*)OrientationFilter->GetOutput())->GetPolys());
}

void vtkEuclideanLineFit::UpdateDirection()
{
  vtkMath::Normalize(Direction);

  vtkFloatingPointType dir_x = Direction[0] / 2;
  vtkFloatingPointType dir_y = (1+Direction[1]) / 2;
  vtkFloatingPointType dir_z = Direction[2] / 2;

  vtkFloatingPointType norm =  sqrt(dir_x*dir_x + dir_y*dir_y + dir_z*dir_z);
  dir_x = dir_x / norm;
  dir_y = dir_y / norm;
  dir_z = dir_z / norm;


  Orientation->Identity();
  Orientation->RotateWXYZ(180,dir_x,dir_y,dir_z);
  Orientation->PostMultiply();
  Orientation->Translate(Center[0],Center[1],Center[2]);
}

vtkEuclideanLineFit* vtkEuclideanLineFit::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkEuclideanLineFit")
;
  if(ret)
    {
    return (vtkEuclideanLineFit*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkEuclideanLineFit;
}

void vtkEuclideanLineFit::Delete()
{
  delete this;

}
void vtkEuclideanLineFit::PrintSelf()
{

}

vtkEuclideanLineFit::vtkEuclideanLineFit()
{
  Base = vtkCylinderSource::New();
  OrientationFilter = vtkTransformFilter::New();
  Orientation = vtkTransform::New();
  
  Center = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
  Center[0] = 0;
  Center[1] = 0;
  Center[2] = 0;

  Direction = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));
  Direction[0] = 0;
  Direction[1] = 1;
  Direction[2] = 0;

  CoordinateSystem = vtkPrincipalAxes::New();


  // setup the pipeline
  OrientationFilter->SetTransform(Orientation);
  OrientationFilter->SetInput(Base->GetOutput());
  
  Orientation->Identity();

  Base->SetResolution(30);
  Base->SetRadius(3);
  Base->SetHeight(400);

}

vtkEuclideanLineFit::~vtkEuclideanLineFit()
{
  free(Center);
  free(Direction);

  Orientation->Delete();
  OrientationFilter->Delete();
  Base->Delete();

  CoordinateSystem->Delete();
}

vtkEuclideanLineFit::vtkEuclideanLineFit(vtkEuclideanLineFit&)
{

}

void vtkEuclideanLineFit::operator=(const vtkEuclideanLineFit)
{

}
