#ifndef __itkTransformRegistrationFilter_txx
#define __itkTransformRegistrationFilter_txx

#include "itkTransformRegistrationFilter.h" // This class
#include "itkProgressAccumulator.h"

#define WRITE_INPUTS 0

namespace itk
{

template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
itk::itkTransformRegistrationFilter<TImageClass, TOptimizerClass, TTransformerClass, TMetricClass >::itkTransformRegistrationFilter()
{
  this->SetNumberOfRequiredInputs( 2 );  

  // registration pipeline

  m_FixedImagePyramid  = FixedImagePyramidType::New();
  m_MovingImagePyramid = MovingImagePyramidType::New();

  m_Metric              = MetricType::New();
  m_Transform           = TransformType::New();
  m_Optimizer           = OptimizerType::New();
  m_LinearInterpolator  = LinearInterpolatorType::New();
  m_NearestInterpolator = NearestInterpolatorType::New();
  
  m_Registration  = RegistrationType::New();
  
  m_Registration->SetOptimizer(     m_Optimizer     );
  m_Registration->SetInterpolator(  m_LinearInterpolator  );
  m_Registration->SetMetric(        m_Metric        );
  m_Registration->SetTransform(     m_Transform     );

  m_Registration->SetFixedImagePyramid(m_FixedImagePyramid);
  m_Registration->SetMovingImagePyramid(m_MovingImagePyramid);

  m_BackgroundLevel = itk::NumericTraits< typename TImageClass::PixelType >::Zero;

  m_Resampler = ResampleFilterType::New();

  // Default parameters
  m_NumberOfLevels = 1;
  m_TranslationScale = 0.001;

  m_FixedImageShrinkFactors.Fill(1);     
  m_MovingImageShrinkFactors.Fill(1);

  m_NumberOfIterations = UnsignedIntArray(1);
  m_NumberOfIterations.Fill(10);

  m_InitialParameters = ParametersType(m_Transform->GetNumberOfParameters());
  m_InitialParameters.Fill(0.0);

  // Specific parameters must be set in the subclass
  // for example:
  //m_Metric->SetNumberOfHistogramBins( 256 );
  //m_Metric->SetNumberOfSpatialSamples( 100000 );
  //m_LearningRates = DoubleArray(1);
  //m_LearningRates.Fill(1e-4);
  //m_InitialParameters[3] = 1.0;

  m_ResampleMovingImage = false;
  m_IsAborted = false;

  // writer 
  m_WriterFixed = FixedImageWriterType::New();
  m_WriterMoving = MovingImageWriterType::New();

} // itkTransformRegistrationFilter

template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
void 
itk::itkTransformRegistrationFilter<TImageClass, TOptimizerClass, TTransformerClass, TMetricClass >::GenerateData()
{
  itk::ProgressAccumulator::Pointer progress = itk::ProgressAccumulator::New();
  progress->SetMiniPipelineFilter(this);
  progress->RegisterInternalFilter(m_Registration,1.f);
  
  // set registration input
  m_Registration->SetFixedImage(  this->GetInput() );
  m_Registration->SetMovingImage( this->GetInput(1) );

  m_Registration->SetFixedImageRegion( this->GetInput()->GetBufferedRegion() );

  m_FixedImagePyramid->SetNumberOfLevels(m_NumberOfLevels);
  m_FixedImagePyramid->SetStartingShrinkFactors(m_FixedImageShrinkFactors.GetDataPointer());

  m_MovingImagePyramid->SetNumberOfLevels(m_NumberOfLevels);
  m_MovingImagePyramid->SetStartingShrinkFactors( m_MovingImageShrinkFactors.GetDataPointer());

  m_Registration->SetNumberOfLevels( m_NumberOfLevels);
  
  // TODO: set number iteration per level
  //m_Optimizer->SetNumberOfIterations( m_NumberOfIterations[0] );

  SetOptimizerParamters();
  SetMetricParamters();
  
  m_Registration->SetInitialTransformParameters( m_Transform->GetParameters() );
  
  if (WRITE_INPUTS) {
    m_WriterFixed->SetInput(this->GetInput());
    m_WriterFixed->SetFileName( "linear_in_fixed.nrrd" );
    m_WriterFixed->Update();
    m_WriterMoving->SetInput( this->GetInput(1));
    m_WriterMoving->SetFileName( "linear_in_moving.nrrd" );
    m_WriterMoving->Update();
  }

  try { 
    m_Registration->StartRegistration(); 
  } 
  catch( itk::ExceptionObject & err ) { 
    std::cout << "itkTransformRegistrationFilter:ExceptionObject caught !" << std::endl; 
    std::cout << err << std::endl; 
  } 

  m_FinalParameters = m_Registration->GetLastTransformParameters();
  m_Transform->SetParameters( m_FinalParameters ); 

  if (m_ResampleMovingImage) {
     this->GraftOutput(GetTransformedOutput());
  }

} // GenerateData

template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
TImageClass* 
itkTransformRegistrationFilter<TImageClass, TOptimizerClass,  TTransformerClass, TMetricClass >
::GetTransformedOutput () 
{
  m_Resampler->SetTransform( m_Transform );
  m_Resampler->SetInput( this->GetInput(1) );

  //FixedImageType::Pointer fixedImage = this->GetInput();
  m_Resampler->SetSize(    this->GetInput()->GetLargestPossibleRegion().GetSize() );
  m_Resampler->SetOutputOrigin(  this->GetInput()->GetOrigin() );
  m_Resampler->SetOutputSpacing( this->GetInput()->GetSpacing() );
  m_Resampler->SetDefaultPixelValue( m_BackgroundLevel );
  m_Resampler->Update();

  return m_Resampler->GetOutput();
}

template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
void
itkTransformRegistrationFilter<TImageClass, TOptimizerClass,  TTransformerClass, TMetricClass >
::SetTransform(const TransformType * transform)
{
  //m_Transform->SetCenter( transform->GetCenter() );
  m_Transform->SetParameters( transform->GetParameters() );
}


template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
void
itkTransformRegistrationFilter<TImageClass, TOptimizerClass,  TTransformerClass, TMetricClass >::GetTransform(typename itkTransformRegistrationFilter<TImageClass, TOptimizerClass,
TTransformerClass, TMetricClass >::TransformType * transform)
{
  transform->SetParameters( m_Registration->GetLastTransformParameters() );
  //transform->SetCenter( m_Transform->GetCenter() );
  //transform->SetParameters( m_Transform->GetParameters() );
  return;
}

template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
void
itkTransformRegistrationFilter<TImageClass, TOptimizerClass,  TTransformerClass, TMetricClass >::GetCurrentTransform(typename itkTransformRegistrationFilter<TImageClass, TOptimizerClass,
TTransformerClass, TMetricClass >::TransformType * transform)
{
  //transform->SetCenter( m_Transform->GetCenter() );
  transform->SetParameters( m_Transform->GetParameters() );
  return;
}


template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
unsigned long 
itk::itkTransformRegistrationFilter<TImageClass, TOptimizerClass, TTransformerClass, TMetricClass >::AddIterationObserver (itk::Command *observer ) 
{
  m_Optimizer->AddObserver( itk::IterationEvent(), observer );
  return m_Optimizer->AddObserver( itk::EndEvent(), observer );
}

template <class TImageClass, class TOptimizerClass, class TTransformerClass, class TMetricClass >
double 
itk::itkTransformRegistrationFilter<TImageClass, TOptimizerClass, TTransformerClass, TMetricClass >::GetMetricValue()
{
  return m_Optimizer->GetValue();
}
} // namespace itk

#endif /* _itkTransformRegistrationFilter__txx */
