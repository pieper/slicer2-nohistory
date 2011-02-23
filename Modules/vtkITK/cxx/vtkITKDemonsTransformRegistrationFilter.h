/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKDemonsTransformRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:45 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKDemonsTransformRegistrationFilter_h
#define __vtkITKDemonsTransformRegistrationFilter_h


#include "vtkITKDeformableRegistrationFilter.h"
#include "itkDemonsTransformRegistrationFilterFF.h"

//#include "itkCurvatureRegistrationFilter.h"
//#include "itkFastSymmetricForcesDemonsRegistrationFunction.h"

#include "itkMultiResolutionPDEDeformableRegistration.h"

#include <itkAffineTransform.h> 

#include "vtkMatrix4x4.h"
#include "vtkProcessObject.h"
#include "vtkImageData.h"
#include "vtkUnsignedIntArray.h"

#include <fstream>
#include <string>

// vtkITKDemonsTransformRegistrationFilter Class

class VTK_EXPORT vtkITKDemonsTransformRegistrationFilter : public vtkITKDeformableRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKDemonsTransformRegistrationFilter,vtkITKImageToImageFilter);

  static vtkITKDemonsTransformRegistrationFilter* New();

  void PrintSelf(ostream& os, vtkIndent indent)
  {
    Superclass::PrintSelf ( os, indent );
  };

  vtkSetMacro(ThresholdAtMeanIntensity, bool);
  vtkGetMacro(ThresholdAtMeanIntensity, bool);

  void ThresholdAtMeanIntensityOn() {
    SetThresholdAtMeanIntensity(true);
  }
  void ThresholdAtMeanIntensityOff() {
    SetThresholdAtMeanIntensity(false);
  }

  vtkSetMacro(NumberOfHistogramLevels, int);
  vtkGetMacro(NumberOfHistogramLevels, int);

  vtkSetMacro(StandardDeviations, double);
  vtkGetMacro(StandardDeviations, double);

  vtkSetMacro(UpdateFieldStandardDeviations, double);
  vtkGetMacro(UpdateFieldStandardDeviations, double);

  // Description
  // The Max Number of Iterations at each multi-resolution level.
  vtkSetObjectMacro(MaxNumberOfIterations,vtkUnsignedIntArray);
  vtkGetObjectMacro(MaxNumberOfIterations,vtkUnsignedIntArray);

  // Description:
  // Reset the Multiresolution Settings
  // It blanks the Min/Max Step and NumberOfIterations
  void ResetMultiResolutionSettings() {
    MaxNumberOfIterations->Reset();
  };


  // Description:
  // Set the max number of iterations at each level
  // Generally less than 5000, 2500 is OK.
  // Must set the same number of Learning Rates as Iterations
  void SetNextMaxNumberOfIterations(const int num)
  { MaxNumberOfIterations->InsertNextValue(num); };

  void SetAbort(int abort) {
    this->AbortExecuteOn();
    m_ITKFilter->AbortIterations();
  }
  virtual void AbortIterations() {
    m_ITKFilter->SetAbortGenerateData(true);
  };

  void GetTransformationMatrix(vtkMatrix4x4* matrix);
  
  void SetTransformationMatrix(vtkMatrix4x4 *matrix);

  vtkProcessObject* GetProcessObject() {return this;};

  double GetMetricValue() {return MetricValue;};
  double GetError() {return MetricValue;};

  // for compatibility with other modules:

  void Initialize (vtkMatrix4x4 *matrix) {
    SetTransformationMatrix(matrix);
  };

  vtkMatrix4x4* GetOutputMatrix() {
    GetTransformationMatrix(m_Matrix);
    return m_Matrix;
  };

  // Description:
  // Set Fixed (Target) Input
  void SetTargetImage(vtkImageData *input)
  {
    SetFixedInput(input);
  };

  // Description:
  // Set Moving (Source) Input
  void SetSourceImage(vtkImageData *input)
  {
    SetMovingInput(input);
  };

  int GetCurrentLevel() {
    return m_ITKFilter->GetCurrentLevel();
  }

protected:
 //BTX
  typedef itk::AffineTransform<double, 3> TransformType;

  int                  NumberOfHistogramLevels;
  bool                 ThresholdAtMeanIntensity;
  double               StandardDeviations;
  double               UpdateFieldStandardDeviations;
  vtkUnsignedIntArray  *MaxNumberOfIterations;
  int                  CurrentIteration;
  double               MetricValue;

  vtkMatrix4x4 *m_Matrix;

  itk::itkDemonsTransformRegistrationFilterFF::Pointer m_ITKFilter;

  virtual vtkITKDeformableRegistrationFilter::DeformationFieldType::Pointer GetDisplacementOutput();

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput();

  virtual void UpdateRegistrationParameters();

  virtual void CreateRegistrationPipeline();

  // default constructor
  vtkITKDemonsTransformRegistrationFilter (); // This is called from New() by vtkStandardNewMacro

  virtual ~vtkITKDemonsTransformRegistrationFilter();
  //ETX
  
private:
  vtkITKDemonsTransformRegistrationFilter(const vtkITKDemonsTransformRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKDemonsTransformRegistrationFilter&);  // Not implemented.
};

//vtkCxxRevisionMacro(vtkITKDemonsTransformRegistrationFilter, "$Revision: 1.10 $");
//vtkStandardNewMacro(vtkITKDemonsTransformRegistrationFilter);
vtkRegistrationNewMacro(vtkITKDemonsTransformRegistrationFilter);





///////////////////////////////////////////////////////////////////
//
//  The following section of code implements a Command observer
//  that will monitor the evolution of the registration process.
//

//BTX
class DemonsTransformRegistrationFilterCommand : public itk::Command 
{
public:
  typedef  DemonsTransformRegistrationFilterCommand   Self;
  typedef  itk::Command             Superclass;
  typedef  itk::SmartPointer<DemonsTransformRegistrationFilterCommand>  Pointer;
  itkNewMacro( DemonsTransformRegistrationFilterCommand );

  void SetDemonsRegistrationFilter (vtkITKDemonsTransformRegistrationFilter *registration) {
    m_registration = registration;
  }
  void SetLogFileName(char *filename) {
    m_fo.open(filename);
  }

protected:
  DemonsTransformRegistrationFilterCommand() : m_fo("reg_demons.log"){};
  vtkITKDemonsTransformRegistrationFilter *m_registration;
  std::ofstream m_fo;

  typedef itk::Image< float, 3 > InternalImageType;
  typedef itk::Vector< float, 3 >    VectorPixelType;
  typedef itk::Image<  VectorPixelType, 3 > DeformationFieldType;
  
  typedef itk::DemonsRegistrationFilter<
    InternalImageType,
    InternalImageType,
    DeformationFieldType>   RegistrationFilterType;
  /***
  typedef itk::CurvatureRegistrationFilter<
                                InternalImageType,
                                InternalImageType,
                                DeformationFieldType,
                                itk::FastSymmetricForcesDemonsRegistrationFunction<InternalImageType,InternalImageType,DeformationFieldType> >   RegistrationFilterType;
  ***/

public:
  
  void Execute(itk::Object *caller, const itk::EventObject & event)
  {
    Execute( (const itk::Object *)caller, event);
  }
  
  void Execute(const itk::Object * object, const itk::EventObject & event)
  {
    const RegistrationFilterType * filter = 
      dynamic_cast< const RegistrationFilterType * >( object );
    if( typeid( event ) != typeid( itk::IterationEvent ) ) {
      return;
    }
    if (filter) {
      unsigned int level = m_registration->GetCurrentLevel();
      int iter = m_registration->GetCurrentIteration();
      if (m_fo.good()) {
        m_fo << "Iteration = " << iter << "   Metric = " << filter->GetMetric() << std::endl;
      }
      m_registration->SetCurrentIteration(iter+1);
      if (m_registration->GetAbortExecute()) {
        m_registration->AbortIterations();
      }
      float maxNumIter = 0;

      for( int i=0; i< m_registration->GetMaxNumberOfIterations()->GetNumberOfTuples();i++) {
        maxNumIter += m_registration->GetMaxNumberOfIterations()->GetValue(i);
      }
      if (maxNumIter == 0) {
        maxNumIter = 1;
      }
      double progress = (iter + 1.0)/maxNumIter;
      
      m_registration->UpdateProgress( progress );
    }
    else {
      if (m_fo.good()) {
        m_fo << "Error in DemonsTransformRegistrationFilterCommand::Execute" << std::endl;
      }
    }
    if (m_fo.good()) {
      m_fo.flush();
    }
  }
};
//ETX
#endif




