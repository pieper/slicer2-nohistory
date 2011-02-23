/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkDemonsRegistrationImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __itkDemonsRegistrationImageFilter_h
#define __itkDemonsRegistrationImageFilter_h

#include "itkImageToImageFilter.h"

#include "itkDemonsRegistrationFilter.h"
#include "itkHistogramMatchingImageFilter.h"
#include "itkCastImageFilter.h"
#include "itkWarpImageFilter.h"
#include "itkLinearInterpolateImageFunction.h"
#include "itkCastImageFilter.h"

#include "itkEventObject.h"

namespace itk {
// itkDemonsRegistrationImageFilter Class
typedef itk::Image<float, 3> itkDemonsRegistrationImageFilterImageType;

class ITK_EXPORT itkDemonsRegistrationImageFilter : public itk::ImageToImageFilter<itkDemonsRegistrationImageFilterImageType, itkDemonsRegistrationImageFilterImageType>

{
public:

  typedef itk::itkDemonsRegistrationImageFilter Self;
  typedef itk::ImageToImageFilter<itkDemonsRegistrationImageFilterImageType,itkDemonsRegistrationImageFilterImageType>  Superclass;
  typedef itk::SmartPointer<Self>        Pointer;
  typedef itk::SmartPointer<const Self>  ConstPointer;


  typedef float InputImagePixelType;
  typedef float OutputImagePixelType;
  typedef itk::Vector<float, 3>    VectorPixelType;

  typedef itk::Image<InputImagePixelType, 3> FixedImageType;
  typedef itk::Image<InputImagePixelType, 3> MovingImageType;
  typedef itk::Image<VectorPixelType, 3> DeformationFieldType;

  
  /** Method for creation through the object factory. */
  itkNewMacro(Self);  

  /** Runtime information support. */
  itkTypeMacro(itkDemonsRegistrationImageFilterImageType, ImageToImageFilter);
  

  itkSetMacro(StandardDeviations, double);
  itkGetMacro(StandardDeviations, double);

  itkSetMacro(NumIterations, int);
  itkGetMacro(NumIterations, int);

  itkSetMacro(CurrentIteration, int);
  itkGetMacro(CurrentIteration, int);

  DeformationFieldType * GetDeformationField(void);

  virtual void AbortIterations() {
    m_Filter->SetAbortGenerateData(true);
  };

  unsigned long AddIterationObserver (itk::Command *observer );
protected:

 void  GenerateData ();

  double m_StandardDeviations;
  int    m_NumIterations;
  int    m_CurrentIteration;

  typedef float InternalPixelType;
  typedef itk::Image<InternalPixelType, 3 >  InternalImageType;

  ////////////////////////////////
  // ITK Pipeline that does the job
  ////////////////////////////////
  typedef itk::CastImageFilter< FixedImageType, 
                                InternalImageType > FixedImageCasterType;
  typedef itk::CastImageFilter< MovingImageType, 
                                InternalImageType > MovingImageCasterType;

  // Casters

  FixedImageCasterType::Pointer m_FixedImageCaster;

  MovingImageCasterType::Pointer m_MovingImageCaster;


  // Matcher
  typedef itk::HistogramMatchingImageFilter<InternalImageType,InternalImageType> MatchingFilterType;
  MatchingFilterType::Pointer m_Matcher;

  // Registration filter
  typedef itk::DemonsRegistrationFilter<
                                InternalImageType,
                                InternalImageType,
                                DeformationFieldType>   RegistrationFilterType;
  RegistrationFilterType::Pointer m_Filter;

  // Warper and interpolator
  typedef itk::WarpImageFilter<
                       MovingImageType,
                       MovingImageType,
                       DeformationFieldType>  WarperType;
  typedef itk::LinearInterpolateImageFunction<
                                   MovingImageType,
                                   double          >  InterpolatorType;

  WarperType::Pointer m_Warper;
  InterpolatorType::Pointer m_Interpolator;


  // default constructor
  itkDemonsRegistrationImageFilter(); 

  virtual ~itkDemonsRegistrationImageFilter() {};
  
private:
  itkDemonsRegistrationImageFilter(const itkDemonsRegistrationImageFilter&);  // Not implemented.
  void operator=(const itkDemonsRegistrationImageFilter&);  // Not implemented.
};

} // end namespace itk

#endif




