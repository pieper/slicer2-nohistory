/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPWMedianIT.h,v $
  Date:      $Date: 2006/01/06 17:57:12 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#ifndef __vtkPWMedianIT_h
#define __vtkPWMedianIT_h

#include <vtkAGConfigure.h>

#include <vtkPWConstantIT.h>

class VTK_AG_EXPORT vtkPWMedianIT : public vtkPWConstantIT
{
public:
  static vtkPWMedianIT* New();
  vtkTypeMacro(vtkPWMedianIT,vtkPWConstantIT);
  void PrintSelf(ostream& os, vtkIndent indent);
      
protected:
  vtkPWMedianIT();
  ~vtkPWMedianIT();
  vtkPWMedianIT(const vtkPWMedianIT&);
  void operator=(const vtkPWMedianIT&);

  void InternalUpdate();
};

#endif


