/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: itkBayesianClassificationImageFilter.txx,v $
  Language:  C++
  Date:      $Date: 2007/08/15 05:13:43 $
  Version:   $Revision: 1.2 $

  Copyright (c) Insight Software Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

  Portions of this code are covered under the VTK copyright.
  See VTKCopyright.txt or http://www.kitware.com/VTKCopyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef _itkBayesianClassificationImageFilter_txx
#define _itkBayesianClassificationImageFilter_txx

#include "itkBayesianClassificationImageFilter.h"

namespace itk
{

template < class TInputImage, class TLabelImage, class TMaskImage >
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::BayesianClassificationImageFilter()
  : m_NumberOfClasses( 0 ),
    m_NumberOfSmoothingIterations( 0 )
{
  m_Initializer = BayesianInitializerType::New();
  m_Classifier  = ClassifierFilterType::New();
}

template < class TInputImage, class TLabelImage, class TMaskImage >
void
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::SetInput(const InputImageType* image) 
{ 
  // Process object is not const-correct so the const_cast is required here
  this->ProcessObject::SetNthInput(0, 
                                   const_cast< InputImageType* >( image ) );
}

template < class TInputImage, class TLabelImage, class TMaskImage >
void
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::SetMaskImage(const MaskImageType* image) 
{ 
  // Process object is not const-correct so the const_cast is required here
  this->ProcessObject::SetNthInput(1, 
                                   const_cast< MaskImageType* >( image ) );
}

template < class TInputImage, class TLabelImage, class TMaskImage >
const TInputImage*
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::GetInput() const
{
  if (this->GetNumberOfInputs() < 1)
    {
    return 0;
    }
  
  return static_cast<const InputImageType * >
    (this->ProcessObject::GetInput(0) );
}  

template < class TInputImage, class TLabelImage, class TMaskImage >
const TMaskImage*
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::GetMaskImage() const
{
  if (this->GetNumberOfInputs() < 2)
    {
    return 0;
    }
  
  return static_cast<const MaskImageType * >
    (this->ProcessObject::GetInput(1) );
}  

template < class TInputImage, class TLabelImage, class TMaskImage >
void
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::GenerateData()
{
  InputImageType *input = const_cast< InputImageType * >(this->GetInput());
  MaskImageType *maskImage = NULL;

  if (this->GetNumberOfInputs() > 1 && this->GetMaskImage() != NULL)
    {
    maskImage = const_cast< MaskImageType * >(this->GetMaskImage());
    }

  // TODO Minipipeline could use a progress accumulator
  if( maskImage ) // mask specified
    {
    m_Initializer->SetMaskImage( maskImage );
    m_Initializer->SetMaskValue( this->m_MaskValue );
    }
  m_Initializer->SetInput( input );
  m_Initializer->SetNumberOfClasses( this->GetNumberOfClasses() );
  m_Initializer->Update();
  
  m_Classifier->SetInput( m_Initializer->GetOutput() );
  m_Classifier->SetNumberOfSmoothingIterations( 
    this->GetNumberOfSmoothingIterations() );

  // Assume that the smoothing filter is Anisotropic diffusion..
  // make this an option to switch between curvature flow - 
  // anisotropic diffusion etc....
  typedef typename ClassifierFilterType::ExtractedComponentImageType 
    ExtractedComponentImageType; 
  typedef itk::GradientAnisotropicDiffusionImageFilter<
  ExtractedComponentImageType, ExtractedComponentImageType >  SmoothingFilterType;
  typename SmoothingFilterType::Pointer smoother = SmoothingFilterType::New();
  smoother->SetNumberOfIterations( 1 );
  smoother->SetTimeStep( 0.0625 );
  smoother->SetConductanceParameter( 3 );  
  m_Classifier->SetSmoothingFilter( smoother );
  m_Classifier->Update();

  OutputImagePointer relabeledImage = m_Classifier->GetOutput();
  ImageRegionType imageRegion = m_Classifier->GetOutput()->GetBufferedRegion();
  RelabeledImageIteratorType    itrRelabeledImage( relabeledImage, imageRegion );

  m_Classifier->GetOutput()->DisconnectPipeline();

  // Relabel the output image
  if( maskImage )
    {
    MaskImageIteratorType  itrMaskImage( this->GetMaskImage(), this->GetMaskImage()->GetBufferedRegion() );
    if( (int)this->GetNumberOfClasses() == 2 )
      {
      for( itrRelabeledImage.GoToBegin(), itrMaskImage.GoToBegin();
           !itrRelabeledImage.IsAtEnd();
           ++itrRelabeledImage, ++itrMaskImage )
        {
        if( (int)itrMaskImage.Get() == (int)this->GetMaskValue() )
          {
          if( (int)itrRelabeledImage.Get() == 0 )
            {
            itrRelabeledImage.Set( 3 );
            }
          else if( (int)itrRelabeledImage.Get() == 1 )
            {
            itrRelabeledImage.Set( 4 );
            }
          }
        else
          {
          itrRelabeledImage.Set( 0 );
          }
        }
      }
    else if( (int)this->GetNumberOfClasses() == 3 )
      {
      for( itrRelabeledImage.GoToBegin(), itrMaskImage.GoToBegin();
           !itrRelabeledImage.IsAtEnd();
           ++itrRelabeledImage, ++itrMaskImage )
        {
        if( (int)itrMaskImage.Get() == (int)this->GetMaskValue() )
          {
          if( (int)itrRelabeledImage.Get() == 0 )
            {
            itrRelabeledImage.Set( 2 );
            }
          else if( (int)itrRelabeledImage.Get() == 1 )
            {
            itrRelabeledImage.Set( 3 );
            }
          else if( (int)itrRelabeledImage.Get() == 2 )
            {
            itrRelabeledImage.Set( 4 );
            }
          }
        else
          {
          itrRelabeledImage.Set( 0 );
          }
        }
      }
    else
      {
      for( itrRelabeledImage.GoToBegin(), itrMaskImage.GoToBegin();
           !itrRelabeledImage.IsAtEnd();
           ++itrRelabeledImage, ++itrMaskImage )
        {
        if( (int)itrMaskImage.Get() == (int)this->GetMaskValue() )
          {
          itrRelabeledImage.Set( itrRelabeledImage.Get() + 2 );
          }
        else
          {
          itrRelabeledImage.Set( 0 );
          }
        }
      }
    }
  else
    {
    if( (int)this->GetNumberOfClasses() == 2 )
      {
      for( itrRelabeledImage.GoToBegin(); !itrRelabeledImage.IsAtEnd(); ++itrRelabeledImage )
        {
        if( (int)itrRelabeledImage.Get() == 0 )
          {
          itrRelabeledImage.Set( 3 );
          }
        else if( (int)itrRelabeledImage.Get() == 1 )
          {
          itrRelabeledImage.Set( 4 );
          }
        }
      }
    else if( (int)this->GetNumberOfClasses() == 3 )
      {
      for( itrRelabeledImage.GoToBegin(); !itrRelabeledImage.IsAtEnd(); ++itrRelabeledImage )
        {
        if( (int)itrRelabeledImage.Get() == 0 )
          {
          itrRelabeledImage.Set( 2 );
          }
        else if( (int)itrRelabeledImage.Get() == 1 )
          {
          itrRelabeledImage.Set( 3 );
          }
        else if( (int)itrRelabeledImage.Get() == 2 )
          {
          itrRelabeledImage.Set( 4 );
          }
        }
      }
    else
      {
      for( itrRelabeledImage.GoToBegin(); !itrRelabeledImage.IsAtEnd(); ++itrRelabeledImage )
        {
        itrRelabeledImage.Set( itrRelabeledImage.Get() + 2 );
        }
      }
    }
  
  if( maskImage )
    {
    typename MaskFilterType::Pointer maskFilter = MaskFilterType::New();
    maskFilter->SetInput1( relabeledImage );
    maskFilter->SetInput2( maskImage );
    maskFilter->SetOutsideValue( 0 );
    maskFilter->GraftOutput( this->GetOutput() );
    maskFilter->Update();
    this->GraftOutput( maskFilter->GetOutput() );
    }
  else
    {
    m_Classifier->GraftOutput( this->GetOutput() );
    m_Classifier->Update();
    this->GraftOutput( relabeledImage );
    }

}

/**
 *  Print Self Method
 */
template < class TInputImage, class TLabelImage, class TMaskImage >
void
BayesianClassificationImageFilter< TInputImage, TLabelImage, TMaskImage >
::PrintSelf( std::ostream& os, Indent indent) const
{
  Superclass::PrintSelf(os,indent);

  os << indent << "NumberOfClasses: " << m_NumberOfClasses << std::endl;
  os << indent << "Number of smoothing iterations =  " << m_NumberOfSmoothingIterations << std::endl;
}


} // end namespace itk
  
#endif 

