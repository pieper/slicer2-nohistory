/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: MIMApplicationBase.txx,v $
  Language:  C++
  Date:      $Date: 2003/12/07 22:32:40 $
  Version:   $Revision: 1.1 $

  Copyright (c) 2002 Insight Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef _MIMApplicationBase_txx
#define _MIMApplicationBase_txx

#include "MIMApplicationBase.h"

namespace itk
{

template < typename TInputImage, typename TImage,
  typename TParser, typename TPreprocessor,
  typename TRegistrator, typename TGenerator >
MIMApplicationBase<TInputImage,TImage,TParser,TPreprocessor,
  TRegistrator, TGenerator>
::MIMApplicationBase()
{
  m_Parser       = ParserType::New();
  m_Preprocessor = PreprocessorType::New();
  m_Registrator  = RegistratorType::New();
  m_Generator    = GeneratorType::New();

  m_Transform     = AffineTransformType::New();
  m_ReSampleTrans = AffineTransformType::New();

  // Set the ResampleTrans to try and recover
  typename AffineTransformType::OffsetType offset;
  typename AffineTransformType::OutputVectorType rot_axis;
  
  offset[0] = 0;
  offset[1] = 15.0;
  offset[2] = 0;

  rot_axis[0] = rot_axis[1] = rot_axis[2] = 1;

  m_ReSampleTrans->SetIdentity();
  m_ReSampleTrans->Rotate3D(rot_axis,0.02777); // about 5 degrees
  m_ReSampleTrans->SetOffset( offset );
  std::cout << m_ReSampleTrans << std::endl;

  m_Parser->SetReSampleTrans(m_ReSampleTrans);
}

template < typename TInputImage, typename TImage,
  typename TParser, typename TPreprocessor,
  typename TRegistrator, typename TGenerator >
void
MIMApplicationBase<TInputImage,TImage,TParser,TPreprocessor,
  TRegistrator, TGenerator>
::Execute()
{

  /**************************
   * Parse input
   **************************/
  std::cout << "Parsing input ... " << std::endl;
  
  try
    {
    this->InitializeParser();
    m_Parser->Execute();
    }
  catch(itk::ExceptionObject & eo)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "itk::ExceptionObject caught" << std::endl;
    std::cout << eo << std::endl;
    throw;
    }
  catch(std::exception & e)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "std::exception caught" << std::endl;
    std::cout << e.what() << std::endl;
    throw;
    }
  catch(...)
   {
   std::cout << "Error occurred during input parsing." << std::endl;
   throw;
   }

  /**************************
   * Preprocess the images before registration
   **************************/

  std::cout << "Preprocess the images ... " << std::endl;

  try
    {
    this->InitializePreprocessor();
    m_Preprocessor->Execute();
    }
  catch(itk::ExceptionObject & eo)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "itk::ExceptionObject caught" << std::endl;
    std::cout << eo << std::endl;
    throw;
    }
  catch(std::exception & e)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "std::exception caught" << std::endl;
    std::cout << e.what() << std::endl;
    throw;
    }
  catch(...)
    {
    std::cout << "Error occured during preprocessing." << std::endl;
    throw;
    }


  /**************************
   * Registered the processed images
   **************************/
  std::cout << "Register the images ... " << std::endl;

  try
    {
    this->InitializeRegistrator();
    m_Registrator->Execute();
    }
  catch(itk::ExceptionObject & eo)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "itk::ExceptionObject caught" << std::endl;
    std::cout << eo << std::endl;
    throw;
    }
  catch(std::exception & e)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "std::exception caught" << std::endl;
    std::cout << e.what() << std::endl;
    throw;
    }
  catch(...)
    {
    std::cout << "Error occured during registration" << std::endl;
    throw;
    }

  // Get the results
  std::cout << "Final parameters: " 
            << m_Registrator->GetTransformParameters() << std::endl;


  /***************************
   * Compute overall transform
   ***************************/
  // compose the preprocess and registration transforms
  m_Transform->SetIdentity();
  m_Transform->Compose( m_Preprocessor->GetPostTransform(), true );
  m_Transform->Compose( m_Registrator->GetAffineTransform(), true );
  m_Transform->Compose( m_Preprocessor->GetPreTransform(), true );

  std::cout << "Overall transform matrix: " << std::endl;
  std::cout << m_Transform->GetMatrix() << std::endl;
  std::cout << "Overall transform offset: " << std::endl;
  std::cout << m_Transform->GetOffset() << std::endl;


  std::cout << m_ReSampleTrans << std::endl;
  std::cout << m_Transform     << std::endl;
    
  m_Transform->Compose( m_ReSampleTrans, true );
  std::cout << m_Transform     << std::endl;
  double metric = m_Transform->Metric();

  if (metric>0.05)
    {
      std::cout << "Did not capture transform well!" << std::endl;
      std::cout << "Metric was bigger than 0.05. It was: " << metric << std::endl;
      throw;
    }
  else
    {
      std::cout << "OK!" << std::endl;
    }

  /**************************
   * Generating output
   **************************/
  // std::cout << "Generating output ... " << std::endl;
  
  try
    {
    this->InitializeGenerator();
    m_Generator->Execute();
    }
  catch(itk::ExceptionObject & eo)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "itk::ExceptionObject caught" << std::endl;
    std::cout << eo << std::endl;
    throw;
    }
  catch(std::exception & e)
    {
    std::cout << "Error occured during registration" << std::endl;
    std::cout << "std::exception caught" << std::endl;
    std::cout << e.what() << std::endl;
    throw;
    }
  catch(...)
   {
   std::cout << "Error occurred during output generation." << std::endl;
   throw;
   }

}


template < typename TInputImage, typename TImage,
  typename TParser, typename TPreprocessor,
  typename TRegistrator, typename TGenerator >
void
MIMApplicationBase<TInputImage,TImage,TParser,TPreprocessor,
  TRegistrator, TGenerator>
::InitializePreprocessor()
{
  m_Preprocessor->SetInputFixedImage( m_Parser->GetFixedImage() );
  m_Preprocessor->SetInputMovingImage( m_Parser->GetMovingImage() );

  m_Preprocessor->SetPermuteOrder( m_Parser->GetPermuteOrder() );
  m_Preprocessor->SetFlipAxes( m_Parser->GetFlipAxes() );
}


template < typename TInputImage, typename TImage,
  typename TParser, typename TPreprocessor,
  typename TRegistrator, typename TGenerator >
void
MIMApplicationBase<TInputImage,TImage,TParser,TPreprocessor,
  TRegistrator, TGenerator>
::InitializeRegistrator()
{

  // connect the images
  m_Registrator->SetFixedImage( m_Preprocessor->GetOutputFixedImage() );
  m_Registrator->SetMovingImage( m_Preprocessor->GetOutputMovingImage() );

  // set multiresolution related parameters
  m_Registrator->SetNumberOfLevels( m_Parser->GetNumberOfLevels() );

  m_Registrator->SetFixedImageShrinkFactors( m_Parser->GetFixedImageShrinkFactors() );

  // permute the shrink factors
  unsigned int permutedFactors[ImageDimension];
  for ( unsigned int j = 0; j < ImageDimension; j++ )
    {
    permutedFactors[j] = m_Parser->GetMovingImageShrinkFactors()[
      m_Parser->GetPermuteOrder()[j] ];
    }
  m_Registrator->SetMovingImageShrinkFactors( permutedFactors );

  m_Registrator->SetNumberOfIterations( m_Parser->GetNumberOfIterations() );
  m_Registrator->SetLearningRates( m_Parser->GetLearningRates() );

  double scale = 1.0 / vnl_math_sqr( m_Parser->GetTranslationScale() );
  m_Registrator->SetTranslationScale( scale );

}

} // namespace itk

#endif


