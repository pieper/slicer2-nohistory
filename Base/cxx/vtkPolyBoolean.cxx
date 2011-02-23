/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPolyBoolean.cxx,v $
  Date:      $Date: 2006/03/31 18:20:41 $
  Version:   $Revision: 1.21 $

=========================================================================auto=*/

#define kcyDebug(x) \
{ cout << x << endl; }

#include <math.h>
#include "vtkPolyBoolean.h"
#include "vtkLine.h"
#include "vtkTriangle.h"
#include "vtkTransform.h"
#include "vtkMath.h"
#include "vtkPolygon.h"
#include "vtkBoolTess.h"

// Description:

vtkPolyBoolean::vtkPolyBoolean()
{
  this->PolyDataB = NULL;
  this->Operation = BOOL_A_MINUS_B;
  this->OBBTreeA = NULL;
  this->OBBTreeB = NULL;
  this->BPoints = NULL;
  this->XformA = NULL;
  this->XformB = NULL;
  this->IntersectionCount = 0;
  this->TestCount = 69;
  this->TriangleCount = 0;
  this->NodeCount = 0;
  this->TriDirectory[0] = this->TriDirectory[1] = NULL;
  this->CellFlags[0] = this->CellFlags[1] = NULL;
  this->CellFlagsB = NULL;
  this->ExecutionCount = 0;
  this->AngleResolution = 0.003;
  this->DistanceResolution = 1.0E-7;
  this->NewPoints = NULL;
  this->NewPolys = NULL;
  this->NewLines = NULL;
  this->NewVerts = NULL;
  this->ThisLoop = NULL;
  this->Tess = new vtkBoolTess;
  this->TriDirectorySize[0] = this->TriDirectorySize[1] = 0;
}

vtkPolyBoolean::~vtkPolyBoolean()
{
  int AorB;

  if ( this->OBBTreeA ) this->OBBTreeA->Delete();
  this->OBBTreeA = NULL;
  if ( this->OBBTreeB ) this->OBBTreeB->Delete();
  this->OBBTreeB = NULL;
  if ( this->XformA ) this->XformA->Delete();
  if ( this->XformB ) this->XformB->Delete();
  if ( this->BPoints ) this->BPoints->Delete();

  for ( AorB=0; AorB<2; AorB++ )
    {
    if ( this->TriDirectory[AorB] )
      {
      this->DeleteTriDirectory( AorB );
      }
    }
  delete [] this->CellFlagsB;
  //if ( this->PolyDataB ) this->PolyDataB->Delete();
  if ( this->ThisLoop ) this->ThisLoop->Delete();
  delete this->Tess;
}

void vtkPolyBoolean::SetOperation( int operation )
{
  if ( (this->Operation == BOOL_A_MINUS_B) !=
       (operation == BOOL_A_MINUS_B) )
    this->DeleteTriDirectory( 1 );
  this->Operation = operation;
  this->Modified();
}


// sets this->TestCount to be the number of intersecting triangles
// between Model A and Model B
// This is found by determining the number of interesecting bounding
// boxes surrounding each cell (?)
void vtkPolyBoolean::SPLTestIntersection() {
  cout << "Declaring Input A Data Input" << endl;
  vtkPolyData *inputA = (vtkPolyData *)this->Inputs[0];
  cout << "0" << endl;
  vtkPolyData *inputB = this->PolyDataB;
  cout << "1" << endl;
  vtkPolyData *output = this->GetOutput();
  cout << "2" << endl;
  vtkPointData *outputPD = output->GetPointData();
  cout << "3" << endl;
  vtkPointData *pdA = inputA->GetPointData(),
               *pdB = inputB->GetPointData();
  cout << "4" << endl;
  vtkCellData *outputCD = output->GetCellData();
  cout << "5" << endl;

  cout << "Declaring Xform Data Input" << endl;
  vtkMatrix4x4 *XformBtoA = vtkMatrix4x4::New();
  vtkMatrix4x4 *XformAInverse = vtkMatrix4x4::New();
  // make dummy transform because of but that Multiply4x4 isn't static fcn
  vtkTransform *dummyxform = vtkTransform::New();

  cout << "Declaring Xform Num Data Input" << endl;
  int numInputPointsA;

  vtkDebugMacro(<< "Performing polyhedron boolean.");
  cout << "Initializing Data" << endl;
  this->ExecutionCount++;
  this->IntersectionCount = 0;
  this->TriangleCount = 0;
  this->NodeCount = 0;

  cout << "NumPoints in A set" << endl;
  this->TestCount = -90;
  numInputPointsA = inputA->GetNumberOfPoints();



  cout << "Testing C++ cout" << endl;
}


void vtkPolyBoolean::DeleteTriDirectory( int AorB )
{
  vtkPolyData *dataset;
  int ii, num;
  vtkBoolTri *thisTri, *nextTri;

  if ( this->TriDirectory[AorB] )
    {
    dataset = ( AorB == 0 ? this->GetInput() : this->PolyDataB );
    num = this->TriDirectorySize[AorB];
    for ( ii=0; ii<num; ii++ )
      {
      thisTri = this->TriDirectory[AorB][ii];
      while( thisTri != NULL )
        {
        nextTri = thisTri->Next;
        delete this->TriDirectory[AorB][ii];
        thisTri = nextTri;
        }
      }
    delete [] this->TriDirectory[AorB];
    this->TriDirectory[AorB] = NULL;
    delete [] this->CellFlags[AorB];
    this->CellFlags[AorB] = NULL;
    this->TriDirectorySize[AorB] = 0;
    }
  if ( AorB == 0 && this->OBBTreeA != NULL )
    {
    this->OBBTreeA->Delete();
    this->OBBTreeA = NULL;
    }
  if ( AorB == 1 && this->OBBTreeB != NULL )
    {
    this->OBBTreeB->Delete();
    this->OBBTreeB = NULL;
    }
}


/*
  void vtkPolyBoolean::SetInput2( vtkPolyData *input )
  {
  this->DeleteTriDirectory(0);
  cout << " setting Input to " << (void *)input << endl;
  this->Inputs;
  this->Inputs[0] = input;
  this->Inputs[0]->Register(this);
  
  }
*/

void vtkPolyBoolean::SetPolyDataB( vtkPolyData *polyDataB )
{
  if ( this->PolyDataB != polyDataB )
    {
    this->DeleteTriDirectory( 1 );
    //    vtkDebugMacro(<<" setting PolyDataB to " << (void *)polyDataB);
    // cout <<" setting PolyDataB to " << (void *)polyDataB;
    fflush(NULL);

    if (this->PolyDataB) {this->PolyDataB->UnRegister(this);}
    this->PolyDataB = polyDataB;
    if (this->PolyDataB) {this->PolyDataB->Register(this);}
    this->Modified();
    }
}

// Description:
// Overload standard modified time function. If PolyDataB is modified
// then this object is modified as well.
unsigned long vtkPolyBoolean::GetMTime()
{
  unsigned long mTime=this->vtkPolyDataToPolyDataFilter::GetMTime();
  unsigned long OtherMTime;

  if ( this->PolyDataB != NULL )
    {
    OtherMTime = this->PolyDataB->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  if ( this->XformA != NULL )
    {
    OtherMTime = this->XformA->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }
  if ( this->XformB != NULL )
    {
    OtherMTime = this->XformB->GetMTime();
    mTime = ( OtherMTime > mTime ? OtherMTime : mTime );
    }

  return mTime;
}


void vtkPolyBoolean::UpdateCutter()
{
  unsigned long int mtime, pdMtime;
  int AorB;
  vtkPolyData *pd[2];

  // make sure input is available
  if ( this->Inputs[0] == NULL || this->PolyDataB == NULL )
    {
    vtkErrorMacro(<< "No input...can't execute!");
    return;
    }
  else
    {
    pd[0] = (vtkPolyData *)this->Inputs[0];
    pd[1] = this->PolyDataB;
    }

  // prevent chasing our tail
  if (this->Updating)
    {
    return;
    }

  this->Updating = 1;
  for (mtime=this->ExecuteTime, AorB = 0; AorB < 2; AorB++)
    {
    pd[AorB]->Update();
    pdMtime = pd[AorB]->GetMTime();
    if ( pdMtime > mtime ||
         this->TriDirectorySize[AorB] != pd[AorB]->GetNumberOfCells() )
      {
      this->DeleteTriDirectory( AorB );
      mtime = pdMtime;
      }
    }
  this->Updating = 0;

  if ( mtime > this->ExecuteTime || this->GetMTime() > this->ExecuteTime )
    {
    for (AorB=0; AorB<2; AorB++)
      {
      if ( pd[AorB]->GetDataReleased() )
        {
        pd[AorB]->Update();
        }
      }
    /*
      if ( this->StartMethod )
      {
      (*this->StartMethod)(this->StartMethodArg);
      }
    */

    //    this->Output->Initialize(); //clear output
    // reset AbortExecute flag and Progress
    this->AbortExecute = 0;
    this->Progress = 0.0;
    this->Execute();
    this->ExecuteTime.Modified();
    if ( !this->AbortExecute )
      {
      this->UpdateProgress(1.0);
      }
    //    this->SetDataReleased(0);
    /*
      if ( this->EndMethod )
      { 
      (*this->EndMethod)(this->EndMethodArg);
      }
    */
    }

  for (AorB=0; AorB<2; AorB++)
    {
    if ( pd[AorB]->ShouldIReleaseData() )
      {
      pd[AorB]->ReleaseData();
      }
    }
}



#define CELLS_PER_BUCKET 15
//
// Perform boolean operation between inputA ad inputB
//
void vtkPolyBoolean::Execute()
{
  vtkPolyData *inputA = (vtkPolyData *)this->Inputs[0];
  vtkPolyData *inputB = this->PolyDataB;
  vtkPolyData *output = this->GetOutput();
  vtkPointData *outputPD = output->GetPointData();
  vtkPointData *pdA = inputA->GetPointData(),
               *pdB = inputB->GetPointData();
  vtkCellData *outputCD = output->GetCellData();
  vtkMatrix4x4 *XformBtoA = vtkMatrix4x4::New();
  vtkMatrix4x4 *XformAInverse = vtkMatrix4x4::New();
  // make dummy transform because of but that Multiply4x4 isn't static fcn
  vtkTransform *dummyxform = vtkTransform::New();
  int numInputPointsA, numInputPointsB, numNewPoints,
      edgeCount = 0, ii;
  int numNewPointsExpected, operationOutputs3D;

  vtkDebugMacro(<< "Performing polyhedron boolean.");
  this->ExecutionCount++;
  this->IntersectionCount = 0;
  this->TriangleCount = 0;
  this->NodeCount = 0;

  numInputPointsA = inputA->GetNumberOfPoints();
  numInputPointsB = inputB->GetNumberOfPoints();
  this->IdOffsetB = numInputPointsA;
  this->IdOffsetNew = numInputPointsA + numInputPointsB;
  numNewPointsExpected = int(2*(sqrt( static_cast<double>(numInputPointsA) ) + sqrt( static_cast<double>(numInputPointsB) )));

  if ( this->Operation != BOOL_A_TOUCHES_B && this->Operation != BOOL_A_AND_B_1D )
    operationOutputs3D = 1;
  else
    operationOutputs3D = 0;

  if ( this->XformA != NULL )
    {
    this->XformA->Invert( *this->XformA, *XformAInverse );
    vtkMatrix4x4::Multiply4x4( XformAInverse, this->XformB, XformBtoA );
    }
  else
    this->XformB->DeepCopy(XformBtoA);
  //    *XformBtoA = *this->XformB;

  vtkDebugMacro(<< "InputA npts=" << numInputPointsA << " InputB npts=" << \
                numInputPointsB );
  vtkDebugMacro(<< "XformA:" << this->XformA << " XformB:" << this->XformB );
  vtkDebugMacro(<< "\nXformBtoA:\n" << XformBtoA->GetElement( 0, 0 ) << " " << \
                XformBtoA->GetElement( 0, 1 ) << " " << \
                XformBtoA->GetElement( 0, 2 ) << " " << \
                XformBtoA->GetElement( 0, 3 ) << "\n" << \
                XformBtoA->GetElement( 1, 0 ) << " " << \
                XformBtoA->GetElement( 1, 1 ) << " " << \
                XformBtoA->GetElement( 1, 2 ) << " " << \
                XformBtoA->GetElement( 1, 3 ) << "\n" << \
                XformBtoA->GetElement( 2, 0 ) << " " << \
                XformBtoA->GetElement( 2, 1 ) << " " << \
                XformBtoA->GetElement( 2, 2 ) << " " << \
                XformBtoA->GetElement( 2, 3 ) << "\n" << \
                XformBtoA->GetElement( 3, 0 ) << " " << \
                XformBtoA->GetElement( 3, 1 ) << " " << \
                XformBtoA->GetElement( 3, 2 ) << " " << \
                XformBtoA->GetElement( 3, 3 ) );

  // Initialize output
  this->NewPoints = vtkPoints::New();
  if ( operationOutputs3D )
    {
    this->NewPoints->Allocate( numInputPointsA + numInputPointsB +
                               numNewPointsExpected, 1000 );
    this->NewPoints->SetNumberOfPoints( numInputPointsA + numInputPointsB );
//    outputPD->CopyAllocate( pdA, numInputPointsA + numInputPointsB +
//                               numNewPointsExpected, 1000 );
    }
  else
    {
    this->NewPoints->Allocate( numNewPointsExpected, 1000 );
    this->NewPoints->SetNumberOfPoints( 0 );
    }

  output->SetPoints( this->NewPoints );
  this->NewPoints->Delete();

  this->NewEdges.Reset();
  if ( operationOutputs3D )
    {
    this->NewPolys = vtkCellArray::New();
    this->NewPolys->Allocate( inputA->GetNumberOfCells() +
                              inputB->GetNumberOfCells() + 300 );
    output->SetPolys( this->NewPolys );
    this->NewPolys->Delete();
    this->NewLines = vtkCellArray::New();
    this->NewLines->Allocate( numNewPointsExpected );
    output->SetLines( this->NewLines );
    this->NewLines->Delete();
    }
  else
    {
    this->NewLines = vtkCellArray::New();
    this->NewLines->Allocate( numNewPointsExpected );
    output->SetLines( this->NewLines );
    this->NewLines->Delete();
    }
  if ( this->Operation == BOOL_DEBUG )
    {
    this->NewLines = vtkCellArray::New();
    this->NewLines->Allocate( numNewPointsExpected );
    output->SetLines( this->NewLines );
    this->NewLines->Delete();
    this->NewVerts = vtkCellArray::New();
    this->NewVerts->Allocate( numNewPointsExpected );
    output->SetVerts( this->NewVerts );
    this->NewVerts->Delete();
    }
  
  // Preprocess volumes into OBB Trees
  if ( this->OBBTreeA == NULL )
    {
    this->OBBTreeA = vtkOBBTree::New();
    this->OBBTreeA->SetDataSet( inputA );
    this->OBBTreeA->SetNumberOfCellsPerBucket( CELLS_PER_BUCKET );
    this->OBBTreeA->SetTolerance( 0.001 );
    this->OBBTreeA->BuildLocator();
    }
  else
    this->OBBTreeA->Update();

  if ( this->OBBTreeB == NULL )
    {
    this->OBBTreeB = vtkOBBTree::New();
    this->OBBTreeB->SetDataSet( inputB );
    this->OBBTreeB->SetNumberOfCellsPerBucket( CELLS_PER_BUCKET );
    this->OBBTreeB->SetTolerance( 0.001 );
    this->OBBTreeB->BuildLocator();
    }
  else
    this->OBBTreeB->Update();

  // Intersect OBBs and process intersecting leaf nodes.
  // Intersect leaf node pairs to generate list of cellId pairs
  // Intersect cellId pairs to generate list of new edges.
  
//  inputA->BuildLinks();
//  inputB->BuildLinks();
  edgeCount = this->OBBTreeA->IntersectWithOBBTree( this->OBBTreeB, XformBtoA,
                                                    this->ProcessTwoNodes,
                                                    (void *)this );
  // New edges are generated from linked PiercePoints that
  // hang off vtkBoolTriEdges of vtkBoolTris in the TriDirectories
  vtkDebugMacro( << "edgeCount = " << edgeCount);

  if ( operationOutputs3D )
    {
    for ( ii=0; ii<numInputPointsA; ii++ )
      {
      this->NewPoints->InsertPoint( ii, inputA->GetPoint( ii ) );
      }
    if ( this->BPoints == NULL )
      this->BuildBPoints( XformBtoA );
    for ( ii=0; ii<numInputPointsB; ii++ )
      {
      this->NewPoints->InsertPoint( ii+this->IdOffsetB,
                                 this->BPoints->GetPoint( ii ) );
      }
    }

  if ( edgeCount > 0 )
    {
    if ( this->Operation == BOOL_DEBUG )
      {
      this->DisplayIntersectionGeometry();
      }
    else if ( operationOutputs3D )
      {
      this->FormLoops();
      }
    else
      {
      this->ProcessNewEdges();
      }
    }

  numNewPoints = this->NewPoints->GetNumberOfPoints();
  vtkDebugMacro( << "numNewPoints = " << numNewPoints << "\n" );
  vtkDebugMacro( << "IdOffsetB = " << this->IdOffsetB << "\n" );
  vtkDebugMacro( << "IdOffsetNew = " << this->IdOffsetNew << "\n" );
  

  if ( operationOutputs3D )
    {
    vtkIdType numPts, *pts;
    vtkCellArray *oldLines;

    this->ClassifyCells();
    // Pass through input lines from A
    oldLines = inputA->GetLines();
    oldLines->InitTraversal();
    while( oldLines->GetNextCell( numPts, pts ) )
      {
      this->NewLines->InsertNextCell( numPts, pts );
      }

    // Pass through input lines from B
    oldLines = inputB->GetLines();
    oldLines->InitTraversal();
    while( oldLines->GetNextCell( numPts, pts ) )
      {
      this->NewLines->InsertNextCell( numPts );
      for ( ii=0; ii<numPts; ii++ )
        {
        this->NewLines->InsertCellPoint( pts[ii]+this->IdOffsetB );
        }
      }

    vtkDebugMacro( << "starting PD copy...from A..." );
    for ( ii=0; 0 && ii<numNewPoints; ii++ )
      {
      if ( ii < this->IdOffsetB )
        {
        outputPD->CopyData(pdA, ii, ii);
        }
      else if ( ii < this->IdOffsetNew )
        {
    if ( ii == this->IdOffsetB)
          {
          vtkDebugMacro( << "...from B..." );
          }
        outputPD->CopyData(pdB, ii-this->IdOffsetB, ii);
        }
      else
        { // new point: figure out something
    if ( ii == this->IdOffsetNew)
          {
          vtkDebugMacro( << "...new points..." );
          }
        }
      }
    vtkDebugMacro( << " ...done PD copy.\n" );
    }

  XformBtoA->Delete();
  XformAInverse->Delete();
  dummyxform->Delete();
  this->IntersectionCount = edgeCount;

  if ( this->BPoints )
    {
    this->BPoints->Delete();
    this->BPoints = NULL;
    }
  this->ResetBoolTris();
  this->DeleteNewEdges();
}

void vtkPolyBoolean::ResetBoolTris()
  {
  int AorB, num, ii, jj;
  vtkPolyData *dataset;
  vtkBoolTri *thisTri;

  for ( AorB=0; AorB<2; AorB++ )
    {
    if ( this->TriDirectory[AorB] )
      {
      dataset = ( AorB == 0 ? this->GetInput() : this->PolyDataB );
      num = this->TriDirectorySize[AorB];
      for ( ii=0; ii<num; ii++ )
        {
        thisTri = this->TriDirectory[AorB][ii];
        while ( thisTri != NULL )
          {
          if ( thisTri->NewLoops ) delete thisTri->NewLoops;
          thisTri->NewLoops = NULL;
          for ( jj=0; jj<3; jj++ )
            {
            thisTri->Edges[jj]->DeletePPs();
            thisTri->Edges[jj]->Flag = 0;
            }
          thisTri = thisTri->Next;
          }
        this->CellFlags[AorB][ii] = BOOL_CELL_UNKNOWN;
        }
      }
    }
  }

void vtkPolyBoolean::DeleteNewEdges()
  {
  int ii, num;

  num = this->NewEdges.GetCount();
  for ( ii=0; ii<num; ii++ )
    {
    delete this->NewEdges.Get( ii );
    }
  }

void vtkPolyBoolean::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkPolyDataToPolyDataFilter::PrintSelf(os,indent);

  os << indent << "PolyDataB: " << this->PolyDataB << "\n";
  os << indent << "Operation: " << this->Operation;
}

int vtkPolyBoolean::ProcessTwoNodes( vtkOBBNode *nodeA,
                                     vtkOBBNode *nodeB,
                                     vtkMatrix4x4 *XformBtoA,
                                     void *bool_void )
  {
  vtkPolyBoolean *pbool = (vtkPolyBoolean *)bool_void;
  vtkPolyData *InputA;
  int ii, jj, numA, numB, type;
  vtkIdType cellIdA, cellIdB, numPts;
  vtkIdType *ptIds;
  static vtkIdList *cellIdsA = vtkIdList::New();
  static vtkIdList *cellIdsB = vtkIdList::New();
  vtkFloatingPointType p0[3], p1[3], p2[3];

  cellIdsA->Allocate(CELLS_PER_BUCKET+10);
  cellIdsB->Allocate(CELLS_PER_BUCKET+10);

  vtkMatrix4x4 *XformAtoB = vtkMatrix4x4::New();
  int new_edges, n_edges = 0;

  pbool->NodeCount++;

// 0) Transform Points from B to A's coordinate frame, if not done yet.
// 1) Foreach cell in OBB-A, triangulate it and check for overlap
//    with OBB-B
// 2) Foreach cell in OBB-B, triangluate it and check for overlap
//    with OBB-A
// 3) Foreach qualified A-triangle, compute piercepoints with each
//    qualified B-triangle, and vice versa.
// 4) Computing the same piercepoint twice is prevented by recording
//    which edge-triangle pairs have already been processed in the
//    edge directory.
// 5) The edge directory...

  if ( pbool->BPoints == NULL )
    pbool->BuildBPoints( XformBtoA );

  cellIdsB->Reset();
  numB = nodeB->Cells->GetNumberOfIds();
  for ( ii=0; ii<numB; ii++ )
    {
    cellIdB = nodeB->Cells->GetId( ii );
    type = pbool->PolyDataB->GetCellType( cellIdB );
    switch ( type )
      {
      case VTK_TRIANGLE:
        pbool->PolyDataB->GetCellPoints( cellIdB, numPts, ptIds );
        pbool->BPoints->GetPoint( ptIds[0], p0 );
        pbool->BPoints->GetPoint( ptIds[1], p1 );
        pbool->BPoints->GetPoint( ptIds[2], p2 );
        // ptIds[] holds the ids if the B triangle points.
        // Go further only if triB intersects OBB-A
        if ( pbool->OBBTreeA->vtkOBBTree::TriangleIntersectsNode(
                                         nodeA, p0, p1, p2, NULL ) )
          { // This cell qualifies for further testing
          cellIdsB->InsertNextId( cellIdB );
          pbool->AddCellTriangles( cellIdB, ptIds, type, numPts, 1 );
          }
        break;
      case VTK_LINE: case VTK_POLY_LINE:
        // Pass through silently
        break;
      default:
        // Not implemented yet.
        vtkGenericWarningMacro( "Unimplemented cell type " << type <<
                                " encountered in B.");
        break;
      }
    }

  numB = cellIdsB->GetNumberOfIds();
  if ( numB == 0 )
    return( 0 ); // Can return early. No intersection.

  XformBtoA->Invert( *XformBtoA, *XformAtoB );

  cellIdsA->Reset();
  numA = nodeA->Cells->GetNumberOfIds();
  InputA = pbool->GetInput();
  for ( ii=0; ii<numA; ii++ )
    {
    cellIdA = nodeA->Cells->GetId( ii );
    type = InputA->GetCellType( cellIdA );
    switch ( type )
      {
      case VTK_TRIANGLE:
      pbool->GetInput()->GetCellPoints( cellIdA, numPts, ptIds );
      InputA->GetPoint( ptIds[0], p0 );
      InputA->GetPoint( ptIds[1], p1 );
      InputA->GetPoint( ptIds[2], p2 );
      // ptIds[] holds the ids if the A triangle points.
      // Go further only if triA intersects OBB-B
      if ( pbool->OBBTreeB->vtkOBBTree::TriangleIntersectsNode(
                                        nodeB, p0, p1, p2, XformAtoB ) )
        { // This cell qualifies for further testing
        cellIdsA->InsertNextId( cellIdA );
        pbool->AddCellTriangles( cellIdA, ptIds, type, numPts, 0 );
        }
      break;
      default:
        // Not implemented yet.
        vtkGenericWarningMacro( "Unimplemented cell type " << type <<
                                " encountered in A.");
        break;
      }
    }

  XformAtoB->Delete();

  numA = cellIdsA->GetNumberOfIds();
  for ( ii=0; ii<numA; ii++ )
    for ( jj=0; jj<numB; jj++ )
      {
      new_edges = pbool->IntersectCellPair( cellIdsA->GetId(ii),
                                           cellIdsB->GetId(jj) );
      if ( new_edges < 0 )
        return( new_edges );
      n_edges += new_edges;
      }
  return( n_edges );
  }

// Returns the number of new edges created.
int vtkPolyBoolean::IntersectCellPair( int cellIdA, int cellIdB )
  {
  vtkBoolTri *triA, *triB;
  int n_edges = 0, edges;

  //vtkDebugMacro( << "IntersectCellPair(" << cellIdA << "," << cellIdB << ")" );
  for ( triA=this->TriDirectory[0][cellIdA]; triA != NULL; triA = triA->Next )
    {
    for ( triB=this->TriDirectory[1][cellIdB]; triB != NULL; triB = triB->Next )
      {
      edges = this->IntersectBoolTriPair( triA, triB );
      if ( edges < 0 )
        return( edges );
      n_edges += edges;
      }
    }
  return( n_edges );
  }

// Returns the number of new edges created.
int vtkPolyBoolean::IntersectBoolTriPair( vtkBoolTri *triA, vtkBoolTri *triB )
  {
  int AorB, ii, flip_dir, numPP, idx, snapIdx;
  vtkBoolTri *tri[2], *thisTri, *otherTri;
  vtkBoolTriEdge *thisEdge, *nextEdge, *prevEdge;
  vtkPiercePoint *thisPP, *nextPP, *intPPs[2][2], *startPP, *endPP, **prevPPP;
  vtkPiercePoint tmpPPs[2][2];
  vtkPoints *points;
  vtkFloatingPointType xprod[3], offsets[2][3], p0[3], p1[3], param, offset0, offset1, deltaX;
  int PPEdgeIndices[2][2];
  vtkFloatingPointType ang_eps = this->AngleResolution*3.14159/180,
        dist_eps = this->DistanceResolution;
  vtkFloatingPointType dist_eps2; // the square of dist_eps, if needed.

  this->TriangleCount++;
  vtkMath::Cross( triA->Normal, triB->Normal, xprod );
  if ( vtkMath::Dot( xprod, xprod ) < ang_eps )
    { // do not process coplanar triangles
    vtkDebugMacro( << "Coplanar triangles:" << triA << "," << triB << "\n");
    return( 0 );
    }

  // check each edge of triA against plane of triB, or vice versa
  tri[0] = triA; tri[1] = triB;
  for ( AorB=0; AorB<2; AorB++ )
    {
    points = (AorB == 0 ? (vtkPoints *)this->GetInput()->GetPoints() :
                          this->BPoints );
    thisTri = tri[AorB];
    otherTri = tri[1-AorB];
    for ( ii=0; ii<3; ii++ )
      { // first pass: compute offsets.
      thisEdge = thisTri->Edges[ii];
      if ( thisEdge->Neighbors[0] == thisTri )
        flip_dir = 0;
      else
        flip_dir = 1;
      points->GetPoint( thisEdge->Points[flip_dir], p0 );
      offsets[AorB][ii] = vtkMath::Dot( p0, otherTri->Normal )
                          - otherTri->Offset;
      }

    numPP = 0;
    for ( ii=0; ii<3; ii++ )
      { // second pass: compute piercepoint topology
      if ( (offsets[AorB][ii]>0) != (offsets[AorB][(ii+1)%3]>0) )
        {
        PPEdgeIndices[AorB][numPP++] = ii;
        }
      }
    if ( numPP != 2 )
      return( 0 ); // must have 2 piercepoints on each tri for intersection.
    }

  // intersection is determined by the 4 PPs from PPEdgeIndices[2][2]
  for ( AorB=0; AorB<2; AorB++ )
    {
    points = (AorB == 0 ? (vtkPoints *)this->GetInput()->GetPoints() :
                          this->BPoints );
    thisTri = tri[AorB];
    otherTri = tri[1-AorB];
    for ( ii=0; ii<2; ii++ )
      {
      idx = PPEdgeIndices[AorB][ii];
      thisEdge = thisTri->Edges[idx];
      for ( thisPP=thisEdge->FirstPP; thisPP != NULL; thisPP=thisPP->Next )
        {
        if ( thisPP->Triangle == otherTri )
          break; // Use old PP from adjacent triangle calculations
        }
      if ( thisPP == NULL )
        { // make a new tmpPP
        thisPP = &tmpPPs[AorB][ii];
        thisPP->NewId = -2; // -2 marks it as a local temporary variable
        thisPP->Next = thisPP->Prev = thisPP->Merge = NULL;
        thisPP->NextEdge[0] = thisPP->NextEdge[1] = NULL;
        thisPP->Triangle = otherTri;
        thisPP->Edge = thisEdge;
        if ( thisEdge->Neighbors[0] == thisTri )
          {
          offset0 = offsets[AorB][idx];
          offset1 = offsets[AorB][(idx+1)%3];
          }
        else
          {
          offset1 = offsets[AorB][idx];
          offset0 = offsets[AorB][(idx+1)%3];
          }
        snapIdx = -1;
        param = offset0/(offset0 - offset1);
        points->GetPoint( thisEdge->Points[0], p0 );
        points->GetPoint( thisEdge->Points[1], p1 );
        if ( param < 0.5 && fabs( offset0 ) < dist_eps )
          { // snap PP to equivalent endpoint
          param = 0.0;
          snapIdx = thisEdge->Points[0];
          thisPP->Point[0] = p0[0];
          thisPP->Point[1] = p0[1];
          thisPP->Point[2] = p0[2];
          }
        else if ( param > 0.5 && fabs( offset1 ) < dist_eps )
          { // snap PP to equivalent endpoint
          param = 1.0;
          snapIdx = thisEdge->Points[1];
          thisPP->Point[0] = p1[0];
          thisPP->Point[1] = p1[1];
          thisPP->Point[2] = p1[2];
          }
        thisPP->SnapIdx = snapIdx;
        thisPP->Param = param;
        if ( snapIdx < 0 )
          { // must compute point from param
          thisPP->Point[0] = p0[0] + param*(p1[0] - p0[0]);
          thisPP->Point[1] = p0[1] + param*(p1[1] - p0[1]);
          thisPP->Point[2] = p0[2] + param*(p1[2] - p0[2]);
          }
        }
      p0[0] = thisPP->Point[0];
      p0[1] = thisPP->Point[1];
      p0[2] = thisPP->Point[2];
      thisPP->Xparam = vtkMath::Dot( xprod, p0 );
      intPPs[AorB][ii] = thisPP;
      }
    if ( intPPs[AorB][0]->Xparam > intPPs[AorB][1]->Xparam )
      { // sort PPs by X param
      nextPP = intPPs[AorB][0];
      intPPs[AorB][0] = intPPs[AorB][1];
      intPPs[AorB][1] = nextPP;
      }
    }

  // Here's the final payoff: If PPs on A and B have an overlapping
  // Xparam range, then there is an edge. Otherwise, there is not.
  if ( intPPs[0][0]->Xparam > intPPs[1][1]->Xparam ||
       intPPs[1][0]->Xparam > intPPs[0][1]->Xparam )
    { // Iff the min A param is greater than the max B param or
      // the min B param is greater than the max A param, then NO EDGE.
    return( 0 ); // empty handed
    }
  else if ( this->Operation == BOOL_A_TOUCHES_B )
    return( -1 ); // Collision Detection
  else
    { // there is a new edge - create it.
    if ( intPPs[0][0]->Xparam > intPPs[1][0]->Xparam )
      { // New edge starts on min A PP
      startPP = intPPs[0][0];
      }
    else
      { // New edge starts on min B PP
      startPP = intPPs[1][0];
      }
    if ( startPP->NewId == -2 )
      { // Make the Tempory PP Permanent.
      // Insert this PP into list in order of param. (insertion sort)
      thisPP = new vtkPiercePoint;
      thisPP->Param = startPP->Param;
      thisPP->Edge = startPP->Edge;
      thisPP->Triangle = startPP->Triangle;
      thisPP->SnapIdx = startPP->SnapIdx;
      thisPP->Xparam = startPP->Xparam;
      thisPP->Point[0] = startPP->Point[0];
      thisPP->Point[1] = startPP->Point[1];
      thisPP->Point[2] = startPP->Point[2];
      param = thisPP->Param;
      prevPPP = &thisPP->Edge->FirstPP;
      while( *prevPPP != NULL && (*prevPPP)->Param < param )
        prevPPP = &(*prevPPP)->Next;
      nextPP = *prevPPP;
      *prevPPP = thisPP;
      thisPP->Prev = *prevPPP;
      thisPP->Next = nextPP;
      if ( nextPP != NULL )
        nextPP->Prev = thisPP;
      startPP = thisPP;
      if ( nextPP != NULL && fabs( param - nextPP->Param ) < 1.0e-7 )
        startPP->MergePP( nextPP );
      if ( startPP->Prev != NULL && fabs( param - startPP->Prev->Param ) < 1.0e-7 )
        startPP->MergePP( startPP->Prev );
      }
    if ( intPPs[0][1]->Xparam < intPPs[1][1]->Xparam )
      { // New edge ends on max A PP
      endPP = intPPs[0][1];
      }
    else
      { // New edge ends on max B PP
      endPP = intPPs[1][1];
      }
    if ( endPP->NewId == -2 )
      { // Make the Temporary PP Permanent.
      // Insert this PP into list in order of param. (insertion sort)
      thisPP = new vtkPiercePoint;
      thisPP->Param = endPP->Param;
      thisPP->Edge = endPP->Edge;
      thisPP->Triangle = endPP->Triangle;
      thisPP->SnapIdx = endPP->SnapIdx;
      thisPP->Xparam = endPP->Xparam;
      thisPP->Point[0] = endPP->Point[0];
      thisPP->Point[1] = endPP->Point[1];
      thisPP->Point[2] = endPP->Point[2];
      param = thisPP->Param;
      prevPPP = &thisPP->Edge->FirstPP;
      while( *prevPPP != NULL && (*prevPPP)->Param < param )
        prevPPP = &(*prevPPP)->Next;
      nextPP = *prevPPP;
      *prevPPP = thisPP;
      thisPP->Prev = *prevPPP;
      thisPP->Next = nextPP;
      if ( nextPP != NULL )
        nextPP->Prev = thisPP;
      endPP = thisPP;
      if ( nextPP != NULL && fabs( param - nextPP->Param ) < 1.0e-7 )
        endPP->MergePP( nextPP );
      if ( endPP->Prev != NULL && fabs( param - endPP->Prev->Param ) < 1.0e-7 )
        endPP->MergePP( endPP->Prev );
      }

    // Merge PPs that are closer than dist_eps
    dist_eps2 = dist_eps * dist_eps * vtkMath::Dot( xprod, xprod );
    deltaX = startPP->Xparam - endPP->Xparam;
    if ( deltaX*deltaX < dist_eps2 )
      {
      startPP->MergePP( endPP ); // New edge has "zero" length, collapse it.
      }
    else
      { // put new edges on triangles
      this->MakeNewPoint( startPP );
      this->MakeNewPoint( endPP );
      thisEdge = new vtkBoolTriEdge;
      thisEdge->Neighbors[0] = triA;
      thisEdge->Neighbors[1] = triB;
      this->CellFlags[0][triA->CellId] = BOOL_CELL_CUT;
      this->CellFlags[1][triB->CellId] = BOOL_CELL_CUT;
      if ( this->Operation == BOOL_A_OR_B )
        { // direction on A is backwards
        thisEdge->Points[1] = startPP->NewId;
        thisEdge->PPoints[1] = startPP;
        thisEdge->Points[0] = endPP->NewId;
        thisEdge->PPoints[0] = endPP;
        startPP->NextEdge[1] = thisEdge;
        endPP->NextEdge[0] = thisEdge;
        nextEdge = startPP->NextEdge[0];
        prevEdge = endPP->NextEdge[1];
        }
      else
        { // direction on A is forwards
        thisEdge->Points[0] = startPP->NewId;
        thisEdge->PPoints[0] = startPP;
        thisEdge->Points[1] = endPP->NewId;
        thisEdge->PPoints[1] = endPP;
        startPP->NextEdge[0] = thisEdge;
        endPP->NextEdge[1] = thisEdge;
        nextEdge = endPP->NextEdge[0];
        prevEdge = startPP->NextEdge[1];
        }
      // link into topology
      if ( nextEdge != NULL )
        {
        thisEdge->Next[0] = nextEdge;
        nextEdge->Next[1] = thisEdge;
        }
      if ( prevEdge != NULL )
        {
        thisEdge->Next[1] = prevEdge;
        prevEdge->Next[0] = thisEdge;
        }
      this->NewEdges.AddNewEdge( thisEdge );
      }
    return( 1 );
    }
  }

void vtkPolyBoolean::MakeNewPoint( vtkPiercePoint *inPP )
  {
  if ( inPP->NewId == -1 )
    { // This PP really is new.
    if ( 0 && inPP->SnapIdx > -1 && this->Operation != BOOL_A_TOUCHES_B &&
         this->Operation != BOOL_A_AND_B_1D )
      { // Re-use an old point
      inPP->NewId = inPP->SnapIdx;
      if ( inPP->Edge->Neighbors[0]->AorB )
        {
        inPP->NewId += this->IdOffsetB; // It's B
        }
      }
    else
      { // Make a new point
      inPP->NewId = this->NewPoints->InsertNextPoint( inPP->Point );
      // Make copy for B
      if ( this->Operation != BOOL_A_TOUCHES_B &&
           this->Operation != BOOL_A_AND_B_1D &&
           this->NewPoints->InsertNextPoint( inPP->Point ) != inPP->NewId+1 )
        {
        vtkDebugMacro( << "PointID assumption violated" );
        }
      }
    }
  }

void vtkPolyBoolean::DisplayIntersectionGeometry()
  {
  int AorB;
  vtkIdType ii, jj, minId, nEdges;
  vtkIdList *pntIds = vtkIdList::New();
  int numEdges, numCells;
  vtkIdType *cellPts;
  vtkBoolTriEdge *thisEdge, *firstEdge, *lastEdge;
  vtkPolyData *dataset;

  numEdges = this->NewEdges.GetCount();
  for ( ii=0; ii<numEdges; ii++ )
    {
    thisEdge = this->NewEdges.Get(ii);
    if ( thisEdge->Flag == 0 )
      {
      firstEdge = lastEdge = thisEdge;
      nEdges = 1;
      while( lastEdge->Next[0] != NULL &&
             lastEdge->Next[0] != firstEdge )
        {
        nEdges++;
        lastEdge = lastEdge->Next[0];
        }
      if ( lastEdge->Next[0] != firstEdge )
        while( firstEdge->Next[1] != NULL )
          { // find beginning of open loop
          nEdges++;
          firstEdge = firstEdge->Next[1];
          }
      pntIds->SetNumberOfIds( nEdges + 1 );
      pntIds->SetId( 0, firstEdge->Points[0] );
      for ( jj=1, thisEdge = firstEdge; jj<=nEdges; jj++ )
        {
        thisEdge->Flag = 1;
        pntIds->SetId( jj, thisEdge->Points[1] );
        thisEdge = thisEdge->Next[0];
        }
      this->NewLines->InsertNextCell( pntIds );
      if ( lastEdge->Next[0] == NULL )
        {
        this->NewLines->InsertNextCell( 2 );
        this->NewLines->InsertCellPoint( firstEdge->Points[0] );
        this->NewLines->InsertCellPoint( this->IdOffsetB );
        this->NewLines->InsertNextCell( 2 );
        this->NewLines->InsertCellPoint( lastEdge->Points[1] );
        this->NewLines->InsertCellPoint( this->IdOffsetB );
        }
      }
    }
  pntIds->Delete();

  for ( AorB=0; AorB<2; AorB++ )
    {
    if ( AorB == 0 )
      minId = 0;
    else
      minId = this->IdOffsetB;
    if ( this->TriDirectory[AorB] )
      {
      dataset = (AorB==0 ? this->GetInput() : this->PolyDataB );
      numCells = this->TriDirectorySize[AorB];
      for ( ii=0; ii<numCells; ii++ )
        {
        if ( this->CellFlags[AorB][ii] == BOOL_CELL_CUT )
          {
          dataset->GetCellPoints( ii, nEdges, cellPts );
          this->NewPolys->InsertNextCell( nEdges );
          for ( jj=0; jj<nEdges; jj++ )
            this->NewPolys->InsertCellPoint( minId + cellPts[jj] );
          }
        }
      }
    }
  }

void vtkPolyBoolean::ProcessNewEdges()
  {
  int ii, jj, nEdges;
  vtkIdList *pntIds = vtkIdList::New();
  int numEdges;
  vtkBoolTriEdge *thisEdge, *firstEdge, *lastEdge;

  numEdges = this->NewEdges.GetCount();
  for ( ii=0; ii<numEdges; ii++ )
    {
    thisEdge = this->NewEdges.Get(ii);
    if ( thisEdge->Flag == 0 )
      {
      firstEdge = lastEdge = thisEdge;
      nEdges = 1;
      while( lastEdge->Next[0] != NULL &&
             lastEdge->Next[0] != firstEdge )
        {
        nEdges++;
        lastEdge = lastEdge->Next[0];
        }
      if ( lastEdge->Next[0] != firstEdge )
        while( firstEdge->Next[1] != NULL )
          { // find beginning of open loop
          nEdges++;
          firstEdge = firstEdge->Next[1];
          }
      pntIds->SetNumberOfIds( nEdges + 1 );
      pntIds->SetId( 0, firstEdge->Points[0] );
      for ( jj=1, thisEdge = firstEdge; jj<=nEdges; jj++ )
        {
        thisEdge->Flag = 1;
        pntIds->SetId( jj, thisEdge->Points[1] );
        thisEdge = thisEdge->Next[0];
        }
      this->NewLines->InsertNextCell( pntIds );
      }
    }
  pntIds->Delete();
  }

void vtkPolyBoolean::ClassifyCells()
  {
  int AorB, numCells, ii, numPts, jj, p0, p1, cellId, neighborId;
  int minId, maxId, inside, operation = this->Operation, keepInside;
  vtkPolyData *dataset;
  vtkBoolTri *thisTri;
  vtkBoolLoop *thisLoop;
  vtkIdList *cellNeighbors = vtkIdList::New();
  vtkBoolTriEdge *thisEdge;
  int flagBit;

  for ( AorB=0; AorB<2; AorB++ )
    {
    dataset = (AorB==0 ? this->GetInput() : this->PolyDataB );
    flagBit = 2*AorB + 2;
    if ( operation == BOOL_A_MINUS_B && AorB == 1 )
      keepInside = 1;
    else if ( operation == BOOL_A_AND_B )
      keepInside = 1;
    else
      keepInside = 0;
    if ( AorB == 0 )
      {
      minId = 0;
      maxId = this->IdOffsetB - 1;
      }
    else
      {
      minId = this->IdOffsetB;
      maxId = this->IdOffsetNew - 1;
      }
    if ( this->TriDirectory[AorB] )
      {
      numCells = this->TriDirectorySize[AorB];
      // This loop identifies all cells that
      // are connected to the intersection.
      for ( ii=0; ii<numCells; ii++ )
        {
        thisTri = this->TriDirectory[AorB][ii];
        while( thisTri != NULL )
          {
          // First mark cells known to be in the result
          cellId = thisTri->CellId;
          thisLoop = thisTri->NewLoops;
          if ( thisLoop != NULL )
            this->AddNewPolygons( thisTri );
          while( thisLoop != NULL )
            { // Gather neighboring cells on AorB for inclusion in result.
            numPts = thisLoop->Points->GetNumberOfIds();
            for ( jj=0; jj<numPts; jj++ )
               {
               p0 = thisLoop->Points->GetId( jj );
               p1 = thisLoop->Points->GetId( (jj+1)%numPts );
               if ( p0 < minId || p0 > maxId || p1 < minId || p1 > maxId )
                 continue;
               p0 -= minId;
               p1 -= minId;
               dataset->GetCellEdgeNeighbors( cellId, p0, p1, cellNeighbors );
               if ( cellNeighbors->GetNumberOfIds() == 1 )
                 {
                 neighborId = cellNeighbors->GetId( 0 );
                 if ( this->CellFlags[AorB][neighborId] == BOOL_CELL_UNKNOWN )
                   this->GatherMarkCellNeighbors( AorB, dataset, neighborId,
                                                  BOOL_CELL_IN_RESULT );
                 }
               else
                 {
                 vtkDebugMacro( << "Edge " << p0 << "-" << p1 << " (" <<
                      dataset->GetPoint(p0)[0] << "," <<
                      dataset->GetPoint(p0)[1] << "," <<
                      dataset->GetPoint(p0)[2] << ")-(" <<
                      dataset->GetPoint(p0)[0] << "," <<
                      dataset->GetPoint(p0)[1] << "," <<
                      dataset->GetPoint(p0)[2] << ")" <<
                      " on cell "<<cellId<<" in "<<
                      (AorB==0?"A":"B")<<" has "<<
                      cellNeighbors->GetNumberOfIds()<<" neighbors.\n" );
                 }
               }
            thisLoop = thisLoop->Next;
            }
          // Next mark the cells known to be not in the result
          // by looking for uncut edges in cut outer triangle boundaries.
          if ( thisTri->NewLoops != NULL &&
               ((thisTri->Edges[0]->Flag & flagBit) ||
                (thisTri->Edges[1]->Flag & flagBit) ||
                (thisTri->Edges[2]->Flag & flagBit) ) )
            { // Outer loop is cut.
            for ( jj=0; jj<3; jj++ )
              {
              thisEdge = thisTri->Edges[jj];
              if ( (thisEdge->Flag & flagBit) == 0 )
                { // Cells neighboring this edge are not in the result
                if ( thisEdge->Neighbors[0] == thisTri )
                  {
                  p0 = thisEdge->Points[0];
                  p1 = thisEdge->Points[1];
                  }
                else
                  {
                  p1 = thisEdge->Points[0];
                  p0 = thisEdge->Points[1];
                  }
                dataset->GetCellEdgeNeighbors( cellId, p0, p1, cellNeighbors );
                if ( cellNeighbors->GetNumberOfIds() == 1 )
                  {
                  neighborId = cellNeighbors->GetId( 0 );
                  if ( this->CellFlags[AorB][neighborId] == BOOL_CELL_UNKNOWN )
                    this->GatherMarkCellNeighbors( AorB, dataset, neighborId,
                                                   BOOL_CELL_NOT_IN_RESULT );
                  }
                }
              }
            }
          thisTri = thisTri->Next;
          }
        }
      }
      // This second pass calculates the disposition of regions
      // that are not part of the intersection.
      numCells = dataset->GetNumberOfCells();
      for ( ii=0; ii<numCells; ii++ )
        {
        if ( this->CellFlags[AorB] == NULL ||
             this->CellFlags[AorB][ii] == BOOL_CELL_UNKNOWN )
          {
          inside = 0;
          if ( inside == keepInside )
            this->GatherMarkCellNeighbors( AorB, dataset, ii,
                                           BOOL_CELL_IN_RESULT );
          else
            this->GatherMarkCellNeighbors( AorB, dataset, ii,
                                           BOOL_CELL_NOT_IN_RESULT );
          }
        }
    }
  cellNeighbors->Delete();
  }

void vtkPolyBoolean::GatherMarkCellNeighbors( int AorB, vtkPolyData *dataset,
                                              int cellId, int marker ) 
  {
  int ii, jj,   offset; 
  vtkIdType thisId, numPts, neighborId, p0, p1;
  vtkIdList *cellNeighbors = vtkIdList::New();
  vtkIdList *offsetIds = vtkIdList::New();
  vtkIdType *cellIdStack, *ptIds;
  int depth, maxDepth, newId, invertB = 0;

  if ( AorB == 0 )
    offset = 0;
  else
    {
    offset = this->IdOffsetB;
    if ( this->Operation == BOOL_A_MINUS_B )
      invertB = 1;
    }

  if ( this->CellFlags[AorB] != NULL )
    {
    cellIdStack = new vtkIdType[dataset->GetNumberOfCells()];
    cellIdStack[0] = cellId;
    this->CellFlags[AorB][cellId] = marker;
    }
  depth = maxDepth = 1;
  while( depth > 0 )
    { // simulate recursion without the overhead or limitations
    depth--;
    if ( this->CellFlags[AorB] != NULL )
      {
      thisId = cellIdStack[depth];
      }
    else
      {
      thisId = cellId;
      }
    dataset->GetCellPoints( thisId, numPts, ptIds );
    offsetIds->SetNumberOfIds( numPts );
    for ( ii=0; ii<numPts; ii++ )
      {
      p0 = ptIds[ii];
      if ( invertB )
        offsetIds->SetId(numPts-ii-1, p0 + offset );
      else
        offsetIds->SetId(ii, p0 + offset );
      p1 = ptIds[(ii+1)%numPts];
      if ( this->CellFlags[AorB] != NULL )
        {
        dataset->GetCellEdgeNeighbors( thisId, p0, p1, cellNeighbors );
        for ( jj=0; jj<cellNeighbors->GetNumberOfIds(); jj++ )
          {
          neighborId = cellNeighbors->GetId( jj );
          if ( this->CellFlags[AorB] != NULL &&
               this->CellFlags[AorB][neighborId] == BOOL_CELL_UNKNOWN )
            { // push this cell onto stack
            this->CellFlags[AorB][neighborId] = marker;
            cellIdStack[depth++] = neighborId;
            }
          }
        }
      }
    if ( depth > maxDepth )
      maxDepth = depth;
    if ( marker == BOOL_CELL_IN_RESULT )
      newId = this->NewPolys->InsertNextCell( offsetIds );
    }
  if ( this->CellFlags[AorB] != NULL )
    {
    delete [] cellIdStack;
    }
  cellNeighbors->Delete();
  offsetIds->Delete();
  }

void vtkPolyBoolean::FormLoops()
  {
  int AorB, ii, jj, flagBit, startPnt, nextPnt, bPnt, direction;
  int numEdges, loopCount, abortTri;
  const char *abortReasons[5] = { "OK", "Dead End", "Rho-walk",
                            "Fell off triangle", "Endless Loop" };
  vtkPiercePoint *thisPP, *nextPP, *linkPP;
  vtkBoolTri *thisTri;
  vtkBoolTriEdge *thisEdge, *nextEdge, *thisFrame, *nextFrame;
  vtkBoolLoop *newLoop;
  double dist2, dist_eps = this->DistanceResolution;

  if ( this->ThisLoop == NULL )
    {
    this->ThisLoop = vtkIdList::New();
    this->ThisLoop->Allocate( 300 );
    }

  numEdges = this->NewEdges.GetCount();
  for ( AorB=0; AorB<2; AorB++ )
    {
    flagBit = 2*AorB + 2;
    for ( ii=0; ii<numEdges; ii++ )
      {
      thisEdge = this->NewEdges.Get(ii);
      if ( (thisEdge->Flag & flagBit) == 0 )
        { // Gather loop on cut triangle AorB
        thisTri = thisEdge->Neighbors[AorB];
        startPnt = thisEdge->Points[AorB];
        this->ThisLoop->Reset();
        abortTri = loopCount = 0;
        do
          {
          if ( thisEdge != NULL )
            { // Step along an intersection edge...
            thisEdge->Flag |= flagBit;
            nextPnt = thisEdge->Points[1-AorB];
            nextPP = thisEdge->PPoints[1-AorB];
            if ( thisEdge->Next[AorB] == NULL )
              { // Repair connectivity across one-sided edge
          vtkDebugMacro( << "Unlinked edge on " << ( AorB ? "A" : "B" )
                             << " in triangle " << thisTri->CellId << ".\n" );
              for ( jj=0; jj<numEdges; jj++ )
                {
                nextEdge = this->NewEdges.Get(jj);
                if ( nextEdge->Next[1-AorB] == NULL )
                  {
                  linkPP = nextEdge->PPoints[AorB];
                  dist2 = vtkMath::Distance2BetweenPoints(
                         nextPP->Point, linkPP->Point );
                  vtkDebugMacro( << "dist2=" << dist2 << "\n" );
                  if ( dist2 < dist_eps*dist_eps + 5.0e-10 )
                    {
                    thisEdge->Next[AorB] = nextEdge;
                    nextEdge->Next[1-AorB] = thisEdge;
                    vtkDebugMacro( << "Linked across one-sided edge at: ("
                                   << linkPP->Point[0] << ", "
                                   << linkPP->Point[1] << ", "
                                   << linkPP->Point[2] << ") \n" );
                    break;
                    }
                  }
                }
              }
            if ( nextPP->Triangle == thisTri )
              { // ...to the next intersection edge...
              nextEdge = thisEdge->Next[AorB];
              nextFrame = NULL;
              if ( nextEdge == NULL )
                { // Must be a MERGED pp. Deal with it.
                for ( thisPP=nextPP->Merge; thisPP != nextPP && !abortTri;
                      thisPP=thisPP->Merge )
                   {
                   if ( thisPP == NULL )
                     { // Dead End on one-sided piercing edge
                     abortTri = 1; // Dead End
                     break;
                     }
                   if ( thisPP->Triangle == thisTri )
                     {
                     nextEdge = thisPP->NextEdge[AorB];
                     nextFrame = NULL;
                     break;
                     }
                   if ( thisPP->Edge->Neighbors[0] == thisTri ||
                        thisPP->Edge->Neighbors[1] == thisTri )
                     {
                     nextEdge = NULL;
                     nextFrame = thisPP->Edge;
                     break;
                     }
                   }
                nextPP = thisPP;
                }
              }
            else
              { // ...or to a frame edge.
              nextEdge = NULL;
              nextFrame = nextPP->Edge;
              }
            }
          else if ( thisFrame != NULL )
            { // Step along a frame edge...
            thisFrame->Flag |= flagBit;
            if ( thisFrame->Neighbors[0] == thisTri )
              direction = 0; // stepping forward on this edge
            else
              direction = 1; // stepping backward on this edge
            if ( direction == 0 )
              {
              if ( thisPP != NULL )
                nextPP = thisPP->Next;
              else
                nextPP = thisFrame->FirstPP;
              }
            else
              {
              if ( thisPP == thisFrame->FirstPP )
                nextPP = NULL;
              else
                {
                nextPP = thisFrame->FirstPP;
                while( nextPP->Next != thisPP )
                      nextPP = nextPP->Next;
                }
              }
            if ( nextPP != NULL )
              { // Step onto intersection edge.
              nextEdge = nextPP->NextEdge[AorB];
              nextPnt = nextPP->NewId;
              if ( nextEdge == NULL )
                { // Must be a MERGED pp. Deal with it.
                for ( thisPP=nextPP->Merge; thisPP != nextPP;
                      thisPP=thisPP->Merge )
                   {
                   if ( thisPP == NULL )
                     {
                     abortTri = 1;
                     break;
                     }
                   if ( thisPP->Triangle == thisTri )
                     {
                     nextEdge = thisPP->NextEdge[AorB];
                     nextFrame = NULL;
                     break;
                     }
                   if ( thisPP->Edge->Neighbors[0] == thisTri ||
                        thisPP->Edge->Neighbors[1] == thisTri )
                     {
                     nextEdge = NULL;
                     nextFrame = thisPP->Edge;
                     break;
                     }
                   }
                nextPP = thisPP;
                }
              }
            else
              { // Step onto next frame.
              nextFrame = thisFrame->Next[direction];
              nextEdge = NULL;
              nextPnt = thisFrame->Points[1-direction];
              if ( AorB )
                nextPnt += this->IdOffsetB; // It's on B
              }
            }
          else
            {
            abortTri = 1;
            }
          if ( nextEdge != NULL )
            {
              if ( nextEdge->Neighbors[AorB] != thisTri )
                {
                vtkDebugMacro( << "Walked off tri:" << thisTri->CellId << "\n" );
                abortTri = 3;
                }
              if ( (nextEdge->Flag & flagBit) && nextPnt != startPnt )
                {
                if ( nextEdge->Points[AorB] == startPnt )
                  {
                  nextPnt = startPnt;
                  }
                else
                  {
                  vtkDebugMacro( << "Walked onto old edge on tri:" <<
                                 thisTri->CellId << "\n" );
                  abortTri = 2;
                  }
                }
            }
          thisPP = nextPP;
          thisFrame = nextFrame;
          thisEdge = nextEdge;
          if ( ++loopCount > 2*numEdges )
            abortTri = 4;
          if ( AorB == 0 || nextPnt < this->IdOffsetNew )
            {
            this->ThisLoop->InsertNextId( nextPnt );
            }
          else
            { // Duplicate new points on B to inherit PointData
            bPnt = nextPnt+1;
            this->ThisLoop->InsertNextId( bPnt );
            // Add a 0-length line for connectivity (KLUDGE ALERT)
            this->NewLines->InsertNextCell( 2 );
            this->NewLines->InsertCellPoint( nextPnt );
            this->NewLines->InsertCellPoint( bPnt );
            }
          }while( nextPnt != startPnt && abortTri == 0 );
        if ( !abortTri )
          {
          newLoop = new vtkBoolLoop;
          newLoop->Next = thisTri->NewLoops;
          thisTri->NewLoops = newLoop;
          loopCount = this->ThisLoop->GetNumberOfIds();
          newLoop->Points->SetNumberOfIds( loopCount );
          for ( jj=0; jj<loopCount; jj++ )
            newLoop->Points->SetId( jj, this->ThisLoop->GetId(jj) );
          }
        else
          {
          vtkDebugMacro(<<"aborted Loop on tri:" << thisTri->CellId <<
                                 " " << abortReasons[abortTri] << " " <<
                                 (AorB==0 ? "[A]":"[B]") << "\n" );
          }
        }
      }
    }
  }

void vtkPolyBoolean::AddNewPolygons( vtkBoolTri *thisTri )
  {
  vtkBoolLoop *thisLoop;
  int ii, nPts, nTriangles = 0;
  vtkIdType *tris, outerLoop[3];
  vtkBoolTess *tess = this->Tess;
  int flagBit, addOuterLoop = 0;
  vtkFloatingPointType p0[3], p1[3], xprod[3], areavec[3];

  // Generate new triangles from the loops on this triangle.
  thisLoop = thisTri->NewLoops;
  if ( thisLoop == NULL )
    return;
  // There's a catch: If none of the loops touch the orignal
  // boundary, then they might be holes and the outer contour
  // must be kept. Or, they might be islands cut out of the
  // original contour, which should not be kept.
  flagBit = 2*thisTri->AorB + 2;
  if ( (thisTri->Edges[0]->Flag & flagBit) == 0 &&
       (thisTri->Edges[1]->Flag & flagBit) == 0 &&
       (thisTri->Edges[2]->Flag & flagBit) == 0 )
    { // Outer boundary was uncut. Include it?
    areavec[0] = areavec[1] = areavec[2] = 0.0;
    do {
      nPts = thisLoop->Points->GetNumberOfIds();
      this->NewPoints->GetPoint( thisLoop->Points->GetId(nPts-1), p0 );
      for ( ii=0; ii<nPts; ii++ )
        {
        this->NewPoints->GetPoint( thisLoop->Points->GetId(ii), p1 );
        vtkMath::Cross( p0, p1, xprod );
        areavec[0] += xprod[0];
        areavec[1] += xprod[1];
        areavec[2] += xprod[2];
        p0[0] = p1[0];
        p0[1] = p1[1];
        p0[2] = p1[2];
        }
      thisLoop = thisLoop->Next;
      }while( thisLoop != NULL );
    if ( vtkMath::Dot( areavec, thisTri->Normal ) < 0.0 )
      { // Include the outer boundary
      addOuterLoop = 1;
      for ( ii=0; ii<3; ii++ )
        {
        if ( thisTri->Edges[ii]->Neighbors[0] == thisTri )
          outerLoop[ii] = thisTri->Edges[ii]->Points[0];
        else
          outerLoop[ii] = thisTri->Edges[ii]->Points[1];
        }
      }
    vtkDebugMacro( << "Cut Tri:" << thisTri->CellId << " on " << thisTri->AorB
                   << " has uncut outer boundary "
                   << (addOuterLoop ? "included" : "excluded") );
    }
  thisLoop = thisTri->NewLoops;
  nPts = thisLoop->Points->GetNumberOfIds();
  if ( thisLoop->Next == NULL && nPts == 3 && addOuterLoop == 0 )
    { // Simple Triangle
    this->NewPolys->InsertNextCell( thisLoop->Points );
    }
  else
    { // Must triangulate it first.
    tess->Reset();
    tess->SetPoints( this->NewPoints->GetData()->GetTuple(0) );
    if ( addOuterLoop )
      tess->AddContour( (vtkIdType)3, outerLoop );
    do {
      tess->AddContour( thisLoop->Points->GetNumberOfIds(),
                       thisLoop->Points->GetPointer(0) );
      thisLoop = thisLoop->Next;
      }while( thisLoop != NULL );
    nTriangles = tess->Triangulate( &tris );
    for ( ii=0; ii<nTriangles*3; ii+=3 )
      {
      this->NewPolys->InsertNextCell( 3, &tris[ii] );
      }
    }
  }

void vtkPolyBoolean::SortLoops( vtkBoolTri *thisTri )
  {
  }


#define vtkCELLTRIANGLES(CELLPTIDS, TYPE, IDX, PTID0, PTID1, PTID2) \
    { switch( TYPE ) \
      { \
      case VTK_TRIANGLE: \
      case VTK_POLYGON: \
      case VTK_QUAD: \
        PTID0 = CELLPTIDS[0]; \
        PTID1 = CELLPTIDS[(IDX)+1]; \
        PTID2 = CELLPTIDS[(IDX)+2]; \
        break; \
      case VTK_TRIANGLE_STRIP: \
        PTID0 = CELLPTIDS[IDX]; \
        PTID1 = CELLPTIDS[(IDX)+1+((IDX)&1)]; \
        PTID2 = CELLPTIDS[(IDX)+2-((IDX)&1)]; \
        break; \
      default: \
        PTID0 = PTID1 = PTID2 = -1; \
      } }

void vtkPolyBoolean::AddCellTriangles( vtkIdType cellId, vtkIdType *ptIds, 
                                       int type, vtkIdType numPts, int AorB )
  {
  vtkBoolTri *newTri, *nextTri, **thisTriDirectory, *adjTri;
  int ii, jj, kk, numCells, triPts[3], p0, p1, neighborId, found;
  int invertB = 0;
  vtkPoints *points;
  vtkPolyData *dataset;
  vtkFloatingPointType p[3], q[3], r[3], v0[3], v1[3], *norm;
  vtkIdList *cellNeighbors = vtkIdList::New();
  vtkBoolTriEdge *thisEdge;

  if ( AorB == 0 )
    { // It's A
    dataset = this->GetInput();
    points = (vtkPoints *)this->GetInput()->GetPoints();
    }
  else
    { // It's B
    dataset = this->PolyDataB;
    points = this->BPoints;
    if ( this->Operation == BOOL_A_MINUS_B )
      invertB = 1;
    }

  numCells = dataset->GetNumberOfCells();
  if ( this->TriDirectory[AorB] == NULL )
    {
    this->TriDirectory[AorB] = new vtkBoolTri *[numCells];
    this->CellFlags[AorB] = new int[numCells];
    this->TriDirectorySize[AorB] = numCells;
    if ( AorB == 1 )
      this->CellFlagsB = new int[numCells];
    for ( ii=0; ii<numCells; ii++ )
      {
      this->TriDirectory[AorB][ii] = NULL; // initialize to NULL
      this->CellFlags[AorB][ii] = BOOL_CELL_UNKNOWN;
      if ( AorB == 1 ) // B
        this->CellFlagsB[ii] = 0;
      }
    // trick to build links
    dataset->GetPointCells( ptIds[0], cellNeighbors );
    }

  thisTriDirectory = this->TriDirectory[AorB];
  if ( thisTriDirectory[cellId] == NULL )
    { // Then this cell hasn't been processed yet - do it now.
        for ( ii=0; ii<numPts-2; ii++ )
      {
      newTri = new vtkBoolTri;
      newTri->CellId = cellId;
      newTri->AorB = AorB;

      vtkCELLTRIANGLES( ptIds, type, ii, triPts[0], triPts[1], triPts[2] );
      if ( triPts[0] > -1 )
        {
        nextTri = thisTriDirectory[cellId];
        thisTriDirectory[cellId] = newTri;
        newTri->Next = nextTri;
        if ( invertB )
          { // invertB's triangles
          kk = triPts[1];
          triPts[1] = triPts[2];
          triPts[2] = kk;
          }
        points->GetPoint( triPts[0], p );
        points->GetPoint( triPts[1], r );
        points->GetPoint( triPts[2], q );
        for ( jj=0; jj<3; jj++ )
          {
          v0[jj] = q[jj] - p[jj];
          v1[jj] = r[jj] - p[jj];
          }
        norm = newTri->Normal;
        vtkMath::Cross( v0, v1, norm );
        vtkMath::Normalize( norm );
        newTri->Offset = vtkMath::Dot( norm, p );
        for ( jj=0; jj<3; jj++ )
          {
          p0 = triPts[jj]; p1 = triPts[(jj+1)%3];
          dataset->GetCellEdgeNeighbors( cellId, p0, p1, cellNeighbors );
          thisEdge = NULL;
          if ( cellNeighbors->GetNumberOfIds() == 1 )
            {
            neighborId = cellNeighbors->GetId( 0 );
            adjTri = thisTriDirectory[neighborId];
            if ( adjTri != NULL )
              { // This is the second triangle to use this edge
              found = 0;
              do {
                 for ( kk=0; kk<3 && !found; kk++ )
                   {
                   thisEdge = adjTri->Edges[kk];
                   if ( thisEdge->Points[0] == p1  &&
                        thisEdge->Points[1] == p0 )
                     {
                     found = 1;
                     thisEdge->Neighbors[1] = newTri;
                     }
                   }
                 adjTri = adjTri->Next;
                 } while( adjTri != NULL && !found );
              if ( !found )
                 vtkGenericWarningMacro(<< "Bad Topology Encountered. CellId="
                                        << cellId );
              }
            }
          if ( thisEdge == NULL )
            { // This is the first triangle to use this edge
            thisEdge = new vtkBoolTriEdge; // allocate it.
            thisEdge->Points[0] = p0;
            thisEdge->Points[1] = p1;
            thisEdge->Neighbors[0] = newTri;
            }
          newTri->Edges[jj] = thisEdge;
          }
        }
      for ( jj=0; jj<3; jj++ )
        { // link edge topology
        thisEdge = newTri->Edges[jj];
        if ( thisEdge->Neighbors[0] == newTri )
          thisEdge->Next[0] = newTri->Edges[(jj+1)%3];
        else
          thisEdge->Next[1] = newTri->Edges[(jj+1)%3];
        }
      }
    if ( AorB == 1 )
      this->CellFlagsB[cellId] = this->ExecutionCount;
    }
  else
    { // Make sure the normal and offset is up to date
    if ( AorB == 1 && this->CellFlagsB[cellId] != this->ExecutionCount )
      {
      for ( newTri=thisTriDirectory[cellId]; newTri != NULL; newTri = newTri->Next )
        {
        for ( ii=0; ii<3; ii++ )
          {
          thisEdge = newTri->Edges[ii];
          if ( thisEdge->Neighbors[0] == newTri )
            triPts[ii] = thisEdge->Points[0];
          else
            triPts[ii] = thisEdge->Points[1];
          }
        points->GetPoint( triPts[0], p );
        points->GetPoint( triPts[1], r );
        points->GetPoint( triPts[2], q );
        for ( jj=0; jj<3; jj++ )
          {
          v0[jj] = q[jj] - p[jj];
          v1[jj] = r[jj] - p[jj];
          }
        norm = newTri->Normal;
        vtkMath::Cross( v0, v1, norm );
        vtkMath::Normalize( norm );
        newTri->Offset = vtkMath::Dot( norm, p );
        }
      this->CellFlagsB[cellId] = this->ExecutionCount;
      }
    }
  cellNeighbors->Delete();
  }

void vtkPolyBoolean::BuildBPoints( vtkMatrix4x4 *XformBtoA )
  {
  vtkTransform *Xform = vtkTransform::New();
  int numPts;

  Xform->SetMatrix( XformBtoA );
  numPts = this->PolyDataB->GetNumberOfPoints();
  this->BPoints = vtkPoints::New();
  this->BPoints->Allocate( numPts, 1 );
  Xform->TransformPoints( this->PolyDataB->GetPoints(),
                        this->BPoints );
  Xform->Delete();
  }

vtkBoolLoop::vtkBoolLoop()
  {
  this->Next = NULL;
  this->Points = vtkIdList::New();
  }

vtkBoolLoop::~vtkBoolLoop()
  {
  if ( this->Next ) delete this->Next;
  if ( this->Points ) this->Points->Delete();
  }

vtkBoolTri::vtkBoolTri()
  {
  this->Next = NULL;
  this->CellId = -1;
  this->Edges[0] = this->Edges[1] = this->Edges[2] = NULL;
  this->NewLoops = NULL;
  }

vtkBoolTri::~vtkBoolTri()
  {
  vtkBoolTriEdge *thisEdge;
  int ii;

  for ( ii=0; ii<3; ii++ )
    {
    thisEdge = this->Edges[ii];
    if ( thisEdge->Neighbors[0] == this )
      thisEdge->Neighbors[0] = NULL;
    else
      thisEdge->Neighbors[1] = NULL;
    if ( thisEdge->Neighbors[0] == NULL && thisEdge->Neighbors[1] == NULL )
      {
      thisEdge->DeletePPs();
      delete thisEdge;
      }
    }
  if (this->NewLoops) delete this->NewLoops;
  }

void vtkBoolTriEdge::DeletePPs()
  {
  vtkPiercePoint *thisPP, *nextPP;

  for ( thisPP = this->FirstPP; thisPP != NULL; thisPP = nextPP )
    {
    nextPP = thisPP->Next;
    delete thisPP;
    }
  this->FirstPP = NULL;
  }

vtkBoolTriEdge::vtkBoolTriEdge()
  {
  this->Flag = 0;
  this->Neighbors[0] = this->Neighbors[1] = NULL;
  this->FirstPP = NULL;
  this->PPoints[0] = this->PPoints[1] = NULL;
  this->Points[0] = this->Points[1] = -1;
  this->Next[0] = this->Next[1] = NULL;
  }

vtkBoolTriEdge::~vtkBoolTriEdge()
  {
  }

vtkPiercePoint::vtkPiercePoint()
  {
  this->NewId = -1;
  this->Next = this->Prev = this->Merge = NULL;
  this->NextEdge[0] = this->NextEdge[1] = NULL;
  }

vtkPiercePoint::~vtkPiercePoint()
  {
  }

vtkNewBoolEdges::vtkNewBoolEdges()
  {
  this->Array = NULL;
  this->GrowSize = 100;
  this->Count = 0;
  this->ArraySize = 0;
  }

void vtkNewBoolEdges::AddNewEdge( vtkBoolTriEdge *thisEdge )
  {
  vtkBoolTriEdge **newArray;

  if ( this->Array == NULL )
    {
    this->ArraySize = this->GrowSize;
    this->Array = new vtkBoolTriEdge * [this->ArraySize];
    }
  else
    if ( this->Count == this->ArraySize )
      { // Must relocate.
      this->ArraySize += this->GrowSize;
      newArray = new vtkBoolTriEdge * [this->ArraySize];
      memcpy( newArray, this->Array, this->Count * sizeof( vtkBoolTriEdge *));
      delete [] this->Array;
      this->Array = newArray;
      this->GrowSize += this->GrowSize;
      }
  // Array has been allocated, and there is room.
  this->Array[this->Count++] = thisEdge;
  }

void vtkNewBoolEdges::Reset()
  {
  this->Count = 0;
  }

int vtkNewBoolEdges::GetCount()
  {
  return( this->Count );
  }

void vtkPiercePoint::MergePP( vtkPiercePoint *otherPP )
  {
  // Merged PPs are linked in a ring.
  vtkPiercePoint *nextPP;

  if ( this->Merge == NULL )
    { // Initialize ring structure
    this->Merge = this;
    }
  else
    { // Ensure they haven't already been merged.
    nextPP = this;
    do {
      if ( nextPP == otherPP )
        return;
      } while( (nextPP = nextPP->Merge) != this );
    }
  if ( otherPP->Merge == NULL )
    { // Initialize ring structure
    otherPP->Merge = otherPP;
    }
  // Merge two rings.
  nextPP = this->Merge;
  this->Merge = otherPP->Merge;
  otherPP->Merge = nextPP;
  }

#undef CELLS_PER_BUCKET
