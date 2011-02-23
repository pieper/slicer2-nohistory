/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDisplayTracts.h,v $
  Date:      $Date: 2006/12/06 00:16:56 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
// .NAME vtkDisplayTracts - 
// .SECTION Description
// Displays a vtkCollection of vtkHyperStreamlines.
//
//

#ifndef __vtkDisplayTracts_h
#define __vtkDisplayTracts_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkCollection.h"
#include "vtkTransform.h"
#include "vtkActor.h"
#include "vtkPolyDataMapper.h"
#include "vtkProperty.h"
#include "vtkLookupTable.h"
#include "vtkImplicitFunction.h"
#include "vtkHyperStreamline.h"
#include "vtkCellPicker.h"
#include "vtkAppendPolyData.h"
// for next vtk version:
//#include "vtkPolyDataAlgorithm.h"
#include "vtkPolyDataSource.h"

class VTK_DTMRI_EXPORT vtkDisplayTracts : public vtkObject
{
 public:
  static vtkDisplayTracts *New();
  vtkTypeMacro(vtkDisplayTracts,vtkObject);

  // Description
  // Set the streamlines that we would like to visualize
  vtkGetObjectMacro(Streamlines, vtkCollection);
  vtkSetObjectMacro(Streamlines, vtkCollection);

  // Description
  // Number of sides of the tube displayed around each (hyper)streamline
  vtkGetMacro(TubeNumberOfSides, unsigned int);
  vtkSetMacro(TubeNumberOfSides, unsigned int);

  // Description
  // Radius of the tube displayed around each (hyper)streamline
  vtkGetMacro(TubeRadius, float);
  vtkSetMacro(TubeRadius, float);

  // Description
  // Update NumberOfSides and Radius in all tube filters.
  // The default behavior is just to apply radius/sides to newly created
  // tracts, so changes are only seen in new ones.  
  // Use this after changing TubeNumberOfSides or TubeRadius to apply 
  // to all existing tract paths.
  void UpdateAllTubeFiltersWithCurrentSettings();

  // Description
  // Transformation that was used in seeding streamlines.  Their start
  // points are specified in the coordinate system of the ROI volume.
  // Transform world coordinates into scaled ijk of the tensor field.
  // This transform is needed to display streamlines in world
  // coordinates (thogh they are calculated in tensor scaled ijk)
  vtkSetObjectMacro(WorldToTensorScaledIJK, vtkTransform);
  vtkGetObjectMacro(WorldToTensorScaledIJK, vtkTransform);

  // Description
  // Make all of the streamlines visible in the renderer.
  void AddStreamlinesToScene();

  // Description
  // Hide all streamlines (turn off their visibility);
  void RemoveStreamlinesFromScene();

  // Description
  // Delete one streamline.  The input is a pointer to the actor you
  // wish to delete.  All associated objects are deleted and removed 
  // from the collections.
  void DeleteStreamline(vtkCellPicker *picker);

  // Description
  // Delete all streamlines
  void DeleteAllStreamlines();

  // Description
  // Delete streamlines in group
  void DeleteAllStreamlinesInGroup(int groupindex);

  // Description
  // Delete streamline "index" in group "groupindex"
  void DeleteStreamlineInGroup(int groupindex, int index);

  // Description
  // Get the internal index of picked streamline for a given group.
  //
  int GetStreamlineIndexFromActor(int groupindex,vtkCellPicker *picker);

  // Description
  // Get the group index of the the chosen actor, if it is a streamline
  // in the collection.
  int GetStreamlineGroupIndexFromActor (vtkActor *pickedActor);

  // Description
  // Get the streamline for a given group index and index in the group
  vtkHyperStreamline* GetStreamlineInGroup(int groupIndex, int indexInGroup);

  // Description:
  // Find the group index and index inside the group for a given streamline
  void FindStreamline(vtkHyperStreamline *currStreamline, int & groupIndex, int & indexInGroup);

  // Description:
  // Find the index inside the group of a given streamline whose group index is known
  void FindStreamlineInGroup(vtkHyperStreamline *currStreamline, int groupIndex, int & indexInGroup);

   // Description
  // Find the group index and index inside the group for a given streamline
  void FindStreamline(vtkCellPicker *picker, int & groupIndex, int & indexInGroup);

  void FindStreamlineInGroup(vtkCellPicker *picker, int groupIndex, int & indexInGroup);

  // Description
  // Set/Get the color (RGBA) of a given streamline
  void SetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char RGBA[4]);
  void SetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char R, unsigned char G, unsigned char B, unsigned char A);
  void GetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char RGBA[4]);
  void GetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char &R, unsigned char &G, unsigned char &B, unsigned char &A);

  void SetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char R, unsigned char G, unsigned char B);
  void SetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char RGB[3]);
  void GetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char RGB[3]);
  void GetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char &R, unsigned char &G, unsigned char &B);

  void SetStreamlineOpacity(vtkHyperStreamline *currStreamline, unsigned char opacity);
  void GetStreamlineOpacity(vtkHyperStreamline *currStreamline, unsigned char &opacity);

  // Description
  // Set/Get color of a given streamline when the Display group is known
  void SetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char RGBA[4]);
  void SetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char R, unsigned char G, unsigned char B, unsigned char A);
  void GetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char RGBA[4]);
  void GetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char &R, unsigned char &G, unsigned char &B, unsigned char &A);

  void SetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char R, unsigned char G, unsigned char B);
  void SetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char RGB[3]);
  void GetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char RGB[3]);
  void GetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline,int groupIndex, unsigned char &R, unsigned char &G, unsigned char &B);

  void SetStreamlineOpacityInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char opacity);
  void GetStreamlineOpacityInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char &opacity);

  // Description
  // List of the output graphics objects
  vtkGetObjectMacro(Actors, vtkCollection);
  vtkGetObjectMacro(Mappers, vtkCollection);
  vtkGetObjectMacro(AppendFilters, vtkCollection);

  // Description
  // List of the output group objects
  vtkGetObjectMacro(TubeFiltersGroup, vtkCollection);
  vtkGetObjectMacro(StreamlinesGroup, vtkCollection);
  vtkGetObjectMacro(TransformFiltersGroup, vtkCollection);
  vtkGetObjectMacro(MergeFiltersGroup, vtkCollection);
 // Description
  // Get streamlines.
  // These are what we are actually displaying.  They are either
  // clipper objects (when we are clipping the input this->Streamlines)
  // or they are pointers to the original input this->Streamlines
  // objects.  The purpose of this is to avoid modifying
  // the objects on the input this->Streamlines collection without
  // actually duplicating them and wasting memory.
  //vtkSetObjectMacro(ClippedStreamlinesGroup, vtkCollection);
  vtkGetObjectMacro(ClippedStreamlinesGroup, vtkCollection);

  vtkCollection * GetClippedStreamlines();

  int GetNumberOfStreamlines() {return this->Streamlines->GetNumberOfItems();}


  // Description
  // Input: list of the renderers whose scenes will have streamlines
  // added.
  vtkSetObjectMacro(Renderers, vtkCollection);
  vtkGetObjectMacro(Renderers, vtkCollection);

  // Description
  // Control actor properties of created streamlines by setting
  // them in this vtkProperty object.  Its parameters are copied
  // into the streamline actors.
  vtkSetObjectMacro(StreamlineProperty, vtkProperty);
  vtkGetObjectMacro(StreamlineProperty, vtkProperty);

  // Description
  // controls scalar visibility of actors created in this class
  void SetScalarVisibility(int);
  vtkGetMacro(ScalarVisibility,int);
  vtkBooleanMacro(ScalarVisibility,int);

  // Description
  // controls clipping of tracts/streamlines
  void SetClipping(int);
  vtkGetMacro(Clipping,int);
  vtkBooleanMacro(Clipping,int);

  // Description
  // Clipping planes 
  vtkSetObjectMacro(ClipFunction, vtkImplicitFunction );
  vtkGetObjectMacro(ClipFunction, vtkImplicitFunction );

  // Description
  // Lookup table for all displayed streamlines
  vtkSetObjectMacro(StreamlineLookupTable, vtkLookupTable);
  vtkGetObjectMacro(StreamlineLookupTable, vtkLookupTable);

  
 protected:
  vtkDisplayTracts();
  ~vtkDisplayTracts();

  // functions not accessible to the user
  void CreateGroupObjects();
  void CreateGraphicsObjects();
  void ApplyUserSettingsToGraphicsObject(int index);
  void SetMapperVisibility(vtkPolyDataMapper *currMapper);
//BTX
#if (VTK_MAJOR_VERSION >= 5)
  vtkPolyDataAlgorithm *
#else
  vtkPolyDataSource *
#endif
  ClipStreamline(vtkHyperStreamline *streamline, vtkCollection *activeClippedStreamlinesGroup);
//ETX

  int IsPropertyEqual(vtkProperty *a, vtkProperty *b);
  void SetActiveGroup (int groupindex);
  void AddNewGroup();

  vtkTransform *WorldToTensorScaledIJK;

  vtkCollection *Renderers;

  vtkCollection *Streamlines;
  vtkCollection *Mappers;
  vtkCollection *Actors;
  vtkCollection *AppendFilters;

  vtkCollection *StreamlinesGroup;
  vtkCollection *ClippedStreamlinesGroup;
  vtkCollection *MergeFiltersGroup;
  vtkCollection *TubeFiltersGroup;
  vtkCollection *TransformFiltersGroup;

  // Cointer of Clipped Streamlines.
  // Allow the user to get a flat collection with all
  // the clipped streamlines
  // Warning: Make sure to call this function after deleting
  // a streamline.
  vtkCollection *ClippedStreamlines;

  // Helper pointer to the active Group
  vtkCollection *activeStreamlines;
  vtkCollection *activeClippedStreamlines;
  vtkCollection *activeMergeFilters;
  vtkCollection *activeTubeFilters;
  vtkCollection *activeTransformFilters;
  vtkAppendPolyData *activeAppendFilter;
  vtkPolyDataMapper *activeMapper;
  vtkActor *activeActor;

  int NumberOfVisibleActors;

  int NumberOfStreamlinesPerActor;

  vtkProperty *StreamlineProperty;
 
  int ScalarVisibility;
  int Clipping;

  vtkLookupTable *StreamlineLookupTable;

  float TubeRadius;
  unsigned int TubeNumberOfSides;

  vtkImplicitFunction *ClipFunction;

};

#endif
