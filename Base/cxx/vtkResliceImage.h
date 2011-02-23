/*=auto=========================================================================

  Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkResliceImage.h,v $
  Date:      $Date: 2006/02/27 19:21:52 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Samson Timoner TetraMesh Library
  Module:    $RCSfile: vtkResliceImage.h,v $
  Language:  C++
  Date:      $Date: 2006/02/27 19:21:52 $
  Version:   $Revision: 1.18 $
  
Copyright (c) 2001 Samson Timoner

This software is not to be edited, distributed, copied, moved, etc.
without express permission of the author. 

========================================================================= */
// .NAME vtkResliceImage - Reslices an image in another coordinate system
// .SECTION Description
// This filter takes in a volume, and resamples it in the coordinates of
// the next volume. A transform that takes the coordinates (mm) in the image
// whose coordinates we will use into the input image coordinates (mm) is 
// possible.
//
// Please note that this program (by Samson Timoner) is also in his
// personal CVS tree. If you make changes, please let him know.
//

#ifndef __vtkResliceImage_h
#define __vtkResliceImage_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkMatrix4x4;
class vtkUnstructuredGrid;

class VTK_SLICER_BASE_EXPORT vtkResliceImage : public vtkImageToImageFilter
{
public:
  // Description:
  // Default:: No transform between the coordinate systems
  // Output Extent of 1 pixel, spacing of (1,1,1), and origin of (0,0,0)
  static vtkResliceImage *New();
  vtkTypeMacro(vtkResliceImage,vtkImageToImageFilter);

 // Description:
  // The output image will have the same spacing and origin and extent
  // as this Volume.
  void SetOutputImageParam(vtkImageData *VolumeToCopyParam);

  void PrintSelf(ostream& os, vtkIndent indent);


  // Description:
  // Set the transformation between the first and final images
  // This transform takes points in the output volume's continuous coordinates
  // (mm) and maps them to the input volume's continuous coordinates (mm).
  // If set to NULL, the transform is the identity.
  virtual void SetTransformOutputToInput(vtkMatrix4x4*);
  vtkGetObjectMacro(TransformOutputToInput,vtkMatrix4x4);
 

  // Description:
  // Set the background scalar to use if there is no 
  // information in the first image in the area specified.
  vtkSetMacro(Background,vtkFloatingPointType);
  vtkGetMacro(Background,vtkFloatingPointType);

  // Helper Functions:
  //

  //BTX
  static void FindInputIJK(vtkFloatingPointType OtherIJK[4],
                           vtkMatrix4x4 *IJKtoIJK,
                           int i, int j, int k);

  static vtkMatrix4x4 *GetIJKtoIJKMatrix(vtkFloatingPointType Spacing2[3],
                                         vtkFloatingPointType Origin2[3],
                                         vtkMatrix4x4 *MM2toMM1,
                                         vtkFloatingPointType Spacing1[3],
                                         vtkFloatingPointType Origin1[3]);
protected:
  vtkResliceImage();
  ~vtkResliceImage() {};

  vtkMatrix4x4     *TransformOutputToInput;
  vtkMatrix4x4     *IJKtoIJK;
  vtkFloatingPointType OutSpacing[3];
  vtkFloatingPointType OutOrigin[3];
  int OutExtent[6];
  vtkFloatingPointType Background;

  void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);
  void ComputeInputUpdateExtent(int inExt[6], int outExt[6]);
  void ExecuteInformation(){this->Superclass::ExecuteInformation();};
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
               int outExt[6], int id);
  //ETX
private:
  vtkResliceImage(const vtkResliceImage&);
  void operator=(const vtkResliceImage&);
};
#endif /* __vtkResliceImage_h */
