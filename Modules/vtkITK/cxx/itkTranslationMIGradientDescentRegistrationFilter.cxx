/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkTranslationMIGradientDescentRegistrationFilter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#include "itkTranslationMIGradientDescentRegistrationFilter.h"

itk::itkTranslationMIGradientDescentRegistrationFilter::itkTranslationMIGradientDescentRegistrationFilter()
{
  m_LearningRate = DoubleArray(1);
  m_LearningRate.Fill( 1e-4);
  m_NumberOfSpatialSamples = 100;
  m_StandardDeviation = 0.4;

  itkTranslationMIGradientDescentRegistrationCommand::Pointer observer = itkTranslationMIGradientDescentRegistrationCommand::New();
  observer->SetRegistrationFilter(this);
  m_Optimizer->AddObserver( itk::IterationEvent(), observer );
  m_Optimizer->AddObserver( itk::EndEvent(), observer );

  m_Optimizer->MaximizeOn();
}


void
itk::itkTranslationMIGradientDescentRegistrationFilter::SetOptimizerParamters()
{

  typedef OptimizerType::ScalesType       OptimizerScalesType;
  OptimizerScalesType optimizerScales( m_Transform->GetNumberOfParameters() );
  optimizerScales.Fill(1.0);

  m_Optimizer->SetScales( optimizerScales );
  m_Optimizer->SetLearningRate( m_LearningRate(0) ); 

  m_Optimizer->SetNumberOfIterations( m_NumberOfIterations[0]);

}

void
itk::itkTranslationMIGradientDescentRegistrationFilter::SetMetricParamters()
{
  m_Metric->SetFixedImageStandardDeviation ( m_StandardDeviation );
  m_Metric->SetMovingImageStandardDeviation ( m_StandardDeviation );
  m_Metric->SetNumberOfSpatialSamples( m_NumberOfSpatialSamples );
}

