/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistractorSource.cxx,v $
  Date:      $Date: 2006/01/06 17:56:38 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include <math.h>
#include "vtkDistractorSource.h"
#include "vtkPoints.h"
//#include "vtkNormals.h"
#include "vtkMath.h"
#include "vtkTransform.h"

vtkDistractorSource::vtkDistractorSource(int res)
{
  res = res < 4 ? 4 : res;
  this->Center[0] = 0.0;
  this->Center[1] = 0.0;
  this->Center[2] = 0.0;
  this->Axis[0] = 0.0;
  this->Axis[1] = 0.0;
  this->Axis[2] = 1.0;
  this->Start[0] = 1.0;
  this->Start[1] = 0.0;
  this->Start[2] = 0.0;
  this->Angle = 0.0;
  this->Distance = 20.0;
  this->Width = 1.0;
  this->FootWidth = 5.0;
  this->FootNormal[0] = 1.0;
  this->FootNormal[1] = 0.0;
  this->FootNormal[2] = 0.0;
  this->Resolution = res;
}

void vtkDistractorSource::Execute()
{
  int numPts, numPolys, ii;
  int triA[3], triB[3];
  vtkPoints *newPoints;
  vtkNormals *newNormals;
  vtkCellArray *newPolys;
  vtkTransform *stepXform;
  vtkPolyData *output=this->GetOutput();

  double a[3], c[3], s[3], t[3], r[3], w[3], n[3];
  double midpt[3];
  float p0[3], p1[3], p2[3], *r1;
  double degreeStep, distStep, radianAngle;
//
// Set things up; allocate memory
//

  numPts = 2 * this->Resolution + 8;
  // creating triangles
  numPolys = 2 * this->Resolution + 2;

  newPoints = vtkPoints::New();
  newPoints->Allocate(numPts);
  newNormals = vtkNormals::New();
  newNormals->Allocate(numPts);
  newPolys = vtkCellArray::New();
  newPolys->Allocate(newPolys->EstimateSize(numPolys,3));

  stepXform = vtkTransform::New();
  stepXform->PostMultiply();
//
// Create distractor
//
  // Check data, determine increments
  for ( ii=0; ii<3; ii++ )
    {
    a[ii] = this->Axis[ii];
    c[ii] = this->Center[ii];
    s[ii] = midpt[ii] = this->Start[ii];
    r[ii] = s[ii] - c[ii]; // Radius vector
    n[ii] = this->FootNormal[ii];
    }
  vtkMath::Normalize( n );
  radianAngle = vtkMath::Pi()*this->Angle/180.0;

  if ( this->Angle == 0.0 )
    {
    degreeStep = 0.0;
    distStep = this->Distance/this->Resolution;
    for ( ii=0; ii<3 ; ii++ )
      {
      t[ii] = a[ii]*this->Distance;
      }
    vtkMath::Normalize( t ); // t is unit Tangent vector
    vtkMath::Cross( n, t, w ); // w is the unit width vector
    }
  else
    {
    degreeStep = this->Angle/this->Resolution;
    distStep = this->Distance/this->Resolution;
    vtkMath::Cross( a, r, t );
    for ( ii=0; ii<3 ; ii++ )
      {
      t[ii] += a[ii]*this->Distance/radianAngle;
      w[ii] = a[ii]; // w is the unit width vector
      }
    vtkMath::Normalize( t ); // t is unit Tangent vector
    }

  p0[0] = midpt[0] + 0.5*w[0]*this->Width;
  p0[1] = midpt[1] + 0.5*w[1]*this->Width;
  p0[2] = midpt[2] + 0.5*w[2]*this->Width;

  p1[0] = midpt[0] - 0.5*w[0]*this->Width;
  p1[1] = midpt[1] - 0.5*w[1]*this->Width;
  p1[2] = midpt[2] - 0.5*w[2]*this->Width;

  newPoints->InsertPoint( 0, p0 );
  newPoints->InsertPoint( 1, p1 );
  // Create intermediate points
  for ( ii=0; ii<this->Resolution; ii++ )
    {
    stepXform->Identity();
    stepXform->RotateWXYZ( (ii+1) * degreeStep, a[0], a[1], a[2] );
    stepXform->Translate( (ii+1)*a[0]*distStep, (ii+1)*a[1]*distStep,
                          (ii+1)*a[2]*distStep );
    stepXform->SetPoint( r[0], r[1], r[2], 1.0 );
    r1 = stepXform->GetPoint();

    midpt[0] = c[0] + r1[0];
    midpt[1] = c[1] + r1[1];
    midpt[2] = c[2] + r1[2];

    p0[0] = midpt[0] + 0.5*w[0]*this->Width;
    p0[1] = midpt[1] + 0.5*w[1]*this->Width;
    p0[2] = midpt[2] + 0.5*w[2]*this->Width;

    p1[0] = midpt[0] - 0.5*w[0]*this->Width;
    p1[1] = midpt[1] - 0.5*w[1]*this->Width;
    p1[2] = midpt[2] - 0.5*w[2]*this->Width;

    newPoints->InsertPoint( 2*ii+2, p0 );
    newPoints->InsertPoint( 2*ii+3, p1 );
    triA[0] = 2*ii;
    triA[1] = 2*ii+1;
    triA[2] = 2*ii+2;
    triB[0] = 2*ii+1;
    triB[1] = 2*ii+3;
    triB[2] = 2*ii+2;
    newPolys->InsertNextCell( 3, triA );
    newPolys->InsertNextCell( 3, triB );
    }

//
// Construct the "feet"
//
  vtkMath::Cross( n, t, w );

  // the start foot
  for ( ii=0; ii<3; ii++ )
    {
    p0[ii] = s[ii] + w[ii]*this->FootWidth;
    p1[ii] = s[ii] - t[ii]*this->FootWidth;
    p2[ii] = s[ii] - w[ii]*this->FootWidth;
    }
  newPoints->InsertPoint( numPts-6, p0 );
  newPoints->InsertPoint( numPts-5, p1 );
  newPoints->InsertPoint( numPts-4, p2 );
  triA[0] = numPts-6;
  triA[1] = numPts-5;
  triA[2] = numPts-4;
  newPolys->InsertNextCell( 3, triA );

  // the end foot
  stepXform->SetPoint( w[0], w[1], w[2], 0.0 );
  r1 = stepXform->GetPoint();
  w[0] = r1[0]; w[1] = r1[1]; w[2] = r1[2];
  stepXform->SetPoint( t[0], t[1], t[2], 0.0 );
  r1 = stepXform->GetPoint();
  t[0] = r1[0]; t[1] = r1[1]; t[2] = r1[2];

  for ( ii=0; ii<3; ii++ )
    {
    p0[ii] = midpt[ii] - w[ii]*this->FootWidth;
    p1[ii] = midpt[ii] + t[ii]*this->FootWidth;
    p2[ii] = midpt[ii] + w[ii]*this->FootWidth;
    }
  newPoints->InsertPoint( numPts-3, p0 );
  newPoints->InsertPoint( numPts-2, p1 );
  newPoints->InsertPoint( numPts-1, p2 );
  triA[0] = numPts-3;
  triA[1] = numPts-2;
  triA[2] = numPts-1;
  newPolys->InsertNextCell( 3, triA );

//
// Update ourselves and release memeory
//
  output->SetPoints(newPoints);
  newPoints->Delete();

  // output->GetPointData()->SetNormals(newNormals);
  newNormals->Delete();

  output->SetPolys(newPolys);
  newPolys->Delete();
}

void vtkDistractorSource::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkPolyDataSource::PrintSelf(os,indent);

  os << indent << "Resolution: " << this->Resolution << "\n";
  os << indent << "Angle: " << this->Angle << "\n";
  os << indent << "Distance: " << this->Distance << "\n";
  os << indent << "Center: (" << this->Center[0] << ", " 
     << this->Center[1] << ", " << this->Center[2] << ")\n";
  os << indent << "Axis: (" << this->Axis[0] << ", " 
     << this->Axis[1] << ", " << this->Axis[2] << ")\n";
  os << indent << "Start: (" << this->Start[0] << ", " 
     << this->Start[1] << ", " << this->Start[2] << ")\n";
  os << indent << "FootWidth: " << this->FootWidth << "\n";
  os << indent << "FootNormal: (" << this->FootNormal[0] << ", " 
     << this->FootNormal[1] << ", " << this->FootNormal[2] << ")\n";
}
