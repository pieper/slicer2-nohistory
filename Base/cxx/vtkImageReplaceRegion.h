/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageReplaceRegion.h,v $
  Date:      $Date: 2006/02/14 20:40:12 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
// .NAME vtkImageReplaceRegion - replaces a region in the input
// with this->Region.
// .SECTION Description
// vtkImageReplaceRegion - Used in vtkImageEditor.cxx to replace
// a 2D region with the output from an editor effect.  (For
// editing on a slice-by-slice basis.)

#ifndef __vtkImageReplaceRegion_h
#define __vtkImageReplaceRegion_h

#include "vtkImageInPlaceFilter.h"

#include "vtkIntArray.h"
#include "vtkImageData.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageReplaceRegion : public vtkImageInPlaceFilter
{
public:
  static vtkImageReplaceRegion *New();
  vtkTypeMacro(vtkImageReplaceRegion,vtkImageInPlaceFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  //
  vtkGetObjectMacro(Region, vtkImageData);
  vtkSetObjectMacro(Region, vtkImageData);

  // Description:
  //
  vtkSetObjectMacro(Indices, vtkIntArray);
  vtkGetObjectMacro(Indices, vtkIntArray);

protected:
  vtkImageReplaceRegion();
  ~vtkImageReplaceRegion();
  vtkImageReplaceRegion(const vtkImageReplaceRegion&);
  void operator=(const vtkImageReplaceRegion&);

  vtkIntArray *Indices;
  vtkImageData *Region;

  void ExecuteData(vtkDataObject *outData);
};

#endif



