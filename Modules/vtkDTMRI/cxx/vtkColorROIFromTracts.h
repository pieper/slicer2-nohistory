/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkColorROIFromTracts.h,v $
  Date:      $Date: 2006/01/06 17:57:25 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
// .NAME vtkColorROIFromTracts - 
// .SECTION Description
//

#ifndef __vtkColorROIFromTracts_h
#define __vtkColorROIFromTracts_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkTransform.h"
#include "vtkCollection.h"

class VTK_DTMRI_EXPORT vtkColorROIFromTracts : public vtkObject
{
 public:
  static vtkColorROIFromTracts *New();
  vtkTypeMacro(vtkColorROIFromTracts,vtkObject);

  void ColorROIFromStreamlines();
  
  // Description
  // Input ROI volume to color with the ID of the streamlines through the ROI
  vtkSetObjectMacro(InputROIForColoring, vtkImageData);
  vtkGetObjectMacro(InputROIForColoring, vtkImageData);

  // Description
  // Output ROI volume, colored with the ID of the streamlines through the ROI
  vtkGetObjectMacro(OutputROIForColoring, vtkImageData);

  // Description
  // Input to this class (for grabbing colors). This 
  // may change to a colorID array.
  vtkSetObjectMacro(Actors, vtkCollection);

  // Description
  // Input to this class (tractographic paths)
  vtkSetObjectMacro(Streamlines, vtkCollection);

  // Description
  // Transformation used to place streamlines in scene 
  vtkSetObjectMacro(WorldToTensorScaledIJK, vtkTransform);
  vtkGetObjectMacro(WorldToTensorScaledIJK, vtkTransform);

  // Description
  // Transformation used in seeding streamlines.  Their start
  // points are specified in the coordinate system of the ROI volume.
  // Transform the ijk coordinates of the ROI to world coordinates.
  vtkSetObjectMacro(ROIToWorld, vtkTransform);
  vtkGetObjectMacro(ROIToWorld, vtkTransform);

 protected:
  vtkColorROIFromTracts();
  ~vtkColorROIFromTracts();

  vtkImageData *InputROIForColoring;
  vtkImageData *OutputROIForColoring;

  vtkTransform *ROIToWorld;
  vtkTransform *WorldToTensorScaledIJK;

  vtkCollection *Streamlines;
  vtkCollection *Actors;

};

#endif
