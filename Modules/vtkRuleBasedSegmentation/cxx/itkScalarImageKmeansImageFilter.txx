/*=========================================================================

    Program:   Insight Segmentation & Registration Toolkit
    Module:    $RCSfile: itkScalarImageKmeansImageFilter.txx,v $
    Language:  C++
    Date:      $Date: 2007/05/31 13:20:01 $
    Version:   $Revision: 1.1 $

    Copyright (c) Insight Software Consortium. All rights reserved.
    See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

       This software is distributed WITHOUT ANY WARRANTY; without even 
       the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
       PURPOSE.  See the above copyright notices for more information.

  =========================================================================*/
#ifndef _itkScalarImageKmeansImageFilter_txx
#define _itkScalarImageKmeansImageFilter_txx
#include "itkScalarImageKmeansImageFilter.h"
#include "itkImageRegionExclusionIteratorWithIndex.h"

#include "itkProgressReporter.h"
//#include "itkImageRegionConstIterator.h"

namespace itk
{

template <class TInputImage, class TMaskImage>
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::ScalarImageKmeansImageFilter()
{
  m_UseNonContiguousLabels = false;
  m_ImageRegionDefined = false;
}

template <class TInputImage, class TMaskImage>
void
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::SetImageRegion( const ImageRegionType & region )
{
  m_ImageRegion = region;
  m_ImageRegionDefined = true;
}

template <class TInputImage, class TMaskImage>
void
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::SetInput(const InputImageType* image) 
{ 
  // Process object is not const-correct so the const_cast is required here
  this->ProcessObject::SetNthInput(0, 
                                   const_cast< InputImageType* >( image ) );
}

template <class TInputImage, class TMaskImage>
void
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::SetMaskImage(const MaskImageType* image) 
{ 
  // Process object is not const-correct so the const_cast is required here
  this->ProcessObject::SetNthInput(1, 
                                   const_cast< MaskImageType* >( image ) );
}

template <class TInputImage, class TMaskImage>
const TInputImage*
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::GetInput() const
{
  if (this->GetNumberOfInputs() < 1)
    {
    return 0;
    }
  
  return static_cast<const InputImageType * >
    (this->ProcessObject::GetInput(0) );
}  

template <class TInputImage, class TMaskImage>
const TMaskImage*
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::GetMaskImage() const
{
  if (this->GetNumberOfInputs() < 2)
    {
    return 0;
    }
  
  return static_cast<const MaskImageType * >
    (this->ProcessObject::GetInput(1) );
}  

template <class TInputImage, class TMaskImage>
void
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::GenerateData()
{
  InputImageType *input = const_cast< InputImageType * >(this->GetInput());
  MaskImageType *maskImage = NULL;

  if (this->GetNumberOfInputs() > 1)
    {
    maskImage = const_cast< MaskImageType * >(this->GetMaskImage());
    }

  typename ImageToListGeneratorType::Pointer imageToListGenerator
    = ImageToListGeneratorType::New();

  // This is not an adaptor.. its a filter.. 
  imageToListGenerator->SetInput( input );

  if (maskImage) // mask specified
    {
//     // DEBUGGING: Count number of ON pixels
//     std::cerr << "Setting the Mask in itkScalarImageKmeansImageFilter..." << std::endl;
//     typedef itk::ImageRegionConstIterator< MaskImageType > MaskIteratorType;
//     MaskIteratorType maskIt( maskImage, maskImage->GetRequestedRegion() );
//     int count = 0;
//     for( maskIt.GoToBegin(); !maskIt.IsAtEnd(); ++maskIt )
//       {
//       if( maskIt.Get() == this->m_MaskValue )
//         {
//         count = count + 1;
//         }
//       }
//     std::cerr << "The Mask Value is:  " << (int)this->m_MaskValue << std::endl;
//     std::cerr << "The Number of Masked Pixels are:  " << count << std::endl;
//     // End DEBUGGING

    imageToListGenerator->SetMaskImage( maskImage );
    imageToListGenerator->SetMaskValue( this->m_MaskValue );
    }

  // Generate the sample set from the masked image.
  imageToListGenerator->Update(); 

  typename TreeGeneratorType::Pointer treeGenerator = TreeGeneratorType::New();
  treeGenerator->SetSample( imageToListGenerator->GetListSample() );
  treeGenerator->SetBucketSize( 16 );
  treeGenerator->Update();

  typename EstimatorType::Pointer estimator = EstimatorType::New();

  const unsigned int numberOfClasses = this->m_InitialMeans.size();

  ParametersType  initialMeans( numberOfClasses );
  for(unsigned int cl=0; cl<numberOfClasses; cl++)
    {
    initialMeans[cl] = this->m_InitialMeans[cl];
    }

  estimator->SetParameters( initialMeans );
    
  estimator->SetKdTree( treeGenerator->GetOutput() );
  estimator->SetMaximumIteration( 200 );
  estimator->SetCentroidPositionChangesThreshold(0.0);
  estimator->StartOptimization();

  this->m_FinalMeans = estimator->GetParameters();

  typedef typename InputImageType::RegionType RegionType;
  typedef typename InputImageType::SizeType   SizeType;


  // Now classify the samples
  //
  typedef itk::Statistics::EuclideanDistance< MeasurementVectorType > 
    MembershipFunctionType;

  typedef itk::MinimumDecisionRule DecisionRuleType;
  DecisionRuleType::Pointer decisionRule = DecisionRuleType::New();
    
  typedef itk::Statistics::SampleClassifier<
    typename ImageToListGeneratorType::ListSampleType > ClassifierType;
  typename ClassifierType::Pointer classifier = ClassifierType::New();

  classifier->SetDecisionRule( decisionRule.GetPointer() );
  classifier->SetSample( imageToListGenerator->GetListSample() );

  classifier->SetNumberOfClasses( numberOfClasses  );

  std::vector< unsigned int > classLabels;
  classLabels.resize( numberOfClasses );

  // Spread the labels over the intensity range 
  unsigned int labelInterval = 1;
  if( m_UseNonContiguousLabels )
    {
    labelInterval = ( NumericTraits<OutputPixelType>::max() / numberOfClasses ) - 1;
    }

  unsigned int label = 0;

  typedef typename MembershipFunctionType::Pointer     MembershipFunctionPointer;
  typedef typename MembershipFunctionType::OriginType  MembershipFunctionOriginType;

  for(unsigned int k=0; k<numberOfClasses; k++)
    {
    classLabels[k] = label;
    label += labelInterval;
    MembershipFunctionPointer membershipFunction = MembershipFunctionType::New();
    MembershipFunctionOriginType origin(
      imageToListGenerator->GetListSample()->GetMeasurementVectorSize() );
    origin[0] = this->m_FinalMeans[k]; // A scalar image has a MeasurementVector of dimension 1
    membershipFunction->SetOrigin( origin );
    classifier->AddMembershipFunction( membershipFunction.GetPointer() );
    }

  classifier->SetMembershipFunctionClassLabels( classLabels );

  // Execute the actual classification

  classifier->Update();

  // Now classify the pixels
  typename OutputImageType::Pointer outputPtr = this->GetOutput();

  typedef ImageRegionIterator< OutputImageType >  ImageIterator;

  outputPtr->SetBufferedRegion( outputPtr->GetRequestedRegion() );
  outputPtr->Allocate();

  RegionType region = outputPtr->GetBufferedRegion();

  // If we constrained the classification to a region, label only pixels within
  // the region. Label outside pixels as numberOfClasses + 1
  if( m_ImageRegionDefined )
    {
    region = m_ImageRegion;
    }
        
  ImageIterator pixel( outputPtr, region );
  pixel.GoToBegin();

  typedef typename ClassifierType::OutputType  ClassifierOutputType;
      
  ClassifierOutputType  * membershipSample = classifier->GetOutput();

  typedef typename ClassifierOutputType::ConstIterator LabelIterator;
    
  LabelIterator iter = membershipSample->Begin();
  LabelIterator end  = membershipSample->End();

  while ( iter != end )
    {
    pixel.Set( iter.GetClassLabel() );
    ++iter;
    ++pixel;
    }

  if( m_ImageRegionDefined )
    {
    // If a region is defined to constrain classification to, we need to label
    // pixels outside with numberOfClasses + 1. 
    typedef ImageRegionExclusionIteratorWithIndex< OutputImageType > 
      ExclusionImageIteratorType;
    ExclusionImageIteratorType exIt( outputPtr, outputPtr->GetBufferedRegion() );
    exIt.SetExclusionRegion( region );
    exIt.GoToBegin();
    if( m_UseNonContiguousLabels )
      {
      OutputPixelType outsideLabel = labelInterval * numberOfClasses;
      while( !exIt.IsAtEnd() )
        {
        exIt.Set( outsideLabel );
        ++exIt;
        }
      }
    else
      {
      while( !exIt.IsAtEnd() )
        {
        exIt.Set( numberOfClasses );
        ++exIt;
        }
      }
    }

}

/**
   * Add a new class for the classifier. This requires to explicitly set the
 * initial mean value for that class.
 */
template <class TInputImage, class TMaskImage>
void
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::AddClassWithInitialMean( RealPixelType mean )
{
  this->m_InitialMeans.push_back( mean );
}


/**
 * Standard "PrintSelf" method
 */
template <class TInputImage, class TMaskImage>
void
ScalarImageKmeansImageFilter<TInputImage,TMaskImage>
::PrintSelf(
  std::ostream& os, 
  Indent indent) const
{
  Superclass::PrintSelf( os, indent );
  os << indent << "Final Means " << m_FinalMeans << std::endl;
  os << indent << "Use Contiguous Labels " << m_UseNonContiguousLabels << std::endl;
  os << indent << "Image Region Defined: " << m_ImageRegionDefined << std::endl;
  os << indent << "Image Region: " << m_ImageRegion << std::endl;
}

} // end namespace itk

#endif
