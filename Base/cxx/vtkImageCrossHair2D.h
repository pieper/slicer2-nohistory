/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageCrossHair2D.h,v $
  Date:      $Date: 2006/04/12 22:25:41 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkImageCrossHair2D -- draws CrossHair2Ds with tic marks on 2D window. 
// .SECTION Description
// vtkImageCrossHair2D draws cross hairs with optional hash marks on a 2D window.
// 

#ifndef __vtkImageCrossHair2D_h
#define __vtkImageCrossHair2D_h

#include "vtkImageInPlaceFilter.h"
#include "vtkSlicer.h"

class vtkImageData;
class VTK_SLICER_BASE_EXPORT vtkImageCrossHair2D : public vtkImageInPlaceFilter
{
public:
  static vtkImageCrossHair2D *New();
  vtkTypeMacro(vtkImageCrossHair2D,vtkImageInPlaceFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Set/Get the RGB CursorColor
  vtkSetVector3Macro(CursorColor, vtkFloatingPointType);
  vtkGetVectorMacro(CursorColor, vtkFloatingPointType, 3);

  // Description:
  // Get/Set the Number of Hash marks on the Cross Hair
  vtkGetMacro(NumHashes, int);
  vtkSetMacro(NumHashes, int);

  // Description:
  // Get/Set the BullsEyeWidth in pixels.
  vtkGetMacro(BullsEyeWidth, int);
  vtkSetMacro(BullsEyeWidth, int);

  // Description:
  // Turn the BullsEye on and off
  vtkGetMacro(BullsEye, int);
  vtkSetMacro(BullsEye, int);
  vtkBooleanMacro(BullsEye, int);

  // Description:
  // Get/Set the Spacing between Hash Marks in mm.
  vtkGetMacro(HashGap, vtkFloatingPointType);
  vtkSetMacro(HashGap, vtkFloatingPointType);

  // Description:
  // Get/Set the Length of a hash mark in mm.
  vtkGetMacro(HashLength, vtkFloatingPointType);
  vtkSetMacro(HashLength, vtkFloatingPointType);

  // Description:
  // Get/Set the Magnification
  // NOTE: This should not be used.  Instead, specify the magnification
  // implicitly in the spacing.
  vtkGetMacro(Magnification, vtkFloatingPointType);
  vtkSetMacro(Magnification, vtkFloatingPointType);

  // Description:
  // Set whether or not the cursor should be shown
  // If not, this filter does nothing.
  vtkGetMacro(ShowCursor, int);
  vtkSetMacro(ShowCursor, int);
  vtkBooleanMacro(ShowCursor, int);

  // Description 
  // Set the cross to intersect or not. 
  // If not, the result is perpendicular lines
  // with their intersection removed.
  vtkGetMacro(IntersectCross, int);
  vtkSetMacro(IntersectCross, int);
  vtkBooleanMacro(IntersectCross, int);

  // Description 
  // Get/Set The Cursor Position.
  vtkSetVector2Macro(Cursor, int);
  vtkGetVectorMacro(Cursor, int, 2);

protected:
  vtkImageCrossHair2D();
  ~vtkImageCrossHair2D() {};

  int ShowCursor;
  int NumHashes;
  int IntersectCross;
  int Cursor[2];
  vtkFloatingPointType CursorColor[3];
  vtkFloatingPointType Magnification;
  vtkFloatingPointType HashGap;
  vtkFloatingPointType HashLength;
  int BullsEye;
  int BullsEyeWidth;

  void DrawCursor(vtkImageData *outData, int outExt[6]);

  // Not threaded because its too simple of a filter
  void ExecuteData(vtkDataObject *);

private:
  vtkImageCrossHair2D(const vtkImageCrossHair2D&);
  void operator=(const vtkImageCrossHair2D&);
};

#endif

