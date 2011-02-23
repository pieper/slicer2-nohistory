/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkDemonsRegistrationImageFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#include "itkDemonsRegistrationImageFilter.h" // This class
#include "itkProgressAccumulator.h"

itk::itkDemonsRegistrationImageFilter::itkDemonsRegistrationImageFilter()
{
  this->SetNumberOfRequiredInputs( 2 );  

  m_NumIterations = 100;
  m_StandardDeviations = 1.0;
  m_CurrentIteration = 0;

  // registration pipeline
  m_FixedImageCaster   = FixedImageCasterType::New();
  m_MovingImageCaster  = MovingImageCasterType::New();

  // first match the intensities of two images
  m_Matcher = MatchingFilterType::New();

  m_Matcher->SetNumberOfHistogramLevels( 1024 );
  m_Matcher->SetNumberOfMatchPoints( 7 );
  m_Matcher->ThresholdAtMeanIntensityOn();

  m_Matcher->SetInput( m_MovingImageCaster->GetOutput() );
  m_Matcher->SetReferenceImage( m_FixedImageCaster->GetOutput() );

  // create Demons m_Filter
  m_Filter = RegistrationFilterType::New();

  // set registration input
  m_Filter->SetFixedImage( m_FixedImageCaster->GetOutput() );
  m_Filter->SetMovingImage( m_Matcher->GetOutput() );

  // create wrapper
  m_Warper = WarperType::New();
  m_Interpolator = InterpolatorType::New();

  m_Warper->SetInterpolator( m_Interpolator );
  m_Warper->SetDeformationField( m_Filter->GetOutput() );

} // itkDemonsRegistrationImageFilter


void itk::itkDemonsRegistrationImageFilter::GenerateData()
{
  itk::ProgressAccumulator::Pointer progress = itk::ProgressAccumulator::New();
  progress->SetMiniPipelineFilter(this);

  //progress->RegisterInternalFilter(m_Matcher,.1f);
  progress->RegisterInternalFilter(m_Filter,1.f);
  //progress->RegisterInternalFilter(m_Warper,.1f);

  m_FixedImageCaster->SetInput( this->GetInput() );
  m_MovingImageCaster->SetInput( this->GetInput(1) );

  m_FixedImageCaster->Update();
  m_MovingImageCaster->Update();

  m_Matcher->Update();

  // set registration parameters
  if (m_Filter->GetNumberOfIterations() != m_NumIterations ) {
    m_Filter->SetNumberOfIterations( m_NumIterations );
  }
  const double *stddev = m_Filter->GetStandardDeviations();
  if ( stddev[0] != m_StandardDeviations ) {
    m_Filter->SetStandardDeviations( m_StandardDeviations );
  }
  m_Filter->Update();

  //FixedImageType::Pointer fixedImage = this->GetInput();
  m_Warper->SetInput(this->GetInput(1));
  m_Warper->SetOutputSpacing( this->GetInput()->GetSpacing() );
  m_Warper->SetOutputOrigin( this->GetInput()->GetOrigin() );
  m_Warper->Update();
  this->GraftOutput(m_Warper->GetOutput());

} // GenerateData

itk::itkDemonsRegistrationImageFilter::DeformationFieldType * 
itk::itkDemonsRegistrationImageFilter::GetDeformationField(void)
{
  return static_cast<DeformationFieldType *> (m_Filter->GetOutput());
} // GetDeformationField

unsigned long 
itk::itkDemonsRegistrationImageFilter::AddIterationObserver (itk::Command *observer ) 
{
  return m_Filter->AddObserver( itk::IterationEvent(), observer );
}
