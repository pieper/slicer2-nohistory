/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMultipleStreamlineController.h,v $
  Date:      $Date: 2006/08/15 16:38:32 $
  Version:   $Revision: 1.47 $

=========================================================================auto=*/
// .NAME vtkMultipleStreamlineController - 
// .SECTION Description
// Creates and manages a vtkCollection of vtkHyperStreamlines.
//
// Individual streamlines can be started at a point, or 
// many can be started inside a region of interest.
// Subclasses of vtkHyperStreamline may be created instead
// of the default vtkHyperStreamline class.
// This class also creates collections of mappers and actors
// for the streamlines, and can control their visibility in the scene.
//

#ifndef __vtkMultipleStreamlineController_h
#define __vtkMultipleStreamlineController_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkCollection.h"
#include "vtkTransform.h"
#include "vtkActor.h"
#include "vtkProperty.h"
#include "vtkLookupTable.h"
#include "vtkShortArray.h"
#include "vtkDoubleArray.h"
#include "vtkPolyData.h"
#include "vtkIntArray.h"
#include "vtkCellPicker.h"

#include "vtkClusterTracts.h"
#include "vtkSaveTracts.h"
#include "vtkDisplayTracts.h"
#include "vtkSeedTracts.h"
#include "vtkColorROIFromTracts.h"

class VTK_DTMRI_EXPORT vtkMultipleStreamlineController : public vtkObject
{
 public:
  static vtkMultipleStreamlineController *New();
  vtkTypeMacro(vtkMultipleStreamlineController,vtkObject);

  // Description
  // Delete one streamline.  The input is a pointer to the actor you
  // wish to delete.  This method finds the index and calls DeleteStreamline.
  void DeleteStreamline(vtkCellPicker *picker);

  // Description
  // Delete all streamlines
  void DeleteAllStreamlines();

  // Description
  // Delete a particular streamline. Also calls method in vtkDisplayTracts
  // to delete graphics objects for this streamline.
  void DeleteStreamline(int index);

  // Description
  // Input tensor field in which to seed streamlines
  void SetInputTensorField(vtkImageData *tensorField);
  vtkGetObjectMacro(InputTensorField, vtkImageData);

  // Description
  // Transformation used in seeding/displaying/saving streamlines.  
  // Transforms world coordinates into scaled ijk of the tensor field.
  void SetWorldToTensorScaledIJK(vtkTransform *);
  vtkGetObjectMacro(WorldToTensorScaledIJK, vtkTransform);

  // Description
  // Rotation used when placing tensors in scene (to align with the tracts
  // which are transformed by the inverse of WorldToTensorScaledIJK)
  // Used when saving tensors along tract paths.
  void SetTensorRotationMatrix(vtkMatrix4x4 *trans);

  // Description
  // List of the output vtkHyperStreamlines (or subclasses)
  // These are what you see (could be clipped by the user)
  vtkCollection *GetClippedStreamlines() {return this->DisplayTracts->GetClippedStreamlinesGroup();}

  // Description
  // List of the output vtkHyperStreamlines (or subclasses)
  vtkGetObjectMacro(Streamlines, vtkCollection);

  // Description
  // Number of streamlines that exist
  int GetNumberOfStreamlines() {return this->Streamlines->GetNumberOfItems();}

  // Description
  // Input: list of the renderers whose scenes will have streamlines
  // added.
  void SetInputRenderers( vtkCollection *);
  vtkGetObjectMacro(InputRenderers, vtkCollection);

  // Description
  // Color tracts based on clustering.
  // Colors the paths that have already been created using this class.
  // The argument (int tmp) is only there because under windows the 
  // wrapping failed with no argument.
  void ClusterTracts(int tmp);

  // Description
  // Get object that performs clustering (to set parameters)
  vtkGetObjectMacro(TractClusterer,vtkClusterTracts);

  // Description
  // Get object that performs saving (to set parameters)
  vtkGetObjectMacro(SaveTracts,vtkSaveTracts);

  // Description
  // Get object that performs seeding (to set parameters)
  vtkGetObjectMacro(SeedTracts,vtkSeedTracts);

  // Description
  // Get object that performs display (to set parameters)
  vtkGetObjectMacro(DisplayTracts,vtkDisplayTracts);

  // Description
  // Get object that colors in an ROI with color of tracts passing
  // through the ROI.
  vtkGetObjectMacro(ColorROIFromTracts,vtkColorROIFromTracts);

 protected:
  vtkMultipleStreamlineController();
  ~vtkMultipleStreamlineController();

  vtkTransform *WorldToTensorScaledIJK;

  vtkImageData *InputTensorField;
  vtkCollection *InputRenderers;

  vtkCollection *Streamlines;

  // Remove 0-length streamlines before clustering.
  void CleanStreamlines(vtkCollection *streamlines);
  vtkClusterTracts *TractClusterer;

  vtkSaveTracts *SaveTracts;
  vtkDisplayTracts *DisplayTracts;
  vtkSeedTracts *SeedTracts;
  vtkColorROIFromTracts *ColorROIFromTracts;


};

#endif
