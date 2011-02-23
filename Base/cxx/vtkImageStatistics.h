/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageStatistics.h,v $
  Date:      $Date: 2006/02/27 19:21:51 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/
// .NAME vtkImageStatistics - Get statistics on an image
// .SECTION Description
// vtkImageStatistics - Reads in an image with one compononet
// and determines the min, mean, max, quartiles, and median.
// This filter does NOT work in parallel
// If sorts the input data into the output data of the same size.
// Note that if IgnoreZero is set, all the zeros are put at the beginning
// of the output data.

#ifndef __vtkImageStatistics_h
#define __vtkImageStatistics_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class vtkImageData;
class VTK_SLICER_BASE_EXPORT vtkImageStatistics : public vtkImageToImageFilter
{
  public:
  static vtkImageStatistics *New();
  vtkTypeMacro(vtkImageStatistics,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Should the data with value 0 be ignored?
  // Note that this DOES work with float data.
  vtkSetMacro(IgnoreZero,int);
  vtkGetMacro(IgnoreZero,int);
  vtkBooleanMacro(IgnoreZero, int);

  // Description
  // Returns the number of elements examined.
  // If counts/does not count zeros appropriately.
  vtkGetMacro(NumExaminedElements,int);
  vtkSetMacro(NumExaminedElements,int);

  // Description:
  // Get Statistical Information:
  vtkGetMacro(Quartile1,double);
  vtkGetMacro(Median   ,double);
  vtkGetMacro(Quartile3,double);
  vtkGetMacro(Quintile1,double);
  vtkGetMacro(Quintile2,double);
  vtkGetMacro(Quintile3,double);
  vtkGetMacro(Quintile4,double);
  vtkGetMacro(Average  ,double);
  vtkGetMacro(Stdev    ,double);
  vtkGetMacro(Max      ,double);
  vtkGetMacro(Min      ,double);

  // Description
  // Don't use these.
  vtkSetMacro(Quartile1,double);
  vtkSetMacro(Median   ,double);
  vtkSetMacro(Quartile3,double);
  vtkSetMacro(Quintile1,double);
  vtkSetMacro(Quintile2,double);
  vtkSetMacro(Quintile3,double);
  vtkSetMacro(Quintile4,double);
  vtkSetMacro(Average  ,double);
  vtkSetMacro(Stdev    ,double);
  vtkSetMacro(Max      ,double);
  vtkSetMacro(Min      ,double);

  protected:
  vtkImageStatistics();
  ~vtkImageStatistics() {};
  vtkImageStatistics(const vtkImageStatistics&);
  void operator=(const vtkImageStatistics&);

  int    IgnoreZero;
  int    NumExaminedElements;
  double Quartile1;
  double Median;
  double Quartile3;
  double Quintile1;
  double Quintile2;
  double Quintile3;
  double Quintile4;
  double Average;  
  double Stdev;    
  double Max;
  double Min;

  void ExecuteInformation(vtkImageData *input, vtkImageData *output);
  void ComputeInputUpdateExtent(int inExt[6], int outExt[6]);
  void ExecuteData(vtkDataObject *);
};

#endif



