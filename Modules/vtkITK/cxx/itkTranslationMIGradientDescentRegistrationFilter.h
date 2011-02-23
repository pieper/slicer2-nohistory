/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkTranslationMIGradientDescentRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/

#ifndef __itkTranslationMIGradientDescentRegistrationFilter_h
#define __itkTranslationMIGradientDescentRegistrationFilter_h

//BTX
#include <fstream>
#include <string>

#include "itkTransformRegistrationFilter.h"

#include "itkMutualInformationImageToImageMetric.h"
#include "itkTranslationTransform.h"
#include "itkGradientDescentOptimizer.h"

#include "itkArray.h"


typedef  itk::Image<float, 3> ImageType;
typedef  itk::GradientDescentOptimizer OptimizerType;
typedef  itk::TranslationTransform< double > TransformType;
typedef  itk::MutualInformationImageToImageMetric< 
                                 ImageType,
                                 ImageType> MetricType;
namespace itk {
class ITK_EXPORT itkTranslationMIGradientDescentRegistrationFilter : public itk::itkTransformRegistrationFilter<ImageType, OptimizerType, TransformType, MetricType>
{
public:
  typedef itkTranslationMIGradientDescentRegistrationFilter             Self;
  typedef itk::itkTransformRegistrationFilter<ImageType, OptimizerType, TransformType, MetricType>  Superclass;
  typedef ::itk::SmartPointer<Self>          Pointer;
  typedef ::itk::SmartPointer<const Self>    ConstPointer;


  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(itkTranslationMIGradientDescentRegistrationFilter, itk::itkTransformRegistrationFilter);

  itkSetMacro(LearningRate, DoubleArray);
  itkGetMacro(LearningRate, DoubleArray);

  itkSetMacro(StandardDeviation, double);
  itkGetMacro(StandardDeviation, double);

  itkGetMacro(NumberOfSpatialSamples, int);
  itkSetMacro(NumberOfSpatialSamples, int);

protected:  
  virtual void SetOptimizerParamters();
  
  virtual void SetMetricParamters();

  DoubleArray m_LearningRate;

  double m_StandardDeviation;

  int m_NumberOfSpatialSamples;

  // Default constructor
  itkTranslationMIGradientDescentRegistrationFilter();

private:
  itkTranslationMIGradientDescentRegistrationFilter(const itkTranslationMIGradientDescentRegistrationFilter&);  // Not implemented.
  void operator=(const itkTranslationMIGradientDescentRegistrationFilter&);  // Not implemented.
};

///////////////////////////////////////////////////////////////////
//
//  The following section of code implements a Command observer
//  that will monitor the evolution of the registration process.
//

//BTX
class itkTranslationMIGradientDescentRegistrationCommand :  public itk::Command 
{
public:
  typedef  itkTranslationMIGradientDescentRegistrationCommand   Self;
  typedef  itk::Command             Superclass;
  typedef  itk::SmartPointer<itkTranslationMIGradientDescentRegistrationCommand>  Pointer;
  itkNewMacro( itkTranslationMIGradientDescentRegistrationCommand );
  
  void SetRegistrationFilter (itkTranslationMIGradientDescentRegistrationFilter *registration) {
    m_registration = registration;
  }
  void SetLogFileName(char *filename) {
    m_fo.open(filename);
  }
  
protected:
  itkTranslationMIGradientDescentRegistrationCommand() : m_fo("regLevel.log"), m_level(0){};
  itkTranslationMIGradientDescentRegistrationFilter  *m_registration;
  std::ofstream m_fo;
  int m_level;
  
  typedef itk::GradientDescentOptimizer     OptimizerType;
  typedef   OptimizerType   *    OptimizerPointer;
  
public:
  
  virtual void Execute(const itk::Object *caller, const itk::EventObject & event)
  {
    Execute( ( itk::Object *)caller, event);
  }
  
  virtual void Execute( itk::Object * object, const itk::EventObject & event)
  {
    
    OptimizerPointer optimizer = 
      dynamic_cast< OptimizerPointer >( object );

    if( typeid( event ) == typeid( itk::EndEvent ) ) {
      OptimizerType::StopConditionType stopCondition = optimizer->GetStopCondition();
      if (m_fo.good()) {
        m_fo << "Optimizer stopped : " << std::endl;
        m_fo << "Stop condition   =  " << stopCondition << std::endl;
        switch(stopCondition) {
        case OptimizerType::MaximumNumberOfIterations:
          m_fo << "MaximumNumberOfIterations" << std::endl; 
          break;
        }
        m_fo.flush();
      }
    }

    if( ! itk::IterationEvent().CheckEvent( &event ) ) {
      return;
    }

    unsigned int level = m_registration->GetCurrentLevel();
    int numIter = m_registration->GetNumberOfIterations().GetElement(level);
    double learningRate  = m_registration->GetLearningRate().GetElement(level); 
    optimizer->SetNumberOfIterations( numIter );
    optimizer->SetLearningRate( learningRate);
    if (m_fo.good()) {
      m_fo << "LEVEL = " << level << "  ITERATION =" << optimizer->GetCurrentIteration() << 
        " LearningRate=" << learningRate <<  
        "  Value=" << optimizer->GetValue() << std::endl;
      m_fo.flush();
    }
  }
};

} // namespace itk

//ETX

#endif
