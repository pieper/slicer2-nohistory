/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWarpDMForce.h,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkImageWarpDMForce - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkImageWarpDMForce_h
#define __vtkImageWarpDMForce_h

#include <vtkAGConfigure.h>

#include <vtkImageWarpForce.h>

class VTK_AG_EXPORT vtkImageWarpDMForce : public vtkImageWarpForce
{
public:
  static vtkImageWarpDMForce* New();
  vtkTypeMacro(vtkImageWarpDMForce,vtkImageWarpForce);
  void PrintSelf(ostream& os, vtkIndent indent);

protected:
  vtkImageWarpDMForce();
  ~vtkImageWarpDMForce();
  vtkImageWarpDMForce(const vtkImageWarpDMForce&);
  void operator=(const vtkImageWarpDMForce&);
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
               int extent[6], int id);
};
#endif
