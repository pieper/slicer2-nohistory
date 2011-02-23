/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkDemonsTransformRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __itkDemonsTransformRegistrationFilter_h
#define __itkDemonsTransformRegistrationFilter_h

#include "itkImageToImageFilter.h"
#include "itkEventObject.h"
#include "itkImage.h"

#include "itkDemonsRegistrationFilter.h"
#include "itkHistogramMatchingImageFilter.h"
#include "itkCastImageFilter.h"
#include "itkWarpImageFilter.h"
#include "itkLinearInterpolateImageFunction.h"
#include "itkCastImageFilter.h"
#include "itkTransform.h"
#include "itkResampleImageFilter.h"
#include "itkImageFileWriter.h"
#include "itkMultiResolutionPDEDeformableRegistration.h"
#include "itkDenseFrequencyContainer.h"

//#include "itkCurvatureRegistrationFilter.h"
//#include "itkFastSymmetricForcesDemonsRegistrationFunction.h"


//BTX
namespace itk 
{

// itkDemonsTransformRegistrationFilter Class

template <class TImageType >

class ITK_EXPORT itkDemonsTransformRegistrationFilter : public itk::ImageToImageFilter< TImageType, TImageType>
{
public:

  typedef itkDemonsTransformRegistrationFilter             Self;
  typedef itk::ImageToImageFilter<TImageType,TImageType>  Superclass;
  typedef ::itk::SmartPointer<Self>          Pointer;
  typedef ::itk::SmartPointer<const Self>    ConstPointer;

  typedef itk::Vector<float, 3>    VectorPixelType;

  typedef TImageType FixedImageType;
  typedef TImageType MovingImageType;

  typedef itk::Image<VectorPixelType, 3> DeformationFieldType;

  typedef itk::Transform<double, 3, 3 > TransformType;
  
  /** UnsignedIntArray type. */
  typedef Array<unsigned int> UnsignedIntArray;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);  

  /** Runtime information support. */
  itkTypeMacro(TImageType, ImageToImageFilter);
  
  /** Set init transfrom */
  void SetTransform( const TransformType* transform )
  {
    m_Transform->SetParameters( transform->GetParameters() );
  }

  /** Get resulting transform */
  void GetTransform(TransformType* transform)
  {
    transform->SetParameters( m_Transform->GetParameters() );
  }


  itkSetMacro(ThresholdAtMeanIntensity, bool);
  itkGetMacro(ThresholdAtMeanIntensity, bool);

  itkSetMacro(NumberOfHistogramLevels, int);
  itkGetMacro(NumberOfHistogramLevels, int);

  itkSetMacro(StandardDeviations, double);
  itkGetMacro(StandardDeviations, double);

  itkSetMacro(UpdateFieldStandardDeviations, double);
  itkGetMacro(UpdateFieldStandardDeviations, double);

  /** Set the number of iterations per level. */
  itkSetMacro( NumberOfIterations, UnsignedIntArray );
  itkGetMacro( NumberOfIterations, UnsignedIntArray );

  itkSetMacro(NumberOfLevels, int);
  itkGetMacro(NumberOfLevels, int);

  itkSetMacro(CurrentIteration, int);
  itkGetMacro(CurrentIteration, int);

  itkSetMacro(WriteInputs, bool);
  itkGetMacro(WriteInputs, bool);

  DeformationFieldType * GetDeformationField(void);

  virtual void AbortIterations() {
    m_Filter->SetAbortGenerateData(true);
    m_MultiResFilter->StopRegistration ();
  };

  int GetCurrentLevel() { return  m_MultiResFilter->GetCurrentLevel();};

  unsigned long AddIterationObserver (itk::Command *observer );

protected:

  void  GenerateData ();

  unsigned short                       m_NumberOfLevels;
  UnsignedIntArray                     m_NumberOfIterations;

  int    m_NumberOfHistogramLevels;
  bool   m_ThresholdAtMeanIntensity;
  double m_UpdateFieldStandardDeviations;
  double m_StandardDeviations;
  int    m_CurrentIteration;
  bool   m_WriteInputs;
  
  typedef float InternalPixelType;
  typedef itk::Image<InternalPixelType, 3 >  InternalImageType;

  ////////////////////////////////
  // ITK Pipeline that does the job
  ////////////////////////////////

  // Transformer for moving image
  typename TransformType::Pointer                m_Transform;
  typename InternalImageType::PixelType          m_BackgroundLevel;

  typedef itk::ResampleImageFilter<
                                    MovingImageType,
                                    MovingImageType  >    ResampleFilterType;
  typename ResampleFilterType::Pointer           m_Resampler;

  // Casters

  typedef itk::CastImageFilter< FixedImageType, 
                                InternalImageType > FixedImageCasterType;
  typedef itk::CastImageFilter< MovingImageType, 
                                InternalImageType > MovingImageCasterType;

  typename FixedImageCasterType::Pointer m_FixedImageCaster;

  typename MovingImageCasterType::Pointer m_MovingImageCaster;

  // Matcher
  typedef itk::HistogramMatchingImageFilter<InternalImageType,InternalImageType> MatchingFilterType;
  MatchingFilterType::Pointer m_Matcher;

  // Registration filter
  typedef itk::DemonsRegistrationFilter<
                                InternalImageType,
                                InternalImageType,
                                DeformationFieldType>   RegistrationFilterType;

  /*****
  typedef itk::FastSymmetricForcesDemonsRegistrationFunction<InternalImageType,InternalImageType,DeformationFieldType>   ImageForceFunctionType;

  typedef itk::CurvatureRegistrationFilter<
                                InternalImageType,
                                InternalImageType,
                                DeformationFieldType,
                                ImageForceFunctionType>   RegistrationFilterType;
  *****/

  RegistrationFilterType::Pointer m_Filter;

  typedef itk::MultiResolutionPDEDeformableRegistration<
                                InternalImageType,
                                InternalImageType,
                                DeformationFieldType >   MultiResRegistrationFilterType;

  MultiResRegistrationFilterType::Pointer m_MultiResFilter;

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
  typedef itk::ImageFileWriter< InternalImageType  >    ImageWriterType;      
  typename ImageWriterType::Pointer m_Writer;

  // default constructor
  itkDemonsTransformRegistrationFilter(); 

  virtual ~itkDemonsTransformRegistrationFilter() {};
  
private:
  itkDemonsTransformRegistrationFilter(const itkDemonsTransformRegistrationFilter&);  // Not implemented.
  void operator=(const itkDemonsTransformRegistrationFilter&);  // Not implemented.
};

} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkDemonsTransformRegistrationFilter.txx"
#endif

 //ETX

#endif




