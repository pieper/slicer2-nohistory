/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAxisSource.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkAxisSource.h"
#include <vtkObjectFactory.h>
#include <vtkMath.h>

void vtkAxisSource::SetDirection(vtkFloatingPointType x,vtkFloatingPointType y,vtkFloatingPointType z)
{
  Direction[0] = x;
  Direction[1] = y;
  Direction[2] = z;

  vtkMath::Normalize(Direction);

  UpdateVisualization();

  Modified();
}
 
void vtkAxisSource::SetDirection(vtkFloatingPointType* d)
{
  SetDirection(d[0],d[1],d[2]);
}

void vtkAxisSource::SetCenter(vtkFloatingPointType x,vtkFloatingPointType y,vtkFloatingPointType z)
{
  Center[0] = x;
  Center[1] = y;
  Center[2] = z;

  UpdateVisualization();

  Modified();
}

void vtkAxisSource::SetCenter(vtkFloatingPointType* p)
{
  SetCenter(p[0],p[1],p[2]);
}

vtkAxisSource* vtkAxisSource::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkAxisSource")
;
  vtkAxisSource* result;
  if(ret)
    {
      result =  (vtkAxisSource*)ret;
    }
  else
    {
      result = new vtkAxisSource();
    }
  return result;
}

void vtkAxisSource::Delete()
{
  delete this;
}

void vtkAxisSource::PrintSelf()
{

}

vtkAxisSource::vtkAxisSource()
{
  Direction = (vtkFloatingPointType*)malloc(3*sizeof(vtkFloatingPointType));
  Center  = (vtkFloatingPointType*)malloc(3*sizeof(vtkFloatingPointType));;

  AxisSource = vtkCylinderSource::New();
  AxisFilter = vtkTransformPolyDataFilter::New();
  AxisTransform = vtkTransform::New();

  // make the axis visible
  AxisSource->SetResolution(30);
  AxisSource->SetRadius(3);
  AxisSource->SetHeight(400);
  // put the pipeline together
  AxisFilter->SetInput(AxisSource->GetOutput());
  AxisFilter->SetTransform(AxisTransform);

  Center[0] = 0;
  Center[1] = 0;
  Center[2] = 0;

  SetDirection(1,0,0);
}

vtkAxisSource::~vtkAxisSource()
{
  free(Direction);
  free(Center);
  AxisSource->Delete();
  AxisTransform->Delete();
  AxisFilter->Delete();
}

void vtkAxisSource::UpdateRepresentation()
{
  double* dir = AxisTransform->TransformNormal(0,1,0);
  vtkFloatingPointType* pos = AxisTransform->GetPosition();
  
  for(int i = 0;i<3;i++)
    {
      Center[i] = pos[i];
      Direction[i] = dir[i];
    }

  vtkMath::Normalize(Direction);
}

// transforming a cylinder to the intended direction is done by rotating the cylinder (which has direction (0,1,0)) around
// the vector halfway between (0,1,0) and the intended direction around 180 degrees.
void vtkAxisSource::UpdateVisualization()
{
  vtkFloatingPointType dir_x = Direction[0];
  vtkFloatingPointType dir_y = Direction[1];
  vtkFloatingPointType dir_z = Direction[2];

  dir_x = dir_x / 2;
  dir_y = (1+dir_y) / 2;
  dir_z = dir_z / 2;

  vtkFloatingPointType norm =  sqrt(dir_x*dir_x + dir_y*dir_y + dir_z*dir_z);
  dir_x = dir_x / norm;
  dir_y = dir_y / norm;
  dir_z = dir_z / norm;

  AxisTransform->Identity();
  AxisTransform->RotateWXYZ(180,dir_x,dir_y,dir_z);
  AxisTransform->PostMultiply();
  AxisTransform->Translate(Center[0],Center[1],Center[2]);
}

void vtkAxisSource::Execute()
{
  vtkPolyData *output = this->GetOutput();

  AxisFilter->Update();
  
  vtkPolyData* input = AxisFilter->GetOutput();

  output->SetPoints(input->GetPoints());
  output->SetPolys(input->GetPolys());
  output->SetStrips(input->GetStrips());
  output->SetLines(input->GetLines());
}

vtkFloatingPointType vtkAxisSource::Angle(vtkFloatingPointType* n)
{
  vtkFloatingPointType angle = acos(vtkMath::Dot(Direction,n) / vtkMath::Norm(n));
  return angle*vtkMath::RadiansToDegrees();
}
