/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKRigidRegistrationTransformBase.h,v $
  Date:      $Date: 2006/01/06 17:58:03 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/
#ifndef __vtkITKRigidRegistrationTransformBase_h
#define __vtkITKRigidRegistrationTransformBase_h
// .NAME vtkITKRigidRegistrationTransformBase - a Base class to Rigidly Register two images
// .SECTION Description
// RigidRegistrationTransformBase computes a transformation that will align
// the source image with the target image.  
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
//  This is a base class. It is expect that classes beneath it will do all
//  the work. Specifically, define an InternalUpdate.
//
// .SECTION see also
// vtkLinearTransform
//
// .SECTION Thanks
// Thanks to Samson Timoner who wrote this class.
// Thanks to Steve Pieper who wrote the initial version of the class.

#include "vtkProcessObject.h"
#include "vtkLinearTransform.h"
#include "vtkRigidIntensityRegistrationConfigure.h"
#include "vtkDoubleArray.h"
#include "vtkImageData.h"
#include "vtkUnsignedIntArray.h"
class vtkMatrix4x4;
class vtkImageFlip;


class VTK_RIGIDINTENSITYREGISTRATION_EXPORT vtkITKRigidRegistrationTransformBase : public vtkLinearTransform
{
 public:
  vtkTypeMacro(vtkITKRigidRegistrationTransformBase,vtkLinearTransform);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Specify the source and target images. The two images must have
  // the same scalar type. Otherwise, the images can differ in scaling, 
  // resolution, etc
  vtkSetObjectMacro(SourceImage, vtkImageData);
  vtkGetObjectMacro(SourceImage, vtkImageData);

  vtkSetObjectMacro(TargetImage, vtkImageData);
  vtkGetObjectMacro(TargetImage, vtkImageData);

  // Description:
  // Set the standard deviations of the parzen window density estimators.
  vtkSetMacro(SourceStandardDeviation, double);
  vtkGetMacro(SourceStandardDeviation, double);
  vtkSetMacro(TargetStandardDeviation, double);
  vtkGetMacro(TargetStandardDeviation, double);

  // Description:
  // Set the number of sample points for density estimation
  vtkSetMacro(NumberOfSamples, int);
  vtkGetMacro(NumberOfSamples, int);

  // Description:
  // Set the translation scale factor.
  vtkSetMacro(TranslateScale, double);
  vtkGetMacro(TranslateScale, double);

  // Description:
  // Did the last run finish with an error?
  // Set to 0 if no error, 1 otherwise.
  vtkSetMacro(Error, int);
  vtkGetMacro(Error, int);

  virtual const char *GetNameOfClass();

  // Description:
  // Set the shrink factors for pyramid schemes.
  // Default is 1 1 1 
  void SetSourceShrinkFactors(unsigned int i,
                              unsigned int j, unsigned int k);
  void SetTargetShrinkFactors(unsigned int i,
                              unsigned int j, unsigned int k);
  unsigned int GetSourceShrinkFactors(const int &dir)
    { return SourceShrink[dir]; }
  unsigned int GetTargetShrinkFactors(const int &dir)
    { return TargetShrink[dir]; }

  // Description:
  // Reset the Multiresolution Settings
  // It blanks the LearningRate and NumberOfIterations
  void ResetMultiResolutionSettings()
    { LearningRate->Reset(); MaxNumberOfIterations->Reset(); };

  // Description:
  // Set the learning rate for the algorithm.
  // Generally between 0 and 1, most often 1e-4 or below
  // Must set the same number of Learning Rates as Iterations
  void SetNextLearningRate(const double rate);

  // Description:
  // Set the max number of iterations at each level
  // Generally less than 5000, 2500 is OK.
  // Must set the same number of Learning Rates as Iterations
  void SetNextMaxNumberOfIterations(const int num);

  // Description
  // The Max Number of Iterations at each multi-resolution level.
  vtkSetObjectMacro(MaxNumberOfIterations,vtkUnsignedIntArray);
  vtkGetObjectMacro(MaxNumberOfIterations,vtkUnsignedIntArray);

  // Description
  // The Learning Rates at each multi-resolution level.
  vtkSetObjectMacro(LearningRate,vtkDoubleArray);
  vtkGetObjectMacro(LearningRate,vtkDoubleArray);

  // Descripation:
  // Get the value of the last metric calculation
  // (Set is for internal use only).
  vtkSetMacro(MetricValue, double);
  vtkGetMacro(MetricValue, double);

  // Descripation:
  // Set Abort to be 1/0 to abort/keep going the process going
  vtkSetMacro(Abort, int);
  vtkGetMacro(Abort, int);

  // Description:
  // Initialize the transformation to a Matrix
  void Initialize(vtkMatrix4x4 *mat);

  // Description:
  // Get the resulting found matrix
  vtkMatrix4x4 *GetOutputMatrix();

  // Description:
  // The call back function for updating progress
  static int DataCallback(void *RigidReg, int NumLevel, int NumIter);

  // Description:
  // For internal use
  vtkGetObjectMacro(ProcessObject, vtkProcessObject);

  // Description:
  // Get the MTime.
  unsigned long GetMTime();

  // Description:
  // Initialize Random Seed
  // Initialize Random seed for itk. This is for testing
  void InitRandomSeed(long int i);

  // Description:
  // Test Initialization of the Matrix, which is a pure rotation/translation
  // returns 0 on success. Also calls MIRegistration->TestParamToMatrix.
  int TestMatrixInitialize(vtkMatrix4x4 *aMat);

  // Description:
  // Invert the transformation.  This is done by switching the
  // source and target images. This is does not work because the
  // transform is not touched.
  void Inverse();

  // Description:
  // GetPossiblyFlippedTargetImage
  // It is possible that we need to flip the target image
  // to take care of determinant -1 transforms
  // Internally, we therefore want to deal with the PossiblyFlippingTargetImage
  // Not the the TargetImage
  // Do not call this unless you know what you are doing.
  vtkImageData *GetPossiblyFlippedTargetImage();

// BTX
protected:

  vtkITKRigidRegistrationTransformBase();
  ~vtkITKRigidRegistrationTransformBase();

  // Update the matrix from the quaternion.
  void InternalUpdate() = 0;

  // Description:
  // Make another transform of the same type.
  // Needs to be in Subclass. Just call the New command...
  vtkAbstractTransform *MakeTransform() = 0;

  // Description:
  // This method does no type checking, use DeepCopy instead.
  void InternalDeepCopy(vtkAbstractTransform *transform);

  vtkImageData *SourceImage;
  vtkImageData *TargetImage;

  int FlipTargetZAxis;     // 1 if flipped z-axis on target
  vtkImageFlip *ImageFlip;
  vtkMatrix4x4 *ZFlipMat;
  vtkMatrix4x4 *OutputMatrix;

  double SourceStandardDeviation;
  double TargetStandardDeviation;
  double TranslateScale;
  int NumberOfSamples;

  double MetricValue;

  unsigned int SourceShrink[3];
  unsigned int TargetShrink[3];

  int Error;
  int Abort;

  vtkUnsignedIntArray  *MaxNumberOfIterations;
  vtkDoubleArray       *LearningRate;

  vtkProcessObject  *ProcessObject;

private:
  vtkITKRigidRegistrationTransformBase(const vtkITKRigidRegistrationTransformBase&);  // Not implemented.
  void operator=(const vtkITKRigidRegistrationTransformBase&);  // Not implemented.
  // Description:
  // Do not use this routine
  // This is not the correct matrix when a z-flip exists.
  vtkMatrix4x4 *GetMatrix()
    { return this->vtkLinearTransform::GetMatrix(); }
};


// ETX

  
#endif
