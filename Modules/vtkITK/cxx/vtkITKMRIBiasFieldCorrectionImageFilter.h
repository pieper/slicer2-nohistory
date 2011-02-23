/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKMRIBiasFieldCorrectionImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKMRIBiasFieldCorrectionImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.3 $
*/
// .NAME vtkITKMRIBiasFieldCorrectionImageFilter - Wrapper class around itk::MRIBiasFieldCorrectionImageFilterImageFilter
// .SECTION Description
// vtkITKMRIBiasFieldCorrectionImageFilter


#ifndef __vtkITKMRIBiasFieldCorrectionImageFilter_h
#define __vtkITKMRIBiasFieldCorrectionImageFilter_h


#include "vtkITKImageToImageFilterFF.h"

#include "itkMRIBiasFieldCorrectionFilter.h"
#include "itkArray.h"

#include "vtkObjectFactory.h"
#include "vtkDoubleArray.h"
#include "vtkUnsignedIntArray.h"

class VTK_EXPORT vtkITKMRIBiasFieldCorrectionImageFilter : public vtkITKImageToImageFilterFF
{
 public:
  static vtkITKMRIBiasFieldCorrectionImageFilter *New();
  vtkTypeRevisionMacro(vtkITKMRIBiasFieldCorrectionImageFilter, vtkITKImageToImageFilterFF);

  void SetTissueClassMeans( vtkDoubleArray *classMeans )
  {
    this->_classMeans->DeepCopy( classMeans );

    if ( this->_classMeans->GetNumberOfTuples() != this->_classSigmas->GetNumberOfTuples() ) {
      this->_classSigmas->SetNumberOfTuples( this->_classMeans->GetNumberOfTuples() );
      this->_classSigmas->DeepCopy( classMeans );
    }

    this->SetTissueClassStatistics();
  }

  void SetTissueClassSigmas( vtkDoubleArray *classSigmas )
  {
    this->_classSigmas->DeepCopy( classSigmas );

    if ( this->_classMeans->GetNumberOfTuples() != this->_classSigmas->GetNumberOfTuples() ) {
      this->_classMeans->SetNumberOfTuples( this->_classSigmas->GetNumberOfTuples() );
      this->_classMeans->DeepCopy( classSigmas );
    }

    this->SetTissueClassStatistics();
  }

  int GetUsingSlabIdentification ()
  {
    DelegateITKOutputMacro ( GetUsingSlabIdentification );
  };
  void SetUsingSlabIdentification( int value )
  {
    DelegateITKInputMacro ( SetUsingSlabIdentification, (bool)value );
  };
  void UsingSlabIdentificationOff()
  {
    SetUsingSlabIdentification(false);
  };
  void UsingSlabIdentificationOn()
  {
    SetUsingSlabIdentification(true);
  };

  int GetUsingInterSliceIntensityCorrection ()
  {
    DelegateITKOutputMacro ( GetUsingInterSliceIntensityCorrection );
  };
  void SetUsingInterSliceIntensityCorrection( int value )
  {
    DelegateITKInputMacro ( SetUsingInterSliceIntensityCorrection, (bool)value );
  };
  void UsingInterSliceIntensityCorrectionOn()
  {
    SetUsingInterSliceIntensityCorrection(true);
  }
  void UsingInterSliceIntensityCorrectionOff()
  {
    SetUsingInterSliceIntensityCorrection(false);
  }

  int GetVolumeCorrectionMaximumIteration ()
  {
    DelegateITKOutputMacro ( GetVolumeCorrectionMaximumIteration );
  };
  void SetVolumeCorrectionMaximumIteration( int value )
  {
    DelegateITKInputMacro ( SetVolumeCorrectionMaximumIteration, value );
  };

  int GetInterSliceCorrectionMaximumIteration ()
  {
    DelegateITKOutputMacro ( GetInterSliceCorrectionMaximumIteration );
  };
  void SetInterSliceCorrectionMaximumIteration( int value )
  {
    DelegateITKInputMacro ( SetInterSliceCorrectionMaximumIteration, value );
  };

  int GetBiasFieldDegree ()
  {
    DelegateITKOutputMacro ( GetBiasFieldDegree );
  };
  void SetBiasFieldDegree( int value )
  {
    DelegateITKInputMacro ( SetBiasFieldDegree, value );
  };

  int GetSlabNumberOfSamples ()
  {
    DelegateITKOutputMacro ( GetSlabNumberOfSamples );
  };
  void SetSlabNumberOfSamples( int value )
  {
    DelegateITKInputMacro ( SetSlabNumberOfSamples, value );
  };

  void SetSlicingDirection( int value )
  {
    DelegateITKInputMacro ( SetSlicingDirection, value );
  };


  double GetSlabBackgroundMinimumThreshold ()
  {
    DelegateITKOutputMacro ( GetSlabBackgroundMinimumThreshold );
  };
  void SetSlabBackgroundMinimumThreshold( double value )
  {
    InputImagePixelType d = static_cast<InputImagePixelType> ( value );
    DelegateITKInputMacro ( SetSlabBackgroundMinimumThreshold, d );
  };

  void SetOptimizerGrowthFactor ( double value )
  {
    DelegateITKInputMacro ( SetOptimizerGrowthFactor, value );
  };

  double GetOptimizerInitialRadius ()
  {
    DelegateITKOutputMacro(GetOptimizerInitialRadius) ;
  };
  void SetOptimizerInitialRadius ( double value )
  {
    DelegateITKInputMacro ( SetOptimizerInitialRadius, value );
  };

  double GetSlabTolerance ()
  {
    DelegateITKOutputMacro(GetSlabTolerance) ;
  };
  void SetSlabTolerance ( double value )
  {
    DelegateITKInputMacro ( SetSlabTolerance, value );
  };


protected:
  //BTX
  typedef itk::MRIBiasFieldCorrectionFilter<Superclass::InputImageType,Superclass::InputImageType,Superclass::InputImageType> ImageFilterType;
  vtkITKMRIBiasFieldCorrectionImageFilter() : Superclass ( ImageFilterType::New() ) 
  {
    _classMeans =  vtkDoubleArray::New();
    _classSigmas = vtkDoubleArray::New();
  };
  ~vtkITKMRIBiasFieldCorrectionImageFilter() 
  {
    _classMeans->Delete();
    _classSigmas->Delete();
  };
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }

  void SetTissueClassStatistics()
  {
    itk::Array<double> itkClassMeans( _classMeans->GetNumberOfTuples() ) ;
    itk::Array<double> itkClassSigmas( _classSigmas->GetNumberOfTuples() ) ;
    
    for(int i=0; i< _classMeans->GetNumberOfTuples();i++) {
      itkClassMeans[i] = _classMeans->GetValue(i);
      itkClassSigmas[i] = _classSigmas->GetValue(i);
    }
    this->GetImageFilterPointer()->SetTissueClassStatistics (itkClassMeans, itkClassSigmas);
  }

  vtkDoubleArray *_classMeans;
  vtkDoubleArray *_classSigmas;
  //ETX
  
private:
  vtkITKMRIBiasFieldCorrectionImageFilter(const vtkITKMRIBiasFieldCorrectionImageFilter&);  // Not implemented.
  void operator=(const vtkITKMRIBiasFieldCorrectionImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKMRIBiasFieldCorrectionImageFilter, "$Revision: 1.3 $");
vtkStandardNewMacro(vtkITKMRIBiasFieldCorrectionImageFilter);

#endif




