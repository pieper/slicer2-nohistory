/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageScalarsToTensors.h,v $
  Date:      $Date: 2006/02/14 20:51:34 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkImageScalarsToTensors - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkImageScalarsToTensors_h
#define __vtkImageScalarsToTensors_h

#include <vtkAGConfigure.h>

#include <vtkImageToImageFilter.h>

class VTK_AG_EXPORT vtkImageScalarsToTensors : public vtkImageToImageFilter {
public:
  static vtkImageScalarsToTensors* New();
  vtkTypeMacro(vtkImageScalarsToTensors,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
protected:
  vtkImageScalarsToTensors() {}
  ~vtkImageScalarsToTensors() {}
  vtkImageScalarsToTensors(const vtkImageScalarsToTensors&);
  void operator=(const vtkImageScalarsToTensors&);
  void ExecuteData(vtkDataObject *out);
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
                int extent[6], int id);
};
#endif


