/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBoolTess.cxx,v $
  Date:      $Date: 2006/03/06 22:47:20 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
#include "vtkBoolTess.h"
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

#define SIGN(x) (x>0?1:(x<0?-1:0))

// Decompose a polygon with or without holes into triangles, via
// monotone polygon intermediates. Perform triangulation by projecting
// along the axis closest to the normal vector. Sort points along
// the axis of greatest extent.
vtkBoolTess::vtkBoolTess()
{
  this->NumContours = 0;
  this->NumInputEdges = 0;
  this->NumNewEdges = 0;
  this->NumTriangles = 0;
  this->PrevNumInputEdges = 0;

  this->ProjAxis = 0;
  this->SortAxis = 0;
  this->YAxis = 0;
  this->Orient = 0;
  
  this->InputEdges = NULL;
  this->NewEdges = NULL;
  this->Vertices = NULL;
  this->SortArray = NULL;
  this->ActivePairs = NULL;
  this->Triangles = NULL;

  }

vtkBoolTess::~vtkBoolTess()
{
  if (this->InputEdges)
  {
    delete [] this->InputEdges;
  }
  if (this->NewEdges)
  {
    delete [] this->NewEdges;
  }
  if (this->Vertices)
  {
    delete [] this->Vertices;
  }
  if (this->SortArray)
  {
    delete [] this->SortArray;
  }
  if (this->ActivePairs)
  {
    delete [] this->ActivePairs;
  }
  if (this->Triangles)
  {
    delete [] this->Triangles;
  }
}

vtkBoolTess *tess;

void vtkBoolTess::Reset()
  {
  this->NumContours = this->NumInputEdges = 0;
  }

void vtkBoolTess::SetPoints( vtkFloatingPointType *points )
  {
  this->Points = (vtkFloatingPointType (*)[3])points;
  }

int vtkBoolTess::AddContour( vtkIdType nPts, vtkIdType *ptIds )
  {
  if ( this->NumContours == VTK_BOOL_MAX_CONTOURS )
    {
    return( -1 );
    }
  this->NLoopPts[this->NumContours] = nPts;
  this->Contours[this->NumContours++] = ptIds;
  this->NumInputEdges += nPts;
  return( 0 );
  }

int vtkBoolTess::Triangulate( vtkIdType **tris )
  {
  int ii, jj, kk;
  int nContours, nEdges;
  vtkIdType **ptIds, *nPts;
  int edgeIndex, prevIndex;
  double bbox[2][3], normal[3];
  int ptId0, ptId1;
  vtkFloatingPointType *thisPnt;
  vtkFloatingPointType (*points)[3] = this->Points;
  extern vtkBoolTess *tess;

  nContours = this->NumContours;
  ptIds = this->Contours;
  nEdges = this->NumInputEdges;
  nPts = this->NLoopPts;

//  cout << "Triangulate nContours=" << nContours << " (";
  for ( ii=0; ii<nContours; ii++ )
    {
//    cout << nPts[ii] << " ";
    }
//  cout << ")\n";

  // First compute the bounding box of the point set.
  bbox[0][0] = bbox[1][0] = points[ptIds[0][0]][0];
  bbox[0][1] = bbox[1][1] = points[ptIds[0][0]][1];
  bbox[0][2] = bbox[1][2] = points[ptIds[0][0]][2];

  for ( ii=0; ii<nContours; ii++ )
    {
    for ( jj=0; jj<nPts[ii]; jj++ )
      {
      for ( kk=0; kk<3; kk++ )
        {
        thisPnt = points[ptIds[ii][jj]];
        if ( thisPnt[kk] < bbox[0][kk] )
          bbox[0][kk] = thisPnt[kk];
        else if ( thisPnt[kk] > bbox[1][kk] )
          bbox[1][kk] = thisPnt[kk];
        }
      }
    }

  // Load the internal arrays
  if ( nEdges > this->PrevNumInputEdges )
    {
//nEdges += 200;
    if ( this->InputEdges )
      delete [] this->InputEdges;
    this->InputEdges = new vtkBoolTessEdge [nEdges];
    if ( this->NewEdges )
      delete [] this->NewEdges;
    this->NewEdges = new vtkBoolTessEdge[nEdges*2];
    if ( this->Vertices )
      delete [] this->Vertices;
    this->Vertices = new vtkBoolTessVtx[nEdges];
    if ( this->SortArray )
      delete [] this->SortArray;
    this->SortArray = new vtkBoolTessVtx *[nEdges];
    if ( this->ActivePairs )
      delete [] this->ActivePairs;
    this->ActivePairs = new vtkBoolTessPair [nEdges];
    if ( this->Triangles )
      delete [] this->Triangles;
    // The maximum # of triangles = nEdges+2*nContours-4
    this->Triangles = new vtkIdType[3*(nEdges + 2*nContours - 4)];
    this->PrevNumInputEdges = nEdges;
//nEdges -= 200;
    }
   
  this->NumNewEdges = this->NumTriangles = 0;
  edgeIndex = 0;
  for ( ii=0; ii<nContours; ii++ )
    {
    prevIndex = edgeIndex + nPts[ii]-1;
    for ( jj=0; jj<nPts[ii]; jj++ )
      {
//      cout << " " << ptIds[ii][jj];
      this->SortArray[edgeIndex] = &this->Vertices[edgeIndex];
      this->Vertices[edgeIndex].PntId = ptIds[ii][jj];
      this->Vertices[edgeIndex].Flag = 0;
      this->Vertices[edgeIndex].NextEdge = &this->InputEdges[edgeIndex];
      this->Vertices[edgeIndex].PrevEdge = &this->InputEdges[prevIndex];
      this->InputEdges[edgeIndex].Prev = &this->InputEdges[prevIndex];
      this->InputEdges[edgeIndex].Vertices[0] = &this->Vertices[edgeIndex];
      if ( jj == nPts[ii]-1 )
        {
        this->InputEdges[edgeIndex].Vertices[1] =
                         &this->Vertices[edgeIndex + 1 - nPts[ii]];
        this->InputEdges[edgeIndex].Next =
                         &this->InputEdges[edgeIndex + 1 - nPts[ii] ];
        }
      else
        {
        this->InputEdges[edgeIndex].Vertices[1] =
                         &this->Vertices[edgeIndex + 1];
        this->InputEdges[edgeIndex].Next = &this->InputEdges[edgeIndex + 1];
        }
      prevIndex = edgeIndex;
      edgeIndex++;
if (edgeIndex > this->NumInputEdges) *((int *)0L) = 0;
      }
//    cout << "\n";
    }

  // Use contours for normal calculation
  normal[0] = normal[1] = normal[2] = 0.0;
  for ( ii=0; ii<nContours; ii++ )
    {
    for ( jj=0; jj<nPts[ii]; jj++ )
      {
      ptId0 = ptIds[ii][jj];
      ptId1 = ptIds[ii][(jj+1)%nPts[ii]];
      normal[0] += points[ptId0][1]*points[ptId1][2] -
                   points[ptId0][2]*points[ptId1][1];
      normal[1] += points[ptId0][2]*points[ptId1][0] -
                   points[ptId0][0]*points[ptId1][2];
      normal[2] += points[ptId0][0]*points[ptId1][1] -
                   points[ptId0][1]*points[ptId1][0];
      }
    }

  // Project along the dominant axis.
  if ( fabs(normal[0]) > fabs(normal[1]) )
    this->ProjAxis = 0;
  else
    this->ProjAxis = 1;
  if ( fabs(normal[2]) > fabs(normal[this->ProjAxis]) )
    this->ProjAxis = 2;

  // Now compute the sorting axis
  this->SortAxis = (this->ProjAxis+1)%3;
  this->YAxis = (this->SortAxis+1)%3;
  if ( bbox[1][this->YAxis]-bbox[0][this->YAxis] >
       bbox[1][this->SortAxis]-bbox[0][this->SortAxis] )
    { // swap SortAxis with YAxis
    this->YAxis = (this->ProjAxis+1)%3;
    this->SortAxis = (this->SortAxis+1)%3;
    }

  this->Orient = SIGN( normal[this->ProjAxis] );

  // Sort the vertices along SortAxis
  tess = this;
  qsort( (void *)this->SortArray, nEdges, sizeof( vtkBoolTessEdge * ),
         this->SortCompare );


  // Everything is set up. Call the main algorithm.
  this->GenerateTriangles();

  *tris = this->Triangles;

  return( this->NumTriangles );
  }

int vtkBoolTess::GenerateTriangles()
  {
  int pos, ii, jj, nActivePairs = 0;
  int fwdIdx, bckIdx, newIdx;
  vtkBoolTessEdge *edges, *thisEdge, *prevEdge;
  vtkBoolTessVtx *thisVtx, *vertices;
  double area;
  vtkBoolTessPair *activePairs;

  vertices = this->Vertices;
  edges = this->InputEdges;
  activePairs = this->ActivePairs;
  for ( pos=0; pos<this->NumInputEdges; pos++ )
    {
    thisVtx = this->SortArray[pos];
    thisVtx->Flag = 1;
    prevEdge = thisVtx->PrevEdge;
    if ( this->NumInputEdges > 10 )
      {
//      cout << pos << "-" << thisVtx->PntId
//           << ":(" << this->Points[thisVtx->PntId][this->SortAxis]
//           << "," << this->Points[thisVtx->PntId][this->YAxis] << ")\n";
      }
    // Classify this vertex as one of the following:
    // 1) The end of an active edge and the beginning of a new one.
    // 2) The end of two active edges.
    // 3) The beginning of two active edges.

    // Note: Each pair of active edges has its own prev vtx!!!
    // Loop invariant: even-numbered active edges move to the
    // "right", odd-numbered ones to the left.
    fwdIdx = bckIdx = -1;
    for ( ii=0; ii<nActivePairs; ii++ )
      {
      if ( activePairs[ii].Edges[0] == thisVtx->PrevEdge )
        fwdIdx = ii;
      if ( activePairs[ii].Edges[1] == thisVtx->NextEdge )
        bckIdx = ii;
      }

//    if ( this->NumInputEdges > 10 )
//      cout << fwdIdx << " " << bckIdx << "\n";
    if ( fwdIdx >= 0 )
      {
      if ( bckIdx >= 0 )
        { // Case 2: The end of two active edges.
        // Remove them from the active list.
        if ( fwdIdx != bckIdx )
          { // Then we are merging two pairs of active edges.
          if ( activePairs[fwdIdx].Edges[0]->Vertices[0] !=
               activePairs[fwdIdx].PrevEdge->Vertices[1] )
            {
            this->AddNewEdges( activePairs[fwdIdx].PrevEdge,
                               thisVtx->NextEdge );
            prevEdge = &this->NewEdges[this->NumNewEdges-1];
            this->TriangulateMonotone( activePairs[fwdIdx].Edges[0] );
            }
          if ( activePairs[bckIdx].Edges[1]->Vertices[1] !=
               activePairs[bckIdx].PrevEdge->Vertices[1] )
            {
            this->AddNewEdges( activePairs[bckIdx].PrevEdge,
                               thisVtx->NextEdge );
            this->TriangulateMonotone( activePairs[bckIdx].Edges[1] );
            }
          activePairs[bckIdx].Edges[1] = activePairs[fwdIdx].Edges[1];
          activePairs[bckIdx].PrevEdge = prevEdge;
          }
        else
          { // A simple end of an active pair.
          if ( activePairs[fwdIdx].Edges[0]->Vertices[0] !=
               activePairs[fwdIdx].PrevEdge->Vertices[1] &&
               activePairs[fwdIdx].Edges[1]->Vertices[1] !=
               activePairs[fwdIdx].PrevEdge->Vertices[1] )
            {
            this->AddNewEdges( activePairs[fwdIdx].PrevEdge,
                               thisVtx->NextEdge );
            this->TriangulateMonotone( activePairs[fwdIdx].Edges[0] );
            this->TriangulateMonotone( activePairs[fwdIdx].Edges[1] );
            }
          else
            {
            if ( activePairs[fwdIdx].Edges[0]->Vertices[0] !=
                 activePairs[fwdIdx].PrevEdge->Vertices[1] )
              this->TriangulateMonotone( activePairs[fwdIdx].Edges[0] );
            else
              this->TriangulateMonotone( activePairs[fwdIdx].Edges[1] );
            }
          }
        for ( ii=fwdIdx; ii<nActivePairs-1; ii++ )
          {
          activePairs[ii] = activePairs[ii+1];
          }
        nActivePairs--;
        }
      else
        { // Case 1: Forward-pointing edge in the active pair is replaced
        if ( pos == 0 )
          {
          cout << "Impossible geometry! " << __FILE__ << __LINE__ << "\n";
          }
        else
          {
          if ( activePairs[fwdIdx].Edges[0]->Vertices[0] !=
               activePairs[fwdIdx].PrevEdge->Vertices[1] )
            { // Connect prev vtx to this vtx (if not already connected)
            this->AddNewEdges( activePairs[fwdIdx].PrevEdge,
                               thisVtx->NextEdge );
            prevEdge = &this->NewEdges[this->NumNewEdges-1];
            this->TriangulateMonotone( activePairs[fwdIdx].Edges[0] );
            }
          // replace the active forward edge
          activePairs[fwdIdx].Edges[0] = thisVtx->NextEdge;
          activePairs[fwdIdx].PrevEdge = prevEdge;
          }
        }
      }
    else
      {
      if ( bckIdx >= 0 )
        { // Case 1: Backward-point edge in the active pair is replaced
        if ( pos == 0 )
          {
          cout << "Impossible geometry! " << __FILE__ << __LINE__ << "\n";
          }
        else
          {
          if ( activePairs[bckIdx].Edges[1]->Vertices[1] !=
               activePairs[bckIdx].PrevEdge->Vertices[1] )
            { // Connect prev vtx to this vtx
            this->AddNewEdges( activePairs[bckIdx].PrevEdge,
                               thisVtx->NextEdge );
            this->TriangulateMonotone( activePairs[bckIdx].Edges[1] );
            }
          // replace the active backward edge
          activePairs[bckIdx].Edges[1] = thisVtx->PrevEdge;
          activePairs[bckIdx].PrevEdge = prevEdge;
          }
        }
      else
        { // Case 3: The beginning of two active edges
        // Insert the pair into the active array
        // and make a new edge to the prev vtx.
        newIdx = -1;
        for ( ii=0; ii<nActivePairs && newIdx == -1; ii++ )
          { // Scan for insertion point
          for ( jj=0; jj<2; jj++ )
            {
            thisEdge = activePairs[ii].Edges[jj];
            // insert this vertex between correct edges, based
            // on signed triangle areas.
            area = this->ProjTriangleArea( thisVtx->PntId,
                                           thisEdge->Vertices[0]->PntId,
                                           thisEdge->Vertices[1]->PntId );
            if ( jj == 1 )
              area *= -1;
            if ( area < 0.0 )
              {
              newIdx = ii;
              break;
              }
            }
          }
        if ( newIdx == -1 )
          newIdx = nActivePairs;
        for ( ii=nActivePairs-1; ii>=newIdx; ii-- )
          { // Make room for two new edges.
          activePairs[ii+1] = activePairs[ii];
          }
        if ( newIdx < nActivePairs &&
             thisEdge == activePairs[newIdx].Edges[1] )
          { // The current active pair is split by this new pair.
          // Unconditionally insert a new edge.
          this->AddNewEdges( activePairs[newIdx].PrevEdge,
                             thisVtx->NextEdge );
          activePairs[newIdx].Edges[1] = thisVtx->PrevEdge;
          activePairs[newIdx+1].Edges[0] = thisVtx->NextEdge;
          activePairs[newIdx].PrevEdge = prevEdge;
          activePairs[newIdx+1].PrevEdge =
                            &this->NewEdges[this->NumNewEdges-1];;
          }
        else
          { // Insert a new active pair in the list.
          activePairs[newIdx].Edges[0] = thisVtx->NextEdge;
          activePairs[newIdx].Edges[1] = thisVtx->PrevEdge;
          activePairs[newIdx].PrevEdge = prevEdge;
          }
        nActivePairs++;
        }
      }
    cout.flush();
    }
  return( 0 );
  }

void vtkBoolTess::TriangulateMonotone( vtkBoolTessEdge *firstEdge )
  {
  int nEdges, baseIndex, ii, jj, tmpId, nPasses = 0;
  vtkBoolTessEdge *thisEdge;
  vtkIdType *tris;
  double area;

  tris = this->Triangles;
  baseIndex = this->NumTriangles * 3;
//  cout << "Monotone:";
  nEdges = 0;
  thisEdge = firstEdge;
  do {
    tris[baseIndex+nEdges] = thisEdge->Vertices[1]->PntId;
    nEdges++;
    if ( thisEdge->Vertices[0]->Flag != 1 || thisEdge->Vertices[1]->Flag != 1 )
      { // Should never happen!
      cout << "Polygon Loop got Lost!!!!!!!!\n";
      }
    thisEdge = thisEdge->Next;
    }while( thisEdge != firstEdge );
//  cout.flush();

  while( nEdges > 3 )
    { // Subdivide the monotone polygon
    nPasses++;
    for ( ii=baseIndex; ii<baseIndex+nEdges-2; ii++ )
      {
      area = this->ProjTriangleArea( tris[ii], tris[ii+1], tris[ii+2] );
      if ( area > 0.0 || nPasses > nEdges )
        { // Snip off this "ear" and reduce nEdges by one.
        tmpId = tris[ii+1];
        for ( jj=baseIndex+nEdges-1; jj>=ii+2; jj-- )
          {
          tris[jj+2] = tris[jj];
          }
        for ( jj=ii; jj>=baseIndex; jj-- )
          {
          tris[jj+3] = tris[jj];
          }
        tris[baseIndex] = tris[ii+3];
        tris[baseIndex+1] = tmpId;
        tris[baseIndex+2] = tris[ii+4];
        baseIndex += 3;
        this->NumTriangles++;
        nEdges--;
        ii += 4;
        }
      }
if ( this->NumTriangles > this->PrevNumInputEdges*3 )
  *((int *)0L) = 0;
//for ( jj=0; jj<this->NumTriangles*3+nEdges; jj++ )
//  {
//  cout << tris[jj];
//  if ( jj < this->NumTriangles*3 && jj%3<2 )
//    cout << "+";
//  else
//    cout << " ";
//  }
//cout << "\n";
//cout.flush();
    }
  // Account for the last triangle.
  this->NumTriangles++;
  }

void vtkBoolTess::AddNewEdges( vtkBoolTessEdge *prevEdge,
                               vtkBoolTessEdge *nextEdge )
  {
  int numNew;
  vtkBoolTessEdge *newEdges[2];

  this->NumNewEdges += 2;
if (this->NumNewEdges > this->NumInputEdges*2) *((int *)0L) = 0;
  numNew = this->NumNewEdges;
  newEdges[0] = &this->NewEdges[numNew-1];
  newEdges[1] = &this->NewEdges[numNew-2];
  newEdges[0]->Next = nextEdge;
  newEdges[0]->Prev = prevEdge;
  newEdges[1]->Next = prevEdge->Next;
  newEdges[1]->Prev = nextEdge->Prev;
  prevEdge->Next = newEdges[0];
  nextEdge->Prev = newEdges[0];
  newEdges[1]->Next->Prev = newEdges[1];
  newEdges[1]->Prev->Next = newEdges[1];
  newEdges[0]->Vertices[0] = newEdges[1]->Vertices[1] = prevEdge->Vertices[1];
  newEdges[0]->Vertices[1] = newEdges[1]->Vertices[0] = nextEdge->Vertices[0];
//  cout << "NewEdge: " << prevEdge->Vertices[1]->PntId << " " <<
//          nextEdge->Vertices[0]->PntId << "\n";
  }

double vtkBoolTess::ProjTriangleArea( int ptId0, int ptId1, int ptId2 )
  {
  int X = (this->ProjAxis+1)%3, Y = (this->ProjAxis+2)%3;
  double vec0[2], vec1[2], area;

  vec0[0] = this->Points[ptId1][X] - this->Points[ptId0][X];
  vec1[0] = this->Points[ptId2][X] - this->Points[ptId0][X];
  vec0[1] = this->Points[ptId1][Y] - this->Points[ptId0][Y];
  vec1[1] = this->Points[ptId2][Y] - this->Points[ptId0][Y];
  area = 0.5*(vec0[0]*vec1[1] - vec0[1]*vec1[0]);
  return( area*this->Orient );
  }

int vtkBoolTess::SortCompare(const void *arg1, const void *arg2 )
  {
  vtkBoolTessVtx *vtx1, *vtx2;
  int sortAxis, yAxis;
  extern vtkBoolTess *tess;

  sortAxis = tess->SortAxis;
  vtx1 = *(vtkBoolTessVtx **)arg1;
  vtx2 = *(vtkBoolTessVtx **)arg2;
  if ( tess->Points[vtx1->PntId][sortAxis] <
       tess->Points[vtx2->PntId][sortAxis] )
    return( -1 );
  if ( tess->Points[vtx1->PntId][sortAxis] >
       tess->Points[vtx2->PntId][sortAxis] )
    return( 1 );
  yAxis = tess->YAxis;
  if ( tess->Points[vtx1->PntId][yAxis] < tess->Points[vtx2->PntId][yAxis] )
    return -1;
  if ( tess->Points[vtx1->PntId][yAxis] > tess->Points[vtx2->PntId][yAxis] )
    return 1;
  else
    return 0;
  }

void vtkBoolTess::PrintSelf(ostream& os, vtkIndent indent)
{
    this->Superclass::PrintSelf(os,indent);

    os << indent << "NumContours: " << this->NumContours << endl;
    os << indent << "NumInputEdges: " << this->NumInputEdges << endl;
    os << indent << "NumNewEdges: " << this->NumNewEdges << endl;
    os << indent << "NumTriangles: " << this->NumTriangles << endl;
    os << indent << "PrevNumInputEdges: " << this->PrevNumInputEdges << endl;
    
    os << indent << "ProjAxis: " << this->ProjAxis << endl;
    os << indent << "SortAxis: " << this->SortAxis << endl;
    os << indent << "YAxis: " << this->YAxis << endl;
    os << indent << "Orient: " << this->Orient << endl;

}
