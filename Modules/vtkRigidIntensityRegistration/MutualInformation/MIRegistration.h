/*=auto=========================================================================
(c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This software ("3D Slicer") is provided by The Brigham and Women's 
Hospital, Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for  
research purposes only, provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software, and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration, and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

=========================================================================auto=*/
#ifndef __MIRegistration_h
#define __MIRegistration_h
// .NAME MIRegistration - uses Mutual Information to Register 2 images 
// .SECTION Description
// MIRegistration computes a transformation that will align
// the source image with the target image.
//
// The algorithm is described in the paper: Viola, P. and Wells III,
// W. (1997).  "Alignment by Maximization of Mutual Information"
// International Journal of Computer Vision, 24(2):137-154
//
// This class was adopted by a class first written by
// Steve Pieper. It was also strongly derived from one of
// the ITK application Examples: the MultiResolutionMIRegistration.
//
//
// It uses the ITK registration framework with
// the following combination of components:
//   - MutualInformationImageToImageMetric
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

#include "RigidRegistrationBase.h"
#include "itkMutualInformationImageToImageMetric.h"
#include "vtkRigidIntensityRegistrationConfigure.h"
#include "itkMutualInformationImageToImageMetric.h"
namespace itk
{

template <typename TFixedImage, typename TMovingImage>
 class MIRegistration : public RigidRegistrationBase<TFixedImage,TMovingImage,MutualInformationImageToImageMetric<TFixedImage, TMovingImage> >
{
public:

  /** Standard class typedefs. */
  typedef MIRegistration Self;
  typedef RigidRegistrationBase<TFixedImage,TMovingImage,MutualInformationImageToImageMetric<TFixedImage, TMovingImage> > Superclass;
  typedef SmartPointer<Self> Pointer;
  typedef SmartPointer<const Self>  ConstPointer;

  /** Run-time type information (and related methods). */
  itkTypeMacro(MIRegistration, Object);

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

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
  typedef typename Superclass::TransformType           TransformType;

  /** Optimizer Type. */
  typedef typename Superclass::OptimizerType           OptimizerType;

  /** Metric Type. */
  typedef typename Superclass::MetricType              MetricType;

  /** Interpolation Type. */
  typedef typename Superclass::InterpolatorType        InterpolatorType;

  /** Fixed Image Pyramid Type. */
  typedef typename Superclass::FixedImagePyramidType   FixedImagePyramidType;

  /** Moving Image Pyramid Type. */
  typedef typename Superclass::MovingImagePyramidType  MovingImagePyramidType;

  /** Registration Method. */
  typedef typename Superclass::RegistrationType        RegistrationType;

  /** Transform parameters type. */
  typedef typename Superclass::ParametersType          ParametersType;

  /** Affine transform type. */
  typedef typename Superclass::AffineTransformType    AffineTransformType;
  typedef typename Superclass::AffineTransformPointer AffineTransformPointer;

  // ----------------------------------------------------------------------
  // Set the Parameters for the Metric
  // ----------------------------------------------------------------------

  /** Set the image parzen window widths. */
  itkSetClampMacro( MovingImageStandardDeviation, double, 0.0,
    NumericTraits<double>::max() );
  itkSetClampMacro( FixedImageStandardDeviation, double, 0.0,
    NumericTraits<double>::max() );

  /** Set the number of spatial samples. */
  itkSetClampMacro( NumberOfSpatialSamples, unsigned short, 1,
    NumericTraits<unsigned short>::max() );

 /** Send the Metric Param to the Metric, and send the optimizer to maximize */
  void SetMetricParam();

protected:
  MIRegistration();
  ~MIRegistration();

  // Description:
  // Print everything
  virtual void PrintSelf(std::ostream& os, Indent indent) const;

private:
  MIRegistration( const Self& ); //purposely not implemented
  void operator=( const Self& ); //purposely not implemented

  double                               m_MovingImageStandardDeviation;
  double                               m_FixedImageStandardDeviation;
  unsigned short                       m_NumberOfSpatialSamples;
};

} // namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "MIRegistration.txx"
#endif

#endif
