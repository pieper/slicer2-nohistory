/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSaveTracts.h,v $
  Date:      $Date: 2006/12/06 02:32:14 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkSaveTracts - 
// .SECTION Description
// Handles save functionality for objects representing tracts.
// Takes as input collections of streamline objects.
// Can use SaveForAnalysis mode (saves tensors at each point
// of the input polydata, for this an InputTensorField is needed).
// Otherwise just saves the input polydata.
// Input is grouped by color (according to color from input actor
// collection) and each color is saved as a separate polydata file.

#ifndef __vtkSaveTracts_h
#define __vtkSaveTracts_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkCollection.h"
#include "vtkDisplayTracts.h"
#include "vtkTransform.h"
#include "vtkMrmlTree.h"
#include "vtkImageData.h"



class VTK_DTMRI_EXPORT vtkSaveTracts : public vtkObject
{
 public:
  static vtkSaveTracts *New();
  vtkTypeMacro(vtkSaveTracts,vtkObject);

  // Description
  // Save streamlines as vtkPolyData models.
  // Streamlines are grouped into model files based on their color.
  // Files are saved as filename_0.vtk, filename_1.vtk, etc.
  // A MRML file is saved as filename.xml.
  // The MRML model names are name_0, name_1, etc.
  void SaveStreamlinesAsPolyData(char *filename, char *name);

  // Description
  // Save streamlines as vtkPolyData models.
  // Streamlines are grouped into model files based on their color.
  // Files are saved as filename_0.vtk, filename_1.vtk, etc.
  // A MRML file is saved as filename.xml.
  // The MRML model names are name_0, name_1, etc.  
  // The optional colorTree argument lets us find and save in MRML
  // the text names of the colors of each streamline.
  void SaveStreamlinesAsPolyData(char *filename, char *name, 
                                 vtkMrmlTree *colorTree);

  // Description
  // Input to this class (things we may save)
  vtkSetObjectMacro(Streamlines, vtkCollection);

  // Description
  // Input to this class (things we may save)
  vtkSetObjectMacro(TubeFilters, vtkCollection);

  // Description
  // Input to this class (to save tensors along tract path)
  vtkSetObjectMacro(InputTensorField, vtkImageData);

  // Description
  // Input to this class (for grabbing colors). This 
  // may change to a colorID array.
  vtkSetObjectMacro(Display, vtkDisplayTracts);

  // Example usage is as follows:
  // 1) If tensors are to be saved in a coordinate system
  //    that is not IJK (array-based), and the whole volume is
  //    being rotated, each tensor needs also to be rotated.
  //    First find the matrix that positions your tensor volume.
  //    This is how the entire volume is positioned, not 
  //    the matrix that positions an arbitrary reformatted slice.
  // 2) Remove scaling and translation from this matrix; we
  //    just need to rotate each tensor.
  // 3) Set TensorRotationMatrix to this rotation matrix.
  //
  vtkSetObjectMacro(TensorRotationMatrix, vtkMatrix4x4);
  vtkGetObjectMacro(TensorRotationMatrix, vtkMatrix4x4);

  // Description
  // Transformation used to place streamlines in scene 
  // (actually inverse of this transform). Needed to save
  // paths in world coordinates.
  vtkSetObjectMacro(WorldToTensorScaledIJK, vtkTransform);
  vtkGetObjectMacro(WorldToTensorScaledIJK, vtkTransform);

  // Description
  // Coordinate system in which to save tracts.
  void SetOutputCoordinateSystemToWorld(){
   this->SetOutputCoordinateSystem(1);}

  // Description
  // Coordinate system in which to save tracts.
  // This is IJK (array) coordinates with voxel scaling.
  void SetOutputCoordinateSystemToScaledIJK(){
   this->SetOutputCoordinateSystem(2);}

  // Description
  // Coordinate system in which to save tracts.
  // This is IJK (array) coordinates with voxel scaling,
  // and the center of the original tensor volume is at the origin.
  // This is useful when the tensor image data has been registered
  // in this coordinate system.
  void SetOutputCoordinateSystemToCenteredScaledIJK(){
   this->SetOutputCoordinateSystem(3);}

  // Description
  // Coordinate system in which to save tracts.
  vtkSetMacro(OutputCoordinateSystem, int);
  vtkGetMacro(OutputCoordinateSystem, int);

  // Description
  // Used to "center" the scaled IJK coords. This is 
  // used when the coordinate system is CenteredScaledIJK.
  // This is the extent of the original tensor volume.
  vtkSetVector6Macro(ExtentForCenteredScaledIJK, int);
  vtkGetVector6Macro(ExtentForCenteredScaledIJK, int);

  // Description
  // Used to "center" the scaled IJK coords. This is 
  // used when the coordinate system is CenteredScaledIJK.
  // This is the voxel scaling (size in mm) of the original tensor volume.
  vtkSetVector3Macro(ScalingForCenteredScaledIJK, float);
  vtkGetVector3Macro(ScalingForCenteredScaledIJK, float);

  // Description
  // Save for Analysis == 1 means save polylines with tensors.
  // Otherwise save tube vtk polydata models.
  vtkSetMacro(SaveForAnalysis,int);
  vtkGetMacro(SaveForAnalysis,int);
  vtkBooleanMacro(SaveForAnalysis,int);

 protected:
  vtkSaveTracts();
  ~vtkSaveTracts();

  vtkImageData *InputTensorField;

  vtkTransform *WorldToTensorScaledIJK;
  vtkMatrix4x4 *TensorRotationMatrix;

  vtkCollection *Streamlines;
  vtkCollection *TubeFilters;

  vtkDisplayTracts *Display;


  int SaveForAnalysis;
  int OutputCoordinateSystem;
  int ExtentForCenteredScaledIJK[6];
  float ScalingForCenteredScaledIJK[3];
};


#endif
