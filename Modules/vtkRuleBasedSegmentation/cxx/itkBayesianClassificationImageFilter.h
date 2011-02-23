/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: itkBayesianClassificationImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2007/08/15 05:13:42 $
  Version:   $Revision: 1.2 $

  Copyright (c) Insight Software Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
// This filter is a wrapper around the
// itk::BayesianClassifierInitializationImageFilter and the
// itk::BayesianClassifierImageFilter. It provides the minimal
// interfaces necessary to provide Slicer with a blackbox that takes
// an image (to be classified) as input and provides an output image.
//
// TODO provide some documentation to a layman on what the filter
// actually does.
// 
// To sum up, the purpose of this class is to provide only the
// interfaces that can be accessed by the slicer GUI. Here we will
// provide methods to set the number of classes (to be classified) and
// the number of smoothing iterations (that must be applied to the
// posteriors). At a later point a method can be provided to switch
// between Curvature smoothing or Anisotropic diffusion. Here we will
// use Anisotropic diffusion.
//

#ifndef __itkBayesianClassificationImageFilter_h
#define __itkBayesianClassificationImageFilter_h

#include "itkBayesianClassifierImageFilter.h"
#include "itkBayesianClassifierInitializationImageFilter.h"
#include "itkProcessObject.h"
#include "itkGradientAnisotropicDiffusionImageFilter.h"
#include "itkMaskImageFilter.h"
#include "itkImageRegionIterator.h"
#include "itkImageRegionConstIterator.h"

namespace itk
{
  
template< class TInputImage, class TLabelImage, class TMaskImage = TInputImage >
class ITK_EXPORT BayesianClassificationImageFilter : public
ImageToImageFilter< TInputImage, TLabelImage >
{
public:
  typedef BayesianClassificationImageFilter          Self;
  typedef TInputImage                                InputImageType;
  typedef TLabelImage                                OutputImageType;
  typedef ImageToImageFilter< 
  InputImageType, OutputImageType >          Superclass;

  typedef SmartPointer<Self>   Pointer;
  typedef SmartPointer<const Self>  ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro( Self );

  /** Run-time type information (and related methods). */
  itkTypeMacro( BayesianClassificationImageFilter, ImageToImageFilter );
  
  /** Input and Output image types */
  typedef typename InputImageType::ConstPointer      InputImagePointer;
  typedef typename OutputImageType::Pointer          OutputImagePointer;
  typedef typename InputImageType::RegionType        ImageRegionType;
  
  /** Relabeled image iterator */
  typedef ImageRegionIterator< OutputImageType >     RelabeledImageIteratorType;

  /** Set/Get methods for the number of classes. The user must supply this. */
  itkSetMacro( NumberOfClasses, unsigned int );
  itkGetMacro( NumberOfClasses, unsigned int );
  
  /** Number of iterations to apply the smoothing filter */
  itkSetMacro( NumberOfSmoothingIterations, unsigned int );
  itkGetMacro( NumberOfSmoothingIterations, unsigned int );

  /** Mask Image typedefs */
  typedef TMaskImage                           MaskImageType;
  typedef typename MaskImageType::Pointer      MaskImagePointer ;
  typedef typename MaskImageType::ConstPointer MaskImageConstPointer ;
  typedef typename MaskImageType::PixelType    MaskPixelType ;
  typedef ImageRegionConstIterator< MaskImageType > MaskImageIteratorType;
  typedef itk::MaskImageFilter< OutputImageType, MaskImageType, OutputImageType >
    MaskFilterType;
  
  /** Method to set/get the image */
  void SetInput( const InputImageType* image ) ;
  const InputImageType* GetInput() const;

  /** Method to set/get the mask */
  void SetMaskImage( const MaskImageType* image ) ;
  const MaskImageType* GetMaskImage() const;

  /** Set the pixel value treated as on in the mask. If a mask has been 
   * specified, only pixels with this value will be added to the list sample, if
   * no mask has been specified all pixels will be added as measurement vectors
   * to the list sample. */
  itkSetMacro( MaskValue, MaskPixelType );
  itkGetMacro( MaskValue, MaskPixelType );
  
protected:
  BayesianClassificationImageFilter();
  virtual ~BayesianClassificationImageFilter() {}
  
  void PrintSelf(std::ostream& os, Indent indent) const;

  virtual void GenerateData();

  // Initialization filter
  typedef BayesianClassifierInitializationImageFilter< 
  InputImageType, MaskImageType >                    BayesianInitializerType;
  typedef typename BayesianInitializerType::Pointer    BayesianInitializerPointer;
  typedef typename BayesianInitializerType::OutputImageType 
    InitializerOutputImageType;
  // Classifier 
  typedef BayesianClassifierImageFilter< 
  InitializerOutputImageType, typename OutputImageType::PixelType >
    ClassifierFilterType;
  typedef typename ClassifierFilterType::Pointer       ClassifierFilterPointer;

private:
  BayesianClassificationImageFilter(const Self&); //purposely not implemented
  void operator=(const Self&); //purposely not implemented

  unsigned int                        m_NumberOfClasses;
  unsigned int                        m_NumberOfSmoothingIterations;
  BayesianInitializerPointer          m_Initializer;
  ClassifierFilterPointer             m_Classifier;

  MaskPixelType m_MaskValue;
};

} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkBayesianClassificationImageFilter.txx"
#endif

#endif    
