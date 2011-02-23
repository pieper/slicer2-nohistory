/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkFastCellPicker.cxx,v $
  Date:      $Date: 2006/03/06 19:02:25 $
  Version:   $Revision: 1.17 $

=========================================================================auto=*/
#include "vtkFastCellPicker.h"
#include "vtkObjectFactory.h"

vtkStandardNewMacro(vtkFastCellPicker);

vtkFastCellPicker::vtkFastCellPicker()
{
  this->CellId = -1;
  this->SubId = -1;
  for (int i=0; i<3; i++)
    {
    this->PCoords[i] = 0.0;
    }
  this->OBBTrees = vtkCollection::New();
}

#if ( (VTK_MAJOR_VERSION == 3 && VTK_MINOR_VERSION == 2) || VTK_MAJOR_VERSION >= 4 )
vtkFloatingPointType vtkFastCellPicker::IntersectWithLine(vtkFloatingPointType p1[3], vtkFloatingPointType p2[3], vtkFloatingPointType tol, 
                      vtkAssemblyPath *assem, vtkActor *a, 
                      vtkMapper *m)
#else
vtkFloatingPointType vtkFastCellPicker::IntersectWithLine(vtkFloatingPointType p1[3], vtkFloatingPointType p2[3], vtkFloatingPointType tol, 
                      vtkActor *assem, vtkActor *a, 
                      vtkMapper *m)
#endif
{
  int numCells, ii, nOBBTrees;
  int i, minSubId;
  vtkIdType minCellId;
  vtkFloatingPointType x[3], t, pcoords[3];
  //vtkCell *cell;
  vtkDataSet *input=m->GetInput();
  vtkOBBTree *pOBBTree, *thisOBBTree;

  if ( (numCells = input->GetNumberOfCells()) < 1 )
    {
    return 2.0;
    }

  nOBBTrees = this->OBBTrees->GetNumberOfItems();
  pOBBTree = NULL;
  for ( ii=0; ii<nOBBTrees && pOBBTree == NULL; ii++ )
    {
    thisOBBTree = (vtkOBBTree *)this->OBBTrees->GetItemAsObject( ii );
    if ( thisOBBTree->GetDataSet() == input )
      {
      pOBBTree = thisOBBTree;
      vtkDebugMacro("Using OBBTree:" << pOBBTree);
      }
    }
  if ( pOBBTree == NULL )
    { // Initialize an OBBTree for this dataset
    pOBBTree = vtkOBBTree::New();
    pOBBTree->SetDataSet( input );
    pOBBTree->SetDebug( 0 );
    this->OBBTrees->AddItem( (vtkObject *)pOBBTree );
    vtkDebugMacro("Making OBBTree:" << pOBBTree);
    vtkDebugMacro("Number of OBBTrees now is:" <<
                  this->OBBTrees->GetNumberOfItems());
    }
  pOBBTree->Update();
  //
  //  Intersect each cell with ray.  Keep track of one closest to 
  //  the eye (and within the clipping range).
  //
  minCellId = -1;
  minSubId = -1;
  if ( pOBBTree->IntersectWithLine( &p1[0], &p2[0], tol, t, &x[0], &pcoords[0],
                                    minSubId, minCellId ) )
    {
    //
    //  Now compare this against other actors.
    //
    if ( minCellId>(-1) && t < this->GlobalTMin ) 
      {
      this->MarkPicked(assem, a, m, t, x);
      this->CellId = minCellId;
      this->SubId = minSubId;
      for (i=0; i<3; i++)
        {
        this->PCoords[i] = pcoords[i];
        }
      vtkDebugMacro("Picked cell id= " << minCellId);
      }
    }
  else
    {
    t = 2.0;
    }
  return t;
}

void vtkFastCellPicker::Initialize()
{
  this->CellId = (-1);
  this->SubId = (-1);
  for (int i=0; i<3; i++)
    {
    this->PCoords[i] = 0.0;
    }
  this->vtkPicker::Initialize();
}

void vtkFastCellPicker::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkPicker::PrintSelf(os,indent);

  os << indent << "Cell Id: " << this->CellId << "\n";
  os << indent << "SubId: " << this->SubId << "\n";
  os << indent << "PCoords: (" << this->PCoords[0] << ", " 
     << this->PCoords[1] << ", " << this->PCoords[2] << ")\n";
}
