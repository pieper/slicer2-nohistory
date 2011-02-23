/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWireScale.h,v $
  Date:      $Date: 2006/02/27 19:21:50 $
  Version:   $Revision: 1.16 $

=========================================================================auto=*/
// .NAME vtkImageLiveWireScale - General scaling of images for input to LiveWire
// .SECTION Description
// This class outputs images whose values range from 0 to 1. (or
// from 0 to this->ScaleFactor if it is set).  This is needed to 
// control magnitude of input images to livewire.
//
// Can scale in the following ways:
// divide input by max value (after shifting input to begin at value 0)
// do the above, then pass through a function
//
// Can use the input as is, or ignore input values less than LowerCutoff
// or greater than UpperCutoff.
//

#ifndef __vtkImageLiveWireScale_h
#define __vtkImageLiveWireScale_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageLiveWireScale : public vtkImageToImageFilter
{
  public:
  static vtkImageLiveWireScale *New();
  vtkTypeMacro(vtkImageLiveWireScale,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // scale factor to multiply image by 
  // (so output is <=ScaleFactor instead of <=1)
  vtkSetMacro(ScaleFactor,int);
  vtkGetMacro(ScaleFactor,int);

  vtkSetMacro(UseTransformationFunction,int);
  vtkGetMacro(UseTransformationFunction,int);

  vtkSetMacro(TransformationFunctionNumber,int);
  vtkGetMacro(TransformationFunctionNumber,int);

#define INVERSE_LINEAR_RAMP 1
#define ONE_OVER_X 2

  void SetTransformationFunctionToOneOverX() {
    this->TransformationFunctionNumber = ONE_OVER_X;
    this->UseTransformationFunction = 1;
  };
  void SetTransformationFunctionToInverseLinearRamp() {
    this->TransformationFunctionNumber = INVERSE_LINEAR_RAMP;    
    this->UseTransformationFunction = 1;
  };
  void SetUpperCutoff(vtkFloatingPointType num) {
    this->UpperCutoff = num;    
    this->UseUpperCutoff = 1;
    this->Modified();
  };
  void SetLowerCutoff(vtkFloatingPointType num) {
    this->LowerCutoff = num;    
    this->UseLowerCutoff = 1;
    this->Modified();
  };
  // just here for access from Execute.
  vtkFloatingPointType TransformationFunction(vtkFloatingPointType intensity, vtkFloatingPointType max, vtkFloatingPointType min);

protected:
  vtkImageLiveWireScale();
  ~vtkImageLiveWireScale();
  
  int ScaleFactor;
  vtkFloatingPointType UpperCutoff;
  vtkFloatingPointType LowerCutoff;
  int UseUpperCutoff;
  int UseLowerCutoff;

  int UseTransformationFunction;
  int TransformationFunctionNumber;

  void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);
  void UpdateData(vtkDataObject *data);
  void ExecuteInformation(){this->Superclass::ExecuteInformation();};
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
                       int ext[6], int id);
private:
  vtkImageLiveWireScale(const vtkImageLiveWireScale&);
  void operator=(const vtkImageLiveWireScale&);
};

#endif



