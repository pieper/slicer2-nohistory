/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKTranslationMIGradientDescentRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKTranslationMIGradientDescentRegistrationFilter_h
#define __vtkITKTranslationMIGradientDescentRegistrationFilter_h

#include <fstream>
#include <string>

#include "vtkITKTransformRegistrationFilter.h"
#include "itkTranslationMIGradientDescentRegistrationFilter.h"


// vtkITKTranslationMIGradientDescentRegistrationFilter Class

class VTK_EXPORT vtkITKTranslationMIGradientDescentRegistrationFilter : public vtkITKTransformRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKTranslationMIGradientDescentRegistrationFilter,vtkITKTransformRegistrationFilter);

  static vtkITKTranslationMIGradientDescentRegistrationFilter* New();

  void PrintSelf(ostream& os, vtkIndent indent)
  {
    Superclass::PrintSelf ( os, indent );
  };

  vtkSetObjectMacro(LearningRate, vtkDoubleArray);
  vtkGetObjectMacro(LearningRate, vtkDoubleArray);

  // Description:
  // Set the number of sample points for density estimation
  vtkSetMacro(NumberOfSamples, int);
  vtkGetMacro(NumberOfSamples, int);

  // Description:
  // Set the number of bins for density estimation
  vtkSetMacro(StandardDeviation, double);
  vtkGetMacro(StandardDeviation, double);


  // Description:
  // Reset the Multiresolution Settings
  // It blanks the Min/Max Step and NumberOfIterations
  void ResetMultiResolutionSettings()
  { LearningRate->Reset(); 
  MaxNumberOfIterations->Reset(); };
  
  // Description:
  // Set the min step for the algorithm.
  void SetNextLearningRate(const double step)
  { LearningRate->InsertNextValue(step); };

  void SetSourceShrinkFactors(unsigned int i,
                              unsigned int j, 
                              unsigned int k);

  void SetTargetShrinkFactors(unsigned int i,
                              unsigned int j, 
                              unsigned int k);

  unsigned int GetSourceShrinkFactors(const int &dir)
  { return SourceShrink[dir]; }

  unsigned int GetTargetShrinkFactors(const int &dir)
  { return TargetShrink[dir]; }
  
  virtual void GetTransformationMatrix(vtkMatrix4x4* matrix);
  
  virtual void GetCurrentTransformationMatrix(vtkMatrix4x4* matrix);
  
  virtual void SetTransformationMatrix(vtkMatrix4x4 *matrix);

  virtual void AbortIterations() {
    m_ITKFilter->AbortIterations();
  };


  void SetAbort(int abort) {
    m_ITKFilter->AbortIterations();
  }

  virtual double GetMetricValue() {
    return  m_ITKFilter->GetMetricValue();
  }

  virtual int GetCurrentLevel() { return m_ITKFilter->GetCurrentLevel();};

  virtual int GetCurrentIteration() {return m_ITKFilter->GetCurrentIteration();};

protected:


  vtkDoubleArray       *LearningRate;

  double StandardDeviation;

  int NumberOfSamples;

  unsigned int SourceShrink[3];
  unsigned int TargetShrink[3];
  //BTX

  itk::itkTranslationMIGradientDescentRegistrationFilter::Pointer m_ITKFilter;

  virtual void UpdateRegistrationParameters();

  virtual void CreateRegistrationPipeline();

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput();

  // default constructor
  vtkITKTranslationMIGradientDescentRegistrationFilter (); // This is called from New() by vtkStandardNewMacro

  virtual ~vtkITKTranslationMIGradientDescentRegistrationFilter() {};
  //ETX
  
private:
  vtkITKTranslationMIGradientDescentRegistrationFilter(const vtkITKTranslationMIGradientDescentRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKTranslationMIGradientDescentRegistrationFilter&);  // Not implemented.
};

vtkRegistrationNewMacro(vtkITKTranslationMIGradientDescentRegistrationFilter);

#endif




