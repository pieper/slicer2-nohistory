#ifndef __itkDemonsTransformRegistrationFilter_txx
#define __itkDemonsTransformRegistrationFilter_txx


#include "itkDemonsTransformRegistrationFilter.h" // This class
#include <itkProgressAccumulator.h>
#include <itkAffineTransform.h> 

template <class TImageClass>
itk::itkDemonsTransformRegistrationFilter<TImageClass>::itkDemonsTransformRegistrationFilter()
{
  this->SetNumberOfRequiredInputs( 2 );  

  m_NumberOfIterations = UnsignedIntArray(1);
  m_NumberOfIterations.Fill(10);

  m_BackgroundLevel = 0;

  m_NumberOfHistogramLevels = 20;
  m_ThresholdAtMeanIntensity = true;

  m_StandardDeviations = 1.0;
  m_UpdateFieldStandardDeviations = 0.0;

  m_CurrentIteration = 0;
  m_WriteInputs = false;

  // registration pipeline

  // resample moving image
  m_Resampler = ResampleFilterType::New();

  typedef itk::AffineTransform<double, 3> InitTransformType;

  InitTransformType::Pointer transform = InitTransformType::New();
  transform->SetIdentity();
  m_Transform           = transform;

  m_FixedImageCaster   = FixedImageCasterType::New();
  m_MovingImageCaster  = MovingImageCasterType::New();

  // match the intensities of two images
  m_Matcher = MatchingFilterType::New();

  m_Matcher->SetNumberOfHistogramLevels( m_NumberOfHistogramLevels );
  m_Matcher->SetNumberOfMatchPoints( 7 );
  if (m_ThresholdAtMeanIntensity) {
    m_Matcher->ThresholdAtMeanIntensityOn();
  }

  m_Matcher->SetInput( m_MovingImageCaster->GetOutput() );
  m_Matcher->SetReferenceImage( m_FixedImageCaster->GetOutput() );

  // create Demons m_Filter
  m_Filter = RegistrationFilterType::New();
  //m_Filter->SetTimeStep( 1 );
  //m_Filte->SetConstraintWeight( 0.1 );

  m_MultiResFilter = MultiResRegistrationFilterType::New();
  m_MultiResFilter->SetRegistrationFilter( m_Filter );

  // set registration input
  m_MultiResFilter->SetFixedImage( m_FixedImageCaster->GetOutput() );
  m_MultiResFilter->SetMovingImage( m_Matcher->GetOutput() );

  // create wrapper
  m_Warper = WarperType::New();
  m_Interpolator = InterpolatorType::New();

  m_Warper->SetInterpolator( m_Interpolator );
  m_Warper->SetDeformationField( m_MultiResFilter->GetOutput() );

  // writer 
  m_Writer = ImageWriterType::New();

} // itkDemonsTransformRegistrationFilter

template <class TImageClass>
void itk::itkDemonsTransformRegistrationFilter<TImageClass>::GenerateData()
{
  itk::ProgressAccumulator::Pointer progress = itk::ProgressAccumulator::New();
  progress->SetMiniPipelineFilter(this);

  //progress->RegisterInternalFilter(m_Matcher,.1f);
  //progress->RegisterInternalFilter(m_Filter,1.f);
  //progress->RegisterInternalFilter(m_Warper,.1f);

  // resample moving image using transform

  m_Resampler->SetTransform( m_Transform );
  m_Resampler->SetInput( this->GetInput(1) );

  //FixedImageType::Pointer fixedImage = this->GetInput();
  m_Resampler->SetSize(    this->GetInput()->GetLargestPossibleRegion().GetSize() );
  m_Resampler->SetOutputOrigin(  this->GetInput()->GetOrigin() );
  m_Resampler->SetOutputSpacing( this->GetInput()->GetSpacing() );
  m_Resampler->SetDefaultPixelValue( m_BackgroundLevel );
  m_Resampler->Update();

  if (m_WriteInputs) {
    m_Writer->SetInput(this->GetInput());
    m_Writer->SetFileName( "demons_in_fixed.nrrd" );
    m_Writer->Update();
    m_Writer->SetInput(m_Resampler->GetOutput());
    m_Writer->SetFileName( "demons_in_moving.nrrd" );
    m_Writer->Update();
  }

  m_FixedImageCaster->SetInput( this->GetInput() );
  m_MovingImageCaster->SetInput( m_Resampler->GetOutput() );

  m_FixedImageCaster->Update();
  m_MovingImageCaster->Update();

  m_Matcher->SetNumberOfHistogramLevels( m_NumberOfHistogramLevels );
  m_Matcher->SetNumberOfMatchPoints( 7 );
  if (m_ThresholdAtMeanIntensity) {
    m_Matcher->ThresholdAtMeanIntensityOn();
  }
  else {
    m_Matcher->ThresholdAtMeanIntensityOff();
  }
  m_Matcher->Update();

  unsigned int *nIterations = new unsigned int [m_NumberOfLevels];

  for(int i=0; i< this->m_NumberOfIterations.GetNumberOfElements();i++) {
    nIterations[i] = m_NumberOfIterations.GetElement(i);
  }

  m_MultiResFilter->SetNumberOfLevels( m_NumberOfLevels );
  m_MultiResFilter->SetNumberOfIterations( nIterations );

  if (m_StandardDeviations > 0.001) {
    m_Filter->SetSmoothDeformationField (true);
    m_Filter->SetStandardDeviations( m_StandardDeviations );
  }
  else {
    m_Filter->SetSmoothDeformationField (false);

  }

  if (m_UpdateFieldStandardDeviations > 0.001) {
    m_Filter->SetSmoothUpdateField (true);
    m_Filter->SetUpdateFieldStandardDeviations ( m_UpdateFieldStandardDeviations );
  }
  else {
    m_Filter->SetSmoothUpdateField  (false);
  }

  if (m_WriteInputs) {
    m_Writer->SetInput(m_MultiResFilter->GetFixedImage());
    m_Writer->SetFileName( "demons_fixed.nrrd" );
    m_Writer->Update();
    m_Writer->SetInput(m_MultiResFilter->GetMovingImage());
    m_Writer->SetFileName( "demons_moving.nrrd" );
    m_Writer->Update();
  }

  // do the registartion
  try {
    m_MultiResFilter->Update();
  }
  catch( ProcessAborted & excp )
  {
    std::cout << "itkDemonsTransformRegistrationFilter:ProcessAborted caught !" << std::endl;
    std::cout << excp << std::endl;
  }
  //FixedImageType::Pointer fixedImage = this->GetInput();
  m_Warper->SetInput(this->GetInput(1));
  m_Warper->SetOutputSpacing( this->GetInput()->GetSpacing() );
  m_Warper->SetOutputOrigin( this->GetInput()->GetOrigin() );
  //m_Warper->Update();
  this->GraftOutput(m_Warper->GetOutput());
  delete [] nIterations;

  if (m_WriteInputs) {
    m_Writer->SetInput(m_Warper->GetOutput());
    m_Writer->SetFileName( "demons_out_xformed.nrrd" );
    m_Writer->Update();
  }


} // GenerateData

template <class TImageClass>
typename itk::itkDemonsTransformRegistrationFilter<TImageClass>::DeformationFieldType * 
itk::itkDemonsTransformRegistrationFilter<TImageClass>::GetDeformationField(void)
{
  return static_cast<DeformationFieldType *> (m_MultiResFilter->GetOutput());
} // GetDeformationField

template <class TImageClass>
unsigned long 
itk::itkDemonsTransformRegistrationFilter<TImageClass>::AddIterationObserver (itk::Command *observer ) 
{
  return m_Filter->AddObserver( itk::IterationEvent(), observer );
}


#endif
