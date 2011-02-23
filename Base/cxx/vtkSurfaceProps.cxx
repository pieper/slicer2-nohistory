/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSurfaceProps.cxx,v $
  Date:      $Date: 2006/04/13 19:53:53 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
#include "vtkSurfaceProps.h"

#include "vtkObjectFactory.h"
#include "vtkPolyData.h"
#include "vtkCellTriMacro.h"

#include "vtkMath.h"
#include <math.h>

//------------------------------------------------------------------------------
vtkSurfaceProps* vtkSurfaceProps::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkSurfaceProps");
  if(ret)
    {
    return (vtkSurfaceProps*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkSurfaceProps;
}


// Description:
vtkSurfaceProps::vtkSurfaceProps()
{
  this->SurfaceArea = 0;
  this->MinCellArea = 0;
  this->MaxCellArea = 0;
  this->Volume = 0;
  this->VolumeError = 0;
  this->Test = 0;
}

vtkSurfaceProps::~vtkSurfaceProps()
{
}

void vtkSurfaceProps::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  os << indent << "SurfaceArea: " << this->SurfaceArea << endl;
  os << indent << "MinCellArea: " << this->MinCellArea << endl;
  os << indent << "MaxCellArea: " << this->MaxCellArea << endl;
  os << indent << "Volume:      " << this->Volume << endl;
  os << indent << "VolumeError: " << this->VolumeError << endl;
  os << indent << "Test:        " << this->Test << endl;
}


void vtkSurfaceProps::Update()
{
  this->SurfaceArea = 0.0;
  this->MinCellArea = VTK_LARGE_FLOAT;
  this->MaxCellArea = 0.0;
  this->Volume = 0.0;
  this->VolumeError = 0.0;
  this->Execute();

}

// Description:
// Specifies the input data...
void vtkSurfaceProps::SetInput(vtkPolyData *input)
{
  this->vtkProcessObject::SetNthInput(0, input);
}

//----------------------------------------------------------------------------
vtkPolyData *vtkSurfaceProps::GetInput()
{
  if (this->NumberOfInputs < 1)
    {
    return NULL;
    }

  return (vtkPolyData *)(this->Inputs[0]);
}

//
// Compute Surface Properties for Input vtkPolyData
//
void vtkSurfaceProps::Execute()
{
  vtkPolyData *input = (vtkPolyData *)this->Inputs[0];
  vtkIdType *ptIds;
  int numCells, jj, kk, type;
  vtkIdType numPts, cellId, pId, qId, rId;
  vtkFloatingPointType p[3], q[3], r[3], xp[3], edge0[3], edge1[3], edge2[3], *center;
  double tri_area, cell_area, tot_area, tri_vol, tot_vol, tot_vol2;

  vtkDebugMacro(<< "Calculating Surface Properties." );

  this->SurfaceArea = 0.0;
  this->MinCellArea = VTK_LARGE_FLOAT;
  this->MaxCellArea = 0.0;
  this->Volume = 0.0;
  this->VolumeError = 0.0;

  tot_area = tot_vol = tot_vol2 = 0.0;

  numPts = input->GetNumberOfPoints();
  numCells = input->GetNumberOfCells();
  if ( this->Inputs[0] == NULL || numPts < 1 || numCells < 1 )
    {
    vtkErrorMacro(<<"Can't compute surface properties - no data available!");
    return;
    }

  center = input->GetCenter();
  //
  // Loop on all polygonal cells
  //
  for ( cellId=0; cellId < numCells; cellId++ )
    {
    type = input->GetCellType( cellId );
    input->GetCellPoints( cellId, numPts, ptIds );
    cell_area = 0.0;
    for ( jj=0; jj<numPts-2; jj++ )
      {
      CELLTRIANGLES( ptIds, type, jj, pId, qId, rId );
      if ( pId < 0 )
        continue;
      input->GetPoint( pId, p );
      input->GetPoint( qId, q );
      input->GetPoint( rId, r );
      // p, q, and r are the oriented triangle points.
      for ( kk=0; kk<3; kk++ )
        {
        // two triangle edge vectors
        edge0[kk] = q[kk] - p[kk];
        edge1[kk] = r[kk] - p[kk];
        }
      vtkMath::Cross( edge0, edge1, xp );
      tri_area = 0.5*vtkMath::Norm( xp );
      cell_area += tri_area;

      tri_vol = vtkMath::Dot( p, xp )/6.0;
      tot_vol2 += tri_vol;
      for ( kk=0; kk<3; kk++ )
        {
        // three tetrahedron edge vectors
        edge0[kk] = p[kk] - center[kk];
        edge1[kk] = q[kk] - center[kk];
        edge2[kk] = r[kk] - center[kk];
        }
      vtkMath::Cross( edge0, edge1, xp );
      tri_vol = vtkMath::Dot( xp, edge2 )/6.0;
      tot_vol += tri_vol;
      } // end foreach triangle

    tot_area += cell_area;
    if ( cell_area > this->MaxCellArea )
      this->MaxCellArea = cell_area;
    if ( cell_area < this->MinCellArea )
      this->MinCellArea = cell_area;
    } // end foreach cell
  this->SurfaceArea = tot_area;
  this->Volume = tot_vol;
  if ( tot_vol > tot_vol2 )
    this->VolumeError = tot_vol - tot_vol2;
  else
    this->VolumeError = tot_vol2 - tot_vol;
}

