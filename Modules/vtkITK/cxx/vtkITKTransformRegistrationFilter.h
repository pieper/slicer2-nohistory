/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKTransformRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKTransformRegistrationFilter_h
#define __vtkITKTransformRegistrationFilter_h


#include "vtkITKRegistrationFilter.h"
#include "itkTransformRegistrationFilter.h"
#include "vtkProcessObject.h"
#include "vtkDoubleArray.h"
#include "vtkImageData.h"
#include "vtkUnsignedIntArray.h"
#include "vtkMatrix4x4.h"
#include "vtkUnsignedIntArray.h"

#include <itkGradientDescentOptimizer.h>
#include <itkRegularStepGradientDescentBaseOptimizer.h> 


// vtkITKTransformRegistrationFilter Class

class VTK_EXPORT vtkITKTransformRegistrationFilter : public vtkITKRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKTransformRegistrationFilter,vtkITKImageToImageFilter);

  static vtkITKTransformRegistrationFilter* New(){return 0;};

  // Description
  // The Max Number of Iterations at each multi-resolution level.
  vtkSetObjectMacro(MaxNumberOfIterations,vtkUnsignedIntArray);
  vtkGetObjectMacro(MaxNumberOfIterations,vtkUnsignedIntArray);

  // Description:
  // Set the max number of iterations at each level
  // Generally less than 5000, 2500 is OK.
  // Must set the same number of Learning Rates as Iterations
  void SetNextMaxNumberOfIterations(const int num)
  { MaxNumberOfIterations->InsertNextValue(num); };

  virtual void GetTransformationMatrix(vtkMatrix4x4* matrix) = 0;
  
  virtual void GetCurrentTransformationMatrix(vtkMatrix4x4* matrix) = 0;
  
  virtual void SetTransformationMatrix(vtkMatrix4x4 *matrix) = 0;

  virtual void AbortIterations() = 0;

  vtkProcessObject* GetProcessObject() {return this;};

  virtual void ResetMultiResolutionSettings() {};

  vtkSetMacro(Error, int);
  vtkGetMacro(Error, int);

  virtual int GetCurrentLevel() {return 0;};

  virtual int GetCurrentIteration() {return 0;};

  virtual double GetMetricValue() {return 0;};

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

  // convert itk space image to image matrix to vtk space and vise versa
  static void vtkItkMatrixTransform (vtkMatrix4x4 *matIn, vtkMatrix4x4 *matOut);

protected:

  //BTX

  vtkMatrix4x4 *m_Matrix;

  vtkUnsignedIntArray  *MaxNumberOfIterations;

  int Error;

  // default constructor
  vtkITKTransformRegistrationFilter (); // This is called from New() by vtkStandardNewMacro

  virtual void UpdateRegistrationParameters(){};

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput();

  virtual void CreateRegistrationPipeline();

  virtual ~vtkITKTransformRegistrationFilter();
  //ETX


private:
  vtkITKTransformRegistrationFilter(const vtkITKTransformRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKTransformRegistrationFilter&);  // Not implemented.
};



///////////////////////////////////////////////////////////////////
//
//  The following section of code implements a Command observer
//  that will monitor the evolution of the registration process.
//

//BTX

class vtkITKTransformRegistrationCommand :  public itk::Command 
{
public:
  typedef  vtkITKTransformRegistrationCommand   Self;
  typedef  itk::Command             Superclass;
  typedef  itk::SmartPointer<vtkITKTransformRegistrationCommand>  Pointer;
  itkNewMacro( vtkITKTransformRegistrationCommand );

  void SetRegistrationFilter (vtkITKTransformRegistrationFilter *registration) {
    m_registration = registration;
  }
  void SetLogFileName(char *filename) {
    m_fo.open(filename);
  }

protected:
  vtkITKTransformRegistrationCommand() : m_fo("reg.log"){};

  vtkITKTransformRegistrationFilter  *m_registration;

  std::ofstream m_fo;

  typedef itk::SingleValuedNonLinearOptimizer     OptimizerType;
  typedef OptimizerType   *    OptimizerPointer;

  typedef itk::RegularStepGradientDescentBaseOptimizer RSGDOptimizerType;
  typedef RSGDOptimizerType   *    RSGDOptimizerPointer;

  typedef itk::GradientDescentOptimizer GDOptimizerType;
  typedef GDOptimizerType   *    GDOptimizerPointer;

public:
  
  virtual void Execute(const itk::Object *caller, const itk::EventObject & event)
  {
    Execute( ( itk::Object *)caller, event);
  }
  
  virtual void Execute( itk::Object * object, const itk::EventObject & event)
  {
    OptimizerPointer optimizer = 
      dynamic_cast< OptimizerPointer >( object );
    
    RSGDOptimizerPointer rsoptimizer = 
      dynamic_cast< RSGDOptimizerPointer>( optimizer );
    
    GDOptimizerPointer gdoptimizer = 
      dynamic_cast< GDOptimizerPointer>( optimizer );
    
    if( rsoptimizer && typeid( event ) == typeid( itk::EndEvent ) ) {
      RSGDOptimizerType::StopConditionType stopCondition = rsoptimizer->GetStopCondition();
      if (m_fo.good()) {
        m_fo << "Optimizer stopped : " << std::endl;
        m_fo << "Stop condition   =  " << stopCondition << std::endl;
        switch(stopCondition) {
        case RSGDOptimizerType::GradientMagnitudeTolerance:
          m_fo << "GradientMagnitudeTolerance" << std::endl; 
          break;
        case RSGDOptimizerType::StepTooSmall:
          m_fo << "StepTooSmall" << std::endl; 
          break;
        case RSGDOptimizerType::ImageNotAvailable:
          m_fo << "ImageNotAvailable" << std::endl; 
          break;
        case RSGDOptimizerType::MaximumNumberOfIterations:
          m_fo << "MaximumNumberOfIterations" << std::endl; 
          break;
        default:
          m_fo << "Unknown Stop Condition" << std::endl;
          break;
        }
      }
    }
    
    if( gdoptimizer && typeid( event ) == typeid( itk::EndEvent ) ) {
      GDOptimizerType::StopConditionType stopCondition = gdoptimizer->GetStopCondition();
      if (m_fo.good()) {
        m_fo << "Optimizer stopped : " << std::endl;
        m_fo << "Stop condition   =  " << stopCondition << std::endl;
        switch(stopCondition) {
        case GDOptimizerType::MaximumNumberOfIterations:
          m_fo << "MaximumNumberOfIterations" << std::endl; 
          break;
        }
      }
    }

    if( itk::IterationEvent().CheckEvent( &event ) ) {
      int iter = m_registration->GetCurrentIteration();
      unsigned int level = m_registration->GetCurrentLevel();
      
      vtkMatrix4x4 *mat = vtkMatrix4x4::New();
      m_registration->GetCurrentTransformationMatrix(mat);

      if (m_fo.good()) {
        m_fo << "  ====== ITERATION =" << m_registration->GetCurrentIteration() << 
          " LEVEL =" <<  m_registration->GetCurrentLevel() <<"   " << std::endl;
        mat->Print(m_fo);
        if (rsoptimizer) {
          m_fo << "Value=" << rsoptimizer->GetValue() << "   ";
          m_fo << "Position=" << rsoptimizer->GetCurrentPosition() << std::endl;
        }
        if (gdoptimizer) {
          m_fo << "Value=" << gdoptimizer->GetValue() << "   ";
          m_fo << "Position=" << gdoptimizer->GetCurrentPosition() << std::endl;
        }
      }

      float maxNumIter = 0;
      std::vector<float> maxProgressIter;
      int i;
      for( i=0; i< m_registration->GetMaxNumberOfIterations()->GetNumberOfTuples();i++) {
        maxProgressIter.push_back( m_registration->GetMaxNumberOfIterations()->GetValue(i) );
        maxNumIter += m_registration->GetMaxNumberOfIterations()->GetValue(i);
      }
      if (maxNumIter == 0) {
        maxNumIter = 1;
      }
      for( i=0; i< m_registration->GetMaxNumberOfIterations()->GetNumberOfTuples();i++) {
        maxProgressIter[i] = maxProgressIter[i]/maxNumIter;
      }
      double progress = 0;
      for( i=0; i< level; i++) {
        progress += maxProgressIter[i];
      }
      progress += (iter + 0.0)/m_registration->GetMaxNumberOfIterations()->GetValue(level) * maxProgressIter[level];
      
      m_registration->UpdateProgress( progress );
    }
    m_fo.flush();
  }
};
//ETX
#endif





