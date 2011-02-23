/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKMutualInformationTransform.h,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkITKMutualInformationTransform_h
#define __vtkITKITKMutualInformationTransform_h
// .NAME vtkITKMutualInformationTransform - a linear transform specified by two images
// .SECTION Description
// MutualInformationTransform computes a transformation that will align
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
// vtkLinearTransform vtkRigidRegistrationTransformBase
//
// .SECTION Thanks
// Thanks to Samson Timoner who wrote this class.
// Thanks to Steve Pieper who wrote the initial version of the class.

#include "vtkITKRigidRegistrationTransformBase.h"
#include "vtkRigidIntensityRegistrationConfigure.h"

class VTK_RIGIDINTENSITYREGISTRATION_EXPORT vtkITKMutualInformationTransform : public vtkITKRigidRegistrationTransformBase {
public:
  static vtkITKMutualInformationTransform *New();
  vtkTypeMacro(vtkITKMutualInformationTransform,vtkITKRigidRegistrationTransformBase);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Get the MTime.
  unsigned long GetMTime();

  // Description:
  // Test Initialization of the Matrix, which is a pure rotation/translation
  // returns 0 on success. Also calls MIRegistration->TestParamToMatrix.
  int TestMatrixInitialize(vtkMatrix4x4 *aMat);

protected:
  vtkITKMutualInformationTransform();
  ~vtkITKMutualInformationTransform();

  // Update the matrix from the quaternion.
  void InternalUpdate();

  // Description:
  // Make another transform of the same type.
  vtkAbstractTransform *MakeTransform();

  // Description:
  // This method does no type checking, use DeepCopy instead.
  void InternalDeepCopy(vtkAbstractTransform *transform);

private:
  vtkITKMutualInformationTransform(const vtkITKMutualInformationTransform&);  // Not implemented.
  void operator=(const vtkITKMutualInformationTransform&);  // Not implemented.
};
  
#endif
