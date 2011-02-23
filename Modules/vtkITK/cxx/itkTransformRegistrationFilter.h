/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkTransformRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/

#ifndef __itkTransformRegistrationFilter_h
#define __itkTransformRegistrationFilter_h

#include "itkImageToImageFilter.h"


#include "itkEventObject.h"
#include "itkImage.h"
#include "itkImageRegistrationMethod.h"
#include "itkNormalizeImageFilter.h"

#include "itkImageRegistrationMethod.h"
#include "itkResampleImageFilter.h"

#include "itkLinearInterpolateImageFunction.h"
#include "itkNearestNeighborInterpolateImageFunction.h"
#include "itkRecursiveMultiResolutionPyramidImageFilter.h"
#include "itkMultiResolutionImageRegistrationMethod.h"

#include "itkTimeProbesCollectorBase.h"
#include "itkImageFileWriter.h"

//BTX

namespace itk
{


/** \class itkTransformRegistrationFilter
 * \brief Performs rigid registration at Multi-Resolution 
 *  Examples of template classes:
 *
 * TOptimizerClass = itk::VersorRigid3DTransformOptimizer 
 * TTransformerClass = itk::VersorRigid3DTransform< double >
 * TMetricClass=  typedef itk::MattesMutualInformationImageToImageMetric< 
 *                                InternalImageType, 
 *                                InternalImageType >    MutualInformationMetricType;
 *
 */
template <class TImageType, class TOptimizerClass, class TTransformerClass, class TMetricClass >

class ITK_EXPORT itkTransformRegistrationFilter : public itk::ImageToImageFilter< TImageType , TImageType >
{
public:
 
  /** Standard class typedefs */
  typedef itkTransformRegistrationFilter             Self;
  typedef itk::ImageToImageFilter<TImageType,TImageType>  Superclass;
  typedef ::itk::SmartPointer<Self>          Pointer;
  typedef ::itk::SmartPointer<const Self>    ConstPointer;

  typedef TTransformerClass   TransformType;
  typedef TOptimizerClass    OptimizerType;
  typedef TMetricClass       MetricType;
  typedef TImageType FixedImageType;
  typedef TImageType MovingImageType;

  typedef typename TransformType::ParametersType    ParametersType;

#if defined(_MSC_VER) && (_MSC_VER < 1300) 
  itkStaticConstMacro( Dimension, unsigned int, 3 );
#else
  static const unsigned int Dimension = 3;
#endif

  /** DoubleArray type. */
  typedef Array<double>  DoubleArray;

  /** UnsignedIntArray type. */
  typedef Array<unsigned int> UnsignedIntArray;

  /** ShrinkFactorsArray type. */
  typedef FixedArray<unsigned int, itkGetStaticConstMacro(Dimension) > ShrinkFactorsArray;

  /** Method for creation through the object factory. */
  //itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(itkTransformRegistrationFilter, itk::ImageToImageFilter);

  void AbortIterations() {
    m_IsAborted = true;
    m_Optimizer->StopOptimization ();
  };
  
  /** is aborted */
  bool IsAborted() { return m_IsAborted; };

  unsigned long AddIterationObserver (itk::Command *observer );

  /** Set init transfrom */
  void SetTransform( const TTransformerClass* transform );

  /** Get resulting transform */
  void GetTransform(TTransformerClass* transform);

  /** Get current transform */
  void GetCurrentTransform(TTransformerClass* transform);

  /** Get number of parameters. */
  unsigned long GetNumberOfParameters()
  { return m_Transform->GetNumberOfParameters(); }
  
  /** Set the number of resolution levels. */
  itkSetClampMacro( NumberOfLevels, unsigned short, 1,
                    NumericTraits<unsigned short>::max() );
  
  /** Set the translation parameter scales. */
  itkSetClampMacro( TranslationScale, double, 0.0,
                    NumericTraits<double>::max() );
  
  /** Set the number of iterations per level. */
  itkSetMacro( NumberOfIterations, UnsignedIntArray );
  itkGetMacro( NumberOfIterations, UnsignedIntArray );

  /** Set the fixed and moving image shrink factors. */
  itkSetMacro( FixedImageShrinkFactors, ShrinkFactorsArray );
  itkSetMacro( MovingImageShrinkFactors, ShrinkFactorsArray );

  int GetCurrentLevel() { return m_Registration->GetCurrentLevel();};

  int GetCurrentIteration() { return m_Optimizer->GetCurrentIteration(); };

  double GetMetricValue();

  itkSetMacro(ResampleMovingImage, bool);
  itkGetMacro(ResampleMovingImage, bool);

  TImageType* GetTransformedOutput (); 

protected:  

  // Types

  /** Fixed Image Pyramid Type. */
  typedef RecursiveMultiResolutionPyramidImageFilter<
                                    FixedImageType,
                                    FixedImageType  >    FixedImagePyramidType;

  /** Moving Image Pyramid Type. */
  typedef RecursiveMultiResolutionPyramidImageFilter<
                                    MovingImageType,
                                    MovingImageType  >   MovingImagePyramidType;

  typedef itk::ResampleImageFilter<
                                    MovingImageType,
                                    MovingImageType  >    ResampleFilterType;
  

  typedef itk::LinearInterpolateImageFunction< 
                                MovingImageType,
                                double             > LinearInterpolatorType;

  typedef itk::NearestNeighborInterpolateImageFunction< 
                                MovingImageType,
                                double             > NearestInterpolatorType;


  typedef typename OptimizerType::ScalesType       OptimizerScalesType;

  /** Registration Method. */
  typedef MultiResolutionImageRegistrationMethod< 
                                    FixedImageType, 
                                    MovingImageType >    RegistrationType;

  // Writer
  typedef itk::ImageFileWriter< FixedImageType  >    FixedImageWriterType;      
  typename FixedImageWriterType::Pointer m_WriterFixed;
  typedef itk::ImageFileWriter< MovingImageType  >    MovingImageWriterType;      
  typename MovingImageWriterType::Pointer m_WriterMoving;

  void  GenerateData ();


  // Default constructor
  itkTransformRegistrationFilter();

  virtual ~itkTransformRegistrationFilter() {};

  virtual void SetOptimizerParamters() = 0;

  virtual void SetMetricParamters() = 0;
  
  typename FixedImagePyramidType::Pointer     m_FixedImagePyramid;
  typename MovingImagePyramidType::Pointer    m_MovingImagePyramid;

  typename TransformType::Pointer                m_Transform;
  typename OptimizerType::Pointer                m_Optimizer;

  typename LinearInterpolatorType::Pointer       m_LinearInterpolator;
  typename NearestInterpolatorType::Pointer      m_NearestInterpolator;

  typename MetricType::Pointer                   m_Metric;

  typename RegistrationType::Pointer             m_Registration;

  typename ResampleFilterType::Pointer           m_Resampler;

  typename FixedImageType::Pointer               m_FixedImage;
  typename MovingImageType::Pointer              m_MovingImage;

  typename TImageType::PixelType                 m_BackgroundLevel;

  bool                                           m_ReportTimers;

  bool                                           m_ResampleMovingImage;

  // Optimizer Stuff
  unsigned short                       m_NumberOfLevels;
  double                               m_TranslationScale;
                   
  UnsignedIntArray                     m_NumberOfIterations;
  //DoubleArray                          m_LearningRates;

  // Multi-res Stuff
  ShrinkFactorsArray                   m_MovingImageShrinkFactors;
  ShrinkFactorsArray                   m_FixedImageShrinkFactors;
                   
  // Transform-stuff
  ParametersType                       m_InitialParameters;
  ParametersType                       m_FinalParameters;

  int                                  m_CurrentIteration;

  bool                                 m_IsAborted;

private:
  itkTransformRegistrationFilter(const itkTransformRegistrationFilter&);  // Not implemented.
  void operator=(const itkTransformRegistrationFilter&);  // Not implemented.
};

} // namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkTransformRegistrationFilter.txx"
#endif

 //ETX

#endif

