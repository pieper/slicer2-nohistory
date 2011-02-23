/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageReformat.h,v $
  Date:      $Date: 2006/02/27 19:21:51 $
  Version:   $Revision: 1.27 $

=========================================================================auto=*/
// .NAME vtkImageReformat -  Reformats a 2D image from a 3D volume.
// .SECTION Description
// vtkImageReformat allows interpolation or replication.
//

#ifndef __vtkImageReformat_h
#define __vtkImageReformat_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkMatrix4x4;
class VTK_SLICER_BASE_EXPORT vtkImageReformat : public vtkImageToImageFilter
{
  public:
    static vtkImageReformat *New();
    vtkTypeMacro(vtkImageReformat,vtkImageToImageFilter);
    void PrintSelf(ostream& os, vtkIndent indent);

    vtkGetMacro(Interpolate, int);
    vtkSetMacro(Interpolate, int);
    vtkBooleanMacro(Interpolate, int);

    //Description: Wld stands for the world coordinates
    vtkGetObjectMacro(WldToIjkMatrix, vtkMatrix4x4);
    virtual void SetWldToIjkMatrix(vtkMatrix4x4*);

    vtkGetObjectMacro(ReformatMatrix, vtkMatrix4x4);
    virtual void SetReformatMatrix(vtkMatrix4x4*);

    //Description: reformatted image in pixels
    // more stuff
    vtkGetMacro(Resolution, int);
    vtkSetMacro(Resolution, int);
    
    //Description: plane in world space
    vtkGetMacro(FieldOfView, vtkFloatingPointType);
    vtkSetMacro(FieldOfView, vtkFloatingPointType);
    
    // >>Karl Krissian - added following 4 functions for new draw ---------------
    //void vtkImageReformat::CrossProduct(float* v1, float* v2, float* v3);
    void CrossProduct(vtkFloatingPointType* v1, vtkFloatingPointType* v2, vtkFloatingPointType* v3);
    void SetPoint(int x, int y);
    void Slice2IJK(int slice_x, int slice_y,float& x, float& y,float& z);
    void IJK2Slice( float x, float y, float z, int& slice_x, int& slice_y);    
    // << Karl --------------------------------------------------------------
    
    vtkGetVector3Macro(WldPoint, vtkFloatingPointType);
    vtkGetVector3Macro(IjkPoint, vtkFloatingPointType);

    vtkFloatingPointType YStep[3];
    vtkFloatingPointType XStep[3];
    vtkFloatingPointType Origin[3];
  
  // >> AT 11/07/01

  // Description
  // XY vector from center of image to center of panned image
  // comes from GUI (MainInteractorPan)
  vtkGetVector2Macro(OriginShift, vtkFloatingPointType);
  vtkSetVector2Macro(OriginShift, vtkFloatingPointType);

  // Description
  // Zoom factor coming from GUI (MainInteractorZoom)
  vtkGetMacro(Zoom, vtkFloatingPointType);
  vtkSetMacro(Zoom, vtkFloatingPointType);

  // Description
  // Pixel size of the reformatted image in mm
  vtkGetMacro(PanScale, vtkFloatingPointType);
  // Description
  // For internal class use only
  vtkSetMacro(PanScale, vtkFloatingPointType);

  // Description
  vtkGetObjectMacro(OriginShiftMtx, vtkMatrix4x4);
  //vtkSetObjectMacro(OriginShiftMtx, vtkMatrix4x4);
  // << AT 11/07/01

  vtkGetMacro(RunTime, int);
  vtkSetMacro(RunTime, int);

  // Description:
  // When determining the modified time of the filter, 
  // this checks the modified time of the matrices.
  unsigned long GetMTime();

protected:
  vtkImageReformat();
  ~vtkImageReformat();

  // >> AT 11/07/01
  vtkFloatingPointType OriginShift[2];
  vtkFloatingPointType Zoom;
  vtkFloatingPointType PanScale;
  vtkMatrix4x4 *OriginShiftMtx;
  // << AT 11/07/01

    int RunTime;
    vtkFloatingPointType IjkPoint[3];
    vtkFloatingPointType WldPoint[3];
    int Resolution;
    vtkFloatingPointType FieldOfView;
    int Interpolate;
    vtkMatrix4x4* ReformatMatrix;
    vtkMatrix4x4* WldToIjkMatrix;

    // Override this function since inExt != outExt
    void ComputeInputUpdateExtent(int inExt[6],int outExt[6]);
  
    void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);
    void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
        int extent[6], int id);

  // We override this in order to allocate output tensors
  // before threading happens.  This replaces the superclass 
  // vtkImageToImageFilter's Execute function.
  //void Execute();
  void ExecuteData(vtkDataObject *out);

private:
  vtkImageReformat(const vtkImageReformat&);
  void operator=(const vtkImageReformat&);
};

#endif



