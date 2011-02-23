/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageDijkstra.h,v $
  Date:      $Date: 2006/02/27 19:21:49 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/

// .NAME vtkImageDijkstra - Run Dijkstra's algorithm where nodes are points
//  and edge values are scalars
// .SECTION Description
// vtkImageDijkstra - 


#ifndef __vtkImageDijkstra_h
#define __vtkImageDijkstra_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkIntArray;
class vtkDataArray;
class vtkPriorityQueue;
class vtkIdList;
class VTK_SLICER_BASE_EXPORT vtkImageDijkstra : public vtkImageToImageFilter
{
  public:
  static vtkImageDijkstra *New();
  vtkTypeMacro(vtkImageDijkstra,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description
  // the source point
  vtkSetMacro(SourceID,int);
  vtkGetMacro(SourceID,int);

  // Description
  // the sink point
  vtkSetMacro(SinkID,int);
  vtkGetMacro(SinkID,int);

  vtkGetObjectMacro(Parent,vtkIntArray);

  
  // Description
  // the boundary scalars
  virtual void SetBoundaryScalars(vtkDataArray*);
  vtkGetObjectMacro(BoundaryScalars,vtkDataArray);

  // Description
  // the number of points of the input
  vtkSetMacro(NumberOfInputPoints,int);
  vtkGetMacro(NumberOfInputPoints,int);
  
  // Description
  // the number of nodes in the graph
  vtkSetMacro(NumberOfGraphNodes,int);
  vtkGetMacro(NumberOfGraphNodes,int);
  
  // Description:
  // The point ids (of the input image) on the shortest path
  vtkGetObjectMacro(ShortestPathIdList, vtkIdList);
  
  // Description:
  // Get the summed weight for all vertices
  //vtkGetObjectMacro(CumulativeWeightFromSource, vtkFloatArray);
   
  // Description:
  vtkSetMacro(UseInverseDistance,int);
  vtkGetMacro(UseInverseDistance,int);
  
  // Description:
  vtkSetMacro(UseInverseSquaredDistance,int);
  vtkGetMacro(UseInverseSquaredDistance,int);

  // Description:
  vtkSetMacro(UseInverseExponentialDistance,int);
  vtkGetMacro(UseInverseExponentialDistance,int);

  // Description:
  vtkSetMacro(UseSquaredDistance,int);
  vtkGetMacro(UseSquaredDistance,int);

      
  // Description:
  unsigned long GetMTime();
  
  // path operations
  void InitTraversePath();
  int GetNextPathNode();
  int GetNumberOfPathNodes();
  

  void init(vtkImageData *inData);
  
  // GRAPH
  
  // build a graph description of the image where nodes are points with
  // a non-zero value
  void CreateGraph(vtkImageData *inData);
  void DeleteGraph();
  void FindNeighbors(vtkIdList *list,int id, vtkDataArray *scalars); 
  // given the id of a point in the image, return the id of the closest point 
  // that belongs to the graph if the original point does not
  int findClosestPointInGraph(vtkDataArray *scalars,int id,int dim0,int dim1, int dim2); 
  

  // ALGO
  
  void InitSingleSource(int startv);
  // Calculate shortest path from vertex startv to vertex endv
  void RunDijkstra(vtkDataArray *scalars,int source, int sink);
  // Relax edge u,v with weight w
  //void Relax(int u, int v, float w);
  // edge cost
  float EdgeCost(vtkDataArray *scalars, int u, int v);
  void BuildShortestPath(int start,int end);
  
  // HEAP

  // structure the heap
  //void Heapify(int i);
  // insert vertex v in heap. Weight is in d(v)
  //void HeapInsert(int v);
  // extract vertex with min d(v)
  //int HeapExtractMin();
  // Update heap when key d(v) has been decreased
  //void HeapDecreaseKey(int v);
        
  
  // VARIABLES
  
  // The vertex at the start of the shortest path
  int SourceID;
  
  // The vertex at the end of the shortest path
  int SinkID;  
  
  // boundary scalars
  vtkDataArray *BoundaryScalars;

  // the number of points if the graph
  int NumberOfInputPoints;
  int NumberOfGraphNodes;

  int UseInverseDistance;
  int UseInverseSquaredDistance;
  int UseInverseExponentialDistance;
  int UseSquaredDistance;

  // list of all the graph nodes
  //vtkIntArray *GraphNodes;
  // Adjacency representation
  //vtkIdList **Neighbors;

  // the pq
  vtkPriorityQueue *PQ;

  // The vertex ids on the shortest path
  vtkIdList *ShortestPathIdList;
  // ShortestPathWeight current summed weight for path to vertex v
  //vtkFloatArray *CumulativeWeightFromSource;
  // pre(v) predecessor of v
  vtkIntArray *Parent;
  // Visited is the set of vertices with allready determined shortest path
  // Visited(v) == 1 means that vertex v is in s
  vtkIntArray *Visited;  
  // f is the set of vertices wich has not a shortest path yet but has a path
  // ie. the front set (f(v) == 1 means that vertex v is in f)
  //vtkIntArray *f;
  // the priority queue (a binary heap) with vertex indices
  //vtkIntArray *Heap;
  // p(v) the position of v in H (p and H are kindoff inverses)
  //vtkIntArray *p;  
  // The real number of elements in Heap != Heap.size()
  //int Heapsize;
 
  int PathPointer;
  //vtkImageData* CachedImage;
  int StopWhenEndReached;

protected:
  vtkImageDijkstra();
  ~vtkImageDijkstra();

  //void Execute(vtkImageData *inData, vtkImageData *outData);
  void ExecuteData(vtkDataObject *);
  void Execute() { this->Superclass::Execute(); };
  void Execute(vtkImageData *outData) { this->Superclass::Execute(outData); };

private:
  vtkImageDijkstra(const vtkImageDijkstra&);
  void operator=(const vtkImageDijkstra&);
};

#endif





