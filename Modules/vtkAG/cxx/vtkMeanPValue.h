/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMeanPValue.h,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkMeanPValue - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkMeanPValue_h
#define __vtkMeanPValue_h

#include <vtkAGConfigure.h>

// #include <vtkImageGradient.h>
#include <vtkImageTwoInputFilter.h>

class VTK_AG_EXPORT vtkMeanPValue : public vtkImageMultipleInputFilter
{
public:
  static vtkMeanPValue* New();
  vtkTypeMacro(vtkMeanPValue,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  vtkSetMacro(NumberOfSamples1, int);
  vtkGetMacro(NumberOfSamples1, int);

  vtkSetMacro(NumberOfSamples2, int);
  vtkGetMacro(NumberOfSamples2, int);

  virtual void SetMean1(vtkImageData *input)
  {
    this->SetInput(0, input);
  }
  vtkImageData* GetMean1();
  
  virtual void SetSigma1(vtkImageData *input)
  {
    this->SetInput(1, input);
  }
  vtkImageData* GetSigma1();
  
  virtual void SetMean2(vtkImageData *input)
  {
    this->SetInput(2, input);
  }
  vtkImageData* GetMean2();
  
  virtual void SetSigma2(vtkImageData *input)
  {
    this->SetInput(3, input);
  }
  vtkImageData* GetSigma2();
  
protected:
  vtkMeanPValue();
  ~vtkMeanPValue();
  vtkMeanPValue(const vtkMeanPValue&);
  void operator=(const vtkMeanPValue&);
  void ExecuteInformation(vtkImageData **inDatas, vtkImageData *outData);
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
               int extent[6], int id);

  int NumberOfSamples1;
  int NumberOfSamples2;
};
#endif
