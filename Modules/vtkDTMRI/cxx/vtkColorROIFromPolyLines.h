/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkColorROIFromPolyLines.h,v $
  Date:      $Date: 2007/08/07 20:12:21 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
// .NAME vtkColorROIFromPolyLines - 
// .SECTION Description
//

#ifndef __vtkColorROIFromPolyLines_h
#define __vtkColorROIFromPolyLines_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkTransform.h"
#include "vtkCollection.h"
#include "vtkIntArray.h"

class VTK_DTMRI_EXPORT vtkColorROIFromPolyLines : public vtkObject
{
 public:
  static vtkColorROIFromPolyLines *New();
  vtkTypeMacro(vtkColorROIFromPolyLines,vtkObject);

  void ColorROIFromStreamlines();
  
  // Description
  // Input ROI volume to color with the ID of the streamlines through the ROI
  // Determines voxel size of output and region to color in output.
  vtkSetObjectMacro(InputROIForColoring, vtkImageData);
  vtkGetObjectMacro(InputROIForColoring, vtkImageData);

  // Description
  // Output ROI volume, colored with the ID of the streamlines through the ROI
  vtkGetObjectMacro(OutputROIForColoring, vtkImageData);

  // Description
  // Output volume, holding fiber count in each voxel
  vtkGetObjectMacro(OutputMaxFiberCount, vtkImageData);

  // Description
  // Input to this class (ID number of each polydata's label)
  vtkSetObjectMacro(Labels, vtkIntArray);

  // Description
  // Input to this class (tractographic paths).
  // Each item is a polydata containing lines in a cluster.
  vtkSetObjectMacro(PolyLineClusters, vtkCollection);

  // Description
  // Transformation used to place streamlines in scene 
  vtkSetObjectMacro(WorldToTensorScaledIJK, vtkTransform);
  vtkGetObjectMacro(WorldToTensorScaledIJK, vtkTransform);

  // Description
  // Transformation that places the InputROI in world space
  vtkSetObjectMacro(ROIToWorld, vtkTransform);
  vtkGetObjectMacro(ROIToWorld, vtkTransform);

 protected:
  vtkColorROIFromPolyLines();
  ~vtkColorROIFromPolyLines();

  vtkImageData *InputROIForColoring;
  vtkImageData *OutputROIForColoring;
  vtkImageData *OutputMaxFiberCount;

  vtkTransform *ROIToWorld;
  vtkTransform *WorldToTensorScaledIJK;

  vtkCollection *PolyLineClusters;
  vtkIntArray *Labels;

};

#endif
