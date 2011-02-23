/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKOtsuMultipleThresholdsImageFilter.h,v $
  Date:      $Date: 2006/03/21 20:58:36 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKOtsuMultipleThresholdsImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/03/21 20:58:36 $
  Version:   $Revision: 1.4 $
*/
// .NAME vtkITKOtsuMultipleThresholdsImageFilter - Wrapper class around itk::OtsuMultipleThresholdsImageFilter
// .SECTION Description
// vtkITKOtsuMultipleThresholdsImageFilter


#ifndef __vtkITKOtsuMultipleThresholdsImageFilter_h
#define __vtkITKOtsuMultipleThresholdsImageFilter_h


#include "vtkITKImageToImageFilterSS.h"
#include "itkOtsuMultipleThresholdsImageFilter.h"
#include "vtkShortArray.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKOtsuMultipleThresholdsImageFilter : public vtkITKImageToImageFilterSS
{
 public:
  static vtkITKOtsuMultipleThresholdsImageFilter *New();
  vtkTypeRevisionMacro(vtkITKOtsuMultipleThresholdsImageFilter, vtkITKImageToImageFilterSS);
  
  //BTX
  typedef itk::OtsuMultipleThresholdsImageFilter<Superclass::InputImageType, Superclass::OutputImageType> ImageFilterType;
  //ETX

  void SetNumberOfHistogramBins( unsigned long value) 
  {
    DelegateITKInputMacro ( SetNumberOfHistogramBins, value );
  };
  unsigned long GetNumberOfHistogramBins ()
  { DelegateITKOutputMacro ( GetNumberOfHistogramBins ); };
  
  void SetNumberOfThresholds (unsigned long value)
  {
    DelegateITKInputMacro ( SetNumberOfThresholds, value );
  };
  unsigned long GetNumberOfThresholds ()
  { DelegateITKOutputMacro ( GetNumberOfThresholds ); };  
  
  void SetLabelOffset (short value)
  { 
    OutputImagePixelType d = static_cast<OutputImagePixelType> ( value );
    DelegateITKInputMacro (SetLabelOffset,d);
  }
  
  OutputImagePixelType GetLabelOffset ()
  { DelegateITKOutputMacro ( GetLabelOffset ); };
  
  vtkShortArray *GetThresholds () {
    ImageFilterType::ThresholdVectorType th;
    th = this->GetImageFilterPointer()->GetThresholds();
    this->Thresholds->SetNumberOfComponents(1);
    this->Thresholds->SetNumberOfTuples(th.size());
    
    for(int i=0; i<th.size();i++)
      this->Thresholds->SetComponent(i,0,th[i]);  
   
    return this->Thresholds;
   }
   

protected:
  //BTX
  vtkITKOtsuMultipleThresholdsImageFilter() : Superclass (ImageFilterType::New())
  {
    this->Thresholds = vtkShortArray::New();
  };
  ~vtkITKOtsuMultipleThresholdsImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }
  //ETX
  
private:
  vtkITKOtsuMultipleThresholdsImageFilter(const vtkITKOtsuMultipleThresholdsImageFilter&);  // Not implemented.
  void operator=(const vtkITKOtsuMultipleThresholdsImageFilter&);  // Not implemented.
  
  vtkShortArray *Thresholds;
  
};

vtkCxxRevisionMacro(vtkITKOtsuMultipleThresholdsImageFilter, "$Revision: 1.4 $");
vtkStandardNewMacro(vtkITKOtsuMultipleThresholdsImageFilter);

#endif




