/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: RigidRegistrationBase.h,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#ifndef __RigidRegistrationBase_h
#define __RigidRegistrationBase_h
// .NAME RigidRegistrationBase - uses Mutual Information to Register 2 images 
// .SECTION Description
// RigidRegistrationBase computes a transformation that will align
// the source image with the target image.
//
// The algorithm is described in the paper: Viola, P. and Wells III,
// W. (1997).  "Alignment by Maximization of Mutual Information"
// International Journal of Computer Vision, 24(2):137-154
//
// This class was adopted by a class first written by
// Steve Pieper. It was also strongly derived from one of
// the ITK application Examples: the MultiResolutionMutualInformationBase
//
//
// It uses the ITK registration framework with
// the following combination of components:
//   - Metric is Sub-classed
//   - QuaternionRigidTransform
//   - QuaternionRigidTransformGradientDescentOptimizer
//   - LinearInterpolateImageFunction
// 
// The registration is done using a multiresolution strategy.
// At each resolution level, the downsampled images are obtained
// using a RecursiveMultiResolutionPyramidImageFilter.
// 
// Note that this class requires both images to be 3D and with
// pixels of a real type.
// 
// The registration process is activated by method Execute().
// 
// Inputs:
//   - pointer to fixed image
//   - pointer to moving image
//   - number of resolution levels
//   - scaling applied to the translation parameters during optimization
//   - parzen window width for the fixed image
//   - parzen window width for the moving image
//   - number of optimization iterations at each level
//   - the optimization learning rate at each level
//   - the initial rigid (quaternion) transform parameters
//   - the coarest level shrink factors for the fixed image
//   - the coarest level shrink factors for the moving image
// 
// Outputs:
//   - rigid (quaternion) transform parameters to maps points from
//     the fixed image to the moving image.
//   - pointer to equivalent affine transform.
//
//
// .SECTION Thanks
// Thanks to Samson Timoner who created this class.

#include "itkObject.h"
#include "itkMultiResolutionImageRegistrationMethod.h"
#include "itkAffineTransform.h"

#include "itkQuaternionRigidTransform.h"
#include "itkLinearInterpolateImageFunction.h"
#include "itkQuaternionRigidTransformGradientDescentOptimizerModified.h"
#include "itkRecursiveMultiResolutionPyramidImageFilter.h"

#include "itkArray.h"

#include "vtkRigidIntensityRegistrationConfigure.h"

class vtkMatrix4x4;
class vtkITKRigidRegistrationTransformBase;

namespace itk
{

template <typename TFixedImage, typename TMovingImage, typename TMetricType>
class RigidRegistrationBase : public Object
{
public:

  /** Standard class typedefs. */
  typedef RigidRegistrationBase Self;
  typedef Object Superclass;
  typedef SmartPointer<Self> Pointer;
  typedef SmartPointer<const Self>  ConstPointer;

  /** Run-time type information (and related methods). */
  itkTypeMacro(RigidRegistrationBase, Object);

  // ----------------------------------------------------------------------
  // All the Type Definitions
  // ----------------------------------------------------------------------

  /** Fixed Image Type. */
  typedef TFixedImage FixedImageType;

  /** Moving Image Type. */
  typedef TMovingImage MovingImageType;

  /** Image dimension enumeration. */
  itkStaticConstMacro (ImageDimension, unsigned int, TFixedImage::ImageDimension);

  /** Transform Type. */
  typedef QuaternionRigidTransform< double >       TransformType;

  /** Optimizer Type. */
  typedef QuaternionRigidTransformGradientDescentOptimizerModified 
                                                         OptimizerType;

  /** Metric Type. */
  typedef TMetricType                                    MetricType;

  /** Interpolation Type. */
  typedef LinearInterpolateImageFunction< 
                                    MovingImageType,
                                    double          >    InterpolatorType;

  /** Fixed Image Pyramid Type. */
  typedef RecursiveMultiResolutionPyramidImageFilter<
                                    FixedImageType,
                                    FixedImageType  >    FixedImagePyramidType;

  /** Moving Image Pyramid Type. */
  typedef RecursiveMultiResolutionPyramidImageFilter<
                                    MovingImageType,
                                    MovingImageType  >   MovingImagePyramidType;

  /** Registration Method. */
  typedef MultiResolutionImageRegistrationMethod< 
                                    FixedImageType, 
                                    MovingImageType >    RegistrationType;

  /** Transform parameters type. */
  typedef typename RegistrationType::ParametersType     ParametersType;

  /** DoubleArray type. */
  typedef Array<double>  DoubleArray;

  /** UnsignedIntArray type. */
  typedef Array<unsigned int> UnsignedIntArray;

  /** ShrinkFactorsArray type. */
  typedef FixedArray<unsigned int,itkGetStaticConstMacro(ImageDimension)> ShrinkFactorsArray;

  /** Affine transform type. */
  typedef AffineTransform<double,itkGetStaticConstMacro(ImageDimension)>   AffineTransformType;
  typedef typename AffineTransformType::Pointer AffineTransformPointer;

  // ----------------------------------------------------------------------
  // Metric Stuff: to be done in child class
  // ----------------------------------------------------------------------

 /** Send the Metric Param to the Metric, and send the optimizer to max/min */
  virtual void SetMetricParam() = 0;

  // ----------------------------------------------------------------------
  // Set the Parameters for the Registration
  // ----------------------------------------------------------------------

  /** Set the fixed image. */
  itkSetObjectMacro( FixedImage, FixedImageType );

  /** Set the fixed image. */
  itkGetObjectMacro( FixedImage, FixedImageType );

  /** Set the moving image. */
  itkSetObjectMacro( MovingImage, MovingImageType );

  /** Set the moving image. */
  itkGetObjectMacro( MovingImage, MovingImageType );

  /** Set the number of resolution levels. */
  itkSetClampMacro( NumberOfLevels, unsigned short, 1,
    NumericTraits<unsigned short>::max() );

  /** Set the translation parameter scales. */
  itkSetClampMacro( TranslationScale, double, 0.0,
    NumericTraits<double>::max() );

  /** Set the number of iterations per level. */
  itkSetMacro( NumberOfIterations, UnsignedIntArray );

  /** Set the learning rate per level. */
  itkSetMacro( LearningRates, DoubleArray );

  /** Set the initial transform parameters. */
  itkSetMacro( InitialParameters, ParametersType );

  /** Set the fixed and moving image shrink factors. */
  itkSetMacro( FixedImageShrinkFactors, ShrinkFactorsArray );
  itkSetMacro( MovingImageShrinkFactors, ShrinkFactorsArray );

  // Description:
  // Initialize the Registration using a matrix
  void InitializeRegistration(vtkMatrix4x4 *matrix);

  //Description:
  //Initalize everything possible from the vtkITKRigidRegistrationTransformBase
  void Initialize(vtkITKRigidRegistrationTransformBase *self,
                  vtkMatrix4x4 *matrix);

  // ----------------------------------------------------------------------
  // Run the Registration
  // ----------------------------------------------------------------------

  /** Method to execute the registration. */
  virtual void Execute();

  /** Initialize registration at the start of new level. */
  void StartNewLevel();

  // ----------------------------------------------------------------------
  // Get Parameters/Results
  // ----------------------------------------------------------------------

  /** Get number of parameters. */
  unsigned long GetNumberOfParameters()
    { return m_Transform->GetNumberOfParameters(); }

  /** Get computed transform parameters. */
  const ParametersType& GetTransformParameters()
    { return m_Registration->GetLastTransformParameters(); }

  const ParametersType& GetInitialParameters()
    { return m_InitialParameters; }

  /** Get computed affine transform. */
  AffineTransformPointer GetAffineTransform();

  // Description:
  // Set the Matrix using the current results of the registration
  void ResultsToMatrix(vtkMatrix4x4 *matrix)
    { ParamToMatrix(this->GetTransformParameters(),matrix);}

  // Description:
  // Set the Matrix using the Parameters.
  // Note that m_Transform is updated with the parameters.
  // This is really only for testing purposes, do not use.
  void ParamToMatrix(const ParametersType &Param,
                     vtkMatrix4x4 *matrix);
  // Description:
  // Test the ParamToMatrix function
  // with the InitializeRegistration function
  // returns 0 on success.
  int TestParamToMatrix();

  // Description:
  // How good was the alignment
  double GetMetricValue()
    {return m_Metric->GetValue(this->GetTransformParameters());}

protected:
  RigidRegistrationBase();
  ~RigidRegistrationBase();

  // Description:
  // Print everything
  virtual void PrintSelf(std::ostream& os, Indent indent) const;

protected:
  typename OptimizerType::Pointer             m_Optimizer;
  typename MetricType::Pointer                m_Metric;

private:
  RigidRegistrationBase( const Self& ); //purposely not implemented
  void operator=( const Self& ); //purposely not implemented

  typename FixedImageType::Pointer            m_FixedImage;
  typename MovingImageType::Pointer           m_MovingImage;
  typename TransformType::Pointer             m_Transform;
  typename InterpolatorType::Pointer          m_Interpolator;
  typename FixedImagePyramidType::Pointer     m_FixedImagePyramid;
  typename MovingImagePyramidType::Pointer    m_MovingImagePyramid;
  typename RegistrationType::Pointer          m_Registration;

  // Optimizer Stuff
  unsigned short                       m_NumberOfLevels;
  double                               m_TranslationScale;
                   
  UnsignedIntArray                     m_NumberOfIterations;
  DoubleArray                          m_LearningRates;

  // Multi-res Stuff
  ShrinkFactorsArray                   m_MovingImageShrinkFactors;
  ShrinkFactorsArray                   m_FixedImageShrinkFactors;
                   
  // Transform-stuff
  ParametersType                       m_InitialParameters;
  AffineTransformPointer               m_AffineTransform;

  // Observer Stuff
  unsigned long                        m_ObserverTag;
  unsigned long                        m_OptimizeObserverTag;

};

} // namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "RigidRegistrationBase.txx"
#endif

#endif
