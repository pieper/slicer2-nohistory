/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPolyBoolean.h,v $
  Date:      $Date: 2006/03/31 18:20:41 $
  Version:   $Revision: 1.20 $

=========================================================================auto=*/
// .NAME vtkPolyBoolean - perform boolean union, subtraction or intersection of volumes
// .SECTION Description
// .SECTION Caveats
// .SECTION See Also

#ifndef __vtkPolyBoolean_h
#define __vtkPolyBoolean_h

#include "vtkPoints.h"
#include "vtkCellArray.h"
#include "vtkPointData.h"
#include "vtkPolyData.h"
#include "vtkPolyDataToPolyDataFilter.h"
#include "vtkOBBTree.h"
#include "vtkMatrix4x4.h"
#include "vtkPolygon.h"
#include "vtkBoolTess.h"
#include "vtkSlicer.h"

// Defines for Operation
#define BOOL_A_MINUS_B 0
#define BOOL_A_OR_B 1
#define BOOL_A_AND_B 2
#define BOOL_A_AND_B_1D 3
#define BOOL_A_TOUCHES_B 4
#define BOOL_DEBUG 5

// Defines for CellFlags
#define BOOL_CELL_UNKNOWN 0
#define BOOL_CELL_IN_RESULT 1
#define BOOL_CELL_CUT 2
#define BOOL_CELL_NOT_IN_RESULT 3

class vtkBoolTri;
class vtkPiercePoint;
//
// Special classes to support boolean intersections.
//
//BTX - begin tcl exclude
//
class vtkBoolTriEdge { //; prevent man page generation
public:
  vtkBoolTriEdge();
  ~vtkBoolTriEdge();

  void DeletePPs();

  int Flag;
  int Points[2];
  vtkBoolTri *Neighbors[2]; // the two neighbor triangles
  vtkPiercePoint *FirstPP;
  vtkBoolTriEdge *Next[2]; // next edge on Neighbors 0 & 1
  class vtkPiercePoint *PPoints[2];
};

class vtkPiercePoint { //; prevent man page generation
public:
  vtkPiercePoint();
  ~vtkPiercePoint();

  int NewId;
  void MergePP( vtkPiercePoint *otherPP );
  vtkFloatingPointType Param; // parameter on edge
  vtkFloatingPointType Xparam; // parameter on intersection
  int SnapIdx; // Index of equivalent input data point, or -1 if new.
  vtkFloatingPointType Point[3]; // 3d position of PP
  vtkBoolTriEdge *Edge; // piercing edge;
  vtkBoolTri *Triangle;
  vtkPiercePoint *Next; // pointer to next PP on this edge
  vtkPiercePoint *Prev; // pointer to previous PP on this edge
  vtkPiercePoint *Merge; // next PP to merge with this one.
    vtkBoolTriEdge *NextEdge[2]; // pointer to next Edge along
                               // intersection in each direction
};

class vtkNewBoolEdges { //; prevent man page generation
public:
  vtkNewBoolEdges();
  ~vtkNewBoolEdges()
    {
    if ( this->Array )
      {
      delete [] this->Array;
      }
    };

  void AddNewEdge( vtkBoolTriEdge *thisEdge );
  void Reset();
  int GetCount();
  vtkBoolTriEdge *Get( int idx ) { return this->Array[idx]; };

protected:
  vtkBoolTriEdge **Array;
  int ArraySize;
  int Count;
  int GrowSize;
};

class vtkBoolLoop { //;prevent man page generation
public:
  vtkBoolLoop();
  ~vtkBoolLoop();

  int sign;          // Positive for outer loops, negative for inner loops.
  vtkIdList *Points; // ids of loop vertices
  vtkBoolLoop *Next;     // next triangle in the triangulation of this cell
};

class vtkBoolTri { //;prevent man page generation
public:
  vtkBoolTri();
  ~vtkBoolTri();

  int AorB;             // 0=from PolyDataA, 1=from PolyDataB.
  vtkFloatingPointType Normal[3];      // triangle Normal
  vtkFloatingPointType Offset;         // plane offset of this triangle ( Normal*p0 )
  vtkBoolTriEdge *Edges[3]; // pointers to the three edges
  vtkBoolTri *Next;     // next triangle in the triangulation of this cell
  int CellId;           // id of the parent cell
  vtkBoolLoop *NewLoops;// linked list of resulting loops
};
//ETX - end tcl exclude
//

class VTK_SLICER_BASE_EXPORT vtkPolyBoolean : public vtkPolyDataToPolyDataFilter
{
public:
//  vtkPolyBoolean(vtkPolyData *pd=NULL);
  static vtkPolyBoolean *New() {return new vtkPolyBoolean;}
  vtkTypeMacro(vtkPolyBoolean,vtkPolyDataToPolyDataFilter);

  // const char* GetClassName() {return "vtkPolyBoolean";}
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Set the distance resolution. Default is 1.0E-6;
  vtkSetMacro(DistanceResolution,vtkFloatingPointType);
  vtkGetMacro(DistanceResolution,vtkFloatingPointType);

  // Description:
  // Set the angle resolution. Default is .003 degrees.
  vtkSetMacro(AngleResolution,vtkFloatingPointType);
  vtkGetMacro(AngleResolution,vtkFloatingPointType);

  void SPLTestIntersection();

  // Description:
  // Set the boolean operation. Default is A-B.
  void SetOperation( int operation );
  vtkGetMacro(Operation,int);

  // Description:
  // Override the SetInput functino from vtkPolyDataFilter
  //  void SetInput2( vtkPolyData *input );

  // Description:
  // Specify the second polydata source for the operation
  void SetPolyDataB( vtkPolyData *polyDataB );
  vtkPolyData *GetPolyDataB() {return (vtkPolyData *)this->PolyDataB;};

  // Description
  // Specify the two xform matrices;
  vtkSetObjectMacro(XformA,vtkMatrix4x4);
  vtkGetObjectMacro(XformA,vtkMatrix4x4);
  vtkSetObjectMacro(XformB,vtkMatrix4x4);
  vtkGetObjectMacro(XformB,vtkMatrix4x4);

  vtkGetMacro(IntersectionCount,int);
  vtkGetMacro(TriangleCount,int);
  vtkGetMacro(NodeCount,int);

  vtkGetMacro(TestCount,int);


  unsigned long int GetMTime();

  // Description:
  // Override the default Update method since this filter has multiple
  // inputs.
  void UpdateCutter();

protected:
  vtkPolyBoolean();
  ~vtkPolyBoolean();
  void Execute();

  static int ProcessTwoNodes(vtkOBBNode *nodeA, vtkOBBNode *nodeB,
                             vtkMatrix4x4 *XformBtoA,
                             void *bool_void);
  void BuildBPoints( vtkMatrix4x4 *XformBtoA );
  void AddCellTriangles( vtkIdType cellId, vtkIdType *ptIds, int type,
                         vtkIdType numPts, int AorB );
  int IntersectCellPair( int cellIdA, int cellIdB );
  int IntersectBoolTriPair( vtkBoolTri *triA, vtkBoolTri *triB );
  void MakeNewPoint( vtkPiercePoint *inPP );
  vtkPolyData *PolyDataB;
  int Operation;
  int IntersectionCount; // Number of intersecting triangle pairs
  int TriangleCount; // Number of triangle pairs intersected
  int NodeCount; // Number of intersecting OBBTree node pairs
  int TestCount;
  vtkMatrix4x4 *XformA;
  vtkMatrix4x4 *XformB;
  vtkFloatingPointType DistanceResolution;
  vtkFloatingPointType AngleResolution;
  vtkNewBoolEdges NewEdges;
  vtkPoints *NewPoints;
  vtkCellArray *NewPolys;
  vtkCellArray *NewLines;
  vtkCellArray *NewVerts;
  int ExecutionCount;

  void DeleteTriDirectory( int AorB );
  void ResetBoolTris();
  void DeleteNewEdges();
  void ProcessNewEdges();
  void FormLoops();
  void ClassifyCells();
  void GatherMarkCellNeighbors( int AorB, vtkPolyData *dataset,
                                int cellId, int marker );
  void AddNewPolygons( vtkBoolTri *thisTri );
  void SortLoops( vtkBoolTri *thisTri );
  void DisplayIntersectionGeometry();

private:
  vtkOBBTree *OBBTreeA;
  vtkOBBTree *OBBTreeB;
  vtkPoints *BPoints;
  vtkBoolTri **TriDirectory[2];
  int *CellFlags[2];
  int *CellFlagsB;
  int *NewPointIds[2];
  int NewIdsUpdate;
  vtkIdList *ThisLoop;
  vtkIdList *TriPts;
  int IdOffsetB;
  int IdOffsetNew;
  vtkBoolTess *Tess;
  int TriDirectorySize[2];

  // time when Execute method was last called
  vtkTimeStamp ExecuteTime;
};

#endif
