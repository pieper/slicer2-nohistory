/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageMosaik.h,v $
  Date:      $Date: 2006/02/23 02:29:34 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkImageMosaik - Make a mosaik from 2 image inputs
// .SECTION Description
// vtkImageMosaik takes 2 inputs images and merges
// them into one output (the mosaik). All inputs must have the same extent,
// scalar type, and number of components.

#ifndef __vtkImageMosaik_h
#define __vtkImageMosaik_h

#include "vtkCompareModuleConfigure.h"

#include "vtkImageData.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkSlicer.h"

class VTK_COMPAREMODULE_EXPORT vtkImageMosaik : public vtkImageMultipleInputFilter
{
public:
  static vtkImageMosaik *New();
  vtkTypeMacro(vtkImageMosaik,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Sets the opacity used to overlay this layer on the others
  double GetOpacity();
  void SetOpacity(double opacity);

  // Sets the mosaik width and height
  int GetDivisionWidth();
  int GetDivisionHeight();
  void SetDivisionWidth(int width);
  void SetDivisionHeight(int height);

protected:
  vtkImageMosaik();
  ~vtkImageMosaik();

  double opacity;
  int divisionWidth;
  int divisionHeight;

  void ExecuteData(vtkDataObject *data);

private:
  vtkImageMosaik(const vtkImageMosaik&);
  void operator=(const vtkImageMosaik&);
};

#endif
