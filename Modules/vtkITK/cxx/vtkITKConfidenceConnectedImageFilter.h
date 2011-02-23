/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKConfidenceConnectedImageFilter.h,v $
  Date:      $Date: 2006/01/06 17:57:45 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKConfidenceConnectedImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:45 $
  Version:   $Revision: 1.5 $
*/
// .NAME vtkITKConfidenceConnectedImageFilter - Wrapper class around itk::ConfidenceConnectedImageFilter
// .SECTION Description
// vtkITKConfidenceConnectedImageFilter


#ifndef __vtkITKConfidenceConnectedImageFilter_h
#define __vtkITKConfidenceConnectedImageFilter_h


#include "vtkITKImageToImageFilterUSUS.h"
#include "itkConfidenceConnectedImageFilter.h"
#include "vtkObjectFactory.h"

class VTK_EXPORT vtkITKConfidenceConnectedImageFilter : public vtkITKImageToImageFilterUSUS
{
 public:
  static vtkITKConfidenceConnectedImageFilter *New();
  vtkTypeRevisionMacro(vtkITKConfidenceConnectedImageFilter, vtkITKImageToImageFilterUSUS);

  void SetReplaceValue ( double value )
  {
    InputImagePixelType d = static_cast<InputImagePixelType> ( value );
    DelegateITKInputMacro ( SetReplaceValue, d );
  };

  void SetMultiplier ( double value )
  {
    DelegateITKInputMacro ( SetMultiplier, value );
  };
  double GetMultiplier()
  { DelegateITKOutputMacro ( GetMultiplier ); };

  void SetNumberOfIterations ( unsigned int value )
  {
    DelegateITKInputMacro ( SetNumberOfIterations, value );
  };
  unsigned int GetNumberOfIterations()
  { DelegateITKOutputMacro ( GetNumberOfIterations ); };

  void SetSeed ( int x, int y, int z )
  {
    ImageFilterType::IndexType seed;
    seed[0] = x;
    seed[1] = y;
    seed[2] = z;
    this->GetImageFilterPointer()->SetSeed ( seed );
  }

  void AddSeed ( int x, int y, int z )
  {
    ImageFilterType::IndexType seed;
    seed[0] = x;
    seed[1] = y;
    seed[2] = z;
    this->GetImageFilterPointer()->AddSeed ( seed );
  }

  void ClearSeeds ( )
  {
      this->GetImageFilterPointer()->ClearSeeds();
  }

protected:
  //BTX
  typedef itk::ConfidenceConnectedImageFilter<Superclass::InputImageType, Superclass::OutputImageType> ImageFilterType;
  vtkITKConfidenceConnectedImageFilter() : Superclass ( ImageFilterType::New() ){};
  ~vtkITKConfidenceConnectedImageFilter() {};
  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }
  //ETX
  
private:
  vtkITKConfidenceConnectedImageFilter(const vtkITKConfidenceConnectedImageFilter&);  // Not implemented.
  void operator=(const vtkITKConfidenceConnectedImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKConfidenceConnectedImageFilter, "$Revision: 1.5 $");
vtkStandardNewMacro(vtkITKConfidenceConnectedImageFilter);

#endif




