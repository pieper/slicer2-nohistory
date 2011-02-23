/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStackOfPolygons.h,v $
  Date:      $Date: 2006/02/14 20:40:16 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
/*=========================================================================

   vtkStackOfPolygons
   Created by Chand T. John for Slicer/NMBL Pipeline

=========================================================================*/
// .NAME vtkStackOfPolygons - represents a sequence of control polygons
// .SECTION Description
// vtkStackOfPolygons is a concrete implementation of the vtkObject class.
// vtkStackOfPolygons represents an ordered sequence of slices, each possibly
// containing multiple control polygons, meant to keep track of all control
// points plotted by the user in Slicer/NMBL Pipeline's Editor->Draw module
// in each slice of data.

#ifndef __vtkStackOfPolygons_h
#define __vtkStackOfPolygons_h

#include "vtkObject.h"
#include "vtkPolygonList.h"
#include "point.h"
#include "vtkSlicer.h"

#include <vector>
#define STACK_OF_POLYGONS_INITIAL_NUM_STACK_SLICES 200

class VTK_SLICER_BASE_EXPORT vtkStackOfPolygons : public vtkObject {
public:
    static vtkStackOfPolygons *New();
    vtkTypeMacro(vtkStackOfPolygons,vtkObject);
    void PrintSelf(ostream& os, vtkIndent indent);

    // Adds polygon to slice s, position p
    void SetPolygon(vtkPoints *polygon, int s, int p, int d, int closed, int preshape, int label);

    // Adds polygon to slice s, first empty position
    void SetPolygon(vtkPoints *polygon, int s, int d);

    // return the number of slots in the array
    unsigned int GetStackSize()
    {   return this->PointStack.size();
    }

    // make sure the array is big enough to handle a
    // PolygonList at the given slot, and ensure that a Polygon List has
    // been allocated for that slot.  
    void PolygonListCreateIfNeeded(int s)
    {
        if ( (unsigned int) s >= this->PointStack.size() ) 
        {   
            unsigned int old_size = this->PointStack.size();
            this->PointStack.reserve( (unsigned int) (2*s) ); // Make plenty of extra space 
            this->IsNonEmpty.reserve( (unsigned int) (2*s) ); 

            for (unsigned int ss = old_size+1; ss < (unsigned int) 2*s; ss++)
            {
                this->PointStack.push_back(NULL);
                this->IsNonEmpty.push_back(0);
            }
        }

        if ( this->PointStack[s] == NULL )
        {
            this->PointStack[s] = vtkPolygonList::New();
        }
    }

    // Returns pointer to polygon p of slice s
    vtkPoints* GetPoints(int s, int p);

    // Returns pointer to first nonempty polygon of slice s
    vtkPoints* GetPoints(int s);

    // Returns pointer to sampled polygon of polygon p in slice s.
    vtkPoints* GetSampledPolygon(int s, int p);

    // Returns density of polygon p in slice s.
    int GetDensity(int s, int p);

    // Returns closedness of polygon p in slice s.
    int GetClosed(int s, int p);

    // Returns preshape of polygon p in slice s.
    int GetPreshape(int s, int p);

    // Returns label of polygon p in slice s.
    int GetLabel(int s, int p);

    // Resets polygon p in slice s
    void RemovePolygon(int s, int p);

    // Returns number of points in first nonempty polygon of slice s.
    int GetNumberOfPoints(int s);

    // Returns lowest index in which there is an empty polygon.
    int ListGetInsertPosition(int s);

    // Returns lowest index after p in which there is an empty polygon.
    int ListGetNextInsertPosition(int s, int p);

    // Returns lowest index in which there is a nonempty polygon.
    int ListGetRetrievePosition(int s);

    // Returns lowest index after p in which there is a nonempty polygon.
    int ListGetNextRetrievePosition(int s, int p);

    // Returns number of polygons to apply, next time Apply is clicked.
    int GetNumApplyable(int s);

    // Returns index of qth polygon to apply.
    int GetApplyable(int s, int q);

    // Removes all polygons in the stack
    void Clear();

    // Returns true if any polygon has ever been applied on slice s
    int Nonempty(int s);

    // Returns number of points in polygon p of slice s.
    int GetNumberOfPoints(int s, int p);

protected:
    vtkStackOfPolygons();
    ~vtkStackOfPolygons();
    vtkStackOfPolygons(const vtkStackOfPolygons&);
    void operator=(const vtkStackOfPolygons&);

//BTX
    // Store polygon data for arbitrary number of slices
    std::vector<vtkPolygonList *> PointStack;

    // IsNonEmpty[s] == false iff no polygon has ever been applied on it
    std::vector<int> IsNonEmpty;
//ETX
};

#endif


