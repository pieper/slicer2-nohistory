#ifndef __itkBSplineMattesMIRegistrationFilter_txx
#define __itkBSplineMattesMIRegistrationFilter_txx


#include "itkBSplineMattesMIRegistrationFilter.h" // This class
#include <itkProgressAccumulator.h>
#include <itkAffineTransform.h> 
#include <itkImageFileReader.h>

template <class TImageClass>
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::itkBSplineMattesMIRegistrationFilter()
{
  this->SetNumberOfRequiredInputs( 2 );  
  this->SetNumberOfRequiredOutputs( 2 );

  m_GridSize = 8;
  m_CostFunctionConvergenceFactor = 1e+7;
  m_ProjectedGradientTolerance = 1e-4;
  m_MaximumNumberOfIterations = 500;
  m_MaximumNumberOfEvaluations = 500;
  m_MaximumNumberOfCorrections = 12;
  m_NumberOfHistogramBins = 50;
  m_NumberOfSpatialSamples = 100000;
  m_BackgroundLevel = 0;   

  m_CurrentIteration = 0;
  m_WriteInputs = false;

  // registration pipeline
  m_Metric              = MetricType::New();
  m_Transform           = TransformType::New();
  m_Optimizer           = OptimizerType::New();
  m_LinearInterpolator  = LinearInterpolatorType::New();
  
  m_Registration  = RegistrationType::New();
  
  m_Registration->SetOptimizer(     m_Optimizer     );
  m_Registration->SetInterpolator(  m_LinearInterpolator  );
  m_Registration->SetMetric(        m_Metric        );
  m_Registration->SetTransform(     m_Transform     );

  // resample moving image
  m_InputResampler = ResampleFilterType::New();

  typedef itk::AffineTransform<double, 3> InputTransformType;

  InputTransformType::Pointer transform = InputTransformType::New();
  transform->SetIdentity();
  m_InputTransform           = transform;

  // create wrapper
  m_Warper = WarperType::New();
  m_Interpolator = InterpolatorType::New();

  m_Warper->SetInterpolator( m_Interpolator );

  // writer 
  m_Writer = ImageWriterType::New();
  m_ResampleMovingImage = false;
  m_IsAborted = false;

  this->GraftNthOutput(0, m_Warper->GetOutput());

  // Deformation output
  //m_DeformationField = DeformationFieldType::New();
  typename DeformationFieldType::Pointer deformationField = DeformationFieldType::New();
  this->SetNthOutput( 1, deformationField.GetPointer() );

} // itkBSplineMattesMIRegistrationFilter

template <class TImageClass>
void itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::GenerateData()
{
  itk::ProgressAccumulator::Pointer progress = itk::ProgressAccumulator::New();
  progress->SetMiniPipelineFilter(this);
  progress->RegisterInternalFilter(m_Registration,1.f);
  
  // resample moving image using transform
  
  m_InputResampler->SetTransform( m_InputTransform );
  m_InputResampler->SetInput( this->GetInput(1) );

  m_InputResampler->SetSize(    this->GetInput()->GetLargestPossibleRegion().GetSize() );
  m_InputResampler->SetOutputOrigin(  this->GetInput()->GetOrigin() );
  m_InputResampler->SetOutputSpacing( this->GetInput()->GetSpacing() );
  m_InputResampler->SetDefaultPixelValue( m_BackgroundLevel );
  m_InputResampler->Update();
  
  
  // set registration input
  m_Registration->SetFixedImage( this->GetInput() );
  m_Registration->SetMovingImage( m_InputResampler->GetOutput() );
  
  m_Registration->SetFixedImageRegion( this->GetInput()->GetBufferedRegion() );
  
  SetTransformParameters();
  SetOptimizerParameters();
  SetMetricParameters();
  
  m_Registration->SetInitialTransformParameters( m_Transform->GetParameters() );
  
  if (m_WriteInputs) {
    m_Writer->SetInput(m_Registration->GetFixedImage());
    m_Writer->SetFileName( "bspline_fixed.nrrd" );
    m_Writer->Update();
    m_Writer->SetInput(m_Registration->GetMovingImage());
    m_Writer->SetFileName( "bspline_moving.nrrd" );
    m_Writer->Update();
  }
  
  // do the registartion
  try { 
    m_Registration->StartRegistration(); 
  } 
  catch( ProcessAborted & excp ) {
    std::cout << "itkBSplineMattesMIRegistrationFilter:ProcessAborted caught !" << std::endl;
    std::cout << excp << std::endl;
  }
  catch( itk::ExceptionObject & err ) { 
    std::cout << "itkTransformRegistrationFilter:ExceptionObject caught !" << std::endl; 
    std::cout << err << std::endl; 
  } 
  
  m_FinalParameters = m_Registration->GetLastTransformParameters();
  m_Transform->SetParameters( m_FinalParameters ); 
  
  this->ComputeDeformationField();
  
  //FixedImageType::Pointer fixedImage = this->GetInput();
  m_Warper->SetDeformationField(m_DeformationField);
  m_Warper->SetInput(this->GetInput(1));
  m_Warper->SetOutputSpacing( this->GetInput()->GetSpacing() );
  m_Warper->SetOutputOrigin( this->GetInput()->GetOrigin() );
  //m_Warper->Update();
  this->GraftNthOutput(0, m_Warper->GetOutput());

  if (m_WriteInputs) {
    m_Writer->SetInput(m_Warper->GetOutput());
    m_Writer->SetFileName( "bspline_out_xformed.nrrd" );
    m_Writer->Update();
  }
  
} // GenerateData

template <class TImageClass>
typename itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::DeformationFieldType * 
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::GetDeformationField(void)
{
  /**
  typedef itk::ImageFileReader< DeformationFieldType  > ImageReaderType;
  static ImageReaderType::Pointer  imageReader  = ImageReaderType::New();
  imageReader->SetFileName("disp_field.vtk");
  imageReader->Update();
  return static_cast<DeformationFieldType *> (imageReader->GetOutput());
  **/
  //return static_cast<DeformationFieldType *> (m_DeformationField);

  return static_cast<DeformationFieldType *> (this->ProcessObject::GetOutput(1));

} // GetDeformationField

template <class TImageClass>
unsigned long 
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::AddIterationObserver (itk::Command *observer ) 
{
  return m_Optimizer->AddObserver( itk::IterationEvent(), observer );
} // AddIterationObserver

template <class TImageClass>
void
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::ComputeDeformationField()
{
  typename DeformationFieldType::Pointer deformationField = this->GetDeformationField();

  typename FixedImageType::Pointer inputImage = 
    dynamic_cast< FixedImageType  *>( ProcessObject::GetInput(0) );

  typename FixedImageType::RegionType fixedRegion = inputImage->GetBufferedRegion();
  
  deformationField->SetLargestPossibleRegion(inputImage->GetLargestPossibleRegion() );
  
  deformationField->SetBufferedRegion(inputImage->GetBufferedRegion() );
  
  deformationField->SetRequestedRegion( inputImage->GetRequestedRegion() );

  deformationField->SetRegions( fixedRegion );
  deformationField->SetOrigin( this->GetInput()->GetOrigin() );
  deformationField->SetSpacing( this->GetInput()->GetSpacing() );
  deformationField->Allocate();
  
  typedef itk::ImageRegionIterator< DeformationFieldType > FieldIterator;
  FieldIterator fi(  deformationField, fixedRegion );
  
  fi.GoToBegin();
  
  TransformType::InputPointType  fixedPoint;
  TransformType::OutputPointType movingPoint;
  DeformationFieldType::IndexType index;
  
  VectorPixelType displacement;
  
  while( ! fi.IsAtEnd() ) {
    index = fi.GetIndex();
    deformationField->TransformIndexToPhysicalPoint( index, fixedPoint );
    movingPoint = m_Transform->TransformPoint( fixedPoint );
    displacement[0] = fixedPoint[0] - movingPoint[0];
    displacement[1] = fixedPoint[1] - movingPoint[1];
    displacement[2] = fixedPoint[2] - movingPoint[2];
    fi.Set( displacement );
    ++fi;
  }
  
} // ComputeDeformationField

template <class TImageClass>
void
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::SetTransformParameters()
{
  typedef TransformType::RegionType RegionType;
  RegionType bsplineRegion;
  typename RegionType::SizeType   gridSizeOnImage;
  typename RegionType::SizeType   gridBorderSize;
  typename RegionType::SizeType   totalGridSize;

  gridSizeOnImage.Fill( m_GridSize );
  gridBorderSize.Fill( 3 );    // Border for spline order = 3 ( 1 lower, 2 upper )
  totalGridSize = gridSizeOnImage + gridBorderSize;

  bsplineRegion.SetSize( totalGridSize );

  typedef TransformType::SpacingType SpacingType;
  SpacingType spacing = this->GetInput()->GetSpacing();

  typedef TransformType::OriginType OriginType;
  OriginType origin = this->GetInput()->GetOrigin();

  typename FixedImageType::SizeType fixedImageSize;
  fixedImageSize = this->GetInput()->GetBufferedRegion().GetSize();

  for(unsigned int r=0; r < 3; r++)
    {
    spacing[r] *= floor( static_cast<double>(fixedImageSize[r] - 1)  / 
                  static_cast<double>(gridSizeOnImage[r] - 1) );
    origin[r]  -=  spacing[r]; 
    }

  m_Transform->SetGridSpacing( spacing );
  m_Transform->SetGridOrigin( origin );
  m_Transform->SetGridRegion( bsplineRegion );
  

  typedef TransformType::ParametersType     ParametersType;

  const unsigned int numberOfParameters =
               m_Transform->GetNumberOfParameters();
  
  ParametersType parameters( numberOfParameters );

  parameters.Fill( 0.0 );

  m_InitialParameters = parameters;
  m_Transform->SetParameters( m_InitialParameters );

} //SetTransformParameters

template <class TImageClass>
void
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::SetOptimizerParameters()
{
  OptimizerType::BoundSelectionType boundSelect( m_Transform->GetNumberOfParameters() );
  OptimizerType::BoundValueType upperBound( m_Transform->GetNumberOfParameters() );
  OptimizerType::BoundValueType lowerBound( m_Transform->GetNumberOfParameters() );

  boundSelect.Fill( 0 );
  upperBound.Fill( 0.0 );
  lowerBound.Fill( 0.0 );

  m_Optimizer->SetBoundSelection( boundSelect );
  m_Optimizer->SetUpperBound( upperBound );
  m_Optimizer->SetLowerBound( lowerBound );

  m_Optimizer->SetCostFunctionConvergenceFactor( m_CostFunctionConvergenceFactor );
  m_Optimizer->SetProjectedGradientTolerance( m_ProjectedGradientTolerance );
  m_Optimizer->SetMaximumNumberOfIterations( m_MaximumNumberOfIterations );
  m_Optimizer->SetMaximumNumberOfEvaluations( m_MaximumNumberOfEvaluations );
  m_Optimizer->SetMaximumNumberOfCorrections( m_MaximumNumberOfCorrections );

} //SetOptimizerParamters

template <class TImageClass>
void
itk::itkBSplineMattesMIRegistrationFilter<TImageClass>::SetMetricParameters()
{
  m_Metric->SetNumberOfHistogramBins( m_NumberOfHistogramBins );
  m_Metric->SetNumberOfSpatialSamples( m_NumberOfSpatialSamples );

  if (m_ReinitializeSeed) {
    m_Metric->ReinitializeSeed( 76926294 );
  }
} //SetMetricParamters

#endif
