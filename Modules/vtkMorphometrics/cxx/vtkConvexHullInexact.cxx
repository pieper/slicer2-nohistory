/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkConvexHullInexact.cxx,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// Internal Structure:
// The model of a convex hull used is viewing a convex hull as an intersection of
// halfspaces. For the exact convex hull all halfspaces have to be considered. In this
// algorithm we consider only a subset of all halfspaces. A halfspace can be represented
// by the hessian normal form of a plane: a point x0 on the limiting plane and a direction
// n, the normal of the limiting plane. Then the halfspace is defined by all points x with
//    vtkMath::Dot(n,x0)  <= vtkMath::Dot(n,x)
// So, given a set of normals, we have to search the point set for points minimalizing
// vtkMath::Dot(n,x) for every normal n if we want to find a limiting halfspace. 
// Searching additionaly for points maximalizing it, we find the minimum of vtkMath::Dot(-1*n,x).
//
// A proper set of normals are all vectors from (0,0,0) to one neighbour voxel:
// (0,0,-1),(0,0,1),(0,-1,-1),(0,-1,0),(0,-1,1),(0,1,-1), ... , (1,1,1)
// If we want a better approximation, we consider the set of all vectors from (0,0,0) to
// voxel at distance 2 from (0,0,0):
// (0,0,-2),(0,0,2),(0,-1,-2),(0,-1,2),(0,1,-2),(0,1,2), ... , (2,2,2)
// We can approximate even better by using vectors to voxels at distance 3 from (0,0,0).
// Which distance we take is defined by the object member Granularity.
//
// Seeing that for every normal n inside this set also -1*n is inside, we can 
// concentrate on computing the minimal and maximal point x for n and exclude -1*n from the set
// of normals. Using only normals which are positive regarding the lexicographic order is a
// proper characterization of that subset.
//
// Deciding whether a point is inside the convex hull boils down to the question whether
// it lies for every normal between Dot(normal,minimal_point) and Dot(normal,maximal_point)
// 
// Computing the distance for a point x inside the hull is searching for the minimal distance 
// to all limiting halfspaces. For a point x we have to search the projection point of it
// on the convex hull and compute the distance from it.
//
// Computing all extremal points is necessary since they form the corners of the polygons.
// It is done by intersecting all possible combinations of halfspaces and looking whether
// the intersection point is part of the convex hull. When such a point is found, we know that
// it is part of the polygons limiting each halfspace used for finding the point. If we
// bookkeep for each halfspace which extremal points are part of it, providing a polygonization
// of the surface of the convex hull is easy.
// 
// object members:
// - Granularity : explained above
// - NumberNormals : number of surface voxels of a cube with side length (2*Granularity +1)
// - ConvexHull : Array of normals and corresponding minimal a maximal points.
//                ConvexHull[i][0] : i-th normal
//                ConvexHull[i][1] : minimal point for i-th normal
//                ConvexHull[i][2] : maximal point for i-th normal
// - Extremals : Extremal points for ConvexHull
// - PolygonPoints : Bookkeeping array containing for each limiting halfspace a list of extremal points in it.
//                 PolygonPoints[i] : List of extremal points on limiting halfspace ConvexHull[i/2][0] and ConvexHull[i/2][1 + (i%2)]
// - PolygonPointCounter :  PolygonPointCounter[i] is the number of how many extremal points are found for
//                          the halfspace [i/2][0] and ConvexHull[i/2][1 + (i%2)]



#include "vtkConvexHullInexact.h"
#include <vtkObjectFactory.h>
#include <vtkCellArray.h>
#include <vtkPolyData.h>
#include <vtkMath.h>
#include <iostream>
#include <assert.h>
#include <float.h>

#define EPSILON 0.000001


bool vtkConvexHullInexact::Inside(vtkFloatingPointType* x)
{
  for(int i =0;i<NumberNormals;i++)
    {
      vtkFloatingPointType smallest_p = vtkMath::Dot(ConvexHull[i][0],ConvexHull[i][1]);
      vtkFloatingPointType largest_p = vtkMath::Dot(ConvexHull[i][0],ConvexHull[i][2]);
      vtkFloatingPointType p_x = vtkMath::Dot(ConvexHull[i][0],x);
      if((p_x < smallest_p - EPSILON) || (largest_p < p_x - EPSILON))
    return false;
    }
  return true;
}



vtkFloatingPointType vtkConvexHullInexact::DistanceFromConvexHull(vtkFloatingPointType x,vtkFloatingPointType y,vtkFloatingPointType z)
{
  vtkFloatingPointType* t = (vtkFloatingPointType*) malloc(sizeof(vtkFloatingPointType)*3);
  t[0] = x;
  t[1] = y;
  t[2] = z;
  vtkFloatingPointType result = DistanceFromConvexHull(t);
  free(t);
  return result;
}

vtkFloatingPointType vtkConvexHullInexact::DistanceFromConvexHull(vtkFloatingPointType* x)
{
  vtkFloatingPointType result = FLT_MAX;
  if(Inside(x))
    {
      for(int i =0;i<NumberNormals;i++)
    {
      vtkFloatingPointType distance1 = fabs(vtkMath::Dot(ConvexHull[i][0],x) - vtkMath::Dot(ConvexHull[i][0],ConvexHull[i][1]));
      vtkFloatingPointType distance2 = fabs(vtkMath::Dot(ConvexHull[i][0],x) - vtkMath::Dot(ConvexHull[i][0],ConvexHull[i][2]));
      if(distance1 < result)
        result = distance1;
      if(distance2 < result)
        result = distance2;
    }
    }
  else
    {
      vtkFloatingPointType* p = (vtkFloatingPointType*)malloc(Dimension*sizeof(vtkFloatingPointType));
      for(int i =0;i<NumberNormals;i++)
    for(int j =1;j<3;j++)
      {
        vtkFloatingPointType* normal = ConvexHull[i][0];
        vtkFloatingPointType distance = fabs(vtkMath::Dot(normal,x) - vtkMath::Dot(normal,ConvexHull[i][j]));
        // project on plane:
        // we normalize on the case that the point is not in the defined halfspace,
        // therefore we have to invert distance in the case j=2;
        if(j==2)
          distance = -distance;

        for(int k=0;k<3;k++)
          p[k] = x[k] + distance*normal[k];

      }
      if(result==FLT_MAX)
    {
      cout << "Error while computing distance from convex hull: couldn't compute projection point"<<endl;
    }
      free(p);
    }
  return result;
}

void vtkConvexHullInexact::UpdateConvexHull(vtkPoints* v)
{
  if(v->GetNumberOfPoints()==0) return;
  vtkFloatingPointType* x0 = v->GetPoint(0);


  // Initialize to one point
  int i;
  for(i =0;i<NumberNormals;i++)
    {
      for(int j=1;j<3;j++)
    {
      for(int k = 0;k<Dimension;k++)
        ConvexHull[i][j][k] = x0[k];
    }
    }

  // iterative updating of the convex hull
  for (i = 0; i< v->GetNumberOfPoints();i++)
    {
      vtkFloatingPointType* p0 = v->GetPoint(i);
      for(int j= 0; j<NumberNormals;j++)
    {
      vtkFloatingPointType* n = ConvexHull[j][0];

      bool smaller_p  =  vtkMath::Dot(n,p0) < vtkMath::Dot(n,ConvexHull[j][1]);
      bool larger_p   =  vtkMath::Dot(n,p0) > vtkMath::Dot(n,ConvexHull[j][2]);
      if(smaller_p)
        {
          ConvexHull[j][1][0] = p0[0];
          ConvexHull[j][1][1] = p0[1];
          ConvexHull[j][1][2] = p0[2];
        }
      if (larger_p)
        {
          ConvexHull[j][2][0] = p0[0];
          ConvexHull[j][2][1] = p0[1];
          ConvexHull[j][2][2] = p0[2];
        }
    }
    }
}

void vtkConvexHullInexact::Execute()
{
  vtkPolyData *input = (vtkPolyData *)this->Inputs[0];
  vtkPolyData *output = this->GetOutput();

  UpdateConvexHull(input->GetPoints());

  GeometricRepresentation->SetInput(GetInput());
  GeometricRepresentation->Update();

  output->SetPoints(GeometricRepresentation->GetOutput()->GetPoints());
  output->SetStrips(((vtkPolyData*)GeometricRepresentation->GetOutput())->GetStrips());
  output->SetLines(((vtkPolyData*)GeometricRepresentation->GetOutput())->GetLines());
  output->SetVerts(((vtkPolyData*)GeometricRepresentation->GetOutput())->GetVerts());
  output->SetPolys(((vtkPolyData*)GeometricRepresentation->GetOutput())->GetPolys());
}


vtkConvexHullInexact* vtkConvexHullInexact::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkConvexHullInexact")
;
  if(ret)
    {
    return (vtkConvexHullInexact*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkConvexHullInexact;
}

void vtkConvexHullInexact::Delete()
{
  delete this;

}
void vtkConvexHullInexact::PrintSelf()
{

}

vtkConvexHullInexact::vtkConvexHullInexact()
{
  ConvexHull = NULL;
  Dimension = 3;
  NumberNormals=-1;
  Granularity= -1;

  GeometricRepresentation = vtkHull::New();
  SetGranularity(2);
}

vtkConvexHullInexact::~vtkConvexHullInexact()
{
  if(ConvexHull!=NULL)
    {
      for(int i = 0;i<NumberNormals;i++)
    {
      for(int j = 0;j<3;j++)
        free(ConvexHull[i][j]);
      free(ConvexHull[i]);
    }
      free(ConvexHull);
    }

  GeometricRepresentation->Delete();
}

vtkConvexHullInexact::vtkConvexHullInexact(vtkConvexHullInexact&)
{

}

void vtkConvexHullInexact::operator=(const vtkConvexHullInexact)
{

}

// think of the normal n as a number to the base 2*(Granularity + 1)
// then the next normal is  n+1
void vtkConvexHullInexact::NextNormal(vtkFloatingPointType* n)
{
  for(int i= Dimension-1;i>=0;i--)
    {
      if(n[i]!= Granularity)
    {
      n[i]++;
      for (int j= i+1;j<Dimension;j++)
        n[j] = -Granularity;
      break;
    }
    }
}

// returns true iff n strictly lexicographic positive
bool vtkConvexHullInexact::LexPositive(vtkFloatingPointType* n)
{
  for(int i =0;i<Dimension;i++)
    {
      if(n[i]<0) return false;
      if(n[i]>0) return true;
    }
  return false;
}

bool vtkConvexHullInexact::AtLeastOneNeighbourDistEntry(vtkFloatingPointType* n)
{
  for(int i = 0;i<Dimension;i++)
    {
      if(fabs(n[i])==Granularity) return true;
    }
  return false;
}

void vtkConvexHullInexact::SetGranularity(int newGranularity)
{
  if(newGranularity < 1 || newGranularity==Granularity) 
    return;

  Granularity = newGranularity;

  GeometricRepresentation->RemoveAllPlanes();

  int i;
  // free the current memory
  if(ConvexHull!=NULL)
    {
      for(i = 0;i<NumberNormals;i++)
    {
      for(int j = 0;j<3;j++)
        free(ConvexHull[i][j]);
      free(ConvexHull[i]);
    }
      free(ConvexHull);
    }

  // compute new count of normals
  NumberNormals = ((int)pow(2*Granularity +1,Dimension) - (int)pow(2*Granularity -1, Dimension)) / 2;

  ConvexHull = (vtkFloatingPointType***) malloc(NumberNormals*sizeof(vtkFloatingPointType**));
  for(i =0;i<NumberNormals;i++)
    {
      ConvexHull[i] = (vtkFloatingPointType**) malloc(3*sizeof(vtkFloatingPointType*));
      for(int j=0;j<3;j++)
    {
      ConvexHull[i][j] = (vtkFloatingPointType*) malloc(Dimension*sizeof(vtkFloatingPointType));
    }
    }
  

  // insert new normals
  vtkFloatingPointType* n = (vtkFloatingPointType*) malloc(Dimension*sizeof(vtkFloatingPointType));

  for(i=0;i<Dimension;i++)
    n[i] = 0;

  i = 0;

  while(i != NumberNormals)
    {
      NextNormal(n);
      if(LexPositive(n) && AtLeastOneNeighbourDistEntry(n))
    {
      GeometricRepresentation->AddPlane(n[0],n[1],n[2]);
      GeometricRepresentation->AddPlane(-n[0],-n[1],-n[2]);
      for(int j=0;j< Dimension;j++)
        ConvexHull[i][0][j] = n[j];
      vtkMath::Normalize(ConvexHull[i][0]);
      i++;
    }
    }
  
  free(n);
  
  Modified();
}
