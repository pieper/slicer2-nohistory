/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPelvisMetric.cxx,v $
  Date:      $Date: 2006/01/18 22:46:55 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include "vtkPelvisMetric.h"
#include <vtkObjectFactory.h>
#include <vtkMath.h>
#include "vtkPrincipalAxes.h"
#include <vtkTransform.h>
#include <vtkMatrix4x4.h>

vtkPelvisMetric* vtkPelvisMetric::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPelvisMetric")
;
  vtkPelvisMetric* result;
  if(ret)
    {
      result =  (vtkPelvisMetric*)ret;
    }
  else
    {
      result = new vtkPelvisMetric();
    }
  return result;
}

void vtkPelvisMetric::Delete()
{
  delete this;
}

void vtkPelvisMetric::PrintSelf()
{

}

vtkPelvisMetric::vtkPelvisMetric()
{
  AcetabularPlane = vtkPlaneSource::New();
  Pelvis = NULL;

  // defaults:
  AcetabularPlane->SetOrigin(0,0,0);
  AcetabularPlane->SetPoint1(100,0,0);
  AcetabularPlane->SetPoint2(0,100,0);
  AcetabularPlane->SetCenter(-88.6134,-4.64934,87.0443);
  AcetabularPlane->SetNormal(-0.721505,0.320132,-0.613959);

  Center = (vtkFloatingPointType*)malloc(3*sizeof(vtkFloatingPointType)); 
  Center[0] = 0;
  Center[1] = 0;
  Center[2] = 0;

  //FrontalAxis  = vtkAxisSource::New();
  //FrontalAxis->SetDirection(1,0,0);

  //SagittalAxis  = vtkAxisSource::New();
  //SagittalAxis->SetDirection(0,1,0);

  //LongitudinalAxis  = vtkAxisSource::New();
  //LongitudinalAxis->SetDirection(0,0,1);

  InclinationAngle = 45;
  AnteversionAngle = 45;

  WorldToObject = vtkTransform::New();

  Normalize();

}

void vtkPelvisMetric::SetPelvis(vtkPolyData* newPelvis)
{
  if(newPelvis==NULL )
    return;

  if(newPelvis==Pelvis)
    return;

  Pelvis = newPelvis;

  // compute the center since this depends solely on the polyData
  Center[0] = 0;
  Center[1] = 0;
  Center[2] = 0;

  for(vtkIdType i=0;i<Pelvis->GetNumberOfPoints();i++)
    {
      Center[0] += Pelvis->GetPoint(i)[0];
      Center[1] += Pelvis->GetPoint(i)[1];
      Center[2] += Pelvis->GetPoint(i)[2];
    }

  Center[0] = Center[0] / Pelvis->GetNumberOfPoints();
  Center[1] = Center[1] / Pelvis->GetNumberOfPoints();
  Center[2] = Center[2] / Pelvis->GetNumberOfPoints();

  WorldCsys();

  Modified();
}

void vtkPelvisMetric::Normalize()
{
  // ensure that the different direction vector look in certain directions.
  // those are invariants needed for computing the angles.

  // acetabular plane normal not pointing towards center of gravity
  vtkFloatingPointType p_acetabulum = vtkMath::Dot(AcetabularPlane->GetCenter(),AcetabularPlane->GetNormal());
  vtkFloatingPointType p_center = vtkMath::Dot(Center,AcetabularPlane->GetNormal());
  if(p_center>p_acetabulum)
    {
      vtkFloatingPointType* normal = AcetabularPlane->GetNormal();
      
      for(int i=0;i<3;i++)
    normal[i] = -normal[i];
      AcetabularPlane->SetNormal(normal);
    }
  
  // OBS! this invariant is also enforced in NormalizeXAxis
  // center of actabular plane in FrontalAxis halfspace
  vtkFloatingPointType* frontalAxisDirection = WorldToObject->TransformNormal(1,0,0);
  p_acetabulum = vtkMath::Dot(AcetabularPlane->GetCenter(),frontalAxisDirection);
  p_center = vtkMath::Dot(Center,frontalAxisDirection);
  if(p_acetabulum<p_center)
    {
      vtkMatrix4x4* m = WorldToObject->GetMatrix();
      for(int i=0;i<3;i++)
    m->SetElement(i,0,-1*m->GetElement(i,0));
    }


  UpdateAngles();
  Modified();
}

// also done for the WorldToObject transformation in Normalize();
void vtkPelvisMetric::NormalizeXAxis(vtkFloatingPointType* n)
{
  vtkFloatingPointType p_acetabulum = vtkMath::Dot(AcetabularPlane->GetCenter(),n);
  vtkFloatingPointType p_center = vtkMath::Dot(Center,n);
  if(p_acetabulum<p_center)
    {
      for(int i=0;i<3;i++)
    n[i] *= -1;
    }
}

vtkFloatingPointType vtkPelvisMetric::Angle(vtkFloatingPointType* n,vtkFloatingPointType* Direction)
{
  vtkFloatingPointType angle = acos(vtkMath::Dot(Direction,n) / vtkMath::Norm(n));
  return angle*vtkMath::RadiansToDegrees();
}


void vtkPelvisMetric::UpdateAngles()
{
  vtkFloatingPointType* normal_in_obj = WorldToObject->TransformNormal(AcetabularPlane->GetNormal());
  
  vtkFloatingPointType* reference_n = (vtkFloatingPointType*) malloc(3*sizeof(vtkFloatingPointType));

  for(int i = 0;i<3;i++)
    reference_n[i] = 0;
  reference_n[0] = 1;

  // Inclination : project normal_in_obj onto x-z-Plane
  normal_in_obj[1]= 0;

  vtkMath::Normalize(normal_in_obj);

  InclinationAngle = 90 - Angle(reference_n,normal_in_obj);

  // Clean up of inclination computation
#if ((VTK_MAJOR_VERSION == 4 && VTK_MINOR_VERSION >= 3) || VTK_MAJOR_VERSION >= 5)
  normal_in_obj = WorldToObject->TransformNormal(AcetabularPlane->GetNormal());
#else
  normal_in_obj = WorldToObject->TransformFloatNormal(AcetabularPlane->GetNormal());
#endif

  // Anteversion
  normal_in_obj[2]= 0;

  vtkMath::Normalize(normal_in_obj);

  AnteversionAngle = Angle(reference_n,normal_in_obj);
  
  free(reference_n);
}

vtkPelvisMetric::~vtkPelvisMetric()
{
  AcetabularPlane->Delete();

  free(Center);

  WorldToObject->Delete();
}


void vtkPelvisMetric::WorldCsys(void)
{
  WorldToObject->Identity();
  WorldToObject->Translate(-Center[0],-Center[1],-Center[2]);
  Normalize();
}

void vtkPelvisMetric::ObjectCsys(void)
{
  WorldToObject->Identity();

  vtkPrincipalAxes* vPA = vtkPrincipalAxes::New();
  vPA->SetInput(Pelvis);
  vPA->Update();

  vtkMatrix4x4* obj = WorldToObject->GetMatrix();

  for(int j=0;j<3;j++)
    {
      obj->SetElement(0,j,vPA->GetXAxis()[j]);
      obj->SetElement(1,j,vPA->GetYAxis()[j]);
      obj->SetElement(2,j,vPA->GetZAxis()[j]);
    }
  
  WorldToObject->PostMultiply();
  WorldToObject->Translate(-Center[0],-Center[1],-Center[2]);
  Normalize();
}

void vtkPelvisMetric::SymmetryAdaptedWorldCsys(void)
{
  WorldToObject->Identity();

  vtkPrincipalAxes* vPA = vtkPrincipalAxes::New();
  vPA->SetInput(Pelvis);
  vPA->Update();

  vtkMatrix4x4* obj = WorldToObject->GetMatrix();

  // write the symmetry axis - the one with the smallest angle to (1,0,0) - into the first column 
  vtkFloatingPointType* axis = (vtkFloatingPointType*)malloc(3*sizeof(vtkFloatingPointType));

  axis[0] = 1;
  axis[1] = 0;
  axis[2] = 0;
  NormalizeXAxis(axis);

  vtkFloatingPointType* candidate = vPA->GetXAxis();
  NormalizeXAxis(candidate);
  int i;
  for(i =0;i<3;i++)
    obj->SetElement(i,0,candidate[i]);

  vtkFloatingPointType distance = vtkMath::Distance2BetweenPoints(candidate,axis);

  candidate = vPA->GetYAxis();
  NormalizeXAxis(candidate);
  if(vtkMath::Distance2BetweenPoints(candidate,axis) < distance)
    {
      distance = vtkMath::Distance2BetweenPoints(candidate,axis);
      for(i =0;i<3;i++)
    obj->SetElement(i,0,candidate[i]);
    } 

  candidate = vPA->GetZAxis();
  NormalizeXAxis(candidate);
  if(vtkMath::Distance2BetweenPoints(candidate,axis) < distance)
    {
      distance = vtkMath::Distance2BetweenPoints(candidate,axis);
      for(int i =0;i<3;i++)
    obj->SetElement(i,0,candidate[i]);
    } 

  // projection of (0,1,0) onto the plane orthogonal to the symmetry axis
  for(i =0;i<3;i++)
    candidate[i] = obj->GetElement(i,0);

  axis[0] = 0;
  axis[1] = 1;
  axis[2] = 0;

  vtkFloatingPointType p = vtkMath::Dot(candidate,axis);
  for(i = 0;i < 3;i++)
    axis[i] = axis[i] - p*candidate[i];
  vtkMath::Normalize(axis);

  for(i = 0;i < 3;i++)
    obj->SetElement(i,1,axis[i]);

  // the last vector is automatically the crossproduct of the first two.
  vtkFloatingPointType* third = (vtkFloatingPointType*)malloc(3*sizeof(vtkFloatingPointType));
  vtkMath::Cross(candidate,axis,third);

  for(i = 0;i < 3;i++)
    obj->SetElement(i,2,third[i]);

  free(axis);
  free(third);

  WorldToObject->PostMultiply();
  WorldToObject->Translate(-Center[0],-Center[1],-Center[2]);
  Normalize();
              
}
