/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWire.h,v $
  Date:      $Date: 2006/02/22 23:47:16 $
  Version:   $Revision: 1.33 $

=========================================================================auto=*/

// .NAME vtkImageLiveWire - Displays a live wire segmentation contour
// .SECTION Description
// Finds the shortest path between user-defined points where
// the distance metric is based on image information.
// Ths input images to this class (UpEdges, etc.) are treated as
// directional edges in a weighted graph, and Dijkstra's algorithm
// is applied to find the shortest path in this graph.
// Currently the output path is displayed on a clear image, but
// it could be overlayed easily on grayscale using the first input
// to the filter, the OriginalImage.
// The output points on the contour can be accessed using 
// this->GetContourPixels.
//
#ifndef __vtkImageLiveWire_h
#define __vtkImageLiveWire_h

#include "vtkImageData.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkSlicer.h"
#include "vtkPoints.h"

//----------------------------------------------------------------------------
// helper classes used in computation
//----------------------------------------------------------------------------

// avoid tcl wrapping ("begin Tcl exclude")
//BTX

//----------------------------------------------------------------------------
// Doubly linked list element.
class listElement {
 public:
  listElement *Prev; 
  listElement *Next; 
  int Coord[2];
  listElement() {this->Prev=NULL; this->Next=NULL;}; 
};

//----------------------------------------------------------------------------
// 2D array.
template <class T>
class array2D {
 public:
  array2D(int x, int y);
  array2D(int x, int y, T initVal);
  ~array2D(){if (this->array) delete[] this->array;};

  // Get/Set functions 
  T GetElement(int x,int y) {return this->array[x + y*this->Cols];};
  void SetElement(int x,int y, T value) {this->array[x + y*this->Cols] = value;};
  // return the array element itself
  T& operator() (int x, int y){return this->array[x + y*this->Cols];};
  // return a pointer to the array element
  T *Element(int x,int y) {return (this->array + x + y*this->Cols);};

 private:
  T *array;
  int Rows, Cols; 
};


//----------------------------------------------------------------------------
// 2D array of list elements
class linkedList : public array2D<listElement>{
 public:
  linkedList(int x, int y);
};
  

//----------------------------------------------------------------------------
// Circular queue.
// This is a *really* circular queue.  Circle points to the heads
// of the linked lists in A.  Vertices are put in a "bucket"
// in Circle, where cost to vertex mod buckets in Circle (-1) defines
// the bucket.  The number of buckets is the max edge cost plus one.
// This way the buckets will always hold vertices with the same 
// cumulative path cost.
//
// Each linked list starts at a bucket and winds its way through A.
// New vertices are inserted at the top (by the bucket).
//
// To extract vertices for examination, it is best to use older
// ones (so it is more like a breadth first search than a depth first one)
// so the last vertex in A is linked back to the bucket.  
// This gives another circle (or a FIFO queue).
// 
// See IEEE Trans Med Img Jan 2000, Live Wire on the Fly for more.
//
class circularQueue {
 public:  
  circularQueue(int x, int y, int buckets);  
  ~circularQueue();

  void Insert(int x, int y, int cost);
  void Remove(int *coord);
  void Remove(int x, int y);
  void Remove(listElement *el);
  listElement *GetListElement(int cost);
  void VerboseOn();

 private:
  int GetBucket(int cost);
  int FindMinBucket(int cost);

  linkedList *A;
  listElement *Circle;
  int C;
  int Verbose;
};

//----------------------------------------------------------------------------
// end of helper classes used in computation
//----------------------------------------------------------------------------

// start Tcl wrapping again (cryptic acronym for End Tcl Exclude)
//ETX


class VTK_SLICER_BASE_EXPORT vtkImageLiveWire : public vtkImageMultipleInputFilter
{
public:
  static vtkImageLiveWire *New();
  vtkTypeMacro(vtkImageLiveWire,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Label value of output contour
  vtkSetMacro(Label, int);
  vtkGetMacro(Label, int);

  // Description:
  // Label value of clicks on output contour
  vtkSetMacro(ClickLabel, int);
  vtkGetMacro(ClickLabel, int);

  // Description:
  // Starting point of shortest path (mouse click #1)
  void SetStartPoint(int x, int y);
  void SetStartPoint(int *point){this->SetStartPoint(point[0],point[1]);};
  vtkGetVector2Macro(StartPoint, int);

  // Description:
  // Ending point of shortest path (mouse click #2)
  void SetEndPoint(int x, int y);
  void SetEndPoint(int *point){this->SetEndPoint(point[0],point[1]);};
  vtkGetVector2Macro(EndPoint, int);

  // Description:
  // Must be either 4 or 8.  Connectedness of the path that is found.
  vtkSetMacro(NumberOfNeighbors, int);
  vtkGetMacro(NumberOfNeighbors, int);  
  
  // Description:
  // Max cost of any single pixel edge; also size of circular queue
  vtkSetMacro(MaxEdgeCost, int);
  vtkGetMacro(MaxEdgeCost, int);

  // Description:
  // For testing.  
  vtkSetMacro(Verbose, int);
  vtkGetMacro(Verbose, int);

  // Description:
  // Original grayscale image the weighted graph edges were created 
  // from.  Could easily be used to output the path over the original
  // image, though this is currently not implemented.
  void SetOriginalImage(vtkImageData *image) {this->SetInput(0,image);}
  vtkImageData *GetOriginalImage() {return this->GetInput(0);}

  // Description:
  // edge costs (for traveling UP to the next pixel)
  void SetUpEdges(vtkImageData *image) {this->SetInput(1,image);}
  vtkImageData *GetUpEdges() {return this->GetInput(1);}

  // Description:
  // edge costs
  void SetDownEdges(vtkImageData *image) {this->SetInput(2,image);}
  vtkImageData *GetDownEdges() {return this->GetInput(2);}

  // Description:
  // edge costs
  void SetLeftEdges(vtkImageData *image) {this->SetInput(3,image);}
  vtkImageData *GetLeftEdges() {return this->GetInput(3);}

  // Description:
  // edge costs
  void SetRightEdges(vtkImageData *image) {this->SetInput(4,image);}
  vtkImageData *GetRightEdges() {return this->GetInput(4);}

  //--- If we are running with 8-connected paths ---
  // Description:
  // edge costs (for traveling UP to the next pixel)
  void SetUpLeftEdges(vtkImageData *image) {this->SetInput(5,image);}
  vtkImageData *GetUpLeftEdges() {return this->GetInput(5);}

  // Description:
  // edge costs (for traveling UP to the next pixel)
  void SetUpRightEdges(vtkImageData *image) {this->SetInput(6,image);}
  vtkImageData *GetUpRightEdges() {return this->GetInput(6);}

  // Description:
  // edge costs
  void SetDownLeftEdges(vtkImageData *image) {this->SetInput(7,image);}
  vtkImageData *GetDownLeftEdges() {return this->GetInput(7);}

  // Description:
  // edge costs
  void SetDownRightEdges(vtkImageData *image) {this->SetInput(8,image);}
  vtkImageData *GetDownRightEdges() {return this->GetInput(8);}

  //--- End if we are running with 8-connected paths ---

  // Description:
  // Edges on the chosen contour
  vtkGetObjectMacro(ContourEdges, vtkPoints);

  // Description:
  // Pixels on the chosen contour
  // The output image has these highlighted, plus any new pixels 
  vtkGetObjectMacro(ContourPixels, vtkPoints);

  // Description:
  // Edges on the new shortest path.
  vtkGetObjectMacro(NewEdges, vtkPoints);

  // Description:
  // Pixels on the new shortest path (moving wire at end of contour).
  // The output image also has these highlighted.
  vtkGetObjectMacro(NewPixels, vtkPoints);

  // Description:
  // Clears the saved contour points (to start again from a new StartPoint)
  void ClearContour();

  // Description:
  // Clears the moving "tail" of the wire.  Use to redo current path 
  // with new settings since it will clear cached shortest path information.
  void ClearContourTail();

  // Description:
  // Clears the points on the last chosen segment of the live wire
  // (the "tail" and also the points between the last two clicks)
  void ClearLastContourSegment();

  // Description:
  // For clearing the last livewire segment 
  // (for pretty screen shots without the "tail")
  vtkSetMacro(InvisibleLastSegment, int);
  vtkGetMacro(InvisibleLastSegment, int);
  
  // ---- Data structures for internal use in path computation -- //
  //BTX
  // Description:
  // Circular queue, composed of buckets that hold vertices of each path cost.
  // The vertices are stored in a doubly linked list for each bucket.
  circularQueue * GetQ() {return this->Q;};

  // Description:
  // CC is the cumulative cost from StartPoint to each pixel.
  array2D<int> * GetCC() {return this->CC;};

  // Description:
  // Dir is the direction the optimal path takes through each pixel.
  array2D<int> * GetDir() {return this->Dir;};

  // Description:
  // L is the list of edges ("bels") which have already been processed
  array2D<int> * GetL() {return this->L;};

  // Description:
  // The directions the path may take.
  // We either use the first 4 or all 8 of these.
  enum {UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT, NONE};

  // ---- End of data structures for internal use in path computation -- //

  // ---- Functions for internal use in path computation -- //

  // Description:
  // This is public since it is called from the non-class function 
  // vtkImageLiveWireExecute...  Don't call this.
  void AllocatePathInformation(int numRows, int numCols);

  // Description:
  // Cumulative cost of current path.
  // Don't set this; it's here for access from vtkImageLiveWireExecute
  vtkSetMacro(CurrentCC, int);
  vtkGetMacro(CurrentCC, int);

  // ---- End Functions for internal use in path computation -- //
  //ETX

protected:
  vtkImageLiveWire();
  ~vtkImageLiveWire();
  vtkImageLiveWire(const vtkImageLiveWire&);
  void operator=(const vtkImageLiveWire&);

  int StartPoint[2];
  int EndPoint[2];
  int PrevEndPoint[2];
  int CurrentCC;
  int MaxEdgeCost;
  int Verbose;
  int Label;
  int ClickLabel;
  int NumberOfNeighbors;
  int InvisibleLastSegment;

  vtkPoints *ContourEdges;
  vtkPoints *ContourPixels;
  vtkPoints *NewEdges;
  vtkPoints *NewPixels;

  //BTX
  circularQueue *Q;
  array2D<int> *CC;
  array2D<int> *Dir;
  array2D<int> *L;
  //ETX

  void DeallocatePathInformation();
  void ExecuteInformation(vtkImageData **inputs, vtkImageData *output); 
  void ComputeInputUpdateExtent(int inExt[6], int outExt[6],
                int whichInput);
  void ExecuteInformation(){this->vtkImageMultipleInputFilter::ExecuteInformation();};
  virtual void ExecuteData(vtkDataObject *);
};

#endif


