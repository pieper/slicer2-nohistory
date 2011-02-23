/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMultipleStreamlineController.cxx,v $
  Date:      $Date: 2007/03/19 14:35:22 $
  Version:   $Revision: 1.74 $

=========================================================================auto=*/
#include "vtkMultipleStreamlineController.h"
#include "vtkLookupTable.h"
#include "vtkRenderer.h"
#include "vtkFloatArray.h"
#include "vtkPointData.h"

#include "vtkHyperStreamline.h"

#include <sstream>

#include "vtkPolyDataMapper.h"

//------------------------------------------------------------------------------
vtkMultipleStreamlineController* vtkMultipleStreamlineController::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMultipleStreamlineController");
  if(ret)
    {
      return (vtkMultipleStreamlineController*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkMultipleStreamlineController;
}

//----------------------------------------------------------------------------
vtkMultipleStreamlineController::vtkMultipleStreamlineController()
{
  // Initialize these to identity, so if the user doesn't set them it's okay.
  this->WorldToTensorScaledIJK = vtkTransform::New();

  // The user must set these for the class to function.
  this->InputTensorField = NULL;
  this->InputRenderers = vtkCollection::New();
  
  // collections
  this->Streamlines = vtkCollection::New();

  // Helper classes
  // ---------------

  // for tract clustering
  this->TractClusterer = vtkClusterTracts::New();

  // for tract saving
  this->SaveTracts = vtkSaveTracts::New();

  // for tract display
  this->DisplayTracts = vtkDisplayTracts::New();

  // for creating tracts
  this->SeedTracts = vtkSeedTracts::New();

  // for coloring an ROI based on tract color
  this->ColorROIFromTracts = vtkColorROIFromTracts::New();

  // Helper class pipelines
  // ----------------------

  this->SeedTracts->SetStreamlines(this->Streamlines);

  this->DisplayTracts->SetStreamlines(this->Streamlines);

  this->SaveTracts->SetStreamlines(this->DisplayTracts->GetClippedStreamlinesGroup());
  this->SaveTracts->SetTubeFilters(this->DisplayTracts->GetTubeFiltersGroup());
  this->SaveTracts->SetDisplay(this->DisplayTracts);

  this->ColorROIFromTracts->SetStreamlines(this->DisplayTracts->GetClippedStreamlinesGroup());
  this->ColorROIFromTracts->SetActors(this->DisplayTracts->GetActors());
}

//----------------------------------------------------------------------------
vtkMultipleStreamlineController::~vtkMultipleStreamlineController()
{
  this->DeleteAllStreamlines();

  this->Streamlines->Delete();

  this->WorldToTensorScaledIJK->Delete();
  if (this->InputTensorField) this->InputTensorField->Delete();

  this->InputRenderers->Delete();

  // delete helper classes
  this->TractClusterer->Delete();
  this->SaveTracts->Delete();  
  this->SeedTracts->Delete();  
  this->DisplayTracts->Delete();  
  this->ColorROIFromTracts->Delete(); 
}


//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::SetInputTensorField(vtkImageData *tensorField)
{
  
  vtkDebugMacro("Setting input tensor field.");

  // Decrease reference count of old object
  if (this->InputTensorField != 0)
    this->InputTensorField->UnRegister(this);

  // Set new value in this class
  this->InputTensorField = tensorField;

  // Increase reference count of new object
  if (this->InputTensorField != 0)
    this->InputTensorField->Register(this);

  // This class has changed
  this->Modified();

  // helper class pipelines
  // ----------------------
  this->SaveTracts->SetInputTensorField(this->InputTensorField);
  this->SeedTracts->SetInputTensorField(this->InputTensorField);

}

//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::SetInputRenderers(vtkCollection *renderers)
{
  
  vtkDebugMacro("Setting input renderers.");

  // Decrease reference count of old object
  if (this->InputRenderers != 0)
    this->InputRenderers->UnRegister(this);

  // Set new value in this class
  this->InputRenderers = renderers;

  // Increase reference count of new object
  if (this->InputRenderers != 0)
    this->InputRenderers->Register(this);

  // This class has changed
  this->Modified();

  // helper class pipelines
  // ----------------------
  this->DisplayTracts->SetRenderers(this->InputRenderers);

}

//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::SetWorldToTensorScaledIJK(vtkTransform *trans)
{
  
  vtkDebugMacro("Setting WorldToTensorScaledIJK.");

  // Decrease reference count of old object
  if (this->WorldToTensorScaledIJK != 0)
    this->WorldToTensorScaledIJK->UnRegister(this);

  // Set new value in this class
  this->WorldToTensorScaledIJK = trans;

  // Increase reference count of new object
  if (this->WorldToTensorScaledIJK != 0)
    this->WorldToTensorScaledIJK->Register(this);

  // This class has changed
  this->Modified();

  // helper class pipelines
  // ----------------------
  this->SaveTracts->SetWorldToTensorScaledIJK(this->WorldToTensorScaledIJK);
  this->SeedTracts->SetWorldToTensorScaledIJK(this->WorldToTensorScaledIJK);
  this->DisplayTracts->SetWorldToTensorScaledIJK(this->WorldToTensorScaledIJK);
  this->ColorROIFromTracts->SetWorldToTensorScaledIJK(this->WorldToTensorScaledIJK);
}

//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::SetTensorRotationMatrix(vtkMatrix4x4 *trans)
{

  // helper class pipelines
  // ----------------------
  this->SaveTracts->SetTensorRotationMatrix(trans);

  this->SeedTracts->SetTensorRotationMatrix(trans);
}


//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::DeleteAllStreamlines()
{
  int numStreamlines, i;

  i=0;
  numStreamlines = this->Streamlines->GetNumberOfItems();
  while (i < numStreamlines)
    {
      vtkDebugMacro( << "Deleting streamline " << i);
      // always delete the first streamline from the collections
      // (they change size as we do this, shrinking away)
      this->DeleteStreamline(0);
      i++;
    }
  
}

// Delete one streamline and all of its associated objects.
// Here we delete the actual vtkHyperStreamline subclass object.
// We call helper class DeleteStreamline functions in order
// to get rid of (for example) graphics display objects.
//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::DeleteStreamline(int index)
{
  vtkHyperStreamline *currStreamline;
  int groupIndex, indexInGroup;
  // Helper class
  // Delete display (actor, mapper)
  vtkDebugMacro( << "Calling DisplayTracts DeleteStreamline" );
  currStreamline = (vtkHyperStreamline *)
    this->Streamlines->GetItemAsObject(index);
  this->DisplayTracts->FindStreamline(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
     //vtkWarningMacro( <<" Fiber not found. Impossible to delete");
     return;
  }

  this->DisplayTracts->DeleteStreamlineInGroup(groupIndex,indexInGroup);

  // Delete actual streamline
  vtkDebugMacro( << "Delete stream" );

  if (currStreamline != NULL)
    {
      this->Streamlines->RemoveItem(index);
      currStreamline->Delete();
    }

  vtkDebugMacro( << "Done deleting streamline");

}

// This is the delete called from the user interface where the
// actor has been picked with the mouse.
//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::DeleteStreamline(vtkCellPicker *picker)
{
  int index,groupIndex,indexInGroup;
  vtkHyperStreamline *currStreamline;

  // Find streamline querying vtkDisplayTracts
  this->DisplayTracts->FindStreamline(picker,groupIndex,indexInGroup);
 
  // If found, delete fiber from vtkDisplay Tracts
  if (groupIndex == -1 || indexInGroup == -1) {
     vtkWarningMacro( <<" Fiber not found. Impossible to delete");
     return;
  }
  
  currStreamline= (vtkHyperStreamline *)
  this->DisplayTracts->GetStreamlineInGroup(groupIndex,indexInGroup);

  this->DisplayTracts->DeleteStreamlineInGroup(groupIndex,indexInGroup);

 // Delete actual streamline
  vtkDebugMacro( << "Delete stream" );
  if (currStreamline != NULL)
    {
      // index return by IsItemPresent is 1-based.
      index = this->Streamlines->IsItemPresent(currStreamline);
      if (index > 0) {
         this->Streamlines->RemoveItem(index-1);
         currStreamline->Delete();
      }
    }
}

// Call the tract clustering object, and then color our hyperstreamlines
// according to their cluster numbers.
//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::ClusterTracts(int tmp)
{
  //vtkCollection *streamlines = this->Streamlines;
  vtkCollection *streamlines = this->DisplayTracts->GetClippedStreamlines();
  //vtkCollection *streamlines = NULL;

  if (streamlines == 0)
    {
      vtkErrorMacro("Streamlines are NULL.");
      return;      
    }

  if (streamlines->GetNumberOfItems() < 1)
    {
      vtkErrorMacro("No streamlines exist.");
      return;      
    }

  // First make sure none of the streamlines have 0 length
  this->CleanStreamlines(streamlines);

  // Get new flat array of clipped streamlines after cleaning.
  streamlines = this->DisplayTracts->GetClippedStreamlines();

  int numberOfClusters= this->TractClusterer->GetNumberOfClusters();

  this->TractClusterer->SetInputStreamlines(streamlines);
  this->TractClusterer->ComputeClusters();

  vtkClusterTracts::OutputType *clusters =  this->TractClusterer->GetOutput();

  if (clusters == 0)
    {
      vtkErrorMacro("Error: clusters have not been computed.");
      return;      
    }

  // Color tracts based on class membership...
  vtkLookupTable *lut = vtkLookupTable::New();
  lut->SetTableRange (0, numberOfClusters-1);
  lut->SetNumberOfTableValues (numberOfClusters);
  lut->Build();

  double rgb[3];
//  vtkPolyDataMapper *currMapper;
  vtkHyperStreamline *currStreamline;
  for (int idx = 0; idx < clusters->GetNumberOfTuples(); idx++)
    {
      vtkDebugMacro("index = " << idx << "class label = " << clusters->GetValue(idx));
      
      currStreamline = (vtkHyperStreamline *) this->DisplayTracts->GetStreamlines()->GetItemAsObject(idx);

      if (currStreamline) 
        {
          lut->GetColor(clusters->GetValue(idx),rgb);
          vtkDebugMacro("rgb " << rgb[0] << " " << rgb[1] << " " << rgb[2]);
          this->DisplayTracts->SetStreamlineRGB(currStreamline,(unsigned char) (rgb[0]*255), (unsigned char) (rgb[1]*255), (unsigned char) (rgb[2]*255));
        }
      else
        {
          vtkErrorMacro("Classified actor " << idx << " not found.");
        }
    }

  // Set mapper to ScalarVisibility = 0
  this->DisplayTracts->SetScalarVisibility(0);
  //for (int idx =0; idx <this->DisplayTracts->GetMappers()->GetNumberOfItems(); idx++) 
  //  {
  //    currMapper = (vtkPolyDataMapper *) this->DisplayTracts->GetMappers()->GetItemAsObject(idx);
  //    currMapper->SetScalarVisibility(0);
  // }
}

// Remove any streamlines with 0 length
//----------------------------------------------------------------------------
void vtkMultipleStreamlineController::CleanStreamlines(vtkCollection *streamlines)
{
  int numStreamlines, index;
  vtkPolyDataSource *currStreamline;



  numStreamlines = streamlines->GetNumberOfItems();
  index = 0;
  for (int i = 0; i < numStreamlines; i++)
    {
      vtkDebugMacro( << "Cleaning streamline " << i << " : " << index);

      // Get the streamline
      currStreamline = (vtkPolyDataSource *) 
        streamlines->GetItemAsObject(index);

      if (currStreamline == NULL)
        {
          vtkErrorMacro( "No streamline " << index);
          return;
        }

      vtkDebugMacro( "streamline " << i << "length " << 
                     currStreamline->GetOutput()->GetNumberOfPoints());

      if (currStreamline->GetOutput()->GetNumberOfPoints() < 5)
        {
          vtkErrorMacro( "Remove short streamline " << i << "length " << 
                         currStreamline->GetOutput()->GetNumberOfPoints());
          // Delete the streamline from the collections
          this->DeleteStreamline(index);
        }
      else
        {
          // Only increment if we haven't deleted one (and shortened the list)
          index++;
        }

    }

}


