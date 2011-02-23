/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStreamlineConvolve2.h,v $
  Date:      $Date: 2006/08/15 16:43:39 $
  Version:   $Revision: 1.1 $

=========================================================================auto=*/
// .NAME vtkStreamlineConvolve2 - extracts points whose scalar value satisfies threshold criterion
// .SECTION Description
// vtkStreamlineConvolve2 is a filter that extracts points from a dataset that 
// satisfy a threshold criterion. The criterion can take three forms:
// 1) greater than a particular value; 2) less than a particular value; or
// 3) between a particular value. The output of the filter is polygonal data.
// .SECTION See Also
// vtkThreshold

#ifndef __vtkStreamlineConvolve2_h
#define __vtkStreamlineConvolve2_h

#include "vtkDTMRIConfigure.h"

#include <vtkStructuredPointsToPolyDataFilter.h>
#include "vtkDoubleArray.h"
#include "vtkMultiThreader.h"
#include "vtkPolyData.h"
#include "vtkTransform.h"

class VTK_DTMRI_EXPORT vtkStreamlineConvolve2 : public vtkStructuredPointsToPolyDataFilter
{
public:
  static vtkStreamlineConvolve2 *New();
  vtkTypeRevisionMacro(vtkStreamlineConvolve2,vtkStructuredPointsToPolyDataFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
    // Description:
  // Get the kernel size
  vtkGetVector3Macro(Sigma, double);
  vtkSetVector3Macro(Sigma, double);

  vtkSetMacro(KernelSize,int);
  vtkGetMacro(KernelSize,int);

  // Description:
  // Set/Get the Streamline to convolve with.
  vtkSetObjectMacro(Streamlines,vtkPolyData);
  vtkGetObjectMacro(Streamlines,vtkPolyData); 
  
  // Descritpion:
  // Transformation that maps one point of the streamline
  // into the ijk space of the image input.
  vtkSetObjectMacro(Transform,vtkTransform);
  vtkGetObjectMacro(Transform,vtkTransform); 
  
  vtkSetMacro(NumberOfThreads,int);
  vtkGetMacro(NumberOfThreads,int);

  void ThreadedExecute(vtkImageData *input, vtkPolyData *output, int range[2], int id);

protected:
  vtkStreamlineConvolve2();
  ~vtkStreamlineConvolve2();

  // Usual data generation method
  void Execute();
  void MultiThread(vtkImageData *input, vtkPolyData *output);
  vtkPolyData *Streamlines;
  vtkTransform *Transform;
  vtkMultiThreader *Threader;
  double Sigma[3];
  int KernelSize;
  int NumberOfThreads;

private:
  vtkStreamlineConvolve2(const vtkStreamlineConvolve2&);  // Not implemented.
  void operator=(const vtkStreamlineConvolve2&);  // Not implemented.
};

#endif
