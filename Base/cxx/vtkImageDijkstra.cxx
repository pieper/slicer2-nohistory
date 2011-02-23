/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageDijkstra.cxx,v $
  Date:      $Date: 2006/02/27 19:21:49 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
#include "vtkImageDijkstra.h"

#include "vtkObjectFactory.h"
#include "vtkIntArray.h"
#include "vtkPointData.h"
#include "vtkPriorityQueue.h"
#include "vtkIdList.h"
#include "vtkImageData.h"
#include "vtkFloatArray.h"

#include <math.h>
#include <stdlib.h>

vtkCxxSetObjectMacro(vtkImageDijkstra,BoundaryScalars,vtkDataArray);

//----------------------------------------------------------------------------
vtkImageDijkstra* vtkImageDijkstra::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageDijkstra");
  if(ret)
    {
    return (vtkImageDijkstra*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageDijkstra;
}





//----------------------------------------------------------------------------
// Constructor sets default values
vtkImageDijkstra::vtkImageDijkstra()
{
  //printf("initialize");
  this->SourceID = 0;
  this->SinkID = 0;
  this->NumberOfInputPoints = 0;
  this->PathPointer = -1;
  this->StopWhenEndReached = 1;
 
  this->ShortestPathIdList = NULL;
  this->Parent        = NULL;
  this->Visited          = NULL;
  this->PQ = NULL;
  this->BoundaryScalars = NULL;

  this->UseInverseDistance = 0;
  this->UseInverseSquaredDistance = 0;
  this->UseInverseExponentialDistance = 1;
  this->UseSquaredDistance = 0;

  //this->Neighbors = NULL;
  //this->CumulativeWeightFromSource          = NULL;
  //this->Heap          = NULL;
  //this->p          = NULL;
  //this->Heapsize  = 0;
}


//------------------------------------------------------------------------------
vtkImageDijkstra::~vtkImageDijkstra()
{

  //printf("in delete");
  if (this->ShortestPathIdList)
    this->ShortestPathIdList->Delete();
  if (this->Parent)
    this->Parent->Delete();
  if(this->BoundaryScalars) 
    this->BoundaryScalars->Delete();
  //if (this->Visited)
  // this->Visited->Delete();
  //if (this->PQ)
  // this->PQ->Delete();
  //if (this->Heap)
  //this->Heap->Delete();
  //if (this->p)
  //this->p->Delete();
  //if(this->BoundaryScalars)
  //this->BoundaryScalars->Delete();
  //DeleteGraph();
  //if (this->CumulativeWeightFromSource)
  //this->CumulativeWeightFromSource->Delete();
  
}

//------------------------------------------------------------------------------
unsigned long vtkImageDijkstra::GetMTime()
{
  unsigned long mTime=this->MTime.GetMTime();
  
  return mTime;
}


//------------------------------------------------------------------------------
void vtkImageDijkstra::init(vtkImageData *inData)
{


  if (this->ShortestPathIdList)
    this->ShortestPathIdList->Delete();
  
  if (this->Parent)
    this->Parent->Delete();
  if (this->Visited)
    this->Visited->Delete();
  if (this->PQ)
  this->PQ->Delete();
  //if (this->Heap)
  //this->Heap->Delete();
  //if (this->p)
  //this->p->Delete();
  //if (this->CumulativeWeightFromSource)
  //this->CumulativeWeightFromSource->Delete();

  this->ShortestPathIdList = vtkIdList::New();
  //this->CumulativeWeightFromSource          = vtkFloatArray::New();
  this->Parent        = vtkIntArray::New();
  this->Visited          = vtkIntArray::New();
  this->PQ = vtkPriorityQueue::New();
  //this->Heap          =  vtkPriorityQueue::New();
  //this->p          = vtkIntArray::New();
  //this->Heapsize  = 0;
  
  //printf("************* before create graph *************");
  CreateGraph(inData);     
  //printf("************* after create graph *************");

  int numPoints = inData->GetNumberOfPoints();

  this->Parent->SetNumberOfComponents(1);
  this->Parent->SetNumberOfTuples(numPoints);
  this->Visited->SetNumberOfComponents(1);
  this->Visited->SetNumberOfTuples(numPoints);
  
  //this->Neighbors = new vtkIdList*[numPoints];
  /*
    this->CumulativeWeightFromSource->SetNumberOfComponents(1);
    this->CumulativeWeightFromSource->SetNumberOfTuples(numPoints);
  */    
    
  //this->p->SetNumberOfComponents(1);
  //this->p->SetNumberOfTuples(numPoints);
  // The heap has elements from 1 to n
  //this->Heap->SetNumberOfComponents(1);
  //this->Heap->SetNumberOfTuples(numPoints+1);
  //Heapsize = 0;
}

void vtkImageDijkstra::DeleteGraph()
{
  
  /*const int npoints = this->GetNumberOfInputPoints();
  
    if (this->Neighbors)
    {
    for (int i = 0; i < npoints; i++)
    {
    if(this->Neighbors[i])
    this->Neighbors[i]->Delete();
    }
    delete [] this->Neighbors;
    }
    this->Neighbors = NULL;
  */
}

//------------------------------------------------------------------------------
void vtkImageDijkstra::CreateGraph(vtkImageData *inData) {

  
  //DeleteGraph();
  //delete old arrays in case we are re-executing this filter
  int numPoints = inData->GetNumberOfPoints(); 
  this->SetNumberOfInputPoints(numPoints);
  
  // initialization
  int *dim = inData->GetDimensions();
  vtkDataArray *scalars = inData->GetPointData()->GetScalars();
  vtkIdList *graphNodes = vtkIdList::New();
  
  //this->Neighbors = new vtkIdList*[numPoints];
  //for (int i = 0; i < numPoints; i++)
  //{
  //  this->Neighbors[i] = vtkIdList::New();
  //}
  int graphSize = 0;
  // create the graph
  for(int k = 0; k <dim[2]; k++) {
    this->UpdateProgress ((float) k / (2 * ((float) dim[2] - 1)));
    for(int j = 0; j <dim[1]; j++) {
      for(int i = 0; i <dim[0]; i++) {
    
    int id = k*(dim[1]*dim[0]) + j*dim[0] + i;
    float maskValue = scalars->GetTuple1(id);
    // only add neighbor if it is in the graph
    
    if(maskValue > 0) {    
      // add to graph
      graphNodes->InsertNextId(id);
      graphSize++;
    }
      }
    }
  }

  this->SetNumberOfGraphNodes(graphSize);
  //printf("graph size %i \n ",graphSize);
  
  // fill the PQ
  PQ->Allocate(graphSize);
  for(int i=0; i<graphSize;i++) {
    PQ->Insert(VTK_LARGE_FLOAT,graphNodes->GetId(i));
  }
  // free some memory
  graphNodes->Delete();
  
}


//------------------------------------------------------------------------------
void vtkImageDijkstra::RunDijkstra(vtkDataArray *scalars,int startv, int endv)
{
  
  int i, u, v;
  
  //printf("variables are : linear %i, squared %i, exponential %i",this->UseInverseDistance,this->UseInverseSquaredDistance,this->UseInverseExponentialDistance);
  InitSingleSource(startv);
  
  //HeapInsert(startv);
  
  this->Visited->SetValue(startv, 1);

  int initialSize = PQ->GetNumberOfItems();
  int size = initialSize;
  int stop = 0;

  while ((PQ->GetNumberOfItems() > 0) && !stop)
    {

      this->UpdateProgress (0.5 + (float) (initialSize - size) / ((float) 2 * initialSize));
      
      if(PQ->GetNumberOfItems() != size) {
    //printf("*************** PROBLEM IN PQ SIZE ******************");
      }
      //printf("visiting node %i \n",u);
      // u is now in s since the shortest path to u is determined
      // remove from the front set >1
      vtkFloatingPointType u_weight;
#if (VTK_MAJOR_VERSION == 4 && VTK_MINOR_VERSION == 0)      
      u = PQ->Pop(u_weight,0);
#else
      u = PQ->Pop(0, u_weight);
#endif
      //printf("looking at id %i that has priority %f",u,u_weight);
     
      this->Visited->SetValue(u, 1);
      
      if (u == endv && StopWhenEndReached)
    stop = 1;
      
      // Update all vertices v neighbors to u
      // find the neighbors of u
      vtkIdList *list = vtkIdList::New();
      this->FindNeighbors(list,u,scalars);
      
      //printf("the list has %i ids",list->GetNumberOfIds());
      for (i = 0; i < list->GetNumberOfIds(); i++) {
    
    v = list->GetId(i);
    
    // s is the set of vertices with determined shortest path...do not 
    // use them again
    if (this->Visited->GetValue(v) != 1)
      {
        // Only relax edges where the end is not in s and edge 
        // is in the front set
        float w = EdgeCost(scalars, u, v);
        float v_weight = this->PQ->GetPriority(v);
        //if(v == endv) 
        //printf("we have found endv %i, its weight is %f, neighbor is %i , weight is %f, edge weight is %f",v,v_weight,u,u_weight,w);
        
        // Relax step
        if (v_weight > (u_weight + w))
          {
        this->PQ->DeleteId(v);
        this->PQ->Insert((u_weight + w),v);
        this->Parent->SetValue(v, u);
        //printf("setting parent of %i to be %i",v,u);
          }
      }
      }
      
      // now delete the array
      list->Delete();
      size--;
      }
  this->PQ->Delete();
  this->Visited->Delete();
}

//----------------------------------------------------------------------------
void vtkImageDijkstra::InitSingleSource(int startv)
{
  for (int v = 0; v < this->GetNumberOfInputPoints(); v++)
    {
      // d will be updated with first visit of vertex
      //this->CumulativeWeightFromSource->SetValue(v, -1);
      this->Parent->SetValue(v, -1);
      this->Visited->SetValue(v, 0);
    }
  PQ->DeleteId(startv);
  // re-insert the source with priority 0
  PQ->Insert(0,startv);
  //printf("priority of startv %f",PQ->GetPriority(startv));
  //this->CumulativeWeightFromSource->SetValue(startv, 0);
}


//----------------------------------------------------------------------------
void vtkImageDijkstra::FindNeighbors(vtkIdList *list,int id, vtkDataArray *scalars) {
  
  // find i, j, k for that node
  vtkImageData *input = this->GetInput();

  int *dim = input->GetDimensions();
  int numPts = dim[0] * dim[1] * dim[2];
  
  
  for(int vk = -1; vk<2; vk++) {
    for(int vj = -1; vj<2; vj++) {
      for(int vi = -1; vi<2; vi++) {         
    
    int tmpID = id + (vk * dim[1]*dim[0]) + (vj * dim[0]) + vi;
    // check we are in bounds (for volume faces)     
    if( tmpID >= 0 && tmpID < numPts && tmpID != 0) {
      float mask = scalars->GetTuple1(tmpID);
      // only add neighbor if it is in the graph
      if(mask > 0) {        
        list->InsertUniqueId(tmpID);
      }
    }
      }
    }
  }
}


//----------------------------------------------------------------------------
// The edge cost function should be implemented as a callback function to
// allow more advanced weighting
float vtkImageDijkstra::EdgeCost(vtkDataArray *scalars, int u, int v)
{
  
  float w;
  // if it is a boundary voxel, give it a very high edge value to 
  // keep the path from going through it
  if(this->BoundaryScalars->GetTuple1(v) == 1) {
    w = 10000;
  } else {
    float dist2 = scalars->GetTuple1(v) ;
    float dist = sqrt(scalars->GetTuple1(v));
    if(this->UseInverseDistance)
      w = (1.0/dist);
    else if(this->UseInverseSquaredDistance)
      w = (1.0/(dist*dist));
    else if(this->UseInverseExponentialDistance)
      w = (1.0/exp(dist));
    else if(this->UseSquaredDistance)
      w = dist2;
  }
  return w;
}

//----------------------------------------------------------------------------
void vtkImageDijkstra::BuildShortestPath(int start,int end)
{
  
  int v = end;
  while (v != start && v > 0)
    {
      this->ShortestPathIdList->InsertNextId(v);
      v = this->Parent->GetValue(v);
    }
  this->ShortestPathIdList->InsertNextId(v);
  
}

//----------------------------------------------------------------------------
// ITERATOR PART 

void vtkImageDijkstra::InitTraversePath(){
  this->PathPointer = -1;
}

//----------------------------------------------------------------------------
int vtkImageDijkstra::GetNumberOfPathNodes(){
  return this->ShortestPathIdList->GetNumberOfIds();
}

//----------------------------------------------------------------------------
int vtkImageDijkstra::GetNextPathNode(){
  this->PathPointer = this->PathPointer + 1;
  
  if(this->PathPointer < this->GetNumberOfPathNodes()) {
    //printf("this->GetPathNode(this->PathPointer) %i",this->GetPathNode(this->PathPointer));
    return this->ShortestPathIdList->GetId(this->PathPointer);
  } else {
    return -1;
  }
}

//----------------------------------------------------------------------------
// find closest scalar to id that is non-zero
int vtkImageDijkstra::findClosestPointInGraph(vtkDataArray *scalars,int id,int dim0,int dim1, int dim2) {

  
  int kFactor = dim0 * dim1;
  int jFactor = dim0;
  
  int numPoints = kFactor * dim2;
  vtkIdList* Q = vtkIdList::New();
  Q->InsertNextId(id);
  
  int pointer = 0;
  int foundID = -1;
  
  while(Q->GetNumberOfIds() != 0) {
    
    int current = Q->GetId(pointer);
    pointer = pointer + 1;
    //printf("we are looking at id %i \n",current);
    
    // check to see if we found something in the graph
    if(scalars->GetTuple1(current) >0) {
      //printf("before return");
      return current;
    } else {
      // set it to -1 to show that we already looked at it
      scalars->SetTuple1(current,-1);
      // put the neighbors on the stack
      // top
      if (current + kFactor <numPoints) {
    if(scalars->GetTuple1(current + kFactor) != -1){
      //printf("expand k+1 %i",current + kFactor);
      Q->InsertNextId(current+kFactor);
    }
      }
      // bottom
      if (current - kFactor >= 0){
    if(scalars->GetTuple1(current - kFactor) != -1){
      //printf("expand k-1 %i", current - kFactor);
      Q->InsertNextId(current-kFactor);
    }
      }
      // front
      if (current + jFactor < numPoints) {
    if(scalars->GetTuple1(current + jFactor) != -1){
      //printf("expand j+1 %i",current + jFactor);
      Q->InsertNextId(current + jFactor);
    }
      }
      // back
      if (current - jFactor >= 0) {
    if(scalars->GetTuple1(current - jFactor) != -1){
      //printf("expand j-1 %i",current - jFactor);
      Q->InsertNextId(current - jFactor);    
    }
      }
      // left
      if (current+1 <numPoints){
    if(scalars->GetTuple1(current + 1) != -1){
      //printf("expand i+1 %i",current+1);
      Q->InsertNextId(current + 1);    
    }
      }
      // right
      if (current -1 >= 0) {
    if(scalars->GetTuple1(current - 1) != -1){
      //printf("expand i-1 %i",current - 1);
      Q->InsertNextId(current - 1);    
    }
      }
    }
  }
  Q->Delete();
  return foundID;
}




//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
template <class T>
static void vtkImageDijkstraExecute(vtkImageDijkstra *self,
                   vtkImageData *inData, T *inPtr,
                   vtkImageData *outData, int *outPtr)
{

  //printf("*************** VTKIMAGEDIJKSTRA Execute **************");
  self->init(inData);
  //printf("*************** after init ****************");
  
  int *dim = inData->GetDimensions();
  vtkDataArray *scalars = inData->GetPointData()->GetScalars();
  
   // find closest point in graph to source and sink if their value is not 0
  //printf("source ID %i value is %f",self->GetSourceID(),scalars->GetScalar(self->GetSourceID()));
  if(scalars->GetTuple1(self->GetSourceID()) == 0) {
    
    vtkFloatArray *copyScalars = vtkFloatArray::New();
    copyScalars->DeepCopy(inData->GetPointData()->GetScalars());
    
    self->SetSourceID(self->findClosestPointInGraph(copyScalars,self->GetSourceID(),dim[0],dim[1],dim[2]));
    
    copyScalars->Delete();
    //printf("NEW source ID %i value is %f",self->GetSourceID(),scalars->GetScalar(self->GetSourceID()));

  }

  //printf("sink ID %i value is %f",self->GetSinkID(),scalars->GetScalar(self->GetSinkID()));
  if(scalars->GetTuple1(self->GetSinkID()) == 0) {
    vtkFloatArray *copyScalars2 = vtkFloatArray::New();
    copyScalars2->DeepCopy(inData->GetPointData()->GetScalars());
    self->SetSinkID(self->findClosestPointInGraph(copyScalars2,self->GetSinkID(),dim[0],dim[1],dim[2]));
    copyScalars2->Delete();
    
    //printf("NEW sink ID %i value is %f",self->GetSinkID(),scalars->GetScalar(self->GetSinkID()));
  }
      
  //printf("************* before run dijkstra ");
  self->RunDijkstra(scalars,self->GetSourceID(),self->GetSinkID());
  //printf("************* before build shortest path");
  self->BuildShortestPath(self->GetSourceID(),self->GetSinkID());
  //printf("************** DONE ***************");
}


//----------------------------------------------------------------------------
// This method is passed a input and output Data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the Datas data types.
// -- sp 2002-09-05 updated for vtk4
void vtkImageDijkstra::ExecuteData(vtkDataObject *)
{
  void *inPtr;
  void *outPtr;
  
  vtkImageData *inData = this->GetInput();
  vtkImageData *outData = this->GetOutput();
  outData->SetExtent(outData->GetWholeExtent());
  outData->AllocateScalars();

  int inExt[6], outExt[6];

  outData->GetExtent(outExt);
  this->ComputeInputUpdateExtent(inExt, outExt);
  inPtr = inData->GetScalarPointerForExtent(inExt);
  outPtr = outData->GetScalarPointerForExtent(outExt);
  

  // Components turned into x, y and z
  if (inData->GetNumberOfScalarComponents() > 3)
    {
    vtkErrorMacro("This filter can handle upto 3 components");
    return;
    }
  
  
  switch (inData->GetScalarType())
    {
    vtkTemplateMacro5(vtkImageDijkstraExecute, this, 
                      inData, (VTK_TT *)(inPtr), 
                      outData, (int *)(outPtr));
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}


//----------------------------------------------------------------------------
void vtkImageDijkstra::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);

  os << indent << "Source ID: ( "
     << this->GetSourceID() << " )\n";

  os << indent << "Sink ID: ( "
     << this->GetSinkID() << " )\n";
}


/*
void vtkImageDijkstra::Heapify(int i)
{
        // left node
        int l = i * 2;
        
        // right node
        int r = i * 2 + 1;
        
        int smallest = -1;
        
        // The value of element v is d(v)
        // the heap stores the vertex numbers
        if (l <= Heapsize && this->CumulativeWeightFromSource->GetValue(this->Heap->GetValue(l)) < this->CumulativeWeightFromSource->GetValue(this->Heap->GetValue(i)))
                smallest = l;
        else
                smallest = i;
        
        if (r <= Heapsize && this->CumulativeWeightFromSource->GetValue(this->Heap->GetValue(r))< this->CumulativeWeightFromSource->GetValue(this->Heap->GetValue(smallest)))
                smallest = r;
        
        if (smallest != i)
        {
                int t = this->Heap->GetValue(i);
                
                this->Heap->SetValue(i, this->Heap->GetValue(smallest));
                
                // where is H(i)
                this->p->SetValue(this->Heap->GetValue(i), i);
                
                // H and p is kinda inverse
                this->Heap->SetValue(smallest, t);
                this->p->SetValue(t, smallest);
                
                Heapify(smallest);
        }
}

// Insert vertex v. Weight is given in d(v)
// H has indices 1..n
void vtkImageDijkstra::HeapInsert(int v)
{
        if (Heapsize >= this->Heap->GetNumberOfTuples()-1)
                return;
        
        Heapsize++;
        int i = Heapsize;
        
        while (i > 1 && this->CumulativeWeightFromSource->GetValue(this->Heap->GetValue(i/2)) > this->CumulativeWeightFromSource->GetValue(v))
        {
                this->Heap->SetValue(i, this->Heap->GetValue(i/2));
                this->p->SetValue(this->Heap->GetValue(i), i);
                i /= 2;
        }
        // H and p is kinda inverse
        this->Heap->SetValue(i, v);
        this->p->SetValue(v, i);
}

int vtkImageDijkstra::HeapExtractMin()
{
        if (Heapsize == 0)
                return -1;
        
        int minv = this->Heap->GetValue(1);
        this->p->SetValue(minv, -1);
        
        this->Heap->SetValue(1, this->Heap->GetValue(Heapsize));
        this->p->SetValue(this->Heap->GetValue(1), 1);
        
        Heapsize--;
        Heapify(1);
        
        return minv;
}

void vtkImageDijkstra::HeapDecreaseKey(int v)
{
        // where in H is vertex v
        int i = this->p->GetValue(v);
        if (i < 1 || i > Heapsize)
                return;
        
        while (i > 1 && this->CumulativeWeightFromSource->GetValue(this->Heap->GetValue(i/2)) > this->CumulativeWeightFromSource->GetValue(v))
        {
                this->Heap->SetValue(i, this->Heap->GetValue(i/2));
                this->p->SetValue(this->Heap->GetValue(i), i);
                i /= 2;
        }
        
        // H and p is kinda inverse
        this->Heap->SetValue(i, v);
        this->p->SetValue(v, i);
}



*/
