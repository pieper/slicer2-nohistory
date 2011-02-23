/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageAutoCorrelation.h,v $
  Date:      $Date: 2006/02/14 20:51:34 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkImageAutoCorrelation - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkImageAutoCorrelation_h
#define __vtkImageAutoCorrelation_h

#include <vtkAGConfigure.h>

#include <stdio.h>
#include <vtkImageToImageFilter.h>

class VTK_AG_EXPORT vtkImageAutoCorrelation : public vtkImageToImageFilter {
public:
  static vtkImageAutoCorrelation* New();
  vtkTypeMacro(vtkImageAutoCorrelation,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
protected:
  vtkImageAutoCorrelation();
  ~vtkImageAutoCorrelation();
  vtkImageAutoCorrelation(const vtkImageAutoCorrelation&);
  void operator=(const vtkImageAutoCorrelation&);
  void ExecuteInformation(vtkImageData *inData,vtkImageData *outData);
  void ThreadedExecute(vtkImageData *inDatas, vtkImageData *outData,
               int extent[6], int id);
};
#endif


