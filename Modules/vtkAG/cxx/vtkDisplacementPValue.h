/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDisplacementPValue.h,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkDisplacementPValue - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkDisplacementPValue_h
#define __vtkDisplacementPValue_h

#include <vtkAGConfigure.h>

// #include <vtkImageGradient.h>
#include <vtkImageTwoInputFilter.h>

class VTK_AG_EXPORT vtkDisplacementPValue : public vtkImageMultipleInputFilter
{
public:
  static vtkDisplacementPValue* New();
  vtkTypeMacro(vtkDisplacementPValue,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  vtkSetMacro(NumberOfSamples, int);
  vtkGetMacro(NumberOfSamples, int);

  virtual void SetMean(vtkImageData *input)
  {
    this->SetInput(0, input);
  }
  vtkImageData* GetMean();
  
  virtual void SetSigma(vtkImageData *input)
  {
    this->SetInput(1, input);
  }
  vtkImageData* GetSigma();
  
  virtual void SetDisplacement(vtkImageData *input)
  {
    this->SetInput(2, input);
  }
  vtkImageData* GetDisplacement();

protected:
  vtkDisplacementPValue();
  ~vtkDisplacementPValue();
  vtkDisplacementPValue(const vtkDisplacementPValue&);
  void operator=(const vtkDisplacementPValue&);
  void ExecuteInformation(vtkImageData **inDatas, vtkImageData *outData);
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
               int extent[6], int id);

  int NumberOfSamples;
};
#endif
