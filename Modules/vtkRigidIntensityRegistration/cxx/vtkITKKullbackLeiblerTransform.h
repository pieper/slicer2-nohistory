/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKKullbackLeiblerTransform.h,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkITKKLTransform_h
#define __vtkITKKLTransform_h
// .NAME vtkITKKLTransform - a linear transform specified by two images
// .SECTION Description
// KLTransform computes a transformation that will align
// the source image with the target image.  The transform can be
// initialized with a vtkLinearTransform or reset with the Identity
// method.
// The algorithm is described in the paper: Viola, P. and Wells III,
// W. (1997).  "Alignment by Maximization of Mutual Information"
// International Journal of Computer Vision, 24(2):137-154
//
// This class was adopted by a transform first written by
// Steve Pieper. It was also strongly derived from one of
// the ITK application Examples: the MultiResolutionMIRegistration.
//
// .Section Dealing with Flips
//  The registration algorithm is based on quaternions, so any registration
//  that requires an inversion (flip), rotation and translation cannot be
//  represented. Thus, sometimes we deal with flips by flipping the image first
//
//  When the matrix is initialized, it is checked for negative
//  determinant If it has negative determinant, the target image is
//  flipped along the z-axis. The matrix is then modified
//  appropriately, and then determined from source to flipped target
//  image. The resulting matrix is then modified appropriately and returned.
//  (Note, there is an assumption that the images are centered....)
//
// .SECTION see also
// vtkLinearTransform
//
// .SECTION Thanks
// Thanks to Samson Timoner who wrote this class.

#include "vtkLinearTransform.h"

#include "vtkITKRigidRegistrationTransformBase.h"

#include "vtkImageData.h"
#include "vtkMatrix4x4.h"

class VTK_RIGIDINTENSITYREGISTRATION_EXPORT vtkITKKullbackLeiblerTransform : public vtkITKRigidRegistrationTransformBase
{
public:
  static vtkITKKullbackLeiblerTransform *New();

  vtkTypeMacro(vtkITKKullbackLeiblerTransform,vtkITKRigidRegistrationTransformBase);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Specify the images that are already aligned
  vtkSetObjectMacro(TrainingSourceImage, vtkImageData);
  vtkSetObjectMacro(TrainingTargetImage, vtkImageData);
  vtkGetObjectMacro(TrainingSourceImage, vtkImageData);
  vtkGetObjectMacro(TrainingTargetImage, vtkImageData);

  // Description:
  // Specify the Training transform between the Training Images
  vtkSetObjectMacro(TrainingTransform, vtkMatrix4x4);
  vtkGetObjectMacro(TrainingTransform, vtkMatrix4x4);

  // Description:
  // Set the size of the histogram for the metric
  // Default is 32 by 32
  vtkSetMacro(HistSizeSource, int);
  vtkGetMacro(HistSizeSource, int);
  vtkSetMacro(HistSizeTarget, int);
  vtkGetMacro(HistSizeTarget, int);

  // Description:
  // Set the histogram frequency to use if the frequency is 0
  // This number should be very small compared with the number
  // of bins in the histogram. 1e-12 is the default.
  vtkSetMacro(HistEpsilon, double);
  vtkGetMacro(HistEpsilon, double);

  // Description:
  // Get the MTime.
  unsigned long GetMTime();

protected:
  vtkITKKullbackLeiblerTransform();
  ~vtkITKKullbackLeiblerTransform();

  // Update the matrix from the quaternion.
  void InternalUpdate();

  // Description:
  // Make another transform of the same type.
  vtkAbstractTransform *MakeTransform();

  // Description:
  // This method does no type checking, use DeepCopy instead.
  void InternalDeepCopy(vtkAbstractTransform *transform);

  vtkImageData *TrainingSourceImage;
  vtkImageData *TrainingTargetImage;
  vtkMatrix4x4 *TrainingTransform;

  int HistSizeSource;
  int HistSizeTarget;
  double HistEpsilon;
  void *TrainingHistogram;

private:
  vtkITKKullbackLeiblerTransform(const vtkITKKullbackLeiblerTransform&);  // Not implemented.
  void operator=(const vtkITKKullbackLeiblerTransform&);  // Not implemented.
};
  
#endif
