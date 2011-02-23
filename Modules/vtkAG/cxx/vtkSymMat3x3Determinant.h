/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSymMat3x3Determinant.h,v $
  Date:      $Date: 2006/02/14 20:51:35 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkSymMat3x3Determinant - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkSymMat3x3Determinant_h
#define __vtkSymMat3x3Determinant_h

#include <vtkAGConfigure.h>

#include <stdio.h>
#include <vtkImageToImageFilter.h>

class VTK_AG_EXPORT vtkSymMat3x3Determinant : public vtkImageToImageFilter {
public:
  static vtkSymMat3x3Determinant* New();
  vtkTypeMacro(vtkSymMat3x3Determinant,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
protected:
  vtkSymMat3x3Determinant();
  ~vtkSymMat3x3Determinant();
  vtkSymMat3x3Determinant(const vtkSymMat3x3Determinant&);
  void operator=(const vtkSymMat3x3Determinant&);
  void ExecuteInformation(vtkImageData *inData,vtkImageData *outData);
  void ThreadedExecute(vtkImageData *inDatas, vtkImageData *outData,
               int extent[6], int id);
};
#endif


