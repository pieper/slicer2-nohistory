/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageBrainSegment.h,v $
  Date:      $Date: 2006/02/14 20:51:34 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkImageBrainSegment - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkImageBrainSegment_h
#define __vtkImageBrainSegment_h

#include <vtkAGConfigure.h>

#include <stdio.h>
#include <vtkImageToImageFilter.h>

class VTK_AG_EXPORT vtkImageBrainSegment : public vtkImageToImageFilter {
public:
  static vtkImageBrainSegment* New();
  vtkTypeMacro(vtkImageBrainSegment,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  vtkSetMacro(ErodeKernelSize,int);
  vtkGetMacro(ErodeKernelSize,int);
  
  vtkSetMacro(DilateKernelSize,int);
  vtkGetMacro(DilateKernelSize,int);
  
protected:
  vtkImageBrainSegment();
  ~vtkImageBrainSegment();
  vtkImageBrainSegment(const vtkImageBrainSegment&);
  void operator=(const vtkImageBrainSegment&);
  void ExecuteData(vtkDataObject *output);
  void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);

private:
  int Average(vtkImageData* img,int thesh);
  int ErodeKernelSize;
  int DilateKernelSize;
};
#endif


