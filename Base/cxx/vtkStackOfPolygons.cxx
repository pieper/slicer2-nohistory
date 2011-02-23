/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStackOfPolygons.cxx,v $
  Date:      $Date: 2006/01/06 17:56:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

    vtkStackOfPolygons
    Created by Chand T. John for Slicer/NMBL Pipeline

=========================================================================*/
#include "vtkStackOfPolygons.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkStackOfPolygons* vtkStackOfPolygons::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkStackOfPolygons");
  if (ret)
    {
    return (vtkStackOfPolygons*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkStackOfPolygons;
}

//-----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkStackOfPolygons::vtkStackOfPolygons()
{
    
    this->PointStack.reserve( STACK_OF_POLYGONS_INITIAL_NUM_STACK_SLICES ); // Make plenty of extra space 
    this->IsNonEmpty.reserve( STACK_OF_POLYGONS_INITIAL_NUM_STACK_SLICES );
    for (unsigned int s = 0; s < this->PointStack.capacity(); s++)
    {
        this->PointStack.push_back(NULL);
        this->IsNonEmpty.push_back(0);
    }
}

vtkStackOfPolygons::~vtkStackOfPolygons()
{
    for (unsigned int s = 0; s < this->PointStack.capacity(); s++)
    {
        if ( this->PointStack[s] != NULL )
        {
            this->PointStack[s]->Delete();
        }
    }
}

void vtkStackOfPolygons::SetPolygon(vtkPoints *polygon, int s, int p, int d, int closed, int preshape, int label)
{
    this->PolygonListCreateIfNeeded(s);
    this->PointStack[s]->Reset(p);
    int n = polygon->GetNumberOfPoints();
    vtkFloatingPointType *rasPt;
    for (int i = 0; i < n; i++)
    {
        rasPt = polygon->GetPoint(i);
        this->PointStack[s]->InsertNextPoint(p, rasPt[0], rasPt[1], rasPt[2]);
    }
    this->PointStack[s]->SetDensity(p, d);
    this->PointStack[s]->SetClosed(p, closed);
    this->PointStack[s]->SetPreshape(p, preshape);
    this->PointStack[s]->SetLabel(p, label);
    this->PointStack[s]->UpdateApplyOrder(p);
    if (!this->IsNonEmpty[s]) this->IsNonEmpty[s] = 1;
}

void vtkStackOfPolygons::SetPolygon(vtkPoints *polygon, int s, int d)
{
    this->PolygonListCreateIfNeeded(s);
    int p = this->PointStack[s]->GetInsertPosition();
    this->PointStack[s]->Reset(p); // Probably unnecessary
    int n = polygon->GetNumberOfPoints();
    vtkFloatingPointType *rasPt;
    for (int i = 0; i < n; i++)
    {
        rasPt = polygon->GetPoint(i);
        this->PointStack[s]->InsertNextPoint(p, rasPt[0], rasPt[1], rasPt[2]);
    }
    this->PointStack[s]->SetDensity(p, d);
    if (!this->IsNonEmpty[s]) this->IsNonEmpty[s] = 1;
}

vtkPoints* vtkStackOfPolygons::GetPoints(int s)
{
    this->PolygonListCreateIfNeeded(s);
    int p = this->PointStack[s]->GetRetrievePosition();
    return this->PointStack[s]->GetPolygon(p);
}

vtkPoints* vtkStackOfPolygons::GetPoints(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetPolygon(p);
}

vtkPoints* vtkStackOfPolygons::GetSampledPolygon(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetSampledPolygon(p);
}

int vtkStackOfPolygons::GetDensity(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetDensity(p);
}

int vtkStackOfPolygons::GetClosed(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetClosed(p);
}

int vtkStackOfPolygons::GetPreshape(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetPreshape(p);
}

int vtkStackOfPolygons::GetLabel(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetLabel(p);
}

void vtkStackOfPolygons::RemovePolygon(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    this->PointStack[s]->Reset(p);
    this->PointStack[s]->RemoveApplyOrder(p);
}

int vtkStackOfPolygons::GetNumberOfPoints(int s)
{
    this->PolygonListCreateIfNeeded(s);
    int p = this->PointStack[s]->GetRetrievePosition();
    vtkPoints *ras = this->PointStack[s]->GetPolygon(p);
    int n = -1;
    if (ras != NULL) n = ras->GetNumberOfPoints();
    return n;
}

int vtkStackOfPolygons::ListGetInsertPosition(int s)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetInsertPosition();
}

int vtkStackOfPolygons::ListGetNextInsertPosition(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetNextInsertPosition(p);
}

int vtkStackOfPolygons::ListGetRetrievePosition(int s)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetRetrievePosition();
}

int vtkStackOfPolygons::ListGetNextRetrievePosition(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetNextRetrievePosition(p);
}

int vtkStackOfPolygons::GetNumApplyable(int s)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetNumApplyable();
}

int vtkStackOfPolygons::GetApplyable(int s, int q)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetApplyable(q);
}

void vtkStackOfPolygons::Clear()
{
    for (unsigned int s = 0; s < this->GetStackSize(); s++)
    {
        if ( this->PointStack[s] != NULL )
        {
            this->PointStack[s]->Clear();
        }
    }
}

int vtkStackOfPolygons::Nonempty(int s)
{
    return this->IsNonEmpty[s];
}

int vtkStackOfPolygons::GetNumberOfPoints(int s, int p)
{
    this->PolygonListCreateIfNeeded(s);
    return this->PointStack[s]->GetNumberOfPoints(p);
}

void vtkStackOfPolygons::PrintSelf(ostream& os, vtkIndent indent)
{
    this->Superclass::PrintSelf(os,indent);

    for (unsigned int s = 0; s < this->GetStackSize(); s++)
    {
        if ( this->PointStack[s] != NULL ) 
        {
            os << indent << "Slice " << s << ":" << endl;
            this->PointStack[s]->PrintSelf(os, indent);
        }
    }
}

