/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKAffineMattesMIRegistrationFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:44 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKAffineMattesMIRegistrationFilter_h
#define __vtkITKAffineMattesMIRegistrationFilter_h

#include <fstream>
#include <string>

#include "vtkITKTransformRegistrationFilter.h"
#include "itkAffineMattesMIRegistrationFilter.h"


// vtkITKAffineMattesMIRegistrationFilter Class

class VTK_EXPORT vtkITKAffineMattesMIRegistrationFilter : public vtkITKTransformRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKAffineMattesMIRegistrationFilter,vtkITKTransformRegistrationFilter);

  static vtkITKAffineMattesMIRegistrationFilter* New();

  void PrintSelf(ostream& os, vtkIndent indent)
  {
    Superclass::PrintSelf ( os, indent );
  };

  vtkSetMacro(TranslateScale, double);
  vtkGetMacro(TranslateScale, double);

  vtkSetObjectMacro(MinimumStepLength, vtkDoubleArray);
  vtkGetObjectMacro(MinimumStepLength, vtkDoubleArray);

  vtkSetObjectMacro(MaximumStepLength, vtkDoubleArray);
  vtkGetObjectMacro(MaximumStepLength, vtkDoubleArray);

  // Description:
  // Set the number of sample points for density estimation
  vtkSetMacro(NumberOfSamples, int);
  vtkGetMacro(NumberOfSamples, int);

  // Description:
  // Set the number of bins for density estimation
  vtkSetMacro(NumberOfHistogramBins, int);
  vtkGetMacro(NumberOfHistogramBins, int);


  // Description:
  // Reset the Multiresolution Settings
  // It blanks the Min/Max Step and NumberOfIterations
  void ResetMultiResolutionSettings()
  { MinimumStepLength->Reset(); 
    MaxNumberOfIterations->Reset();
    MaximumStepLength->Reset(); };
  
  // Description:
  // Set the min step for the algorithm.
  void SetNextMinimumStepLength(const double step)
  { MinimumStepLength->InsertNextValue(step); };

  // Description:
  // Set the max step for the algorithm.
  void SetNextMaximumStepLength(const double step)
  { MaximumStepLength->InsertNextValue(step); };

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
  void ReSeedSamples() {
    m_ITKFilter->SetReinitializeSeed(8775070);
  }

  virtual int GetCurrentLevel() { return m_ITKFilter->GetCurrentLevel();};

  virtual int GetCurrentIteration() {return m_ITKFilter->GetCurrentIteration();};

protected:

  double TranslateScale;

  vtkDoubleArray       *MinimumStepLength;

  vtkDoubleArray       *MaximumStepLength;

  int NumberOfHistogramBins;

  int NumberOfSamples;

  unsigned int SourceShrink[3];
  unsigned int TargetShrink[3];
  //BTX

  itk::itkAffineMattesMIRegistrationFilter::Pointer m_ITKFilter;

  virtual void UpdateRegistrationParameters();

  virtual void CreateRegistrationPipeline();

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput();

  // default constructor
  vtkITKAffineMattesMIRegistrationFilter (); // This is called from New() by vtkStandardNewMacro

  virtual ~vtkITKAffineMattesMIRegistrationFilter() {};
  //ETX
  
private:
  vtkITKAffineMattesMIRegistrationFilter(const vtkITKAffineMattesMIRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKAffineMattesMIRegistrationFilter&);  // Not implemented.
};

vtkRegistrationNewMacro(vtkITKAffineMattesMIRegistrationFilter);

#endif




