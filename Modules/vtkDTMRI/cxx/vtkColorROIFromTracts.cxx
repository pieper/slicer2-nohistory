/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkColorROIFromTracts.cxx,v $
  Date:      $Date: 2006/01/06 17:57:25 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

#include "vtkColorROIFromTracts.h"
#include "vtkActor.h"
#include "vtkProperty.h"
#include "vtkPolyData.h"
#include "vtkPolyDataSource.h"
#include "vtkCell.h"
#include <vector>

//------------------------------------------------------------------------------
vtkColorROIFromTracts* vtkColorROIFromTracts::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkColorROIFromTracts");
  if(ret)
    {
      return (vtkColorROIFromTracts*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkColorROIFromTracts;
}

//----------------------------------------------------------------------------
vtkColorROIFromTracts::vtkColorROIFromTracts()
{

  this->InputROIForColoring = NULL;
  this->OutputROIForColoring = NULL;
  this->Streamlines = NULL;
  this->Actors = NULL;
  this->WorldToTensorScaledIJK = NULL;
  this->ROIToWorld = NULL;
}

//----------------------------------------------------------------------------
vtkColorROIFromTracts::~vtkColorROIFromTracts()
{


}




// Color in volume with color ID of streamline passing through it.
// Note: currently does not handle multiple streamlines per voxel
// (chooses last to pass through).
// Note: currently IDs are assigned in order of colors on streamline list.
// This should be changed to use internal color IDs when we have those.
//----------------------------------------------------------------------------
void vtkColorROIFromTracts::ColorROIFromStreamlines()
{

  if (this->InputROIForColoring == NULL)
    {
      vtkErrorMacro("No ROI input.");
      return;      
    }
  
  // make sure it is short type
  if (this->InputROIForColoring->GetScalarType() != VTK_SHORT)
    {
      vtkErrorMacro("Input ROI is not of type VTK_SHORT");
      return;      
    }
  
  // prepare to traverse streamline collection
  this->Streamlines->InitTraversal();
  vtkPolyDataSource *currStreamline = 
    dynamic_cast<vtkPolyDataSource *> (this->Streamlines->GetNextItemAsObject());
  
  // test we have streamlines
  if (currStreamline == NULL)
    {
      vtkErrorMacro("No streamlines have been created yet.");
      return;      
    }
  
  this->Actors->InitTraversal();
  vtkActor *currActor= (vtkActor *)this->Actors->GetNextItemAsObject();
  
  // test we have actors and streamlines
  if (currActor == NULL)
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

  // Create scratch space for saving max # of tract paths in a voxel
  vtkImageData *maxPathCount = vtkImageData::New();
  maxPathCount->CopyTypeSpecificInformation( this->InputROIForColoring );
  maxPathCount->SetExtent(this->InputROIForColoring->GetWholeExtent());
  maxPathCount->AllocateScalars();

  // initialize to all 0's
  int dims[3];
  this->OutputROIForColoring->GetDimensions(dims);
  int size = dims[0]*dims[1]*dims[2];
  short *outPtr = (short *) this->OutputROIForColoring->GetScalarPointer();
  short *currentPathCountPtr = (short *) currentPathCount->GetScalarPointer();
  short *maxPathCountPtr = (short *) maxPathCount->GetScalarPointer();
  for(int i=0; i<size; i++)
    {
      *outPtr = (short) 0;
      outPtr++;

      *currentPathCountPtr = (short) 0;
      currentPathCountPtr++;

      *maxPathCountPtr = (short) 0;
      maxPathCountPtr++;
    }


  // Create transformation matrices to go backwards from streamline points to ROI space
  // This is used to access ROIForColoring, it has to have same 
  // dimensions and location as seeding ROI for now.
  vtkTransform *WorldToROI = vtkTransform::New();
  WorldToROI->SetMatrix(this->ROIToWorld->GetMatrix());
  WorldToROI->Inverse();
  vtkTransform *TensorScaledIJKToWorld = vtkTransform::New();
  TensorScaledIJKToWorld->SetMatrix(this->WorldToTensorScaledIJK->GetMatrix());
  TensorScaledIJKToWorld->Inverse();
  
  // init color IDs with the first streamline.
  double rgb[3];
  currActor->GetProperty()->GetColor(rgb);
  double R[1000], G[1000], B[1000];
  int arraySize=1000;
  int lastColor = 0;
  int currColor, newColor;
  R[0]=rgb[0];
  G[0]=rgb[1];
  B[0]=rgb[2];
  
  // testing
  //double spacing[3];
  //this->OutputROIForColoring->GetSpacing(spacing);


  // make color id array (each path has a color ID)
  std::vector<int> colorIDs;
  colorIDs.resize(this->Streamlines->GetNumberOfItems());
  int tractIdx = 0;
  while(currActor)
    {    
      currColor=0;
      newColor=1;
      // If we have this color already, store its index in currColor
      while (currColor<=lastColor && currColor<arraySize)
        {
          currActor->GetProperty()->GetColor(rgb);
          if (rgb[0]==R[currColor] &&
              rgb[1]==G[currColor] &&
              rgb[2]==B[currColor])
            {
              newColor=0;
              break;
            }
          currColor++;
        }
      
      if (newColor)
        {
          // increment count of colors
          lastColor=currColor;
          // save this color's info in the array
          R[currColor]=rgb[0];
          G[currColor]=rgb[1];
          B[currColor]=rgb[2];
        }
      // now currColor is set to this color's index, which we will
      // use to label voxels
      colorIDs[tractIdx] = currColor;
      currActor = (vtkActor *) this->Actors->GetNextItemAsObject();
      tractIdx++;
    }
      

  // Loop over colors
  for (int colorIdx = 0; colorIdx <= lastColor; colorIdx++) 
    {

      // find paths of current color
      this->Streamlines->InitTraversal();
      currStreamline = (vtkPolyDataSource *) this->Streamlines->GetNextItemAsObject();
      tractIdx = 0;

      while (currStreamline)
        {
          
          if (colorIDs[tractIdx] == colorIdx)
            {

              // Loop over the two paths out from the start point
              for (int pathIdx = 0; pathIdx < 2; pathIdx++)
                {
                  
                  // for each point on the path, test
                  // the nearest voxel for path/ROI intersection.
                  vtkPoints * hs = 
                    currStreamline->GetOutput()->GetCell(pathIdx)->GetPoints();
                  
                  // the seed point is the first point on both paths,
                  // don't count it twice.
                  int ptidx=0;
                  if (pathIdx == 1) 
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
                      
                      //pt[0]= (int) floor(point[0]/spacing[0]+0.5);
                      //pt[1]= (int) floor(point[1]/spacing[1]+0.5);
                      //pt[2]= (int) floor(point[2]/spacing[2]+0.5);
                      
                      short *tmp = (short *) this->InputROIForColoring->GetScalarPointer(pt);
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
                } // end loop over tracking directions 0 and 1
            } // end if path color is the right one

          // Get the streamline
          currStreamline = (vtkPolyDataSource *) this->Streamlines->GetNextItemAsObject();
          tractIdx++;

        } // end loop over all paths in this color
      
      // Now we have counted all paths of this color, check where it is 
      // max so far (voxels with the most paths from this color).
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
              *outPtr = colorIdx + 1;
            }
          //*outPtr = *currentPathCountPtr;
          
          currentPathCountPtr++;
          maxPathCountPtr++;
          outPtr++;      
        }    


    } // end loop over all colors

  // Delete scratch space
  currentPathCount->Delete();
  maxPathCount->Delete();

}



