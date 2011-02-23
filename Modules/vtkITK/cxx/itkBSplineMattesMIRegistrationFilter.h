/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkBSplineMattesMIRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __itkBSplineMattesMIRegistrationFilter_h
#define __itkBSplineMattesMIRegistrationFilter_h

#include "itkEventObject.h"
#include "itkImage.h"
#include "itkImageRegistrationMethod.h"
#include "itkNormalizeImageFilter.h"

#include "itkImageRegistrationMethod.h"
#include "itkResampleImageFilter.h"

#include "itkLinearInterpolateImageFunction.h"
#include "itkRecursiveMultiResolutionPyramidImageFilter.h"
#include "itkMultiResolutionImageRegistrationMethod.h"

#include "itkWarpImageFilter.h"
#include "itkTransform.h"
#include "itkImageFileWriter.h"


#include "itkImageRegistrationMethod.h"
#include "itkMattesMutualInformationImageToImageMetric.h"
#include "itkLinearInterpolateImageFunction.h"

#include "itkBSplineDeformableTransform.h"
#include "itkLBFGSBOptimizer.h"

//BTX
namespace itk 
{

// itkBSplineMattesMIRegistrationFilter Class

template <class TImageType >

class ITK_EXPORT itkBSplineMattesMIRegistrationFilter : public itk::ImageToImageFilter< TImageType, TImageType>
{
public:

  typedef itkBSplineMattesMIRegistrationFilter             Self;
  typedef itk::ImageToImageFilter<TImageType,TImageType>  Superclass;
  typedef ::itk::SmartPointer<Self>          Pointer;
  typedef ::itk::SmartPointer<const Self>    ConstPointer;

  typedef itk::Vector<float, 3>    VectorPixelType;

  typedef TImageType FixedImageType;
  typedef TImageType MovingImageType;

  typedef itk::Image<VectorPixelType, 3> DeformationFieldType;

  typedef itk::Transform<double, 3, 3 > InputTransformType;
  typedef itk::BSplineDeformableTransform<double, 3, 3 >     TransformType;
  
  /** Method for creation through the object factory. */
  itkNewMacro(Self);  

  /** Runtime information support. */
  itkTypeMacro(TImageType, ImageToImageFilter);
  
  /** Set bspline transfrom */
  void SetTransform( const InputTransformType* transform )
  {
    m_Transform->SetParameters( transform->GetParameters() );
  }

  /** Set input transfrom */
  void SetInputTransform( const InputTransformType* transform )
  {
    m_InputTransform->SetParameters( transform->GetParameters() );
  }

  /** Get input transform */
  void GetInputTransform(InputTransformType* transform)
  {
    transform->SetParameters( m_InputTransform->GetParameters() );
  }

  /** Get resulting transform */
  void GetTransform(TransformType* transform)
  {
    transform->SetParameters( m_Transform->GetParameters() );
  }

  double GetMetricValue() {
    return m_Optimizer->GetValue();
  }

  TImageType* GetTransformedOutput (); 

  DeformationFieldType * GetDeformationField(void);

  virtual void AbortIterations() {
    m_IsAborted = true;
  };
  bool IsAborted() { return m_IsAborted; };

  unsigned long AddIterationObserver (itk::Command *observer );

  // Properties

  itkSetMacro(GridSize, int);
  itkGetMacro(GridSize, int);

  itkSetMacro(CostFunctionConvergenceFactor, double);
  itkGetMacro(CostFunctionConvergenceFactor, double);

  itkSetMacro(ProjectedGradientTolerance, double);
  itkGetMacro(ProjectedGradientTolerance, double);

  itkSetMacro(MaximumNumberOfIterations, int);
  itkGetMacro(MaximumNumberOfIterations, int);

  itkSetMacro(MaximumNumberOfEvaluations, int);
  itkGetMacro(MaximumNumberOfEvaluations, int);

  itkSetMacro(MaximumNumberOfCorrections, int);
  itkGetMacro(MaximumNumberOfCorrections, int);

  itkSetMacro(NumberOfHistogramBins, int);
  itkGetMacro(NumberOfHistogramBins, int);

  itkSetMacro(NumberOfSpatialSamples, int);
  itkGetMacro(NumberOfSpatialSamples, int);

  itkSetMacro(CurrentIteration, int);
  itkGetMacro(CurrentIteration, int);

  itkSetMacro(WriteInputs, bool);
  itkGetMacro(WriteInputs, bool);

  itkSetMacro(ResampleMovingImage, bool);
  itkGetMacro(ResampleMovingImage, bool);

  itkSetMacro(ReinitializeSeed, bool);
  itkGetMacro(ReinitializeSeed, bool);

protected:

  void  GenerateData ();

  void ComputeDeformationField();

  void SetTransformParameters();

  void SetOptimizerParameters();

  void SetMetricParameters();


  int    m_GridSize;
  double m_CostFunctionConvergenceFactor;
  double m_ProjectedGradientTolerance;
  int    m_MaximumNumberOfIterations;
  int    m_MaximumNumberOfEvaluations;
  int    m_MaximumNumberOfCorrections;
  int    m_NumberOfHistogramBins;
  int    m_NumberOfSpatialSamples;
  int    m_CurrentIteration;
  bool   m_WriteInputs;
  bool   m_IsAborted;
  bool   m_ResampleMovingImage;
  bool   m_ReinitializeSeed;


  ////////////////////////////////
  // ITK Pipeline that does the job
  ////////////////////////////////

  // Transformer for moving image
  typename InputTransformType::Pointer      m_InputTransform;
  typename FixedImageType::PixelType        m_BackgroundLevel;

  typedef itk::ResampleImageFilter<
                                    MovingImageType,
                                    MovingImageType  >    ResampleFilterType;
  typename ResampleFilterType::Pointer           m_InputResampler;

  // Warper and interpolator
  typedef itk::WarpImageFilter<
                       MovingImageType,
                       MovingImageType,
                       DeformationFieldType>  WarperType;

  typedef itk::LinearInterpolateImageFunction<
                                   MovingImageType,
                                   double          >  InterpolatorType;

  typename WarperType::Pointer m_Warper;
  typename InterpolatorType::Pointer m_Interpolator;

  // Writer
  typedef itk::ImageFileWriter< FixedImageType  >    ImageWriterType;      
  typename ImageWriterType::Pointer m_Writer;


  // Transfrom
  typename TransformType::Pointer                m_Transform;

  // Optimizer
  typedef itk::LBFGSBOptimizer                   OptimizerType;
  typename OptimizerType::Pointer                m_Optimizer;

  // Interpolator
 typedef itk:: LinearInterpolateImageFunction< 
                                    MovingImageType,
                                    double          >    LinearInterpolatorType;
  typename LinearInterpolatorType::Pointer       m_LinearInterpolator;

  // Metric
  typedef itk::MattesMutualInformationImageToImageMetric< 
                                    FixedImageType, 
                                    MovingImageType >    MetricType;
  typename MetricType::Pointer                   m_Metric;

  // Registration
  typedef itk::ImageRegistrationMethod< 
                                    FixedImageType, 
                                    MovingImageType >    RegistrationType;
  typename RegistrationType::Pointer             m_Registration;

  typename ResampleFilterType::Pointer           m_Resampler;

  typename FixedImageType::Pointer               m_FixedImage;
  typename MovingImageType::Pointer              m_MovingImage;


  // Transform parameters
  typedef TransformType::ParametersType     ParametersType;
  ParametersType                        m_InitialParameters;
  ParametersType                        m_FinalParameters;

  // Deformation field
  typename DeformationFieldType::Pointer         m_DeformationField;

  // default constructor
  itkBSplineMattesMIRegistrationFilter(); 

  virtual ~itkBSplineMattesMIRegistrationFilter() {};
  
private:
  itkBSplineMattesMIRegistrationFilter(const itkBSplineMattesMIRegistrationFilter&);  // Not implemented.
  void operator=(const itkBSplineMattesMIRegistrationFilter&);  // Not implemented.
};

} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkBSplineMattesMIRegistrationFilter.txx"
#endif

 //ETX

#endif




