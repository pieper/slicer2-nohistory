/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKBSplineMattesMIRegistrationFilter.h,v $
  Date:      $Date: 2006/05/26 19:52:12 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKBSplineMattesMIRegistrationFilter_h
#define __vtkITKBSplineMattesMIRegistrationFilter_h


#include "vtkITKDeformableRegistrationFilter.h"
#include "itkBSplineMattesMIRegistrationFilterFF.h"

#include <itkAffineTransform.h> 
#include <itkExceptionObject.h>

#include "vtkMatrix4x4.h"
#include "vtkProcessObject.h"
#include "vtkImageData.h"

#include "itkLBFGSBOptimizer.h"

#include <fstream>
#include <string>

// vtkITKBSplineMattesMIRegistrationFilter Class

class VTK_EXPORT vtkITKBSplineMattesMIRegistrationFilter : public vtkITKDeformableRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKBSplineMattesMIRegistrationFilter,vtkITKImageToImageFilter);

  static vtkITKBSplineMattesMIRegistrationFilter* New();

  void PrintSelf(ostream& os, vtkIndent indent)
  {
    Superclass::PrintSelf ( os, indent );
  };

  vtkSetMacro(GridSize, int);
  vtkGetMacro(GridSize, int);

  vtkSetMacro(CostFunctionConvergenceFactor, double);
  vtkGetMacro(CostFunctionConvergenceFactor, double);

  vtkSetMacro(ProjectedGradientTolerance, double);
  vtkGetMacro(ProjectedGradientTolerance, double);

  vtkSetMacro(MaximumNumberOfIterations, int);
  vtkGetMacro(MaximumNumberOfIterations, int);

  vtkSetMacro(MaximumNumberOfEvaluations, int);
  vtkGetMacro(MaximumNumberOfEvaluations, int);

  vtkSetMacro(MaximumNumberOfCorrections, int);
  vtkGetMacro(MaximumNumberOfCorrections, int);

  vtkSetMacro(NumberOfHistogramBins, int);
  vtkGetMacro(NumberOfHistogramBins, int);

  vtkSetMacro(NumberOfSpatialSamples, int);
  vtkGetMacro(NumberOfSpatialSamples, int);

  vtkSetMacro(ResampleMovingImage, bool);
  vtkGetMacro(ResampleMovingImage, bool);

  vtkSetMacro(ReinitializeSeed, bool);
  vtkGetMacro(ReinitializeSeed, bool);

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

  double GetMetricValue() {return m_ITKFilter->GetMetricValue();};
  double GetError() {return GetMetricValue();};

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
    SetMovingInput(input);
  };

  // Description:
  // Set Moving (Source) Input
  void SetSourceImage(vtkImageData *input)
  {
    SetFixedInput(input);
  };

protected:
  //BTX
  int    GridSize;
  double CostFunctionConvergenceFactor;
  double ProjectedGradientTolerance;
  int    MaximumNumberOfIterations;
  int    MaximumNumberOfEvaluations;
  int    MaximumNumberOfCorrections;
  int    NumberOfHistogramBins;
  int    NumberOfSpatialSamples;

  bool   ResampleMovingImage;
  bool   ReinitializeSeed;


  vtkMatrix4x4 *m_Matrix;

  itk::itkBSplineMattesMIRegistrationFilterFF::Pointer m_ITKFilter;

  typedef itk::AffineTransform<double, 3> TransformType;

  virtual vtkITKDeformableRegistrationFilter::DeformationFieldType::Pointer GetDisplacementOutput();

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput();

  virtual void UpdateRegistrationParameters();

  virtual void CreateRegistrationPipeline();

  // default constructor
  vtkITKBSplineMattesMIRegistrationFilter (); // This is called from New() by vtkStandardNewMacro

  virtual ~vtkITKBSplineMattesMIRegistrationFilter();
  //ETX
  
private:
  vtkITKBSplineMattesMIRegistrationFilter(const vtkITKBSplineMattesMIRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKBSplineMattesMIRegistrationFilter&);  // Not implemented.
};

vtkRegistrationNewMacro(vtkITKBSplineMattesMIRegistrationFilter);




///////////////////////////////////////////////////////////////////
//
//  The following section of code implements a Command observer
//  that will monitor the evolution of the registration process.
//

//BTX
class BSplineMattesMIRegistrationFilterCommand : public itk::Command 
{
public:
  typedef  BSplineMattesMIRegistrationFilterCommand   Self;
  typedef  itk::Command             Superclass;
  typedef  itk::SmartPointer<BSplineMattesMIRegistrationFilterCommand>  Pointer;
  itkNewMacro( BSplineMattesMIRegistrationFilterCommand );

  void SeRegistrationFilter (vtkITKBSplineMattesMIRegistrationFilter *registration) {
    m_registration = registration;
  }
  void SetLogFileName(char *filename) {
    m_fo.open(filename);
  }

protected:
  BSplineMattesMIRegistrationFilterCommand() : m_fo("reg_bspline.log"){};
  vtkITKBSplineMattesMIRegistrationFilter *m_registration;
  std::ofstream m_fo;

  typedef itk::LBFGSBOptimizer OptimizerType;
  typedef OptimizerType   *    OptimizerPointer;

public:
  
  void Execute(itk::Object *caller, const itk::EventObject & event)
  {
    Execute( (const itk::Object *)caller, event);
  }
  
  void Execute(const itk::Object * object, const itk::EventObject & event)
  { 
    const OptimizerType * optimizer = 
      dynamic_cast< const OptimizerType * >( object );
    
    if( typeid( event ) != typeid( itk::IterationEvent ) ) {
      return;
    }
    if (optimizer) {
      int iter = m_registration->GetCurrentIteration();
      double progress = (iter + 0.0)/m_registration->GetMaximumNumberOfIterations();
      m_registration->UpdateProgress( progress );     
      if (m_fo.good()) {
        m_fo << "Iteration = " << iter  << "  Metric = " << optimizer->GetValue() << std::endl;
      }
      m_registration->SetCurrentIteration(iter+1);
      if (m_registration->GetAbortExecute()) {
        m_registration->AbortIterations();
        throw itk::ProcessAborted(__FILE__,__LINE__);
      }
    }
    else {
      if (m_fo.good()) {
        m_fo << "Error in BSplineMattesMIRegistrationFilterCommand::Execute" << std::endl;
      }
    }
    if (m_fo.good()) {
      m_fo.flush();
    }
    
  }
};
//ETX
#endif




