/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageExtractSlices.h,v $
  Date:      $Date: 2006/03/06 21:07:29 $
  Version:   $Revision: 1.9 $
 
=========================================================================auto=*/
// .NAME vtkImageDiffusionTensor - 
// .SECTION Description

#ifndef __vtkImageExtractSlices_h
#define __vtkImageExtractSlices_h

#include "vtkDTMRIConfigure.h"
#include "vtkImageToImageFilter.h"

#define MODESLICE 0
#define MODEVOLUME 1
#define MODEMOSAIC 2

class VTK_DTMRI_EXPORT vtkImageExtractSlices : public vtkImageToImageFilter
{
 public:
  static vtkImageExtractSlices *New();
  vtkTypeMacro(vtkImageExtractSlices,vtkImageToImageFilter);

  // Description:
  // Number of the slice to extract from the volume
  // Specified as an offset that repeats once each
  // SlicePeriod.  For example if the period is 5 slices
  // and the offset is 0, we will extract slices 0,
  // 5, 10, and so on.
  vtkSetMacro(SliceOffset, int);
  vtkGetMacro(SliceOffset, int);

  // Description:
  // Slices repeat in groups of the Period throughout the volume.
  // Use in conjunction with slice offset to extract every
  // Period-th slice throughout the volume starting
  // at slice number SliceOffset.
  vtkSetMacro(SlicePeriod, int);
  vtkGetMacro(SlicePeriod, int);
  // Lauren need to make sure the period is not larger than
  // the number of slices

  vtkSetMacro(Mode, int);
  vtkGetMacro(Mode, int);

  void SetModeToSLICE(void)
  {
   this->SetMode(0);
   this->Modified();
  };

  void SetModeToVOLUME(void)
  {
  this->SetMode(1);
  this->Modified(); 
  };

  void SetModeToMOSAIC(void)
  {
  this->SetMode(2);
  this->Modified();
  }

  // Description:
  // New variables to support MOSAIC, Siemens,data
  // Number of real slices per each mosaic slice
  vtkSetMacro(MosaicSlices,int);
  vtkGetMacro(MosaicSlices,int);

  // Numbers of tiles per mosaic slice row.
  vtkSetMacro(MosaicTiles,int);
  vtkGetMacro(MosaicTiles,int);

  vtkSetMacro(NumberOfRepetitions,int);
  vtkGetMacro(NumberOfRepetitions,int);
  
  vtkSetClampMacro(Repetition,int,1,NumberOfRepetitions);
  vtkGetMacro(Repetition,int);
  
  vtkBooleanMacro(AverageRepetitions,int);
  vtkSetMacro(AverageRepetitions,int);
  vtkGetMacro(AverageRepetitions,int);

 protected:
  vtkImageExtractSlices();
  ~vtkImageExtractSlices() {};
  vtkImageExtractSlices(const vtkImageExtractSlices&);
  void operator=(const vtkImageExtractSlices&);
  void PrintSelf(ostream& os, vtkIndent indent);

  int SliceOffset;
  int SlicePeriod;
  int Mode;
  int MosaicSlices;
  int MosaicTiles;
  int NumberOfRepetitions;
  int Repetition;
  int AverageRepetitions;

  void ExecuteInformation(vtkImageData *input, 
              vtkImageData *output);
  void ComputeInputUpdateExtent(int inExt[6], 
                int outExt[6]);
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
               int extent[6], int id);
};

#endif




