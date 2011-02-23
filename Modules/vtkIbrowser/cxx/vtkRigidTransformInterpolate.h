/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkRigidTransformInterpolate.h,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkRigidTransformInterpolate - Reads Nearly Raw Raster Data files
// .SECTION Description
// vtkRigidTransformInterpolate 
// Uses Quaternion code from vtkMath to interpolated between two rigid transform matrices
//

//
// .SECTION See Also
// vtkObject

#ifndef __vtkRigidTransformInterpolate_h
#define __vtkRigidTransformInterpolate_h

#include "vtkIbrowserConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkMatrix4x4.h"

class VTK_IBROWSER_EXPORT vtkRigidTransformInterpolate : public vtkObject
{
public:
  static vtkRigidTransformInterpolate *New();
  vtkTypeRevisionMacro(vtkRigidTransformInterpolate,vtkObject);
  virtual void PrintSelf(ostream& os, vtkIndent indent);

  vtkSetObjectMacro(M0,vtkMatrix4x4);
  vtkSetObjectMacro(M1,vtkMatrix4x4);
  vtkSetObjectMacro(MT,vtkMatrix4x4);
  vtkGetObjectMacro(M0,vtkMatrix4x4);
  vtkGetObjectMacro(M1,vtkMatrix4x4);
  vtkGetObjectMacro(MT,vtkMatrix4x4);

  vtkSetMacro(T,vtkFloatingPointType);
  vtkGetMacro(T,vtkFloatingPointType);

  void Interpolate();

protected:
  vtkRigidTransformInterpolate() {
    this->M0 = 0; 
    this->M1 = 0; 
    this->MT = 0; 
    this->T = 0.; 
  };
  ~vtkRigidTransformInterpolate() {};

private:

  vtkMatrix4x4 *M0;
  vtkMatrix4x4 *M1;
  vtkMatrix4x4 *MT;
  vtkFloatingPointType T;

  vtkRigidTransformInterpolate(const vtkRigidTransformInterpolate&);  // Not implemented.
  void operator=(const vtkRigidTransformInterpolate&);  // Not implemented.
};
#endif


