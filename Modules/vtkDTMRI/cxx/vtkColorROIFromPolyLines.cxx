/*=auto=========================================================================

Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

See Doc/copyright/copyright.txt
or http://www.slicer.org/copyright/copyright.txt for details.

Program:   3D Slicer
Module:    $RCSfile: vtkColorROIFromPolyLines.cxx,v $
Date:      $Date: 2007/08/07 20:12:20 $
Version:   $Revision: 1.3 $

=========================================================================auto=*/

#include "vtkColorROIFromPolyLines.h"
#include "vtkActor.h"
#include "vtkProperty.h"
#include "vtkPolyData.h"
#include "vtkPolyDataSource.h"
#include "vtkCell.h"
#include <vector>

//------------------------------------------------------------------------------
vtkColorROIFromPolyLines* vtkColorROIFromPolyLines::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkColorROIFromPolyLines");
  if(ret)
    {
      return (vtkColorROIFromPolyLines*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkColorROIFromPolyLines;
}

//----------------------------------------------------------------------------
vtkColorROIFromPolyLines::vtkColorROIFromPolyLines()
{

  this->InputROIForColoring = NULL;
  this->OutputROIForColoring = NULL;
  this->OutputMaxFiberCount = NULL;
  this->PolyLineClusters = NULL;
  this->Labels = NULL;

  // Init these to identity in case the user does not set them
  this->WorldToTensorScaledIJK = vtkTransform::New();
  this->ROIToWorld = vtkTransform::New();
}

//----------------------------------------------------------------------------
vtkColorROIFromPolyLines::~vtkColorROIFromPolyLines()
{

  if (this->InputROIForColoring != NULL)
    this->InputROIForColoring->Delete();
  if (this->OutputROIForColoring != NULL)
    this->OutputROIForColoring->Delete();
  if (this->OutputMaxFiberCount != NULL)
    this->OutputMaxFiberCount->Delete();
  if (this->PolyLineClusters != NULL)
    this->PolyLineClusters->Delete();
  if (this->Labels != NULL)
    this->Labels->Delete();
  if (this->WorldToTensorScaledIJK != NULL)
    this->WorldToTensorScaledIJK->Delete();
  if (this->ROIToWorld != NULL)
    this->ROIToWorld->Delete();
}




// Color in volume with color ID of streamline passing through it.
//----------------------------------------------------------------------------
void vtkColorROIFromPolyLines::ColorROIFromStreamlines()
{

  if (this->InputROIForColoring == NULL)
    {
      vtkErrorMacro("No ROI input.");
      return;      
    }

  if (this->Labels == NULL)
    {
      vtkErrorMacro("No Labels input.");
      return;      
    }
  
  // make sure it is short type
  if (this->InputROIForColoring->GetScalarType() != VTK_SHORT)
    {
      vtkErrorMacro("Input ROI is not of type VTK_SHORT");
      return;      
    }
  
  // prepare to traverse streamline collection
  this->PolyLineClusters->InitTraversal();
  vtkPolyData *currCluster = 
    dynamic_cast<vtkPolyData *> (this->PolyLineClusters->GetNextItemAsObject());
  
  // test we have streamlines
  if (currCluster == NULL)
    {
      vtkErrorMacro("No streamlines have been created yet.");
      return;      
    }
  
  // Create output
  if (this->OutputROIForColoring != NULL)
    this->OutputROIForColoring->Delete();
  this->OutputROIForColoring = vtkImageData::New();

  // Start with some defaults.
  this->OutputROIForColoring->CopyTypeSpecificInformation( this->InputROIForColoring );
  this->OutputROIForColoring->SetExtent(this->InputROIForColoring->GetWholeExtent());
  this->OutputROIForColoring->AllocateScalars();

  // Create scratch space for counting current tract paths in a voxel
  vtkImageData *currentPathCount = vtkImageData::New();
  currentPathCount->CopyTypeSpecificInformation( this->InputROIForColoring );
  currentPathCount->SetExtent(this->InputROIForColoring->GetWholeExtent());
  currentPathCount->AllocateScalars();

 // Create output for saving max # of tract paths in a voxel
  if (this->OutputMaxFiberCount != NULL)
    this->OutputMaxFiberCount->Delete();
  this->OutputMaxFiberCount = vtkImageData::New();
  vtkImageData *maxPathCount = this->OutputMaxFiberCount;
  maxPathCount->CopyTypeSpecificInformation( this->InputROIForColoring );
  maxPathCount->SetExtent(this->InputROIForColoring->GetWholeExtent());
  maxPathCount->AllocateScalars();

  // initialize output volume to all 0's
  int dims[3];
  this->OutputROIForColoring->GetDimensions(dims);
  int size = dims[0]*dims[1]*dims[2];
  short *outPtr = (short *) this->OutputROIForColoring->GetScalarPointer();
  short *maxPathCountPtr = (short *) maxPathCount->GetScalarPointer();
  for(int i=0; i<size; i++)
    {
      *outPtr = (short) 0;
      outPtr++;

      *maxPathCountPtr = (short) 0;
      maxPathCountPtr++;
    }


  // Create transformation matrices to go backwards from streamline points to ROI space
  vtkTransform *WorldToROI = vtkTransform::New();
  WorldToROI->SetMatrix(this->ROIToWorld->GetMatrix());
  WorldToROI->Inverse();
  vtkTransform *TensorScaledIJKToWorld = vtkTransform::New();
  TensorScaledIJKToWorld->SetMatrix(this->WorldToTensorScaledIJK->GetMatrix());
  TensorScaledIJKToWorld->Inverse();


  // Loop over clusters of polylines
  int clusterIndex = 0;
  while (currCluster)
    {
    // initialize current cluster path count output volume to all 0's
    short *currentPathCountPtr1 = (short *) currentPathCount->GetScalarPointer();
    for(int i=0; i<size; i++)
      {
      *currentPathCountPtr1 = (short) 0;
      currentPathCountPtr1++;
      }

      int numberOfPaths = currCluster->GetNumberOfCells();

      // Loop over all paths in this cluster
      for (int pathIdx = 0; pathIdx < numberOfPaths; pathIdx++)
        {
          
          // Make sure this one is a line.
          //if (currCluster->GetCell(pathIdx)->GetCellType() == VTK_LINE)
          //{
                  
              // for each point on the path, test
              // the nearest voxel for path/ROI intersection.
              vtkPoints * hs = 
                currCluster->GetCell(pathIdx)->GetPoints();
                  
              // Change this if one line per path:
              // the seed point is the first point on each pair of paths,
              // don't count it twice.
              int ptidx=0;
              if (fmod(pathIdx,2.0) == 0) 
                ptidx = 1;
                  
              int pt[3];
              double point[3], point2[3];
              for (ptidx = 0; ptidx < hs->GetNumberOfPoints(); ptidx++)
                {
                  hs->GetPoint(ptidx,point);
                  // First transform to world space.
                  TensorScaledIJKToWorld->TransformPoint(point,point2);
                  // Now transform to ROI IJK space
                  WorldToROI->TransformPoint(point2,point);
                  // Find that voxel number
                  pt[0]= (int) floor(point[0]+0.5);
                  pt[1]= (int) floor(point[1]+0.5);
                  pt[2]= (int) floor(point[2]+0.5);
                      
                  short *tmp = (short *) this->InputROIForColoring->GetScalarPointer(pt);

                  // if we are inside the volume
                  if (tmp != NULL)
                    {
                      // if we are in the ROI to be colored 
                      if (*tmp > 0) {

                        // increment the path count
                        //tmp = (short *) this->OutputROIForColoring->GetScalarPointer(pt);
                        //*tmp = (short) (currColor + 1);
                        tmp = (short *) currentPathCount->GetScalarPointer(pt);
                        *tmp = *tmp + 1;
                      }
                    }

                } // end loop over points on path

              //} // end if it's a line

        } // end loop over paths in cluster

      
      // Now we have counted all paths from this cluster, check where it is 
      // max so far (voxels with the highest number of paths from this cluster).
      // In these locations, set the max to this count and also the output
      // color to the current color.
      short *outPtr = (short *) this->OutputROIForColoring->GetScalarPointer();
      short *currentPathCountPtr = (short *) currentPathCount->GetScalarPointer();
      short *maxPathCountPtr = (short *) maxPathCount->GetScalarPointer();
      for(int i=0; i<size; i++)
        {
          if (*currentPathCountPtr > *maxPathCountPtr)
            {
              *maxPathCountPtr = *currentPathCountPtr;
              *outPtr = (short) this->Labels->GetValue(clusterIndex);
            }

          // testing
          //*outPtr = *currentPathCountPtr;
      
          currentPathCountPtr++;
          maxPathCountPtr++;
          outPtr++;      
        }    

      // Get the next cluster
      currCluster = dynamic_cast<vtkPolyData *> 
        (this->PolyLineClusters->GetNextItemAsObject());
      
      clusterIndex++;

    }

  // Delete scratch space
  currentPathCount->Delete();

}



