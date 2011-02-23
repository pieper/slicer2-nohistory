/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageReformatIJK.h,v $
  Date:      $Date: 2006/02/27 19:21:51 $
  Version:   $Revision: 1.21 $

=========================================================================auto=*/
// .NAME vtkImageReformatIJK -  
// .SECTION Description
// non-oblique reformatting (axial, sagittal, coronal orientations only).
//
// Description added by odonnell 4/02:
// This class is never used for actual reformatting (i.e. image generation).
// It is just used in two places in vtkMrmlSlicer.cxx.
// It is used to compute the reformat matrix for IJK-based reformatting
// and also for converting points to IJK for manual editing.
// The sequence of events (from vtkMrmlSlicer.cxx) is:
//
//  vtkImageReformatIJK *ijk = this->ReformatIJK;
//  ijk->SetWldToIjkMatrix(node->GetWldToIjk());
//  ijk->SetInput(vol->GetOutput());
//  ijk->SetInputOrderString(node->GetScanOrder());
//  ijk->SetOutputOrderString(orderString);
//  ijk->SetSlice(offset);
//  ijk->ComputeTransform();
//  ijk->ComputeOutputExtent();
//  ijk->ComputeReformatMatrix(ref);
//
//
//  So this class just encapsulates the logic needed to calculate this matrix.
//
//  Note the reformat matrix is the matrix that would move a standard
//  axial plane through the origin into the location where the slice
//  is desired.  So this is defined in world space in the slicer, NOT
//  IJK.  So this file basically converts the IJK notion of a slice
//  through the array into the appropriate world-space matrix, using
//  knowledge of the volume's location/scale from this->WldToIjkMatrix
//  and using the extent of the image data to see where this slice
//  should be placed in world space.
//

#ifndef __vtkImageReformatIJK_h
#define __vtkImageReformatIJK_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkMatrix4x4;
class vtkTransform;
class vtkIntArray;
class VTK_SLICER_BASE_EXPORT vtkImageReformatIJK : public vtkImageToImageFilter
{
public:
    static vtkImageReformatIJK *New();
  vtkTypeMacro(vtkImageReformatIJK,vtkImageToImageFilter);
    void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // XStep, YStep, ZStep, and Origin are
  // Given delta_x = 1 in IJK Space, XStep is the resulting step in RAS space
  // Given delta_y = 1 in IJK Space, YStep is the resulting step in RAS space
  // Given delta_z = 1 in IJK Space, ZStep is the resulting step in RAS space
  // I'm pretty sure Origin is the Origin in IJK space in RAS, but I'm not
  // positive.
  // Note: As far as I can tell, no one ever uses these functions.
    vtkGetVector4Macro(XStep, float);
    vtkGetVector4Macro(YStep, float);
    vtkGetVector4Macro(ZStep, float);
    vtkGetVector4Macro(Origin, float);

  // Description:
  //
  // Warning: XXX-MH this produces compiler warnings: should it be float 
  // (vtkFloatingPointType)?
    vtkSetMacro(Slice, int);
    vtkGetMacro(Slice, int);


  // Description:
  // Set Input order and output order to: SI IS LR RL AP PA 
  void SetInputOrderString(const char *str);
  void SetOutputOrderString(const char *str);


  // Description:
  // Integer corresponding to the input order
  // The following constants are defined in vtkImageReformatIJK.h
  // ORDER_IS, ORDER_SI, ORDER_LR, ORDER_RL, ORDER_PA, ORDER_AP
  vtkSetMacro(InputOrder, int);
  vtkGetMacro(InputOrder, int);
  vtkSetMacro(OutputOrder, int);
  vtkGetMacro(OutputOrder, int);

  vtkGetObjectMacro(Indices, vtkIntArray);

  vtkGetObjectMacro(WldToIjkMatrix, vtkMatrix4x4);
  virtual void SetWldToIjkMatrix(vtkMatrix4x4*);

  void ComputeReformatMatrix(vtkMatrix4x4 *ref);

  void SetIJKPoint(int i, int j, int k);
  vtkGetVectorMacro(XYPoint, int, 2);

  vtkMatrix4x4* WldToIjkMatrix;
  int NumSlices;
  vtkGetMacro(NumSlices, int);
  float XStep[4];
  float YStep[4];
  float ZStep[4];
  float Origin[4];
  int IJKPoint[3];
  int XYPoint[2];
  int Slice;
  vtkTransform *tran;
  int InputOrder;
  int OutputOrder;
  vtkIntArray *Indices;

  void ComputeTransform();

  void ComputeOutputExtent();

protected:
  vtkImageReformatIJK();
  ~vtkImageReformatIJK();

  vtkTimeStamp TransformTime;
  int OutputExtent[6];

    // Override this function since inExt != outExt
    void ComputeInputUpdateExtent(int inExt[6],int outExt[6]);
    void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);

    void ExecuteData(vtkDataObject *);

private:
    vtkImageReformatIJK(const vtkImageReformatIJK&);
    void operator=(const vtkImageReformatIJK&);
};

#endif



