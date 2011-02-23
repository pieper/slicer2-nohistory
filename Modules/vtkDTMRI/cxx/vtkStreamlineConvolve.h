/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStreamlineConvolve.h,v $
  Date:      $Date: 2006/03/06 21:07:30 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkStreamlineConvolve - extracts points whose scalar value satisfies threshold criterion
// .SECTION Description
// vtkStreamlineConvolve is a filter that extracts points from a dataset that 
// satisfy a threshold criterion. The criterion can take three forms:
// 1) greater than a particular value; 2) less than a particular value; or
// 3) between a particular value. The output of the filter is polygonal data.
// .SECTION See Also
// vtkThreshold

#ifndef __vtkStreamlineConvolve_h
#define __vtkStreamlineConvolve_h

#include "vtkDTMRIConfigure.h"

#include <vtkStructuredPointsToPolyDataFilter.h>
#include "vtkDoubleArray.h"

#include "vtkPolyData.h"
#include "vtkTransform.h"

class VTK_DTMRI_EXPORT vtkStreamlineConvolve : public vtkStructuredPointsToPolyDataFilter
{
public:
  static vtkStreamlineConvolve *New();
  vtkTypeRevisionMacro(vtkStreamlineConvolve,vtkStructuredPointsToPolyDataFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
    // Description:
  // Get the kernel size
  vtkGetVector3Macro(KernelSize, int);

  // Description:
  // Set the kernel to be a given 3x3 or 5x5 or 7x7 kernel.
  void SetKernel3x3(vtkDoubleArray* kernel);
  void SetKernel5x5(vtkDoubleArray* kernel);
  void SetKernel7x7(vtkDoubleArray* kernel);

  // Description:
  // Set the kernel to be a 3x3x3 or 5x5x5 or 7x7x7 kernel.
  void SetKernel3x3x3(vtkDoubleArray* kernel);
  void SetKernel5x5x5(vtkDoubleArray* kernel);
  void SetKernel7x7x7(vtkDoubleArray* kernel);

  // Description:
  // Return an array that contains the kernel
  void GetKernel(vtkDoubleArray *kernel); 
  double* GetKernel();

  // Description:
  // Set/Get the Streamline to convolve with.
  vtkSetObjectMacro(Streamlines,vtkPolyData);
  vtkGetObjectMacro(Streamlines,vtkPolyData); 
  
  // Descritpion:
  // Transformation that maps one point of the streamline
  // into the ijk space of the image input.
  vtkSetObjectMacro(Transform,vtkTransform);
  vtkGetObjectMacro(Transform,vtkTransform); 

protected:
  vtkStreamlineConvolve();
  ~vtkStreamlineConvolve();

  // Usual data generation method
  void Execute();
  
  void SetKernel(vtkDoubleArray* kernel,
                 int sizeX, int sizeY, int sizeZ);
  

  int KernelSize[3];
  double Kernel[343];
  vtkPolyData *Streamlines;
  vtkTransform *Transform;

private:
  vtkStreamlineConvolve(const vtkStreamlineConvolve&);  // Not implemented.
  void operator=(const vtkStreamlineConvolve&);  // Not implemented.
};

#endif
