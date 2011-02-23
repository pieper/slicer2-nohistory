/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWarpOFForce.h,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkImageWarpOFForce - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkImageWarpOFForce_h
#define __vtkImageWarpOFForce_h

#include <vtkAGConfigure.h>

#include <vtkImageWarpForce.h>

class VTK_AG_EXPORT vtkImageWarpOFForce : public vtkImageWarpForce
{
public:
  static vtkImageWarpOFForce* New();
  vtkTypeMacro(vtkImageWarpOFForce,vtkImageWarpForce);
  void PrintSelf(ostream& os, vtkIndent indent);

protected:
  vtkImageWarpOFForce();
  ~vtkImageWarpOFForce();
  vtkImageWarpOFForce(const vtkImageWarpOFForce&);
  void operator=(const vtkImageWarpOFForce&);
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
               int extent[6], int id);
};
#endif
